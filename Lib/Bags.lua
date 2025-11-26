-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots
local ClearCursor = ClearCursor
local PickupContainerItem = PickupContainerItem
local DeleteCursorItem = DeleteCursorItem
local GetContainerItemInfo = GetContainerItemInfo
local GetCoinTextureString = GetCoinTextureString
local UseContainerItem = UseContainerItem
local WrapTextInColorCode = WrapTextInColorCode
local SecondsToTime = SecondsToTime
local CanMerchantRepair = CanMerchantRepair
local RepairAllItems = RepairAllItems
local ItemRefTooltip = ItemRefTooltip
local GameTooltip = GameTooltip
local GetInventoryItemID = GetInventoryItemID
local GetContainerItemLink = GetContainerItemLink
local tContains = tContains
-------------------------------------------------------------------------------
function c.GetBagsFreeSlots()
    local free = 0
    -- считаем сободное место
    for bag = 0, NUM_BAG_SLOTS do
        local n = GetContainerNumFreeSlots(bag);
        if n then free = free + n end
    end
    return free
end

-------------------------------------------------------------------------------
function c.EachBugsSlot(fn)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local value = fn(bag, slot)
            if value ~= nil then return value end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
local disabledItemEquipLoc = {
    'INVTYPE_BODY',
    'INVTYPE_TABARD',
    'INVTYPE_RELIC',
    'INVTYPE_BAG',
    'INVTYPE_QUIVER',
    'INVTYPE_THROWN'
}
local familyRare = 7
local function getEquippedItemLevel(link)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
        GetItemInfo(link)
    if not itemName then return end
    --c.Log(itemLink, itemType, itemSubType, itemEquipLoc, itemMinLevel, itemLevel)
    if itemRarity == familyRare then return end
    if itemEquipLoc and tContains(disabledItemEquipLoc, itemEquipLoc) then return end

    if itemType == 'Доспехи' then return itemLevel, itemLink end
    if itemType == 'Оружие' then
        if itemSubType == 'Удочки' then return end
        if itemSubType == 'Разное' then return end
        return itemLevel, itemLink
    end
end
-------------------------------------------------------------------------------
local getMinEquippedItemLevel = c.GetCachedFunc(function()
    local minLvL = nil
    for i = 1, 18 do
        local itemID = GetInventoryItemID('player', i)
        if itemID then
            local itemLevel, itemLink = getEquippedItemLevel(itemID)
            if itemLevel then
                --c.Log(itemLink, itemLevel)
                if not minLvL or itemLevel < minLvL then
                    minLvL = itemLevel
                    --c.Log('берем', itemLevel)
                end
            end
        end
    end
    --c.Log('minItemLevel', minLvL)
    return minLvL or 0
end)
-------------------------------------------------------------------------------
local function checkItemLevel(itemLevel, itemSellPrice)
    local minItemLevel = getMinEquippedItemLevel()
    if itemLevel < c.Round(minItemLevel * 0.8) then -- 80%
        return format('Хлам (ilvl:%d < %d)', itemLevel, minItemLevel),
            itemSellPrice
    end
end

local function checkItemMinLevel(itemMinLevel, itemSellPrice)
    if itemMinLevel > 0 and itemMinLevel < (UnitLevel('player') - 10) then
        return 'Хлам (по ур.)', itemSellPrice
    end
end

local function checkJunkList(skipList, itemName, itemSellPrice)
    if not skipList and c.db.junk and c.db.junk[itemName] then return 'Хлам (метка)', itemSellPrice end
end

local function isJunk(link, skipList)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
        GetItemInfo(link)
    if not itemName then return end
    -- продаем любой хлам
    if itemRarity == 0 then return 'Хлам', itemSellPrice end
    -- вещи обычного качества
    if itemRarity == 1 then
        -- проверяем, на игнорируемые слоты (эти вещи не трогаем)
        if itemEquipLoc and tContains(disabledItemEquipLoc, itemEquipLoc) then
            return checkJunkList(skipList, itemName, itemSellPrice)
        end

        if itemType == 'Доспехи' then return checkItemLevel(itemLevel, itemSellPrice) end
        if itemType == 'Оружие' then
            if itemSubType == 'Удочки' then return checkJunkList(skipList, itemName, itemSellPrice) end
            if itemSubType == 'Разное' then return checkJunkList(skipList, itemName, itemSellPrice) end
            return checkItemLevel(itemLevel, itemSellPrice)
        end

        if itemType == 'Расходуемые' then
            if itemSubType == 'Зелья' and (c.StrContains(itemName, 'лечебн') or c.StrContains(itemName, ' маны')) then
                return checkItemMinLevel(itemMinLevel, itemSellPrice)
            end
            if itemSubType == 'Еда и напитки' then
                return checkItemMinLevel(itemMinLevel, itemSellPrice)
            end
        end
    end

    return checkJunkList(skipList, itemName, itemSellPrice)
