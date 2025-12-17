---@class Core
local c = Core

local GetTime = GetTime       -- Возвращает время работы системы в секундах с точностью до миллисекунды.
local timers = {}             -- одна переменная на все таймеры

function c.TimerStarted(name) -- Проверяет запущен ли таймер
  return timers[name] ~= nil
end

function c.TimerReset(name) -- Сбрасывает и удаляет таймер
  if c.TimerStarted(name) then
    timers[name] = nil      -- чистим запись в таблице
  end
end

function c.TimerStart(name, offset) -- Запуск/перезапуск таймера
  timers[name] = GetTime() + (offset or 0)
end

function c.TimerElapsed(name) -- Возвращает прошедшее время в секундах с момента запуска таймера
  return GetTime() - (timers[name] or 0)
end

function c.TimerLess(name, less) -- Возвращает true если с момента запуска таймера name прошло меннее less секунд
  return c.TimerStarted(name) and c.TimerElapsed(name) < (less or 0)
end

function c.TimerMore(name, more) -- Возвращает true если с момента запуска таймера name прошло более more секунд или таймер не был запущен
  return c.TimerElapsed(name) > (more or 0)
end

function c.TimerToggle(name, toggle) -- Переключает состояние таймера (но не перезапускает, если уже запущен)
  if toggle then
    if not c.TimerStarted(name) then c.TimerStart(name) end
  else
    c.TimerReset(name)
  end
end
