------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
local st = ns.State
------------------------------------------------------------------------------------------------------------------
if st.playerClass ~= 'PALADIN' then return end
------------------------------------------------------------------------------------------------------------------
ns.Chat(st.playerClass, st.playerColor)
------------------------------------------------------------------------------------------------------------------
local GetRuneCooldown = GetRuneCooldown
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local IsCurrentSpell = IsCurrentSpell
local GetRuneType = GetRuneType
local GetTalentInfo = GetTalentInfo
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local IsEquippedItem = IsEquippedItem
local type = type
local math_max = math.max
local format = format
------------------------------------------------------------------------------------------------------------------
local function canUseSpell(spell)
    return IsUsableSpell(spell) and ns.CanUseAction(spell) and not ns.IsSpellFailedRecently(spell)
end
------------------------------------------------------------------------------------------------------------------
local function canUseGcdSpell(spell)
    return not st.gcd and canUseSpell(spell)
end
------------------------------------------------------------------------------------------------------------------
local function canUseItem(item)
    return IsUsableItem(item) and ns.CanUseAction(item)
end
------------------------------------------------------------------------------------------------------------------
local function getHolyAction()
    local action, reason
    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end

    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    action, reason = ns.TryTarget()
    if action then
        return action, reason
    end
    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    action, reason = 'none', 'гкд'
    if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', 'пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------
local function getProtoAction()
    local action, reason

    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end

    -----------------------------------------------
    ns.TimerToggle('needHeal', st.playerHP100 < (st.group and 40 or 60)) -- таймер идет пока hp < 40
    ns.TimerToggle('needMoreDamage', st.ttd > 10)                        -- таймер идет пока ttd > 20
    ns.TimerToggle('still', st.still)
    -----------------------------------------------
    -- hp меньше половины уже 2 секунды
    local needHeal = ns.TimerStarted('needHeal') and ns.TimerMore('needHeal', 1.5) and st.combatMode
    local needMoreDamage = ns.TimerStarted('needMoreDamage') and ns.TimerMore('needMoreDamage', 1)
    local still = ns.TimerStarted('still') and ns.TimerMore('still', 1)
    -- нужно бурстить
    local needBurst = st.targetHard and needMoreDamage --and dancingRuneWeaponReady
    -----------------------------------------------
    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)

    action, reason = 'Аура благочестия', 'аура'
    if not ns.HasMyBuff('Аура') and not ns.HasBuff(action) and canUseSpell(action) then return action, reason end

    action, reason = 'Печать праведности', 'аура'
    if not ns.HasMyBuff('Печать') and canUseSpell(action) then return action, reason end
    -----------------------------------------------

    -- if st.targetImmuneMagic then
    -- end
    -----------------------------------------------


    action, reason = 'Свет небес', 'хилимся'
    if still and needHeal and canUseSpell(action) then return action, reason end

    -----------------------------------------------

    action, reason = ns.TryTarget()
    if action then return action, reason end

    -----------------------------------------------
    --local inMelee = ns.IsSpellInRange('Удар чумы')
    -----------------------------------------------




    action, reason = 'Пламя феникса', 'сало PVP'
    if canUseSpell(action) then return action, reason end

    action, reason = 'Древняя сфера', 'сфера PVE'
    if canUseSpell(action) then return action, reason end


    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    -- action, reason = 'none', 'гкд'
    -- if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', '#пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------
local function getRetributionAction()
    local action, reason
    -- иногда в ротации есть необходимость прерывания своего каста
    action, reason = 'none', 'кастую [%s]'
    if st.playerCasting then return action, format(reason, st.playerCasting) end

    -- тут что-то делаем бафы, хилки, и т.д. (Цели тут может и не быть)
    action, reason = ns.TryTarget()
    if action then
        return action, reason
    end
    -- тут ротацию ишем, можно использовать что можно прожать в гкд
    action, reason = 'none', 'гкд'
    if st.gcd then return action, reason end
    -- то что требует отсутствия гкд
    action, reason = 'none', 'пока всё'
    return action, reason
end
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
local rotations = { getHolyAction, getProtoAction, getRetributionAction }
local rotation
local function updateRotation()
    local spec = 2 --ns.GetCurrentSpecID()
    rotation = rotations[spec]
end
ns.AttachEvent('PLAYER_TALENT_UPDATE', updateRotation)
ns.AttachEvent('ACTIVE_TALENT_GROUP_CHANGED', updateRotation)
function ns.GetAction()
    if type(rotation) ~= 'function' then
        updateRotation()
    end
    return rotation()
end

------------------------------------------------------------------------------------------------------------------
