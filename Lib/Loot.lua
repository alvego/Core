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
local IsEquippedItemType = IsEquippedItemType
local math_random = math.random
local CombatLogClearEntries = CombatLogClearEntries
-------------------------------------------------------------------------------
local canLoot = c.GetCachedFunc(function(unit)
    local ptr = c.UnitPtr(unit)
    return c.ReadByte(ptr, 168) ~= 0
end)

local lootList = {}
local lootTimer = 'lootTimer'
local lootDist = 5

local function checkCorpseForLoot(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > lootDist then return end -- so far
    if not canLoot(unit) then return end                         -- can't loot
    if tContains(lootList, unit) then return end
    return unit
end
-------------------------------------------------------------------------------
local canSkin = c.GetCachedFunc(function(unit)
    local creatureType = UnitCreatureType(unit)
    return creatureType == 'Животное' and not canLoot(unit)
end)

local skinList = {}
local skinTimer = 'skinTimer';
local skinDist = 8

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
local function checkCorpse(unit, allowSkin)
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

local function getNearCorpse(allowSkin)
    _corpse, _dist = nil, 0
    c.FindValue(c.GetUnits(), checkCorpse, allowSkin)
    return _corpse
end
-------------------------------------------------------------------------------
local function lootUnit(unit, name)
    if tContains(lootList, unit) then return end
    c.Message(name or c.UnitInfo(unit), 'Лутаем')
    c.UnitClick(unit, true)
    c.TimerStart(lootTimer)
    tinsert(lootList, unit)
end

local function waitForLoot()
    local isOpenLoot = LootFrame:IsVisible()
    c.TimerToggle('LootFrame', isOpenLoot) -- таймер идет пока открыт LootFrame
    if isOpenLoot then
        -- LootFrame висит
        local IsLootLag = c.TimerStarted('LootFrame') and c.TimerMore('LootFrame', 0.5)
        -- если окно лута подвисло
        if IsLootLag then
            c.Log('#подвисло окно лута')
            for i = 1, GetNumLootItems() do
                if not select(5, GetLootSlotInfo(i)) then LootSlot(i) end
            end
            CloseLoot()
        end
        return true -- ждем закрытия лута
    end
    return false    -- лут нет, можно что-то делать
end
-------------------------------------------------------------------------------
local fish = {}
fish.run = false
fish.spell = 'Рыбная ловля'
fish.icon = select(3, GetSpellInfo(fish.spell))
fish.guid = nil
fish.bobber = nil
fish.delay = 1

c.AttachActionHook(fish.spell, function()
    fish.run = true
end)

c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        if c.Paused() then return end
        local spellName = select(2, ...)
        if subEvent:match('SPELL_CREATE') and sourceGUID == st.playerGUID and spellName == fish.spell then
            fish.guid = destGUID
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
            fish.run = false
        end
        c.TimerReset(fish.spell)
        return false
    end

    c.SkipNextUpdate()

    if not st.playerCasting then
        if c.CanUseGcdSpell(fish.spell, nil, fish.delay) then
            CombatLogClearEntries()
            c.DoAction('Забрасываем', fish.spell)
            fish.run = true
            fish.delay = 0.5 + math_random() * 2.5 -- [0 .. 3]
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
        --c.CastStop()
    end

    if fish.bobber and not tContains(lootList, fish.bobber) then
        c.MessageLog('#ждем клева...', fish.spell, fish.icon)
        local ptr = c.UnitPtr(fish.bobber)
        if c.ReadByte(ptr, 188) ~= 1 then return end
        c.MessageLog('#подсекаем', fish.spell, fish.icon)
        lootUnit(fish.bobber, UnitName(fish.bobber))
        c.CastStop()
        fish.bobber = nil
        fish.run = false
    end
    return true
end


-------------------------------------------------------------------------------
local function waitForCorpseLoot()
    -- ищем кого можно лутануть
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if not corpse then return false end
    lootUnit(corpse)
    return true
end
-------------------------------------------------------------------------------
local function waitForCorpseSkin()
    if not st.still then return false end
    local skinSpell = 'Снятие шкур'
    local allowSkin = IsUsableSpell(skinSpell)
    if not allowSkin then return false end
    if c.TimerLess('Skin', 1) then return false end
    -- ищем кого можно освежевать
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForSkin)
    if not corpse then return false end
    c.DoAction('Свежуем', skinSpell, corpse)
    tinsert(skinList, corpse)
    c.TimerStart(skinTimer)
    c.TimerStart('Skin')
    return true
end
-------------------------------------------------------------------------------
local function waitForFindCorpse()
    if not c.canMove() or st.move then return false end
    if st.look then return false end
    if c.TimerLess('Move', 0.5) then return false end
    -- ищем ближайший полезный труп
    local corpse = getNearCorpse(IsUsableSpell('Снятие шкур'))
    if corpse and c.PlayerMove(corpse, maxDist) then
        c.TimerStart('Move')
    end
end

-------------------------------------------------------------------------------

c.AttachBeforeUpdate(function()
    if c.Paused() or not c.canLoot() then return end
    --if st.group and (GetLootMethod() ~= 'freeforall') then return end
    if c.GetBagsFreeSlots() < 1 then return end
    if GetCVar('autoLootDefault') ~= '1' then return end
    if waitForLoot() then return end

    if c.TimerStarted(lootTimer) and c.TimerMore(lootTimer, 0.3) then wipe(lootList) end
    if c.TimerStarted(skinTimer) and c.TimerMore(skinTimer, 2) then wipe(skinList) end

    if st.mounted then return end

    if waitForFishing() then return end

    if st.gcd or st.playerCasting then return end

    if waitForCorpseLoot() then return end

    if st.combatMode then return end

    if waitForCorpseSkin() then return end
    if waitForFindCorpse() then return end
end)
-------------------------------------------------------------------------------
c.AttachActionHook('loot', function()
    c.EchoBool('Loot', c.canLoot(not c.canLoot()))
end)
