---@class Core
local c = Core

local tostring = tostring
local format = format

c.SpellStore = {}
function c.SpellStoreAdd(spellName)
    if not spellName then
        c.Error(format('SpellStoreAdd(%s) name falure', tostring(spellName)))
        return
    end
    local id = c.GetSpellId(spellName)
    if id == 0 then
        c.Error(format('SpellStoreAdd(%s) id falure', spellName))
        return
    end
    c.SpellStore[id] = spellName
    c.SpellStore[spellName] = id
end
