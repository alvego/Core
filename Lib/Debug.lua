------------------------------------------------------------------------------------------------------------------
-- By by Unknown Coder
------------------------------------------------------------------------------------------------------------------
local _, ns = ...
------------------------------------------------------------------------------------------------------------------
local GetCVar = GetCVar
local tinsert = tinsert
------------------------------------------------------------------------------------------------------------------
local funcList = {}
function ns.AttachUpdateDebugState(func)
    if type(func) ~= 'function' then error("Wrong type") end
    tinsert(funcList, func)
end

------------------------------------------------------------------------------------------------------------------
local function updateDebugState() -- call all subscribers
    ns.Debug = GetCVar('scriptErrors') == '1'
    if ns.IsChanged('ns.Debug', ns.Debug) then
        for i = 1, #funcList do
            funcList[i](ns.Debug)
        end
    end
end
ns.AttachBeforeIdle(updateDebugState)
------------------------------------------------------------------------------------------------------------------
