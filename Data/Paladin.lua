-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local UnitClass = UnitClass
-------------------------------------------------------------------------------
local className = select(2, UnitClass('player'))
-------------------------------------------------------------------------------
if className ~= 'PALADIN' then return end
-------------------------------------------------------------------------------
c.PrintLoadClassModuleMessage(className)
-------------------------------------------------------------------------------
local st = c.state
local spell = c.SpellStore
local addSpell = c.SpellStoreAdd
local UnitCreatureType = UnitCreatureType
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsUnit = UnitIsUnit
local format = format
local tostring = tostring
-------------------------------------------------------------------------------
local isLoaded = false;
local forbearanceId = 25771 -- Воздержанность
local cleanseTypes = { 'Magic', 'Disease', 'Poison' }
local sealAuras, stanceAuras, stanceDefenceAuras, blessingAuras
-------------------------------------------------------------------------------
local function onLoad()
    if isLoaded then return end

    addSpell('Праведное неистовство')

    addSpell('Печать повиновения')
    addSpell('Печать порчи')
    addSpell('Печать мудрости')
    addSpell('Печать справедливости')
    addSpell('Печать Света')
    addSpell('Печать праведности')

    addSpell('Аура благочестия')
    addSpell('Аура воздаяния')
    addSpell('Аура сосредоточенности')
    addSpell('Аура защиты от темной магии')
    addSpell('Аура защиты от магии льда')
    addSpell('Аура защиты от огня')
    addSpell('Аура воина Света')

    addSpell('Благословение неприкосновенности')
    addSpell('Благословение королей')
    addSpell('Благословение могущества')
    addSpell('Благословение мудрости')

    addSpell('Великое благословение неприкосновенности')
    addSpell('Великое благословение королей')
    addSpell('Великое благословение могущества')
    addSpell('Великое благословение мудрости')

    addSpell('Божественная защита')
    addSpell('Святая клятва')

    sealAuras = {
        spell['Печать повиновения'],
        spell['Печать порчи'],
        spell['Печать мудрости'],
        spell['Печать справедливости'],
        spell['Печать Света'],
        spell['Печать праведности']
    }

    stanceAuras = {
        spell['Аура благочестия'],
        spell['Аура защиты от темной магии'],
        spell['Аура защиты от магии льда'],
        spell['Аура защиты от огня'],
        spell['Аура сосредоточенности'],
        spell['Аура воздаяния'],
        spell['Аура воина Света']
    }

    stanceDefenceAuras = {
        spell['Аура благочестия'],
        spell['Аура защиты от темной магии'],
        spell['Аура защиты от магии льда'],
        spell['Аура защиты от огня']
    }

    blessingAuras = {
        spell['Благословение неприкосновенности'],
        spell['Благословение королей'],
        spell['Благословение могущества'],
        spell['Благословение мудрости']
    }


    isLoaded = true;
end
c.AttachEvent('PLAYER_ENTERING_WORLD', onLoad)

-------------------------------------------------------------------------------
local function getAvailableStance(unit)
    for i = 1, #stanceAuras do
        local stance = stanceAuras[i]
        if not c.UnitAuraByID(unit, stance) then
            return stance
        end
    end
    return nil
end

-------------------------------------------------------------------------------
local function getAvailableBlessing(unit)
    for i = 1, #blessingAuras do
        local blessing = spell[blessingAuras[i]]
        if not c.HasBuff(blessing, unit) then
            return blessing
        end
    end
    return nil
end

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if not isLoaded then return end
    return c.TelemetryRedBool('TANK', c.UnitAuraByID('player', spell['Праведное неистовство']))
end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if not isLoaded then return end
    return c.TelemetryRedBool('AURA', c.UnitAuraByID('player', stanceDefenceAuras))
end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if not isLoaded then return end --
    return c.TelemetryRedBool('5M', not UnitExists('target') or c.IsSpellInRange('Молот праведника', 'target'))
end)

