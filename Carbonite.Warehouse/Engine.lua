-- Carbonite.Warehouse | Engine
-- The bulky end of NxWarehouse.lua: window UI (Create / CreateMenu
-- / button + menu handlers / list event routing), the Update /
-- UpdateGuild / UpdateItems / UpdateProfessions render path,
-- tooltip processing, guild-bank delete + record, inventory capture
-- (Capture* / AddBag / AddLink / DiffBags / CaptureInvDurability*),
-- and the character/profession recording functions.
--
-- All methods stay attached to Nx.Warehouse so the legacy callsites
-- in Carbonite.* see no change. Pure code relocation; the small
-- file-locals the original code needed (GuildBank, CurrencyArray,
-- defaults) live in NxWarehouse.lua / Init.lua and are reached
-- through the namespace.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Warehouse', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Warehouse = Nx.Warehouse or {}

local GuildBank      = LibStub('LibGuildBankComm-1.0')

-- Shared bag-id catalogs + currency list live on Nx.Warehouse so
-- this file can see them after the extraction. NxWarehouse.lua sets
-- them up before this file loads. BandBankActive is mutable so we
-- read it through Nx.Warehouse rather than aliasing.
local CharBags      = Nx.Warehouse.CharBags
local BankBags      = Nx.Warehouse.BankBags
local BandBags      = Nx.Warehouse.BandBags
local CurrencyArray = Nx.Warehouse.CurrencyArray
local WarehouseAPI  = Nx.Warehouse.API
local ProfessionSchemaVersion = Nx.Warehouse.ProfessionSchemaVersion or 3
local StorageSchemaVersion = Nx.Warehouse.StorageSchemaVersion or 1
local RequiresBagSchemaMigration = Nx.isRetail
    and WarehouseAPI and WarehouseAPI.HasAccountBank and WarehouseAPI.HasAccountBank()

local function IsCharacterBagDataCurrent(ch)
    if not RequiresBagSchemaMigration then
        return true
    end
    return type(ch) == "table"
        and (tonumber(ch.WarehouseStorageSchemaVersion) or 0) >= StorageSchemaVersion
end

local function GetStoredItemStats(inv)
    local entries = 0
    local total = 0

    if type(inv) ~= "table" then
        return entries, total
    end

    for _, data in pairs(inv) do
        if type(data) == "string" then
            local count = Nx.Split("^", data)
            entries = entries + 1
            total = total + (tonumber(count) or 0)
        end
    end

    return entries, total
end

local function FormatScanStatus(scanTime, hasData)
    scanTime = tonumber(scanTime)
    if scanTime and scanTime > 0 then
        local elapsed = max(0, time() - scanTime)
        if elapsed < 60 then
            return "|cff80ff80current|r"
        end
        return format("|cffcfcfcf%s ago|r", Nx.Util_GetTimeElapsedStr(elapsed))
    end

    if hasData then
        return "|cffffff80legacy cache|r"
    end
    return "|cff888888not scanned|r"
end

local function AddSectionHeader(list, column, label, count)
    list:ItemAdd(0)
    if count ~= nil then
        list:ItemSet(column, format("|cff80bfff%s|r |cff777777(%d)|r", label, tonumber(count) or 0))
    else
        list:ItemSet(column, format("|cff80bfff%s|r", label))
    end
end

local function GetLatestProfessionScan(ch)
    local latest
    local profs = ch and ch["Profs"]
    if type(profs) ~= "table" then
        return nil
    end

    for _, prof in pairs(profs) do
        if type(prof) == "table" and type(prof._SkillLineInfo) == "table" then
            for _, scope in pairs(prof._SkillLineInfo) do
                local scanTime = type(scope) == "table" and tonumber(scope.ScanTime) or nil
                if scanTime and (not latest or scanTime > latest) then
                    latest = scanTime
                end
            end
        end
    end
    return latest
end

local function GetCurrencyDisplayRows(ch)
    local rows = {}
    local currency = ch and ch["Currency"]
    if type(currency) ~= "table" then
        return rows
    end

    local meta = type(ch["CurrencyMeta"]) == "table" and ch["CurrencyMeta"] or {}
    for currencyID, quantity in pairs(currency) do
        quantity = tonumber(quantity) or 0
        if quantity > 0 then
            local info = meta[currencyID] or meta[tonumber(currencyID)]
            local name = info and info.Name
            if not name and WarehouseAPI and WarehouseAPI.GetCurrencyInfo then
                local currentInfo = WarehouseAPI.GetCurrencyInfo(tonumber(currencyID))
                name = currentInfo and currentInfo.name
            end
            rows[#rows + 1] = {
                id = tonumber(currencyID),
                name = name or format("Currency %s", tostring(currencyID)),
                quantity = quantity,
                accountWide = info and info.AccountWide and true or false,
            }
        end
    end

    sort(rows, function(a, b)
        return strlower(a.name) < strlower(b.name)
    end)
    return rows
end

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

    local paneSplit = .38
    self.PaneSplit = paneSplit
    win:Attach (list.Frm, 0, paneSplit, 0, 1)

    -- Item List

    Nx.List:SetCreateFont ("Warehouse.WarehouseFont", 16)

    local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm)
    self.ItemList = list

    list:SetUser (self, self.OnItemListEvent)

--    list:SetLineHeight (3)

    list:ColumnAdd ("", 1, 17)
    list:ColumnAdd ("", 2, 35, "RIGHT", "Font.Small")
    list:ColumnAdd ("", 3, 900)

    win:Attach (list.Frm, paneSplit, 1, 18, 1)

    -- Filter Edit Box

    self.EditBox = Nx.EditBox:Create (win.Frm, self, self.OnEditBox, 60)
    self.EditBox.FilterDesc = "Search items..."
    self.EditBox.FilterDescEsc = "Search items%.%.%."
    self.EditBox.Frm:SetText(self.EditBox.FilterDesc)

    win:Attach (self.EditBox.Frm, paneSplit, 1, 0, 18)

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
            local profT = ch and ch["Profs"] and ch["Profs"][prof]

            if profT and profT["Link"] and not WarehouseAPI.InsertChatLink(profT["Link"], true) then
                Nx.prt ("Unable to open profession link")
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
                    name, link = WarehouseAPI.GetItemInfo(id)
                elseif id < 0 then
                    name = WarehouseAPI.GetSpellName(-id)
                    link = WarehouseAPI.GetSpellLink(-id)
                else
                    name = WarehouseAPI.GetItemInfo(link)
                end

                if link and WarehouseAPI.InsertChatLink(link, false) then
                    -- Link inserted into the active chat edit box.
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
-- Warehouse presentation helpers
-------------------------------------------------------------------------------

