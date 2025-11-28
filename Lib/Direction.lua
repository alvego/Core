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


local turnUnit = nil

local function turnUpdate()
    -- не поворачиваемся
    if c.Paused() or
        not turnUnit or
        not UnitExists(turnUnit) or
        st.move or
        st.look or
        st.playerCasting or
        c.PlayerFacingTarget(turnUnit, 30) then
        turnUnit = nil
        if c.TimerStarted('TurnToUnit') then
            c.TimerReset('TurnToUnit')
        end
        return
    end
    if c.TimerLess('TurnToUnit', 0.3) then return end
    c.LookAtUnit(UnitIsUnit(turnUnit, 'target') and 'target' or turnUnit)
    --c.Log('turnUpdate', turnUnit)
    c.TimerStart('TurnToUnit')
end

function c.TurnToUnit(target)
    if not target then
        target = 'target'
    end
    turnUnit = target
    turnUpdate()
    return turnUnit ~= nil -- поворачиваемся
end

c.AttachBeforeUpdate(turnUpdate)
-------------------------------------------------------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if subEvent == 'SPELL_CAST_FAILED' and sourceGUID == st.playerGUID then
        local message = select(4, ...)
        if message == 'Цель должна быть перед вами.' then
            c.TurnToUnit('target')
        end
    end
end
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)

-------------------------------------------------------------------------------
local function onUIErrorMessage(event, ...)
    local message = ...
    if message == 'Вы смотрите мимо цели!' then
        c.TurnToUnit('target')
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
local moveUnit = nil
local maveMaxDist = nil

local function getPointAhead(d)
    local x, y, z = c.UnitPosition('player')
    local facing = GetPlayerFacing()
    local nx = x + d * math.cos(facing)
    local ny = y + d * math.sin(facing)
    local nz = z -- или скорректируй через TraceLine, если нужно
    return nx, ny, nz
end

local function moveEnd(cond)
    moveUnit = nil
    maveMaxDist = nil
    c.TimerReset('PlayerMove')
    c.Log('#пришли', cond)
    if st.speed > 0 and not st.move and not st.playerCasting then
        c.Log('#тормозим')
        c.MoveTo(getPointAhead(0.1))
    end
end
local function moveUpdate()
    -- не идем
    if not moveUnit then return end

    if c.Paused()
        or not c.flags.move
        or st.move
        or st.look
        or st.playerCasting
        or not moveUnit
        or not UnitExists(moveUnit)
        or not c.UnitInLOS('player', moveUnit)
    then
        moveEnd('условия')
        return
    end

    local px, py, pz = c.UnitPosition('player')
    local tx, ty, tz = c.UnitPosition(moveUnit)
    local dx, dy, dz = px - tx, py - ty, pz - tz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local d = st.combatMode and 4 or 2 -- нет смысла подходить ближе
    if dist <= d then
        moveEnd(format('ближе %dм.', d))
        return
    end
    if maveMaxDist and dist > maveMaxDist then
        moveEnd(format('дальше %dм.', d))
        return
    end

    local ratio = d / dist
    -- Ограничиваем, чтобы остаться на отрезке (опционально)
    if ratio > 1 then
        moveEnd(format('пришли ratio(%.1f) > 1  при d: %d', ratio, d))
        return
    end
    local x, y, z = tx + ratio * dx, ty + ratio * dy, tz + ratio * dz


    local delta = c.Distance(px, py, pz, x, y, z)
    if delta < 1 then
        moveEnd(format('пришли delta(%.1f) < 1  при d: %d', delta, d))
        return
    end

    if c.TimerLess('PlayerMove', 0.5) then return end
    -- поворачиваемся
    if c.TurnToUnit(moveUnit) then
        c.Log('#поворачиваем к ', c.UnitInfo(moveUnit))
        return
    end
    -- идем
    c.Log('#идем к ', c.UnitInfo(moveUnit))
    c.MoveTo(x, y, z)
    c.TimerStart('PlayerMove')
end
c.AttachBeforeUpdate(moveUpdate)

function c.MoveToUnit(target, maxDist)
    moveUnit = target
    maveMaxDist = maxDist
    c.Log('#нужно подойти к ', c.UnitInfo(moveUnit))
    -- идем
    moveUpdate()
    return moveUnit ~= nil
end
