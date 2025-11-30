-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
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
local type = type
local tostring = tostring
local SpellHasRange = SpellHasRange
local GetSpellIDByName = GetSpellIDByName
local ConsoleExec = ConsoleExec
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
function c.GetSpellId(name, rank, skipError)
    local fullName = name
    if rank then
        fullName = name .. " (" .. rank .. ")" -- ruRU формат
    end
    local result = spellToIdList[fullName]
    if nil == result then
        if GetSpellIDByName then
            result = GetSpellIDByName(fullName)
        else
            local link = GetSpellLink(name, rank)
            if link then
                result = tonumber(link:match("spell:%d+"):match("%d+") or 0)
            end
        end

        if type(result) ~= 'number' or result <= 0 then
            result = 0
            if not skipError then
                c.Chat(WrapTextInColorCode('[' .. name .. '] не найден ID', 'ffff0000'))
            end
        end
        spellToIdList[fullName] = result
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
function c.CanUseSpell(spell, unit)
    if spell == nil or type(spell) ~= 'string' then
        return false, '!spell ' .. tostring(spell)
    end
    local isUsable, notEnoughMana = IsUsableSpell(spell)
    if not isUsable or notEnoughMana then
        return false, notEnoughMana and '!mana' or '!usable'
    end
    if unit ~= nil and SpellHasRange(spell) and not c.IsSpellInRange(spell, unit) then
        return false, '!range'
    end
    if not c.IsReadySpell(spell) then
        return false, '!ready'
    end
    return true
end

-------------------------------------------------------------------------------
function c.DoSpell(reason, spell, target)
    if type(reason) ~= 'string' then
        c.Error(format('DoSpell: reason required! - [%s]', c.ToStr(reason, spell, target)))
        return
    end
    if type(spell) ~= 'string' then
        c.Error(format('DoSpell: spell required! - [%s]', c.ToStr(reason, spell, target)))
        return
    end
    c.LogWhatHappend(reason, true)
    local canuse, canuseinfo = c.CanUseSpell(spell, target)
    if not canuse then
        c.MessageLog(format('#%s - [%s]', reason, canuseinfo), spell, GetSpellTexture(spell))
        return
    end
    local targetName = target and UnitName(target) or nil
    if targetName then reason = reason .. ' ' .. c.UnitInfo(target) end
    c.ClearCursor()
    c.Message(reason, spell, GetSpellTexture(spell))
    ConsoleExec('Sound_EnableSFX 0')
    c.Spell(spell, target)
    ConsoleExec('Sound_EnableSFX 1')
    st.lastSpell = spell
end
