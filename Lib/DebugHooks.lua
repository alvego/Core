---@class Core
local c = Core
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar

c.ActionHook('test', function()
    print('----------------------')
    print('Obj', c.bFindObject('Косяк'))
end)
