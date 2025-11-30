-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local UnitClass = UnitClass
-------------------------------------------------------------------------------
local className = select(2, UnitClass('player'))
-------------------------------------------------------------------------------
if className ~= 'SHAMAN' then return end
-------------------------------------------------------------------------------
c.PrintLoadClassModuleMessage(className)
-------------------------------------------------------------------------------
local st = c.state
--c.updateDelay = 0.25
local GetTotemInfo = GetTotemInfo

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    return format('AOEtar: %d', c.GetEnemyCount(10, 'player'))
end)
-------------------------------------------------------------------------------
local function HasMagmaTotem()
    local haveTotem, name = GetTotemInfo(1)
    return haveTotem and name == 'Тотем магмы VII'
end
-------------------------------------------------------------------------------
local function updateEnhance()
    local reason, action, unit
    -------------------------------------------------------------------------------
    -- иногда в ротации есть необходимость прерывания своего каста
    reason = '#cast [%s]'
    if st.playerCasting then return format(reason, st.playerCasting) end
    -------------------------------------------------------------------------------
    c.TimerToggle('needHeal', st.playerHP100 < (st.group and 50 or 80))
    c.TimerToggle('still', st.still)
    c.TimerToggle('needMagmaTotem', st.ttd and st.ttd > 20)
    local needMagmaTotem = c.TimerStarted('needMagmaTotem') and c.TimerMore('needMagmaTotem', 2)
    local still = c.TimerStarted('still') and c.TimerMore('still', 1)
    local needHeal = c.TimerStarted('needHeal') and c.TimerMore('needHeal', 2)
    local mana100 = c.UnitMana100('player')
    local aoe = c.GetEnemyCount(10, 'player') > 2
    local _, _, stacks = c.HasMyBuff('Оружие Водоворота')
    local isInstant = stacks > 4
    local dist = c.UnitDistance('target', 'player')
    -------------------------------------------------------------------------------
    reason, action, unit = 'Хп упало, дэф', 'Ярость шамана', 'player'
    if st.combatMode and st.playerHP100 < 40 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'МАНА упала, дэф', 'Ярость шамана', 'player'
    if st.combatMode and mana100 < 50 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Мало ХП', 'Волна исцеления', 'player'
    if isInstant and st.combatMode and needHeal and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason = c.TryTarget(true, 30, st.attack or st.look)
    -- есть ли причина для отстановки?.
    if reason then return reason end
    -------------------------------------------------------------------------------
    -- Дальше считаем что у нас есть валидная цель
    -------------------------------------------------------------------------------
  
    reason, action, unit = 'Лава по шоку', 'Выброс лавы', 'target'
    if isInstant and not aoe and c.CanGcdSpell(action, unit) and c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Аое или много маны', 'Цепная молния', 'target'
    if isInstant and mana100 > 40 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Заполнитель', 'Молния', 'target'
    if isInstant and mana100 <= 40 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason = '#instantcast return'
    if isInstant then
        return reason
    end

    reason, action, unit = 'Минибурст', 'Варварский ритуал', 'target'
    if not c.pvp and c.CanSpell(action) and dist < 8 and not c.HasMyBuff('Варварский ритуал') then
        c.DoAction(reason, action)
        return reason
    end

    reason, action, unit = 'Основной мили удар', 'Удар бури', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'АОЕ или босс', 'Тотем магмы', 'target'
    if mana100 >= 30 and still and (aoe or needMagmaTotem) and c.CanGcdSpell(action) and dist < 6 and not HasMagmaTotem() then
        c.DoAction(reason, action)
        return reason
    end

    reason, action, unit = 'АОЕ', 'Кольцо огня', 'target'
    if aoe and c.CanGcdSpell(action) and HasMagmaTotem() then
        c.DoAction(reason, action)
        return reason
    end

    reason, action, unit = 'Второй мили удар', 'Вскипание лавы', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Поджигаем', 'Огненный шок', 'target'
    if c.CanGcdSpell(action, unit) and not c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Приземляем', 'Земной шок', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Морозим', 'Ледяной шок', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    if st.gcd then return '#gcd' end
    return '#none'
end
-------------------------------------------------------------------------------
function c.Update()
    local stopReason = c.GetStopReason()
    if stopReason then
        c.LogWhatHappend(stopReason)
        return
    end

    c.LogWhatHappend(updateEnhance())
end

-------------------------------------------------------------------------------
