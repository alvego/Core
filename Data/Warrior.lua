------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
if ns.State.playerClass ~= 'WARRIOR' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(ns.State.playerClass, ns.State.playerColor)
------------------------------------------------------------------------------------------------------------------
local function getSpec1Action()
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
local function getSpec2Action()
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
local function getSpec3Action()
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
local rotations = { getSpec1Action, getSpec2Action, getSpec3Action }
function ns:GetAction()
    local spec = ns.GetCurrentSpecID()
    local rotation = rotations[spec]
    return rotation()
end

------------------------------------------------------------------------------------------------------------------
