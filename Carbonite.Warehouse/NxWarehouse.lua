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
Nx.Warehouse = Nx.Warehouse or {}
Nx.Warehouse.ProfessionSchemaVersion = 3
Nx.Warehouse.StorageSchemaVersion = 1

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
Nx.Warehouse.CharBags       = {}
Nx.Warehouse.BankBags       = {}
Nx.Warehouse.BandBags       = {}
Nx.Warehouse.BandBankActive = false
local CharBags = Nx.Warehouse.CharBags
local BankBags = Nx.Warehouse.BankBags
local BandBags = Nx.Warehouse.BandBags

-- Check if Enum.BagIndex exists (not available in all Classic versions)
if Enum and Enum.BagIndex then
    local bagIndex = Enum.BagIndex

    for _, idx in ipairs({
        bagIndex.Backpack,
        bagIndex.Bag_1,
        bagIndex.Bag_2,
        bagIndex.Bag_3,
        bagIndex.Bag_4,
    }) do
        if idx ~= nil then
            CharBags[#CharBags + 1] = idx
        end
    end

    if bagIndex.ReagentBag ~= nil then
        CharBags[#CharBags + 1] = bagIndex.ReagentBag
    end

    -- Modern character banks use purchased tab bag IDs. Older clients use
    -- the legacy bank container plus seven bank-bag containers. Detect the
    -- storage model from the enum itself rather than from a project/version
    -- flag so new clients inherit the correct behavior automatically.
    if bagIndex.CharacterBankTab_1 ~= nil then
        for index = 1, 6 do
            local idx = bagIndex["CharacterBankTab_" .. index]
            if idx ~= nil then
                BankBags[#BankBags + 1] = idx
            end
        end
    else
        if bagIndex.Bank ~= nil then
            BankBags[#BankBags + 1] = bagIndex.Bank
        end
        for index = 1, 7 do
            local idx = bagIndex["BankBag_" .. index]
            if idx ~= nil then
                BankBags[#BankBags + 1] = idx
            end
        end
    end

    -- Account/Warband storage is scanned separately from character bags so
    -- shared inventory is never copied into every character record. Presence
    -- of the enum alone is not enough to enable it; runtime C_Bank capability
    -- checks below decide whether the feature can actually be scanned.
    for index = 1, 5 do
        local idx = bagIndex["AccountBankTab_" .. index]
        if idx ~= nil then
            BandBags[#BandBags + 1] = idx
        end
    end

    if not Nx.CataMaps and bagIndex.Keyring ~= nil then
        CharBags[#CharBags + 1] = bagIndex.Keyring
    end
else
    -- Fallback for clients without Enum.BagIndex. Populate the shared tables
    -- in-place so Engine.lua sees the same lists through Nx.Warehouse.
    for _, idx in ipairs({ 0, 1, 2, 3, 4 }) do
        CharBags[#CharBags + 1] = idx
    end
    for _, idx in ipairs({ -1, 5, 6, 7, 8, 9, 10, 11 }) do
        BankBags[#BankBags + 1] = idx
    end
end

-------------------------------------------------------------------------------
-- WAREHOUSE API COMPATIBILITY
-------------------------------------------------------------------------------

Nx.Warehouse.API = Nx.Warehouse.API or {}
local WarehouseAPI = Nx.Warehouse.API

local SharedAPI = Nx.Compat and Nx.Compat.Api
local ContainerAPI = SharedAPI and SharedAPI.Container
local ItemAPI = SharedAPI and SharedAPI.Item
local SpellAPI = SharedAPI and SharedAPI.Spell
local CTradeSkillUI = _G.C_TradeSkillUI
local CBank = _G.C_Bank
local CCurrencyInfo = _G.C_CurrencyInfo

function WarehouseAPI.GetContainerItemInfo(bag, slot)
    if ContainerAPI then
        return ContainerAPI:GetItemInfo(bag, slot)
    end
end

function WarehouseAPI.GetContainerItemLink(bag, slot)
    if ContainerAPI then
        return ContainerAPI:GetItemLink(bag, slot)
    end
end

function WarehouseAPI.GetContainerNumSlots(bag)
    if ContainerAPI then
        return ContainerAPI:GetNumSlots(bag)
    end
    return 0
end

function WarehouseAPI.UseContainerItem(bag, slot)
    if ContainerAPI then
        return ContainerAPI:UseItem(bag, slot)
    end
end

function WarehouseAPI.GetItemInfo(item)
    if ItemAPI then
        return ItemAPI:GetInfo(item)
    end
end

function WarehouseAPI.RequestItemData(item)
    if ItemAPI then
        return ItemAPI:RequestData(item)
    end
end

local function NormalizeCurrencyInfo(info, fallbackID)
    if type(info) ~= "table" then
        return nil
    end
    return {
        currencyID = tonumber(info.currencyID) or tonumber(fallbackID),
        name = info.name,
        quantity = tonumber(info.quantity) or 0,
        iconFileID = info.iconFileID,
        isHeader = info.isHeader and true or false,
        discovered = info.discovered,
        isAccountWide = info.isAccountWide and true or false,
        isAccountTransferable = info.isAccountTransferable and true or false,
        maxQuantity = tonumber(info.maxQuantity) or 0,
        maxWeeklyQuantity = tonumber(info.maxWeeklyQuantity) or 0,
    }
end

function WarehouseAPI.GetCurrencyInfo(currencyID)
    if CCurrencyInfo and CCurrencyInfo.GetCurrencyInfo then
        local info = CCurrencyInfo.GetCurrencyInfo(currencyID)
        if type(info) == "table" then
            return NormalizeCurrencyInfo(info, currencyID)
        end
    end

    if _G.GetCurrencyInfo then
        local name, quantity, iconFileID, earnedThisWeek, weeklyMax, totalMax,
              isDiscovered, quality = _G.GetCurrencyInfo(currencyID)
        if name then
            return {
                currencyID = tonumber(currencyID),
                name = name,
                quantity = tonumber(quantity) or 0,
                iconFileID = iconFileID,
                isHeader = false,
                discovered = isDiscovered,
                earnedThisWeek = earnedThisWeek,
                weeklyMax = weeklyMax,
                totalMax = totalMax,
                quality = quality,
            }
        end
    end
end

function WarehouseAPI.GetCurrencyListEntries()
    local entries = {}
    if not (CCurrencyInfo and CCurrencyInfo.GetCurrencyListSize and CCurrencyInfo.GetCurrencyListInfo) then
        return entries, false
    end

    local size = tonumber(CCurrencyInfo.GetCurrencyListSize()) or 0
    for index = 1, size do
        local info = CCurrencyInfo.GetCurrencyListInfo(index)
        local normalized = NormalizeCurrencyInfo(info)
        if normalized and normalized.currencyID and not normalized.isHeader then
            entries[normalized.currencyID] = normalized
        end
    end
    return entries, true
end

local function GetCurrencyConstants()
    return _G.Constants and _G.Constants.CurrencyConsts
end

function WarehouseAPI.GetHonorCurrencyID()
    local constants = GetCurrencyConstants()
    if constants then
        if Nx.isRetail and constants.HONOR_CURRENCY_ID then
            return constants.HONOR_CURRENCY_ID
        end
        if constants.CLASSIC_HONOR_CURRENCY_ID then
            return constants.CLASSIC_HONOR_CURRENCY_ID
        end
        if constants.HONOR_CURRENCY_ID then
            return constants.HONOR_CURRENCY_ID
        end
    end
    return Nx.isRetail and 1792 or 1901
end

function WarehouseAPI.GetConquestCurrencyID()
    local constants = GetCurrencyConstants()
    if constants then
        if Nx.isRetail and constants.CONQUEST_CURRENCY_ID then
            return constants.CONQUEST_CURRENCY_ID
        end
        if constants.CLASSIC_CONQUEST_CURRENCY_ID then
            return constants.CLASSIC_CONQUEST_CURRENCY_ID
        end
        if constants.CONQUEST_POINTS_CURRENCY_ID then
            return constants.CONQUEST_POINTS_CURRENCY_ID
        end
        if constants.CONQUEST_CURRENCY_ID then
            return constants.CONQUEST_CURRENCY_ID
        end
    end
    return Nx.isRetail and 1602 or 390
end

function WarehouseAPI.HasModernCharacterBank()
    return Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 ~= nil
end

function WarehouseAPI.HasAccountBank()
    return #BandBags > 0
        and CBank ~= nil
        and type(CBank.FetchPurchasedBankTabIDs) == "function"
        and Enum ~= nil
        and Enum.BankType ~= nil
        and Enum.BankType.Account ~= nil
end

function WarehouseAPI.GetPurchasedBankTabIDs(bankType, fallback)
    if CBank and CBank.FetchPurchasedBankTabIDs and bankType ~= nil then
        local ok, tabs = pcall(CBank.FetchPurchasedBankTabIDs, bankType)
        if ok and type(tabs) == "table" then
            return tabs, true
        end
    end
    return fallback or {}, false
end

function WarehouseAPI.GetCharacterBankBags()
    if WarehouseAPI.HasModernCharacterBank()
        and CBank and CBank.FetchPurchasedBankTabIDs
        and Enum and Enum.BankType and Enum.BankType.Character ~= nil then
        return WarehouseAPI.GetPurchasedBankTabIDs(Enum.BankType.Character, BankBags)
    end
    return BankBags, false
end

function WarehouseAPI.GetAccountBankBags()
    if WarehouseAPI.HasAccountBank() then
        return WarehouseAPI.GetPurchasedBankTabIDs(Enum.BankType.Account, BandBags)
    end
    return {}, false
end

function WarehouseAPI.GetDepositedBankMoney(bankType)
    if CBank and CBank.FetchDepositedMoney and bankType ~= nil then
        local ok, amount = pcall(CBank.FetchDepositedMoney, bankType)
        if ok then
            return tonumber(amount) or 0, true
        end
    end
    return 0, false
end

function WarehouseAPI.CanScanAccountBank()
    if not WarehouseAPI.HasAccountBank() then
        return false
    end
    if CBank and CBank.FetchBankLockedReason and Enum and Enum.BankType then
        local ok, reason = pcall(CBank.FetchBankLockedReason, Enum.BankType.Account)
        if ok and reason ~= nil then
            return false
        end
    end
    return true
end

Nx.Warehouse.BandBankActive = WarehouseAPI.HasAccountBank()

function WarehouseAPI.GetProfessionIndexes()
    if not _G.GetProfessions then
        return {}
    end
    return { _G.GetProfessions() }
end

function WarehouseAPI.GetProfessionInfo(index)
    if _G.GetProfessionInfo then
        return _G.GetProfessionInfo(index)
    end
end

function WarehouseAPI.GetSpellName(spellID)
    if SpellAPI then
        return SpellAPI:GetName(spellID)
    end
end

function WarehouseAPI.GetSpellLink(spellID)
    if SpellAPI then
        return SpellAPI:GetLink(spellID)
    end
end

function WarehouseAPI.InsertChatLink(link, openIfInactive)
    if type(link) ~= "string" or link == "" then
        return false
    end

    local chatUtil = _G.ChatFrameUtil
    if chatUtil then
        local active = chatUtil.GetActiveWindow and chatUtil.GetActiveWindow()
        if active and chatUtil.InsertLink then
            chatUtil.InsertLink(link)
            return true
        end
        if openIfInactive and chatUtil.OpenChat then
            chatUtil.OpenChat(link)
            return true
        end
    end

    local editBox = _G.ChatEdit_GetActiveWindow and _G.ChatEdit_GetActiveWindow()
    if not editBox and _G.DEFAULT_CHAT_FRAME then
        editBox = _G.DEFAULT_CHAT_FRAME.editBox
    end
    if editBox and editBox.IsVisible and editBox:IsVisible() then
        if editBox.Insert then
            editBox:Insert(link)
        else
            editBox:SetText((editBox:GetText() or "") .. link)
        end
        return true
    end

    if openIfInactive and _G.ChatFrame_OpenChat then
        _G.ChatFrame_OpenChat(link)
        return true
    end

    return false
end

function WarehouseAPI.IsTradeSkillLinked()
    if CTradeSkillUI and CTradeSkillUI.IsTradeSkillLinked then
        return CTradeSkillUI.IsTradeSkillLinked()
    end
    if _G.IsTradeSkillLinked then
        return _G.IsTradeSkillLinked()
    end
    return false
end

function WarehouseAPI.HasModernTradeSkillRecipes()
    return CTradeSkillUI ~= nil
        and type(CTradeSkillUI.GetFilteredRecipeIDs) == "function"
        and type(CTradeSkillUI.GetRecipeInfo) == "function"
end

function WarehouseAPI.IsNPCCrafting()
    return CTradeSkillUI and CTradeSkillUI.IsNPCCrafting and CTradeSkillUI.IsNPCCrafting() or false
end

function WarehouseAPI.GetOpenProfessionScope()
    if WarehouseAPI.HasModernTradeSkillRecipes() then
        local baseInfo = CTradeSkillUI.GetBaseProfessionInfo and CTradeSkillUI.GetBaseProfessionInfo()
        local childInfo = CTradeSkillUI.GetChildProfessionInfo and CTradeSkillUI.GetChildProfessionInfo()
        local skillLineID = CTradeSkillUI.GetProfessionChildSkillLineID and CTradeSkillUI.GetProfessionChildSkillLineID()

        if (not skillLineID or skillLineID == 0) and childInfo then
            skillLineID = childInfo.professionID
        end

        local title = baseInfo and baseInfo.professionName
        if not title and childInfo then
            title = childInfo.parentProfessionName or childInfo.professionName
        end

        if title and title ~= "" then
            return {
                key = skillLineID and ("skill:" .. tostring(skillLineID)) or ("modern:" .. title),
                skillLineID = skillLineID,
                title = title,
                professionName = childInfo and childInfo.professionName or title,
                expansionName = childInfo and childInfo.expansionName,
                rank = childInfo and childInfo.skillLevel,
                maxRank = childInfo and childInfo.maxSkillLevel,
                modern = true,
            }
        end
    end

    if _G.GetTradeSkillLine then
        local title, rank, maxRank = _G.GetTradeSkillLine()
        if title and title ~= "" then
            return {
                key = "legacy:" .. title,
                title = title,
                professionName = title,
                rank = rank,
                maxRank = maxRank,
                modern = false,
            }
        end
    end
end

function WarehouseAPI.GetOpenProfessionName()
    local scope = WarehouseAPI.GetOpenProfessionScope()
    return scope and scope.title
end

function WarehouseAPI.GetTradeSkillListLink()
    if CTradeSkillUI and CTradeSkillUI.GetTradeSkillListLink then
        return CTradeSkillUI.GetTradeSkillListLink()
    end
    if _G.GetTradeSkillListLink then
        return _G.GetTradeSkillListLink()
    end
end

local function ExtractLinkID(link, linkType)
    if type(link) ~= "string" then
        return nil
    end
    return tonumber(string.match(link, linkType .. ":(%d+)"))
end

local function IsModernRecipeScanComplete()
    if not WarehouseAPI.HasModernTradeSkillRecipes() then
        return false
    end

    if CTradeSkillUI.GetRecipeItemNameFilter then
        local text = CTradeSkillUI.GetRecipeItemNameFilter()
        if type(text) == "string" and text ~= "" then
            return false
        end
    end
    if CTradeSkillUI.GetShowLearned and not CTradeSkillUI.GetShowLearned() then
        return false
    end
    if CTradeSkillUI.GetOnlyShowMakeableRecipes and CTradeSkillUI.GetOnlyShowMakeableRecipes() then
        return false
    end
    if CTradeSkillUI.GetOnlyShowSkillUpRecipes and CTradeSkillUI.GetOnlyShowSkillUpRecipes() then
        return false
    end
    if CTradeSkillUI.GetOnlyShowFirstCraftRecipes and CTradeSkillUI.GetOnlyShowFirstCraftRecipes() then
        return false
    end
    if CTradeSkillUI.AreAnyInventorySlotsFiltered and CTradeSkillUI.AreAnyInventorySlotsFiltered() then
        return false
    end
    if CTradeSkillUI.AnyRecipeCategoriesFiltered and CTradeSkillUI.AnyRecipeCategoriesFiltered() then
        return false
    end

    local petJournal = _G.C_PetJournal
    if petJournal and petJournal.GetNumPetSources
        and CTradeSkillUI.IsAnyRecipeFromSource
        and CTradeSkillUI.IsRecipeSourceTypeFiltered then

        for sourceIndex = 1, petJournal.GetNumPetSources() do
            if CTradeSkillUI.IsAnyRecipeFromSource(sourceIndex)
                and CTradeSkillUI.IsRecipeSourceTypeFiltered(sourceIndex) then
                return false
            end
        end
    end

    return true
end

local function GetRecipeOutputMetadata(recipeID)
    local itemID
    local qualityItemIDs

    if CTradeSkillUI.GetRecipeSchematic then
        local schematic = CTradeSkillUI.GetRecipeSchematic(recipeID, false)
        if schematic then
            itemID = schematic.outputItemID
        end
    end

    if CTradeSkillUI.GetFactionSpecificOutputItem then
        itemID = CTradeSkillUI.GetFactionSpecificOutputItem(recipeID) or itemID
    end

    if not itemID and CTradeSkillUI.GetRecipeOutputItemData then
        local outputInfo = CTradeSkillUI.GetRecipeOutputItemData(recipeID)
        if outputInfo then
            itemID = outputInfo.itemID or ExtractLinkID(outputInfo.hyperlink, "item")
        end
    end

    if CTradeSkillUI.GetRecipeQualityItemIDs then
        local ids = CTradeSkillUI.GetRecipeQualityItemIDs(recipeID)
        if type(ids) == "table" and #ids > 0 then
            qualityItemIDs = {}
            for _, id in ipairs(ids) do
                id = tonumber(id)
                if id and id > 0 then
                    qualityItemIDs[#qualityItemIDs + 1] = id
                end
            end
            if not itemID then
                itemID = qualityItemIDs[1]
            end
            if #qualityItemIDs == 0 then
                qualityItemIDs = nil
            end
        end
    end

    return tonumber(itemID) or 0, qualityItemIDs
end

function WarehouseAPI.GetOpenProfessionRecipes(scope)
    local recipes = {}
    scope = scope or WarehouseAPI.GetOpenProfessionScope()

    if WarehouseAPI.HasModernTradeSkillRecipes() then
        local complete = IsModernRecipeScanComplete()
        local recipeIDs = CTradeSkillUI.GetFilteredRecipeIDs() or {}

        if not scope or not scope.skillLineID or not CTradeSkillUI.IsRecipeInSkillLine then
            complete = false
        end

        for _, recipeID in ipairs(recipeIDs) do
            local info = CTradeSkillUI.GetRecipeInfo(recipeID)
            if info and info.recipeID and info.learned then
                local inScope = true
                if scope and scope.skillLineID and CTradeSkillUI.IsRecipeInSkillLine then
                    inScope = CTradeSkillUI.IsRecipeInSkillLine(info.recipeID, scope.skillLineID)
                end
                if inScope then
                    local itemID, qualityItemIDs = GetRecipeOutputMetadata(info.recipeID)
                    recipes[#recipes + 1] = {
                        recipeID = info.recipeID,
                        itemID = itemID,
                        qualityItemIDs = qualityItemIDs,
                        name = info.name,
                        icon = info.icon,
                        link = info.hyperlink,
                        categoryID = info.categoryID,
                        supportsQualities = info.supportsQualities and true or false,
                    }
                end
            end
        end
        return recipes, complete, scope
    end

    if _G.GetNumTradeSkills and _G.GetTradeSkillInfo then
        local count = _G.GetNumTradeSkills() or 0
        for index = 1, count do
            local recipeName, skillType = _G.GetTradeSkillInfo(index)
            if skillType and skillType ~= "header" then
                local recipeLink = _G.GetTradeSkillRecipeLink and _G.GetTradeSkillRecipeLink(index)
                local recipeID = ExtractLinkID(recipeLink, "enchant") or ExtractLinkID(recipeLink, "spell")
                if recipeID then
                    local itemLink = _G.GetTradeSkillItemLink and _G.GetTradeSkillItemLink(index)
                    local itemID = ExtractLinkID(itemLink, "item") or 0
                    local icon
                    if _G.GetTradeSkillIcon then
                        icon = _G.GetTradeSkillIcon(index)
                    end
                    recipes[#recipes + 1] = {
                        recipeID = recipeID,
                        itemID = itemID,
                        name = recipeName,
                        icon = icon,
                        link = recipeLink,
                    }
                end
            end
        end
    end

    -- Legacy trade-skill APIs can be filtered by the client UI and do not
    -- expose enough state consistently to prove that a scan is complete.
    return recipes, false, scope
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
