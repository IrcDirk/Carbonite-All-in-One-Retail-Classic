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
-- Commit: 2019-08-20 08:10:08 +0200 (436eed1)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- INITIALIZATION
-- Core addon setup using Ace3 framework
-------------------------------------------------------------------------------

local _G = getfenv(0)

-- The new Core/Bootstrap.lua may have already created the Carbonite
-- AceAddon and aliased it as Nx. If so, reuse it; otherwise create
-- it the old way for unmigrated load orders.
local AceAddon = LibStub("AceAddon-3.0")
Nx = AceAddon:GetAddon("Carbonite", true)
if not Nx then
    Nx = AceAddon:NewAddon("Carbonite","AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0", "AceComm-3.0")
    _G.Nx = Nx
end
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-------------------------------------------------------------------------------
-- VERSION INFORMATION
-- Version numbers used for data migration and compatibility checks
-------------------------------------------------------------------------------

Nx.WebSite = "wowinterface.com"
NXTITLEFULL = L["Carbonite"]

-- Main version numbers
Nx.VERMAJOR             = 113
Nx.VERMINOR             = .0                -- Non-zero indicates test version
Nx.BUILD                = "436eed1"
if Nx.BUILD:find("Format:%h", 1, true) then Nx.BUILD = string.sub("581", 0, 7) end
if Nx.BUILD:find("project-revision", 1, true) then Nx.BUILD = "0" end

Nx.VERSION              = Nx.VERMAJOR + Nx.VERMINOR / 100

-- Data structure version numbers (used for migration/reset on version change)
Nx.VERSIONDATA          = .02               -- Main data format
Nx.VERSIONCHAR          = .02               -- Character data format
Nx.VERSIONCharData      = .4                -- Character-specific saved data
Nx.VERSIONGATHER        = .9                -- Gathered node data (herbs/mines)
Nx.VERSIONGOPTS         = .102              -- Global options
Nx.VERSIONHUDOPTS       = .03               -- HUD options
Nx.VERSIONList          = .1                -- List header data
Nx.VERSIONTaxiCap       = .5                -- Taxi capture data
Nx.VERSIONTRAVEL        = .5                -- Travel data
Nx.VERSIONWin           = .31               -- Window layouts
Nx.VERSIONTOOLBAR       = .1                -- Tool Bar data
Nx.VERSIONCAP           = .75               -- Captured data (quest recording)
Nx.VERSIONVENDORV       = .56               -- Visited vendor data
Nx.VERSIONTransferData  = .1                -- Transfer data

-- Color codes for formatted text
Nx.TXTBLUE              = "|cffc0c0ff"

-------------------------------------------------------------------------------
-- KEYBINDING DEFINITIONS
-- Localized names for keybindable actions
-------------------------------------------------------------------------------

BINDING_HEADER_Carbonite        = "|cffc0c0ff" .. L["Carbonite"] .. "|r"
BINDING_NAME_NxMAPTOGORIGINAL   = L["NxMAPTOGORIGINAL"]
BINDING_NAME_NxMAPTOGNORMMAX    = L["NxMAPTOGNORMMAX"]
BINDING_NAME_NxMAPTOGNONEMAX    = L["NxMAPTOGNONEMAX"]
BINDING_NAME_NxMAPTOGNONENORM   = L["NxMAPTOGNONENORM"]
BINDING_NAME_NxMAPSCALERESTORE  = L["NxMAPSCALERESTORE"]
BINDING_NAME_NxMAPTOGMINIFULL   = L["NxMAPTOGMINIFULL"]
BINDING_NAME_NxMAPTOGHERB       = L["NxMAPTOGHERB"]
BINDING_NAME_NxMAPTOGMINE       = L["NxMAPTOGMINE"]
BINDING_NAME_NxTOGGLEGUIDE      = L["NxTOGGLEGUIDE"]
BINDING_NAME_NxMAPSKIPTARGET    = L["NxMAPSKIPTARGET"]

-------------------------------------------------------------------------------
-- GAME VERSION DETECTION
-- Flags for different WoW client versions
-------------------------------------------------------------------------------

Nx.isClassic      = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)
Nx.isClassicEra   = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
Nx.isTBCClassic   = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
Nx.isWotlkClassic = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
Nx.isCataClassic  = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
Nx.isMoPClassic   = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
Nx.isRetail       = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

Nx.OldMapIDs  = select(4, GetBuildInfo()) < 49999

Nx.TBCMaps    = select(4, GetBuildInfo()) > 19999
Nx.WOTLKMaps  = select(4, GetBuildInfo()) > 29999
Nx.CataMaps   = select(4, GetBuildInfo()) > 39999
Nx.MOPMaps    = select(4, GetBuildInfo()) > 49999
Nx.WODMaps    = select(4, GetBuildInfo()) > 59999
Nx.LegionMaps = select(4, GetBuildInfo()) > 69999
Nx.BFAMaps    = select(4, GetBuildInfo()) > 79999
Nx.SLMaps     = select(4, GetBuildInfo()) > 89999
Nx.DFMaps     = select(4, GetBuildInfo()) > 99999
Nx.TWWMaps    = select(4, GetBuildInfo()) > 109999
Nx.MidMaps    = select(4, GetBuildInfo()) > 119999

Nx.BlobsAvailable = select(4, GetBuildInfo()) > 39999
Nx.OldRidingSkill = select(4, GetBuildInfo()) < 40000
Nx.MaxPlayerLevel = GetMaxLevelForExpansionLevel(LE_EXPANSION_LEVEL_CURRENT)

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded

-- Nx:GetMaxGatherSkill, Nx:ShouldShowGatherNode and
-- Nx:GetGatherNodeName were extracted into
-- Modules/Gather/GatherEngine.lua. Compat/Expansion.lua is now the
-- canonical source for the per-flavor skill cap.

-------------------------------------------------------------------------------
-- GLOBAL STATE VARIABLES
-------------------------------------------------------------------------------

-- Frame update counter
Nx.Tick = 0

-- Battleground combat statistics
Nx.Combat = {
    ["KBs"] = 0,        -- Killing blows
    ["Deaths"] = 0,     -- Deaths
    ["HKs"] = 0,        -- Honorable kills
    ["Honor"] = 0,      -- Honor earned
    ["DamDone"] = 0,    -- Damage done
    ["HealDone"] = 0,   -- Healing done
}

-------------------------------------------------------------------------------
-- MODULE NAMESPACES
-- Empty tables to be populated by respective modules
-------------------------------------------------------------------------------

-- UI Components
Nx.Font = {}
Nx.Skin = {}
Nx.Window = {}
Nx.Menu = {}
Nx.MenuI = {}
Nx.List = {}
Nx.DropDown = {}
Nx.Button = {}
Nx.EditBox = {}
Nx.Graph = {}
Nx.Slider = {}
Nx.TabBar = {}
Nx.ToolBar = {}

-- Processing and scripting
Nx.Proc = {}
Nx.Script = {}

-- Logo texture path
Nx.Logo = "Interface\\AddOns\\Carbonite\\Gfx\\Carbonite"

-- Options module
Nx.Opts = {}

-- Communication module
Nx.Com = {}
Nx.Com.List = {}

-- Heads-up display
Nx.HUD = {}

-- Map module (main functionality)
Nx.Map = {}
Nx.Map.Dock = {}
Nx.Map.Guide = {}
Nx.Map.Guide.PlayerTargets = {}

-- Travel/taxi system
Nx.Travel = {}

-- Title screen animation
Nx.Title = {}

-- Auction house assistant
Nx.AuctionAssist = {}

-- User events tracking
Nx.UEvents = {}
Nx.UEvents.List = {}

-------------------------------------------------------------------------------
-- RUNTIME FLAGS
-- State tracking variables
-------------------------------------------------------------------------------

Nx.DebugOn = false          -- Debug output enabled
Nx.NetSendPos = false       -- Network position sending enabled
Nx.NetPlyrSendTime = GetTime()  -- Last network send timestamp

Nx.GroupMembers = {}        -- Current group member cache

Nx.Item = {}                -- Item management module

Nx.NXMiniMapBut = {}        -- Minimap button handler

Nx.db = {}                  -- Main database reference
Nx.dbs = {}                 -- Database array for multi-profile support

Nx.ModuleUpdateIcon = {"test"}
Nx.RequestTime = false      -- Time played request pending
Nx.FirstTry = true          -- First initialization attempt
Nx.Loaded = false           -- Addon files loaded
Nx.Initialized = false      -- Full initialization complete
Nx.RealTom = false          -- Real TomTom addon detected
Nx.PlayerFnd = false        -- Player unit found
Nx.ModQAction = ""          -- Module quest action
Nx.ModPAction = ""          -- Module player action
Nx.GlowOn = false           -- Minimap button glow state

-------------------------------------------------------------------------------
-- WHAT'S NEW SYSTEM
-- Displays version history and update notes to users
-------------------------------------------------------------------------------

-- Whatsnew data + window methods were extracted into
-- Modules/Whatsnew/WhatsnewEngine.lua. Nx.Whatsnew is populated
-- by that file at load time.

-- Nx.EmulateTomTom is provided by Modules/Integrations/TomTom.lua,
-- which exposes a fuller surface (ClearAllWaypoints,
-- GetCurrentPlayerPosition, /way / /cway / /wayb slash commands,
-- etc.) and aliases Nx.EmulateTomTom on CARBONITE_LOADED. The old
-- 30-line stub here that just registered AddWaypoint /
-- AddZWaypoint / SetCustomWaypoint / SetCrazyArrow and the /way +
-- /cbway slash commands has been removed in favour of that
-- integration module.

