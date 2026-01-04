-- MissingEnchantClassic.lua
-----------------------------------------------------
-- Frame & Saved Variables
-----------------------------------------------------
local frame = CreateFrame("Frame")
local slotTexts = {}

-- Default font size
local DEFAULT_FONT_SIZE = 12

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

-- Default positions for each slot
local DEFAULT_POSITIONS = {
    ["CharacterHeadSlot"]      = { side = "RIGHT", x = 3,  y = -5 },
    ["CharacterShoulderSlot"]  = { side = "RIGHT", x = 3,  y = -5 },
    ["CharacterBackSlot"]      = { side = "RIGHT", x = 3,  y = -5 },
    ["CharacterChestSlot"]     = { side = "RIGHT", x = 3,  y = -5 },
    ["CharacterWristSlot"]     = { side = "RIGHT", x = 3,  y = -5 },
    ["CharacterHandsSlot"]     = { side = "LEFT",  x = -3, y = -5 },
    ["CharacterLegsSlot"]      = { side = "LEFT",  x = -3, y = -5 },
    ["CharacterFeetSlot"]      = { side = "LEFT",  x = -3, y = -5 },
    ["CharacterMainHandSlot"]  = { side = "LEFT",  x = 0,  y = -16 },
}

-- Saved variables
MissingEnchantClassicDB = MissingEnchantClassicDB or {}
MissingEnchantClassicDB.textPositions = MissingEnchantClassicDB.textPositions or {}
MissingEnchantClassicDB.fontSize = MissingEnchantClassicDB.fontSize or DEFAULT_FONT_SIZE

-----------------------------------------------------
-- Utility: Get slot icon safely
-----------------------------------------------------
local function GetSlotIcon(slotButton, slotName)
    if not slotButton then return nil end
    return slotButton.icon or slotButton.Icon or slotButton.iconTexture or slotButton.IconTexture or _G[slotName .. "IconTexture"]
end

-----------------------------------------------------
-- Create or update red text for a slot
-----------------------------------------------------
local function CreateSlotText(slotName)
    local slotButton = _G[slotName]
    if not slotButton then return end

    if not slotTexts[slotName] then
        local text = slotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetFont("Fonts\\FRIZQT__.TTF", MissingEnchantClassicDB.fontSize, "OUTLINE")
        text:SetTextColor(1, 0, 0)
        text:SetText("")
        slotTexts[slotName] = text
    end

    local text = slotTexts[slotName]
    local pos = MissingEnchantClassicDB.textPositions[slotName] or DEFAULT_POSITIONS[slotName] or { side = "RIGHT", x = 3, y = -5 }

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
                local enchantID = tonumber(itemLink:match("item:%d+:(%d*):"))
                if not enchantID or enchantID == 0 then
                    textLabel:SetText("Not enchanted!")
                    if icon then icon:SetVertexColor(1, 0, 0) end
                else
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

    if slotTexts[slotName] then
        local slotButton = _G[slotName]
        if side == "LEFT" then
            slotTexts[slotName]:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", x, y)
        else
            slotTexts[slotName]:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", x, y)
        end
    end
end

function MissingEnchantClassic_SetFontSize(size)
    MissingEnchantClassicDB.fontSize = size
    for _, text in pairs(slotTexts) do
        text:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    end
end

-----------------------------------------------------
-- Slash commands
-----------------------------------------------------
SLASH_MEC1 = "/mec"
SlashCmdList["MEC"] = function(msg)
    local cmd, slot, side, x, y = msg:match("(%w+)%s*(%w*)%s*(%w*)%s*(%-?%d*)%s*(%-?%d*)")
    if cmd == "setpos" and slot and side and x ~= "" and y ~= "" then
        MissingEnchantClassic_SetSlotPosition(slot, side, tonumber(x), tonumber(y))
        print("MEC: Updated position for", slot)
    elseif cmd == "fontsize" and slot ~= "" then
        MissingEnchantClassic_SetFontSize(tonumber(slot))
        print("MEC: Updated font size to", slot)
    else
        print("MEC Commands:")
        print("/mec setpos <SlotName> <LEFT|RIGHT> <X> <Y>  - Set text position")
        print("/mec fontsize <Size>                        - Set text font size")
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
    if CharacterFrame and CharacterFrame:IsShown() then
        CheckEquipment()
    end
end)
