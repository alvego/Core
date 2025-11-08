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

-- local offsets = {}
-- local ignored = { 168, 169 }
-- --local ignored = { 191, 171, 168, 169, 170 }
-- local function findOffset()
--     --if UnitExists('target') and UnitIsDead('target') then
--     if UnitExists('target') then
--         local ptr = c.UnitPtr('target')

--         print('-----------------------------------------------')
--         -- print('test8', c.ReadByte(ptr, 168)) --171
--         --if true then return end
--         for i = 1, 300 do
--             if not tContains(ignored, i) then
--                 local data = c.ReadByte(ptr, i)

--                 if offsets[i] ~= data then
--                     if offsets[i] ~= nil then
--                         print('#' .. i, offsets[i], '!=', data)
--                     end

--                     offsets[i] = data
--                     --break
--                 end
--             end
--         end
--     end
-- end

c.AttachActionHook('test', function()
    -- print(IsSpellTarget)
end)


--c.AttachBeforeUpdate(findOffset)
