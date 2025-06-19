-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod       = {}
mfwk.Requires( "class", "path", "registry" )

mod.Module      = mfwk.class.New()
mod.ModuleInfo  = mfwk.class.New()

local registry  = mfwk.registry.New( mod.ModuleInfo )

-- Cache
local class_New     = mfwk.class.New
local path_Combine  = mfwk.path.Combine

-- Class: module info
local class     = mod.ModuleInfo
class.File      = { set = false }
class.Name      = { set = false }
class.Package   = { set = false }
class.Path      = { set = false }
class.Module    = nil

function class.Constructor( self, package, name, file )
    self.File       = file
    self.Name       = name
    self.Package    = package
    self.Path       = path_Combine( package.Name, name )

    -- Register
    registry[ self.Path ] = self
end

function class.Load( self )
    if self.Module then return self.Module end

    -- Load module
    self.Module = include( self.File )()
    self.Module.Info = {{ self }}

    -- Initialize
    self.Module:Initialize()

    -- Make immutable
    self.Module = {{ self.Module }}

    -- Return
    return self.Module
end

-- Class: module
local class         = mod.Module
class.Finalize      = function() end
class.Initialize    = function() end
class.Info          = { set = true, init = true }

function class.Include( path )
    local info = registry[ path ]
    if ( not info ) then
        ErrorNoHaltWithStack( "Could not resolve module '" .. path .. "'!" )
        return
    end

    return info:Load()
end

-- Functions
function mod.New()
    return class_New( mod.Module )
end

-- Export
return mod, { Module = mod.New, ModuleInfo = mod.ModuleInfo }