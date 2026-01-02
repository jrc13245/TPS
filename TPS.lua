-- TPS (Target Position Status)
-- Shows Behind/Front, LOS, and Range status for your target
-- Requires UnitXP_SP3

local ADDON_NAME = "TPS"

-- Saved variables defaults
local defaults = {
    locked = false,
    posX = nil,
    posY = nil,
    scale = 1.0,
    updateInterval = 0.05, -- 50ms update rate
    hideNoTarget = false,
    showDistance = true,
    showPosition = true,
    showLOS = true,
    showRange = true,
}

-- Colors
local COLOR_BEHIND = { r = 0, g = 1, b = 0 }           -- Green
local COLOR_FRONT = { r = 1, g = 0.5, b = 0 }          -- Orange
local COLOR_LOS = { r = 0.4, g = 0.8, b = 1 }          -- Light blue
local COLOR_NO_LOS = { r = 1, g = 0, b = 0 }           -- Red
local COLOR_MELEE = { r = 1, g = 1, b = 0 }            -- Yellow
local COLOR_RANGED = { r = 0.6, g = 0.2, b = 0.8 }     -- Purple
local COLOR_NEUTRAL = { r = 0.5, g = 0.5, b = 0.5 }    -- Gray (no target)
local COLOR_TITLE = { r = 1, g = 0.82, b = 0 }         -- Gold
local COLOR_DISTANCE = { r = 1, g = 1, b = 1 }         -- White

-- Melee range threshold (exactly 2.00 = in melee range, 2.01+ = out of range)
local MELEE_RANGE = 2.00

-- Check for UnitXP
local hasUnitXP = false
local function CheckUnitXP()
    local ok = pcall(UnitXP, "nop", "nop")
    hasUnitXP = ok
    return ok
end

-- Main frame
local frame = CreateFrame("Frame", "TPSFrame", UIParent)
frame:SetWidth(160)
frame:SetHeight(88)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")

-- Background - grey, slightly see through
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
frame:SetBackdropColor(0.1, 0.1, 0.1, 0.75)
frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

-- Title: "Target:<name>"
local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
titleText:SetPoint("TOP", frame, "TOP", 0, -8)
titleText:SetText("Target: ---")
titleText:SetTextColor(COLOR_TITLE.r, COLOR_TITLE.g, COLOR_TITLE.b)

-- Distance text
local distanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
distanceText:SetPoint("TOP", titleText, "BOTTOM", 0, -2)
distanceText:SetText("Distance: ---")
distanceText:SetTextColor(COLOR_DISTANCE.r, COLOR_DISTANCE.g, COLOR_DISTANCE.b)

-- Behind/Front text (centered)
local behindText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
behindText:SetPoint("TOP", distanceText, "BOTTOM", 0, -4)
behindText:SetText("---")
behindText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)

-- LOS text (centered, below behind)
local losText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
losText:SetPoint("TOP", behindText, "BOTTOM", 0, -2)
losText:SetText("---")
losText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)

-- Range text (centered, below LOS)
local rangeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rangeText:SetPoint("TOP", losText, "BOTTOM", 0, -2)
rangeText:SetText("---")
rangeText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)

-- Lock indicator (small icon in corner)
local lockIcon = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lockIcon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
lockIcon:SetText("")
lockIcon:SetTextColor(0.5, 0.5, 0.5)

-- State
local db
local timeSinceUpdate = 0

-- Calculate frame height based on visible elements
local function UpdateFrameHeight()
    local height = 8 -- top padding
    height = height + 12 -- title

    if db.showDistance then
        height = height + 14
    end
    if db.showPosition then
        height = height + 16
    end
    if db.showLOS then
        height = height + 16
    end
    if db.showRange then
        height = height + 16
    end

    height = height + 8 -- bottom padding
    frame:SetHeight(math.max(height, 40))
end

-- Update text positions based on visibility
local function UpdateTextPositions()
    local lastElement = titleText
    local yOffset = -2

    -- Distance
    if db.showDistance then
        distanceText:ClearAllPoints()
        distanceText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        distanceText:Show()
        lastElement = distanceText
        yOffset = -4
    else
        distanceText:Hide()
    end

    -- Position (Behind/Front)
    if db.showPosition then
        behindText:ClearAllPoints()
        behindText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        behindText:Show()
        lastElement = behindText
        yOffset = -2
    else
        behindText:Hide()
    end

    -- LOS
    if db.showLOS then
        losText:ClearAllPoints()
        losText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        losText:Show()
        lastElement = losText
        yOffset = -2
    else
        losText:Hide()
    end

    -- Range
    if db.showRange then
        rangeText:ClearAllPoints()
        rangeText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        rangeText:Show()
    else
        rangeText:Hide()
    end

    UpdateFrameHeight()
