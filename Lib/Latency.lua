---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
local GetNetStats = GetNetStats
local GetTime = GetTime
local math_max = math.max
-- luacheck: pop
local sendTime = nil
local function updateLagTime(event, ...)
    local unit, spell = select(1, ...)
    if spell and unit == 'player' then
        if event == 'UNIT_SPELLCAST_SENT' then
            sendTime = GetTime()
        else
            if not sendTime then return end
            c.latency = math_max(GetTime() - sendTime, c.advance)
            c.TimerStart('updateLagTime')
            sendTime = nil
        end
    end
end
c.Event('UNIT_SPELLCAST_SENT', updateLagTime)
c.Event('UNIT_SPELLCAST_START', updateLagTime)
c.Event('UNIT_SPELLCAST_SUCCEEDED', updateLagTime)
c.Event('UNIT_SPELLCAST_FAILED', updateLagTime)

local function updateLatency() -- Время сетевой задержки
    if c.TimerMore('updateLagTime', 15) then
        c.latency = math_max(tonumber((select(3, GetNetStats()) or 0)) / 1000, c.advance)
        c.TimerStart('updateLagTime')
    end
end
c.BeforeUpdate(updateLatency)
