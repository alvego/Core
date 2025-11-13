-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local format = format
local GetFramerate = GetFramerate
local WrapTextInColorCode = WrapTextInColorCode
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local UnitIsPVP = UnitIsPVP
local UnitIsAFK = UnitIsAFK
-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if UnitIsAFK('player') == 1 then
        return WrapTextInColorCode('Run', 'ffffbb00')
    end
    if st.attack then
        return WrapTextInColorCode('Run', 'ffff0000')
    end
    return c.TelemetryBool('Run', not c.Paused())
end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('TAR15: %03d', c.GetEnemyCount(15, 'player'))
-- end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('SPD: %03d%%', c.Round(st.speed / 7 * 100))
-- end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('Lag: %04dms', c.Round(c.latency * 1000))
-- end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('FPS: %03d', GetFramerate())
-- end)

-------------------------------------------------------------------------------
-- c.AttachTelemetry(function()
--     return format('Mem: %.1fKB', GetAddOnMemoryUsage(c.name))
-- end)

-------------------------------------------------------------------------------
