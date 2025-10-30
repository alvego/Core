-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local error = error
local SetCVar = SetCVar
local GetCVar = GetCVar
local GetActionTexture = GetActionTexture
local ActionHasRange = ActionHasRange
local IsUsableAction = IsUsableAction
local IsActionInRange = IsActionInRange
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
-------------------------------------------------------------------------------
local userAction = {}
userAction.slot = nil
userAction.target = nil
userAction.button = nil

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
    local inCast = c.UnitCasting('player')
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
    if not c.CanUseSlot(userAction.slot, userAction.target) then
        c.SkipNextUpdate()
        return
    end
    if c.UnitCasting('player') then -- add spell busy
        c.SkipNextUpdate()
        return
    end

    if c.GetSpellCooldownLeft(c.gcdSpellId) > 0 then
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
local function attackActionHook()
    c.attack = true
    c.Paused(false)
    c.TurnTo('target')
end
c.AttachActionHook('attack', attackActionHook)

-------------------------------------------------------------------------------
local function updateAttack()
    c.attack = c.IsActionPressed('attack') or c.IsMouse(4)
    if c.attack then
        c.Paused(false)
        c.TurnTo('target')
    end
end
c.AttachBeforeUpdate(updateAttack)

-------------------------------------------------------------------------------
local function startActionHook()
    c.start = true
    c.Paused(false)
end
c.AttachActionHook('attack', startActionHook)

-------------------------------------------------------------------------------
local function updateStart()
    c.start = c.IsActionPressed('start') or c.IsMouse(3)
    if c.start then
        c.Paused(false)
    end
end
c.AttachBeforeUpdate(updateStart)

-------------------------------------------------------------------------------
local function stopActionHook()
    if c.attack then return end
    c.Paused(true)
end
c.AttachActionHook('stop', stopActionHook)
-------------------------------------------------------------------------------
local function updateStop()
    if c.attack then return end
    if c.IsActionPressed('stop') or c.IsMouse(5) or UnitIsDeadOrGhost('player') then
        c.Paused(true)
    end
end
c.AttachBeforeUpdate(updateStop)
-------------------------------------------------------------------------------
local function debugActionHook()
    SetCVar("scriptErrors", GetCVar("scriptErrors") == "1" and 0 or 1)
end
c.AttachActionHook('debug', debugActionHook)

-------------------------------------------------------------------------------
local function targetActionHook()
    c.FindAndSelectNewTarget()
end
c.AttachActionHook('target', targetActionHook)


-------------------------------------------------------------------------------
local function auraActionHook() -- for debug
    local target = 'target'
    if not UnitExists(target) then
        target = 'player'
    end
    local unit = UnitName(target)
    if unit == nil then return end
    local guid = UnitGUID(target)
    c.MessageLog('Auras for GUID:' .. guid, unit, nil, 0, 0, 1)
    local idx = 0
    repeat
        local spellId, count, duration, endTime, isMine, isDebuff = c.UnitAuraByIndex(target, idx)
        if spellId == nil then break end
        if spellId and spellId ~= 0 then
            local name, _, icon = GetSpellInfo(spellId)
            local link = GetSpellLink(spellId)
            if name then
                local method = isDebuff and UnitDebuff or UnitBuff
                local aura, _, _, _, _, _, _, _, _, _, auraId = method(target, name)
                local findInUI = aura and (auraId == spellId)
                c.MessageLog(
                    format(
                        '%s |cff%sUI|r',
                        link or name,
                        findInUI and '00ff00' or '000000'
                    ),
                    format('|cff%s%s|r', isDebuff and 'ff0000' or '00ff00', spellId), icon, 1, 1, 1
                )
            end
        end
        idx = idx + 1
    until false
end
c.AttachActionHook('aura', auraActionHook)

-------------------------------------------------------------------------------
local function testActionHook()
    c.Target(nil)
end

c.AttachActionHook('test', testActionHook)
-------------------------------------------------------------------------------
