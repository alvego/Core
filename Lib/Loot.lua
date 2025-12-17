local c                     = Core
local st                    = c.state

local GetLootMethod         = GetLootMethod
local GetCVar               = GetCVar
local UnitExists            = UnitExists
local UnitIsDeadOrGhost     = UnitIsDeadOrGhost
local UnitIsPlayer          = UnitIsPlayer
local UnitIsTapped          = UnitIsTapped
local UnitIsTappedByPlayer  = UnitIsTappedByPlayer
local GetSpellInfo          = GetSpellInfo
local GetSpellTexture       = GetSpellTexture
local IsUsableSpell         = IsUsableSpell
local GetSpellLink          = GetSpellLink
local LootFrame             = LootFrame
local CloseLoot             = CloseLoot
local GetLootSlotInfo       = GetLootSlotInfo
local GetNumLootItems       = GetNumLootItems
local LootSlot              = LootSlot
local GetLootSlotLink       = GetLootSlotLink
local wipe                  = wipe
local type                  = type
local math_random           = math.random
local CombatLogClearEntries = CombatLogClearEntries
local UIParent              = UIParent
local WrapTextInColorCode   = WrapTextInColorCode

local lootList              = {}
local lootTimer             = 'lootTimer'
local lootDist              = 5
local lootFilterList        = {}
local lootTitle             = 'Лутаем'
local lootIcon              = [[Interface\Icons\Ability_Racial_PackHobgoblin]]
local lootTarget            = nil

local skinList              = {}
local skinTimer             = 'skinTimer';
local skinDist              = 8
local skinFilterList        = {}
local allowSkin             = false
local skinTarget            = nil
local skinSpell             = 'Снятие шкур'
local skinIcon              = nil

local maxTryCount           = 2

c.Event('PLAYER_ENTERING_WORLD', function()
    allowSkin = IsUsableSpell(skinSpell)
    if allowSkin then
        skinIcon = GetSpellTexture(skinSpell)
    end
end)


local function isLooting()
    -- нет цели лута, не лутаем
    if not lootTarget then return false end
    -- есть цель и время ожидания не истекло, лутаем
    if c.TimerLess(lootTimer, 0.5) then return true end
    -- время ожидания окна лута истекло, сбрасываем цель, не луитаем
    -- lootList[lootTarget] = true -- добавлем в список уже лутаных целей, чтоб не лутать повторно
    c.MessageLog(format('#%s: %s', WrapTextInColorCode('неудача', 'FF773A3A'), c.UnitInfo(lootTarget)), lootTitle,
        lootIcon)
    lootTarget = nil
    return false
end


c.Event('LOOT_OPENED', function()
    if lootTarget then
        -- успешло полутали цель, у нее есть лут
        lootList[lootTarget] = true -- добавлем в список уже лутаных целей, чтоб не лутать повторно

        local info =
            c.MessageLog(
                format('#%s: %s', WrapTextInColorCode('успех', 'FF3F773A'),
                    IsFishingLoot() and UnitName(lootTarget) or c.UnitInfo(lootTarget)), lootTitle,
                lootIcon)
        -- сбрасываем цель


        for i = 1, GetNumLootItems() do
            local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
            local link = GetLootSlotLink(i) or item
            local count = (type(quantity) == 'number' and quantity > 1) and
                WrapTextInColorCode('x' .. quantity, 'ff00ff00') or ''
            c.MessageLog('#добыча ' .. link .. count, lootTitle, texture)
        end

        lootTarget = nil
    end
end)

local function isSkinning()
    -- нет цели, свободны
    if not skinTarget then return false end
    -- есть цель и время ожидания не истекло, в процессе
    if c.TimerLess(skinTimer, 2) then return true end
    -- время ожидания спела истекло, сбрасываем цель, свободны
    c.MessageLog(format('#%s: %s', WrapTextInColorCode('неудача по времени', 'FF773A3A'), c.UnitInfo(skinTarget)),
        skinSpell,
        skinIcon)
    skinTarget = nil
    return false
end

