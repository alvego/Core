-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local math_random = math.random
-------------------------------------------------------------------------------
function c.UnitNeedKick(unit) -- cбивалка, проверяет название, сбиваемость и время сбивания
    unit = unit or 'target'
    local spell, left, duration, channel, notinterrupt = c.UnitCasting(unit)
    if not spell then return false end
    -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    if left < (channel and 0.5 or 0.2) then return false end
    -- Для игроков эмулируем сбивание ручками
    local salt = math_random() * 0.3         -- [0 .. 0.3]
    local kickZone = duration * (channel and (0.9 - salt) or (0.1 + salt))
    if left > kickZone then return false end -- пока нет смысла
    return spell, notinterrupt
end

-------------------------------------------------------------------------------
