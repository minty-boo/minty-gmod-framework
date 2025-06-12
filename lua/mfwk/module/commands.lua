-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = mfwk.Module()

mod.autocomplete    = {}
mod.transform       = {}

-- Constants
local TAG               = "mfwk.commands.Execute"

-- Cache
local debug_getinfo     = debug.getinfo
local debug_getlocal    = debug.getlocal
local ipairs            = ipairs
local pairs             = pairs
local player_FindByName = mfwk.player.FindByName
local player_GetAll     = player.GetAll
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
local index = {
    command = {},
    mdl     = {},
}

local meta  = {
    command = {},
}

local registry = {}

-- Utility: command
local function cmd_autocomplete( cmd, args_str, args )
    local result = {}
    if ( not cmd.__autocomplete ) then return result end

    local args_count = #args
    local completer = cmd.__autocomplete[ args_count - 1 ]

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
        for i, v in ipairs( completer( args[ args_count ] ) ) do
            result[ i ] = ( cmd.__prefix .. ' ' .. args[ 1 ] .. ' ' .. v )
        end

        return result
    end

    return result
end

local function cmd_execute_server( cmd, ply, args )

end

local function cmd_execute( command, cmd, ply, args_str, args )
    -- Transform args
    if command.__transform then
        for i, fn in ipairs( cmd.__transform ) do
            args[ i ] = fn( args[ i ] )
        end
    end

    -- Set environment and call
    command.__env.caller = ply
    command.__env.args = args
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
    local function handle_sub_callback( ply, cmd, args, args_string )
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
        cmd_execute( command, ply, cmd, args, args_string )
    end

    -- Register prefix command
    concommand.Add( prefix, handle_sub_callback, handle_sub_autocomplete )
    registry[ prefix ] = entry
end

local function cmd_register( cmd )
    -- Register sub-command
    if ( not registry[ cmd.__prefix ] ) then cmd_register_prefix( cmd.__prefix ) end
    registry[ cmd.__prefix ][ cmd.__name ] = cmd

    table_insert( registry[ cmd.__prefix ].__commands, cmd.__name )
end

local function cmd_params_string( cmd )
    local info = debug_getinfo( cmd.__callback, 'u' )
    local params_string = nil

    for i = 1, info.nparams do
        local param = ( '<' .. debug_getlocal( cmd.__callback, i ) .. '>' )
        params_string = ( params_string and ( params_string .. ' ' .. param ) or param )
    end

    if info.isvararg then
        local param = "<...>"
        params_string = ( params_string and ( params_string .. ' ' .. param ) or param )
    end

    return params_string
end

-- Index: command
function index.command.Autocomplete( self, ... )
    self.__autocomplete = { ... }
    return self
end

function index.command.Transform( self, ... )
    self.__transform = { ... }
    return self
end

-- Index: mdl
function index.mdl.AddCommand( mdl, name, callback )
    local cmd       = {
        __env       = setmetatable( { mod = mdl }, { __index = _G } ),
        __name      = name,
        __mdl       = mdl,
        __prefix    = mdl.__command_prefix,
        __server    = true,
    }

    cmd.__callback = setfenv( callback, cmd.__env )
    cmd.__help = ( "usage: " .. cmd.__prefix .. ' ' .. cmd.__name .. ' ' .. cmd_params_string( cmd ) )

    cmd = setmetatable( cmd, meta.command )
    cmd_register( cmd )

    return cmd
end

-- Meta: command
function meta.command.__call( self, ... )
    self.__env.caller = nil
    self.__env.args = { ... }
    self.__callback( ... )
end

function meta.command.__index( self, k )
    if index.command[ k ] then return index.command[ k ] end
end

-- Functions: autocomplete
function mod.autocomplete.Player( arg )
    local _, names = player_FindByName( arg )
    return names
end

-- Functions: transform
function mod.transform.Player( arg )
    local players, _ = player_FindByName( arg )
    return players[ 1 ]
end

-- Functions: module
function mod.Constructor( mdl )
    mdl.__commands = {}
    mdl.__command_prefix = mdl.__root

    -- Register meta-functions
    mdl:Index( index.mdl )

    -- Register init-env
    mdl:Init( { autocomplete = mod.autocomplete, transform = mod.transform } )

    -- Register commands
    if types_IsTable( mdl.commands ) then
        for k, v in pairs( mdl.commands ) do
            mdl.commands[ k ] = mdl:AddCommand( string_lower( k ), v )
        end
    end
end

-- Export
return mod