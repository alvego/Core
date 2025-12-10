-------------------------------------------------------------------------------
-- Core by Unknown Coder
-------------------------------------------------------------------------------
---@class Core
local c = Core
-------------------------------------------------------------------------------
local wipe = wipe
-------------------------------------------------------------------------------
local pool = {} -- Общий пул для всех таблиц

-- Получить таблицу из пула
function c.TablePoolAcquire()
    local t = next(pool)
    if t then
        pool[t] = nil
        return t
    end
    return {}
end

-- Вернуть таблицу в пул
function c.TablePoolRelease(t)
    wipe(t) -- Очищаем таблицу
    pool[t] = true
end

-- Очистить весь пул
function c.TablePoolClear()
    wipe(pool)
end

-- Получить размер пула (для отладки)
function c.TablePoolGetSize()
    local count = 0
    for _ in pairs(pool) do count = count + 1 end
    return count
end

-------------------------------------------------------------------------------
