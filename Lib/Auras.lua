------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
local function matchBuff(buffName, name, debuffType, canStealOrPurge, spellId)
    if type(buffName) == 'number' then
        return spellId == buffName
    end
    if buffName == debuffType then
        return true --canStealOrPurge
    end
    return ns.StrContains(name, buffName)
end
------------------------------------------------------------------------------------------------------------------
local function matchBuffs(buffName, name, debuffType, canStealOrPurge, spellId)
    if type(buffName) == 'table' then
        for i = 1, #buffName do
            if matchBuff(buffName[i], name, debuffType, canStealOrPurge, spellId) then return true end
        end
        return false
    end
    return matchBuff(buffName, name, debuffType, canStealOrPurge, spellId)
end
------------------------------------------------------------------------------------------------------------------
function ns.HasBuff(buffName, unit, last, my, method)
    unit = unit or 'player'
    if buffName then
        if last == nil then
            last = ns.State.latency
        end
        if method == nil then
            method = UnitBuff
        end
        for i = 1, 40 do
            local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId = method(unit, i)
            if name ~= nil then
                local remaining =  expirationTime ~= 0 and (expirationTime - GetTime()) or 999
                if matchBuffs(buffName, name, debuffType, canStealOrPurge, spellId) and (remaining > last) and (not my or unitCaster == 'player') then
                    return name, remaining, count
                    --return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId
                end
            end
        end
    end
    return false, 0, 0, 0
end
------------------------------------------------------------------------------------------------------------------
function ns.HasMyBuff(buffName, unit, last)
    return ns.HasBuff(buffName, unit, last, true)
end
------------------------------------------------------------------------------------------------------------------
function ns.HasDebuff(buffName, unit, last, my)
    unit = unit or 'target'
    return ns.HasBuff(buffName, unit, last, my, UnitDebuff)
end
------------------------------------------------------------------------------------------------------------------
function ns.HasMyDebuff(buffName, unit, last)
    return ns.HasDebuff(buffName, unit, last, true)
end
------------------------------------------------------------------------------------------------------------------
