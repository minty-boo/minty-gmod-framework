-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

mfwk = {}

-- Cache
local include       = include
local ipairs        = ipairs
local pairs         = pairs
local string_sub    = string.sub
local string_upper  = string.upper

-- Constants
local EXTENSION_SEPARATOR   = "."
local PATH_SEPARATOR        = "/"

local INCLUDES_ROOT = "mfwk/include"

-- Utility: path
local function path_combine( ... )
    local args = { ... }
    local count = #args

    local path = nil
    
    for i, v in ipairs( args ) do
        if ( i == count ) and ( v[ 1 ] == EXTENSION_SEPARATOR ) then
            path = ( path and ( path .. v ) or v )
        else
            path = ( path and ( path .. PATH_SEPARATOR .. v ) or v )
        end
    end

    return path
end

local function path_without_extension( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == EXTENSION_SEPARATOR ) then
            return string_sub( path, 1, i - 1 )
        end
    end

    return path
end

-- Utility: load
local function load_include( name )
    if mfwk[ name ] then return end

    -- Register include
    local inc, aliases = include( path_combine( INCLUDES_ROOT, name, ".lua" ) )
    mfwk[ name ] = inc

    -- Register aliases
    if aliases then
        for k, v in pairs( aliases ) do
            mfwk[ k ] = v
        end
    end
end

local function load_includes()
    local files, _ = file.Find( path_combine( INCLUDES_ROOT, "*.lua" ), "LUA" )
    
    for _, k in ipairs( files ) do
        local name = path_without_extension( k )
        load_include( name )
    end
end

-- Functions
function mfwk.Requires( ... )
    for _, k in ipairs( { ... } ) do
        load_include( k )
    end
end

-- Load
load_includes()

-- Debug
local packages = mfwk.package.Find()
packages[ 1 ]:Load()