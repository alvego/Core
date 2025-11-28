-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local GetTime = GetTime
local busySpells = {}
-------------------------------------------------------------------------------

local function spellIsBusy(spellName, busy)
    if busy then
        busySpells[spellName] = GetTime()
        --print(spellName, 'is busy')
        return
    end
    if busySpells[spellName] then
        --print(spellName, 'is free after', c.Round(GetTime() - busySpells[spellName], 3))
        busySpells[spellName] = nil
    end
end

function c.IsBusySpell(spellName)
    if not spellName then return false end
    if not busySpells[spellName] then return false end
    if GetTime() - busySpells[spellName] < 0.5 then return true end
    spellIsBusy(spellName, false)
    return false
end

-------------------------------------------------------------------------------
hooksecurefunc(c, 'Spell', function(spellName, ...)
    if not spellName then return end
    spellIsBusy(spellName, true)
end)

hooksecurefunc('UseAction', function(slot, ...)
    if type(slot) ~= 'number' or slot <= 0 then return end
    local spellName = c.GetActionSpell(slot)
    if not spellName then return end
    spellIsBusy(spellName, true)
end)

local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if source ~= 'player' then return end
    --print(spellName, event)
    spellIsBusy(spellName, false)
end
-- c.AttachEvent('UNIT_SPELLCAST_SENT', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_START', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_STOP', onEvent)
c.AttachEvent('UNIT_SPELLCAST_FAILED', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_FAILED_QUIET', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_DELAYED', onEvent)
c.AttachEvent('UNIT_SPELLCAST_SUCCEEDED', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_INTERRUPTED', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_INTERRUPTIBLE', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_CHANNEL_START', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', onEvent)
-- c.AttachEvent('UNIT_SPELLCAST_CHANNEL_STOP', onEvent)


-- c.AttachBeforeUpdate(function()
--     print(c.IsBusySpell('Молот правосудия'))
-- end)
