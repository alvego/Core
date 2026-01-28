---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local SpellIsTargeting = SpellIsTargeting
-- luacheck: pop
st.attack = false
st.start = false
c.BeforeUpdate(function()
    st.attack = c.TimerLess('attack', 1)
    st.start = c.TimerLess('start', 10)
    if not UnitIsDeadOrGhost('player') then return end
    if not c.Paused() then c.Paused(true) end
end, true)

c.Event('GLOBAL_MOUSE_DOWN', function(event, button)
    if button == "Button4" then
        if c.Paused() then
            c.Paused(false)
            c.TimerStart('start')
            c.TimerReset('attack')
        else
            c.bLookAt('target')
            c.TimerStart('attack')
            c.TimerReset('start')
            c.bUseMacro('/startattack [exists, harm, nodead]')
            c.bUseMacro('/petattack [exists, harm, nodead]')
        end
    elseif button == "Button5" then
        if c.Paused() then
            if st.targetExists then
                c.bUseMacro('/cleartarget')
                c.Log('#сброс цели')
            elseif c.UnitCasting() or SpellIsTargeting() then
                c.bUseMacro('/stopcasting')
                c.Log('#отмена каста')
            end
        else
            c.TimerReset('attack')
            c.TimerReset('start')
            c.Paused(true)
            c.bUseMacro('/stopattack')
            c.bUseMacro('/petstop')
            c.bUseMacro('/petfollow')
        end
    end
end)

c.Event('ADDON_LOADED', function(event, addonName)
    if addonName ~= c.name then return end
    CoreDB = CoreDB or {}
    c.db = CoreDB
    c.loaded = true
end)

local function inWorldUpdate(event)
    st.inWorld = event == 'PLAYER_ENTERING_WORLD'
end
c.Event('PLAYER_ENTERING_WORLD', inWorldUpdate)
c.Event('PLAYER_LEAVING_WORLD', inWorldUpdate)
