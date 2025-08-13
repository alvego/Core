------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ...
local format = format
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

function ns.UpdateTelemetry()
    local telemetry = format(
        'RUN: %s, PVP: %s, LAG: %sms, GCD: %s, ATK: %s',
        Paused and '0' or '1',
        ns.State.pvp and '1' or '0',
        ns.Round(ns.State.latency, 3) * 1000,
        ns.State.gcd and '1' or '0',
        ns.State.autoattack and '1' or '0'
    )
    if ns.IsChanged('ns.UpdateTelemetry', telemetry) then
        frame.text:SetText(telemetry)
    end
end

------------------------------------------------------------------------------------------------------------------
