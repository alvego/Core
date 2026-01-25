---@class Core
local c = Core

local GetCVar = GetCVar
local SetCVar = SetCVar
local tinsert = tinsert
local type = type
local error = error
local hooksecurefunc = hooksecurefunc
local debug = nil

SetCVar('Sound_EnableErrorSpeech', '0');

function c.Debug()
    if debug == nil then
        debug = GetCVar('scriptErrors') == '1'
    end
    return debug
end

local funcList = {}
function c.UpdateDebugState(func)
    if type(func) ~= 'function' then error('Неверный тип аргумента', 2) end
    tinsert(funcList, func)
end

local function updateDebugState()
    debug = GetCVar('scriptErrors') == '1'
    if c.IsChanged('Debug', debug) then
        for i = 1, #funcList do
            funcList[i](debug)
        end
    end
end
c.Event('PLAYER_ENTERING_WORLD', updateDebugState)

hooksecurefunc('SetCVar', function(key)
    if key == 'scriptErrors' then updateDebugState() end
end)

function c.DebugHook(funcName)
    hooksecurefunc(funcName, function(...)
        c.Log(funcName, ...)
    end)
end
