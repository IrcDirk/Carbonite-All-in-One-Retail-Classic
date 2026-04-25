-------------------------------------------------------------------------------
-- NxFav - Favorites/Notes Window
-- Copyright 2008-2012 Carbon Based Creations, LLC
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
-- VERSION AND MODULE INITIALIZATION
-------------------------------------------------------------------------------

-- Data version for favorites/notes format
Nx.VERSIONFAV = .16

-- Notes module namespace
Nx.Notes = {}

-- Create the AceAddon for the Notes module
CarboniteNotes = LibStub("AceAddon-3.0"):NewAddon("CarboniteNotes", "AceTimer-3.0", "AceEvent-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

-------------------------------------------------------------------------------
-- KEYBINDING DEFINITIONS
-------------------------------------------------------------------------------

BINDING_HEADER_CarboniteNotes = "|cffc0c0ff" .. L["Carbonite Notes"] .. "|r"
BINDING_NAME_NxTOGGLEFAV = L["NxTOGGLEFAV"]

-------------------------------------------------------------------------------
-- LOCAL VARIABLES
-------------------------------------------------------------------------------

-- Storage for notes from other addons
local addonNotes = {}

-------------------------------------------------------------------------------
-- DEFAULT OPTIONS
-- Default settings for notes module
-------------------------------------------------------------------------------

local defaults = {
    profile = {
        Notes = {
            ShowMap = true,           -- Show user notes on map
            HandyNotes = true,        -- Show HandyNotes integration
            HandyNotesSize = 15,      -- HandyNotes icon size
            RareScanner = true,       -- Show RareScanner integration
            RareScannerSize = 32,     -- RareScanner icon size
            Questie = false,          -- Show Questie quest objectives
            QuestieSE = false,        -- Show Questie available quests
            QuestieSize = 32,         -- Questie icon size
        },
        Addons = {
        },
    }
}

-------------------------------------------------------------------------------
-- OPTIONS CONFIGURATION
-- AceConfig options for notes module
-------------------------------------------------------------------------------

local notesoptions

---
-- Get or create notes options configuration
-- @return  Notes options table
--
local function notesConfig()
    if not notesoptions then
        notesoptions = {
            type = "group",
            name = L["Note Options"],
            args = {
                -- Show notes on map toggle
                notemap = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L["Show Notes On Map"],
                    desc = L["Shows your notes on the carbonite map"],
                    get = function()
                        return Nx.fdb.profile.Notes.ShowMap
                    end,
                    set = function()
                        Nx.fdb.profile.Notes.ShowMap = not Nx.fdb.profile.Notes.ShowMap
                    end,
                },
                handy = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = L["Display Handynotes On Map"],
                    desc = L["If you have HandyNotes installed, allows them on the Carbonite map"],
                    get = function()
                        return Nx.fdb.profile.Notes.HandyNotes
                    end,
                    set = function()
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.HandyNotes = not Nx.fdb.profile.Notes.HandyNotes
                        if Nx.fdb.profile.Notes.HandyNotes then
                            Nx.Notes:HandyNotes(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!HANDY")
                        end
                    end,
                    disabled = function()
                        if HandyNotes then
                            return false
                        end
                        return true
                    end,
                },
                handysize = {
                    order = 3,
                    type = "range",
                    width = "normal",
                    min = 10,
                    max = 60,
                    step = 5,
                    name = L["Handnotes Icon Size"],
                    get = function()
                        return Nx.fdb.profile.Notes.HandyNotesSize
                    end,
                    set = function(input,value)
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.HandyNotesSize = value
                        map:ClearIconType("!HANDY")
                        Nx.Notes:HandyNotes(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function()
                        if HandyNotes then
                            return false
                        end
                        return true
                    end,
                },
                rarescanner = {
                    order = 4,
                    type = "toggle",
                    width = "full",
                    name = L["Display RareScanner icons On Map"],
                    desc = L["If you have RareScanner installed, allows its icons on the Carbonite map"],
                    get = function()
                        return Nx.fdb.profile.Notes.RareScanner
                    end,
                    set = function()
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.RareScanner = not Nx.fdb.profile.Notes.RareScanner
                        if Nx.fdb.profile.Notes.RareScanner then
                            Nx.Notes.PrevRSPins = 0
                            Nx.Notes:RareScanner(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!RSR")
                        end
                    end,
                    disabled = function()
                        if RareScanner then
                            return false
                        end
                        return true
                    end,
                },
                raresize = {
                    order = 5,
                    type = "range",
                    width = "normal",
                    min = 10,
                    max = 60,
                    step = 5,
                    name = L["RareScanner Icon Size"],
                    get = function()
                        return Nx.fdb.profile.Notes.RareScannerSize
                    end,
                    set = function(input,value)
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.RareScannerSize = value
                        map:ClearIconType("!RSR")
                        Nx.Notes:RareScanner(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function()
                        if RareScanner then
                            return false
                        end
                        return true
                    end,
                },
                questie = {
                    order = 6,
                    type = "toggle",
                    width = "full",
                    name = L["Display Questie quest objective icons On Map (Beware: might cause lags and fps loss)"],
                    desc = L["If you have Questie installed, allows its icons for quest objectives on the Carbonite map"],
                    get = function()
                        return Nx.fdb.profile.Notes.Questie
                    end,
                    set = function()
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.Questie = not Nx.fdb.profile.Notes.Questie
                        if Nx.fdb.profile.Notes.Questie then
                            Nx.Notes.PrevQuestiePins = 0
                            Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!QUE")
                        end
                    end,
                    disabled = function()
                        if Questie then
                            return false
                        end
                        return true
                    end,
                },
                questieSE = {
                    order = 7,
                    type = "toggle",
                    width = "full",
                    name = L["Display icons for Available quests from Questie on Carbonite Map"],
                    desc = L["If you have Questie installed, allows its icons for available quests on the Carbonite map"],
                    get = function()
                        return Nx.fdb.profile.Notes.QuestieSE
                    end,
                    set = function()
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.QuestieSE = not Nx.fdb.profile.Notes.QuestieSE
                        if Nx.fdb.profile.Notes.Questie then
                            Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
                        end
                    end,
                    disabled = function()
                        if Questie then
                            return false
                        end
                        return true
                    end,
                },
                questiesize = {
                    order = 8,
                    type = "range",
                    width = "normal",
                    min = 10,
                    max = 40,
                    step = 1,
                    name = L["Questie Icon Size"],
                    get = function()
                        return Nx.fdb.profile.Notes.QuestieSize
                    end,
                    set = function(input,value)
                        local map = Nx.Map:GetMap (1)
                        Nx.fdb.profile.Notes.QuestieSize = value
                        map:ClearIconType("!QUE")
                        Nx.Notes.PrevQuestiePins = 0
                        Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function()
                        if Questie then
                            return false
                        end
                        return true
                    end,
                },

            },
        }
    end
    Nx.Opts:AddToProfileMenu(L["Notes"], 4, Nx.fdb)
    return notesoptions
end

-------------------------------------------------------------------------------
-- MODULE INITIALIZATION
-------------------------------------------------------------------------------

---
-- AceAddon initialization callback
-- Sets up database, registers menus, and integrates with Carbonite
--
function CarboniteNotes:OnInitialize()
    -- Wait for main Carbonite addon to initialize
    if not Nx.Initialized then
        CarbNotesInit = Nx:ScheduleTimer(CarboniteNotes.OnInitialize, 1)
        return
    end

    -- Initialize the database
    Nx.fdb = LibStub("AceDB-3.0"):New("NXNotes", defaults, true)
    Nx.Notes:Init()

    -- Register addon communication channel
    CarboniteNotes:RegisterComm("carbmodule", Nx.Notes.OnChat_msg_addon)

    -- Define button type for map toolbar
    local function func()
        Nx.Notes:ToggleShow()
    end
    Nx.Button.TypeData["MapFav"] = {
        Up = "$INV_Torch_Lit",
        SizeUp = 22,
        SizeDn = 22,
    }

    -- Add to minimap button menu
    Nx.NXMiniMapBut.Menu:AddItem(0, L["Show Notes"], func, Nx.NXMiniMapBut)

    -- Register for icon updates
    tinsert(Nx.ModuleUpdateIcon, "Notes")

    -- Add toolbar button data
    tinsert(Nx.BarData, {"MapFav", L["-Notes-"], Nx.Notes.OnButToggleFav, false})

    -- Add context menu items to map
    Nx.Map.Maps[1]:CreateToolBar()
    Nx.Map.Maps[1].Menu:AddItem(0, L["Add Note"], Nx.Notes.Menu_OnAddNote, Nx.Map.Maps[1])
    Nx.Map.Maps[1].GIconMenu:AddItem(0, L["Add Note"], Nx.Notes.Menu_OnAddNote, Nx.Map.Maps[1])

    -- Register with Carbonite options
    Nx:AddToConfig("Notes Module", notesConfig(), L["Notes Module"])

    -- Add to broker menu
    tinsert(Nx.BrokerMenuTemplate, { text = L["Toggle Notes"], func = function() Nx.Notes:ToggleShow() end })
end

-------------------------------------------------------------------------------
-- ADDON COMMUNICATION
-------------------------------------------------------------------------------

---
-- Handle incoming addon messages
-- @param msg     Message string
-- @param dist    Distribution type
-- @param target  Target player
--
function Nx.Notes:OnChat_msg_addon(msg, dist, target)
    local ssplit = { strsplit("|", msg) }
    if ssplit[1] == "CMD" then
        if ssplit[2] == "note" then
            Nx.Notes:SetNoteAtStr(ssplit[3])
        end
    end
end

-------------------------------------------------------------------------------
-- NOTES INITIALIZATION
-------------------------------------------------------------------------------

---
-- Initialize the notes module
-- Sets up data version, folders, and available icons
--
function Nx.Notes:Init()
    local fav = Nx.fdb.profile.Notes

    -- Check and upgrade data version if needed
    if not fav or not fav.Version or fav.Version < Nx.VERSIONFAV then
        if fav and fav.Version then
            Nx.prt(L["Reset old notes data"] .. " %f", fav.Version)
        end

        fav = {}
        Nx.fdb.profile.Notes = fav
        fav.Version = Nx.VERSIONFAV
    end

    -- Initialize state
    self.Folders = Nx.GetFav()
    self.PrevQuestiePins = 0
    self.PrevRSPins = 0

    -- Available note icons (raid markers, minimap icons, etc.)
    self.NoteIcons = {
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",   -- Star
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",   -- Circle
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",   -- Diamond
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",   -- Triangle
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",   -- Moon
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",   -- Square
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",   -- Cross
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",   -- Skull
        "Interface\\Minimap\\Tracking\\Auctioneer",
        "Interface\\Minimap\\Tracking\\Banker",
        "Interface\\Minimap\\Tracking\\BattleMaster",
        "Interface\\Minimap\\Tracking\\FlightMaster",
        "Interface\\Minimap\\Tracking\\Innkeeper",
        "Interface\\Minimap\\Tracking\\Mailbox",
        "Interface\\Minimap\\Tracking\\Repair",
        "Interface\\Minimap\\Tracking\\StableMaster",
        "Interface\\Minimap\\Tracking\\Class",
        "Interface\\Minimap\\Tracking\\Profession",
        "Interface\\Minimap\\Tracking\\TrivialQuests",
        "Interface\\Minimap\\Tracking\\Ammunition",
        "Interface\\Minimap\\Tracking\\Food",
        "Interface\\Minimap\\Tracking\\Poisons",
        "Interface\\Minimap\\Tracking\\Reagents",
        "Interface\\TargetingFrame\\UI-PVP-Alliance",
        "Interface\\TargetingFrame\\UI-PVP-Horde",
        "Interface\\TargetingFrame\\UI-PVP-FFA",
        "Interface\\PVPFrame\\PVP-ArenaPoints-Icon",
        "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    }

    -- Update notes when loot window closes (for gathering tracking)
    CarboniteNotes:RegisterEvent("LOOT_CLOSED", function() Nx.Notes:Update() end)
end

-------------------------------------------------------------------------------
-- ICON HELPERS
-------------------------------------------------------------------------------

---
-- Get inline texture string for an icon
-- @param index  Icon index
-- @return       Texture escape string
--
function Nx.Notes:GetIconInline(index)
    local file = self.NoteIcons[index]
    return format("|T%s:16|t", file)
end

---
-- Get icon file path
-- @param index  Icon index
-- @return       File path string
--
function Nx.Notes:GetIconFile(index)
    return self.NoteIcons[index]
end

-------------------------------------------------------------------------------
-- SAFECALL IMPLEMENTATION
-- Protected function calls for addon compatibility
-------------------------------------------------------------------------------

local xpcall = xpcall

local function errorhandler(err)
    return geterrorhandler()(err)
end

---
-- Safely call a function with error handling
-- Used for optional callbacks that may not exist
-- @param func  Function to call (or nil)
-- @param ...   Arguments to pass
-- @return      Function result or nil
--
local function safecall(func, ...)
    if type(func) == "function" then
        return xpcall(func, errorhandler, ...)
    end
end

-------------------------------------------------------------------------------
-- HANDYNOTES PIN HANDLERS
-- Mouse event handlers for HandyNotes integration
-------------------------------------------------------------------------------

local handypin = {}

function handypin:OnEnter(motion)
    WorldMapBlobFrame:SetScript("OnUpdate", nil)
    safecall(HandyNotes.plugins[self.pluginName].OnEnter, self, self.mapFile, self.coord)
end

function handypin:OnLeave(motion)
    WorldMapBlobFrame:SetScript("OnUpdate", WorldMapBlobFrame_OnUpdate)
    safecall(HandyNotes.plugins[self.pluginName].OnLeave, self, self.mapFile, self.coord)
end

-------------------------------------------------------------------------------
-- FAVORITES WINDOW CREATION
-------------------------------------------------------------------------------

---
-- Create the favorites/notes window
-- Sets up window, buttons, lists, and menus
--
function Nx.Notes:Create()

    self.Side = 1

    -- Create Window

    local win = Nx.Window:Create ("NxFav", 240, nil, nil, 1)
    self.Win = win
    win.Frm.NxInst = self

    win:CreateButtons (true, true)
    win:SetTitleLineH (18)
    win:SetTitleXOff (220)

    win:InitLayoutData (nil, -.23, -.25, -.54, -.5)
    win.Frm:SetToplevel (true)

    win:Show (false)

    tinsert (UISpecialFrames, win.Frm:GetName())

    -- Buttons

    local bw, bh = win:GetBorderSize()

    local but = Nx.Button:Create (win.Frm, "Txt64B", L["Record"], nil, bw + 1, -bh, "TOPLEFT", 44, 20, self.But_OnRecord, self)
    self.RecBut = but

    local but = Nx.Button:Create (win.Frm, "Txt64", L["Up"], nil, bw + 48, -bh, "TOPLEFT", 40, 20, self.But_OnUp, self)
    local but = Nx.Button:Create (but.Frm, "Txt64", L["Down"], nil, 42, 0, "TOPLEFT", 40, 20, self.But_OnDown, self)
    Nx.Button:Create (but.Frm, "Txt64", L["Delete Item"], nil, 54, 0, "TOPLEFT", 72, 20, self.But_OnItemDel, self)

    -- Folder List

    Nx.List:SetCreateFont ("Font.Medium", 16)

    local list = Nx.List:Create ("FavF", 0, 0, 1, 1, win.Frm)
    self.List = list

    list:SetUser (self, self.OnListEvent)

    list:SetLineHeight (4)

    list:ColumnAdd ("", 1, 20)
    list:ColumnAdd (L["Name"], 2, 900)

    win:Attach (list.Frm, 0, .3, 0, 1)

    -- Item List

    Nx.List:SetCreateFont ("Font.Medium", 16)

    local list = Nx.List:Create ("FavI", 0, 0, 1, 1, win.Frm)
    self.ItemList = list

    list:SetUser (self, self.OnItemListEvent)

    list:SetLineHeight (2)

    list:ColumnAdd ("", 1, 17)
    list:ColumnAdd (L["Type"], 2, 90)
    list:ColumnAdd (L["Value"], 3, 250)
    list:ColumnAdd (L["Location"], 4, 900)

    win:Attach (list.Frm, .3, 1, 0, 1)            -- 18, 1 with editbox

    -- Filter Edit Box

--    self.EditBox = Nx.EditBox:Create (win.Frm, self, self.OnEditBox, 30)

--    win:Attach (self.EditBox.Frm, .3, 1, 0, 18)

    --

    self:CreateMenu()

    --

    self:Update()

    self.List:FullUpdate()
end

-------------------------------------------------------------------------------
-- RECORDING FUNCTIONS
-- Record locations and notes while exploring
-------------------------------------------------------------------------------

function Nx.Notes:But_OnRecord(but)
    self:SetRecord(but:GetPressed())
end

---
-- Enable or disable recording mode
-- @param on  true to enable recording
--
function Nx.Notes:SetRecord(on)

    local but = self.RecBut

    if on then
        if self.CurFav then
            self.Recording = self.CurFav
            self.RecAlphaAnim = 1000
            self.FavRec = Nx:ScheduleRepeatingTimer(self.RecordAnimTimer,0.1,self)
            but:SetPressed (true)
        else
            Nx.prt (L["Select a favorite before recording"])
            but:SetPressed (false)
        end
    else
        Nx:CancelTimer(self.FavRec)
        self.Recording = nil
        but:SetAlpha (1)
        but:SetPressed (false)
    end
end

function Nx.Notes:RecordAnimTimer()

    if self.Recording then
        local a = (self.RecAlphaAnim - 35) % 1000
        self.RecAlphaAnim = a
        self.RecBut:SetAlpha (abs (a - 500) / 1000 + .5)
    end
end

function Nx.Notes:But_OnUp()
    self:MoveCur (true)
end

function Nx.Notes:But_OnDown()
    self:MoveCur()
end

function Nx.Notes:MoveCur (low)

    if self.Side == 1 then

        local item = self.CurFavOrFolder
        if item then

            local parent = self:GetParent (item)

            Nx.Util_TMoveItem (parent, item, low)

            local i = self:FindListI (item)
            if i > 0 then
                self.List:Select (i + 1)        -- Add one for "Root" entry
            end
        end
    else
        local fav = self.CurFav
        if fav and self.CurItemI then
            local i = Nx.Util_TMoveI (fav, self.CurItemI, low)
            if i then
                self.CurItemI = i
                self.ItemList:Select (i)
            end
        end
    end

    self:Update()
end

function Nx.Notes:But_OnItemDel()

    local fav = self.CurFav
    if fav and self.CurItemI then
        if fav[self.CurItemI] then
            tremove (fav, self.CurItemI)
        end
    end

    self:Update()
end

-------------------------------------------------------------------------------
-- CONTEXT MENUS
-- Create folder/item context menus
-------------------------------------------------------------------------------

---
-- Create the folder and item context menus
--
function Nx.Notes:CreateMenu()

    local menu = Nx.Menu:Create (self.List.Frm, 250)
    self.Menu = menu

    menu:AddItem (0, L["Add Folder"], self.Menu_OnAddFolder, self)
    menu:AddItem (0, L["Add Favorite"], self.Menu_OnAddFavorite, self)
    menu:AddItem (0, "")
    menu:AddItem (0, L["Rename"], self.Menu_OnRename, self)
    menu:AddItem (0, L["Cut"], self.Menu_OnCut, self)
    menu:AddItem (0, L["Copy"], self.Menu_OnCopy, self)
    menu:AddItem (0, L["Paste"], self.Menu_OnPaste, self)

    local function func()
        Nx.Opts:Open ("Favorites")
    end

    menu:AddItem (0, "")
    menu:AddItem (0, L["Options"] .. "...", func)

    local menu = Nx.Menu:Create (self.List.Frm, 250)
    self.ItemMenu = menu

    menu:AddItem (0, L["Add Comment"], self.IMenu_OnAddComment, self)
    menu:AddItem (0, "")
    menu:AddItem (0, L["Rename"], self.IMenu_OnRename, self)
    menu:AddItem (0, L["Cut"], self.IMenu_OnCut, self)
    menu:AddItem (0, L["Copy"], self.IMenu_OnCopy, self)
    menu:AddItem (0, L["Paste"], self.IMenu_OnPaste, self)

    menu:AddItem (0, "")
    menu:AddItem (0, L["Set Icon"], self.IMenu_OnSetIcon, self)
end

function Nx.Notes:Menu_OnAddFolder (item)

    local function func (str, self)
        self:AddFolder (str, self.CurFolder)
        self:Update()
    end

    Nx:ShowEditBox (L["Name"], "", self, func)
end

function Nx.Notes:Menu_OnAddFavorite (item)

    local function func (str, self)
        self:AddFavorite (str, self.CurFolder)
        self:Update()
    end

    Nx:ShowEditBox (L["Name"], "", self, func)
end

function Nx.Notes:Menu_OnRename (item)

    local function func (str, self)
        if self.CurFavOrFolder then
            self.CurFavOrFolder["Name"] = str
            self:Update()
        end
    end

    if self.CurFavOrFolder then
        local name = self.CurFavOrFolder["Name"]
        Nx:ShowEditBox (L["Name"], name, self, func)
    end
end

function Nx.Notes:Menu_OnCut()

    local item = self.CurFavOrFolder
    if item then

        local parent = self:GetParent (item)

        for i, it in ipairs (parent) do
            if it == item then
                tremove (parent, i)
                self.CopyBuf = item
                self:Update()
            end
        end

        self:SelectCur()
    end
end

function Nx.Notes:Menu_OnCopy()

    local item = self.CurFavOrFolder
    if item then
        self.CopyBuf = Nx.Util_TCopyRecurse (item)
    end
end

function Nx.Notes:Menu_OnPaste()

    if not self.CopyBuf then
        Nx.prt (L["Nothing to paste"])
        return
    end

    if type (self.CopyBuf) ~= "table" then
        Nx.prt (L["Can't paste that on the left side"])
        return
    end

    local new = Nx.Util_TCopyRecurse (self.CopyBuf)
    local item = self.CurFav

    if item then
        local parent = self:GetParent (item)
        local i = Nx.Util_TFindItemI (parent, item)
        tinsert (parent, i, new)
    else
        tinsert (self.CurFolder, 1, new)
    end

    self:Update()
    self:SelectCur()
end

---------------------------------------------------------------------------------------

function Nx.Notes:IMenu_OnAddComment()

    local function func (str, self)
        local s = self:CreateItem ("", 0, str)
        self:AddItem (self.CurFav, self.CurItemI, s)
    end

    Nx:ShowEditBox (L["Name"], "", self, func)
end

function Nx.Notes:IMenu_OnRename()

    local function func (str, self)
        if self.CurFavOrFolder then
            self:SetItemName (self.CurItemI, str)
            self:Update()
        end
    end

    local typ, name = self:GetItemTypeName (self.CurItemI)
    Nx:ShowEditBox (L["Name"], name, self, func)
end

function Nx.Notes:IMenu_OnCut()
    local fav = self.CurFav
    if fav and self.CurItemI then

        if fav[self.CurItemI] then
            self.CopyBuf = fav[self.CurItemI]
            tremove (fav, self.CurItemI)
        end
    end

    self:Update()
end

function Nx.Notes:IMenu_OnCopy()
    local fav = self.CurFav
    if fav then
        self.CopyBuf = fav[self.CurItemI]
    end
end

function Nx.Notes:IMenu_OnPaste()

    if not self.CopyBuf then
        Nx.prt (L["Nothing to paste"])
        return
    end

    if type (self.CopyBuf) ~= "string" then
        Nx.prt (L["Can't paste that on the right side"])
        return
    end

    local fav = self.CurFav
    if fav then
        local i = min (self.CurItemI, #fav) + 1
        tinsert (fav, i, self.CopyBuf)
    end

    self:Update()
end

function Nx.Notes:IMenu_OnSetIcon()

    Nx.DropDown:Start (self, self.SetIconAccept)

    for i, name in ipairs (self.NoteIcons) do

        local iconStr = self:GetIconInline (i)
        local s = format ("%s", iconStr)

        Nx.DropDown:Add (s, false)
    end

    Nx.DropDown:Show (self.Win.Frm)
end

function Nx.Notes:SetIconAccept (name, sel)

    local fav = self.CurFav
    local index = self.CurItemI

    if fav and index then

        local item = fav[index]
        local typ, flags, name, data = self:ParseItem (item)

        flags = strbyte (flags) - 35

        if typ == "N" then
            local icon, id, x, y, level = self:ParseItemNote (data)
            fav[index] = self:CreateItem ("N", flags, name, sel, id, x, y, level)

            self:Update()
        end
    end
end

-------------------------------------------------------------------------------
-- WINDOW VISIBILITY
-------------------------------------------------------------------------------

---
-- Keybinding handler to toggle notes window
--
function Nx:NXFavKeyToggleShow()
    Nx.Notes:ToggleShow()
end

---
-- Toggle the notes window visibility
--
function Nx.Notes:ToggleShow()

    if not self.Win then
        self:Create()
    end

    self.Win:Show (not self.Win:IsShown())

    if self.Win:IsShown() then
        self:Update()
    end
end

-------------------------------------------------------------------------------
-- EDIT BOX HANDLING
-------------------------------------------------------------------------------

---
-- Handle filter edit box changes
-- @param editbox  Edit box frame
-- @param message  Event message
--
function Nx.Notes:OnEditBox(editbox, message)

    if message == "Changed" then
        self:Update()
    end
end

-------------------------------------------------------------------------------
-- LIST EVENT HANDLERS
-------------------------------------------------------------------------------

---
-- Handle folder list events (selection, context menu, etc.)
-- @param eventName  Event type
-- @param sel        Selected index
-- @param val2       Additional value
-- @param click      Click info
--
function Nx.Notes:OnListEvent(eventName, sel, val2, click)

    -- Nx.prt ("Notes list event "..eventName)

    local data = self.List:ItemGetData (sel)

    if not data then
        self.CurFolder = self.Folders
        self.CurFav = nil
    else
        if data["T"] == "F" then
            self.CurFolder = data
            self.CurFav = nil
        else
            self.CurFolder = self:GetParent (data)
            self.CurFav = data
            self:SelectItems (1)
        end
    end

    self.CurFavOrFolder = data    -- This is nil if root

    self.Side = 1

    if eventName == "select" or eventName == "mid" or eventName == "menu" then

        if eventName == "menu" then
            if type(self.CurFav) == "string" then
                self.Menu:Show(-1)
            else
                self.Menu:Show(1)
            end
            self.Menu:Open()
        end

        self:Update()

    elseif eventName == "button" then    -- Button icon

        self.List:Select (sel)
        if data then
            if type(data) == "string" then
                data = addonNotes
            end
            if data["Hide"] then
                data["Hide"] = nil
            else
                data["Hide"] = true
            end
            self:Update()
        end
    end
end

---
-- Handle item list events (selection, context menu, etc.)
-- @param eventName  Event type
-- @param sel        Selected index
-- @param val2       Additional value
-- @param click      Click info
--
function Nx.Notes:OnItemListEvent(eventName, sel, val2, click)

--    Nx.prt ("List event "..eventName)

    local list = self.ItemList

    local item = list:ItemGetData (sel)

    self.CurItemI = sel
    self.Side = 2

    if eventName == "select" or eventName == "mid" or eventName == "menu" then

        if eventName == "menu" then
            self.ItemMenu:Show (self.CurFav and true or -1)
            if type(self.CurFav) == "string" then
                self.ItemMenu:Show(-1)
            end
            self.ItemMenu:Open()
        end

    elseif eventName == "button" then    -- Button icon

        local flags = val2 and 1 or 0        -- Pressed
        self:SetItemFlags (sel, 0xfe, flags)

    end

    self:SelectItems (sel)
    self:Update()
end

-------------------------------------------------------------------------------
-- UPDATE FUNCTIONS
-- Refresh lists and display
-------------------------------------------------------------------------------

---
-- Update the favorites window
-- Refreshes both folder and item lists
--
function Nx.Notes:Update()

    self.Draw = false        -- Force map to update icons

    local Nx = Nx

    if not self.Win then
        return
    end

    -- List

    local list = self.List

    list:Empty()

    list:ItemAdd()
    list:ItemSet (2, "|cff808080Root")

    self.FavCnt = 0

    self:UpdateFolder (self.Folders, 1)
    self:AddonFolders(1)
    list:Update()
    -- Right side list

    self:UpdateItems()

    -- Title

    self.Win:SetTitle (format (L["Notes"] .. ": %s", self.FavCnt))
end

function Nx.Notes:AddonFolders(level)
    local list = self.List
    local hide = addonNotes.Hide
    list:ItemAdd("addons")
    list:ItemSet(2,"  " .. L["Note Addons"])
    list:ItemSetButton ("QuestHdr", hide)
    if not hide then
        for a,b in pairs(addonNotes) do
            if a ~= "Hide" then
                local space = strrep ("  ", level+1)
                list:ItemAdd(a)
                list:ItemSet(2, format ("%s|cffdfdfdf%s",space,a))
            end
        end
    end
end

function Nx.Notes:UpdateFolder (folder, level)

    local list = self.List

    local hide = folder["Hide"]

    if level > 1 then
        list:ItemAdd (folder)
        local space = strrep ("  ", level - 1)
        list:ItemSet (2, format ("%s%s", space, folder["Name"]))
        list:ItemSetButton ("QuestHdr", hide)
    end

    if not hide then

        local space = strrep ("  ", level)

        for index, item in ipairs (folder) do

            local typ = item["T"]
            local name = item["Name"]

            if typ == "F" then
                self:UpdateFolder (item, level + 1)
            else

                self.FavCnt = self.FavCnt + 1

                list:ItemAdd (item)
                list:ItemSet (2, format ("%s|cffdfdfdf%s", space, name))

                if self.FavToSelect == item then
                    self.FavToSelect = nil
                    list:Select (list:ItemGetNum())
                end
            end
        end
    end
end

function Nx.Notes:UpdateItems (selectI)

    local list = self.ItemList

    if not list then
        return
    end

    list:Empty()

    if self.CurFav then
        if type(self.CurFav) == "string" then
            if self.CurFav == "addons" then
                selectI = 0
            else
                if self.CurFav ~= "Hide" then
                    if addonNotes[self.CurFav] then
                        for a,b in pairs (addonNotes[self.CurFav]["notes"]) do
                            local name, data = a,b
                            list:ItemAdd(item)
                            local icon, id, x, y, level = self:ParseItemNote (data)
                            icon = self:GetIconInline (icon)
                            id = Nx.Map:GetMapNameByID(id) or "?"
                            list:ItemSet (2, "Note:")
                            list:ItemSet (3, format ("%s %s", icon, name))
                            list:ItemSet (4, format ("|cff80ef80(%s %.1f %.1f)", id, x, y))
                        end
                    end
                end
            end
        else
            for index, str in ipairs (self.CurFav) do

                local typ, flags, name, data = self:ParseItem (str)

                list:ItemAdd (item)
                list:ItemSetButton ("Chk", bit.band (strbyte (flags) - 35, 1) > 0)

                if typ == "" then            -- Comment
                    list:ItemSet (3, format ("|cffa0a0a0-- %s", name))

                elseif typ == "N" then            -- Note

                    local icon, id, x, y, level = self:ParseItemNote (data)
                    icon = self:GetIconInline (icon)
                    local newid = Nx.Map:GetMapNameByID(id) or "?"
                    list:ItemSet (2, L["Note"] .. ":")
                    list:ItemSet (3, format ("%s %s", icon, name))
                    list:ItemSet (4, format ("|cff80ef80(%s %.1f %.1f)", newid, x, y))

                elseif typ == "T" or typ == "t" then            -- Target

                    local typName = typ == "T" and "Target 1st" or "Target"
                    local mapId, x, y = self:ParseItemTarget (data)
                    local mapName = Nx.Map:GetMapNameByID(mapId) or "?"
                    list:ItemSet (2, format ("%s:", typName))
                    list:ItemSet (3, format ("%s", name))
                    list:ItemSet (4, format ("|cff80ef80(%s %.1f %.1f)", mapName, x, y))
                end
            end
        end
    end

    if selectI then
        list:Select (selectI)
    end

    list:Update()
end

-------------------------------------------------------------------------------
-- SELECTION AND NAVIGATION
-------------------------------------------------------------------------------

---
-- Select the current favorite in the list
--
function Nx.Notes:SelectCur()

    self.List:SendUserSelect()
    self:SelectItems (1)
end

---
-- Get the parent folder of an item
-- @param item    Item to find parent for
-- @param folder  Starting folder (nil for root)
-- @return        Parent folder or nil
--
function Nx.Notes:GetParent(item, folder)

    folder = folder or self.Folders

    for _, it in ipairs (folder) do

        if it == item then
            return folder
        end

        local typ = it["T"]
        if typ == "F" then
            local v = self:GetParent (item, it)
            if v then
                return v
            end
        end
    end
end

---
-- Find a folder by name
-- @param name    Folder name to find
-- @param parent  Parent folder to search (nil for root)
-- @return        Folder table or nil
--
function Nx.Notes:FindFolder(name, parent)

    parent = parent or self.Folders

    for _, item in ipairs (parent) do

        if item["T"] == "F" then
            if item["Name"] == name then
                return item
            end
        end
    end
end

---
-- Find a favorite by a variable value
-- @param val      Value to match
-- @param varName  Variable name to check
-- @param parent   Parent folder (nil for root)
-- @return         Favorite table or nil
--
function Nx.Notes:FindFav(val, varName, parent)

    parent = parent or self.Folders

    for _, item in ipairs (parent) do

        if item["T"] == nil then
            if item[varName] == val then
                return item
            end
        end
    end
end

---
-- Open all folders leading to a favorite
-- @param item    Favorite item
-- @param folder  Starting folder (nil for root)
-- @return        Index in the folder
--
function Nx.Notes:OpenFoldersToFav(item, folder)

    folder = folder or self.Folders

    for index, it in ipairs (folder) do

        if it == item then
            return index
        end

        if it["T"] == "F" then

            index = self:OpenFoldersToFav (item, it)

            if index then    -- Found?
                it["Hide"] = nil
                return index
            end
        end
    end
end

---
-- Find the list index of an item
-- @param item    Item to find
-- @param folder  Starting folder (nil for root)
-- @param index   Current index (internal)
-- @return        List index (negative if not found)
--
function Nx.Notes:FindListI(item, folder, index)

    folder = folder or self.Folders
    index = index or 1

    for _, it in ipairs (folder) do

        if it == item then
            return index
        end

        index = index + 1

        if it["T"] == "F" then
            if not it["Hide"] then
                index = self:FindListI (item, it, index)
                if index > 0 then    -- Found?
                    return index
                end
                index = -index
            end
        end
    end

    return -index        -- Failed
end

function Nx.Notes:AddFolder (name, parent, index)

    local folder = {}
    folder["Name"] = name
    folder["T"] = "F"

    parent = parent or self.Folders

    if parent then
        index = index or #parent + 1
        tinsert (parent, index, folder)
    end

    return folder
end

function Nx.Notes:AddFavorite (name, parent, index)

    local fav = {}
    fav["Name"] = name

    parent = parent or self.Folders

    if parent then
        index = index or #parent + 1
        tinsert (parent, index, fav)
    end

    return fav
end

function Nx.Notes:AddItem (fav, index, item)

--    Nx.prt ("Fav AddItem %s #%s %s", fav["Name"], index or "nil", item)

    if fav then

        local i = max (min (index or 999999, #fav), 0) + 1
        tinsert (fav, i, item)

        self:SelectItems (i)
    end
end

function Nx.Notes:CreateItem (typ, flags, name, p1, p2, p3, p4, p5)

    p5 = p5 or 0

    flags = flags + 35

    name = gsub (name, "[~^]", "")
    name = gsub (name, "\n", " ")

    if typ == "" then            -- Comment
        return format ("~%c~%s", flags, name)

    elseif typ == "N" then    -- Note
        return format ("N~%c~%s~%s|%s|%s|%s|%s", flags, name, p1, p2, p3,p4, p5)
    elseif typ == "T" or typ == "t" then    -- Target
        return format ("%s~%c~%s~%s|%s|%s|%s", typ, flags, name, p1, p2, p3, p5)
    end
end

function Nx.Notes:MakeXY (x, y)
    local s = Nx:PackXY (x, y % 100)
    return s .. strchar (floor (y / 100) + 35)    -- Add dungeon level to end
end

function Nx.Notes:ParseItem (item)
    if item then
        return strsplit ("~", item)    -- Type~Flags (# based)~Name~Data
    end
end

function Nx.Notes:ParseItemNote (data)
    local iconI,zone,x,y, dLvl = Nx.Split("|",data)
    if not dLvl then
        dLvl = 0
    end
    return tonumber(iconI), tonumber(zone), tonumber(x), tonumber(y), tonumber(dLvl)
end

function Nx.Notes:ParseItemTarget (data)
    local zone, x, y, dLvl = Nx.Split("|",data)
    if not dLvl then
        dLvl = 0
    end
    return tonumber(zone), tonumber(x), tonumber(y), tonumber(dLvl)
end

function Nx.Notes:GetItemTypeName (index)

    local fav = self.CurFav
    if fav then
        local typ, flags, name = strsplit ("~", fav[index])
        return typ, name
    end
end

function Nx.Notes:SetItemFlags (index, mask, orFlags)

    local fav = self.CurFav
    if fav then
        local typ, flags, name, data = strsplit ("~", fav[index])

        flags = bit.bor (bit.band (strbyte (flags) - 35, mask), orFlags) + 35

        if data then
            fav[index] = format ("%s~%c~%s~%s", typ, flags, name, data)
        else
            fav[index] = format ("%s~%c~%s", typ, flags, name)
        end
    end
end

function Nx.Notes:SetItemName (index, name)

    name = gsub (name, "[~^]", "")
    name = gsub (name, "\n", " ")

    local fav = self.CurFav
    if fav then
        local typ, flags, _, data = strsplit ("~", fav[index])
        if data then
            fav[index] = format ("%s~%s~%s~%s", typ, flags, name, data)
        else
            fav[index] = format ("%s~%s~%s", typ, flags, name)
        end
    end
end

---
-- Select an item in the item list
-- @param index  Item index to select
--
function Nx.Notes:SelectItems(index)

    if self.CurFav then

        if self.Recording ~= self.CurFav then
            self:SetRecord (false)
        end

        self.CurItemI = min (index, #self.CurFav)

        self:UpdateItems (self.CurItemI)

        self:UpdateTargets()
    end
end

-------------------------------------------------------------------------------
-- NOTE RECORDING
-- Record notes, targets, and locations
-------------------------------------------------------------------------------

---
-- Record a note or target at the current location
-- @param typ    Type ("Note", "TargetS", "Target")
-- @param name   Note name
-- @param id     Map ID
-- @param x      X coordinate
-- @param y      Y coordinate
-- @param level  Dungeon level (optional)
--
function Nx.Notes:Record(typ, name, id, x, y, level)
    if self.InUpdateTarget then
        return
    end

    local fav = self.Recording

    self.RecId = id
    self.RecX = x
    self.RecY = y
    self.RecL = level or 0
    if typ == "Note" then

        local function func (name, self)
            local fav = self.Recording or self:GetNoteFav (self.RecId)
            local s = self:CreateItem ("N", 0, name, 1, self.RecId, self.RecX, self.RecY, self.RecL)
            self:AddItem (fav, self.CurItemI, s)
            self:Update()
        end

        Nx:ShowEditBox ("Name", name, self, func)

    elseif typ == "TargetS" then    -- Start

        local fav = self.Recording
        if fav then
            local s = self:CreateItem ("T", 0, name, self.RecId, self.RecX, self.RecY, self.RecL)
            self:AddItem (fav, self.CurItemI, s)
            self:Update()
        end

    elseif typ == "Target" then

        local fav = self.Recording
        if fav then
            local s = self:CreateItem ("t", 0, name, self.RecId, self.RecX, self.RecY, self.RecL)
            self:AddItem (fav, self.CurItemI, s)
            self:Update()
        end
    end
end

function Nx.Notes:GetNoteFav (mapId)

    local notes = self:FindFolder (L["My Notes"])

    if not notes then
        notes = self:AddFolder (L["My Notes"])
    end

    local name = Nx.Map:IdToName (mapId)

    local fav = self:FindFav (name, "Name", notes)

    if not fav then
        fav = self:AddFavorite (name, notes)
        fav["ID"] = mapId
        sort (notes, function (a, b) return a["Name"] < b["Name"] end)
    end

    return fav
end

function Nx.Notes:SetNoteAtStr (str)

    local words = {}
    local quote
    local strDone
    local curStr = ""

    for s in gmatch (str, ".") do

--        Nx.prt ("%s", s)

        if s == quote then
            quote = false
            strDone = true

        elseif not quote and (s == '"' or s == "'") then
            quote = s

        elseif s == ' ' and not quote then
            strDone = true

        else
            curStr = curStr .. s
        end

        if strDone then
            if #curStr > 0 then
                tinsert (words, curStr)
            end
            strDone = false
            curStr = ""
        end
    end

    if #curStr > 0 then
        tinsert (words, curStr)
    end

    --

    local map = Nx.Map:GetMap (1)

    local mId = map.RMapId
    local zx, zy = map.PlyrRZX, map.PlyrRZY
    local level = map.DungeonLevel

    if #words > 1 then
        mId, zx, zy = map:ParseTargetStr (table.concat (words, " ", 2))
    end

    if mId then
        local fav = self.Recording or self:GetNoteFav (mId)
        local s = self:CreateItem ("N", 0, words[1] or "", 1, mId, zx, zy, level)
        self:AddItem (fav, nil, s)
        self:Update()
    end
end

-------------------------------------------------------------------------------
-- ICON NOTE DISPLAY
-------------------------------------------------------------------------------

---
-- Show a note's details in the window when clicked on map
-- @param icon  Map icon that was clicked
--
function Nx.Notes:ShowIconNote(icon)

    local fav, index = Nx.Map:GetIconFavData (icon)

    self:OpenFoldersToFav (fav)
    self.FavToSelect = fav

    self.CurFolder = self:GetParent (fav)
    self.CurFav = fav
    self.CurItemI = index

    self.CurFavOrFolder = fav

    if not (self.Win and self.Win:IsShown()) then
        self:ToggleShow()
        if not self.Win then        -- Not validated?
            return
        end
    else
        self:Update()
    end

    self:SelectItems (index)
end

function Nx.Notes:UpdateTargets()

    local shown = self.Win and self.Win:IsShown()

    if self.CurFav and self.CurItemI    and (self.Recording or shown) then

        self.InUpdateTarget = true

        local map = Nx.Map:GetMap (1)

        local keep

        for n = self.CurItemI, #self.CurFav do

            local str = self.CurFav[n]
            local typ, flags, name, data = self:ParseItem (str)
            if typ == "T" then

                if n ~= self.CurItemI then        -- Another 1st target?
                    break
                end

                local mapId, x, y = self:ParseItemTarget (data)
                map:SetTargetXY (mapId, x, y, name, keep)
                keep = true

            elseif typ == "t" then

                local mapId, x, y = self:ParseItemTarget (data)
                map:SetTargetXY (mapId, x, y, name, keep)
                keep = true

            else

                break
            end
        end

        if keep then    -- Had a target?
            map:GotoPlayer()
        end

        self.InUpdateTarget = false
    end
end

-------------------------------------------------------------------------------
-- MAP ICON UPDATES
-- Draw note icons on the Carbonite map
-------------------------------------------------------------------------------

---
-- Update all note icons on the map
-- Includes user notes and addon integrations
--
function Nx.Notes:UpdateIcons()
    local Map = Nx.Map
    local map = Map:GetMap (1)

    if self.CurFav and self.CurItemI then

        map:InitIconType ("!Fav2", "WP", "", 21, 21)
        local str
        local typ, flags, name, data
        if type(self.CurFav) == "string" then
        else
            str = self.CurFav[self.CurItemI]
            typ, flags, name, data = self:ParseItem (str)
        end

        if typ == "N" then

            local icon, mapId, x, y, level = self:ParseItemNote (data)
            icon = self:GetIconFile (icon)
            local wx, wy = Map:GetWorldPos (mapId, x, y)

            local icon = map:AddIconPt ("!Fav2", wx, wy, level, nil, icon)
            map:SetIconTip (icon, L["Note"] .. ": " .. name)
            map:SetIconFavData (icon, self.CurFav, self.CurItemI)

            map:SetIconTypeAlpha ("!Fav2", abs ((GetTime() * 100 % 100 - 50) / 50))
        end

    else
        map:ClearIconType ("!Fav2")
    end

    local mapId = map.MapId
    local draw = map.ScaleDraw > .3 and Nx.fdb.profile.Notes.ShowMap

    if (Nx.fdb.profile.Notes.Questie and Questie) then
        Nx.Notes:Questie(mapId)
    end

    if (Nx.fdb.profile.Notes.RareScanner and RareScanner) then
        Nx.Notes:RareScanner(mapId)
    end

    if mapId == self.DrawMapId and draw == self.Draw and self.InstLevelSet == Nx.Map:GetCurrentMapDungeonLevel() then
        return
    end

    self.DrawMapId = mapId
    self.Draw = draw

    map:InitIconType ("!Fav", "WP", "", 17, 17)
--    map:SetIconTypeAlpha ("!Fav", map.GOpts["MapIconFavAlpha"])

    if not draw and self.InstLevelSet == Nx.Map:GetCurrentMapDungeonLevel() then
        return
    end

    self.InstLevelSet = Nx.Map:GetCurrentMapDungeonLevel()

    local cont = map:IdToContZone (mapId)
    cont = tonumber(cont)
--    Nx.prt ("mapid %s, cont %s", mapId, cont)

    if cont > 0 and cont < 90 then

        local notes = self:FindFolder (L["My Notes"])

        if notes then

            local fav = self:FindFav (mapId, "ID", notes)
            if fav then
                for n, str in ipairs (fav) do
                    local typ, flags, name, data = self:ParseItem (str)

                    if typ == "N" then
                        local icon, _, x, y, level = self:ParseItemNote (data)
                        icon = self:GetIconFile (icon)
                        local wx, wy = Map:GetWorldPos (mapId, x, y)

                        local icon = map:AddIconPt ("!Fav", wx, wy, level, nil, icon)
                        map:SetIconTip (icon, L["Note"] .. ": " .. name)
                        map:SetIconFavData (icon, fav, n)
                    end
                end
            end
        end
        for a,b in pairs(addonNotes) do
            if a ~= "Hide" then
                for c,d in pairs(addonNotes[a]["notes"]) do
                    local icon, zoneid, x, y, level = self:ParseItemNote(d)
                    if zoneid == mapId then
                        icon = self:GetIconFile (icon)
                        local wx, wy = Map:GetWorldPos(mapId,x,y)
                        local icon = map:AddIconPt("!Fav", wx, wy, level, nil, icon)
                        map:SetIconTip(icon, L["Note"] .. ": " .. c)
                        map:SetIconFavData(icon, fav, d)
                    end
                end
            end
        end
        Nx.Notes:HandyNotes(mapId)
        --WorldMap_HijackTooltip(map.Frm)
        GameTooltip:Hide()
    end
end

-------------------------------------------------------------------------------
-- HANDYNOTES INTEGRATION
-- Display HandyNotes pins on Carbonite map
-------------------------------------------------------------------------------

-- Cache for tracking map/level changes
Nx.Notes.HandyNotesLastMapId = nil
Nx.Notes.HandyNotesLastLevel = nil

-- Reusable temp frame for tooltip extraction (avoids garbage collection)
local handyTempFrame = nil

local function GetHandyTempFrame()
    if not handyTempFrame then
        handyTempFrame = CreateFrame("Frame", "CarbHandyTemp", UIParent)
    end
    return handyTempFrame
end

---
-- Update HandyNotes icons on the map
-- @param mapId  Current map ID
--
function Nx.Notes:HandyNotes(mapId)
    local map = Nx.Map:GetMap (1)
    if (Nx.fdb.profile.Notes.HandyNotes and HandyNotes) then
        local mapInfo = C_Map.GetMapInfo(mapId)
        if not mapInfo or mapInfo.mapType ~= 3 then
            return
        end

        local lvl = Nx.Map:GetCurrentMapDungeonLevel()

        -- Quick check: if map and level haven't changed, skip entirely
        local cacheKey = mapId .. "_" .. lvl
        if self.HandyNotesLastMapId == mapId and self.HandyNotesLastLevel == lvl then
            return -- Same map and level, skip
        end

        -- Map/level changed - clear and rebuild
        map:ClearIconType("!HANDY")
        self.HandyNotesLastMapId = mapId
        self.HandyNotesLastLevel = lvl

        map:InitIconType ("!HANDY", "WP", "", Nx.fdb.profile.Notes.HandyNotesSize or 15, Nx.fdb.profile.Notes.HandyNotesSize or 15)
        map:SetIconTypeChop ("!HANDY", true)
        map:SetIconTypeNoDockMinimap ("!HANDY", true)
        map:SetIconTypeLevel ("!HANDY", 20)

        -- Reuse temp frame instead of creating new ones
        local tempIcon = GetHandyTempFrame()
        local tmpFrame = WorldMapFrame:GetCanvas()
        tempIcon:SetParent(tmpFrame)

        for pluginName, pluginHandler in pairs(HandyNotes.plugins) do
            HandyNotes:UpdateWorldMapPlugin(pluginName)
            local pluginNodes, mapFile
            if type(pluginHandler.GetNodes) == "function" then
                mapFile = select(3, Nx.Map:GetLegacyMapInfo(mapId))
                pluginNodes = {pluginHandler:GetNodes(mapFile, false, lvl)}
            else
                pluginNodes = {pluginHandler:GetNodes2(mapId, false)}
            end
            Nx.pluginNodes = pluginNodes
            for coord, mapFile2, iconpath, scale, alpha, level2 in unpack(pluginNodes) do
                local x, y = floor(coord / 10000) / 100, (coord % 10000) / 100
                local texture
                local wx, wy = Nx.Map:GetWorldPos(mapId,x,y)
                local x1, x2, y1, y2
                if type(iconpath) == "table" then
                    texture = iconpath.icon
                    if iconpath.tCoordLeft then
                        x1 = iconpath.tCoordLeft
                        x2 = iconpath.tCoordRight
                        y1 = iconpath.tCoordTop
                        y2 = iconpath.tCoordBottom
                    end
                else
                    texture = iconpath
                end

                -- Reuse temp frame for tooltip extraction
                tempIcon:ClearAllPoints()
                tempIcon:SetHeight(scale or 15)
                tempIcon:SetWidth(scale or 15)
                tempIcon:SetPoint("CENTER", tmpFrame, "TOPLEFT", x*tmpFrame:GetWidth(), -y*tmpFrame:GetHeight())
                safecall(HandyNotes.plugins[pluginName].OnEnter, tempIcon, mapFile and mapFile or mapId, coord)

                local tooltip = ""
                local tooltipName = "GameTooltip"
                local handynote
                if x1 then
                    handynote = map:AddIconPt("!HANDY", wx, wy, level2, "FFFFFF", texture, x1, x2, y1, y2)
                else
                    handynote = map:AddIconPt("!HANDY", wx, wy, level2, "FFFFFF", texture)
                end
                for i = 1,10 do
                    local text = _G[tooltipName .. "TextLeft" .. i]
                    if text and text:IsShown() then
                        local R, G, B, A = text:GetTextColor()
                        R = Nx.Util_dec2hex(R * 255)
                        G = Nx.Util_dec2hex(G * 255)
                        B = Nx.Util_dec2hex(B * 255)
                        if strlen(tooltip) == 0 then
                            tooltip = "|cFF" .. R .. G .. B .. text:GetText()
                        else
                            tooltip = tooltip .. "\n" .. "|cFF" .. R .. G .. B .. text:GetText()
                        end
                    end
                end
                map:SetIconTip(handynote,tooltip)
                safecall(HandyNotes.plugins[pluginName].OnLeave, tempIcon, mapFile and mapFile or mapId, coord)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- RARESCANNER INTEGRATION
-- Display RareScanner pins on Carbonite map
-------------------------------------------------------------------------------

-- Cache for dirty detection
Nx.Notes.RSCache = Nx.Notes.RSCache or {}
Nx.Notes.RSLastMapId = nil
Nx.Notes.RSNeedsRefresh = true  -- Flag to track if we need to refresh WorldMapFrame

-- Hook WorldMapFrame OnHide to know when we need to refresh again
-- When user closes the Blizzard map, pins get cleared, so we need to re-populate
if not Nx.Notes.RSWorldMapHooked then
    Nx.Notes.RSWorldMapHooked = true
    WorldMapFrame:HookScript("OnHide", function()
        Nx.Notes.RSNeedsRefresh = true
        -- Clear cache so icons get rebuilt after user closes Blizzard map
        Nx.Notes.RSCache = {}
        Nx.Notes.PrevRSPins = 0
    end)
end

if not Nx.Notes.CriteriaUpdateHooked then
    Nx.Notes.CriteriaUpdateHooked = true
    CarboniteNotes:RegisterEvent("CRITERIA_EARNED", function(...) Nx.Notes:Update()
        Nx.Notes.RSNeedsRefresh = true
        -- Clear cache so icons get rebuilt after user closes Blizzard map
        Nx.Notes.RSCache = {}
        Nx.Notes.PrevRSPins = 0
    end)
end

---
-- Update RareScanner icons on the map
-- @param mapId  Current map ID
--
function Nx.Notes:RareScanner(mapId)
    local map = Nx.Map:GetMap (1)
    if (Nx.fdb.profile.Notes.RareScanner and RareScanner) then
        -- Refresh WorldMapFrame when needed (zone change or after Blizzard map was closed)
        -- Only refresh when Blizzard map is NOT shown to avoid flickering
        if self.RSNeedsRefresh or self.RSLastMapId ~= mapId then
            if not WorldMapFrame:IsShown() and not InCombatLockdown() then
                self.RSNeedsRefresh = false
                -- Refresh to populate RareScanner pins
                -- pcall: dataProviders may be nil if WorldMapFrame hasn't been shown yet
                pcall(function() WorldMapFrame:RefreshAll(true) end)
            end
        end

        -- Collect all pins and build a hash of their positions/data
        local rspins = {}
        local currentHash = 0

        for pin in WorldMapFrame:EnumeratePinsByTemplate("RSEntityPinTemplate") do
            rspins[#rspins + 1] = pin
            -- Hash includes position and mapID to detect any changes
            if pin.POI then
                currentHash = currentHash + (pin.normalizedX or 0) * 10000 + (pin.normalizedY or 0) * 100 + (pin.POI.mapID or 0)
            end
        end
        for pin in WorldMapFrame:EnumeratePinsByTemplate("RSOverlayTemplate") do
            rspins[#rspins + 1] = pin
            -- Hash overlay pins too
            if pin.pin and pin.pin.POI then
                currentHash = currentHash + (pin.normalizedX or 0) * 10000 + (pin.normalizedY or 0) * 100 + (pin.pin.POI.mapID or 0)
            end
        end

        -- Check if data actually changed (count + positions + map)
        local cacheKey = mapId .. "_RS"
        if self.RSCache[cacheKey] == currentHash and self.RSLastMapId == mapId and self.PrevRSPins == #rspins then
            return -- No changes, skip update
        end

        -- Data changed - clear old icons and rebuild
        map:ClearIconType("!RSR")
        self.RSCache[cacheKey] = currentHash
        self.RSLastMapId = mapId
        self.PrevRSPins = #rspins

        local level = nil

        map:InitIconType ("!RSR", "WP", "", Nx.fdb.profile.Notes.RareScannerSize or 32, Nx.fdb.profile.Notes.RareScannerSize or 32)
        map:SetIconTypeChop ("!RSR", true)
        map:SetIconTypeNoDockMinimap ("!RSR", true)
        map:SetIconTypeLevel ("!RSR", 20)

        for _,rspin in ipairs(rspins) do
            if rspin.POI then
                if rspin.POI.mapID == map.MapId and rspin.normalizedX and rspin.normalizedY then
                    local x = rspin.normalizedX * 100
                    local y = rspin.normalizedY * 100
                    local texture = rspin.Texture:GetTexture()
                    if not texture then
                        texture = rspin.pin and rspin.pin.POI and rspin.pin.POI.Texture
                    end
                    local wx, wy = Nx.Map:GetWorldPos(mapId,x,y)
                    local rsnote = map:AddIconPt("!RSR", wx, wy, level, "FFFFFF", texture)
                    local tooltip = rspin.POI.name
                    map:SetIconTip(rsnote,tooltip)
                    map:SetIconUserData(rsnote, rspin)
                end
            elseif rspin.pin and rspin.pin.POI then
                if rspin.pin.POI.mapID == map.MapId then
                    local x = rspin.normalizedX * 100
                    local y = rspin.normalizedY * 100
                    if (rspin.normalizedX ~= rspin.pin.normalizedX or rspin.normalizedY ~= rspin.pin.normalizedY) then
                        local texture = rspin.Texture:GetTexture()
                        local colr, colg, colb = rspin.Texture:GetVertexColor()
                        local color = "FFFFFF"
                        if colr and colg and colb then
                            local IconColor = CreateColor(colr, colg, colb)
                            color = IconColor:GenerateHexColor()
                        end
                        if not texture then
                            texture = rspin.pin.POI.Texture
                        end
                        local wx, wy = Nx.Map:GetWorldPos(mapId,x,y)
                        local rsnote = map:AddIconPt("!RSR", wx, wy, level, color, texture)
                        local tooltip = rspin.pin.POI.name
                        map:SetIconTip(rsnote,tooltip)
                        map:SetIconUserData(rsnote, rspin.pin)
                    end
                end
            end
        end
    end
end


-------------------------------------------------------------------------------
-- QUESTIE INTEGRATION
-- Display Questie quest objective pins on Carbonite map
-------------------------------------------------------------------------------

-- Cache for dirty detection
Nx.Notes.QuestieCache = Nx.Notes.QuestieCache or {}
Nx.Notes.QuestieLastMapId = nil

---
-- Update Questie icons on the map
-- @param mapId  Current map ID
--
function Nx.Notes:Questie(mapId)
    local map = Nx.Map:GetMap (1)

    if (Nx.fdb.profile.Notes.Questie and Questie) then
        -- Check if pin pool exists
        local pinPool = WorldMapFrame.pinPools and WorldMapFrame.pinPools["HereBeDragonsPinsTemplateQuestie"]
        if not pinPool then
            return
        end

        -- Collect pins and build hash of positions/data
        local questiePins = {}
        local currentHash = 0

        for pin in WorldMapFrame:EnumeratePinsByTemplate("HereBeDragonsPinsTemplateQuestie") do
            questiePins[#questiePins + 1] = pin
            -- Hash includes position, mapID, and quest data ID to detect any changes
            if pin.icon and pin.icon.data then
                local questId = pin.icon.data.QuestData and pin.icon.data.QuestData.Id or 0
                currentHash = currentHash + (pin.normalizedX or 0) * 10000 + (pin.normalizedY or 0) * 100 + questId
            end
        end

        -- Check if data actually changed (count + positions + quest data + map)
        local cacheKey = mapId .. "_QUE"
        if self.QuestieCache[cacheKey] == currentHash and self.QuestieLastMapId == mapId and self.PrevQuestiePins == #questiePins then
            return -- No changes, skip update
        end

        -- Data changed - clear old icons and rebuild
        map:ClearIconType("!QUE")
        self.QuestieCache[cacheKey] = currentHash
        self.QuestieLastMapId = mapId
        self.PrevQuestiePins = #questiePins

        local level = nil

        -- Cache settings lookup
        local showAvailable = Nx.fdb.profile.Notes.QuestieSE

        map:InitIconType ("!QUE", "WP", "", Nx.fdb.profile.Notes.QuestieSize or 32, Nx.fdb.profile.Notes.QuestieSize or 32)
        map:SetIconTypeChop ("!QUE", true)
        map:SetIconTypeNoDockMinimap ("!QUE", true)
        map:SetIconTypeLevel ("!QUE", 20)

        for _,questiePin in ipairs(questiePins) do
            local icon = questiePin.icon
            if icon and icon.UiMapID == map.MapId and icon.data and icon.data.QuestData then
                local dataType = icon.data.Type
                if (showAvailable and dataType == "available") or dataType == "monster" or dataType == "item" then
                    local x = questiePin.normalizedX * 100
                    local y = questiePin.normalizedY * 100
                    local texture = icon.texture and icon.texture:GetTexture()
                    local wx, wy = Nx.Map:GetWorldPos(mapId, x, y)
                    local qnote = map:AddIconPt("!QUE", wx, wy, level, "FFFFFF", texture)
                    map:SetIconUserData(qnote, questiePin)
                end
            end
        end
    end
end


-------------------------------------------------------------------------------
-- BUTTON AND MENU HANDLERS
-------------------------------------------------------------------------------

function Nx.Notes:OnButToggleFav(but)
    Nx.Notes:ToggleShow()
end

-------------------------------------------------------------------------------
-- DATA ACCESS
-------------------------------------------------------------------------------

---
-- Get the favorites data table
-- @return  Favorites/notes profile data
--
function Nx:GetFav()
    return Nx.fdb.profile.Notes
end

---
-- Menu handler to add a note at click location
--
function Nx.Notes:Menu_OnAddNote()
    local map = Nx.Map:GetMap(1)
    local mId = map.RMapId
    local wx, wy = self:FramePosToWorldPos(self.ClickFrmX, self.ClickFrmY)
    local zx, zy = self:GetZonePos(mId, wx, wy)
    local level = map.DungeonLevel
    Nx.Notes:AddNote("?", mId, zx, zy, level)
end

---
-- Add a note at the specified location
-- @param name   Note name
-- @param id     Map ID
-- @param x      X coordinate
-- @param y      Y coordinate
-- @param level  Dungeon level (optional)
--
function Nx.Notes:AddNote(name, id, x, y, level)
    Nx.Notes:Record("Note", name, id, x, y, level)
end

---
-- Register a note from another addon
-- @param folder  Folder name for the addon
-- @param name    Note name
-- @param icon    Icon index
-- @param id      Map ID
-- @param x       X coordinate
-- @param y       Y coordinate
--
function Nx.Notes:AddonNote(folder, name, icon, id, x, y)
    if not addonNotes[folder] then
        addonNotes[folder] = {}
        addonNotes[folder]["notes"] = {}
    end
    addonNotes[folder]["notes"][name] = icon .. "|" .. id .. "|" .. x .. "|" .. y
end

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------
