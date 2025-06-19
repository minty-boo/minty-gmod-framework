-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

--- Convenience functions for paths.
-- @module mfwk.path
-- @alias mod

local mod = {}

-- Cache
local string_sub        = string.sub

-- Constants
local EXTENSION_SEPARATOR   = "."
local PATH_SEPARATOR        = "/"
local STRING_EMPTY          = ""

-- Functions: utility

--- Concatenates arguments into a file path.
-- E.g. `mfwk.path.Combine( "foo", "bar", "module", ".lua" )` will return `foo/bar/module.lua`.
-- @tparam {string,...} Variable amount of path parts.
-- @treturn string Concatenated path.
function mod.Combine( ... )
    local args = { ... }
    local count = #args

    local path = nil
    
    for i, v in ipairs( args ) do
        if ( i == count ) and ( v[ 1 ] == EXTENSION_SEPARATOR ) then
            path = ( path and ( path .. v ) or v )
        elseif v and ( v ~= STRING_EMPTY ) then
            path = ( path and ( path .. PATH_SEPARATOR .. v ) or v )
        end
    end

    return path
end

--- Returns the sub-directory of `path`.
-- E.g. `mfwk.path.Directory( "foo/bar/module.lua" )` will return `foo/bar`.
-- @tparam string path Path to get the sub-directory of.
-- @treturn string Sub-directory of `path`.
function mod.Directory( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == PATH_SEPARATOR ) then
            return string_sub( path, 1, i - 1 )
        end
    end

    return path
end

--- Returns the file name and extension of `path`.
-- E.g. `mfwk.path.File( "foo/bar/module.lua" )` will return `module.lua`.
-- @tparam string path Path to get the file name and extension of.
-- @treturn string File name and extension after the last path separator.
function mod.File( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == PATH_SEPARATOR ) then
            return string_sub( path, i + 1 )
        end
    end

    return path
end

--- Returns the file name of `path`, without file extension.
-- E.g. `mfwk.path.FileWithoutExtension( "foo/bar/module.lua" )` will return `module`.
-- @tparam string path Path to get the file name of.
-- @treturn string File name after the last path separator, without extension.
function mod.FileWithoutExtension( path )
    return mod.WithoutExtension( mod.File( path ) )
end

--- Trims trailing extension from `path`, if it has one.
-- E.g. `mfwk.path.WithoutExtension( "foo/bar/module.lua" )` will return `foo/bar/module`.
-- @tparam string path Path to trim.
-- @treturn string Path without trailing extension.
function mod.WithoutExtension( path )
    for i = #path, 1, -1 do
        if ( path[ i ] == EXTENSION_SEPARATOR ) then
            return string_sub( path, 1, i - 1 )
        end

        if ( path[ i ] == PATH_SEPARATOR ) then break end
    end

    return path
end

-- Export
return mod