---@class Core
local c = Core -- luacheck: ignore
local st = c.state;

-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-- luacheck: push ignore
-- luacheck: pop

c.ActionHook('test', function()
    print('----------------------')
    --local activeTalentGroup, numTalentGroups = GetActiveTalentGroup(false, false), GetNumTalentGroups(false, false);
    --print(select(5, GetTalentInfo(2, 29)))
    print(c.HasTalent('Чистота'))
end)
