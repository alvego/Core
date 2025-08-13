------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ...     -- namespace
------------------------------------------------------------------------------------------------------------------
local FADE_DURATION = 30 -- Длительность затухания в секундах
local MAX_MESSAGES = 10  -- Максимальное количество сообщений
------------------------------------------------------------------------------------------------------------------
-- Создание фрейма
local frame = CreateFrame("ScrollingMessageFrame", name .. 'Log', UIParent)

-- Настройка фрейма
frame:SetSize(300, 300)                            -- Ширина, высота
frame:SetPoint("TOP", UIParent, "TOP", -300, -100) -- Позиция
frame:SetFontObject(GameFontNormal)                -- Шрифт
frame:SetJustifyH("CENTER")                        -- Выравнивание по центру
frame:SetFading(true)                              -- Включить затухание
frame:SetFadeDuration(FADE_DURATION)               -- Длительность затухания
frame:SetTimeVisible(5)                            -- Время видимости до затухания (сек)
frame:SetMaxLines(MAX_MESSAGES)                    -- Максимум сообщений
frame:SetSpacing(3)                                -- Расстояние между строками
frame:SetInsertMode("TOP")                         -- Новые сообщения сверху
------------------------------------------------------------------------------------------------------------------
local function updateLogVisibility()
    if ns.State.debug then
        if not frame:IsVisible() then frame:Show() end
        return
    end
    if frame:IsVisible() then frame:Hide() end
end
ns.AttachUpdateDebugState(updateLogVisibility)

------------------------------------------------------------------------------------------------------------------
function ns.Log(text, hex)
    if not ns.State.debug then
        return
    end
    --print(text)
    local r, g, b = ns.Hex2Rgb(hex or '88FF88')
    frame:AddMessage(
        text, -- Текст
        r,    -- Красный (0-1)
        g,    -- Зеленый (0-1)
        b,    -- Синий (0-1)
        nil,  -- ID текстуры (не используется)
        false -- Не добавлять в историю чата
    )
end

------------------------------------------------------------------------------------------------------------------
