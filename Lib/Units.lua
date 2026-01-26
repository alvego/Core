---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
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
local GetNumTalents = GetNumTalents
local GetTalentInfo = GetTalentInfo
local UnitIsFriend = UnitIsFriend
local GetActiveSpecGroup = GetActiveSpecGroup
local UnitClass = UnitClass
local UnitInRaid = UnitInRaid
local UnitInParty = UnitInParty
-- luacheck: pop

function c.UnitHealth100(unit)
    unit = unit or 'player'
    return UnitHealth(unit) * 100 / UnitHealthMax(unit)
end

function c.UnitMana100(unit)
    unit = unit or 'player'
    return UnitMana(unit) * 100 / UnitManaMax(unit)
end

function c.UnitLostHP(unit)
    unit = unit or 'player'
    local hp = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    local lost = maxhp - hp
    return lost
end

function c.IsInvalidTarget(unit)
    unit = unit or 'target'
    if not UnitExists(unit) then return 'остутствует ' .. unit end
    if UnitIsFriend('player', unit) then return 'дружественная цель ' .. unit end
    if not UnitCanAttack('player', unit) then return 'не могу бить ' .. unit end
    if UnitIsDeadOrGhost(unit) and not c.HasBuff('Притвориться мертвым', unit) then return unit .. ' мертв' end
    return false
end

function c.UnitIsNPC(unit)
    unit = unit or 'target'
    return UnitExists(unit) and not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack('player', unit))
end

function c.UnitIsPet(unit)
    unit = unit or 'target'
    return UnitExists(unit) and not c.UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit)
end

function c.UnitIsBoss(unit)
    unit = unit or 'target'
    local lvl = UnitLevel(unit)
    return lvl == -1 or lvl > UnitLevel('player') + 3
end

function c.UnitInGroup(unit)
    return UnitInRaid(unit) or UnitInParty(unit)
end

function c.UnitIsTank(unit)
    unit = unit or 'player'
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return false
    end

    local _, class = UnitClass(unit)
    if not class then
        return false
    end

    if class == "WARRIOR" then
        return c.bHasAuraByID(unit, 71) -- Defensive Stance
    end
    if class == "PALADIN" then
        return c.bHasAuraByID(unit, 25780) -- Righteous Fury
    end
    if class == "DRUID" then
        return c.bHasAuraByID(unit, 5487) or
            c.bHasAuraByID(unit, 9634) -- Bear Form (или 9634 для Dire Bear, но в 3.3.5a обычно 5487)
    end
    if class == "DEATHKNIGHT" then
        return c.bHasAuraByID(unit, 48263) -- Frost Presence
    end

    return false
end

local immuneList = { 'Божественный щит', 'Ледяная глыба', 'Сдерживание' }
function c.UnitIsImmune(unit)
    unit = unit or 'target'
    local aura = c.HasBuff(immuneList, unit)
    if aura then
        return aura
    end
    aura = c.HasDebuff('Смерч', unit)
    return aura and aura or false
end

local magicList = { 'Отражение заклинания', 'Антимагический панцирь', 'Рунический покров', 'Эффект тотема заземления' }
function c.UnitIsMagicImmune(unit)
    unit = unit or 'target'
    local aura = c.HasBuff(magicList, unit)
    return aura and aura or false
end

function c.HasTalent(talent)
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
