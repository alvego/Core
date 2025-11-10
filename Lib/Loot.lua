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
local fish = {}
fish.spell = 'Рыбная ловля'
fish.bobber = nil
fish.delay = 0

c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        local spellName = select(2, ...)
        if subEvent:match('SPELL_CREATE') and sourceGUID == st.playerGUID and spellName == fish.spell then
            fish.bobber = c.GetObjectIdByGUID(destGUID)
            c.Log('Видим поплавок')
            c.TimerStart(fish.spell)
            fish.delay = 0.5 + math_random() * 2.5 -- [0 .. 3]
        end
    end
)
-------------------------------------------------------------------------------

local function lootUnit(unit)
    c.Message(c.UnitInfo(unit), 'Лутаем')
    c.UnitClick(unit, true)
    c.TimerStart(lootTimer)
    tinsert(lootList, unit)
end

local function waitForLoot()
    local isOpenLoot = LootFrame:IsVisible()
    c.TimerToggle('LootFrame', isOpenLoot) -- таймер идет пока открыт LootFrame
    if isOpenLoot then
        -- LootFrame висит уже 1.5 секунды
        local IsLootLag = c.TimerStarted('needHeal') and c.TimerMore('needHeal', 1.5)
        -- если окно лута подвисло
        if IsLootLag then
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

c.AttachBeforeUpdate(function()
    if c.Paused() then return end
    if st.group and (GetLootMethod() ~= 'freeforall') then return end
    if c.GetBagsFreeSlots() < 1 then return end
    if GetCVar('autoLootDefault') ~= '1' then return end
    if waitForLoot() then return end
    if c.TimerLess('Loot', 0.5) then return end
    if c.TimerStarted(lootTimer) and c.TimerMore(lootTimer, 5) then wipe(lootList) end
    if c.TimerStarted(skinTimer) and c.TimerMore(skinTimer, 5) then wipe(skinList) end
    if st.gcd or st.mounted or st.combatMode then return end

    if IsEquippedItemType('Удочка') and IsUsableSpell(fish.spell) and c.TimerLess(fish.spell, 5) then
        if not st.still then return end

        if not st.playerCasting then
            if c.CanUseGcdSpell(fish.spell, nil, fish.delay) then
                c.DoAction('Забрасываем', fish.spell)
                c.SkipNextUpdate()
                c.TimerStart(fish.spell)
            end
            return
        end

        if st.playerCasting == fish.spell and fish.bobber then
            c.TimerStart(fish.spell)
            local ptr = c.UnitPtr(fish.bobber)
            if c.ReadByte(ptr, 188) ~= 1 then return end
            lootUnit(fish.bobber)
            fish.bobber = nil
        end
        return
    end

    if st.playerCasting then return end
    -- ищем кого можно лутануть
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if corpse then
        lootUnit(corpse)
        c.TimerStart('Loot')
        return
    end

    if not st.still then return end

    local skinSpell = 'Снятие шкур'
    local allowSkin = IsUsableSpell(skinSpell)
    if allowSkin then
        -- ищем кого можно освежевать
        corpse = c.FindValue(c.GetUnits(), checkCorpseForSkin)
        if corpse then
            c.DoAction('Свежуем', skinSpell, corpse)
            tinsert(skinList, corpse)
            c.TimerStart(skinTimer)
            c.TimerStart('Loot', 1.5)
            return
        end
    end

    if not c.canMove then return end
    if st.look then return end
    -- ищем ближайший полезный труп
    corpse = getNearCorpse(allowSkin)
    if corpse and c.PlayerMove(corpse, maxDist) then
        c.TimerStart('Loot', 3)
    end
end)
-------------------------------------------------------------------------------
