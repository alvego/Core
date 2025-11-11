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
c.attack = false
c.start = false
c.advance = 0.05
c.latency = c.advance
c.gcdSpellId = 61304
c.lastUsedSpell = nil
c.duel = false
-------------------------------------------------------------------------------
c.showSpellSuccess = true
c.showSpellError = true
c.showNoneReason = true
-------------------------------------------------------------------------------
c.canMove = false

local state = {}
c.state = state

local stateCache = {}
c.stateCache = stateCache

-------------------------------------------------------------------------------
function c.Paused(value)
    if c.db and type(value) == 'boolean' then
        c.db.paused = value
    end
    if (UnitIsAFK('player') == 1) then
        c.Echo('AFK')
        return true
    end
    if not c.db then return true end
    return c.db.paused
end

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
