-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local tinsert = tinsert
local tContains = tContains
local type = type
local error = error

-------------------------------------------------------------------------------
-- Инициализация скрытого фрейма для обработки событий
local frame = CreateFrame('Frame', c.name .. 'Events', UIParent)
-------------------------------------------------------------------------------
-- Список событие -> обработчики
local eventList = {}
function c.Event(event, func)
    if type(func) ~= 'function' then error('Wrong type') end
    local funcList = eventList[event]
    if nil == funcList then
        funcList = {}
        -- attach events
        frame:RegisterEvent(event)
    end
    tinsert(funcList, func)
    eventList[event] = funcList
end

-------------------------------------------------------------------------------
-- Выполняем обработчики соответствующего события

local unfiltredEvents = {
    'ADDON_LOADED',
    'PLAYER_ENTERING_WORLD',
    'PLAYER_LEAVING_WORLD'
}

local function onEvent(self, event, ...)
    if eventList[event] ~= nil and
        (c.IsLoaded() or tContains(unfiltredEvents, event)) then
        local funcList = eventList[event]
        for i = 1, #funcList do
            funcList[i](event, ...)
        end
    end
end
frame:SetScript('OnEvent', onEvent)

-------------------------------------------------------------------------------
local listNextTick = {}
function c.NextTick(func)
    if type(func) ~= 'function' then error('Wrong type') end
    if tContains(listNextTick, func) then return end
    tinsert(listNextTick, func)
end

local function callNextTick()
    local nextTickCount = #listNextTick
    if nextTickCount > 0 then
        for i = 1, nextTickCount do
            listNextTick[i]()
        end
        wipe(listNextTick)
    end
end

-------------------------------------------------------------------------------
local listBeforeUpdate = {}
function c.BeforeUpdate(func, important)
    if type(func) ~= 'function' then error('Wrong type') end
    listBeforeUpdate[func] = important or false
end

local listAfterUpdate = {}
function c.AfterUpdate(func, important)
    if type(func) ~= 'function' then error('Wrong type') end
    tinsert(listAfterUpdate, func)
    listAfterUpdate[func] = important or false
end

local function callUpdateList(list)
    for func, important in pairs(list) do
        if not c.busy or important then
            func()
        end
    end
end

-------------------------------------------------------------------------------

local skipNextUpdate = false -- skip next Update
function c.SkipNextUpdate()  -- пропустить вызов Update() в следующий тик
    skipNextUpdate = true
end

local immediatelyNextUpdate = false -- запустить следующий тик немедленно
function c.ImmediatelyNextUpdate()
    immediatelyNextUpdate = true
end

-------------------------------------------------------------------------------
-- Выполняем обработчики события OnUpdate
local timeGap = c.advance
local immediatelyTimer = 'immediatelyNextUpdate'
local updateTimer = 'Update'
local function onUpdate()
    callNextTick()

    -- осталось секунд до конца гкд или 0
    local gcdLeft = c.GetSpellCooldownLeft(c.gcdSpellId)
    if gcdLeft > 0 then
        -- гкд запущено
        if gcdLeft < (c.updateDelay + timeGap) then
            --осталось меньше такта

            if gcdLeft > timeGap then
                -- ничего не делаем, ждем конца гкд
                return
            end

            -- конец гкд, запускаем таймер немедленного обновления
            c.TimerStart(immediatelyTimer)
        else
            -- гкд успешно запущен, до его конца еще есть время, не частим
            -- стопаем таймер немедленного обновления
            c.TimerReset(immediatelyTimer)
        end
    end
    c.busy = false -- не занят
    if immediatelyNextUpdate or c.TimerLess(immediatelyTimer, timeGap) then
        c.TimerReset(updateTimer)
        immediatelyNextUpdate = false
        c.busy = true -- занят прожимом гкд спела, не используй лишней логики
    end

    -- не чаще нескольких раз в секунду
    if c.TimerLess(updateTimer, c.updateDelay) then return end

    if not c.IsLoaded() then return end

    c.CheckExtendedFunc()
    ----------------------------------------------------------------
    callUpdateList(listBeforeUpdate)
    ----------------------------------------------------------------
    if not (skipNextUpdate or c.Paused()) and type(c.Update) == 'function' then
        -- print(
        --     c.TelemetryBool('gcd', gcdLeft > 0),
        --     c.TelemetryBool('imm', c.TimerLess(immediatelyTimer, timeGap)),
        --     c.TelemetryBool('busy', c.busy),
        --     'interval:', c.Round(c.TimerElapsed('test'), 3)
        -- )
        -- c.TimerStart('test')
        c.Update()
    end
    skipNextUpdate = false
    ----------------------------------------------------------------
    callUpdateList(listAfterUpdate)
    ----------------------------------------------------------------
    c.TimerStart(updateTimer) -- Обновляем таймер после вызова (плюс время выполнения)
end
frame:SetScript('OnUpdate', onUpdate)
-------------------------------------------------------------------------------
