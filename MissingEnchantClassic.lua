local addonName = "MissingEnchantClassic"
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")

-----------------------------------------------------
-- Constants & Defaults
-----------------------------------------------------
local DEFAULT_FONT_SIZE = 12
local DEFAULT_FONT = "Interface\\AddOns\\MissingEnchantClassic\\fonts\\Expressway.ttf"

-- Slot names relative to the "Character" prefix (e.g., CharacterHeadSlot)
-- We'll just store the suffix part to make it easier to map to InspectFrame
local SLOT_SUFFIXES = {
    "HeadSlot",
    "ShoulderSlot",
    "BackSlot",
    "ChestSlot",
    "WristSlot",
    "HandsSlot",
    "LegsSlot",
    "FeetSlot",
    "MainHandSlot",
    "SecondaryHandSlot",
}

local DEFAULT_POSITIONS = {
    ["HeadSlot"]           = { side = "RIGHT", x = 9,  y = -22 },
    ["ShoulderSlot"]       = { side = "RIGHT", x = 9,  y = -22 },
    ["BackSlot"]           = { side = "RIGHT", x = 9,  y = -22 },
    ["ChestSlot"]          = { side = "RIGHT", x = 9,  y = -22 },
    ["WristSlot"]          = { side = "RIGHT", x = 9,  y = -22 },
    ["HandsSlot"]          = { side = "LEFT",  x = -9, y = -22 },
    ["LegsSlot"]           = { side = "LEFT",  x = -9, y = -22 },
    ["FeetSlot"]           = { side = "LEFT",  x = -9, y = -22 },
    ["MainHandSlot"]       = { side = "LEFT",  x = -9, y = -22 },
    ["SecondaryHandSlot"]  = { side = "RIGHT", x = 9,  y = -22 },
}

local defaults = {
    profile = {
        fontSize = DEFAULT_FONT_SIZE,
        font = DEFAULT_FONT,
        textPositions = {
            ["HeadSlot"]           = { side = "RIGHT", x = 9,  y = -22 },
            ["ShoulderSlot"]       = { side = "RIGHT", x = 9,  y = -22 },
            ["BackSlot"]           = { side = "RIGHT", x = 9,  y = -22 },
            ["ChestSlot"]          = { side = "RIGHT", x = 9,  y = -22 },
            ["WristSlot"]          = { side = "RIGHT", x = 9,  y = -22 },
            ["HandsSlot"]          = { side = "LEFT",  x = -9, y = -22 },
            ["LegsSlot"]           = { side = "LEFT",  x = -9, y = -22 },
            ["FeetSlot"]           = { side = "LEFT",  x = -9, y = -22 },
            ["MainHandSlot"]       = { side = "LEFT",  x = -9, y = -22 },
            ["SecondaryHandSlot"]  = { side = "RIGHT", x = 9,  y = -22 },
        },
    }
}

-----------------------------------------------------
-- Variables
-----------------------------------------------------
local slotTexts = {} -- Key: slotButtonName (e.g. "CharacterHeadSlot" or "InspectHeadSlot")

-----------------------------------------------------
-- Utilities
-----------------------------------------------------
local function GetSlotIcon(slotButton, slotName)
    if not slotButton then return nil end
    return slotButton.icon
        or slotButton.Icon
        or slotButton.iconTexture
        or slotButton.IconTexture
        or _G[slotName .. "IconTexture"]
end

local function ApplyFont(fontString)
    local success = fontString:SetFont(
        addon.db.profile.font,
        addon.db.profile.fontSize,
        "OUTLINE"
    )

    if not success then
        fontString:SetFont(
            "Fonts\\FRIZQT__.TTF",
            addon.db.profile.fontSize,
            "OUTLINE"
        )
    end
end

local function CanOffhandBeEnchanted(itemLink)
    local _, _, _, _, _, itemClass, _, _, equipLoc = GetItemInfo(itemLink)

    if not equipLoc then return false end
    if equipLoc == "INVTYPE_HOLDABLE" then return false end
    if equipLoc == "INVTYPE_SHIELD" then return true end
    if itemClass == "Weapon" then return true end

    return false
end

