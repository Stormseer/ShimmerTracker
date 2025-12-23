local Addon = CreateFrame("Frame")
local GetSpellCooldown = C_Spell.GetSpellCooldown -- Upvalue
local settingsCategory

local blinkSpellID   = 1953
local shimmerSpellID = 212653
local SpellID = 1953 -- Blink

--------------------------------------------------
-- The Actual Shown textures and such
--------------------------------------------------
local displayFrame = CreateFrame("Frame", "ShimmerTrackerDisplay", UIParent)
displayFrame:SetSize(400, 50)
displayFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 18)
displayFrame:SetFrameStrata("HIGH")
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

--------------------------------------------------
-- DB Stuff
--------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
initFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

initFrame:SetScript("OnEvent", function(_, _, addonName)
    --if addonName ~= "ShimmerTracker" then
    --    return
    --end
    print("Setting spellID for ShimmerTracker")
    blinkOrShimmer()
    print("Tracked Spell ID: " .. SpellID)

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
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(settingsCategory)
    end
end