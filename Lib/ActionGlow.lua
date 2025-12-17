---@class Core
local c = Core

local type = type
local GetTime = GetTime

local spellAlertIcon = [[Interface\SpellActivationOverlay\IconAlert]]
local function createCustomGlow(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints(parent) -- будет растягиваться под кнопку
    f:Hide()

    -- Размеры кнопки (нужны для правильного масштабирования текстур)
    local w, h = parent:GetSize()

    -- 1. outerGlow (большое золотое кольцо снаружи)
    local outer = f:CreateTexture(nil, "ARTWORK")
    outer:SetTexture(spellAlertIcon)
    outer:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    outer:SetSize(w * 1.6, h * 1.6) -- чуть больше кнопки
    outer:SetPoint("CENTER")
    f.outerGlow = outer

    -- 2. outerGlowOver (верхняя половина того же кольца, даёт яркость)
    local outerOver = f:CreateTexture(nil, "ARTWORK", nil, 1)
    outerOver:SetTexture(spellAlertIcon)
    outerOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
    outerOver:SetAllPoints(outer)
    f.outerGlowOver = outerOver

    -- Функции управления
    f.ShowGlow = function(self)
        self:Show()
    end

    f.HideGlow = function(self)
        self:Hide()
    end

    -- Если вдруг понадобится поменять цвет (например на синий/красный для разных проков)
    f.SetColor = function(self, r, g, b, a)
        a = a or 1
        self.outerGlow:SetVertexColor(r, g, b, a)
        self.outerGlowOver:SetVertexColor(r, g, b, a)
    end

    return f
end

local function showGlow(button, r, g, b)
    if not button then return end

    -- Создаём один раз
    if not button.customGlow then
        button.customGlow = createCustomGlow(button)
    end

    if r or g or b then
        button.customGlow:SetColor(r, g, b)
    else
        button.customGlow:SetColor(0, 1, 0) -- синий
    end

    button.customGlow:ShowGlow()
end

local function hideGlow(button)
    if button and button.customGlow then
        button.customGlow:HideGlow()
    end
end

local function getButton(slot)
    if type(slot) == "string" then slot = c.GetSlot(slot, true) end
    if not slot then return end
    return _G["BT4Button" .. slot]
end

function c.ShowActionGlow(slot, interval, r, g, b)
    local button = getButton(slot)
    if not button then return end
    showGlow(button, r, g, b)
    -- проверка на постоянную подсветку
    if type(interval) ~= 'number' or interval <= 0 then return end
    -- если нужно скрыть по времени
    button.glowTimer = GetTime() + interval -- время скрытия
    button:SetScript("OnUpdate", function(self)
        if GetTime() - self.glowTimer > 0 then
            -- пора скрыть подсветку
            hideGlow(self)
            -- сбрасываем подписку на OnUpdate
            self:SetScript("OnUpdate", nil)
        end
    end)
end

function c.HideActionGlow(slot)
    local button = getButton(slot)
    if not button then return end
    hideGlow(button)
end

hooksecurefunc(c, 'Spell', function(spell, ...)
    local slot = c.GetSlot(spell, true)
    if not slot then return end
    c.ShowActionGlow(slot, 1)
end)

hooksecurefunc(c, 'Action', function(slot, ...)
    if type(slot) ~= 'number' or slot <= 0 then return end
    c.ShowActionGlow(slot, 1)
end)