local defaults = {
    char = {
        Map = {
            ShowGatherA = false,
            ShowGatherH = false,
            ShowGatherM = false,
            ShowGatherL = false,
            ShowClassTrainer = false,
            ShowProfessionTrainer = false,
            ShowQuestGivers = 1,
            ShowContPois = true,
            ShowMailboxes = true,
            ShowRaidBoss = true,
            ShowWorldQuest = true,
            ShowCustom = true,
            ShowCCity = false,
            ShowCExtra = true,
            ShowCTown = false,
            ShowArchBlobs = true,
            ShowQuestBlobs = true,
        },
    },
    global = {
       Characters = {},
    },
    profile = {
        Battleground = {
            ShowStats = true
        },
        General = {
            CameraForceMaxDist = false,
            CaptureEnable = false,
            CaptureShare = true,
            ChatMsgFrm = "",
            GryphonsHide = true,
            LoginHideVer = true,
            TitleOff = true,
            TitleSoundOn = false,
        },
        Guide = {
            VendorVMax = 60,
            GatherEnabled = true,
            ShowMines = {
                [1] = true,
                [2] = true,
                [3] = true,
                [4] = true,
                [5] = true,
                [6] = true,
                [7] = true,
                [8] = true,
                [9] = true,
                [10] = true,
                [11] = true,
                [12] = true,
                [13] = true,
                [14] = true,
                [15] = true,
                [16] = true,
                [17] = true,
                [18] = true,
                [19] = true,
                [20] = true,
                [21] = true,
                [22] = true,
                [23] = true,
                [24] = true,
                [25] = true,
                [26] = true,
                [27] = true,
                [28] = true,
                [29] = true,
                [30] = true,
                [31] = true,
                [32] = true,
                [33] = true,
                [34] = true,
                [35] = true,
                [36] = true,
                [37] = true,
                [38] = true,
                [39] = true,
                [40] = true,
                [41] = true,
                [42] = true,
                [43] = true,
                [44] = true,
                [45] = true,
                [46] = true,
                [47] = true,
                [48] = true,
                [49] = true,
                [50] = true,
                [51] = true,
                [52] = true,
                [53] = true,
                [54] = true,
                [55] = true,
                [56] = true,
                [57] = true,
                [58] = true,
                [59] = true,
                [60] = true,
                [61] = true,
                [62] = true,
                [63] = true,
                [64] = true,
                [65] = true,
                [66] = true,
                [67] = true,
                [68] = true,
                [69] = true,
                [70] = true,
                [71] = true,
                [72] = true,
                [73] = true,
                [74] = true,
                [75] = true,
                [76] = true,
                [77] = true,
                [78] = true,
                [79] = true,
                [80] = true,
                [81] = true,
                [82] = true,
                [83] = true,
                [84] = true,
                [85] = true,
                [86] = true,
                [87] = true,
                [88] = true,
                [89] = true,
                [90] = true,
                [91] = true,
                [92] = true,
                [93] = true,
                [94] = true,
                [95] = true,
                [96] = true,
                [97] = true,
                [98] = true,
                [99] = true,
                [100] = true,
                [101] = true,
                [102] = true,
                [103] = true,
                [104] = true,
                [105] = true,
                [106] = true,
                [107] = true,
                [108] = true,
                [109] = true,
                [110] = true,
                [111] = true,
                [112] = true,
                [113] = true,
                [114] = true,
                [115] = true,
                [116] = true,
                [117] = true,
                [118] = true,
                [119] = true,
                [120] = true,
            },
            ShowHerbs = {
                [1] = true,
                [2] = true,
                [3] = true,
                [4] = true,
                [5] = true,
                [6] = true,
                [7] = true,
                [8] = true,
                [9] = true,
                [10] = true,
                [11] = true,
                [12] = true,
                [13] = true,
                [14] = true,
                [15] = true,
                [16] = true,
                [17] = true,
                [18] = true,
                [19] = true,
                [20] = true,
                [21] = true,
                [22] = true,
                [23] = true,
                [24] = true,
                [25] = true,
                [26] = true,
                [27] = true,
                [28] = true,
                [29] = true,
                [30] = true,
                [31] = true,
                [32] = true,
                [33] = true,
                [34] = true,
                [35] = true,
                [36] = true,
                [37] = true,
                [38] = true,
                [39] = true,
                [40] = true,
                [41] = true,
                [42] = true,
                [43] = true,
                [44] = true,
                [45] = true,
                [46] = true,
                [47] = true,
                [48] = true,
                [49] = true,
                [50] = true,
                [51] = true,
                [52] = true,
                [53] = true,
                [54] = true,
                [55] = true,
                [56] = true,
                [57] = true,
                [58] = true,
                [59] = true,
                [60] = true,
                [61] = true,
                [62] = true,
                [63] = true,
                [64] = true,
                [65] = true,
                [66] = true,
                [67] = true,
                [68] = true,
                [69] = true,
                [70] = true,
                [71] = true,
                [72] = true,
                [73] = true,
                [74] = true,
                [75] = true,
                [76] = true,
                [77] = true,
                [78] = true,
                [79] = true,
                [80] = true,
                [81] = true,
                [82] = true,
                [83] = true,
                [84] = true,
                [85] = true,
                [86] = true,
                [87] = true,
                [88] = true,
                [89] = true,
                [90] = true,
                [91] = true,
                [92] = true,
                [93] = true,
                [94] = true,
                [95] = true,
                [96] = true,
                [97] = true,
                [98] = true,
                [99] = true,
                [100] = true,
                [101] = true,
                [102] = true,
                [103] = true,
                [104] = true,
                [105] = true,
                [106] = true,
                [107] = true,
                [108] = true,
                [109] = true,
                [110] = true,
                [111] = true,
                [112] = true,
                [113] = true,
                [114] = true,
                [115] = true,
                [116] = true,
                [117] = true,
                [118] = true,
                [119] = true,
                [120] = true,
                [121] = true,
                [122] = true,
                [123] = true,
                [124] = true,
                [125] = true,
                [126] = true,
                [127] = true,
            },
            ShowTimber = {
                [1] = true,
                [2] = true,
                [3] = true,
            },
        },
        Comm = {
            Global = true,
            Zone = true,
            LvlUpShow = true,
            SendToFriends = true,
            SendToGuild = true,
            SendToZone = true,
        },
        Debug = {
          VerDebug = false,
          VerT = 0,
          DebugMap = false,
          DebugDock = false,
          DBGather = false,
          DBMapMax = false,
          DebugCom = false,
          DebugUnit = false,
        },
        Font = {
            Small = "Friz",
            SmallSize = 10,
            SmallSpacing = 0,
            Medium = "Friz",
            MediumSize = 12,
            MediumSpacing = 0,
            Map = "Friz",
            MapSize = 10,
            MapSpacing = 0,
            MapLoc = "Friz",
            MapLocSize = 10,
            MapLocSpacing = 0,
            Menu = "Friz",
            MenuSize = 10,
            MenuSpacing = 0,
        },
        Skin = {
          Name = "",
          WinBdColor = ".8|.8|1|1",
          WinFixedBgColor = ".5|.5|.5|.5",
          WinSizedBgColor = ".121|.121|.121|.88",
        },
        Map = {
            ButLAlt = L["None"],
            ButLCtrl = L["Goto"],
            ButM = L["Show Player Zone"],
            ButMAlt = L["None"],
            ButMCtrl = L["None"],
            ButR = L["Menu"],
            ButRAlt = L["None"],
            ButRCtrl = L["None"],
            But4 = L["Show Selected Zone"],
            But4Alt = L["Add Note"],
            But4Ctrl = L["None"],
            Compatibility = false,
            DetailSize = 6,
            IconPOIAlpha = 1,
            IconGatherA = 0.7,
            IconGatherAtScale = 0.5,
            LineThick = 1.0,
            LocTipAnchor = "TopRight",
            LocTipAnchorRel = "None",
            MaxCenter = true,
            MaxMouseIgnore = false,
            MaxOverride = true,
            MaxRestoreHide = false,
            MouseIgnore = false,
            PlyrArrowSize = 32,
            RestoreScaleAfterTrack = true,
            RouteUse = true,
            TopTooltip = false,
            IconScaleMin = 1,
            ShowOthersInCities = true,
            ShowOthersInZone = true,
            ShowPalsInCities = true,
            ShowPOI = true,
            ShowTitleName = true,
            ShowTitleXY = true,
            ShowTitleSpeed = true,
            ShowTitle2 = false,
            ShowToolBar = true,
            ShowTrail = true,
            TakeFunctions = false,
            TrailCnt = 100,
            TrailDist = 2,
            TrailTime = 90,
            WOwn = false,
            ZoneDrawCnt = 3,
            InstanceBossSize = 32,
            InstancePlayerSize = 24,
            InstanceGroupSize = 24,
            InstanceScale = 16,
            mapUpdate = .05,
            UseLocaleTextures = false,  -- Use locale-specific compressed overlay textures (Conv/locale/)
        },
        MiniMap = {
            AboveIcons = false,
            ButColumns = 1,
            ButCorner = "TopRight",
            ButOwn = false,
            ButShowCarb = true,
            ButHide = false,
            ButLock = false,
            ButShowCalendar = true,
            ButShowClock = true,
            ButShowWorldMap = true,
            ButShowLFG = true,
            ButSpacing = 29,
            ButWinMinimize = false,
            DockHigh = "",
            DockAlways = false,
            DockBugged = true,
            DockIndoors = true,
            DockOnMax = false,
            DockSquare = true,
            DockBottom = false,
            DockRight = false,
            DockIScale = 1,
            DockZoom = 0,
            DXO = 0,
            DYO = 0,
            HideOnMax = false,
            InstanceTogFullSize = false,
            IndoorTogFullSize = false,
            BuggedTogFullSize = false,
            IScale = 1,
            MoveCapBars = true,
            NodeGD = 0,
            Own = false,
            ShowOldNameplate = true,
            Square = false,
        },
        Menu = {
            CenterH = false,
            CenterV = false,
            UseMenuUtil = (MenuUtil and MenuUtil.CreateContextMenu) and true or false,  -- Route simple menus through Blizzard MenuUtil for native dropdown look (retail / Cata+ Classic)
        },
        Route = {
            GatherRadius = 60,
            MergeRadius = 20,
            Recycle = false,
        },
        Track = {
            EmuTomTom = true,
            Hide = false,
            HideInBG = false,
            ShowDir = false,
            Lock = false,
            AGfx = "Gloss",
            ASize = 44,
            AXO = 0,
            AYO = 0,
            TBut = true,
            TButColor = "0|0|0|.101",
            TButCombatColor = "1|0|0|.101",
            TSoundOn = true,
            ATBGPal = true,
            ATCorpse = true,
            ATTaxi = true,
        },
        Version = {
            OptionsVersion = 0,
        },
        WinSettings = {
        },
        Whatsnew = {
            lastreadtime = 0,
        },
   },
}

