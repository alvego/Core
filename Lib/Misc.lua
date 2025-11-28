-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
-- Кешируем функции и значения
local strlower = strlower
local tostring = tostring;
local select = select
local table_concat = table.concat
local wipe = wipe
local time = time
local WrapTextInColorCode = WrapTextInColorCode
local UnitClass = UnitClass
local UnitCreatureType = UnitCreatureType
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local IsMouseButtonDown = IsMouseButtonDown
local sqrt = sqrt
local UnitIsUnit = UnitIsUnit
local GetCursorInfo = GetCursorInfo
local ClearCursor = ClearCursor
local StaticPopup1 = StaticPopup1
local StaticPopup1Button1 = StaticPopup1Button1
local StaticPopup1Button2 = StaticPopup1Button2
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
function c.FindValue(values, checkFn, ...)
    for i = 1, #values do
        local value = checkFn(values[i], ...)
        if value ~= nil then return value end
    end
    return nil
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
local creatureColors = { -- Летающее, Магический зверь, Водное под вопросом
    ["Животное"] = "aa228B22", -- лесной зелёный
    ["Дракон"] = "aa8A2BE2", -- фиолетовый
    ["Летающее"] = "aa87CEEB", -- небесно-голубой
    ["Гуманоид"] = "aaEEFF00", -- жёлтый
    ["Существо"] = "aaD2691E", -- коричневый
    ["Магический зверь"] = "aaFF1493", -- малиновый
    ["Спутник"] = "aaFF69B4", -- розовый
    ["Водное"] = "aa1E90FF", -- синий
    ["Нежить"] = "aaA0A0A0", -- серый
    ["Демон"] = "aaFF0000", -- красный
    ["Элементаль"] = "aa00FFFF", -- голубой
    ["Великан"] = "aaFF8C00", -- оранжевый
    ["Механизм"] = "aaC0C0C0", -- серебристый
    ["Тотем"] = "aa556B2F", -- оливково-зелёный
    ["Не указано"] = "aaFFFFFF", -- белый
}
function c.GetUnitColorHex(unit)
    unit = unit or 'target'
    if not UnitExists(unit) then return "aaffffff" end

    local _, class = UnitClass(unit)
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return string.format("ff%02x%02x%02x",
            math.floor(c.r * 255),
            math.floor(c.g * 255),
            math.floor(c.b * 255))
    end

    -- Fallback: цвет по типу существа
    local ctype = UnitCreatureType(unit)
    return creatureColors[ctype] or "aaffffff"
end

-------------------------------------------------------------------------------
function c.ClearCursor()
    local infoType = GetCursorInfo()
    if infoType then
        -- Курсор держит что-то (например, item, spell и т.д.)
        c.Log("#ClearCursor from " .. infoType)
        ClearCursor() -- Очищаем, если нужно
    end
end

-------------------------------------------------------------------------------
function c.UnitInfo(unit)
    if not unit or not UnitExists(unit) then return WrapTextInColorCode('!exists', 'aaff0000') end
    local name = UnitName(unit)
    if not name then return WrapTextInColorCode('!name', 'aaff0000') end
    name = WrapTextInColorCode(name, c.GetUnitColorHex(unit))
    local level = UnitLevel(unit)
    if level then name = name .. WrapTextInColorCode('[' .. level .. ']', 'FF0D7EC0') end
    if UnitIsUnit(unit, 'player') then return name end
    local ctype = UnitCreatureType(unit)
    if ctype then
        name = name .. WrapTextInColorCode(strlower(ctype), creatureColors[ctype] or 'aaffffff')
    end
    local d = c.UnitDistance('player', unit)
    if d then
        name = name .. WrapTextInColorCode('(' .. c.Round(d) .. 'м)', 'FF308F9B')
    end
    if UnitIsDead(unit) then
        name = name .. WrapTextInColorCode('труп', 'ff333333')
    end
    return name
end

-------------------------------------------------------------------------------
local function autoButton(btn, btnText)
    if btn:IsVisible() ~= 1 or btn:IsEnabled() ~= 1 then return false end
    local text = btn:GetText()
    if text ~= btnText then return false end
    c.Log('Жмем', btnText)
    btn:Click()
    return true
end
-------------------------------------------------------------------------------
function c.AutoPopup(messagePart, btnText)
    local popup = StaticPopup1
    if popup:IsVisible() ~= 1 then return false end
    local text = popup.text:GetText()
    if not c.StrContains(text, messagePart) then return false end
    c.Log('Диалог', text)
    return autoButton(StaticPopup1Button1, btnText) or autoButton(StaticPopup1Button2, btnText)
end

-------------------------------------------------------------------------------
function c.PrintTargetAuras() -- for debug
    local target = 'target'
    if not UnitExists(target) then
        target = 'player'
    end
    local unit = UnitName(target)
    if unit == nil then return end
    local guid = UnitGUID(target)
    c.MessageLog('Auras for GUID:' .. guid, unit, nil, 0, 0, 1)
    local idx = 0
    repeat
        local spellId, count, duration, endTime, isMine, isDebuff = c.UnitAuraByIndex(target, idx)
        if spellId == nil then break end
        if spellId and spellId ~= 0 then
            local name, _, icon = GetSpellInfo(spellId)
            local link = GetSpellLink(spellId)
            if name then
                local method = isDebuff and UnitDebuff or UnitBuff
                local aura, _, _, _, _, _, _, _, _, _, auraId = method(target, name)
                local findInUI = aura and (auraId == spellId)
                c.MessageLog(
                    format(
                        '%s |cff%sUI|r',
                        link or name,
                        findInUI and '00ff00' or '000000'
                    ),
                    format('|cff%s%s|r', isDebuff and 'ff0000' or '00ff00', spellId), icon, 1, 1, 1
                )
            end
        end
        idx = idx + 1
    until false
end

-------------------------------------------------------------------------------
-- fix overlay error
local ActionButton_AllOverlayAlphaUpdate = ActionButton_AllOverlayAlphaUpdate
_G.ActionButton_AllOverlayAlphaUpdate = function(alpha)
    if type(alpha) ~= 'number' then alpha = 0 end
    ActionButton_AllOverlayAlphaUpdate(alpha)
end
