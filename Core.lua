-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
Core = {}
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local tostring = tostring
local error = error
local setmetatable = setmetatable
local format = format
local UnitIsAFK = UnitIsAFK
-------------------------------------------------------------------------------
c.name = ...
c.icon = format([[Interface\AddOns\%s\textures\serp_molot_debug.blp]], c.name)
c.db = {}
c.state = {}
c.stateCache = {}
c.loaded = false
-------------------------------------------------------------------------------
c.advance = 0.05
c.latency = c.advance
c.gcdSpellId = 61304
-------------------------------------------------------------------------------
local flags = { -- defaults
    paused = true,
    loot = false,
    move = false,
    fullLog = false,
    autoDelJunk = false,
    autoLook = false,
    autoMelee = false
}

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
        error('get: invalid flag - ' .. tostring(key))
        return nil
    end,

    __newindex = function(_, key, value)
        local def = flags[key]
        if def == nil then
            error('set: invalid flag ' .. tostring(key))
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
    if UnitIsAFK('player') == 1 then
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
