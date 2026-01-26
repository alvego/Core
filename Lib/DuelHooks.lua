---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
-- luacheck: pop
local hooksecurefunc = hooksecurefunc

local function startDuel()
    st.duel = false
end
hooksecurefunc('StartDuel', startDuel);

local function duelUpdate(event)
    st.duel = event == 'DUEL_REQUESTED'
end
c.Event('DUEL_REQUESTED', duelUpdate)
c.Event('DUEL_FINISHED', duelUpdate)
