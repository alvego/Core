---@class Core
local c = Core -- luacheck: ignore
local st = c.state;
local wipe = wipe
local UnitGUID = UnitGUID

-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-- luacheck: push ignore
-- luacheck: pop

local units = {}
c.ActionHook('test', function()
    print('----------------------')
    wipe(units)
    c.bFindUnits(units, 15, 1)

    print('bFindUnits #', #units)

    c.FindUnitGUID(units, function(token)
        print(token, UnitGUID(token), c.UnitInfo(token))
    end)
end)
