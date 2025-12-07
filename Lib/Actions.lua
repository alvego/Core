-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
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
local HasAction = HasAction
local GetMacroSpell = GetMacroSpell
local GetItemSpell = GetItemSpell
local GetPetActionInfo = GetPetActionInfo
local ConsoleExec = ConsoleExec
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
c.Event('ACTIONBAR_SLOT_CHANGED', updateActions)
c.Event('PLAYER_ENTERING_WORLD', updateActions)


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
function c.GetActionSpell(slot)
    if not HasAction(slot) then return nil end -- Слот 1-120 пустой

    local actionType, id, subType, spellID = GetActionInfo(slot)
    if not actionType then return nil end

    if spellID then return select(1, GetSpellInfo(spellID)) end

    local spellName = nil
    if actionType == 'macro' then
        spellName = GetMacroSpell(id)
    elseif actionType == 'item' then
        local itemName = GetItemInfo(id)
        if itemName then
            spellName = GetItemSpell(itemName)
        end
    elseif actionType == 'pet' then
        spellName = GetPetActionInfo(id) -- id как pet slot index
    end
    return spellName
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
    if unit ~= nil and ActionHasRange(slot) and IsActionInRange(slot, unit) == 0 then
        return false, '!range'
    end
    if c.GetSlotCooldownLeft(slot) > c.latency then
        return false, '!ready'
    end
    return true, ''
end

-------------------------------------------------------------------------------
function c.GetSlot(action, skipError)
    if action == 'none' then
        return
    end
    if not action then
        if not skipError then c.Error('Неверное действие. Используй none для бездействия.') end
        return
    end
    local slot = actions[action]
    if not slot then
        if not skipError then c.Error('Не могу найти на панели [' .. action .. ']') end
        return
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
        c.Error(format('DoAction: reason required! - [%s]', c.ToStr(reason, name, target, btnNum)))
        return
    end
    if type(name) ~= 'string' then
        c.Error(format('DoAction: name required! - [%s]', c.ToStr(reason, name, target, btnNum)))
        return
    end
    local button = mouseButtons[btnNum]
    if type(button) ~= 'string' then
        button = mouseButtons[1]
    end
    local slot = c.GetSlot(name, true)
    if not slot then
        c.DoSpell(reason, name, target) -- failback
        return
    end
    c.LogWhatHappend(reason, true)
    local targetName = target and UnitName(target) or nil
    if targetName then reason = reason .. ' ' .. c.UnitInfo(target) end
    c.ClearCursor()
    c.Message(reason, name, GetActionTexture(slot), 1, 0.8431, 0) -- permanent gold
    ConsoleExec('Sound_EnableSFX 0')
    c.Action(slot, target, button)
    ConsoleExec('Sound_EnableSFX 1')
    st.lastAction = name
end

-------------------------------------------------------------------------------
