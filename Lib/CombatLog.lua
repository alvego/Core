------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local InCombatLockdown = InCombatLockdown
local CombatLogClearEntries = CombatLogClearEntries
------------------------------------------------------------------------------------------------------------------
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', function(...)
    ns.TimerStart("CombatLog") -- начианаем отсчет с последнего полученного сообщения
end)

ns.AttachBeforeIdle(function()
    if not InCombatLockdown() then
        return -- не в бою
    end
    if ns.TimerLess("CombatLog", 3) then
        return -- последнее сооющение было недавно
    end
    if ns.TimerLess("CombatLogReset", 30) then
        return -- не частим со сбросом
    end
    -- сброс ComatLog
    CombatLogClearEntries()
    ns.TimerStart("CombatLogReset")
    --ns.Log("CombatLogClearEntries!")
end
)

ns.AttachTelemetry(function()
    return ns.TelemetryBool('CL', ns.TimerLess("CombatLog", 3))
end)
