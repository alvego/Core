-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
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
local IsMouselooking = IsMouselooking
local wipe = wipe
-------------------------------------------------------------------------------
local function updateState()
    wipe(c.stateCache)
    local gameFocus = not GetCurrentKeyBoardFocus()
    st.ctrl = gameFocus and IsControlKeyDown() == 1
    st.alt = gameFocus and IsAltKeyDown() == 1
    st.shift = gameFocus and IsShiftKeyDown() == 1
    st.look = IsMouselooking()
    st.playerGUID = UnitGUID('player')
    st.pressedButton = c.ButtonIsPressed()

    st.playerCasting = c.UnitCasting()
    st.playerHP100 = c.UnitHealth100()
    st.playerMana100 = c.UnitMana100()

    st.existsTarget = UnitExists('target')
    st.ttd = c.UnitTimeToDie('target')
    st.invalidTarget = c.IsInvalidTarget()

    local inInstance, instanceType = IsInInstance()
    st.instance = inInstance ~= nil and instanceType ~= 'pvp' and instanceType ~= 'arena'
    st.battleground = inInstance ~= nil and instanceType == 'pvp'
    st.arena = inInstance ~= nil and instanceType == 'arena'
    st.pvp = st.arena or st.battleground or c.duel or
        (not st.invalidTarget and UnitIsPlayer('target'))
    st.party = GetNumPartyMembers() > 0
    st.raid = GetNumRaidMembers() > 0
    st.group = st.party or st.raid

    st.combatLock = InCombatLockdown()
    c.TimerToggle('combatLock', st.combatLock)
    st.combatTarget = st.existsTarget and UnitAffectingCombat('target')
    st.bossTarget = st.existsTarget and c.UnitIsBoss('target')
    st.targetPlayer = st.existsTarget and UnitIsPlayer('target')

    st.targetImmune = st.invalidTarget or c.UnitIsImmune('target')
    st.targetImmuneMagic = st.targetImmune or c.UnitIsMagicImmune('target')
    st.targetVisible = st.existsTarget and c.UnitInLOS('player', 'target')
    st.targetBehind = st.existsTarget and c.UnitBehind('target')

    if not st.invalidTarget and st.combatTarget then
        c.TimerStart('combatTarget')
    end

    st.autoattack = IsCurrentSpell('Автоматическая атака')
    st.combatMode = c.attack or c.TimerLess('combatTarget', 1)

    st.speed = GetUnitSpeed('player') or 0
    st.falling = IsFalling()
    c.TimerToggle('Falling', st.falling)
    st.still = st.speed == 0 and not st.falling
    st.gcd = not c.IsReadySpell(c.gcdSpellId)
end
c.AttachBeforeUpdate(updateState)
updateState() -- for init
-------------------------------------------------------------------------------
