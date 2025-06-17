-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

--- Convenience functions for tables.
-- @module mfwk.table
-- @alias mod

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

--- Checks whether `tbl` contains `obj`.
-- @tparam table tbl Table to check.
-- @param obj Value to search for.
-- @return bool Does `tbl` contain `obj`?
function mod.Contains( tbl, obj )
    for _, v in pairs( tbl ) do if ( v == obj ) then return true end end
    return false
end

--- Counts the number of entries in `tbl`.
-- @tparam table tbl Table to count entries of.
-- @treturn number Amount of entries in `tbl`.
function mod.Count( tbl )
    local count = 0
    for _, _ in pairs( tbl ) do count = count + 1 end

    return count
end

--- Filters `tbl`, given a `filter` function.
-- Assumes `tbl` is numerically and sequentially indexed.
-- @tparam table tbl Table to filter.
-- @tparam func filter Filter function, e.g. `function( v ) return ( type( v ) == "string" ) end` to filter out all strings.
-- @treturn table Filtered results.
function mod.Filter( tbl, filter )
    local result = {}

    for i, v in ipairs( tbl ) do
        if filter( v ) then
            result[ #result + 1 ] = v
        end
    end

    return result
end

--- Finds the fully qualified name of `tbl`.
-- E.g. `local tbl = mfwk.table; mfwk.table.FindName( tbl )` would output "mfwk.table".
-- @tparam table tbl Table to find the name of.
-- @treturn string Name of `tbl`, or `nil` if it could not be found.
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

--- Finds the root table containing `tbl`.
-- E.g. `local tbl = mfwk.table; mfwk.table.FindParent( tbl )` would output `mfwk`.
-- @tparam table tbl Table to find the parent table of.
-- @treturn table Parent table, or `nil` if it could not be found.
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

--- Removes an entry from `tbl`, by number index or value.
-- Assumes `tbl` is numerically and sequentially indexed.
-- @tparam table tbl Table to remove from.
-- @param kv Number index, or value.
-- @return Removed value, or nil if the index was invalid/value could not be found.
function mod.Remove( tbl, kv )
    if types_IsNumber( kv ) then return table_remove( tbl, kv ) end
    
    for i, v in ipairs( tbl ) do
        if ( v == kv ) then return table_remove( tbl, i ) end
    end
end

--- Sorts `tbl`, given a `sorter` function.
-- Assumes `tbl` is numerically and sequentially indexed.
-- @tparam table tbl Table to sort.
-- @tparam func sorter Sorting function, e.g. `function( a, b ) return ( #a < #b ) end` to sort by length (ascending).
-- @treturn table Sorted results.
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

--- Seperates the values of nested tables in `tbl` into separate tables.
-- Assumes `tbl` is numerically and sequentially indexed.
-- @tparam table tbl Table to unzip.
-- @treturn table Unzipped results.
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