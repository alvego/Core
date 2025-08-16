------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetTime = GetTime
local wipe = wipe
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
            local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId =
                method(unit, i)
            if name ~= nil then
                local remaining = expirationTime ~= 0 and (expirationTime - GetTime()) or 999
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
local db = {}

local function updateDotes()
    -- Не чичтим если
    if ns.State.combatMode then return true end        -- в бою
    if ns.State.autoattack then return true end        -- автоатака
    if ns.State.attack then return true end            -- зажата атака
    if not ns.State.invalidTarget then return true end -- есть валидный таргет
    if (next(db) ~= nil) then
        -- Возвращаем все таблицы в пул перед очисткой db
        for guid, victim in pairs(db) do
            ns.TablePoolRelease(victim)
        end
        wipe(db)
    end
    return false
end
ns.AttachBeforeIdle(updateDotes)

local function addDotedTarget(guid, spell)
    local victim = db[guid]
    if not victim then
        victim = ns.TablePoolAcquire()
        db[guid] = victim
    end
    victim[spell] = true
end
------------------------------------------------------------------------------------------------------------------
local function removeDotedTarget(guid, spell)
    local victim = db[guid]
    if victim then
        victim[spell] = nil
    end
end
------------------------------------------------------------------------------------------------------------------
function ns.DotedTargetsCount(spell)
    local count = 0
    for k, victim in pairs(db) do
        if victim[spell] then count = count + 1 end
    end
    return count
end

local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    -- если есть смысл
    if not updateDotes() then return end
    -- Обрабатываем тошлько мои ауры
    if sourceGUID ~= ns.State.playerGUID then return end
    local spellName = select(2, ...)
    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then -- or subEvent == "SPELL_CAST_SUCCESS"
        addDotedTarget(destGUID, spellName)
    elseif subEvent == "SPELL_AURA_REMOVED" then
        removeDotedTarget(destGUID, spellName)
    end
end
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)
------------------------------------------------------------------------------------------------------------------
