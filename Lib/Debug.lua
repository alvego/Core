------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local GetCVar = GetCVar
local tinsert = tinsert
------------------------------------------------------------------------------------------------------------------
local funcList = {}
function ns.AttachUpdateDebugState(func) -- not use ns.State.debug in func
    if nil == func then error("Func can't be nil") end
    tinsert(funcList, func)
end

------------------------------------------------------------------------------------------------------------------
function ns.UpdateDebugState() -- call all subscribers
    local scriptErrors = GetCVar('scriptErrors') == '1'
    if ns.IsChanged('scriptErrors', scriptErrors) then
        for i = 1, #funcList do
            funcList[i](scriptErrors)
        end
    end
    return scriptErrors
end

------------------------------------------------------------------------------------------------------------------
