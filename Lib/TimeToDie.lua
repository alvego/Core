---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local GetTime = GetTime
local bit = bit
local wipe = wipe
local next = next
local select = select
local pairs = pairs
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local math_max = math.max
local COMBATLOG_OBJECT_TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
-- luacheck: pop
local db = {}

local function needUpdateUnits()
    if st.combatMode then return true end        -- в бою
    if st.autoattack then return true end        -- автоатака
    if st.attack then return true end            -- зажата атака
    if not st.invalidTarget then return true end -- есть валидный target
    return false
end

local function clearUnits()
    -- Не очищаем если нужно обновлять
    if needUpdateUnits() then return end
    if (next(db) ~= nil) then
        -- Возвращаем все таблицы в пул перед очисткой db
        for _, unitInfo in pairs(db) do
            c.TablePoolRelease(unitInfo)
        end
        wipe(db)
    end
end
c.BeforeUpdate(clearUnits)

local function updateUnit(guid, amount)
    -- Берем по GUID, запоминаем начало боя и суммируем весь входящий в target урон, потом делим на время с начала
    local unitInfo = db[guid]
    if not unitInfo then
        unitInfo = c.TablePoolAcquire()
        unitInfo.amount = amount
        unitInfo.startTime = GetTime()
        db[guid] = unitInfo
    else
        unitInfo.amount = unitInfo.amount + amount
    end
end

local function killUnit(guid)
    local unitInfo = db[guid]
    if unitInfo then
        c.TablePoolRelease(unitInfo)
        db[guid] = nil
    end
end

local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    -- Какое-то время уже не в бою
    if not needUpdateUnits() then return end

    -- Источник события - неодушевленный объект, ловушка, тотем, пропускаем
    if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_OBJECT) ~= 0 then return end
    -- фильтр для игнорирования событий с участием союзников, чтобы фокусировался на боевых действиях против врагов.
    if bit.band(sourceFlags, destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 then return end

    local amount
    if subEvent == 'SWING_DAMAGE' then
        amount = select(1, ...)
        updateUnit(destGUID, amount)
    elseif subEvent == 'SPELL_DAMAGE' or subEvent == 'RANGE_DAMAGE' or subEvent == 'SPELL_PERIODIC_DAMAGE' then
        amount = select(4, ...)
        updateUnit(destGUID, amount)
    elseif subEvent == 'UNIT_DIED' then
        killUnit(destGUID)
    end
end
c.Event('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)


function c.UnitTimeToDie(unit)
    unit = unit and unit or 'target'
    local guid = UnitGUID(unit)
    if not guid then return nil end
    local unitInfo = db[guid]
    if not unitInfo then return nil end
    return UnitHealth(unit) / (unitInfo.amount / math_max(GetTime() - unitInfo.startTime, 2))
end
