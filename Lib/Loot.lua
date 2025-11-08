-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local GetLootMethod = GetLootMethod
-------------------------------------------------------------------------------
c.AttachBeforeUpdate(function()
    local lootMethod = GetLootMethod()
    if lootMethod ~= 'freeforall' then return end
end
)