end

local itemTipHook = function(self, ...)
    local itemName, itemLink = self:GetItem()
    local junk = isJunk(itemLink)
    if not junk then return end
    local line1 = WrapTextInColorCode(junk, 'ff888888')
    local line2 = WrapTextInColorCode('Будет продан/выброшен', 'FFAD1F1F')
    self:AddDoubleLine(line1, line2)
    self:Show()
end
GameTooltip:HookScript('OnTooltipSetItem', itemTipHook)
ItemRefTooltip:HookScript('OnTooltipSetItem', itemTipHook)
-------------------------------------------------------------------------------
local itemTipTypeHook = function(self, ...)
    local _, link = self:GetItem()
    local _, _, _, _, _, itemType, itemSubType =
        GetItemInfo(link)
    if not itemType then return end
    local line1 = WrapTextInColorCode(itemType ~= itemSubType and itemType or '', 'FF0069A1')
    local line2 = WrapTextInColorCode(itemSubType, 'FF0069A1')
    self:AddDoubleLine(line1, line2)
    self:Show()
end
GameTooltip:HookScript('OnTooltipSetItem', itemTipTypeHook)
ItemRefTooltip:HookScript('OnTooltipSetItem', itemTipTypeHook)
-------------------------------------------------------------------------------
c.AttachEvent('GLOBAL_MOUSE_UP', function(event, button)
    if button ~= "MiddleButton" then return end
    local name, link = GameTooltip:GetItem()
    if not name or not link then return end
    if isJunk(link, true) then return end
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
        GetItemInfo(link)
    if not itemName then return end
    if not c.db.junk then c.db.junk = {} end
    if c.db.junk[itemName] then
        c.db.junk[itemName] = nil
        c.MessageLog(format('%s %s', WrapTextInColorCode('удалено из списка хлама', 'ff00ff00'), itemLink), 'Хлам',
            itemTexture)
        return
    end
    c.db.junk[itemName] = true
    c.MessageLog(format('%s %s', WrapTextInColorCode('добавлено в список хлама', 'ffff0000'), itemLink), 'Хлам',
        itemTexture)
end)
-------------------------------------------------------------------------------
local junkIcon = [[Interface\Icons\Spell_Mage_ConjuredManaBuns]]
function c.RemoveJunk()
    ClearCursor()
    local cnt = 0
    local free = c.GetBagsFreeSlots()
    c.EachBugsSlot(function(bag, slot)
        local icon, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if icon and not locked ~= 1 then -- and lootable ~= 1
            local junk = isJunk(link)
            if junk then
                cnt = cnt + 1
                c.MessageLog(format('Выбрасываем %s %s из сумок', junk, link), 'Очистка', icon)
                PickupContainerItem(bag, slot)
                DeleteCursorItem()
            end
        end
    end)
    if cnt > 0 then
        c.Message(format('Освободили %s слот(ов). Свободно %s слот(а).', cnt, free + cnt), 'Очистка', junkIcon)
    end
end

-------------------------------------------------------------------------------
local lootIcon = [[Interface\Icons\Ability_Racial_PackHobgoblin]]
c.AttachEvent('MERCHANT_SHOW', function()
    ClearCursor()
    local sum = 0
    local cnt = 0
    local free = c.GetBagsFreeSlots()
    c.EachBugsSlot(function(bag, slot)
        local icon, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if icon and not locked ~= 1 and lootable ~= 1 then
            local isTrash, sellPrice = isJunk(link)
            if isTrash then
                cnt = cnt + 1
                if sellPrice > 0 then
                    sum = sum + sellPrice
                    c.MessageLog(format('%s за %s', link, GetCoinTextureString(sellPrice)),
                        'Продажа', icon)
                    UseContainerItem(bag, slot)
                else
                    c.MessageLog(format('%s выбрасываем из сумок', link), 'Очистка', icon)
                    PickupContainerItem(bag, slot)
                    DeleteCursorItem()
                end
            end
        end
    end)
    if sum > 0 then
        c.Message(format('Итого продали на %s', GetCoinTextureString(sum)), 'Продажа', lootIcon)
    end
    if cnt > 0 then
        c.Message(format('Освободили %s слот(ов). Свободно %s слот(а).', cnt, free + cnt), 'Продажа', lootIcon)
    end
    if CanMerchantRepair() then
        RepairAllItems(1) -- сперва пробуем за счет ги банка
        RepairAllItems()
    end
end)
-------------------------------------------------------------------------------
