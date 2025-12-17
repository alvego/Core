---@class Core
local c = Core

local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local ChatFrame_RemoveAllChannels = ChatFrame_RemoveAllChannels
local FCF_UnDockFrame = FCF_UnDockFrame
local FCF_DockFrame = FCF_DockFrame
local FCF_SetWindowName = FCF_SetWindowName
local FCF_SetLocked = FCF_SetLocked
local FCF_SelectDockFrame = FCF_SelectDockFrame
local IsControlKeyDown = IsControlKeyDown
local math_max = math.max
local format = format
local tostring = tostring
local YELLOW_FONT_COLOR = YELLOW_FONT_COLOR
local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local GREEN_FONT_COLOR = GREEN_FONT_COLOR
local ORANGE_FONT_COLOR = ORANGE_FONT_COLOR

local frame = CreateFrame('Frame', c.name .. 'WhatHappend', UIParent)
frame:ClearAllPoints()
frame:SetPoint("CENTER", UIParent, "TOP", 0, -5)
frame:SetHeight(10)
frame:SetWidth(10)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetFont([[Fonts\ARIALN.TTF]], 10) -- Альтернативный шрифт
frame.text:SetTextColor(0.8, 0.8, 0.8, 0.8)
frame.text:SetAllPoints()

-- очистка чата по Ctrl + LeftButton клик на табик
local FCF_Tab_OnClick = FCF_Tab_OnClick
_G.FCF_Tab_OnClick = function(self, button)
    local chatFrame = _G["ChatFrame" .. self:GetID()];
    if (IsControlKeyDown() == 1 and button == "LeftButton") then
        chatFrame:Clear()
        return
    end
    return FCF_Tab_OnClick(self, button)
end


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

-- очистка чата по началу боя
-- c.Event('PLAYER_REGEN_DISABLED', function()
--     local chatFrame, tab = getDebugChatFrame()
--     if not chatFrame then return end
--     chatFrame:Clear()
-- end)

local docked = true
local function toggleChatVisibility(visible)
    if visible then
        if not frame:IsVisible() then frame:Show() end
    else
        if frame:IsVisible() then frame:Hide() end
    end
    local chatFrame, tab = getDebugChatFrame()
    if chatFrame then
        if tab:IsShown() then
            if not visible then
                -- выбираем первую вкладку
                docked = chatFrame.isDocked
                if docked and chatFrame:IsShown() then
                    local firstChatFrame = _G['ChatFrame1']
                    if firstChatFrame then
                        FCF_SelectDockFrame(firstChatFrame)
                    end
                end

                -- окрепляем
                if docked then
                    FCF_UnDockFrame(chatFrame)
                end

                -- прячем
                chatFrame:Hide()
                tab:Hide()
            end
        elseif visible then
            tab:Show()
            if docked then
                FCF_DockFrame(chatFrame)
                FCF_SelectDockFrame(chatFrame)
            else
                chatFrame:Show()
            end
        end
    end
end
c.UpdateDebugState(toggleChatVisibility)


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
c.Event('PLAYER_LOGIN', createDebugChatTab)


local iconSuccess = [[Interface\Icons\ability_vehicle_shellshieldgenerator_green]]
local iconLog = [[Interface\Icons\ability_vehicle_shellshieldgenerator_s_black]]
local iconError = [[Interface\Icons\ability_vehicle_shellshieldgenerator_s_red]]
local iconEcho = [[Interface\Icons\ability_vehicle_shellshieldgenerator_s_orange]]
local iconMessage = [[Interface\Icons\Ability_Vehicle_ShellShieldGenerator]]

local function formatIcon(icon)
    return icon and '|T' .. icon .. ':24:24:0:0|t' or '       '
end

local function formatMessage(icon, label, msg)
    return format('%s [%s] %s', formatIcon(icon), label or '...', msg or '???')
end


-- Функция для вывода отладочных сообщений
local function debugChat(msg, title, icon, r, g, b)
    if msg == nil then return end
    local isCommented = string.sub(msg, 1, 1) == '#'
    if not c.flags.fullLog and isCommented then
        return -- игнорируем комментарии
    end
    r = r or YELLOW_FONT_COLOR.r
    g = g or YELLOW_FONT_COLOR.g
    b = b or YELLOW_FONT_COLOR.b
    if isCommented then
        msg = WrapTextInColorCode('# ', 'ff333333') .. msg:sub(2)
        r = math_max(r - 0.1, 0)
        g = math_max(g - 0.1, 0)
        b = math_max(b - 0.1, 0)
    end
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
        r,
        g,
        b
    )
