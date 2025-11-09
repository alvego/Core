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
local UnitThreatSituation = UnitThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitAffectingCombat = UnitAffectingCombat
local UnitExists = UnitExists
local UnitOnTaxi = UnitOnTaxi
local UnitIsUnit = UnitIsUnit
local UnitCanAttack = UnitCanAttack
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local tContains = tContains
local format = format
local tostring = tostring
local tinsert = tinsert
-------------------------------------------------------------------------------
local isLoaded = false
local cleanseTypes = { 'Magic', 'Disease', 'Poison' }
local sealAuras, stanceAuras, stanceDefenceAuras, blessingAuras, tauntSpells
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


    addSpell('Праведная защита')
    addSpell('Длань возмездия')
    addSpell('Длань спасения')



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

    tauntSpells = {
        spell['Праведная защита'],
        spell['Длань возмездия'],
        spell['Длань спасения'],
    }

    isLoaded = true;
end
c.AttachEvent('PLAYER_ENTERING_WORLD', onLoad)

-------------------------------------------------------------------------------
--local forbearanceId = 25771 -- Воздержанность
local function inForbearance(unit)
    if unit == nil then unit = "player" end
    --return (c.TimerLess('Гнев карателя', 30) or c.HasAuraByID(forbearanceId, unit))
    return (c.TimerLess('Гнев карателя', 30) or c.HasDebuff('Воздержанность', unit))
end

local forbearanceSpells = { "Гнев карателя", "Божественный щит", "Возложение рук", "Божественная защита", "Длань защиты" }
c.CustomCanUseSpell = function(spell, unit)
    if tContains(forbearanceSpells, spell) and inForbearance(unit) then return false end
    return true
end
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

local isTank = false
-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if not isLoaded then return end
    isTank = c.HasAuraByID('player', spell['Праведное неистовство']) and true or false
    return c.TelemetryRedBool('TANK', isTank)
end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if not isLoaded then return end
    return c.TelemetryRedBool('AURA', c.UnitAuraByID('player', stanceDefenceAuras))
end)

-------------------------------------------------------------------------------
c.AttachTelemetry(function()
    if not isLoaded then return end --
    --return c.TelemetryRedBool('5M', not UnitExists('target') or c.IsSpellInRange('Молот праведника', 'target'))
    return format('Dist: %.2f', UnitExists('target') and c.UnitDistance('player', 'target') or 0)
end)

-------------------------------------------------------------------------------
-- Функции для обработки агро-способностей
-------------------------------------------------------------------------------
local function checkThreatUnit(unit, action, threatStatus, checkHand) -- unit with threat
    if not UnitExists(unit) then return end
    if UnitIsUnit('player', unit) then return end
    if UnitThreatSituation(unit) ~= threatStatus then return end
    if action and not c.IsSpellInRange(action, unit) then return end
    if checkHand and c.HasBuff('Длань', unit) then return end
    if not c.UnitInLOS('player', unit) then return end
    if UnitExists('focus') and UnitIsUnit('focus', unit) then return end
    if c.UnitIsTank(unit) then return end
    return unit
end
local tankingUnits = {}
local function checkTankingUnit(unit, target)
    if UnitThreatSituation(unit, target) == 3 then return true end
    return nil
end
local function checkTauntTarget(target, action, checkHand) -- target for taunt
    if not target or not UnitExists(target) then return end
    if not UnitCanAttack('player', target) then return end
    if not UnitAffectingCombat(target) == 1 then return end
    if not c.IsSpellInRange(action, target) then return end
    if checkHand and c.HasBuff('Длань', target) then return end
    if not c.UnitInLOS('player', target) then return end
    if not c.FindValue(tankingUnits, checkTankingUnit, target) then return end
    return target
end
local function getTauntTarget(action)
    wipe(tankingUnits)
    local units = c.GetGroupUnits()
    for i = 1, #units do
        local unit = checkThreatUnit(units[i], nil, 3)
        if unit then tinsert(tankingUnits, unit) end
    end
    return c.FindValue(c.GetTargets(), checkTauntTarget, action, true)
end
-------------------------------------------------------------------------------
local function checkCastTarget(target, action) -- unit for taunt
    if not UnitCanAttack('player', target) then return end
    if not UnitAffectingCombat(target) then return end
    if UnitIsTapped(target) and not UnitIsTappedByPlayer(target) then return end
    if not c.UnitCasting(target) then return end
    if not c.IsSpellInRange(action, target) then return end
    if not c.UnitInLOS('player', target) then return end
    return target
