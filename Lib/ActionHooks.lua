-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local error = error
local GetActionTexture = GetActionTexture
local ActionHasRange = ActionHasRange
local IsUsableAction = IsUsableAction
local IsActionInRange = IsActionInRange
-------------------------------------------------------------------------------
local userAction = {}
userAction.slot = nil
userAction.target = nil
userAction.button = nil
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

    local isMine = c.SlotIsPressed(slot)
    if not isMine then return end

    local hook = actionHooks[name]
    if hook then
        c.MessageLog('', name, GetActionTexture(slot)) -- hook
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
        c.MessageLog(notEnoughMana and '!mana' or '!usable', name, GetActionTexture(slot))
        return
    end
    if ActionHasRange(slot) and IsActionInRange(slot, target) == 0 then
        c.MessageLog('!range', name, GetActionTexture(slot))
        return
    end
    if userAction.slot ~= slot then
        userAction.slot = slot
        userAction.target = target
        userAction.button = button
        c.TimerStart(userActionTimer, castLeft or 0)
        c.MessageLog('нажать?', name, GetActionTexture(slot))
    elseif inCast then
        c.MessageLog('повтор -> стопкаст', name, GetActionTexture(slot))
        c.CastStop()
    end
end
hooksecurefunc('UseAction', hookUseAction)

-------------------------------------------------------------------------------
local function updateUserAction()
    if userAction.slot == nil then
        return
    end
    if c.TimerMore(userActionTimer, 2) then
        c.Message('отмена по времени!', c.GetSlotName(userAction.slot), GetActionTexture(userAction.slot))
        userAction.slot = nil
        userAction.target = nil
        userAction.button = nil
        return
    end
    if not c.CanUseSlot(userAction.slot, userAction.target) then
        c.MessageLog('пока не доступно!', c.GetSlotName(userAction.slot), GetActionTexture(userAction.slot))
        c.SkipNextUpdate()
        return
    end
    if c.UnitCasting('player') then -- add spell busy
        c.MessageLog('ожидаем конец каста!', c.GetSlotName(userAction.slot), GetActionTexture(userAction.slot))
        c.SkipNextUpdate()
        return
    end

    if c.GetSpellCooldownLeft(c.gcdSpellId) > 0 then
        c.MessageLog('пока готово!', c.GetSlotName(userAction.slot), GetActionTexture(userAction.slot))
        c.SkipNextUpdate()
        return
    end
    c.Message('жмем!', c.GetSlotName(userAction.slot), GetActionTexture(userAction.slot))
    c.Action(userAction.slot, userAction.target, userAction.button)
    c.SkipNextUpdate()
    userAction.slot = nil
    userAction.target = nil
    userAction.button = nil
end
c.AttachAfterUpdate(updateUserAction)
-------------------------------------------------------------------------------
