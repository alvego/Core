------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ...
------------------------------------------------------------------------------------------------------------------
local format = format
------------------------------------------------------------------------------------------------------------------
local frame = CreateFrame("Frame", name .. "Telemetry", UIParent)
frame:ClearAllPoints()
frame:SetHeight(10)
frame:SetWidth(800)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetAllPoints()
frame:SetPoint('TOPLEFT', 110, 0)
frame:SetScale(1);
frame:SetAlpha(1)
------------------------------------------------------------------------------------------------------------------
local _telemetry = ''
function ns.UpdateTelemetry()
    if not ns.State.debug then
        if frame:IsVisible() then frame:Hide() end
        return
    end
    local telemetry = ns.State.telemetry or ''
    if not frame:IsVisible() then frame:Show() end
    if telemetry ~= _telemetry then
        _telemetry = telemetry
        frame.text:SetText(telemetry)
    end
end
------------------------------------------------------------------------------------------------------------------

