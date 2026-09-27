-- Carbonite.Warehouse | Init
-- AceAddon lifecycle for the CarboniteWarehouse plugin: database
-- creation, event dispatcher, guild-bank-sync callbacks, the legacy
-- ConvertData migration, and the warehouse-specific Init / Login
-- / prtdb helpers. Lifted from NxWarehouse.lua so that file stays
-- focused on data declarations + the actual storage tables.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Warehouse', true)

-- Guild-bank comm library — used by OnInitialize and the sync
-- callbacks below. NxWarehouse.lua holds its own file-local of the
-- same LibStub object; LibStub returns the same table each call so
-- the two aliases stay in sync.
local GuildBank = LibStub("LibGuildBankComm-1.0")

local Nx = _G.Nx
if not Nx then return end
Nx.Warehouse = Nx.Warehouse or {}

local function RegisterWarehouseEvent(event)
    if type(event) ~= "string" or event == "" then
        return false
    end

    local ok = pcall(CarboniteWarehouse.RegisterEvent, CarboniteWarehouse, event, "EventHandler")
    return ok
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
        Nx.Warehouse.InitTimer = Nx:ScheduleTimer(CarboniteWarehouse.OnInitialize, 1)
        return
    end
    Nx.wdb = LibStub("AceDB-3.0"):New("NXWhouse", Nx.Warehouse.defaults, true)
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
    Nx.Warehouse:ConvertData()
    Nx.Warehouse:InitWarehouseCharacter()
    Nx.Font:ModuleAdd("Warehouse.WarehouseFont",{ "NxFontWHI", "GameFontNormal","wdb" })
    Nx.Warehouse:Init()
    Nx.Warehouse:Login()
    Nx.Warehouse:CaptureItems()
    local function func ()
        Nx.Warehouse:ToggleShow()
    end
    Nx.NXMiniMapBut.Menu:AddItem(0, L["Show Warehouse"], func, Nx.NXMiniMapBut)
    RegisterWarehouseEvent("BAG_UPDATE_DELAYED")
    RegisterWarehouseEvent("PLAYERBANKSLOTS_CHANGED")
    RegisterWarehouseEvent("BANKFRAME_OPENED")
    RegisterWarehouseEvent("BANKFRAME_CLOSED")
    if Nx.Warehouse.API and Nx.Warehouse.API.HasAccountBank and Nx.Warehouse.API.HasAccountBank() then
        RegisterWarehouseEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
        RegisterWarehouseEvent("BANK_TABS_CHANGED")
    elseif not (Nx.Warehouse.API and Nx.Warehouse.API.HasModernCharacterBank and Nx.Warehouse.API.HasModernCharacterBank()) then
        RegisterWarehouseEvent("PLAYERBANKBAGSLOTS_CHANGED")
        if _G.REAGENTBANK_CONTAINER then
            RegisterWarehouseEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
        end
    end
    RegisterWarehouseEvent("GUILDBANKFRAME_OPENED")
    RegisterWarehouseEvent("GUILDBANKFRAME_CLOSED")
    RegisterWarehouseEvent("GUILDBANKBAGSLOTS_CHANGED")
    RegisterWarehouseEvent("GUILDBANK_UPDATE_TABS")
    RegisterWarehouseEvent("GUILDBANK_UPDATE_MONEY")
    RegisterWarehouseEvent("ITEM_LOCK_CHANGED")
    RegisterWarehouseEvent("GET_ITEM_INFO_RECEIVED")
    RegisterWarehouseEvent("MAIL_INBOX_UPDATE")
    RegisterWarehouseEvent("UNIT_INVENTORY_CHANGED")
    RegisterWarehouseEvent("MERCHANT_SHOW")
    RegisterWarehouseEvent("MERCHANT_CLOSED")
    RegisterWarehouseEvent("TIME_PLAYED_MSG")
    RegisterWarehouseEvent("LOOT_OPENED")
    RegisterWarehouseEvent("LOOT_SLOT_CLEARED")
    RegisterWarehouseEvent("LOOT_CLOSED")
    RegisterWarehouseEvent("CHAT_MSG_SKILL")
    RegisterWarehouseEvent("SKILL_LINES_CHANGED")
    RegisterWarehouseEvent("TRADE_SKILL_CLOSE")
    RegisterWarehouseEvent("TRADE_SKILL_SHOW")
    if Nx.Warehouse.API and Nx.Warehouse.API.HasModernTradeSkillRecipes and Nx.Warehouse.API.HasModernTradeSkillRecipes() then
        RegisterWarehouseEvent("TRADE_SKILL_LIST_UPDATE")
    end
    RegisterWarehouseEvent("PLAYER_LOGIN")
    -- UNIT_SPELLCAST_* via a dedicated unit-filtered frame instead of
    -- AceEvent. AceEvent funnels every event onto one shared frame
    -- registered with the unfiltered RegisterEvent; that frame sits in the
    -- same global secure-dispatch list as Blizzard's CastingBarFrame, so
    -- Carbonite's taint leaks onto the casting bar's staged/empowered-cast
    -- animation code ("attempted to iterate a table that cannot be accessed
    -- while tainted ... CastingBarFrame StopAnims/StopFinishAnims").
    -- RegisterUnitEvent scoped to "player" routes us through the
    -- filtered-event path, which dispatches separately and keeps our taint
    -- off the casting bar. The handlers only ever act on arg1 == "player",
    -- so behaviour is unchanged.
    if not Nx.Warehouse.SpellcastFrame then
        local castFrame = CreateFrame("Frame", "CarboniteWarehouseSpellcastFrame")
        castFrame:SetScript("OnEvent", function (_, event, ...)
            CarboniteWarehouse:EventHandler(event, ...)
        end)
        castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        castFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
        castFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        Nx.Warehouse.SpellcastFrame = castFrame
    end
    RegisterWarehouseEvent("CURRENCY_DISPLAY_UPDATE")
    GuildBank.RegisterCallback(CarboniteWarehouse,"GuildBankComm_PageUpdate", "OnPageSync")
    GuildBank.RegisterCallback(CarboniteWarehouse, "GuildBankComm_FundsUpdate", "OnMoneySync")
    GuildBank.RegisterCallback(CarboniteWarehouse, "GuildBankComm_TabsUpdate", "OnTabSync")

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

    elseif TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
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
            local name, link = Nx.Warehouse.API.GetItemInfo(itemID)
            if not link or not count then
                return
            end
            Nx.Warehouse.onAuctionHouseUpdate(link, count)
        end)
    end

    Nx:AddToConfig("Warehouse Module",Nx.Warehouse:GetOptionsConfig(),L["Warehouse Module"])
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
    Nx.wdb.global = type(Nx.wdb.global) == "table" and Nx.wdb.global or {}
    Nx.wdb.global.Characters = type(Nx.wdb.global.Characters) == "table" and Nx.wdb.global.Characters or {}

    local sourceCharacters = Nx.db and Nx.db.global and Nx.db.global.Characters
    if type(sourceCharacters) ~= "table" then
        return
    end

    local moveFields = {
        "WareBank", "WareMail", "Time", "LMoney", "Profs", "LXP", "LHonor",
        "DurLowPercent", "XPMax", "Conquest", "LArenaPts", "TimePlayed", "XP",
        "XPRest", "Honor", "Money", "WareBags", "LXPMax", "LTime", "LXPRest",
        "DurPercent", "WareInv", "LvlTime", "Pos", "WHHide", "Garrison", "Apexis",
        "Nethershard", "WareRBank", "OrderHall",
    }

    for charName, source in pairs(sourceCharacters) do
        if type(source) == "table" then
            local target = Nx.wdb.global.Characters[charName]
            if type(target) ~= "table" then
                target = {}
                Nx.wdb.global.Characters[charName] = target
            end

            for _, field in ipairs(moveFields) do
                if source[field] ~= nil then
                    target[field] = source[field]
                    source[field] = nil
                end
            end

            -- Core still owns these identity fields, so copy rather than move.
            if source.Class ~= nil then
                target.Class = source.Class
            end
            if source.Level ~= nil then
                target.Level = source.Level
            end
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
    if event == "BAG_UPDATE_DELAYED" then
        Nx.Warehouse:OnBag_update()
    elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERBANKBAGSLOTS_CHANGED"
        or event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" or event == "BANK_TABS_CHANGED" then
        Nx.Warehouse:OnBag_update()
    elseif event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
        Nx.Warehouse:ScanRBank()
    elseif event == "BANKFRAME_OPENED" then
        Nx.Warehouse:OnBankframe_opened()
    elseif event == "BANKFRAME_CLOSED" then
        Nx.Warehouse:OnBankframe_closed()
    elseif event == "GUILDBANKFRAME_OPENED" then
        Nx.Warehouse:OnGuildbankframe_opened()
    elseif event == "GUILDBANKFRAME_CLOSED" then
        Nx.Warehouse:OnGuildbankframe_closed()
    elseif event == "GUILDBANKBAGSLOTS_CHANGED" then
        if Nx.Warehouse.GuildBankOpen then
            Nx.Warehouse:GuildRecord(true)
        end
    elseif event == "GUILDBANK_UPDATE_TABS" then
        Nx.Warehouse:GuildRecord(Nx.Warehouse.GuildBankOpen)
    elseif event == "GUILDBANK_UPDATE_MONEY" then
        Nx.Warehouse:GuildRecord(false)
    elseif event == "ITEM_LOCK_CHANGED" then
        Nx.Warehouse:OnItem_lock_changed(arg1, arg2)
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        Nx.Warehouse:OnItemDataReceived(arg1, arg2)
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
    elseif event == "CHAT_MSG_SKILL" or event == "SKILL_LINES_CHANGED" then
        Nx.Warehouse:OnChat_msg_skill()
    elseif event == "TRADE_SKILL_CLOSE" or event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" then
        Nx.Warehouse:OnTrade_skill_update(event)
    elseif event == "PLAYER_LOGIN" then
        Nx.Warehouse:Login(event, arg1)
    elseif event == "TIME_PLAYED_MSG" then
        Nx.Warehouse:OnTime_played_msg(event, arg1, arg2)
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
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
    local version = type(ware) == "table" and tonumber(ware.Version) or nil

    -- Preserve legacy guild-bank caches. WarehouseData is migrated in place;
    -- a missing or older version is not sufficient reason to discard scans.
    if type(ware) ~= "table" then
        ware = {}
        Nx.wdb.profile.WarehouseData = ware
    end
    if not version or version < Nx.VERSIONWare then
        ware.Version = Nx.VERSIONWare
    end

    ware.StorageSchemaVersion = Nx.Warehouse.StorageSchemaVersion or 1

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
    Nx.Warehouse:RecordCharacterSkills()
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
