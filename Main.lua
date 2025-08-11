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
    return 'none', 'paused'
  end

  if UnitIsDeadOrGhost("player") then
    return 'none', 'RIP'
  end

  if SpellIsTargeting() then
    return 'mouse1', 'spell targeting' -- left mouse click
  end
  local btn = ns.State.pressedButton
  if btn then
    return 'none', btn .. ' pressed'
  end
  if GetCurrentKeyBoardFocus() then
    return 'none', 'chat'
  end
  if ns.State.mount or ns.State.vehicle then
    if ns.State.attack then
      return 'dismount', 'mount attack'
    end
    return 'none', 'mount'
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
        return 'tarpvp', 'select pvp target'
      end
      return 'tar', 'select target'
    end

    return 'none', ns.State.invalidTarget
  end

  if not ns.State.attack and not ns.State.combatTarget then
    return 'none', 'target !combat & !attack'
  end

  if ns.State.autoattack then
    if not ns.State.attack then
      local debuff = ns.HasDebuff(stopAttackDebuff)
      if debuff then
        return 'stopattack', '!attack ' .. debuff
      end
    end
  else
    return 'startattack', 'attack'
  end
  return false, ''
end

------------------------------------------------------------------------------------------------------------------
function ns.Idle()
  ns.UpdateState()
  ns.UpdateLog()
  local action, info = getAction();
  ns.UseAction(action, info)
  ns.UpdateTelemetry()
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
