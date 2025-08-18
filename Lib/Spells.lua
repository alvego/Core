------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetTime = GetTime
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellLink = GetSpellLink
local IsSpellInRange = IsSpellInRange
local GetSpellCooldown = GetSpellCooldown
local IsUsableSpell = IsUsableSpell
local UnitLevel = UnitLevel
local math_random = math.random
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
function ns.UnitNeedKick(unit, kickByStun) -- cбивалка, проверяет название, сбиваемость и время сбивания
    unit = unit or 'target'
    if kickByStun and UnitLevel(unit) == -1 then return false end
    local spell, left, duration, channel, notinterrupt = ns.UnitCasting(unit)
    if not spell then return false end
    if not notinterrupt and not kickByStun then return false end

    if left < 0.1 then return false end
    local salt = math_random() * 0.3                            -- [0 .. 0.3]
    if channel then
        if left > duration * (0.9 - salt) then return false end -- нет смысла, еще больше 60% .. 90% каста
    else
        if left > duration * (0.1 + salt) then return false end -- нет смысла, еще больше 10% .. 40% каста
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
local bookSpellIds = {}
local function refreshBookSpells()
    local bookType = 'spell'
    local maxIndex = 0
    local maxTabs = GetNumSpellTabs()
    for i = 1, maxTabs do
        local _, _, offs, numspells, _, specId = GetSpellTabInfo(i)
        if specId == 0 then
            maxIndex = offs + numspells
        end
    end

    for spellBookId = 1, maxIndex do
        local spellType, baseSpellID = GetSpellBookItemInfo(spellBookId, bookType)

        if spellType == 'SPELL' then
            local currentSpellName = GetSpellBookItemName(spellBookId, bookType)
            local link = GetSpellLink(currentSpellName)
            local currentSpellID = tonumber(link and link:gsub('|', '||'):match('spell:(%d+)'))

            if currentSpellName and not bookSpellIds[currentSpellName] then
                bookSpellIds[currentSpellName] = spellBookId
            end
            if currentSpellID and not bookSpellIds[currentSpellID] then
                bookSpellIds[currentSpellID] = spellBookId
            end

            if baseSpellID then
                local baseSpellName = GetSpellInfo(baseSpellID)
                if baseSpellName and not bookSpellIds[baseSpellName] then
                    bookSpellIds[baseSpellName] = spellBookId
                end
                if not bookSpellIds[baseSpellID] then
                    bookSpellIds[baseSpellID] = spellBookId
                end
            end
        end
    end
end
ns.AttachEvent('SPELLS_CHANGED', refreshBookSpells)
ns.AttachEvent('PLAYER_ENTERING_WORLD', refreshBookSpells)

function ns.IsSpellInRange(spell, unit)
    if next(bookSpellIds) == nil then refreshBookSpells() end
    if spell == nil then return false end
    if unit == nil then unit = 'target' end
    local inRange = IsSpellInRange(spell, unit)
    if inRange == nil then
        local spellBookId = bookSpellIds[spell]
        if spellBookId then
            return IsSpellInRange(spellBookId, 'spell', unit) == 1
        end
    end
    return inRange == 1
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
        ns.TimerStart(spellName)
        if subEvent == 'SPELL_CAST_FAILED' then
            local reason = select(4, ...)
            ns.ActionLog(nil, spellName or 'Ошибка', reason or 'Что-то пошло не так', '880000')
        end
    end
end
ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onCombatLogEvent)

local failedSpell = nil
local function onEvent(event, ...)
    local source, spellName = select(1, ...)
    if source ~= 'player' then return end
    ns.TimerStart(spellName)
    lastUsedSpell = spellName
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
