---@class Core
local c = Core
---@class Core.state
local st = c.state

local SpellIsTargeting = SpellIsTargeting
local GetSpellInfo = GetSpellInfo
local Dismount = Dismount
local VehicleExit = VehicleExit
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local IsCurrentSpell = IsCurrentSpell
local UnitIsUnit = UnitIsUnit
local type = type


---Строка причины остановки из-за еды
c.stopReasonMount = '#mount'
---Строка причины остановки из-за еды
c.stopReasonEat = '#eat'
---Строка причины остановки из-за цели
c.stopReasonTargeting = '#targeting'


---Список аур пищи и питья
local eatAuras = {
    'Пища',
    'Питье'
}


---Снимает езду/транспорт/ауру
function c.Dismount()
    if not st.mounted then return end
    if st.mount then
        Dismount()
        return
    end

    if st.vehicle then
        VehicleExit()
        return
    end

    if st.mountAura then
        local auraName = GetSpellInfo(st.mountAura)
        c.Command('/cancelaura ' .. auraName)
        return
    end
end

---Получает причину остановки
---@return string? Строка причины остановки или nil, если нет причины
function c.GetStopReason()
    if SpellIsTargeting() then
        return c.stopReasonTargeting
    end

    if st.mounted then
        if not st.attack then
            return c.stopReasonMount
        end
        c.Dismount()
    end

    if not st.attack then
        local auraName = c.HasBuff(eatAuras, 'player')
        if auraName then
            return c.stopReasonEat
        end
    end

    return nil
end

---Список дебафов останавливающих атаку
local stopAttackDebuff = {
    'Паралич',
    'Превращение',
    'Ошеломление',
    'Покаяние',
    'Сон',
    -- 'Соблазн',
    -- 'Страх',
    -- 'Вой ужаса',
    -- 'Устрашающий крик',
    -- 'Контроль над разумом',
    -- 'Глубинный ужас',
    -- 'Ментальный крик'
}
---Пытается выбрать новую цель или проверяет текущую
---@param range number? Максимальная дистанция (0 - ближний бой)
---@param angle number? Угол зрения (0 - без ограничений)
---@return string? Причина остановки или nil, если всё хорошо
function c.TryTarget(range, angle)
    if st.invalidTarget then
        if st.combatMode and c.SearchTarget(range or 40, angle) then
            -- не делаем паузы после выбора цели (новый onUpdate начнется незамедлительно)
            c.ImmediatelyNextUpdate()
            -- выходим так как нужно обновить state
            return '#выбирали новую цель, причина: ' .. st.invalidTarget
        end
        return '#' .. st.invalidTarget
    end

    if c.flags.autoMelee and not st.targetMelee and not c.IsManualTarget() and c.SearchTarget(0, angle) then
        -- не делаем паузы после выбора цели (новый onUpdate начнется незамедлительно)
        c.ImmediatelyNextUpdate()
        -- выходим так как нужно обновить state
        return '#выбирали цель для ближнего боя'
    end

    if not st.attack and not st.targetCombat and not st.autoattack then
        return '#цель не в бою, не нажата атака, не вкл автоатака'
    end
    local stopDebuff = not st.attack and c.HasDebuff(stopAttackDebuff)
    if st.autoattack then
        if stopDebuff then
            local stopAttackReason = '#не бьем в ' .. stopDebuff
            c.Command('/stopattack')
            c.Command('/petstop')
            c.Command('/petfollow')
            return stopAttackReason
        end
    elseif not stopDebuff then
        c.Command('/startattack [exists, harm, nodead]')
        c.Command('/petattack [exists, exists, nodead]')
    end
    local dist = c.UnitDistance('target', 'player')
    if c.flags.move and not st.targetMelee and (dist < 25 or st.attack) and not c.IsTurnToUnit() and
        (st.targetStill or not UnitIsUnit('target-target', 'player')) then
        c.MoveToUnit('target', 100)
    end
    if c.flags.autoLook and st.targetMelee and st.combatMode and st.still then
        c.TurnToUnit('target')
    end
    return nil
end

---Проверяет, можно ли использовать заклинание
---@param spell string Заклинание
---@param unit string? Юнит
---@param interval number? Интервал между использованиями
---@return boolean Можно ли использовать
function c.CanSpell(spell, unit, interval)
    if not spell or type(spell) ~= 'string' then return false end
    if interval and not c.TimerMore(spell, interval) then return false end
    if c.IsSpellFailedRecently(spell) then return false end
    if not IsUsableSpell(spell) then return false end
    if unit and not c.UnitInLOS('player', unit) then return false end
    if type(c.CustomCanSpell) == 'function' and not c.CustomCanSpell(spell, unit) then return false end
    return c.CanUseSpell(spell, unit)
end

---Проверяет, можно ли использовать гкд заклинание
---@param spell string Заклинание
---@param unit string? Юнит
---@param interval number? Интервал между использованиями
---@return boolean Можно ли использовать
function c.CanGcdSpell(spell, unit, interval)
    if st.gcd then return false end
    return c.CanSpell(spell, unit, interval)
end

---Проверяет, можно ли использовать предмет
---@param item string Предмет
---@param unit string? Юнит
---@return boolean canUse Можно ли использовать
---@return string reason Можно ли использовать
function c.CanItem(item, unit)
    if not IsUsableItem(item) then return false, '!usable item' end
    return c.CanUseAction(item, unit)
end

---Проверяет, можно ли использовать текущее заклинание
---@param spell string Заклинание
---@param unit string? Юнит
---@return boolean canUse Можно ли использовать
function c.CanCurrentSpell(spell, unit)
    if c.TimerLess('CurrentSpell', 0.1) then return false end
    if IsCurrentSpell(spell) then return false end
    if not c.CanSpell(spell, unit) then return false end
    c.TimerStart('CurrentSpell')
    return true
end

---Проверяет, не использовалось ли заклинание в последний раз с заданным интервалом
---@param spell string|number|table Заклинание или таблица заклинаний
---@param interval number Интервал между использованиями
---@return boolean notUsed Не использовалось ли
local function isSpellNotUsed(spell, interval)
    if not spell then return false end
    if type(spell) == 'number' then
        spell = c.SpellStore[spell] or GetSpellInfo(spell)
    end
    if not spell or type(spell) ~= 'string' then return false end
    return c.TimerMore(spell, interval)
end


---Проверяет, не использовалось ли заклинание в последний раз с заданным интервалом (для таблицы)
---@param spell string|number|table Заклинание или таблица заклинаний
---@param interval number Интервал между использованиями
---@return boolean notUsed Не использовалось ли
function c.IsSpellNotUsed(spell, interval)
    if type(spell) ~= 'table' then return isSpellNotUsed(spell, interval) end
    if #spell < 1 then return false end
    for i = 1, #spell do
        if not isSpellNotUsed(spell[i], interval) then return false end
    end
    return true
end
