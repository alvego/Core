-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local tinsert = tinsert
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS
local UnitIsUnit = UnitIsUnit
local UnitCanAttack = UnitCanAttack
local UnitAffectingCombat = UnitAffectingCombat
local UnitGUID = UnitGUID
local IsMouselooking = IsMouselooking
local wipe = wipe
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsPossessed = UnitIsPossessed
-------------------------------------------------------------------------------
local localDebug = false
-------------------------------------------------------------------------------
local partyUnits = {}
for i = 0, MAX_PARTY_MEMBERS do
    tinsert(partyUnits, 'party' .. i)
end
local raidUnits = {}
for i = 0, MAX_RAID_MEMBERS do
    tinsert(raidUnits, 'raid' .. i)
end
local playerUnits = { 'player' }
-------------------------------------------------------------------------------
function c.GetGroupUnits()
    if c.state.raid then
        return raidUnits
    end
    if c.state.party then
        return partyUnits
    end
    return playerUnits
end

-------------------------------------------------------------------------------
local groupTargets = {}
local function getGroupTarget(skipGUID) --assist
    local tar, cnt = nil, 0
    local units = c.GetGroupUnits()
    wipe(groupTargets)
    for i = 1, #units do
        local t = units[i] .. '-target'
        if UnitCanAttack('player', t) and UnitAffectingCombat(t) and (not skipGUID or UnitGUID(t) == skipGUID) then
            for _t, _ in pairs(groupTargets) do
                if UnitIsUnit(t, _t) then
                    t = _t -- use first added uid
                    break
                end
            end
            local _c = (groupTargets[t] or 0) + 1 -- count of people who select this target + 1
            groupTargets[t] = _c
            if not tar or _c > cnt then
                tar = t
                cnt = _c
            end
        end
    end
    return tar
end

-------------------------------------------------------------------------------
local enemy = {}
local function checkEnemy(uid, look, skipGUID, x, y, z)
    local invalidTarget = c.IsInvalidTarget(uid)
    if invalidTarget then
        return invalidTarget
    end
    local maxHP = UnitHealthMax(uid)
    if UnitHealthMax(uid) < 20 then
        return c.ToStr('skip: maxhp(', maxHP, ') < 20')
    end
    local combat = UnitAffectingCombat(uid)
    -- выбираем другую цель
    if skipGUID and skipGUID == UnitGUID(uid) then
        return 'skip: curr tar'
    end
    -- уже есть кто-то в бою
    if enemy.combat and not combat then
        return 'skip: !combat'
    end
    -- автоматически выбераем только цели в бою
    if not c.attack and not combat then
        return 'skip: !attack & !combat'
    end
    -- не будет лута
    if (UnitIsTapped(uid)) and (not UnitIsTappedByPlayer(uid)) then
        return 'skip: tapped'
    end
    -- Призванный юнит
    if UnitIsPossessed(uid) then
        return 'skip: possessed'
    end
    -- в pvp выбираем только игроков
    if c.state.pvp and not UnitIsPlayer(uid) then
        return 'skip: pvp !player'
    end
    -- только актуальные цели
    local angle = look and 15 or 90
    local face = c.PlayerFacingTarget(uid, angle)
    -- если смотрим, то только впереди
    if look and not face then
        return c.ToStr('look(', angle, ') & !face')
    end
    local dist = c.Distance(x, y, z, c.UnitPosition(uid))
    if enemy.face and not face and dist > 8 then
        return c.ToStr('skip: !face & dist(', dist, ') > 8')
    end
    if dist > enemy.dist then
        return c.ToStr('skip: dist(', c.Round(dist, 2), ') > enemy.dist(', c.Round(enemy.dist, 2), ')')
    end
    enemy.uid = uid
    enemy.combat = combat
    enemy.face = face
    enemy.dist = dist
    return c.ToStr(
        'success,',
        'combat:', enemy.combat,
        'face:', enemy.face,
        'dist:', c.Round(dist)
    )
end

-------------------------------------------------------------------------------
local function getEnemyTarget(skipGUID)
    enemy.uid = nil
    enemy.face = false
    enemy.dist = 1000
    enemy.combat = false
    local look = IsMouselooking()
    local targets = c.GetTargets()
    local x, y, z = c.UnitPosition(uid)
    for i = 1, #targets do
        local uid = targets[i]
        local info = checkEnemy(uid, look, skipGUID, x, y, z)
        if (localDebug and info) then
            c.Message(format('%s', info, uid), 'target')
            c.MessageLog(format('-- name: %s', UnitName(uid)), 'target')
            c.MessageLog(format('-- uid: %s', uid), 'target')
        end
    end
    return enemy.uid
end

-------------------------------------------------------------------------------

function c.FindAndSelectNewTarget()
    local _currentGUID = c.state.invalidTarget and nil or UnitGUID("target")
    local tar = nil
    -- assist
    if not c.attack and not c.state.pvp and c.state.group then
        tar = getGroupTarget(_currentGUID)
        if tar then
            if localDebug then
                c.Success('Select form group targets')
                c.MessageLog(format('-- name: %s', UnitName(tar)), 'target')
                c.MessageLog(format('-- uid: %s', tar), 'target')
            end
            c.Target(tar)
            return
        end
    end
    -- enemy
    tar = getEnemyTarget(_currentGUID)
    if tar then
        if localDebug then
            c.Success('Select form enemies')
            c.MessageLog(format('-- name: %s', UnitName(tar)), 'target')
            c.MessageLog(format('-- uid: %s', tar), 'target')
        end
        c.Target(tar)
    end
end

-------------------------------------------------------------------------------
