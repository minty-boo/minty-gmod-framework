-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}
mfwk.Requires( "string", "table" )

-- Cache
local player_GetAll     = player.GetAll
local string_BeginsWith = mfwk.string.BeginsWith
local string_lower      = string.lower
local table_Filter      = mfwk.table.Filter
local table_Sort        = mfwk.table.Sort
local table_Unzip       = mfwk.table.Unzip
local unpack            = unpack

-- Functions
function mod.FindByName( name )
    name = string_lower( name )
    local players = {}
    
    -- Get all player names
    for _, ply in ipairs( player_GetAll() ) do
        if IsValid( ply ) then
            players[ #players + 1 ] = { ply, ply:Nick() }
        end
    end

    -- Filter by matching names
    players = table_Filter( players, function( v ) return string_BeginsWith( string_lower( v[ 2 ] ), name ) end )

    -- Sort by shortest match
    players = table_Sort( players, function( a, b ) return ( #a[ 2 ] < #b[ 2 ] ) end )

    return unpack( table_Unzip( players ) )
end

-- Export
return mod