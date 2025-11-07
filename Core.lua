-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
Core = {}
CoreDB = CoreDB or {}
Core.db = CoreDB
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

local state = {}
c.state = state

local stateCache = {}
c.stateCache = stateCache

local db = c.db
if db.paused == nil then
    db.paused = true
end

-------------------------------------------------------------------------------
function c.Paused(value)
    if type(value) == 'boolean' then
        db.paused = value
    end
    if (UnitIsAFK('player') == 1) then return true end
    return db.paused
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