end


-- Функция для вывода отладочных сообщений  без спама
function c.Message(msg, title, icon, r, g, b)
    msg = tostring(msg)
    title = tostring(title)
    if not c.IsChanged('Message', msg .. title) then
        return
    end
    debugChat(msg, title, icon, r, g, b)
end

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

-- Функция для вывода отладочных сообщений без частого спама с указанием времени
local times = 0
local lastLog = nil
local function getLogMsg(log)
    if times > 1 then
        return log .. ' (' .. times .. ')'
    end
    return log
end
local function chatLogMsg(log)
    debugChat(
        getLogMsg(log),
        c.GetCurrentTime(),
        iconLog,
        GRAY_FONT_COLOR.r,
        GRAY_FONT_COLOR.g,
        GRAY_FONT_COLOR.b
    )
end
function c.Log(...)
    local log = c.ToStr(...)

    if c.IsChanged('Log', log) then
        -- выводим прошлоее сообщение если накопилось
        if lastLog and times > 0 then
            chatLogMsg(lastLog)
        end
        -- сброс
        times = 0
        -- выводим новое
        chatLogMsg(log)
        -- запоминаем последнее
        lastLog = log
    elseif lastLog then
        if c.TimerLess('Log', 1) then
            -- прошло менее секунды, не частим, накапливаем счетчик
            times = times + 1
            return
        end
        -- перезапускаем таймер
        c.TimerStart('Log')
        -- сливаем, что накопилось
        chatLogMsg(log)
        -- сброс
        times = 0
    end
end

-- Функция для вывода сообщений об ошибках без спама
function c.Error(msg, icon)
    if not c.IsChanged('Error', msg) then return end
    c.EchoError(msg)
    debugChat(
        msg,
        'Ошибка',
        icon or iconError,
        RED_FONT_COLOR.r,
        RED_FONT_COLOR.g,
        RED_FONT_COLOR.b
    )
end

function c.Success(msg, icon)
    if not c.IsChanged('Success', msg) then return end
    debugChat(
        msg,
        'Успех',
        icon or iconSuccess,
        GREEN_FONT_COLOR.r,
        GREEN_FONT_COLOR.g,
        GREEN_FONT_COLOR.b
    )
end

-- Функция для вывода отладочных сообщений в общий чат
function c.Chat(msg)
    if msg == nil then return end
    msg = tostring(msg)
    local key = 'Chat:'
    if not c.IsChanged(key, msg) and c.TimerLess(key, 2) then return end
    DEFAULT_CHAT_FRAME:AddMessage(
        formatMessage(
            c.icon,
            c.name,
            msg
        ),
        GREEN_FONT_COLOR.r,
        GREEN_FONT_COLOR.g,
        GREEN_FONT_COLOR.b);
    c.TimerStart(key)
end

-- Функция для вывода сообщений в центре экрана с затуханием (UIErrorsFrame)
function c.Echo(msg, title, icon, r, g, b) -- Показ сообщения в UIErrorsFrame
    if msg == nil then return end
    msg = tostring(msg)
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage(
        title == nil and icon == nil and msg or formatMessage(
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

function c.EchoError(msg) -- Показ ошибки в UIErrorsFrame
    if msg == nil then return end
    msg = tostring(msg)
    if not c.IsChanged('EchoError', msg) then return end
    UIErrorsFrame:AddMessage(
        msg,
        RED_FONT_COLOR.r,
        RED_FONT_COLOR.g,
        RED_FONT_COLOR.b,
        53,
        2
    );
end

UIErrorsFrame:UnregisterEvent('UI_ERROR_MESSAGE')

function c.LogWhatHappend(msg, skipLogging)
    if not msg then
        c.EchoError('WhatHappend is "' .. tostring(msg) .. '"?!!')
        return
    end
    if not c.IsChanged('WhatHappend', msg) then return end
    if not skipLogging then c.MessageLog(msg) end
    if string.sub(msg, 1, 1) == '#' then msg = string.sub(msg, 2) end
    frame.text:SetText(format('|T%s:16:16:0:0|t %s', c.icon, msg))
    local textWidth = frame.text:GetStringWidth() -- Получаем ширину текста
    local textHeight = frame.text:GetStringHeight()
    frame:SetWidth(textWidth)
    frame:SetHeight(textHeight)
end
