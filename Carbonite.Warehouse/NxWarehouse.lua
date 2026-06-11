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

-- Bag-id catalogs live on the namespace so the extracted Engine.lua
-- can read them. File-local aliases below let existing NxWarehouse
-- code stay unchanged. The namespace table is created here because
-- the canonical `Nx.Warehouse = {}` declaration further down was
-- relying on already-existing state, but the bag-id catalogs run
-- first.
Nx.Warehouse = Nx.Warehouse or {}
Nx.Warehouse.CharBags       = {}
Nx.Warehouse.BankBags       = {}
Nx.Warehouse.BandBags       = {}
Nx.Warehouse.BandBankActive = false
local CharBags = Nx.Warehouse.CharBags
local BankBags = Nx.Warehouse.BankBags
local BandBags = Nx.Warehouse.BandBags

-- Check if Enum.BagIndex exists (not available in all Classic versions)
if Enum and Enum.BagIndex then
    -- Character bags. Build into the namespace table directly so the
    -- alias above keeps pointing at the same shared list.
    for _, idx in ipairs({
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
    }) do CharBags[#CharBags + 1] = idx end

    if Nx.isRetail then
        Nx.Warehouse.BandBankActive = true
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
            -- Build into the shared namespace table in-place so the
            -- file-local alias (and any later readers) keep pointing
            -- at the same array.
            for _, idx in ipairs({
                Enum.BagIndex.AccountBankTab_1,
                Enum.BagIndex.AccountBankTab_2,
                Enum.BagIndex.AccountBankTab_3,
                Enum.BagIndex.AccountBankTab_4,
                Enum.BagIndex.AccountBankTab_5,
            }) do BandBags[#BandBags + 1] = idx end
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

Nx.Warehouse.defaults = {
    profile = {
        Warehouse = {
            -- Font settings
            WarehouseFont = "Friz",
            WarehouseFontSize = 11,
            WarehouseFontSpacing = 6,
            WarehouseFontOutline = "",
            WarehouseFontShadow = false,
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

-- Warehouse module namespace. Don't clobber — the bag-id catalogs
-- and BandBankActive flag set up earlier in this file live on the
-- same table.
Nx.Warehouse = Nx.Warehouse or {}

-------------------------------------------------------------------------------
-- CURRENCY TRACKING
-- Array of currency IDs to track
-------------------------------------------------------------------------------

Nx.Warehouse.CurrencyArray = {
    61, 81, 241, 361, 384, 385, 391, 393, 394, 395, 396, 397, 398, 399, 400,
    401, 402, 416, 515, 614, 615, 676, 677, 697, 698, 738, 752, 754, 766, 777,
    789, 810, 821, 823, 824, 828, 829, 910, 944, 980, 994, 999, 1008, 1017,
    1020, 1101, 1129, 1149, 1154, 1155, 1166, 1171, 1172, 1173, 1174, 1191,
    1220, 1226, 1268, 1273, 1275, 1299, 1314, 1324, 1325, 1342, 1355, 1356,
    1357, 1379, 1416, 1501, 1506, 1508, 1533
}

local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo or GetCurrencyInfo


