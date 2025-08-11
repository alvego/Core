------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local UnitGUID = UnitGUID
local GetCVar = GetCVar
local IsMounted = IsMounted
local CanExitVehicle = CanExitVehicle
local IsInInstance = IsInInstance
local hooksecurefunc = hooksecurefunc
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitIsPlayer = UnitIsPlayer
local UnitExists = UnitExists
local InCombatLockdown = InCombatLockdown
local UnitAffectingCombat = UnitAffectingCombat
local IsCurrentSpell = IsCurrentSpell
local GetUnitSpeed = GetUnitSpeed
local IsFalling = IsFalling
------------------------------------------------------------------------------------------------------------------
ns.State = {}
ns.State.debug = true

local playerClass, playerColor = ns.UnitClassName()
ns.State.playerClass = playerClass
ns.State.playerColor = playerColor
ns.State.playerGUID = UnitGUID('player')

local eatBuff = { "Пища", "Питье" }

local function startDuel()
    ns.State.duel = true
end
hooksecurefunc("StartDuel", startDuel);

local function duelUpdate(event)
    ns.State.duel = event == 'DUEL_REQUESTED'
end
ns.AttachEvent('DUEL_REQUESTED', duelUpdate)
ns.AttachEvent('DUEL_FINISHED', duelUpdate)

------------------------------------------------------------------------------------------------------------------
function ns.UpdateState()
    ns.State.debug = GetCVar('scriptErrors') == '1'
    ns.State.attack = ns.IsMouse(4)
    ns.State.stop = ns.IsMouse(5)
    ns.State.pressedButton = ns.ButtonIsPressed()
    ns.State.mount = IsMounted()
    ns.State.vehicle = CanExitVehicle()
    ns.State.playerCasting = ns.UnitCasting()
    ns.State.playerEat = ns.HasBuff(eatBuff)
    ns.State.playerHP100 = ns.UnitHealth100()
    ns.State.playerMana100 = ns.UnitMana100()
    ns.State.existsTarget = UnitExists('target')
    ns.State.invalidTarget = ns.IsInvalidTarget()

    local inInstance, instanceType = IsInInstance()
    ns.State.instance = inInstance ~= nil and instanceType ~= "pvp" and instanceType ~= "arena"
    ns.State.battleground = inInstance ~= nil and instanceType == "pvp"
    ns.State.arena = inInstance ~= nil and instanceType == "arena"
    ns.State.pvp = ns.State.arena or ns.State.battleground or ns.State.duel or
        (not ns.State.invalidTarget and UnitIsPlayer('target'))
    ns.State.party = GetNumPartyMembers() > 0
    ns.State.raid = GetNumRaidMembers() > 0
    ns.group = ns.State.party or ns.State.raid

    ns.State.combatLock = InCombatLockdown()
    ns.State.combatTarget = UnitAffectingCombat('target')

    if not ns.State.invalidTarget and ns.State.combatTarget then
        ns.TimerStart('CombatTarget')
    end

    ns.State.combatMode = ns.State.combatLock or ns.TimerLess('CombatTarget', 2)
    ns.State.autoattack = IsCurrentSpell('Автоматическая атака')

    ns.State.speed = GetUnitSpeed('player')
    ns.State.still = ns.State.speed == 0 and not IsFalling()

    if Paused then
        if ns.State.attack then
            ns.Echo('Attack')
            Paused = false
        end
    else
        if ns.State.stop then
            ns.Echo('Stop')
            Paused = true
        end
    end
end

------------------------------------------------------------------------------------------------------------------
-- local function onEvent(event, ...)
--     if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
--         local _, eventType, sourceGUID, sourceName, _, destGUID, destName, _, spellId, spellName = select(
--             1, ...)
--         if (sourceGUID == ns.State.playerGUID and eventType:match("^SPELL_CAST")) then
--             --print(eventType, sourceName, destName, spellName)
--             ns.State.lastUsed = spellName
--         end
--         return
--     end
-- end
-- ns.AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', onEvent)
