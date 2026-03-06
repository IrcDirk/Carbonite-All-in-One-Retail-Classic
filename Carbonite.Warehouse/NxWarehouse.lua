-------------------------------------------------------------------------------
-- NxWarehouse - Warehouse Inventory Tracker
-- Copyright 2007-2012 Carbon Based Creations, LLC
-------------------------------------------------------------------------------
-- Carbonite - Addon for World of Warcraft(tm)
-- Copyright 2007-2012 Carbon Based Creations, LLC
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- MODULE INITIALIZATION
-------------------------------------------------------------------------------

local _G = getfenv(0)

-- Create the AceAddon for the Warehouse module
CarboniteWarehouse = LibStub("AceAddon-3.0"):NewAddon("CarboniteWarehouse", "AceEvent-3.0", "AceComm-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Warehouse", true)

-- Guild bank communication library for syncing
local GuildBank = LibStub("LibGuildBankComm-1.0")

-------------------------------------------------------------------------------
-- VERSION AND NAMESPACE
-------------------------------------------------------------------------------

Nx.VERSIONWare = .15                    -- Warehouse data version

-------------------------------------------------------------------------------
-- KEYBINDING DEFINITIONS
-------------------------------------------------------------------------------

BINDING_HEADER_CarboniteWarehouse = "|cffc0c0ff" .. L["Carbonite Warehouse"] .. "|r"
BINDING_NAME_NxTOGGLEWAREHOUSE = L["NxTOGGLEWAREHOUSE"]

-------------------------------------------------------------------------------
-- API COMPATIBILITY
-- Wrapper for container item info API changes
-------------------------------------------------------------------------------

local CharBags = {}
local BankBags = {}
local BandBags = {}
local BandBankActive = false

-- Check if Enum.BagIndex exists (not available in all Classic versions)
if Enum and Enum.BagIndex then
    -- Character bags
    CharBags = {
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
    }

    if Nx.isRetail then
        BandBankActive = true
        local CharBankTabsActive = Enum.BagIndex.CharacterBankTab_1 ~= nil
        if Enum.BagIndex.ReagentBag then
            table.insert(CharBags, Enum.BagIndex.ReagentBag)
        end

        if CharBankTabsActive then
            table.insert(BankBags, Enum.BagIndex.CharacterBankTab_1)
            table.insert(BankBags, Enum.BagIndex.CharacterBankTab_2)
            table.insert(BankBags, Enum.BagIndex.CharacterBankTab_3)
            table.insert(BankBags, Enum.BagIndex.CharacterBankTab_4)
            table.insert(BankBags, Enum.BagIndex.CharacterBankTab_5)
            table.insert(BankBags, Enum.BagIndex.CharacterBankTab_6)
        else
            table.insert(BankBags, Enum.BagIndex.Bank)
            table.insert(BankBags, Enum.BagIndex.BankBag_1)
            table.insert(BankBags, Enum.BagIndex.BankBag_2)
            table.insert(BankBags, Enum.BagIndex.BankBag_3)
            table.insert(BankBags, Enum.BagIndex.BankBag_4)
            table.insert(BankBags, Enum.BagIndex.BankBag_5)
            table.insert(BankBags, Enum.BagIndex.BankBag_6)
            table.insert(BankBags, Enum.BagIndex.BankBag_7)
        end

        if Enum.BagIndex.AccountBankTab_1 then
            BandBags = {
                Enum.BagIndex.AccountBankTab_1,
                Enum.BagIndex.AccountBankTab_2,
                Enum.BagIndex.AccountBankTab_3,
                Enum.BagIndex.AccountBankTab_4,
                Enum.BagIndex.AccountBankTab_5,
            }
        end
    elseif Nx.isClassicEra then
        table.insert(BankBags, Enum.BagIndex.Bank)
        table.insert(BankBags, Enum.BagIndex.BankBag_1)
        table.insert(BankBags, Enum.BagIndex.BankBag_2)
        table.insert(BankBags, Enum.BagIndex.BankBag_3)
        table.insert(BankBags, Enum.BagIndex.BankBag_4)
        table.insert(BankBags, Enum.BagIndex.BankBag_5)
        table.insert(BankBags, Enum.BagIndex.BankBag_6)
        table.insert(BankBags, Enum.BagIndex.BankBag_7)
        if Enum.BagIndex.ReagentBag then
            table.insert(BankBags, Enum.BagIndex.ReagentBag)
        end
    else
        -- MoP Classic / Cata Classic / other classic versions
        if Enum.BagIndex.Bank then
            table.insert(BankBags, Enum.BagIndex.Bank)
        end
        if Enum.BagIndex.BankBag_1 then
            table.insert(BankBags, Enum.BagIndex.BankBag_1)
            table.insert(BankBags, Enum.BagIndex.BankBag_2)
            table.insert(BankBags, Enum.BagIndex.BankBag_3)
            table.insert(BankBags, Enum.BagIndex.BankBag_4)
            table.insert(BankBags, Enum.BagIndex.BankBag_5)
            table.insert(BankBags, Enum.BagIndex.BankBag_6)
            table.insert(BankBags, Enum.BagIndex.BankBag_7)
        end
    end

    -- Keyring for older classic versions
    if not Nx.CataMaps and Enum.BagIndex.Keyring then
        table.insert(CharBags, Enum.BagIndex.Keyring)
    end
else
    -- Fallback for versions without Enum.BagIndex (use numeric constants)
    CharBags = { 0, 1, 2, 3, 4 }  -- BACKPACK_CONTAINER through bag 4
    BankBags = { -1, 5, 6, 7, 8, 9, 10, 11 }  -- BANK_CONTAINER and bank bags
end

function GetContainerItemInfo(bag, slot)
    local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
    if containerInfo then
        return containerInfo.iconFileID, containerInfo.stackCount, containerInfo.isLocked,
               containerInfo.quality, containerInfo.isReadable, containerInfo.hasLoot,
               containerInfo.hyperlink, containerInfo.isFiltered, containerInfo.hasNoValue,
               containerInfo.itemID, containerInfo.isBound
    end
    return nil
end

-------------------------------------------------------------------------------
-- DEFAULT OPTIONS
-- Default profile settings for warehouse module
-------------------------------------------------------------------------------

