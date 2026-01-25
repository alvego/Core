---@class Core
local c = Core

local type = type
local table_concat = table.concat
local SecondsToTime = SecondsToTime
local WrapTextInColorCode = WrapTextInColorCode


local function isReadyFunc(fn)
    return c.IsLoaded() and type(fn) == 'function'
end


function c.UnitsCount()
    local func = oUnitsCount
    if isReadyFunc(func) then
        return func()
    end
    return 0
end

function c.UnitPtr(unit)
    local func = oUnitPtr
    if isReadyFunc(func) then
        return func(unit)
    end
    return 0
end

function c.UnitIDByIndex(idx)
    local func = oUnitIDByIndex
    if isReadyFunc(func) then
        return func(idx)
    end
    return nil
end

function c.ReadUlong(ptr, offset)
    local func = oReadUlong
    if isReadyFunc(func) then
        return func(ptr, offset)
    end
    return nil
end

function c.ReadInt(ptr, offset)
    local func = oReadInt
    if isReadyFunc(func) then
        return func(ptr, offset)
    end
    return nil
end

function c.ReadFloat(ptr, offset)
    local func = oReadFloat
    if isReadyFunc(func) then
        return func(ptr, offset)
    end
    return nil
end

function c.ReadByte(ptr, offset)
    local func = oReadByte
    if isReadyFunc(func) then
        return func(ptr, offset)
    end
    return nil
end

function c.ReadString(ptr, offset)
    local func = oReadString
    if isReadyFunc(func) then
        return func(ptr, offset)
    end
    return nil
end

function c.UnitBehind(unit)
    local func = oUnitBehind
    if isReadyFunc(func) then
        return func(unit)
    end
    return true
end

function c.LookAt(x, y, z)
    local func = oLookAt
    if isReadyFunc(func) then
        func(x, y, z)
    end
end

function c.LookAtUnit(unit)
    local func = oLookAtUnit
    if isReadyFunc(func) then
        func(unit)
    end
end

function c.MoveTo(x, y, z)
    local func = oMove
    if isReadyFunc(func) then
        func(x, y, z)
    end
end

function c.MoveStop()
    local func = oMoveStop
    if isReadyFunc(func) then
        func()
    end
end

function c.UnitInLOS(unit1, unit2)
    local func = oUnitInLOS
    if isReadyFunc(func) then
        return func(unit1, unit2)
    end
    return true
end

function c.UnitClick(unit, use)
    local func = oUnitClick
    if isReadyFunc(func) then
        func(unit, use and '1' or nil)
    end
end

function c.UnitPosition(unit)
    local func = oUnitPosition
    if isReadyFunc(func) then
        return func(unit)
    end
    return 0, 0, 0
end

function c.UnitFacing(unit)
    local func = oUnitFacing
    if isReadyFunc(func) then
        return func(unit)
    end
    return 0
end

c.UnitDistance = c.GetCachedFunc(
---Вычисляет расстояние между двумя существующими юнитами
---@param unit1 string
---@param unit2 string
---@return number distance between  unit1 and unit2
    function(unit1, unit2)
        if unit1 and not UnitExists(unit1) then
            error('UnitDistance работает только с существующим unit1', 2)
        end
        if unit2 and not UnitExists(unit2) then
            error('UnitDistance работает только с существующим unit2', 2)
        end
        local func = oUnitDistance
        if isReadyFunc(func) then
            return func(unit1, unit2)
        end
        return 0
    end
)

function c.UnitAuraByID(unit, spellIds, mineOnly)
    local func = oUnitAuraByID
    if isReadyFunc(func) then
        if type(spellIds) == 'table' then
            spellIds = table_concat(spellIds, ' ')
        end

        local spellId, count, duration, endTime, isMine, isDebuff = func(unit, spellIds,
            mineOnly and '1' or nil)
        if spellId == nil then
            return nil
        end
        return spellId, count, duration, endTime, isMine, isDebuff
    end
    return nil
end

c.HasAuraByID = c.GetCachedFunc(c.UnitAuraByID)


function c.UnitAuraByIndex(unit, idx)
    local func = oUnitAuraByIndex
    if isReadyFunc(func) then
        local spellId, count, duration, endTime, isMine, isDebuff = func(unit, idx)
        if spellId == nil then return nil end
        return spellId, count, duration, endTime, isMine, isDebuff
    end
    return nil
end

function c.Command(chatCommandLine)
    local func = oCommand
    if isReadyFunc(func) then
        func(chatCommandLine)
    end
end
