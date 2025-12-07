-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local InCombatLockdown = InCombatLockdown
local CombatLogClearEntries = CombatLogClearEntries
-------------------------------------------------------------------------------
c.Event('COMBAT_LOG_EVENT_UNFILTERED', function(...)
    c.TimerStart('CombatLog') -- начинаем отсчет с последнего полученного сообщения
end)

c.BeforeUpdate(function()
    if not InCombatLockdown() then
        return -- не в бою
    end
    if c.TimerLess('CombatLog', 3) then
        return -- последнее сообщение было недавно
    end
    if c.TimerLess('CombatLogReset', 30) then
        return -- не частим со сбросом
    end
    -- сброс CombatLog
    CombatLogClearEntries()
    c.TimerStart('CombatLogReset')
    --c.Log('CombatLogClearEntries!')
end
)

-- c.Telemetry(function()
--     return c.TelemetryBool('CL', c.TimerLess('CombatLog', 3))
-- end)
