---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
local tostring = tostring
local format = format
-- luacheck: pop
c.SpellStore = {}
function c.SpellStoreAdd(spellName)
    if not spellName then
        c.Error(format('SpellStoreAdd(%s) name failure', tostring(spellName)))
        return
    end
    local id = c.GetSpellId(spellName)
    if id == 0 then
        c.Error(format('SpellStoreAdd(%s) id failure', spellName))
        return
    end
    c.SpellStore[id] = spellName
    c.SpellStore[spellName] = id
end