Nx.BrokerMenuTemplate = {
    { text = "Carbonite", icon = icon, isTitle = true },
    { text = L["Options"], func = function() Nx.Opts:Open() end },
    { text = L["Toggle Map"], func = function() Nx.Map:ToggleSize(0) end },
    { text = L["Toggle Events"], func = function() Nx.UEvents.List:Open() end },
}

-- Create dropdown frame for Classic/old retail (UIDropDownMenuTemplate doesn't exist in 11.0+)
local menuFrame
if Nx.isRetail then
    -- Retail 11.0+ uses new menu system
    menuFrame = nil
else
    menuFrame = CreateFrame("Frame", "CarboniteMenuFrame", UIParent, "UIDropDownMenuTemplate")
end

-- Helper function to show context menu (compatible with both old and new systems)
local function ShowBrokerMenu(ownerRegion)
    if MenuUtil and MenuUtil.CreateContextMenu then
        -- Retail 11.0+ new menu system
        MenuUtil.CreateContextMenu(ownerRegion, function(ownerRegion, rootDescription)
            rootDescription:CreateTitle("Carbonite")
            rootDescription:CreateButton(L["Options"], function() Nx.Opts:Open() end)
            rootDescription:CreateButton(L["Toggle Map"], function() Nx.Map:ToggleSize(0) end)
            rootDescription:CreateButton(L["Toggle Events"], function() Nx.UEvents.List:Open() end)
        end)
    elseif EasyMenu then
        -- Classic/old retail
        EasyMenu(Nx.BrokerMenuTemplate, menuFrame, "cursor", 0, 0, "MENU")
    end
end

Nx.Broker = LibStub("LibDataBroker-1.1"):NewDataObject("Broker_Carbonite", {
    type = "data source",
    icon = "Interface\\AddOns\\Carbonite\\Gfx\\MMBut",
    label = "Carbonite",
    text = "Carbonite",
    OnTooltipShow = function(tooltip)
                        if not tooltip or not tooltip.AddLine then return end
                        tooltip:AddLine("Carbonite")
                        tooltip:AddLine(L["Left-Click to Toggle Map"])
                        if Nx.db.profile.MiniMap.ButOwn then
                            tooltip:AddLine(L["Shift Left-Click to Toggle Minimize"])
                        end
                        tooltip:AddLine(L["Middle-Click to Toggle Guide"])
                        tooltip:AddLine(L["Right-Click for Menu"])
                    end,
    OnClick = function(frame, msg)
                if msg == "LeftButton" then
                    if (IsShiftKeyDown()) then
                        Nx.db.profile.MiniMap.ButWinMinimize = not Nx.db.profile.MiniMap.ButWinMinimize
                        Nx.Map.Dock:UpdateOptions()
                    else
                        Nx.Map:ToggleSize(0)
                    end
                elseif msg == "MiddleButton" then
                    Nx.Map:GetMap(1).Guide:ToggleShow()
                elseif msg == "RightButton" then
                    ShowBrokerMenu(frame)
                end
            end,
})

function Nx:OnInitialize()
    local ver = GetBuildInfo()
    local v1, v2, v3 = Nx.Split (".", ver)
    v1 = tonumber (v1) or 0
    v2 = tonumber (v2) or 0
    v3 = tonumber (v3) or 0
    ver = v1 * 10000 + v2 * 100 + v3

    Nx.V30 = true

    if ver < 10000 or ver >= 40003 then        -- Patch 4
        Nx.V403 = true
    end

    if ver > 10000 and ver < 50000 then        -- Old?
        --local s = "|cffff2020" .. L["Carbonite requires v5.0 or higher"]
        --DEFAULT_CHAT_FRAME:AddMessage (s)
        --UIErrorsFrame:AddMessage (s)
        Nx.NXVerOld = true
    end
    Nx.TooltipLastDiffNumLines = 0
    Nx.db = LibStub("AceDB-3.0"):New("CarbData", defaults, true)
    tinsert(Nx.dbs,Nx.db)
    Nx.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    Nx.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    Nx.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    Nx.SetupConfig()
    Nx:RegisterComm("carbmodule",Nx.ModChatReceive)
end

function Nx:OnProfileChanged(event, database, newProfileKey)
    if not Nx.db.profile.MapSettings then
        Nx.db:RegisterDefaults(defaults)
        Nx.db.profile.MapSettings = NxMapOptsDefaults
        Nx.db.profile.MapSettings.Maps = NXMapOptsMapsDefault
    end
    Nx.db.profile.Version.OptionsVersion = Nx.VERSIONGOPTS
    Nx.Map:VerifySettings()
    Nx.Opts.NXCmdReload()
end

function Nx:OnEnable()
end

function Nx:OnDisable()
end
-------------------------------------------------------------------------------
-- SLASH COMMAND HANDLER
-- Parses /carb command and subcommands
-------------------------------------------------------------------------------

---
-- Parse and execute slash commands
-- @param txt  Command string following /carb
--
function Nx.slashCommand (txt)

    local UEvents = Nx.UEvents
    local cmd, a1, a2 = Nx.Split (" ", txt)
    cmd = strlower (cmd)

    a1 = a1 or ""
    a2 = a2 or ""

    if cmd == "" or cmd == "?" or cmd == "help" then

        Nx.prt ("Commands:")
        Nx.prt (" editmode  (toggle quest objective rectangle editor)")
        Nx.prt (" goto [zone] x y  (set map goto)")
        Nx.prt (" gotoadd [zone] x y  (add map goto)")
        Nx.prt (" menu  (open menu)")
        Nx.prt (" note [\"]name[\"] [zone] [x y]  (make map note)")
        Nx.prt (" options  (open options window)")
        Nx.prt (" resetwin  (reset window layouts)")
        Nx.prt (" rl  (reload UI)")
        Nx.prt (" track name  (track the player)")
        Nx.prt (" winpos name x y  (position a window)")
        Nx.prt (" winshow name [0/1]  (toggle or show a window)")
        Nx.prt (" winsize name w h  (size a window)")

    elseif cmd == "goto" then
        local map = Nx.Map:GetMap (1)
        local s = gsub (txt, "goto%s*", "")
        map:SetTargetAtStr (s)

    elseif cmd == "gotoadd" then
        local map = Nx.Map:GetMap (1)
        local s = gsub (txt, "gotoadd %s*", "")
        map:SetTargetAtStr (s, true)

    elseif cmd == "menu" then
        Nx.NXMiniMapBut:OpenMenu()

    elseif cmd == "options" then
        Nx.Opts:Open()

    elseif cmd == "resetwin" then
        Nx.Window:ResetLayouts()

    elseif cmd == "rl" then
        ReloadUI()

    elseif cmd == "track" then
        if a1 then
            local map = Nx.Map:GetMap (1)
            map.TrackPlyrs[a1] = true
        end

    elseif cmd == "winpos" then
        Nx.Window:ConsolePos (gsub (txt, "winpos %s*", ""))

    elseif cmd == "winshow" then
        Nx.Window:ConsoleShow (gsub (txt, "winshow %s*", ""))

    elseif cmd == "winsize" then
        Nx.Window:ConsoleSize (gsub (txt, "winsize %s*", ""))

    elseif cmd == "gatherd" then
        Nx.db.profile.Debug.DBGather = not Nx.db.profile.Debug.DBGather

    elseif cmd == "herb" then
        UEvents:AddHerb (strtrim (a1 .. " " .. a2))

    elseif cmd == "dbmapmax" then
        Nx.db.profile.Debug.DBMapMax = not Nx.db.profile.Debug.DBMapMax

    elseif cmd == "mine" then
        UEvents:AddMine (strtrim (a1 .. " " .. a2))

    elseif cmd == "addopen" then
        UEvents:AddOpen (a1, a2)

    elseif cmd == "cap" then
        Nx.CaptureItems()

    elseif cmd == "crash" then
        assert()

    elseif cmd == "com" then
        Nx.Com.List:Open()

    elseif cmd == "comd" then
        Nx.db.profile.Debug.DebugCom = not Nx.db.profile.Debug.DebugCom
        ReloadUI()

    elseif cmd == "comt" then
        Nx.Com:Test (a1, a2)

    elseif cmd == "comver" then
        if Nx.db.profile.Debug.VerDebug then        -- Stop casual use
            Nx.Com:GetUserVer()
        end

    elseif cmd == "d" then
        Nx.DebugOn = not Nx.DebugOn
        Nx.prt("Carbonite Debug: %s", Nx.DebugOn and "On" or "Off")

    elseif cmd == "dock" then
        Nx.db.profile.Debug.DebugDock = not Nx.db.profile.Debug.DebugDock

    elseif cmd == "events" then
        UEvents.List:Open()

    elseif cmd == "item" then
        local id = format ("Hitem:%s", a1)
        Nx.TooltipText:SetOwner (UIParent, "ANCHOR_LEFT", 0, 0)
        Nx.TooltipText:SetHyperlink (id)
        local name, iLink, iRarity, lvl, minLvl, type, subType, stackCount, equipLoc, tx = C_Item.GetItemInfo (id)
        Nx.prt ("Item: %s %s", name or "nil", iLink or "")

    elseif cmd == "kill" then
        UEvents:AddKill (a1)

    elseif cmd == "loot" then
        Nx.LootOn = not Nx.LootOn
        Nx.prt ("Loot %s", Nx.LootOn and "On" or "Off")

    elseif cmd == "mapd" then
        Nx.db.profile.Debug.DebugMap = not Nx.db.profile.Debug.DebugMap
        ReloadUI()

    elseif cmd == "questclr" then
        Nx.Quest:ClearCaptured()

    elseif cmd == "unitc" then
        Nx.db.profile.Debug.DebugUnit = true
        Nx:UnitDCapture()

    elseif cmd == "unitd" then
        Nx.db.profile.Debug.DebugUnit = not Nx.db.profile.Debug.DebugUnit

    elseif cmd == "vehpos" then
        Nx.Map:GetMap (1):VehicleDumpPos()

    elseif cmd == "editmode" then
        Nx.Map:GetMap(1):ToggleEditMode()

    else
        local s = gsub (txt, "note%s*", "")
        Nx:SendCommMessage("carbmodule","CMD|" .. cmd .. "|" .. s,"WHISPER",UnitName("player"))
    end
end

-------------------------------------------------------------------------------
-- ADDON STARTUP
-- Initial loading and event registration
-------------------------------------------------------------------------------

---
-- Called when the addon frame is created
-- Registers slash commands and initial events
-- @param frm  The addon's main frame
--
function Nx:NXOnLoad (frm)

    SlashCmdList["Carbonite"] = Nx.slashCommand
    SLASH_Carbonite1 = "/Carb"

    self.Frm = frm        --V4 this
    self.TimeLast = 0
    self.ClassColorStrs = Nx.Util_coltrgb2colstr (RAID_CLASS_COLORS)

    Nx:RegisterEvent ("ADDON_LOADED")
    Nx:RegisterEvent ("UNIT_NAME_UPDATE")
    Nx:RegisterEvent ("PLAYER_ENTERING_WORLD", "UNIT_NAME_UPDATE")
    Nx.CalendarDate = 0        -- For safety if Map update happens early
end

---
-- Main initialization function
-- Sets up all modules and UI components after player is detected
-- Called when addon is loaded, player exists, and not in combat
--
function Nx:SetupEverything()

    if not Nx.FirstTry then
        return
    end
    Nx.FirstTry = false
    local fact = UnitFactionGroup ("player")
    Nx.PlFactionNum = strsub (fact, 1, 1) == "A" and 0 or 1

    Nx.AirshipType = Nx.PlFactionNum == 0 and "Airship Alliance" or "Airship Horde"

    Nx:InitGlobal()

    Nx:prtSetChatFrame()

    if Nx.db.profile.General.LoginHideVer then
        Nx.prt (L["Carbonite"].." |cffffffff"..Nx.VERMAJOR.."."..(Nx.VERMINOR*10).." Build "..Nx.BUILD.." ".. L["Loading"])
    end

    Nx:LocaleInit()

    Nx:InitEvents()

    Nx.Opts:Init()

    Nx:UIInit()
    Nx.Item:Init()
    Nx.Proc:Init()
    Nx.Title:Init()
    Nx.NXMiniMapBut:Init()

    Nx.Com:Init()
    Nx.HUD:Init()
    Nx.Map:Init()

    Nx:GatherInit()        -- Needs map init. May need to do before map open

    Nx.Map:Open()
    Nx.Travel:Init()

    Nx.UEvents:Init()
    Nx.UEvents.List:Open()

    if Nx.db.profile.General.LoginHideVer then
        Nx.prt (L["Loading Done"])
    end
    if Nx.Font.AddonLoaded then
        Nx.Font:AddonLoaded()
    end

    ShowUIPanel(WorldMapFrame)
    HideUIPanel(WorldMapFrame)

    if Nx.db.profile.Map.MaxOverride then Nx.Map:ToggleSize() end

    Nx.Initialized = true
    Nx:OnPlayer_login("PLAYER_LOGIN")

    -- Adding support for Zygor Waypoint system
    if ZGV and ZGV.Pointer then
        hooksecurefunc(ZGV.Pointer, "SetWaypoint", function (e, m, x, y, data, arrow)
            local map = Nx.Map:GetMap (1)
            if not m then
                if WorldMapFrame:IsShown() then m=WorldMapFrame:GetMapID() else m=C_Map.GetBestMapForUnit("player") end
            end

            x = x or 0;
            y = y or 0;

            local wx, wy = map:GetWorldPos (m, x*100, y*100)
            local title = (ZGV.CurrentStep and ZGV.CurrentStep.current_waypoint_goal_num and ZGV.CurrentStep.goals) and ZGV.CurrentStep.goals[ZGV.CurrentStep.current_waypoint_goal_num]:GetText() or ""

            if ZygorGuidesViewerFrame:IsVisible() then
                map:SetTarget ("Goto", wx, wy, wx, wy, nil, nil, title or "Zygor Waypoint (check step in Zygor Guide Viewer)", nil, m)
            end

            return waypoint
        end)
    end

    --GuildControlPopupFrame.initialized = 1
end

---
-- Handle ADDON_LOADED event
-- Marks addon as loaded
--
function Nx:ADDON_LOADED (event, arg1, ...)
    Nx.Loaded = true
    CarbMigr = {}
end

---
-- Handle UNIT_NAME_UPDATE event
-- Called when player name becomes available; enables TomTom emulation
--
function Nx:UNIT_NAME_UPDATE (event, arg1, ...)
    Nx.PlayerFnd = true

    if _G.TomTom then
        Nx.RealTom = true
        SLASH_CBWAY1 = '/cbway'
        SlashCmdList["CBWAY"] = function (msg, editbox)
            Nx:TTWayCmd(msg)
        end
    end

    Nx.EmulateTomTom()
end

---
-- Initialize locale settings
-- Stores current game locale for localization
--
function Nx:LocaleInit()
    local loc = GetLocale()
    Nx.Locale = loc
end

-------------------------------------------------------------------------------
-- EVENT REGISTRATION
-- Sets up all event handlers for the addon
-------------------------------------------------------------------------------

---
-- Register all addon events
-- Uses Ace3 event system for various game events
--
function Nx:InitEvents()

    local Com = Nx.Com
    local Guide = Nx.Map.Guide
    local AuctionAssist = Nx.AuctionAssist
    local Travel = Nx.Travel

    LibStub("AceEvent-3.0"):Embed(Com)
    LibStub("AceEvent-3.0"):Embed(Guide)
    LibStub("AceEvent-3.0"):Embed(AuctionAssist)
    LibStub("AceEvent-3.0"):Embed(Travel)

    ---------------------------------------------------------------------------
    -- Core Events (all versions)
    ---------------------------------------------------------------------------
    Nx:RegisterEvent("PLAYER_LOGIN", "OnPlayer_login")
    Nx:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnUpdate_mouseover_unit")
    Nx:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayer_regen_disabled")
    Nx:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayer_regen_enabled")
    Nx:RegisterEvent("UNIT_SPELLCAST_SENT", "OnUnit_spellcast_sent")
    Nx:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZone_changed_new_area")
    Nx:RegisterEvent("PLAYER_LEVEL_UP", "OnPlayer_level_up")
    Nx:RegisterEvent("GROUP_ROSTER_UPDATE", "OnParty_members_changed")
    Nx:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "OnUpdate_battlefield_score")

    ---------------------------------------------------------------------------
    -- Communication Events
    ---------------------------------------------------------------------------
    Com:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
    Com:RegisterEvent("FRIENDLIST_UPDATE", "OnFriendguild_update")
    Com:RegisterEvent("GUILD_ROSTER_UPDATE", "OnFriendguild_update")
    Com:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED", "OnFriendguild_update")
    Com:RegisterEvent("GROUP_ROSTER_UPDATE", "OnFriendguild_update")
    Com:RegisterEvent("CHAT_MSG_CHANNEL_JOIN", "OnChatEvent")
    Com:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", "OnChatEvent")
    Com:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE", "OnChatEvent")
    Com:RegisterEvent("CHAT_MSG_CHANNEL", "OnChat_msg_channel")

    -- SOCIAL_QUEUE_UPDATE: Available from Legion+ (group finder social queues)
    if Nx.LegionMaps then
        Com:RegisterEvent("SOCIAL_QUEUE_UPDATE", "OnFriendguild_update")
    end

    -- CHAT_MSG_SYSTEM: Classic/older versions only (handled differently in retail)
    if not Nx.BFAMaps then
        Com:RegisterEvent("CHAT_MSG_SYSTEM", "OnChat_msg_channel")
    end

    ---------------------------------------------------------------------------
    -- Auction House Events (API changed in BFA 8.3)
    ---------------------------------------------------------------------------
    AuctionAssist:RegisterEvent("AUCTION_HOUSE_SHOW", "OnAuction_house_show")
    AuctionAssist:RegisterEvent("AUCTION_HOUSE_CLOSED", "OnAuction_house_closed")

    -- REPLICATE_ITEM_LIST_UPDATE: New auction house API (BFA 8.3+)
    -- AUCTION_ITEM_LIST_UPDATE: Classic auction house API (pre-BFA)
    if Nx.BFAMaps then
        AuctionAssist:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE", "OnAuction_item_list_update")
    else
        AuctionAssist:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "OnAuction_item_list_update")
    end

    ---------------------------------------------------------------------------
    -- Guide Events (all versions)
    ---------------------------------------------------------------------------
    Guide:RegisterEvent("MERCHANT_SHOW", "OnMerchant_show")
    Guide:RegisterEvent("MERCHANT_UPDATE", "OnMerchant_update")
    Guide:RegisterEvent("GOSSIP_SHOW", "OnGossip_show")
    Guide:RegisterEvent("TRAINER_SHOW", "OnTrainer_show")

    ---------------------------------------------------------------------------
    -- Travel Events (all versions)
    ---------------------------------------------------------------------------
    Travel:RegisterEvent("TAXIMAP_OPENED", "OnTaximap_opened")
