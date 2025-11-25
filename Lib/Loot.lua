-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local GetLootMethod = GetLootMethod
local GetCVar = GetCVar
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitCreatureType = UnitCreatureType
local LootFrame = LootFrame
local CloseLoot = CloseLoot
local GetLootSlotInfo = GetLootSlotInfo
local GetNumLootItems = GetNumLootItems
local LootSlot = LootSlot
local tinsert = tinsert
local wipe = wipe
local tContains = tContains
local math_random = math.random
local CombatLogClearEntries = CombatLogClearEntries
-------------------------------------------------------------------------------
local lootList = {}
local lootTimer = 'lootTimer'
local lootDist = 5
local lootFilterList = {}
-------------------------------------------------------------------------------
local skinList = {}
local skinTimer = 'skinTimer';
local skinDist = 8
local skinFilterList = {}
local skinTarget = nil
-------------------------------------------------------------------------------
local function resetTimers()
    if c.TimerStarted(lootTimer) then
        if c.TimerMore(lootTimer, 0.75) then wipe(lootList) end
        if c.TimerMore(lootTimer, 300) then wipe(lootFilterList) end
    end
    if c.TimerStarted(skinTimer) then
        if c.TimerMore(skinTimer, 2.5) then wipe(skinList) end
        if c.TimerMore(skinTimer, 300) then wipe(skinFilterList) end
    end
end
-------------------------------------------------------------------------------
local allowSkin = false
local skinSpell = 'Снятие шкур'
c.AttachEvent('PLAYER_ENTERING_WORLD', function()
    allowSkin = IsUsableSpell(skinSpell)
end)
-------------------------------------------------------------------------------
local canLoot = c.GetCachedFunc(function(unit)
    local ptr = c.UnitPtr(unit)
    if c.ReadByte(ptr, 168) == 0 then return false end
    if (lootFilterList[unit] or 0) >= 3 then return false end
    return true
end)
-------------------------------------------------------------------------------
local function checkCorpseForLoot(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > lootDist then return end -- so far
    if not canLoot(unit) then return end                         -- can't loot
    if tContains(lootList, unit) then return end
    if tContains(skinList, unit) then return end
    return unit
end
-------------------------------------------------------------------------------
-- c.TestLoot = function()
--     local unit = c.GetUnitID('target')
--     if not UnitExists(unit) then return '!exists' end
--     if not UnitIsDead(unit) then return '!dead' end
--     if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return '!tapped' end
--     if UnitIsPlayer(unit) then return 'player' end
--     if c.UnitDistance('player', unit) > lootDist then return 'dist > 5' end -- so far

--     local ptr = c.UnitPtr(unit)
--     if c.ReadByte(ptr, 168) == 0 then return '!canLoot' end
--     if (lootFilterList[unit] or 0) >= 3 then return 'lootFilterList ' .. lootFilterList[unit] end
--     -- can't loot
--     if tContains(lootList, unit) then return 'in lootList' end
--     if tContains(skinList, unit) then return 'in skinList' end
--     return 'ok'
-- end

-------------------------------------------------------------------------------

local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if subEvent == 'SPELL_CAST_FAILED' and sourceGUID == st.playerGUID then
        local message = select(4, ...)
        if message == 'С этого существа нельзя снять шкуру.' then
            if skinTarget then
                local name = UnitName(skinTarget)
                if name then
                    c.Log('#skin ignore error ', name)
                    skinFilterList[name] = true
                end
            end
        end
    end
end
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)
-------------------------------------------------------------------------------

local ignoreSkinTypes = {
    'Гуманоид',
    'Существо',
    'Элементаль',
    'Великан',
    'Механизм',
    'Газовое облако',
    'Тотем',
    'Спутник',
    'Не указано' }
