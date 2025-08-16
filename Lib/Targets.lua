------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
local bit = bit
local wipe = wipe
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth

local COMBATLOG_OBJECT_TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
------------------------------------------------------------------------------------------------------------------
local db = {}

local function updateTargets()
    -- Не чичтим если
    if ns.State.combatMode then return true end        -- в бою
    if ns.State.autoattack then return true end        -- автоатака
    if ns.State.attack then return true end            -- зажата атака
    if not ns.State.invalidTarget then return true end -- есть валидный таргет
    if (next(db) ~= nil) then
        -- Возвращаем все таблицы в пул перед очисткой db
        for guid, victim in pairs(db) do
            ns.TablePoolRelease(victim.attackers)
            ns.TablePoolRelease(victim)
        end
        wipe(db)
    end
    return false
end
ns.AttachBeforeIdle(updateTargets)
------------------------------------------------------------------------------------------------------------------
local function updateVictim(srcGuid, guid, amount)
    -- Берем по гуиду, запоминаем начало боя и суммируем весь входящий в таргет урон, потом делим на время с начала
    local victim = db[guid]
    if not victim then
        victim = ns.TablePoolAcquire()
        victim.amount = amount
        victim.startTime = GetTime()
        victim.attackers = ns.TablePoolAcquire()
        db[guid] = victim
    else
        victim.amount = victim.amount + amount
    end
    victim.attackers[srcGuid] = GetTime()
end
------------------------------------------------------------------------------------------------------------------
local function killVictim(guid)
    local victim = db[guid]
    if victim then
        -- забиваем всех, кто бил моба
        ns.TablePoolRelease(victim.attackers)
        ns.TablePoolRelease(victim)
        db[guid] = nil
    end
    -- и всех, кого бил мобa
    for _, v in pairs(db) do
        v.attackers[guid] = nil
    end
end
------------------------------------------------------------------------------------------------------------------
local function OnCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    -- Какое-то время уже не в бою
    if not updateTargets() then return end

    -- Источник события - неодушевленный объект, ловушка, тотем, пропускаем
    if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_OBJECT) ~= 0 then return end
    -- фильтр для игнорирования событий с участием союзников, чтобы фокусировался на боевых действиях против врагов.
    if bit.band(sourceFlags, destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 then return end

    local amount
    if subEvent == "SWING_DAMAGE" then
        amount = select(1, ...)
        updateVictim(sourceGUID, destGUID, amount)
    elseif subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" then
        amount = select(4, ...)
        updateVictim(sourceGUID, destGUID, amount)
    elseif subEvent == "SPELL_MISSED" or subEvent == "RANGE_MISSED" or
        subEvent == "SWING_MISSED" or subEvent == "SPELL_PERIODIC_MISSED" then
        updateVictim(sourceGUID, destGUID, 0)
    elseif subEvent == "UNIT_DIED" or subEvent == "PARTY_KILL" then
        killVictim(destGUID)
    end
end
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', OnCombatLogEvent)
------------------------------------------------------------------------------------------------------------------
local uniqueTargets = {}
function ns.GetNumTargets(unit)
    unit = unit and unit or "targettarget"
    local guid = UnitGUID(unit)             -- скорее всего я, или танк
    local victim = guid and db[guid] or nil -- инфо о подвергнувшимся нападению


    -- проверка на target
    if not ns.State.invalidTarget then
        uniqueTargets[UnitGUID('target')] = true
    end

    -- т.к. нам надо считать и тех, кто атакует цель цели и тех, кого я, то сначала запоминаем гуиды, а потом делаем дистинкт
    if victim then                             -- считаем кто бьем меня или танка
        for attackerGuid, attackTime in pairs(victim.attackers) do
            if GetTime() - attackTime < 5 then -- стукнули менее 5 секунд назад
                uniqueTargets[attackerGuid] = true
            end
        end
    end

    -- бежим по всем
    for g, vict in pairs(db) do
        for attackerGuid, attackTime in pairs(vict.attackers) do -- ищем тех, кого бью я
            if attackerGuid == ns.State.playerGUID and GetTime() - attackTime < 8 then
                uniqueTargets[g] = true                          -- я ударил менее 8 секунд назад
            end
        end
    end

    local numTargets = 0
    for _ in pairs(uniqueTargets) do numTargets = numTargets + 1 end
    wipe(uniqueTargets)
    return numTargets
end

------------------------------------------------------------------------------------------------------------------
function ns.TimeToDie(unit)
    unit = unit and unit or "target"
    local guid = UnitGUID(unit)
    if not guid then return 0 end
    local enemy = db[guid]
    return enemy and UnitHealth(unit) / (enemy.amount / math.max(GetTime() - enemy.startTime, 2)) or 0
end

------------------------------------------------------------------------------------------------------------------
