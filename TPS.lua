-- TPS (Target Position Status)
-- Shows Behind/Front, LOS, and Range status for your target
-- Requires UnitXP_SP3

local ADDON_NAME = "TPS"

-- Color palette (spectrum order)
local COLOR_PALETTE = {
    white   = { r = 1,    g = 1,    b = 1 },
    gray    = { r = 0.5,  g = 0.5,  b = 0.5 },
    black   = { r = 0.1,  g = 0.1,  b = 0.1 },
    brown   = { r = 0.6,  g = 0.3,  b = 0.1 },
    red     = { r = 1,    g = 0,    b = 0 },
    coral   = { r = 1,    g = 0.5,  b = 0.31 },
    salmon  = { r = 1,    g = 0.55, b = 0.41 },
    orange  = { r = 1,    g = 0.5,  b = 0 },
    peach   = { r = 1,    g = 0.8,  b = 0.6 },
    gold    = { r = 1,    g = 0.82, b = 0 },
    yellow  = { r = 1,    g = 1,    b = 0 },
    lime    = { r = 0.5,  g = 1,    b = 0 },
    mint    = { r = 0.6,  g = 1,    b = 0.6 },
    green   = { r = 0,    g = 1,    b = 0 },
    teal    = { r = 0,    g = 0.5,  b = 0.5 },
    cyan    = { r = 0,    g = 1,    b = 1 },
    sky     = { r = 0.53, g = 0.81, b = 0.92 },
    blue    = { r = 0.4,  g = 0.8,  b = 1 },
    indigo  = { r = 0.29, g = 0,    b = 0.51 },
    purple  = { r = 0.5,  g = 0,    b = 0.5 },
    violet  = { r = 0.6,  g = 0.2,  b = 0.8 },
    lavender= { r = 0.7,  g = 0.5,  b = 1 },
    magenta = { r = 1,    g = 0,    b = 1 },
    pink    = { r = 1,    g = 0.41, b = 0.71 },
}

-- Saved variables defaults
local defaults = {
    locked = false,
    posX = nil,
    posY = nil,
    scale = 1.0,
    updateInterval = 0.05, -- 50ms update rate
    hideNoTarget = false,
    showTitle = true,
    showDistance = true,
    showPosition = true,
    showLOS = true,
    showRange = true,
    -- Custom colors (nil = use default)
    colorTitle = nil,
    colorDistance = nil,
    colorBehind = nil,
    colorFront = nil,
    colorLos = nil,
    colorNolos = nil,
    colorMelee = nil,
    colorRanged = nil,
    -- Alpha/opacity settings (0.0 = invisible, 1.0 = fully opaque)
    alphaBackground = 0.75,
    alphaBorder = 0.8,
    alphaTitle = 1.0,
    alphaDistance = 1.0,
    alphaBehind = 1.0,
    alphaFront = 1.0,
    alphaLos = 1.0,
    alphaNolos = 1.0,
    alphaMelee = 1.0,
    alphaRanged = 1.0,
}

-- Default colors (used when custom not set)
local DEFAULT_COLORS = {
    title    = { r = 1, g = 0.82, b = 0 },      -- Gold
    distance = { r = 1, g = 1, b = 1 },          -- White
    behind   = { r = 0, g = 1, b = 0 },          -- Green
    front    = { r = 1, g = 0.5, b = 0 },        -- Orange
    los      = { r = 0.4, g = 0.8, b = 1 },      -- Light blue
    nolos    = { r = 1, g = 0, b = 0 },          -- Red
    melee    = { r = 1, g = 1, b = 0 },          -- Yellow
    ranged   = { r = 0.6, g = 0.2, b = 0.8 },    -- Purple
}

local COLOR_NEUTRAL = { r = 0.5, g = 0.5, b = 0.5 }    -- Gray (no target)

-- State (declared early so GetColor can access it)
local db

-- Helper to get color (custom or default)
local function GetColor(element)
    local customKey = "color" .. string.upper(string.sub(element, 1, 1)) .. string.sub(element, 2)
    if db and db[customKey] then
        return COLOR_PALETTE[db[customKey]] or DEFAULT_COLORS[element]
    end
    return DEFAULT_COLORS[element]
end

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
titleText:SetTextColor(DEFAULT_COLORS.title.r, DEFAULT_COLORS.title.g, DEFAULT_COLORS.title.b)

-- Distance text
local distanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
distanceText:SetPoint("TOP", titleText, "BOTTOM", 0, -2)
distanceText:SetText("---")
distanceText:SetTextColor(DEFAULT_COLORS.distance.r, DEFAULT_COLORS.distance.g, DEFAULT_COLORS.distance.b)

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
local timeSinceUpdate = 0

-- Calculate frame height based on visible elements
local function UpdateFrameHeight()
    local height = 8 -- top padding

    if db.showTitle then
        height = height + 12 -- title
    end
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
    frame:SetHeight(math.max(height, 30))
