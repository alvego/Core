---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local GetTime = GetTime
local UnitName = UnitName
local GetFramerate = GetFramerate
local format = format
local print = print
local select = select
local strlower = strlower
local strtrim = strtrim
local tinsert = tinsert
local tremove = tremove
local wipe = wipe
-- luacheck: pop

local VERSION = 1         -- версия протокола записи
local MAX_RECORDS = 20000 -- жёсткий кап записей на сессию
local MAX_SESSIONS = 5    -- сколько последних сессий хранить в дампе

local active = false   -- идёт ли запись прямо сейчас
local records = nil    -- буфер текущей сессии (массив позиционных записей { t, kind, ... })
local session = nil    -- текущая сессия { t0, t1, meta, records }
local lastReason = nil -- предыдущий reason для дедупа R-канала

-- форвард-декларация: буфер может сам остановить запись по капу
local stopRecording

---Доступ к хранилищу дампа в SavedVariables (создаёт при отсутствии)
---@return table? s { version, sessions }
local function store()
    local db = c.db
    if not db then return nil end
    local s = db.recorder
    if not s then
        s = { version = VERSION, sessions = {} }
        db.recorder = s
    end
    if not s.sessions then
        s.sessions = {}
    end
    return s
end

---Добавить запись в буфер текущей сессии.
---Гвард первой строкой обязателен: хендлеры событий дёргаются всегда (даже при
---выключенной записи), а Events.onEvent зовёт их без pcall — падение здесь
---оборвёт доставку событий соседним подписчикам (например, SpellError)
---@param record table позиционная запись { t, kind, ... }
local function push(record)
    if not active then return end
    local n = #records + 1
    records[n] = record
    if n >= MAX_RECORDS then
        stopRecording('cap')
    end
end

-------------------------------------------------------------------------------
-- Публичное API (заполнение каналов)
-------------------------------------------------------------------------------

---Единая точка записи нажатий.
---При выключенной записи — пустышка (одна проверка, оверхеда нет).
---Имя спелла резолвит вызывающий (Bridge): при выключенной записи
---GetActionSpell и прочие аллокации не должны выполняться вовсе
---@param spellName? string имя спелла (может быть nil)
---@param slot? number|string слот действия (nil для канала прямых спеллов)
---@param unitID? UnitToken цель нажатия
---@param source? string источник нажатия: 'rotation'|'manual'|'spell'|'unknown'
---@param reason? string reason ротации, если известен
function c.RecordPress(spellName, slot, unitID, source, reason)
    if not active then return end
    -- P press: t, спелл, слот, цель, источник, reason, гкд, остаток гкд, лаг, FPS
    push {
        GetTime(), 'P',
        spellName,
        slot,
        unitID,
        source,
        reason,
        st.gcd,
        c.GetSpellCooldownLeft(c.gcdSpellId),
        c.latency,
        GetFramerate(),
    }
end

---Запись решения ротации: только при смене reason относительно предыдущего
---@param reason? string reason ротации (nil допустим)
function c.RecordDecision(reason)
    if not active or reason == lastReason then return end
    lastReason = reason
    -- R decision: t, reason
    push { GetTime(), 'R', reason }
end

---Идёт ли запись
---@return boolean
function c.RecorderActive()
    return active
end

-------------------------------------------------------------------------------
-- Подписки на события (свои каналы, SpellError не трогаем)
-------------------------------------------------------------------------------

---A ack: подтверждения стадий каста (только player)
local function onSpellcast(event, unitID, spellName)
    if unitID ~= 'player' then return end
    -- A ack: t, event, spellName
    push { GetTime(), 'A', event, spellName }
end
c.Event('UNIT_SPELLCAST_SUCCEEDED', onSpellcast)
c.Event('UNIT_SPELLCAST_START', onSpellcast)
c.Event('UNIT_SPELLCAST_FAILED', onSpellcast)
c.Event('UNIT_SPELLCAST_INTERRUPTED', onSpellcast)
c.Event('UNIT_SPELLCAST_CHANNEL_START', onSpellcast)
c.Event('UNIT_SPELLCAST_CHANNEL_STOP', onSpellcast)

