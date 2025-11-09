-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
-------------------------------------------------------------------------------
c.AttachBeforeUpdate(function()
    c.attack = c.IsActionPressed('attack') or c.IsMouse(4)
    c.start = c.IsActionPressed('start') or c.IsMouse(3)
    local stop = c.IsActionPressed('stop') or c.IsMouse(5) or UnitIsDeadOrGhost('player')
    if c.attack then c.TurnTo('target') end
    if c.attack or c.start then
        c.Paused(false)
    elseif stop then
        c.Paused(true)
    end
end)

-------------------------------------------------------------------------------
c.AttachActionHook('attack', function()
    c.attack = true
    c.Paused(false)
    c.TurnTo('target')
end)

-------------------------------------------------------------------------------
c.AttachActionHook('start', function()
    c.start = true
    c.Paused(false)
end)

-------------------------------------------------------------------------------
c.AttachActionHook('stop', function()
    if c.attack then return end
    c.Paused(true)
end)

-------------------------------------------------------------------------------
c.AttachEvent('PLAYER_ENTERING_WORLD', function()
    c.inWorld = true
end)
c.AttachEvent('PLAYER_LEAVING_WORLD', function()
    c.inWorld = false
end)
