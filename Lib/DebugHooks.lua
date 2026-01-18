---@class Core
local c = Core
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar


local Cmd = function(name, ...)
    --if (type(Bridge) ~= 'function') then return end
    return GetBillingTimeRested(name, ...)
end

-- Глобальная обертка (добавь в свой загрузочный скрипт)
function WithGUID(guid, callback)
    local token = "mouseover"
    local oldGuid = UnitGUID(token)
    Cmd("UseGUID", token, guid)
    local result = callback(token)
    Cmd("UseGUID", token, oldGuid)
    return result
end

c.ActionHook('test', function()
    print('Pulse', Cmd('Pulse'));

    print(Cmd('GetUnitInfo', 'target'))

    print('----------------------')
end)
