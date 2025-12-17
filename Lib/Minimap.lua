-------------------------------------------------------------------------------
-- Core by Unknown Coder
-------------------------------------------------------------------------------
---@class Core
local c = Core
-------------------------------------------------------------------------------
local EasyMenu = EasyMenu
local Minimap = Minimap
local GameTooltip = GameTooltip
local PlaySound = PlaySound
local tinsert = tinsert
local type = type
local error = error
local ReloadUI = ReloadUI
local SetCVar = SetCVar
local GetCVar = GetCVar
local WrapTextInColorCode = WrapTextInColorCode
--local ForceQuit = ForceQuit
-------------------------------------------------------------------------------
-- Инициализация
local minimapDropDown = CreateFrame('Frame', 'CoreMinimapDropDown', UIParent, 'UIDropDownMenuTemplate') -- Фрейм для выпадающего меню

-- Создание кнопки у миникарты
local button = CreateFrame('Button', 'CoreMinimapButton', Minimap)
button:SetSize(32, 32) -- Размер кнопки
button:SetFrameStrata('MEDIUM')
button:SetFrameLevel(8)
button:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 0, 0) -- Позиция (можно изменить, например, на 'BOTTOMRIGHT' для другого места)
-- Фон кнопки (круглый, как у стандартных мини-карт кнопок)
local bg = button:CreateTexture(nil, 'BACKGROUND')
bg:SetTexture([[Interface\Minimap\UI-Minimap-Background]])
bg:SetAllPoints()
bg:SetVertexColor(1, 1, 1, 0.6) -- Полупрозрачный фон
-- Иконка кнопки (замените на вашу текстуру, если нужно)
local icon = button:CreateTexture(nil, 'ARTWORK')
icon:SetTexture(c.icon)                         -- Пример иконки; замените на свою
icon:SetSize(20, 20)
icon:SetPoint('CENTER', button, 'CENTER', 0, 0) -- Легкий сдвиг для вида

-- Добавьте это после создания highlight (или в конец создания текстур кнопки)
local border = button:CreateTexture(nil, 'BORDER')
border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
border:SetSize(54, 54)                               -- Размер бордера (стандартный для WoW: больше кнопки для 'рамки')
border:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1) -- Сдвиг для центрирования бордера вокруг кнопки

-- Хайлайт при наведении
local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
highlight:SetTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
highlight:SetBlendMode('ADD')
highlight:SetAllPoints()

button:SetScript('OnEnter', function(self)
  GameTooltip:SetOwner(self, 'ANCHOR_LEFT') -- Можно 'ANCHOR_TOP', 'ANCHOR_BOTTOM' и т.д.
  -- Заголовок (жирным)
  GameTooltip:AddLine(c.name, 0, 1, 0)      -- белый цвет
  -- Описание действий
  GameTooltip:AddLine(' ')
  GameTooltip:AddLine('ЛКМ — открыть меню переключателей', 0.5, 0.8, 1) -- голубоватый
  GameTooltip:AddLine('СКМ — список хлама (junk list)', 1, 0.8, 0.2) -- оранжевый
  GameTooltip:AddLine('ПКМ — быстрые действия', 0.5, 0.8, 1) -- голубоватый
  GameTooltip:AddLine(' ')
  GameTooltip:AddLine('Зажмите ЛКМ и тяните — переместить кнопку', 0.6, 0.6, 0.6)
  GameTooltip:Show()
end)

button:SetScript('OnLeave', function()
  GameTooltip:Hide()
end)
local lootIcon = [[Interface\Icons\Ability_Racial_PackHobgoblin]]
local moveIcon = [[Interface\Icons\Spell_Priest_PathofDevout]]
local logIcon = [[Interface\Icons\ability_vehicle_shellshieldgenerator_s_white]]
local debugIcon = [[Interface\Icons\ability_vehicle_shellshieldgenerator_s_blue]]
local delJunkIcon = [[Interface\Icons\Spell_Mage_ConjuredManaBuns]]
local autoLookIcon = [[Interface\Icons\Ability_Hunter_SniperShot]]
local autoMeleeIcon = [[Interface\Icons\Ability_SteelMelee]]
local flagFunc = function(btn)
  local flag = btn.value
  if not flag then return end
  c.flags[flag] = not c.flags[flag] -- toggle flag
end
local debugFunc = function(btn)
  SetCVar('scriptErrors', GetCVar('scriptErrors') == '1' and 0 or 1)
end


