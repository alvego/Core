-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type
local GetTime = GetTime
-------------------------------------------------------------------------------
local function setGlowColor(button, r, g, b)
    for i = 1, 6 do
        local region = select(i, button.glow:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            -- В шаблоне 3.3.5a обычно 2 текстуры отвечают за свечение:
            -- первая — внешний ободок, вторая — внутренний блик
            region:SetVertexColor(r, g, b) -- чисто зеленый
            -- или: 1, 0.3, 0.3 — мягкий красный
            -- или: 1, 0, 0.7 — красно-фиолетовый
        end
    end
end

local glowOverlap = 0.3 --  на 30%  выступает наружу
local function createGlow(button)
    button.glow = button.glow or CreateFrame("Frame", nil, UIParent, "ActionBarButtonSpellActivationAlert")
    local frameWidth, frameHeight = button:GetSize()
    button.glow:SetParent(button)
    button.glow:ClearAllPoints()
    --Make the height/width available before the next frame:
    local scale = 1 + glowOverlap * 2 -- 100% и 2 стороны по glowOverlap %
    button.glow:SetSize(frameWidth * scale, frameHeight * scale)
    button.glow:SetPoint("TOPLEFT", button, "TOPLEFT", -frameWidth * glowOverlap, frameHeight * glowOverlap)
    button.glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", frameWidth * glowOverlap, -frameHeight * glowOverlap)
end

local function showGlow(button, r, g, b)
    if not button.glow then
        -- создаем первый раз
        createGlow(button)
    end

    -- Зеленый цвет по умолчанию (можно любой)
    setGlowColor(button, r or 0, g or 1, b or 0)

    if not button.glow:IsShown() then
        -- показываем, если скрыт
        button.glow:Show()
    end
end

local function hideGlow(button)
    -- если нет, прятать нечего
    if not button.glow then return end
    -- если спрятан, то уже нечего делать
    if not button.glow:IsShown() then return end
    -- прячем
    button.glow:Hide()
end

local function getButton(slot)
    if type(slot) == "string" then slot = c.GetSlot(slot) end
    if not slot then return end
    local button = _G["BT4Button" .. slot]
    return button
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

function c.HighlightActionSlot(slot)
    --print('|cffaaFFaa' .. slot .. '|r')
    c.ShowActionGlow(slot, 2) -- 2 sec
end

-------------------------------------------------------------------------------
