---@class Core
local c = Core
---@class Core.state
local st = c.state

-- local GetCVar = GetCVar
-- local SetCVar = SetCVar
local strtrim = strtrim
local SetRaidTarget = SetRaidTarget
local GetRaidTargetIndex = GetRaidTargetIndex
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local type = type
local PlaySound = PlaySound
local UnitExists = UnitExists
local SOUNDKIT = SOUNDKIT
local title = 'Поиск'
local icon = [[Interface\Icons\Ability_Hunter_SniperShot]]
local searchName, objectGUID, objName, objX, objY, objZ, objRange

c.ActionHook('find', function()
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then return end
    local text = editBox:GetText()
    if type(text) == 'string' and text ~= '' then
        searchName = strtrim(text)
        objectGUID = nil
        editBox:SetText('')
        editBox:ClearFocus()
        c.Notify('Поиск "' .. searchName .. '"', icon, 3)
        c.Message("Для сброса поиска нажмите макрос с [ctrl]", title, icon)
    else
        if searchName then
            if st.ctrl then
                if objectGUID then
                    c.Notify('Найденный ранее объект "' .. objName .. '" сброшен', icon)
                    c.Message("Для сброса строки поиска нажмите макрос с [ctrl] еще раз", title, icon)
                    objectGUID = nil
                    return
                end
                if searchName then
                    c.Notify('Поиск "' .. searchName .. '" сброшен', icon, 3)
                    searchName = nil
                    return
                end
            end
        else
            c.Notify('Не задана строка для поиска', icon, 3)
            c.Message("Для начала поиска введите в чате имя объекта (можно часть)", title, icon)
        end
    end
    if objectGUID and objX and objY and objZ then
        c.Notify('Начинаем  движение к ' .. objName, icon, 3)
        c.bPlayerMoveTo(objX, objY, objZ)
    end
end)


c.AfterUpdate(function()
    if not searchName then return end
    if c.TimerLess('LookUnit', 1) then return end
    c.TimerStart('LookUnit')
    objectGUID, objName, objX, objY, objZ, objRange = c.bFindObject(searchName)
    if not c.IsChanged('bFindObject', objectGUID) then return end
    if not objectGUID then return end
    --PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
    PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN)
    c.Notify('Найден "' .. objName .. '" на расстоянии ' .. c.Round(objRange, 1) .. 'м.', icon, 10)
    c.Message('Найден объект новый объект "' .. objName .. '"', title, icon)
    c.Message('Нажмите на макрос для того чтоб начать двигаться к "' .. objName .. '"', title, icon)
    if st.combatMode then return end
    c.bWithGUID(objectGUID, function(token)
        if UnitExists(token) then
            local raidTargetIdx = 4
            if GetRaidTargetIndex(token) ~= raidTargetIdx then SetRaidTarget(token, raidTargetIdx) end
            c.bTargetUnit(token)
        end
    end)
end)
