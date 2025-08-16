------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ...
local format = format
local tinsert = tinsert
local wipe = wipe
local table_concat = table.concat
------------------------------------------------------------------------------------------------------------------
local frame = CreateFrame("Frame", name .. "Telemetry", UIParent)
frame:ClearAllPoints()
frame:SetHeight(10)
frame:SetWidth(210)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetAllPoints()
frame:SetPoint('TOPLEFT', 20, 0)
frame:SetScale(1);
frame:SetAlpha(1)
local texture = frame:CreateTexture('Texture', 'Background')
texture:SetBlendMode('Disable')
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
    if type(fn) ~= "function" then error("Telemetry fn must be a getter function") end
    tinsert(list, fn)
end

------------------------------------------------------------------------------------------------------------------
function ns.TelemetryBool(value)
    return value and '1' or '0'
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
        frame:SetWidth(textWidth)
    end
end
ns.AttachAfterIdle(updateTelemetry)
------------------------------------------------------------------------------------------------------------------

ns.AttachTelemetry(function()
    return format('RUN: %s', ns.TelemetryBool(not Paused))
end)

ns.AttachTelemetry(function()
    return format('PVP: %s', ns.TelemetryBool(ns.State.pvp))
end)

ns.AttachTelemetry(function()
    return format('TAR: %s', ns.State.numTargets)
end)

ns.AttachTelemetry(function()
    return format('BSS: %s', ns.TelemetryBool(ns.State.bossTarget))
end)

ns.AttachTelemetry(function()
    return format('TTD: %ss', ns.Round(ns.State.ttd, 2))
end)
