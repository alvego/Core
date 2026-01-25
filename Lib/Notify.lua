---@class Core
local c = Core
local format = format
local ORANGE_FONT_COLOR = ORANGE_FONT_COLOR
local CreateFrame = CreateFrame
local UIParent = UIParent

local frame = CreateFrame('Frame', c.name .. 'Notify', UIParent)
frame:ClearAllPoints()
frame:SetPoint("CENTER", UIParent, "TOP", 0, -20)
frame:SetHeight(1)
frame:SetWidth(1)
frame.text = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
frame.text:SetFont([[Fonts\ARIALN.TTF]], 16) -- Альтернативный шрифт
frame.text:SetTextColor(ORANGE_FONT_COLOR.r, ORANGE_FONT_COLOR.g, ORANGE_FONT_COLOR.b, ORANGE_FONT_COLOR.a)
frame.text:SetAllPoints()


function c.Notify(msg, icon, wait)
    frame.text:SetText(format('|T%s:16:16:0:0|t %s', icon or c.iconUpdate, msg))
    local textWidth = frame.text:GetStringWidth() -- Получаем ширину текста
    local textHeight = frame.text:GetStringHeight()
    frame:SetWidth(textWidth)
    frame:SetHeight(textHeight)
    frame:Show()
    c.TimerStart('Notify', wait)
end

c.AfterUpdate(function()
    if frame:IsShown() and c.TimerMore('Notify', 1) then frame:Hide() end
end)
