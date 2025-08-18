------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
if ns.State.playerClass ~= 'DEATHKNIGHT' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(ns.State.playerClass, ns.State.playerColor)
------------------------------------------------------------------------------------------------------------------
local GetRuneCooldown = GetRuneCooldown
local GetRuneType = GetRuneType
local GetTalentInfo = GetTalentInfo
------------------------------------------------------------------------------------------------------------------
local lastNumWoundedTargets = 0
ns.AttachEvent('PLAYER_REGEN_ENABLED', function()
    lastNumWoundedTargets = 0
end)

local function getBloodAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end

    local runicPower = UnitPower('player')
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end

    local inMelee = ns.IsSpellInRange('Удар чумы')
    if ns.TimerMore('Удушение', 1) and ns.UnitNeedKick('target') and ns.CanUseAction('Заморозка разума') then
        return 'Заморозка разума', 'кик в гкд'
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if ns.State.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    if ns.TimerMore('Заморозка разума', 1) and ns.UnitNeedKick('target') and ns.CanUseAction('Удушение') then
        return 'Удушение', 'кик'
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

    -- ситуация - у нас 3 секунды до спадания болезни, руна крови на кд 4 сек и полная руна смерти вместо руны крови
    -- в итоге будет слита руна смерти на касание и мы не сможем заюзать мор

    -- если до отката руны меньше чем до спадания и всё это меньше гкд, то почему бы их не слить, надо дождаться отката руны и заюзать мор
    local waitPestilence = frostFever and bloodPlague and minDebuffDuration < 1.5 and
        timeToBloodRuneReady < minDebuffDuration and glyphofDisease

    local immuneToFrost = ns.State.targetImmuneMagic

    if immuneToFrost then
        frostFever = true
        frostFeverLeft = 10
    end

    if not inMelee then
        if frostFeverLeft < 1 and not immuneToFrost and ns.CanUseAction('Ледяное прикосновение') then
            return 'Ледяное прикосновение', 'range 1'
        end
        if ns.CanUseAction('Лик смерти') then
            return 'Лик смерти', 'range 2'
        end
        if IsUsableSpell('Зимний горн') and ns.CanUseAction('Зимний горн') then
            return 'Зимний горн', 'range 3'
        end
        return 'none', 'больше нечем в range'
    end

    local numTargetsReal = ns.State.numTargets
    local numTargets = numTargetsReal

    local numWoundedTargets = math.max(ns.DotedTargetsCount('Кровавая чума'), ns.DotedTargetsCount('Озноб'))

    if ns.TimerLess('Мор', 2) then lastNumWoundedTargets = numWoundedTargets end

    -- Death and Decay > Ледяное прикосновение > Удар чумы > Pestilence > Blood Boil
    local targetsForAOE = 3

    if glyphofDisease and frostFever and bloodPlague and (frostFeverLeft < 3 or bloodPlagueLeft < 3) and ns.CanUseAction('Мор') then
        return 'Мор', 'обновляем болезни'
    end

    if waitPestilence then
        return 'none', 'ждем [Мор]'
    end

    if numTargets < targetsForAOE and not IsCurrentSpell('Рунический удар') and IsUsableSpell('Рунический удар') and ns.CanUseAction('Рунический удар') then
        return 'Рунический удар', 'не aoe'
    end

    if runicPower > 80 and ns.CanUseAction('Пожинание') then
        return 'Пожинание', 'сливаем runic power'
    end


    if numTargets >= targetsForAOE and goBloodAbils and ns.CanUseAction('Смерть и разложение') then
        return 'Смерть и разложение', 'aoe'
    end

    if frostFever and bloodPlague and numTargetsReal > numWoundedTargets and lastNumWoundedTargets ~= numWoundedTargets and ns.CanUseAction('Мор') then
        return 'Мор', 'довешиваем болячки'
    end

    if frostFeverLeft < 1 and not immuneToFrost and ns.CanUseAction('Ледяное прикосновение') then
        return 'Ледяное прикосновение', 'вешаем [Озноб]'
    end

    if bloodPlagueLeft < 1 and ns.CanUseAction('Удар чумы') then
        return 'Удар чумы', 'вешаем [Кровавая чума]'
    end

    if goBloodAbils and ns.State.playerHP100 < 70 and ns.CanUseAction('Захват рун') then
        return 'Захват рун', 'хилимся hp < 70%'
    end

    local targetDebuffsFromMe = (bloodPlague and 1 or 0) + (frostFever and 1 or 0)

    if ns.State.playerHP100 < (ns.State.group and 40 or 80) and targetDebuffsFromMe > 0 and ns.CanUseAction('Удар смерти') then
        return 'Удар смерти', 'хилимся, есть болезни'
    end

    if ns.State.targetHard and ns.CanUseAction('Танцующее руническое оружие') then
        return 'Танцующее руническое оружие', 'бурст'
    end

    if goBloodAbils and numTargets >= targetsForAOE and (ns.TimerLess('Смерть и разложение', 30 - morbidityTalentCount * 5 - timeToBloodRuneReady)) and ns.CanUseAction('Вскипание крови') then
        return 'Вскипание крови', 'слив руны крови, пока нет [Смерть и разложение]'
    end

    if not IsCurrentSpell('Рунический удар') and IsUsableSpell('Рунический удар') and ns.CanUseAction('Рунический удар') then
        return 'Рунический удар', 'руник'
    end

    if unholyRunes + frostRunes > 1 and (not glyphofDeathStrike or runicPower >= 25) and targetDebuffsFromMe > 0 and ns.CanUseAction('Удар смерти') then
        return 'Удар смерти', 'дамажим, есть болезни'
    end

    if IsUsableSpell('Зимний горн') and ns.CanUseAction('Зимний горн') then
        return 'Зимний горн', 'дуем'
    end

    -- local GoFrostAbils = frostRunes > 0 or frostDeathRunes > 0 or bloodDeathRunes == 0 or not glyphofDisease or b2r or
    --     frostFever and bloodPlague and minDebuffDuration > ttrb2r + 1.5 or
    --     minDebuffDuration > 10

    if goBloodAbils and (numTargets < targetsForAOE) and ns.CanUseAction('Кровавый удар') then
        return 'Удар в сердце', 'не aoe, cливаем руну крови'
    end

    if runicPower >= 0 and ns.CanUseAction('Пожинание') then
        return 'Пожинание', 'сливаем runic power'
    end

    if bloodRunes < 1 and IsUsableSpell('Кровоотвод') and ns.CanUseAction('Кровоотвод') then
        return 'Кровоотвод', 'нет рун крови'
    end

    return 'none', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local function getFrostAction()
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
local function getUncholyAction()
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
local rotations = { getBloodAction, getFrostAction, getUncholyAction }
function ns:GetAction()
    local spec = ns.GetCurrentSpecID()
    local rotation = rotations[spec]
    return rotation()
end