local canSkin = c.GetCachedFunc(function(unit)
    local name = UnitName(unit)
    if skinFilterList[name] then return false end
    local creatureType = UnitCreatureType(unit)
    if tContains(ignoreSkinTypes, creatureType) then return false end
    if canLoot(unit) then return false end
    return true
end)
-------------------------------------------------------------------------------
local function checkCorpseForSkin(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > skinDist then return end -- so far
    if not canSkin(unit) then return end                         -- can't skin
    if tContains(skinList, unit) then return end
    return unit
end

-------------------------------------------------------------------------------
local maxDist = 40
local _corpse, _dist = nil, 0
local function checkCorpse(unit)
    if not UnitExists(unit) then return end
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    local loot = not (
        tContains(lootList, unit) or (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit))
    ) and canLoot(unit)
    local skin = allowSkin and not (loot or tContains(skinList, unit)) and canSkin(unit)
    if not (loot or skin) then return end
    if not c.UnitInLOS(unit) then return end
    local dist = c.UnitDistance('player', unit)
    if dist < (loot and lootDist or skinDist) or dist > maxDist then return end
    if not _corpse or not _dist or dist < _dist then
        _corpse = unit
        _dist = dist
    end
end
-------------------------------------------------------------------------------
local function getNearCorpse()
    _corpse, _dist = nil, 0
    c.FindValue(c.GetUnits(), checkCorpse)
    return _corpse
end
-------------------------------------------------------------------------------
local lootIcon = 'Interface\\Icons\\Ability_Racial_PackHobgoblin'
local function lootUnit(unit, name)
    if tContains(lootList, unit) then return end

    --local uid = c.GetUnitID('target')

    c.Message(name or c.UnitInfo(unit), 'Лутаем', lootIcon)
    c.UnitClick(unit, true)
    c.TimerStart(lootTimer)
    tinsert(lootList, unit)
    -- попытки лута
    lootFilterList[unit] = (lootFilterList[unit] or 0) + 1
end
-------------------------------------------------------------------------------
local function waitForLoot()
    -- core лут отключен, стоп
    if not c.flags.loot then return true end
    -- нет свободного места в сумках, стоп
    if c.GetBagsFreeSlots() < 1 then return true end
    -- wow автолут отключен, дальше не идем
    if GetCVar('autoLootDefault') ~= '1' then return true end
    -- открыт лут
    local isOpenLoot = LootFrame:IsVisible()
    c.TimerToggle('LootFrame', isOpenLoot) -- таймер идет пока открыт LootFrame

    -- иначе может просто подвиснуть лут, бывает при клике одновременно с interact
    if isOpenLoot then
        if c.AutoPopup('станет персональным, если вы его поднимете.', 'ОК') then return true end
        -- если в группе и не freeforall, может быть окно item roll, так что ждем
        if st.group and (GetLootMethod() ~= 'freeforall') then return true end
        -- LootFrame висит
        local IsLootLag = c.TimerStarted('LootFrame') and c.TimerMore('LootFrame', 0.5)
        -- если окно лута подвисло
        if IsLootLag then
            c.Log('#подвисло окно лута')
            for i = 1, GetNumLootItems() do
                -- тогда лутаем вручную
                if not select(5, GetLootSlotInfo(i)) then LootSlot(i) end
            end
            CloseLoot() -- закрываем фрейм лута
        end
        return true     -- ждем одну итерацию, для закрытия лута
    end
    return false        -- лута нет, можно что-то делать
