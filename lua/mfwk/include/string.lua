-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local string_sub    = string.sub
local unpack        = unpack

-- Constants
local MAX_SPLIT         = 128

local STRING_EMPTY      = ""
local STRING_WHITESPACE = {
    [ ' ' ]     = true,
    [ '\n' ]    = true,
    [ '\r' ]    = true,
    [ '\t' ]    = true,
}

-- Functions
function mod.BeginsWith( v, prefix )
    for i = 1, #prefix do
        if ( v[ i ] ~= prefix[ i ] ) then return false end
    end

    return true
end

function mod.EndsWith( v, suffix )
    local j = #v

    for i = #suffix, 1, -1 do
        if ( v[ j ] ~= suffix[ i ] ) then return false end
        j = j - 1
    end

    return true
end

function mod.Trim( v )
    local start, stop = 1, #v

    for i = start, stop do
        start = i
        if ( not STRING_WHITESPACE[ v[ i ] ] ) then break end
    end

    for i = stop, start, -1 do
        stop = i
        if ( not STRING_WHITESPACE[ v[ i ] ] ) then break end
    end

    if ( start == stop ) and ( STRING_WHITESPACE[ v[ 1 ] ] ) then return STRING_EMPTY end

    return string_sub( v, start, stop )
end

function mod.Split( v, delimiter, count )
    count = count or MAX_SPLIT
    if ( count < 1 ) then return v end
    
    local split = {}
    local start, length = 1, #v
    
    for i = 1, count do
        if ( start > length ) then break end
        
        for j = start, length do
            if ( v[ j ] == delimiter ) then
                split[ i ] = string_sub( v, start, j - 1 )
                start = j + 1
                
                break
            end
        end
    end

    if ( start <= length ) then
        split[ #split + 1 ] = string_sub( v, start )	
    end

    return unpack( split )
end

-- Export
return mod