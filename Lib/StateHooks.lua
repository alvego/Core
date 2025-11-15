-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
-------------------------------------------------------------------------------
st.attack = false
st.start = false
c.AttachBeforeUpdate(function()
    st.attack = c.IsActionPressed('attack') or c.IsMouse(4)
    st.start = c.IsActionPressed('start') or c.IsMouse(3)
    local stop = c.IsActionPressed('stop') or c.IsMouse(5) or UnitIsDeadOrGhost('player')
    if st.attack then c.TurnTo('target') end
    if st.attack or st.start then
        c.Paused(false)
    elseif stop then
        c.Paused(true)
    end
end)

-------------------------------------------------------------------------------
c.AttachActionHook('attack', function()
    st.attack = true
    c.Paused(false)
    c.TurnTo('target')
end)

-------------------------------------------------------------------------------
c.AttachActionHook('start', function()
    st.start = true
    c.Paused(false)
end)

-------------------------------------------------------------------------------
c.AttachActionHook('stop', function()
    if st.attack then return end
    c.Paused(true)
end)

-------------------------------------------------------------------------------
c.AttachEvent('ADDON_LOADED', function(event, addonName)
    if addonName ~= c.name then return end
    CoreDB = CoreDB or {}
    c.db = CoreDB
    c.loaded = true
end)
-------------------------------------------------------------------------------
c.AttachEvent('PLAYER_ENTERING_WORLD', function()
    st.inWorld = true
end)
c.AttachEvent('PLAYER_LEAVING_WORLD', function()
    st.inWorld = false
end)
