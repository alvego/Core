------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local tinsert = tinsert
-- Инициализация скрытого фрейма для обработки событий
local frame = CreateFrame("Frame", name .. "Events", UIParent)
------------------------------------------------------------------------------------------------------------------
-- Список событие -> обработчики
local eventList = {}
function ns.AttachEvent(event, func)
    if type(func) ~= 'function' then error("Wrong type") end
    local funcList = eventList[event]
    if nil == funcList then
        funcList = {}
        -- attach events
        frame:RegisterEvent(event)
    end
    tinsert(funcList, func)
    eventList[event] = funcList
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики соответсвующего события
local function onEvent(self, event, ...)
    if eventList[event] ~= nil then
        local funcList = eventList[event]

        for i = 1, #funcList do
            funcList[i](event, ...)
        end
    end
end
frame:SetScript("OnEvent", onEvent)

------------------------------------------------------------------------------------------------------------------
local listBeforeIdle = {}
function ns.AttachBeforeIdle(func)
    if type(func) ~= 'function' then error("Wrong type") end
    tinsert(listBeforeIdle, func)
end
------------------------------------------------------------------------------------------------------------------
local listAfterIdle = {}
function ns.AttachAfterIdle(func)
    if type(func) ~= 'function' then error("Wrong type") end
    tinsert(listAfterIdle, func)
end
------------------------------------------------------------------------------------------------------------------
local busy = false -- we don't use ns.IsChnaged for speed reasons
local function lockedIdle()
    busy = true
    for i = 1, #listBeforeIdle do
        listBeforeIdle[i]()
    end
    if type(ns.Idle) == 'function' then ns.Idle() end
    for i = 1, #listAfterIdle do
        listAfterIdle[i]()
    end
    busy = false
end
------------------------------------------------------------------------------------------------------------------
local update = 1
-- Выполняем обработчики события OnUpdate
local function onUpdate(frame, elapsed)
    if busy then return end
    update = update + elapsed
    if update < 0.125 then return end -- ждем 1/8 sec
    update = 0
    lockedIdle();
end
frame:SetScript("OnUpdate", onUpdate)
------------------------------------------------------------------------------------------------------------------