function Nx.Warehouse:AddSelectionSummary(list)
    local selected = self.SelectedChar
    if not selected then
        return
    end

    local hasAccountBank = WarehouseAPI and WarehouseAPI.HasAccountBank and WarehouseAPI.HasAccountBank()
    local account = hasAccountBank and self:GetAccountStorageRecord() or nil
    local _, accountTotal = GetStoredItemStats(account and account.Inv)
    local accountStatus = FormatScanStatus(account and account.ScanTime, account and next(account.Inv or {}) ~= nil)

    list:ItemAdd(selected)
    list:ItemSet(2, "|cff80bfffStorage Summary|r")

    if selected == 99 then
        local bagTotal, bankTotal, mailTotal = 0, 0, 0
        for _, rc in ipairs(Nx.RealmChars) do
            local ch = Nx.wdb.global.Characters[rc]
            if ch then
                local _, bags = GetStoredItemStats(IsCharacterBagDataCurrent(ch) and ch["WareBags"] or nil)
                local _, bank = GetStoredItemStats(ch["WareBank"])
                local _, rbank = GetStoredItemStats(ch["WareRBank"])
                local _, mail = GetStoredItemStats(ch["WareMail"])
                bagTotal = bagTotal + bags
                bankTotal = bankTotal + bank + rbank
                mailTotal = mailTotal + mail
            end
        end

        list:ItemAdd(selected)
        list:ItemSet(2, format("  Characters: %d", #Nx.RealmChars))
        list:ItemAdd(selected)
        list:ItemSet(2, format("  Bags: %d  Bank: %d  Mail: %d", bagTotal, bankTotal, mailTotal))
        if hasAccountBank then
            list:ItemAdd(selected)
            list:ItemSet(2, format("  %s: %d", _G.ACCOUNT_BANK_PANEL_TITLE or "Warband Bank", accountTotal))
            list:ItemAdd(selected)
            list:ItemSet(2, format("  Shared scan: %s", accountStatus))
        end
        return
    end

    local rc = Nx.RealmChars[selected]
    local ch = rc and Nx.wdb.global.Characters[rc]
    if not ch then
        return
    end

    local equipCount = type(ch["WareInv"]) == "table" and #ch["WareInv"] or 0
    local _, bagTotal = GetStoredItemStats(IsCharacterBagDataCurrent(ch) and ch["WareBags"] or nil)
    local _, bankTotal = GetStoredItemStats(ch["WareBank"])
    local _, reagentTotal = GetStoredItemStats(ch["WareRBank"])
    local _, mailTotal = GetStoredItemStats(ch["WareMail"])

    list:ItemAdd(selected)
    list:ItemSet(2, format("  Equipped: %d  Bags: %d", equipCount, bagTotal))
    list:ItemAdd(selected)
    list:ItemSet(2, format("  Bank: %d  Mail: %d", bankTotal + reagentTotal, mailTotal))
    if hasAccountBank then
        list:ItemAdd(selected)
        list:ItemSet(2, format("  %s: %d", _G.ACCOUNT_BANK_PANEL_TITLE or "Warband Bank", accountTotal))
    end

    list:ItemAdd(selected)
    list:ItemSet(2, format("  Bags scan: %s", FormatScanStatus(ch.WareBagsScanTime, ch["WareBags"] ~= nil)))
    list:ItemAdd(selected)
    list:ItemSet(2, format("  Bank scan: %s", FormatScanStatus(ch.WareBankScanTime or ch.WareRBankScanTime, ch["WareBank"] ~= nil or ch["WareRBank"] ~= nil)))
    list:ItemAdd(selected)
    list:ItemSet(2, format("  Mail scan: %s", FormatScanStatus(ch.WareMailScanTime, ch["WareMail"] ~= nil)))
    list:ItemAdd(selected)
    list:ItemSet(2, format("  Professions: %s", FormatScanStatus(GetLatestProfessionScan(ch), ch["Profs"] and next(ch["Profs"]) ~= nil)))

    if type(ch["Profs"]) == "table" then
        local professionNames = {}
        for name, prof in pairs(ch["Profs"]) do
            if type(prof) == "table" then
                professionNames[#professionNames + 1] = name
            end
        end
        sort(professionNames)
        for _, name in ipairs(professionNames) do
            local prof = ch["Profs"][name]
            local rank = tonumber(prof.Rank) or 0
            local maxRank = tonumber(prof.MaxRank) or 0
            local rankText = maxRank > 0 and format("%d/%d", rank, maxRank) or tostring(rank)
            list:ItemAdd(selected)
            list:ItemSet(2, format("    %s  |cffcfcfcf%s|r", name, rankText))
        end
    end
end

function Nx.Warehouse:AddStorageOverview(list, ch, allCharacters)
    local hasAccountBank = WarehouseAPI and WarehouseAPI.HasAccountBank and WarehouseAPI.HasAccountBank()
    local account = hasAccountBank and self:GetAccountStorageRecord() or nil
    local _, accountTotal = GetStoredItemStats(account and account.Inv)

    AddSectionHeader(list, 3, allCharacters and "Character Storage - All Characters" or "Character Storage")

    if allCharacters then
        local bagTotal, bankTotal, mailTotal = 0, 0, 0
        for _, rc in ipairs(Nx.RealmChars) do
            local saved = Nx.wdb.global.Characters[rc]
            if saved then
                local _, bags = GetStoredItemStats(IsCharacterBagDataCurrent(saved) and saved["WareBags"] or nil)
                local _, bank = GetStoredItemStats(saved["WareBank"])
                local _, rbank = GetStoredItemStats(saved["WareRBank"])
                local _, mail = GetStoredItemStats(saved["WareMail"])
                bagTotal = bagTotal + bags
                bankTotal = bankTotal + bank + rbank
                mailTotal = mailTotal + mail
            end
        end
        list:ItemAdd(0)
        list:ItemSet(3, format("  Bags: %d   Bank: %d   Mail: %d", bagTotal, bankTotal, mailTotal))
    elseif ch then
        local _, bags = GetStoredItemStats(IsCharacterBagDataCurrent(ch) and ch["WareBags"] or nil)
        local _, bank = GetStoredItemStats(ch["WareBank"])
        local _, rbank = GetStoredItemStats(ch["WareRBank"])
        local _, mail = GetStoredItemStats(ch["WareMail"])
        list:ItemAdd(0)
        list:ItemSet(3, format("  Bags: %d   Bank: %d   Mail: %d", bags, bank + rbank, mail))
        list:ItemAdd(0)
        list:ItemSet(3, format("  Updated: Bags %s  Bank %s  Mail %s",
            FormatScanStatus(ch.WareBagsScanTime, ch["WareBags"] ~= nil),
            FormatScanStatus(ch.WareBankScanTime or ch.WareRBankScanTime, ch["WareBank"] ~= nil or ch["WareRBank"] ~= nil),
            FormatScanStatus(ch.WareMailScanTime, ch["WareMail"] ~= nil)))
    end

    if hasAccountBank then
        AddSectionHeader(list, 3, _G.ACCOUNT_BANK_PANEL_TITLE or "Warband Bank", accountTotal)
        list:ItemAdd(0)
        list:ItemSet(3, format("  Shared account storage - %s",
            FormatScanStatus(account and account.ScanTime, account and next(account.Inv or {}) ~= nil)))
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
    list:ItemSetButton ("Warehouse", false, "Interface\\Addons\\Carbonite\\Gfx\\Icons\\INV_Misc_GroupNeedMore")
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
                local currencyRows = GetCurrencyDisplayRows(ch)
                if #currencyRows > 0 then
                    list:ItemAdd(cnum)
                    list:ItemSet(2, format("|cff80bfffCurrencies|r |cff777777(%d)|r", #currencyRows))
                    local visibleRows = min(#currencyRows, 12)
                    for currencyIndex = 1, visibleRows do
                        local row = currencyRows[currencyIndex]
                        local accountTag = row.accountWide and " |cff80c0ff[Account]|r" or ""
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format("  %s: %s%d|r%s", row.name, hicol, row.quantity, accountTag))
                    end
                    if #currencyRows > visibleRows then
                        list:ItemAdd(cnum)
                        list:ItemSet(2, format("  |cff888888+ %d more currencies|r", #currencyRows - visibleRows))
                    end
                elseif ch["Honor"] or ch["Conquest"] then
                    list:ItemAdd(cnum)
                    list:ItemSet(2, format(" Honor: %s%s|r  Conquest: %s%s", hicol, ch["Honor"] or 0, hicol, ch["Conquest"] or 0))
                else
                    list:ItemAdd(cnum)
                    list:ItemSet(2, format(" " .. L["No Currency Data Saved"]))
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

                        local rank = tonumber(p["Rank"]) or 0
                        local maxRank = tonumber(p["MaxRank"]) or 0
                        local rankText = maxRank > 0 and format("%d/%d", rank, maxRank) or tostring(rank)
                        local scopeCount = 0
                        if type(p._SkillLines) == "table" then
                            for _, recipeIDs in pairs(p._SkillLines) do
                                if type(recipeIDs) == "table" and #recipeIDs > 0 then
                                    scopeCount = scopeCount + 1
                                end
                            end
                        end
                        local scopeText = scopeCount > 1 and format(" |cff777777[%d skill lines]|r", scopeCount) or ""
                        list:ItemSet (2, format (" %s %s%s%s", name, hicol, rankText, scopeText))

                        if p["Link"] then
                            list:ItemSetButton ("WarehouseProf", false, nil, "#" .. p["Link"])
                        end
                    end
                end
            end
        end
    end
    self:AddSelectionSummary(list)

    local money = Nx.Util_GetMoneyStr (totalMoney)
    if Nx.wdb.profile.Warehouse.ShowGold then
        list:ItemSet (2, format ("|cffafdfaf%s|r  |cffd7af5f%s", L["All Characters"], money), allIndex)
    else
        list:ItemSet (2, format ("|cffafdfaf%s", L["All Characters"]), allIndex)
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
    local selectedguild
    for name, guilds in pairs (ware) do
        if name == rn then
            for gName, guild in pairs (guilds) do
                    if gName == self.SelectedGuild then
                        selectedguild = guild
                    end
            end
        end
        if not selectedguild then
            local connectedrealms = type(_G.GetAutoCompleteRealms) == "function" and _G.GetAutoCompleteRealms() or nil
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
    selectedguild = type(selectedguild) == "table" and selectedguild or {}
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
                        local name = WarehouseAPI.GetItemInfo(link)
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

        self:AddStorageOverview(list, ch, false)

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
            local equippedLabel = strtrim(gsub(L["---- Equipped ----"], "%-", ""))
            AddSectionHeader(list, 3, equippedLabel, #inv)
            for _, data in ipairs (inv) do
                local slot, link = Nx.Split ("^", data)
                Nx.Item:Load (link)
                slot = gsub (slot, L["Slot"], "")
                slot = gsub (slot, "%d", "")
                local name = WarehouseAPI.GetItemInfo(link)
                self:UpdateItem (format ("  %s - ", slot), name, 1, 0, 0, link, true)
            end
        end
    else

        self:AddStorageOverview(list, nil, true)

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

                    local name, _, iRarity = WarehouseAPI.GetItemInfo(link)
                    if iRarity and iRarity >= self.NXEqRarityMin then

                        if not hdr then
                            hdr = true
                            local rname, cname = Nx.Split (".", rc)
                            local equippedLabel = strtrim(gsub(L["---- Equipped ----"], "%-", ""))
                            AddSectionHeader(list, 3, format("%s - %s", cname, equippedLabel))
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

        local bags = IsCharacterBagDataCurrent(ch) and ch["WareBags"] or nil

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

    local account = self:GetAccountStorageRecord()
    if account and account.ScanTime and account.Inv then
        for name, data in pairs(account.Inv) do
            self:AddItem(items, 5, name, data)
        end
    end

    local sortRare = true

    local isorted = {}

    for name, data in pairs (items) do

        local bagCnt, bankCnt, mailCnt, accountCnt, link = Nx.Split ("^", data)
        Nx.Item:Load (link)

        if self.SortByRarity or self.SortBySlot then

            local _, iLink, iRarity, lvl, minLvl, itype, _, _, equipLoc = WarehouseAPI.GetItemInfo(link)

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

            local _, name, bagCnt, bankCnt, mailCnt, accountCnt, link = Nx.Split ("^", v)
            local _, iLink, iRarity = WarehouseAPI.GetItemInfo(link)

            iRarity = tonumber(iRarity) or 0    -- Happens if item not in cache

            if iRarity >= self.NXRarityMin then
                self:UpdateItem ("", name, bagCnt, bankCnt, mailCnt, link, nil, accountCnt)
            end
--[[
            local name, iLink, iRarity, lvl, minLvl, itype = GetItemInfo (link)
            Nx.prt ("item %s", itype)
--]]
        end
    else

        for _, typ in ipairs (self.ItemTypes) do

            for n = 1, #isorted do

                local _, name, bagCnt, bankCnt, mailCnt, accountCnt, link = Nx.Split ("^", isorted[n])
                local _, iLink, iRarity, lvl, minLvl, itype = WarehouseAPI.GetItemInfo(link)
                iRarity = tonumber(iRarity) or 0

                if itype == typ then    -- Found one of type?

                    AddSectionHeader(list, 3, typ)

                    for n2 = n, #isorted do

                        local _, name, bagCnt, bankCnt, mailCnt, accountCnt, link = Nx.Split ("^", isorted[n2])
                        local _, iLink, iRarity, lvl, minLvl, itype = WarehouseAPI.GetItemInfo(link)
                        iRarity = tonumber(iRarity) or 0

                        if itype == typ then

                            if iRarity >= self.NXRarityMin then
                                self:UpdateItem ("  ", name, bagCnt, bankCnt, mailCnt, link, nil, accountCnt)
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

function Nx.Warehouse:AddItem(items, typ, name, data)
    local totalBag = 0
    local totalBank = 0
    local totalMail = 0
    local totalAccount = 0

    if items[name] then
        totalBag, totalBank, totalMail, totalAccount = Nx.Split("^", items[name])
        totalBag = tonumber(totalBag) or 0
        totalBank = tonumber(totalBank) or 0
        totalMail = tonumber(totalMail) or 0
        totalAccount = tonumber(totalAccount) or 0
    end

    local count, iLink = Nx.Split("^", data)
    count = tonumber(count) or 0

    if typ == 2 then
        totalBag = totalBag + count
    elseif typ == 3 then
        totalBank = totalBank + count
    elseif typ == 4 then
        totalMail = totalMail + count
    elseif typ == 5 then
        totalAccount = totalAccount + count
    end

    items[name] = format("%d^%d^%d^%d^%s", totalBag, totalBank, totalMail, totalAccount, iLink)
end

function Nx.Warehouse:UpdateItem (pre, name, bagCnt, bankCnt, mailCnt, link, showILvl, accountCnt)

    local list = self.ItemList

    name = name or link

    bagCnt = tonumber (bagCnt) or 0
    bankCnt = tonumber (bankCnt) or 0
    mailCnt = tonumber (mailCnt) or 0
    accountCnt = tonumber (accountCnt) or 0

    local total = bagCnt + bankCnt + mailCnt + accountCnt

    local str
    str = format ("%s  ", name)

    local iname, iLink, iRarity, lvl, minLvl, itype, subType, stackCount, equipLoc, tx = WarehouseAPI.GetItemInfo(link)

    if not iname then
        iLink = link
        iRarity = 0
        minLvl = 0
    end

    iRarity = min(tonumber(iRarity) or 0, 6)
    minLvl = tonumber(minLvl) or 0
    local qualityColor = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[iRarity]
    local col = iRarity == 1 and "|cffe7e7e7" or (qualityColor and qualityColor.hex) or "|cffe7e7e7"

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
    if accountCnt > 0 then
        local accountLabel = _G.ACCOUNT_BANK_PANEL_TITLE or "Warband Bank"
        istr = format("%s |cffcfffaf(%s %s)", istr, accountCnt, accountLabel)
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
            list:ItemSet (2, format ("|cffcfcfff%s  ", bagCnt + bankCnt + mailCnt + accountCnt))
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

    local petJournal = _G.C_PetJournal
    local itemID = tonumber(link)
    if itemID and petJournal and type(petJournal.GetPetInfoByItemID) == "function"
        and type(petJournal.GetOwnedPetIDs) == "function"
        and type(petJournal.GetPetInfoByPetID) == "function" then
        local isPet, _, _, petID = petJournal.GetPetInfoByItemID(itemID)
        if isPet and petID then
            local ownedPets = petJournal.GetOwnedPetIDs() or {}
            for _, ownedPetGUID in ipairs(ownedPets) do
                local ownedPetID = select(11, petJournal.GetPetInfoByPetID(ownedPetGUID))
                if ownedPetID == petID then
                    petCnt = petCnt + 1
                end
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

        local bags = IsCharacterBagDataCurrent(ch) and ch["WareBags"] or nil

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

    local accountCnt = 0
    local account = self:GetAccountStorageRecord()
    if account and account.ScanTime and account.Inv then
        for _, data in pairs(account.Inv) do
            local iCount, iLink = Nx.Split("^", data)
            local itemID = iLink and strmatch(iLink, "item:(%d+)")
            if itemID == link then
                accountCnt = accountCnt + (tonumber(iCount) or 0)
                break
            end
        end
    end

    if accountCnt > 0 then
        local s
        local accountLabel = _G.ACCOUNT_BANK_PANEL_TITLE or "Warband Bank"
        if specific == "tooltip" then
            s = format("|cFFFFFF00%s#|cFFFF0000[|cFF00FF00%s:%d|cFFFF0000]", accountLabel, accountLabel, accountCnt)
        else
            s = format("%s %d", accountLabel, accountCnt)
        end

        if not str then
            str = s
        elseif specific ~= "tooltip" then
            str = format("%s\n%s", str, s)
        else
            str = format("%s#%s", str, s)
        end

        totalCnt = totalCnt + accountCnt
        charCnt = charCnt + 1
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

local function FormatProfessionScopeLabel(info, fallbackName)
    info = type(info) == "table" and info or {}

    local name = info.Name or fallbackName or "Profession"
    local expansion = info.Expansion
    local label = name

    if expansion and expansion ~= "" then
        local lname = strlower(name or "")
        local lexpansion = strlower(expansion)
        if not strfind(lname, lexpansion, 1, true) then
            label = format("%s - %s", expansion, name)
        end
    end

    local rank = tonumber(info.Rank)
    local maxRank = tonumber(info.MaxRank)
    if rank and maxRank and maxRank > 0 then
        label = format("%s  %d/%d", label, rank, maxRank)
    elseif rank and rank > 0 then
        label = format("%s  %d", label, rank)
    end

    return label
end

local function GetProfessionScopeEntries(profT, professionName)
    local scopes = {}
    local skillLines = type(profT._SkillLines) == "table" and profT._SkillLines or {}
    local skillLineInfo = type(profT._SkillLineInfo) == "table" and profT._SkillLineInfo or {}

    for scopeKey, recipeIDs in pairs(skillLines) do
        if type(recipeIDs) == "table" and #recipeIDs > 0 then
            local info = skillLineInfo[scopeKey]
            scopes[#scopes + 1] = {
                key = scopeKey,
                ids = recipeIDs,
                info = type(info) == "table" and info or {},
            }
        end
    end

    sort(scopes, function(a, b)
        local aID = tonumber(a.info.ID) or -1
        local bID = tonumber(b.info.ID) or -1
        if aID ~= bID then
            return aID > bID
        end
        return FormatProfessionScopeLabel(a.info, professionName) < FormatProfessionScopeLabel(b.info, professionName)
    end)

    return scopes
end

local function GetProfessionRecipeRow(profT, recipeID, scopeLabel, filterStr)
    local meta = type(profT._RecipeInfo) == "table" and profT._RecipeInfo[recipeID] or nil
    meta = type(meta) == "table" and meta or {}

    local recipeName = meta.Name or WarehouseAPI.GetSpellName(recipeID) or "?"
    local recipeLink = meta.Link or WarehouseAPI.GetSpellLink(recipeID)
    local itemID = tonumber(profT[recipeID]) or 0
    local qualityIDs = type(profT._RecipeQualities) == "table" and profT._RecipeQualities[recipeID] or nil

    local displayItemID = itemID
    if displayItemID <= 0 and type(qualityIDs) == "table" then
        displayItemID = tonumber(qualityIDs[1]) or 0
    end

    local itemName, itemLink, itemRarity, _, itemMinLevel, itemType, itemSubType, _, _, itemTexture
    if displayItemID > 0 then
        Nx.Item:Load(displayItemID)
        itemName, itemLink, itemRarity, _, itemMinLevel, itemType, itemSubType, _, _, itemTexture = WarehouseAPI.GetItemInfo(displayItemID)
    end

    local displayName = recipeName
    if itemName and itemName ~= "" and strlower(itemName) ~= strlower(recipeName) then
        displayName = format("%s |cff777777- %s|r", recipeName, itemName)
    end

    local searchParts = { recipeName }
    if itemName then
        searchParts[#searchParts + 1] = itemName
    end
    if scopeLabel then
        searchParts[#searchParts + 1] = scopeLabel
    end
    if itemType then
        searchParts[#searchParts + 1] = itemType
    end
    if itemSubType then
        searchParts[#searchParts + 1] = itemSubType
    end

    local qualityOutputs = {}
    if type(qualityIDs) == "table" and #qualityIDs > 1 then
        for _, qualityItemID in ipairs(qualityIDs) do
            qualityItemID = tonumber(qualityItemID)
            if qualityItemID and qualityItemID > 0 then
                Nx.Item:Load(qualityItemID)
                local qName, qLink = WarehouseAPI.GetItemInfo(qualityItemID)
                if qName then
                    searchParts[#searchParts + 1] = qName
                end
                qualityOutputs[#qualityOutputs + 1] = {
                    id = qualityItemID,
                    name = qName,
                    link = qLink,
                }
            end
        end
        displayName = format("%s |cff777777[Qx%d]|r", displayName, #qualityOutputs)
    end

    if filterStr ~= "" then
        local searchable = strlower(table.concat(searchParts, " "))
        if not strfind(searchable, filterStr, 1, true) then
            return nil
        end
    end

    local color = ""
    itemRarity = tonumber(itemRarity)
    if itemRarity then
        itemRarity = min(itemRarity, 6)
        local qualityColor = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemRarity]
        if itemRarity == 1 then
            color = "|cffe7e7e7"
        elseif qualityColor then
            color = qualityColor.hex or ""
        end
    end

    local tooltip
    if #qualityOutputs > 1 then
        local lines = {
            recipeName,
            scopeLabel,
            format("Quality outputs: %d", #qualityOutputs),
        }
        for index, output in ipairs(qualityOutputs) do
            local outputText = output.link or output.name or format("Item %d", output.id)
            lines[#lines + 1] = format("  Q%d  %s", index, outputText)
        end
        lines[#lines + 1] = "|cff888888Alt: item tooltip|r"
        if itemLink then
            tooltip = "!" .. itemLink .. "^" .. table.concat(lines, "\n")
        else
            tooltip = table.concat(lines, "\n")
        end
    elseif itemLink then
        tooltip = "!" .. itemLink
    elseif recipeLink then
        tooltip = "#" .. recipeLink
    end

    return {
        recipeID = recipeID,
        itemID = displayItemID,
        name = color .. displayName,
        sortName = strlower(recipeName),
        category = itemType or "",
        minLevel = tonumber(itemMinLevel) or 0,
        texture = itemTexture or meta.Icon,
        tooltip = tooltip,
    }
end

local function RenderProfessionScope(list, profT, recipeIDs, scopeLabel, filterStr, rendered, showCategories)
    local rows = {}

    for _, id in ipairs(recipeIDs) do
        local recipeID = tonumber(id)
        if recipeID and not rendered[recipeID] and type(profT[recipeID]) == "number" then
            local row = GetProfessionRecipeRow(profT, recipeID, scopeLabel, filterStr)
            if row then
                rows[#rows + 1] = row
            end
        end
    end

    sort(rows, function(a, b)
        if showCategories and a.category ~= b.category then
            return a.category < b.category
        end
        if a.sortName ~= b.sortName then
            return a.sortName < b.sortName
        end
        return a.recipeID < b.recipeID
    end)

    if #rows == 0 then
        return 0
    end

    list:ItemAdd(0)
    list:ItemSet(3, format("---- %s ----", scopeLabel))

    local currentCategory
    for _, row in ipairs(rows) do
        rendered[row.recipeID] = true

        if showCategories and row.category ~= "" and row.category ~= currentCategory then
            currentCategory = row.category
            list:ItemAdd(0)
            list:ItemSet(3, format("  -- %s --", currentCategory))
        end

        local rowID = row.itemID > 0 and row.itemID or -row.recipeID
        list:ItemAdd(rowID)
        list:ItemSetDataEx(nil, row.recipeID, 1)
        if row.minLevel > 0 then
            list:ItemSet(2, "|cff777777" .. row.minLevel .. " ")
        end
        list:ItemSet(3, row.name)
        if row.tooltip or row.texture then
            list:ItemSetButton("WarehouseItem", false, row.texture, row.tooltip)
        end
    end

    return #rows
end

function Nx.Warehouse:UpdateProfessions()

    local list = self.ItemList

    list:Empty()

    local cn1 = self.SelectedChar
    local rc = Nx.RealmChars[cn1]
    local ch = rc and Nx.wdb.global.Characters[rc]
    if not ch then
        list:Update()
        return
    end

    local rname, cname = Nx.Split(".", rc)
    local pname = self.SelectedProf

    list:ColumnSetName(3, format(L["%s's %s Skills"], cname, pname))

    local profsT = ch["Profs"]
    local profT = profsT and profsT[pname]
    if profT then
        self:MigrateProfessionTable(profT)

        local filterStr = strlower(self.EditBox:GetText() or "")
        local rendered = {}
        local scoped = {}
        local totalRows = 0
        local scopes = GetProfessionScopeEntries(profT, pname)

        for _, scope in ipairs(scopes) do
            for _, id in ipairs(scope.ids) do
                id = tonumber(id)
                if id then
                    scoped[id] = true
                end
            end
            local scopeLabel = FormatProfessionScopeLabel(scope.info, pname)
            totalRows = totalRows + RenderProfessionScope(
                list, profT, scope.ids, scopeLabel, filterStr, rendered, self.ShowItemCategory)
        end

        local unscoped = {}
        for id in pairs(profT) do
            if type(id) == "number" and not scoped[id] then
                unscoped[#unscoped + 1] = id
            end
        end
        sort(unscoped)

        if #unscoped > 0 then
            local fallbackLabel = #scopes > 0 and format("%s - Other", pname) or pname
            totalRows = totalRows + RenderProfessionScope(
                list, profT, unscoped, fallbackLabel, filterStr, rendered, self.ShowItemCategory)
        end

        if totalRows == 0 and filterStr ~= "" then
            list:ItemAdd(0)
            list:ItemSet(3, format(" No profession recipes match '%s'", self.EditBox:GetText()))
        end
    else
        list:ItemAdd(0)
        list:ItemSet(3, format(L["|cffff1010No data - open %s window"], pname))
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
        self.GuildBankOpen = true
        self:GuildRecord(true)
    end
end

function Nx.Warehouse.OnGuildbankframe_closed()
    local self = Nx.Warehouse
    if self.Enabled then
        self:GuildRecord(false)
        self.GuildBankOpen = false
    end
end

function Nx.Warehouse:GuildRecord(scanCurrentTab)
    if not IsInGuild() then
        return
    end

    local gName = GetGuildInfo("player")
    if not gName then
        return
    end

    local ware = Nx.wdb.profile.WarehouseData
    local rn = GetRealmName()
    local rnGuilds = ware[rn] or {}
    ware[rn] = rnGuilds
    local guild = rnGuilds[gName] or {}
    rnGuilds[gName] = guild

    if GetGuildBankMoney then
        local money = GetGuildBankMoney()
        if money ~= nil then
            guild["Money"] = money
        end
    end

    local getNumTabs = _G.GetNumGuildBankTabs
    local getTabInfo = _G.GetGuildBankTabInfo
    local getCurrentTab = _G.GetCurrentGuildBankTab
    local getItemLink = _G.GetGuildBankItemLink
    local getItemInfo = _G.GetGuildBankItemInfo

    if type(getNumTabs) ~= "function" or type(getTabInfo) ~= "function" then
        return
    end

    local numTabs = tonumber(getNumTabs()) or 0
    for page = 1, numTabs do
        local name, icon, isViewable = getTabInfo(page)
        local tab = guild["Tab" .. page] or {}
        guild["Tab" .. page] = tab
        tab.Name = name
        tab.Icon = icon
        tab.Viewable = isViewable and true or false
    end

    if not scanCurrentTab or type(getCurrentTab) ~= "function"
        or type(getItemLink) ~= "function" or type(getItemInfo) ~= "function" then
        return
    end

    local page = tonumber(getCurrentTab())
    if not page or page < 1 or page > numTabs then
        return
    end

    local name, icon, isViewable = getTabInfo(page)
    if not isViewable then
        return
    end

    local inv = {}
    for slot = 1, 98 do
        local link = getItemLink(page, slot)
        if link then
            local _, count = getItemInfo(page, slot)
            inv[slot] = format("%s^%s", tonumber(count) or 1, link)
        end
    end

    local tab = guild["Tab" .. page] or {}
    guild["Tab" .. page] = tab
    tab.Name = name
    tab.Icon = icon
    tab.Viewable = true
    tab.Inv = inv
    tab.ScanTime = time()
end

function Nx.Warehouse.OnBag_update()

    local self = Nx.Warehouse

    if self.Enabled then
        local delay = self.BankOpen and 0 or .8
        self.CaptureTimer = Nx:ScheduleTimer(self.CaptureUpdate, delay, self)
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
    ch.WareMailScanTime = time()

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
    if not ch then
        return
    end

    ch["WareMail"] = type(ch["WareMail"]) == "table" and ch["WareMail"] or {}
    self:AddLink(link, count, ch["WareMail"])
    self:Update()
end

local function BagListContains(bags, bag)
    for _, value in ipairs(bags or {}) do
        if value == bag then
            return true
        end
    end
    return false
end

function Nx.Warehouse:OnCommodityPurchased(itemID, quantity)
    if type(itemID) ~= "number" or type(quantity) ~= "number" or quantity <= 0 then
        return
    end
    local _, link = C_Item.GetItemInfo(itemID)
    if not link then
        return
    end
    Nx.Warehouse.onAuctionHouseUpdate(link, quantity)
end

function Nx.Warehouse:RememberAuctionBuyout(frame, auctionID)
    if type(auctionID) ~= "number" then
        return
    end
    local buyFrame = frame and frame.ItemBuyFrame
    local itemKey = buyFrame and buyFrame.itemKey
    if not itemKey or not C_AuctionHouse.GetNumItemSearchResults then
        return
    end
    local num = C_AuctionHouse.GetNumItemSearchResults(itemKey) or 0
    for i = 1, num do
        local info = C_AuctionHouse.GetItemSearchResultInfo(itemKey, i)
        if info and info.auctionID == auctionID then
            if info.itemLink then
                self.PendingBuyouts = self.PendingBuyouts or {}
                self.PendingBuyouts[auctionID] = { link = info.itemLink, count = info.quantity or 1 }
            end
            return
        end
    end
end

function Nx.Warehouse:OnAuctionPurchaseCompleted(auctionID)
    local pending = self.PendingBuyouts and self.PendingBuyouts[auctionID]
    if not pending then
        return
    end
    self.PendingBuyouts[auctionID] = nil
    Nx.Warehouse.onAuctionHouseUpdate(pending.link, pending.count)
end

function Nx.Warehouse.OnItem_lock_changed(_, arg1, arg2)
    if type(arg1) ~= "number" or type(arg2) ~= "number" then
        return
    end

    local self = Nx.Warehouse
    if not self.Enabled then
        return
    end

    local bankBags = BankBags
    if WarehouseAPI.GetCharacterBankBags then
        bankBags = WarehouseAPI.GetCharacterBankBags()
    end

    local isCharacterBag = BagListContains(CharBags, arg1)
    local isBankBag = BagListContains(bankBags, arg1)
    local isAccountBag = BagListContains(BandBags, arg1)
    if not isCharacterBag and not isBankBag and not isAccountBag then
        return
    end

    self.LockBank = isBankBag and true or nil
    self.LockBag = arg1
    self.LockSlot = arg2

    local itemInfo = WarehouseAPI.GetContainerItemInfo(arg1, arg2)
    self.Locked = itemInfo and itemInfo.isLocked and true or false
    if itemInfo then
        self.LockCnt = itemInfo.stackCount
        self.LockLink = itemInfo.hyperlink or WarehouseAPI.GetContainerItemLink(arg1, arg2)
    end

    -- BAG_UPDATE_DELAYED is the authoritative coalesced refresh. Keep the
    -- immediate capture for compatibility with older clients and for visible
    -- Warehouse UI, but never classify Account Bank tabs as character bank.
    self:CaptureUpdate()
    self.LockBag = nil
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

function Nx.Warehouse:GetAccountStorageRecord()
    if not (Nx.wdb and Nx.wdb.global) then
        return nil
    end

    local account = Nx.wdb.global.AccountBank
    if type(account) ~= "table" then
        account = {}
        Nx.wdb.global.AccountBank = account
    end
    account.SchemaVersion = StorageSchemaVersion
    account.Inv = type(account.Inv) == "table" and account.Inv or {}
    return account
end

function Nx.Warehouse:ScanBagList(bags)
    local inv = {}
    local totalSlots = 0

    for _, bag in ipairs(bags or {}) do
        local slots = WarehouseAPI.GetContainerNumSlots(bag)
        if type(slots) == "number" and slots > 0 then
            totalSlots = totalSlots + slots
            self:AddBag(bag, false, inv)
        end
    end

    return inv, totalSlots
end

function Nx.Warehouse:CaptureItems()
    local ch = Nx.Warehouse.CurCharacter
    if not ch then
        return
    end

    local inv = {}
    ch["WareInv"] = inv

    for _, name in ipairs(self.InvNames) do
        local id = GetInventorySlotInfo(name)
        local link = GetInventoryItemLink("player", id)
        if link then
            tinsert(inv, format("%s^%s", name, link))
        end
    end

    -- Character-owned bags only. Account/Warband bank tabs must never be
    -- copied into this table or cross-character totals count them repeatedly.
    local bags = {}
    ch["WareBags"] = bags
    for _, bag in ipairs(CharBags) do
        self:AddBag(bag, false, bags)
    end
    ch.WareBagsScanTime = time()
    ch.WareInvScanTime = ch.WareBagsScanTime
    ch.WarehouseStorageSchemaVersion = StorageSchemaVersion

    if self.BankOpen then
        local bankBags = BankBags
        if WarehouseAPI.GetCharacterBankBags then
            bankBags = WarehouseAPI.GetCharacterBankBags()
        end
        local bankInv, bankSlots = self:ScanBagList(bankBags)
        if bankSlots > 0 then
            -- Replace even when empty so removing the last item clears stale
            -- saved bank data.
            ch["WareBank"] = bankInv
            ch.WareBankScanTime = time()
            if WarehouseAPI.HasModernCharacterBank and WarehouseAPI.HasModernCharacterBank() then
                -- Modern tabbed character banks supersede the old reagent-bank
                -- container. Keeping its historical cache would double-count
                -- migrated reagents.
                ch["WareRBank"] = nil
            end
        end

        if WarehouseAPI.CanScanAccountBank and WarehouseAPI.CanScanAccountBank() then
            local accountBags = WarehouseAPI.GetAccountBankBags()
            local accountInv, accountSlots = self:ScanBagList(accountBags)
            if accountSlots > 0 then
                local account = self:GetAccountStorageRecord()
                if account then
                    account.Inv = accountInv
                    account.ScanTime = time()
                    if WarehouseAPI.GetDepositedBankMoney and Enum and Enum.BankType then
                        local money, available = WarehouseAPI.GetDepositedBankMoney(Enum.BankType.Account)
                        if available then
                            account.Money = money
                        end
                    end
                end
            end
        end

        if not (WarehouseAPI.HasModernCharacterBank and WarehouseAPI.HasModernCharacterBank()) then
            self:ScanRBank()
        end
    elseif self.LockBank and self.LockBag and not self.Locked and ch["WareBank"] then
        self:AddLink(self.LockLink, self.LockCnt, ch["WareBank"])
    end
end

function Nx.Warehouse:ScanRBank()
    local ch = Nx.Warehouse.CurCharacter
    if not ch or not _G.REAGENTBANK_CONTAINER then
        return
    end

    local slots = WarehouseAPI.GetContainerNumSlots(_G.REAGENTBANK_CONTAINER)
    if not slots or slots <= 0 then
        return
    end

    local inv = {}
    self:AddBag(_G.REAGENTBANK_CONTAINER, true, inv)
    ch["WareRBank"] = inv
    ch.WareRBankScanTime = time()
end

function Nx.Warehouse:AddBag(bag, isBank, inv)
    if bag == nil or type(inv) ~= "table" then
        return
    end

    local slots = WarehouseAPI.GetContainerNumSlots(bag)
    for slot = 1, slots do
        local containerItemInfo = WarehouseAPI.GetContainerItemInfo(bag, slot)
        if containerItemInfo then
            local count = tonumber(containerItemInfo.stackCount) or 0
            if count > 0 and not containerItemInfo.isLocked then
                local link = containerItemInfo.hyperlink or WarehouseAPI.GetContainerItemLink(bag, slot)
                if link then
                    self:AddLink(link, count, inv)
                end
            end
        end
    end
end

function Nx.Warehouse:AddLink(link, count, inv)
    if type(inv) ~= "table" or not link then
        return
    end

    count = tonumber(count) or 0
    if count <= 0 then
        return
    end

    local name, iLink = WarehouseAPI.GetItemInfo(link)
    if name then
        local total = 0
        if inv[name] then
            local savedCount = Nx.Split("^", inv[name])
            total = tonumber(savedCount) or 0
        end
        inv[name] = format("%d^%s", total + count, iLink or link)
        return
    end

    -- Item information can be absent on the first cache lookup. Request it and
    -- schedule one consolidated inventory refresh when Blizzard reports that
    -- the data arrived instead of permanently omitting the item.
    local itemID = WarehouseAPI.RequestItemData(link)
    if itemID then
        self.PendingItemData = self.PendingItemData or {}
        self.PendingItemData[itemID] = true
    end
end

-------------------------------------------------------------------------------

function Nx.Warehouse:OnItemDataReceived(itemID, success)
    itemID = tonumber(itemID)
    if not itemID or not self.PendingItemData or not self.PendingItemData[itemID] then
        return
    end

    self.PendingItemData[itemID] = nil
    if success == false then
        return
    end

    self:CaptureUpdate()
    if _G.MailFrame and _G.MailFrame.IsShown and _G.MailFrame:IsShown() then
        self:OnMail_inbox_update()
    end
    if _G.GuildBankFrame and _G.GuildBankFrame.IsShown and _G.GuildBankFrame:IsShown() then
        self:GuildRecord(true)
    end
end

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
                for slot = 1, WarehouseAPI.GetContainerNumSlots(bag) do
                    local sellit = false
                    local itemfetch = WarehouseAPI.GetContainerItemInfo(bag, slot)
                    if itemfetch then
                        local tex, stack, locked, quality, link = itemfetch.iconFileID, itemfetch.stackCount, itemfetch.isLocked, itemfetch.quality, itemfetch.hyperlink
                        if not locked and tex then
                            local name, _, _, lvl, _, _, _, _, _, _, price = WarehouseAPI.GetItemInfo(link)
                            local sellPrice = tonumber(price) or 0
                            local itemLevel = tonumber(lvl) or math.huge
                            local stackCount = tonumber(stack) or 1
                            if quality == 0 and Nx.wdb.profile.Warehouse.SellGreys and sellPrice > 0 then
                                sellit = true
                            end
                            if quality == 1 and Nx.wdb.profile.Warehouse.SellWhites and sellPrice > 0 then
                                if Nx.wdb.profile.Warehouse.SellWhitesiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellWhitesiLVLValue then
                                    sellit = true
                                elseif not Nx.wdb.profile.Warehouse.SellWhitesiLVL then
                                    sellit = true
                                end
                            end
                            if quality == 2 and Nx.wdb.profile.Warehouse.SellGreens and sellPrice > 0 then
                                if Nx.wdb.profile.Warehouse.SellGreensBOE and Nx.Warehouse:GetStorageType(bag, slot, "BOE") then
                                    if Nx.wdb.profile.Warehouse.SellGreensiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellGreensiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellGreensiLVL then
                                        sellit = true
                                    end
                                end
                                if Nx.wdb.profile.Warehouse.SellGreensBOP and Nx.Warehouse:GetStorageType(bag, slot, "SOULBOUND") then
                                    if Nx.wdb.profile.Warehouse.SellGreensiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellGreensiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellGreensiLVL then
                                        sellit = true
                                    end
                                end
                            end
                            if quality == 3 and Nx.wdb.profile.Warehouse.SellBlues and sellPrice > 0 then
                                if Nx.wdb.profile.Warehouse.SellBluesBOE and Nx.Warehouse:GetStorageType(bag, slot, "BOE") then
                                    if Nx.wdb.profile.Warehouse.SellBluesiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellBluesiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellBluesiLVL then
                                        sellit = true
                                    end
                                end
                                if Nx.wdb.profile.Warehouse.SellBluesBOP and Nx.Warehouse:GetStorageType(bag, slot, "SOULBOUND") then
                                    if Nx.wdb.profile.Warehouse.SellBluesiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellBluesiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellBluesiLVL then
                                        sellit = true
                                    end
                                end
                            end
                            if quality == 4 and Nx.wdb.profile.Warehouse.SellPurps and sellPrice > 0 then
                                if Nx.wdb.profile.Warehouse.SellPurpsBOE and Nx.Warehouse:GetStorageType(bag, slot, "BOE") then
                                    if Nx.wdb.profile.Warehouse.SellPurpsiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellPurpsiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellPurpsiLVL then
                                        sellit = true
                                    end
                                end
                                if Nx.wdb.profile.Warehouse.SellPurpsBOP and Nx.Warehouse:GetStorageType(bag, slot, "SOULBOUND") then
                                    if Nx.wdb.profile.Warehouse.SellPurpsiLVL and itemLevel < Nx.wdb.profile.Warehouse.SellPurpsiLVLValue then
                                        sellit = true
                                    elseif not Nx.wdb.profile.Warehouse.SellPurpsiLVL then
                                        sellit = true
                                    end
                                end
                            end
                            if name and Nx.wdb.profile.Warehouse.SellList and Nx.wdb.profile.Warehouse.SellingList[name] then
                                sellit = true
                            end
                            if sellit then
                                if not Nx.wdb.profile.Warehouse.SellTesting then
                                    WarehouseAPI.UseContainerItem(bag, slot)
                                end
                                if Nx.wdb.profile.Warehouse.SellVerbose then
                                    local moneyStr = Nx.Util_GetMoneyStr(stackCount * sellPrice)
                                    Nx.prt(L["Selling"] .. " " .. (name or link or "item") .. " @ " .. moneyStr)
                                end
                                totalearned = totalearned + (stackCount * sellPrice)
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

    self.DurabilityTimer = Nx:ScheduleTimer(self.CaptureInvDurabilityTimer, 3, self)
end

function Nx.Warehouse:GetStorageType(bag, slot, checkwhich)
    local scan = self.StorageScanTooltip
    if not scan then
        scan = CreateFrame("GameTooltip", "NxWarehouseStorageScanTooltip", nil, "GameTooltipTemplate")
        self.StorageScanTooltip = scan
    end

    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    scan:SetBagItem(bag, slot)

    local foundone = false
    local scannername = scan:GetName()
    for i = 2, 6 do
        local text = scannername and _G[scannername .. "TextLeft" .. i]
        local value = text and text:GetText()
        if value == ITEM_SOULBOUND then
            foundone = "SOULBOUND"
        elseif value == ITEM_BIND_ON_EQUIP then
            foundone = "BOE"
        end
    end
    scan:Hide()

    return checkwhich == foundone
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

    ch["DurPercent"] = durAllMax > 0 and (durAll / durAllMax * 100) or 100
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
        local name, iLink, iRarity, lvl, minLvl, iType = WarehouseAPI.GetItemInfo(self.LootItems[arg1])
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

                local name, iLink, iRarity, lvl, minLvl, itype = WarehouseAPI.GetItemInfo(link)
                if itype == "Quest" then
                    self:prtdb ("Quest item added: %s", name)
                    self:Capture (link)
                end
            end
        else
            local name, iLink, iRarity, lvl, minLvl, itype = WarehouseAPI.GetItemInfo(link)
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

        self.SkillRecordTimer = Nx:ScheduleTimer(self.RecordCharacterSkills, .5, self)
    end
end

-------------------------------------------------------------------------------
-- Profession names, ranks, and saved recipe data
-------------------------------------------------------------------------------

function Nx.Warehouse:MigrateProfessionTable(profT)
    if type(profT) ~= "table" then
        return nil
    end

    if type(profT._SkillLines) ~= "table" then
        profT._SkillLines = {}
    end
    if type(profT._SkillLineInfo) ~= "table" then
        profT._SkillLineInfo = {}
    end
    if type(profT._RecipeQualities) ~= "table" then
        profT._RecipeQualities = {}
    end
    if type(profT._RecipeInfo) ~= "table" then
        profT._RecipeInfo = {}
    end

    for recipeID, itemID in pairs(profT) do
        if type(recipeID) == "number" then
            profT[recipeID] = tonumber(itemID) or 0
        end
    end

    profT.Old = nil
    profT._SchemaVersion = ProfessionSchemaVersion
    return profT
end

function Nx.Warehouse:MigrateProfessionData(profs)
    if type(profs) ~= "table" then
        return
    end

    for name, profT in pairs(profs) do
        if type(profT) == "table" then
            self:MigrateProfessionTable(profT)
        else
            profs[name] = nil
        end
    end
end

function Nx.Warehouse:RecordCharacterSkills()

    local ch = Nx.Warehouse.CurCharacter
    if not ch then
        return
    end

    ch["Profs"] = ch["Profs"] or {}
    self:MigrateProfessionData(ch["Profs"])
    self.SkillRiding = Nx.Travel:GetRidingSkill()

    local proI = WarehouseAPI.GetProfessionIndexes()
    local seen = {}
    local seenCount = 0

    for _, i in pairs(proI) do
        local name, icon, rank, maxrank, numspells, spelloffset, skillline = WarehouseAPI.GetProfessionInfo(i)
        if name then
            local t = ch["Profs"]
            local p = t[name]
            if type(p) ~= "table" then
                p = {}
                t[name] = p
            end
            self:MigrateProfessionTable(p)
            p["Rank"] = tonumber(rank) or 0
            p["MaxRank"] = tonumber(maxrank) or p["MaxRank"]
            p["SkillLine"] = tonumber(skillline) or p["SkillLine"]
            seen[name] = true
            seenCount = seenCount + 1
        end
    end

    -- Do not prune saved professions when the client returns no profession
    -- data; this can occur during login or UI initialization.
    if seenCount > 0 then
        for name in pairs(ch["Profs"]) do
            if not seen[name] then
                ch["Profs"][name] = nil
                Nx.prt(L["%s deleted"], name)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- TRADE SKILL TRACKING
-------------------------------------------------------------------------------

---
-- Handle trade skill update event
--
function Nx.Warehouse.OnTrade_skill_update(event)

    local self = Nx.Warehouse
    if not self.Enabled then
        return
    end

    if event == "TRADE_SKILL_CLOSE" then
        self.TradeSkillOpen = false
        return
    end

    if event == "TRADE_SKILL_SHOW" then
        self.TradeSkillOpen = true
    elseif event == "TRADE_SKILL_LIST_UPDATE" and not self.TradeSkillOpen then
        return
    end

    if not self.ProfessionRecordPending then
        self.ProfessionRecordPending = true
        self.ProfessionRecordTimer = Nx:ScheduleTimer(self.RecordProfession, .2, self)
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
local function RecipeExistsInOtherScope(skillLines, currentKey, recipeID)
    for scopeKey, recipeIDs in pairs(skillLines) do
        if scopeKey ~= currentKey and type(recipeIDs) == "table" then
            for _, id in ipairs(recipeIDs) do
                if tonumber(id) == recipeID then
                    return true
                end
            end
        end
    end
    return false
end

function Nx.Warehouse:RecordProfession()

    self.ProfessionRecordPending = false

    if not self.Enabled or WarehouseAPI.IsTradeSkillLinked() or WarehouseAPI.IsNPCCrafting() then
        return
    end
    if WarehouseAPI.HasModernTradeSkillRecipes() and not self.TradeSkillOpen then
        return
    end

    local ch = self.CurCharacter
    local scope = WarehouseAPI.GetOpenProfessionScope()
    local title = scope and scope.title
    if not ch or not ch["Profs"] or not title then
        return
    end

    local profT = ch["Profs"][title]
    if type(profT) ~= "table" then
        profT = {}
        ch["Profs"][title] = profT
    end
    self:MigrateProfessionTable(profT)

    local link = WarehouseAPI.GetTradeSkillListLink()
    if link then
        profT["Link"] = link
    end

    local recipes, complete, scanScope = WarehouseAPI.GetOpenProfessionRecipes(scope)
    scope = scanScope or scope
    local scopeKey = scope and scope.key or ("legacy:" .. title)
    local skillLines = profT._SkillLines
    local previousScope = skillLines[scopeKey]
    if type(previousScope) ~= "table" then
        previousScope = {}
    end

    local newScope = {}
    local newScopeSet = {}
    local qualityData = profT._RecipeQualities
    local recipeInfo = profT._RecipeInfo

    for _, recipe in ipairs(recipes) do
        local recipeID = tonumber(recipe.recipeID)
        if recipeID then
            local itemID = tonumber(recipe.itemID) or 0
            profT[recipeID] = itemID

            local info = recipeInfo[recipeID]
            if type(info) ~= "table" then
                info = {}
                recipeInfo[recipeID] = info
            end
            info.Name = recipe.name or info.Name
            info.Icon = tonumber(recipe.icon) or info.Icon
            info.Link = recipe.link or info.Link
            info.CategoryID = tonumber(recipe.categoryID) or info.CategoryID
            info.SupportsQualities = recipe.supportsQualities and true or nil
            info.ItemID = itemID > 0 and itemID or nil

            if not newScopeSet[recipeID] then
                newScopeSet[recipeID] = true
                newScope[#newScope + 1] = recipeID
            end

            if type(recipe.qualityItemIDs) == "table" and #recipe.qualityItemIDs > 1 then
                local ids = {}
                for _, qualityItemID in ipairs(recipe.qualityItemIDs) do
                    qualityItemID = tonumber(qualityItemID)
                    if qualityItemID and qualityItemID > 0 then
                        ids[#ids + 1] = qualityItemID
                    end
                end
                qualityData[recipeID] = #ids > 1 and ids or nil
            elseif complete then
                qualityData[recipeID] = nil
            end
        end
    end

    table.sort(newScope)

    if complete then
        for _, recipeID in ipairs(previousScope) do
            recipeID = tonumber(recipeID)
            if recipeID and not newScopeSet[recipeID]
                and not RecipeExistsInOtherScope(skillLines, scopeKey, recipeID) then
                profT[recipeID] = nil
                qualityData[recipeID] = nil
                recipeInfo[recipeID] = nil
            end
        end
        skillLines[scopeKey] = newScope
    else
        local merged = {}
        for _, recipeID in ipairs(previousScope) do
            recipeID = tonumber(recipeID)
            if recipeID and not newScopeSet[recipeID] then
                newScopeSet[recipeID] = true
                merged[#merged + 1] = recipeID
            end
        end
        for _, recipeID in ipairs(newScope) do
            merged[#merged + 1] = recipeID
        end
        table.sort(merged)
        skillLines[scopeKey] = merged
    end

    profT._SkillLineInfo[scopeKey] = {
        ID = scope and tonumber(scope.skillLineID) or nil,
        Name = scope and scope.professionName or title,
        Expansion = scope and scope.expansionName or nil,
        Rank = scope and tonumber(scope.rank) or nil,
        MaxRank = scope and tonumber(scope.maxRank) or nil,
        Complete = complete and true or false,
        ScanTime = time(),
    }
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

    for _, savedChar in pairs(chars) do
        if type(savedChar) == "table" then
            savedChar["Profs"] = savedChar["Profs"] or {}
            self:MigrateProfessionData(savedChar["Profs"])
        end
    end

    local ch = chars[fullName]
    if not ch then
        ch = {}
        chars[fullName] = ch
    end

    Nx.Warehouse.CurCharacter = ch
    ch["Profs"] = ch["Profs"] or {}
    self:MigrateProfessionData(ch["Profs"])
end

---
-- Record character data at login
-- Captures initial state of money, XP, honor, etc.
--
function Nx.Warehouse:RecordCharacterLogin()
    local ch = self.CurCharacter
    if type(ch) ~= "table" then
        return
    end

    ch["LTime"] = time()
    ch["LvlTime"] = time()
    ch["LLevel"] = tonumber(UnitLevel("player")) or 0
    ch["Class"] = Nx:GetUnitClass()
    ch["LMoney"] = GetMoney()
    ch["LXP"] = UnitXP ("player")
    ch["LXPMax"] = UnitXPMax ("player")
    ch["LXPRest"] = GetXPExhaustion() or 0
    local conquestID = WarehouseAPI.GetConquestCurrencyID and WarehouseAPI.GetConquestCurrencyID() or 390
    local honorID = WarehouseAPI.GetHonorCurrencyID and WarehouseAPI.GetHonorCurrencyID() or 1901
    local arena = WarehouseAPI.GetCurrencyInfo(conquestID)
    local honor = WarehouseAPI.GetCurrencyInfo(honorID)
    ch["Conquest"] = arena and arena.quantity or 0
    ch["Honor"] = honor and honor.quantity or 0
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
    local mapID = tonumber(map.UpdateMapID)
    local mapX = tonumber(map.PlyrRZX)
    local mapY = tonumber(map.PlyrRZY)
    if mapID and mapX and mapY then
        ch["Pos"] = format("%d^%f^%f", mapID, mapX, mapY)
    end
    ch["Time"] = time()
    ch["Level"] = tonumber(UnitLevel("player")) or tonumber(ch["Level"]) or 0
    ch["Class"] = Nx:GetUnitClass()
    local lastLevel = tonumber(ch["LLevel"]) or ch["Level"]
    if ch["Level"] > lastLevel then    -- Made a level? Reset
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
    if not ch then
        return
    end

    local currencies = {}
    local metadata = {}

    if WarehouseAPI.GetCurrencyListEntries then
        local listed = WarehouseAPI.GetCurrencyListEntries()
        for currencyID, info in pairs(listed) do
            if info.name and (info.discovered ~= false or (info.quantity or 0) > 0) then
                currencies[currencyID] = info.quantity or 0
                metadata[currencyID] = {
                    Name = info.name,
                    Icon = info.iconFileID,
                    AccountWide = info.isAccountWide and true or false,
                    Transferable = info.isAccountTransferable and true or false,
                }
            end
        end
    end

    -- Retain the historical Carbonite currency set as a compatibility
    -- supplement. This also covers Classic-family clients that do not expose
    -- the modern currency-list enumeration APIs.
    for _, currencyID in ipairs(CurrencyArray) do
        local info = WarehouseAPI.GetCurrencyInfo(currencyID)
        if info and not info.isHeader and info.name then
            currencies[currencyID] = info.quantity or 0
            metadata[currencyID] = metadata[currencyID] or {
                Name = info.name,
                Icon = info.iconFileID,
                AccountWide = info.isAccountWide and true or false,
                Transferable = info.isAccountTransferable and true or false,
            }
        end
    end

    ch["Currency"] = currencies
    ch["CurrencyMeta"] = metadata
end

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------
