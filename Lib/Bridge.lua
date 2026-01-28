---@class Core
local c = Core -- luacheck: ignore -- luacheck: ignore
-- luacheck: push ignore
local SecondsToTime = SecondsToTime
local UnitGUID = UnitGUID
-- luacheck: pop
---@alias bCmdName "Pulse"
---|"Test"
---|"UnitPosition"
---|"UnitDistance"
---|"UnitFacing"
---|"UnitBehind"
---|"UnitInView"
---|"UnitInLoS"
---|"UnitClick"
---|"UseLua"
---|"UseMacro"
---|"UseSpell"
---|"UseAction"
---|"UseGUID"
---|"TargetUnit"
---|"PlayerMoveTo"
---|"PlayerMoveStop"
---|"PlayerLookAt"
---|"FindObject"
---|"ObjectExists"
---|"ObjectInfo"
---|"CheckBobber"
---|"FindCorpse"
---|"FindUnits"
---|"FindUnit"
---|"FindExecuteTarget"
---|"GetEnemyCount"
---|"InRange"
---|"InMelee"
---|"FindTarget"
---|"UnitAura"
---|"GetAura"
---|"HasAura

---Command Alias
---@param name bCmdName имя команды моста
---@param ... any? зависит от команды
---@return ... зависит от команды
local cmd = function(name, ...)
    ---@diagnostic disable-next-line
    return GetBillingTimeRested(name, ...) -- luacheck: ignore
end

---Легкая обертка с подменой `mouseover`
---@param unitGUID string|nil нужный GUID
---@param callback function функция обработчик `mouseover` - принимает `token` = `"mouseover"`) первым агрументом.
---@param ... any? будет проброшено в `callback` после `token`
---@return any? result первый возвращаемый результат работы callback
function c.bWithGUID(unitGUID, callback, ...)
    local token = "mouseover"
    local tokenGUID = UnitGUID(token)
    if unitGUID == tokenGUID then
        return callback(token, ...)
    end
    c.bUseGUID(unitGUID, token)
    local result = callback(token, ...)
    c.bUseGUID(tokenGUID, token)
    return result
end

---Состояние: синхронизирован ли мост
local bConnected = false
---Подключен ли мост (вызывать после `Pulse`)
---@return boolean isConnected `true` - мост синхронизирован
function c.bConnected()
    return bConnected
end

---Команда для проверки работоспособности моста (`Heartbeat`).
---Обновляет кэш `ObjectManager`.
---Следует вызывать единожды в начале общего `onUpdate`
---@return boolean isConnected `true` если мост подключен
function c.bPulse()
    local pulse = cmd('Pulse')
    bConnected = type(pulse) == 'boolean' and pulse
    return bConnected
end

---Для тестирования (временно)
function c.bTest(...)
    if not bConnected then return end
    return cmd('Test', ...)
end

---Возвращает позицию юнита
---@param unitID? UnitToken Default = 'player' (поддерживает unitGUID)
---@return number x Default = 0
---@return number y Default = 0
---@return number z Default = 0
function c.bUnitPosition(unitID)
    if not bConnected then return 0, 0, 0 end
    return cmd('UnitPosition', unitID)
end

---Возвращает дистанцию между юнита (Collision Distance).
---@param unitID1? UnitToken Default = '' (поддерживает unitGUID)
---@param unitID2? UnitToken Default = 'player' (поддерживает unitGUID)
---@return number distance Default = 99999
function c.bUnitDistance(unitID1, unitID2)
    if not bConnected then return 99999 end
    return cmd('UnitDistance', unitID1, unitID2)
end

---Возвращает направление взгляда юнита (в радианах).
---@param unitID? UnitToken Default = 'target' (поддерживает unitGUID)
---@return number facing Default = 0 [0 .. 2*PI]
function c.bUnitFacing(unitID)
    if not bConnected then return 0 end
    return cmd('UnitFacing', unitID)
end