end

-- Update text positions based on visibility
local function UpdateTextPositions()
    local lastElement
    local yOffset
    local anchorToFrame = false

    -- Title
    if db.showTitle then
        titleText:Show()
        lastElement = titleText
        yOffset = -2
    else
        titleText:Hide()
        lastElement = frame
        yOffset = -8  -- top padding
        anchorToFrame = true
    end

    -- Distance
    if db.showDistance then
        distanceText:ClearAllPoints()
        if anchorToFrame then
            distanceText:SetPoint("TOP", lastElement, "TOP", 0, yOffset)
            anchorToFrame = false
        else
            distanceText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        end
        distanceText:Show()
        lastElement = distanceText
        yOffset = -4
    else
        distanceText:Hide()
    end

    -- Position (Behind/Front)
    if db.showPosition then
        behindText:ClearAllPoints()
        if anchorToFrame then
            behindText:SetPoint("TOP", lastElement, "TOP", 0, yOffset)
            anchorToFrame = false
        else
            behindText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        end
        behindText:Show()
        lastElement = behindText
        yOffset = -2
    else
        behindText:Hide()
    end

    -- LOS
    if db.showLOS then
        losText:ClearAllPoints()
        if anchorToFrame then
            losText:SetPoint("TOP", lastElement, "TOP", 0, yOffset)
            anchorToFrame = false
        else
            losText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        end
        losText:Show()
        lastElement = losText
        yOffset = -2
    else
        losText:Hide()
    end

    -- Range
    if db.showRange then
        rangeText:ClearAllPoints()
        if anchorToFrame then
            rangeText:SetPoint("TOP", lastElement, "TOP", 0, yOffset)
        else
            rangeText:SetPoint("TOP", lastElement, "BOTTOM", 0, yOffset)
        end
        rangeText:Show()
    else
        rangeText:Hide()
    end

    UpdateFrameHeight()
end

-- Update the display
local function UpdateStatus()
    if not hasUnitXP then
        titleText:SetText("NO UnitXP")
        titleText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b, db.alphaTitle)
        distanceText:SetText("")
        behindText:SetText("")
        losText:SetText("")
        rangeText:SetText("")
        return
    end

    if not UnitExists("target") then
        if db.hideNoTarget then
            frame:Hide()
            return
        end

        titleText:SetText("")
        distanceText:SetText("")
        behindText:SetText("")
        losText:SetText("")
        rangeText:SetText("")
        return
    end

    -- Show frame if we have a target and it was hidden
    if db.hideNoTarget and not frame:IsShown() then
        frame:Show()
    end

    -- Update target name
    local targetName = UnitName("target") or "Unknown"
    titleText:SetText("Target: " .. targetName)
    local titleColor = GetColor("title")
    titleText:SetTextColor(titleColor.r, titleColor.g, titleColor.b, db.alphaTitle)

    -- Update distance
    if db.showDistance then
        local distance = UnitXP("distanceBetween", "player", "target")
        if distance then
            distanceText:SetText(string.format("%.2f yds", distance))
            local distColor = GetColor("distance")
            distanceText:SetTextColor(distColor.r, distColor.g, distColor.b, db.alphaDistance)
        else
            distanceText:SetText("---")
            distanceText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b, db.alphaDistance)
        end
    end

    -- Check behind status
    if db.showPosition then
        local isBehind = UnitXP("behind", "player", "target")
        if isBehind then
            behindText:SetText("BEHIND")
            local behindColor = GetColor("behind")
            behindText:SetTextColor(behindColor.r, behindColor.g, behindColor.b, db.alphaBehind)
        else
            behindText:SetText("FRONT")
            local frontColor = GetColor("front")
            behindText:SetTextColor(frontColor.r, frontColor.g, frontColor.b, db.alphaFront)
        end
    end

    -- Check LOS status
    if db.showLOS then
        local inLOS = UnitXP("inSight", "player", "target")
        if inLOS then
            losText:SetText("IN LOS")
            local losColor = GetColor("los")
            losText:SetTextColor(losColor.r, losColor.g, losColor.b, db.alphaLos)
        else
            losText:SetText("NO LOS")
            local nolosColor = GetColor("nolos")
            losText:SetTextColor(nolosColor.r, nolosColor.g, nolosColor.b, db.alphaNolos)
        end
    end

    -- Check melee range status (uses same distance as display for consistency)
    if db.showRange then
        local meleeDistance = UnitXP("distanceBetween", "player", "target")
        if meleeDistance then
            if meleeDistance <= MELEE_RANGE then
                rangeText:SetText("MELEE")
                local meleeColor = GetColor("melee")
                rangeText:SetTextColor(meleeColor.r, meleeColor.g, meleeColor.b, db.alphaMelee)
            else
                rangeText:SetText("RANGED")
                local rangedColor = GetColor("ranged")
                rangeText:SetTextColor(rangedColor.r, rangedColor.g, rangedColor.b, db.alphaRanged)
            end
        else
            rangeText:SetText("---")
            rangeText:SetTextColor(COLOR_NEUTRAL.r, COLOR_NEUTRAL.g, COLOR_NEUTRAL.b, db.alphaMelee)
        end
    end