end

-- Update the display
local function UpdateStatus()
    if not hasUnitXP then
        titleText:SetText("Target: NO UnitXP")
        titleText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        distanceText:SetText("Distance: ---")
        distanceText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        behindText:SetText("---")
        behindText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        losText:SetText("---")
        losText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        rangeText:SetText("---")
        rangeText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        return
    end

    if not UnitExists("target") then
        if db.hideNoTarget then
            frame:Hide()
            return
        end

        titleText:SetText("Target: ---")
        titleText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        distanceText:SetText("Distance: ---")
        distanceText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        behindText:SetText("---")
        behindText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        losText:SetText("---")
        losText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        rangeText:SetText("---")
        rangeText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        return
    end

    -- Show frame if we have a target and it was hidden
    if db.hideNoTarget and not frame:IsShown() then
        frame:Show()
    end

    -- Update target name
    local targetName = UnitName("target") or "Unknown"
    titleText:SetText("Target: " .. targetName)
    titleText:SetTextColor(COLOR_TITLE.r, COLOR_TITLE.g, COLOR_TITLE.b)

    -- Update distance
    if db.showDistance then
        local distance = UnitXP("distanceBetween", "player", "target")
        if distance then
            distanceText:SetText(string.format("Distance: %.2f yds", distance))
            distanceText:SetTextColor(COLOR_DISTANCE.r, COLOR_DISTANCE.g, COLOR_DISTANCE.b)
        else
            distanceText:SetText("Distance: ---")
            distanceText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        end
    end

    -- Check behind status
    if db.showPosition then
        local isBehind = UnitXP("behind", "player", "target")
        if isBehind then
            behindText:SetText("BEHIND")
            behindText:SetTextColor(COLOR_BEHIND.r, COLOR_BEHIND.g, COLOR_BEHIND.b)
        else
            behindText:SetText("FRONT")
            behindText:SetTextColor(COLOR_FRONT.r, COLOR_FRONT.g, COLOR_FRONT.b)
        end
    end

    -- Check LOS status
    if db.showLOS then
        local inLOS = UnitXP("inSight", "player", "target")
        if inLOS then
            losText:SetText("IN LOS")
            losText:SetTextColor(COLOR_LOS.r, COLOR_LOS.g, COLOR_LOS.b)
        else
            losText:SetText("NO LOS")
            losText:SetTextColor(COLOR_NO_LOS.r, COLOR_NO_LOS.g, COLOR_NO_LOS.b)
        end
    end

    -- Check melee range status (uses same distance as display for consistency)
    if db.showRange then
        local meleeDistance = UnitXP("distanceBetween", "player", "target")
        if meleeDistance then
            if meleeDistance <= MELEE_RANGE then
                rangeText:SetText("MELEE")
                rangeText:SetTextColor(COLOR_MELEE.r, COLOR_MELEE.g, COLOR_MELEE.b)
            else
                rangeText:SetText("RANGED")
                rangeText:SetTextColor(COLOR_RANGED.r, COLOR_RANGED.g, COLOR_RANGED.b)
            end
        else
            rangeText:SetText("---")
            rangeText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b)
        end
    end
end

-- Dragging
local function StartDragging()
    if not db.locked then
        frame:StartMoving()
    end
end

local function StopDragging()
    frame:StopMovingOrSizing()
    -- Save position
    local point, _, relPoint, x, y = frame:GetPoint()
    db.posX = x
    db.posY = y
end

frame:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        StartDragging()
    end
end)

frame:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" then
        StopDragging()
    end
end)

-- Toggle lock
local function ToggleLock()
    db.locked = not db.locked
    if db.locked then
        lockIcon:SetText("L")
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Frame locked")
    else
        lockIcon:SetText("U")
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Frame unlocked - drag to move")
    end
end