end

---
-- Handle legacy frame events
-- Routes events to appropriate handlers
--
function Nx:NXOnEvent (event, ...)
    local h = self.Events[event]
    if h then
        h (nil, event, ...)
    else
        assert (0)
    end
end

-------------------------------------------------------------------------------
-- EVENT HANDLERS
-- Individual handlers for game events
-------------------------------------------------------------------------------

---
-- Handle PLAYER_LOGIN event
-- Initializes windows and requests time played
--
function Nx:OnPlayer_login (event, ...)
    Nx:OnParty_members_changed()
    Nx.Com:OnEvent (event)
    Nx.InitWins()

    Nx.BlizzChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed        -- Save func
    ChatFrame_DisplayTimePlayed = function() end

--    RequestTimePlayed()        -- Blizz does not do anymore on login???
    Nx.RequestTime = true;
end

---
-- Handle UPDATE_MOUSEOVER_UNIT event
-- Processes quest tooltips and GUID information for debugging
--
function Nx:OnUpdate_mouseover_unit (event, ...)
    if Nx.Quest then
        Nx.Quest:TooltipProcess (true)
    end

    local data, guid, id, typ = Nx:UnitDGet ("mouseover")
    if guid then

        local tip = GameTooltip

        if typ == 0 then
            tip:AddLine (format (L["GUID player"] .. " %s", strsub (guid, 6)))

        elseif typ == 3 then
            tip:AddLine (format (L["GUID NPC"] .." %d", id))

            Nx:UnitDTip()

        elseif typ == 4 then
            tip:AddLine (format (L["GUID pet"] .. " %s", strsub (guid, 13)))
        end

        tip:AddLine (format (" %s", guid))
        tip:Show()    -- Adjusts size
    end
