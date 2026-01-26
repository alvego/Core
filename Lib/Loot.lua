---@class Core
local c  = Core -- luacheck: ignore
---@class Core.state
local st = c.state


-- luacheck: push ignore
local GetLootMethod         = GetLootMethod
local GetSpellInfo          = GetSpellInfo ---@diagnostic disable-line
local GetSpellTexture       = GetSpellTexture ---@diagnostic disable-line
local IsUsableSpell         = IsUsableSpell ---@diagnostic disable-line
local GetSpellLink          = GetSpellLink
local LootFrame             = LootFrame
local UIParent              = UIParent
local IsFishingLoot         = IsFishingLoot
local UnitIsAFK             = UnitIsAFK
local GetCVar               = GetCVar
local UnitExists            = UnitExists
local UnitName              = UnitName
local CloseLoot             = CloseLoot
local GetLootSlotInfo       = GetLootSlotInfo
local GetNumLootItems       = GetNumLootItems
local LootSlot              = LootSlot
local GetLootSlotLink       = GetLootSlotLink
local type                  = type
local CombatLogClearEntries = CombatLogClearEntries
local CreateFrame           = CreateFrame
local format                = format
local WrapTextInColorCode   = WrapTextInColorCode
-- luacheck: pop

local lootTimer             = 'lootTimer'
local lootDist              = 0
local lootTitle             = 'Обыск'
local lootIcon              = [[Interface\Icons\Ability_Racial_PackHobgoblin]]
local lootTargetGUID        = nil

local skinTimer             = 'skinTimer';
local skinDist              = 5
local allowSkin             = false
local skinTargetGUID        = nil
local skinSpell             = 'Снятие шкур'
local skinIcon              = nil

c.Event('PLAYER_ENTERING_WORLD', function()
    allowSkin = IsUsableSpell(skinSpell)
    if allowSkin then
        skinIcon = GetSpellTexture(skinSpell)
    end
end)

local function isLooting()
    -- нет цели обыска, не обыскиваем
    if not lootTargetGUID then return false end
    -- есть цель и время ожидания не истекло, обыскиваем
    if c.TimerLess(lootTimer, 0.5) then return true end
    -- время ожидания LootFrame истекло, сбрасываем цель, не обыскиваем
    c.MessageLog(format('#%s: %s', WrapTextInColorCode('неудача', 'FF773A3A'), c.UnitInfo(lootTargetGUID)), lootTitle,
        lootIcon)
    lootTargetGUID = nil
    return false
end


c.Event('LOOT_OPENED', function()
    if lootTargetGUID then
        -- успешно обыскали цель, с нее есть добыча
        c.MessageLog(
            format('#%s: %s', WrapTextInColorCode('успех', 'FF3F773A'),
                IsFishingLoot() and UnitName(lootTargetGUID) or c.UnitInfo(lootTargetGUID)), lootTitle,
            lootIcon)

        for i = 1, GetNumLootItems() do
            -- luacheck: ignore
            local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
            local link = GetLootSlotLink(i) or item
            local count = (type(quantity) == 'number' and quantity > 1) and
                WrapTextInColorCode('x' .. quantity, 'ff00ff00') or ''
            c.MessageLog('#добыча ' .. link .. count, lootTitle, texture)
        end
        -- сбрасываем цель
        lootTargetGUID = nil
    end
end)

local function isSkinning()
    -- нет цели, свободны
    if not skinTargetGUID then return false end
    -- есть цель и время ожидания не истекло, в процессе
    if c.TimerLess(skinTimer, 2) then return true end
    -- время ожидания спела истекло, сбрасываем цель, свободны
    c.MessageLog(format('#%s: %s', WrapTextInColorCode('неудача по времени', 'FF773A3A'), c.UnitInfo(skinTargetGUID)),
        skinSpell,
        skinIcon)
    skinTargetGUID = nil
    return false
end

local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if not skinTargetGUID then return end
    if source ~= 'player' then return end
    if spellName ~= skinSpell then return end
    if event == 'UNIT_SPELLCAST_SUCCEEDED' then
        c.MessageLog(format('#%s: %s', WrapTextInColorCode('успех', 'FF3F773A'), c.UnitInfo(skinTargetGUID)), skinSpell,
            skinIcon)
        lootTargetGUID = skinTargetGUID
        c.TimerStart(lootTimer)
    else
        c.MessageLog(format('#%s: %s', WrapTextInColorCode('неудача', 'FF773A3A'), c.UnitInfo(skinTargetGUID)),
            skinSpell,
            skinIcon)
    end
    skinTargetGUID = nil
