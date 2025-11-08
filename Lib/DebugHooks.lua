-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local GetCVar = GetCVar
local SetCVar = SetCVar
-------------------------------------------------------------------------------
c.AttachActionHook('aura', function() -- for debug
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
end)

-------------------------------------------------------------------------------
c.AttachActionHook('debug', function()
    SetCVar("scriptErrors", GetCVar("scriptErrors") == "1" and 0 or 1)
end)

-------------------------------------------------------------------------------
c.AttachActionHook('log', function()
    c.showSpellSuccess = not c.showSpellSuccess
    c.showSpellError = not c.showSpellError
    c.showNoneReason = not c.showNoneReason
end)

-------------------------------------------------------------------------------
c.AttachActionHook('test', function()
    local spell = 'Снятие шкур'
    --    print(1)
    c.DoAction('test', spell, 'target')
    c.ClearCursor()
end)
