---@class Core
local c = Core

-- local GetCVar = GetCVar
-- local SetCVar = SetCVar


local Bridge = function(cmd, ...)
    return GetBillingTimeRested(cmd, ...)
end

UIParentLoadAddOn('Blizzard_DebugTools');

c.ActionHook('test', function()
    --ChatFrame_OpenChat('test')
    -- DevTools_Dump({
    --     GetBillingTimeRested("exec",
    --         "return 'текст', 25, 0.333, nil, false, true, {['x'] = 1, ['x'] = 2}, function() return 1 end")
    -- })

    print(
        'exec',
        GetBillingTimeRested(
            "exec",
            "print('issecure() ==', issecure())"
        )
    )

    print(
        'eval',
        GetBillingTimeRested(
            "eval",
            "print('issecure() ==', issecure())"
        )
    )

    Bridge('help')

    --print(D('join', 'текст', 25, 0.333, nil, false, true, { ['x'] = 1, ['y'] = 2 }, function() return 1 end))

    -- print('GetBillingTimeRested("version") = ', GetBillingTimeRested("version"))
    -- local unit = 'target'
    -- if not UnitExists(unit) then return end
    -- local g = UnitGUID(unit)
    -- local name = UnitName(unit)
    -- local gname = UnitName(g)
    -- print(g, name, gname)
end)
