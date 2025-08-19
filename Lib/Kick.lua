------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitLevel = UnitLevel
local math_random = math.random
------------------------------------------------------------------------------------------------------------------
function ns.UnitNeedKick(unit, kickByStun) -- cбивалка, проверяет название, сбиваемость и время сбивания
    unit = unit or 'target'
    if kickByStun and UnitLevel(unit) == -1 then return false end
    local spell, left, duration, channel, notinterrupt = ns.UnitCasting(unit)
    if not spell then return false end
    if notinterrupt and not kickByStun then return false end

    -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    if left < (channel and 0.5 or 0.2) then return false end
    if not UnitIsPlayer(unit) then
        return spell -- в pve сбиваем по первой возможности
    end
    -- Для игроков эмулируем сбивание ручками
    local salt = math_random() * 0.3         -- [0 .. 0.3]
    local kickZone = duration * (channel and (0.9 - salt) or (0.1 + salt))
    if left > kickZone then return false end -- пока нет смысла
    return spell
end

------------------------------------------------------------------------------------------------------------------
