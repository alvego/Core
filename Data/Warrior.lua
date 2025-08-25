------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
if ns.State.playerClass ~= 'WARRIOR' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(ns.State.playerClass, ns.State.playerColor)
------------------------------------------------------------------------------------------------------------------
local UnitMana = UnitMana
------------------------------------------------------------------------------------------------------------------
local function getArmsAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if ns.State.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return 'none', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local function getFuryAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if ns.State.gcd then return 'none', 'гкд' end
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
-- Новая функция для обработки агро-способностей
local function checkThreatAndAct(unit, rage, stance)
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or not UnitCanAttack('player', unit) then
        return false
    end

    local unitName = UnitName(unit)
    local unitTargetName, threat = getTargetInfo(unit)
    local spellUsed = nil
    local reason = nil
    local rangeInfo = nil

    local dist10 = CheckInteractDistance(unit, 3)

    if threat == 3 then return false end
    -- Проверка удара грома (10 метров, вне АОЕ)

    -- Проверка удара грома (10 метров, вне АОЕ)
    if not spellUsed and rage >= 16 and stance ~= 3 and dist10 and ns.CanUseAction('Удар грома') then
        spellUsed = 'Удар грома'
        reason = 'Цель не спровоцирована'
        rangeInfo = '10м'
    end

    -- Проверка дразнящего удара (мили)
    if not spellUsed and ns.IsSpellInRange('Кровопускание', unit) and ns.CanUseAction('Дразнящий удар') then
        spellUsed = (unit == 'mouseover' and 'Дразнящий М' or 'Дразнящий удар')
        reason = 'Цель не спровоцирована'
        rangeInfo = 'мили'
    end

    -- Проверка раскола брони (мили)
    if not spellUsed and rage >= 15 and stance == 2 and ns.IsSpellInRange('Кровопускание', unit) and ns.CanUseAction('Раскол брони') then
        spellUsed = (unit == 'mouseover' and 'Раскол брони МО' or 'Раскол брони')
        reason = 'Цель не спровоцирована'
        rangeInfo = 'мили'
    end

    -- Проверка провокации (30 метров)
    if not spellUsed and not dist10 and ns.CanUseAction('Провокация') and ns.IsSpellInRange('Провокация', unit) then
        spellUsed = (unit == 'mouseover' and 'Провокация МО' or 'Провокация')
        reason = 'Цель не спровоцирована'
        rangeInfo = '30м'
    end

    -- Проверка вызывающего крика (10 метров, вне АОЕ)
    if not spellUsed and dist10 and IsUsableSpell('Вызывающий крик') and ns.CanUseAction('Вызывающий крик') and rage >= 10 then
        spellUsed = 'Вызывающий крик'
        reason = 'Цель не спровоцирована'
        rangeInfo = '10м'
    end

    -- Логирование для агро-способностей
    if not spellUsed then
        return false
    end

    return spellUsed, string.format(
        '[TANK] %s на %s (%s): %s. Угроза: %d, Цель цели: %s, Дистанция: %s',
        spellUsed,
        unitName,
        unit,
        reason,
        threat,
        unitTargetName,
        rangeInfo
    )
