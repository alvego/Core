------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
local st = ns.State
------------------------------------------------------------------------------------------------------------------
if st.playerClass ~= 'PALADIN' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(st.playerClass, st.playerColor)
------------------------------------------------------------------------------------------------------------------
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local UnitCreatureType = UnitCreatureType
local GetTalentInfo = GetTalentInfo
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local IsEquippedItem = IsEquippedItem
local CheckInteractDistance = CheckInteractDistance
local UnitIsPlayer = UnitIsPlayer
local type = type
local math_max = math.max
local format = format
------------------------------------------------------------------------------------------------------------------
local function canUseSpell(spell)
    return IsUsableSpell(spell) and ns.CanUseAction(spell) and not ns.IsSpellFailedRecently(spell)
end
------------------------------------------------------------------------------------------------------------------
local function canUseGcdSpell(spell)
    return not st.gcd and canUseSpell(spell)
end
------------------------------------------------------------------------------------------------------------------
local function canUseItem(item)
    return IsUsableItem(item) and ns.CanUseAction(item)
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

-- Новая функция для обработки агро-способностей
local function tryThreat(unit)
    if ns.IsInvalidTarget(unit) then
        -- ns.Log('IsInvalidTarget', unit)
        return false
    end

    local isTanking, status, threatPercent = UnitDetailedThreatSituation('player', unit) -- 0: нет угрозы, 1: есть угроза, 2: овертаунт, 3: танк
    local spellUsed, action
    local targetUnit = unit .. 'target'
    local unitTargetName = UnitExists(targetUnit) and UnitName(targetUnit) or 'Нет цели'

    if isTanking then
        -- ns.Log('IsInvalidTarget', unit)
        return false
    end
    if ns.IsOneUnit('player', targetUnit) then
        -- ns.Log('its me', unit)
        return false
    end
    if UnitExists('focus') and ns.IsOneUnit(unit, 'focus') then
        -- ns.Log('is focus', unit)
        return false
    end

    if ns.TimerLess('Длань возмездия', 1) or ns.TimerLess('Праведная защита', 1) then
        -- ns.Log('недавно прожали, не частим')
        return false -- недавно прожали, не частим
    end
    local isMO = unit == 'mouseover'

    action = isMO and ' Дл возмездия MO' or 'Длань возмездия'
    if not spellUsed and IsUsableSpell('Длань возмездия') and ns.CanUseAction(action) then
        spellUsed = action
    end

    action = isMO and 'Прав защита MO' or 'Праведная защита'
    if not spellUsed and UnitIsPlayer(targetUnit) and IsUsableSpell('Праведная защита') and ns.CanUseAction(action) then
        spellUsed = action
    end

    if not spellUsed then
        -- ns.Log('not spellUsed', IsUsableSpell('Длань возмездия'), IsUsableSpell('Праведная защита'))
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
local function getHolyAction()
    local action, reason
    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end

    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    action, reason = ns.TryTarget()
    if action then
        return action, reason
    end
    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    action, reason = 'none', 'гкд'
    if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', 'пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------
