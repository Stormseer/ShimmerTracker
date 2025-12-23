local shimmerCD = 27
local blinkCD = 15

local shimmerSpellID = 212653
local blinkSpellID = 1953
local alterTimeSpellID = 342247
local defaultCancelItem = 53808 -- Pygmy Oil

local AT_DURATION = 10
local alterTimeActive = false
local alterTimeTimer = nil

local shimmerReadyAt = 0
local activeTimer = nil

local MAX_CHARGES = 2
local charges = MAX_CHARGES

local statusText
local settingsCategory

-- Pre declaring function names because i CBA
local UpdateCooldownText
local StartRecharge

--------------------------------------------------
-- Global Function
--------------------------------------------------
function AlterTimeCancelled()
    print("Reached my cool new alter cancel function.")
    if not alterTimeActive then
        return
    end

    alterTimeActive = false

    if alterTimeTimer then
        alterTimeTimer:Cancel()
        alterTimeTimer = nil
    end
end

--------------------------------------------------
-- DB Stuff
--------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= "ShimmerTracker" then
        return
    end

end)

--------------------------------------------------
-- Helper functions.
--------------------------------------------------
local function GrantAlterTimeCharge()
    alterTimeActive = false
    alterTimeTimer = nil

    if charges < MAX_CHARGES then
        charges = charges + 1
    end

    if charges >= MAX_CHARGES then
        shimmerReadyAt = 0

        if activeTimer then
            activeTimer:Cancel()
            activeTimer = nil
        end
        statusText:SetText("")
    end
end

UpdateCooldownText = function(isShimmer)
    if charges > 0 then
        statusText:SetText("")
        return
    end

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
            end
        end

        -- If still missing charges, start next recharge
        if charges < MAX_CHARGES then
            StartRecharge(isShimmer)
        end

        return
    end

    -- Only show text when NO charges
    if charges == 0 then
        statusText:SetText(string.format("No Shimmer: %.1f", remaining))
    end
end


StartRecharge = function(isShimmer)
    if shimmerReadyAt > GetTime() then
        return
    end

    local cd = isShimmer and shimmerCD or blinkCD
    shimmerReadyAt = GetTime() + cd

    if activeTimer then
        activeTimer:Cancel()
        activeTimer = nil
    end

    -- Instant update to fix text showing up 1 second *after* you've run out of charges.
    UpdateCooldownText(isShimmer)

    activeTimer = C_Timer.NewTicker(0.1, function()
        UpdateCooldownText(isShimmer)
    end)
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

            if charges == MAX_CHARGES - 1 then
                StartRecharge(true)
            end
        end

    elseif spellID == blinkSpellID then
        print("Cast Blink")
        if charges > 0 then
            charges = charges - 1

            if charges == MAX_CHARGES - 1 then
                StartRecharge(false)
            end
        end

    elseif spellID == alterTimeSpellID then 
        print("Cast Alter Time")
        -- If AT is already active, recast = immediate refund
        if alterTimeActive then
            if alterTimeTimer then
                alterTimeTimer:Cancel()
            end
            GrantAlterTimeCharge()
            return
        end

        -- First cast: arm delayed refund
        alterTimeActive = true
        alterTimeTimer = C_Timer.NewTimer(AT_DURATION, GrantAlterTimeCharge)
    end
end)

--------------------------------------------------
-- The shown text object
--------------------------------------------------
local displayFrame = CreateFrame("Frame", "ShimmerTrackerDisplay", UIParent)
displayFrame:SetSize(400, 50)
displayFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 18)
displayFrame:SetFrameStrata("HIGH")
displayFrame:Show()

statusText = displayFrame:CreateFontString(nil, "OVERLAY")
statusText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
statusText:SetPoint("CENTER")
statusText:SetJustifyH("CENTER")
statusText:SetTextColor(1, 1, 1, 1)
statusText:SetText("")


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
