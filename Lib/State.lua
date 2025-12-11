-------------------------------------------------------------------------------
-- Core by Unknown Coder
-------------------------------------------------------------------------------
---@class Core
local c = Core
---@class Core.state
local st = c.state
-------------------------------------------------------------------------------
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local UnitGUID = UnitGUID
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
local UnitIsAFK = UnitIsAFK
local IsMounted = IsMounted
local CanExitVehicle = CanExitVehicle
-------------------------------------------------------------------------------
local mountAuras = {
    311563, -- Магический пузырь
    32556   -- Полет
}
-------------------------------------------------------------------------------
local function updateState()
    wipe(c.stateCache)
    local gameFocus = not GetCurrentKeyBoardFocus()
    st.ctrl = gameFocus and IsControlKeyDown() == 1
    st.alt = gameFocus and IsAltKeyDown() == 1
    st.shift = gameFocus and IsShiftKeyDown() == 1
    st.look = IsMouselooking()
    st.mount = IsMounted()
    st.vehicle = CanExitVehicle()
    st.mountAura = c.UnitAuraByID('player', mountAuras)
    st.mounted = st.mount or st.vehicle or st.mountAura
    st.playerGUID = UnitGUID('player')
    st.pressedButton = c.ButtonIsPressed()

    st.playerCasting = c.UnitCasting()
    st.playerHP100 = c.UnitHealth100()
    st.playerMana100 = c.UnitMana100()

    st.targetExists = UnitExists('target')
    st.ttd = c.UnitTimeToDie('target')
    st.invalidTarget = c.IsInvalidTarget()

    local inInstance, instanceType = IsInInstance()
    st.instance = inInstance ~= nil and instanceType ~= 'pvp' and instanceType ~= 'arena'
    st.battleground = inInstance ~= nil and instanceType == 'pvp'
    st.arena = inInstance ~= nil and instanceType == 'arena'
    st.pvp = st.arena or st.battleground or st.duel or
        (not st.invalidTarget and UnitIsPlayer('target'))
    st.party = GetNumPartyMembers() > 0
    st.raid = GetNumRaidMembers() > 0
    st.group = st.party or st.raid

    st.combatLock = InCombatLockdown()
    c.TimerToggle('combatLock', st.combatLock)
    st.targetCombat = st.targetExists and UnitAffectingCombat('target')
    st.targetBoss = st.targetExists and c.UnitIsBoss('target')
    st.targetPlayer = st.targetExists and UnitIsPlayer('target')
    st.targetMelee = st.targetExists and c.InMelee('target')
    st.targetImmune = st.invalidTarget or c.UnitIsImmune('target')
    st.targetImmuneMagic = st.targetImmune or c.UnitIsMagicImmune('target')
    st.targetVisible = st.targetExists and c.UnitInLOS('player', 'target')
    st.targetBehind = st.targetExists and c.UnitBehind('target')

    if not st.invalidTarget and st.targetCombat then
        c.TimerStart('targetCombat')
    end

    st.autoattack = IsCurrentSpell('Автоматическая атака')
    st.combatMode = st.attack or c.TimerLess('targetCombat', c.updateDelay * 2)

    st.speed = GetUnitSpeed('player') or 0
    st.falling = IsFalling()
    c.TimerToggle('falling', st.falling)
    c.TimerToggle('still', st.speed == 0 and not st.falling and not st.move and not c.IsMoveUnit())
    st.still = c.TimerStarted('still') and c.TimerMore('still', 0.5)
    st.afk = UnitIsAFK('player') == 1 and c.TimerStarted('still') and c.TimerMore('still', 60)
    st.targetSpeed = GetUnitSpeed('target') or 0
    c.TimerToggle('targetStill', st.targetExists and st.targetSpeed == 0)
    st.targetStill = c.TimerStarted('targetStill') and c.TimerMore('targetStill', 0.55)
    st.gcd = not c.IsReadySpell(c.gcdSpellId)
end
c.BeforeUpdate(updateState, true)
updateState() -- for init
-------------------------------------------------------------------------------
c.Event('PLAYER_REGEN_DISABLED', function()
    c.TimerStart('targetCombat')
end)