---Проверяет, находится ли `player` за спиной у указанного юнита.
---@param unitID? UnitToken Default = 'target' (поддерживает unitGUID)
---@return boolean isBehind Default = false
function c.bUnitBehind(unitID)
    if not bConnected then return false end
    return cmd('UnitBehind', unitID)
end

---Проверяет, находится ли юнит в секторе обзора `player`.
---@param unitID? UnitToken Default = 'target' (поддерживает unitGUID)
---@param angleDegrees? number Default = 90 (Угол зрения в градусах)
---@return boolean isInView Default = false
function c.bUnitInView(unitID, angleDegrees)
    if not bConnected then return false end
    return cmd('UnitInView', unitID, angleDegrees)
end

---Возвращает правду если unit в прямой видимости player.
---На линии взгляда (LoS -> Line of Sight) нет препятствий.
---@param unitID1? UnitToken Default = 'target' (поддерживает unitGUID)
---@param unitID2? UnitToken Default = 'player' (поддерживает unitGUID)
---@return boolean isInLoS Default = false
function c.bUnitInLoS(unitID1, unitID2)
    if not bConnected then return false end
    return cmd('UnitInLoS', unitID1, unitID2)
end

---Выбирает юнита как цель заклинания(AOE) или взаимодействует, если задан второй параметр
---@param unitID? UnitToken Default = 'player' (поддерживает unitGUID)
---@param interact? boolean Default = false (если задан, то взаимодействует)
---@return nil
function c.bUnitClick(unitID, interact)
    if not bConnected then return end
    return cmd('UnitClick', unitID, interact)
end

---Выполняет Lua код (защищенный)
---@param luaScript? string Default = ''
---@return nil
function c.bUseLua(luaScript)
    if not bConnected then return end
    return cmd('UseLua', luaScript)
end

---Выполняет строку макроса
---@param macroLine? string Default = ''
---@return nil
function c.bUseMacro(macroLine)
    if not bConnected then return end
    return cmd('UseMacro', macroLine)
end

---Каст спела в цель
---@param spellName? string Default = ''
---@param unitID? UnitToken Default = '' (Не поддерживает unitGUID)
---@return nil
function c.bUseSpell(spellName, unitID)
    if not bConnected then return end
    return cmd('UseSpell', spellName, unitID)
end

---Используем слот на юнита левой кнопкой мыши
---@param slot? number|string Default = ''
---@param unitID? UnitToken Default = '' (Не поддерживает unitGUID)
---@return nil
function c.bUseAction(slot, unitID)
    if not bConnected then return end
    return cmd('UseAction', slot, unitID)
end

---Используем unitGUID на как unitID.
---Например "0xF130..." как "mouseover".
---@param unitGUID? string Default = '0x0'
---@param token? "mouseover"|"focus"|"target" Default = 'mouseover'
---@return nil
function c.bUseGUID(unitGUID, token)
    if not bConnected then return end
    return cmd('UseGUID', unitGUID, token)
end

---Выбор в цели
---@param unitID? UnitToken Default = '' (поддерживает unitGUID)
---@return nil
function c.bTargetUnit(unitID)
    if not bConnected then return end
    return cmd('TargetUnit', unitID)
end

---Двигаться к точке (0, 0, 0 - не валидная точка)
---@param x? number Default = 0
---@param y? number Default = 0
---@param z? number Default = 0
---@return nil
function c.bPlayerMoveTo(x, y, z)
    if not bConnected then return end
    return cmd('PlayerMoveTo', x, y, z)
end

---Останавливаем движение
---@return nil
function c.bPlayerMoveStop()
    if not bConnected then return end
    return cmd('PlayerMoveStop')
end

---Смотри на юнита ("none" для прекращения)
---@param unitID? UnitToken Default = 'none' (поддерживает unitGUID)
---@return nil
function c.bPlayerLookAt(unitID)
    if not bConnected then return end
    return cmd('PlayerLookAt', unitID)
end

