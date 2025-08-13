------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local GetNetStats = GetNetStats
------------------------------------------------------------------------------------------------------------------
local latency = 0
local sendTime = nil
local function updateLagTime(event, ...)
    local unit, spell = select(1, ...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            sendTime = GetTime()
        else
            if not sendTime then return end
            latency = GetTime() - sendTime
            ns.TimerStart('updateLagTime')
            sendTime = nil
        end
    end
end
ns.AttachEvent('UNIT_SPELLCAST_SENT', updateLagTime)
ns.AttachEvent('UNIT_SPELLCAST_START', updateLagTime)
ns.AttachEvent('UNIT_SPELLCAST_SUCCEEDED', updateLagTime)
ns.AttachEvent('UNIT_SPELLCAST_FAILED', updateLagTime)
------------------------------------------------------------------------------------------------------------------
function ns.GetLatency() -- Время сетевой задержки
    if ns.TimerMore('updateLagTime', 15) then
        latency = tonumber((select(3, GetNetStats()) or 0)) / 1000
        ns.TimerStart('updateLagTime')
    end
    return math.max(latency, ns.advance)
end