end
------------------------------------------------------------------------------------------------------------------
local function getProtoAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local rage = UnitMana('player')
    local stance = GetShapeshiftForm()
    local aoe  = ns.IsShift() or (ns.State.numTargets > 2)
    local ctrl = ns.IsCtr()

    if stance ~= 2 and ns.State.combatLock then --ns.CanUseAction('Оборонительная стойка')
        return 'Оборонительная стойка', '#свитч в дэфстэнс в бою'
    end

    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end

    local inMelee = ns.IsSpellInRange('Кровопускание')


    local isRecentlyCharged = ns.TimerLess('Перехват', 1.5) or ns.TimerLess('Рывок', 1.5) or
        ns.TimerLess('Вмешательство', 1.5)

    if ns.State.attack and not isRecentlyCharged then
        -- Инициация боя: Рывок
        if ns.CanUseAction('Рывок') then
            return 'Рывок', '#прыгаем [Рывок]'
        end
        -- Или Перехват
        if ns.CanUseAction('Перехват') then
            return 'Перехват', '#прыгаем [Перехват]'
        end
        -- Или Вмешательство
        -- if ns.CanUseAction('Вмешательство') then
        --     return 'Вмешательство', 'пригаем [Вмешательство] target-target'
        -- end
    end

    -- часть ротации которую можно прожимать во время гкд
    -- Защита: Блок щитом, при низком здоровье Глухая оборона
    if ns.State.playerHP100 < 80 and rage >= 10 and ns.CanUseAction('Блок щитом') then
        return 'Блок щитом', '#защита при hp < 80%'
    end

    if ns.State.playerHP100 < 70 and not ns.State.instance and ns.CanUseAction('Безудержная ярость') then
        return 'Безудержная ярость', '#дефаемся и хилимся расовой абилкой'
    end

    if ns.State.playerHP100 < 35 and rage >= 10 and ns.CanUseAction('Глухая оборона') then
        return 'Глухая оборона', '#деф при hp < 35%'
    end

     -- Генерация ярости: Кровавая ярость
    if ns.State.combatLock and rage < 20 and inMelee and ns.CanUseAction('Кровавая ярость') then
        return 'Кровавая ярость', '#генерация ярости'
    end

    -- Удары которые можно сетить вне гкд 
    if not aoe and not IsCurrentSpell('Удар героя') and ns.CanUseAction('Удар героя') and inMelee and rage >= 80 then
        return 'Удар героя', '#соло заполнитель' 
    end

    if not aoe and not IsCurrentSpell('Удар героя') and ns.CanUseAction('Удар героя') and inMelee and ns.HasMyBuff('Символ реванша') then
        return 'Удар героя', '#Бесплатный по проку'
    end

    if aoe and not IsCurrentSpell('Рассекающий удар') and ns.CanUseAction('Рассекающий удар') and rage >= 36 and inMelee then
        return 'Рассекающий удар', '#aoe заполнитель'
    end

    if IsUsableSpell('Реванш') and ns.CanUseAction('Реванш') and inMelee and ns.CanUseAction('Варварский ритуал') then
        return 'Варварский ритуал', '#реванш доступен, [Варварский ритуал]'
    end

    if ns.State.gcd then return 'none', '#гкд' end

    -- то что выполняется в рамках гкд

    local dist10 = CheckInteractDistance('target', 3)

    -- Пуллтайм ротация
    local isPull = ns.TimerLess('combatLock', 3) -- Первые 3 секунды боя
    if isPull and ns.State.group then            -- только в группе
        if ns.CanUseAction('Удар грома') and rage >= 16 and inMelee then
            return 'Удар грома', '#пулл в мили'
        end

        if ns.CanUseAction('Ударная волна') and ns.State.targetVisible and dist10 and not ns.IsReadySpell('Удар грома') and rage >= 15 then
            return 'Ударная волна', '#пулл 10м'
        end

        return 'none', '#завершаем ротацию, чтобы не переходить к основной'
    end

    if ns.State.combatLock and ns.State.group then
        local aSpell, aReason
        -- Проверка агро для маусовер-цели
        if UnitExists('mouseover') and UnitCanAttack('player', 'mouseover') then
            aSpell, aReason = checkThreatAndAct('mouseover', rage, stance)
            if aSpell then
                return aSpell, aReason
            end
        end

        -- Проверка агро для текущей цели
        aSpell, aReason = checkThreatAndAct('target', rage, stance)

        if aSpell then
            return aSpell, aReason
        end
    end

    -- Основные атакующие способности

    if IsUsableSpell('Реванш') and inMelee and ns.CanUseAction('Реванш') then
        return 'Реванш', '#реванш по доступности'
    end

    if inMelee and ns.CanUseAction('Мощный удар щитом') and ns.HasMyBuff('Щит и меч') then
        return 'Мощный удар щитом', '#по проку бъем щитом'
    end

    if rage >= 16 and inMelee and ns.CanUseAction('Удар грома') then
        return 'Удар грома', '#гром в мили'
    end

     -- Деморализующий крик в АОЕ
    if aoe and dist10 and ns.CanUseAction('Деморализующий крик') and rage >= 10 and not ns.HasMyDebuff('Деморализующий крик') then
        return 'Деморализующий крик', '#автоматический деморал крик'
    end

    if not (ns.HasMyBuff('Командирский крик') or ns.HasBuff('Боевой крик') or ns.HasBuff('благословение могущества')) then
        return 'Боевой крик', '#яростно кричим на бицуху'
    end

    if dist10 and not ns.IsReadySpell('Удар грома') and ns.State.targetVisible and rage >= 17 and ns.CanUseAction('Ударная волна') then
        return 'Ударная волна', '#волна в 10м'
    end
    if rage >= 36 and stance == 2 and inMelee and ns.CanUseAction('Мощный удар щитом') then
        return 'Мощный удар щитом', '#сливаем рагу щитом'
    end
    if not aoe and IsUsableSpell('Сокрушение') and not ns.HasMyBuff('Щит и меч') and rage >= 31 and inMelee then
        return 'Сокрушение', '#крушим пока shit на КД'
    end
    -- раскол по контролу на боса
    if ctrl and ns.CanUseAction('Раскол брони') and not ns.HasMyDebuff('Раскол брони') then
        return 'Раскол брони', '#раскол по ctrl'
    end

    return 'none', '#пока всё'
end
------------------------------------------------------------------------------------------------------------------
local rotations = { getArmsAction, getFuryAction, getProtoAction }
function ns:GetAction()
    local spec = ns.GetCurrentSpecID()
    local rotation = rotations[spec]
    return rotation()
end

------------------------------------------------------------------------------------------------------------------
