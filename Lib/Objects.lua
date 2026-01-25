---@class Core
local c = Core

-- Кешируем функции и значения
local tinsert = tinsert
local UnitIsUnit = UnitIsUnit
local UnitCanAttack = UnitCanAttack
local UnitHealthMax = UnitHealthMax
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local actual = false
local units = {}
local targets = {}
local objects = {}

c.BeforeUpdate(function()
    if c.TimerMore('resetObjectCache', 1.5) then
        actual = false
        c.TimerStart('resetObjectCache')
    end
end)

local function updateObject()
    if actual then return end
    wipe(units)
    wipe(targets)
    wipe(objects)
    local count = c.UnitsCount()
    for i = 0, count - 1 do
        local unit = c.UnitIDByIndex(i)
        if unit then
            if UnitExists(unit) then
                tinsert(units, unit)
                if UnitCanAttack('player', unit) then
                    tinsert(targets, unit)
                end
            else
                tinsert(objects, unit)
            end
        end
    end
    actual = true
end


function c.GetTargets()
    updateObject()
    return targets
end

c.GetEnemyCount = c.GetCachedFunc(function(range, aroundUnit)
    return c.bGetEnemyCount(range, aroundUnit, 20)
end)


local function checkSameUnit(uid, unit)
    if not UnitIsUnit(uid, unit) then return end
    return uid
end

c.GetUnitID = c.GetCachedFunc(function(unit)
    if not UnitExists(unit) then return end
    updateObject();
    local count = #units
    if count < 1 then return end
    return c.FindValue(units, checkSameUnit, unit)
end)

local function checkSameGuid(uid, guid)
    --if not UnitExists(uid) then return end
    if UnitGUID(uid) ~= guid then return end
    return uid
end

c.GetObjectIdByGUID = c.GetCachedFunc(function(guid)
    if not guid then return end
    updateObject();
    local count = #objects
    if count < 1 then return end
    return c.FindValue(objects, checkSameGuid, guid)
end)
