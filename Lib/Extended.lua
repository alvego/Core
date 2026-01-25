---@class Core
local c = Core
local type = type

local function isReadyFunc(fn)
    return c.IsLoaded() and type(fn) == 'function'
end

function c.UnitsCount()
    local func = oUnitsCount
    if isReadyFunc(func) then
        return func()
    end
    return 0
end

function c.UnitIDByIndex(idx)
    local func = oUnitIDByIndex
    if isReadyFunc(func) then
        return func(idx)
    end
    return nil
end
