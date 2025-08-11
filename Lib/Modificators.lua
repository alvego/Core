------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
-- Кешируем функции и значения
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local IsMouseButtonDown = IsMouseButtonDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local IsShiftKeyDown = IsShiftKeyDown
------------------------------------------------------------------------------------------------------------------
function ns.IsMouse(n)
    return IsMouseButtonDown(n) == 1
end
------------------------------------------------------------------------------------------------------------------
function ns.IsCtr()
    if GetCurrentKeyBoardFocus() then return false end
    return IsControlKeyDown() == 1
end
------------------------------------------------------------------------------------------------------------------
function ns.IsAlt()
    if GetCurrentKeyBoardFocus() then return false end
    return IsAltKeyDown() == 1
end
------------------------------------------------------------------------------------------------------------------
function ns.IsShift()
    if GetCurrentKeyBoardFocus() then return false end
    return IsShiftKeyDown() == 1
end
------------------------------------------------------------------------------------------------------------------
