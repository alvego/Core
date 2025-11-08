-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local GetLootMethod = GetLootMethod
-------------------------------------------------------------------------------
c.AttachBeforeUpdate(function()
    if not st.group or (GetLootMethod() == 'freeforall') then return end
end)