---Поиск ближайшего GameObject по имени или части имени
---@param partOfName? string Default = '' (по пустой строке искать не будет)
---@return string|nil unitGUID
---@return string|nil unitName
---@return number|nil x найденого объекта
---@return number|nil y найденого объекта
---@return number|nil z игрока
---@return number|nil range расстояние
function c.bFindObject(partOfName)
    if not bConnected then return end
    return cmd('FindObject', partOfName)
end

---Поиск ближайшего GameObject по имени или части имени
---@param unitID? UnitToken Default = 'none' (поддерживает unitGUID)
---@return boolean exists in ObjectManager cache
function c.bObjectExists(unitID)
    if not bConnected then return false end
    return cmd('ObjectExists', unitID)
end

---Поиск ближайшего GameObject по имени или части имени
---@param unitID? UnitToken Default = 'none' (поддерживает unitGUID)
---@return string|nil unitGUID
---@return string|nil unitName
---@return number|nil x найденого объекта
---@return number|nil y найденого объекта
---@return number|nil z игрока
---@return number|nil range расстояние
function c.bObjectInfo(unitID)
    if not bConnected then return end
    return cmd('ObjectInfo', unitID)
end

---Проверить поплавок, true если подсекли.
---@return boolean isSuccess взаимодействуем c поплавком
function c.bCheckBobber()
    if not bConnected then return false end
    return cmd('CheckBobber')
end

---Поиск ближайшего подходящего трупа для обыска или снятия шкур (Взаимодействие возможно, если range: 0 - обыск, 5 - снятие шкур)
---@param range? number Default = -1 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@param skining? boolean Default = false (`true` подходит для снятия шкур, иначе для обыска)
---@param minMaxHP? number Default = 20 (фильтр по maxHP <= minMaxHP, `-1` отключен)
---@return string|nil unitGUID
function c.bFindCorpse(range, skining, minMaxHP)
    if not bConnected then return nil end
    return cmd('FindCorpse', range, skining, minMaxHP)
end

---Поиск юнитов.
---filterMask:
---IsAlive = 0,
---CanAttack = 1,
---IsInCombat = 2,
---IsCasting = 4,
---TargetingMe = 8,
---NotTargetingMe = 16.
---NotTappedByOther = 32.
---InLoS = 64.
---@param units table - таблица в которую будут записаны строки `unitGUID` найденных юнитов (используй wipe() перед вызовом!)
---@param range? number Default = -1 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@param filterMask? number Default = 0 - (маска для фильтрации)
---@param minMaxHP? number Default = 20 (фильтр по maxHP <= minMaxHP, `-1` отключен)
---@return number count количество найденных и добавленных в таблицу юнитов
function c.bFindUnits(units, range, filterMask, minMaxHP)
    if not bConnected then return 0 end
    return cmd('FindUnits', units, range, filterMask, minMaxHP)
end

---Поиск юнита.
---filterMask:
---IsAlive = 0,
---CanAttack = 1,
---IsInCombat = 2,
---IsCasting = 4,
---TargetingMe = 8,
---NotTargetingMe = 16.
---NotTappedByOther = 32.
---InLoS = 64.
---@param range? number Default = -1 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@param filterMask? number Default = 0 - (маска для фильтрации)
---@param minMaxHP? number Default = 20 (фильтр по maxHP <= minMaxHP, `-1` отключен)
---@return string|nil unitGUID
function c.bFindUnit(range, filterMask, minMaxHP)
    if not bConnected then return nil end
    return cmd('FindUnit', range, filterMask, minMaxHP)
end

---Поиск ближайшего подходящего для добивания юнита (фаза казни)
---@param range? number Default = 30 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@param hpPercent? number Default = 20 фильтр по текущему % hp (hp100 < hpPercent)
---@param minMaxHP? number Default = 20 (фильтр по maxHP <= minMaxHP, `-1` отключен)
---@return string|nil unitGUID
function c.bFindExecuteTarget(range, hpPercent, minMaxHP)
    if not bConnected then return nil end
    return cmd('FindExecuteTarget', range, hpPercent, minMaxHP)
end

