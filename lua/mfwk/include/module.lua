-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local ipairs            = ipairs
local pairs             = pairs
local path_Combine      = mfwk.path.Combine
local string_Split      = mfwk.string.Split
local table_insert      = table.insert
local types_IsFunction  = mfwk.types.IsFunction

-- Variables
local index     = {}
local meta      = {}
local registry  = {}

-- Index: module
function index.Include( self, k )
    self.__dependencies[ k ] = true
end

function index.Index( self, tbl )
    for k, v in pairs( tbl ) do
        self.__index[ k ] = v
    end
end

function index.Init( self, tbl )
    for k, v in pairs( tbl ) do
        self.__init_env[ k ] = v
    end
end

-- Meta: module
function meta.__index( self, k )
    if index[ k ] then return index[ k ] end
    if self.__index[ k ] then return self.__index[ k ] end

    if ( not self.__initialized ) then
        rawset( self, k, {} )
        return self[ k ]
    end
end

-- Functions
function mod.Get( name )
    return registry[ name ]
end

function mod.Initialize()
    local ordered = {}

    -- Determine load order
    for name, mdl in pairs( registry ) do
        local insert = true

        -- Register includes
        for k, _ in pairs( mdl.__dependencies ) do
            local parts = { string_Split( k, '/' ) }
            local count = #parts

            if ( not mdl.__includes[ parts[ 1 ] ] ) then mdl.__includes[ parts[ 1 ] ] = {} end
            local tail = mdl.__includes[ parts[ 1 ] ]

            for i = 2, ( count - 1 ) do
                if ( not tail[ parts[ i ] ] ) then tail[ parts[ i ] ] = {} end
                tail = tail[ parts[ i ] ]
            end

            tail[ parts[ count ] ] = registry[ k ]
        end

        -- Check dependencies
        for i = #ordered, 1, -1 do
            if mdl.__dependencies[ ordered[ i ].__path ] then
                table_insert( ordered, i + 1, mdl )
                insert = false
                break
            end
        end

        -- Check depends
        for i, depends in ipairs( ordered ) do
            if depends.__dependencies[ mdl.__path ] then
                table_insert( ordered, i, mdl )
                insert = false
                break
            end
        end

        -- Insert anyway?
        if insert then table_insert( ordered, mdl ) end
    end

    -- Initialize modules
    for i, mdl in ipairs( ordered ) do
        -- Set init environment
        mdl.Initialize = setfenv( mdl.Initialize, mdl.__init_env )

        -- Hook constructors/destructors
        for k, _ in pairs( mdl.__dependencies ) do
            local v = registry[ k ]

            if types_IsFunction( v.Constructor ) then
                local initialize = mdl.Initialize
                
                mdl.Initialize = function( self )
                    v.Constructor( self )
                    initialize( self )
                end
            end

            if types_IsFunction( v.Destructor ) then
                local finalize = mdl.Finalize

                mdl.Finalize = function( self )
                    v.Destructor( self )
                    finalize( self )
                end
            end
        end

        -- Initialize module
        mdl:Initialize()
        mdl.__initialized = true
    end
end

function mod.New()
    local new = {
        __constructor   = false,
        __dependencies  = {},
        __includes      = {},
        __index         = {},
        __init_env      = setmetatable( {}, { __index = _G } ),
        __initialized   = false,

        Finalize        = function() end,
        Initialize      = function() end,
    }

    new.__init_env.mod  = new

    return setmetatable( new, meta ), new.__includes
end

function mod.Register( file, name, package )
    -- Include module
    local mdl = include( file )
    mdl.__name = name
    mdl.__root = package.Name
    mdl.__path = path_Combine( mdl.__root, mdl.__name )

    mdl.debug = mfwk.debug.New( mdl )

    -- Add to registry
    registry[ mdl.__path ] = mdl
end

-- Export
return mod