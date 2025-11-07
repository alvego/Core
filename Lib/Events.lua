-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local tinsert = tinsert
local type = type
local error = error
local GetTime = GetTime
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
local function onEvent(self, event, ...)
    if eventList[event] ~= nil then
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
function c.SkipNextUpdate()
    skipNextUpdate = true
end

-------------------------------------------------------------------------------
c.TimerStart('CheckExtended')
-- Выполняем обработчики события OnUpdate
local function onUpdate()
    if c.TimerLess('UPDATE', 0.2) then
        return
    end

    if c.TimerMore('CheckExtended', 5) and c.IsNeedEnableExtended() then
        c.Echo('Enable Extended Func!', 'Warning')
        c.TimerStart('CheckExtended')
    end
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
