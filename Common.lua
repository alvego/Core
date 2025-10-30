-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local SpellIsTargeting = SpellIsTargeting
local GetSpellInfo = GetSpellInfo
local IsMounted = IsMounted
local Dismount = Dismount
local CanExitVehicle = CanExitVehicle
local VehicleExit = VehicleExit
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local IsCurrentSpell = IsCurrentSpell
local type = type
-------------------------------------------------------------------------------
local st = c.state
local mountAuras = {
    311563, -- Магический пузырь
    32556   -- Полет
}

local eatAuras = {
    'Пища',
    'Питье'
}
c.stopReasonMount = '#mount'
c.stopReasonEat = '#eat'
c.stopReasonTargeting = '#targeting'
-------------------------------------------------------------------------------
function c.GetStopReason()
    if SpellIsTargeting() then
        return c.stopReasonTargeting
    end

    if IsMounted() then
        if not c.attack then
            return c.stopReasonMount
        end
        Dismount()
    end

    if CanExitVehicle() then
        if not c.attack then
            return c.stopReasonMount
        end
        VehicleExit()
    end

    local mountAura = c.UnitAuraByID('player', mountAuras)
    if mountAura then
        local auraName = GetSpellInfo(mountAura)
        if not c.attack then
            return c.stopReasonMount
        end
        c.CancelBuff(auraName)
    end


    if not c.attack then
        local auraName = c.HasBuff(eatAuras, 'player')
        if auraName then
            return c.stopReasonEat
        end
    end

    return nil
end

-------------------------------------------------------------------------------

-- FindAndSelectNewTarget

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

function c.TryTarget()
    if st.invalidTarget then
        if st.combatMode then
            c.FindAndSelectNewTarget()
        end

        return '#' .. st.invalidTarget
    end

    if not st.attack and not st.combatTarget and not st.autoattack then
        return '#цель не в бою, не нажата атака, не вкл автоатака'
    end
    local stopDebuff = not st.attack and c.HasDebuff(stopAttackDebuff)
    if st.autoattack then
        if stopDebuff then
            local stopAttackReason = '#не бъем в ' .. stopDebuff
            c.DoAction(stopAttackReason, 'stop')
            return stopAttackReason
        end
    elseif not stopDebuff then
        c.DoAction('#автоатака', 'attack')
    end
    return nil
end

-------------------------------------------------------------------------------
function c.CanUseSpell(spell, unit, interval)
    if not spell or type(spell) ~= 'string' then return false end
    if interval and not c.TimerMore(spell, interval) then return false end
    if c.IsSpellFailedRecently(spell) then return false end
    if not IsUsableSpell(spell) then return false end
    return c.CanUseAction(spell, unit)
end

-------------------------------------------------------------------------------
function c.CanUseGcdSpell(spell, unit, interval)
    if st.gcd then return false end
    return c.CanUseSpell(spell, unit, interval)
end

-------------------------------------------------------------------------------
function c.CanUseItem(item, unit)
    if not IsUsableItem(item) then return false end
    return c.CanUseAction(item, unit)
end

-------------------------------------------------------------------------------
function c.CanUseCurrentSpell(spell, unit)
    if c.TimerLess('CurrentSpell', 0.1) then return false end
    if IsCurrentSpell(spell) then return false end
    if not c.CanUseSpell(spell, unit) then return false end
    c.TimerStart('CurrentSpell')
    return true
end

-------------------------------------------------------------------------------
local function isSpellNotUsed(spell, interval)
    if not spell then return false end
    if type(spell) == 'number' then
        spell = c.SpellStore[spell] or GetSpellInfo(spell)
    end
    if not spell or type(spell) ~= 'string' then return false end
    return c.TimerMore(spell, interval)
end

-------------------------------------------------------------------------------
function c.IsSpellNotUsed(spell, interval)
    if type(spell) ~= 'table' then return isSpellNotUsed(spell, interval) end
    if #spell < 1 then return false end
    for i = 1, #spell do
        if not isSpellNotUsed(spell[i], interval) then return false end
    end
    return true
end

-------------------------------------------------------------------------------
-- Функция для преобразования статуса в текст
function c.GetThreatStatusText(status)
    if status == 0 then
        return "нет угрозы"
    elseif status == 1 then
        return "есть угроза"
    elseif status == 2 then
        return "овертаунт"
    elseif status == 3 then
        return "танкуем"
    else
        return "неизвестно"
    end
end
