---@class Core
local c = Core -- luacheck: ignore
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-- luacheck: push ignore
-- luacheck: pop
local t = { 319572, 25780, 57139 }
c.ActionHook('test', function()
    print('----------------------')
    print('UnitAuraByID', c.bUnitAuraByID('target', t, true))
end)
