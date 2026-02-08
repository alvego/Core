---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local tinsert = tinsert
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS
local UnitAffectingCombat = UnitAffectingCombat
local UnitGUID = UnitGUID
local GameTooltip = GameTooltip
local bit = bit
local format = format
local IsControlKeyDown = IsControlKeyDown
local ChatEdit_InsertLink = ChatEdit_InsertLink
local WrapTextInColorCode = WrapTextInColorCode
local COMBATLOG_OBJECT_TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local UnitName = UnitName
local UnitExists = UnitExists
local ChatEdit_GetActiveWindow = ChatEdit_GetActiveWindow
local hooksecurefunc = hooksecurefunc
-- luacheck: pop
local partyUnits = {}
for i = 0, MAX_PARTY_MEMBERS do
    tinsert(partyUnits, 'party' .. i)
end
local raidUnits = {}
for i = 0, MAX_RAID_MEMBERS do
    tinsert(raidUnits, 'raid' .. i)
end
local playerUnits = { 'player' }

function c.GetGroupUnits()
    if st.raid then
        return raidUnits
    end
    if st.party then
        return partyUnits
    end
    return playerUnits
end

local title          = 'Цель'
local icon           = [[Interface\Icons\Ability_Hunter_SniperShot]]

local prevGUID       = nil
local lastGUID       = nil
local manualLastGuid = nil
local searchLastGuid = nil

local mouseButton    = ''
local mouseUnitName  = ''
local manualSource   = WrapTextInColorCode('выбрано руками', 'FF00A6FF')
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

c.Event('GLOBAL_MOUSE_UP', function(event, button)
    if button ~= 'LeftButton' and button ~= 'RightButton' then return end
    mouseUnitName = _G['GameTooltipTextLeft1']:GetText() or '' --GameTooltip:GetUnit()
    if mouseUnitName == '' then return end
    mouseButton = button
    c.NextTick(afterMouseUp)

    if (ChatEdit_GetActiveWindow() and button == 'LeftButton' and IsControlKeyDown() == 1) then
        ChatEdit_InsertLink(mouseUnitName);
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
hookTargetChange('AssistUnit')
hookTargetChange('TargetNearest')
hookTargetChange('TargetNearestEnemy')
hookTargetChange('TargetNearestFriend')

c.Event('PLAYER_TARGET_CHANGED', function()
    local unit = 'target'
    if not UnitExists(unit) then
        searchLastGuid = nil
        manualLastGuid = nil
        return
    end
    lastGUID = UnitGUID(unit)
    c.Message(format('#Новая цель %s', c.UnitInfo(unit)), title, icon)
end)

function c.IsManualTarget()
    return manualLastGuid and lastGUID == manualLastGuid
end

c.Event('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        if subEvent == 'UNIT_DIED' and lastGUID == destGUID then
            c.TimerReset('attack')
        end
    end)
function c.SearchTarget(range, angle)
    local targetGuid = c.bFindTarget(range, angle, lastGUID, st.attack)
    if not targetGuid then return false end
    c.Log('Поиск цели range:', range, ':angle', angle, 'combatMode:', st.attack, 'нашли:', targetGuid)
    searchLastGuid = targetGuid
    c.bTargetUnit(targetGuid)
    local tar = 'target'
    if not UnitExists(tar) then return false end
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
    return true
end

c.Event('COMBAT_LOG_EVENT_UNFILTERED', function(event, timestamp, subEvent,
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
    c.TimerStart('targetCombat') -- повлияет на st.combatMode и выбор цели
end)

c.GetEnemyCount = c.GetCachedFunc(function(range, aroundUnit)
    return c.bGetEnemyCount(range, aroundUnit)
end)
