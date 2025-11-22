-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local SpellIsTargeting = SpellIsTargeting
-------------------------------------------------------------------------------
st.attack = false
st.start = false
c.AttachBeforeUpdate(function()
    st.attack = c.TimerLess('attack', 1)
    st.start = c.TimerLess('start', 10)
    if not UnitIsDeadOrGhost('player') then return end
    if not c.Paused() then c.Paused(true) end
end)

c.AttachEvent('GLOBAL_MOUSE_DOWN', function(event, button)
    if button == "Button4" then
        if c.Paused() then
            c.Paused(false)
            c.TimerStart('start')
            c.TimerReset('attack')
        else
            c.TurnToUnit('target')
            c.TimerStart('attack')
            c.TimerReset('start')
            c.Command('/startattack [exists, harm, nodead]')
            c.Command('/petattack [exists, harm, nodead]')
        end
    elseif button == "Button5" then
        if c.Paused() then
            if st.existsTarget then
                c.Command('/cleartarget')
                c.Log('#сброс цели')
            elseif c.UnitCasting() or SpellIsTargeting() then
                c.CastStop()
                c.Log('#отмена каста')
            end
        else
            c.TimerReset('attack')
            c.TimerReset('start')
            c.Paused(true)
            c.Command('/stopattack')
            c.Command('/petstop')
            c.Command('/petfollow')
        end
    end
end)
-------------------------------------------------------------------------------
c.AttachEvent('ADDON_LOADED', function(event, addonName)
    if addonName ~= c.name then return end
    CoreDB = CoreDB or {}
    c.db = CoreDB
    c.loaded = true
end)
-------------------------------------------------------------------------------
local function inWorldUpdate(event)
    st.inWorld = event == 'PLAYER_ENTERING_WORLD'
end
c.AttachEvent('PLAYER_ENTERING_WORLD', inWorldUpdate)
c.AttachEvent('PLAYER_LEAVING_WORLD', inWorldUpdate)
