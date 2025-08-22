------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetTime = GetTime
local GetSpellLink = GetSpellLink
local GetSpellCooldown = GetSpellCooldown
local IsUsableSpell = IsUsableSpell
local div1000 = 0.001 -- 1 / 1000
------------------------------------------------------------------------------------------------------------------
function ns.UnitCasting(unit)
    unit = unit or 'player'
    local channel = false
    local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(
        unit)
    if not spell then
        spell, rank, displayName, icon, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
        if not spell then return false end
        channel = true
    end
    if spell == nil or not startTime or not endTime then return nil end
    local left = endTime * div1000 - GetTime()
    if left < ns.State.latency then return nil end
    local duration = (endTime - startTime) * div1000
    return spell, left, duration, channel, notInterruptible
end

------------------------------------------------------------------------------------------------------------------
local spellToIdList = {}
function ns.GetSpellId(name, rank)
    local spellGUID = name
    if rank then
        spellGUID = name .. rank
    end
    local result = spellToIdList[spellGUID]
    if nil == result then
        local link = GetSpellLink(name, rank)
        if not link then
            result = 0
        else
            result = 0 + link:match("spell:%d+"):match("%d+")
        end
        spellToIdList[spellGUID] = result
    end
    return result
end

------------------------------------------------------------------------------------------------------------------
function ns.getSpellCooldownLeft(spell)
    local start, duration = GetSpellCooldown(spell)
    if start then
        return math.max(0, start + duration - GetTime())
    end
    return 0
end

------------------------------------------------------------------------------------------------------------------
function ns.IsReadySpell(spell)
    return ns.getSpellCooldownLeft(spell) < ns.State.latency
end

------------------------------------------------------------------------------------------------------------------
function ns.IsUsableSpell(spell, unit)
    local usable, _ = IsUsableSpell(spell)
    if not usable then return false end
    if not ns.IsReadySpell(spell) then return false end
    if unit ~= nil and not ns.IsSpellInRange(spell, unit) then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
local lastUsedSpell = nil
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if sourceGUID ~= ns.State.playerGUID then return end
    if subEvent:match('^SPELL_CAST') then
        local spellName = select(2, ...)
        lastUsedSpell = spellName
        if ns.showSpellError and subEvent == 'SPELL_CAST_FAILED' then
            local reason = select(4, ...)
            ns.ActionLog(nil, spellName or 'Ошибка', reason or 'Что-то пошло не так', 'AA0000')
        end
    end
end
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)

local failedSpell = nil
local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if source ~= 'player' then return end

    lastUsedSpell = spellName
    if event == 'UNIT_SPELLCAST_SUCCEEDED' then
        if ns.showSpellSuccess then
            ns.DebugChat('>>>>[' .. spellName .. '] - успешно', '00FF00')
        end
        ns.TimerStart(spellName)
        return
    end

    if event == 'UNIT_SPELLCAST_FAILED' then
        failedSpell = spellName
        ns.TimerStart('failedSpell')
    end
end
ns.AttachEvent('UNIT_SPELLCAST_START', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_STOP', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_FAILED', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_DELAYED', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_SUCCEEDED', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_INTERRUPTED', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_CHANNEL_START', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', onEvent)
ns.AttachEvent('UNIT_SPELLCAST_CHANNEL_STOP', onEvent)


local function onUIErrorMessage(event, ...)
    if not ns.showSpellError then return end
    local action = 'Ошибка'
    if failedSpell and ns.TimerLess('failedSpell', 0.5) then action = failedSpell end
    local message = ...
    ns.ActionLog(nil, action, message or 'Что-то пошло не так', '880000')
end
ns.AttachEvent('UI_ERROR_MESSAGE', onUIErrorMessage)


function ns.LastUsedSpell()
    return lastUsedSpell
end

-- if ns.TimerMore('Удар грома', 3) then
--     print('Удар грома не был или был более 3 секунд назад')
-- end

-- if ns.TimerLess('Удар грома', 3) then
--     print('Удар грома был и был менее 3 секунд назад')
-- end


------------------------------------------------------------------------------------------------------------------