end

-- Apply alpha to frame background and border (defined early for ToggleLock)
local function ApplyFrameAlpha()
    frame:SetBackdropColor(0.1, 0.1, 0.1, db.alphaBackground)
    if db.locked then
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, db.alphaBorder * 0.75)
    else
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, db.alphaBorder)
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
        lockIcon:SetText("")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Frame locked")
    else
        lockIcon:SetText("U")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Frame unlocked - drag to move")
    end
    ApplyFrameAlpha()
end

-- Set scale
local function SetScale(scale)
    scale = tonumber(scale)
    if scale and scale >= 0.3 and scale <= 2.0 then
        db.scale = scale
        frame:SetScale(scale)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Scale set to " .. scale)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Scale must be between 0.3 and 2.0")
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
    if option == "title" then
        db.showTitle = not db.showTitle
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Title (Target name) display " .. (db.showTitle and "enabled" or "disabled"))
    elseif option == "distance" then
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
    DEFAULT_CHAT_FRAME:AddMessage("  title: " .. (db.showTitle and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  distance: " .. (db.showDistance and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  position: " .. (db.showPosition and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  los: " .. (db.showLOS and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  range: " .. (db.showRange and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  hidenotarget: " .. (db.hideNoTarget and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
end

-- Valid color elements and their display names
local COLOR_ELEMENTS = {
    title = "Title",
    distance = "Distance",
    behind = "Behind",
    front = "Front",
    los = "In LOS",
    nolos = "No LOS",
    melee = "Melee",
    ranged = "Ranged",
}

-- Get color name from palette value
local function GetColorName(colorKey)
    for name, _ in pairs(COLOR_PALETTE) do
        if name == colorKey then
            return name
        end
    end
    return "default"
end

-- Format color for display with color code
local function FormatColorDisplay(colorName)
    local color = COLOR_PALETTE[colorName]
    if color then
        local hex = string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
        return "|cff" .. hex .. colorName .. "|r"
    end
    return colorName
end

-- Set color for an element
local function SetColor(element, colorName)
    element = string.lower(element or "")
    colorName = string.lower(colorName or "")

    if not COLOR_ELEMENTS[element] then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Unknown element '" .. element .. "'")
        DEFAULT_CHAT_FRAME:AddMessage("  Valid elements: title, distance, behind, front, los, nolos, melee, ranged")
        return false
    end

    if colorName == "default" or colorName == "reset" then
        local key = "color" .. string.upper(string.sub(element, 1, 1)) .. string.sub(element, 2)
        db[key] = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r " .. COLOR_ELEMENTS[element] .. " color reset to default")
        return true
    end

    if not COLOR_PALETTE[colorName] then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Unknown color '" .. colorName .. "'")
        DEFAULT_CHAT_FRAME:AddMessage("  white, gray, black, brown, red, coral, salmon, orange,")
        DEFAULT_CHAT_FRAME:AddMessage("  peach, gold, yellow, lime, mint, green, teal, cyan,")
        DEFAULT_CHAT_FRAME:AddMessage("  sky, blue, indigo, purple, violet, lavender, magenta, pink")
        return false
    end

    local key = "color" .. string.upper(string.sub(element, 1, 1)) .. string.sub(element, 2)
    db[key] = colorName
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r " .. COLOR_ELEMENTS[element] .. " color set to " .. FormatColorDisplay(colorName))
    return true
end

-- Show current color settings
local function ShowColors()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS colors:|r (use /tps color <element> <color>)")
    for element, displayName in pairs(COLOR_ELEMENTS) do
        local key = "color" .. string.upper(string.sub(element, 1, 1)) .. string.sub(element, 2)
        local colorName = db[key] or "default"
        local displayColor
        if colorName == "default" then
            displayColor = "|cff888888default|r"
        else
            displayColor = FormatColorDisplay(colorName)
        end
        DEFAULT_CHAT_FRAME:AddMessage("  " .. element .. ": " .. displayColor)
    end
end

-- Valid alpha elements and their display names
local ALPHA_ELEMENTS = {
    background = "Background",
    border = "Border",
    title = "Title text",
    distance = "Distance text",
    behind = "Behind text",
    front = "Front text",
    los = "In LOS text",
    nolos = "No LOS text",
    melee = "Melee text",
    ranged = "Ranged text",
}

-- Set alpha for an element
local function SetAlpha(element, value)
    element = string.lower(element or "")
    value = tonumber(value)

    if not ALPHA_ELEMENTS[element] then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Unknown element '" .. element .. "'")
        DEFAULT_CHAT_FRAME:AddMessage("  Valid elements: background, border, title, distance,")
        DEFAULT_CHAT_FRAME:AddMessage("    behind, front, los, nolos, melee, ranged")
        return false
    end

    if not value or value < 0 or value > 1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Alpha must be between 0 and 1")
        return false
    end

    local key = "alpha" .. string.upper(string.sub(element, 1, 1)) .. string.sub(element, 2)
    db[key] = value

    -- Apply immediately
    if element == "background" or element == "border" then
        ApplyFrameAlpha()
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r " .. ALPHA_ELEMENTS[element] .. " alpha set to " .. string.format("%.2f", value))
    return true
end

-- Show current alpha settings
local function ShowAlpha()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS alpha:|r (use /tps alpha <element> <0-1>)")
    DEFAULT_CHAT_FRAME:AddMessage("  background: " .. string.format("%.2f", db.alphaBackground))
    DEFAULT_CHAT_FRAME:AddMessage("  border: " .. string.format("%.2f", db.alphaBorder))
    DEFAULT_CHAT_FRAME:AddMessage("  title: " .. string.format("%.2f", db.alphaTitle))
    DEFAULT_CHAT_FRAME:AddMessage("  distance: " .. string.format("%.2f", db.alphaDistance))
    DEFAULT_CHAT_FRAME:AddMessage("  behind: " .. string.format("%.2f", db.alphaBehind))
    DEFAULT_CHAT_FRAME:AddMessage("  front: " .. string.format("%.2f", db.alphaFront))
    DEFAULT_CHAT_FRAME:AddMessage("  los: " .. string.format("%.2f", db.alphaLos))
    DEFAULT_CHAT_FRAME:AddMessage("  nolos: " .. string.format("%.2f", db.alphaNolos))
    DEFAULT_CHAT_FRAME:AddMessage("  melee: " .. string.format("%.2f", db.alphaMelee))
    DEFAULT_CHAT_FRAME:AddMessage("  ranged: " .. string.format("%.2f", db.alphaRanged))
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
    elseif msg == "colors" then
        ShowColors()
    elseif msg == "alpha" then
        ShowAlpha()
    elseif string.find(msg, "^alpha%s+") then
        local _, _, element, value = string.find(msg, "^alpha%s+(%S+)%s*(%S*)")
        if element and value and value ~= "" then
            SetAlpha(element, value)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Usage: /tps alpha <element> <0-1>")
            DEFAULT_CHAT_FRAME:AddMessage("  Elements: background, border, title, distance,")
            DEFAULT_CHAT_FRAME:AddMessage("    behind, front, los, nolos, melee, ranged")
            DEFAULT_CHAT_FRAME:AddMessage("  Example: /tps alpha background 0.5")
        end
    elseif msg == "color" or string.find(msg, "^color%s+") then
        local _, _, element, color = string.find(msg, "^color%s+(%S+)%s*(%S*)")
        if element and color and color ~= "" then
            SetColor(element, color)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS:|r Usage: /tps color <element> <color>")
            DEFAULT_CHAT_FRAME:AddMessage("  Elements: title, distance, behind, front, los, nolos, melee, ranged")
            DEFAULT_CHAT_FRAME:AddMessage("  Colors: white, gray, black, brown, red, coral, salmon, orange,")
            DEFAULT_CHAT_FRAME:AddMessage("    peach, gold, yellow, lime, mint, green, teal, cyan,")
            DEFAULT_CHAT_FRAME:AddMessage("    sky, blue, indigo, purple, violet, lavender, magenta, pink")
            DEFAULT_CHAT_FRAME:AddMessage("  Use 'default' to reset to original color")
        end
    elseif ToggleOption(msg) then
        -- Option was toggled, message already sent
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TPS commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps lock - Lock the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps unlock - Unlock the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps toggle - Toggle lock state")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps reset - Reset position to center")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps scale <0.3-2.0> - Set frame scale")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps show - Show the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps hide - Hide the frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps config - Show current config")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Display toggles:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps title - Toggle target name display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps distance - Toggle distance display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps position - Toggle behind/front display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps los - Toggle LOS display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps range - Toggle melee/ranged display")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps hidenotarget - Toggle hide when no target")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Colors:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps colors - Show current color settings")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps color <element> <color> - Set element color")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Alpha/Opacity:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps alpha - Show current alpha settings")
        DEFAULT_CHAT_FRAME:AddMessage("  /tps alpha <element> <0-1> - Set element opacity")
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

        -- Restore lock state and apply alpha
        if db.locked then
            lockIcon:SetText("")
        else
            lockIcon:SetText("U")
        end
        ApplyFrameAlpha()

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