local menu = {
  LeftButton = {
    { text = 'Переключатели', isTitle = true, notCheckable = true },
    { text = '', notCheckable = true, isSeparator = true },
    {
      text = 'Пауза',
      value = 'paused',
      icon = c.icon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Отладка',
      value = 'debug',
      icon = debugIcon,
      func = debugFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Подробные #логи',
      value = 'fullLog',
      icon = logIcon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Сбор добычи с мобов',
      value = 'loot',
      icon = lootIcon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Движение игрока',
      value = 'move',
      icon = moveIcon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Aвтоудаление хлама',
      value = 'autoDelJunk',
      icon = delJunkIcon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Всегда лицом в ближнем бою',
      value = 'autoLook',
      icon = autoLookIcon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    {
      text = 'Цели ближнего боя',
      value = 'autoMelee',
      icon = autoMeleeIcon,
      func = flagFunc,
      checked = true,
      notCheckable = false,
      isNotRadio = true
    },
    { text = '', notCheckable = true, isSeparator = true },
    { text = 'Закрыть', notCheckable = true, func = function() end },
  },
  MiddleButton = {}, -- обновляем при открытии
  RightButton = {
    { text = 'Быстрые действия', isTitle = true, notCheckable = true },
    { text = '', notCheckable = true, isSeparator = true },
    {
      text = 'Выкинуть хлам (junk) из сумок',
      icon = delJunkIcon,
      notCheckable = true,
      func = function() c.RemoveJunk() end
    },
    {
      text = 'Вывод аур цели',
      icon = [[Interface\Icons\Ability_Priest_HeavanlyVoice]],
      notCheckable = true,
      func = function() c.PrintTargetAuras() end
    },
    {
      text = 'Перезагрузить UI',
      icon = [[Interface\Icons\Ability_Creature_Cursed_04]],
      notCheckable = true,
      func = function() ReloadUI() end
    },
    { text = '', notCheckable = true, isSeparator = true },
    { text = 'Закрыть', notCheckable = true, func = function() end },
  }
}
local updateFlagMenu = function(flagMenu)
  if (next(flagMenu) ~= nil) then
    for _, item in pairs(flagMenu) do
      if item.notCheckable == false and item.value then
        if item.value == 'debug' then
          item.checked = GetCVar('scriptErrors') == '1'
        else
          item.checked = c.flags[item.value]
        end
      end
    end
  end
end

local junkIcon = [[Interface\TargetingFrame\UI-RaidTargetingIcon_7]]
local junkFunc = function(btn)
  if not c.db.junk then return end
  local itemName = btn.value
  if not itemName then return end
  c.MessageLog(format('%s %s', WrapTextInColorCode('удалено из списка хлама', 'ff00ff00'), itemName), 'Хлам',
    junkIcon)
  c.db.junk[itemName] = nil -- remove from junk list
end
local updateJunkMenu = function(junkMenu)
  if (next(junkMenu) ~= nil) then
    -- Возвращаем все таблицы в пул перед очисткой junkMenu
    for _, item in pairs(junkMenu) do
      c.TablePoolRelease(item)
    end
    wipe(junkMenu)
  end
  -- заголовок
  local item = c.TablePoolAcquire()
  item.text = 'Cписок хлама (junk list)'
  item.isTitle = true
  item.notCheckable = true -- Без чекбоксов
  tinsert(junkMenu, item)
  -- разделитель
  item = c.TablePoolAcquire()
  item.text = ''
  item.isSeparator = true
  item.notCheckable = true
  tinsert(junkMenu, item)

  local needSep = false

  if c.db.junk then
    for itemName in pairs(c.db.junk) do
      if itemName then
        item = c.TablePoolAcquire()
        item.text = itemName
        item.icon = junkIcon
        item.func = junkFunc
        item.notCheckable = true -- Без чекбоксов
        tinsert(junkMenu, item)

        needSep = true
      end
    end
  end
  -- разделитель, если были предметы
  if needSep then
    item = c.TablePoolAcquire()
    item.text = ''
    item.isSeparator = true
    item.notCheckable = true
    tinsert(junkMenu, item)
  end
  -- закрыть
  item = c.TablePoolAcquire()
  item.text = 'Закрыть'
  item.notCheckable = true -- Без чекбоксов
  item.func = function() end
  tinsert(junkMenu, item)
end

button:RegisterForClicks('LeftButtonDown', 'MiddleButtonDown', 'RightButtonDown', 'Button4Down', 'Button5Down');

-- Обработка клика: открытие меню
button:SetScript('OnClick', function(self, btn, ...)
  if btn == 'LeftButton' then
    updateFlagMenu(menu.LeftButton)
  elseif btn == 'MiddleButton' then
    updateJunkMenu(menu.MiddleButton)
  end

  -- Показываем меню у курсора
  EasyMenu(menu[btn], minimapDropDown, self, 0, 0, 'MENU')
  PlaySound('igMainMenuOptionCheckBoxOn') -- звук, как у стандартных кнопок
end)

-- Опционально: сделать кнопку перетаскиваемой (для удобства пользователя)
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForDrag('LeftButton')
button:SetScript('OnDragStart', function(self) self:StartMoving() end)
button:SetScript('OnDragStop', function(self) self:StopMovingOrSizing() end)
-------------------------------------------------------------------------------
