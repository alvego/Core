------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local CHAT_NAME_TEMPLATE = CHAT_NAME_TEMPLATE
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local ChatFrame_RemoveAllChannels = ChatFrame_RemoveAllChannels
local FCF_SetWindowName = FCF_SetWindowName
local FCF_SetLocked = FCF_SetLocked
local FCF_SelectDockFrame = FCF_SelectDockFrame
local GetCVar = GetCVar
local format = format
------------------------------------------------------------------------------------------------------------------
-- Имя новой вкладки чата
local DEBUG_TAB_NAME = "Debug"


local function getDebugChatFrame()
    local debugChatFrame, tab
    -- Находим чат-фрейм с нашей вкладкой
    for i = 1, NUM_CHAT_WINDOWS do
        tab = _G["ChatFrame" .. i .. "Tab"]
        if tab and tab:GetText() == DEBUG_TAB_NAME then
            debugChatFrame = _G["ChatFrame" .. i]
            break
        end
    end
    return debugChatFrame, tab
end

-- Функция для управления видимостью вкладки
local function updateDebugTabVisibility(visible)
    local chatFrame, tab = getDebugChatFrame()

    if chatFrame then
        if tab:IsShown() then
            if not visible then
                if chatFrame.isDocked and chatFrame:IsShown() then
                    local firstChatFrame = _G["ChatFrame1"]
                    if firstChatFrame then
                        FCF_SelectDockFrame(firstChatFrame)
                    end
                end
                chatFrame:Hide()
                tab:Hide()
            end
        elseif visible then
            tab:Show()
            if chatFrame.isDocked then
                FCF_SelectDockFrame(chatFrame)
            else
                chatFrame:Show()
            end
        end
    end
end
ns.AttachUpdateDebugState(updateDebugTabVisibility)


local function getFreeChatIndex()
    local frame, tab
    for i = 1, NUM_CHAT_WINDOWS do
        frame = _G["ChatFrame" .. i]
        tab = _G["ChatFrame" .. i .. "Tab"]
        -- Проверяем, что фрейм не используется (нет имени вкладки или вкладка скрыта и не настроена)

        if frame and tab and not tab:IsShown() and not frame:IsShown() then --and tab:GetText() == format(CHAT_NAME_TEMPLATE, i)
            return frame, tab
        end
    end
    return nil
end

local function configureDebugChatFrame(chatFrame)
    -- Настраиваем чат-фрейм
    if not chatFrame then
        ns.Chat('Debug: chatFrame is nil!', 'FF0000')
        return
    end
    -- Устанавливаем имя вкладки
    FCF_SetWindowName(chatFrame, DEBUG_TAB_NAME)

    -- Отключаем стандартные каналы чата
    ChatFrame_RemoveAllMessageGroups(chatFrame)
    ChatFrame_RemoveAllChannels(chatFrame)

    -- Включаем стандартное поведение для открепления и перемещения
    FCF_SetLocked(chatFrame, false) -- Разблокируем окно для перемещения
    chatFrame:SetMovable(true)
    chatFrame:SetResizable(true)
end

-- Функция для создания вкладки чата
local function createDebugChatTab()
    -- Проверяем, не существует ли уже вкладка с именем "Debug"
    local chatFrame = getDebugChatFrame()
    if chatFrame then return end -- уже есть

    -- Находим свободный чат-фрейм, который не используется
    chatFrame = getFreeChatIndex()
    if not chatFrame then
        ns.Chat("Нет свободных чат-фреймов для создания вкладки Debug! Закройте или удалите существующие вкладки.",
            'FF0000')
        return
    end
    print(1, chatFrame == nil)
    configureDebugChatFrame(chatFrame)
end
ns.AttachEvent("PLAYER_LOGIN", createDebugChatTab)

------------------------------------------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений
function ns.DebugChat(msg, hex)
    if not ns.Debug then return end
    if msg == nil then return end
    local chatFrame = getDebugChatFrame()
    if not chatFrame then return end
    local r, g, b = ns.Hex2Rgb(hex or '88FF88')
    chatFrame:AddMessage(msg, r, g, b)
end

------------------------------------------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений  без спама
function ns.DebugChatNoSpam(msg, hex)
    if not ns.IsChanged('ns.DebugChatNoSpam', msg .. hex) then
        return
    end
    ns.DebugChat(msg, hex)
end

------------------------------------------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений без частого спама
function ns.Log(...)
    local log = ns.ToStr(...)
    if not ns.IsChanged('ns.Log', log) and ns.TimerLess('ns.Log', 1) then
        return
    end
    ns.TimerStart('ns.Log')
    ns.DebugChat(format('[%s]: %s', ns.GetCurrentTime(), log), '0066AA')
end

------------------------------------------------------------------------------------------------------------------
-- Функция для вывода сообщений об ошибках без спама
function ns.Error(...)
    local error = ns.ToStr(...)
    if not ns.IsChanged('ns.Error', error) then return end
    ns.DebugChat('Ошибка: ' .. error, 'FF0000')
end

------------------------------------------------------------------------------------------------------------------
function ns.Chat(msg, hexColor)
    if msg == nil then return end
    hexColor = hexColor or '88FF88'
    local key = 'ns.Chat:' .. hexColor
    if not ns.IsChanged(key, msg) and ns.TimerLess(key, 2) then return end
    local r, g, b = ns.Hex2Rgb(hexColor)
    DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b);
    ns.TimerStart(key)
end

------------------------------------------------------------------------------------------------------------------
function ns.Echo(msg) -- Показ сообщения в UIErrorsFrame
    if msg == nil then return end
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end

------------------------------------------------------------------------------------------------------------------
