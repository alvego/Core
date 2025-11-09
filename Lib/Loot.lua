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

local function checkCorpseForLoot(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > 5 then return end -- so far
    if not canLoot(unit) then return end                  -- can't loot
    return unit
end

local canSkin = c.GetCachedFunc(function(unit)
    local creatureType = UnitCreatureType(unit)
    return creatureType == 'Животное' and not canLoot(unit)
end)

local skinList = {}
local skinTimer = 'skinTimer';

local function checkCorpseForSkin(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > 8 then return end -- so far
    if not canSkin(unit) then return end                  -- can't skin
    if tContains(skinList, unit) then return end
    return unit
end


local _corpse, _dist = nil, 0
local function checkCorpse(unit, allowSkin)
    if not UnitExists(unit) then return end
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if tContains(skinList, unit) then return end
    if not (canLoot(unit) or (allowSkin and canSkin(unit))) then return end
    if not c.UnitInLOS(unit) then return end
    local dist = c.UnitDistance('player', unit)
    if dist < 5 or dist > 40 then return end
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
local bobberUID = nil
local isBobbingTimer = 'isBobbing'
local fishSpell = 'Рыбная ловля'
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        local spellName = select(2, ...)
        if subEvent:match('SPELL_CREATE') and sourceGUID == c.state.playerGUID and spellName == fishSpell then
            bobberUID = c.GetUnitIdByGUID(destGUID)
            c.TimerStop(isBobbingTimer)
            c.Log('Видим поплавок')
        end
    end
)
-------------------------------------------------------------------------------

c.AttachBeforeUpdate(function()
    if c.Paused() then return end
    if c.TimerLess('Loot', 0.5) then return end
    if c.TimerStarted(skinTimer) and c.TimerMore(skinTimer, 5) then wipe(skinList) end
    if st.gcd or st.mounted or st.combatMode then return end
    if st.group and (GetLootMethod() ~= 'freeforall') then return end
    if c.GetBagsFreeSlots() < 1 then return end
    if GetCVar('autoLootDefault') ~= '1' then return end
    -- если окно лута подвисло
    if LootFrame:IsVisible() then
        for i = 1, GetNumLootItems() do
            if not select(5, GetLootSlotInfo(i)) then LootSlot(i) end
        end
        CloseLoot()
        return
    end

    if IsEquippedItemType('Удочка') and IsUsableSpell(fishSpell) and c.TimerLess(fishSpell, 15) then
        if not st.still then return end

        if not st.playerCasting then
            local salt = 0.5 + math_random() * 2.5 -- [0 .. 3]
            if c.CanUseGcdSpell(fishSpell, nil, salt) then
                c.DoAction('Забрасываем', fishSpell)
                c.TimerStart(fishSpell)
            end
            return
        end

        if st.playerCasting == fishSpell and bobberUID and UnitExists(bobberUID) then
            if not c.TimerStarted(isBobbingTimer) then
                local ptr = c.UnitPtr(bobberUID)
                if c.ReadByte(ptr, 188) == 1 then
                    c.Log('Клюнуло')
                    c.TimerStart(isBobbingTimer)
                end
            end

            if c.TimerStarted(isBobbingTimer) then
                local delay = 0.5 + math_random() * 0.5 -- [0 .. 1]
                if c.TimerMore(isBobbingTimer, delay) then
                    c.Log('Подсекаем')
                    c.UnitClick(bobberUID, true)
                    bobberUID = nil
                    c.TimerStop(isBobbingTimer)
                    c.TimerStart(fishSpell)
                end
            end

            return
        end

        return
    end

    if st.playerCasting then return end
    -- ищем кого можно лутануть
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if corpse then
        c.Message(c.UnitInfo(corpse), 'Лутаем')
        c.UnitClick(corpse, true)
        c.SkipNextUpdate()
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
            c.SkipNextUpdate()
            c.TimerStart('Loot', 1.5)
            return
        end
    end

    if not c.canMove then return end
    if st.look then return end
    -- ищем ближайший полезный труп
    corpse = getNearCorpse(allowSkin)
    if corpse and c.PlayerMove(corpse, 40) then
        c.TimerStart('Loot', 3)
    end
end)
-------------------------------------------------------------------------------
