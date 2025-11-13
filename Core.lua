-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
Core = {}
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local UnitIsAFK = UnitIsAFK
-------------------------------------------------------------------------------
c.name = ...
c.db = {}
c.state = {}
c.stateCache = {}
-------------------------------------------------------------------------------
c.advance = 0.05
c.latency = c.advance
c.gcdSpellId = 61304
-------------------------------------------------------------------------------

local function canBool(name, value, def)
    if type(value) == 'boolean' then
        c.db[name] = value
    end
    if c.db[name] == nil then return def end
    return c.db[name]
end

function c.Paused(value)
    local paused = canBool('paused', value, true)
    return UnitIsAFK('player') == 1 and true or paused
end

function c.canLoot(value)
    return canBool('canLoot', value, true)
end

function c.canMove(value)
    return canBool('canMove', value, false)
end

function c.showSpellSuccess(value)
    return canBool('showSpellSuccess', value, true)
end

function c.showSpellError(value)
    return canBool('showSpellError', value, true)
end

function c.showCommentLog(value)
    return canBool('showCommentLog', value, true)
end

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
local stateCacheIndex = 0
function c.GetCachedFunc(func)
    stateCacheIndex = stateCacheIndex + 1
    local name = '#' .. stateCacheIndex
    return function(...)
        local key = c.ToStr(name, ...)
        local value = c.stateCache[key]
        if value then return value end
        value = func(...)
        c.stateCache[key] = value
        return value
    end
end

-------------------------------------------------------------------------------
--[[
UIParentLoadAddOn('Blizzard_DebugTools');
DevTools_Dump(c)
]]

--[[
  /run UIParentLoadAddOn('Blizzard_DebugTools');
  /fstack true
  /etrace
]]
-------------------------------------------------------------------------------
