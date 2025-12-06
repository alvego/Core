-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
local SetRaidTarget = SetRaidTarget
local GetRaidTargetIndex = GetRaidTargetIndex
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local type = type
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
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

c.AfterUpdate(function()
    if c.busy then return end
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
    PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
    local raidTargetIdx = 4
    if GetRaidTargetIndex(unit) ~= raidTargetIdx then SetRaidTarget(unit, raidTargetIdx) end
    c.Echo('Найден ' .. c.UnitInfo('target'))
    if UnitCanAttack('player', 'target') and not st.mounted then
        c.TimerStart('attack')
    end
    c.TurnToUnit(unit)
end)
