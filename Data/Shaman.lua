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
    local aoe = c.GetEnemyCount(10, 'player') > 2
    local _, _, stacks = c.HasMyBuff('Оружие Водоворота')
    local function HasMagmaTotem()
        local haveTotem, name = GetTotemInfo(1)
        return haveTotem and name == 'Тотем магмы VII'
    end 

    reason, action, unit = 'АОЕшим', 'Цепная молния', 'target'
    if aoe and c.CanUseGcdSpell(action) and stacks == 5 then
        c.DoAction(reason, action, unit)
        return reason
    end


    reason, action, unit = 'Лава по шоку', 'Выброс лавы', 'target'
    if not aoe and c.CanUseGcdSpell(action) and c.HasMyDebuff('Огненный шок', target, 1) and stacks == 5 then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Уплотняем ротацию', 'Молния', 'target'
    if not aoe and c.CanUseGcdSpell(action) and stacks == 5 then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Основной мили удар', 'Удар бури', 'target'
    if c.CanUseGcdSpell(action) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Подбаф расовый', 'Варварский ритуал', 'target'
    if c.CanUseGcdSpell(action) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Второй мили удар', 'Вскипание лавы', 'target'
    if c.CanUseGcdSpell(action) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Поджигаем', 'Огненный шок', 'target'
    if c.CanUseGcdSpell(action) and not c.HasMyDebuff('Огненный шок', target, 1) then
        c.DoAction(reason, action, unit)
        return reason
    end

    reason, action, unit = 'Приземляем', 'Земной шок', 'target'
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
