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

local entities = {} -- Создаем таблицу один раз
UIParentLoadAddOn('Blizzard_DebugTools');

c.ActionHook('test', function()
    print('Pulse', Cmd('Pulse'));

    print('--- Test GetEntities ---')

    -- Очистка таблицы перед вызовом (эмуляция table.wipe, если её нет в 3.3.5, используем цикл)
    wipe(entities);
    -- Запрос: Юниты в радиусе 30м
    local count = Cmd('GetEntities', entities, 'units', 30)
    DevTools_Dump(entities)
    print('Found units (30m):', count)

    -- Вывод первых 3 результатов
    for i = 1, math.min(count, 3) do
        local guid = entities[i]
        local name = "Unknown"
        -- Используем наш WithGUID враппер или стандартный способ если есть
        -- Тут просто выведем GUID для проверки
        print(i, guid)
    end

    print('----------------------')
end)
