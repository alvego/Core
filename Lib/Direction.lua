-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local UnitIsUnit = UnitIsUnit
local GetPlayerFacing = GetPlayerFacing
local IsMouselooking = IsMouselooking
local deg = deg
local atan2 = atan2
-------------------------------------------------------------------------------
function c.TurnTo(target)
    if not c.attack and c.Paused() then return end
    if c.TimerLess("TurnTo", c.attack and 0.1 or 0.5) then return end
    if not c.attack and not c.state.still then return end
    if IsMouselooking() then
        c.TimerStart("TurnTo")
        return
    end
    if not target then target = "target" end
    if not UnitExists(target) then return end
    if c.PlayerFacingTarget(target, c.attack and 15 or 90) then return end
    --c.Log('Turning to target')
    c.FaceToUnit(target)
    c.TimerStart("TurnTo")
end

-------------------------------------------------------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if subEvent == 'SPELL_CAST_FAILED' and sourceGUID == c.state.playerGUID then
        local message = select(4, ...)
        if message == 'Цель должна быть перед вами.' then
            c.TurnTo('target')
        end
    end
end
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)

-------------------------------------------------------------------------------
local function onUIErrorMessage(event, ...)
    local message = ...
    if message == 'Вы смотрите мимо цели!' then
        c.TurnTo('target')
    end
end
c.AttachEvent('UI_ERROR_MESSAGE', onUIErrorMessage)

-------------------------------------------------------------------------------
function c.PlayerFacingTarget(unit, angle) -- angle 1 .. 90, default 90
    if not angle then angle = 90 end
    if not UnitExists(unit) or UnitIsUnit("player", unit) then return true end
    local yawAngle = c.PlayerFacingAngleToPoint(c.UnitPosition(unit))
    return yawAngle > -angle and yawAngle < angle
end

------------------------------------------------------------------------------------------------------------------
function c.PlayerFacingAngleToPoint(x, y)
    if not x or not y then return 0 end
    local facing = GetPlayerFacing()
    local x0, y0 = c.UnitPosition("player")
    local yawAngle = atan2(y0 - y, x0 - x) - deg(facing) - 180
    if yawAngle < 0 then yawAngle = yawAngle + 360 end
    return yawAngle
end

------------------------------------------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return c.TelemetryBool('DIR', c.PlayerFacingTarget('target', 30))
-- end)
