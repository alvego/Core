---@class Core
local c = Core -- luacheck: ignore
---@class Core.state
local st = c.state
-- luacheck: push ignore
local type = type
local error = error
local GetActionTexture = GetActionTexture
local ActionHasRange = ActionHasRange
local IsUsableAction = IsUsableAction
local IsActionInRange = IsActionInRange
local hooksecurefunc = hooksecurefunc
-- luacheck: pop
local userAction = {}
local function userActionReset()
    if not userAction.slot then return end
    c.HideActionGlow(userAction.slot)
    userAction.slot = nil
    userAction.target = nil
    userAction.name = nil
    userAction.icon = nil
    userAction.spellName = nil
end

local function userActionSet(slot, target, name, icon, spellName)
    userActionReset()
    if not slot then return end
    userAction.slot = slot
    userAction.target = target
    userAction.name = name
    userAction.icon = icon
    userAction.spellName = spellName
    c.ShowActionGlow(userAction.slot, 0, 1, 0.8431, 0) -- permanent gold
end
local userActionTimer = 'userAction'
local actionHooks = {}

function c.ActionHook(name, func)
    if type(name) ~= 'string' then error('Имя должно быть строкой', 2) end
    if type(func) ~= 'function' then error('Неверный тип аргумента', 2) end
    actionHooks[name] = func
end

local function hookUseAction(slot, target)
    local name = c.GetSlotName(slot)
    -- похоже пустой слот
    if not name then return end
    local icon = GetActionTexture(slot)
    local isMine = c.SlotIsPressed(slot)
    -- нажат не руками
    if not isMine then return end

    local hook = actionHooks[name]
    if hook then
        c.MessageLog('', name, icon) -- hook
        hook(slot, target)
        -- если уже есть обработчик, игнорируем
        return
    end

    -- макрос без спела
    local spellName = c.GetActionSpell(slot)
    if not spellName then return end

    -- тут бы неплохо проверить, а есть ли у слота вообще кд? Может это макрос без spell и или item которые не usable
    local left = c.GetSlotCooldownLeft(slot)
    local gcdLeft, gcdDuration = c.GetSpellCooldownLeft(c.gcdSpellId)
    local onGcd = left > 0 and (left == gcdLeft)
    local inCast, castLeft = c.UnitCasting('player')
    if not inCast then
        -- спел не на гкд
        if not onGcd then return end
        -- было нажатие и сразу пошло гкд, вероятно нажатие его и запустило
        local ownGCD = onGcd and (gcdDuration - gcdLeft) < c.advance
        -- вероятно спел и запустил гкд
        if ownGCD then return end
    end
    -- а можно ли нажать?
    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable or notEnoughMana then
        c.MessageLog(notEnoughMana and '!mana' or '!usable', name, icon)
        return
    end
    -- а что на счет дистанции?
    if ActionHasRange(slot) and IsActionInRange(slot, target) == 0 then
        c.MessageLog('!range', name, icon)
        return
    end

    if userAction.slot ~= slot then
        -- будем пытаться нажать следующим
        userActionSet(slot, target, name, icon, spellName)
        c.TimerStart(userActionTimer, castLeft or 0)
        c.MessageLog('нажать?', name, icon)
    elseif inCast then
        -- при повторном нажатии отменим текущий каст
        c.MessageLog('повтор -> стопкаст', name, icon)
        c.bUseMacro('/stopcasting')
    end
end
hooksecurefunc('UseAction', hookUseAction)


local function updateUserAction()
    if userAction.slot == nil then
        return
    end
    if c.TimerLess(userAction.spellName, 0.5) then
        c.Message('прожали!', userAction.name, userAction.icon)
        userActionReset()
        return
    end
    if c.TimerMore(userActionTimer, 2) then
        c.Message('не успели!', userAction.name, userAction.icon)
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
    c.bUseAction(userAction.slot, userAction.target)
    c.SkipNextUpdate()
end
c.BeforeUpdate(updateUserAction, true)
