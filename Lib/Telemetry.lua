-------------------------------------------------------------------------------
-- Core by Unknown Coder
-------------------------------------------------------------------------------
---@class Core
local c = Core
-------------------------------------------------------------------------------
local tostring = tostring
local tinsert = tinsert
local wipe = wipe
local type = type
local error = error
local table_concat = table.concat
local WrapTextInColorCode = WrapTextInColorCode

-------------------------------------------------------------------------------
local frame = CreateFrame('Frame', c.name .. 'Telemetry', UIParent)
frame:ClearAllPoints()
frame:SetPoint('TOPLEFT', 0, 0)
frame:SetHeight(10)
frame:SetWidth(10)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetFont([[Fonts\ARIALN.TTF]], 10) -- Альтернативный шрифт
frame.text:SetAllPoints()
local texture = frame:CreateTexture('Texture', 'BACKGROUND')
texture:SetBlendMode('DISABLE')
texture:SetTexture(0, 0, 0)
texture:SetAlpha(0.5)
texture:SetAllPoints(frame)

-------------------------------------------------------------------------------
local function updateTelemetryVisibility(visible)
    if visible then
        if not frame:IsVisible() then frame:Show() end
        return
    end
    if frame:IsVisible() then frame:Hide() end
end
c.UpdateDebugState(updateTelemetryVisibility)

-------------------------------------------------------------------------------
local list = {}
function c.Telemetry(func)
    if type(func) ~= 'function' then error('Функция для телеметрии должна возвращать значение', 2) end
    tinsert(list, func)
end

-------------------------------------------------------------------------------
function c.TelemetryBool(label, value)
    return WrapTextInColorCode(label, value and 'ff00ff00' or 'ff885555')
end

function c.TelemetryRedBool(label, value)
    return WrapTextInColorCode(label, value and 'ff558855' or 'ffff0000')
end

-------------------------------------------------------------------------------

local data = {}
local function createTelemetryMessage()
    for i = 1, #list do
        local msg = list[i]()
        if msg then
            tinsert(data, tostring(msg))
        end
    end
    local label = table_concat(data, ', ')
    wipe(data)
    return label
end
-------------------------------------------------------------------------------

local function updateTelemetry()
    local telemetry = createTelemetryMessage()
    if c.IsChanged('UpdateTelemetry', telemetry) then
        frame.text:SetText(telemetry)
        local textWidth = frame.text:GetStringWidth() -- Получаем ширину текста
        local textHeight = frame.text:GetStringHeight()
        frame:SetWidth(textWidth)
        frame:SetHeight(textHeight)
    end
end
c.AfterUpdate(updateTelemetry)

-------------------------------------------------------------------------------
