local addon = _G.MissingEnchantClassic
if not addon then return end

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Slot names for the settings panel
local SLOT_NAMES = {
    { key = "HeadSlot", label = "Head" },
    { key = "ShoulderSlot", label = "Shoulders" },
    { key = "BackSlot", label = "Back" },
    { key = "ChestSlot", label = "Chest" },
    { key = "WristSlot", label = "Wrists" },
    { key = "HandsSlot", label = "Hands" },
    { key = "LegsSlot", label = "Legs" },
    { key = "FeetSlot", label = "Feet" },
    { key = "MainHandSlot", label = "Main Hand" },
    { key = "SecondaryHandSlot", label = "Off Hand" },
}

-- Build options table
local options = {
    name = "MissingEnchantClassic",
    type = "group",
    args = {
        general = {
            type = "group",
            name = "General Settings",
            order = 1,
            inline = true,
            args = {
                font = {
                    type = "select",
                    name = "Font",
                    desc = "Select the font for enchant warnings",
                    order = 1,
                    values = {
                        ["Interface\\AddOns\\MissingEnchantClassic\\fonts\\Expressway.ttf"] = "Expressway (Default)",
                        ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata",
                        ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
                        ["Fonts\\skurri.ttf"] = "Skurri",
                        ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
                    },
                    get = function() return addon.db.profile.font end,
                    set = function(info, value)
                        addon.db.profile.font = value
                        addon:SetFontSize(addon.db.profile.fontSize) -- Refresh fonts
                    end,
                },
                fontSize = {
                    type = "range",
                    name = "Font Size",
                    desc = "Adjust the font size for enchant warnings",
                    min = 8,
                    max = 24,
                    step = 1,
                    order = 2,
                    get = function() return addon.db.profile.fontSize end,
                    set = function(info, value)
                        addon.db.profile.fontSize = value
                        addon:SetFontSize(value)
                    end,
                },
            },
        },
        slots = {
            type = "group",
            name = "Slot Text Positions",
            order = 2,
            args = {
                description = {
                    type = "description",
                    name = "Adjust the position of warning text for each equipment slot.",
                    order = 0,
                },
            },
        },
        reset = {
            type = "execute",
            name = "Reset to Defaults",
            desc = "Reset all settings to default values",
            order = 100,
            confirm = true,
            confirmText = "Reset all settings to default values?",
            func = function()
                -- Reset font and font size
                addon.db.profile.font = "Interface\\AddOns\\MissingEnchantClassic\\fonts\\Expressway.ttf"
                addon.db.profile.fontSize = 12
                addon:SetFontSize(12)
                
                -- Reset each slot to its default position
                local defaults = addon:GetDefaults()
                addon.db.profile.textPositions = {}
                for slotKey, defaultPos in pairs(defaults) do
                    addon.db.profile.textPositions[slotKey] = {
                        side = defaultPos.side,
                        x = defaultPos.x,
                        y = defaultPos.y
                    }
                    addon:SetSlotPosition(slotKey, defaultPos.side, defaultPos.x, defaultPos.y)
                end
                
                print("MissingEnchantClassic: Settings reset to defaults")
            end,
        },
    },
}

-- Add slot-specific options
for i, slotInfo in ipairs(SLOT_NAMES) do
    local slotKey = slotInfo.key
    local slotLabel = slotInfo.label
    
    options.args.slots.args[slotKey] = {
        type = "group",
        name = slotLabel,
        order = i,
        inline = true,
        args = {
            side = {
                type = "select",
                name = "Side",
                desc = "Which side of the slot to display the warning",
                order = 1,
                values = {
                    LEFT = "LEFT",
                    RIGHT = "RIGHT",
                },
                get = function()
                    local pos = addon.db.profile.textPositions[slotKey]
                    if pos then
                        return pos.side
                    end
                    local defaults = addon:GetDefaults()
                    return defaults[slotKey] and defaults[slotKey].side or "RIGHT"
                end,
                set = function(info, value)
                    local pos = addon.db.profile.textPositions[slotKey] or {}
                    pos.side = value
                    addon.db.profile.textPositions[slotKey] = pos
                    addon:SetSlotPosition(slotKey, pos.side, pos.x or 0, pos.y or 0)
                end,
            },
            x = {
                type = "range",
                name = "X Offset",
                desc = "Horizontal offset from the slot",
                order = 2,
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    local pos = addon.db.profile.textPositions[slotKey]
                    if pos and pos.x then
                        return pos.x
                    end
                    local defaults = addon:GetDefaults()
                    return defaults[slotKey] and defaults[slotKey].x or 0
                end,
                set = function(info, value)
                    local pos = addon.db.profile.textPositions[slotKey] or {}
                    pos.x = value
                    addon.db.profile.textPositions[slotKey] = pos
                    addon:SetSlotPosition(slotKey, pos.side or "RIGHT", pos.x, pos.y or 0)
                end,
            },
            y = {
                type = "range",
                name = "Y Offset",
                desc = "Vertical offset from the slot",
                order = 3,
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    local pos = addon.db.profile.textPositions[slotKey]
                    if pos and pos.y then
                        return pos.y
                    end
                    local defaults = addon:GetDefaults()
                    return defaults[slotKey] and defaults[slotKey].y or 0
                end,
                set = function(info, value)
                    local pos = addon.db.profile.textPositions[slotKey] or {}
                    pos.y = value
                    addon.db.profile.textPositions[slotKey] = pos
                    addon:SetSlotPosition(slotKey, pos.side or "RIGHT", pos.x or 0, pos.y)
                end,
            },
        },
    }
end

-- Register options
AceConfig:RegisterOptionsTable("MissingEnchantClassic", options)
AceConfigDialog:AddToBlizOptions("MissingEnchantClassic", "MissingEnchantClassic")

-- Add slash command to open settings
SLASH_MECSETTINGS1 = "/mecsettings"
SlashCmdList["MECSETTINGS"] = function()
    -- Try both old and new methods
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("MissingEnchantClassic")
        InterfaceOptionsFrame_OpenToCategory("MissingEnchantClassic") -- Call twice to fix Blizzard bug
    elseif Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("MissingEnchantClassic")
    end
end
