---@class Core
local c = Core
local st = c.state;
-- local GetCVar = GetCVar
-- local SetCVar = SetCVar


local Cmd = function(name, ...)
    --if (type(Bridge) ~= 'function') then return end
    return GetBillingTimeRested(name, ...)
end

-- Глобальная обертка (добавь в свой загрузочный скрипт)
function WithGUID(guid, callback)
    local token = "mouseover"
    local oldGuid = UnitGUID(token)
    Cmd("UseGUID", token, guid)
    local result = callback(token)
    Cmd("UseGUID", token, oldGuid)
    return result
end

-- UIParentLoadAddOn('Blizzard_DebugTools');

c.ActionHook('test', function()
    print('Cmd(\'Pulse\'):', Cmd('Pulse'))

    print('target dist:', Cmd('UnitDistance', 'target'))

    local corpse = Cmd('FindCorpse', 5)
    print('corpse', corpse, type('corpse'))
    if corpse then
        print('Лутаем', WithGUID(corpse, UnitName))
        Cmd('UnitClick', corpse, 1)
        return
    end
    corpse = Cmd('FindCorpse', 8, 1)
    if corpse then
        print('Снимаем шкуру', WithGUID(corpse, UnitName))
        Cmd('UnitClick', corpse, 1)
        return
    end

    corpse = Cmd('FindCorpse', 40)
    if corpse then
        print('Идем лутать ', WithGUID(corpse, UnitName))
        Cmd('PlayerMoveTo', corpse);
        return
    end

    corpse = Cmd('FindCorpse', 40, 1)
    if corpse then
        print('Идем снимать шкуру с ', WithGUID(corpse, UnitName))
        Cmd('PlayerMoveTo', corpse);
        return
    end

    print('Некого лутать/шкурить')
end)


c.ActionHook('test2', function()
    -- print('Bridge:', type(GetBillingTimeRested))
    -- print('Bridge():', GetBillingTimeRested())
    --print('Bridge(\'Pulse\'):', Cmd('Pulse'))
    --print('Player facing:', Cmd('UnitFacing', 'player'), 'position:', Cmd('UnitPosition', 'player'));
    --Cmd('Test')

    -- if UnitExists('target') then
    --     print(Cmd('UnitInLoS', "target"));
    -- end

    -- if st.speed > 0 then
    --     print('PlayerMoveStop')
    --     Cmd('PlayerMoveStop')
    -- else
    --     if UnitExists('target') then
    --         Cmd('PlayerFaceAt', Cmd('UnitPosition', 'target'))
    --     end
    -- end

    -- print(1, testTable)
    -- DevTools_Dump(testTable);
    -- Cmd('FillTable', testTable)
    -- print(2, testTable)
    -- DevTools_Dump(testTable);
    -- print('player', UnitGUID('player'))
    -- print('target', UnitGUID('target'))
    -- print('focus', UnitGUID('focus'))
    -- print('mouseover', UnitGUID('mouseover'))


    --print('WithGUID:', WithGUID(UnitGUID('player'), UnitName))
    --Cmd('UseSpell', 'Смерть и разложение', 'target')


    --WithGUID(UnitGUID('mouseover'), function(token) Cmd('UseLua', 'InteractUnit("' .. token .. '")') end)

    --Cmd('UnitClick', 'focus', '1')
    --Cmd('TargetUnit', UnitGUID('mouseover'))
end)
