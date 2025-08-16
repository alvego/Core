------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
-- Кешируем функции и значения
local div255 = 1 / 255 --предвычисленное значение
local strlower = strlower
local tostring = tostring;
local select = select
local table_concat = table.concat
local wipe = wipe
local format = format
local time = time
------------------------------------------------------------------------------------------------------------------
local hexCache = {}
function ns.Hex2Rgb(hex)
    if not hexCache[hex] then
        if not hex or #hex ~= 6 then
            hexCache[hex] = { 0, 0, 0 }
        else
            hexCache[hex] = {
                tonumber(hex:sub(1, 2), 16) * div255,
                tonumber(hex:sub(3, 4), 16) * div255,
                tonumber(hex:sub(5, 6), 16) * div255
            }
        end
    end

    local c = hexCache[hex]
    return c[1], c[2], c[3]
end

--------------------------------------------------------------------------------------
local numCache = {}
function ns.Num2Rgb(num) -- делает bp числа num (0..10000) цвет r, g, b 0..1 (number)
    if not numCache[num] then
        if not num then
            numCache[num] = { 0, 0, 0 }
        else
            local c6 = string.sub(format('%X', num), -6)
            local hex = string.rep('0', 6 - #c6) .. c6
            numCache[num] = {
                tonumber(string.sub(hex, 1, 2) or 0, 16) * div255,
                tonumber(string.sub(hex, 3, 4) or 0, 16) * div255,
                tonumber(string.sub(hex, 5, 6) or 0, 16) * div255
            }
        end
    end

    local c = numCache[num]
    return c[1], c[2], c[3]
end

------------------------------------------------------------------------------------------------------------------
function ns.StrContains(str, sub)
    if (not str or not sub) then
        return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

------------------------------------------------------------------------------------------------------------------
local toStrBuffer = {}
function ns.ToStr(...)
    local n = select('#', ...)
    if n == 0 then return "" end
    for i = 1, n do
        toStrBuffer[i] = tostring(select(i, ...))
    end
    local str = table_concat(toStrBuffer, ' ')
    wipe(toStrBuffer)
    return str
end

------------------------------------------------------------------------------------------------------------------
-- Возвращает текущее локальное время в формате hh:mm:ss.
-- @return (string) Текущее время в секундах, hh:mm:ss.
function ns.GetCurrentTime()
    -- Получаем локальное время в секундах
    local t = time()
    -- Вычисляем часы, минуты, секунды
    local hours = math.floor(t / 3600) % 24
    local minutes = math.floor(t / 60) % 60
    local seconds = math.floor(t % 60)
    -- Форматируем результат в hh:mm:ss
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

------------------------------------------------------------------------------------------------------------------
local lastValues = {}

-- Проверяет, изменилось ли значение для указанного ключа по сравнению с последним сохранённым.
-- @param key (string) Уникальный идентификатор для отслеживания значения.
-- @param value (any) Новое значение, которое нужно проверить и, при необходимости, сохранить.
-- @return (boolean) true, если значение изменилось или ключ ещё не существовал; false, если значение не изменилось.
function ns.IsChanged(key, value)
    local lastValue = lastValues[key]
    if lastValue == value then
        return false -- value not changed
    end
    lastValues[key] = value
    return true -- value changed
end

------------------------------------------------------------------------------------------------------------------
-- Округляет число до указанного количества десятичных знаков.
-- @param number (number) Число, которое нужно округлить.
-- @param decimals (number) Количество десятичных знаков, до которых нужно округлить число.
-- @return (number) Округленное число.
function ns.Round(number, decimals)
    decimals = decimals or 0
    local multiplier = 10 ^
        decimals                                              -- Множитель для преобразования числа к целому типу после умножения
    return math.floor(number * multiplier + 0.5) / multiplier -- Округление и возвращение результата
end
