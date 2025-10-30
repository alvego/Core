-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local UnitGUID = UnitGUID
local IsMounted = IsMounted
local CanExitVehicle = CanExitVehicle
local IsInInstance = IsInInstance
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitIsPlayer = UnitIsPlayer
local UnitExists = UnitExists
local InCombatLockdown = InCombatLockdown
local UnitAffectingCombat = UnitAffectingCombat
local IsCurrentSpell = IsCurrentSpell
local GetUnitSpeed = GetUnitSpeed
local IsFalling = IsFalling
local wipe = wipe
-------------------------------------------------------------------------------
local function updateState()
    wipe(c.stateCache)
    local gameFocus = not GetCurrentKeyBoardFocus()
    c.state.ctrl = gameFocus and IsControlKeyDown() == 1
    c.state.alt = gameFocus and IsAltKeyDown() == 1
    c.state.shift = gameFocus and IsShiftKeyDown() == 1

    c.state.playerGUID = UnitGUID('player')
    c.state.pressedButton = c.ButtonIsPressed()

    c.state.playerCasting = c.UnitCasting()
    c.state.playerHP100 = c.UnitHealth100()
    c.state.playerMana100 = c.UnitMana100()

    c.state.existsTarget = UnitExists('target')
    c.state.ttd = c.UnitTimeToDie('target')
    c.state.invalidTarget = c.IsInvalidTarget()

    local inInstance, instanceType = IsInInstance()
    c.state.instance = inInstance ~= nil and instanceType ~= 'pvp' and instanceType ~= 'arena'
    c.state.battleground = inInstance ~= nil and instanceType == 'pvp'
    c.state.arena = inInstance ~= nil and instanceType == 'arena'
    c.state.pvp = c.state.arena or c.state.battleground or c.duel or
        (not c.state.invalidTarget and UnitIsPlayer('target'))
    c.state.party = GetNumPartyMembers() > 0
    c.state.raid = GetNumRaidMembers() > 0
    c.state.group = c.state.party or c.state.raid

    c.state.combatLock = InCombatLockdown()
    c.TimerToggle('combatLock', c.state.combatLock)
    c.state.combatTarget = c.state.existsTarget and UnitAffectingCombat('target')
    c.state.bossTarget = c.state.existsTarget and c.UnitIsBoss('target')
    c.state.targetPlayer = c.state.existsTarget and UnitIsPlayer('target')

    c.state.targetImmune = c.state.invalidTarget or c.UnitIsImmune('target')
    c.state.targetImmuneMagic = c.state.targetImmune or c.UnitIsMagicImmune('target')
    c.state.targetVisible = c.state.existsTarget and c.UnitInLOS('player', 'target')
    c.state.targetBehind = c.state.existsTarget and c.UnitBehind('target')

    if not c.state.invalidTarget and c.state.combatTarget then
        c.TimerStart('combatTarget')
    end

    c.state.autoattack = IsCurrentSpell('Автоматическая атака')
    c.state.combatMode = c.attack or c.TimerLess('combatTarget', 1)

    c.state.speed = GetUnitSpeed('player') or 0
    c.state.falling = IsFalling()
    c.TimerToggle('Falling', c.state.falling)
    c.state.still = c.state.speed == 0 and not c.state.falling
    c.state.gcd = not c.IsReadySpell(c.gcdSpellId)
end
c.AttachBeforeUpdate(updateState)
updateState() -- for init
-------------------------------------------------------------------------------
