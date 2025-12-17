---@class Core
local c = Core

local UnitClass = UnitClass

local className = select(2, UnitClass('player'))

if className ~= 'PRIEST' then return end

c.PrintLoadClassModuleMessage(className)

c.Update(function()
    -- Idle
    c.Log(className)
end)
