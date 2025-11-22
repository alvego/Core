-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local tinsert = tinsert
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS
local UnitIsUnit = UnitIsUnit
local UnitAffectingCombat = UnitAffectingCombat
local UnitGUID = UnitGUID
local bit = bit
local wipe = wipe
local math_max = math.max
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsPossessed = UnitIsPossessed
local UnitIsPlayer = UnitIsPlayer
local COMBATLOG_OBJECT_TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
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
    if st.raid then
        return raidUnits
    end
    if st.party then
        return partyUnits
    end
    return playerUnits
end

-------------------------------------------------------------------------------
local lastGUID = nil
local searchLastGuid = nil

-- c.DebugHook('TargetUnit')
-- c.DebugHook('TargetLastTarget')
-- c.DebugHook('TargetLastFriend')
-- c.DebugHook('TargetLastEnemy')
-- c.DebugHook('AssistUnit')
-- c.DebugHook('TargetNearest')
-- c.DebugHook('TargetNearestEnemy')
-- c.DebugHook('TargetNearestEnemyPlayer')
-- c.DebugHook('TargetNearestFriend')
-- c.DebugHook('TargetNearestFriendPlayer')
-- c.DebugHook('TargetNearestPartyMember')
-- c.DebugHook('TargetNearestRaidMember')
-- c.DebugHook('SpellTargetUnit')
-- c.DebugHook('ClearTarget')
-- c.DebugHook('ClearFocus')


-- c.DebugHook('RunMacro')
-- c.DebugHook('RunMacroText')
-- c.DebugHook('SecureActionButton_OnClick')

-- hooksecurefunc('ChatEdit_ParseText', function(frame, ...)
--     c.Log('ChatEdit_ParseText', frame:GetText(), ...)
-- end)

-- hooksecurefunc('ClearTarget', function(...)
--     c.Log('ClearTarget', ..., GetTime())
-- end)

-- hooksecurefunc('UnitIsCharmed', function(...)
--     c.Log('UnitIsCharmed', ..., GetTime())
-- end)

-- hooksecurefunc('SpellStopCasting', function(...)
--     c.Log('SpellStopCasting', ..., GetTime())
-- end)

-- hooksecurefunc('SpellStopTargeting', function(...)
--     c.Log('SpellStopTargeting', ..., GetTime())
-- end)

c.DebugHook('RunMacro')
c.DebugHook('RunMacroText')
c.DebugHook('CastSpellByName')
c.DebugHook('CastSpellByID')
c.DebugHook('ClearTarget')

c.AttachEvent('PLAYER_TARGET_CHANGED', function()
    local unit = 'target'
    if not UnitExists(unit) then return end
    lastGUID = UnitGUID(unit)
end)

local search = {}
local title  = 'ENEMY'
local icon   = 'Interface\\Icons\\Ability_Hunter_SniperShot'
local function initSearch(maxDistance, inViewfield)
    wipe(search)
    search.maxDistance = maxDistance
    search.inViewfield = inViewfield
    search.skipGUID = lastGUID -- skip last target
    lastGUID = nil             -- but only once
    local x, y, z = c.UnitPosition('player')
    search.x = x
    search.y = y
    search.z = z
    search.angle = st.attack and 30 or 90
end

local enemyInView = c.GetCachedFunc(function(unit)
    return c.PlayerFacingTarget(unit, search.angle)
end)

local enemyDistance = c.GetCachedFunc(function(unit)
    return c.Distance(search.x, search.y, search.z, c.UnitPosition(unit))
end)

local function isInvalidEnemy(unit)
    local invalidTarget = c.IsInvalidTarget(unit)
    if invalidTarget then
        return invalidTarget
    end
    local name = UnitName(unit)
    if c.StrContains(name, 'тотем') then
        return c.ToStr('skip: тотем')
    end
    local maxHP = UnitHealthMax(unit)
    if UnitHealthMax(unit) <= 25 then
        return c.ToStr('skip: maxhp(', maxHP, ') < 25')
    end
    -- выбираем другую цель
    if search.skipGUID and search.skipGUID == UnitGUID(unit) then
        return 'skip: curr tar'
    end
    -- не будет лута
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
        return 'skip: tapped'
    end
    -- Призванный юнит
    if UnitIsPossessed(unit) then
        return 'skip: possessed'
    end
    -- Призванный юнит
    if not c.UnitInLOS('player', unit) then
        return 'skip: !inLoS'
    end
    -- в pvp выбираем только игроков
    if st.pvp and not UnitIsPlayer(unit) then
        return 'skip: pvp !player'
    end
    -- если надо, то только цели перед лицом
    if search.inViewfield and not enemyInView(unit) then
        return 'skip: out of view field'
    end
    -- слишком далеко
    if search.maxDistance and enemyDistance(unit) > search.maxDistance then
        return c.ToStr('skip: too far')
    end
    return nil
