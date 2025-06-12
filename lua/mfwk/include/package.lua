-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local file_Exists               = file.Exists
local file_Find                 = file.Find
local file_IsDir                = file.IsDir
local ipairs                    = ipairs
local path_Combine              = mfwk.path.Combine
local path_WithoutExtension     = mfwk.path.WithoutExtension
local string_sub                = string.sub

-- Constants
local GAME_PATH_LOCAL           = "MOD"
local GAME_PATH_MOUNTED         = "LUA"
local PATH_MODULES              = "module"
local PATH_PACKAGE              = "package.lua"
local ROOT_LOCAL                = "lua"
local ROOT_MOUNTED              = ""

local LUA_REALMS    = { "shared", "server", "client" }

local REALM_SHARED  = 1
local REALM_SERVER  = 2
local REALM_CLIENT  = 3

-- Utility: convenience
local function package_info( root, game_path )
    -- Is valid package?
    local modules_path = path_Combine( root, PATH_MODULES )
    if ( not file_IsDir( modules_path, game_path ) ) then return false end
    
    local package_file = path_Combine( root, PATH_PACKAGE )
    if ( not file_Exists( package_file, game_path ) ) then return false end

    -- Get info
    AddCSLuaFile( package_file )
    
    local info = include( package_file )
    info.Root = modules_path

    return info
end

local function should_allow_local()
    return ( GetConVar( "sv_allowcslua" ):GetInt() > 0 ) 
end

local function should_index( realm )
    return (
        ( realm == REALM_SHARED ) or
        ( ( realm == REALM_SERVER ) and SERVER ) or
        ( ( realm == REALM_CLIENT ) and CLIENT )
    )
end

local function should_upload( realm )
    return ( realm ~= REALM_SERVER )
end

-- Utility: indexing
local function index_recursive( root, sub, game_path, realm, index )
    local realm_length = ( #LUA_REALMS[ realm ] + 2 )

    local files, _ = file_Find( path_Combine( root, sub, "*.lua" ), game_path )
    local _, folders = file_Find( path_Combine( root, sub,  "*" ), game_path )

    for _, file in ipairs( files ) do
        -- Upload to client if client/shared
        if should_upload( realm ) then AddCSLuaFile( path_Combine( root, sub, file ) ) end

        -- Do not register if not in realm
        if should_index( realm ) then
            index[ #index + 1 ] = {
                path_Combine( string_sub( sub, realm_length ), path_WithoutExtension( file ) ),
                path_Combine( root, sub, file ),
            }
        end
    end

    for _, folder in ipairs( folders ) do
        index_recursive( root, path_Combine( sub, folder ), game_path, realm, index )
    end
end

local function index_files( root, game_path )
    local index = {}
    root = path_Combine( root, PATH_MODULES )

    -- Top-level
    local files, _ = file_Find( path_Combine( root, "*.lua" ), game_path )

    for _, name in ipairs( files ) do
        local file = path_Combine( root, name )
        AddCSLuaFile( file )

        index[ #index + 1 ] = { path_WithoutExtension( name ), file }
    end

    -- Recursive
    for realm, folder in ipairs( LUA_REALMS ) do
        index_recursive( root, folder, game_path, realm, index )
    end

    -- Return
    return index
end

-- Utility: finding
local function find_packages( root, game_path )
    local packages = {}
    local _, folders = file_Find( path_Combine( root, '*' ), game_path )

    if folders then
        for _, name in ipairs( folders ) do
            local folder = path_Combine( root, name )
            local info = package_info( folder, game_path )

            -- Valid package?
            if info then
                info.Name = ( info.Name or name ) -- Default to folder name
                info.Modules = index_files( folder, game_path ) -- Index modules

                packages[ #packages + 1 ] = info
            end
        end
    end

    return packages
end

local function find_local()
    if SERVER or ( not should_allow_local() ) then return {} end
    return find_packages( ROOT_LOCAL, GAME_PATH_LOCAL )
end

local function find_mounted()
    return find_packages( ROOT_MOUNTED, GAME_PATH_MOUNTED )
end

-- Utility: register
local function register_packages( packages )
    
end

-- Functions
function mod.Find()
    local packages = {}
    for _, package in ipairs( find_mounted() ) do packages[ #packages + 1 ] = package end
    for _, package in ipairs( find_local() ) do packages[ #packages + 1 ] = package end

    return packages
end

function mod.Register( package )
    for _, v in ipairs( package.Modules ) do
        mfwk.module.Register( v[ 2 ], v[ 1 ], package )
    end
end

-- Export
return mod