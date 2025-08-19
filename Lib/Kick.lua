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
    if left < 0.1 then return false end
    local salt = math_random() * 0.3         -- [0 .. 0.3]
    local kickZone = duration * (channel and (0.9 - salt) or (0.1 + salt))
    if left > kickZone then return false end -- пока нет смысла
    return spell
end

------------------------------------------------------------------------------------------------------------------
