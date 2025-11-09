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
local canLoot = c.GetCachedFunc(function(unit)
    local ptr = c.UnitPtr(unit)
    return c.ReadByte(ptr, 168) ~= 0
end)

local function checkCorpseForLoot(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > 5 then return end -- so far
    if not canLoot(unit) then return end                  -- can't loot
    return unit
end

local canSkin = c.GetCachedFunc(function(unit)
    local creatureType = UnitCreatureType(unit)
    return creatureType == 'Животное' and not canLoot(unit)
end)

local skinList = {}
local skinTimer = 'skinTimer';

local function checkCorpseForSkin(unit)
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    if c.UnitDistance('player', unit) > 8 then return end -- so far
    if not canSkin(unit) then return end                  -- can't skin
    if tContains(skinList, unit) then return end
    return unit
end


local _corpse, _dist = nil, 0
local function checkCorpse(unit)
    if not UnitExists(unit) then return end
    if not UnitExists(unit) then return end
    if not UnitIsDead(unit) then return end
    if UnitIsPlayer(unit) then return end
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then return end
    if tContains(skinList, unit) then return end
    if not (canLoot(unit) or canSkin(unit)) then return end
    if not c.UnitInLOS(unit) then return end
    local dist = c.UnitDistance('player', unit)
    if dist < 5 or dist > 40 then return end
    if not _corpse or not _dist or dist < _dist then
        _corpse = unit
        _dist = dist
    end
end

local function getNearCorpse()
    _corpse, _dist = nil, 0
    c.FindValue(c.GetUnits(), checkCorpse)
    return _corpse
end
-------------------------------------------------------------------------------

c.AttachBeforeUpdate(function()
    if c.Paused() then return end
    if c.TimerLess('Loot', 0.5) then return end

    if c.TimerStarted(skinTimer) and c.TimerMore(skinTimer, 2) then wipe(skinList) end
    if LootFrame:IsVisible() then return end
    if st.playerCasting or st.gcd or st.mounted then return end
    if st.group and (GetLootMethod() ~= 'freeforall') then return end
    if c.GetBagsFreeSlots() < 1 then return end
    if st.combatMode then return end
    if GetCVar('autoLootDefault') ~= '1' then return end

    local corpse = c.FindValue(c.GetUnits(), checkCorpseForLoot)
    if corpse then
        c.Message(c.UnitInfo(corpse), 'Лутаем')
        c.UnitClick(corpse, true)
        c.SkipNextUpdate()
        c.TimerStart('Loot')
        return
    end

    if not st.still then return end
    local spell = 'Снятие шкур'
    if not IsUsableSpell(spell) then return end
    corpse = c.FindValue(c.GetUnits(), checkCorpseForSkin)
    if corpse then
        -- c.Message(c.UnitInfo(corpse), 'Свежуем')
        -- c.UnitClick(corpse, true)
        c.DoAction('Свежуем', spell, corpse)
        tinsert(skinList, corpse)
        c.TimerStart(skinTimer)
        c.SkipNextUpdate()
        c.TimerStart('Loot', 2)
        return
    end

    if not c.canMove then return end
    if st.look then return end
    corpse = getNearCorpse()
    if corpse and c.PlayerMove(corpse, 40) then
        c.TimerStart('Loot', 3)
    end
end)
