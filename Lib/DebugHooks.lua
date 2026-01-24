---@class Core
local c = Core
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar

c.ActionHook('aura', function()
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
        local spellId, count, duration, endTime, isMine, isDebuff, level = c.bGetAura(target, idx)
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

c.BeforeUpdate(function()
    local pulse = c.bPulse()
    if not c.IsChanged('Pulse', pulse) then return end
    local msg = pulse and
        WrapTextInColorCode('Система синхронизирована', 'ff13a10e') or
        WrapTextInColorCode('Ожидаем синхронизацию', 'ff3b78ff')
    c.MessageLog(msg, 'Статус', c.iconUpdate)
end, true)

c.ActionHook('test', function()
    print('----------------------')
end)
