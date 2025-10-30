-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local table_concat = table.concat
-------------------------------------------------------------------------------
function c.UnitsCount()
    if type(oUnitsCount) == 'function' then
        return oUnitsCount()
    end
    return 0
end

-------------------------------------------------------------------------------
function c.UnitPtr(unit)
    if type(oUnitPtr) == 'function' then
        return oUnitPtr(unit)
    end
    return 0
end

-------------------------------------------------------------------------------
function c.UnitIDByIndex(idx)
    if type(oUnitIDByIndex) == 'function' then
        return oUnitIDByIndex(idx)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadUlong(ptr, offset)
    if type(oReadUlong) == 'function' then
        return oReadUlong(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadInt(ptr, offset)
    if type(oReadInt) == 'function' then
        return oReadInt(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadFloat(ptr, offset)
    if type(oReadFloat) == 'function' then
        return oReadFloat(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadByte(ptr, offset)
    if type(oReadByte) == 'function' then
        return oReadByte(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.ReadString(ptr, offset)
    if type(oReadString) == 'function' then
        return oReadString(ptr, offset)
    end
    return nil
end

-------------------------------------------------------------------------------
function c.UnitBehind(unit)
    if type(oUnitBehind) == 'function' then
        return oUnitBehind(unit)
    end
    return true
end

-------------------------------------------------------------------------------
function c.FaceToUnit(unit)
    if type(oFaceToUnit) == 'function' then
        oFaceToUnit(unit)
    end
end

-------------------------------------------------------------------------------
function c.MovePlayer(x, y, z)
    if type(oMovePlayer) == 'function' then
        oMovePlayer(x, y, z)
    end
end

-------------------------------------------------------------------------------
function c.UnitInLOS(unit1, unit2)
    if type(oUnitInLOS) == 'function' then
        return oUnitInLOS(unit1, unit2)
    end
    return true
end

-------------------------------------------------------------------------------
function c.UnitClick(unit)
    if type(oUnitClick) == 'function' then
        oUnitClick(unit)
    end
end

-------------------------------------------------------------------------------
function c.UnitPosition(unit)
    if type(oUnitPosition) == 'function' then
        return oUnitPosition(unit)
    end
    return 0, 0, 0
end

-------------------------------------------------------------------------------
function c.UnitFacing(unit)
    if type(oUnitFacing) == 'function' then
        return oUnitFacing(unit)
    end
    return 0
end

-------------------------------------------------------------------------------
function c.UnitDistance(unit1, unit2)
    if type(oUnitDistance) == 'function' then
        return oUnitDistance(unit1, unit2)
    end
    return 0
end

-------------------------------------------------------------------------------
function c.UnitAuraByID(unit, spellIds, isMine)
    if type(oUnitAuraByID) == 'function' then
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

-------------------------------------------------------------------------------
function c.UnitAuraByIndex(unit, idx)
    if type(oUnitAuraByIndex) == 'function' then
        local spellId, count, duration, endTime, isMine, isDebuff = oUnitAuraByIndex(unit, idx)
        if spellId == nil then return nil end
        return spellId, count, duration, endTime, isMine, isDebuff
    end
    return nil
end

-------------------------------------------------------------------------------
function c.CastStop()
    if type(oCastStop) == 'function' then
        oCastStop()
    end
end

-------------------------------------------------------------------------------
function c.CancelBuff(buff)
    if type(oCancelBuff) == 'function' then
        oCancelBuff(buff)
    end
end

-------------------------------------------------------------------------------
function c.Target(unit)
    if type(oTarget) == 'function' then
        oTarget(unit)
    end
end

-------------------------------------------------------------------------------
function c.Focus(unit)
    if type(oFocus) == 'function' then
        oFocus(unit)
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
    if type(oAction) == 'function' then
        oAction(slot, target, button)
    end
end

-------------------------------------------------------------------------------
function c.IsExternalEnabled()
    return type(oHelp) == 'function'
end

-------------------------------------------------------------------------------
