---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
local UnitClass = UnitClass
-- luacheck: pop
local className = select(2, UnitClass('player'))

if className ~= 'MAGE' then return end

c.PrintLoadClassModuleMessage(className)

c.Update(function()
    -- Idle
    c.Log(className)
end)
