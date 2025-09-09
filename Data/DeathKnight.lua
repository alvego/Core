------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
local st = ns.State
------------------------------------------------------------------------------------------------------------------
if st.playerClass ~= 'DEATHKNIGHT' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(st.playerClass, st.playerColor)
------------------------------------------------------------------------------------------------------------------
local GetRuneCooldown = GetRuneCooldown
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local IsCurrentSpell = IsCurrentSpell
local GetRuneType = GetRuneType
local GetTalentInfo = GetTalentInfo
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local type = type
local math_max = math.max
local format = format
------------------------------------------------------------------------------------------------------------------
local lastNumWoundedTargets = 0
ns.AttachEvent('PLAYER_REGEN_ENABLED', function()
    lastNumWoundedTargets = 0
end)
------------------------------------------------------------------------------------------------------------------
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', function(event, timestamp, subEvent,
                                                       sourceGUID, sourceName, sourceFlags,
                                                       destGUID, destName, destFlags, ...)
    if subEvent:match("_DAMAGE") and destGUID == ns.State.playerGUID then --SWING_DAMAGE
        if subEvent:match("SPELL_") then
            -- ns.Log('Получен урон заклинанием', subEvent, select(1, ...))
            ns.TimerStart('SPELL_DAMAGE')
        else
            -- ns.Log('Получен урон от удара', subEvent, select(1, ...))
            ns.TimerStart('SWING_DAMAGE')
        end
    end
end)
------------------------------------------------------------------------------------------------------------------
local ghoulGuid = nil
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', function(event, timestamp, subEvent,
                                                       sourceGUID, sourceName, sourceFlags,
                                                       destGUID, destName, destFlags, ...)
    if subEvent == "UNIT_DIED" and destGUID == ghoulGuid then
        ns.TimerReset('summonGhoul')
        ghoulGuid = nil
        ns.Log('Гуль умертвлен', destGUID)
        return
    end

    if sourceGUID ~= st.playerGUID then return end

    local spellName = select(2, ...)
    if subEvent == 'SPELL_SUMMON' and destName == 'Восставший союзник' and spellName == 'Воскрешение мертвых' then
        ns.TimerStart('summonGhoul') -- призвали гуля
        ns.Log('Гуль призван', destGUID)
        ghoulGuid = destGUID
        return
    end
end)
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
        return false
    end

    local isTanking, status, threatPercent = UnitDetailedThreatSituation('player', unit) -- 0: нет угрозы, 1: есть угроза, 2: овертаунт, 3: танк
    local spellUsed, action
    local targetUnit = unit .. 'target'
    local unitTargetName = UnitExists(targetUnit) and UnitName(targetUnit) or 'Нет цели'

    if isTanking then return false end
    if ns.IsOneUnit('player', targetUnit) then return false end

    if ns.TimerLess('Темная власть', 3) or ns.TimerLess('Хватка смерти', 3) then
        return false -- недавно прожали, не частим
    end

    action = (unit == 'mouseover') and 'Темная власть MO' or 'Темная власть'
    if not spellUsed and IsUsableSpell('Темная власть') and ns.CanUseAction(action) then
        spellUsed = action
    end

    action = (unit == 'mouseover') and 'Хватка смерти MO' or 'Хватка смерти'
    if not spellUsed and IsUsableSpell('Хватка смерти') and ns.CanUseAction(action) then
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