end


local groupTargets = {}
local function getGroupTarget() --assist
    local tar, cnt = nil, 0
    local units = c.GetGroupUnits()
    wipe(groupTargets)
    for i = 1, #units do
        local t = units[i] .. '-target'
        if UnitAffectingCombat(t) and not isInvalidEnemy(t) then
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
local function initEnemy()
    wipe(enemy)
    enemy.uid = nil
    enemy.dist = 99999
    enemy.combat = false
    enemy.look = false
end

local meleeDist = 5
local function checkEnemy(uid)
    local invalidEnemy = isInvalidEnemy(uid)
    if invalidEnemy then
        return invalidEnemy
    end
    local combat = UnitAffectingCombat(uid)
    -- уже есть кто-то в бою
    if enemy.combat and not combat then
        return 'skip: !combat'
    end
    -- автоматически выбераем только цели в бою
    if not st.attack and not combat then
        return 'skip: !attack & !combat'
    end


    local dist = math_max(meleeDist, enemyDistance(uid)) -- melee
    -- уже нашел ближе
    if dist > enemy.dist then
        return format('skip: dist(%.1f) > enemy.dist(%.1f)', dist, enemy.dist)
    end

    local look = enemyInView(uid) -- meleeDist
    if dist == enemy.dist and enemy.look and not look then
        return 'skip: melee !look'
    end

    enemy.uid = uid
    enemy.combat = combat
    enemy.dist = dist
    enemy.look = look
    return c.ToStr(
        'success,',
        'combat:', enemy.combat,
        'dist:', c.Round(dist)
    )
end

-------------------------------------------------------------------------------
local function getEnemyTarget()
    initEnemy()
    local targets = c.GetTargets()
    for i = 1, #targets do
        local uid = targets[i]
        local info = checkEnemy(uid)
        if (localDebug and info) then
            local name = c.UnitInfo(uid)
            c.MessageLog(format('#checkEnemy: %s, name: %s, uid: %s', info, name, uid), title, icon)
        end
    end
    return enemy.uid
end

-------------------------------------------------------------------------------
local function searchSelect(tar)
    if not tar then return false end
    c.Message(format('нашел новую цель: %s', UnitName(tar)), title, icon)
    searchLastGuid = UnitGUID(tar)
    c.Command('/target ' .. tar)
    return true
end

function c.SearchTarget(tryAssist, maxDistance, inViewfield)
    initSearch(maxDistance, inViewfield)
    -- assist
    if tryAssist and st.group then
        if searchSelect(getGroupTarget()) then return end
    end
    -- enemy
    searchSelect(getEnemyTarget())
end

-------------------------------------------------------------------------------
local attackerGUID = nil -- автовыбор атакующих
local function attackTracker(event, timestamp, subEvent,
                             sourceGUID, sourceName, sourceFlags,
                             destGUID, destName, destFlags, ...)
    -- Источник события - неодушевленный объект, ловушка, тотем, пропускаем
    if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_OBJECT) ~= 0 then return end
    -- фильтр для игнорирования событий с участием союзников, чтобы фокусировался на боевых действиях против врагов.
    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 then return end
    if not sourceGUID or destGUID ~= st.playerGUID then return end
    if not (subEvent:match('_DAMAGE') or subEvent:match('_MISSED')) then return end
    --c.Log('#нас атакуют -', sourceName)
    attackerGUID = sourceGUID -- нас атакуют
end
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', attackTracker)


c.AttachBeforeUpdate(function()
    if not attackerGUID then return end
    attackerGUID = nil -- сброс, чтоб не подлипало
    if c.Paused() then return end
    local reason = st.invalidTarget
    if not reason and not st.combatTarget then reason = 'target не в бою' end
    if not reason then return end
    c.MessageLog(c.ToStr('#выбор цели, reason:', reason))
    c.SearchTarget(false, 40, false)
end)

-------------------------------------------------------------------------------
