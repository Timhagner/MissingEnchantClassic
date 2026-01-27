-- MissingEnchantClassic.lua
-----------------------------------------------------
-- Frame & Saved Variables
-----------------------------------------------------
local frame = CreateFrame("Frame")
local slotTexts = {}

-- Defaults
local DEFAULT_FONT_SIZE = 12
local DEFAULT_FONT = "Interface\\AddOns\\MissingEnchantClassic\\fonts\\Expressway.ttf"

-- Classic enchantable slots
local enchantableSlots = {
    "CharacterHeadSlot",
    "CharacterShoulderSlot",
    "CharacterBackSlot",
    "CharacterChestSlot",
    "CharacterWristSlot",
    "CharacterHandsSlot",
    "CharacterLegsSlot",
    "CharacterFeetSlot",
    "CharacterMainHandSlot",
    "CharacterSecondaryHandSlot",
}

-- Default positions for each slot
local DEFAULT_POSITIONS = {
    ["CharacterHeadSlot"]           = { side = "RIGHT", x = 9,  y = -22 },
    ["CharacterShoulderSlot"]       = { side = "RIGHT", x = 9,  y = -22 },
    ["CharacterBackSlot"]           = { side = "RIGHT", x = 9,  y = -22 },
    ["CharacterChestSlot"]          = { side = "RIGHT", x = 9,  y = -22 },
    ["CharacterWristSlot"]          = { side = "RIGHT", x = 9,  y = -22 },
    ["CharacterHandsSlot"]          = { side = "LEFT",  x = -9, y = -22 },
    ["CharacterLegsSlot"]           = { side = "LEFT",  x = -9, y = -22 },
    ["CharacterFeetSlot"]           = { side = "LEFT",  x = -9, y = -22 },
    ["CharacterMainHandSlot"]       = { side = "LEFT",  x = -9,  y = -22 },
    ["CharacterSecondaryHandSlot"]  = { side = "RIGHT",  x = 9,  y = -22 },
}

-- Saved variables
MissingEnchantClassicDB = MissingEnchantClassicDB or {}
MissingEnchantClassicDB.textPositions = MissingEnchantClassicDB.textPositions or {}
MissingEnchantClassicDB.fontSize = MissingEnchantClassicDB.fontSize or DEFAULT_FONT_SIZE
MissingEnchantClassicDB.font = MissingEnchantClassicDB.font or DEFAULT_FONT

-----------------------------------------------------
-- Utility: Get slot icon safely
-----------------------------------------------------
local function GetSlotIcon(slotButton, slotName)
    if not slotButton then return nil end
    return slotButton.icon
        or slotButton.Icon
        or slotButton.iconTexture
        or slotButton.IconTexture
        or _G[slotName .. "IconTexture"]
end

-----------------------------------------------------
-- Utility: Apply font safely
-----------------------------------------------------
local function ApplyFont(fontString)
    local success = fontString:SetFont(
        MissingEnchantClassicDB.font,
        MissingEnchantClassicDB.fontSize,
        "OUTLINE"
    )

    if not success then
        fontString:SetFont(
            "Fonts\\FRIZQT__.TTF",
            MissingEnchantClassicDB.fontSize,
            "OUTLINE"
        )
    end
end

-----------------------------------------------------
-- Utility: Off-hand enchant eligibility
-----------------------------------------------------
local function CanOffhandBeEnchanted(itemLink)
    local _, _, _, _, _, itemClass, _, _, equipLoc = GetItemInfo(itemLink)

    if not equipLoc then
        return false
    end

    -- Held in Off-hand (cannot be enchanted)
    if equipLoc == "INVTYPE_HOLDABLE" then
        return false
    end

    -- Shields can be enchanted
    if equipLoc == "INVTYPE_SHIELD" then
        return true
    end

    -- One-hand weapons can be enchanted
    if itemClass == "Weapon" then
        return true
    end

    return false
end

