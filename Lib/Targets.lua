-------------------------------------------------------------------------------
-- by Unknown Coder
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
local GameTooltip = GameTooltip
local bit = bit
local wipe = wipe
local math_max = math.max
local IsControlKeyDown = IsControlKeyDown
local ChatFrame_OpenChat = ChatFrame_OpenChat
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsPossessed = UnitIsPossessed
local UnitIsPlayer = UnitIsPlayer
local WrapTextInColorCode = WrapTextInColorCode
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
local search         = {}
local title          = 'Цель'
local icon           = [[Interface\Icons\Ability_Hunter_SniperShot]]
-------------------------------------------------------------------------------
local prevGUID       = nil
local lastGUID       = nil
local manualLastGuid = nil
local searchLastGuid = nil

local mouseButton    = ''
local mouseUnitName  = ''
local manualSource   = WrapTextInColorCode('выбрано рукми', 'FF00A6FF')
local searchSource   = WrapTextInColorCode('выбрано поиском', 'FF81FF7D')

local function logTargetSource(source, method)
    c.MessageLog(format('#%s через %s', source, method), title, icon)
end

local afterMouseUp = function()
    local unit = 'target'
    local name = UnitName('target')
    if name ~= mouseUnitName then
        return
    end
    local guid = UnitGUID(unit)
    if guid == prevGUID then return end
    prevGUID = guid
    searchLastGuid = nil
    manualLastGuid = guid
    logTargetSource(manualSource, mouseButton)
end

c.AttachEvent('GLOBAL_MOUSE_UP', function(event, button)
    if button ~= 'LeftButton' and button ~= 'RightButton' then return end
    mouseUnitName = GameTooltip:GetUnit()
    if not mouseUnitName then return end
    mouseButton = button
    c.NextTick(afterMouseUp)

    if button == 'LeftButton' and IsControlKeyDown() == 1 then
        ChatFrame_OpenChat(mouseUnitName)
    end
end)

local function hookTargetChange(funcName)
    hooksecurefunc(funcName, function(...)
        local unit = 'target'
        if not UnitExists(unit) then return end
        local guid = UnitGUID(unit)
        if guid == prevGUID then return end
        prevGUID = guid
        if funcName == 'TargetUnit' and guid == searchLastGuid then
            manualLastGuid = nil
            logTargetSource(searchSource, c.ToStr(funcName, ...))
            return
        end
        searchLastGuid = nil
        manualLastGuid = guid
        logTargetSource(manualSource, c.ToStr(funcName, ...))
    end)
end
hookTargetChange('TargetUnit')
-- hookTargetChange('TargetLastTarget')
-- hookTargetChange('TargetLastFriend')
-- hookTargetChange('TargetLastEnemy')
hookTargetChange('AssistUnit')
hookTargetChange('TargetNearest')
hookTargetChange('TargetNearestEnemy')
-- hookTargetChange('TargetNearestEnemyPlayer')
hookTargetChange('TargetNearestFriend')
-- hookTargetChange('TargetNearestFriendPlayer')
-- hookTargetChange('TargetNearestPartyMember')
-- hookTargetChange('TargetNearestRaidMember')
-- hookTargetChange('SpellTargetUnit')

-- hooksecurefunc('SpellStopCasting', function(...)
--     c.Log('SpellStopCasting', ..., GetTime())
-- end)

-- hooksecurefunc('SpellStoTargeting', function(...)
--     c.Log('SpellStopTargeting', ..., GetTime())
-- end)

-- hooksecurefunc('UnitIsCharmed', function(...)
--     c.Log('UnitIsCharmed', ..., GetTime())
-- end)

c.AttachEvent('PLAYER_TARGET_CHANGED', function()
    local unit = 'target'
    if not UnitExists(unit) then
        searchLastGuid = nil
        manualLastGuid = nil
        return
    end
    --prevGUID = lastGUID
    lastGUID = UnitGUID(unit)
    c.Message(format('#Новая цель %s', c.UnitInfo(unit)), title, icon)
end)

function c.IsManualTarget()
    return manualLastGuid and lastGUID == manualLastGuid
end

c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        if subEvent == 'UNIT_DIED' and lastGUID == destGUID then
            c.TimerReset('attack')
        end
    end)

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
    enemy.dist = search.maxDistance or 999
    -- если режиме боя, и не даваим атаку, игнорируем мобов не в бою
    enemy.combat = st.combatMode and not st.attack
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
    c.Message(format('#%s: %s', WrapTextInColorCode(c.name, 'ff00ff00'), c.UnitInfo(tar)), title, icon)
    c.MessageLog(
        format('#бой: игрок - %s, цель - %s',
            st.combatLock and 'да' or 'нет',
            UnitAffectingCombat(tar) and 'да' or 'нет'
        ),
        title, icon)
    c.MessageLog(
        format('#comabtMode: %s',
            st.combatMode and 'да' or 'нет'
        ),
        title, icon)
    c.MessageLog(
        format('#attack: %s',
            st.attack and 'да' or 'нет'
        ),
        title, icon)
    searchLastGuid = UnitGUID(tar)
    c.Command('/target ' .. tar)
    return true
end

function c.SearchTarget(tryAssist, maxDistance, inViewfield)
    initSearch(maxDistance, inViewfield)
    -- assist
    if tryAssist and st.group then
        if searchSelect(getGroupTarget()) then return true end
    end
    -- enemy
    if searchSelect(getEnemyTarget()) then return true end
    return false
end

-------------------------------------------------------------------------------
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', function(event, timestamp, subEvent,
                                                      sourceGUID, sourceName, sourceFlags,
                                                      destGUID, destName, destFlags, ...)
    if not st.combatLock then return end -- только в бою
    if st.combatMode then return end     -- если нет цели
    -- только направленные на меня
    if not sourceName or not sourceGUID or destGUID ~= st.playerGUID then return end
    -- Источник события - неодушевленный объект, ловушка, тотем, пропускаем
    if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_OBJECT) ~= 0 then return end
    -- фильтр для игнорирования событий с участием союзников, чтобы фокусировался на боевых действиях против врагов.
    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 then return end
    -- нас пытаются ударить
    if not (subEvent:match('_DAMAGE') or subEvent:match('_MISSED')) then return end
    c.MessageLog(format('#нас атакует: %s', sourceName), title, icon)
    c.TimerStart('combatTarget') -- повлияет на st.combatMode и выбор цели
end)
-------------------------------------------------------------------------------
