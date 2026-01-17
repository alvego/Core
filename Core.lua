Core = {} -- Глобальная переменная для аддона
---Основа аддона, содержит глобальные переменные и функции
---@class Core
local c = Core
local type = type
local tostring = tostring
local setmetatable = setmetatable
local format = format

---Имя аддона
c.name = ...
---Путь к иконке аддона
c.icon = format([[Interface\AddOns\%s\textures\lenin.blp]], c.name)
c.iconUpdate = format([[Interface\AddOns\%s\textures\serp_molot.blp]], c.name)
---База данных аддона
c.db = {}
---
---Состояние аддона
---
---@class Core.state
c.state = {}
---Кэш состояний
c.stateCache = {}
---Флаг загрузки аддона (db подгружена)
c.loaded = false
---Флаг занятости аддона (время на стыке гкд)
c.busy = true

---Интервал минимальной сетевой задержки (в секундах)
c.advance = 0.05
---Пауза между обновления
c.updateDelay = 0.25
---Сетевая задержка
c.latency = c.advance
---Id гкд спела
c.gcdSpellId = 61304

---@class Core.flags
---Флаги аддона (по умолчанию)
local flags = {          -- defaults
    paused = true,       -- аддон на паузе
    loot = false,        -- автоосмотр добычи
    move = false,        -- движение к цели/добыче
    fullLog = false,     -- полные логи (выводит закомментированные # сообщения)
    autoDelJunk = false, -- тихо удаляем хлам при заполнении сумок
    autoLook = false,    -- всегда держим взгляд на цели
    autoMelee = false    -- приоритет - цели ближнего боя
}
---@class Core.flags
---Флаги аддона (связанные с базой данных)
c.flags = {} -- metatable linked with db
-- Метатаблица для c.flags
local flagsMeta = {
    __index = function(_, key)
        -- Сначала проверяем в базе данных
        if c.db[key] ~= nil then
            return c.db[key]
        end
        -- Иначе возвращаем значение по умолчанию из flags defaults
        local def = flags[key]
        if def ~= nil then
            return def
        end
        -- Если флага вообще нет, возвращаем nil (или можно добавить error для отладки)
        c.Error('Запрашивает неверный флаг - ' .. tostring(key))
        return nil
    end,

    __newindex = function(_, key, value)
        local def = flags[key]
        if def == nil then
            c.Error('Задает неверный флаг ' .. tostring(key))
            return
        end
        -- При присвоении сохраняем в базу данных
        c.db[key] = value
    end
}
setmetatable(c.flags, flagsMeta)

---Получает значение флага паузы
---@param value boolean? Значение для установки флага (если указано)
---@return boolean
function c.Paused(value)
    if type(value) == 'boolean' then
        c.flags.paused = value
    end
    if c.state.afk then
        return true
    end
    return c.flags.paused
end

---Проверяет, загружен ли аддон (загружена db и игрок в мире)
---@return boolean
function c.IsLoaded()
    return c.loaded and c.state.inWorld
end

local stateCacheIndex = 0
---Кэширует результат работы функции для заданных параметров.
---Кеш сбрасывается перед следующем обновлении.
---Кеширует только первый возвращаемый результат.
---Для `target` аргументов проверяйте перед вызовом на `UnitExists`.
---@generic T: function
---@param func T Функция для кэширования
---@return T
function c.GetCachedFunc(func)
    stateCacheIndex = stateCacheIndex + 1
    local name = '#' .. stateCacheIndex
    return function(...)
        local key = c.ToStr(name, ...)
        local value = c.stateCache[key]
        if value then return value end
        value = func(...)
        c.stateCache[key] = value
        return value
    end
end

--[[
UIParentLoadAddOn('Blizzard_DebugTools');
DevTools_Dump(c)
]]

--[[
  /run UIParentLoadAddOn('Blizzard_DebugTools');
  /fstack true
  /etrace
]]
