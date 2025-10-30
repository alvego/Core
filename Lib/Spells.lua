-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetTime = GetTime
local GetSpellLink = GetSpellLink
local GetSpellCooldown = GetSpellCooldown
local IsUsableSpell = IsUsableSpell
local GetSpellTexture = GetSpellTexture
local WrapTextInColorCode = WrapTextInColorCode
local div1000 = 0.001 -- 1 / 1000
local errorBuffer = {}
local wipe = wipe
local type = type
-------------------------------------------------------------------------------
local function pushError(message, spell)
    if not c.showSpellError then return end
    message = message or 'Что-то пошло не так'
    if not spell then
        local _spell = errorBuffer[message]
        spell = type(_spell) == 'string' and spell or true
    end
    errorBuffer[message] = spell
end

-------------------------------------------------------------------------------
function c.UnitCasting(unit)
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
    if left < c.latency then return nil end
    local duration = (endTime - startTime) * div1000
    return spell, left, duration, channel, notInterruptible
end

-------------------------------------------------------------------------------
local spellToIdList = {}
function c.GetSpellId(name, rank)
    local spellGUID = name
    if rank then
        spellGUID = name .. rank
    end
    local result = spellToIdList[spellGUID]
    if nil == result then
        result = 0
        local link = GetSpellLink(name, rank)
        if link then
            result = result + link:match("spell:%d+"):match("%d+")
            spellToIdList[spellGUID] = result
        else
            c.Chat(WrapTextInColorCode('[' .. name .. '] не найден ID', 'ffff0000'))
        end
    end
    return result
end

-------------------------------------------------------------------------------
function c.GetSpellCooldownLeft(spell)
    local start, duration = GetSpellCooldown(spell)
    if start then
        return math.max(0, start + duration - GetTime()), duration
    end
    return 0, 0
end

-------------------------------------------------------------------------------
function c.IsReadySpell(spell)
    return c.GetSpellCooldownLeft(spell) < c.latency
end

-------------------------------------------------------------------------------
function c.IsUsableSpell(spell, unit)
    local usable, _ = IsUsableSpell(spell)
    if not usable then return false end
    if not c.IsReadySpell(spell) then return false end
    if unit ~= nil and not c.IsSpellInRange(spell, unit) then return false end
    return true
end

-------------------------------------------------------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if sourceGUID ~= c.state.playerGUID then return end
    if subEvent:match('^SPELL_CAST') then
        local spellName = select(2, ...)
        c.lastUsedSpell = spellName
        if subEvent == 'SPELL_CAST_FAILED' then
            local message = select(4, ...)
            pushError(message, spellName)
        end
    end
end
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)

local failedSpell = nil
local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if source ~= 'player' then return end

    c.lastUsedSpell = spellName

    if event == 'UNIT_SPELLCAST_SUCCEEDED' then
        if spellName then
            c.TimerStart(spellName)
            if c.showSpellSuccess then
                local spellId = c.GetSpellId(spellName)
                local msg = spellId > 0 and
                    format('%s ID: %s', GetSpellLink(spellId), WrapTextInColorCode(spellId, 'ff71d5ff')) or
                    format('[%s]', spellName)
                c.Success(msg, GetSpellTexture(spellName))
            end
        end
        return
    end

    if event == 'UNIT_SPELLCAST_FAILED' then
        failedSpell = spellName
        c.TimerStart('Fail:' .. failedSpell)
    end
end
c.AttachEvent('UNIT_SPELLCAST_START', onEvent)
c.AttachEvent('UNIT_SPELLCAST_STOP', onEvent)
c.AttachEvent('UNIT_SPELLCAST_FAILED', onEvent)
c.AttachEvent('UNIT_SPELLCAST_DELAYED', onEvent)
c.AttachEvent('UNIT_SPELLCAST_SUCCEEDED', onEvent)
c.AttachEvent('UNIT_SPELLCAST_INTERRUPTED', onEvent)
c.AttachEvent('UNIT_SPELLCAST_CHANNEL_START', onEvent)
c.AttachEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', onEvent)
c.AttachEvent('UNIT_SPELLCAST_CHANNEL_STOP', onEvent)


local function onUIErrorMessage(event, ...)
    if not c.showSpellError then return end
    local action = nil
    if failedSpell and c.TimerLess('Fail:' .. failedSpell, 0.1) then action = failedSpell end
    local message = ...
    pushError(message, action)
end
c.AttachEvent('UI_ERROR_MESSAGE', onUIErrorMessage)

local function onErrorUpdate()
    for message, spellName in pairs(errorBuffer) do
        if type(spellName) == 'string' then
            print()
            local spellId = c.GetSpellId(spellName)
            c.Error(format('%s %s', message, GetSpellLink(spellId) or spellName), GetSpellTexture(spellName))
        else
            c.Error(format('%s', message))
        end
    end
    wipe(errorBuffer)
end
c.AttachBeforeUpdate(onErrorUpdate)


function c.IsSpellFailedRecently(spellName)
    return c.TimerLess('Fail:' .. spellName, 0.2)
end

-- if c.TimerMore('Удар грома', 3) then
--     print('Удар грома не был или был более 3 секунд назад')
-- end

-- if c.TimerLess('Удар грома', 3) then
--     print('Удар грома был и был менее 3 секунд назад')
-- end
-------------------------------------------------------------------------------