local defaults = {
    profile = {
        Warehouse = {
            -- Font settings
            WarehouseFont = "Friz",
            WarehouseFontSize = 11,
            WarehouseFontSpacing = 6,
            -- General settings
            Enable = true,
            AddTooltip = true,                  -- Add warehouse info to tooltips
            TooltipIgnore = true,               -- Use ignore list for tooltips
            IgnoreList = {},                    -- Items to ignore in tooltips
            ShowGold = false,                   -- Show gold in character list
            -- Auto sell settings
            SellTesting = false,                -- Test mode (don't actually sell)
            SellVerbose = false,                -- Show what was sold
            SellGreys = false,                  -- Sell grey items
            SellWhites = false,                 -- Sell white items
            SellWhitesiLVL = false,             -- Use iLevel filter for whites
            SellWhitesiLVLValue = 600,          -- Max iLevel for white sell
            SellGreens = false,                 -- Sell green items
            SellGreensBOP = false,              -- Sell BOP greens
            SellGreensBOE = false,              -- Sell BOE greens
            SellGreensiLVL = false,             -- Use iLevel filter for greens
            SellGreensiLVLValue = 600,          -- Max iLevel for green sell
            SellBlues = false,                  -- Sell blue items
            SellBluesiLVL = false,              -- Use iLevel filter for blues
            SellBluesiLVLValue = 600,           -- Max iLevel for blue sell
            SellBluesBOP = false,               -- Sell BOP blues
            SellBluesBOE = false,               -- Sell BOE blues
            SellPurps = false,                  -- Sell purple items
            SellPurpsiLVL = false,              -- Use iLevel filter for purples
            SellPurpsiLVLValue = 600,           -- Max iLevel for purple sell
            SellPurpsBOP = false,               -- Sell BOP purples
            SellPurpsBOE = false,               -- Sell BOE purples
            SellList = false,                   -- Use sell list
            SellingList = {},                   -- Items to auto-sell
            -- Auto repair settings
            RepairAuto = false,                 -- Auto repair gear
            RepairGuild = false,                -- Use guild funds first
        },
    },
}

-- Warehouse module namespace
Nx.Warehouse = {}

-------------------------------------------------------------------------------
-- CURRENCY TRACKING
-- Array of currency IDs to track
-------------------------------------------------------------------------------

local CurrencyArray = {
    61, 81, 241, 361, 384, 385, 391, 393, 394, 395, 396, 397, 398, 399, 400,
    401, 402, 416, 515, 614, 615, 676, 677, 697, 698, 738, 752, 754, 766, 777,
    789, 810, 821, 823, 824, 828, 829, 910, 944, 980, 994, 999, 1008, 1017,
    1020, 1101, 1129, 1149, 1154, 1155, 1166, 1171, 1172, 1173, 1174, 1191,
    1220, 1226, 1268, 1273, 1275, 1299, 1314, 1324, 1325, 1342, 1355, 1356,
    1357, 1379, 1416, 1501, 1506, 1508, 1533
}

local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo or GetCurrencyInfo

-------------------------------------------------------------------------------
-- OPTIONS CONFIGURATION
-- AceConfig options table for warehouse module settings
-------------------------------------------------------------------------------

local warehouseopts

---
-- Get or create warehouse options configuration
-- @return  Warehouse options table for AceConfig
--
local function WarehouseOptions()
    if not warehouseopts then
        warehouseopts = {
            type = "group",
            name = L["Warehouse Options"],
            childGroups = "tab",
            args = {
                main = {
                    order = 1,
                    name = L["Warehouse"],
                    type = "group",
                    args = {
                        toolTip = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Add Warehouse Tooltip"],
                            desc = L["When enabled, will show warehouse information in hover tooltips of items"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.AddTooltip
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.AddTooltip = not Nx.wdb.profile.Warehouse.AddTooltip
                            end,
                        },
                        showGold = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            name = L["Show coin count in warehouse list"],
                            desc = L["Restores the coin totals after character names in warehouse listing"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.ShowGold
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.ShowGold = not Nx.wdb.profile.Warehouse.ShowGold
                            end,
                        },
                        tiphidelist = {
                            order = 3,
                            name = L["Use don't display list"],
                            desc = L["If enabled, don't show listed items in tooltips"],
                            type = "toggle",
                            width = "full",
                            descStyle = "inline",
                            get = function()
                                return Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.TooltipIgnore = not Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                        },
                        hidenew = {
                            order = 4,
                            type = "input",
                            name = L["New Item To Ignore (Case Insensative)"],
                            desc = L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."],
                            width = "full",
                            disabled = function()
                                return not Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                            get = false,
                            set = function (info, value)
                                local name = C_Item.GetItemInfo(value)
                                name = name or value
                                StaticPopupDialogs["NX_AddIgnore"] = {
                                    text = L["Ignore"] .. " " .. value .. "?",
                                    button1 = L["Yes"],
                                    button2 = L["No"],
                                    OnAccept = function()
                                        Nx.wdb.profile.Warehouse.IgnoreList[name] = name
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                    end,
                                    hideOnEscape = true,
                                    whileDead = true,
                                }
                                local dlg = StaticPopup_Show("NX_AddIgnore")
                            end,
                        },
                        hidedelete = {
                            order = 5,
                            type = "select",
                            style = "radio",
                            name = L["Delete Item"],
                            disabled = function()
                                return not Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                            get = false,
                            values = Nx.wdb.profile.Warehouse.IgnoreList,
                            set = function(info, value)
                                StaticPopupDialogs["NX_DelIgnore"] = {
                                    text = L["Delete"] .. " " .. value .. "?",
                                    button1 = L["Yes"],
                                    button2 = L["No"],
                                    OnAccept = function()
                                        Nx.wdb.profile.Warehouse.IgnoreList[value] = nil
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                    end,
                                    hideOnEscape = true,
                                    whileDead = true,
                                }
                                local dlg = StaticPopup_Show("NX_DelIgnore")
                            end,
                        },
                        WareFont = {
                            order = 6,
                            type    = "select",
                            name    = L["Warehouse Font"],
                            desc    = L["Sets the font to be used for warehouse windows"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                for a,b in pairs(vals) do
                                  if (b == Nx.wdb.profile.Warehouse.WarehouseFont) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                Nx.wdb.profile.Warehouse.WarehouseFont = vals[name]
                                Nx.Opts:NXCmdFontChange()
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("FontFace","Get")
                            end,
                        },
                        WareFontSize = {
                            order = 7,
                            type = "range",
                            name = L["Warehouse Font Size"],
                            desc = L["Sets the size of the warehouse font"],
                            min = 6,
                            max = 14,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.wdb.profile.Warehouse.WarehouseFontSize
                            end,
                            set = function(info,value)
                                Nx.wdb.profile.Warehouse.WarehouseFontSize = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        WareFontSpacing = {
                            order = 8,
                            type = "range",
                            name = L["Warehouse Font Spacing"],
                            desc = L["Sets the spacing of the warehouse font"],
                            min = -10,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.wdb.profile.Warehouse.WarehouseFontSpacing
                            end,
                            set = function(info,value)
                                Nx.wdb.profile.Warehouse.WarehouseFontSpacing = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                    },
                },
                seller = {
                    order = 2,
                    name = L["Auto Sell"],
                    type = "group",
                    args = {
                        sellopts = {
                            order = 1,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                enabletest = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Test Selling"],
                                    desc = L["Enabling this allows you to see what would get sold, without actually selling."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellTesting
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellTesting = not Nx.wdb.profile.Warehouse.SellTesting
                                    end,
                                },
                                enableverb = {
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Verbose Selling"],
                                    desc = L["When enabled shows what items got sold instead of just the grand total earned."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellVerbose
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellVerbose = not Nx.wdb.profile.Warehouse.SellVerbose
                                    end,
                                },
                            },
                        },
                        greys = {
                            order = 2,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellgreys = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cff777777" .. L["Grey"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your grey items"],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreys
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreys = not Nx.wdb.profile.Warehouse.SellGreys
                                    end,
                                },
                            },
                        },
                        whites = {
                            order = 3,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellwhites = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cffffffff" .. L["White"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your white items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellWhites
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellWhites = not Nx.wdb.profile.Warehouse.SellWhites
                                    end,
                                },
                                whiteilvl = {
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellWhites
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellWhitesiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellWhitesiLVL = not Nx.wdb.profile.Warehouse.SellWhitesiLVL
                                    end,
                                },
                                whitevalue = {
                                    order = 3,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellWhites or not Nx.wdb.profile.Warehouse.SellWhitesiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellWhitesiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellWhitesiLVLValue = value
                                    end,
                                },
                            },
                        },
                        greens = {
                            order = 4,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellgreens = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cff00ff00" .. L["Green"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your green items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreens = not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                },
                                greepbop = {
                                    order = 2,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOP Items"],
                                    desc = L["When enabled will sell items that are BOP"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensBOP
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreensBOP = not Nx.wdb.profile.Warehouse.SellGreensBOP
                                    end,
                                },
                                greenboe = {
                                    order = 3,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOE Items"],
                                    desc = L["When enabled will sell items that are BOE"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensBOE
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreensBOE = not Nx.wdb.profile.Warehouse.SellGreensBOE
                                    end,
                                },
                                greenilvl = {
                                    order = 4,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreensiLVL = not Nx.wdb.profile.Warehouse.SellGreensiLVL
                                    end,
                                },
                                greenvalue = {
                                    order = 5,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens or not Nx.wdb.profile.Warehouse.SellGreensiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellGreensiLVLValue = value
                                    end,
                                },
                            },
                        },
                        blues = {
                            order = 5,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellblues = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cff3333ff" .. L["Blue"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your blue items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBlues = not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                },
                                bluebop = {
                                    order = 2,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOP Items"],
                                    desc = L["When enabled will sell items that are BOP"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesBOP
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBluesBOP = not Nx.wdb.profile.Warehouse.SellBluesBOP
                                    end,
                                },
                                blueboe = {
                                    order = 3,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOE Items"],
                                    desc = L["When enabled will sell items that are BOE"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesBOE
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBluesBOE = not Nx.wdb.profile.Warehouse.SellBluesBOE
                                    end,
                                },
                                blueilvl = {
                                    order = 4,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBluesiLVL = not Nx.wdb.profile.Warehouse.SellBluesiLVL
                                    end,
                                },
                                bluevalue = {
                                    order = 5,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues or not Nx.wdb.profile.Warehouse.SellBluesiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellBluesiLVLValue = value
                                    end,
                                },
                            },
                        },
                        purps = {
                            order = 6,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellpurps = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cffff00ff" .. L["Purple"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your purple items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurps = not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                },
                                purpbop = {
                                    order = 2,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOP Items"],
                                    desc = L["When enabled will sell items that are BOP"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsBOP
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurpsBOP = not Nx.wdb.profile.Warehouse.SellPurpsBOP
                                    end,
                                },
                                purpboe = {
                                    order = 3,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOE Items"],
                                    desc = L["When enabled will sell items that are BOE"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsBOE
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurpsBOE = not Nx.wdb.profile.Warehouse.SellPurpsBOE
                                    end,
                                },
                                purpilvl = {
                                    order = 4,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurpsiLVL = not Nx.wdb.profile.Warehouse.SellPurpsiLVL
                                    end,
                                },
                                purpvalue = {
                                    order = 5,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps or not Nx.wdb.profile.Warehouse.SellPurpsiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellPurpsiLVLValue = value
                                    end,
                                },
                            },
                        },
                        list = {
                            order = 7,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                selllist = {
                                    order = 1,
                                    name = L["Sell items based on a list"],
                                    desc = L["If item name matches one on the list, auto-sell it"],
                                    type = "toggle",
                                    width = "full",
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellList
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellList = not Nx.wdb.profile.Warehouse.SellList
                                    end,
                                },
                                new = {
                                    order = 2,
                                    type = "input",
                                    name = L["New Item To Sell (Case Insensative)"],
                                    desc = L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."],
                                    width = "full",
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellList
                                    end,
                                    get = false,
                                    set = function (info, value)
                                        local name = C_Item.GetItemInfo(value)
                                        name = name or value
                                        StaticPopupDialogs["NX_AddSell"] = {
                                            text = L["Add"] .. " " .. value .. "?",
                                            button1 = L["Yes"],
                                            button2 = L["No"],
                                            OnAccept = function()
                                                Nx.wdb.profile.Warehouse.SellingList[name] = name
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                            end,
                                            hideOnEscape = true,
                                            whileDead = true,
                                        }
                                        local dlg = StaticPopup_Show("NX_AddSell")
                                    end,
                                },
                                delete = {
                                    order = 3,
                                    type = "select",
                                    style = "radio",
                                    name = L["Delete Item"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellList
                                    end,
                                    get = false,
                                    values = Nx.wdb.profile.Warehouse.SellingList,
                                    set = function(info, value)
                                        StaticPopupDialogs["NX_DelSell"] = {
                                            text = L["Delete"] .. " " .. value .. "?",
                                            button1 = L["Yes"],
                                            button2 = L["No"],
                                            OnAccept = function()
                                                Nx.wdb.profile.Warehouse.SellingList[value] = nil
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                            end,
                                            hideOnEscape = true,
                                            whileDead = true,
                                        }
                                        local dlg = StaticPopup_Show("NX_DelSell")
                                    end,
                                },
                            },
                        },
                    },
                },
                repair = {
                    order = 3,
                    name = L["Auto Repair"],
                    type = "group",
                    args = {
                        autorepair = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            descStyle = "inline",
                            name = L["Auto Repair Gear"],
                            desc = L["When you open a merchant, will attempt to auto repair your gear"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.RepairAuto
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.RepairAuto = not Nx.wdb.profile.Warehouse.RepairAuto
                            end,
                        },
                        guildrepair = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            descStyle = "inline",
                            disabled = function()
                                return not Nx.wdb.profile.Warehouse.RepairAuto
                            end,
                            name = L["Use Guild Repair First"],
                            desc = L["Will try to use guild funds to pay for repairs before your own"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.RepairGuild
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.RepairGuild = not Nx.wdb.profile.Warehouse.RepairGuild
                            end,
                        },
                    },
                },
            },
        }
    end
    Nx.Opts:AddToProfileMenu(L["Warehouse"], 5, Nx.wdb)
    return warehouseopts
end

-------------------------------------------------------------------------------
-- MODULE INITIALIZATION
-------------------------------------------------------------------------------

---
-- AceAddon initialization callback
-- Sets up database, events, button types, and tooltip hooks
--
function CarboniteWarehouse:OnInitialize()
    if not Nx.Initialized then
        CarbWHInit = Nx:ScheduleTimer(CarboniteWarehouse.OnInitialize,1)
        return
    end
    Nx.wdb = LibStub("AceDB-3.0"):New("NXWhouse",defaults, true)
    Nx.Warehouse:ConvertData()
    Nx.Warehouse:InitWarehouseCharacter()
    Nx.Font:ModuleAdd("Warehouse.WarehouseFont",{ "NxFontWHI", "GameFontNormal","wdb" })
    Nx.Warehouse:Init()
    Nx.Warehouse:Login()
    local function func ()
        Nx.Warehouse:ToggleShow()
    end
    Nx.NXMiniMapBut.Menu:AddItem(0, L["Show Warehouse"], func, Nx.NXMiniMapBut)
    CarboniteWarehouse:RegisterEvent("BAG_UPDATE","EventHandler")
    CarboniteWarehouse:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "EventHandler")
    --CarboniteWarehouse:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", "EventHandler")
    --CarboniteWarehouse:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("BANKFRAME_OPENED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("BANKFRAME_CLOSED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("GUILDBANKFRAME_OPENED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("GUILDBANKFRAME_CLOSED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("ITEM_LOCK_CHANGED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("MAIL_INBOX_UPDATE", "EventHandler")
    CarboniteWarehouse:RegisterEvent("UNIT_INVENTORY_CHANGED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("MERCHANT_SHOW", "EventHandler")
    CarboniteWarehouse:RegisterEvent("MERCHANT_CLOSED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("TIME_PLAYED_MSG", "EventHandler")
    CarboniteWarehouse:RegisterEvent("LOOT_OPENED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("LOOT_SLOT_CLEARED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("LOOT_CLOSED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("CHAT_MSG_SKILL", "EventHandler")
    CarboniteWarehouse:RegisterEvent("SKILL_LINES_CHANGED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("TRADE_SKILL_CLOSE", "EventHandler")
    CarboniteWarehouse:RegisterEvent("TRADE_SKILL_SHOW", "EventHandler")
    CarboniteWarehouse:RegisterEvent("PLAYER_LOGIN","EventHandler")
    CarboniteWarehouse:RegisterEvent("TIME_PLAYED_MSG","EventHandler")
    CarboniteWarehouse:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("UNIT_SPELLCAST_FAILED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "EventHandler")
    CarboniteWarehouse:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "EventHandler")
    GuildBank.RegisterCallback(CarboniteWarehouse,"GuildBankComm_PageUpdate", "OnPageSync")
    GuildBank.RegisterCallback(CarboniteWarehouse, "GuildBankComm_FundsUpdate", "OnMoneySync")
    GuildBank.RegisterCallback(CarboniteWarehouse, "GuildBankComm_TabsUpdate", "OnTabSync")

    Nx.Button.TypeData["MapWarehouse"] = {
        Up = "$INV_Misc_EngGizmos_17",
        SizeUp = 22,
        SizeDn = 22,
    }
    Nx.Button.TypeData["Warehouse"] = {
        Bool = true,
        Up = "$INV_Misc_QuestionMark",
        Dn = "$INV_Misc_QuestionMark",
        SizeUp = 18,
        SizeDn = 11,
    }
    Nx.Button.TypeData["WarehouseItem"] = {
        Up = "$INV_Misc_QuestionMark",
        Dn = "$INV_Misc_QuestionMark",
        SizeUp = 16,
        SizeDn = 16,
    }
    Nx.Button.TypeData["WarehouseProf"] = {
        Up = "Interface\\TradeSkillFrame\\UI-TradeSkill-LinkButton",
        Dn = "Interface\\TradeSkillFrame\\UI-TradeSkill-LinkButton",
        SizeUp = 16,
        SizeDn = 14,
        UpUV = { 0, 1, 0, .5 },
    }
    tinsert (Nx.BarData,{"MapWarehouse", L["-Warehouse-"], Nx.Warehouse.OnButToggleWarehouse, false })
    Nx.Map.Maps[1]:CreateToolBar()

    ---------------------------------------------------------------------------
    -- Tooltip Hooks - Version-specific
    -- Priority: GameTooltip_UpdateStyle > TooltipDataProcessor > Individual hooks
    ---------------------------------------------------------------------------

    if GameTooltip_UpdateStyle then
        -- GameTooltip_UpdateStyle: Available in Classic and Shadowlands
        -- This is the simplest approach - one hook catches all tooltip updates
        hooksecurefunc("GameTooltip_UpdateStyle", Nx.Warehouse.TooltipProcess)

    elseif TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- TooltipDataProcessor: Dragonflight+ modern tooltip system
        -- Used when GameTooltip_UpdateStyle is not available
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip then
                Nx.Warehouse.TooltipProcess()
            elseif tooltip == ItemRefTooltip then
                Nx.Warehouse.ReftipProcess()
            end
        end)

    else
        -- Fallback: Individual tooltip method hooks
        -- Used when neither GameTooltip_UpdateStyle nor TooltipDataProcessor is available
        local ttHooks = {
            "SetAction",
            "SetBagItem",
            "SetHyperlink",
            "SetInboxItem",
            "SetInventoryItem",
            "SetLootItem",
            "SetLootRollItem",
            "SetMerchantItem",
            "SetQuestItem",
            "SetQuestLogItem",
            "SetTradeTargetItem",
            "SetAuctionItem",
        }

        -- SetGuildBankItem: Available from TBC+ (guild banks added in TBC 2.3)
        if Nx.TBCMaps then
            tinsert(ttHooks, "SetGuildBankItem")
        end

        -- SetCraftItem / SetTradeSkillItem: Classic crafting system
        tinsert(ttHooks, "SetCraftItem")
        tinsert(ttHooks, "SetTradeSkillItem")

        -- SetRecipeReagentItem / SetRecipeResultItem: Newer crafting system (WoD+)
        if Nx.WODMaps then
            tinsert(ttHooks, "SetRecipeReagentItem")
            tinsert(ttHooks, "SetRecipeResultItem")
        end

        -- Hook the tooltip methods that exist in this version
        for k, name in ipairs(ttHooks) do
            if GameTooltip[name] then
                hooksecurefunc(GameTooltip, name, Nx.Warehouse.TooltipProcess)
            end
            if ItemRefTooltip[name] then
                hooksecurefunc(ItemRefTooltip, name, Nx.Warehouse.ReftipProcess)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Auction House Hooks - Version-specific
    -- Old AH API (pre-BFA 8.3) vs New AH API (BFA 8.3+)
    ---------------------------------------------------------------------------

    -- Old Auction House API: Classic through BFA 8.2
    if PlaceAuctionBid then
        hooksecurefunc("PlaceAuctionBid", function(ltype, index, bid)
            local link = GetAuctionItemLink(ltype, index)
            local _, _, count, _, _, _, _, _, _, buyout = GetAuctionItemInfo(ltype, index)
            if not link or bid ~= buyout then
                return
            end
            Nx.Warehouse.onAuctionHouseUpdate(link, count)
        end)
    end

    if CancelAuction then
        hooksecurefunc("CancelAuction", function(index)
            local link = GetAuctionItemLink("owner", index)
            local _, _, count = GetAuctionItemInfo("owner", index)
            if not link or not count or count == 0 then
                return
            end
            Nx.Warehouse.onAuctionHouseUpdate(link, count)
        end)
    end

    -- New Auction House API: BFA 8.3+ and MoP Classic (retail client base)
    if C_AuctionHouse and C_AuctionHouse.ConfirmCommoditiesPurchase then
        hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(itemID, count)
            local name, link = C_Item.GetItemInfo(itemID)
            if not link or not count then
                return
            end
            Nx.Warehouse.onAuctionHouseUpdate(link, count)
        end)
    end

    Nx:AddToConfig("Warehouse Module",WarehouseOptions(),L["Warehouse Module"])
    tinsert(Nx.BrokerMenuTemplate,{ text = L["Toggle Warehouse"], func = function() Nx.Warehouse:ToggleShow() end })
    if Nx.RequestTime then
        RequestTimePlayed()
    end
end

-------------------------------------------------------------------------------
-- GUILD BANK SYNCHRONIZATION
-- Callbacks for LibGuildBankComm synchronization
-------------------------------------------------------------------------------

---
-- Handle guild bank page sync from another player
-- @param event      Event name
-- @param sender     Sending player
-- @param page       Bank page number
-- @param guildName  Guild name
--
function CarboniteWarehouse:OnPageSync(event, sender, page, guildName)
    local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()
    local rnGuilds = ware[rn] or {}
    ware[rn] = rnGuilds
    local guild = rnGuilds[guildName] or {}
    rnGuilds[guildName] = guild
    if not guild["Tab" .. page] then
            guild["Tab" .. page] = {}
    end
    guild["Tab" .. page]["Inv"] = {}
    for slot, link, stack in GuildBank:IteratePage(page) do
        if stack and link then
            guild["Tab" .. page]["Inv"][slot] = format("%s^%s",stack,link)
        end
    end
    guild["Tab" .. page]["ScanTime"] = time()
end

---
-- Handle guild bank money sync from another player
-- @param event      Event name
-- @param sender     Sending player
-- @param newFunds   New fund amount
-- @param guildName  Guild name
--
function CarboniteWarehouse:OnMoneySync(event, sender, newFunds, guildName)
    local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()
    local rnGuilds = ware[rn] or {}
    ware[rn] = rnGuilds
    local guild = rnGuilds[guildName] or {}
    rnGuilds[guildName] = guild
    guild["Money"] = newFunds
end

---
-- Handle guild bank tab info sync from another player
-- @param event      Event name
-- @param sender     Sending player
-- @param numTabs    Number of tabs
-- @param guildName  Guild name
--
function CarboniteWarehouse:OnTabSync(event, sender, numTabs, guildName)
    local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()
    local rnGuilds = ware[rn] or {}
    ware[rn] = rnGuilds
    local guild = rnGuilds[guildName] or {}
    rnGuilds[guildName] = guild
    for i = 1, numTabs do
        local name, icon = GuildBank:GetTabInfo(i)
        if not guild["Tab" .. i] then
            guild["Tab" .. i] = {}
        end
        guild["Tab" .. i].Name = name
        guild["Tab" .. i].Icon = icon
    end
end

-------------------------------------------------------------------------------
-- DATA CONVERSION
-- Migrate warehouse data from old format to new
-------------------------------------------------------------------------------

---
-- Convert warehouse data from main db to warehouse db
--
function Nx.Warehouse:ConvertData()
    if not Nx.wdb.global then
        Nx.wdb.global = {}
    end
    if not Nx.wdb.global.Characters then
        Nx.wdb.global.Characters = {}
    end
    for ch,data in pairs(Nx.db.global.Characters) do
        if not Nx.wdb.global.Characters[ch] then
            Nx.wdb.global.Characters[ch] = {}
        end
        if Nx.db.global.Characters[ch].WareBank then
            Nx.wdb.global.Characters[ch].WareBank = Nx.db.global.Characters[ch].WareBank
            Nx.db.global.Characters[ch].WareBank = nil
        end
        if Nx.db.global.Characters[ch].WareMail then
            Nx.wdb.global.Characters[ch].WareMail = Nx.db.global.Characters[ch].WareMail
            Nx.db.global.Characters[ch].WareMail = nil
        end
        if Nx.db.global.Characters[ch].WareBank then
            Nx.wdb.global.Characters[ch].WareBank = Nx.db.global.Characters[ch].WareBank
            Nx.db.global.Characters[ch].WareBank = nil
        end
        if Nx.db.global.Characters[ch].Time then
            Nx.wdb.global.Characters[ch].Time = Nx.db.global.Characters[ch].Time
            Nx.db.global.Characters[ch].Time = nil
        end
        if Nx.db.global.Characters[ch].LMoney then
            Nx.wdb.global.Characters[ch].LMoney = Nx.db.global.Characters[ch].LMoney
            Nx.db.global.Characters[ch].LMoney = nil
        end
        if Nx.db.global.Characters[ch].Profs then
            Nx.wdb.global.Characters[ch].Profs = Nx.db.global.Characters[ch].Profs
            Nx.db.global.Characters[ch].Profs = nil
        end
        if Nx.db.global.Characters[ch].LXP then
            Nx.wdb.global.Characters[ch].LXP = Nx.db.global.Characters[ch].LXP
            Nx.db.global.Characters[ch].LXP = nil
        end
        if Nx.db.global.Characters[ch].LHonor then
            Nx.wdb.global.Characters[ch].LHonor = Nx.db.global.Characters[ch].LHonor
            Nx.db.global.Characters[ch].LHonor = nil
        end
        if Nx.db.global.Characters[ch].DurLowPercent then
            Nx.wdb.global.Characters[ch].DurLowPercent = Nx.db.global.Characters[ch].DurLowPercent
            Nx.db.global.Characters[ch].DurLowPercent = nil
        end
        if Nx.db.global.Characters[ch].XPMax then
            Nx.wdb.global.Characters[ch].XPMax = Nx.db.global.Characters[ch].XPMax
            Nx.db.global.Characters[ch].XPMax = nil
        end
        if Nx.db.global.Characters[ch].Conquest then
            Nx.wdb.global.Characters[ch].Conquest = Nx.db.global.Characters[ch].Conquest
            Nx.db.global.Characters[ch].Conquest = nil
        end
        if Nx.db.global.Characters[ch].LArenaPts then
            Nx.wdb.global.Characters[ch].LArenaPts = Nx.db.global.Characters[ch].LArenaPts
            Nx.db.global.Characters[ch].LArenaPts = nil
        end
        if Nx.db.global.Characters[ch].TimePlayed then
            Nx.wdb.global.Characters[ch].TimePlayed = Nx.db.global.Characters[ch].TimePlayed
            Nx.db.global.Characters[ch].TimePlayed = nil
        end
        if Nx.db.global.Characters[ch].XP then
            Nx.wdb.global.Characters[ch].XP = Nx.db.global.Characters[ch].XP
            Nx.db.global.Characters[ch].XP = nil
        end
        if Nx.db.global.Characters[ch].XPRest then
            Nx.wdb.global.Characters[ch].XPRest = Nx.db.global.Characters[ch].XPRest
            Nx.db.global.Characters[ch].XPRest = nil
        end
        if Nx.db.global.Characters[ch].Honor then
            Nx.wdb.global.Characters[ch].Honor = Nx.db.global.Characters[ch].Honor
            Nx.db.global.Characters[ch].Honor = nil
        end
        if Nx.db.global.Characters[ch].Money then
            Nx.wdb.global.Characters[ch].Money = Nx.db.global.Characters[ch].Money
            Nx.db.global.Characters[ch].Money = nil
        end
        if Nx.db.global.Characters[ch].WareBags then
            Nx.wdb.global.Characters[ch].WareBags = Nx.db.global.Characters[ch].WareBags
            Nx.db.global.Characters[ch].WareBags = nil
        end
        if Nx.db.global.Characters[ch].LXPMax then
            Nx.wdb.global.Characters[ch].LXPMax = Nx.db.global.Characters[ch].LXPMax
            Nx.db.global.Characters[ch].LXPMax = nil
        end
        if Nx.db.global.Characters[ch].LTime then
            Nx.wdb.global.Characters[ch].LTime = Nx.db.global.Characters[ch].LTime
            Nx.db.global.Characters[ch].LTime = nil
        end
        if Nx.db.global.Characters[ch].LXPRest then
            Nx.wdb.global.Characters[ch].LXPRest = Nx.db.global.Characters[ch].LXPRest
            Nx.db.global.Characters[ch].LXPRest = nil
        end
        if Nx.db.global.Characters[ch].DurPercent then
            Nx.wdb.global.Characters[ch].DurPercent = Nx.db.global.Characters[ch].DurPercent
            Nx.db.global.Characters[ch].DurPercent = nil
        end
        if Nx.db.global.Characters[ch].WareInv then
            Nx.wdb.global.Characters[ch].WareInv = Nx.db.global.Characters[ch].WareInv
            Nx.db.global.Characters[ch].WareInv = nil
        end
        if Nx.db.global.Characters[ch].LvlTime then
            Nx.wdb.global.Characters[ch].LvlTime = Nx.db.global.Characters[ch].LvlTime
            Nx.db.global.Characters[ch].LvlTime = nil
        end
        if Nx.db.global.Characters[ch].Pos then
            Nx.wdb.global.Characters[ch].Pos = Nx.db.global.Characters[ch].Pos
            Nx.db.global.Characters[ch].Pos = nil
        end
        if Nx.db.global.Characters[ch].WHHide then
            Nx.wdb.global.Characters[ch].WHHide = Nx.db.global.Characters[ch].WHHide
            Nx.db.global.Characters[ch].WHHide = nil
        end
        if Nx.db.global.Characters[ch].Garrison then
            Nx.wdb.global.Characters[ch].Garrison = Nx.db.global.Characters[ch].Garrison
            Nx.db.global.Characters[ch].Garrison = nil
        end
        if Nx.db.global.Characters[ch].Apexis then
            Nx.wdb.global.Characters[ch].Apexis = Nx.db.global.Characters[ch].Apexis
            Nx.db.global.Characters[ch].Apexis = nil
        end
        if Nx.db.global.Characters[ch].Nethershard then
            Nx.wdb.global.Characters[ch].Nethershard = Nx.db.global.Characters[ch].Nethershard
            Nx.db.global.Characters[ch].Nethershard = nil
        end
        if Nx.db.global.Characters[ch].WareRBank then
            Nx.wdb.global.Characters[ch].WareRBank = Nx.db.global.Characters[ch].WareRBank
            Nx.db.global.Characters[ch].WareRBank = nil
        end
        if Nx.db.global.Characters[ch].OrderHall then
            Nx.wdb.global.Characters[ch].OrderHall = Nx.db.global.Characters[ch].OrderHall
            Nx.db.global.Characters[ch].OrderHall = nil
        end
        if Nx.db.global.Characters[ch].Class then
            Nx.wdb.global.Characters[ch].Class = Nx.db.global.Characters[ch].Class
        end
        if Nx.db.global.Characters[ch].Level then
            Nx.wdb.global.Characters[ch].Level = Nx.db.global.Characters[ch].Level
        end
    end
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-- Central event dispatcher for warehouse events
-------------------------------------------------------------------------------

---
-- Main event handler for warehouse events
-- @param event  Event name
-- @param arg1   First event argument
-- @param arg2   Second event argument
-- @param arg3   Third event argument
--
function CarboniteWarehouse:EventHandler(event, arg1, arg2, arg3)
    if event == "BAG_UPDATE" then
        Nx.Warehouse:OnBag_update()
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        Nx.Warehouse:OnBag_update()
    elseif event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
        Nx.Warehouse:ScanRBank()
    elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
        Nx.Warehouse:OnBag_update()
    elseif event == "BANKFRAME_OPENED" then
        Nx.Warehouse:OnBankframe_opened()
    elseif event == "BANKFRAME_CLOSED" then
        Nx.Warehouse:OnBankframe_closed()
    elseif event == "GUILDBANKFRAME_OPENED" then
        Nx.Warehouse:OnGuildbankframe_opened()
    elseif event == "GUILDBANKFRAME_CLOSED" then
        Nx.Warehouse:OnGuildbankframe_closed()
    elseif event == "ITEM_LOCK_CHANGED" then
        Nx.Warehouse:OnItem_lock_changed(arg1, arg2)
    elseif event == "MAIL_INBOX_UPDATE" then
        Nx.Warehouse:OnMail_inbox_update()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        Nx.Warehouse:OnUnit_inventory_changed(arg1)
    elseif event == "MERCHANT_SHOW" then
        Nx.Warehouse:OnMerchant_show()
    elseif event == "MERCHANT_CLOSED" then
        Nx.Warehouse:OnMerchant_closed()
    elseif event == "LOOT_OPENED" then
        Nx.Warehouse:OnLoot_opened(arg1, arg2)
    elseif event == "LOOT_SLOT_CLEARED" then
        Nx.Warehouse:OnLoot_slot_cleared(arg1)
    elseif event == "LOOT_CLOSED" then
        Nx.Warehouse:OnLoot_closed()
    elseif event == "CHAT_MSG_SKILL" then
        Nx.Warehouse:OnChat_msg_skill()
    elseif event == "SKILL_LINES_CHANGED" then
        Nx.Warehouse:OnChat_msg_skill()
    elseif event == "TRADE_SKILL_CLOSE" then
        Nx.Warehouse:OnTrade_skill_update()
    elseif event == "TRADE_SKILL_SHOW" then
        Nx.Warehouse:OnTrade_skill_update()
    elseif event == "PLAYER_LOGIN" then
        Nx.Warehouse:Login(event,arg1)
    elseif event == "TIME_PLAYED_MSG" then
        Nx.Warehouse:OnTime_played_msg(event,arg1,arg2)
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        Nx.Warehouse:OnUnit_spellcast_interrupted(event, arg1)
    elseif event == "UNIT_SPELLCAST_FAILED" then
        Nx.Warehouse:OnUnit_spellcast_interrupted(event, arg1)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        Nx.Warehouse:OnUnit_spellcast_succeeded(event, arg1, arg2, arg3)
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        Nx.Warehouse:RecordCurrency()
    else
        Nx.prt("ERROR: Event " .. event .. " triggered without function.")
    end
end

-------------------------------------------------------------------------------
-- EVENT CALLBACKS
-- Individual event handler functions
-------------------------------------------------------------------------------

---
-- Handle TIME_PLAYED_MSG event
-- @param event  Event name
-- @param arg1   Total time played
-- @param arg2   Time this level
--
function Nx.Warehouse:OnTime_played_msg(event, arg1, arg2)
    Nx.Warehouse.TimePlayed = arg1
    if Nx.RequestTime == false then
        Nx.prt("Total Time Played: " .. Nx.Util_SecondsToDays(arg1))
        Nx.prt("Time played this level: " .. Nx.Util_SecondsToDays(arg2))
    end
    Nx.RequestTime = false
    local ch = Nx.Warehouse.CurCharacter
    Nx.Warehouse:GuildRecord()
    if Nx.Warehouse.TimePlayed then
        ch["TimePlayed"] = Nx.Warehouse.TimePlayed
        Nx.Warehouse.TimePlayed = nil
    end
end

function Nx.Warehouse:OnUnit_spellcast_interrupted (event, arg1)

    if arg1 == "player" then
        Nx.GatherTarget = nil
        Nx.Warehouse.LootTarget = nil
    end
end

function Nx.Warehouse:OnUnit_spellcast_succeeded (event, arg1, arg2, arg3)

    if arg1 == "player" then
        if arg2 == NXlOpening or arg2 == NXlOpeningNoText then

            if Nx.GatherTarget then
                Nx.Warehouse.LootTarget = format ("O^%s", Nx.GatherTarget)
                Nx.GatherTarget = nil
            end
        end
    end
end

-------------------------------------------------------------------------------
-- WAREHOUSE INITIALIZATION
-- Setup warehouse data structures and UI resources
-------------------------------------------------------------------------------

---
-- Initialize the warehouse system
-- Sets up data version, class icons, inventory names, and tooltip scanner
--
function Nx.Warehouse:Init()
    local ware = Nx.wdb.profile.WarehouseData

    -- Check and upgrade data version if needed
    if not ware or ware.Version < Nx.VERSIONWare then
        if ware then
            Nx.prt("Reset old warehouse data %f", ware.Version)
        end

        ware = {}
        Nx.wdb.profile.WarehouseData = ware
        ware.Version = Nx.VERSIONWare
    end

    self.Enabled = Nx.wdb.profile.Warehouse.Enable
    self.SkillRiding = 0

    -- Class icons for character list display
    self.ClassIcons = {
        ["Druid"] = "Ability_Druid_Maul",
        ["Hunter"] = "INV_Weapon_Bow_07",
        ["Mage"] = "INV_Staff_13",
        ["Paladin"] = "INV_Hammer_01",
        ["Priest"] = "INV_Staff_30",
        ["Rogue"] = "INV_ThrowingKnife_04",
        ["Shaman"] = "Spell_Nature_BloodLust",
        ["Warlock"] = "Spell_Nature_FaerieFire",
        ["Warrior"] = "INV_Sword_27",
        ["Death Knight"] = "Spell_Deathknight_ClassIcon",
        ["Monk"] = "class_monk",
        ["Demonhunter"] = "INV_Glaive_1h_npc_d_01",
    }

    self.InvNames = {
        "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot",
        "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
        "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot",
        "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
        "MainHandSlot", "SecondaryHandSlot", "AmmoSlot", --"RangedSlot",
        "Bag0Slot", "Bag1Slot", "Bag2Slot", "Bag3Slot"
    }

--    self.LProfessions = TRADE_SKILLS
--    self.LSecondarySkills = gsub (SECONDARY_SKILLS, ":", "")

    self.ItemTypes = L["ItemTypes"]

    -- Create durability scanner tooltip

    self.DurInvNames = {
        "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot",
        "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot",
        "MainHandSlot", "SecondaryHandSlot" --, "RangedSlot"
    }

    self.DurTooltipFrm = CreateFrame ("GameTooltip", "NxTooltipD", UIParent, "GameTooltipTemplate")
    self.DurTooltipFrm:SetOwner (UIParent, "ANCHOR_NONE")        -- We won't see with this anchor
end

-------------------------------------------------------------------------------
-- LOGIN AND CHARACTER DATA
-------------------------------------------------------------------------------

---
-- Handle player login event
-- Records character data and guild information
-- @param event  Event name
-- @param arg1   Event argument
--
function Nx.Warehouse:Login(event, arg1)
    local ch = Nx.Warehouse.CurCharacter
    Nx.Warehouse:RecordCharacterLogin()
    Nx.Warehouse:GuildRecord()
    if Nx.Warehouse.TimePlayed then
        ch["TimePlayed"] = Nx.Warehouse.TimePlayed
--        Nx.Warehouse.TimePlayed = nil
        Nx.prt(Nx.Warehouse.TimePlayed)
        if Nx.BlizzChatFrame_DisplayTimePlayed then
            ChatFrame_DisplayTimePlayed = Nx.BlizzChatFrame_DisplayTimePlayed        -- Restore
            Nx.BlizzChatFrame_DisplayTimePlayed = nil
        end
    end
end

---
-- Debug print function
-- Only prints if debug mode is enabled
--
function Nx.Warehouse:prtdb(...)
    if self.Debug then
        Nx.prt(...)
    end
end

-------------------------------------------------------------------------------
-- WAREHOUSE WINDOW
-- Create and manage the warehouse UI window
-------------------------------------------------------------------------------

---
-- Create the warehouse window
-- Sets up window, lists, edit box, and menus
--
function Nx.Warehouse:Create()
    self.SelectedChar = 1
--    self.SelectedProf = nil

    self.ShowItemCategory = true

    -- Create Window

    local win = Nx.Window:Create ("NxWarehouse", nil, nil, nil, 1)
    self.Win = win
    win.Frm.NxInst = self

    win:CreateButtons (true, true)

    win:InitLayoutData (nil, -.25, -.15, -.5, -.6)
    win.Frm:SetToplevel (true)

    win:Show (false)

    tinsert (UISpecialFrames, win.Frm:GetName())

    -- Back button

--    but = Nx.Button:Create (win.Frm, "Txt", "Back", nil, 0, 0, "TOPLEFT", 100, 16, self.But_OnBack, g)

--    win:Attach (but.Frm, 2, 2+40, 1.01, 11)

    -- Character List

    Nx.List:SetCreateFont ("Font.Medium", 16)

    local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm)
    self.List = list

    list:SetUser (self, self.OnListEvent)

    list:SetLineHeight (4)

    list:ColumnAdd ("", 1, 24)
    list:ColumnAdd ("Name", 2, 900)

    win:Attach (list.Frm, 0, .5, 0, 1)

    -- Item List

    Nx.List:SetCreateFont ("Warehouse.WarehouseFont", 16)

    local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm)
    self.ItemList = list

    list:SetUser (self, self.OnItemListEvent)

--    list:SetLineHeight (3)

    list:ColumnAdd ("", 1, 17)
    list:ColumnAdd ("", 2, 35, "RIGHT", "Font.Small")
    list:ColumnAdd ("", 3, 900)

    win:Attach (list.Frm, .5, 1, 18, 1)

    -- Filter Edit Box

    self.EditBox = Nx.EditBox:Create (win.Frm, self, self.OnEditBox, 30)

    win:Attach (self.EditBox.Frm, .5, 1, 0, 18)

    --

    self:CreateMenu()

    --

    self:Update()

    self.List:Select (3)
    self.List:FullUpdate()

--PAIDE!

end

-------------------------------------------------------------------------------
-- CONTEXT MENUS
-- Create warehouse context menus
-------------------------------------------------------------------------------

---
-- Create the context menus for character and item lists
--
function Nx.Warehouse:CreateMenu()

    local menu = Nx.Menu:Create (self.List.Frm, 250)
    self.Menu = menu

    local item = menu:AddItem (0, L["Remove Character or Guild"], self.Menu_OnRemoveChar, self)

    menu:AddItem (0, "", nil, self)
    menu:AddItem (0, L["Import settings from selected character"], self.Menu_OnImport, self)
    menu:AddItem (0, L["Export current settings to all characters"], self.Menu_OnExport, self)

    menu:AddItem (0, "", nil, self)
    menu:AddItem (0, L["Sync account transfer file"], self.Menu_OnSyncAccount, self)

    local menu = Nx.Menu:Create (self.List.Frm, 250)
    self.IListMenu = menu

    self.NXEqRarityMin = 7

    local item = menu:AddItem (0, L["Show Lowest Equipped Rarity"], self.Menu_OnRarityMin, self)
    item:SetSlider (self, 0, 7, 1, "NXEqRarityMin")

    local item = menu:AddItem (0, L["Show Item Headers"], self.Menu_OnShowItemCat, self)
    item:SetChecked (true)

    local item = menu:AddItem (0, L["Sort By Rarity"], self.Menu_OnSortByRarity, self)
    item:SetChecked (false)

    self.NXRarityMin = 0

    local item = menu:AddItem (0, L["Show Lowest Rarity"], self.Menu_OnRarityMin, self)
    item:SetSlider (self, 0, 7, 1, "NXRarityMin")

    local item = menu:AddItem (0, L["Sort By Slot"], self.Menu_OnSortBySlot, self)
    item:SetChecked (false)
end

function Nx.Warehouse:Menu_OnRemoveChar (item)

    if self.SelectedGuild then

        self:GuildDelete (self.SelectedGuild)
        self.SelectedGuild = false

    else

        local cn = self.SelectedChar
        local rc = Nx.RealmChars[cn]
        if cn > 1 and rc then

            tremove (Nx.RealmChars, cn)
            Nx.db.global.Characters[rc] = nil
            Nx.wdb.global.Characters[rc] = nil
            self.SelectedChar = 1
        end
    end

    self:Update()
end

function Nx.Warehouse:Menu_OnImport (item)

    local cn = self.SelectedChar
    local rc = Nx.RealmChars[cn]
    if cn > 1 and rc then

        local rname, sname = Nx.Split (".", rc)
        self.ImportChar = sname

        local s = format (L["Import %s's character data and reload?"], sname)
        Nx:ShowMessage (s, L["Import"], Nx.Warehouse.ImportDo, L["Cancel"])
    end
end

function Nx.Warehouse.ImportDo()

    local self = Nx.Warehouse
    local dname = UnitName ("player")

    if Nx:CopyCharacterData (self.ImportChar, dname) then
        ReloadUI()
    end
end

function Nx.Warehouse:Menu_OnExport (item)
    local s = format (L["Overwrite all character settings and reload?"], sname)
    Nx:ShowMessage (s, L["Export"], Nx.Warehouse.ExportDo, L["Cancel"])
end

function Nx.Warehouse.ExportDo()

    if Nx:CopyCharacterData() then
        ReloadUI()
    end
end

function Nx.Warehouse:Menu_OnSyncAccount()
    Nx.Warehouse.ImportDo()
    Nx.Warehouse.ExportDo()
    Nx:CalcRealmChars()
    self:Update()
end

function Nx.Warehouse:Menu_OnShowItemCat (item)
    self.ShowItemCategory = item:GetChecked()
    self:Update()
end

function Nx.Warehouse:Menu_OnSortByRarity (item)
    self.SortByRarity = item:GetChecked()
    self:Update()
end

function Nx.Warehouse:Menu_OnRarityMin (item)
    self:Update()
end

function Nx.Warehouse:Menu_OnSortBySlot (item)
    self.SortBySlot = item:GetChecked()
    self:Update()
end

-------------------------------------------------------------------------------
-- WINDOW VISIBILITY
-------------------------------------------------------------------------------

---
-- Keybinding handler to toggle warehouse window
--
function Nx:NXWarehouseKeyToggleShow()
    Nx.Warehouse:ToggleShow()
end

---
-- Toggle the warehouse window visibility
--
function Nx.Warehouse:ToggleShow()

    if not self.Win then
        self:Create()
    end

    self.Win:Show (not self.Win:IsShown())

    if self.Win:IsShown() then

        self:CaptureInvDurabilityTimer()
        self:Update()
    end

--PAIDE!
end

--------
-- Handle item list filter edit box

function Nx.Warehouse:OnEditBox (editbox, message)

    if message == "Changed" then
        self:Update()
    end
end

-------------------------------------------------------------------------------
-- On list events
-------------------------------------------------------------------------------

function Nx.Warehouse:OnListEvent (eventName, sel, val2, click)

--    Nx.prt ("Guide list event "..eventName)

    local data = self.List:ItemGetData (sel) or 0
    local id = data % 1000
--    local prof = floor (data / 1000)

    local prof = self.List:ItemGetDataEx (sel, 1)

    self.SelectedGuild = false
    self.SelectedProf = false
    self.SelectedChar = false

    if (id >= 1 and id <= #Nx.RealmChars) or id == 99 then
        self.SelectedChar = id
    end
    if eventName == "select" or eventName == "mid" or eventName == "menu" then

        if id == 100 then
            self.SelectedGuild = prof
        else
            self.SelectedProf = prof
        end

        self.ItemOwnersId = nil

        if eventName == "menu" then
            self.Menu:Open()
        end

        self:Update()

    elseif eventName == "button" then    -- Button icon

        self.List:Select (sel)        -- Select char name line

        self.SelectedProf = prof

        if prof then

            local ch = Nx.wdb.global.Characters[Nx.RealmChars[id]]
            local profT = ch["Profs"][prof]

            local frm = DEFAULT_CHAT_FRAME
            local eb = frm["editBox"]
            if eb:IsVisible() and profT["Link"] then

                eb:SetText (eb:GetText() .. profT["Link"])

            else
                Nx.prt ("No edit box open!")
            end

        elseif id >= 1 and id <= #Nx.RealmChars then

            local ch = Nx.wdb.global.Characters[Nx.RealmChars[id]]
            if ch then
                ch["WHHide"] = val2        -- Pressed
            end

        elseif id == 99 then

            for cnum, rc in ipairs (Nx.RealmChars) do

                local ch = Nx.wdb.global.Characters[rc]
                if ch then
                    ch["WHHide"] = true
                end
            end
        end

        self:Update()
    end
end

-------------------------------------------------------------------------------
-- On item list events
-------------------------------------------------------------------------------

function Nx.Warehouse:OnItemListEvent (eventName, sel, val2, click)

--    Nx.prt ("List event "..eventName)

    local list = self.ItemList

    local id = list:ItemGetData (sel) or 0

    if eventName == "select" or eventName == "mid" or eventName == "menu" then

        if eventName == "menu" then
            self.IListMenu:Open()
        else

            if id > 0 then
                if not IsModifiedClick() then
                    SetItemRef ("item:" .. id)
--                    Nx.Item:ShowTooltip (id, true)
                end

            elseif id == 0 then

                local oldId = self.ItemOwnersId
                self.ItemOwnersId = nil

                local tip = list:ItemGetButtonTip (sel)
                if tip then
                    tip = strsub (tip, 2)    -- Remove !

                    local str, count = self:FindCharsWithItem (tip)
                    if str then

                        if oldId then
                            if sel > self.ItemOwnersSel then
                                sel = sel - self.ItemOwnersCount
                                list:Select (sel)
                            end
                        end

                        self.ItemOwnersSel = sel
                        self.ItemOwnersCount = count

                        local id = strmatch (tip, "item:(%d+)")
                        self.ItemOwnersId = id
                        self.ItemOwners = str
                    end
                end
            end
        end

        self:Update()

    elseif eventName == "button" then    -- Button icon

--        if IsShiftKeyDown() then

            local tip = list:ItemGetButtonTip (sel)
            if tip then

                local name, link

                link = strsub (tip, 2)    -- Remove !

                if id > 0 then
                    name, link = C_Item.GetItemInfo (id)
                elseif id < 0 then
                    name = GetSpellInfo (-id)
                    link = GetSpellLink (-id)
                else
                    name = C_Item.GetItemInfo (link)
                end

                local frm = DEFAULT_CHAT_FRAME
                local eb = frm["editBox"]
                if eb:IsVisible() and link then

                    eb:SetText (eb:GetText() .. link)

                elseif BrowseName and BrowseName:IsVisible() then

                    if name then
                        BrowseName:SetText (name)
                        AuctionFrameBrowse_Search()
                    end
                else
                    Nx.prt ("No edit box open!")
                end
            end
--        end
    end
end

-------------------------------------------------------------------------------
-- Update Warehouse
-------------------------------------------------------------------------------

function Nx.Warehouse:Update()

    local Nx = Nx

    if not Nx.Warehouse.CurCharacter then    -- Can even happen?
        return
    end

    if not self.Win then
        return
    end

    -- Title

    self.Win:SetTitle (format (L["Warehouse: %d characters"], #Nx.RealmChars))

    -- List

    local myName = UnitName ("player")

    local totalChars = 0
    local totalMoney = 0
    local totalPlayed = 0
    local hicol = "|cffcfcfcf"

    local list = self.List

    list:Empty()

    list:ItemAdd (99)
    list:ItemSetButton ("Warehouse", false, "Interface\\Addons\\\Carbonite\\Gfx\\Icons\\INV_Misc_GroupNeedMore")
    local allIndex = list:ItemGetNum()

    --[[local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()
    local guildlabel = false
    for name, guilds in pairs (ware) do
        if not guildlabel then
            guildlabel = true
            list:ItemAdd(0)
            list:ItemSet (2, "|cff999999--------- " .. L["Guilds"] .. " ---------")
        end
        if name == rn then
            for gName, guild in pairs (guilds) do
                local moneyStr = guild["Money"] and Nx.Util_GetMoneyStr (guild["Money"]) or "?"
                list:ItemAdd (100)
                if Nx.wdb.profile.Warehouse.ShowGold then
                    list:ItemSet (2, format ("|cffff7fff%s %s", gName, moneyStr))
                else
                    list:ItemSet (2, format ("|cffff7fff%s", gName))
                end
                list:ItemSetDataEx (nil, gName, 1)
            end
        end
        local connectedrealms = GetAutoCompleteRealms()
        if connectedrealms then
            for i=1,#connectedrealms do
                if connectedrealms[i] ~= rn and name == connectedrealms[i] then
                    for gName, guild in pairs (guilds) do
                        local moneyStr = guild["Money"] and Nx.Util_GetMoneyStr (guild["Money"]) or "?"
                        list:ItemAdd (100)
                        if Nx.wdb.profile.Warehouse.ShowGold then
                            list:ItemSet (2, format ("|cffff7fff%s %s", gName, moneyStr))
                        else
                            list:ItemSet (2, format ("|cffff7fff%s", gName))
                        end
                        list:ItemSetDataEx (nil, gName, 1)
                    end
                end
            end
        end
    end]]--

    list:ItemAdd (0)
    list:ItemSet (2, "|cff999999--------- " .. L["Characters"] .. " ---------")

    for cnum, rc in ipairs (Nx.RealmChars) do
        local rname, cname = Nx.Split (".", rc)
        local cnameCol = "|cffafdfaf"
        if cname == myName then        -- Me?
            cnameCol = "|cffdfffdf"
        end
        local ch = Nx.wdb.global.Characters[rc]
        if ch then
            totalChars = totalChars + 1
            totalPlayed = totalPlayed + ch["TimePlayed"]
            local lvl = tonumber (ch["Level"] or 0)
--            ch["Class"] = "Deathknight"    -- TEST
            local cls = ch["Class"] or "?"
            local money = ch["Money"]
            totalMoney = totalMoney + (money or 0)
            local moneyStr = Nx.Util_GetMoneyStr (money)
            list:ItemAdd (cnum)
            local s = ch["Account"] and format ("%s (%s)", cname, ch["Account"]) or cname
            if Nx.wdb.profile.Warehouse.ShowGold then
                list:ItemSet (2, format ("%s%s %s %s %s", cnameCol, s, lvl, cls, moneyStr))
            else
                list:ItemSet (2, format ("%s%s %s %s", cnameCol, s, lvl, cls))
            end
            local hide = ch["WHHide"]

            if self.ClassIcons[ch["Class"]] then
                list:ItemSetButton ("Warehouse", hide, "Interface\\Icons\\" .. self.ClassIcons[ch["Class"]])
            end

            if not hide then

                if cname == myName then        -- Me?

                    local secs = difftime (time(), ch["LTime"])
                    local mins = secs / 60 % 60
                    local hours = secs / 3600
                    local lvlHours = difftime (time(), ch["LvlTime"]) / 3600
                    local played = Nx.Util_GetTimeElapsedStr (ch["TimePlayed"])
                    list:ItemAdd (cnum)
                    list:ItemSet (2, format (L[" Realm:%s %s"],hicol,rname))
                    list:ItemAdd (cnum)
                    local moneyStr = Nx.Util_GetMoneyStr (ch["Money"])
                    list:ItemSet (2, format (" " .. L["Current Funds"] .. ": %s",moneyStr))
                    list:ItemAdd (cnum)
                    list:ItemSet (2, format (L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"], hicol, hours, mins, secs % 60, hicol, played))
                    local money = (ch["Money"] or 0) - ch["LMoney"]
                    moneyStr = Nx.Util_GetMoneyStr (money)
                    local moneyHStr = Nx.Util_GetMoneyStr (money / hours)

                    list:ItemAdd (cnum)
                    list:ItemSet (2, format (L[" Session Money:%s %s|r, Per Hour:%s %s"], hicol, moneyStr, hicol, moneyHStr))

                    if ch["DurPercent"] then

                        local col = (ch["DurPercent"] < 50 or ch["DurLowPercent"] < 50) and "|cffff0000" or hicol

                        list:ItemAdd (cnum)
                        list:ItemSet (2, format (L[" Durability: %s%d%%, lowest %d%%"], col, ch["DurPercent"], ch["DurLowPercent"]))
                    end

                    if lvl < Nx.MaxPlayerLevel then
                        local rest = ch["LXPRest"] / ch["LXPMax"] * 100        -- Sometimes over 150%?
                        local xp = ch["XP"] - ch["LXP"]
                        list:ItemAdd (cnum)
                        list:ItemSet (2, format (L[" Session XP:%s %s|r, Per Hour:%s %.0f"], hicol, xp, hicol, xp / lvlHours))
                        xp = max (1, xp)
                        local lvlTime = (ch["XPMax"] - ch["XP"]) / (xp / lvlHours)

                        if lvlTime < 100 then
                            list:ItemAdd (cnum)
                            list:ItemSet (2, format (L[" Hours To Level: %s%.1f"], hicol, lvlTime))
                        end
                    end
                else
                    list:ItemAdd (cnum)
                    list:ItemSet (2, format (L[" Realm:%s %s"],hicol,rname))
                    local moneyStr = Nx.Util_GetMoneyStr (ch["Money"])
                    list:ItemAdd (cnum)
                    list:ItemSet (2, format (" " .. L["Current Funds"] .. ": %s",moneyStr))
                    if ch["Time"] then

                        local secs = difftime (time(), ch["Time"])
                        local str = Nx.Util_GetTimeElapsedStr (secs)
                        local played = Nx.Util_GetTimeElapsedStr (ch["TimePlayed"])

                        list:ItemAdd (cnum)
                        list:ItemSet (2, format (L[" Last On: %s%s|r, Played: %s%s"], hicol, str, hicol, played))
                    end
                    if ch["Pos"] then
                        local mid, x, y = Nx.Split ("^", ch["Pos"])
                        local map = Nx.Map:GetMap (1)
                        local name = map:IdToName (tonumber (mid))
                        list:ItemAdd (cnum)
                        list:ItemSet (2, format (L[" Location: %s%s (%d, %d)"], hicol, name, x, y))
                    end
                end

                if lvl < Nx.MaxPlayerLevel then
                    if ch["XP"] then

                        local rest = ch["LXPRest"] / ch["LXPMax"] * 100
                        list:ItemAdd (cnum)
                        list:ItemSet (2, format (L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"], hicol, ch["LXP"], ch["LXPMax"], ch["LXP"] / ch["LXPMax"] * 100, hicol, rest))

                        local rest = ch["XPRest"] / ch["XPMax"] * 100

                        if ch["Time"] then
                            rest = min (150, rest + difftime (time(), ch["Time"]) * .0001736111)
                        end

                        list:ItemAdd (cnum)
                        list:ItemSet (2, format (L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"], hicol, ch["XP"], ch["XPMax"], ch["XP"] / ch["XPMax"] * 100, hicol, rest))
                    end
                end
                list:ItemAdd(cnum)
                list:ItemSet (2, "|cff00ffff  ------")
                if ch["Currency"] then
                    if ch["Currency"][395] and ch["Currency"][396] then
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format (L[" Valor: %s%s|r  Justice: %s%s"], hicol, ch["Currency"][396], hicol, ch["Currency"][395]))
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\pvecurrency-valor")
                    end
                    if ch["Currency"][823] then
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format (L[" Apexis Crystals: %s%s"], hicol, ch["Currency"][823]))
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\inv_apexis_draenor")
                    end
                    if ch["Currency"][1226] then
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format (L[" Nethershard: %s%s"], hicol, ch["Currency"][1226]))
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\inv_datacrystal01")
                    end
                    if ch["Currency"][824] then
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format (L[" Garrison Resources: %s%s"], hicol, ch["Currency"][824]))
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\inv_garrison_resource")
                    end
                    if ch["Currency"][1220] then
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format (L[" Order Resources: %s%s"], hicol, ch["Currency"][1220]))
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\inv_orderhall_orderresources")
                    end
                else
                    list:ItemAdd(cnum)
                    list:ItemSet(2, format (" " .. L["No Currency Data Saved"]))
                end
                list:ItemAdd(cnum)
                list:ItemSet (2, "|cff00ffff  ------")
                if ch["Honor"] and ch["Conquest"] then
                    list:ItemAdd (cnum)
                    list:ItemSet (2, format (L[" Honor: %s%s|r  Conquest: %s%s"], hicol, ch["Honor"], hicol, ch["Conquest"]))
                    if (Nx.PlFactionNum == 1) then
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\pvpcurrency-conquest-horde")
                    else
                        list:ItemSetButton ("Warehouse", false, "Interface\\Icons\\pvpcurrency-conquest-alliance")
                    end
                end
                list:ItemAdd(cnum)
                list:ItemSet (2, "|cff00ffff  ------")
                if ch["Profs"] then

                    local profs = ch["Profs"]

                    local names = {}

                    for name, data in pairs (profs) do
                        tinsert (names, name)
                    end

                    sort (names)

                    for n, name in ipairs (names) do

                        local p = profs[name]
                        list:ItemAdd (cnum)
                        list:ItemSetDataEx (nil, name, 1)
                        list:ItemSet (2, format (" %s %s%s", name, hicol, p["Rank"]))

                        if p["Link"] then
                            list:ItemSetButton ("WarehouseProf", false)
                        end
                    end
                end
            end
        end
    end
    local money = Nx.Util_GetMoneyStr (totalMoney)
    if Nx.wdb.profile.Warehouse.ShowGold then
        list:ItemSet (2, format ("|cffafdfaf %s" .. L["All Characters"],money), allIndex)
    else
        list:ItemSet (2, format ("|cffafdfaf" .. L["All Characters"]), allIndex)
    end

    list:Update()

    -- Right side list

    if self.SelectedProf then
        self:UpdateProfessions()
    elseif self.SelectedGuild then
        self:UpdateGuild()
    elseif self.SelectedChar then
        self:UpdateItems()
    else
        self:UpdateBlank()
    end
end

function Nx.Warehouse:UpdateBlank()
    local list = self.ItemList
    list:Empty()
    list:ColumnSetName (3, "")
    list:Update()
end

function Nx.Warehouse:UpdateGuild()
    local list = self.ItemList
    list:Empty()
    local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()
    local selectedguild = {}
    for name, guilds in pairs (ware) do
        if name == rn then
            for gName, guild in pairs (guilds) do
                    if gName == self.SelectedGuild then
                        selectedguild = guild
                    end
            end
        end
        if not selectedguild then
            local connectedrealms = GetAutoCompleteRealms()
            if connectedrealms then
                for i=1,#connectedrealms do
                    if connectedrealms[i] ~= rn and name == connectedrealms[i] then
                        for gName, guild in pairs (guilds) do
                            if gName == self.SelectedGuild then
                                selectedguild = guild
                            end
                        end
                    end
                end
            end
        end
    end
    list:ColumnSetName (3, format(L["Guild Bank"] .. " -- %s",self.SelectedGuild))
    local moneyStr = selectedguild["Money"] and Nx.Util_GetMoneyStr (selectedguild["Money"]) or "?"
    list:ItemAdd (0)
    list:ItemSet (3, L["Current Funds"] .. ": " .. moneyStr)
    list:ItemAdd (0)
    list:ItemSet (3, "")
    for tab = 1,8 do
        if not selectedguild["Tab" .. tab] or (selectedguild["Tab" .. tab] and not next(selectedguild["Tab" .. tab])) then
            list:ItemAdd(0)
            list:ItemSet(3,"|cffff0000---- " .. L["Tab"] .. " " .. tab .. " " .. L["not opened or scanned."])
        else
            list:ItemAdd(0)
            list:ItemSetButton ("Warehouse", false, selectedguild["Tab" .. tab].Icon)
            list:ItemSet(3,selectedguild["Tab" .. tab].Name)
            list:ItemAdd(0)
            local dateStr = Nx.Util_GetTimeElapsedStr(time() - selectedguild["Tab" .. tab].ScanTime)
            list:ItemSet(3,"|cff00ffff" .. L["Last Updated"] .. ":|r " .. dateStr .. " |cff00ffff" .. L["ago"])
            if not selectedguild["Tab" .. tab].Inv or (selectedguild["Tab" .. tab].Inv and not next(selectedguild["Tab" .. tab].Inv)) then
                list:ItemAdd(0)
                list:ItemSet(3,"|cffff0000--- " .. L["Tab is empty or no access"] .. " ---")
            else
                for slot,item in pairs(selectedguild["Tab" .. tab].Inv) do
                    if item then
                        local stack, link = Nx.Split("^",item)
                        local name = C_Item.GetItemInfo(link)
                        self:UpdateItem ("", name, stack, 0, 0, link)
                    end
                end
            end
        end
        list:ItemAdd(0)
        list:ItemSet(3,"")
    end
    list:Update()
end

function Nx.Warehouse:UpdateItems()

    local list = self.ItemList

    list:Empty()

    local items = {}

    local cn1 = 1
    local cn2 = 1

    cn2 = #Nx.RealmChars

    if self.SelectedChar ~= 99 then

        cn1 = self.SelectedChar
        cn2 = cn1

        local rc = Nx.RealmChars[cn1]

        local rname, cname = Nx.Split (".", rc)
        list:ColumnSetName (3, format (L["%s's Items"], cname))

        local ch = Nx.wdb.global.Characters[rc]

        local bank = ch["WareBank"]
        if not bank then
            list:ItemAdd (0)
            list:ItemSet (3, L["|cffff1010No bank data - visit your bank"])
        end

        local rbank = ch["WareRBank"]
        --[[if not rbank then
            list:ItemAdd (0)
            list:ItemSet (3, L["|cffff1010No reagent bank data - visit your bank"])
        end]]--

        local inv = ch["WareInv"]

        if inv then
            list:ItemAdd (0)
            list:ItemSet (3, L["---- Equipped ----"])
            for _, data in ipairs (inv) do
                local slot, link = Nx.Split ("^", data)
                Nx.Item:Load (link)
                slot = gsub (slot, L["Slot"], "")
                slot = gsub (slot, "%d", "")
                local name = C_Item.GetItemInfo (link)
                self:UpdateItem (format ("  %s - ", slot), name, 1, 0, 0, link, true)
            end
        end
    else

        for cn = cn1, cn2 do

            local rc = Nx.RealmChars[cn]
            local ch = Nx.wdb.global.Characters[rc]

            local inv = ch["WareInv"]

            if inv then

                local hdr

                for _, data in ipairs (inv) do

                    local slot, link = Nx.Split ("^", data)
                    Nx.Item:Load (link)

                    slot = gsub (slot, L["Slot"], "")
                    slot = gsub (slot, "%d", "")

                    local name, _, iRarity = C_Item.GetItemInfo (link)
                    if iRarity and iRarity >= self.NXEqRarityMin then

                        if not hdr then
                            hdr = true
                            list:ItemAdd (0)
                            local rname, cname = Nx.Split (".", rc)
                            local s = format (L["---- %s Equipped ----"], cname)
                            list:ItemSet (3, s)
                        end

                        self:UpdateItem (format ("  %s - ", slot), name, 1, 0, 0, link, true)
                    end
                end
            end
        end

        list:ColumnSetName (3, L["All Items"])
--[[
        if Nx.Free then
            list:ItemAdd (0)
            list:ItemSet (3, "See All Is " .. Nx.FreeMsg)
            return
        end
--]]
    end

    for cn = cn1, cn2 do

        local rc = Nx.RealmChars[cn]
        local ch = Nx.wdb.global.Characters[rc]

        local bags = ch["WareBags"]

        if bags then
            for name, data in pairs (bags) do
                self:AddItem (items, 2, name, data)
            end
        end

        local bank = ch["WareBank"]

        if bank then
            for name, data in pairs (bank) do
                self:AddItem (items, 3, name, data)
            end
        end

        local rbank = ch["WareRBank"]
        if rbank then
            for name, data in pairs (rbank) do
                self:AddItem (items, 3, name, data)
            end
        end

        local mail = ch["WareMail"]

        if mail then
            for name, data in pairs (mail) do
                self:AddItem (items, 4, name, data)
            end
        end
    end

    local sortRare = true

    local isorted = {}

    for name, data in pairs (items) do

        local bagCnt, bankCnt, mailCnt, link = Nx.Split ("^", data)
        Nx.Item:Load (link)

        if self.SortByRarity or self.SortBySlot then

            local _, iLink, iRarity, lvl, minLvl, itype, _, _, equipLoc = C_Item.GetItemInfo (link)

            local sortStr = ""

            if self.SortByRarity then
                sortStr = 9 - (iRarity or 0)
            end

            if self.SortBySlot and itype == ARMOR and equipLoc then
                local loc = _G[equipLoc] or ""
                name = format ("%s - %s", loc, name)
                sortStr = format ("%s%s", loc, sortStr)
            end

            tinsert (isorted, format ("%s^%s^%s", sortStr, name, data))
        else
            tinsert (isorted, format ("^%s^%s", name, data))
        end

    end

    sort (isorted)

    if not self.ShowItemCategory then

        for _, v in ipairs (isorted) do

            local _, name, bagCnt, bankCnt, mailCnt, link = Nx.Split ("^", v)
            local _, iLink, iRarity = C_Item.GetItemInfo (link)

            iRarity = iRarity or 0    -- Happens if item not in cache

            if iRarity >= self.NXRarityMin then
                self:UpdateItem ("", name, bagCnt, bankCnt, mailCnt, link)
            end
--[[
            local name, iLink, iRarity, lvl, minLvl, itype = GetItemInfo (link)
            Nx.prt ("item %s", itype)
--]]
        end
    else

        for _, typ in ipairs (self.ItemTypes) do

            for n = 1, #isorted do

                local _, name, bagCnt, bankCnt, mailCnt, link = Nx.Split ("^", isorted[n])
                local _, iLink, iRarity, lvl, minLvl, itype = C_Item.GetItemInfo (link)

                if itype == typ then    -- Found one of type?

                    list:ItemAdd (0)
                    list:ItemSet (3, "---- " .. typ .. " ----")

                    for n2 = n, #isorted do

                        local _, name, bagCnt, bankCnt, mailCnt, link = Nx.Split ("^", isorted[n2])
                        local _, iLink, iRarity, lvl, minLvl, itype = C_Item.GetItemInfo (link)

                        if itype == typ then

                            if iRarity >= self.NXRarityMin then
                                self:UpdateItem ("  ", name, bagCnt, bankCnt, mailCnt, link)
                            end
                        end
                    end

                    break
                end
            end
        end
    end
    list:Update()
end

function Nx.Warehouse:AddItem (items, typ, name, data)

    local totalBag = 0
    local totalBank = 0
    local totalMail = 0

    if items[name] then
        totalBag, totalBank, totalMail = Nx.Split ("^", items[name])
    end

    local count, iLink = Nx.Split ("^", data)

    if typ == 2 then
        totalBag = totalBag + count

    elseif typ == 3 then
        totalBank = totalBank + count

    elseif typ == 4 then
        totalMail = totalMail + count
    end

    items[name] = format ("%d^%d^%d^%s", totalBag, totalBank, totalMail, iLink)
end

function Nx.Warehouse:UpdateItem (pre, name, bagCnt, bankCnt, mailCnt, link, showILvl)

    local list = self.ItemList

    name = name or link

    bagCnt = tonumber (bagCnt)
    bankCnt = tonumber (bankCnt)
    mailCnt = tonumber (mailCnt)

    local total = bagCnt + bankCnt + mailCnt

    local str
    str = format ("%s  ", name)

    local iname, iLink, iRarity, lvl, minLvl, itype, subType, stackCount, equipLoc, tx = C_Item.GetItemInfo (link)

    if not iname then
        iLink = link
        iRarity = 0
        minLvl = 0
    end

    iRarity = min (iRarity, 6)        -- Fix Blizz bug with color table only going to 6. Account bound are 6 or 7
    local col = iRarity == 1 and "|cffe7e7e7" or ITEM_QUALITY_COLORS[iRarity]["hex"]

    local show = true
    local istr = pre .. col .. str

    local showilvls = {["INVTYPE_HEAD"]=1,["INVTYPE_NECK"]=1,["INVTYPE_SHOULDER"]=1,["INVTYPE_CHEST"]=1,["INVTYPE_ROBE"]=1,["INVTYPE_WAIST"]=1,["INVTYPE_LEGS"]=1,["INVTYPE_FEET"]=1,["INVTYPE_WRIST"]=1,
                        ["INVTYPE_HAND"]=1,["INVTYPE_FINGER"]=1,["INVTYPE_TRINKET"]=1,["INVTYPE_CLOAK"]=1,["INVTYPE_WEAPON"]=1,["INVTYPE_SHIELD"]=1,["INVTYPE_2HWEAPON"]=1,["INVTYPE_WEAPONMAINHAND"]=1,
                        ["INVTYPE_WEAPONOFFHAND"]=1,["INVTYPE_HOLDABLE"]=1,["INVTYPE_RANGED"]=1,["INVTYPE_THROWN"]=1,["INVTYPE_RANGEDRIGHT"]=1,["INVTYPE_RELIC"]=1}
    if lvl and showilvls[equipLoc] then
        istr = istr .. "|c0000ff00[|rIL " .. lvl .. "|c0000ff00]"
    end

    if bankCnt > 0 then
        istr = format (L["%s |cffcfcfff(%s Bank)"], istr, bankCnt)
    end
    if mailCnt > 0 then
        istr = format (L["%s |cffcfffff(%s Mail)"], istr, mailCnt)
    end

    local filterStr = self.EditBox:GetText()

    if filterStr ~= "" then

        local lstr = strlower (format ("%s", istr))
        local filtStr = strlower (filterStr)

        show = strfind (lstr, filtStr, 1, true)
    end

    if show then

        list:ItemAdd (0)

        if total > 1 then
            list:ItemSet (2, format ("|cffcfcfff%s  ", bagCnt + bankCnt + mailCnt))
        end

        if minLvl > UnitLevel ("player") then
            istr = format ("%s |cffff4040[%s]", istr, minLvl)
        end

        list:ItemSet (3, istr)
        list:ItemSetButton ("WarehouseItem", false, tx, "!" .. iLink)

        local s1, s2, id = strfind (link, "item:(%d+)")
        assert (s1)
        assert (id)

        if self.ItemOwnersId == id then

            local pos = 1

            for n = 1, 99 do

--                Nx.prt ("Owners %s", self.ItemOwners)

                local e = strfind (self.ItemOwners, "\n", pos)

                str = strsub (self.ItemOwners, pos, e and e - 1)

                list:ItemAdd (0)
                list:ItemSet (3, format ("        %s", str))

                if not e then
                    break
                end

                pos = e + 1
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Find all chars who have item
-------------------------------------------------------------------------------

function Nx.Warehouse:FindCharsWithItem (link, specific)

--    local tm = GetTime()
    local s1, s2, link = strfind (link, "item:(%d+)")
    local str
    local charCnt = 0
    local totalCnt = 0
    local petCnt = 0

    if not link then
        return "", 0, 0
    end

    local isPet, _, _, petID = C_PetJournal.GetPetInfoByItemID(link)

    if isPet then
        local ownedPets = C_PetJournal.GetOwnedPetIDs()
        for _, ownedPetGUID in ipairs(ownedPets) do
            local ownedPetID = select(11, C_PetJournal.GetPetInfoByPetID(ownedPetGUID))
            if ownedPetID == petID then
                petCnt = petCnt + 1
            end
        end
    end

    for cnum, rc in ipairs (Nx.RealmChars) do

        local bagCnt = 0
        local bankCnt = 0
        local rbankCnt = 0
        local invCnt = 0
        local mailCnt = 0

        local rname, cname = Nx.Split (".", rc)
        if not Nx.wdb.global.Characters[rc] then
            return "", 0, 0
        end
        local ch = Nx.wdb.global.Characters[rc]

        local bags = ch["WareBags"]

        if bags then
            for name, data in pairs (bags) do
                local iCount, iLink = Nx.Split ("^", data)
                local s1, s2, iLink = strfind (iLink, "item:(%d+)")
                if iLink == link then
                    bagCnt = bagCnt + iCount
                    break
                end
            end
        end

        local bank = ch["WareBank"]

        if bank then
            for name, data in pairs (bank) do
                local iCount, iLink = Nx.Split ("^", data)
                local s1, s2, iLink = strfind (iLink, "item:(%d+)")
                if iLink == link then
                    bankCnt = bankCnt + iCount
                    break
                end
            end
        end

        local rbank = ch["WareRBank"]

        if rbank then
            for name, data in pairs (rbank) do
                local iCount, iLink = Nx.Split ("^", data)
                local s1, s2, iLink = strfind (iLink, "item:(%d+)")
                if iLink == link then
                    rbankCnt = rbankCnt + iCount
                    break
                end
            end
        end

        local inv = ch["WareInv"]

        if inv then
            for name, data in pairs (inv) do
                local slot, iLink = Nx.Split ("^", data)
                local s1, s2, iLink = strfind (iLink, "item:(%d+)")
                if iLink == link then
                    invCnt = invCnt + 1
                end
            end
        end

        local mail = ch["WareMail"]

        if mail then
            for name, data in pairs (mail) do
                local iCount, iLink = Nx.Split ("^", data)
                local s1, s2, iLink = strfind (iLink, "item:(%d+)")
                if iLink == link then
                    mailCnt = mailCnt + iCount
                    break
                end
            end
        end
        local cnt = bagCnt + invCnt + bankCnt + rbankCnt + mailCnt

        if cnt > 0 then

            charCnt = charCnt + 1
            totalCnt = totalCnt + cnt

            local s

            if invCnt > 0 then
                s = format (L["%s %d (%d Worn)"], cname, bagCnt, invCnt)
            else
                s = format ("%s %d", cname, bagCnt)
            end

            if bankCnt > 0 then
                s = format (L["%s (%d Bank)"], s, bankCnt)
            end

            if rbankCnt > 0 then
                s = format (L["%s (%d RBank)"], s, rbankCnt)
            end

            if mailCnt > 0 then
                s = format (L["%s (%s Mail)"], s, mailCnt)
            end
            if specific == "tooltip" then
                s = format ("|cFFFFFF00%s#",cname)
                if bagCnt > 0 then
                    s = format (L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"],s,bagCnt)
                end
                if invCnt > 0 then
                    s = format (L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"],s,invCnt)
                end
                if mailCnt > 0 then
                    s = format (L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"],s,mailCnt)
                end
                if bankCnt > 0 then
                    s = format (L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"],s,bankCnt)
                end
                if rbankCnt > 0 then
                    s = format (L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"],s,rbankCnt)
                end
            end
            if not str then
                str = s
            else
                if specific ~= "tooltip" then
                    str = format ("%s\n%s", str, s)
                else
                    str = format("%s#%s",str,s)
                end
            end
        end
    end

    if petCnt > 0 then
        cname = UnitName("player")
        local sp = format ("%s %d", cname, petCnt)
        sp = format (L["%s (%s Pets)"], sp, petCnt)
        if specific == "tooltip" then
            sp = format ("|cFFFFFF00%s#",cname)
            sp = format (L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"], sp, petCnt)
        end
        if not str then
            str = sp
        else
            if specific ~= "tooltip" then

                str = format ("%s\n%s", str, sp)
            else
                str = format("%s#%s",str,sp)
            end
        end
        totalCnt = totalCnt + 1
        charCnt = charCnt + 1
    end

--    Nx.prt ("FindCharsWithItem %f secs", GetTime() - tm)
    return str, charCnt, totalCnt
end

function Nx.Warehouse:UpdateProfessions()

    local list = self.ItemList

    list:Empty()

    local cn1 = self.SelectedChar
    local rc = Nx.RealmChars[cn1]
    local ch = Nx.wdb.global.Characters[rc]

    local rname, cname = Nx.Split (".", rc)
    local pname = self.SelectedProf

    list:ColumnSetName (3, format (L["%s's %s Skills"], cname, pname))

    local profsT = ch["Profs"]
    local profT = profsT[pname]
    if profT then

        local items = {}

        for id, itemId in pairs (profT) do

            if type (id) == "number" then

                local name = GetSpellInfo (id)
                local iName, iLink, iRarity, iLvl, iMinLvl, iType, iSubType, iStackCount, iEquipLoc = C_Item.GetItemInfo (itemId)

                name = iName or name or "?"
                local cat = ""

                if self.ShowItemCategory then
                    cat = iType or ""
                end

                local sortStr = ""

                if self.SortBySlot and iType == ARMOR and iEquipLoc then
--                if self.SortBySlot and iEquipLoc then
                    local loc = _G[iEquipLoc] or ""
                    name = format ("%s - %s", loc, name)
                    sortStr = format ("%s%s", loc, sortStr)
                end

                tinsert (items, format ("%s^%s%02d^%s^%s", cat, sortStr, iMinLvl or 0, name, id))
            end
        end

        sort (items)

        local filterStr = strlower (self.EditBox:GetText())
        local curCat = ""

        for _, str in ipairs (items) do

            local cat, _, name, id = Nx.Split ("^", str)
            local id = tonumber (id)

            local link = GetSpellLink (id)
            local iName, iLink, iRarity, iLvl, iMinLvl, iType, iSubType, iStackCount, iEquipLoc, iTx
            local col = ""

            local itemId = -id        -- Use negatives for enchants

            if profT[id] > 0 then

                itemId = profT[id]

                Nx.Item:Load (itemId)

                iName, iLink, iRarity, iLvl, iMinLvl, iType, iSubType, iStackCount, iEquipLoc, iTx = C_Item.GetItemInfo (itemId)
                if iRarity then
                    iRarity = min (iRarity, 6)        -- Fix Blizz bug with color table only going to 6. Account bound are 6 or 7
                    col = iRarity == 1 and "|cffe7e7e7" or ITEM_QUALITY_COLORS[iRarity]["hex"]
                end
            end

            local iStr = col .. name
            local show = true

            if filterStr ~= "" then
                local lstr = strlower (iStr)
                show = strfind (lstr, filterStr, 1, true)
            end

            if show then

                if cat ~= curCat then
                    curCat = cat
                    list:ItemAdd (0)
                    list:ItemSet (3, format ("---- %s ----", cat))
                end

                list:ItemAdd (itemId)        -- Neg enchant, pos item
                if iMinLvl and iMinLvl > 0 then
                    list:ItemSet(2, "|cff777777" .. iMinLvl .. " ")
                end
                list:ItemSet (3, iStr)
                if link then
                    list:ItemSetButton ("WarehouseItem", false, iTx, "#" .. link)
                end
            end
        end

    else

        list:ItemAdd (0)
        list:ItemSet (3, format (L["|cffff1010No data - open %s window"], pname))
    end

    list:Update()
end

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

function Nx.Warehouse:ReftipProcess()
    if not Nx.wdb.profile.Warehouse.AddTooltip then
        return
    end
    local tip = ItemRefTooltip
    local name, link = tip:GetItem()
    if name then
        if Nx.wdb.profile.Warehouse.TooltipIgnore and Nx.wdb.profile.Warehouse.IgnoreList[name] then
            return
        end
        local titleStr = format (L["|cffffffffW%sarehouse:"], Nx.TXTBLUE)
        local textName = "ItemRefTooltipTextLeft"
        for n = 2, tip:NumLines() do
            local s1 = strfind (_G[textName .. n]:GetText() or "", titleStr)
            if s1 then
                return
            end
        end
        local str, count, total = Nx.Warehouse:FindCharsWithItem (link,"tooltip")
        if total > 0 then
            str = gsub (str, "\n", "\n ")
            local temparray = { Nx.Split("#",str) }
            local a = false
            local char
            tip:AddLine(titleStr)
            for i, j in pairs (temparray) do
                if a == false then
                    a = true
                    char = j
                else
                    a = false
                    tip:AddDoubleLine(char,j)
                end
            end
            tip:Show()
        end
    end
end

function Nx.Warehouse:TooltipProcess()
    if not Nx.wdb.profile.Warehouse.AddTooltip then
        return
    end
    local tip = GameTooltip
    local name, link = tip:GetItem()
    if name then
        if Nx.wdb.profile.Warehouse.TooltipIgnore and Nx.wdb.profile.Warehouse.IgnoreList[name] then
            return
        end

        local titleStr = format (L["|cffffffffW%sarehouse:"], Nx.TXTBLUE)
        local textName = "GameTooltipTextLeft"
        for n = 2, tip:NumLines() do
            local s1 = strfind (_G[textName .. n]:GetText() or "", titleStr)
            if s1 then
                return
            end
        end

        local str, count, total = Nx.Warehouse:FindCharsWithItem (link,"tooltip")
        if total > 0 then
            str = gsub (str, "\n", "\n ")
            local temparray = { Nx.Split("#",str) }
            local a = false
            local char
            tip:AddLine(titleStr)
            for i, j in pairs (temparray) do
                if a == false then
                    a = true
                    char = j
                else
                    a = false
                    tip:AddDoubleLine(char,j)
                end
            end
            tip:Show()
        end
    end
end

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

function Nx.Warehouse:GuildDelete (guildName)

    local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()

    for name, guilds in pairs (ware) do
        if name == rn then
            guilds[guildName] = nil
            return
        end
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Capture item changes
-------------------------------------------------------------------------------

function Nx.Warehouse.OnBankframe_opened()
--    Nx.prt ("Bank open")

    local self = Nx.Warehouse

    if self.Enabled then
        self.BankOpen = true
        self:CaptureUpdate()
    end
end

function Nx.Warehouse.OnBankframe_closed()
--    Nx.prt ("Bank close")

    local self = Nx.Warehouse

    if self.Enabled then
        self.BankOpen = false
        self:CaptureUpdate()
    end
end

function Nx.Warehouse.OnGuildbankframe_opened()
    local self = Nx.Warehouse
    if self.Enabled then
        self:GuildRecord (true)
    end
end

function Nx.Warehouse.OnGuildbankframe_closed()
    local self = Nx.Warehouse
    if self.Enabled then
        self:GuildRecord (true)
    end
end

function Nx.Warehouse:GuildRecord (open)
    if not IsInGuild() then
        return
    end
    local gName = GetGuildInfo ("player")
    if gName then
        local ware = Nx.wdb.profile.WarehouseData
        local rn = GetRealmName()
        local rnGuilds = ware[rn] or {}
        ware[rn] = rnGuilds
        local guild = rnGuilds[gName] or {}
        rnGuilds[gName] = guild
        if open then
            guild["Money"] = GetGuildBankMoney()
            local numTabs = GetNumGuildBankTabs()
            local name, icon
            for page = 1, numTabs do
                guild["Tab" .. page] = {}
                name, icon = GetGuildBankTabInfo(page)
                guild["Tab" .. page]["Name"] = name
                guild["Tab" .. page]["Icon"] = icon
                guild["Tab" .. page]["ScanTime"] = time()
                guild["Tab" .. page]["Inv"] = {}
                for slot = 1, 98 do
                    if GetGuildBankItemLink(page, slot) then
                        local itemString = GetGuildBankItemLink(page, slot)
                        local _, num = GetGuildBankItemInfo(page, slot)
                        guild["Tab" .. page]["Inv"][slot] = format("%s^%s",num,itemString)
                    end
                end
            end
        end
    end
end

function Nx.Warehouse.OnBag_update()

    local self = Nx.Warehouse

    if self.Enabled then
        local delay = self.BankOpen and 0 or .8
        WarehouseCap = Nx:ScheduleTimer(self.CaptureUpdate,delay,self)
    end
end

function Nx.Warehouse.OnMail_inbox_update()

--    Nx.prt ("MAIL_INBOX_UPDATE")

    local self = Nx.Warehouse

    if not self.Enabled then
        return
    end

    local ch = Nx.Warehouse.CurCharacter

    local inv = {}
    ch["WareMail"] = inv

    for n = 1, GetInboxNumItems() do

        local _, _, sender, subject, money, COD, daysLeft, hasItem, wasRead = GetInboxHeaderInfo (n)

        if hasItem then
--            Nx.prt ("Mail #%d cnt %d", n, hasItem)

            for i = 1, ATTACHMENTS_MAX_RECEIVE do

                local name, _, _, count = GetInboxItem (n, i)
                if name then

                    local link = GetInboxItemLink (n, i)

                    if link then
                        self:AddLink (link, count, inv)
                    end

--                    Nx.prt ("Mail %s", link or "nil")
                end
            end
        end
    end

    self:Update()
end


function Nx.Warehouse.onAuctionHouseUpdate(link, count)
    local self = Nx.Warehouse

    if not self.Enabled then
        return
    end

    if not link then
        return
    end

    local ch = Nx.Warehouse.CurCharacter

    self:AddLink (link, count, ch["WareMail"])
        self:Update()
end

function Nx.Warehouse.OnItem_lock_changed(_, arg1, arg2)

    if type (arg2) ~= "number" then    -- Inventory item?
        return
    end

    local self = Nx.Warehouse

    if not self.Enabled then
        return
    end

    if arg1 == KEYRING_CONTAINER or arg1 == BACKPACK_CONTAINER or (arg1 >= 1 and arg1 <= NUM_BAG_SLOTS) or
            arg1 == BANK_CONTAINER or arg1 == REAGENTBANK_CONTAINER or (arg1 >= NUM_BAG_SLOTS + 1 and arg1 <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then

        self.LockBank = nil

        if arg1 == BANK_CONTAINER or arg1 == REAGENTBANK_CONTAINER or (arg1 >= NUM_BAG_SLOTS + 1 and arg1 <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
            self.LockBank = true
        end

        self:prtdb ("LockChg %s %s", arg1, tostring(arg2))

        self.LockBag = arg1
        self.LockSlot = arg2
        local tx, count, locked = GetContainerItemInfo (arg1, arg2)
        if tx then
            self.LockCnt = count
            self.LockLink = C_Container.GetContainerItemLink (arg1, arg2)
        end

        if locked then

--            Nx.prt ("Lock %d %d", arg1, arg2)
            self.Locked = true

        else

--            Nx.prt ("Unlock %d %d", arg1, arg2)
            self.Locked = false
        end

        self:CaptureUpdate()
        self.LockBag = nil        -- Off
    end
end

-------------------------------------------------------------------------------
-- Capture and update UI
-------------------------------------------------------------------------------

function Nx.Warehouse:CaptureUpdate()

    self:CaptureItems()

    if self.Win then
        self:Update()
    end
end

-------------------------------------------------------------------------------
-- Capture items
-------------------------------------------------------------------------------

function Nx.Warehouse:CaptureItems()

    local ch = Nx.Warehouse.CurCharacter

--    ch["WareBank"] = nil

    local inv = {}
    ch["WareInv"] = inv

    for _, name in ipairs (self.InvNames) do

        local id = GetInventorySlotInfo (name)
        local link = GetInventoryItemLink ("player", id)
        if link then
            tinsert (inv, format ("%s^%s", name, link))
        end
    end

    -- Bag slots

--    local oldBags = ch["WareBags"]

    local inv = {}
    ch["WareBags"] = inv

    for i, bag in ipairs(CharBags) do
        self:AddBag (bag, false, inv)
    end

    if BandBankActive then
        for i, bandbag in ipairs(BandBags) do
            self:AddBag (bandbag, false, inv)
        end
    end

--    self:prtdb ("Bags %d", Nx.Util_tcount (inv))

    -- Bank slots

    if self.BankOpen then
        local inv = {}
        for i, bankbag in ipairs(BankBags) do
            self:AddBag (bankbag, true, inv)
        end

        if next (inv) then        -- Get any bank items?
            ch["WareBank"] = inv

--            self:prtdb ("Bank %d", Nx.Util_tcount (inv))
        end
        Nx.Warehouse:ScanRBank()
    else

        if self.LockBank and self.LockBag and not self.Locked then
--            Nx.prt ("Bank add back")
            self:AddLink (self.LockLink, self.LockCnt, ch["WareBank"])
        end
    end
end

function Nx.Warehouse:ScanRBank()
    local ch = Nx.Warehouse.CurCharacter
    inv = {}
    --self:AddBag (REAGENTBANK_CONTAINER, true, inv)
    if next (inv) then
        ch["WareRBank"] = inv
    end
end

function Nx.Warehouse:AddBag (bag, isBank, inv)
    if bag == nil then
        return
    end

    local slots = C_Container.GetContainerNumSlots (bag)
    for slot = 1, slots do
        local containerItemInfo = C_Container.GetContainerItemInfo (bag, slot)
        if containerItemInfo then
            local count = containerItemInfo.stackCount
            local locked = containerItemInfo.isLocked
            if not locked then
                local link = C_Container.GetContainerItemLink (bag, slot)
                if link then
                    self:AddLink (link, count, inv)
                end
            end
        end
    end
end

function Nx.Warehouse:AddLink (link, count, inv)

    local name, iLink = C_Item.GetItemInfo (link)

    if name and inv then        -- inv can somehow be nil. bank addon?

        local total = 0

        if inv[name] then
            total = Nx.Split ("^", inv[name])
        end

        total = total + count

        inv[name] = format ("%d^%s", total, iLink)
    else
--        Nx.prt ("AddLink nil %s", link)
    end
end

-------------------------------------------------------------------------------

function Nx.Warehouse.OnUnit_inventory_changed(_, arg1)

--    Nx.prt ("OnUNIT_INVENTORY_CHANGED %s", arg1)
    if arg1 == "player" and not UnitAffectingCombat ("player") and Nx.Info and Nx.Info.NeedDurability then
        Nx.Warehouse:CaptureInvDurability()
    end
end

function Nx.Warehouse.OnMerchant_show()
    if CanMerchantRepair() and Nx.wdb.profile.Warehouse.RepairAuto then
        local cost, canrepair = GetRepairAllCost()
        if canrepair then
            local guildrepaired = false
            if Nx.wdb.profile.Warehouse.RepairGuild then
                if (IsInGuild() and CanGuildBankRepair()) then
                    if cost <= GetGuildBankWithdrawMoney() and cost <= GetGuildBankMoney() then
                        RepairAllItems(1)
                        local moneyStr = Nx.Util_GetMoneyStr(cost)
                        Nx.prt(L["AUTO-REPAIR"] .. ": " .. moneyStr .. " [" .. L["GUILD WITHDRAW"] .. "]")
                        guildrepaired = true
                    end
                end
            end
            if cost <= GetMoney() and not guildrepaired then
                RepairAllItems()
                local moneyStr = Nx.Util_GetMoneyStr(cost)
                Nx.prt(L["AUTO-REPAIR"] .. ": " .. moneyStr)
            elseif not guildrepaired then
                Nx.prt(L["AUTO-REPAIR"] .. ": " .. L["Not enough funds to repair."])
            end
        end
    end
    if GetMerchantNumItems() > 0 and not CursorHasItem() then
        if Nx.wdb.profile.Warehouse.SellGreys or Nx.wdb.profile.Warehouse.SellWhites or Nx.wdb.profile.Warehouse.SellGreens or Nx.wdb.profile.Warehouse.SellBlues or Nx.wdb.profile.Warehouse.SellPurps or Nx.wdb.profile.Warehouse.SellList then
            local totalearned = 0
            for bag = 0, NUM_BAG_SLOTS do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local sellit = false
                    local itemfetch = C_Container.GetContainerItemInfo(bag, slot)
                    if itemfetch then
                        local tex, stack, locked, quality, link = itemfetch.iconFileID, itemfetch.stackCount, itemfetch.isLocked, itemfetch.quality, itemfetch.hyperlink
                        if not locked and tex then
                            local name, _, _, lvl, _, _, _, _, _, _, price = C_Item.GetItemInfo(link)
                            if quality == 0 and Nx.wdb.profile.Warehouse.SellGreys and price > 0 then
                                sellit = true
                            end
                            if quality == 1 and Nx.wdb.profile.Warehouse.SellWhites and price > 0 then
                                if Nx.wdb.profile.Warehouse.SellWhitesiLVL and lvl < Nx.wdb.profile.Warehouse.SellWhitesiLVLValue then
                                    sellit = true
                                elseif not Nx.wdb.profile.Warehouse.SellWhitesiLVL then
                                    sellit = true
                                end
                            end
                            if quality == 2 and Nx.wdb.profile.Warehouse.SellGreens and price > 0 then
                                if Nx.wdb.profile.Warehouse.SellGreensBOE and Nx.Warehouse:GetStorageType(bag, slot, "BOE") then
                                    if Nx.wdb.profile.Warehouse.SellGreensiLVL and lvl < Nx.wdb.profile.Warehouse.SellGreensiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellGreensiLVL then
                                        sellit = true
                                    end
                                end
                                if Nx.wdb.profile.Warehouse.SellGreensBOP and Nx.Warehouse:GetStorageType(bag, slot, "SOULBOUND") then
                                    if Nx.wdb.profile.Warehouse.SellGreensiLVL and lvl < Nx.wdb.profile.Warehouse.SellGreensiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellGreensiLVL then
                                        sellit = true
                                    end
                                end
                            end
                            if quality == 3 and Nx.wdb.profile.Warehouse.SellBlues and price > 0 then
                                if Nx.wdb.profile.Warehouse.SellBluesBOE and Nx.Warehouse:GetStorageType(bag, slot, "BOE") then
                                    if Nx.wdb.profile.Warehouse.SellBluesiLVL and lvl < Nx.wdb.profile.Warehouse.SellBluesiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellBluesiLVL then
                                        sellit = true
                                    end
                                end
                                if Nx.wdb.profile.Warehouse.SellBluesBOP and Nx.Warehouse:GetStorageType(bag, slot, "SOULBOUND") then
                                    if Nx.wdb.profile.Warehouse.SellBluesiLVL and lvl < Nx.wdb.profile.Warehouse.SellBluesiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellBluesiLVL then
                                        sellit = true
                                    end
                                end
                            end
                            if quality == 4 and Nx.wdb.profile.Warehouse.SellPurps and price > 0 then
                                if Nx.wdb.profile.Warehouse.SellPurpsBOE and Nx.Warehouse:GetStorageType(bag, slot, "BOE") then
                                    if Nx.wdb.profile.Warehouse.SellPurpsiLVL and lvl < Nx.wdb.profile.Warehouse.SellPurpsiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellPurpsiLVL then
                                        sellit = true
                                    end
                                end
                                if Nx.wdb.profile.Warehouse.SellPurpsBOP and Nx.Warehouse:GetStorageType(bag, slot, "SOULBOUND") then
                                    if Nx.wdb.profile.Warehouse.SellPurpsiLVL and lvl < Nx.wdb.profile.Warehouse.SellPurpsiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellPurpsiLVL then
                                        sellit = true
                                    end
                                end
                            end
                            if Nx.wdb.profile.Warehouse.SellList and Nx.wdb.profile.Warehouse.SellingList[name] then
                                sellit = true
                            end
                            if sellit then
                                if not Nx.wdb.profile.Warehouse.SellTesting then
                                    C_Container.UseContainerItem(bag,slot)
                                end
                                if Nx.wdb.profile.Warehouse.SellVerbose then
                                    local moneyStr = Nx.Util_GetMoneyStr(stack * price)
                                    Nx.prt(L["Selling"] ..  " ".. name .. " @ " .. moneyStr)
                                end
                                totalearned = totalearned + (stack * price)
                            end
                        end
                    end
                end
            end
            if totalearned > 0 then
                local moneyStr = Nx.Util_GetMoneyStr(totalearned)
                Nx.prt(L["AUTO-SELL: You Earned"] .. " " .. moneyStr)
            end
        end
    end
end

function Nx.Warehouse.OnMerchant_closed()

--    Nx.prt ("OnMERCHANT_CLOSED %s", arg1)
    Nx.Warehouse:CaptureInvDurability()
end

function Nx.Warehouse:CaptureInvDurability()

    WarehouseDur = Nx:ScheduleTimer(self.CaptureInvDurabilityTimer,3,self)
end

function Nx.Warehouse:GetStorageType(bag, slot, checkwhich)
    CreateFrame("GameTooltip","scan",nil,"GameTooltipTemplate")
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    scan:SetBagItem(bag, slot)
    local foundone = false
    local scannername = scan:GetName()
    for i = 2,6 do
        local text = _G[scannername .. "TextLeft" .. i]
        if text then
            if text:GetText() == ITEM_SOULBOUND then
                foundone = "SOULBOUND"
            elseif text:GetText() == ITEM_BIND_ON_EQUIP then
                foundone = "BOE"
            end
        end
    end
    if checkwhich == foundone then
        return true
    end
    return false
end
-------------------------------------------------------------------------------

function Nx.Warehouse:CaptureInvDurabilityTimer()

--PAIDS!

--    local tm = GetTime()

--    local tip = GameTooltip
--    local textName = "GameTooltipTextLeft"
    local tip = self.DurTooltipFrm
    local textName = "NxTooltipDTextLeft"

    self.DurTooltipFrm:SetOwner (UIParent, "ANCHOR_NONE")    -- Fixes numlines 0 problem if UI was hidden

    local durPattern = L["DurPattern"]
    local durAll = 0
    local durAllMax = 0
    local durLow = 1

    for _, invName in ipairs (self.DurInvNames) do

        local id = GetInventorySlotInfo (invName)

        if tip:SetInventoryItem ("player", id) then        -- Slot has item?

--            Nx.prt ("Slot %s %s #%s", invName, id, tip:NumLines())

            for n = 4, tip:NumLines() do

--                Nx.prt ("Tip line #%s %s", n, getglobal (textName .. n):GetText() or "nil")

                local _, _, dur, durMax = strfind (_G[textName .. n]:GetText() or "", durPattern)
                if dur and durMax then
                    durAll = durAll + tonumber (dur)
                    durAllMax = durAllMax + tonumber (durMax)
                    durLow = min (durLow, tonumber (dur) / tonumber (durMax))

--                    Nx.prt (" %s", dur)

                    break
                end
            end
        end
    end

--    tip:Hide()

    local ch = Nx.Warehouse.CurCharacter

    ch["DurPercent"] = durAll / durAllMax * 100
    ch["DurLowPercent"] = durLow * 100

    ch["DurPercent"] = ch["DurPercent"] == math.huge and 0 or ch["DurPercent"]
    ch["DurLowPercent"] = ch["DurLowPercent"] == math.huge and 0 or ch["DurLowPercent"]

--    Nx.prt ("GetDur %s", GetTime() - tm)

--PAIDE!
end

-------------------------------------------------------------------------------
-- Looting
-------------------------------------------------------------------------------

function Nx.Warehouse.OnLoot_opened(_, arg1, arg2)

    local self = Nx.Warehouse

    if not self.LootTarget then
        self.LootTarget = format ("U^%s", UnitName ("target") or "")
    end

    self.LootItems = {}

    for n = 1, GetNumLootItems() do
        self.LootItems[n] = GetLootSlotLink (n)        -- Money is nil
    end

    self:prtdb (L["LOOT_OPENED %s (%s %s)"], self.LootTarget, arg1, arg2 or "nil")
end

function Nx.Warehouse.OnLoot_slot_cleared(_, arg1)

    local self = Nx.Warehouse

    if not self.LootTarget then
        self:prtdb (L["no LootTarget"])
        return
    end

    if self.LootItems[arg1] then
        local name, iLink, iRarity, lvl, minLvl, iType = C_Item.GetItemInfo (self.LootItems[arg1])
        if iType == "Quest" then
            self:prtdb (L["LOOT_SLOT_CLEARED #%s %s (quest)"], arg1, self.LootItems[arg1])
            self:Capture (iLink)
        end
    end
end

function Nx.Warehouse.OnLoot_closed()

    local self = Nx.Warehouse

    self.LootTarget = nil
--    self.LootItems = nil                -- Cant do. Sometimes called before OnLOOT_SLOT_CLEARED

    self:prtdb ("LOOT_CLOSED")
end

--[[
function Nx.Warehouse:DiffBags (oldBags)

    local ch = Nx.CurCharacter

    for name, v in pairs (ch["WareBags"]) do

        local newCnt, link = Nx.Split ("^", v)

        if oldBags[name] then
            local oldCnt = Nx.Split ("^", oldBags[name])
            if newCnt > oldCnt then

                local name, iLink, iRarity, lvl, minLvl, itype = C_Item.GetItemInfo (link)
                if itype == "Quest" then
                    self:prtdb ("Quest item added: %s", name)
                    self:Capture (link)
                end
            end
        else
            local name, iLink, iRarity, lvl, minLvl, itype = C_Item.GetItemInfo (link)
            if itype == "Quest" then
                self:prtdb ("Quest item added: %s", name)
                self:Capture (link)
            end
        end
    end
end
--]]

function Nx.Warehouse:Capture (link)

end

function Nx.Warehouse:CaptureGet (t, key)

    assert (type (t) == "table" and key)

    local d = t[key] or {}
    t[key] = d
    return d
end

-------------------------------------------------------------------------------
-- Skill message
-------------------------------------------------------------------------------

function Nx.Warehouse.OnChat_msg_skill()

    local self = Nx.Warehouse

    if self.Enabled then

--        Nx.prt ("OnChat_msg_skill")

        WarehouseRec = Nx:ScheduleTimer(self.RecordCharacterSkills,.5,self)
    end
end

-------------------------------------------------------------------------------
-- Record 2 professions name rank and riding skill
-------------------------------------------------------------------------------

function Nx.Warehouse:RecordCharacterSkills()

--    Nx.prt ("Warehouse Rec skill")

    local ch = Nx.Warehouse.CurCharacter

    for _, v in pairs (ch["Profs"]) do
        v.Old = true    -- Flag for delete
    end

    -- Check riding spells to get skill

    self.SkillRiding = Nx.Travel:GetRidingSkill()

--    Nx.prt ("WH riding %s", self.SkillRiding)

    -- Scan professions

--    local prof_1, prof_2, archaeology, fishing, cooking, firstaid = GetProfessions()        -- Indices for GetProfessionInfo
    local proI = { GetProfessions() }        -- Indices for GetProfessionInfo

    for _, i in pairs (proI) do

        local name, icon, rank, maxrank, numspells, spelloffset, skillline = GetProfessionInfo (i)
        if name then

--            Nx.prt ("Prof %s %s %d", i, name, rank)

            local t = ch["Profs"]
            local p = t[name] or {}
            t[name] = p
            p["Rank"] = rank
            p.Old = nil
        end
    end


--[[    OLD <4.0
    for n = 1, GetNumSkillLines() do

        local name, hdr, expanded = GetSkillLineInfo (n)
        if not name then
            break
        end

        if hdr and (name == self.LProfessions or name == self.LSecondarySkills) then

--            Nx.prt ("hdr %s", name)

            local open

            if not expanded then
--                Nx.prt (" #%s %s", n, GetNumSkillLines())
                ExpandSkillHeader (n)
                open = n
--                Nx.prt (" #%s %s", n, GetNumSkillLines())
            end

            for n2 = n + 1, GetNumSkillLines() do

                local name, hdr, expanded, rank, tempPoints, modifier = GetSkillLineInfo (n2)

                if hdr then
                    break
                end

                if name == NXlRiding then
                    self.SkillRiding = rank

                else

--                    Nx.prt (" skill %s", name)

                    local t = ch["Profs"]
                    local p = t[name] or {}
                    t[name] = p
                    p["Rank"] = rank
                    p.Old = nil
                end
            end

            if open then
                CollapseSkillHeader (open)
            end
        end
    end
--]]

    -- Nuke any old ones

    for name, v in pairs (ch["Profs"]) do
        if v.Old then
            ch["Profs"][name] = nil
            Nx.prt (L["%s deleted"], name)
        end
    end

--    Nx.prt ("Riding %s", self.SkillRiding)
end

-------------------------------------------------------------------------------
-- TRADE SKILL TRACKING
-------------------------------------------------------------------------------

---
-- Handle trade skill update event
--
function Nx.Warehouse.OnTrade_skill_update()

    local self = Nx.Warehouse
    if self.Enabled then

--        Nx.prt ("OnTrade_skill_update")
--        Nx.prt ("#skills %s", GetNumTradeSkills())

-- #        WarehouseRecProf = Nx:ScheduleTimer(self.RecordProfession,0,self)
    end
end

--[[
function Nx.Map.Guide.OnTrade_skill_show()    -- Your own trade window

--    local self = Nx.Map.Guide

    Nx.prt ("OnTRADE_SKILL_SHOW")

    Nx.prtStrHex ("Trade", GetTradeSkillListLink())
    local link = GetTradeSkillListLink()

--    self:SavePlayerNPCTarget()
end
--]]

-------------------------------------------------------------------------------
-- PROFESSION RECORDING
-------------------------------------------------------------------------------

---
-- Record profession recipes and links
--
function Nx.Warehouse:RecordProfession()

--    Nx.prt ("Rec #skills %s", GetNumTradeSkills())

    local linked = C_TradeSkillUI.IsTradeSkillLinked()
    if linked then
--        Nx.prt (" Linked, skip")
        return
    end

    local recipies = C_TradeSkillUI.GetAllRecipeIDs()

    if recipies and #recipies == 0 then
        return
    end

    local ch = Nx.Warehouse.CurCharacter

    local _,title = C_TradeSkillUI.GetTradeSkillLine()

    local profT = ch["Profs"][title]

    if not profT then
        return
    end

    local link = C_TradeSkillUI.GetTradeSkillListLink()
    if link then
        profT["Link"] = link
    end

    local recipiesInfo = {}
    for n = 1, #recipies do
        local skipadd = 0
        local recipiesInfo = C_TradeSkillUI.GetRecipeInfo(recipies[n])
        local rId = recipiesInfo.recipeID
        local link = C_TradeSkillUI.GetRecipeItemLink (rId)
        local itemId = link and strmatch (link, L["item:(%d+)"]) or 0
        profT[tonumber (rId)] = tonumber (itemId)
    end
end

---
-- Button callback to toggle warehouse window
--
function Nx.Warehouse:OnButToggleWarehouse(but)
    Nx.Warehouse:ToggleShow()
end

-------------------------------------------------------------------------------
-- CHARACTER DATA MANAGEMENT
-------------------------------------------------------------------------------

---
-- Initialize warehouse data for current character
--
function Nx.Warehouse:InitWarehouseCharacter()
    local chars = Nx.wdb.global.Characters
    local fullName = Nx:GetRealmCharName()
    local ch = chars[fullName]
    if not ch then
        ch = {}
    end
    Nx.Warehouse.CurCharacter = ch
    ch["Profs"] = ch["Profs"] or {}        -- Professions
end

---
-- Record character data at login
-- Captures initial state of money, XP, honor, etc.
--
function Nx.Warehouse:RecordCharacterLogin()
    local ch = self.CurCharacter
    ch["LTime"] = time()
    ch["LvlTime"] = time()
    ch["LLevel"] = UnitLevel ("player")
    ch["Class"] = Nx:GetUnitClass()
    ch["LMoney"] = GetMoney()
    ch["LXP"] = UnitXP ("player")
    ch["LXPMax"] = UnitXPMax ("player")
    ch["LXPRest"] = GetXPExhaustion() or 0
    local _, arena =  GetCurrencyInfo(390)
    local _, honor = GetCurrencyInfo(1901)
    ch["Conquest"] = arena            --V4 gone GetArenaCurrency()
    ch["Honor"] = honor            --V4 gone GetHonorCurrency()
    Nx.Warehouse:RecordCharacter()
    Nx.Warehouse:RecordCurrency()
end

---
-- Record current character data
-- Updates position, level, money, and experience
--
function Nx.Warehouse:RecordCharacter()
    local ch = self.CurCharacter
    local map = Nx.Map:GetMap (1)
    if not ch or not map then
        return
    end
    if map.UpdateMapID then
        ch["Pos"] = format ("%d^%f^%f", map.UpdateMapID, map.PlyrRZX, map.PlyrRZY)
    end
    ch["Time"] = time()
    ch["Level"] = UnitLevel ("player")
    ch["Class"] = Nx:GetUnitClass()
    if ch["Level"] > ch["LLevel"] then    -- Made a level? Reset
        ch["LLevel"] = ch["Level"]
        ch["LvlTime"] = time()
        ch["LXP"] = UnitXP ("player")
        ch["LXPMax"] = UnitXPMax ("player")
        ch["LXPRest"] = GetXPExhaustion() or 0
    end
    ch["Money"] = GetMoney()
    ch["XP"] = UnitXP ("player")
    ch["XPMax"] = UnitXPMax ("player")
    ch["XPRest"] = GetXPExhaustion() or 0
end

---
-- Record all tracked currencies for current character
--
function Nx.Warehouse:RecordCurrency()
    local ch = self.CurCharacter
    ch["Currency"] = {}
    for _,currency in pairs(CurrencyArray) do
        local name, count = GetCurrencyInfo(currency)
        if not isHeader then
            if ch[name] then ch[name] = {} end  --- Move currencys into subtable for something i'm planning / thinking of.
            ch["Currency"][currency]=count
        end
    end
end

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------
