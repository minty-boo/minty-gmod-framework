-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = mfwk.Module()

-- Variables
mod.__meta = {
    ANGLE       = FindMetaTable( "Angle" ),
    COLOR       = FindMetaTable( "Color" ),
    ENTITY      = FindMetaTable( "Entity" ),
    IMATERIAL   = FindMetaTable( "IMaterial" ),
    PANEL       = FindMetaTable( "Panel" ),
    PHYSOBJ     = FindMetaTable( "PhysObj" ),
    PLAYER      = FindMetaTable( "Player" ),
    VECTOR      = FindMetaTable( "Vector" ),
    WEAPON      = FindMetaTable( "Weapon" ),
}

local meta = {
    null = {},
    patch = {},
}

local index = {
    patch = {},
}

-- Meta: null
local null = setmetatable( { __null = true }, meta.null )

function meta.null.__index( self, _ ) return null end
function meta.null.__newindex( self, _, _ ) end

-- Index: patch
function index.patch.Clear( self )
    self:Unpatch()
    self.__patch = {}
end

function index.patch.Patch( self )
    if self.__active then self:Unpatch() end

    for k, v in pairs( self.__patch ) do
        if v.__patch then
            v:Patch()
        else
            v[ 1 ][ k ] = v[ 3 ]
        end
    end

    self.__active = true
end

function index.patch.Unpatch( self )
    if not self.__active then return end

    for k, v in pairs( self.__patch ) do
        if v.__patch then
            v:Unpatch()
        else
            v[ 1 ][ k ] = v[ 2 ]
        end
    end

    self.__active = false
end

-- Meta: patch
function meta.patch.__index( self, k )
    -- Trying to get patched function?
    if ( k == "__func" ) then k = 3 end

    -- Exists as child?
    if self.__patch[ k ] then return self.__patch[ k ] end
    
    -- Exists as meta-function?
    if index.patch[ k ] then return index.patch[ k ] end

    local name = ( self.__name and ( self.__name .. '.' .. k ) or k )
    local target = ( self.__table and self.__table[ k ] or ( _G[ k ] or mod.__meta[ k ] ) )
    local Tt = type( target )

    -- Ensure target table exists
    if ( Tt ~= "table" ) then
        mod.debug.Warn( "Invalid target table '" .. name .. "', got '" .. Tt .. "'" )
        mod.debug.TraceEx( 1, '^' )

        return null
    end
    
    -- Create child patch
    local child = meta.patch.New( name, self, target )
    rawset( self.__patch, k, child )

    return child
end

function meta.patch.__newindex( self, k, v )
    local name      = ( self.__name and ( self.__name .. '.' .. k ) or k )
    local table     = ( self.__table or _G )
    local target    = table[ k ]

    -- Ensure target exists
    if not target then
        mod.debug.Warn( "Invalid target: " .. k )
        mod.debug.TraceEx( 1, '^' )

        return
    end

    -- Ensure type match
    local Tt = type( target )
    local Tv = type( v )

    if ( Tt ~= Tv ) then
        mod.debug.Warn( "Type mismatch for target '" .. name .. "', expected '", Tt, "' got '", Tv, "'" )
        mod.debug.TraceEx( 1, '^' )
        
        return
    end

    -- Register patch
    if ( Tv == "function" ) then
        v = setfenv( v, setmetatable( { [ "_f" ] = target }, { __index = _G } ) )
    end

    self.__patch[ k ] = { table, target, v, name }
end

function meta.patch.New( name, super, table )
    local new = {
        __name = name,
        __super = super,
        __table = table,

        __active = false,
        __patch = {},
    }

    return setmetatable( new, meta.patch )
end

-- Functions
function mod.Constructor( mdl )
    mdl.patch = meta.patch.New( false, false, false )
end

-- Export
return mod