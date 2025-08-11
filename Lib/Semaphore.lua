------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
-- Инициализация скрытого фрейма для обработки событий
local frame = CreateFrame('Frame', name .. 'Semaphore', UIParent)
frame:SetFrameStrata('High')
frame:SetPoint('TOPLEFT',  0, 0)
frame:SetWidth(5)
frame:SetHeight(5)
frame:SetScale(1, 1)
frame:SetAlpha(1)
frame:Show()
------------------------------------------------------------------------------------------------------------------
local texture = frame:CreateTexture('Texture', 'Background')
texture:SetBlendMode('Disable')
texture:SetTexture(0, 0, 0)
texture:SetAllPoints(frame)
------------------------------------------------------------------------------------------------------------------

function ns.Semaphore(num)
    local r, g, b = ns.Num2Rgb(num)
    texture:SetTexture(r, g, b)
end
------------------------------------------------------------------------------------------------------------------