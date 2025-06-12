-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local pairs             = pairs
local ipairs            = ipairs
local string_find       = string.find
local string_lower      = string.lower
local table_insert      = table.insert
local table_remove      = table.remove
local tostring          = tostring
local types_IsNumber    = mfwk.types.IsNumber
local types_IsString    = mfwk.types.IsString
local types_IsTable     = mfwk.types.IsTable
local unpack            = unpack

-- Variables
local cache = {
    name    = {},
    parent  = {},
}

-- Functions
function mod.Count( tbl )
    local count = 0
    for _, _ in pairs( tbl ) do count = count + 1 end

    return count
end

function mod.Filter( tbl, filter )
    local result = {}

    for i, v in ipairs( tbl ) do
        if filter( v ) then
            result[ #result + 1 ] = v
        end
    end

    return result
end

function mod.Sort( tbl, sorter )
    local result = {}

    for i, v in ipairs( tbl ) do
        local count = #result
        local index = ( count + 1 )

        for j = count, 1, -1 do
            if sorter( v, result[ j ] ) then
                index = j - 1
                break
            end
        end

        table_insert( result, index, v )
    end

    return result
end

function mod.Find( needle, root, name, exclude )
    root = root or _G
    exclude = exclude or {}

    exclude[ root ] = true

    local result = {}

    -- Single depth pass
    for k, v in pairs( root ) do
        if types_IsString( k ) then
            if string_find( string_lower( k ), string_lower( needle ) ) then
                local name = ( name and ( name .. '.' .. k ) or k )
                result[ name ] = tostring( v )
            end
        end
    end

    -- Recursive pass
    for k, v in pairs( root ) do
        if types_IsString( k ) and types_IsTable( v ) and not exclude[ v ] then
            for p, q in pairs( mod.Find( needle, v, ( name and ( name .. '.' .. k ) or k ), exclude ) ) do
                result[ p ] = q
            end
        end
    end

    return result
end

function mod.FindName( tbl, root, name, exclude )
    if cache.name[ tbl ] then return cache.name[ tbl ] end

    root = root or _G
    exclude = exclude or {}

    exclude[ root ] = true

    -- Single depth pass
    for k, v in pairs( root ) do
        if types_IsString( k ) and types_IsTable( v ) then
            if name and not cache.name[ root ] then cache.name[ root ] = name end
            
            local name = ( name and ( name .. '.' .. k ) or k )

            if not cache.name[ v ] then cache.name[ v ] = name end
            if not cache.parent[ v ] then cache.parent[ v ] = { root, k } end

            if ( v == tbl ) then
                return name
            end
        end
    end

    -- Recursive pass
    for k, v in pairs( root ) do
        if types_IsString( k ) and types_IsTable( v ) and not exclude[ v ] then
            local name = mod.FindName( tbl, v, ( name and ( name .. '.' .. k ) or k ), exclude )
            if name then return name end
        end
    end
end

function mod.FindParent( tbl, root, exclude )
    if cache.parent[ tbl ] then return unpack( cache.parent[ tbl ] ) end

    root = root or _G
    exclude = exclude or {}

    exclude[ root ] = true

    -- Single depth pass
    for k, v in pairs( root ) do
        if types_IsString( k ) and types_IsTable( v ) then
            if not cache.parent[ v ] then cache.parent[ v ] = { root, k } end

            if ( v == tbl ) then
                return root, k
            end
        end
    end

    -- Recursive pass
    for k, v in pairs( root ) do
        if types_IsString( k ) and types_IsTable( v ) and not exclude[ v ] then
            local p, q = mod.FindParent( tbl, v, exclude )
            if p then return p, q end
        end
    end
end

function mod.Remove( tbl, kv )
    if types_IsNumber( kv ) then return table_remove( tbl, kv ) end
    
    for i, v in ipairs( tbl ) do
        if ( v == kv ) then return table_remove( tbl, i ) end
    end
end

function mod.Unzip( tbl )
    local unzipped = {}

    for i, v in ipairs( tbl ) do
        for j, q in ipairs( v ) do
            if ( not unzipped[ j ] ) then unzipped[ j ] = {} end
            unzipped[ j ][ i ] = q
        end
    end

    return unzipped
end

-- Export
return mod