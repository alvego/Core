-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local ChatFrame_RemoveAllChannels = ChatFrame_RemoveAllChannels
local FCF_SetWindowName = FCF_SetWindowName
local FCF_SetLocked = FCF_SetLocked
local FCF_SelectDockFrame = FCF_SelectDockFrame
local format = format
local tostring = tostring
local YELLOW_FONT_COLOR = YELLOW_FONT_COLOR
local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local GREEN_FONT_COLOR = GREEN_FONT_COLOR
local ORANGE_FONT_COLOR = ORANGE_FONT_COLOR
-------------------------------------------------------------------------------
-- Функция для получения текущего активного чата
local function getDebugChatFrame()
    local debugChatFrame, tab
    -- Находим чат-фрейм с нашей вкладкой
    for i = 1, NUM_CHAT_WINDOWS do
        tab = _G['ChatFrame' .. i .. 'Tab']
        if tab and tab:GetText() == c.name then
            debugChatFrame = _G['ChatFrame' .. i]
            break
        end
    end
    return debugChatFrame, tab
end
-------------------------------------------------------------------------------
-- Функция для управления видимостью вкладки
local function updateDebugTabVisibility(visible)
    local chatFrame, tab = getDebugChatFrame()

    if chatFrame then
        if tab:IsShown() then
            if not visible then
                if chatFrame.isDocked and chatFrame:IsShown() then
                    local firstChatFrame = _G['ChatFrame1']
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
c.AttachUpdateDebugState(updateDebugTabVisibility)


-------------------------------------------------------------------------------
local function renederDebugTab()
    updateDebugTabVisibility(c.Debug())
end
c.AttachEvent('PLAYER_ENTERING_WORLD', renederDebugTab)
-------------------------------------------------------------------------------
-- Функция для получения свободного чат-фрейма
local function getFreeChatIndex()
    local frame, tab
    for i = 1, NUM_CHAT_WINDOWS do
        frame = _G['ChatFrame' .. i]
        tab = _G['ChatFrame' .. i .. 'Tab']
        -- Проверяем, что фрейм не используется (нет имени вкладки или вкладка скрыта и не настроена)

        if frame and tab and not tab:IsShown() and not frame:IsShown() then
            return frame, tab
        end
    end
    return nil
end
-------------------------------------------------------------------------------
-- Настройка чат-фрейма
local function configureDebugChatFrame(chatFrame)
    -- Настраиваем чат-фрейм
    if not chatFrame then
        c.Chat('Debug: chatFrame is nil!')
        return
    end
    -- Устанавливаем имя вкладки
    FCF_SetWindowName(chatFrame, c.name)

    -- Отключаем стандартные каналы чата
    ChatFrame_RemoveAllMessageGroups(chatFrame)
    ChatFrame_RemoveAllChannels(chatFrame)

    -- Включаем стандартное поведение для открепления и перемещения
    FCF_SetLocked(chatFrame, false) -- Разблокируем окно для перемещения
    chatFrame:SetMovable(true)
    chatFrame:SetResizable(true)
end

-------------------------------------------------------------------------------
-- Функция для создания вкладки чата
local function createDebugChatTab()
    -- Проверяем, не существует ли уже вкладка с именем 'Debug'
    local chatFrame = getDebugChatFrame()
    if chatFrame then return end -- уже есть

    -- Находим свободный чат-фрейм, который не используется
    chatFrame = getFreeChatIndex()
    if not chatFrame then
        c.Chat('Нет свободных чат-фреймов для создания вкладки Debug! Закройте или удалите существующие вкладки.')
        return
    end
    configureDebugChatFrame(chatFrame)
end
c.AttachEvent('PLAYER_LOGIN', createDebugChatTab)

-------------------------------------------------------------------------------
local iconSuccess = 'Interface\\Icons\\ability_vehicle_shellshieldgenerator_green'
local iconLog = 'Interface\\Icons\\ability_vehicle_shellshieldgenerator_s_black'
local iconError = 'Interface\\Icons\\ability_vehicle_shellshieldgenerator_s_red'
local iconEcho = 'Interface\\Icons\\ability_vehicle_shellshieldgenerator_s_orange'
local iconMessage = 'Interface\\Icons\\Ability_Vehicle_ShellShieldGenerator'

local function formatIcon(icon)
    return icon and '|T' .. icon .. ':24:24:0:0|t' or '       '
