------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local UnitClass = UnitClass
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerControlled = UnitPlayerControlled
local UnitLevel = UnitLevel
local UnitGUID = UnitGUID
local UnitThreatSituation = UnitThreatSituation
local hooksecurefunc = hooksecurefunc
local GetNumTalents = GetNumTalents
local GetTalentInfo = GetTalentInfo
------------------------------------------------------------------------------------------------------------------
local classHex = {
    ['ROGUE'] = 'FFF468',
    ['PRIEST'] = 'FFFFFF',
    ['PALADIN'] = 'F48CBA',
    ['HUNTER'] = 'AAD372',
    ['DEATHKNIGHT'] = 'C41E3A',
    ['MAGE'] = '3FC7EB',
    ['DRUID'] = 'FF7C0A',
    ['WARRIOR'] = 'C69B6D',
    ['WARLOCK'] = '8788EE',
    ['SHAMAN'] = '0070DD',
}
------------------------------------------------------------------------------------------------------------------
function ns.UnitClassName(unit)
    local className = select(2, UnitClass(unit or 'player'))
    return className, classHex[className]
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitHealth100(unit)
    unit = unit or 'player'
    return UnitHealth(unit) * 100 / UnitHealthMax(unit)
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitMana100(unit)
    unit = unit or 'player'
    return UnitMana(unit) * 100 / UnitManaMax(unit)
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitLostHP(unit)
    unit = unit or 'player'
    local hp = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    local lost = maxhp - hp
    return lost
end

------------------------------------------------------------------------------------------------------------------
function ns.IsInvalidTarget(unit)
    unit = unit or 'target'
    if not UnitExists(unit) then return 'остутствует ' .. unit end
    if not UnitCanAttack('player', unit) then return 'не могу бить ' .. unit end
    if UnitIsDeadOrGhost(unit) and not ns.HasBuff('Притвориться мертвым', unit) then return unit .. ' мертв' end
    return false
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitIsNPC(unit)
    unit = unit or 'target'
    return UnitExists(unit) and not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack('player', unit))
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitIsPet(unit)
    unit = unit or 'target'
    return UnitExists(unit) and not ns.UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit)
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitIsBoss(unit)
    unit = unit or 'target'
    local lvl = UnitLevel(unit)
    return lvl == -1 or lvl > UnitLevel('player') + 3
end

------------------------------------------------------------------------------------------------------------------
function ns.IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return unit1 == unit2 or UnitGUID(unit1) == UnitGUID(unit2)
end

------------------------------------------------------------------------------------------------------------------
local inDuel = false
local function startDuel()
    inDuel = true
end
hooksecurefunc('StartDuel', startDuel);

local function duelUpdate(event)
    inDuel = event == 'DUEL_REQUESTED'
end
ns.AttachEvent('DUEL_REQUESTED', duelUpdate)
ns.AttachEvent('DUEL_FINISHED', duelUpdate)

function ns.IsInDuel()
    return inDuel
end

------------------------------------------------------------------------------------------------------------------
local immuneList = { 'Божественный щит', 'Ледяная глыба', 'Сдерживание' }
function ns.UnitIsImmune(unit)
    unit = unit or 'target'
    local aura = ns.HasBuff(immuneList, unit)
    if aura then
        return aura
    end
    aura = ns.HasDebuff('Смерч', unit)
    return aura and aura or false
end

------------------------------------------------------------------------------------------------------------------
local magicList = { 'Отражение заклинания', 'Антимагический панцирь', 'Рунический покров', 'Эффект тотема заземления' }
function ns.UnitIsMagicImmune(unit)
    unit = unit or 'target'
    local aura = ns.HasBuff(magicList, unit)
    return aura and aura or false
end

------------------------------------------------------------------------------------------------------------------
local function resetTimers()
    ns.TimerReset('notBehind')
    ns.TimerReset('notVisible')
end
ns.AttachEvent('PLAYER_TARGET_CHANGED', resetTimers)
------------------------------------------------------------------------------------------------------------------
function ns.IsLOS()
    return ns.TimerLess('notVisible', 0.5)
end

------------------------------------------------------------------------------------------------------------------
function ns.IsNotBehind()
    return ns.TimerLess('notBehind', 0.5)
end

------------------------------------------------------------------------------------------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if sourceGUID ~= ns.State.playerGUID then return end
    if subEvent == 'SPELL_CAST_FAILED' then
        local reason = select(4, ...)
        if reason == 'Вы должны находиться позади цели.' then
            ns.TimerStart('notBehind')
        elseif reason == 'Цель вне поля зрения.' then
            ns.TimerStart('notVisible')
        end
    end
end
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)
------------------------------------------------------------------------------------------------------------------
function ns.HasTalent(talent)
    local found = false;
    for i = 1, 7 do
        for j = 1, 3 do
            local id, n, x, sel = GetTalentInfo(i, j, GetActiveSpecGroup());
            if (id == talent or n == talent) and sel then
                found = true;
            end
        end
    end
    return found;
end

------------------------------------------------------------------------------------------------------------------
function ns.GetCurrentSpecID()
    local maxPoints = 0
    local specID = 0

    for tab = 1, 3 do
        local points = 0
        for i = 1, GetNumTalents(tab) do
            local _, _, _, _, currentRank = GetTalentInfo(tab, i)
            points = points + currentRank
        end

        if points > maxPoints then
            maxPoints = points
            specID = tab
        end
    end

    return specID
end

------------------------------------------------------------------------------------------------------------------
