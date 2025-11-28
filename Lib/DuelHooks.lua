-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local hooksecurefunc = hooksecurefunc
-------------------------------------------------------------------------------
local function startDuel()
    st.duel = false
end
hooksecurefunc('StartDuel', startDuel);
-------------------------------------------------------------------------------
local function duelUpdate(event)
    st.duel = event == 'DUEL_REQUESTED'
end
c.AttachEvent('DUEL_REQUESTED', duelUpdate)
c.AttachEvent('DUEL_FINISHED', duelUpdate)
-------------------------------------------------------------------------------
