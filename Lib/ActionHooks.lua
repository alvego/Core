-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local type = type
local error = error
local GetActionTexture = GetActionTexture
local ActionHasRange = ActionHasRange
local IsUsableAction = IsUsableAction
local IsActionInRange = IsActionInRange
local ActionButton_ShowOverlayGlow = ActionButton_ShowOverlayGlow
local ActionButton_HideOverlayGlow = ActionButton_HideOverlayGlow
-------------------------------------------------------------------------------
local userAction = {}
local function userActionReset()
    if not userAction.slot then return end
    local button = _G["BT4Button" .. userAction.slot]
    ActionButton_HideOverlayGlow(button)
    userAction.slot = nil
    userAction.target = nil
    userAction.button = nil
    userAction.name = nil
    userAction.icon = nil
end

local function userActionSet(slot, target, button, name, icon)
    userActionReset()
    if not slot then return end
    userAction.slot = slot
    userAction.target = target
    userAction.button = button
    userAction.name = name
    userAction.icon = icon
    local button = _G["BT4Button" .. userAction.slot]
    ActionButton_ShowOverlayGlow(button)
end
local userActionTimer = 'userAction'
local actionHooks = {}

function c.AttachActionHook(name, func)
    if type(name) ~= 'string' then error('Wrong name type') end
    if type(func) ~= 'function' then error('Wrong func type') end
    actionHooks[name] = func
end

local function hookUseAction(slot, target, button)
    local name = c.GetSlotName(slot)
    if not name then
        return
    end
    local icon = GetActionTexture(slot)
    local isMine = c.SlotIsPressed(slot)
    if not isMine then return end

    local hook = actionHooks[name]
    if hook then
        c.MessageLog('', name, icon) -- hook
        hook(slot, target, button)
        return
    end

    local left = c.GetSlotCooldownLeft(slot)
    local gcdLeft, gcdDuration = c.GetSpellCooldownLeft(c.gcdSpellId)
    local onGcd = left > 0 and (left == gcdLeft)
    local inCast, castLeft = c.UnitCasting('player')
    if not inCast then
        if not onGcd then return end
        local ownGCD = onGcd and (gcdDuration - gcdLeft) < c.advance
        if ownGCD then return end
    end
    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable or notEnoughMana then
        c.MessageLog(notEnoughMana and '!mana' or '!usable', name, icon)
        return
    end
    if ActionHasRange(slot) and IsActionInRange(slot, target) == 0 then
        c.MessageLog('!range', name, icon)
        return
    end
    if userAction.slot ~= slot then
        userActionSet(slot, target, button, name, icon)
        c.TimerStart(userActionTimer, castLeft or 0)
        c.MessageLog('нажать?', name, icon)
    elseif inCast then
        c.MessageLog('повтор -> стопкаст', name, icon)
        c.Command('/stopcasting')
    end
end
hooksecurefunc('UseAction', hookUseAction)

-------------------------------------------------------------------------------
local function updateUserAction()
    if userAction.slot == nil then
        return
    end
    if c.TimerMore(userActionTimer, 2) then
        c.Message('не успели!', userAction.name, userAction.icon)
        userActionReset()
        return
    end
    if not c.IsSpellNotUsed(userAction.name, 0.5) then
        c.Message('прожали!', userAction.name, userAction.icon)
        userActionReset()
        return
    end
    local canuse, canuseinfo = c.CanUseSlot(userAction.slot, userAction.target)
    if not canuse then
        c.MessageLog(canuseinfo, userAction.name, userAction.icon)
        c.SkipNextUpdate()
        return
    end
    if st.playerCasting then -- add spell busy
        c.MessageLog('каст!', userAction.name, userAction.icon)
        c.SkipNextUpdate()
        return
    end

    if st.gcd then
        c.MessageLog('гкд!', userAction.name, userAction.icon)
        c.SkipNextUpdate()
        return
    end
    c.Message('жмем!', userAction.name, userAction.icon)
    -- print(userAction.slot, userAction.target, userAction.button)
    -- print(c.GetSlotName(userAction.slot), UnitExists(userAction.target or 'target'))
    c.Action(userAction.slot, userAction.target, userAction.button)
    c.SkipNextUpdate()
end
c.AttachBeforeUpdate(updateUserAction)
-------------------------------------------------------------------------------
-- исправленеие зависающих стандартных желтых обводок проков
c.AttachBeforeUpdate(function()
    -- по выходу из боя
    for i = 1, 120 do -- 12 x 10
        -- для всех кнопок на панелях
        local btn = _G['BT4Button' .. i]
        if btn then
            -- делаем сброс стандартной мигающей подсветки
            ActionButton_HideOverlayGlow(btn)
            ActionButton_HideOverlayGlow(btn)
        end
    end
end)