-- Returns number of empty sockets
local function GetMissingGemCount(itemLink)
    if not GetItemStats then return 0 end -- Fallback for very old clients?
    
    local stats = GetItemStats(itemLink)
    if not stats then return 0 end

    local missing = 0
    for key, value in pairs(stats) do
        -- Keys look like "EMPTY_SOCKET_RED", "EMPTY_SOCKET_META", etc.
        if string.find(key, "EMPTY_SOCKET_") then
             missing = missing + value
        end
    end

    return missing
end

local function CreateSlotText(slotButtonName, suffix)
    local slotButton = _G[slotButtonName]
    if not slotButton then return nil end

    -- Create text if it doesn't exist for this specific button
    if not slotTexts[slotButtonName] then
        local text = slotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ApplyFont(text)
        text:SetTextColor(1, 0, 0)
        text:SetText("")
        slotTexts[slotButtonName] = text
    end

    local text = slotTexts[slotButtonName]
    -- Use the suffix to look up generic position config (e.g. "HeadSlot")
    -- Historically we saved full name "CharacterHeadSlot". 
    -- To keep backward compat, we check "Character"..suffix first, then fallback to suffix.
    local savedPos = addon.db.profile.textPositions["Character"..suffix] 
                     or addon.db.profile.textPositions[suffix] 
                     or DEFAULT_POSITIONS[suffix] 
                     or { side = "RIGHT", x = 3, y = -5 }

    text:ClearAllPoints()
    if savedPos.side == "LEFT" then
        text:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", savedPos.x, savedPos.y)
    else
        text:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", savedPos.x, savedPos.y)
    end
    
    return text
end

-----------------------------------------------------
-- Core Logic
-----------------------------------------------------
-- generic function to check any unit (player or inspect)
local function CheckUnit(unit, framePrefix)
    for _, suffix in ipairs(SLOT_SUFFIXES) do
        local slotButtonName = framePrefix .. suffix
        local slotButton = _G[slotButtonName]
        
        -- Need to create text for this specific frame (Character vs Inspect)
        local textLabel = CreateSlotText(slotButtonName, suffix)
        
        -- Get Icon generic
        local icon = GetSlotIcon(slotButton, slotButtonName)

        -- Reset state
        if textLabel then textLabel:SetText("") end
        if icon then icon:SetVertexColor(1, 1, 1) end

        -- Only proceed if we have a button and text
        if slotButton and textLabel then
            local slotID = slotButton:GetID()
            if slotID then
                local itemLink = GetInventoryItemLink(unit, slotID)

                if itemLink then
                    local issues = {}
                    
                    -----------------------
                    -- Check Enchant
                    -----------------------
                    local shouldCheckEnchant = true
                    if suffix == "SecondaryHandSlot" then
                        shouldCheckEnchant = CanOffhandBeEnchanted(itemLink)
                    end

                    if shouldCheckEnchant then
                        local enchantID = tonumber(itemLink:match("item:%d+:(%d*)"))
                        if not enchantID or enchantID == 0 then
                            table.insert(issues, "No Enchant")
                        end
                    end

                    -----------------------
                    -- Check Gems
                    -----------------------
                    local missingGems = GetMissingGemCount(itemLink)
                    if missingGems > 0 then
                        table.insert(issues, "No Gems")
                    end

                    -----------------------
                    -- Display
                    -----------------------
                    if #issues > 0 then
                        if #issues == 2 then
                            textLabel:SetText("Missing All!")
                        else
                            textLabel:SetText(issues[1] .. "!")
                        end
                        if icon then icon:SetVertexColor(1, 0, 0) end
                    else
                         -- All good
                    end
                end
            end
        end
    end
end

local function CheckPlayer()
    if CharacterFrame and CharacterFrame:IsShown() then
        CheckUnit("player", "Character")
    end
end

local function CheckInspect()
    if InspectFrame and InspectFrame:IsShown() then
        -- In Classic, the inspected unit is always "target"
        local unit = "target"
        
        -- Make sure we have valid target
        if UnitExists(unit) then
            CheckUnit(unit, "Inspect")
        end
    end
end

