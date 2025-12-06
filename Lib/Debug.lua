-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local GetCVar = GetCVar
local SetCVar = SetCVar
local tinsert = tinsert
local type = type
local error = error
local debug = nil

SetCVar('Sound_EnableErrorSpeech', '0');

function c.Debug()
    if debug == nil then
        debug = GetCVar('scriptErrors') == '1'
    end
    return debug
end

-------------------------------------------------------------------------------
local funcList = {}
function c.UpdateDebugState(func)
    if type(func) ~= 'function' then error('Wrong type') end
    tinsert(funcList, func)
end

-------------------------------------------------------------------------------
local function updateDebugState()
    debug = GetCVar('scriptErrors') == '1'
    if c.IsChanged('Debug', debug) then
        for i = 1, #funcList do
            funcList[i](debug)
        end
    end
end
c.Event('PLAYER_ENTERING_WORLD', updateDebugState)
-------------------------------------------------------------------------------
local function updateDebugStateHook(key, value)
    if key ~= 'scriptErrors' then return end
    updateDebugState()
end
hooksecurefunc('SetCVar', updateDebugStateHook)
-------------------------------------------------------------------------------
function c.DebugHook(funcName)
    hooksecurefunc(funcName, function(...)
        c.Log(funcName, ...)
    end)
end

--c.DebugHook('SetCVar')
--c.DebugHook('ClearTarget')
-------------------------------------------------------------------------------

-- local lastMana = 0

-- c.Event('PLAYER_ENTERING_WORLD', function()
--     lastMana = UnitMana('player')
-- end)

-- c.Event('UNIT_MANA', function(event, unit)
--     if unit ~= 'player' then return end
--     local currentMana = UnitMana('player')
--     local spent = lastMana - currentMana
--     lastMana = currentMana
--     if (spent > 0) then
--         c.Log('#' .. WrapTextInColorCode(format('утекло %s маны', spent), 'ff0000ff'))
--     end
-- end)


-- local f = CreateFrame("Frame")
-- local manaSpent = {}
-- local casts = {}
-- local currentMana = 0
-- local lastSentSpell = nil

-- f:RegisterEvent("PLAYER_LOGIN")
-- f:RegisterEvent("PLAYER_REGEN_DISABLED")
-- f:RegisterEvent("PLAYER_REGEN_ENABLED")
-- f:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
-- f:RegisterUnitEvent("UNIT_MANA", "player")

-- f:SetScript("OnEvent", function(self, event, ...)
--     if event == "PLAYER_LOGIN" then
--         -- Инициализация
--     elseif event == "PLAYER_REGEN_DISABLED" then
--         wipe(manaSpent)
--         wipe(casts)
--         currentMana = UnitMana("player")
--         lastSentSpell = nil
--         -- print("|cFF00FF00ManaSpent: |rОтслеживание начато")
--     elseif event == "PLAYER_REGEN_ENABLED" then
--         local sorted = {}
--         for key, mp in pairs(manaSpent) do
--             local c = casts[key] or 0
--             table.insert(sorted, { key = key, mp = mp, casts = c })
--         end
--         table.sort(sorted, function(a, b) return a.mp > b.mp end)

--         if #sorted == 0 then
--             print("|cFF00FF00ManaSpent: |rМана не тратилась")
--         else
--             print("|cFF00FF00=== Расход маны за бой ===|r")
--             local total_mp = 0
--             for i, data in ipairs(sorted) do
--                 local casts_str = data.casts > 0 and " (" .. data.casts .. ")" or ""
--                 print(i ..
--                     ". " ..
--                     WrapTextInColorCode(data.key, 'ffff8800') ..
--                     casts_str .. " - " .. WrapTextInColorCode(data.mp .. "mp", 'ff0000ff'))
--                 total_mp = total_mp + data.mp
--             end
--             print("|cFF00FF00Итого: |r" ..
--                 WrapTextInColorCode(total_mp .. "mp" .. ' (' .. c.Round(total_mp / UnitManaMax('player') * 100) .. '%)',
--                     'ff0000ff'))
--         end
--     elseif event == "UNIT_SPELLCAST_SENT" then
--         local unit, spellName, rank, castGUID = ...
--         if unit == "player" and spellName then
--             lastSentSpell = { name = spellName, rank = rank or "" }
--         end
--     elseif event == "UNIT_MANA" then
--         local unit = ...
--         if unit == "player" then
--             local newMana = UnitMana("player")
--             local spent = currentMana - newMana
--             if spent > 0 and lastSentSpell then
--                 local key = lastSentSpell.name
--                 if lastSentSpell.rank and lastSentSpell.rank ~= "" then
--                     key = key .. " (" .. lastSentSpell.rank .. ")"
--                 end
--                 manaSpent[key] = (manaSpent[key] or 0) + spent
--                 casts[key] = (casts[key] or 0) + 1
--                 lastSentSpell = nil -- Использовано
--             end
--             currentMana = newMana
--         end
--     end
-- end)
