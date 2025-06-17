-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local debug_getinfo     = debug.getinfo
local path_Combine      = mfwk.path.Combine
local setmetatable      = setmetatable
local string_Hash       = mfwk.string.Hash
local types_IsFunction  = mfwk.types.IsFunction

-- Constants
local GUID_SALT     = "module"
local STRING_EMPTY  = ""

-- Variables
local environment   = false
local index         = {}
local meta          = {}
local registry      = {}
local lut           = {}

-- Utility
local function apply_environment( mdl )
    if ( not environment ) then return end

    for k, v in pairs( environment ) do
        rawset( mdl, k, v )
    end

    environment = false
end

local function get_module_source()
    local level = 2
    
    while true do
        local candidate = debug_getinfo( level, "nS" )
        if ( not candidate ) then return STRING_EMPTY end
        if ( candidate.namewhat == STRING_EMPTY ) then return candidate.source end

        level = level + 1
    end
end

local function include_module( entry )
    if entry.module then return entry.module end

    environment = {
        __name  = entry.name,
        __path  = entry.path,
        __root  = entry.root,
    }

    local mdl = include( entry.file )
    entry.module = mdl
    
    return mdl
end

-- Index
function index.Include( self, path )
    local entry = registry[ path ]
    if ( not entry ) then ErrorNoHaltWithStack( "Could not resolve module with name '" .. path .. "'!" ) return end
    
    -- Get from registry, otherwise load file
    local mdl = include_module( entry )

    -- Hook post-include
    if types_IsFunction( mdl.dependency.Include ) then
        mdl.dependency.Include( self )
    end

    -- Hook constructor
    if types_IsFunction( mdl.dependency.Initialize ) then
        local __constructor = self.__constructor
        
        self.__constructor = function( self )
            mdl.dependency.Initialize( self )
            __constructor( self )
        end
    end

    -- Hook destructor
    if types_IsFunction( mdl.dependency.Finalize ) then
        local __destructor = self.__destructor
        
        self.__destructor = function( self )
            mdl.dependency.Finalize( self )
            __destructor( self )
        end
    end

    return mdl
end

-- Meta
function meta.__index( self, k )
    if index[ k ] then return index[ k ] end
end

-- Functions
function mod.GUID()
    return string_Hash( GUID_SALT .. get_module_source() )
end

function mod.Initialize()
    for k, v in pairs( registry ) do
        if ( not v.module ) then include_module( v ) end

        v.module:__constructor()
        v.module:Initialize()

        v.module.__initialized = true
    end
end

function mod.New()
    local guid  = mod.GUID()
    local mdl   = lut[ guid ]

    -- New
    local new   = {
        __guid          = guid,

        __constructor   = function() end,
        __destructor    = function() end,
        __initialized   = false,

        dependency      = {},

        Initialize      = function() end,
        Finalize        = function() end,
    }

    apply_environment( new )
    new = setmetatable( new, meta )

    -- Reload?
    if mdl then
        if mdl.__initialized then mdl:Finalize() end

        rawset( new, "__name", mdl.__name )
        rawset( new, "__path", mdl.__path )
        rawset( new, "__root", mdl.__root )

        registry[ mdl.__path ].module = new

        if mdl.__initialized then mdl:Initialize() end
    end

    lut[ guid ] = new

    return new
end

function mod.Register( file, name, package )
    local path = path_Combine( package.Name, name )
    
    registry[ path ] = {
        file    = file,
        module  = false,
        name    = name,
        package = package,
        path    = path,
        root    = package.Name,
    }
end

-- Export
return mod