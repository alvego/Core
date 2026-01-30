---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local format = format
local GetFramerate = GetFramerate
local WrapTextInColorCode = WrapTextInColorCode
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local UnitIsAFK = UnitIsAFK
-- luacheck: pop
c.Telemetry(function()
    if UnitIsAFK('player') == 1 then
        return WrapTextInColorCode(c.name, 'ffffbb00')
    end
    if st.attack then
        return WrapTextInColorCode(c.name, 'ffff0000')
    end
    if st.start then
        return WrapTextInColorCode(c.name, 'ff0000ff')
    end
    return c.TelemetryBool(c.name, not c.Paused())
end)


c.Telemetry(function()
    return format('TAR15: %03d', c.GetEnemyCount(15, 'player'))
end)


c.Telemetry(function()
    return format('SPD: %03d%%', c.Round(st.speed / 7 * 100))
end)


c.Telemetry(function()
    return format('Lag: %04dms', c.Round(c.latency * 1000))
end)


c.Telemetry(function()
    return format('FPS: %03d', GetFramerate())
end)


c.Telemetry(function()
    return format('Mem: %.1fKB', GetAddOnMemoryUsage(c.name))
end)
