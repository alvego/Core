-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local _G = _G
local ActionHasRange = ActionHasRange
local wipe = wipe
local type = type
local tostring = tostring
local GetMacroInfo = GetMacroInfo
local GetActionInfo = GetActionInfo
local GetSpellInfo = GetSpellInfo
local GetItemInfo = GetItemInfo
local GetCompanionInfo = GetCompanionInfo
local GetActionTexture = GetActionTexture
local WrapTextInColorCode = WrapTextInColorCode
-------------------------------------------------------------------------------
function c.GetSlotName(slot)
    local name = nil
    local actiontype, id, subtype, spellId = GetActionInfo(slot)
    if actiontype == 'spell' then
        name = GetSpellInfo(spellId)
    elseif actiontype == 'item' then
        name = GetItemInfo(id)
    elseif actiontype == 'companion' then
        name = select(2, GetCompanionInfo(subtype, id))
    elseif actiontype == 'macro' then
        name = GetMacroInfo(id)
    end
    return name, actiontype
end

-------------------------------------------------------------------------------
local actions = {}
local updateActions = function()
    wipe(actions)
    for slot = 1, 120 do -- 12 x 10
        local name = c.GetSlotName(slot)
        if name then
            actions[name] = slot
        end
    end
end
c.AttachEvent('ACTIONBAR_SLOT_CHANGED', updateActions)
c.AttachEvent('PLAYER_ENTERING_WORLD', updateActions)


-------------------------------------------------------------------------------
local actionsCD = {}
local function hook_SetCooldown(self, start, duration)
    local parent = self:GetParent()
    if not parent then return end
    local name = parent:GetName()
    if not name then return end
    actionsCD[name] = start + duration
end
hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', hook_SetCooldown)
-------------------------------------------------------------------------------
function c.GetSlotCooldownLeft(slot)
    if not slot then return 0 end
    local cd = actionsCD['BT4Button' .. slot]
    return cd and (cd - GetTime()) or 0
end

-------------------------------------------------------------------------------
function c.CanUseSlot(slot, unit)
    if type(slot) ~= 'number' or slot == nil or slot == 0 or slot > 120 then
        return false, '!slot ' .. tostring(slot)
    end
    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable or notEnoughMana then
        return false, notEnoughMana and '!mana' or '!usable'
    end
    if ActionHasRange(slot) and IsActionInRange(slot, unit) == 0 then
        return false, '!range'
    end
    if c.GetSlotCooldownLeft(slot) > c.latency then
        return false, '!ready'
    end
    return true, ''
end

-------------------------------------------------------------------------------
function c.GetSlot(action)
    if action == 'none' then
        return 0
    end
    if not action then
        c.Error('Неверное действие. Используй none для бездействия.');
        return 0
    end
    local slot = actions[action]
    if not slot then
        c.Error('Не могу найти на панели [' .. action .. ']');
        return 0
    end
    return slot
end

-------------------------------------------------------------------------------
function c.IsReadyAction(action)
    local slot = c.GetSlot(action)
    return c.GetSlotCooldownLeft(slot) < c.latency
end

-------------------------------------------------------------------------------
function c.CanUseAction(action, unit)
    local slot = c.GetSlot(action)
    return c.CanUseSlot(slot, unit)
end

-------------------------------------------------------------------------------
function c.SlotIsPressed(slot)
    if not slot then return false end
    local btn = _G['BT4Button' .. slot]
    if not btn then return false end
    return btn:GetButtonState() == 'PUSHED'
end

-------------------------------------------------------------------------------
function c.ButtonIsPressed()
    for i = 1, 120 do -- 12 x 10
        if c.SlotIsPressed(i) then
            return i
        end
    end
    return nil
end

-------------------------------------------------------------------------------
function c.IsActionPressed(action)
    return c.SlotIsPressed(c.GetSlot(action))
end

-------------------------------------------------------------------------------
local mouseButtons = {
    [1] = 'LeftButton',
    [2] = 'RightButton',
    [3] = 'MiddleButton',
    [4] = 'Button4',
    [5] = 'Button5',
}

function c.DoAction(reason, name, target, btnNum)
    if type(reason) ~= 'string' then
        c.Error(format('DoAction: reason requared! - [%s]', c.ToStr(reason, name, target, btnNum)))
        return
    end
    if type(name) ~= 'string' then
        c.Error(format('DoAction: name requared! - [%s]', c.ToStr(reason, name, target, btnNum)))
        return
    end
    local button = mouseButtons[btnNum]
    if type(button) ~= 'string' then
        button = mouseButtons[1]
    end
    local slot = c.GetSlot(name)
    local canuse, canuseinfo = c.CanUseSlot(slot, target)
    if not canuse then
        c.MessageLog(format('%s - [%s]', reason, canuseinfo), name, GetActionTexture(slot))
        return
    end
    c.LogWhatHappend(reason, true)
    local targetName = target and UnitName(target) or nil
    if targetName then reason = reason .. WrapTextInColorCode(' @' .. targetName, c.GetUnitColorHex(target)) end
    c.ClearCursor()
    c.Message(reason, name, GetActionTexture(slot))
    c.Action(slot, target, button)
    c.lastAction = name
end

-------------------------------------------------------------------------------