end
c.Event('UNIT_SPELLCAST_FAILED', onEvent)
c.Event('UNIT_SPELLCAST_SUCCEEDED', onEvent)

function c.CanSkinning(unit)
    if not allowSkin then return false end
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
            -- luacheck: ignore
            local r, g, b = _G[textName]:GetTextColor()
            -- Красный текст: g ~0.1-0.2; белый/желтый/зеленый: g > 0.5
            -- Возвращаем true, если НЕ красный (уровень профессии ок)
            return g > 0.5
        end
    end
    return false
end

local function waitForLoot()
    -- core лут отключен, стоп
    if not c.flags.loot then return true end
    -- нет свободного места в сумках, стоп
    if c.GetBagsFreeSlots() < 1 then return true end
    -- wow autoLoot отключен, дальше не идем
    if GetCVar('autoLootDefault') ~= '1' then return true end
    -- полутали, ждем открытия LootFrame
    if isLooting() then return true end
    -- свежуем, скоро будем ждать LootFrame
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
        -- если окно добычи подвисло
        if IsLootLag then
            c.MessageLog('#подвисло окно добычи', lootTitle, lootIcon)
            for i = 1, GetNumLootItems() do
                -- тогда обыскиваем вручную
                if not select(5, GetLootSlotInfo(i)) then LootSlot(i) end
            end
            CloseLoot() -- закрываем LootFrame
        end
        return true     -- ждем одну итерацию, для закрытия LootFrame
    end
    return false        -- LootFrame нет, можно что-то делать
end

local fish = {}
fish.run = false
fish.spell = 'Рыбная ловля'
fish.icon = select(3, GetSpellInfo(fish.spell))
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

local function stopFishing(reason)
    if fish.run then
        c.Message('Сезон рыбалки закрыт! ' .. reason, fish.spell, fish.icon)
    end
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
            CombatLogClearEntries()
            startFishing()
            c.DoAction('Забрасываем', fish.spell)
            fish.delay = nil --0.5 + math_random() * 2.5 -- [0.5 .. 3]
        end
        return true
    end
    -- рыбачим, забросили и ждем
    c.TimerStart(fish.spell)

    if c.bCheckBobber() then
        c.MessageLog('#подсекаем', fish.spell, fish.icon)
        c.bUseMacro('/stopcasting')
    end
    return true
end

local function waitForCorpseLoot()
    -- ищем кого можно обыскать
    local corpseGUID = c.bFindCorpse(lootDist, false, 20)
    if not corpseGUID then return false end
    c.Message(c.UnitInfo(corpseGUID), lootTitle, lootIcon)
    c.bUnitClick(corpseGUID, true)
    lootTargetGUID = corpseGUID
    c.TimerStart(lootTimer)
    return true
end

local function waitForCorpseSkin()
    if not st.still then return false end
    if not allowSkin then return false end
    -- ищем кого можно освежевать
    local corpseGUID = c.bFindCorpse(skinDist, true, 20)
    if not corpseGUID then return false end
    if not c.bWithGUID(corpseGUID, c.CanSkinning) then return false end -- TODO: тут будет сбой, если уровень профессии не достаточен
    c.DoActionWithGUID('Свежуем', skinSpell, corpseGUID)
    skinTargetGUID = corpseGUID
    c.TimerStart(skinTimer)
    return true
end

local lastCorpseGUID = nil
local function waitForFindCorpse()
    if c.TimerLess('waitForFindCorpse', 1) then return true end
    if not c.flags.move or st.move then return false end
    if st.playerCasting then return false end
    if st.look then return false end
    if lastCorpseGUID and c.bObjectExists(lastCorpseGUID) then return false end
    -- ищем ближайший полезный труп
    local corpseGUID = c.bFindCorpse(40, false, 20) or c.bFindCorpse(40, true, 20)
    if corpseGUID and c.MoveToUnit(corpseGUID) then
        c.MessageLog('#идем к ' .. c.UnitInfo(corpseGUID), 'Loot', lootIcon)
        c.TimerStart('waitForFindCorpse')
        lastCorpseGUID = corpseGUID
    end
end

c.BeforeUpdate(function()
    if waitForLoot() then return end
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
