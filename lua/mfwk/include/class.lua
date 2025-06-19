-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}
mfwk.Requires( "registry", "table", "types" )

-- Cache
local ipairs            = ipairs
local pairs             = pairs
local registry_New      = mfwk.registry.New
local setmetatable      = setmetatable
local table_OnlyKeys    = mfwk.table.OnlyKeys
local types_IsFunction  = mfwk.types.IsFunction
local types_IsTable     = mfwk.types.IsTable

-- Constants
local MEMBER_FIELD      = 1
local MEMBER_METHOD     = 2
local MEMBER_PROPERTY   = 3

local KEYS_PROPERTY     = { "get", "set", "init", "value" }

local LUT                   = {
    MEMBER_COPY             = {
        [ MEMBER_FIELD ]    = true,
        [ MEMBER_METHOD ]   = false,
        [ MEMBER_PROPERTY ] = true,
    },

    MEMBER_KIND             = {
        [ MEMBER_FIELD ]    = "field",
        [ MEMBER_METHOD ]   = "method",
        [ MEMBER_PROPERTY ] = "property",
    },
}

-- Variables
local index     = {
    instance    = {},
    immutable   = {},
    member      = {},
}

local meta      = {
    class       = { __metatable = "class" },
    instance    = { __metatable = "instance" },
    immutable   = { __metatable = "immutable" },
    member      = { __metatable = "member" },
}

local registry  = {
    class       = registry_New( meta.class ),
    instance    = registry_New( meta.instance ),
    immutable   = registry_New( meta.immutable ),
}

-- Meta: class
function meta.class.__call( self, ... )
    local instance  = meta.instance.New( self )
    local entry     = registry.instance[ instance ]

    -- Copy members
    local from = self

    while from do
        for k, v in pairs( registry.class[ from ].members ) do
            if ( not entry.members[ k ] ) and LUT.MEMBER_COPY[ v.kind ] then
                entry.members[ k ] = v:copy()
            end
        end

        from = from.base
    end

    -- Make class immutable
    registry.class[ self ].immutable = true

    -- Construct instance
    self.Constructor( instance, ... )
    entry.constructed = true

    -- Seal members
    for _, v in pairs( entry.members ) do
        if types_IsTable( v.value ) and ( not v.set ) then
            v.value = meta.immutable.New( v.value )
        end
    end

    return instance
end

function meta.class.__index( self, k )
    -- Existing member?
    local member = registry.class[ self ].members[ k ]
    if member then return member:get() end

    -- Base class?
    if self.base then
        member = self.base[ k ]
        if member then return member end
    end
end

function meta.class.__newindex( self, k, v )
    local entry = registry.class[ self ]

    -- Immutable?
    if entry.immutable then
        ErrorNoHaltWithStack( "Tried to set member '" .. k .. "' of an immutable object!" )
        return
    end

    -- Existing member?
    local member = entry.members[ k ]

    if member then
        -- Duplicate definition
        ErrorNoHaltWithStack( "Duplicate definition of " .. LUT.MEMBER_KIND[ member.kind ] .. " '" .. k .. "'!" )
        return
    end

    -- New property?
    if types_IsTable( v ) then
        -- New property?
        if table_OnlyKeys( v, KEYS_PROPERTY ) then
            entry.members[ k ] = meta.member.New( MEMBER_PROPERTY, ( v.get or nil ), ( v.set or false ), ( v.init or false ), v.value )
            return
        end
    end

    -- New method?
    if types_IsFunction( v ) then
        entry.members[ k ] = meta.member.New( MEMBER_METHOD, nil, false, false, v )
        return
    end

    -- New field?
    entry.members[ k ] = meta.member.New( MEMBER_FIELD, nil, nil, false, v )
end

function meta.class.New( base )
    -- New
    local new   = {
        Constructor = function() end,
        Destructor  = function() end,
    }

    new = setmetatable( new, meta.class )

    -- Registry entry
    local entry     = {
        immutable   = false,
        members     = {},
    }

    registry.class[ new ] = entry

    -- Set base?
    if base then
        local base_entry = registry.class[ base ]

        -- Valid base?
        if ( not base_entry ) then
            ErrorNoHaltWithStack( "Invalid base class!" )
            return
        end

        -- Set/seal base
        base_entry.immutable = true
        new.base = { set = false, value = base }
    else
        new.base = nil
    end

    -- Return
    return new
end

-- Index: instance
function index.instance.ipairs( self )
    local values = {}

    for k, v in ipairs( registry.instance[ self ].members ) do
        values[ k ] = v.value
    end

    return ipairs( values )
