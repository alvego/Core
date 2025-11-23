-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local type = type

-------------------------------------------------------------------------------

local function showGlow(self)
    if (self.glow) then
        if not self.glow:IsShown() then
            self.glow:Show()
        end
    else
        self.glow = CreateFrame("Frame", nil, UIParent,
            "ActionBarButtonSpellActivationAlert")

        -- Красный цвет (можно любой)
        for i = 1, 6 do
            local region = select(i, self.glow:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                -- В шаблоне 3.3.5a обычно 2 текстуры отвечают за свечение:
                -- первая — внешний ободок, вторая — внутренний блик
                region:SetVertexColor(0, 1, 0) -- чисто зеленый
                -- или: 1, 0.3, 0.3 — мягкий красный
                -- или: 1, 0, 0.7 — красно-фиолетовый
            end
        end

        local frameWidth, frameHeight = self:GetSize()
        self.glow:SetParent(self)
        self.glow:ClearAllPoints()
        --Make the height/width available before the next frame:
        self.glow:SetSize(frameWidth * 1.6, frameHeight * 1.6)
        self.glow:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.3, frameHeight * 0.3)
        self.glow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.3, -frameHeight * 0.3)
        self.glow:Show()
    end
end

local function hideGlow(self)
    if (self.glow and self.glow:IsShown()) then
        self.glow:Hide()
    end
end

function c.HighlightActionSlot(slot)
    --print('|cffaaFFaa' .. slot .. '|r')
    if type(slot) == "string" then slot = c.GetSlot(slot) end
    if not slot then return end
    local button = _G["BT4Button" .. slot]
    if not button then return end

    showGlow(button)
    button.timer = GetTime()
    button:SetScript("OnUpdate", function(self)
        if GetTime() - self.timer > 2 then
            self:SetScript("OnUpdate", nil)
            hideGlow(self)
        end
    end)
end

-------------------------------------------------------------------------------