local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if not skinTarget then return end
    if source ~= 'player' then return end
    if spellName ~= skinSpell then return end
    if event == 'UNIT_SPELLCAST_SUCCEEDED' then
        c.MessageLog(format('#%s: %s', WrapTextInColorCode('успех', 'FF3F773A'), c.UnitInfo(skinTarget)), skinSpell,
            skinIcon)
        lootTarget = skinTarget
        c.TimerStart(lootTimer)
        skinList[skinTarget] = true -- добавлем в список уже освежеваных целей, чтоб не снимать повторно
    else
        c.MessageLog(format('#%s: %s', WrapTextInColorCode('неудача', 'FF773A3A'), c.UnitInfo(skinTarget)),
            skinSpell,
            skinIcon)
        skinFilterList[skinTarget] = (skinFilterList[skinTarget] or 0) + 1
        if skinFilterList[skinTarget] == maxTryCount then
            c.MessageLog('#в игнор (ошибка): ' .. c.UnitInfo(skinTarget), skinSpell, skinIcon)
            skinList[skinTarget] = true
        end
    end

    skinTarget = nil
end
c.Event('UNIT_SPELLCAST_FAILED', onEvent)
c.Event('UNIT_SPELLCAST_SUCCEEDED', onEvent)

local function resetTimers()
    if c.TimerStarted(lootTimer) and c.TimerMore(lootTimer, 300) then
        wipe(lootList)
        wipe(lootFilterList)
    end
    if c.TimerStarted(skinTimer) and c.TimerMore(skinTimer, 300) then
        wipe(skinList)
        wipe(skinFilterList)
    end
end

local hasSkinTooltip = c.GetCachedFunc(function(unit)
    local tooltipName = 'SkinCheckTooltip'
    local tooltip = _G[tooltipName] or
        CreateFrame('GameTooltip', tooltipName, UIParent, 'GameTooltipTemplate')
    -- Проверка подсказки: наличие текста 'Можно снять шкуру' и что он не красный (уровень профессии достаточен)
    tooltip:ClearLines()
    tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
    tooltip:SetUnit(unit)
    local numLines = tooltip:NumLines()
    for i = 1, numLines do
        local textName = tooltipName .. 'TextLeft' .. i
        local tipText = _G[textName]:GetText()
        if tipText and string.find(tipText, 'Можно снять шкуру') then
            local r, g, b = _G[textName]:GetTextColor()
            -- Красный текст: g ~0.1-0.2; белый/желтый/зеленый: g > 0.5
            -- Возвращаем true, если НЕ красный (уровень профессии ок)
            return g > 0.5
        end
    end
    return false
end)

local canLoot = c.GetCachedFunc(function(unit)
    if lootList[unit] then return false end
    if skinList[unit] then return false end
    if (lootFilterList[unit] or 0) >= maxTryCount then return false end
    -- если далеко
    if c.UnitDistance('player', unit) > lootDist then
        -- проверим, стоит ли идти?
        -- иногда проверка дает ложное срабатывание
        -- если говорит что можнно лутануть, то 100%, что это верно
        -- если говорит что нельзя лутануть, то 3%, что это верно
        -- поэтому используем только, чтоб проверить, стоит ли идти
        if c.ReadByte(c.UnitPtr(unit), 168) == 0 then return false end
    end
    if hasSkinTooltip(unit) then return false end
    return true
end)