-- Set scale
local function SetScale(scale)
    scale = tonumber(scale)
    if scale and scale >= 0.5 and scale <= 2.0 then
        db.scale = scale
        frame:SetScale(scale)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Scale set to " .. scale)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Scale must be between 0.5 and 2.0")
    end
end

-- Reset position
local function ResetPosition()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    db.posX = 0
    db.posY = 200
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Position reset")
end

-- Toggle display option
local function ToggleOption(option)
    if option == "distance" then
        db.showDistance = not db.showDistance
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Distance display " .. (db.showDistance and "enabled" or "disabled"))
    elseif option == "position" then
        db.showPosition = not db.showPosition
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Position (Behind/Front) display " .. (db.showPosition and "enabled" or "disabled"))
    elseif option == "los" then
        db.showLOS = not db.showLOS
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r LOS display " .. (db.showLOS and "enabled" or "disabled"))
    elseif option == "range" then
        db.showRange = not db.showRange
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Range (Melee/Ranged) display " .. (db.showRange and "enabled" or "disabled"))
    elseif option == "hidenotarget" then
        db.hideNoTarget = not db.hideNoTarget
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Hide with no target " .. (db.hideNoTarget and "enabled" or "disabled"))
        if not db.hideNoTarget and not frame:IsShown() then
            frame:Show()
        end
    else
        return false
    end
    UpdateTextPositions()
    return true
end

-- Show current config
local function ShowConfig()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS config:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  distance: " .. (db.showDistance and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  position: " .. (db.showPosition and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  los: " .. (db.showLOS and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  range: " .. (db.showRange and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  hidenotarget: " .. (db.hideNoTarget and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
end

-- OnUpdate handler
frame:SetScript("OnUpdate", function()
    timeSinceUpdate = timeSinceUpdate + arg1
    if timeSinceUpdate >= db.updateInterval then
        timeSinceUpdate = 0
        UpdateStatus()
    end
end)

-- Slash commands
SLASH_TPS1 = "/tps"
SlashCmdList["TPS"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "lock" then
        if not db.locked then
            ToggleLock()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Already locked")
        end
    elseif msg == "unlock" then
        if db.locked then
            ToggleLock()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Already unlocked")
        end
    elseif msg == "toggle" then
        ToggleLock()
    elseif msg == "reset" then
        ResetPosition()
    elseif string.find(msg, "^scale%s+") then
        local _, _, scale = string.find(msg, "^scale%s+(%S+)")
        SetScale(scale)
    elseif msg == "show" then
        frame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Frame shown")
    elseif msg == "hide" then
        frame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Frame hidden")
    elseif msg == "config" then
        ShowConfig()
    elseif ToggleOption(msg) then
        -- Option was toggled, message already sent
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps lock - Lock the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps unlock - Unlock the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps toggle - Toggle lock state")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps reset - Reset position to center")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps scale <0.5-2.0> - Set frame scale")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps show - Show the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps hide - Hide the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps config - Show current config")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Display toggles:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps distance - Toggle distance display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps position - Toggle behind/front display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps los - Toggle LOS display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps range - Toggle melee/ranged display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps hidenotarget - Toggle hide when no target")
    end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Initialize saved variables
        if not TPS_DB then
            TPS_DB = {}
        end
        db = TPS_DB

        -- Apply defaults
        for k, v in pairs(defaults) do
            if db[k] == nil then
                db[k] = v
            end
        end

        -- Check for UnitXP
        CheckUnitXP()

        -- Restore position
        if db.posX and db.posY then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
        end

        -- Restore scale
        if db.scale then
            frame:SetScale(db.scale)
        end

        -- Restore lock state
        if db.locked then
            lockIcon:SetText("L")
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)
        else
            lockIcon:SetText("U")
        end

        -- Update text positions based on config
        UpdateTextPositions()

        -- Handle initial hide state
        if db.hideNoTarget and not UnitExists("target") then
            frame:Hide()
        end

        -- Initial update
        UpdateStatus()

        if hasUnitXP then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS loaded.|r Type /tps for options.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TPS:|r UnitXP_SP3 not detected! Addon will not function.")
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Immediately show/hide based on target
        if db.hideNoTarget then
            if UnitExists("target") then
                frame:Show()
            else
                frame:Hide()
            end
        end
        -- Force immediate update
        UpdateStatus()
    end
end)