---C ack: подтверждения из боевого лога (только свои касты)
local function onCombatLog(event, timestamp, subEvent, sourceGUID, ...)
    if sourceGUID ~= st.playerGUID then return end
    if subEvent == 'SPELL_CAST_SUCCESS' or subEvent == 'SPELL_CAST_FAILED' then
        -- C ack: t, CLEU-timestamp, subEvent, spellName
        -- (в хвосте vararg: sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
        push { GetTime(), 'C', timestamp, subEvent, select(7, ...) }
    end
end
c.Event('COMBAT_LOG_EVENT_UNFILTERED', onCombatLog)

---E error: ВСЕ тексты ошибок, включая skip-лист SpellError (фильтрация запрещена)
local function onUIError(event, message)
    -- E error: t, сырой текст ошибки
    push { GetTime(), 'E', message }
end
c.Event('UI_ERROR_MESSAGE', onUIError)

-------------------------------------------------------------------------------
-- Управление: /drdrec [on|off|status|clear|dump], без аргумента — toggle
-------------------------------------------------------------------------------

---Начать запись новой сессии.
---Сессия сразу регистрируется живой ссылкой в c.db.recorder.sessions: дописи идут
---в неё же, WoW сериализует CoreDB на выходе — автодамп-события не нужны, а
---лоадскрины (портал в рейде) сессию не убивают
---@return boolean started
local function startRecording()
    if active then return false end
    local s = store()
    if not s then return false end
    active = true
    lastReason = nil
    records = {}
    session = {
        t0 = GetTime(),
        t1 = nil,
        meta = { UnitName('player'), VERSION },
        records = records,
    }
    tinsert(s.sessions, session)
    while #s.sessions > MAX_SESSIONS do
        tremove(s.sessions, 1)
    end
    -- M meta: t, имя игрока, версия протокола (дубль session.meta для парсера)
    push { GetTime(), 'M', UnitName('player'), VERSION }
    c.Message('запись начата', 'Recorder')
    return true
end

---Остановить запись (сессия уже лежит в дампе — финализируем t1 на месте)
---@param reason string причина остановки ('manual'|'cap'), только для сообщения
---@return boolean stopped
function stopRecording(reason)
    if not active then return false end
    active = false
    local count = records and #records or 0
    if session then
        session.t1 = GetTime()
    end
    session = nil
    records = nil
    lastReason = nil
    c.Message(format('запись остановлена (%s): записей %d', tostring(reason), count), 'Recorder')
    return true
end

SLASH_DRDREC1 = '/drdrec'
SlashCmdList['DRDREC'] = function(msg)
    msg = strtrim(strlower(msg or ''))
    local prefix = '|cffffd100DrDamage:|r '

    if msg == 'on' then
        if active then
            print(prefix .. 'запись уже идёт')
        elseif startRecording() then
            -- сообщение о старте ушло через c.Message
        else
            print(prefix .. 'не удалось начать запись (c.db недоступна)')
        end

    elseif msg == 'off' then
        if not stopRecording('manual') then
            print(prefix .. 'запись не активна')
        end

    elseif msg == 'status' then
        local s = store()
        local sessions = s and s.sessions
        print(format(prefix .. 'активна: %s, записей в буфере: %d, сессий в дампе: %d',
            active and 'да' or 'нет', records and #records or 0, sessions and #sessions or 0))

    elseif msg == 'clear' then
        if active then
            -- активная сессия живёт в дампе; гасим её, чтобы не потерять ссылку
            stopRecording('manual')
        end
        local s = store()
        if s then
            wipe(s.sessions)
        end
        print(prefix .. 'дамп очищен')

    elseif msg == 'dump' then
        if active then
            -- не новая сессия: просто обновляем t1, WoW сохранит состояние на выходе
            session.t1 = GetTime()
            local s = store()
            print(format(prefix .. 'дамп актуален: записей %d, сессий в дампе: %d',
                #records, s and #s.sessions or 0))
        else
            print(prefix .. 'запись не активна')
        end

    else -- toggle
        if active then
            stopRecording('manual')
        else
            startRecording()
        end
    end
end
