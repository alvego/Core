---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
local UnitClass = UnitClass
-- luacheck: pop
local className = select(2, UnitClass('player'))

if className ~= 'PALADIN' then return end

c.PrintLoadClassModuleMessage(className)

---@class Core.state
local st = c.state
local spell = c.SpellStore
local addSpell = c.SpellStoreAdd
-- luacheck: push ignore
local UnitCreatureType = UnitCreatureType
local UnitThreatSituation = UnitThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitExists = UnitExists
local UnitOnTaxi = UnitOnTaxi
local UnitIsUnit = UnitIsUnit
local UnitCanAttack = UnitCanAttack
local UnitGUID = UnitGUID
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local tContains = tContains
local format = format
local tostring = tostring
local tinsert = tinsert
local wipe = wipe
-- luacheck: pop
local isLoaded = false
local cleanseTypes = { 'Magic', 'Disease', 'Poison' }
local sealAuras, stanceAuras, stanceAurasDD, stanceDefenceAuras, blessingAuras, tauntSpells

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
    addSpell('Священный щит')


    addSpell('Праведная защита')
    addSpell('Длань возмездия')
    addSpell('Длань спасения')
    addSpell('Щит мстителя')



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

    stanceAurasDD = {
        spell['Аура воздаяния'],
        spell['Аура благочестия'],
        spell['Аура защиты от темной магии'],
        spell['Аура защиты от магии льда'],
        spell['Аура защиты от огня'],
        spell['Аура сосредоточенности'],
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
        spell['Щит мстителя'],
    }

    isLoaded = true;
end
c.Event('PLAYER_ENTERING_WORLD', onLoad)


--local forbearanceId = 25771 -- Воздержанность
local function inForbearance(unit)
    if unit == nil then unit = "player" end
    --return (c.TimerLess('Гнев карателя', 30) or c.bHasAuraByID(forbearanceId, unit))
    return (c.TimerLess('Гнев карателя', 30) or c.HasDebuff('Воздержанность', unit))
end

local forbearanceSpells = { "Гнев карателя", "Божественный щит", "Возложение рук", "Божественная защита", "Длань защиты" }
c.CustomCanSpell = function(spell, unit)
    if tContains(forbearanceSpells, spell) and inForbearance(unit) then return false end
    return true
end

local isTank = false

local function getAvailableStance(unit)
    local stances = isTank and stanceAuras or stanceAurasDD
    for i = 1, #stances do
        local stance = stances[i]
        if not c.bGetAura(unit, stance) then
            return stance
        end
    end
    return nil
end


local function getAvailableBlessing(unit)
    for i = 1, #blessingAuras do
        local blessing = spell[blessingAuras[i]]
        if not c.HasBuff(blessing, unit) then
            return blessing
        end
    end
    return nil
end



c.Telemetry(function()
    if not isLoaded then return end
    isTank = c.bHasAura('player', spell['Праведное неистовство']) and true or false
    return c.TelemetryRedBool('Tank', isTank)
end)


c.Telemetry(function()
    if not isLoaded then return end
    return c.TelemetryRedBool('Aura', c.bGetAura('player', stanceDefenceAuras))
end)


c.Telemetry(function()
    if not isLoaded then return end

    return c.TelemetryRedBool(
        format('Dist: %dм.', UnitExists('target') and c.Round(c.bUnitDistance('player', 'target')) or 0),
        c.bInMelee('target')
    )
end)


-- Функции для обработки агро-способностей

local function checkThreatUnit(unit, action, threatStatus, checkHand) -- unit with threat
    if not UnitExists(unit) then return end
    if UnitIsUnit('player', unit) then return end
    if UnitThreatSituation(unit) ~= threatStatus then return end
    if action and not c.IsSpellInRange(action, unit) then return end
    if checkHand and c.HasBuff('Длань', unit) then return end
    if not c.bUnitInLoS('player', unit) then return end
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
    if UnitAffectingCombat(target) ~= 1 then return end
    if not c.IsSpellInRange(action, target) then return end
    if checkHand and c.HasBuff('Длань', target) then return end
    if not c.bUnitInLoS('player', target) then return end
    if not c.FindValue(tankingUnits, checkTankingUnit, target) then return end
    return target
