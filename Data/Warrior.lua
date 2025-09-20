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
local IsUsableSpell = IsUsableSpell
local IsCurrentSpell = IsCurrentSpell
local GetTalentInfo = GetTalentInfo
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local CheckInteractDistance = CheckInteractDistance
local GetShapeshiftForm = GetShapeshiftForm
local math_max = math.max
local format = format
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
    if ns.TimerLess('CurrentSpell', 1) then return false end
    if IsCurrentSpell(spell) then return false end
    if not canUseSpell(spell) then return false end
    ns.TimerStart('CurrentSpell')
    return true
end
------------------------------------------------------------------------------------------------------------------
local function canUseItem(item)
    return IsUsableItem(item) and ns.CanUseAction(item)
end
------------------------------------------------------------------------------------------------------------------
ns.AttachTelemetry(function()
    return ns.TelemetryBool('HS', IsCurrentSpell('Удар героя'))
end)

ns.AttachTelemetry(function()
    return ns.TelemetryBool('CL', IsCurrentSpell('Рассекающий удар'))
end)
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
    -- тут ротацию ишем, можно использовать что можно прожать в гкд
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
    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    if st.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return 'none', 'пока всё'
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
    local inMelee = ns.IsSpellInRange('Кровопускание', unit)

    if isTanking then return false end
    if ns.IsOneUnit('player', targetUnit) then return false end

    -- Проверка удара грома (10 метров, вне АОЕ)
    action = 'Удар грома'
    if not spellUsed and stance ~= 3 and dist10 and ns.CanUseAction(action) then
        spellUsed = action
    end

    -- Проверка дразнящего удара (мили)
    action = (unit == 'mouseover') and 'Дразнящий М' or 'Дразнящий удар'
    if not spellUsed and inMelee and ns.CanUseAction(action) then
        spellUsed = action
    end

    -- Проверка раскола брони (мили)
    --[[     if not spellUsed and ns.IsSpellInRange('Кровопускание', unit) and canUseGcdSpell('Раскол брони') then
        spellUsed = (unit == 'mouseover' and 'Раскол брони МО' or 'Раскол брони')
    end]]

    -- Проверка провокации (до 30 метров)
    action = (unit == 'mouseover') and 'Провокация МО' or 'Провокация'
    if not spellUsed and ns.CanUseAction(action) then
        spellUsed = action
    end

    -- Проверка бросок (10-30 метров)
    action = (unit == 'mouseover') and 'Героический МО' or 'Героический бросок'
    if not spellUsed and not dist10 and ns.CanUseAction(action) then
        spellUsed = action
    end

    -- Проверка вызывающего крика (10 метров, вне АОЕ)
    action = 'Вызывающий крик'
    if not spellUsed and ns.TimerLess('Удар грома', 2) and dist10 and ns.CanUseAction(action) then
        spellUsed = action
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
    local action, reason

    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local rage   = UnitMana('player')
    local stance = GetShapeshiftForm()
    local aoe    = ns.IsShift() or (st.numTargets > 2)
    local ctrl   = ns.IsCtr()

    action, reason = 'Рунический флакон с лечебным зельем', '#хилимся на 20% хп'
    if st.playerHP100 < 20 and canUseItem(action) then return action, reason end

    action, reason = 'Аргуссианский компас', '#щит на 30% хп'
    if st.playerHP100 < 30 and canUseItem(action) then return action, reason end

    action, reason = 'Оборонительная стойка', '#свитч в дэфстэнс в бою'
    if stance ~= 2 and st.combatLock then --ns.CanUseAction('Оборонительная стойка')
        return action, reason
    end

    action, reason = ns.TryTarget()
    if action then return action, reason end

    local inMelee = ns.IsSpellInRange('Кровопускание')
    local dist10 = CheckInteractDistance('target', 3)
    local isRecentlyCharged = ns.TimerLess('Перехват', 1.5) or ns.TimerLess('Рывок', 1.5) or
        ns.TimerLess('Вмешательство', 1.5)
    if st.attack and not isRecentlyCharged then
        -- Инициация боя: Рывок
        action, reason = 'Рывок', 'зажата атака сокращаем дистанцию'
        if canUseSpell(action) then
            return action, reason
        end
        
        -- Или Перехват
        action, reason = 'Перехват', 'зажата атака сокращаем дистанцию'
        if canUseSpell(action) then
            return action, reason
        end
        -- Или Вмешательство
        -- if canUseSpell('Вмешательство') then
        --     return 'Вмешательство', 'пригаем [Вмешательство] target-target'
        -- end
    end

    -- часть ротации которую можно прожимать во время гкд

    action, reason = 'Оберег скитальца', '#хп < 85, хилимся рассовой PVE-абилкой'
    if not st.pvp and st.playerHP100 < 85 and canUseSpell(action) then
        return action, reason
    end

    action, reason = 'Блок щитом', '#по КД'
    if canUseSpell(action) and inMelee then
        return action, reason
    end

    action, reason = 'Дар скитальца', '#хп < 75, хилимся рассовой PVP-абилкой'
    if st.playerHP100 < 70 and not ns.HasBuff('Перемирие') and not st.instance and canUseSpell(action) then
        return action, reason
    end

    action, reason = 'Глухая оборона', '#деф при hp < 40%'
    if st.playerHP100 < 40 and rage >= 10 and canUseSpell(action) then
        return action, reason
    end

    action, reason = 'Кровавая ярость', '#генерация ярости'
    if st.combatLock and rage < 20 and canUseSpell(action) then
        return action, reason
    end
   
    -- Удары которые можно сетить вне гкд
    action, reason = 'Удар героя', '#соло заполнитель Удар героя, ярость > 80'
    if not aoe and inMelee and canUseCurrentSpell(action) and rage >= 80 then
        return action, reason
    end

    action, reason = 'Удар героя', '#бесплатный Удар героя по проку'  
    if not aoe and inMelee and canUseCurrentSpell(action) and ns.HasMyBuff('Символ реванша') then
        return action, reason
    end

    action, reason = 'Рассекающий удар', '#aoe заполнитель Рассекающий'
    if aoe and inMelee and canUseCurrentSpell(action) and rage >= 36 then
        return action, reason
    end

    -- то что выполняется в рамках гкд

    action, reason = 'Безудержное восстановление', '#хилимся при hp < 35%'
    if not st.gcd and st.playerHP100 < 35 and rage >= 15 and canUseSpell(action) then
        return action, reason
    end

    -- Пуллтайм ротация
    local isPull = ns.TimerLess('combatLock', 3) -- Первые 3 секунды боя
    if isPull and st.group then  -- только в группе
        action, reason = 'Удар грома', '#пуллтайм в милизоне'            
        if canUseGcdSpell(action) and inMelee then
            return action, reason
        end

        action, reason = 'Ударная волна', '#в пуллтайме'
        if canUseGcdSpell(action) and dist10 and ns.TimerLess('Удар грома', 2) then
            return action, reason
        end

        return 'none', '#завершаем ротацию, чтобы не переходить к основной'
    end

    if not st.pvp and st.combatLock and st.group then
        -- Проверка агро для маусовер-цели
        action, reason = tryThreat('mouseover')
        if action then return action, reason end

        -- Проверка агро для текущей цели
        action, reason = tryThreat('target')
        if action then return action, reason end
    end

    -- Основные атакующие способности

    action, reason = 'Реванш', '#по доступности приоритетно'
    if canUseGcdSpell(action) then
        return action, reason
    end

    action, reason = 'Мощный удар щитом', '#по проку приоритетно'
    if canUseGcdSpell(action) and ns.HasMyBuff('Щит и меч') then
        return action, reason
    end

    action, reason = 'Удар грома', '#по доступности набиваем агро'
    if canUseGcdSpell(action) and inMelee then
        return action, reason
    end

    action, reason = 'Деморализующий крик', '#автоматический Деморализующий крик'
    if aoe and dist10 and canUseGcdSpell(action) and not ns.HasMyDebuff('Деморализующий крик') then
        return action, reason
    end

    action, reason = 'Боевой крик', '#поддерживаем при отсутствии других бафов на АП'
    if inMelee and not (ns.HasMyBuff('Командирский крик') or ns.HasBuff('Боевой крик') or ns.HasBuff('благословение могущества')) and canUseGcdSpell(action) then
        return action, reason
    end

    action, reason = 'Командирский крик', '#есть баф на АП, используем баф на ХП'
    if inMelee and not ns.HasMyBuff('Боевой крик') and not ns.HasBuff('Командирский крик') and (ns.HasBuff('благословение могущества') or ns.HasBuff('Боевой крик')) and canUseGcdSpell(action) then
        return action, reason
    end

    action, reason = 'Ударная волна', '#волна в  10м'
    if dist10 and not ns.IsReadySpell('Удар грома') and canUseGcdSpell(action) then
        return action, reason
    end

    --[[ action, reason = 'Мощный удар щитом', 'сливаем ярость щитом'
    if rage >= 36 and canUseGcdSpell(action) then
        return action, reason 
    end ]]

    action, reason = 'Сокрушение', '#заполняем ротацию'
    if not aoe and not ns.HasMyBuff('Щит и меч') and canUseGcdSpell(action) then
        return action, reason
    end

    action, reason = 'none', '#пока всё'
    return action, reason
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
