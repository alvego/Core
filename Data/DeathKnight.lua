------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
if ns.State.playerClass ~= 'DEATHKNIGHT' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(ns.State.playerClass, ns.State.playerColor)
------------------------------------------------------------------------------------------------------------------
local function getBloodAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if ns.State.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return '', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local function getFrostAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if ns.State.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return '', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local function getUncholyAction()
    if ns.State.playerCasting then -- возможно стоит перенести в ротацию (прерывание каста)
        return 'none', 'кастую [' .. ns.State.playerCasting .. ']'
    end
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    local tarcmd, tarinfo = ns.TryTarget()
    if tarcmd then
        return tarcmd, tarinfo
    end
    -- тут ротацию ишем, можно испольовать что можно прожвать в гкд
    if ns.State.gcd then return 'none', 'гкд' end
    -- то что требуется гкд
    return '', 'пока всё'
end
------------------------------------------------------------------------------------------------------------------
local rotations = { getBloodAction, getFrostAction, getUncholyAction }
function ns:GetAction()
    local spec = ns.GetCurrentSpecID()
    return rotations[spec]()
end
