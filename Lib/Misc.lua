-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
-- Кешируем функции и значения
local div255 = 1 / 255 --предвычисленное значение
local strlower = strlower
local tostring = tostring;
local select = select
local table_concat = table.concat
local wipe = wipe
local format = format
local time = time
local WrapTextInColorCode = WrapTextInColorCode
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local strlower = strlower
local IsMouseButtonDown = IsMouseButtonDown
local sqrt = sqrt
local bit = bit
-------------------------------------------------------------------------------
function c.StrContains(str, sub)
    if (not str or not sub) then
        return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

-------------------------------------------------------------------------------
local toStrBuffer = {}
function c.ToStr(...)
    local n = select('#', ...)
    if n == 0 then return '' end
    for i = 1, n do
        toStrBuffer[i] = tostring(select(i, ...))
    end
    local str = table_concat(toStrBuffer, ' ')
    wipe(toStrBuffer)
    return str
end

-------------------------------------------------------------------------------
-- Возвращает текущее локальное время в формате hh:mm:ss.
-- @return (string) Текущее время в секундах, hh:mm:ss.
function c.GetCurrentTime()
    -- Получаем локальное время в секундах
    local t = time()
    -- Вычисляем часы, минуты, секунды
    local hours = math.floor(t / 3600) % 24
    local minutes = math.floor(t / 60) % 60
    local seconds = math.floor(t % 60)
    -- Форматируем результат в hh:mm:ss
    return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end

-------------------------------------------------------------------------------
local lastValues = {}

-- Проверяет, изменилось ли значение для указанного ключа по сравнению с последним сохранённым.
-- @param key (string) Уникальный идентификатор для отслеживания значения.
-- @param value (any) Новое значение, которое нужно проверить и, при необходимости, сохранить.
-- @return (boolean) true, если значение изменилось или ключ ещё не существовал; false, если значение не изменилось.
function c.IsChanged(key, value)
    local lastValue = lastValues[key]
    if lastValue == value then
        return false -- value not changed
    end
    lastValues[key] = value
    return true -- value changed
end

-------------------------------------------------------------------------------
-- Округляет число до указанного количества десятичных знаков.
-- @param number (number) Число, которое нужно округлить.
-- @param decimals (number) Количество десятичных знаков, до которых нужно округлить число.
-- @return (number) Округленное число.
function c.Round(number, decimals)
    decimals = decimals or 0
    local multiplier = 10 ^
        decimals                                              -- Множитель для преобразования числа к целому типу после умножения
    return math.floor(number * multiplier + 0.5) / multiplier -- Округление и возвращение результата
end

-------------------------------------------------------------------------------

function c.PrintLoadClassModuleMessage(className)
    local name = WrapTextInColorCode(className:sub(1, 1) .. strlower(className:sub(2)),
        RAID_CLASS_COLORS[className].colorStr)
    c.Chat(name)
end

-------------------------------------------------------------------------------
-- button - Number or name of a mouse button (number,string)
-- 1 or LeftButton - Primary mouse button
-- 2 or RightButton - Secondary mouse button
-- 3 or MiddleButton - Third mouse button (or clickable scroll control)
-- 4 or Button4 - Fourth mouse button
-- 5 or Button5 - Fifth mouse button
-------------------------------------------------------------------------------
function c.IsMouse(n)
    return IsMouseButtonDown(n) == 1
end

-------------------------------------------------------------------------------
function c.Distance(x1, y1, z1, x2, y2, z2)
    if not (x1 and y1 and z1 and x2 and y2 and z2) then return 0 end
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return sqrt(dx * dx + dy * dy + dz * dz)
end

-------------------------------------------------------------------------------
