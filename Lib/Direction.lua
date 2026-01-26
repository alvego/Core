---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local UnitIsUnit = UnitIsUnit
local GetPlayerFacing = GetPlayerFacing
local deg = deg
local atan2 = atan2
local WrapTextInColorCode = WrapTextInColorCode
local SetView = SetView
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local format = format
-- luacheck: pop

local viewIndex = 5

function c.SyncCam(reason)
    if c.TimerMore('SetView', 5) and not st.look then
        c.TimerStart('SetView')
        c.Log('#SyncCam ' .. reason)
        SetView(viewIndex)
    end
end

local turnGUID = nil

local function turnUpdate()
    -- не поворачиваемся
    if c.Paused() or
        not turnGUID or
        not c.bObjectExists(turnGUID) or
        st.move or
        st.look or
        st.playerCasting or
        c.bUnitInView(turnGUID, 30) then
        if turnGUID then
            turnGUID = nil
            if c.TimerStarted('TurnToUnit') then
                c.TimerReset('TurnToUnit')
                c.bPlayerLookAt()
            end
        end
        return
    end
    if c.TimerLess('TurnToUnit', 0.3) then return end
    c.bPlayerLookAt(turnGUID)
    --c.Log('turnUpdate', turnUnit)
    c.TimerStart('TurnToUnit')
end
c.BeforeUpdate(turnUpdate, true)

function c.IsTurnToUnit()
    return turnGUID ~= nil -- поворачиваемся
end

function c.TurnToUnit(target)
    if not target then
        target = 'target'
    end
    turnGUID = UnitGUID(target)
    turnUpdate()
    return c.IsTurnToUnit()
end

local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if subEvent == 'SPELL_CAST_FAILED' and sourceGUID == st.playerGUID then
        local message = select(4, ...)
        if message == 'Цель должна быть перед вами.' then
            c.TurnToUnit('target')
        end
    end
end
c.Event('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)


local function onUIErrorMessage(event, ...)
    local message = ...
    if message == 'Вы смотрите мимо цели!' then
        c.TurnToUnit('target')
    end
end
c.Event('UI_ERROR_MESSAGE', onUIErrorMessage)

-----------------------------------
local moveGUID = nil
local moveMaxDist = nil

local function moveEnd(cond)
    moveGUID = nil
    moveMaxDist = nil
    c.TimerReset('PlayerMove')
    c.Log('#пришли', WrapTextInColorCode(cond, 'ff333333'))
    if st.speed > 0 and not st.move and not st.playerCasting then
        c.Log('#тормозим')
        c.bPlayerMoveStop()
    end
    c.SyncCam('moveEnd')
end
local function moveUpdate()
    -- не идем
    if not moveGUID then return end

    if c.Paused()
        or not c.flags.move
        or st.move
        or st.look
        or st.playerCasting
        or not moveGUID
        or not c.bObjectExists(moveGUID)
        or not c.bUnitInLoS('player', moveGUID)
    then
        moveEnd('по проверкам')
        return
    end

    local px, py, pz = c.bUnitPosition('player')
    local tx, ty, tz = c.bUnitPosition(moveGUID)
    local dx, dy, dz = px - tx, py - ty, pz - tz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local d = st.combatMode and 4 or 2 -- нет смысла подходить ближе
    if dist <= d then
        moveEnd(format('дист. < %dм.', d))
        return
    end
    if moveMaxDist and dist > moveMaxDist then
        moveEnd(format('дист. > %dм.', d))
        return
    end

    local ratio = d / dist
    -- Ограничиваем, чтобы остаться на отрезке (опционально)
    if ratio > 1 then
        moveEnd(format('ratio(%.1f) > 1 при d: %d', ratio, d))
        return
    end
    local x, y, z = tx + ratio * dx, ty + ratio * dy, tz + ratio * dz


    local delta = c.Distance(px, py, pz, x, y, z)
    if delta < 1 then
        moveEnd(format('delta(%.1f) < 1  при d: %d', delta, d))
        return
    end

    if c.TimerLess('PlayerMove', 0.5) then return end
    -- поворачиваемся
    if c.TurnToUnit(moveGUID) then
        --c.Log('#поворачиваем к ', c.UnitInfo(moveUnit))
        return
    end
    -- идем
    --c.Log('#идем к ', c.UnitInfo(moveUnit))
    c.bPlayerMoveTo(x, y, z)
    c.TimerStart('PlayerMove')
end
c.BeforeUpdate(moveUpdate, true)

function c.IsMoveUnit()
    return moveGUID ~= nil
end

function c.MoveToUnit(target, maxDist)
    local unitGUID = moveGUID
    moveGUID = UnitGUID(target)
    moveMaxDist = maxDist
    if moveGUID and unitGUID ~= moveGUID then
        c.Log('#нужно подойти к ', c.UnitInfo(target))
    end
    -- идем
    moveUpdate()
    return c.IsMoveUnit()
end
