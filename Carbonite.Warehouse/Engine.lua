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
local GetCurrencyInfo = (_G.C_CurrencyInfo and _G.C_CurrencyInfo.GetCurrencyInfo) or _G.GetCurrencyInfo

-- Shared bag-id catalogs + currency list live on Nx.Warehouse so
-- this file can see them after the extraction. NxWarehouse.lua sets
-- them up before this file loads. BandBankActive is mutable so we
-- read it through Nx.Warehouse rather than aliasing.
local CharBags      = Nx.Warehouse.CharBags
local BankBags      = Nx.Warehouse.BankBags
local BandBags      = Nx.Warehouse.BandBags
local CurrencyArray = Nx.Warehouse.CurrencyArray

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

    local numBankBagSlots = NUM_BANKBAGSLOTS or 7
    if arg1 == KEYRING_CONTAINER or arg1 == BACKPACK_CONTAINER or (arg1 >= 1 and arg1 <= NUM_BAG_SLOTS) or
            arg1 == BANK_CONTAINER or arg1 == REAGENTBANK_CONTAINER or (arg1 >= NUM_BAG_SLOTS + 1 and arg1 <= NUM_BAG_SLOTS + numBankBagSlots) then

        self.LockBank = nil

        if arg1 == BANK_CONTAINER or arg1 == REAGENTBANK_CONTAINER or (arg1 >= NUM_BAG_SLOTS + 1 and arg1 <= NUM_BAG_SLOTS + numBankBagSlots) then
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

    if Nx.Warehouse.BandBankActive then
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
