-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local GetLootMethod = GetLootMethod
local GetCVar = GetCVar
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitCreatureType = UnitCreatureType
local SpellIsTargeting = SpellIsTargeting
local LootFrame = LootFrame
local tinsert = tinsert
local wipe = wipe
local tContains = tContains
-------------------------------------------------------------------------------

local function checkCorpseForLoot(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > 5 then return end -- so far
    local name = UnitName(unit)
    local ptr = c.UnitPtr(unit)
    local canLoot = c.ReadByte(ptr, 168) ~= 0
    if not canLoot then return end -- can't loot
    return unit
end


local skinList = {}
local skinTimer = 'skinTimer';

local function checkCorpseForSkin(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > 8 then return end -- so far
    local ptr = c.UnitPtr(unit)
    local canLoot = c.ReadByte(ptr, 168) ~= 0
    if canLoot then return end -- can't loot
    local creatureType = UnitCreatureType(unit)
    if creatureType ~= "Животное" then return end
    if tContains(skinList, unit) then return end
    return unit
end

-------------------------------------------------------------------------------
c.AttachBeforeUpdate(function()
    if c.Paused() then return end
    if c.TimerLess('Loot', 0.5) then return end

    if c.TimerStarted(skinTimer) and c.TimerMore(skinTimer, 60) then wipe(skinList) end
    if LootFrame:IsVisible() then return end
    if st.playerCasting or st.gcd then return end
    if st.group and (GetLootMethod() ~= 'freeforall') then return end
    if c.GetBagsFreeSlots() < 1 then return end
    if st.combatMode then return end
    if GetCVar('autoLootDefault') ~= '1' then return end

    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if corpse then
        c.Message('Лутаем', UnitName(corpse))
        c.UnitClick(corpse, true)
        c.SkipNextUpdate()
        c.TimerStart('Loot')
        return
    end
    local spell = 'Снятие шкур'
    if not IsUsableSpell(spell) then return end

    corpse = c.FindValue(c.GetUnits(), checkCorpseForSkin)
    if corpse then
        c.DoAction('Скальпируем', spell, corpse)
        tinsert(skinList, corpse)
        c.TimerStart(skinTimer)
        c.SkipNextUpdate()
        c.TimerStart('Loot', 1)
        return
    end
end)
