-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local format = format
local tostring = tostring
local tinsert = tinsert
local wipe = wipe
local table_concat = table.concat
local GetFramerate = GetFramerate
local WrapTextInColorCode = WrapTextInColorCode
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local UnitIsPVP = UnitIsPVP
-------------------------------------------------------------------------------
local frame = CreateFrame('Frame', c.name .. 'Telemetry', UIParent)
frame:ClearAllPoints()
frame:SetHeight(10)
frame:SetWidth(10)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetFont("Fonts\\ARIALN.TTF", 10) -- Альтернативный шрифт
frame.text:SetAllPoints()
frame:SetPoint('TOPLEFT', 0, 0)
frame:SetScale(1);
frame:SetAlpha(1)
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
c.AttachUpdateDebugState(updateTelemetryVisibility)

-------------------------------------------------------------------------------
local list = {}
function c.AttachTelemetry(fn)
    if type(fn) ~= 'function' then error('Telemetry fn must be a getter function') end
    tinsert(list, fn)
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
    for _, fn in pairs(list) do
        local msg = fn()
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
c.AttachAfterUpdate(updateTelemetry)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    return c.TelemetryBool('RUN', not c.Paused())
end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    return c.TelemetryBool('ATK', c.attack)
end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('TAR15: %03d', c.GetEnemyCount(15, 'player'))
-- end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    return format('SPD: %03d%%', c.Round(c.state.speed / 7 * 100))
end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('Lag: %04dms', c.Round(c.latency * 1000))
-- end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    return format('FPS: %03d', GetFramerate())
end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('Mem: %.1fKB', GetAddOnMemoryUsage(c.name))
-- end)

-------------------------------------------------------------------------------
