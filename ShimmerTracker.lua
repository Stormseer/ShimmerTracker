local Addon = CreateFrame("Frame")
local GetSpellCooldown = C_Spell.GetSpellCooldown -- Upvalue
local settingsCategory

local blinkSpellID   = 1953
local shimmerSpellID = 212653
local SpellID = 1953 -- Blink

local DB
local defaults = {
    x = 0,
    y = 18,
    fontSize = 20,
}

--------------------------------------------------
-- The Actual Shown textures and such
--------------------------------------------------
local displayFrame = CreateFrame("Frame", "ShimmerTrackerDisplay", UIParent)
displayFrame:SetSize(400, 50)
displayFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 18)
displayFrame:SetFrameStrata("LOW")
displayFrame:Show()

local statusText = displayFrame:CreateFontString(nil, "OVERLAY")
statusText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
statusText:SetPoint("CENTER")
statusText:SetJustifyH("CENTER")
statusText:SetTextColor(1, 1, 1, 1)

--------------------------------------------------
-- Helper Functions
--------------------------------------------------
local function blinkOrShimmer()
    if C_SpellBook.IsSpellKnown(shimmerSpellID) then
        SpellID = shimmerSpellID
    else
        SpellID = blinkSpellID
    end
end

local function GetActualCooldown() 
    local durationObject = C_Spell.GetSpellCooldownDuration(SpellID)
    return durationObject:GetRemainingDuration(1)
end

local function ApplyPosition()
    displayFrame:ClearAllPoints()
    displayFrame:SetPoint("CENTER", UIParent, "CENTER", DB.x, DB.y)
end

local function ApplyFontSize()
    statusText:SetFont("Fonts\\FRIZQT__.TTF", DB.fontSize, "OUTLINE")
end


--------------------------------------------------
-- DB Stuff
--------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
initFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

initFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= "ShimmerTracker" then
        return
    end

    -- Init DB
    ShimmerTrackerDB = ShimmerTrackerDB or {}
    DB = ShimmerTrackerDB

    for k, v in pairs(defaults) do
        if DB[k] == nil then
            DB[k] = v
        end
    end

    -- Apply saved settings
    displayFrame:ClearAllPoints()
    displayFrame:SetPoint("CENTER", UIParent, "CENTER", DB.x, DB.y)

    statusText:SetFont("Fonts\\FRIZQT__.TTF", DB.fontSize, "OUTLINE")

    blinkOrShimmer()
end)

--------------------------------------------------
-- Actual Addon Logic
--------------------------------------------------
local function UpdateCdReadyTextures()
  displayFrame:SetAlphaFromBoolean(GetSpellCooldown(SpellID).isOnGCD ~= false, 0, 1)
  statusText:SetText(string.format("No Shimmer: %.1f", GetActualCooldown()))
end

C_Timer.NewTicker(0.1, UpdateCdReadyTextures)

function Addon:SPELL_UPDATE_COOLDOWN()
  UpdateCdReadyTextures()
end

Addon:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
Addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")

-----------------------------------------------------------------------
-- 💀💀💀💀
-- It's all Options Panel from down here (enter at your own risk)
-----------------------------------------------------------------------
do
    local panel = CreateFrame("Frame", "ShimmerTrackerOptionsPanel")
    panel.name = "ShimmerTracker"
    panel:Hide()

    panel:SetScript("OnShow", function(self)
        if self.initialized then return end
        self.initialized = true

        ----------------------------------------------------------------
        -- Title & description
        ----------------------------------------------------------------
        local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("ShimmerTracker")

        local desc = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        desc:SetJustifyH("LEFT")
        desc:SetText("Made by Aryella on Silvermoon EU")

        ----------------------------------------------------------------
        -- X and Y Position
        ----------------------------------------------------------------
        local xPosition = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        xPosition:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
        xPosition:SetText("Text X position:")

        local xPositionEditBox = CreateFrame("EditBox", "ShimmerTrackerXPositionEditBox", self, "InputBoxTemplate")
        xPositionEditBox:SetSize(50, 20)
        xPositionEditBox:SetMaxLetters(10)
        xPositionEditBox:SetPoint("LEFT", xPosition, "RIGHT", 10, 0)
        xPositionEditBox:SetAutoFocus(false)

        xPositionEditBox:SetText(DB.x)
        xPositionEditBox:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText())
            if value then
                DB.x = value
                ApplyPosition()
            end
            self:ClearFocus()
        end)
        
        local yPosition = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        yPosition:SetPoint("TOPLEFT", xPosition, "BOTTOMLEFT", 0, -10)
        yPosition:SetText("Text Y position:")

        local yPositionEditBox = CreateFrame("EditBox", "ShimmerTrackerYPositionEditBox", self, "InputBoxTemplate")
        yPositionEditBox:SetSize(50, 20)
        yPositionEditBox:SetMaxLetters(10)
        yPositionEditBox:SetPoint("LEFT", yPosition, "RIGHT", 10, 0)
        yPositionEditBox:SetAutoFocus(false)

        yPositionEditBox:SetText(DB.y)
        yPositionEditBox:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText())
            if value then
                DB.y = value
                ApplyPosition()
            end
            self:ClearFocus()
        end)

        ----------------------------------------------------------------
        -- Font Size
        ----------------------------------------------------------------
        local fontSizeLabel = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        fontSizeLabel:SetPoint("TOPLEFT", yPosition, "BOTTOMLEFT", 0, -10)
        fontSizeLabel:SetText("Font Size:")

        local fontSizeEditBox = CreateFrame("EditBox", "ShimmerTrackerFontSizeEditBox", self, "InputBoxTemplate")
        fontSizeEditBox:SetSize(50, 20)
        fontSizeEditBox:SetMaxLetters(10)
        fontSizeEditBox:SetPoint("LEFT", fontSizeLabel, "RIGHT", 10, 0)
        fontSizeEditBox:SetAutoFocus(false)

        fontSizeEditBox:SetText(DB.fontSize)
        fontSizeEditBox:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText())
            if value and value > 6 then
                DB.fontSize = value
                ApplyFontSize()
            end
            self:ClearFocus()
        end)
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(settingsCategory)
    end
end