end

local tauntGUIDs = {}
local function getTauntGUID(action, checkHand)
    wipe(tankingUnits)
    local units = c.GetGroupUnits()
    for i = 1, #units do
        local unit = checkThreatUnit(units[i], nil, 3)
        if unit then tinsert(tankingUnits, unit) end
    end

    wipe(tauntGUIDs)
    --CanAttack|IsInCombat|NotTargetingMe|InLoS
    c.bFindUnits(tauntGUIDs, 40, 83, 20)
    return c.FindUnitGUID(tauntGUIDs, checkTauntTarget, action, checkHand)
end

local mouseoverGUID = nil
local mouseoverTimer = 'mouseoverTimer'
c.Event('GLOBAL_MOUSE_DOWN', function(event, button)
    if button ~= "MiddleButton" then return end
    local unit = 'mouseover'

    if not UnitExists(unit) then return end
    mouseoverGUID = UnitGUID(unit)
    c.TimerStart(mouseoverTimer)
end)

local function tryMouseTaunt()
    if not mouseoverGUID then return end
    return c.bWithGUID(mouseoverGUID, function(mouseover)
        if c.TimerMore(mouseoverTimer, 2) then return end
        if not c.IsSpellNotUsed(tauntSpells, 0.5) then return end
        local reason, action, unit = 'Танунт по мышке', 'Длань возмездия', mouseover
        if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then return end

        if UnitCanAttack('player', unit) and c.CanSpell(action, unit) and not c.HasBuff('Длань', unit) and (UnitThreatSituation('player', unit) ~= 3) then
            c.DoAction(reason, action, unit)
            mouseoverGUID = nil
            return reason
        end

        reason, action, unit = 'Снятие агро по мышке', 'Праведная защита', mouseover
        if c.UnitInGroup(unit) and c.CanSpell(action, unit) and (UnitThreatSituation(unit) == 3) then
            c.DoAction(reason, action, unit)
            mouseoverGUID = nil
            return reason
        end
    end)
end


