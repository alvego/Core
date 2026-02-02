---@class Core
local c = Core -- luacheck: ignore
local st = c.state;

-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-- luacheck: push ignore
-- luacheck: pop

c.ActionHook('test', function()
    print('----------------------')
    local cm = st.combatMode
    st.combatMode = true
    print(c.TryTarget(100, 15))
    st.combatMode = cm
end)
