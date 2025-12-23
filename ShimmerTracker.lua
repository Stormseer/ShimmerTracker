local shimmerCD = 27
local blinkCD = 15
local twoCharges = true

local shimmerSpellID = 212653
local blinkSpellID = 1953
local alterTimeSpellID = 342247
--local cancelItemSpellID = 53808
local cancelItemSpellID = 30161

local shimmerReadyAt = 0
local activeTimer = nil
local currentInterval = nil

local MAX_CHARGES = 2
local charges = MAX_CHARGES
local rechargeEnd = 0

local statusText
local settingsCategory

-- Pre declaring function names because i CBA
local UpdateCooldownText
local StartRecharge

--------------------------------------------------
-- Helper functions.
--------------------------------------------------
UpdateCooldownText = function(isShimmer)
    local now = GetTime()
    local remaining = shimmerReadyAt - now

    -- Handle recharge completion
    if remaining <= 0 then
        charges = math.min(charges + 1, MAX_CHARGES)

        if charges >= 1 then
            statusText:SetText("")

            if activeTimer then
                activeTimer:Cancel()
                activeTimer = nil
                currentInterval = nil
            end
        end

        -- If still missing charges, start next recharge
        if charges < MAX_CHARGES then
            StartRecharge()
        end

        return
    end

    -- Only show text when NO charges
    if charges == 0 then
        if remaining <= 3 then
            statusText:SetText(string.format("No Shimmer: %.1f", remaining))
        else
            statusText:SetText(string.format("No Shimmer: %.0f", remaining))
        end
    end

    -- Adaptive tick rate
    local desiredInterval = (remaining <= 3) and 0.1 or 1.0
    if desiredInterval ~= currentInterval then
        if activeTimer then activeTimer:Cancel() end
        currentInterval = desiredInterval
        activeTimer = C_Timer.NewTicker(currentInterval, function()
            UpdateCooldownText(isShimmer)
        end)
    end
end


StartRecharge = function(isShimmer)
    if isShimmer then 
        rechargeEnd = GetTime() + shimmerCD
    else
        rechargeEnd = GetTime() + blinkCD
    end
    
    shimmerReadyAt = rechargeEnd
    UpdateCooldownText(isShimmer)
end


--------------------------------------------------
-- Spell Cast Handler
--------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(_, _, unit, _, spellID)
    if unit ~= "player" then return end

    if spellID == shimmerSpellID then
        print("Cast Shimmer")
        if charges > 0 then
            charges = charges - 1

            -- If we just spent the last charge, start recharge
            if charges == MAX_CHARGES - 1 then
                StartRecharge(true)
            end
        end

    elseif spellID == blinkSpellID then
        print("Cast Blink")
        if charges > 0 then
            charges = charges - 1

            -- If we just spent the last charge, start recharge
            if charges == MAX_CHARGES - 1 then
                StartRecharge(false)
            end
        end

    elseif spellID == alterTimeSpellID then 
        print("Cast Alter Time")

    elseif spellID == cancelItemSpellID then
        print("Cast Cancel-Item")

    end
end)

--------------------------------------------------
-- The shown text object
--------------------------------------------------
local displayFrame = CreateFrame("Frame", "ShimmerTrackerDisplay", UIParent)
displayFrame:SetSize(400, 50)
displayFrame:SetPoint("TOP", UIParent, "TOP", 0, -120)
displayFrame:SetFrameStrata("HIGH")
displayFrame:Show()

statusText = displayFrame:CreateFontString(nil, "OVERLAY")
statusText:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
statusText:SetPoint("CENTER")
statusText:SetJustifyH("CENTER")
statusText:SetTextColor(1, 0.1, 0.1, 1) -- red-ish
statusText:SetText("")


-----------------------------------------------------------------------
-- 💀💀💀💀
-- It's all Options Panel from down here (enter at your own risk)
-----------------------------------------------------------------------
do
    local panel = CreateFrame("Frame", "TalentReminderOptionsPanel")
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

        local iconLabel = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        iconLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -15)
        iconLabel:SetText("Cancel item Spell ID:")

        local editBox = CreateFrame("EditBox", "FocusMarkerOptionsIconEditBox", self, "InputBoxTemplate")
        editBox:SetSize(80, 20)
        editBox:SetPoint("LEFT", iconLabel, "RIGHT", 10, 0)
        editBox:SetAutoFocus(false)

        local hint = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        hint:SetPoint("TOPLEFT", iconLabel, "BOTTOMLEFT", 0, -15)
        hint:SetJustifyH("LEFT")
        hint:SetText("A few suggestions: \n" ..
                    "Noggenfogger Elixir - 16589\n" ..
                    "Pygmy Oil - 53808")
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(settingsCategory)
    else
        -- Something is wrong and can't make the options menu. AKA fuck handling multiple client versions. 
        if not FocusMarkerOptions_NoInterfaceOptionsWarning then
            FocusMarkerOptions_NoInterfaceOptionsWarning = true
            print("|cffffff00[TalentReminder]|r Unable to register options panel: no Settings or InterfaceOptions API found.")
        end
    end
end
