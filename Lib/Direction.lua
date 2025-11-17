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
        c.PlayerFacingTarget(turnUnit, 30) then
        turnUnit = nil
        if c.TimerStarted('TurnTo') then
            c.TimerReset('TurnTo')
            --c.Log('endturn ', c.PlayerFacingTarget(turnUnit, 30))
        end
        return
    end
    if c.TimerLess('TurnTo', 0.3) then return end
    c.FaceToUnit(turnUnit)
    --c.Log('turn1')
    c.TimerStart('TurnTo')
end

function c.TurnTo(target)
    if not target then target = 'target' end
    turnUnit = target
    turnUpdate()
    --print('turnUnit', turnUnit)
    return turnUnit ~= nil -- поворачиваемся
end

c.AttachBeforeUpdate(turnUpdate)
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
local moveUnit = nil
local maveMaxDist = nil
local function moveEnd()
    if not c.TimerStarted('PlayerMove') then return end
    c.TimerReset('PlayerMove')
    moveUnit = nil
    maveMaxDist = nil
    --c.Log('#пришли')
    if st.speed > 0 and not st.move then
        --c.Log('#тормозим')
        c.MovePlayer(c.UnitPosition('player'))
    end
end
local function moveUpdate()
    -- не идем
    if c.Paused()
        or not c.flags.move
        or st.move
        or st.look
        or not moveUnit
        or not UnitExists(moveUnit)
        or not c.UnitInLOS('player', moveUnit)
    then
        --c.Log('end cond')
        moveEnd()
        return
    end

    local px, py, pz = c.UnitPosition('player')
    local tx, ty, tz = c.UnitPosition(moveUnit)
    local dx, dy, dz = px - tx, py - ty, pz - tz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local d = 4 -- нет смысла подходить ближе
    if dist < 5 or dist <= d or (maveMaxDist and dist > maveMaxDist) then
        --c.Log('end dist')
        moveEnd()
        return
    end

    local ratio = d / dist
    -- Ограничиваем, чтобы остаться на отрезке (опционально)
    if ratio > 1 then ratio = 1 end
    local x, y, z = tx + ratio * dx, ty + ratio * dy, tz + ratio * dz

    -- поворачиваемся

    if c.TurnTo(moveUnit) then
        --c.Log('turn')
        return
    end

    -- идем
    if c.TimerLess('PlayerMove', 0.5) then return end
    --c.Log('move')
    c.MovePlayer(x, y, z)
    c.TimerStart('PlayerMove')
end
c.AttachBeforeUpdate(moveUpdate)

function c.PlayerMove(target, maxDist)
    moveUnit = target
    maveMaxDist = maxDist
    -- идем
    moveUpdate()
    return moveUnit ~= nil
end