--local allTypes = { 'Magic', 'Disease', 'Poison', 'Curse' }
local cleanseTypes = { 'Magic', 'Disease', 'Poison' }
local function getProtoAction()
    local action, reason

    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end

    -----------------------------------------------
    ns.TimerToggle('needHeal', st.playerHP100 < (st.group and 40 or 60)) -- таймер идет пока hp < 40
    ns.TimerToggle('needMoreDamage', st.ttd > 10)                        -- таймер идет пока ttd > 20
    ns.TimerToggle('still', st.still)
    -----------------------------------------------
    -- hp меньше половины уже 2 секунды
    local needHeal = ns.TimerStarted('needHeal') and ns.TimerMore('needHeal', 1.5) and st.combatMode
    local needMoreDamage = ns.TimerStarted('needMoreDamage') and ns.TimerMore('needMoreDamage', 1)
    local still = ns.TimerStarted('still') and ns.TimerMore('still', 1)
    -- нужно бурстить
    local needBurst = st.targetHard and needMoreDamage --and dancingRuneWeaponReady
    -----------------------------------------------
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)



    action, reason = 'Праведное неистовство', 'танк'
    if not ns.HasBuff(action) and canUseSpell(action) then return action, reason end

    if not st.existsTarget then
        action, reason = 'Аура благочестия', 'аура'
        if not ns.HasMyBuff('Аура') and not ns.HasBuff(action) and canUseSpell(action) then return action, reason end

        --action, reason = 'Печать праведности', 'печать'
        action, reason = 'Печать повиновения', 'печать'
        if not ns.HasMyBuff('Печать') and canUseSpell(action) then return action, reason end

        action, reason = 'Благословение неприкосновенности', 'благословение'
        if not ns.HasMyBuff('Благословение') and canUseSpell(action) then return action, reason end

        -- action, reason = 'Свет небес', 'хилимся'
        -- if still and (st.playerHP100 < 40 and needHeal) and canUseSpell(action) then return action, reason end
    end

    action, reason = 'Божественная защита', 'деф'
    if still and needHeal and canUseSpell(action) then return action, reason end



    -----------------------------------------------

    -- if st.targetImmuneMagic then
    -- end
    -----------------------------------------------
    local mana100 = ns.UnitMana100('player')
    local useMana = st.attack or (mana100 > 50)
    -----------------------------------------------

    action, reason = ns.TryTarget()
    if action then return action, reason end

    -----------------------------------------------
    --local inMelee = ns.IsSpellInRange('Удар чумы')
    -----------------------------------------------

    if ns.HasBuff('Криво-пружинный механизм') then
        if st.group then
            action, reason = 'Свет небес', 'group: хилимся без каста'
            if needHeal and canUseSpell(action) then return action, reason end
        else
            action, reason = (st.playerHP100 < 75 and useMana) and 'Свет небес' or 'Вспышка Света', 'хилимся без каста'
            if (useMana or needHeal) and st.playerHP100 < 95 and canUseSpell(action) then return action, reason end
        end

        action, reason = 'Экзорцизм', 'экзорцизм без каста'
        if useMana and canUseSpell(action) then return action, reason end
    end

    -- action, reason = 'Пламя феникса', 'сало PVP'
    -- if canUseSpell(action) then return action, reason end

    -- action, reason = 'Древняя сфера', 'сфера PVE'
    -- if canUseSpell(action) then return action, reason end

    local cleanseDebuff = ns.HasDebuff(cleanseTypes)
    action, reason = 'Очищение', 'снимаем яд, болезнь и маг эффект.'
    if cleanseTypes and useMana and ns.TimerMore(action, 10) and canUseSpell(action) then return action, reason end

    action, reason = 'Криво-пружинный механизм', 'деф PVE'
    if useMana and not st.pvp and canUseSpell(action) then return action, reason end


    -- action, reason = 'Дар скитальца', 'деф PVE'
    -- if st.pvp and needHeal and canUseSpell(action) then return action, reason end


    local tankingBuff = ns.HasBuff('Праведное неистовство')
    local dist10 = CheckInteractDistance('target', 3) == 1

    action, reason = 'Святая клятва', 'на ману'
    if st.combatMode and canUseSpell(action) then return action, reason end
    -----------------------------------------------
    if tankingBuff and st.group and not st.pvp then  -- только в группе
        -- Пуллтайм ротация
        local isPull = ns.TimerLess('combatLock', 3) -- Первые 3 секунды боя
        if isPull then
            action, reason = 'Освящение', 'пул'
            if (st.numTargets > 2 or ns.targetHard) and still and dist10 and useMana and canUseGcdSpell(action) then
                return
                    action, reason
            end
        end
        if not isPull and ns.State.combatLock then
            -- Проверка агро для маусовер-цели
            action, reason = tryThreat('mouseover')
            if action then return action, reason end
            -- Проверка агро для текущей цели
            action, reason = tryThreat('target')
            if action then return action, reason end
        end
    end

    action, reason = 'Щит небес', 'щит'
    if dist10 and useMana and canUseSpell(action) then return action, reason end

    action, reason = 'Длань возмездия', 'урон агрилкой'
    if useMana and not ns.IsOneUnit('target-target', 'player') and canUseSpell(action) then
        return
            action, reason
    end
    -----------------------------------------------


    action, reason = 'Молот гнева', 'добивание'
    if ns.UnitHealth100('target') < 20 and useMana and canUseSpell(action) then return action, reason end

    action, reason = 'Щит мстителя', 'щит x 3'
    if useMana and canUseSpell(action) then return action, reason end

    action, reason = 'Молот праведника', 'молот x 3'
    if canUseSpell(action) then return action, reason end

    action, reason = mana100 < 70 and 'Правосудие мудрости' or 'Правосудие света', 'Правосудие'
    if canUseSpell(action) then return action, reason end

    action, reason = 'Гнев небес', 'Нежить'
    if st.numTargets > 1 and (UnitCreatureType('target') == "Нежить") and useMana and dist10 and canUseSpell(action) then
        return action,
            reason
    end

    action, reason = 'Освящение', 'лужа'
    if (st.numTargets > 2 or ns.targetHard or mana100 > 90) and still and dist10 and useMana and canUseGcdSpell(action) then
        return
            action, reason
    end

    action, reason = 'Щит праведности', 'заплонитель'
    if canUseSpell(action) then return action, reason end

    -- action, reason = 'Экзорцизм', 'Экзорцизм'
    -- if canUseSpell(action) then return action, reason end

    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    -- action, reason = 'none', 'гкд'
    -- if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', '#пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------
local function getRetributionAction()
    local action, reason
    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end

    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    action, reason = ns.TryTarget()
    if action then
        return action, reason
    end
    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    action, reason = 'none', 'гкд'
    if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', 'пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
local rotations = { getHolyAction, getProtoAction, getRetributionAction }
local rotation
local function updateRotation()
    local spec = 2 --ns.GetCurrentSpecID()
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