---Количество целей в радиусе вокруг unitID (с фильтром по min maxHP)
---@param range? number Default = 0 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@param unitID? UnitToken Default = 'player' (поддерживает unitGUID)
---@param minMaxHP? number Default = 20 (фильтр по maxHP <= minMaxHP, `-1` отключен)
---@return number count количество найденных юнитов
function c.bGetEnemyCount(range, unitID, minMaxHP)
    if not bConnected then return 0 end
    return cmd('GetEnemyCount', range, unitID, minMaxHP)
end

---В радиусе, с учетом коллизий (как спелы)
---@param unitID? UnitToken Default = 'target' (поддерживает unitGUID)
---@param range? number Default = 0 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@return boolean isInRange в радиусе
function c.bInRange(unitID, range)
    if not bConnected then return false end
    return cmd('InRange', unitID, range)
end

---В радиусе ближнего боя
---@param unitID? UnitToken Default = 'target' (поддерживает unitGUID)
---@return boolean isInMelee в радиусе
function c.bInMelee(unitID)
    if not bConnected then return false end
    return cmd('InMelee', unitID)
end

---Поиск ближайшей подходящей цели
---@param range? number Default = 0 `range < 0` без ограничений, `range = 0` радиус ближнего боя, `range > 0` фильтр с учетом хитбоксов
---@param angle? number Default = 0 Угол зрения в градусах, 0 - без ограничений
---@param unitGUID? string Default = nil фильтр по unitGUID
---@param forceAttack? boolean Default = false разрешает брать цели не в бою
---@param minMaxHP? number Default = 20 (фильтр по maxHP <= minMaxHP, `-1` отключен)
---@return string|nil unitGUID подходящая цель
function c.bFindTarget(range, angle, unitGUID, forceAttack, minMaxHP)
    if not bConnected then return nil end
    return cmd('FindTarget', range, angle, unitGUID, forceAttack, minMaxHP)
end

---Возвращает информацию об ауре юнита по индексу
---@param unitID? string Default = '' (поддерживает unitGUID)
---@param index? number Default = 0 разрешает брать цели не в бою
---@return number|nil spellID 0 - пропуск, nil - конец списка
---@return number|nil count stack количество
---@return number|nil duration длительность
---@return number|nil endTime время окончания
---@return boolean|nil isMine это моя аура
---@return boolean|nil isDebuff это негативный эффект
---@return boolean|nil level уровень кастера?
function c.bUnitAura(unitID, index)
    if not bConnected then return nil end
    return cmd('UnitAura', unitID, index)
end

---Возвращает информацию об ауре юнита по auraID
---@param unitID? string Default = '' (поддерживает unitGUID)
---@param auraFilter? number|string|table Default = 0 ищет по auraID|partOfName или по таблице c auraID|partOfName
---@param mineOnly? boolean Default = false ищет только мои
---@return number|nil spellID 0 - пропуск, nil - конец списка
---@return number|nil count stack количество
---@return number|nil duration длительность
---@return number|nil endTime время окончания
---@return boolean|nil isMine это моя аура
---@return boolean|nil isDebuff это негативный эффект
---@return boolean|nil level уровень кастера?
function c.bGetAura(unitID, auraFilter, mineOnly)
    if not bConnected then return nil end
    return cmd('GetAura', unitID, auraFilter, mineOnly)
end

---Проверка наличия ауры у юнита по auraID
---@param unitID? string Default = '' (поддерживает unitGUID)
---@param auraFilter? number|string|table Default = 0 ищет по auraID|partOfName или по таблице c auraID|partOfName
---@param mineOnly? boolean Default = false ищет только мои
---@return boolean found
function c.bHasAura(unitID, auraFilter, mineOnly)
    if not bConnected then return false end
    return cmd('HasAura', unitID, auraFilter, mineOnly)
end

function c.CheckBridge()
    local pulse = c.bPulse()
    c.TimerToggle('bridge', not pulse)
    if not pulse and c.TimerMore('bridge', 3) then
        c.Notify(
            'Ожидаем синхронизацию: ' .. SecondsToTime(c.TimerElapsed('bridge'))
        )
    end
end
