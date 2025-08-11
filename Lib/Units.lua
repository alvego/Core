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
    if not UnitExists(unit) then return '!exists ' .. unit end
    if not UnitCanAttack("player", unit) then return '!can attack ' .. unit end
    if UnitIsDeadOrGhost(unit) and not ns.HasBuff('Притвориться мертвым', unit) then return '!alive ' .. unit end
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
    return lvl == -1 or lvl > UnitLevel("player") + 3
end

------------------------------------------------------------------------------------------------------------------
function ns.IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return unit1 == unit2 or UnitGUID(unit1) == UnitGUID(unit2)
end

------------------------------------------------------------------------------------------------------------------
function ns.UnitThreat(u, t)
    if not UnitIsPlayer(u) then return 0 end
    return UnitThreatSituation(u, t) or 0
end

------------------------------------------------------------------------------------------------------------------
