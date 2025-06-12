-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

mfwk = mfwk or {}

-- Cache
local ipairs = ipairs

-- Constants
local LUA_INCLUDES  = {
    "types",
    "string",
    "path",
    "table",
    "player",
    "debug",
    "module",
    "package",
}

local INCLUDES_ROOT = "mfwk/include"

-- Utility: path
local function path_combine( ... )
    local args = { ... }
    local count = #args

    local path = nil
    
    for i, v in ipairs( args ) do
        if ( i == count ) and ( v[ 1 ] == '.' ) then
            path = ( path and ( path .. v ) or v )
        else
            path = ( path and ( path .. '/' .. v ) or v )
        end
    end

    return path
end

-- Utility: load
local function load_includes()
    for _, v in ipairs( LUA_INCLUDES ) do
        local path = path_combine( INCLUDES_ROOT, v, ".lua" )

        if SERVER then AddCSLuaFile( path ) end
        mfwk[ v ] = include( path )
    end
end

local function load_packages()
    for _, package in ipairs( mfwk.package.Find() ) do
        mfwk.package.Register( package )
    end

    mfwk.module.Initialize()
end

-- Load: includes
load_includes()

-- Functions
mfwk.Module = mfwk.module.New

-- Load: packages
load_packages()