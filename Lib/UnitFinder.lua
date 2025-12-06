-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
local SetRaidTarget = SetRaidTarget
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local type = type
-------------------------------------------------------------------------------
local unitName, unit, dist
c.ActionHook('tar', function()
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then return end
    local name = editBox:GetText()
    if type(name) ~= 'string' or name == '' then
        if unitName ~= nil then
            unitName = nil
            c.Echo('Поиск остановлен')
        end
        return
    end
    editBox:SetText('')
    editBox:ClearFocus()
    c.Echo('Поиск ' .. name)
    unitName = name
end)

local function checkByName(u)
    if not UnitExists(u) then return end
    local name = UnitName(u)
    if not name then return end
    if not c.StrContains(name, unitName) then return end
    local d = c.UnitDistance('player', u)
    if dist < d then return end
    unit = u
    dist = d
end

c.BeforeUpdate(function()
    if not unitName then return end
    if st.targetExists then return end
    if st.combatMode then return end
    if c.TimerLess('LookUnit', 1) then return end
    c.TimerStart('LookUnit')
    unit = nil
    dist = 999
    local units = c.GetUnits()
    for i = 1, #units do
        checkByName(units[i])
    end
    if not unit then return end
    c.Command('/target ' .. unit)
    SetRaidTarget(unit, 8)
    c.TurnToUnit(unit)
end)

-- Константы оффсетов для WoW 3.3.5a (100% точные на 2025 год)

-- local offsets = {}
-- local ignored = {
--     191, -- mouseover
-- }
--local ignored = { 191, 171, 168, 169, 170 }
-- local function findOffset()
--     if UnitExists('target') and UnitIsDeadOrGhost('target') then
--         --if UnitExists('target') then
--         local ptr = c.UnitPtr('target')
--         local line = false
--         -- print('test8', c.ReadByte(ptr, 168)) --171
--         --if true then return end
--         for i = 1, 300 do
--             if not tContains(ignored, i) then
--                 local data = c.ReadByte(ptr, i)

--                 if offsets[i] ~= data then
--                     if offsets[i] ~= nil then
--                         if not line then
--                             line = true
--                             print('-----------------------------------------------')
--                         end
--                         print('#' .. i, offsets[i], '!=', data)
--                     end

--                     offsets[i] = data
--                     --break
--                 end
--             end
--         end
--     end
-- end

-- c.BeforeUpdate(findOffset)

-- hooksecurefunc('ClearTarget', function(...)
--     c.Log('ClearTarget', ..., GetTime())
-- end)
local ignored = {}
c.ActionHook('test', function()
    -- print(StaticPopup1:IsVisible() == 1, StaticPopup1.text:GetText())
    -- print(StaticPopup1Button1:IsVisible() == 1 and StaticPopup1Button1:IsEnabled() == 1, StaticPopup1Button1:GetText())
    --ChatFrame_OpenChat(StaticPopup1Button1:GetText())

    -- local x, y, z = c.UnitPosition('player')
    -- ChatFrame_OpenChat(c.ToStr(c.Round(x), c.Round(y), c.Round(z)))
    --c.LookAtUnit('target')
    --c.LookAtUnit(c.GetUnitID('target'))
    --c.hasSkinTooltip(c.GetUnitID('target'))
end)
