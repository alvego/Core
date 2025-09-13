------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local name, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local _G = _G
local ActionHasRange = ActionHasRange
local format = format
local wipe = wipe
local error = error
local GetMacroInfo = GetMacroInfo
local GetActionInfo = GetActionInfo
local GetSpellInfo = GetSpellInfo
local GetItemInfo = GetItemInfo
local GetCompanionInfo = GetCompanionInfo
local GetActionTexture = GetActionTexture
------------------------------------------------------------------------------------------------------------------
function ns.GetSlotName(slot)
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
    return name
end

------------------------------------------------------------------------------------------------------------------
local actions = {}
local updateActions = function()
    wipe(actions)
    for slot = 1, 120 do -- 12 x 10
        local name = ns.GetSlotName(slot)
        if name then
            actions[name] = slot
        end
    end
end
ns.AttachEvent('ACTIONBAR_SLOT_CHANGED', updateActions)
ns.AttachEvent('PLAYER_ENTERING_WORLD', updateActions)


------------------------------------------------------------------------------------------------------------------
local actionsCD = {}
local function hook_SetCooldown(self, start, duration)
    local parent = self:GetParent()
    if not parent then return end
    local name = parent:GetName()
    if not name then return end
    actionsCD[name] = start + duration
end
hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', hook_SetCooldown)
------------------------------------------------------------------------------------------------------------------
function ns.GetSlotCooldownLeft(slot)
    if not slot then return 0 end
    local cd = actionsCD['BT4Button' .. slot]
    return cd and (cd - GetTime()) or 0
end

------------------------------------------------------------------------------------------------------------------
function ns.CanUseSlot(slot)
    if slot == nil then
        return false, 'not set'
    end
    if slot == 0 or slot > 120 then -- не проверяем кастомные слоты
        return true, ''
    end
    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable or notEnoughMana then
        return false, notEnoughMana and '!mana' or '!usable'
    end
    if ActionHasRange(slot) and IsActionInRange(slot) == 0 then
        return false, '!range'
    end
    if ns.GetSlotCooldownLeft(slot) > ns.State.latency then
        return false, '!ready'
    end
    return true, ''
end

------------------------------------------------------------------------------------------------------------------
function ns.GetSlot(action)
    if action == 'none' then
        return 0
    end
    if not action then
        ns.Error('Неверное действие. Используй none для бездействия.');
        return 0
    end
    if action == 'mouse1' then
        return 1000 -- left mouse click
    end
    if action == 'mouse1_center' then
        return 1001 -- left mouse click in center screen
    end
    if action == 'skip_afk' then
        return 2000 -- Skip AFK state
    end
    local slot = actions[action]
    if not slot then
        ns.Error('Не могу найти на панели [' .. action .. ']');
        return 0
    end
    return slot
end

------------------------------------------------------------------------------------------------------------------
local function formatIcon(icon)
    return icon and '|T' .. icon .. ':24:24:0:0|t' or '       '
end

function ns.ActionLog(icon, action, info, hex)
    if string.sub(info, 1, 1) == "#" then
        return -- игнорируем комментарии
    end
    ns.DebugChatNoSpam(format('%s [%s] %s', formatIcon(icon), action or '...', info or '???'), hex or 'FFFFFF')
end

------------------------------------------------------------------------------------------------------------------
local lastSlot = 0
local lastAction = nil
function ns.UseAction(action, info)
    if action == nil then
        error(format('ns.UseAction(%s, %s) - action can be string', action or 'nil', info or 'nil'))
    end
    if info == nil then
        ns.Error(format('ns.UseAction(%s, %s) - can have info!', action or 'nil', info or 'nil'))
    end
    local slot = ns.GetSlot(action)
    local canuse, canuseinfo = ns.CanUseSlot(slot)


    if action == 'none' then
        if ns.showNoneReason then
            ns.ActionLog(nil, action, info, '888888')
        end
    elseif not canuse then
        ns.ActionLog(nil, action, info .. ' ' .. canuseinfo, 'ff8888')
        slot = 0
    end

    if lastSlot ~= slot then
        lastSlot = slot
        ns.Semaphore(slot)
        if slot ~= 0 and slot <= 120 then -- 12 * 10
            local icon = GetActionTexture(slot)
            ns.ActionLog(icon, action, info, '00BFFF')
            lastAction = action
        end
    end
end

function ns.GetLastAction()
    return lastAction
end

------------------------------------------------------------------------------------------------------------------
function ns.IsReadyAction(action)
    local slot = ns.GetSlot(action)
    return ns.GetSlotCooldownLeft(slot) < ns.State.latency
end

------------------------------------------------------------------------------------------------------------------
function ns.CanUseAction(action)
    local slot = ns.GetSlot(action)
    return ns.CanUseSlot(slot)
end

------------------------------------------------------------------------------------------------------------------
function ns.ButtonIsPressed()
    for i = 1, 120 do -- 12 x 10
        local btn = _G['BT4Button' .. i]
        if btn and btn:GetButtonState() == 'PUSHED' and lastSlot ~= i then
            lastAction = ns.GetSlotName(i)
            return i
        end
    end
    return nil
end

------------------------------------------------------------------------------------------------------------------
