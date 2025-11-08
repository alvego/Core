-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
-- Кешируем функции и значения
local tinsert = tinsert
-------------------------------------------------------------------------------
local actual = false
local objects = {}
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
    wipe(objects)
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
            else
                tinsert(objects, unit)
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
function c.GetObjects()
    updateObject()
    return objects
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