-----------------------------------------------------
-- Addon Initialization
-----------------------------------------------------
function addon:OnInitialize()
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("MissingEnchantClassicDB", defaults, true)
    
    -- Migrate old settings if they exist
    if _G["MissingEnchantClassicDB"] and type(_G["MissingEnchantClassicDB"]) == "table" then
        local oldDB = _G["MissingEnchantClassicDB"]
        if oldDB.fontSize then
            self.db.profile.fontSize = oldDB.fontSize
        end
        if oldDB.font then
            self.db.profile.font = oldDB.font
        end
        if oldDB.textPositions then
            for k, v in pairs(oldDB.textPositions) do
                -- Only migrate if the table has actual values (not empty)
                if v.side or v.x or v.y then
                    self.db.profile.textPositions[k] = v
                end
            end
        end
    end
    
    -- Fill in any missing slot positions with defaults
    for slotKey, defaultPos in pairs(DEFAULT_POSITIONS) do
        if not self.db.profile.textPositions[slotKey] or 
           (not self.db.profile.textPositions[slotKey].side and 
            not self.db.profile.textPositions[slotKey].x and 
            not self.db.profile.textPositions[slotKey].y) then
            self.db.profile.textPositions[slotKey] = {
                side = defaultPos.side,
                x = defaultPos.x,
                y = defaultPos.y
            }
        end
    end
end

function addon:OnEnable()
    -- Register events
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", CheckPlayer)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", CheckPlayer)
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", function(event, unit)
        if unit == "player" then
            CheckPlayer()
        elseif InspectFrame and InspectFrame:IsShown() and unit == InspectFrame.unit then
             -- If the unit we are inspecting changes gear live
            CheckInspect()
        end
    end)
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED", CheckPlayer)
    self:RegisterEvent("INSPECT_READY", function()
        -- Small delay to ensure data is fully loaded
        C_Timer.After(0.1, CheckInspect)
    end)
    
    -- Hook Character Frame
    CharacterFrame:HookScript("OnShow", CheckPlayer)
    
    -- Try to hook Inspect Frame if already loaded
    if InspectFrame then
        InspectFrame:HookScript("OnShow", function()
            CheckInspect() 
        end)
    end
    
    -- Refresh fonts on enable in case they changed
    for _, text in pairs(slotTexts) do
        ApplyFont(text)
    end
end

function addon:OnDisable()
    -- Cleanup if needed
end

-----------------------------------------------------
-- Public Interface
-----------------------------------------------------
function addon:SetSlotPosition(slotName, side, x, y)
    side = side:upper()
    if side ~= "LEFT" and side ~= "RIGHT" then
        print("MEC: Side must be LEFT or RIGHT")
        return
    end

    self.db.profile.textPositions[slotName] = { side = side, x = x, y = y }
    -- We can force update player immediately
    CheckPlayer() 
end

function addon:SetFontSize(size)
    self.db.profile.fontSize = size
    for _, text in pairs(slotTexts) do
        ApplyFont(text)
    end
end

function addon:GetDefaults()
    return DEFAULT_POSITIONS
end

-----------------------------------------------------
-- Slash Commands
-----------------------------------------------------
SLASH_MISSINGENCHANT1 = "/mec"
SlashCmdList["MISSINGENCHANT"] = function(msg)
    local cmd, arg1, arg2, x, y = msg:match("(%S+)%s*(%S*)%s*(%S*)%s*(%-?%d*)%s*(%-?%d*)")

    if cmd == "setpos" and arg1 ~= "" and arg2 ~= "" and x ~= "" and y ~= "" then
        addon:SetSlotPosition(arg1, arg2, tonumber(x), tonumber(y))
        print("MEC: Updated position for", arg1)

    elseif cmd == "fontsize" and arg1 ~= "" then
        addon:SetFontSize(tonumber(arg1))
        print("MEC: Updated font size to", arg1)

    else
        print("|cff33ff99MissingEnchantClassic|r Commands:")
        print("/mec setpos <SlotName> <LEFT|RIGHT> <X> <Y>")
        print("/mec fontsize <Size>")
        print("/mecsettings - Open settings panel")
    end
end

-- Make addon globally accessible for Settings.lua
_G.MissingEnchantClassic = addon
