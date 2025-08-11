------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
------------------------------------------------------------------------------------------------------------------
local cache = {}
function ns.Chat(msg, hexColor)
    hexColor = hexColor or '88FF88'
    local timerName = 'chat'..hexColor
    if cache[timerName] == msg and ns.TimerLess(timerName, 2) then return end
    local r, g, b = ns.Hex2Rgb(hexColor)
    DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b);
    ns.TimerStart(timerName)
    cache[timerName] = msg
end
------------------------------------------------------------------------------------------------------------------
