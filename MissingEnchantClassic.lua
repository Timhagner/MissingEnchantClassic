local frame = CreateFrame("Frame")
local slotTexts = {}

-- Configurable options
local FONT_SIZE = 12
local OFFSET_LEFT_X, OFFSET_LEFT_Y = -3, -12
local OFFSET_RIGHT_X, OFFSET_RIGHT_Y = 3, -12

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
    "CharacterMainHandSlot"
}

-- Slots that should show the text on the left side
local leftSlots = {
    ["CharacterMainHandSlot"] = true,
    ["CharacterHandsSlot"] = true,
    ["CharacterLegsSlot"] = true,
    ["CharacterFeetSlot"] = true
}

-----------------------------------------------------
-- Create the red text next to an item slot
-----------------------------------------------------
local function CreateSlotText(slotName)
    local slotButton = _G[slotName]
    if slotButton and not slotTexts[slotName] then
        local text = slotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE, "OUTLINE")

        if leftSlots[slotName] then
            text:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", OFFSET_LEFT_X, OFFSET_LEFT_Y)
        else
            text:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", OFFSET_RIGHT_X, OFFSET_RIGHT_Y)
        end

        text:SetTextColor(1, 0, 0)
        text:SetText("")
        slotTexts[slotName] = text
    end
end

-----------------------------------------------------
-- Get the icon for a slot safely (Classic 1.15+ compatible)
-----------------------------------------------------
local function GetSlotIcon(slotButton, slotName)
    if not slotButton then return nil end
    return slotButton.icon or slotButton.Icon or slotButton.iconTexture or slotButton.IconTexture or _G[slotName .. "IconTexture"]
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
                local enchantID = tonumber(itemLink:match("item:%d+:(%d*):"))

                if not enchantID or enchantID == 0 then
                    -- Missing enchant: show text + red icon
                    textLabel:SetText("Not enchanted!")
                    if icon then icon:SetVertexColor(1, 0, 0) end
                else
                    -- Has enchant: clear text + restore icon color
                    textLabel:SetText("")
                    if icon then icon:SetVertexColor(1, 1, 1) end
                end
            else
                -- Empty slot
                textLabel:SetText("")
                if icon then icon:SetVertexColor(1, 1, 1) end
            end
        end
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

-- Update when character frame opens
CharacterFrame:HookScript("OnShow", CheckEquipment)

-- Persist icon tint: reapply every frame while character sheet is visible
CharacterFrame:HookScript("OnUpdate", function()
    if CharacterFrame and CharacterFrame:IsShown() then
        CheckEquipment()
    end
end)
