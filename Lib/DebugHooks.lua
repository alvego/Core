---@class Core
local c = Core -- luacheck: ignore
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-- luacheck: push ignore
-- luacheck: pop
c.ActionHook('test', function()
    print('----------------------')
    --print('bLookAt', c.bLookAt('target'))
    print('bMoveTo', c.bMoveTo('target'))
end)
