-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

--- Convenience functions for strings.
-- @module mfwk.string
-- @alias mod

local mod = {}

-- Cache
local math_fmod     = math.fmod
local string_byte   = string.byte
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

--- Checks whether `str` begins with `prefix`.
-- @tparam string str String to check.
-- @tparam string prefix Prefix to check for.
-- @treturn bool Does `str` begin with `prefix`?
function mod.BeginsWith( str, prefix )
    for i = 1, #prefix do
        if ( str[ i ] ~= prefix[ i ] ) then return false end
    end

    return true
end

--- Checks whether `str` ends with `suffix`.
-- @tparam string str String to check.
-- @tparam string suffix Suffix to check for.
-- @treturn bool Does `str` end with `suffix`?
function mod.EndsWith( str, suffix )
    local j = #str

    for i = #suffix, 1, -1 do
        if ( str[ j ] ~= suffix[ i ] ) then return false end
        j = j - 1
    end

    return true
end

--- Calculates the djb2 hash for `str`.
-- @tparam string str String to hash.
-- @treturn number Hash of the string.
function mod.Hash( str )
    local h = 5381

    for i = 1, #str do
        h = math_fmod( ( h * 32 ) + h + string_byte( str, 1 ), 2147483648 )
    end

    return h
end

--- Removes all leading and trailing whitespace from `str`.
-- @tparam string str String to trim.
-- @treturn string Trimmed result.
function mod.Trim( str )
    local start, stop = 1, #str

    for i = start, stop do
        start = i
        if ( not STRING_WHITESPACE[ str[ i ] ] ) then break end
    end

    for i = stop, start, -1 do
        stop = i
        if ( not STRING_WHITESPACE[ str[ i ] ] ) then break end
    end

    if ( start == stop ) and ( STRING_WHITESPACE[ str[ 1 ] ] ) then return STRING_EMPTY end

    return string_sub( str, start, stop )
end

--- Splits `str` by `delimiter`, optionally a maximum of `count` times.
-- @tparam string str String to split.
-- @tparam string delimiter Character to split by.
-- @tparam[opt] number count Maximum amount of times to split `str`.
-- @treturn {string,...} A table of strings split by `delimiter`.
function mod.Split( str, delimiter, count )
    count = count or MAX_SPLIT
    if ( count < 1 ) then return str end
    
    local split = {}
    local start, length = 1, #str
    
    for i = 1, count do
        if ( start > length ) then break end
        
        for j = start, length do
            if ( str[ j ] == delimiter ) then
                split[ i ] = string_sub( str, start, j - 1 )
                start = j + 1
                
                break
            end
        end
    end

    if ( start <= length ) then
        split[ #split + 1 ] = string_sub( str, start )	
    end

    return split
end

--- Same as `mfwk.string.Split`, but returns a variable amount of strings.
-- @see mfwk.string.Split
function mod.Explode( str, delimiter, count )
    return unpack( mod.Split( str, delimiter, count ) )
end

-- Export
return mod