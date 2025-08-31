------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
local st = ns.State
------------------------------------------------------------------------------------------------------------------
if st.playerClass ~= 'WARRIOR' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(st.playerClass, st.playerColor)
------------------------------------------------------------------------------------------------------------------
local UnitMana = UnitMana
local type = type
local UnitThreatSituation = UnitThreatSituation
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local CheckInteractDistance = CheckInteractDistance
local GetShapeshiftForm = GetShapeshiftForm
------------------------------------------------------------------------------------------------------------------
local function canUseSpell(spell)
    return IsUsableSpell(spell) and ns.CanUseAction(spell)
end
------------------------------------------------------------------------------------------------------------------
local function canUseGcdSpell(spell)
    return not st.gcd and canUseSpell(spell)
end
------------------------------------------------------------------------------------------------------------------
local function canUseCurrentSpell(spell)
    return not IsCurrentSpell(spell) and canUseSpell(spell)
end
------------------------------------------------------------------------------------------------------------------
local function getArmsAction()
    if st.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. st.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожать в гкд
    if st.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return 'none', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local function getFuryAction()
    if st.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. st.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожать в гкд
    if st.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return 'none', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
-- Новая функция для проверки состояния цели и логирования
local function getTargetInfo(unit)
    local unitTargetName = 'Нет цели'
    local threat = UnitThreatSituation('player', unit) or 0 -- 0: нет угрозы, 1: есть угроза, 2: овертаунт, 3: танк
    local targetUnit = unit .. 'target'
    if UnitExists(targetUnit) then
        unitTargetName = UnitName(targetUnit)
    end
    return unitTargetName, threat
end
------------------------------------------------------------------------------------------------------------------
-- Функция для преобразования статуса в текст
local function getThreatStatusText(status)
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

-- Функция для обработки агро-способностей
local function tryThreat(unit)
    if ns.IsInvalidTarget(unit) then
        return false
    end

    local isTanking, status, threatPercent = UnitDetailedThreatSituation('player', unit)
    local spellUsed, action
    local targetUnit = unit .. 'target'
    local unitTargetName = UnitExists(targetUnit) and UnitName(targetUnit) or 'Нет цели'
    local dist10 = CheckInteractDistance(unit, 3)

    if isTanking then return false end
    if ns.IsOneUnit('player', targetUnit) then return false end

    -- Проверка удара грома (10 метров, вне АОЕ)
    if not spellUsed and stance ~= 3 and dist10 and canUseGcdSpell('Удар грома') then
        spellUsed = 'Удар грома'
    end

    -- Проверка дразнящего удара (мили)
    --[[ if not spellUsed and canUseGcdSpell('Дразнящий удар') then
        spellUsed = (unit == 'mouseover' and 'Дразнящий М' or 'Дразнящий удар')
    end ]]

    -- Проверка раскола брони (мили)
    if not spellUsed and canUseGcdSpell('Раскол брони') then
        spellUsed = (unit == 'mouseover' and 'Раскол брони МО' or 'Раскол брони')
    end

    -- Проверка провокации (30 метров)
    if not spellUsed and not dist10 and canUseSpell('Провокация') then
        spellUsed = (unit == 'mouseover' and 'Провокация МО' or 'Провокация')
    end

    -- Проверка вызывающего крика (10 метров, вне АОЕ)
    if not spellUsed and ns.TimerLess('Удар грома', 2) and dist10 and canUseGcdSpell('Вызывающий крик') then
        spellUsed = 'Вызывающий крик'
    end

    if not spellUsed then
        return false
    end

    return spellUsed, string.format(
        'агрим %s (%s): %s, угроза: %d, бъет: %s',
        UnitName(unit),
        unit,
        getThreatStatusText(status),
        threatPercent or 0,
        unitTargetName
    )