end
-------------------------------------------------------------------------------
local fish = {}
fish.run = false
fish.spell = 'Рыбная ловля'
fish.icon = select(3, GetSpellInfo(fish.spell))
fish.guid = nil
fish.bobber = nil
fish.delay = 1
-------------------------------------------------------------------------------
c.AttachActionHook(fish.spell, function()
    fish.run = true
end)
-------------------------------------------------------------------------------
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        local spellName = select(2, ...)
        if subEvent:match('SPELL_CREATE') and sourceGUID == st.playerGUID and spellName == fish.spell then
            fish.guid = destGUID
            fish.run = true
            c.MessageLog('#забросили удочку', fish.spell, fish.icon)
        end
    end
)
-------------------------------------------------------------------------------
local function waitForFishing()
    if not IsUsableSpell(fish.spell) or
        not c.TimerLess(fish.spell, 5) or
        st.playerCasting and st.playerCasting ~= fish.spell or
        not st.still then
        if fish.run then
            c.MessageLog('#хватит рыбачить', fish.spell, fish.icon)
            fish.guid = nil
            fish.bobber = nil
            fish.run = false
        end
        c.TimerReset(fish.spell)
        return false
    end

    c.SkipNextUpdate()

    if not st.playerCasting then
        if c.CanGcdSpell(fish.spell, nil, fish.delay) then
            fish.run = false
            fish.bobber = nil
            fish.guid = nil
            if not c.Paused() then
                CombatLogClearEntries()
                c.DoSpell('Забрасываем', fish.spell)
                fish.run = true
                fish.delay = 0.5 + math_random() * 2.5 -- [0.5 .. 3]
            end
        end
        return true
    end

    c.TimerStart(fish.spell)

    if not fish.bobber and fish.guid then
        fish.bobber = c.GetObjectIdByGUID(fish.guid)
        if fish.bobber then
            c.MessageLog('#нашли поплавок', fish.spell, fish.icon)

            -- local ptr = c.UnitPtr(fish.bobber)
            -- for i = 0, 1200 do
            --     local guid = c.ReadUlong(ptr, i)
            --     if guid == st.playerGUID then c.Log('#', i) end
            -- end
            -- local guid = c.ReadUlong(ptr, 0x18)
            -- c.Log('Created by me', guid == st.playerGUID, 0 + guid, 0 + st.playerGUID)

            -- c.Log('UnitPlayerControlled', UnitPlayerControlled(fish.bobber))
            -- c.Log('UnitIsTapped', UnitIsTapped(fish.bobber))
            -- c.Log('UnitIsTappedByPlayer', UnitIsTappedByPlayer(fish.bobber))
            fish.guid = nil
        end
    end

    if fish.run and not fish.bobber and not fish.guid then
        c.MessageLog('#завис combat log', fish.spell, fish.icon)
        --c.Command('/stopcasting')
    end

    if fish.bobber and not tContains(lootList, fish.bobber) then
        c.MessageLog('#ждем клева...', fish.spell, fish.icon)
        local ptr = c.UnitPtr(fish.bobber)
        if c.ReadByte(ptr, 188) ~= 1 then return end
        c.MessageLog('#подсекаем', fish.spell, fish.icon)
        lootUnit(fish.bobber, UnitName(fish.bobber))
        c.Command('/stopcasting')
        fish.bobber = nil
        fish.guid = nil
        fish.run = false
    end
    return true
end


-------------------------------------------------------------------------------
local function waitForCorpseLoot()
    if c.TimerLess('waitForCorpseLoot', 0.4) then return true end
    -- ищем кого можно лутануть
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if not corpse then return false end
    lootUnit(corpse)
    c.TimerStart('waitForCorpseLoot')
    return true
end
-------------------------------------------------------------------------------
local function waitForCorpseSkin()
    if c.TimerLess('waitForCorpseSkin', 0.8) then return true end
    if not st.still then return false end
    if not allowSkin then return false end
    -- ищем кого можно освежевать
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForSkin)
    if not corpse then return false end
    if not c.IsSpellInRange(skinSpell, corpse) then
        local name = UnitName(corpse)
        if name then
            c.Log('#skin ignore by !can ', name)
            skinFilterList[name] = true
        end
        return true
    end
    c.DoSpell('Свежуем', skinSpell, corpse)
    tinsert(skinList, corpse)
    skinTarget = corpse
    c.TimerStart(skinTimer)
    c.TimerStart('waitForCorpseSkin')
    return true
end
-------------------------------------------------------------------------------
local lastCorpse = nil
local function waitForFindCorpse()
    if c.TimerLess('waitForFindCorpse', 0.5) then return true end
    if not c.flags.move or st.move then return false end
    if st.look then return false end
    if lastCorpse and UnitExists(lastCorpse) and (checkCorpseForLoot(lastCorpse) or checkCorpseForSkin(lastCorpse)) then return false end
    -- ищем ближайший полезный труп
    local corpse = getNearCorpse()
    if corpse and c.MoveToUnit(corpse, maxDist) then
        c.Message('идем к ' .. c.UnitInfo(corpse), 'Loot', lootIcon)
        c.TimerStart('waitForFindCorpse')
        lastCorpse = corpse
    end
end

-------------------------------------------------------------------------------

c.AttachBeforeUpdate(function()
    if waitForLoot() then return end
    resetTimers()
    if st.mounted then return end
    if st.combatMode then return end
    if waitForFishing() then return end
    if c.Paused() then return end
    if st.gcd or st.playerCasting then return end
    if waitForCorpseLoot() then return end
    if waitForCorpseSkin() then return end
    if waitForFindCorpse() then return end
end)

-------------------------------------------------------------------------------
