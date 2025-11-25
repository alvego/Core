-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local table_concat = table.concat
local SecondsToTime = SecondsToTime
local WrapTextInColorCode = WrapTextInColorCode
-------------------------------------------------------------------------------

local function isReadyFunc(fn)
    return c.IsLoaded() and type(fn) == 'function'
end

-------------------------------------------------------------------------------
function c.UnitsCount()
    if isReadyFunc(oUnitsCount) then
        return oUnitsCount()
    end
    return 0
end

-------------------------------------------------------------------------------
function c.UnitPtr(unit)
    if isReadyFunc(oUnitPtr) then
        return oUnitPtr(unit)
    end
    return 0
end

-------------------------------------------------------------------------------
function c.UnitIDByIndex(idx)
    if isReadyFunc(oUnitIDByIndex) then
        return oUnitIDByIndex(idx)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadUlong(ptr, offset)
    if isReadyFunc(oReadUlong) then
        return oReadUlong(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadInt(ptr, offset)
    if isReadyFunc(oReadInt) then
        return oReadInt(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadFloat(ptr, offset)
    if isReadyFunc(oReadFloat) then
        return oReadFloat(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadByte(ptr, offset)
    if isReadyFunc(oReadByte) then
        return oReadByte(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadString(ptr, offset)
    if isReadyFunc(oReadString) then
        return oReadString(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.UnitBehind(unit)
    if isReadyFunc(oUnitBehind) then
        return oUnitBehind(unit)
    end
    return true
end

-------------------------------------------------------------------------------
function c.LookAt(x, y, z)
    if isReadyFunc(oLookAt) then
        oLookAt(x, y, z)
    end
end

-------------------------------------------------------------------------------
function c.LookAtUnit(unit)
    if isReadyFunc(oLookAtUnit) then
        oLookAtUnit(unit)
    end
end

-------------------------------------------------------------------------------
function c.MoveTo(x, y, z)
    if isReadyFunc(oMove) then
        oMove(x, y, z)
    end
end

-------------------------------------------------------------------------------
function c.UnitInLOS(unit1, unit2)
    if isReadyFunc(oUnitInLOS) then
        return oUnitInLOS(unit1, unit2)
    end
    return true
end

-------------------------------------------------------------------------------
function c.UnitClick(unit, use)
    if isReadyFunc(oUnitClick) then
        oUnitClick(unit, use and '1' or nil)
    end
end

-------------------------------------------------------------------------------
function c.UnitPosition(unit)
    if isReadyFunc(oUnitPosition) then
        return oUnitPosition(unit)
    end
    return 0, 0, 0
end

-------------------------------------------------------------------------------
function c.UnitFacing(unit)
    if isReadyFunc(oUnitFacing) then
        return oUnitFacing(unit)
    end
    return 0
end

-------------------------------------------------------------------------------
c.UnitDistance = c.GetCachedFunc(function(unit1, unit2)
    if isReadyFunc(oUnitDistance) then
        return oUnitDistance(unit1, unit2)
    end
    return 0
end)

-------------------------------------------------------------------------------
function c.UnitAuraByID(unit, spellIds, isMine)
    if isReadyFunc(oUnitAuraByID) then
        if type(spellIds) == 'table' then
            spellIds = table_concat(spellIds, ' ')
        end

        local spellId, count, duration, endTime, isMine, isDebuff = oUnitAuraByID(unit, spellIds, isMine and '1' or nil)
        if spellId == nil then
            return nil
        end
        return spellId, count, duration, endTime, isMine, isDebuff
    end
    return nil
end

c.HasAuraByID = c.GetCachedFunc(c.UnitAuraByID)

-------------------------------------------------------------------------------
function c.UnitAuraByIndex(unit, idx)
    if isReadyFunc(oUnitAuraByIndex) then
        local spellId, count, duration, endTime, isMine, isDebuff = oUnitAuraByIndex(unit, idx)
        if spellId == nil then return nil end
        return spellId, count, duration, endTime, isMine, isDebuff
    end
    return nil
end

-------------------------------------------------------------------------------
function c.Script(luaCode)
    if isReadyFunc(oScript) then
        oScript(luaCode)
    end
end

-------------------------------------------------------------------------------
function c.Command(chatCommandLine)
    if isReadyFunc(oCommand) then
        oCommand(chatCommandLine)
    end
end

-------------------------------------------------------------------------------
function c.Spell(spell, target)
    if isReadyFunc(oSpell) then
        oSpell(spell, target)
    end
end

-------------------------------------------------------------------------------
-- slot - An action bar slot (number, actionID)
-- target - A unit to be used as target for the action (string, unitID)
-- button - Mouse button used to activate the action (string)
--  Button4 - Fourth mouse button
--  Button5 - Fifth mouse button
--  LeftButton - Left mouse button (also used when the action is activated via keyboard)
--  MiddleButton - Third mouse button (typically middle button / scroll wheel)
--  RightButton - Right mouse button
function c.Action(slot, target, button)
    if isReadyFunc(oAction) then
        oAction(slot, target, button)
    end
end

-------------------------------------------------------------------------------
local checkTimer = 'CheckExtendedFunc'
function c.CheckExtendedFunc()
    c.TimerToggle(checkTimer, type(oHelp) ~= 'function')
    if c.TimerStarted(checkTimer) and c.TimerMore(checkTimer, 3) then
        c.Echo(WrapTextInColorCode('ждем ' .. SecondsToTime(c.TimerElapsed(checkTimer)), 'ffffff00'), nil,
            c.icon, 0, 1, 0)
    end
end

-------------------------------------------------------------------------------