end

---
-- Get unit debug data from GUID
-- @param target  Unit ID to inspect
-- @return        data table, guid, id, type
--
-- Nx:UnitDGet / Nx:UnitDCapture / Nx:UnitDTip (mouseover NPC debug
-- coordinate + tooltip capture) were extracted into
-- Modules/DebugFlags/UnitDataCapture.lua.

-- The six WoW-event handlers OnPlayer_regen_disabled / regen_enabled,
-- OnUnit_spellcast_sent, OnZone_changed_new_area, OnPlayer_level_up,
-- OnParty_members_changed and OnUpdate_battlefield_score were
-- extracted into Modules/UserEvents/EventHandlers.lua. Nx:InitEvents
-- still registers them via Nx:RegisterEvent("EVENT", "OnX"); they
-- continue to attach to Nx.

-------------------------------------------------------------------------------
-- MAIN UPDATE LOOP
-- Called every frame to update addon state
-------------------------------------------------------------------------------

-- File-scope helpers used by NXOnUpdate's tooltip-scan branch.
-- Operating on GameTooltip text can hit "secure value" taint:
-- GameTooltipTextLeft1:GetText() may return a string carrying the
-- secure flag from a spell / aura tooltip path. `#secureString` and
-- `secureString ~= otherSecureString` both raise inside a tainted
-- code path. The legacy code defended against this with pcall wrapping
-- inline closures, but those closures were allocated EVERY frame the
-- tooltip was visible — a real per-frame leak. Hoisting the wrapped
-- functions here keeps the taint guard while only allocating them
-- once at file load.
local function _tt_lenOf(s) return #s end
local function _tt_neq(a, b) return a ~= b end

---
-- Main frame update handler
-- Processes tooltips, network updates, and calls module updates
-- @param elapsed  Time since last frame
--
function Nx:NXOnUpdate (elapsed)
    if InCombatLockdown() and not Nx.Initialized and not Nx.CombatMessage then
        Nx.prt("You are in combat! Carbonite will resume loading when your safe.")
        Nx.CombatMessage = true
    end
    local Nx = Nx

    if Nx.Loaded and Nx.PlayerFnd and not Nx.Initialized and not InCombatLockdown() then    -- Safety check
        Nx:SetupEverything()
        return
    end
    if not Nx.Loaded or not Nx.PlayerFnd or not Nx.Initialized then
        return
    end
    Nx.Tick = Nx.Tick + 1
    if Nx.LootOn then
        Nx:LootIt()
    end

    Nx.Proc:OnUpdate (elapsed)

    -- Tooltip stuff

    if not GameTooltip:IsVisible() then
        Nx.TooltipLastDiffText = nil
    end

    -- Where TooltipDataProcessor exists (retail and every Classic flavor except
    -- Classic Era), it delivers tooltip updates without tainting GameTooltip;
    -- the polling fallback below writes to GameTooltip from an OnUpdate path
    -- and would re-introduce the taint.
    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
        local s = GameTooltipTextLeft1:GetText()
        if s and type(s) == "string" then
            -- pcall through the file-scope _tt_lenOf / _tt_neq helpers
            -- to defend against secure-tainted GameTooltip strings
            -- (`#s` and `s ~= other` both raise on tainted values).
            -- The previous code inlined `function() ... end` closures
            -- here; that allocated a closure every frame and was a
            -- significant contributor to the per-frame leak. Hoisted
            -- helpers keep the guard with zero per-frame allocation.
            local ok, slen = pcall(_tt_lenOf, s)
            if not ok then slen = 0 end
            if Nx.Tick % 4 == 1 and GameTooltipTextLeft1:IsVisible() and slen > 5 then
                local okEq, textDiff = pcall(_tt_neq, Nx.TooltipLastDiffText, s)
                if not okEq then textDiff = true end
                if textDiff or Nx.TooltipLastDiffNumLines ~= GameTooltip:NumLines() then
                    if Nx.Quest then
                        Nx.Quest:TooltipProcess()
                    end
                end
            end
            Nx.TooltipLastText = s
        end
    end

    if Nx.TooltipOwner then
        if not Nx.TooltipOwner:IsVisible() then
            if Nx.TooltipText:IsOwned (Nx.TooltipOwner) then
                Nx.TooltipText:Hide()
            end
            Nx.TooltipOwner = nil
        end
    end

    --

    if self.NetSendPos then

        local t = GetTime()

        if t > self.NetPlyrSendTime then

            local plX, plY = Nx.Map.GetPlayerMapPosition ("player")

            if plX > 0 or plY > 0 then

                local s = format ("Map~%d~%d~%d", plX * 100000000, plY * 100000000, Nx.Map:GetCurrentMapId())
                Nx.prt ("NetSend %s", s)
                Nx.Com:Send ("Z", s)

                self.NetPlyrSendTime = t + 1.5
            end
        end
    end

    local combat = UnitAffectingCombat ("player")
    if Nx.InCombat ~= combat then

        Nx.InCombat = combat
    end

    Nx.Com:OnUpdate (elapsed)
    Nx.Map:MainOnUpdate (elapsed)

    if Nx.Quest then
        Nx.Quest:OnUpdate (elapsed)
    end

    if Nx.Tick % 11 == 0 then
        Nx:RecordCharacter()
        if Nx.Warehouse then
            Nx.Warehouse:RecordCharacter()
        end
    end

    if not Nx.Whatsnew.HasWhatsNew then -- Adding it here to be at bottom of menu always.
        Nx.Whatsnew.HasWhatsNew = true
        Nx.NXMiniMapBut.Menu:AddItem(0,"")
        local function func ()
            Nx.Whatsnew:ToggleShow()
        end
        Nx.NXMiniMapBut.Menu:AddItem(0, L["Whats New!"], func, Nx.NXMiniMapBut)
    end

end

-- Nx:WhatsNewUnread and the Nx.Whatsnew window methods live in
-- Modules/Whatsnew/WhatsnewEngine.lua.

-------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------------------------------------

---
-- Debug function to auto-click gossip buttons
-- Used for vendor testing
--
function Nx:LootIt()

    local b = _G["GossipTitleButton1"]

    if b:IsVisible() then
        b:Click()
    end
end

---
-- Show a generic message dialog with optional callbacks
-- @param msg       Message text to display
-- @param func1Txt  Button 1 text
-- @param func1     Button 1 callback function
-- @param func2Txt  Button 2 text (optional)
-- @param func2     Button 2 callback function (optional)
--
-- Nx:ShowMessage / ShowEditBox / ShowMessageTrial /
-- FindActiveChatFrameEditBox were extracted into
-- Modules/UI/Dialogs.lua. The new Carbonite.UI.Dialogs surface
-- exposes them as Dialogs:Message / Dialogs:EditBox / etc.

---
-- Get high-resolution time value
-- Returns seconds * 100 with simulated hundredths
-- @return  Time value for event ordering
--
function Nx:Time()

    local tm = time()

    if tm > self.TimeLast then
        self.TimeFrac = 0
    else
        self.TimeFrac = self.TimeFrac + 1
    end

    self.TimeLast = tm

    return tm * 100 + self.TimeFrac
end

---
-- Check if a unit is an elite mob
-- @param target  Unit ID to check
-- @return        true if elite, rareelite, or worldboss
--
function Nx:UnitIsPlusMob (target)
    local c = UnitClassification (target)
    return c == "elite" or c == "rareelite" or c == "worldboss"
end

-------------------------------------------------------------------------------
-- GLOBAL DATA MANAGEMENT
-- Functions for managing saved variables and persistent data
-------------------------------------------------------------------------------

-- Gather format:
--   [nodeType] = { [mapId] = { [nodeId] = { "x|y|level", ... } } }
--   Herb and Mine node data organized by map

---
-- Initialize global data structures
-- Creates/migrates character data, options, travel data, gather data, etc.
--
function Nx:InitGlobal()
    if Nx.db.profile.Version.OptionsVersion < Nx.VERSIONDATA then

        if Nx.db.profile.Version.OptionsVersion > 0 then
            Nx.prt (L["Reset old data"] .. " %f", Nx.db.profile.Version.OptionsVersion)
        end

        Nx.db:ResetDB("Default")
        Nx.db.profile.Version.OptionsVersion = Nx.VERSIONDATA
        Nx.db.global.Characters = {}        -- Indexed by "Server.Name"
    end

    if not Nx.db.profile.Version.NXVer1 then
        Nx.db.profile.Version.NXVer1 = Nx.VERSION
    end
    Nx:InitCharacter()

    --

--    local unitName = Nx.DemungeStr ("TnjrManc")    -- UnitName
--    Nx.PlayerName = _G[unitName] (Nx.DemungeStr ("olbwdr"))        -- player

    -- Global options

    local opts = Nx.db.profile

    if not opts or opts.Version.OptionsVersion < Nx.VERSIONGOPTS then

        if opts and opts.Version.OptionsVersion < Nx.VERSIONGOPTS then
            Nx.prt (L["Reset old global options"] .. " %f", opts.Version.OptionsVersion)
            Nx:ShowMessage (L["Options have been reset for the new version."] .. "\n" .. L["Privacy or other settings may have changed."], "OK")
        end

        opts = {}
        Nx.db:ResetDB("Default")
        Nx.db.profile.Version.OptionsVersion = Nx.VERSIONGOPTS

--        Nx.Opts:Reset()
    end

    -- Clean old junk

