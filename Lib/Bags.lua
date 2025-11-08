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
local function isJunk(link)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
        GetItemInfo(link)
    if not itemName then
        return nil, 0
    end
    return itemRarity == 0, itemSellPrice
end

local itemTipHook = function(self, ...)
    local itemName, itemLink = self:GetItem()
    if isJunk(itemLink) ~= true then return end
    local line1 = WrapTextInColorCode('Хлам', 'ff888888')
    local line2 = WrapTextInColorCode('Будет продан/выброшен', 'FFAD1F1F')
    self:AddDoubleLine(line1, line2)
    self:Show()
end
GameTooltip:HookScript('OnTooltipSetItem', itemTipHook)
ItemRefTooltip:HookScript('OnTooltipSetItem', itemTipHook)

-------------------------------------------------------------------------------
c.AttachActionHook('junk', function()
    ClearCursor()
    c.TimerStart('junk')
    local count = 0
    c.EachBugsSlot(function(bag, slot)
        local icon, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if icon and not locked ~= 1 and lootable ~= 1 and isJunk(link) then
            c.MessageLog(format('Выбрасываем хлам %s из сумок', link), 'Очистка', icon)
            PickupContainerItem(bag, slot)
            DeleteCursorItem()
            count = count + 1
        end
    end)
    if count > 0 then
        c.Message(format("Освободили %s слотов, за %s", count,
            SecondsToTime(c.TimerElapsed('junk'))), 'Очистка')
    end
end
)
-------------------------------------------------------------------------------
c.AttachEvent('MERCHANT_SHOW', function()
    ClearCursor()
    c.TimerStart('junk')
    local sum = 0
    local count = 0
    c.EachBugsSlot(function(bag, slot)
        local icon, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if icon and not locked ~= 1 and lootable ~= 1 then
            local isTrash, sellPrice = isJunk(link)
            if isTrash then
                if sellPrice > 0 then
                    c.MessageLog(format('Продаем хлам %s из сумок за %s', link, GetCoinTextureString(sellPrice)),
                        'Продажа', icon)
                    UseContainerItem(bag, slot)
                    sum = sum + sellPrice
                else
                    c.MessageLog(format('Выбрасываем хлам %s из сумок', link), 'Очистка', icon)
                    PickupContainerItem(bag, slot)
                    DeleteCursorItem()
                end
                count = count + 1
            end
        end
    end)
    if sum > 0 then
        c.Message(format("Итого продали на %s", GetCoinTextureString(sum)), 'Продажа')
        c.Message(format("Освободили %s слотов, за %s", count,
            SecondsToTime(c.TimerElapsed('junk'))), 'Продажа')
    end
    if CanMerchantRepair() then
        RepairAllItems(1) -- сперва пробуем за счет ги банка
        RepairAllItems()
    end
end)
-------------------------------------------------------------------------------
