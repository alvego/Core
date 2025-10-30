-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local hooksecurefunc = hooksecurefunc
-------------------------------------------------------------------------------
local function startDuel()
    c.duel = false
end
hooksecurefunc('StartDuel', startDuel);
-------------------------------------------------------------------------------
local function duelUpdate(event)
    c.duel = event == 'DUEL_REQUESTED'
end
c.AttachEvent('DUEL_REQUESTED', duelUpdate)
c.AttachEvent('DUEL_FINISHED', duelUpdate)
-------------------------------------------------------------------------------
