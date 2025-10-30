-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local InCombatLockdown = InCombatLockdown
local CombatLogClearEntries = CombatLogClearEntries
-------------------------------------------------------------------------------
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', function(...)
    c.TimerStart("CombatLog") -- начианаем отсчет с последнего полученного сообщения
end)

c.AttachBeforeUpdate(function()
    if not InCombatLockdown() then
        return -- не в бою
    end
    if c.TimerLess("CombatLog", 3) then
        return -- последнее сооющение было недавно
    end
    if c.TimerLess("CombatLogReset", 30) then
        return -- не частим со сбросом
    end
    -- сброс ComatLog
    CombatLogClearEntries()
    c.TimerStart("CombatLogReset")
    --c.Log("CombatLogClearEntries!")
end
)

-- c.AttachTelemetry(function()
--     return c.TelemetryBool('CL', c.TimerLess("CombatLog", 3))
-- end)
