-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

--- Provides auto-defragmented weak table functionality.
-- @module mfwk.registry
-- @alias mod

local mod = {}
mfwk.Requires( "debug" )

-- Cache
local debug_Trace   = debug.Trace
local getmetatable  = getmetatable
local setmetatable  = setmetatable

-- Constants
local GARBAGE_THRESHOLD = 2048  -- Allows roughly 32KiB of deleted slots to accumulate per weak table (x86_64)

-- Variables
local garbage   = setmetatable( {}, { __mode = "k" } )
local registry  = setmetatable( {}, { __mode = "k" } )

-- Functions

--- Creates a new registry for `handle`.
-- @param handle Handle that owns the registry.
-- @treturn table Automatically defragmented weak table.
function mod.New( handle )
    local ipairs    = ipairs
    local newproxy  = newproxy
    local pairs     = pairs

    garbage[ handle ] = 0

    -- Set up weak table
    local entry = {}
    local index = {}
    local meta  = { __mode = "k" }

    -- Index
    function index.ipairs()
        local values = {}

        for i, v in ipairs( entry ) do
            values[ i ] = v.value
        end

        return ipairs( values )
    end

    function index.pairs()
        local values = {}

        for k, v in pairs( entry ) do
            values[ k ] = v.value
        end

        return pairs( values )
    end

    -- Meta
    function meta.__index( self, k )
        if index[ k ] then return index[ k ] end
        if ( not entry[ k ] ) then return end

        return entry[ k ].value
    end

    function meta.__newindex( self, k, v )
        local proxy = newproxy( true )

        getmetatable( proxy ).__gc = function()
            -- Threshold hit?
            garbage[ handle ] = ( garbage[ handle ] + 1 )
            if ( garbage[ handle ] < GARBAGE_THRESHOLD ) then return end

            -- Deflate
            local inflated = entry
            local deflated = {}
            
            for k, v in pairs( inflated ) do
                if ( v.value ~= nil ) then
                    deflated[ k ] = v
                end
            end

            garbage[ handle ] = 0
            entry = deflated
        end

        entry[ k ]  = {
            proxy   = proxy,
            value   = v,
        }
    end

    -- Register
    registry[ handle ] = setmetatable( {}, meta )
    return registry[ handle ]
end

return mod