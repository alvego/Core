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
local GetCVar = GetCVar
local format = format
------------------------------------------------------------------------------------------------------------------
local cache = {}
function ns.Chat(msg, hexColor)
    hexColor = hexColor or '88FF88'
    local timerName = 'chat' .. hexColor
    if cache[timerName] == msg and ns.TimerLess(timerName, 2) then return end
    local r, g, b = ns.Hex2Rgb(hexColor)
    DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b);
    ns.TimerStart(timerName)
    cache[timerName] = msg
end

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

-- Функция для вывода отладочных сообщений
function ns.DebugChat(msg, hex)
    if not ns.State.debug then
        return
    end

    local chatFrame = getDebugChatFrame()
    if not chatFrame then return end
    local r, g, b = ns.Hex2Rgb(hex or '88FF88')
    chatFrame:AddMessage(msg, r, g, b)
end

-- Функция для вывода отладочных сообщений  без спама
local last = nil
function ns.DebugChatNoSpam(msg, hex)
    local current = msg .. hex
    if last == current then
        return
    end
    last = current
    ns.DebugChat(msg, hex)
end

-- Функция для управления видимостью вкладки
local function updateDebugTabVisibility()
    local showErrors = GetCVar("scriptErrors") == "1"
    local chatFrame, tab = getDebugChatFrame()

    if chatFrame then
        if tab:IsShown() then
            if not showErrors then
                if chatFrame.isDocked and chatFrame:IsShown() then
                    local firstChatFrame = _G["ChatFrame1"]
                    if firstChatFrame then
                        FCF_SelectDockFrame(firstChatFrame)
                    end
                end
                chatFrame:Hide()
                tab:Hide()
            end
        elseif showErrors then
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
    local chatFrameIndex
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        local tab = _G["ChatFrame" .. i .. "Tab"]
        -- Проверяем, что фрейм не используется (нет имени вкладки или вкладка скрыта и не настроена)
        if frame and tab and tab:GetText() == format(CHAT_NAME_TEMPLATE, i) and not frame:IsShown() then
            chatFrameIndex = i
            break
        end
    end
    return chatFrameIndex
end

local function configureDebugChatFrame(chatFrameIndex)
    if not chatFrameIndex then return end
    -- Настраиваем чат-фрейм
    local chatFrame = _G["ChatFrame" .. chatFrameIndex]

    if chatFrame then return end
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
local function CreateDebugChatTab()
    -- Проверяем, не существует ли уже вкладка с именем "Debug"
    local chatFrame = getDebugChatFrame()
    if chatFrame then
        updateDebugTabVisibility()
        return
    end

    -- Находим свободный чат-фрейм, который не используется
    local chatFrameIndex = getFreeChatIndex()
    if not chatFrameIndex then
        ns.Chat("Нет свободных чат-фреймов для создания вкладки Debug! Закройте или удалите существующие вкладки.",
            'FF0000')
        return
    end
    configureDebugChatFrame(chatFrameIndex)

    -- Обновляем видимость вкладки на основе scriptErrors
    updateDebugTabVisibility()

    --print("Отладочная вкладка '" .. DEBUG_TAB_NAME .. "' создана в ChatFrame" .. chatFrameIndex .. "!")
end
ns.AttachEvent("PLAYER_LOGIN", CreateDebugChatTab)


-- Пример использования
--ns.DebugMsg("Тестовое отладочное сообщение!", 1, 1, 0)