--    opts.NXCleaned = nil

    if not opts.NXCleaned then

        opts.NXCleaned = true

        local keep = {
            ["Characters"] = 1,
            ["NXCap"] = 1,
            ["NXFav"] = 1,
            ["NXGather"] = 1,
            ["NXGOpts"] = 1,
            ["NXHUDOpts"] = 1,
            ["NXInfo"] = 1,
            ["NXQOpts"] = 1,
            ["NXSocial"] = 1,
            ["NXTravel"] = 1,
            ["NXVendorV"] = 1,
            ["NXVendorVVersion"] = 1,
            ["NXVer1"] = 1,
            ["NXVerT"] = 1,
            ["NXWare"] = 1,
            ["Version"] = 1,
        }

        local cnt = 0
        if cnt > 0 then
            Nx.prt (L["Cleaned"] .. " %d " .. L["items"], cnt)
        end
    end

    -- HUD options

    local opts = Nx.db.profile.HUDOpts

    if not opts or opts.Version < Nx.VERSIONHUDOPTS then

        if opts then
            Nx.prt (L["Reset old HUD options"] .. " %f", opts.Version)
        end

        opts = {}
        Nx.db.profile.HUDOpts = opts
        opts.Version = Nx.VERSIONHUDOPTS

--        Nx.HUD:OptsReset()
    end

    -- Travel data

    local tr = Nx.db.char.Travel

    if not tr or tr.Version < Nx.VERSIONTRAVEL then

        if tr then
            Nx.prt (L["Reset old travel data"] .. " %f", tr.Version)
        end

        tr = {}
        Nx.db.char.Travel = tr
        tr.Version = Nx.VERSIONTRAVEL
    end

    tr["TaxiTime"] = tr["TaxiTime"] or {}

    local cd = Nx.db.char.Travel.Taxi

    if not cd or cd.Version < Nx.VERSIONCharData then
        cd = {}
        Nx.db.char.Travel.Taxi = cd
        cd.Version = Nx.VERSIONCharData
        cd["Taxi"] = {}        -- Taxi nodes we have
    end

    --

    -- Gather data

    local gath = Nx.db.profile.GatherData

    if not gath or gath.Version < Nx.VERSIONGATHER then

        if gath and gath.Version < 0 then
            Nx.DoGatherUpgrade = gath.Version

        else
            if gath then
                Nx.prt (L["Reset old gather data"] .. " %f", gath.Version)
            end

            gath = {}
            Nx.db.profile.GatherData = gath
            gath.NXHerb = {}
            gath.NXMine = {}
            gath.NXTimber = {}
        end

        gath.Version = Nx.VERSIONGATHER
    end

    gath["Misc"] = gath["Misc"] or {}
--    gath.NXGas = gath.NXGas or {}

    -- Capture data

    local cap = Nx.db.global.Capture        -- Keep NX

--    cap = nil        -- Nuke test

    if not cap or cap.Version < Nx.VERSIONCAP then

--        if cap then
--            Nx.prt ("Reset old cap %f", cap.Version)
--        end

        cap = {}
        Nx.db.global.Capture = cap
        cap.Version = Nx.VERSIONCAP
        cap["Q"] = {}

--        Nx.HUD:OptsReset()
    end

    cap["NPC"] = cap["NPC"] or {}
end

---
-- Get named data from appropriate storage
-- @param name  Data category: "Events", "List", "Quests", "Win", "Herb", "Mine"
-- @param ch    Character table (defaults to current)
-- @return      Requested data table
--
-- Nx:GetData / GetDataToolBar / GetHUDOpts / GetCap / CaptureFind
-- moved to Modules/PlayerCharacter/CharacterData.lua alongside the
-- saved-variable character ops (Init/Find/Copy/Delete/RealmChars).

---
-- Pack x,y coordinates into a hex string
-- @param x  X coordinate (0-100)
-- @param y  Y coordinate (0-100)
-- @return   6-character hex string "XXXYYY"
--
function Nx:PackXY (x, y)

    x = max (0, min (100, x))
    y = max (0, min (100, y))
    return format ("%03x%03x", x * 40.9 + .5, y * 40.9 + .5)        -- Round off
end

---
-- Unpack a hex string to x,y coordinates
-- @param xy  6-character hex string
-- @return    x, y coordinates (0-100 range)
--
function Nx:UnpackXY (xy)
    local x = tonumber (strsub (xy, 1, 3), 16) / 40.9
    local y = tonumber (strsub (xy, 4, 6), 16) / 40.9
    return x, y
end

-------------------------------------------------------------------------------
-- CHARACTER DATA MANAGEMENT
-- Per-character data storage and retrieval
-------------------------------------------------------------------------------

-- Event packed string format: "TYPE^TIME^MAPID^XXYY^NAME[^DATA]"
--   TYPE: I=Info, K=Kill, D=Death, M=Mine, H=Herb
--   TIME: time() * 100
--   MAPID: numeric map ID
--   XXYY: packed coordinates
--   NAME: event description
--   DATA: optional extra data (kill count, etc.)

-- Quest format:
--   Table indexed by quest ID
--   Value: "STIME" where S = status (C=complete, c=incomplete, W=watched)
--                         TIME = time() value

-- Nx:InitCharacter / GetRealmCharName / CalcRealmChars /
-- FindCharacter / DeleteCharacter / GetUnitClass / RecordCharacter
-- live in Modules/PlayerCharacter/CharacterData.lua.

-- The per-character event log (DeleteOldEvents, AddEvent,
-- GetEventMapId, UnpackEvent, AddInfo/Death/Kill/Herb/Mine/Timber
-- Event) lives in Modules/UserEvents/EventLog.lua.

-------------------------------------------------------------------------------
-- TITLE SCREEN ANIMATION
-- Animated logo displayed on addon load
-------------------------------------------------------------------------------

-- Nx.Title:Init / TickWait / TickWait2 / Tick (splash animation)
-- live in Modules/TitleScreen/TitleScreenEngine.lua.

-------------------------------------------------------------------------------
-- AUCTION HOUSE ASSISTANT
-- Provides buyout-per-item calculations and display
-------------------------------------------------------------------------------

-- The AuctionAssist engine -- OnAuction_house_show /
-- OnAuction_house_closed / OnAuction_item_list_update /
-- AuctionFrameBrowse_Update plus the Create / Update / OnListEvent
-- stubs -- lives in Modules/AuctionAssist/AuctionAssistEngine.lua.

-------------------------------------------------------------------------------
-- USER EVENTS SYSTEM
-- Records and displays player activities (kills, deaths, gathering, etc.)
-------------------------------------------------------------------------------

---
-- Initialize user events module
--
function Nx.UEvents:Init()
    -- self.Sorted = {}
end

---
-- Add an info event to the log
-- @param name  Description of the event
-- @return      Map ID where event occurred
--
function Nx.UEvents:AddInfo (name)

    local mapId, x, y = self:GetPlyrPos()

    Nx:AddInfoEvent (name, Nx:Time(), mapId, x, y)

    self:UpdateAll()

    return mapId
end

---
-- Add a player death event
-- @param name  Cause of death description
--
function Nx.UEvents:AddDeath (name)

    local mapId, x, y = self:GetPlyrPos()

    Nx:AddDeathEvent (name, Nx:Time(), mapId, x, y)

    self:UpdateAll()

--    Nx:SendComm (2, "Death "..name)

    if Nx.Map:IsBattleGroundMap (mapId) then
--        Nx.prt ("Req D")
        RequestBattlefieldScoreData()
    end
end

---
-- Add a kill event
-- @param name   Name of killed enemy
-- @param npcId  Optional NPC ID (parsed from the destGUID by the caller)
--
function Nx.UEvents:AddKill (name, npcId)

    local mapId, x, y = self:GetPlyrPos()

    Nx:AddKillEvent (name, Nx:Time(), mapId, x, y, npcId)

    self:UpdateAll()
end

---
-- Add an honor event
-- @param name  Honor event description
--
function Nx.UEvents:AddHonor (name)

    local mapId = self:AddInfo (name)

    if Nx.Map:IsBattleGroundMap (mapId) then
--        Nx.prt ("Req H")
        RequestBattlefieldScoreData()
    end
end

---
-- Add an herb gathering event
-- @param name  Name of the herb gathered
--
function Nx.UEvents:AddHerb (name)

    local mapId, x, y, level = self:GetPlyrPos()
    mapId = Nx.Map:GetCurrentMapAreaID()
    if Nx.db.profile.Guide.GatherEnabled then
        local id = Nx:HerbNameToId (name)
        if id then
            Nx:AddHerbEvent (name, Nx:Time(), mapId, x, y)
            Nx:GatherHerb (id, mapId, x, y, level)
        end
        self:UpdateAll (true)
    end
end

---
-- Add a mining event
-- @param name  Name of the ore mined
--
function Nx.UEvents:AddMine (name)
    local mapId, x, y, level = self:GetPlyrPos()
    mapId = Nx.Map:GetCurrentMapAreaID()
    if Nx.db.profile.Guide.GatherEnabled then
        local id = Nx:MineNameToId (name)
        if id then
            Nx:AddMineEvent (name, Nx:Time(), mapId, x, y)
            Nx:GatherMine (id, mapId, x, y, level)
        end
        self:UpdateAll (true)
    end
end

---
-- Add a timber logging event
-- @param name  Name of the timber logged
--
function Nx.UEvents:AddTimber (name)
    local mapId, x, y, level = self:GetPlyrPos()
    mapId = Nx.Map:GetCurrentMapAreaID()
    if Nx.db.profile.Guide.GatherEnabled then
        local size = false
        if name == L["Small Timber"] then
            size = 1
        elseif name == L["Timber"] or name == L["Medium Timber"] then
            size = 2
        elseif name == L["Large Timber"] then
            size = 3
        end
        if size then
            Nx:AddTimberEvent (name, Nx:Time(), mapId, x, y)
            Nx:GatherTimber (size, mapId, x, y, level)
        end
        self:UpdateAll (true)
    end
end

---
-- Add a chest/container opening event
-- @param typ   Type of opening (e.g., "Art" for artifact)
-- @param name  Name of what was opened
--
function Nx.UEvents:AddOpen (typ, name)

    local mapId = self:AddInfo (name)
    if Nx.db.profile.Guide.GatherEnabled then
        local mapId, x, y, level = self:GetPlyrPos()
        mapId = Nx.Map:GetCurrentMapAreaID()
        Nx:Gather ("Misc", typ, mapId, x, y, level)
        self:UpdateAll()
    end
