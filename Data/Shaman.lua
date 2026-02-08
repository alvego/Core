---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
local UnitClass = UnitClass
-- luacheck: pop
local className = select(2, UnitClass('player'))

if className ~= 'SHAMAN' then return end

c.PrintLoadClassModuleMessage(className)

---@class Core.state
local st = c.state
--c.updateDelay = 0.25
-- luacheck: push ignore
local GetTotemInfo = GetTotemInfo
local UnitHealthMax = UnitHealthMax
local format = format
local IsSpellKnown = IsSpellKnown
-- luacheck: pop
c.Telemetry(function()
    return format('AOEtar: %d', c.GetEnemyCount(20, 'player'))
end)

local function HasMagmaTotem()
    local haveTotem, name = GetTotemInfo(1)
    return haveTotem and name == 'Тотем магмы VII'
end

local function updateEnhance()
    local reason, action, unit

    -- иногда в ротации есть необходимость прерывания своего каста
    reason = '#cast: %s'
    if st.playerCasting then return format(reason, st.playerCasting) end

    c.TimerToggle('needHeal', st.playerHP100 < (st.group and 50 or 80))
    c.TimerToggle('needMagmaTotem', st.ttd and st.ttd > 20)
    local needMagmaTotem = (c.TimerStarted('needMagmaTotem') and c.TimerMore('needMagmaTotem', 2)) or
        (not st.invalidTarget and UnitHealthMax('target') > 300000)
    local needHeal = c.TimerStarted('needHeal') and c.TimerMore('needHeal', 2)
    local mana100 = c.UnitMana100('player')
    local function aoe(n)
        return c.GetEnemyCount(20, 'player') > n
    end
    local _, _, stacks = c.HasMyBuff('Оружие Водоворота')
    local isInstant = stacks > 4
    local dist = st.targetExists and c.bUnitDistance('player', 'target') or 999

    reason, action, unit = 'Хп упало, дэф', 'Ярость шамана', 'player'
    if st.combatMode and st.playerHP100 < 40 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Мало ХП', 'Волна исцеления', 'player'
    if isInstant and st.combatMode and needHeal and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason = c.TryTarget(30, (st.attack or st.look) and 30 or 0)
    -- есть ли причина для остановки?.
    if reason then return reason end

    -- Дальше считаем что у нас есть валидная цель

    reason, action, unit = 'Рассовый спелл', 'Пламя дракона', 'target'
    if not st.pvp and c.CanSpell(action) then
        c.DoAction(reason, action)
        return reason
    end

    --[[     reason, action, unit = 'Вешаем дэбаф', 'Удар бури', 'target'
    if st.targetMelee and not c.HasMyBuff('Удар бури', unit) and c.CanGcdSpell(action, unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end ]]

    reason, action, unit = 'Шокаем боса сразу', 'Огненный шок', 'target'
    if c.CanGcdSpell(action, unit) and not aoe(3) and UnitHealthMax('target') > 500000 and not c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end


    reason, action, unit = 'Лава по шоку', 'Выброс лавы', 'target'
    if isInstant and not aoe(3) and c.CanGcdSpell(action, unit) and c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Мейн пока можем', 'Цепная молния', 'target'
    if isInstant and (not c.IsReadySpell('Выброс лавы') or not c.HasMyDebuff('Огненный шок', unit, 1)) and aoe(1) and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Заполнитель', 'Молния', 'target'
    if isInstant and (not c.IsReadySpell('Выброс лавы') or not c.HasMyDebuff('Огненный шок', unit, 1)) and not aoe(1) and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason = '#instantcast return'
    if isInstant then
        return reason
    end

    reason, action, unit = 'мало маны', 'Ярость шамана', 'player'
    if st.combatMode and mana100 < 40 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Основной мили удар', 'Удар бури', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Поджигаем !мили/хп>20000', 'Огненный шок', 'target'
    if c.CanGcdSpell(action, unit) and not aoe(3) and (UnitHealthMax('target') > 20000 or not st.targetMelee) and not c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'АОЕ или босс', 'Тотем магмы', 'target'
    if mana100 >= 30 and st.still and (aoe(2) or needMagmaTotem) and c.CanGcdSpell(action) and (dist < 10 or st.targetMelee) and not HasMagmaTotem() then
        c.DoAction(reason, action)
        return reason
    end

    reason, action, unit = 'Второй мили удар', 'Вскипание лавы', 'target'
    if c.CanGcdSpell(action, unit) and not c.IsReadySpell('Удар бури') then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'АОЕ', 'Кольцо огня', 'target'
    if aoe(4) and c.CanGcdSpell(action) and HasMagmaTotem() then
        c.DoAction(reason, action)
        return reason
    end

    reason, action, unit = 'Приземляем', 'Земной шок', 'target'
    if c.CanGcdSpell(action, unit) and (c.HasMyDebuff('Огненный шок', unit, 1) or not c.IsReadySpell('Огненный шок')) then
        c.DoAction(reason, action, unit)
        return reason
    end

    if st.gcd then return '#gcd' end
    return '#none'
end

local function updateElemental()
    local reason, action, unit

    reason = '#cast: %s'
    if st.playerCasting then return format(reason, st.playerCasting) end

    reason, action, unit = 'Рассовый спелл', 'Пламя дракона', 'target'
    if not st.pvp and c.CanSpell(action) then
        c.DoAction(reason, action)
        return reason
    end

    reason, action, unit = 'Шокаем боса сразу', 'Огненный шок', 'target'
    if c.CanGcdSpell(action, unit) and not c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Лава по шоку', 'Выброс лавы', 'target'
    if c.CanGcdSpell(action, unit) and c.HasMyDebuff('Огненный шок', unit, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Заполнитель', 'Молния', 'target'
    if (not c.IsReadySpell('Выброс лавы') or not c.HasMyDebuff('Огненный шок', unit, 1)) and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    if st.gcd then return '#gcd' end
    return '#none'
end

c.Update(function()
    local stopReason = c.GetStopReason()
    if stopReason then
        c.LogWhatHappend(stopReason)
        return
    end

    local isEnhance = IsSpellKnown(51533, false)   -- наличие спелла 'Дух дикого волка' энх
    local isElemental = IsSpellKnown(16166, false) -- наличие спелла 'Покорение стихий' элем

    if isEnhance then
        c.LogWhatHappend(updateEnhance())
    elseif isElemental then
        c.LogWhatHappend(updateElemental())
    else
        return '#not_dps_spec' -- Restoration хил спек
    end
end)
