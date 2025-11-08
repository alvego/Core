-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local UnitClass = UnitClass
-------------------------------------------------------------------------------
local className = select(2, UnitClass('player'))
-------------------------------------------------------------------------------
if className ~= 'SHAMAN' then return end
-------------------------------------------------------------------------------
c.PrintLoadClassModuleMessage(className)
-------------------------------------------------------------------------------
local st = c.state
local IsMouselooking = IsMouselooking
-------------------------------------------------------------------------------
local function updateEnhance()
    local reason, action, unit

    -------------------------------------------------------------------------------
    -- иногда в ротации есть необходимость прерывания своего каста
    reason = '#cast [%s]'
    if st.playerCasting then return format(reason, st.playerCasting) end

    -------------------------------------------------------------------------------
    reason = c.TryTarget(true, 30, c.attack or IsMouselooking())
    -- есть ли причина для отстановки?
    if reason then return reason end
    -------------------------------------------------------------------------------
    -- Дальше считаем что у нас есть валидная цель
    -------------------------------------------------------------------------------

    reason, action, unit = 'Заплонитель', 'Молния', 'target'
    if c.CanUseGcdSpell(action) then
        c.DoAction(reason, action, unit)
        return reason
    end
    if st.gcd then return '#gcd' end
    return '#none'
end
-------------------------------------------------------------------------------
function c.Update()
    local stopReason = c.GetStopReason()
    if stopReason then
        c.LogWhatHappend(stopReason)
        return
    end
    
    c.LogWhatHappend(updateEnhance())
end

-------------------------------------------------------------------------------
