---@class Core
local c = Core
---@class Core.state
local st = c.state

local wipe = wipe
local select = select
local pairs = pairs
local next = next
local db = {}

local function needUpdateDotes()
    if st.combatMode then return true end        -- в бою
    if st.autoattack then return true end        -- автоатака
    if st.attack then return true end            -- зажата атака
    if not st.invalidTarget then return true end -- есть валидный таргет
    return false
end


local function updateDotes()
    -- Не чичтим если нужно обновлять
    if needUpdateDotes() then return end
    if (next(db) ~= nil) then
        -- Возвращаем все таблицы в пул перед очисткой db
        for _, dotes in pairs(db) do
            c.TablePoolRelease(dotes)
        end
        wipe(db)
    end
end
c.BeforeUpdate(updateDotes)


local function addDotedUnit(guid, spell)
    local dotes = db[guid]
    if not dotes then
        dotes = c.TablePoolAcquire()
        db[guid] = dotes
    end
    dotes[spell] = dotes
end

-----------------------------------
local function removeDotedUnit(guid, spell)
    local dotes = db[guid]
    if dotes then
        dotes[spell] = nil
    end
end

-----------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    -- если есть смысл
    if not needUpdateDotes() then return end
    -- Обрабатываем только мои ауры
    if sourceGUID ~= st.playerGUID then return end
    local spellName = select(2, ...)
    if subEvent == 'SPELL_AURA_APPLIED' or subEvent == 'SPELL_AURA_REFRESH' then
        addDotedUnit(destGUID, spellName)
    elseif subEvent == 'SPELL_AURA_REMOVED' then
        removeDotedUnit(destGUID, spellName)
    end
end
c.Event('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)

-----------------------------------
function c.DotedUnitCount(spell) -- Count of units with my dote <spell>
    local count = 0
    for _, dotes in pairs(db) do
        if dotes[spell] then count = count + 1 end
    end
    return count
end

-----------------------------------