local function getBloodAction()
    local action, reason

    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end
    -----------------------------------------------
    action, reason = 'Захват рун', 'хилися на 10% хп (нет цели)'
    if st.invalidTarget and st.playerHP100 < 80 and canUseSpell(action) then return action, reason end

    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    action, reason = ns.TryTarget()
    if action then return action, reason end
    -----------------------------------------------
    ns.TimerToggle('hp50less', st.playerHP100 < 50) -- таймер идет пока hp < 50
    ns.TimerToggle('ttd15more', st.ttd > 15)        -- таймер идет пока ttd > 15
    -----------------------------------------------
    local runicPower = UnitPower('player')
    -----------------------------------------------
    -- [Танцующее руническое оружие], как раз должно быть готово
    local dancingRuneWeaponReady = ns.TimerMore('Танцующее руническое оружие', 90) -- 1.5m
    -- нужно бурстить
    local needBurst = st.targetHard and dancingRuneWeaponReady
    -- hp меньше половины уже 2 секунды
    local needHeal = ns.TimerStarted('hp50less') and ns.TimerMore('hp50less', 2)
    local needMoreDamage = ns.TimerStarted('ttd15more') and ns.TimerMore('ttd15more', 2)
    -- [Воскрешение мертвых], как раз должно быть готово
    local raiseDeadReady = ns.TimerMore('Воскрешение мертвых', 180) -- 3m
    --  [Смертельный союз], как раз должно быть готово
    local deathPactReady = ns.TimerMore('Смертельный союз', 120) -- 2m
    local hasGhoul = ns.TimerLess('summonGhoul', 60) -- гуля призвали меньше минуты назад
    local needDeathPact = needHeal and deathPactReady and (raiseDeadReady or hasGhoul)
    local goRunicAbils = not needBurst and not needDeathPact
    -----------------------------------------------
    local glyphofDisease = true     -- При использовании способности 'Мор' время действия болезней и их вторичных эффектов на цели обновляется.
    local glyphofDeathStrike = true -- Увеличивает урон от способности 'Удар смерти' на 1% за каждые 1 ед. накопленной силы рун (максимум на 25%). Сила рун при этом не расходуется.
    local morbidityTalentCount = select(5, GetTalentInfo(3, 5))
    -----------------------------------------------
    local bloodPlague, bloodPlagueLeft = ns.HasMyDebuff('Кровавая чума')
    local frostFever, frostFeverLeft = ns.HasMyDebuff('Озноб')
    -----------------------------------------------
    local bloodRunes = (select(3, GetRuneCooldown(1)) and (GetRuneType(1) == 1) and 1 or 0) +
        (select(3, GetRuneCooldown(2)) and (GetRuneType(2) == 1) and 1 or 0)
    local unholyRunes = (select(3, GetRuneCooldown(3)) and (GetRuneType(3) == 2) and 1 or 0) +
        (select(3, GetRuneCooldown(4)) and (GetRuneType(4) == 2) and 1 or 0)
    local frostRunes = (select(3, GetRuneCooldown(5)) and (GetRuneType(5) == 3) and 1 or 0) +
        (select(3, GetRuneCooldown(6)) and (GetRuneType(6) == 3) and 1 or 0)
    -----------------------------------------------
    local bloodDeathRunes = (select(3, GetRuneCooldown(1)) and (GetRuneType(1) == 4) and 1 or 0) +
        (select(3, GetRuneCooldown(2)) and (GetRuneType(2) == 4) and 1 or 0)
    local unholyDeathRunes = (select(3, GetRuneCooldown(3)) and (GetRuneType(3) == 4) and 1 or 0) +
        (select(3, GetRuneCooldown(4)) and (GetRuneType(4) == 4) and 1 or 0)
    local frostDeathRunes = (select(3, GetRuneCooldown(5)) and (GetRuneType(5) == 4) and 1 or 0) +
        (select(3, GetRuneCooldown(6)) and (GetRuneType(6) == 4) and 1 or 0)
    -----------------------------------------------
    local b1s, _, b1r = GetRuneCooldown(1)
    local b2s, _, b2r = GetRuneCooldown(2)
    -----------------------------------------------
    local ttrb1r = b1r and 0 or 10 - (GetTime() - b1s)
    local ttrb2r = b2r and 0 or 10 - (GetTime() - b2s)
    -----------------------------------------------
    -- если у нас 1 руна есть, то надо чтобы до отката второй было меньше, чем времени до спадания дота
    -- так же до спадания дота должно быть более гкд, чтобы не получилось так, что руна откатится через 500 мс, а дота спадет через 1 - мы зря заюзаем абилки и из-за гкд не успеем обновить
    local timeToBloodRuneReady = math.max(ttrb1r, ttrb2r)
    -----------------------------------------------
    local minDebuffDuration = math.min(frostFeverLeft, bloodPlagueLeft)
    -----------------------------------------------
    -- если у нас нет рун, на кд которых мы опираемся, но есть руны смерти, которых мы не учитываем, то почему бы их не слить...
    local goBloodAbils = bloodRunes == 2 or bloodRunes == 1 and minDebuffDuration > timeToBloodRuneReady + 1.5 or
        not glyphofDisease or minDebuffDuration > 10 or bloodRunes == 0
    -- ситуация - у нас 3 секунды до спадания болезни, руна крови на кд 4 сек и полная руна смерти вместо руны крови
    -- в итоге будет слита руна смерти на касание и мы не сможем заюзать мор

    local hasDiseases = frostFever and bloodPlague
    -- если до отката руны меньше чем до спадания и всё это меньше гкд, то почему бы их не слить, надо дождаться отката руны и заюзать мор
    local waitPestilence = hasDiseases and minDebuffDuration < 1.5 and
        timeToBloodRuneReady < minDebuffDuration and glyphofDisease

    local frostPresenceBuff = ns.HasBuff('Власть льда')

    if st.targetImmuneMagic then
        frostFever = true
        frostFeverLeft = 10
        hasDiseases = bloodPlague
    end
    -----------------------------------------------

    action, reason = 'Кровь вампира', 'утолщаемся'
    if (goBloodAbils and needHeal or needDeathPact) and canUseSpell(action) then return action, reason end

    action, reason = 'Особое пойло Нота', 'хилися и восстанавливаем рп'
    if (needHeal or (needDeathPact and runicPower < 40)) and canUseItem(action) then return action, reason end

    action, reason = 'Воскрешение мертвых', 'призываем гуля'
    if needDeathPact and (runicPower >= 40) and canUseGcdSpell(action) then return action, reason end

    action, reason = 'Смертельный союз', 'хилимся гулем' -- 40rp
    if hasGhoul and canUseGcdSpell(action) then return action, reason end

    local inMelee = ns.IsSpellInRange('Удар чумы')

    action, reason = 'Захват рун', 'хилися на 10% хп'
    if goBloodAbils and st.playerHP100 < 70 and canUseSpell(action) then return action, reason end

    action, reason = 'Незыблемость льда', 'физ деф hp < 75%' -- 20rp
    if st.playerHP100 < 75 and ns.TimerLess("SWING_DAMAGE", 2) and canUseSpell(action) then return action, reason end

    action, reason = 'Антимагический панцирь', 'маг деф hp < 75%' -- 20rp
    if st.playerHP100 < 75 and ns.TimerLess("SPELL_DAMAGE", 2) and canUseSpell(action) then return action, reason end
    -----------------------------------------------
    -- недавно прожали, то не частим
    if ns.TimerMore('KICK', 0.5) then
        local spell, notinterrupt = ns.UnitNeedKick('target')
        local needKick = spell and not notinterrupt
        action, reason = 'Заморозка разума', 'кик в гкд [%s]' -- 20rp
        if needKick and canUseSpell(action) then
            ns.TimerStart('KICK')
            return action, format(reason, spell)
        end

        action, reason = 'Удушение', 'кик [%s] - цель'
        if needKick and canUseGcdSpell(action) then
            ns.TimerStart('KICK')
            return action, format(reason, spell)
        end

        if frostPresenceBuff or not st.group then
            action, reason = 'Хватка смерти', 'кик [%s]'
            if spell and notinterrupt and ns.CanUseAction(action) then
                ns.TimerStart('KICK')
                return action, format(reason, spell)
            end

            spell, notinterrupt = ns.UnitNeedKick('mouseover')
            action, reason = 'Хватка смерти MO', 'кик [%s]'
            if spell and ns.CanUseAction(action) and ns.IsSpellInRange('Хватка смерти', 'mouseover') then
                ns.TimerStart('KICK')
                return action, format(reason, spell)
            end
        end
    end
    -----------------------------------------------
    if frostPresenceBuff and st.group and not st.pvp then -- только в группе
        -- Пуллтайм ротация
        local isPull = ns.TimerLess('combatLock', 3)      -- Первые 3 секунды боя
        if isPull then
            action, reason = 'Смерть и разложение', 'пул'
            if goBloodAbils and canUseGcdSpell(action) then return action, reason end
        end
        if ns.State.combatLock then
            -- Проверка агро для маусовер-цели
            action, reason = tryThreat('mouseover')
            if action then return action, reason end

            -- Проверка агро для текущей цели
            action, reason = tryThreat('target')
            if action then return action, reason end
        end
    end

    if not inMelee then
        action, reason = 'Ледяное прикосновение', 'range 1'
        if frostFeverLeft < 1 and not st.targetImmuneMagic and canUseGcdSpell(action) then return action, reason end

        action, reason = 'Лик смерти', 'range 2' -- 40rp
        if goRunicAbils and runicPower >= (frostPresenceBuff and 80 or 60) and canUseGcdSpell(action) then
            return action,
                reason
        end

        action, reason = 'Зимний горн', 'range 3'
        if canUseSpell(action) then return action, reason end
        action, reason = 'none', 'больше нечем в range'
        return action, reason
    end

    local numTargets = st.numTargets

    local numWoundedTargets = math_max(ns.DotedTargetsCount('Кровавая чума'), ns.DotedTargetsCount('Озноб'))
    local maxTargets = math_max(numTargets, numWoundedTargets)

    if ns.TimerLess('Мор', 2) then lastNumWoundedTargets = numWoundedTargets end

    -- Death and Decay > Ледяное прикосновение > Удар чумы > Pestilence > Blood Boil
    local targetsForAOE = 3

    action, reason = 'Мор', 'обновляем болезни'
    if glyphofDisease and hasDiseases and (frostFeverLeft < 3 or bloodPlagueLeft < 3) and canUseGcdSpell(action) then
        return
            action, reason
    end

    action, reason = 'none', 'ждем [Мор]'
    if waitPestilence then return action, reason end

    if hasDiseases and ns.TimerMore('Мор', 2) and
        (
            (numTargets > numWoundedTargets and lastNumWoundedTargets ~= numWoundedTargets) or
            (numTargets > 1 and frostFeverLeft ~= bloodPlagueLeft)
        ) then
        action, reason = 'Мор', 'довешиваем болячки'
        if canUseGcdSpell(action) then
            return action, reason
        end
        action, reason = 'Кровоотвод', 'нет рун крови на [Мор]'
        if bloodRunes < 1 and canUseSpell(action) then
            return action, reason
        end
        action, reason = 'none', 'ждем довес [Мор]'
        return action, reason
    end

    action, reason = 'Смерть и разложение', 'aoe'
    if needMoreDamage and maxTargets >= targetsForAOE and goBloodAbils and canUseGcdSpell(action) then
        return action,
            reason
    end

    if needBurst or needMoreDamage then
        action, reason = 'Безудержная ярость', 'pvp бурст'
        if not st.instance and not ns.HasBuff('Перемирие') and canUseSpell(action) then return action, reason end

        action, reason = 'Варварский ритуал', 'pve бурст'
        if not st.pvp and canUseSpell(action) then return action, reason end

        action, reason = 'Истерия', 'бурст'
        if st.playerHP100 > 80 and not st.pvp and not ns.HasBuff('Истерия') and canUseSpell(action) then
            return action, reason
        end
    end

    action, reason = 'Особое пойло Нота', 'бурст, восстанавливаем рп'
    if (needBurst and not needDeathPact) and (runicPower < 60) and canUseItem(action) then return action, reason end

    action, reason = 'Танцующее руническое оружие', 'бурст' -- 60rp
    if needBurst and not needDeathPact and canUseGcdSpell(action) then return action, reason end

    action, reason = 'Рунический удар', 'не aoe' -- 20rp goRunicAbils and
    if numTargets < targetsForAOE and canUseCurrentSpell(action) then return action, reason end

    action, reason = 'Пожинание', 'сливаем runic power' -- 32rp
    if goRunicAbils and runicPower > 80 and canUseGcdSpell(action) then return action, reason end


    action, reason = 'Ледяное прикосновение', 'вешаем [Озноб]'
    if frostFeverLeft < 1 and not st.targetImmuneMagic and canUseGcdSpell(action) then return action, reason end

    action, reason = 'Удар чумы', 'вешаем [Кровавая чума]'
    if bloodPlagueLeft < 1 and canUseGcdSpell(action) then return action, reason end

    local targetDebuffsFromMe = (bloodPlague and 1 or 0) + (frostFever and 1 or 0)

    action, reason = 'Удар смерти', 'хилимся, есть болезни'
    if st.playerHP100 < (st.group and 40 or 80) and targetDebuffsFromMe > 0 and canUseGcdSpell(action) then
        return action,
            reason
    end

    action, reason = 'Вскипание крови', 'Вскипаем, лужа на кд'
    if goBloodAbils and hasDiseases and (frostFeverLeft == bloodPlagueLeft) and numWoundedTargets >= targetsForAOE and (ns.TimerLess('Смерть и разложение', 30 - morbidityTalentCount * 5 - timeToBloodRuneReady)) and canUseGcdSpell(action) then
        return
            action, reason
    end

    action, reason = 'Рунический удар', 'руник' -- 20rp goRunicAbils and
    if canUseCurrentSpell(action) then return action, reason end

    action, reason = 'Удар смерти', 'дамажим, есть болезни'
    if (unholyRunes + frostRunes) > 1 and (not glyphofDeathStrike or runicPower >= 25) and targetDebuffsFromMe > 0 and canUseGcdSpell(action) then
        return
            action, reason
    end

    action, reason = 'Зимний горн', 'дуем в дудку'
    if canUseSpell(action) then return action, reason end

    local goFrostAbils = frostRunes > 0 or frostDeathRunes > 0 or bloodDeathRunes == 0 or not glyphofDisease or b2r or
        hasDiseases and minDebuffDuration > ttrb2r + 1.5 or
        minDebuffDuration > 10

    action, reason = 'Ледяное прикосновение', 'агро лед тач'
    if frostPresenceBuff and goFrostAbils and not st.targetImmuneMagic and numTargets < targetsForAOE and canUseGcdSpell(action) then
        return
            action, reason
    end

    action, reason = 'Удар в сердце', 'не aoe, cливаем руну крови'
    if goBloodAbils and (numTargets < targetsForAOE) and canUseGcdSpell(action) then return action, reason end

    action, reason = 'Пожинание', 'сливаем runic power' -- 32rp
    if goRunicAbils and runicPower >= (frostPresenceBuff and 80 or 52) and canUseGcdSpell(action) then
        return action,
            reason
    end

    action, reason = 'Кровоотвод', 'нет рун крови'
    if not st.gcd and bloodRunes < 1 and canUseSpell(action) then return action, reason end

    action, reason = 'Усиление рунического оружия', 'нет рун'
    if not st.gcd and runicPower < 20 and (bloodRunes + unholyRunes + frostRunes + bloodDeathRunes + unholyDeathRunes + frostDeathRunes == 0) and canUseSpell(action) then
        return
            action, reason
    end

    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    -- action, reason = 'none', 'гкд'
    -- if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', '#пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------
local function getFrostAction()
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
local function getUncholyAction()
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
local rotations = { getBloodAction, getFrostAction, getUncholyAction }
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
