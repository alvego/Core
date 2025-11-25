-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
-------------------------------------------------------------------------------


-- Константы оффсетов для WoW 3.3.5a (100% точные на 2025 год)

-- local offsets = {}
-- local ignored = {
--     191, -- mouseover
-- }
--local ignored = { 191, 171, 168, 169, 170 }
-- local function findOffset()
--     if UnitExists('target') and UnitIsDead('target') then
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

-- c.AttachBeforeUpdate(findOffset)

-- hooksecurefunc('ClearTarget', function(...)
--     c.Log('ClearTarget', ..., GetTime())
-- end)
local ignored = {}
c.AttachActionHook('test', function()
    -- print(StaticPopup1:IsVisible() == 1, StaticPopup1.text:GetText())
    -- print(StaticPopup1Button1:IsVisible() == 1 and StaticPopup1Button1:IsEnabled() == 1, StaticPopup1Button1:GetText())
    --ChatFrame_OpenChat(StaticPopup1Button1:GetText())

    -- local x, y, z = c.UnitPosition('player')
    -- ChatFrame_OpenChat(c.ToStr(c.Round(x), c.Round(y), c.Round(z)))
end)