end

---
-- Get current player map position
-- @return  mapId, x, y, dungeonLevel
--
function Nx.UEvents:GetPlyrPos()
    local mapId = Nx.Map:GetRealMapId()
    local map = Nx.Map:GetMap (1)
    return mapId, map.PlyrRZX, map.PlyrRZY, Nx.Map.DungeonLevel
end

--------

function Nx.UEvents:UpdateAll (upGuide)

    self:Sort()
    self:UpdateMap (upGuide)
    self.List:Update()
end

--------
-- Sort compare

function Nx.UEvents.SortCmp (v1, v2)

--    prtD ("Sort "..v1.Time.." "..v2.Time)

    local _, tm1 = Nx.Split ("^", v1)
    local _, tm2 = Nx.Split ("^", v2)

    return tonumber (tm1) < tonumber (tm2)
end

--------

function Nx.UEvents:Sort()

--    wipe (self.Sorted)

--    Nx:AddAllEvents (self.Sorted)

--    sort (self.Sorted, self.SortCmp)

    sort (Nx.CurCharacter.E, self.SortCmp)        -- Should already be sorted, but whatever
end

--------
-- Open and init or toggle user events list

function Nx.UEvents.List:Open()

    local UEvents = Nx.UEvents

    local win = self.Win

    if win then
        if win:IsShown() then
            win:Show (false)
        else
            win:Show()
        end
        return
    end

    -- Create Window

    local win = Nx.Window:Create ("NxEventsList", nil, nil, nil, nil, nil, true)
    self.Win = win

    win:CreateButtons (true)

    win:InitLayoutData (nil, -.75, -.6, -.25, -.1)

    local list = Nx.List:Create ("Events", 2, -2, 100, 12 * 3, win.Frm)
    self.List = list
    list:ColumnAdd (L["Time"], 1, 70)
    list:ColumnAdd (L["Event"], 2, 140)
    list:ColumnAdd ("#", 3, 30, "CENTER")
    list:ColumnAdd (L["Position"], 4, 500)

    win:Attach (list.Frm, 0, 1, 0, 1)

    UEvents:UpdateAll()
end

