-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = mfwk.Module()

-- Cache
local types_IsFunction  = mfwk.types.IsFunction
local types_IsTable     = mfwk.types.IsTable

-- Variables
local meta      = {}

local registry  = {
    parent      = {},
    properties  = {},
}

-- Meta: properties
function meta.__index( self, k )
    local parent = registry.parent[ self ]
    local property = registry.properties[ self ][ k ]
    
    -- Existing property?
    if property then
        if types_IsFunction( property.get ) then return property.get( parent ) end
        return property.get
    end
end

function meta.__newindex( self, k, v )
    local parent = registry.parent[ self ]
    local property = registry.properties[ self ][ k ]

    -- Existing property?
    if property then
        -- Has setter?
        if not property.set then
            mod.debug.Error( "Tried to set read-only property '" .. k .. "'!" )
            return
        end

        -- Setter function?
        if types_IsFunction( property.set ) then
            property.set( parent, v )
            return
        end

        -- Allow direct setting?
        if property.set then
            property.get = v
        end
    end

    -- Create new property
    property = {}

    -- Read-only?
    if ( not types_IsTable( v ) ) then
        property.get = v
        property.set = false
    else
        property.get = v[ 1 ] or v.get
        property.set = v[ 2 ] or v.set
    end

    registry.properties[ self ][ k ] = property
end

-- Functions
function mod.New( parent, init )
    local new = setmetatable( {}, meta )

    registry.properties[ new ] = {}
    registry.parent[ new ] = parent

    if types_IsTable( init ) then
        for k, v in pairs( init ) do
            new[ k ] = v
        end
    end

    return new
end

-- Export
return mod