end
------------------------------------------------------------------------------------------------------------------
local function getProtoAction()
    if st.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. st.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local rage   = UnitMana('player')
    local stance = GetShapeshiftForm()
    local aoe    = ns.IsShift() or (st.numTargets > 2)
    local ctrl   = ns.IsCtr()

    if stance ~= 2 and st.combatLock then --ns.CanUseAction('Оборонительная стойка')
        return 'Оборонительная стойка', '#свитч в дэфстэнс в бою'
    end

    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end

    local inMelee = ns.IsSpellInRange('Кровопускание')


    local isRecentlyCharged = ns.TimerLess('Перехват', 1.5) or ns.TimerLess('Рывок', 1.5) or
        ns.TimerLess('Вмешательство', 1.5)

    if st.attack and not isRecentlyCharged then
        -- Инициация боя: Рывок
        if canUseSpell('Рывок') then
            return 'Рывок', '#прыгаем [Рывок]'
        end
        -- Или Перехват
        if canUseSpell('Перехват') then
            return 'Перехват', '#прыгаем [Перехват]'
        end
        -- Или Вмешательство
        -- if canUseSpell('Вмешательство') then
        --     return 'Вмешательство', 'пригаем [Вмешательство] target-target'
        -- end
    end

    -- часть ротации которую можно прожимать во время гкд
    -- Защита: Блок щитом, при низком здоровье Глухая оборона
    if st.playerHP100 < 80 and canUseSpell('Блок щитом') then
        return 'Блок щитом', '#защита при hp < 80%'
    end

    if st.playerHP100 < 70 and not ns.HasBuff('Перемирие') and not st.instance and canUseSpell('Безудержная ярость') then
        return 'Безудержная ярость', '#дефаемся и хилимся расовой абилкой'
    end

    if st.playerHP100 < 35 and rage >= 10 and canUseSpell('Глухая оборона') then
        return 'Глухая оборона', '#деф при hp < 35%'
    end

    -- Генерация ярости: Кровавая ярость
    if st.combatLock and rage < 20 and canUseSpell('Кровавая ярость') then
        return 'Кровавая ярость', '#генерация ярости'
    end

    -- Удары которые можно сетить вне гкд
    if not aoe and canUseCurrentSpell('Удар героя') and rage >= 80 then
        return 'Удар героя', '#соло заполнитель Удар героя, ярость > 80'
    end

    if not aoe and canUseCurrentSpell('Удар героя') and ns.HasMyBuff('Символ реванша') then
        return 'Удар героя', '#бесплатный Удар героя по проку'
    end

    if aoe and canUseCurrentSpell('Рассекающий удар') and rage >= 36 then
        return 'Рассекающий удар', '#aoe заполнитель Рассекающий'
    end

    if not st.pvp and canUseGcdSpell('Реванш') and canUseSpell('Варварский ритуал') then
        return 'Варварский ритуал', '#реванш доступен, усиляем [Варварский ритуал]'
    end

    if st.gcd then return 'none', '#гкд' end

    -- то что выполняется в рамках гкд

    local dist10 = CheckInteractDistance('target', 3)

    -- Пуллтайм ротация
    local isPull = ns.TimerLess('combatLock', 3) -- Первые 3 секунды боя
    if isPull and st.group then                  -- только в группе
        if canUseGcdSpell('Удар грома') and inMelee then
            return 'Удар грома', '#пулл в мили'
        end

        if canUseGcdSpell('Ударная волна') and dist10 and ns.TimerLess('Удар грома', 2) then
            return 'Ударная волна', '#пулл 10м'
        end

        return 'none', '#завершаем ротацию, чтобы не переходить к основной'
    end

    if not st.pvp and st.combatLock and st.group then
        -- Проверка агро для маусовер-цели
        local aSpell, aReason = tryThreat('mouseover')
        if aSpell then
            return aSpell, aReason
        end

        -- Проверка агро для текущей цели
        aSpell, aReason = tryThreat('target')
        if aSpell then
            return aSpell, aReason
        end
    end

    -- Основные атакующие способности

    if canUseGcdSpell('Реванш') then
        return 'Реванш', '#реванш по доступности'
    end

    if canUseGcdSpell('Мощный удар щитом') and ns.HasMyBuff('Щит и меч') then
        return 'Мощный удар щитом', '#по проку бъем щитом'
    end

    if canUseGcdSpell('Удар грома') and inMelee then
        return 'Удар грома', '#гром в мили'
    end

    -- Деморализующий крик в АОЕ
    if aoe and dist10 and canUseGcdSpell('Деморализующий крик') and not ns.HasMyDebuff('Деморализующий крик') then
        return 'Деморализующий крик', '#автоматический Деморализующий крик'
    end

    if not (ns.HasMyBuff('Командирский крик') or ns.HasBuff('Боевой крик') or ns.HasBuff('благословение могущества')) and canUseGcdSpell('Боевой крик') then
        return 'Боевой крик', '#поддерживаем Боевой крик'
    end
  
    if not ns.HasMyBuff('Боевой крик') and not ns.HasBuff('Командирский крик') and (ns.HasBuff('благословение могущества') or ns.HasBuff('Боевой крик')) and canUseGcdSpell('Командирский крик') then
        return 'Командирский крик', '#есть баф на АП, используем Командирский крик'
    end

    if dist10 and not ns.IsReadySpell('Удар грома') and rage >= 17 and canUseGcdSpell('Ударная волна') then
        return 'Ударная волна', '#волна в 10м'
    end
    if rage >= 36 and canUseGcdSpell('Мощный удар щитом') then
        return 'Мощный удар щитом', '#сливаем ярость щитом'
    end
    if not aoe and canUseGcdSpell('Сокрушение') and not ns.HasMyBuff('Щит и меч') and rage >= 31 then
        return 'Сокрушение', '#крушим пока Удар щитом на КД'
    end

    return 'none', '#пока всё'
end
------------------------------------------------------------------------------------------------------------------
local rotations = { getArmsAction, getFuryAction, getProtoAction }
local rotation
local function updateRotation()
    local spec = ns.GetCurrentSpecID()
    rotation = rotations[spec]
end
ns.AttachEvent('PLAYER_TALENT_UPDATE', updateRotation)
ns.AttachEvent('ACTIVE_TALENT_GROUP_CHANGED', updateRotation)
function ns.GetAction()
    if type(rotation) ~= 'function' then
        updateRotation()
    end
    return rotation()
end

------------------------------------------------------------------------------------------------------------------
