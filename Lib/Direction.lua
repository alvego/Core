-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local UnitIsUnit = UnitIsUnit
local GetPlayerFacing = GetPlayerFacing
local deg = deg
local atan2 = atan2
-------------------------------------------------------------------------------
function c.TurnTo(target)
    if not target then target = 'target' end
    -- не поворачиваемся
    if not UnitExists(target) then return false end
    if c.PlayerFacingTarget(target, 30) then return false end
    -- поворачиваемся
    if not st.attack and c.Paused() then return true end
    if c.TimerLess('TurnTo', 0.3) then return true end
    if not st.attack and not st.still then return true end
    if st.look then return true end
    --c.Log('Turning to target')
    c.FaceToUnit(target)
    c.TimerStart('TurnTo')
    return true
end

-------------------------------------------------------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if subEvent == 'SPELL_CAST_FAILED' and sourceGUID == st.playerGUID then
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
    if not UnitExists(unit) or UnitIsUnit('player', unit) then return true end
    local yawAngle = c.PlayerFacingAngleToPoint(c.UnitPosition(unit))
    return yawAngle > -angle and yawAngle < angle
end

------------------------------------------------------------------------------------------------------------------
function c.PlayerFacingAngleToPoint(x, y)
    if not x or not y then return 0 end
    local facing = GetPlayerFacing()
    local x0, y0 = c.UnitPosition('player')
    local yawAngle = atan2(y0 - y, x0 - x) - deg(facing) - 180
    if yawAngle < 0 then yawAngle = yawAngle + 360 end
    return yawAngle
end

------------------------------------------------------------------------------------------------------------------
function c.PlayerMove(target, maxDist)
    -- не идем
    if c.Paused() then return false end
    if st.move then return false end
    if not c.canMove() then return false end
    if c.TimerLess('PlayerMove', 0.5) then return false end
    if st.move then return false end
    if st.look then return false end
    if not c.UnitInLOS('player', target) then return false end

    local px, py, pz = c.UnitPosition('player')
    local tx, ty, tz = c.UnitPosition(target)
    local dx = px - tx
    local dy = py - ty
    local dz = pz - tz
    local d = 3
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

    if dist < 5 or dist <= d then
        return false
    end
    if maxDist and dist > maxDist then
        return false
    end

    local ratio = d / dist
    if ratio > 1 then
        ratio = 1 -- Ограничиваем, чтобы остаться на отрезке (опционально)
    end

    local x = tx + ratio * dx
    local y = ty + ratio * dy
    local z = tz + ratio * dz

    -- поворачиваемся и идем
    if c.TurnTo(target) then return true end
    -- идем
    c.MovePlayer(x, y, z)
    c.TimerStart('PlayerMove')
    return true
end

c.AttachActionHook('move', function()
    c.EchoBool('Move', c.canMove(not c.canMove()))
end)

c.AttachTelemetry(function()
    return c.TelemetryBool('Move', c.canMove())
end)
