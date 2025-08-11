------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
function ns.UnitCasting(unit)
    unit = unit or 'player'
    local channel = false
    local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    if not spell then
		spell, rank, displayName, icon, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
        if not spell then return false end
        channel = true
	end
    if spell == nil or not startTime or not endTime then return nil end
    local left =  endTime * 0.001 - GetTime()
    local canInterrupt = not notInterruptible
	local duration = (endTime - startTime) * 0.001
    return spell, left, duration, channel, canInterrupt
end
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
