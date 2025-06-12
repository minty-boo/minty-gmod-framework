-- SPDX-License-Identifier: MIT
-- (c) ppr_minty 2025

local mod = {}

-- Cache
local MsgC          = MsgC
local SysTime       = SysTime
local debug_getinfo = debug.getinfo
local math_ceil     = math.ceil
local table_insert  = table.insert

-- Constants
local PREFIX        = "mfwk"
local TAG           = "<debug>"

local COLOR_PREFIX  = Color( 110, 210, 155 )
local COLOR_TAG     = Color( 128, 128, 128 )

local COLOR_FATAL   = Color( 255, 0, 0 )
local COLOR_ERROR   = Color( 255, 128, 128 )
local COLOR_WARN    = Color( 255, 255, 128 )
local COLOR_INFO    = Color( 192, 192, 192 )
local COLOR_DEBUG   = Color( 128, 128, 128 )
local COLOR_TRACE   = Color( 255, 128, 255 )

local VERBOSITY_COLOR = {
    COLOR_FATAL,
    COLOR_ERROR,
    COLOR_WARN,
    COLOR_INFO,
    COLOR_DEBUG,
    COLOR_TRACE,
}

local VERBOSITY_TAG = { 'F', 'E', 'W', 'I', 'D', 'T' }

mod.VERBOSITY_NONE  = 0
mod.VERBOSITY_FATAL = 1
mod.VERBOSITY_ERROR = 2
mod.VERBOSITY_WARN  = 3
mod.VERBOSITY_INFO  = 4
mod.VERBOSITY_DEBUG = 5
mod.VERBOSITY_TRACE = 6

-- Variables
mod.verbosity = mod.VERBOSITY_TRACE

-- Utility
local function format_trace( tag, info )
    return ( tag .. ( info.name and ( "::" .. info.name ) or '' ) .. "@L" .. info.currentline )
end

local function to_microseconds( seconds )
    return math_ceil( seconds * 10e6 )
end

-- Functions: logging
function mod.Print( prefix, tag, message, verbosity )
    if ( verbosity > mod.verbosity ) then return end

    MsgC(
        COLOR_PREFIX, prefix, ' ',
        COLOR_TAG, VERBOSITY_TAG[ verbosity ], ' ',
        COLOR_PREFIX, tag, ' '
    )
    
    for _, part in ipairs( message ) do
        MsgC( VERBOSITY_COLOR[ verbosity ], tostring( part ) )    
    end

    MsgC( '\n' )
end

function mod.Fatal( ... ) mod.Print( PREFIX, TAG, { ... }, mod.VERBOSITY_FATAL ) end
function mod.Error( ... ) mod.Print( PREFIX, TAG, { ... }, mod.VERBOSITY_ERROR ) end
function mod.Warn( ... ) mod.Print( PREFIX, TAG, { ... }, mod.VERBOSITY_WARN ) end
function mod.Info( ... ) mod.Print( PREFIX, TAG, { ... }, mod.VERBOSITY_INFO ) end
function mod.Debug( ... ) mod.Print( PREFIX, TAG, { ... }, mod.VERBOSITY_DEBUG ) end

function mod.Time( tag )
    local begin = SysTime()

    return function( logger )
        local duration = to_microseconds( SysTime() - begin )
        logger( '(', tag, ')', " took ", duration, "us" )

        return duration
    end
end

-- Functions: loggers
local function sub_Fatal( prefix, tag, ... ) mod.Print( prefix, tag, { ... }, mod.VERBOSITY_FATAL ) end
local function sub_Error( prefix, tag, ... ) mod.Print( prefix, tag, { ... }, mod.VERBOSITY_ERROR ) end
local function sub_Warn( prefix, tag, ... ) mod.Print( prefix, tag, { ... }, mod.VERBOSITY_WARN ) end
local function sub_Info( prefix, tag, ... ) mod.Print( prefix, tag, { ... }, mod.VERBOSITY_INFO ) end
local function sub_Debug( prefix, tag, ... ) mod.Print( prefix, tag, { ... }, mod.VERBOSITY_DEBUG ) end

local function sub_Trace( prefix, tag, ... )
    if ( mod.verbosity < mod.VERBOSITY_TRACE ) then return end
    mod.Print( prefix, format_trace( tag, debug_getinfo( 3 ) ), { ... }, mod.VERBOSITY_TRACE )
end

-- Functions: instantiation
function mod.New( mdl )
    local prefix = mdl.__root
    local tag = mdl.__name
    
    local log = {
        Fatal = function( ... ) sub_Fatal( prefix, tag, ... ) end,
        Error = function( ... ) sub_Error( prefix, tag, ... ) end,
        Warn = function( ... ) sub_Warn( prefix, tag, ... ) end,
        Info = function( ... ) sub_Info( prefix, tag, ... ) end,
        Debug = function( ... ) sub_Debug( prefix, tag, ... ) end,
        Trace = function( ... ) sub_Trace( prefix, tag, ... ) end,
    }

    return log
end

-- Export
return mod