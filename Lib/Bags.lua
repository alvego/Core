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
c.db.junk = c.db.junk or {}

c.AttachActionHook('markJunk', function()
    local name, link = GameTooltip:GetItem()
    if not name or not link then return end
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =  GetItemInfo(link)
    if not itemName then return end
    if itemRarity == 0 then return end
    local mark = WrapTextInColorCode('Хлам*', 'ff888888')
    local title = 'Маркер'
    if c.db.junk[itemName] then
        c.db.junk[itemName] = nil
        с.Echo(format('отметка %s стерта с %s', mark, itemLink), title, itemTexture)
        return
    end
    c.db.junk[itemName] = true
    с.Echo(format('%s помечен как %s', itemLink, mark), title, itemTexture)    
end)


local function isJunk(link)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
        GetItemInfo(link)
    if not itemName then return nil, 0, false end
    if itemRarity == 0 then return true, itemSellPrice, false end
    if c.db.junk[itemName] then return true, itemSellPrice, true end
    return false, 0, false
end

local itemTipHook = function(self, ...)
    local itemName, itemLink = self:GetItem()
    local junk, price, mark = isJunk(itemLink)
    if junk ~= true then return end
    local line1 = WrapTextInColorCode('Хлам' .. (mark and '*' or ''), 'ff888888')
    local line2 = WrapTextInColorCode('Будет продан/выброшен', 'FFAD1F1F')
    self:AddDoubleLine(line1, line2)
    self:Show()
end
GameTooltip:HookScript('OnTooltipSetItem', itemTipHook)
ItemRefTooltip:HookScript('OnTooltipSetItem', itemTipHook)

-------------------------------------------------------------------------------
c.AttachActionHook('junk', function()
    ClearCursor()
    local cnt = 0
    c.EachBugsSlot(function(bag, slot)
        local icon, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if icon and not locked ~= 1 and lootable ~= 1 and isJunk(link) then
            cnt = cnt + 1
            c.MessageLog(format('Выбрасываем хлам %s из сумок', link), 'Очистка', icon)
            PickupContainerItem(bag, slot)
            DeleteCursorItem()
        end
    end)
    if cnt > 0 then
        c.Message(format("Освободили %s слот(ов). Свободно %s слот(а).", cnt, c.GetBagsFreeSlots()), 'Очистка')
    end
end
)
-------------------------------------------------------------------------------
c.AttachEvent('MERCHANT_SHOW', function()
    ClearCursor()
    local sum = 0
    local cnt = 0
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
        c.Message(format("Итого продали на %s", GetCoinTextureString(sum)), 'Продажа')
    end
    if cnt > 0 then
        c.Message(format("Освободили %s слот(ов). Свободно %s слот(а).", cnt, c.GetBagsFreeSlots()), 'Продажа')
    end
    if CanMerchantRepair() then
        RepairAllItems(1) -- сперва пробуем за счет ги банка
        RepairAllItems()
    end
end)
-------------------------------------------------------------------------------
