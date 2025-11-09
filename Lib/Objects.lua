-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
-- Кешируем функции и значения
local tinsert = tinsert
local UnitIsUnit = UnitIsUnit
local UnitCanAttack = UnitCanAttack
-------------------------------------------------------------------------------
local actual = false
local units = {}
local targets = {}
-------------------------------------------------------------------------------
c.AttachBeforeUpdate(function()
    if c.TimerMore('resetObjectCache', 1.5) then
        actual = false
        c.TimerStart('resetObjectCache')
    end
end)
-------------------------------------------------------------------------------
local function updateObject()
    if actual then return end
    wipe(units)
    wipe(targets)
    local count = c.UnitsCount()
    for i = 0, count - 1 do
        local unit = c.UnitIDByIndex(i)
        if unit then
            if UnitExists(unit) then
                tinsert(units, unit)
                if UnitCanAttack('player', unit) then
                    tinsert(targets, unit)
                end
            end
        end
    end
    actual = true
end

-------------------------------------------------------------------------------
function c.GetTargets()
    updateObject()
    return targets
end

-------------------------------------------------------------------------------
function c.GetUnits()
    updateObject()
    return units
end

-------------------------------------------------------------------------------
c.GetEnemyCount = c.GetCachedFunc(function(range, aroundUnit)
    aroundUnit = aroundUnit or 'player'
    local result = 0
    updateObject();
    local count = #targets
    if count < 1 then return result end
    local x, y, z = c.UnitPosition(aroundUnit)
    for i = 1, count do
        local unit = targets[i]
        if UnitCanAttack('player', unit) then
            local dist = c.Distance(x, y, z, c.UnitPosition(unit))
            if dist <= range then
                result = result + 1
            end
        end
    end
    return result
end)

-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
local function checkSameGuid(uid, guid)
    if UnitExists(uid) then return end
    if UnitGUID(uid) ~= guid then return end
    return uid
end

c.GetUnitIdByGUID = c.GetCachedFunc(function(guid)
    if not guid then return end
    updateObject();
    local count = #units
    if count < 1 then return end
    return c.FindValue(units, checkSameGuid, guid)
end)