-------------------------------------------------------------------------------
-- Новая функция для обработки агро-способностей
-------------------------------------------------------------------------------
local function tryThreat(unit)
    if c.IsInvalidTarget(unit) then
        return -- не верная цель
    end

    local isTanking, status, threatPercent = UnitDetailedThreatSituation('player', unit) -- 0: нет угрозы, 1: есть угроза, 2: овертаунт, 3: танк
    local reason, action
    local target = unit .. 'target'


    if isTanking then
        return -- Unit не танкует
    end

    if UnitIsUnit('player', target) then
        return -- Не агрим с себя
    end

    if UnitExists('focus') and UnitIsUnit(target, 'focus') then
        return -- Не агрим с фокуса
    end

    if c.UnitIsTank(target) then
        return -- Не агрим с танков
    end

    if c.TimerLess('Длань возмездия', 1) or c.TimerLess('Праведная защита', 1) then
        return -- недавно прожали, не частим
    end

    reason = string.format(
        'агрим %s (%s): %s, угроза: %d, бъет: %s',
        UnitName(unit),
        unit,
        c.GetThreatStatusText(status),
        threatPercent or 0,
        UnitExists(target) and UnitName(target) or 'Нет цели'
    )
    action = 'Длань возмездия'
    if IsUsableSpell('Длань возмездия') and c.CanUseAction(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    action = 'Праведная защита'
    if UnitIsPlayer(target) and IsUsableSpell('Праведная защита') and c.CanUseAction(action, target) then
        c.DoAction(reason, action, target)
        return reason
    end
end


-------------------------------------------------------------------------------
local function updateProto()
    local reason, action, unit
    -------------------------------------------------------------------------------
    -- иногда в ротации есть необходимость прерывания своего каста
    reason = 'кастую [%s]'
    if st.playerCasting then return format(reason, st.playerCasting) end

    -------------------------------------------------------------------------------
    c.TimerToggle('needHeal', st.playerHP100 < (st.group and 40 or 60)) -- таймер идет пока hp < 40
    c.TimerToggle('needMoreDamage', st.ttd and st.ttd > 10)             -- таймер идет пока ttd > 20
    c.TimerToggle('still', st.still)
    -------------------------------------------------------------------------------
    -- hp меньше половины уже 2 секунды
    local needHeal = c.TimerStarted('needHeal') and c.TimerMore('needHeal', 1.5) and st.combatMode
    local needMoreDamage = c.TimerStarted('needMoreDamage') and c.TimerMore('needMoreDamage', 1)
    local still = c.TimerStarted('still') and c.TimerMore('still', 1)
    -- нужно бурстить
    local needBurst = st.targetHard and needMoreDamage --and dancingRuneWeaponReady
    -------------------------------------------------------------------------------
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    -------------------------------------------------------------------------------
    local mana100 = c.UnitMana100('player')
    local useMana = st.attack or (mana100 > 50)

    -------------------------------------------------------------------------------
    --- танкуем или нет, вот в чем вопрос
    local isTank = c.UnitAuraByID(unit, spell['Праведное неистовство'])
    -------------------------------------------------------------------------------
    -- автовключание если в группе и есть отметка что танк
    local hasTankMark = UnitGroupRolesAssigned("player") == 'TANK'
    reason, action, unit = 'Влючаем баф для танкования', 'Праведное неистовство', 'player'
    if not st.gcd and hasTankMark and not isTank and c.CanUseGcdSpell(action, unit, 5) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Нужно обновить печать', 'Печать повиновения', 'player'
    if not st.gcd and c.CanUseGcdSpell(action, unit, 10) and not c.UnitAuraByID(unit, sealAuras) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Нужно обновить стойку', isTank and 'Аура благочестия' or 'Аура воздаяния', 'player'
    if useMana and not st.gcd and c.IsSpellNotUsed(stanceAuras, 15) and c.CanUseGcdSpell(action, unit) then
        -- Могу прожать стойку
        local stance = c.UnitAuraByID(unit, stanceAuras, true)
        if stance then
            -- на мне ecть моя стойка (аура палладина)
            -- но она не атуальна, чужой атуальной нет
            if stance == spell['Аура воина Света'] and not c.UnitAuraByID(unit, spell[action]) then
                c.DoAction(reason, action, unit) --  переключаемся в атуальную стойку
                return reason
            end
        else
            -- на мне нет моей стойки (ауры палладина)
            stance = getAvailableStance(unit) -- что можно включить?
            if stance then
                action = spell[stance]
                c.DoAction(reason, action, unit)
                return reason
            end
        end
    end
    -------------------------------------------------------------------------------
    reason, action, unit = "Нужно обновить благословение",
        isTank and 'Благословение неприкосновенности' or 'Благословение могущества', 'player'
    if useMana and not st.gcd and c.IsSpellNotUsed(blessingAuras, 15) and not c.HasMyBuff('Благословение', unit) then
        if not c.HasBuff(action, unit) and c.CanUseGcdSpell(action, unit) then
            c.DoAction(reason, action, unit)
            return reason
        end

        local blessing = getAvailableBlessing(unit)
        if blessing then
            action = blessing
            if c.CanUseGcdSpell(action, unit) then
                c.DoAction(reason, action, unit)
                return reason
            end
        end
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Мало хп в бою, нужен деф', 'Божественная защита', 'player'
    if st.combatMode and needHeal and not c.UnitAuraByID(forbearanceId, unit) and c.CanUseSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
    end
    -------------------------------------------------------------------------------
    reason = c.TryTarget()
    -- есть ли причина для отстановки?
    if reason then return reason end
    -------------------------------------------------------------------------------
    -- Дальше считаем что у нас есть валидная цель
    -------------------------------------------------------------------------------
    reason, action, unit = 'Деф PVE с созвездия по кд', 'Криво-пружинный механизм', 'player'
    if not st.pvp and c.CanUseSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
    end
    -------------------------------------------------------------------------------
    if not st.gcd and c.HasBuff('Криво-пружинный механизм') then
        if st.group then
            reason, action, unit = 'Свет небес без каста', 'Свет небес', 'player'
            if needHeal and c.CanUseGcdSpell(action, unit) then
                c.DoAction(reason, action, unit)
                return reason
            end
        else
            reason, action, unit = format('Хилимся без каста на %s%%hp', st.playerHP100),
                (st.playerHP100 < 75 and useMana) and 'Свет небес' or 'Вспышка Света', 'player'
            if (useMana or needHeal) and st.playerHP100 < 95 and c.CanUseGcdSpell(action, unit) then
                c.DoAction(reason, action, unit)
                return reason
            end
        end

        reason, action, unit = 'Экзорцизм без каста', 'Экзорцизм', 'target'
        if useMana and c.CanUseGcdSpell(action, unit) then
            c.DoAction(reason, action, unit)
            return reason
        end
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Обновляем баф на ману', 'Святая клятва', 'player'
    if not st.gcd and not c.UnitAuraByID(unit, spell[action]) and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    if not st.gcd then
        local cleanseDebuff = c.HasDebuff(cleanseTypes, 'player', 5) -- яд, болезнь и маг эффект
        reason, action, unit = 'Пробуем ' .. tostring(cleanseDebuff), 'Очищение', 'player'
        if c.IsSpellFailedRecently(action) then
            c.TimerStart(action) -- считаем что использовали
        end
        if cleanseDebuff and useMana and c.CanUseGcdSpell(action, unit, 10) then
            c.DoAction(reason, action, unit)
            return reason
        end
    end
    -------------------------------------------------------------------------------
    local dist = c.UnitDistance('target', 'player')
    -------------------------------------------------------------------------------

    if isTank and st.group and not st.pvp then      -- только в группе
        -- Пуллтайм ротация
        local isPull = c.TimerLess('combatLock', 3) -- Первые 3 секунды боя

        if isPull then
            reason, action = 'пул', 'Освящение'
            if not st.gcd and still and useMana and dist < 8 and (c.GetEnemyCount(8, 'player') > 2 or c.targetHard) and c.CanUseGcdSpell(action) then
                c.DoAction(reason, action)
                return reason
            end
        elseif c.State.combatLock then
            -- Проверка агро для маусовер-цели
            reason = tryThreat('mouseover')
            if reason then return reason end
            -- Проверка агро для текущей цели
            reason = tryThreat('target')
            if reason then return reason end
        end
    end

    -------------------------------------------------------------------------------
    reason, action, unit = 'Нужнен баф на блокирование', 'Щит небес', 'player'
    if not st.gcd and dist < 10 and useMana and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Урон агрилкой', 'Длань возмездия', 'target'
    if useMana and (isTank or not st.group) and not UnitIsUnit('target-target', 'player') and c.CanUseSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Добивание', 'Молот гнева', 'target'
    if not st.gcd and useMana and c.UnitHealth100(unit) < 20 and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    --- TODO: 30м  Использовать приоритетно в кастеров (Найти и уничтожить)
    reason, action, unit = 'Сало на троих', 'Щит мстителя', 'target'
    if not st.gcd and useMana and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Молот в 3 цели', 'Молот праведника', 'target'
    if c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Вершим правосудие!', mana100 < 80 and 'Правосудие мудрости' or 'Правосудие света', 'target'
    if c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    local creatureType = UnitCreatureType('target')
    reason, action, unit = creatureType, 'Гнев небес', 'target'
    if not st.gcd and useMana and dist < 10 and c.GetEnemyCount(10, 'player') > 1 and (creatureType == 'Нежить' or creatureType == 'Демон') and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Нужно пустить лужу', 'Освящение', 'target'
    if not st.gcd and still and useMana and dist < 8 and (c.targetHard or mana100 > 90 or c.GetEnemyCount(8, 'player') > 2) and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Заплонитель', 'Щит праведности', 'target'
    if c.CanUseGcdSpell(action) then
        c.DoAction(reason, action, unit)
        return reason
    end

    return st.gcd and '#gcd' or '#none'
end
-------------------------------------------------------------------------------
function c.Update()
    if not isLoaded then return end

    local stopReason = c.GetStopReason()
    if stopReason then
        -------------------------------------------------------------------------------
        -- только для палладина, врубаем коня на маунте
        -------------------------------------------------------------------------------
        if stopReason == c.stopReasonMount then
            local reason, action, unit = 'Врубаем ускорение на транспорте', 'Аура воина Света', 'player'
            if not c.UnitAuraByID(unit, spell[action]) and c.CanUseGcdSpell(action, unit) then
                c.DoAction(reason, action, unit)
                stopReason = reason
            end
        end
        -------------------------------------------------------------------------------
        c.LogWhatHappend(stopReason)
        return
    end
    c.LogWhatHappend(updateProto())
end

-------------------------------------------------------------------------------
