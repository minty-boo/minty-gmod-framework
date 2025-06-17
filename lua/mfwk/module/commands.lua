-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = mfwk.Module()

mod.autocomplete    = {}
mod.transform       = {}
mod.validate        = {}

-- Constants
local TAG               = "mfwk.commands.Execute"

-- Cache
local debug_getinfo     = debug.getinfo
local debug_getlocal    = debug.getlocal
local ipairs            = ipairs
local pairs             = pairs
local player_FindByName = mfwk.player.FindByName
local setmetatable      = setmetatable
local string_BeginsWith = mfwk.string.BeginsWith
local string_Split      = mfwk.string.Split
local string_find       = string.find
local string_lower      = string.lower
local string_sub        = string.sub
local table_Filter      = mfwk.table.Filter
local table_Sort        = mfwk.table.Sort
local table_insert      = table.insert
local table_remove      = table.remove
local types_IsFunction  = mfwk.types.IsFunction
local types_IsTable     = mfwk.types.IsTable
local unpack            = unpack

-- Variables
local index     = {
    command     = {},
    commands    = {},
}

local meta      = {
    command     = {},
    commands    = {},
}

local registry  = {}

local lut           = {
    autocomplete    = {},
    transform       = {},
    validate        = {},
}

-- Utility: command
local function cmd_autocomplete( cmd, args_str, args )
    local result        = {}
    local args_count    = #args
    local completer     = cmd.__autocomplete[ args_count - 1 ]

    if ( not completer ) then return result end

    -- Simple table-value autocompletion
    if types_IsTable( completer ) then
        for i, v in ipairs( completer ) do
            result[ i ] = ( cmd.__prefix .. ' ' .. args[ 1 ] .. ' ' .. v )
        end

        return result
    end

    -- Autocomplete callback
    if types_IsFunction( completer ) then
        local completions = completer( args[ args_count ] )
        if ( not completions ) then return result end

        for i, v in ipairs( completions ) do
            result[ i ] = ( cmd.__prefix .. ' ' .. args[ 1 ] .. ' ' .. v )
        end

        return result
    end

    return result
end

local function cmd_execute_server( cmd, ply, args )

end

local function cmd_execute( command, cmd, ply, args, args_str )
    if CLIENT and command.__server then return end

    -- Transform args
    for i, fn in ipairs( command.__transform ) do
        args[ i ] = fn( args[ i ] )
    end

    -- Set environment and call
    command.__environment.caller = ply
    command.__environment.args = args
    command.__callback( unpack( args ) )
end

local function cmd_print( ply, message )
    if ply and IsValid( ply ) then
        ply:PrintMessage( HUD_PRINTCONSOLE, message .. '\n' )
    else
        print( message )
    end
end

