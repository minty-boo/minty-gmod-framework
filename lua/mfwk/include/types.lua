-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local type      = type

-- Utility
local function type_check( object, T ) return ( type( object ) == T ) end

-- Functions
function mod.IsBoolean( object ) return type_check( object, "boolean" ) end
function mod.IsEntity( object ) return type_check( object, "userdata" ) end
function mod.IsFunction( object ) return type_check( object, "function" ) end
function mod.IsNumber( object ) return type_check( object, "number" ) end
function mod.IsString( object ) return type_check( object, "string" ) end
function mod.IsTable( object ) return type_check( object, "table" ) end
function mod.IsType( object, T ) return type_check( object, T ) end

function mod.IsNil( object ) return ( object == nil ) end

-- Compatibility: GLua
mod.IsBoolean   = isbool or mod.IsBoolean
mod.IsEntity    = isentity or mod.IsEntity
mod.IsFunction  = isfunction or mod.IsFunction
mod.IsNumber    = isnumber or mod.IsNumber
mod.IsString    = isstring or mod.IsString
mod.IsTable     = istable or mod.IsTable

-- Export
return mod