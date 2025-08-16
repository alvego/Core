------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local SpellIsTargeting = SpellIsTargeting
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
------------------------------------------------------------------------------------------------------------------
if type(ns.GetAction) ~= 'function' then
  error('GetAction not a func!')
  return
end
------------------------------------------------------------------------------------------------------------------
local function getAction()
  if Paused then
    return 'none', 'пауза'
  end

  if UnitIsDeadOrGhost("player") then
    return 'none', 'ты мертв'
  end

  if SpellIsTargeting() then
    return 'mouse1', 'делаем выбор области' -- left mouse click
  end
  local btn = ns.State.pressedButton
  if btn then
    local btnName = ns.GetSlotName(btn)
    btnName = btnName and ' [' .. btnName .. ']' or ''
    return 'none', 'зажата Button' .. btn .. btnName
  end
  if GetCurrentKeyBoardFocus() then
    return 'none', 'чат'
  end
  if ns.State.mount or ns.State.vehicle then
    if ns.State.attack then
      return 'dismount', 'спешится, зажата атака'
    end
    return 'none', 'верхом'
  end
  if not ns.State.attack and ns.State.playerEat then
    return 'none', ns.State.playerEat
  end
  return ns.GetAction()
end
------------------------------------------------------------------------------------------------------------------
local stopAttackDebuff = { 'Паралич', 'Превращение' }
function ns.TryTarget()
  if ns.State.invalidTarget then
    if ns.State.combatMode or ns.State.attack then
      if ns.State.pvp then
        return 'tarpvp', 'выбор цели-игрока'
      end
      return 'tar', 'выбор цели'
    end

    return 'none', ns.State.invalidTarget
  end

  if not ns.State.attack and not (ns.State.combatTarget or ns.State.autoattack) then
    return 'none', 'цель не в бою, не нажата атака и не вкл автоатака'
  end

  if ns.State.autoattack then
    if not ns.State.attack then
      local debuff = ns.HasDebuff(stopAttackDebuff)
      if debuff then
        return 'stopattack', 'не бъем в ' .. debuff
      end
    end
  else
    return 'startattack', 'автоатака'
  end
  return false, ''
end

------------------------------------------------------------------------------------------------------------------
function ns.Idle()
  ns.UpdateState()
  local action, info = getAction();
  ns.UseAction(action, info)
end

------------------------------------------------------------------------------------------------------------------
--[[
UIParentLoadAddOn("Blizzard_DebugTools");
DevTools_Dump(ns)
]]

--[[
  /run UIParentLoadAddOn("Blizzard_DebugTools");
  /fstack true
  /etrace
]]
------------------------------------------------------------------------------------------------------------------