local function cmd_register_prefix( prefix )
    local entry = {}
    entry.__commands = {}

    -- Handler: autocomplete
    local function handle_sub_autocomplete( cmd, args_str, args )
        local name = args[ 1 ]

        -- Find command?
        if name then
            -- Existing command?
            if args[ 2 ] and entry[ name ] then
                return cmd_autocomplete( entry[ name ], args_str, args )
            end

            -- Evaluate candidates
            local result = {}
            local names = table_Filter( entry.__commands, function( k ) return string_BeginsWith( k, name ) end )
            names = table_Sort( names, function( a, b ) return ( #a < #b ) end )

            for i, k in ipairs( names ) do
                result[ i ] = ( cmd .. ' ' .. k )
            end

            return result
        end
    end

    -- Handler: callback
    local function handle_sub_callback( ply, cmd, args, args_str )
        local name = args[ 1 ]
        local name_length = #name

        -- User needs help?
        if ( name[ name_length ] == '?' ) then
            name = string_sub( name, 1, name_length - 1 )

            -- Command exists?
            local command = entry[ name ]
            if ( not command ) then
                cmd_print( ply, "Unknown command: " .. cmd .. ' ' .. name )
                return
            end

            -- Print help string
            cmd_print( ply, command.__help )
            return
        end

        -- Command exists?
        local command = entry[ name ]
        if ( not command ) then
            cmd_print( ply, "Unknown command: " .. cmd .. ' ' .. name )
            return
        end

        table_remove( args, 1 )
        cmd_execute( command, ply, cmd, args, args_str )
    end

    -- Register prefix command
    concommand.Add( prefix, handle_sub_callback, handle_sub_autocomplete, FCVAR_USERINFO )
    registry[ prefix ] = entry
end

local function cmd_register( cmd )
    -- Register sub-command
    if ( not registry[ cmd.__prefix ] ) then cmd_register_prefix( cmd.__prefix ) end
    registry[ cmd.__prefix ][ cmd.__name ] = cmd

    table_insert( registry[ cmd.__prefix ].__commands, cmd.__name )
end

local function cmd_params_names( callback )
    local names = {}
    local info  = debug_getinfo( callback, 'u' )

    for i = 1, info.nparams do
        names[ i ] = debug_getlocal( callback, i )
    end

    return names, info.isvararg
end

local function cmd_params_info( callback )
    local names, is_vararg  = cmd_params_names( callback )
    local params_string     = nil

    for _, name in ipairs( names ) do
        local param = ( '<' .. name .. '>' )
        params_string = ( params_string and ( params_string .. ' ' .. param ) or param )
    end

    if is_vararg then
        local param = "<...>"
        params_string = ( params_string and ( params_string .. ' ' .. param ) or param )
    end

    return #names, params_string
end

local function cmd_new( mdl, name, callback )
    local args_count, params_string = cmd_params_info( callback )
    local environment               = setmetatable( {}, { __index = _G } )
    local prefix                    = registry[ mdl ].prefix

    local cmd           = {
        __args_count    = args_count,
        __help          = ( "usage: " .. prefix .. ' ' .. name .. ' ' .. params_string ),

        __callback      = setfenv( callback, environment ),
        __environment   = environment,
        __name          = name,
        __module        = mdl,
        __prefix        = prefix,

        __autocomplete  = {},
        __optional      = {},
        __transform     = {},
        __server        = true,
    }

    cmd = setmetatable( cmd, meta.command )
    cmd_register( cmd )

    return cmd
end

-- Meta: command
function meta.command.__call( self, ... )
    self.__environment.caller = nil
    self.__environment.args = { ... }
    self.__callback( ... )
end

function meta.command.__index( self, k )
    if index.command[ k ] then return index.command[ k ] end
end

-- Meta: commands
function meta.commands.__index( self, k )
    if index.commands[ k ] then return index.commands[ k ] end
    if self.__commands[ k ] then return self.__commands[ k ] end
end

function meta.commands.__newindex( self, k, v )
    local cmd = cmd_new( self.__module, string_lower( k ), v )

    -- Infer autocomplete/transform/validate?
    if registry[ self.__module ].infer then
        local params_names = cmd_params_names( v )

        for i, name in ipairs( params_names ) do
            name = string_lower( name )

            local autocomplete  = lut.autocomplete[ name ]
            local transform     = lut.transform[ name ]
            local validate      = lut.validate[ name ]

            if autocomplete then cmd.__autocomplete[ i ] = autocomplete end
            if transform then cmd.__transform[ i ] = transform end
            if validate then cmd.__validate[ i ] = validate end
        end
    end

    -- Register command
    self.__commands[ k ] = cmd
end

function meta.commands.New( mdl )
    local new       = {
        __commands  = {},
        __module    = mdl, 
    }

    return setmetatable( new, meta.commands )
end

-- Functions: autocomplete
function mod.autocomplete.Player( arg )
    local _, names = player_FindByName( arg )
    return names
end

-- Functions: transform
function mod.transform.Player( arg )
    local players, _ = player_FindByName( arg )
    return ( players and players[ 1 ] or nil )
end

-- Build LUTs
for k, v in pairs( mod.autocomplete ) do lut.autocomplete[ string_lower( k ) ] = v end
for k, v in pairs( mod.transform ) do lut.transform[ string_lower( k ) ] = v end
for k, v in pairs( mod.validate ) do lut.validate[ string_lower( k ) ] = v end

-- Functions: module
function mod.dependency.Include( mdl )
    registry[ mdl ] = {
        infer     = true,
        prefix    = mdl.__root,
    }

    mdl.commands    = meta.commands.New( mdl )
end

-- Export
return mod