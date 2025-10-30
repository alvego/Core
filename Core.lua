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
    return db.paused or UnitIsAFK('player')
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
