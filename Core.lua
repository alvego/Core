-------------------------------------------------------------------------------
-- Core by Unknown Coder
-------------------------------------------------------------------------------
---@class Core
Core = {}
-------------------------------------------------------------------------------
---@class Core
local c = Core
-------------------------------------------------------------------------------
local type = type
local tostring = tostring
local error = error
local setmetatable = setmetatable
local format = format
-------------------------------------------------------------------------------
c.name = ...
c.icon = format([[Interface\AddOns\%s\textures\serp_molot_debug.blp]], c.name)
c.db = {}

---@class Core.state
c.state = {}
c.stateCache = {}
c.loaded = false
c.busy = true
-------------------------------------------------------------------------------
c.advance = 0.05
c.updateDelay = 0.25
c.latency = c.advance
c.gcdSpellId = 61304
-------------------------------------------------------------------------------
---@class Core.flags
local flags = { -- defaults
    paused = true,
    loot = false,
    move = false,
    fullLog = false,
    autoDelJunk = false,
    autoLook = false,
    autoMelee = false
}
---@class Core.flags
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
        c.Error('get: invalid flag - ' .. tostring(key))
        return nil
    end,

    __newindex = function(_, key, value)
        local def = flags[key]
        if def == nil then
            c.Error('set: invalid flag ' .. tostring(key))
            return
        end
        -- При присвоении сохраняем в базу данных
        c.db[key] = value
    end
}
setmetatable(c.flags, flagsMeta)

function c.Paused(value)
    if type(value) == 'boolean' then
        c.flags.paused = value
    end
    if c.state.afk then
        return true
    end
    return c.flags.paused
end

-------------------------------------------------------------------------------
function c.IsLoaded()
    return c.loaded and c.state.inWorld
end

-------------------------------------------------------------------------------
local stateCacheIndex = 0
---@generic T: function
---@param func T
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

-------------------------------------------------------------------------------
--[[
UIParentLoadAddOn('Blizzard_DebugTools');
DevTools_Dump(c)
]]

--[[
  /run UIParentLoadAddOn('Blizzard_DebugTools');
  /fstack true
  /etrace
]]
-------------------------------------------------------------------------------
