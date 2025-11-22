-------------------------------------------------------------------------------
-- By by Unknown Coder
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
function c.AttachEvent(event, func)
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
-- Выполняем обработчики соответсвующего события

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
local listBeforeUpdate = {}
function c.AttachBeforeUpdate(func)
    if type(func) ~= 'function' then error('Wrong type') end
    tinsert(listBeforeUpdate, func)
end

-------------------------------------------------------------------------------
local listAfterUpdate = {}
function c.AttachAfterUpdate(func)
    if type(func) ~= 'function' then error('Wrong type') end
    tinsert(listAfterUpdate, func)
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
local function onUpdate()
    if immediatelyNextUpdate then
        c.TimerReset('UPDATE')
        immediatelyNextUpdate = false
        return
    end
    -- не чаще 5 раз в секунду
    if c.TimerLess('UPDATE', 0.33) then return end

    if not c.IsLoaded() then return end

    c.CheckExtendedFunc()
    ----------------------------------------------------------------
    for i = 1, #listBeforeUpdate do
        listBeforeUpdate[i]()
    end
    ----------------------------------------------------------------
    if not (skipNextUpdate or c.Paused()) and type(c.Update) == 'function' then
        c.Update()
    end
    skipNextUpdate = false
    ----------------------------------------------------------------
    for i = 1, #listAfterUpdate do
        listAfterUpdate[i]()
    end
    ----------------------------------------------------------------
    c.TimerStart('UPDATE') -- Обновляем таймер после вызова (плюс время выполнения)
end
frame:SetScript('OnUpdate', onUpdate)
-------------------------------------------------------------------------------
