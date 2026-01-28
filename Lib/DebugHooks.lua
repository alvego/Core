---@class Core
local c = Core -- luacheck: ignore
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-- luacheck: push ignore
-- luacheck: pop
local t = { 57623 + 1, 'Зимний горн' }
c.ActionHook('test', function()
    print('----------------------')
    print('HasAura', c.bHasAura('player', t, true))
    print('GetAura', c.bGetAura('player', t, true))
    --print(c.bTest(25780), GetSpellInfo(25780));
end)