end
-------------------------------------------------------------------------------
local function checkFinishTarget(target, action)
    if not UnitCanAttack('player', target) then return end
    if not UnitAffectingCombat(target) then return end
    if UnitIsTapped(target) and not UnitIsTappedByPlayer(target) then return end
    if not (c.UnitHealth100(target) < 19.9) then return end
    if not c.IsSpellInRange(action, target) then return end
    if not c.UnitInLOS('player', target) then return end
    return target
end
-------------------------------------------------------------------------------
local function updateProto()
    local reason, action, unit
    -------------------------------------------------------------------------------
    -- иногда в ротации есть необходимость прерывания своего каста
    reason = '#cast [%s]'
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
    local useMana = c.attack or (mana100 > 50)
    -------------------------------------------------------------------------------
    -- автовключание если в группе и есть отметка что танк
    reason, action, unit = 'Влючаем баф для танкования', 'Праведное неистовство', 'player'
    if not isTank and (UnitGroupRolesAssigned("player") == 'TANK') and c.CanUseGcdSpell(action, unit, 5) then
        c.DoAction(reason, action, unit)
        return reason
    end

    -------------------------------------------------------------------------------
    reason, action, unit = 'Деф PVE с созвездия', 'Криво-пружинный механизм', 'player'
    if not st.pvp and needHeal and c.CanUseSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
        return reason
    end
    -------------------------------------------------------------------------------

    reason, action, unit = format('group: Хилка без каста на %s%% hp', c.Round(st.playerHP100)),
        (st.playerHP100 < 85) and 'Свет небес' or 'Вспышка Света', 'player'
    if not st.gcd and st.playerHP100 < 99 and c.CanUseGcdSpell(action, unit) and c.HasBuff('Криво-пружинный механизм') then
        c.DoAction(reason, action, unit)
        return reason
    end

    -------------------------------------------------------------------------------
    reason, action, unit = 'Очень мало хп в бою, нужен хил', 'Возложение рук', 'player'
    if st.combatMode and st.playerHP100 < 20 and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Мало хп в бою, нужен деф', 'Божественная защита', 'player'
    if st.combatMode and needHeal and c.CanUseSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
    end
    -------------------------------------------------------------------------------
    unit = 'mouseover'
    if c.start and UnitExists(unit) then
        if c.IsSpellNotUsed(tauntSpells, 0.5) then
            reason, action, unit = 'Танунт по мышке', 'Длань возмездия', 'mouseover'
            if UnitCanAttack('player', unit) and c.CanUseSpell(action, unit) and not UnitIsUnit('player', unit .. '-target') and not c.HasBuff('Длань', unit) then
                c.DoAction(reason, action, unit)
                return reason
            end
            reason, action, unit = 'Снятие агро по мышке', 'Праведная защита',
                UnitIsPlayer(unit) and unit or unit .. '-target'
            if c.UnitInGroup(unit) and c.CanUseSpell(action, unit) and (UnitThreatSituation(unit) == 3) then
                c.DoAction(reason, action, unit)
                return reason
            end
        end
    end
    -------------------------------------------------------------------------------
    if not st.gcd and (st.start or (not c.attack and st.combatMode)) then
        -------------------------------------------------------------------------------
        reason, action, unit = 'Нужно обновить печать', 'Печать повиновения', 'player'
        if c.CanUseGcdSpell(action, unit, 10) and not c.UnitAuraByID(unit, sealAuras) then
            c.DoAction(reason, action, unit)
            return reason
        end
        -------------------------------------------------------------------------------
        reason, action, unit = 'Нужно обновить стойку', isTank and 'Аура благочестия' or 'Аура воздаяния', 'player'
        if useMana and c.CanUseGcdSpell(action, unit) and c.IsSpellNotUsed(stanceAuras, 15) then
            -- Могу прожать стойку
            local stance = c.UnitAuraByID(unit, stanceAuras, true)
            if stance then
                -- на мне ecть моя стойка (аура палладина)
                -- но она не атуальна, чужой атуальной нет
                if stance == spell['Аура воина Света'] and not c.HasAuraByID(unit, spell[action]) then
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
    end

    -------------------------------------------------------------------------------
    local dist = c.UnitDistance('target', 'player')
    -------------------------------------------------------------------------------
    if isTank and st.group and not st.pvp then      -- только в группе
        -- Пуллтайм ротация
        local isPull = c.TimerLess('combatLock', 3) -- Первые 3 секунды боя

        if isPull then
            reason, action = 'пул', 'Освящение'
            if still and useMana and dist < 8 and c.CanUseGcdSpell(action) and (c.targetHard or c.GetEnemyCount(8, 'player') > 2) then
                c.DoAction(reason, action)
                return reason
            end
        elseif c.state.combatLock and c.IsSpellNotUsed(tauntSpells, 0.5) then
            -------------------------------------------------------------------------------
            reason, action, unit = 'Снимаем агро', 'Праведная защита', 'target'
            if c.IsUsableSpell(action) then
                unit = c.FindValue(c.GetGroupUnits(), checkThreatUnit, action, 3) -- 3 red indicator
                if unit then
                    c.DoAction(reason, action, unit)                              -- мговенка
                    return reason                                                 -- не частим
                end
            end

            -------------------------------------------------------------------------------
            reason, action, unit = 'Таунт', 'Длань возмездия', 'target'
            if c.IsUsableSpell(action) then
                unit = getTauntTarget(action)
                if unit then
                    c.DoAction(reason, action, unit) -- мговенка
                    return reason                    -- не частим
                end
            end

            -- -------------------------------------------------------------------------------
            reason, action, unit = 'Понижаем агро', 'Длань спасения', 'target'
            if not st.gcd and c.IsUsableSpell(action) then
                unit = c.FindValue(c.GetGroupUnits(), checkThreatUnit, action, 2, true) -- 2 orange indicator
                if unit then
                    c.DoAction(reason, action, unit)
                    return reason -- не частим
                end
            end

            -------------------------------------------------------------------------------
        end
    end -- isTank
    -------------------------------------------------------------------------------
    reason, action, unit = 'Пробуем снять ', 'Очищение', 'player'
    if c.IsSpellFailedRecently(action) then
        c.TimerStart(action) -- считаем что использовали
    end
    if not st.gcd and useMana then
        local cleanseDebuff = c.HasDebuff(cleanseTypes, unit, 5) -- яд, болезнь и маг эффект
        reason = reason .. tostring(cleanseDebuff)
        if cleanseDebuff and c.CanUseGcdSpell(action, unit, 10) then
            c.DoAction(reason, action, unit)
            return reason
        end
    end
    -------------------------------------------------------------------------------
    reason = c.TryTarget(not isTank, 40, c.attack or st.look)
    -- есть ли причина для отстановки?
    if reason then return reason end

    if dist > 5 and (dist < 10 or c.attack) then c.PlayerMove('target', 60) end
    -------------------------------------------------------------------------------
    -- Дальше считаем что у нас есть валидная цель
    -------------------------------------------------------------------------------
    reason, action, unit = 'Обновляем баф на ману', 'Святая клятва', 'player'
    if c.CanUseGcdSpell(action, unit) and not c.HasAuraByID(unit, spell[action]) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Нужнен баф на блокирование', 'Щит небес', 'player'
    if not st.gcd and dist < 10 and useMana and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Урон агрилкой', 'Длань возмездия', 'target'
    if useMana and (isTank or not st.group) and not (UnitExists(unit .. '-target') and UnitIsUnit(unit .. '-target', 'player') == 1) and c.CanUseSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Экзорцизм без каста', 'Экзорцизм', 'target'
    if useMana and st.playerHP100 >= 99 and c.CanUseGcdSpell(action, unit) and c.HasBuff('Криво-пружинный механизм') then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Добивание', 'Молот гнева', 'target'
    if useMana and not st.gcd and c.IsUsableSpell(action) then
        unit = c.FindValue(c.GetTargets(), checkFinishTarget, action)
        if unit then
            c.DoAction(reason, action, unit)
            return reason -- не частим
        end
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Сало на троих', 'Щит мстителя', 'target'
    if useMana and not st.gcd and c.IsUsableSpell(action) then
        unit = c.FindValue(c.GetTargets(), checkCastTarget, action)
        if unit then
            c.DoAction(reason, action, unit)
            return reason -- не частим
        end
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
    reason, action, unit =
        'Нужно пустить лужу - ' ..
        (c.targetHard and 'страшно' or 'враги окружили'),
        'Освящение', 'target'
    if not st.gcd and still and useMana and dist < 8 and (c.targetHard or c.GetEnemyCount(8, 'player') > 2) and c.CanUseGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end
    -------------------------------------------------------------------------------
    reason, action, unit = 'Заполнитель', 'Щит праведности', 'target'
    if useMana and c.CanUseGcdSpell(action) then
        c.DoAction(reason, action, unit)
        return reason
    end

    --if st.gcd then return '#gcd' end
    --if not useMana then return '#mana' end
    return '#none'
end
-------------------------------------------------------------------------------
function c.Update()
    if not isLoaded then return end
    local stopReason = c.GetStopReason()
    if stopReason then
        -------------------------------------------------------------------------------
        -- только для палладина, врубаем коня на маунте
        -------------------------------------------------------------------------------
        if stopReason == c.stopReasonMount and not UnitOnTaxi("player") then
            local reason, action, unit = 'Врубаем ускорение на транспорте', 'Аура воина Света', 'player'
            if not c.HasAuraByID(unit, spell[action]) and c.CanUseGcdSpell(action, unit) then
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
