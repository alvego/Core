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
local GetRuneType = GetRuneType
local GetTalentInfo = GetTalentInfo
------------------------------------------------------------------------------------------------------------------
local lastNumWoundedTargets = 0
ns.AttachEvent('PLAYER_REGEN_ENABLED', function()
    lastNumWoundedTargets = 0
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
    return not IsCurrentSpell(spell) and canUseSpell(spell)
end
------------------------------------------------------------------------------------------------------------------
local function getBloodAction()
    local action

    if st.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. st.playerCasting .. ']'
    end

    local runicPower = UnitPower('player')
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    local inMelee = ns.IsSpellInRange('Удар чумы')

    action = 'Безудержная ярость'
    if inMelee and not st.instance and not ns.HasBuff('Перемирие') and canUseSpell(action) then
        return action, 'pvp бурст'
    end

    action = 'Варварский ритуал'
    if inMelee and not st.pvp and canUseSpell(action) then
        return action, 'pve бурст'
    end

    action = 'Истерия'
    if inMelee and not st.pvp and canUseSpell(action) then
        return action, 'бурст'
    end

    action = 'Незыблемость льда'
    if inMelee and st.playerHP100 < 80 and canUseSpell(action) then
        return action, 'деф hp < 80%'
    end

    action = 'Заморозка разума'
    if ns.TimerMore('Удушение', 1) and ns.UnitNeedKick('target') and canUseSpell(action) then
        return action, 'кик в гкд'
    end

    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    --if st.gcd then return 'none', 'гкд' end
    -- то что требуется гкд

    action = 'Удушение'
    if ns.TimerMore('Заморозка разума', 1) and ns.UnitNeedKick('target') and canUseGcdSpell(action) then
        return action, 'кик'
    end

    local glyphofDisease = true     -- При использовании способности 'Мор' время действия болезней и их вторичных эффектов на цели обновляется.
    local glyphofDeathStrike = true -- Увеличивает урон от способности 'Удар смерти' на 1% за каждые 1 ед. накопленной силы рун (максимум на 25%). Сила рун при этом не расходуется.
    local morbidityTalentCount = select(5, GetTalentInfo(3, 5))

    local bloodPlague, bloodPlagueLeft = ns.HasMyDebuff('Кровавая чума')
    local frostFever, frostFeverLeft = ns.HasMyDebuff('Озноб')


    local bloodRunes = (select(3, GetRuneCooldown(1)) and (GetRuneType(1) == 1) and 1 or 0) +
        (select(3, GetRuneCooldown(2)) and (GetRuneType(2) == 1) and 1 or 0)
    local unholyRunes = (select(3, GetRuneCooldown(3)) and (GetRuneType(3) == 2) and 1 or 0) +
        (select(3, GetRuneCooldown(4)) and (GetRuneType(4) == 2) and 1 or 0)
    local frostRunes = (select(3, GetRuneCooldown(5)) and (GetRuneType(5) == 3) and 1 or 0) +
        (select(3, GetRuneCooldown(6)) and (GetRuneType(6) == 3) and 1 or 0)

    local bloodDeathRunes = (select(3, GetRuneCooldown(1)) and (GetRuneType(1) == 4) and 1 or 0) +
        (select(3, GetRuneCooldown(2)) and (GetRuneType(2) == 4) and 1 or 0)
    local unholyDeathRunes = (select(3, GetRuneCooldown(3)) and (GetRuneType(3) == 4) and 1 or 0) +
        (select(3, GetRuneCooldown(4)) and (GetRuneType(4) == 4) and 1 or 0)
    local frostDeathRunes = (select(3, GetRuneCooldown(5)) and (GetRuneType(5) == 4) and 1 or 0) +
        (select(3, GetRuneCooldown(6)) and (GetRuneType(6) == 4) and 1 or 0)

    local b1s, _, b1r = GetRuneCooldown(1)
    local b2s, _, b2r = GetRuneCooldown(2)

    local ttrb1r = b1r and 0 or 10 - (GetTime() - b1s)
    local ttrb2r = b2r and 0 or 10 - (GetTime() - b2s)

    -- если у нас 1 руна есть, то надо чтобы до отката второй было меньше, чем времени до спадания дота
    -- так же до спадания дота должно быть более гкд, чтобы не получилось так, что руна откатится через 500 мс, а дота спадет через 1 - мы зря заюзаем абилки и из-за гкд не успеем обновить
    local timeToBloodRuneReady = math.max(ttrb1r, ttrb2r)

    local minDebuffDuration = math.min(frostFeverLeft, bloodPlagueLeft)

    -- если у нас нет рун, на кд которых мы опираемся, но есть руны смерти, которых мы не учитываем, то почему бы их не слить...
    local goBloodAbils = bloodRunes == 2 or bloodRunes == 1 and minDebuffDuration > timeToBloodRuneReady + 1.5 or
        not glyphofDisease or minDebuffDuration > 10 or bloodRunes == 0
    goBloodAbils = goBloodAbils or frostDeathRunes > 0 or unholyDeathRunes > 0
    -- ситуация - у нас 3 секунды до спадания болезни, руна крови на кд 4 сек и полная руна смерти вместо руны крови
    -- в итоге будет слита руна смерти на касание и мы не сможем заюзать мор

    -- если до отката руны меньше чем до спадания и всё это меньше гкд, то почему бы их не слить, надо дождаться отката руны и заюзать мор
    local waitPestilence = frostFever and bloodPlague and minDebuffDuration < 1.5 and
        timeToBloodRuneReady < minDebuffDuration and glyphofDisease

    local frostPresenceBuff = ns.HasBuff('Власть льда')
    local immuneToFrost = st.targetImmuneMagic

    if immuneToFrost then
        frostFever = true
        frostFeverLeft = 10
    end

    if not inMelee then
        action = 'Ледяное прикосновение'
        if frostFeverLeft < 1 and not immuneToFrost and canUseGcdSpell(action) then
            return action, 'range 1'
        end

        action = 'Лик смерти'
        if runicPower >= (frostPresenceBuff and 60 or 0) and canUseGcdSpell(action) then
            return action, 'range 2'
        end

        action = 'Зимний горн'
        if canUseSpell(action) then
            return action, 'range 3'
        end

        return 'none', 'больше нечем в range'
    end

    local numTargetsReal = st.numTargets
    local numTargets = numTargetsReal

    local numWoundedTargets = math.max(ns.DotedTargetsCount('Кровавая чума'), ns.DotedTargetsCount('Озноб'))

    if ns.TimerLess('Мор', 2) then lastNumWoundedTargets = numWoundedTargets end

    -- Death and Decay > Ледяное прикосновение > Удар чумы > Pestilence > Blood Boil
    local targetsForAOE = 3

    action = 'Мор'
    if glyphofDisease and frostFever and bloodPlague and (frostFeverLeft < 3 or bloodPlagueLeft < 3) and canUseGcdSpell(action) then
        return action, 'обновляем болезни'
    end

    if waitPestilence then
        return 'none', 'ждем [Мор]'
    end

    if frostFever and bloodPlague and numTargetsReal > numWoundedTargets and lastNumWoundedTargets ~= numWoundedTargets then
        action = 'Мор'
        if canUseGcdSpell(action) then
            return action, 'довешиваем болячки'
        end
        action = 'Кровоотвод'
        if bloodRunes < 1 and canUseSpell(action) then
            return action, 'нет рун крови на [Мор]'
        end
        return 'none', 'ждем довес [Мор]'
    end

    action = 'Рунический удар'
    if numTargets < targetsForAOE and canUseCurrentSpell(action) then
        return action, 'не aoe'
    end

    action = 'Пожинание'
    if runicPower > 80 and canUseGcdSpell(action) then
        return action, 'сливаем runic power'
    end

    action = 'Смерть и разложение'
    if numTargets >= targetsForAOE and goBloodAbils and canUseGcdSpell(action) then
        return action, 'aoe'
    end

    action = 'Ледяное прикосновение'
    if frostFeverLeft < 1 and not immuneToFrost and canUseGcdSpell(action) then
        return action, 'вешаем [Озноб]'
    end

    action = 'Удар чумы'
    if bloodPlagueLeft < 1 and canUseGcdSpell(action) then
        return action, 'вешаем [Кровавая чума]'
    end

    action = 'Кровь вампира'
    if goBloodAbils and st.playerHP100 < 70 and canUseSpell(action) then
        return action, 'утолщаемся hp < 70%'
    end

    action = 'Захват рун'
    if goBloodAbils and st.playerHP100 < 70 and canUseGcdSpell(action) then
        return action, 'хилимся hp < 70%'
    end

    local targetDebuffsFromMe = (bloodPlague and 1 or 0) + (frostFever and 1 or 0)

    action = 'Удар смерти'
    if st.playerHP100 < (st.group and 40 or 80) and targetDebuffsFromMe > 0 and canUseGcdSpell(action) then
        return action, 'хилимся, есть болезни'
    end

    action = 'Танцующее руническое оружие'
    if st.targetHard and canUseGcdSpell(action) then
        return action, 'бурст'
    end

    action = 'Вскипание крови'
    if goBloodAbils and numTargets >= targetsForAOE and (ns.TimerLess('Смерть и разложение', 30 - morbidityTalentCount * 5 - timeToBloodRuneReady)) and canUseGcdSpell(action) then
        return action, 'Вскипаем, лужа на кд'
    end

    action = 'Рунический удар'
    if canUseCurrentSpell(action) then
        return action, 'руник'
    end

    action = 'Удар смерти'
    if (unholyRunes + frostRunes) > 1 and (not glyphofDeathStrike or runicPower >= 25) and targetDebuffsFromMe > 0 and canUseGcdSpell(action) then
        return action, 'дамажим, есть болезни'
    end

    action = 'Зимний горн'
    if canUseSpell(action) then
        return action, 'дуем в дудку'
    end

    local goFrostAbils = frostRunes > 0 or frostDeathRunes > 0 or bloodDeathRunes == 0 or not glyphofDisease or b2r or
        frostFever and bloodPlague and minDebuffDuration > ttrb2r + 1.5 or
        minDebuffDuration > 10

    action = 'Ледяное прикосновение'
    if frostPresenceBuff and goFrostAbils and not immuneToFrost and numTargets < targetsForAOE and canUseGcdSpell(action) then
        return action, 'агро лед тач'
    end

    action = 'Удар в сердце'
    if goBloodAbils and (numTargets < targetsForAOE) and canUseGcdSpell(action) then
        return action, 'не aoe, cливаем руну крови'
    end

    action = 'Пожинание'
    if runicPower >= (frostPresenceBuff and 60 or 0) and canUseGcdSpell(action) then
        return action, 'сливаем runic power'
    end

    action = 'Кровоотвод'
    if bloodRunes < 1 and canUseSpell(action) then
        return action, 'нет рун крови'
    end
    if st.gcd then return 'none', 'гкд' end
    return 'none', st.gcd and 'гкд' or 'нечем бить'
end
------------------------------------------------------------------------------------------------------------------
local function getFrostAction()
    if st.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. st.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if st.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return 'none', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local function getUncholyAction()
    if st.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. st.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if st.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return 'none', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local rotations = { getBloodAction, getFrostAction, getUncholyAction }
local function updateRotation()
    local spec = ns.GetCurrentSpecID()
    ns.GetAction = rotations[spec]
end
ns.AttachEvent('PLAYER_TALENT_UPDATE', updateRotation)
ns.AttachEvent('ACTIVE_TALENT_GROUP_CHANGED', updateRotation)
ns.AttachEvent('PLAYER_ENTERING_WORLD', updateRotation)
------------------------------------------------------------------------------------------------------------------