------
function Nx.UEvents.List:Update()

    local Nx = Nx
    local UEvents = Nx.UEvents

    if not self.Win then
        return
    end

    local sorted = Nx.CurCharacter.E

    self.Win:SetTitle (format (L["Events"] .. ": %d", #sorted))

    local list = self.List
    local isLast = list:IsShowLast()
    list:Empty()

    for k, item in ipairs (sorted) do

        local typ, tm, mapId, x, y, text, data = Nx:UnpackEvent (item)

        list:ItemAdd()
        list:ItemSet (1, date ("%d %H:%M:%S", tm / 100))

        local eStr = text

        if typ == "D" then

            eStr = "|cffff6060" .. L["Died"] .. "! " .. text

        elseif typ == "K" then

            list:ItemSet (3, data)

            eStr = "|cffff60ff" .. L["Killed"] .. " " .. text

        elseif typ == "H" then

            eStr = "|cff60ff60" .. L["Picked"] .. " " .. text

        elseif typ == "M" then

            eStr = "|cffc0c0c0" .. L["Mined"] .. " " .. text

        elseif typ == "F" then

            eStr = "|cffc0c0c0" .. L["Fished"] .. " " .. text

        end
        list:ItemSet (2, eStr)

        local mapName = Nx.Map:IdToName (mapId)

        local str = format ("%s %.0f %.0f", mapName, x, y)
        list:ItemSet (4, str)
    end

    list:Update (isLast)
end

------
-- Update user event data on map

function Nx.UEvents:UpdateMap (upGuide)

--    Nx.prt ("UEvents:UpdateMap")

    local Nx = Nx
    local Map = Nx.Map

    local mapId = Map:GetCurrentMapId()
    local m = Map:GetMap (1)

    if m then

        if upGuide then
            m.Guide:Update()
        end

        -- "WP" draw mode + 32x32 makes these scale the same as RareScanner /
        -- Notes pins (much smaller on screen than ZP-mode icons would be).
        -- SetIconTypeChop / NoDockMinimap match the way other WP icon types
        -- behave on a docked minimap.
        m:InitIconType ("Kill", "WP", "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 32, 32)
        m:InitIconType ("Death", "WP", "Interface\\TargetingFrame\\UI-TargetingFrame-Seal", 32, 32)
        m:SetIconTypeChop ("Kill", true)
        m:SetIconTypeChop ("Death", true)
        m:SetIconTypeNoDockMinimap ("Kill", true)
        m:SetIconTypeNoDockMinimap ("Death", true)

        local icon

        -- Read kill-icon settings from Carbonite.Info if loaded; default to
        -- "show, no auto-expire" when Info isn't present.
        local killEnabled = true
        local autoClearSecs = 0
        local keepForever = false
        if Nx.idb and Nx.idb.profile and Nx.idb.profile.Info then
            killEnabled = Nx.idb.profile.Info.KillIcons
            autoClearSecs = Nx.idb.profile.Info.KillIconAutoClearSecs or 0
            keepForever = Nx.idb.profile.Info.KillIconKeepForever or false
        end

        local now = Nx:Time()
        local events = Nx.CurCharacter.E

        -- Build a multi-line tooltip for kill/death markers: branding line,
        -- name, kill time (decoded from the *100 Nx:Time() format), and an
        -- optional NPC ID line when the captured destGUID supplied one.
        local function buildKillTip(name, tm, dataField, isDeath)
            local realTm = tm and math.floor(tm / 100) or 0
            local timeStr = realTm > 0 and date("%H:%M:%S  %Y-%m-%d", realTm) or "?"
            local kills, npcId = strsplit("|", dataField or "")
            local label = isDeath
                and ("[Carbonite.Info  " .. (L["death"] or "death") .. "]")
                or  ("[Carbonite.Info  " .. (L["kill"] or "kill") .. "]")
            local lines = {
                "|cff8080ff" .. label .. "|r",
                name or "?",
                "|cffa0a0a0" .. timeStr .. "|r",
            }
            if kills and tonumber(kills) and tonumber(kills) > 1 then
                lines[#lines + 1] = "|cffa0a0a0" .. format(L["kills: %s"] or "kills: %s", kills) .. "|r"
            end
            if npcId and npcId ~= "" then
                lines[#lines + 1] = "|cffa0a0a0" .. format(L["NPC ID: %s"] or "NPC ID: %s", npcId) .. "|r"
            end
            return table.concat(lines, "\n")
        end

        -- Walk in reverse so we can splice expired entries when the user has
        -- NOT opted into "keep history forever". With KeepForever the timer
        -- only suppresses display — the records remain in saved variables.
        for k = #events, 1, -1 do
            local item = events[k]
            local iMapId = Nx:GetEventMapId (item)
            local typ, tm, _, x, y, text, data = Nx:UnpackEvent (item)
            local isKillish = (typ == "K" or typ == "D")

            -- Nx:Time() = time()*100 + frac, so threshold needs *100 too.
            local expired = isKillish and autoClearSecs > 0 and tm
                                and (now - tm) > autoClearSecs * 100

            if expired and not keepForever then
                table.remove(events, k)
            elseif iMapId == mapId and isKillish and killEnabled and not expired then
                local wx, wy = m:GetWorldPos (iMapId, x, y)
                if typ == "K" then
                    icon = m:AddIconPt ("Kill", wx, wy)
                    icon.EventIndex = k
                    m:SetIconTip (icon, buildKillTip(text, tm, data, false))
                elseif typ == "D" then
                    icon = m:AddIconPt ("Death", wx, wy)
                    icon.EventIndex = k
                    m:SetIconTip (icon, buildKillTip(text, tm, data, true))
                end
            end
            -- expired AND keepForever: silently skip drawing, keep record.
        end

    end
end

-------------------------------------------------------------------------------
-- The Gather subsystem (Nx.GatherInfo / Nx.GatherRemap / Nx.GatherCache /
-- Nx:GatherInit / GetGather / IsGathering / HerbNameToId / MineNameToId /
-- GatherHerb / Mine / Timber / Gather / GatherUnpack / GatherDelete* /
-- GatherImportCarb* / GatherImportBatch / GatherNodeToCarb / GatherConvert)
-- lives in Modules/Gather/GatherStorage.lua.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ITEM HANDLING
-- Item info loading and tooltip management
-------------------------------------------------------------------------------

---
-- Initialize item management
--
function Nx.Item:Init()
    self.Asked = {}
end

---
-- Load item info by ID
-- Caches result to avoid repeated queries
-- @param id  Item ID
--
function Nx.Item:Load (id)
    if not self.Asked[id] then
        local name, link = C_Item.GetItemInfo (id)
        if name then
            self.Asked[id] = name
        end
    end
end

---
-- Enable server-side item loading
-- Sets up tooltip for query and timer for update
--
function Nx.Item.EnableLoadFromServer()

--    Nx.prt ("EnableLoadFromServer")

    local self = Nx.Item

    self.TooltipFrm = CreateFrame ("GameTooltip", "NxTooltipItem", UIParent, "GameTooltipTemplate")
    self.TooltipFrm:SetOwner (UIParent, "ANCHOR_NONE")        -- We won't see with this anchor

    self.ItemsRequested = 0

    Item = Nx:ScheduleTimer (self.Timer, 1)
end

function Nx.Item.DisableLoadFromServer()

--    Nx.prt ("DisableLoadFromServer")

    local self = Nx.Item
    self.Needed = {}
    self.Load = function() end        -- Nuke function

    AskDeleteVV = Nx:ScheduleTimer (self.AskDeleteVV, 0)
end

function Nx.Item.AskDeleteVV()

    local function func()
            Nx.db.profile.VendorV = nil
            Nx.Map.Guide:UpdateVisitedVendors()
    end

    Nx:ShowMessage (Nx.TXTBLUE.."Carbonite:\n|cffffff60" .. L["Delete visited vendor data?"] .. "\n" .. L["This will stop the attempted retrieval of items on login."], L["Delete"], func, L["Cancel"])
end

---
-- Show item tooltip by ID
-- @param id       Item ID or link
-- @param compare  Show comparison tooltips if true
--
function Nx.Item:ShowTooltip (id, compare)

--    Nx.prtVar ("ShowTooltip", id)

    local id = tostring (id)

    id = Nx.Split ("^", id)

    if not strfind (id, "item:") then
        if strfind (id, "quest:") then
        else
            id = "item:" .. id .. ":0:0:0:0:0:0:0"        -- Without the 7 ":0" Pawn prints an error
        end
    end

    Nx.TooltipText:SetHyperlink (id)
end

function Nx.Item:DrawTimer()

    if next (self.Needed) then        -- More?
        Nx.prt (" %d " .. L["items retrieved"], self.ItemsRequested)

    else
        Nx.prt (L["Item retrieval from server complete"])
    end

    local g = Nx.Map:GetMap (1).Guide
    g:UpdateVisitedVendors()
    g:Update()
end

-------------------------------------------------------------------------------
-- MINIMAP BUTTON
-- Main addon button on the minimap
-------------------------------------------------------------------------------

---
-- Initialize the minimap button
-- Sets up right-click menu with addon options
--
function Nx.NXMiniMapBut:Init()
    local f = NXMiniMapBut

    if not Nx.db.profile.MiniMap.ButOwn then
        f:RegisterForDrag ("LeftButton")
    end

    -- Create menu

    local menu = Nx.Menu:Create (f)
    self.Menu = menu
    menu:AddItem (0, L["Options"], self.Menu_OnOptions, self)
    menu:AddItem (0, L["Show Map"], self.Menu_OnShowMap, self)
    menu:AddItem (0, L["Show Events"], self.Menu_OnShowEvents, self)
    menu:AddItem (0, "", nil, self)

    local item = menu:AddItem (0, L["Show Auction Buyout Per Item"], self.Menu_OnShowAuction, self)
    item:SetChecked (false)

    if Nx.db.profile.Debug.DebugCom then
        menu:AddItem (0, "", nil, self)
        menu:AddItem (0, L["Show Com Window"], self.Menu_OnShowCom, self)
    end
    if Nx.db.profile.Debug.DebugMap then
        menu:AddItem (0, "", nil, self)
        menu:AddItem (0, L["Toggle Profiling"], self.Menu_OnProfiling, self)
    end

    -- Fix position if bad (does not work)

    NXMiniMapBut:SetClampedToScreen (true)

--    self:Move()

    -- Ask to disable profiling

    local ok, var = pcall (GetCVar, "scriptProfile")
    if ok and var ~= "0" then
        Nx:ShowMessage ("Profiling is on. This decreases game performance. Disable?", "Disable and Reload", self.ToggleProfiling, "Cancel")
    end
end

function Nx.NXMiniMapBut:Menu_OnOptions()
    Nx.Opts:Open()
end

function Nx.NXMiniMapBut:Menu_OnShowMap()
    Nx.Map:ToggleSize()
end

function Nx.NXMiniMapBut:Menu_OnShowEvents()
    Nx.UEvents.List:Open()
end

function Nx.NXMiniMapBut:Menu_OnHideWatch (item)
    local hide = item:GetChecked()
    Nx.Quest.Watch.Win:Show (not hide)
end

function Nx.NXMiniMapBut:Menu_OnShowAuction (item)
    Nx.AuctionShowBOPer = item:GetChecked()

    if AuctionFrame and AuctionFrame:IsShown() then
        AuctionFrameBrowse_Update()
    end
end

function Nx.NXMiniMapBut:Menu_OnShowCom()
    Nx.Com.List:Open()
end

function Nx.NXMiniMapBut:Menu_OnProfiling()
    Nx:ShowMessage ("Toggle profiling? Reloads UI", "Reload", self.ToggleProfiling, "Cancel")
end

function Nx.NXMiniMapBut:ToggleProfiling()

    RegisterCVar ("scriptProfile")

    local var = GetCVar ("scriptProfile")
--    Nx.prtVar ("v:", var)
    var = var == "0" and "1" or "0"
    SetCVar ("scriptProfile", var)

--    Nx.prt (format ("Profiling %s", var))
    ReloadUI()
end

function Nx.NXMiniMapBut:NXOnEnter (frm)

    local mmown = Nx.db.profile.MiniMap.ButOwn
    local tip = Nx.TooltipText

    --V4 this
    tip:SetOwner (frm, "ANCHOR_LEFT")
    tip:SetText (NXTITLEFULL .. " " .. Nx.VERMAJOR .. "." .. Nx.VERMINOR*10)
    tip:AddLine (L["Left click toggle Map"], 1, 1, 1, true)

    if mmown then
        tip:AddLine (L["Shift left click toggle minimize"], 1, 1, 1, true)
    end

    tip:AddLine (L["Alt left click toggle Watch List"], 1, 1, 1, true)
    tip:AddLine (L["Middle click toggle Guide"], 1, 1, 1, true)
    tip:AddLine (L["Right click for Menu"], 1, 1, 1, true)

    if not mmown then
        tip:AddLine (L["Shift drag to move"], 1, 1, 1, true)
    end
    tip:AppendText ("")
end

function Nx.NXMiniMapBut:NXOnClick (button, down)

--    Nx.prt (button)

    if button == "LeftButton" then

        if IsShiftKeyDown() then
            Nx.db.profile.MiniMap.ButWinMinimize = not Nx.db.profile.MiniMap.ButWinMinimize
            Nx.Map.Dock:UpdateOptions()
        elseif IsAltKeyDown() and Nx.Quest then
            local w = Nx.Quest.Watch.Win
            w:Show (not w:IsShown())
        else
            Nx.Map:ToggleSize (0)
        end

    elseif button == "MiddleButton" then

        Nx.Map:GetMap (1).Guide:ToggleShow()

    else
        self:OpenMenu()
    end
end

function Nx.NXMiniMapBut:OpenMenu()
    if self.Menu then            -- Someone had error with this nil
        self.Menu:Open()
    end
end

---
-- Update handler for minimap button dragging
-- @param frm  The button frame
--
function Nx.NXMiniMapBut:NXOnUpdate (frm)

--    Nx.prtVar ("NXOnUpdate", frm)

    --V4 this
    if frm.NXDrag then

--        Nx.prt ("Drag")

        local mm = _G["Minimap"]

        local x, y = GetCursorPosition()
        local s = mm:GetEffectiveScale()
        self:Move (x / s, y / s)
    end
end

---
-- Position the minimap button around the minimap edge
-- @param x  Cursor X position
-- @param y  Cursor Y position
--
function Nx.NXMiniMapBut:Move (x, y)
    local but = NXMiniMapBut        -- 32x32

    local mm = _G["Minimap"]

    local l = mm:GetLeft() + 70        -- Minimap is 140x140
    local b = mm:GetBottom() + 70
--[[
    if not x then
        x = but:GetLeft()
        y = but:GetTop()
        Nx.prt ("xy %s %s", x, y)
    end
--]]
    x = x - l
    y = y - b

    local ang = atan2 (y, x)
    local r = (x ^ 2 + y ^ 2) ^ .5
    r = max (r, 79)
    r = min (r, 110)

    x = r * cos (ang)
    y = r * sin (ang)
    but:SetPoint ("TOPLEFT", mm, "TOPLEFT", x + 54, y - 54)
    but:SetUserPlaced (true)
end

---
-- Handle inter-addon communication (stub)
--
function Nx.ModChatReceive(msg,dist,target)
end

-------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-- String splitting, process management
-------------------------------------------------------------------------------

-- Cache for split results (weak values for garbage collection)
local TempTable = {}
setmetatable(TempTable, {__mode = "v"})

---
-- Split a string by delimiter (cached for performance)
-- @param d  Delimiter character
-- @param p  String to split
-- @return   Unpacked values from split
--
function Nx.Split(d, p)
    if p and not string.find(p,d) then
        return p
    end
    if not p then
        return nil
    end
    if p and #p <= 1 then return p end
    if TempTable[p] then
        return unpack(TempTable[p],1,table.maxn(TempTable[p]))
    else
        --local TempNum = 0
        local Tossaway = {strsplit(d, p)}
        --[[while true do
            local l=string.find(p,d,TempNum,true);
            if l~=nil then
                table.insert(Tossaway, string.sub(p,TempNum,l-1))
                TempNum=l+1
            else
                table.insert(Tossaway, string.sub(p,TempNum))
                break
            end
        end]]--
        TempTable[p] = Tossaway
        return unpack(Tossaway)
    end
end

-------------------------------------------------------------------------------
-- PROCESS SCHEDULER
-- Lightweight coroutine-like system for spreading work across frames
-------------------------------------------------------------------------------

---
-- Initialize the process scheduler
--
function Nx.Proc:Init()
    self.Procs = {}
    self.TimeLeft = 0
end

---
-- Create a new scheduled process
-- @param user   Object that owns the process (passed to func)
-- @param func   Function to call each tick
-- @param delay  Initial delay in ticks before first call
--
function Nx.Proc:New (user, func, delay)

    local p = {}
    tinsert (self.Procs, p)
    p.User = user
    p.Func = func
    p.Delay = delay or 1
end

---
-- Change the function for a running process
-- @param proc  Process object
-- @param func  New function to call
--
function Nx.Proc:SetFunc (proc, func)
    proc.Func = func
end

---
-- Process scheduler update
-- Runs pending processes based on elapsed time
-- @param elapsed  Time since last frame
--
function Nx.Proc:OnUpdate (elapsed)

--    Nx.prt ("Proc Elapsed raw %s", elapsed)

    elapsed = min (elapsed, .2) * 60

--    Nx.prt ("Proc Elapsed %s", elapsed)

    elapsed = elapsed + self.TimeLeft

    while elapsed >= 1 do

        elapsed = elapsed - 1

        local n = 1

        while 1 do
            local p = self.Procs[n]
            if not p then
                break
            end

            local d = p.Delay - 1
            if d <= 0 then
                d = p.Func (p.User, p) or 1

                if d < 0 then                -- No time?
                    tremove (self.Procs, n)        -- Kill proc
                    n = n - 1            -- Same index again
                end
            end
            p.Delay = d

            n = n + 1
        end

    end

    self.TimeLeft = elapsed
end
-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------