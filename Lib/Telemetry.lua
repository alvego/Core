------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ...
local format = format
local tinsert = tinsert
local wipe = wipe
local table_concat = table.concat
------------------------------------------------------------------------------------------------------------------
local frame = CreateFrame('Frame', name .. 'Telemetry', UIParent)
frame:ClearAllPoints()
frame:SetHeight(10)
frame:SetWidth(10)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetFont("Fonts\\ARIALN.TTF", 10) -- Альтернативный шрифт
frame.text:SetAllPoints()
frame:SetPoint('TOPLEFT', 20, 0)
frame:SetScale(1);
frame:SetAlpha(1)
local texture = frame:CreateTexture('Texture', 'BACKGROUND')
texture:SetBlendMode('DISABLE')
texture:SetTexture(0, 0, 0)
texture:SetAlpha(0.5)
texture:SetAllPoints(frame)
------------------------------------------------------------------------------------------------------------------
local function updateTelemetryVisibility(visible)
    if visible then
        if not frame:IsVisible() then frame:Show() end
        return
    end
    if frame:IsVisible() then frame:Hide() end
end
ns.AttachUpdateDebugState(updateTelemetryVisibility)
------------------------------------------------------------------------------------------------------------------

local list = {}
function ns.AttachTelemetry(fn)
    if type(fn) ~= 'function' then error('Telemetry fn must be a getter function') end
    tinsert(list, fn)
end

------------------------------------------------------------------------------------------------------------------

function ns.TelemetryBool(label, value)
    return value and '|cff00ff00' .. label .. '|r' or '|cff888888' .. label .. '|r'
end

------------------------------------------------------------------------------------------------------------------

local data = {}
local function createTelemetryMessage()
    for _, fn in pairs(list) do
        tinsert(data, fn())
    end
    local label = table_concat(data, ', ')
    wipe(data)
    return label
end
------------------------------------------------------------------------------------------------------------------
local function updateTelemetry()
    local telemetry = createTelemetryMessage()
    if ns.IsChanged('ns.UpdateTelemetry', telemetry) then
        frame.text:SetText(telemetry)
        local textWidth = frame.text:GetStringWidth() -- Получаем ширину текста
        local textHeight = frame.text:GetStringHeight()
        frame:SetWidth(textWidth)
        frame:SetHeight(textHeight)
    end
end
ns.AttachAfterIdle(updateTelemetry)
------------------------------------------------------------------------------------------------------------------

ns.AttachTelemetry(function()
    return ns.TelemetryBool('RUN', not Paused)
end)

ns.AttachTelemetry(function()
    return ns.TelemetryBool('BOSS', ns.State.bossTarget)
end)

ns.AttachTelemetry(function()
    return ns.TelemetryBool('PVP', ns.State.pvp)
end)

ns.AttachTelemetry(function()
    return format('SPD: %03d%%', ns.Round(ns.State.speed / 7 * 100))
end)

ns.AttachTelemetry(function()
    return format('TAR: %02d', ns.State.numTargets)
end)

ns.AttachTelemetry(function()
    return format('TTD: %03ds', ns.Round(ns.State.ttd))
end)