end

function index.instance.pairs( self )
    local values = {}

    for k, v in pairs( registry.instance[ self ].members ) do
        values[ k ] = v.value
    end

    return pairs( values )
end

-- Meta: instance
function meta.instance.__index( self, k )
    if index.instance[ k ] then return index.instance[ k ] end
    local entry = registry.instance[ self ]

    -- Existing member?
    local member = entry.members[ k ]
    if member then return member:get() end

    -- Class member?
    member = entry.class[ k ]
    if member then return member end
end

function meta.instance.__newindex( self, k, v )
    local entry = registry.instance[ self ]

    -- Existing member?
    local member = entry.members[ k ]

    if member then
        if ( not member.set ) then
            -- Allow setting read-only members in constructor
            if ( not entry.constructed ) then
                member.value = v
                return
            end

            ErrorNoHaltWithStack( "Tried to set read-only " .. LUT.MEMBER_KIND[ member.kind ] .. " '" .. k .. "'!" )
            return
        end

        -- Only set once?
        if member.init then
            member.init = false
            self[ k ] = v

            member.set = false
            return
        end

        -- Create immutable?
        if v and types_IsTable( v ) and ( types_IsTable( v[ 1 ] ) ) then
            v = v[ 1 ][ 1 ]

            member.set = false
            member.value = ( types_IsTable( v ) and meta.immutable.New( v ) or v )
            return
        end

        if types_IsFunction( member.set ) then member:set( v ) else member.value = v end
        return
    end

    -- Class member?
    member = registry.class[ entry.class ][ k ]
    if member then
        ErrorNoHaltWithStack( "Tried to overwrite class " .. LUT.MEMBER_KIND[ member.kind ] .. " '" .. k .. "'!" )
        return
    end

    -- Non-existant member
    ErrorNoHaltWithStack( "Tried to set non-existant member '" .. k .. "'!" )
end

function meta.instance.New( class )
    local new   = {}
    
    -- Registry entry
    local entry     = {
        class       = class,
        constructed = false,
        members     = {},
    }

    registry.instance[ new ] = entry

    -- Return
    return setmetatable( new, meta.instance )
end

-- Index: member
function index.member.copy( self )
    return meta.member.New( self.kind, self.get, self.set, self.init, self.value )
end

function index.member.get( self )
    return self.value
end

function index.member.set( self, v )
    self.value = v
end

-- Meta: member
function meta.member.__index( self, k )
    if index.member[ k ] then return index.member[ k ] end
end

function meta.member.New( kind, get, set, init, value )
    -- New
    local new   = {
        kind    = kind,

        get     = get,
        set     = set,
        init    = init,
        value   = value,
    }

    return setmetatable( new, meta.member )
end

-- Index: immutable
function index.immutable.ipairs( self )
    local entry     = registry.immutable[ self ]
    local immutable = {}

    if entry.ipairs then
        for i, v in entry:ipairs() do
            immutable[ i ] = ( types_IsTable( v ) and meta.immutable.New( v ) or v )
        end
    else
        for i, v in ipairs( entry ) do
            immutable[ i ] = ( types_IsTable( v ) and meta.immutable.New( v ) or v )
        end
    end

    return ipairs( immutable )
end

function index.immutable.pairs( self )
    local entry     = registry.immutable[ self ]
    local immutable = {}

    if entry.pairs then
        for k, v in entry:pairs() do
            immutable[ k ] = ( types_IsTable( v ) and meta.immutable.New( v ) or v )
        end
    else
        for k, v in pairs( entry ) do
            immutable[ k ] = ( types_IsTable( v ) and meta.immutable.New( v ) or v )
        end
    end

    return pairs( immutable )
end

-- Meta: immutable
function meta.immutable.__call( self, ... )
    return registry.immutable[ self ]( ... )
end

function meta.immutable.__index( self, k )
    if index.immutable[ k ] then return index.immutable[ k ] end
    
    local v = registry.immutable[ self ][ k ]
    if types_IsTable( v ) then return meta.immutable.New( v ) end
    return v
end

function meta.immutable.__newindex( self, k, _ )
    ErrorNoHaltWithStack( "Tried to set member '" .. k .. "' of an immutable object!" )
end

function meta.immutable.New( tbl )
    local new = {}
    registry.immutable[ new ] = tbl

    return setmetatable( new, meta.immutable )
end

-- Functions
function mod.New( base )
    return meta.class.New( base )
end

-- Export
return mod, { Immutable = meta.immutable.New }