end

local function formatMessage(icon, label, msg)
    return format('%s [%s] %s', formatIcon(icon), label or '...', msg or '???')
end

-------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений
local function debugChat(msg, title, icon, r, g, b)
    if not c.Debug() then return end
    if msg == nil then return end
    local chatFrame = getDebugChatFrame()
    if not chatFrame then
        chatFrame = DEFAULT_CHAT_FRAME --failback
    end
    chatFrame:AddMessage(
        formatMessage(
            icon or iconMessage,
            title or c.name,
            msg
        ),
        r or YELLOW_FONT_COLOR.r,
        g or YELLOW_FONT_COLOR.g,
        b or YELLOW_FONT_COLOR.b
    )
end

-------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений  без спама
function c.Message(msg, title, icon, r, g, b)
    msg = tostring(msg)
    title = tostring(title)
    if not c.showNoneReason and string.sub(msg, 1, 1) == '#' then
        return -- игнорируем комментарии
    end
    if not c.IsChanged('Message', msg .. title) then
        return
    end
    debugChat(msg, title, icon, r, g, b)
end

-------------------------------------------------------------------------------
function c.MessageLog(msg, title, icon, r, g, b)
    c.Message(
        msg,
        title or c.GetCurrentTime(),
        icon or iconLog,
        r or GRAY_FONT_COLOR.r,
        g or GRAY_FONT_COLOR.g,
        b or GRAY_FONT_COLOR.b
    )
end

-------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений без частого спама с указанием времени
local times = 0
function c.Log(...)
    local log = c.ToStr(...)
    if not c.IsChanged('Log', log) and c.TimerLess('Log', 1) then
        times = times + 1
        return
    end
    c.TimerStart('Log')
    if times > 1 then
        log = log .. ' (' .. times .. ')'
    end
    times = 0
    debugChat(
        log,
        c.GetCurrentTime(),
        iconLog,
        GRAY_FONT_COLOR.r,
        GRAY_FONT_COLOR.g,
        GRAY_FONT_COLOR.b
    )
end

-------------------------------------------------------------------------------
-- Функция для вывода сообщений об ошибках без спама
function c.Error(msg, icon)
    if not c.IsChanged('Error', msg) then return end
    debugChat(
        msg,
        'Ошибка',
        icon or iconError,
        RED_FONT_COLOR.r,
        RED_FONT_COLOR.g,
        RED_FONT_COLOR.b
    )
end

-------------------------------------------------------------------------------
function c.Success(msg, icon)
    if not c.IsChanged('Succes', msg) then return end
    debugChat(
        msg,
        'Успех',
        icon or iconSuccess,
        GREEN_FONT_COLOR.r,
        GREEN_FONT_COLOR.g,
        GREEN_FONT_COLOR.b
    )
end

-------------------------------------------------------------------------------
-- Функция для вывода отладочных сообщений в общий чат
function c.Chat(msg)
    if msg == nil then return end
    msg = tostring(msg)
    local key = 'Chat:'
    if not c.IsChanged(key, msg) and c.TimerLess(key, 2) then return end
    DEFAULT_CHAT_FRAME:AddMessage(
        formatMessage(
            iconSuccess,
            c.name,
            msg
        ),
        GREEN_FONT_COLOR.r,
        GREEN_FONT_COLOR.g,
        GREEN_FONT_COLOR.b);
    c.TimerStart(key)
end

-------------------------------------------------------------------------------
-- Функция для вывода сообщений в центре экрана с затуханием (UIErrorsFrame)
function c.Echo(msg, title, icon, r, g, b) -- Показ сообщения в UIErrorsFrame
    if msg == nil then return end
    msg = tostring(msg)
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage(
        formatMessage(
            icon or iconEcho,
            title or c.name,
            msg
        ),
        r or ORANGE_FONT_COLOR.r,
        g or ORANGE_FONT_COLOR.g,
        b or ORANGE_FONT_COLOR.b,
        53,
        2
    );
end

UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
-------------------------------------------------------------------------------
function c.LogWhatHappend(msg, skipLogging)
    if not msg then
        c.Error('WhatHappend is "' .. tostring(msg) .. '"?!!')
        return
    end
    if not c.IsChanged('WhatHappend', msg) or skipLogging then return end
    c.MessageLog(msg)
end

-------------------------------------------------------------------------------
