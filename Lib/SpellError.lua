-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local GetSpellLink = GetSpellLink
local GetSpellTexture = GetSpellTexture
local WrapTextInColorCode = WrapTextInColorCode
local errorBuffer = {}
local wipe = wipe
local type = type
local tContains = tContains
-------------------------------------------------------------------------------
local function pushError(message, spell)
    message = message or 'Что-то пошло не так'
    if not spell then
        local _spell = errorBuffer[message]
        spell = type(_spell) == 'string' and spell or true
    end
    errorBuffer[message] = spell
end
-------------------------------------------------------------------------------
local function onCombatLogEvent(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName,
                                destFlags, ...)
    if sourceGUID ~= st.playerGUID then return end
    if subEvent:match('^SPELL_CAST') then
        local spellName = select(2, ...)
        st.lastUsedSpell = spellName
        if subEvent == 'SPELL_CAST_FAILED' then
            local message = select(4, ...)
            pushError(message, spellName)
        end
    end
end
c.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)
-------------------------------------------------------------------------------
local failedSpell = nil
local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if source ~= 'player' then return end

    st.lastUsedSpell = spellName

    if event == 'UNIT_SPELLCAST_SUCCEEDED' then
        if spellName then
            c.TimerStart(spellName)
            if c.flags.fullLog then
                local spellId = c.GetSpellId(spellName, nil, true)
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
-------------------------------------------------------------------------------

local function onUIErrorMessage(event, ...)
    local action = nil
    if failedSpell and c.TimerLess('Fail:' .. failedSpell, 0.1) then action = failedSpell end
    local message = ...
    pushError(message, action)
end
c.AttachEvent('UI_ERROR_MESSAGE', onUIErrorMessage)

-------------------------------------------------------------------------------
local skipErrors = {
    'Заклинание пока недоступно.',
    'Еще не готово.'
}
-------------------------------------------------------------------------------
local function onErrorUpdate()
    for message, spellName in pairs(errorBuffer) do
        if not tContains(skipErrors, message) then
            if type(spellName) == 'string' then
                local spellId = c.GetSpellId(spellName, nil, true)
                c.Error(format('%s %s', message, GetSpellLink(spellId) or spellName), GetSpellTexture(spellName))
            else
                c.Error(format('%s', message))
            end
        end
    end
    wipe(errorBuffer)
end
c.AttachBeforeUpdate(onErrorUpdate)
-------------------------------------------------------------------------------

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
