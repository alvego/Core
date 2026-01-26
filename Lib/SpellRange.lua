---@class Core
local c = Core -- luacheck: ignore
-- luacheck: push ignore
local GetNumSpellTabs = GetNumSpellTabs ---@diagnostic disable-line
local GetSpellTabInfo = GetSpellTabInfo ---@diagnostic disable-line
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName ---@diagnostic disable-line
local IsSpellInRange = IsSpellInRange
-- luacheck: pop
local bookSpellIds = {}
local function refreshBookSpells()
    local bookType = 'spell'
    local maxIndex = 0
    local maxTabs = GetNumSpellTabs()
    for i = 1, maxTabs do
        local _, _, offs, numspells, _, specId = GetSpellTabInfo(i)
        if specId == 0 then
            maxIndex = offs + numspells
        end
    end

    for spellBookId = 1, maxIndex do
        local spellType, baseSpellId = GetSpellBookItemInfo(spellBookId, bookType)

        if spellType == 'SPELL' then
            local currentSpellName = GetSpellBookItemName(spellBookId, bookType)
            local currentSpellId = c.GetSpellId(currentSpellName)

            if currentSpellName and not bookSpellIds[currentSpellName] then
                bookSpellIds[currentSpellName] = spellBookId
            end
            if currentSpellId and not bookSpellIds[currentSpellId] then
                bookSpellIds[currentSpellId] = spellBookId
            end

            if baseSpellId then
                local baseSpellName = GetSpellInfo(baseSpellId)
                if baseSpellName and not bookSpellIds[baseSpellName] then
                    bookSpellIds[baseSpellName] = spellBookId
                end
                if not bookSpellIds[baseSpellId] then
                    bookSpellIds[baseSpellId] = spellBookId
                end
            end
        end
    end
end
c.Event('SPELLS_CHANGED', refreshBookSpells)
c.Event('PLAYER_ENTERING_WORLD', refreshBookSpells)

function c.IsSpellInRange(spell, unit)
    if next(bookSpellIds) == nil then refreshBookSpells() end
    if spell == nil then return false end
    if unit == nil then unit = 'target' end
    local inRange = IsSpellInRange(spell, unit)
    if inRange == nil then
        local spellBookId = bookSpellIds[spell]
        if spellBookId then
            return IsSpellInRange(spellBookId, 'spell', unit) == 1
        end
    end
    return inRange == 1
end
