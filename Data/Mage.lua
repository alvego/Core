------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
if ns.State.playerClass ~= 'MAGE' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(ns.State.playerClass, ns.State.playerColor)
------------------------------------------------------------------------------------------------------------------
local tContains = tContains
local IsUsableSpell = IsUsableSpell

local aoeCast = { "Огненный столб", "Снежная буря" }
local intBuff = { "Чародейская гениальность", "Чародейский интеллект" }
local fireBuff = { "Власть Огня", "Путь огня" }
------------------------------------------------------------------------------------------------------------------
function ns:GetAction()
    local aoe = ns.IsCtr()

    if aoe and ns.State.playerCasting and not tContains(aoeCast, ns.State.playerCasting) then
        return 'stopcast', 'нужно aoe, стопаем: ' .. ns.State.playerCasting
    end

    if ns.State.playerCasting == "Огненная глыба" then
        return 'stopcast', 'только по проку, не кастим: ' .. ns.State.playerCasting
    end

    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end

    ---- AOE

    if aoe then
        if ns.State.lastAction ~= "Огненный столб" then
            return "Огненный столб", 'aoe: поджигаем'
        end
        if ns.State.lastAction ~= "Снежная буря" then
            return "Снежная буря", 'aoe: морозим'
        end
        return 'none', 'нечем болше aoe-шить'
    end


    ---- buffs
    if not ns.State.existsTarget and not ns.State.attack then
        if not ns.HasBuff("Морозный доспех") then
            return "Морозный доспех", 'доспех ннадда'
        end
        if not ns.HasBuff(intBuff) then
            return "Чародейский интеллект", 'обмазываемся интеллектом'
        end
    end


    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end

    local instantFireBuff = ns.HasBuff(fireBuff)
    if instantFireBuff then
        return "Огненная глыба", instantFireBuff
    end

    local force = ns.IsAlt()

    if force then
        if ns.State.pvp then
            if ns.IsReadyAction("Возгорание") then
                return "Возгорание", 'бурст pvp'
            end
        else
            if ns.IsReadyAction("Власть Огня") then
                return "Власть Огня", 'бурст'
            end
        end
    end

    if ns.State.gcd then return 'none', 'гкд' end

    local dist10 = CheckInteractDistance('target', 3) == 1
    local fireSpell = "Огненный шар"

    if not dist10 and ns.State.still and ns.TimerMore(fireSpell, 3) and not ns.HasMyDebuff(fireSpell) and not ns.State.combatTarget then
        return fireSpell, 'пока не сагрил, можно что-то долгое кастануть'
    end

    if IsUsableSpell("Живая бомба") and ns.TimerMore("Живая бомба", 2) and not ns.HasMyDebuff("Живая бомба") then
        return "Живая бомба", 'вешаем бомбу'
    end

    local scorch = ns.HasDebuff("Улучшенный ожог", 'target', 1)

    if not ns.State.pvp and ns.CanUseAction("Реактивный снаряд") then
        return "Реактивный снаряд", 'рпг'
    end

    if ns.CanUseAction("Огненный взрыв") then
        return "Огненный взрыв", 'взрываем'
    end

    if dist10 and not ns.State.still then
        if (ns.State.speed > 0 and ns.State.speed < 7) and ns.CanUseAction("Конус холода") then
            return "Конус холода", 'продувка по курсу'
        end
        if ns.CanUseAction("Кольцо льда") then
            return "Кольцо льда", 'подмараживаем по кругу'
        end
        if ns.CanUseAction("Чародейский взрыв") then
            return "Чародейский взрыв", 'слив маны'
        end
    end
    if ns.State.still and not scorch and ns.TimerMore("Ожог", 2) then
        return "Ожог", 'наладываем улучшенный ожог'
    end

    if ns.State.still then
        return fireSpell, 'дамажим'
    end

    return 'none', 'чё делать то?'
end

------------------------------------------------------------------------------------------------------------------
