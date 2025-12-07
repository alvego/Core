-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local GetCVar = GetCVar
local SetCVar = SetCVar
local tinsert = tinsert
local type = type
local error = error
local debug = nil

SetCVar('Sound_EnableErrorSpeech', '0');

function c.Debug()
    if debug == nil then
        debug = GetCVar('scriptErrors') == '1'
    end
    return debug
end

-------------------------------------------------------------------------------
local funcList = {}
function c.UpdateDebugState(func)
    if type(func) ~= 'function' then error('Wrong type') end
    tinsert(funcList, func)
end

-------------------------------------------------------------------------------
local function updateDebugState()
    debug = GetCVar('scriptErrors') == '1'
    if c.IsChanged('Debug', debug) then
        for i = 1, #funcList do
            funcList[i](debug)
        end
    end
end
c.Event('PLAYER_ENTERING_WORLD', updateDebugState)
-------------------------------------------------------------------------------
local function updateDebugStateHook(key, value)
    if key ~= 'scriptErrors' then return end
    updateDebugState()
end
hooksecurefunc('SetCVar', updateDebugStateHook)
-------------------------------------------------------------------------------
function c.DebugHook(funcName)
    hooksecurefunc(funcName, function(...)
        c.Log(funcName, ...)
    end)
end