local function updateProto()
    local reason, action, unit

    -- иногда в ротации есть необходимость прерывания своего каста
    reason = '#cast: %s'
    if st.playerCasting then return format(reason, st.playerCasting) end


    c.TimerToggle('needHeal', st.playerHP100 < (st.group and 40 or 60)) -- таймер идет пока hp < 40

    -- hp меньше половины уже 2 секунды
    local needHeal = c.TimerStarted('needHeal') and c.TimerMore('needHeal', 1.5) and st.combatMode
    -- нужно бурстить
    local needBurst = st.targetHard and st.needMoreDamage --and dancingRuneWeaponReady

    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)

    local mana100 = c.UnitMana100('player')
    local useMana = st.attack or (mana100 > 50)

    -- автовключение если в группе и есть отметка что танк
    local roleTank, roleHeal, roleDD = UnitGroupRolesAssigned("player")
    reason, action, unit = 'Включаем баф для танкования', 'Праведное неистовство', 'player'
    if not isTank and roleTank and c.CanGcdSpell(action, unit, 5) then
        c.DoAction(reason, action, unit)
        return reason
    end


    reason, action, unit = 'Деф PVE с созвездия', 'Криво-пружинный механизм', 'player'
    if not st.pvp and needHeal and c.CanSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
        return reason
    end


    reason, action, unit = format('group: Хилка без каста на %s%% hp', c.Round(st.playerHP100)),
        (st.playerHP100 < 85) and 'Свет небес' or 'Вспышка Света', 'player'
    if not st.gcd and st.playerHP100 < 99 and c.CanGcdSpell(action, unit) and c.HasBuff('Криво-пружинный механизм') then
        c.DoAction(reason, action, unit)
        return reason
    end


    reason, action, unit = 'Очень мало хп в бою, нужен хил', 'Возложение рук', 'player'
    if st.combatMode and st.playerHP100 < 20 and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    -- reason, action, unit = 'Мало хп в бою, нужен деф', 'Божественная защита', 'player'
    -- if st.combatMode and needHeal and c.CanSpell(action, unit) then
    --     c.DoAction(reason, action, unit) -- мгновенка
    -- end

    reason = tryMouseTaunt()
    if reason then return reason end

    if not st.gcd and (st.start or (not st.attack and st.combatMode)) then
        reason, action, unit = 'Нужно обновить печать', 'Печать повиновения', 'player'
        if c.CanGcdSpell(action, unit, 10) and not c.bGetAura(unit, sealAuras) then
            c.DoAction(reason, action, unit)
            return reason
        end


        reason, action, unit = 'Нужно обновить стойку', isTank and 'Аура благочестия' or 'Аура воздаяния', 'player'
        if c.CanGcdSpell(action, unit) and c.IsSpellNotUsed(stanceAuras, 15) then
            -- Могу прожать стойку
            local stance = c.bGetAura(unit, stanceAuras, true)
            if stance then
                -- на мне есть моя стойка (аура палладина)
                -- но она не атуальна, чужой атуальной нет
                if stance == spell['Аура воина Света'] and not c.bHasAura(unit, spell[action]) then
                    c.DoAction(reason, action, unit) --  переключаемся в актуальную стойку
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

        reason, action, unit = "Нужно обновить благословение",
            isTank and 'Благословение неприкосновенности' or 'Благословение могущества', 'player'
        if useMana and not st.gcd and c.IsSpellNotUsed(blessingAuras, 15) and not c.HasMyBuff('Благословение', unit) then
            if not c.HasBuff(action, unit) and c.CanGcdSpell(action, unit) then
                c.DoAction(reason, action, unit)
                return reason
            end

            local blessing = getAvailableBlessing(unit)
            if blessing then
                action = blessing
                if c.CanGcdSpell(action, unit) then
                    c.DoAction(reason, action, unit)
                    return reason
                end
            end
        end
    end


    local dist = st.targetExists and c.bUnitDistance('player', 'target') or 999

    if isTank and st.group and not st.pvp then      -- только в группе
        -- Пуллтайм ротация
        local isPull = c.TimerLess('combatLock', 3) -- Первые 3 секунды боя

        if isPull then
            reason, action = 'пул', 'Освящение'
            if st.still and useMana and dist < 8 and c.CanGcdSpell(action) and (st.targetHard or c.GetEnemyCount(8, 'player') > 2) then
                c.DoAction(reason, action)
                return reason
            end
        elseif st.combatLock and c.IsSpellNotUsed(tauntSpells, 0.5) then
            reason, action, unit = 'Снимаем агро', 'Праведная защита', 'target'
            if c.CanSpell(action) then
                unit = c.FindValue(c.GetGroupUnits(), checkThreatUnit, action, 3) -- 3 red indicator
                if unit then
                    c.DoAction(reason, action, unit)                              -- мговенка
                    return reason                                                 -- не частим
                end
            end


            reason, action, unit = 'Таунт', 'Длань возмездия', 'target'
            if c.CanSpell(action) then
                -- мгновенка
                if c.DoActionWithGUID(reason, action, getTauntGUID(action, true)) then
                    return reason -- не частим
                end
            end

            --
            reason, action, unit = 'Понижаем агро', 'Длань спасения', 'target'
            if not st.gcd and c.CanSpell(action) then
                unit = c.FindValue(c.GetGroupUnits(), checkThreatUnit, action, 2, true) -- 2 orange indicator
                if unit then
                    c.DoAction(reason, action, unit)
                    return reason -- не частим
                end
            end

            reason, action, unit = 'Повышаем агро используя Сало', 'Щит мстителя', 'target'
            if useMana and not st.gcd and c.CanSpell(action) then
                if c.DoActionWithGUID(reason, action, getTauntGUID(action, false)) then
                    return reason -- не частим
                end
            end
        end
    end -- isTank

    reason, action, unit = 'Пробуем снять ', 'Очищение', 'player'
    if c.IsSpellFailedRecently(action) then
        c.TimerStart(action) -- считаем что использовали
    end
    if not st.gcd and useMana then
        local cleanseDebuff = c.HasDebuff(cleanseTypes, unit, 5) -- яд, болезнь и маг эффект
        reason = reason .. tostring(cleanseDebuff)
        if cleanseDebuff and c.CanGcdSpell(action, unit, 10) then
            c.DoAction(reason, action, unit)
            return reason
        end
    end

    reason = c.TryTarget(
        st.attack and st.look and 100 or 40,
        st.attack and 15 or (st.look and 30 or 0)
    )
    -- есть ли причина для остановки?
    if reason then return reason end


    -- Дальше считаем что у нас есть валидная цель

    reason, action, unit =
        'Нужно пустить лужу - ' ..
        (st.targetHard and 'страшно' or 'враги окружили'),
        'Освящение', 'target'
    if not st.gcd and st.still and useMana and dist < 8 and (st.targetHard or c.GetEnemyCount(8, 'player') > 2) and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Обновляем баф на ману', 'Святая клятва', 'player'
    if c.CanGcdSpell(action, unit) and not c.bHasAura(unit, spell[action]) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Обновляем поглощение', 'Священный щит', 'player'
    if c.CanGcdSpell(action, unit, 5) and not c.bHasAura(unit, spell[action]) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Нужен баф на блокирование', 'Щит небес', 'player'
    if not st.gcd and dist < 10 and useMana and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Урон агрилкой', 'Длань возмездия', 'target'
    if useMana and (isTank or not st.group) and not (UnitExists(unit .. '-target') and UnitIsUnit(unit .. '-target', 'player') == 1) and c.CanSpell(action, unit) then
        c.DoAction(reason, action, unit) -- мгновенка
    end

    reason, action, unit = 'Экзорцизм без каста', 'Экзорцизм', 'target'
    if useMana and st.playerHP100 >= 99 and c.CanGcdSpell(action, unit) and c.HasBuff('Криво-пружинный механизм') then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Добивание', 'Молот гнева', 'target'
    if useMana and not st.gcd and c.CanSpell(action) then
        if c.DoActionWithGUID(reason, action, c.bFindExecuteTarget(30, 19.9, 20)) then
            return reason -- не частим
        end
    end

    reason, action, unit = 'Сало на троих', 'Щит мстителя', 'target'
    if useMana and c.CanGcdSpell(action) then
        --CanAttack|IsInCombat|IsCasting|NotTappedByOther|InLoS
        if c.DoActionWithGUID(reason, action, c.bFindUnit(30, 103, 20)) then
            return reason -- не частим
        end
    end

    reason, action, unit = 'Молот в 3 цели', 'Молот праведника', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Вершим правосудие!', mana100 < 80 and 'Правосудие мудрости' or 'Правосудие света', 'target'
    if c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    local creatureType = UnitCreatureType('target')
    reason, action, unit = creatureType, 'Гнев небес', 'target'
    if not st.gcd and useMana and dist < 10 and c.GetEnemyCount(10, 'player') > 1 and (creatureType == 'Нежить' or creatureType == 'Демон') and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Заполнитель', 'Щит праведности', 'target'
    if useMana and c.CanGcdSpell(action, unit) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Прям совсем нечего нажать, кидаем Сало', 'Щит мстителя', 'target'
    if useMana and c.CanGcdSpell(action, unit, 3) then
        c.DoAction(reason, action, unit)
        return reason -- не частим
    end

    --if st.gcd then return '#gcd' end
    --if not useMana then return '#mana' end
    return '#none'
end

c.Update(function()
    if not isLoaded then return end
    local stopReason = c.GetStopReason()
    if stopReason then
        -- только для палладина, врубаем коня на маунте
        if stopReason == c.stopReasonMount and not UnitOnTaxi("player") then
            local reason, action, unit = 'Врубаем ускорение на транспорте', 'Аура воина Света', 'player'
            if not c.bHasAura(unit, spell[action]) and c.CanGcdSpell(action, unit) then
                c.DoAction(reason, action, unit)
                stopReason = reason
            end
        end
        c.LogWhatHappend(stopReason)
        return
    end
    c.LogWhatHappend(updateProto())
end)
