------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ... -- namespace
------------------------------------------------------------------------------------------------------------------
local SpellIsTargeting = SpellIsTargeting
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsAFK = UnitIsAFK
local type = type
------------------------------------------------------------------------------------------------------------------
local function getAction()
  if SpellIsTargeting() then
    local info = ns.LastSpellAutoTarget()
    if info == true then
      return 'mouse1_center', 'делаем выбор области под себя' -- left mouse click in center screen
    elseif info == false then
      return 'mouse1', 'делаем выбор области' -- left mouse click
    end
    return 'none', 'ждем выбор области'
  end

  if ns.IsPaused() then
    if ns.State.autoattack then
      return 'stopattack', '#выкл автоатаку - пауза'
    end

    return 'none', '#пауза'
  end

  if UnitIsAFK('player') then
    return 'skip_afk', 'сброс AFK'
  end

  if UnitIsDeadOrGhost('player') then
    return 'none', 'ты мертв'
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

  if ns.State.mount or ns.State.vehicle or ns.HasBuff('Полет') then
    if ns.State.attack then
      return 'dismount', 'спешится, зажата атака'
    end
    return 'none', 'верхом'
  end

  if not ns.State.attack and ns.State.playerEat then
    return 'none', ns.State.playerEat
  end

  if type(ns.GetAction) ~= 'function' then
    return 'none', 'ns.GetAction not a func!'
  end

  return ns.GetAction()
end
------------------------------------------------------------------------------------------------------------------
local stopAttackDebuff = {
  'Паралич',
  'Превращение',
  'Ошеломление',
  'Покаяние',
  'Сон',
  -- 'Соблазн',
  -- 'Страх',
  -- 'Вой ужаса',
  -- 'Устрашающий крик',
  -- 'Контроль над разумом',
  -- 'Глубинный ужас',
  -- 'Ментальный крик'
}
function ns.TryTarget()
  if ns.State.invalidTarget then
    if ns.State.combatMode then
      if ns.State.pvp then
        return 'tarpvp', '#выбор цели-игрока'
      end
      return 'tar', '#выбор цели'
    end

    return 'none', ns.State.invalidTarget
  end

  if not ns.State.attack and not ns.State.combatTarget and not ns.State.autoattack then
    return 'none', 'цель не в бою, не нажата атака, не вкл автоатака'
  end

  local stopDebuff = not ns.State.attack and ns.HasDebuff(stopAttackDebuff)
  if ns.State.autoattack then
    if stopDebuff then
      return 'stopattack', 'не бъем в ' .. stopDebuff
    end
  elseif not stopDebuff then
    return 'startattack', '#автоатака'
  end
  return false, ''
end

------------------------------------------------------------------------------------------------------------------
function ns.Idle()
  ns.UpdateState()
  ns.TogglePause(ns.State.attack, ns.State.stop)
  local action, info = getAction();
  ns.UseAction(action, info)
end

------------------------------------------------------------------------------------------------------------------
--[[
UIParentLoadAddOn('Blizzard_DebugTools');
DevTools_Dump(ns)
]]

--[[
  /run UIParentLoadAddOn('Blizzard_DebugTools');
  /fstack true
  /etrace
]]
------------------------------------------------------------------------------------------------------------------