local function checkCorpseForLoot(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDeadOrGhost(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > lootDist then return end -- so far
    if not canLoot(unit) then return end                         -- can't loot
    return unit
end

local canSkin = c.GetCachedFunc(function(unit)
    if skinList[unit] then return false end
    if (skinFilterList[unit] or 0) >= maxTryCount then return false end
    if not hasSkinTooltip(unit) then return false end
    return true
end)



local function checkCorpseForSkin(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDeadOrGhost(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > skinDist then return end -- so far
    if not canSkin(unit) then return end                         -- can't skin
    if skinList[unit] then return end
    -- на нужном расстоянии, но сам спелл говорит обратное
    if not c.IsSpellInRange(skinSpell, unit) then
        skinFilterList[unit] = (skinFilterList[unit] or 0) + 1
        if skinFilterList[unit] == maxTryCount then
            c.MessageLog('#в игнор (спелл): ' .. c.UnitInfo(unit), skinSpell, skinIcon)
            skinList[unit] = true
        end
        return
    end
    return unit
end


local maxDist = 40
local _corpse, _dist = nil, 0
local function checkCorpse(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDeadOrGhost(unit) then return end
    if UnitIsPlayer(unit) then return end
    local loot = not (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) and canLoot(unit)
    local skin = allowSkin and not loot and canSkin(unit)
    if not (loot or skin) then return end
    if not c.UnitInLOS(unit) then return end
    local dist = c.UnitDistance('player', unit)
    if dist < (loot and lootDist or skinDist) or dist > maxDist then return end
    if not _corpse or not _dist or dist < _dist then
        _corpse = unit
        _dist = dist
    end
end

local function getNearCorpse()
    _corpse, _dist = nil, 0
    c.FindValue(c.GetUnits(), checkCorpse)
    return _corpse
end

local function lootUnit(unit, name)
    -- и так уже лутаем кого-то
    -- if isLooting() then return end
    -- -- уже полутан
    -- if lootList[unit] then return end
    c.Message(name or c.UnitInfo(unit), lootTitle, lootIcon)
    c.UnitClick(unit, true)
    lootTarget = unit
    c.TimerStart(lootTimer)
    -- попытки лута
    lootFilterList[unit] = (lootFilterList[unit] or 0) + 1
    if lootFilterList[unit] == maxTryCount then
        c.MessageLog('#в игнор (попытки):' .. (name or c.UnitInfo(unit)), lootTitle, lootIcon)
        lootList[unit] = true
    end
end

local function waitForLoot()
    -- core лут отключен, стоп
    if not c.flags.loot then return true end
    -- нет свободного места в сумках, стоп
    if c.GetBagsFreeSlots() < 1 then return true end
    -- wow автолут отключен, дальше не идем
    if GetCVar('autoLootDefault') ~= '1' then return true end
    -- полутали, ждем открытия лута
    if isLooting() then return true end
    -- свежуем, скоро будем дждать лута
    if isSkinning() then return true end
    -- открыт ли лут?
    local isOpenLoot = LootFrame:IsVisible()
    -- таймер идет пока открыт LootFrame
    c.TimerToggle('LootFrame', isOpenLoot)
    -- может просто подвиснуть лут, бывает при клике одновременно с interact
    if isOpenLoot then
        if c.AutoPopup('станет персональным, если вы его поднимете.', 'ОК') then return true end
        -- если в группе и не freeforall, может быть окно item roll, так что ждем
        if st.group and (GetLootMethod() ~= 'freeforall') then return true end
        -- LootFrame висит
        local IsLootLag = c.TimerStarted('LootFrame') and c.TimerMore('LootFrame', 0.5)
        -- если окно лута подвисло
        if IsLootLag then
            c.MessageLog('#подвисло окно лута', lootTitle, lootIcon)
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

local fish = {}
fish.run = false
fish.spell = 'Рыбная ловля'
fish.icon = select(3, GetSpellInfo(fish.spell))
fish.guid = nil
fish.bobber = nil
fish.delay = 1

local function startFishing()
    if not fish.run then
        c.Message('Сезон рыбалки открыт!', fish.spell, fish.icon)
    end
    fish.run = true
    c.TimerStart(fish.spell)
end

c.ActionHook(fish.spell, function()
    startFishing()
end)

c.Event('COMBAT_LOG_EVENT_UNFILTERED',
    function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
             destFlags, ...)
        local spellName = select(2, ...)
        if subEvent:match('SPELL_CREATE') and sourceGUID == st.playerGUID and spellName == fish.spell then
            startFishing()
            fish.guid = destGUID
            c.MessageLog('#забросили удочку', fish.spell, fish.icon)
        end
    end
)

local function stopFishing(reason)
    if fish.run then
        c.Message('Сезон рыбалки закрыт! ' .. reason, fish.spell, fish.icon)
    end
    fish.guid = nil
    fish.bobber = nil
    fish.run = false
    c.TimerReset(fish.spell)
end
local function waitForFishing()
    if not c.TimerStarted(fish.spell) then return false end

    if c.Paused() then
        stopFishing(UnitIsAFK('player') and 'AFK' or 'Пауза')
        return false
    end

    if not IsUsableSpell(fish.spell) then
        stopFishing('Не могу использовать ' .. GetSpellLink(fish.spell))
        return false
    end

    if c.TimerMore(fish.spell, 5) then
        stopFishing('Не получается уже более 5 сек')
        return false
    end

    if st.playerCasting and st.playerCasting ~= fish.spell then
        stopFishing('Кастую ' .. GetSpellLink(c.GetSpellId(st.playerCasting, nil, true)))
        return false
    end

    if not st.still then
        stopFishing('Двигаюсь')
        return false
    end

    c.SkipNextUpdate()

    if not st.playerCasting then
        if c.CanGcdSpell(fish.spell, nil, fish.delay) then
            fish.bobber = nil
            fish.guid = nil
            CombatLogClearEntries()
            startFishing()
            c.DoAction('Забрасываем', fish.spell)
            fish.delay = nil --0.5 + math_random() * 2.5 -- [0.5 .. 3]
        end
        return true
    end
    -- рыбачим, забросили и ждем
    c.TimerStart(fish.spell)

    if not fish.bobber and fish.guid then
        fish.bobber = c.GetObjectIdByGUID(fish.guid)
        if fish.bobber then
            c.MessageLog('#нашли поплавок', fish.spell, fish.icon)
            fish.guid = nil
        end
    end

    if fish.bobber and not lootList[fish.bobber] then
        c.MessageLog('#ждем клева...', fish.spell, fish.icon)
        local ptr = c.UnitPtr(fish.bobber)
        if c.ReadByte(ptr, 188) ~= 1 then return end
        c.MessageLog('#подсекаем', fish.spell, fish.icon)
        lootUnit(fish.bobber, UnitName(fish.bobber))
        c.Command('/stopcasting')
        fish.bobber = nil
        fish.guid = nil
    end
    return true
end



local function waitForCorpseLoot()
    -- ищем кого можно лутануть
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if not corpse then return false end
    lootUnit(corpse)
    return true
end

local function waitForCorpseSkin()
    if not st.still then return false end
    if not allowSkin then return false end
    -- ищем кого можно освежевать
    local corpse = c.FindValue(c.GetUnits(), checkCorpseForSkin)
    if not corpse then return false end
    c.DoAction('Свежуем', skinSpell, corpse)
    skinTarget = corpse
    c.TimerStart(skinTimer)
    return true
end

local lastCorpse = nil
local function waitForFindCorpse()
    if c.TimerLess('waitForFindCorpse', 1) then return true end
    if not c.flags.move or st.move then return false end
    if st.playerCasting then return false end
    if st.look then return false end
    if lastCorpse and UnitExists(lastCorpse) and (checkCorpseForLoot(lastCorpse) or checkCorpseForSkin(lastCorpse)) then return false end
    -- ищем ближайший полезный труп
    local corpse = getNearCorpse()
    if corpse and c.MoveToUnit(corpse, maxDist) then
        c.MessageLog('#идем к ' .. c.UnitInfo(corpse), 'Loot', lootIcon)
        c.TimerStart('waitForFindCorpse')
        lastCorpse = corpse
    end
end



c.BeforeUpdate(function()
    if waitForLoot() then return end
    resetTimers()
    if st.mounted then return end
    if st.combatMode then return end
    if st.combatLock and not st.invalidTarget then return end
    if waitForFishing() then return end
    if c.Paused() then return end
    if st.gcd or st.playerCasting then return end
    if waitForCorpseLoot() then return end
    if waitForCorpseSkin() then return end
    if waitForFindCorpse() then return end
end)
