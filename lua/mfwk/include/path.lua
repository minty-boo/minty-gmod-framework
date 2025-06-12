-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local string_sub        = string.sub

-- Constants
local STRING_EMPTY      = ""

-- Functions: utility
function mod.Combine( ... )
    local args = { ... }
    local count = #args

    local path = nil
    
    for i, v in ipairs( args ) do
        if ( i == count ) and ( v[ 1 ] == '.' ) then
            path = ( path and ( path .. v ) or v )
        elseif v and ( v ~= STRING_EMPTY ) then
            path = ( path and ( path .. '/' .. v ) or v )
        end
    end

    return path
end

function mod.Directory( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == '/' ) then
            return string_sub( path, 1, i - 1 )
        end
    end

    return path
end

function mod.File( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == '/' ) then
            return string_sub( path, i + 1 )
        end
    end

    return path
end

function mod.FileWithoutExtension( path )
    return mod.WithoutExtension( mod.File( path ) )
end

function mod.WithoutExtension( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == '.' ) then
            return string_sub( path, 1, i - 1 )
        end
    end

    return path
end

-- Export
return mod