-----------------------------------------------------
-- Create or update red text for a slot
-----------------------------------------------------
local function CreateSlotText(slotName)
    local slotButton = _G[slotName]
    if not slotButton then return end

    if not slotTexts[slotName] then
        local text = slotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ApplyFont(text)
        text:SetTextColor(1, 0, 0)
        text:SetText("")
        slotTexts[slotName] = text
    end

    local text = slotTexts[slotName]
    local pos = MissingEnchantClassicDB.textPositions[slotName]
        or DEFAULT_POSITIONS[slotName]
        or { side = "RIGHT", x = 3, y = -5 }

    text:ClearAllPoints()
    if pos.side == "LEFT" then
        text:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", pos.x, pos.y)
    else
        text:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", pos.x, pos.y)
    end
end

-----------------------------------------------------
-- Main function to check all enchantable slots
-----------------------------------------------------
local function CheckEquipment()
    for _, slotName in ipairs(enchantableSlots) do
        CreateSlotText(slotName)

        local slotButton = _G[slotName]
        local slotID = slotButton and slotButton:GetID()
        local textLabel = slotTexts[slotName]
        local icon = GetSlotIcon(slotButton, slotName)

        if slotID then
            local itemLink = GetInventoryItemLink("player", slotID)

            if itemLink then
                local shouldCheckEnchant = true

                -- Special handling for off-hand
                if slotName == "CharacterSecondaryHandSlot" then
                    shouldCheckEnchant = CanOffhandBeEnchanted(itemLink)
                end

                if shouldCheckEnchant then
                    local enchantID = tonumber(itemLink:match("item:%d+:(%d*):"))
                    if not enchantID or enchantID == 0 then
                        textLabel:SetText("Not enchanted!")
                        if icon then icon:SetVertexColor(1, 0, 0) end
                    else
                        textLabel:SetText("")
                        if icon then icon:SetVertexColor(1, 1, 1) end
                    end
                else
                    -- Item cannot be enchanted
                    textLabel:SetText("")
                    if icon then icon:SetVertexColor(1, 1, 1) end
                end
            else
                textLabel:SetText("")
                if icon then icon:SetVertexColor(1, 1, 1) end
            end
        end
    end
end

-----------------------------------------------------
-- User configuration functions
-----------------------------------------------------
function MissingEnchantClassic_SetSlotPosition(slotName, side, x, y)
    side = side:upper()
    if side ~= "LEFT" and side ~= "RIGHT" then
        print("MEC: Side must be LEFT or RIGHT")
        return
    end

    MissingEnchantClassicDB.textPositions[slotName] = { side = side, x = x, y = y }
    CreateSlotText(slotName)
end

function MissingEnchantClassic_SetFontSize(size)
    MissingEnchantClassicDB.fontSize = size
    for _, text in pairs(slotTexts) do
        ApplyFont(text)
    end
end

-----------------------------------------------------
-- Slash commands
-----------------------------------------------------
SLASH_MEC1 = "/mec"
SlashCmdList["MEC"] = function(msg)
    local cmd, arg1, arg2, x, y = msg:match("(%S+)%s*(%S*)%s*(%S*)%s*(%-?%d*)%s*(%-?%d*)")

    if cmd == "setpos" and arg1 ~= "" and arg2 ~= "" and x ~= "" and y ~= "" then
        MissingEnchantClassic_SetSlotPosition(arg1, arg2, tonumber(x), tonumber(y))
        print("MEC: Updated position for", arg1)

    elseif cmd == "fontsize" and arg1 ~= "" then
        MissingEnchantClassic_SetFontSize(tonumber(arg1))
        print("MEC: Updated font size to", arg1)

    else
        print("MEC Commands:")
        print("/mec setpos <SlotName> <LEFT|RIGHT> <X> <Y>")
        print("/mec fontsize <Size>")
    end
end

-----------------------------------------------------
-- Event hooks
-----------------------------------------------------
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")

frame:SetScript("OnEvent", function()
    if CharacterFrame and CharacterFrame:IsShown() then
        CheckEquipment()
    end
end)

CharacterFrame:HookScript("OnShow", CheckEquipment)
CharacterFrame:HookScript("OnUpdate", function()
    if CharacterFrame:IsShown() then
        CheckEquipment()
    end
end)
