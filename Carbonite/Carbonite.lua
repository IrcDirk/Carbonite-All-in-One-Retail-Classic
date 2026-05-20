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

---
-- Get max gathering skill level for the current game version
-- Used to filter which gathering nodes are relevant for the current expansion
-- @return  Max skill level for the current expansion (9999 for retail)
--
function Nx:GetMaxGatherSkill()
    if Nx.isRetail then
        return 9999  -- Show all nodes on retail
    elseif Nx.isMoPClassic then
        return 600
    elseif Nx.isCataClassic then
        return 525
    elseif Nx.isWotlkClassic then
        return 450
    elseif Nx.isTBCClassic then
        return 375
    elseif Nx.isClassicEra then
        return 300
    else
        return 9999  -- Default to showing all
    end
end

---
-- Check if a gathering node should be shown for the current game version
-- @param skill           The skill level of the node
-- @param isExpansionNode true if this is a WoD+ expansion-specific node (skill=1 expansion herbs/mines)
-- @return                true if the node should be shown
--
function Nx:ShouldShowGatherNode(skill, isExpansionNode)
    -- WoD+ expansion nodes use skill=1 (expansion-based scaling) and are retail/WoD-only.
    -- Classic-era nodes like Silverleaf, Peacebloom, Copper Vein also have skill=1
    -- but should always be shown (isExpansionNode=false for those).
    if skill == 1 and isExpansionNode then
        return Nx.isRetail or Nx.WODMaps
    end
    -- Other nodes are shown if skill is within the expansion's max
    return skill <= Nx:GetMaxGatherSkill()
end

---
-- Get localized name for a gather node using item ID
-- Falls back to the L["..."] name if item not cached
-- @param typ: "H" for herbs, "M" for mines, "L" for timber
-- @param index: index in GatherInfo[typ]
-- @return localized name string
---
function Nx:GetGatherNodeName(typ, index)
    local nodeData = Nx.GatherInfo[typ] and Nx.GatherInfo[typ][index]
    if not nodeData then
        return "Unknown"
    end

    local itemId = nodeData[4]
    if itemId then
        -- Try to get localized name from game
        local name
        if C_Item and C_Item.GetItemInfo then
            name = C_Item.GetItemInfo(itemId)
        elseif GetItemInfo then
            name = GetItemInfo(itemId)
        end
        if name then
            return name
        end
    end
    -- Fall back to the L["..."] localized name
    return nodeData[3] or "Unknown"
end

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

Nx.Whatsnew = {}
Nx.Whatsnew.Categories = {"Maps"}
Nx.Whatsnew.Maps = {
    [1568657164] = {
        "Sept 16th 2019", "",
        "This is Alpha version of Carbonite Classic, all bugs/issues please report to",
        "GitHub repo: https://github.com/IrcDirk/Carbonite-Classic."
    },
    [1653631200] = {
        "May 27th 2022", "",
        "Fixed map path generation using FlightMasters",
        "Fixed HandyNotes icons disappearing while standing still",
        "Fixed Carbonite Map causing errors while trying to open map in combat",
        "Fixed Carbonite maps going out while traveling between islands/subcontinents in Kalimdor/Eastern Kingdoms/Outlands",
        "Fixed Warehouse module not showing equipped wands",
        "Add tracking of goods bought in Auction House in Warehouse module",
        "Add localizations for various strings (need translators for some languages)",
        "Updated translations for some of the Carbonite modules"
    },
    [1660510987] = {
        "Aug 14th 2022", "",
        "Implemented WotLK Classic support for Pre-patch",
        "Updated Flight Masters data",
        "Updated Flight Masters locales for DE,ES,FR,KO,PT,RU,TW Languages",
        "Fixed various small errors caused by division by zero."
    }
}
Nx.Whatsnew.WhichCat = 1
Nx.Whatsnew.HasWhatsNew = nil

-------------------------------------------------------------------------------
-- TOMTOM EMULATION
-- Provides TomTom-compatible API for addons that expect it
-------------------------------------------------------------------------------

---
-- Set up TomTom emulation API
-- Creates global TomTom table with wrapper functions
--
function Nx.EmulateTomTom()
    if _G.TomTom and Nx.RealTom then
        return
    end
    local tom = {}
    _G.TomTom = tom
    tom["version"] = "v40200"
    tom["AddWaypoint"] = Nx.TTAddWaypoint
    tom["AddZWaypoint"] = Nx.TTAddZWaypoint
    tom["SetCustomWaypoint"] = Nx.TTSetCustomWaypoint
    tom["SetCustomMFWaypoint"] = Nx.TTSetCustomMFWaypoint
    tom["AddMFWaypoint"] = Nx.TTSetCustomMFWaypoint
    tom["RemoveWaypoint"] = Nx.TTRemoveWaypoint
    tom["SetCrazyArrow"] = Nx.TTSetCrazyArrow
    tom["DefaultCallbacks"] = Nx.TTDefaultCallbacks
    tom["SetClosestWaypoint"] = Nx.TTSetClosestWaypoint
    SLASH_WAY1 = '/way'
    SLASH_CBWAY1 = '/cbway'
    SlashCmdList["WAY"] = function (msg, editbox)
        Nx:TTWayCmd(msg)
    end
    SlashCmdList["CBWAY"] = function (msg, editbox)
        Nx:TTWayCmd(msg)
    end
end

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
function Nx:UnitDGet (target)
    if Nx.db.profile.Debug.DebugUnit then

        local guid = UnitGUID (target)
        if guid then

            local id = tonumber (strsub (guid, 7, 10), 16)
            local typ = tonumber (strsub (guid, 5, 5), 16)

            local data = Nx.db.profile.Debug.DBUnit or {}
            local ver = 2

            if (data["Ver"] or 0) < ver then
                data = {}
                data["Ver"] = ver
            end

            Nx.db.profile.Debug.DBUnit = data

            return data, guid, id, typ
        end
    end
end

---
-- Capture position of targeted unit
-- Stores NPC location data for debugging
--
function Nx:UnitDCapture()

    local data, guid, id, typ = self:UnitDGet ("target")
    if data and typ == 3 then

        local mid = Nx.Map:GetCurrentMapAreaID()
        local plZX, plZY = Nx.Map.GetPlayerMapPosition ("player")
        if mid and (plZX > 0 or plZY > 0) then

            local s = data[id] or "0~0~~~~"
            local reactA, reactH, _, _, _, tipStr = Nx.Split ("~", s)

            data[id] = format ("%s~%s~%s~%s~0~%s", reactA, reactH, mid, self:PackXY (plZX * 100, plZY * 100), tipStr)

            Nx.prt ("UnitDCap: %s, %s, %s", id, plZX * 10000, plZY * 10000)

        else

            Nx.prt (L["Unit map error"])
        end
    end
end

---
-- Add unit debug info to tooltip
-- Shows GUID and position data for moused-over unit
--
function Nx:UnitDTip()
    local data, guid, id, typ = self:UnitDGet ("mouseover")
    if data and typ == 3 then

        local midCur = Nx.Map:GetCurrentMapAreaID()
        local plZX, plZY = Nx.Map.GetPlayerMapPosition ("player")
        if midCur and (plZX > 0 or plZY > 0) then

            local react = UnitReaction ("mouseover", "player")

            local s = data[id]

            local reactA, reactH, mid, xy, dist = Nx.Split ("~", s or "0~0~~000000~9")

            reactA = reactA or 0
            reactH = reactH or 0

            local x, y = self:UnpackXY (xy)

            if Nx.PlFactionNum == 0 then
                reactA = react
            else
                reactH = react
            end

            dist = tonumber (dist)

            local dcur = 9
            if CheckInteractDistance ("mouseover", 1) then        -- 28 yards
                dcur = 2
            end
            if CheckInteractDistance ("mouseover", 3) then        -- 9.9 yards
                dcur = 1
            end

            if dcur <= dist then
                dist = dcur
                mid = midCur
                x = plZX * 100
                y = plZY * 100
            end

            local tipStr = ""
            local tip = GameTooltip
            local textName = "GameTooltipTextLeft"

            for n = 1, tip:NumLines() do
                local s = _G[textName .. n]:GetText()
                if s then
                    tipStr = tipStr .. s .. "^"
                end
            end

            data[id] = format ("%s~%s~%s~%s~%s~%s", reactA, reactH, mid, self:PackXY (x, y), dist, tipStr)

            if IsControlKeyDown() then
                Nx.prt ("UnitDTip: %s %s, %d, %d (%d)", id, react or "nil", x * 100 + .5, y * 100 + .5, dist)
            end

            if IsShiftKeyDown() and IsControlKeyDown() and (x > 0 or y > 0) then

                local Map = Nx.Map
                local mapId = Map:GetCurrentMapId()
                local m = Map:GetMap (1)

                local tar = m:SetTargetXY (mapId, x, y, "UnitD " .. id)
                  tar.Radius = 1
            end
        else
            Nx.prt (L["Unit map error"])
        end
    end
end

---
-- Handle entering combat
--
function Nx:OnPlayer_regen_disabled()
    Nx.Window:UpdateCombat()
end

---
-- Handle leaving combat
--
function Nx:OnPlayer_regen_enabled()
    Nx.Window:UpdateCombat()
end

---
-- Handle spell cast sent event
-- Detects gathering spells (herbs/mining) to record nodes
--
function Nx:OnUnit_spellcast_sent (event, arg1, arg2, arg3, arg4)
    pcall(function()
        if arg1 == "player" then
            local Nx = Nx
            if Nx:IsGathering(arg2) == L["Herb Gathering"] then
                Nx.GatherTarget = Nx.TooltipLastText

                if Nx.db.profile.Debug.DBGather then
                    Nx.prt (L["Gather"] .. ": %s %s", arg2, Nx.GatherTarget or "nil")
                end

                if Nx.GatherTarget then
                    Nx.UEvents:AddHerb (Nx.GatherTarget)
                    Nx.GatherTarget = nil
                end

            elseif Nx:IsGathering(arg2) == L["Mining"] then
                Nx.GatherTarget = Nx.TooltipLastText

                if Nx.db.profile.Debug.DBGather then
                    Nx.prt (L["Gather"] .. ": %s %s", arg2, Nx.GatherTarget)
                end

                if Nx.GatherTarget then
                    Nx.UEvents:AddMine (Nx.GatherTarget)
                    Nx.GatherTarget = nil
                end
            elseif arg2 == L["Searching for Artifacts"] then
                Nx.UEvents:AddOpen ("Art", arg4)
            elseif arg2 == L["Extract Gas"] then
                Nx.UEvents:AddOpen ("Gas", L["Extract Gas"])
            elseif arg2 == L["Logging"] then
                Nx.GatherTarget = Nx.TooltipLastText
                if Nx.GatherTarget then
                    Nx.UEvents:AddTimber (Nx.GatherTarget)
                    Nx.GatherTarget = nil
                end
            elseif arg2 == L["Opening"] or arg2 == L["Opening - No Text"] then
                Nx.GatherTarget = Nx.TooltipLastText
                if arg4 == L["Glowcap"] then
                    Nx.UEvents:AddHerb (arg4)
                elseif arg4 == L["Everfrost Chip"] then
                    Nx.UEvents:AddOpen ("Everfrost", arg4)
                end
            end
        end
    end)
end

---
-- Handle zone change event
-- Records zone entry in events list
--
function Nx:OnZone_changed_new_area (event)
    Nx.UEvents:AddInfo (L["Entered"])
    Nx.Com:OnEvent (event)
end

---
-- Handle player level up event
-- Records level gain in events list
--
function Nx:OnPlayer_level_up (event, arg1)
    Nx.UEvents:AddInfo (format (L["Level"] .. " %d", arg1))
    Nx.Com:OnPlayer_level_up (event, arg1)
end

---
-- Handle party/raid roster change
-- Updates group member cache
--
function Nx.OnParty_members_changed()
    local self = Nx

    local members = {}
    self.GroupMembers = members

    local memberCnt = MAX_PARTY_MEMBERS
    local unitName = "party"

    if IsInRaid() then
        memberCnt = MAX_RAID_MEMBERS
        unitName = "raid"
    end

    self.GroupType = unitName

    for n = 1, memberCnt do

        local unit = unitName .. n
        local name = UnitName (unit)
        if name then
            members[name] = n
        end
    end
    if Nx.Quest then
        Nx.Quest.OnParty_members_changed()
    end
end

---
-- Handle battleground score update
-- Tracks and displays player's PvP statistics
--
function Nx:OnUpdate_battlefield_score (event)
    local plName = UnitName ("player")
    local scores = GetNumBattlefieldScores()
    local cb = Nx.Combat

    local show

    for n = 1, scores do
        local name, kbs, hks, deaths, honor, faction, race, class, classCap, damDone, healDone = GetBattlefieldScore (n)
        if name == plName then

            honor = floor (honor)    --V4 returns weird fractions

            local any = kbs + deaths + hks + honor

            if any > 0 and (cb.KBs ~= kbs or cb.Deaths ~= deaths or cb.HKs ~= hks or cb.Honor ~= honor) then
                cb.KBs = kbs
                cb.Deaths = deaths
                cb.HKs = hks
                cb.Honor = honor

                show = true
            end

            cb.DamDone = damDone
            cb.HealDone = healDone

            break
        end
    end

    if show and Nx.db.profile.Battleground.ShowStats then

        local kbrank = 1

        for n = 1, scores do
            local name, kbs = GetBattlefieldScore (n)
            if name ~= plName then

                if kbs > cb.KBs then
                    kbrank = kbrank + 1
                end
            end
        end

        Nx.prt ("%s KB (#%d), %s " .. L["Deaths"] .. ", %s HK, %d " .. L["Bonus"], cb.KBs, kbrank, cb.Deaths, cb.HKs, cb.Honor)
    end

end

-------------------------------------------------------------------------------
-- MAIN UPDATE LOOP
-- Called every frame to update addon state
-------------------------------------------------------------------------------

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
            local slen = 0
            pcall(function() slen = #s end)
            if Nx.Tick % 4 == 1 and GameTooltipTextLeft1:IsVisible() and slen > 5 then
                local textDiff = true
                pcall(function() textDiff = (Nx.TooltipLastDiffText ~= s) end)
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

    --[[if Nx.WhatsNewUnread() then
        if Nx.Tick % 50 == 0 then
            if Nx.GlowOn then
                NXMiniMapBut:SetNormalTexture("Interface\\AddOns\\Carbonite\\Gfx\\MMBut")
                Nx.GlowOn = false
            else
                NXMiniMapBut:SetNormalTexture("Interface\\AddOns\\Carbonite\\Gfx\\MMButFilled")
                Nx.GlowOn = true
            end
        end
    end]]--
    if not Nx.Whatsnew.HasWhatsNew then -- Adding it here to be at bottom of menu always.
        Nx.Whatsnew.HasWhatsNew = true
        Nx.NXMiniMapBut.Menu:AddItem(0,"")
        local function func ()
            Nx.Whatsnew:ToggleShow()
        end
        Nx.NXMiniMapBut.Menu:AddItem(0, L["Whats New!"], func, Nx.NXMiniMapBut)
    end

end

---
-- Check if there are unread what's new entries
-- @return  true if any entries are newer than last read time
--
function Nx:WhatsNewUnread()
    for a, b in pairs(Nx.Whatsnew.Categories) do
        for c, d in pairs(Nx.Whatsnew[b]) do
            if Nx.db.profile.Whatsnew.lastreadtime < c then
                return true
            end
        end
    end
    return false
end

---
-- Toggle the What's New window visibility
--
function Nx.Whatsnew:ToggleShow()

    if not self.Win then
        self:Create()
    end

    self.Win:Show (not self.Win:IsShown())

    if self.Win:IsShown() then
        self:Update()
    end
end

---
-- Create the What's New window
-- Sets up list view with date entries
--
function Nx.Whatsnew:Create()
    local win = Nx.Window:Create ("NxWhatsNew", nil, nil, nil, 1)
    self.Win = win
    self.SelectedLine = 1
    win.Frm.NxInst = self
    win:CreateButtons (true, true)
    win:InitLayoutData (nil, -.25, -.15, -.5, -.6)
    win.Frm:SetToplevel (true)
    win:Show (false)
    win.Frm:SetScript ("OnHide",self.Recordtime)
    tinsert (UISpecialFrames, win.Frm:GetName())
    Nx.List:SetCreateFont ("Font.Medium", 16)
    local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm)
    self.List = list
    list:SetUser (self, self.OnListEvent)
    list:SetLineHeight (4)
    list:ColumnAdd ("", 1, 24)
    list:ColumnAdd ("Date", 2, 200)
    list:SetUser (self, self.OnListEvent)
    win:Attach (list.Frm, 0, .2, 0, 1)
    local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm)
    self.WhatsNewList = list
    list:ColumnAdd ("", 1, 500)
    win:Attach (list.Frm, .2, 1, 0, 1)
    local bw, bh = win:GetBorderSize()
    local pos = 150
    for a,b in pairs(Nx.Whatsnew.Categories) do
        local function func()
            Nx.Whatsnew:Cat_button(a)
        end
        local but = Nx.Button:Create (win.Frm, "Txt64", b, nil, pos, -bh, "TOPLEFT", string.len(b)*10, 20, func, self)
        pos = pos + but.Frm:GetWidth()
    end
    self:Update()
    self.List:Select (0)
    self.List:FullUpdate()
end

function Nx.Whatsnew:Recordtime()
    Nx.db.profile.Whatsnew.lastreadtime = time()
    NXMiniMapBut:SetNormalTexture("Interface\\AddOns\\Carbonite\\Gfx\\MMBut")
end

function Nx.Whatsnew:Cat_button(num)
    Nx.Whatsnew.WhichCat = num
    Nx.Whatsnew.SelectedLine = 1
    Nx.Whatsnew:Update()
end

function Nx.Whatsnew:OnListEvent (eventName, sel, val2, click)
    local data = self.List:ItemGetData (sel) or 0
    local id = data % 1000
    self.SelectedLine = id
    if eventName == "select" then
        self:Update()
    end
end

function Nx.Whatsnew:Update()
    self.Win:SetTitle (L["Carbonite What's New"])
    local list = self.List
    list:Empty()
    local cnt = 1
    local display = {}
    local cat = Nx.Whatsnew.Categories[Nx.Whatsnew.WhichCat]
    for a,b in pairs(Nx.Whatsnew[cat]) do
        list:ItemAdd(cnt)
        list:ItemSet(2, date("%m/%d/%y",a))
        if cnt == self.SelectedLine then
            display = b
        end
        cnt = cnt + 1
    end
    list:Update()
    list = self.WhatsNewList
    list:Empty()
    cnt = 1
    for a,b in pairs(display) do
        list:ItemAdd(cnt)
        list:ItemSet(1, b)
        cnt = cnt + 1
    end
    list:Update()
end

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
function Nx:ShowMessage (msg, func1Txt, func1, func2Txt, func2)

    local pop = StaticPopupDialogs["NxMsg"]

    if not pop then
        pop = {
            ["whileDead"] = 1,
            ["hideOnEscape"] = 1,
            ["timeout"] = 0,
        }
        StaticPopupDialogs["NxMsg"] = pop
    end

    pop["text"] = msg
    pop["button1"] = func1Txt
    pop["OnAccept"] = func1
    pop["button2"] = func2Txt
    pop["OnCancel"] = func2

    pop["OnShow"] = function (this)
        this:SetFrameStrata("FULLSCREEN_DIALOG")
        this:SetFrameLevel(100)
    end

    StaticPopup_Show ("NxMsg")
end

---
-- Show a generic edit box dialog with callbacks
-- @param msg         Prompt message
-- @param val         Initial value in edit box
-- @param userData    Data to pass to callback
-- @param funcAccept  Accept button callback
-- @param funcCancel  Cancel button callback
--
function Nx:ShowEditBox (msg, val, userData, funcAccept, funcCancel)

--    Nx.prt ("ShowEditBox")

    local pop = StaticPopupDialogs["NxEdit"]

    if not pop then

        pop = {
            ["whileDead"] = 1,
            ["hideOnEscape"] = 1,
            ["timeout"] = 0,
            ["exclusive"] = 1,
            ["hasEditBox"] = 1,
        }
        StaticPopupDialogs["NxEdit"] = pop
    end

    pop["maxLetters"] = 110
    pop["text"] = msg

    Nx.ShowEditBoxVal = tostring (val)
    Nx.ShowEditBoxUData = userData
    Nx.ShowEditBoxFunc = funcAccept

    pop["OnAccept"] = function (this)
        if Nx.ShowEditBoxFunc then
            Nx.ShowEditBoxFunc (_G[this:GetName().."EditBox"]:GetText(), Nx.ShowEditBoxUData)
        end
    end

    pop["EditBoxOnEnterPressed"] = function (this)
        if Nx.ShowEditBoxFunc then
            Nx.ShowEditBoxFunc (_G[this:GetParent():GetName().."EditBox"]:GetText(), Nx.ShowEditBoxUData)
        end
        this:GetParent():Hide()
    end

    pop["EditBoxOnEscapePressed"] = function (this)
        this:GetParent():Hide()
    end

    pop["OnShow"] = function (this)
        this:SetFrameStrata("FULLSCREEN_DIALOG")
        this:SetFrameLevel(100)

        ChatEdit_FocusActiveWindow()
        local eb = _G[this:GetName().."EditBox"]
        eb:SetFocus()
        eb:SetText (Nx.ShowEditBoxVal)
        eb:HighlightText()
    end

    pop["OnHide"] = function (this)
        _G[this:GetName().."EditBox"]:SetText ("")
    end

    pop["button1"] = ACCEPT
    pop["button2"] = CANCEL
    pop["OnCancel"] = funcCancel

    StaticPopup_Show ("NxEdit")
end

---
-- Show trial limitation message (stub)
--
function Nx:ShowMessageTrial()
end

---
-- Find the currently active chat frame edit box
-- Returns the edit box if one is open for typing
-- @return  Active chat edit box or nil
--
function Nx:FindActiveChatFrameEditBox()
    return ChatEdit_GetActiveWindow()
end

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
function Nx:GetData (name, ch)

    ch = ch or Nx.CurCharacter

    if name == "Events" then
        return ch.E

    elseif name == "List" then
        return ch["L"]

    elseif name == "Quests" then
        return ch.Q

    elseif name == "Win" then
        return Nx.db.profile.WinSettings

    elseif name == "Herb" then
        return Nx.db.profile.GatherData.NXHerb
    elseif name == "Timber" then
        return Nx.db.profile.GatherData.NXTimber
    elseif name == "Mine" then
        return Nx.db.profile.GatherData.NXMine

    end
end

---
-- Copy character data between characters
-- @param srcName  Source character name (nil = export current to all)
-- @param dstName  Destination character name
-- @return         true on success
--
function Nx:CopyCharacterData (srcName, dstName)

    if not srcName then

        -- Export me to everyone

        local sch = Nx.CurCharacter

        for rc, dch in pairs (Nx.db.global.Characters) do

            if dch ~= sch then
                dch["L"] = sch["L"]
                dch["TBar"] = sch["TBar"]
            end
        end
    else

        local sch = Nx:FindCharacter (srcName)
        local dch = Nx:FindCharacter (dstName)

        if not sch or not dch then
            Nx.prt (L["Missing character data!"])
            return
        end

        -- Change references. Save will make copy
        dch["L"] = sch["L"]
        dch["TBar"] = sch["TBar"]
    end

    return true
end

---
-- Delete a character's saved data
-- @param srcName  Character name to delete
--
function Nx:DeleteCharacterData (srcName)

    self:DeleteCharacter (srcName)
    self:CalcRealmChars()
    if Nx.Warehouse then
        self.Warehouse:Update()
    end
end

---
-- Get toolbar layout data for current character
-- @return  Toolbar configuration table
--
function Nx:GetDataToolBar()
    return Nx.CurCharacter["TBar"]
end

---
-- Get HUD options
-- @return  HUD configuration table
--
function Nx:GetHUDOpts()
    return Nx.db.profile.HUDOpts
end

---
-- Get captured (recorded) data
-- @return  Global capture table
--
function Nx:GetCap()
    return Nx.db.global.Capture
end

---
-- Find or create a capture data entry
-- @param t    Table to search in
-- @param key  Key to find/create
-- @return     Data table for the key
--
function Nx:CaptureFind (t, key)

    assert (type (t) == "table" and key)

    local d = t[key] or {}
    t[key] = d
    return d
end

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

---
-- Initialize character-specific data
-- Creates or migrates character record
--
function Nx:InitCharacter()
    local chars = Nx.db.global.Characters
    local fullName = self:GetRealmCharName()
    local ch = chars[fullName]

    if not ch or ch.Version < Nx.VERSIONCHAR then
        -- Add a new character
        ch = {}
        chars[fullName] = ch

        ch.Version = Nx.VERSIONCHAR

        ch.E = {}    -- Events
    end

    Nx.CurCharacter = ch

    ch["Opts"] = ch["Opts"] or {}        -- Character options

    ch["L"] = ch["L"] or {}            -- List

    if not ch["TBar"] then
        ch["TBar"] = {}            -- Tool Bar layouts
    end
    self:DeleteOldEvents()
    ch.NXLoggedOnNum = ch.NXLoggedOnNum or 0 + 1
    --
    self:CalcRealmChars()
end


---
-- Get the full realm.character name for current player
-- @return  "RealmName.CharacterName"
--
function Nx:GetRealmCharName()
    return GetRealmName() .. "." .. UnitName ("player")
end

---
-- Build list of characters on current realm (including connected realms)
-- Populates Nx.RealmChars with sorted list
--
function Nx:CalcRealmChars()
    local chars = Nx.db.global.Characters
    local realmName = GetRealmName()
    local fullName = realmName .. "." .. UnitName ("player")
    local t = {}
    for rc, v in pairs (chars) do
        if v ~= Nx.CurCharacter then
            local rname = Nx.Split (".", rc)
            if rname == realmName then
                tinsert (t, rc)
            end
        end
    end
    local connectedrealms = GetAutoCompleteRealms()
    if connectedrealms then
        for i=1,#connectedrealms do
            for rc, v in pairs (chars) do
                if v ~= Nx.CurCharacter then
                    local rname = Nx.Split (".", rc)
                    if rname == connectedrealms[i] and connectedrealms[i] ~= realmName then
                        tinsert (t, rc)
                    end
                end
            end
        end
    end
    sort (t)            -- Alphabetical
    tinsert (t, 1, fullName)    -- Put me at top
    self.RealmChars = t
    -- Fix char data
    for cnum, rc in ipairs (self.RealmChars) do
        local ch = chars[rc]
        if ch then
            if ch["XP"] then
                ch["XPMax"] = ch["XPMax"] or 1
                ch["XPRest"] = ch["XPRest"] or 0
                ch["LXP"] = ch["LXP"] or 0
                ch["LXPMax"] = ch["LXPMax"] or 1
                ch["LXPRest"] = ch["LXPRest"] or 0
            end
            ch["TimePlayed"] = ch["TimePlayed"] or 0
        end
    end
end

---
-- Find character data by name
-- Searches current realm first, then accepts "realm.name" format
-- @param name  Character name or "realm.name"
-- @return      Character data table or nil
--
function Nx:FindCharacter (name)

    for cnum, rc in ipairs (Nx.RealmChars) do

        local ch = Nx.db.global.Characters[rc]
        if ch then

            local rname, cname = Nx.Split (".", rc)
            if cname == name then
                return ch
            end
        end
    end

    return Nx.db.global.Characters[name]
end

---
-- Delete character data by name
-- @param name  Character name or "realm.name"
--
function Nx:DeleteCharacter (name)

    for cnum, rc in ipairs (Nx.RealmChars) do

        local ch = Nx.db.global.Characters[rc]
        if ch then

            local rname, cname = Nx.Split (".", rc)
            if cname == name then
                Nx.db.global.Characters[rc] = nil
                return
            end
        end
    end

    Nx.db.global.Characters[name] = nil
end

---
-- Get player's class name (formatted)
-- @return  Capitalized class name
--
function Nx:GetUnitClass()
    local _, cls = UnitClass ("player")
    cls = gsub (Nx.Util_CapStr (cls), L["Deathknight"], L["Death Knight"])
    return cls
end

---
-- Record current character state (level, class)
-- Called periodically during gameplay
--
function Nx:RecordCharacter()
    local ch = self.CurCharacter
    ch["Level"] = UnitLevel ("player")
    ch["Class"] = Nx:GetUnitClass()
end

---
-- Delete old events from all characters
-- Migrates old format and trims to max count
--
function Nx:DeleteOldEvents()
    for rc, ch in pairs (Nx.db.global.Characters) do
        if not ch.E or ch.E["Info"] then    -- Missing or old table format
            ch.E = {}
        end
        self:DeleteOldEvent (ch.E, 60)
    end
end

---
-- Trim event list to maximum size
-- @param ev    Event array
-- @param maxE  Maximum entries to keep
--
function Nx:DeleteOldEvent (ev, maxE)
    if #ev > maxE then

        for n = 1, #ev - maxE do
            tremove (ev, 1)
        end
    end
end

---
-- Add an event to current character's event log
-- @param event  Event type: "I"=info, "K"=kill, "D"=death, "H"=herb, "M"=mine
-- @param name   Event description
-- @param time   Timestamp from Nx:Time()
-- @param mapId  Map ID where event occurred
-- @param x      Zone X coordinate (0-100)
-- @param y      Zone Y coordinate (0-100)
-- @param data   Optional extra data string
--
function Nx:AddEvent (event, name, time, mapId, x, y, data)

    local ev = Nx.CurCharacter.E

--[[
    local i = #ev + 1

    local item = {}

    item.NXName = name
    item.NXTime = time
    item.NXMapId = mapId
    item.NXX = x
    item.NXY = y
--]]

    local s = Nx:PackXY (x, y)
    name = gsub (name, "^", "")

    s = format ("%s^%.0f^%d^%s^%s", event, time, mapId or 0, s, name)

    if data then
        s = s .. "^" .. data
    end

    tinsert (ev, s)
end

--------

--function Nx:GetEventType (evStr)
--    return strsub (evStr, 1, 1)
--end

---
-- Extract map ID from packed event string
-- @param evStr  Packed event string
-- @return       Map ID number
--
function Nx:GetEventMapId (evStr)
    local _, _, map = Nx.Split ("^", evStr)
    return tonumber (map) or 0
end

---
-- Unpack an event string to its components
-- @param evStr  Packed event string
-- @return       type, time, mapId, x, y, text, data
--
function Nx:UnpackEvent (evStr)
    local typ, tm, map, xy, text, data = Nx.Split ("^", evStr)
    tm = tonumber (tm)
    map = tonumber (map) or 0
    local x, y = Nx:UnpackXY (xy)
    return typ, tm, map, x, y, text, data
end

--------

function Nx:AddInfoEvent (name, time, mapId, x, y)
    self:AddEvent ("I", name, time, mapId, x, y)
end

function Nx:AddDeathEvent (name, time, mapId, x, y)
    self:AddEvent ("D", name, time, mapId, x, y)
end

function Nx:AddKillEvent (name, time, mapId, x, y, npcId)

    local ev = self.CurCharacter.E

    local kills = 1

    for k, item in ipairs (ev) do

        local typ, tm, mapId, x, y, text = self:UnpackEvent (item)

        if typ == "K" and text == name then
            kills = kills + 1
        end
    end

    -- Pack kills count and NPC ID into the single data field with a "|"
    -- separator. Old records had just "<kills>"; the parser below tolerates
    -- both "<kills>" and "<kills>|<npcId>".
    local data
    if npcId then
        data = format("%d|%d", kills, npcId)
    else
        data = format("%d", kills)
    end
    self:AddEvent ("K", name, time, mapId, x, y, data)
end

function Nx:AddHerbEvent (name, time, mapId, x, y)
    self:AddEvent ("H", name, time, mapId, x, y)
end

function Nx:AddMineEvent (name, time, mapId, x, y)
    self:AddEvent ("M", name, time, mapId, x, y)
end

function Nx:AddTimberEvent (name, time, mapId, x, y)
    self:AddEvent ("T", name, time, mapId, x, y)
end

-------------------------------------------------------------------------------
-- TITLE SCREEN ANIMATION
-- Animated logo displayed on addon load
-------------------------------------------------------------------------------

---
-- Initialize the title screen animation
-- Creates frame with logo and schedules animation process
--
function Nx.Title:Init()

    local f = CreateFrame ("Frame", nil, UIParent, "BackdropTemplate")
    f.NxInst = self
    self.Frm = f

    f:SetFrameStrata ("HIGH")

    f:SetWidth (400)
    f:SetHeight (192)

    local bk = {
        ["bgFile"] = "Interface\\Buttons\\White8x8",
        ["edgeFile"] = "Interface\\DialogFrame\\UI-DialogBox-Border",
        ["tile"] = true,
        ["tileSize"] = 16,
        ["edgeSize"] = 16,
        ["insets"] = { ["left"] = 2, ["right"] = 2, ["top"] = 2, ["bottom"] = 2 }
    }

    f:SetBackdrop (bk)
    f:SetBackdropColor (0, 0, .1, 1)

    local lf = CreateFrame ("Frame", nil, f, "BackdropTemplate")

    lf:SetWidth (256)
    lf:SetHeight (128)

    lf:SetPoint ("CENTER", 0, 0)

    local t = lf:CreateTexture()
    t:SetTexture (Nx.Logo)
--    t:SetVertexColor (1, 1, 1, 1)
    t:SetAllPoints (lf)
    lf.texture = t

    for n = 1, 2 do
        local fstr = f:CreateFontString()
        self["NXFStr"..n] = fstr
        fstr:SetFontObject ("GameFontNormal")
        fstr:SetJustifyH ("CENTER")
        fstr:SetPoint ("TOPLEFT", 0, -158 - (n - 1) * 14)
        fstr:SetWidth (400)
        fstr:Show()
    end

    local str

    if Nx.VERMINOR > 0 then
        str = NXTITLEFULL .. " |cffe0e0ff" .. L["Version"] .. " %d.%d Build %s"
    else
        str = NXTITLEFULL .. " |cffe0e0ff" .. L["Version"] .. " %d.%d Build %s"
    end

    str = format (str, Nx.VERMAJOR,Nx.VERMINOR*10, Nx.BUILD)

    self.NXFStr1:SetText (str)
    self.NXFStr2:SetText ("|cffe0e0ff" .. L["Maintained by"] .. " The community.")

    Nx.Proc:New (self, self.TickWait, 40)

--    f:Show()
end

function Nx.Title:TickWait (proc)

    Nx.Map:StartupZoom()
    Nx.Proc:SetFunc (proc, self.TickWait2)
    return 30
end

function Nx.Title:TickWait2 (proc)
    self.X = 0
    self.Y = GetScreenHeight() * .4
    self.XV = 0
    self.YV = 0
    self.Scale = .8
    self.ScaleTarget = .8
    self.Alpha = 0
    self.AlphaTarget = 1

--    Nx.prt ("Y %s", self.Y)

    if Nx.db.profile.General.TitleSoundOn then
        PlaySound(SOUNDKIT.READY_CHECK);
    end

    Nx.Proc:SetFunc (proc, self.Tick)
end

function Nx.Title:Tick()

    local this = self.Frm

--PAIDS!
    if not Nx.db.profile.General.TitleOff then
        this:Hide()
    end
--PAIDE!

    self.X = self.X + self.XV
    self.Y = self.Y + self.YV

    self.Scale = Nx.Util_StepValue (self.Scale, self.ScaleTarget, .8 / 60)

    this:SetPoint ("CENTER", self.X / self.Scale, self.Y / self.Scale)
    this:SetScale (self.Scale)

--    Nx.prt ("Title %f %f", elapsed, self.Alpha)

    self.Alpha = Nx.Util_StepValue (self.Alpha, self.AlphaTarget, .8 / 60)
    this:SetAlpha (self.Alpha)

    if self.Alpha == 1 then

        local sw = GetScreenWidth() / 2
        local sh = GetScreenHeight() / 2
        self.XV = (sw * .95 - self.X) / 80
        self.YV = (sh * .95 - self.Y) / 80

        self.ScaleTarget = .03
        self.AlphaTarget = 0

        return 1 * 60
    end

    if self.Alpha == 0 then

        this:Hide()
        return -1    -- Die
    end
end

-------------------------------------------------------------------------------
-- AUCTION HOUSE ASSISTANT
-- Provides buyout-per-item calculations and display
-------------------------------------------------------------------------------

---
-- Handle auction house opening
-- Hooks update function if AuctionUI is loaded
--
function Nx.AuctionAssist.OnAuction_house_show()

--    Nx.prt ("OnAUCTION_HOUSE_SHOW")

    if IsAddOnLoaded ("Blizzard_AuctionUI") then
        hooksecurefunc ("AuctionFrameBrowse_Update", Nx.AuctionAssist.AuctionFrameBrowse_Update)
        Nx.AuctionAssist:Create()
    end
end

---
-- Handle auction house closing
-- Hides window and clears item list
--
function Nx.AuctionAssist.OnAuction_house_closed()
    local self = Nx.AuctionAssist
    if self.Win then
        self.Win:Show (false)
        self.ItemList:Empty()
    end
end

function Nx.AuctionAssist.OnAuction_item_list_update()
--    Nx.prt ("OnAUCTION_ITEM_LIST_UPDATE")
    Nx.AuctionAssist:Update()
end

--------
-- Create favorites window

function Nx.AuctionAssist:Create()
end

--------
-- On list events

function Nx.AuctionAssist:OnListEvent (eventName, sel, val2, click)

--    Nx.prt ("Guide list event "..eventName)

    local name = self.List:ItemGetData (sel)

    Nx.prt ("%s", name)

    BrowseName:SetText (name)
    AuctionFrameBrowse_Search()
end

function Nx.AuctionAssist:Update()

end

--------

function Nx.AuctionAssist.AuctionFrameBrowse_Update()

    if not Nx.AuctionShowBOPer then
        return
    end

--    Nx.prt ("Auction")

    local low = 99999999
    local lowName
    local lowIName

    local numBatchAuctions, totalAuctions = GetNumAuctionItems ("list")
    local offset = FauxScrollFrame_GetOffset (BrowseScrollFrame)
    local last = offset + NUM_BROWSE_TO_DISPLAY

--    Nx.prt ("Auction off %d %d %d", offset, numBatchAuctions, totalAuctions)

    for n = 1, NUM_AUCTION_ITEMS_PER_PAGE do

        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo ("list", n)

--        Nx.prt ("Auction #%d %d %d", n, buyoutPrice, count)

        local index = n + NUM_AUCTION_ITEMS_PER_PAGE * AuctionFrameBrowse["page"]

        if index > numBatchAuctions + NUM_AUCTION_ITEMS_PER_PAGE * AuctionFrameBrowse["page"] then
            break
        end

        if bidAmount == 0 then
            requiredBid = minBid
        else
            requiredBid = bidAmount + minIncrement
        end

        if requiredBid >= MAXIMUM_BID_PRICE then
            buyoutPrice = requiredBid
        end

        if buyoutPrice > 0 then

            local price1 = floor (buyoutPrice / count)

            if n > offset and n <= last then

                local buttonName = "BrowseButton" .. (n - offset)
                local itemName = _G[buttonName .. "Name"]

                if itemName then

                    if price1 < low then
                        low = price1
                        lowName = name
                        lowIName = itemName
                    end

--                    Nx.prtVar ("name", buttonName)

                    if count > 1 then

                        itemName:SetText (format ("%s *", name))

                        local color = ITEM_QUALITY_COLORS[quality]
                        itemName:SetVertexColor (color.r, color.g, color.b)

                        local bf = _G[buttonName.."BuyoutFrameMoney"]
                        if bf then
                            MoneyFrame_Update (bf:GetName(), price1)
                        end
                    end
                end

            elseif price1 < low then
                low = price1
                lowName = nil
            end
        end
    end

    if lowName then
        lowIName:SetText (format ("%s * low", lowName))
    end
end

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
-- GATHERING SYSTEM
-- Tracks and stores locations of herb/mining nodes
-- Data structure: { skillLevel, iconPath, localizedName }
-------------------------------------------------------------------------------

Nx.GatherInfo = {
    [" "] = {    -- Misc
        ["Art"] = { 0, "Trade_Archaeology", L["Artifact"]},
        ["Everfrost"] = { 0, "spell_shadow_teleport", L["Everfrost"]},
        ["Gas"] = { 0, "inv_gizmo_zapthrottlegascollector",    L["Gas"]},
    },
    ["L"] = {    -- Timber (WoD Lumber Mill)
        { 1, "inv_tradeskillitem_03", L["Small Timber"]},
        { 2, "inv_tradeskillitem_03", L["Medium Timber"]},
        { 3, "inv_tradeskillitem_03", L["Large Timber"]},
    },
    ["H"] = {    -- Herbs (4th element is itemId for localization)
        { 340,    "inv_misc_herb_ancientlichen",L["Ancient Lichen"], 22790},
        { 220,    "inv_misc_herb_13",L["Arthas' Tears"], 8836},
        { 300,    "inv_misc_herb_17",L["Black Lotus"], 13468},
        { 235,    "inv_misc_herb_14",L["Blindweed"], 8839},
        { 1,    "inv_misc_herb_11a",L["Bloodthistle"], 22710},
        { 70,    "inv_misc_root_01",L["Briarthorn"], 2450},
        { 100,    "inv_misc_herb_01",L["Bruiseweed"], 2453},
        { 270,    "inv_misc_herb_dreamfoil",L["Dreamfoil"], 13463},
        { 315,    "inv_misc_herb_dreamingglory",L["Dreaming Glory"], 22786},
        { 15,    "inv_misc_herb_07",L["Earthroot"], 2449},
        { 160,    "inv_misc_herb_12",L["Fadeleaf"], 3818},
        { 300,    "inv_misc_herb_felweed",L["Felweed"], 22785},
        { 205,    "inv_misc_herb_19",L["Firebloom"], 4625},
        { 335,    "inv_misc_herb_flamecap",L["Flame Cap"], 22788},
        { 245,    "inv_mushroom_08",L["Ghost Mushroom"], 8845},
        { 260,    "inv_misc_herb_sansamroot",L["Golden Sansam"], 13464},
        { 170,    "inv_misc_herb_15",L["Goldthorn"], 3821},
        { 120,    "inv_misc_dust_02",L["Grave Moss"], 3369},
        { 250,    "inv_misc_herb_16",L["Gromsblood"], 8846},
        { 290,    "inv_misc_herb_iceCap",L["Icecap"], 13467},
        { 185,    "inv_misc_herb_08",L["Khadgar's Whisker"], 3358},
        { 125,    "inv_misc_herb_03",L["Kingsblood"], 3356},
        { 150,    "inv_misc_root_02",L["Liferoot"], 3357},
        { 50,    "inv_jewelry_talisman_03",L["Mageroyal"], 785},
        { 375,    "inv_misc_herb_manathistle",L["Mana Thistle"], 22793},
        { 280,    "inv_misc_herb_mountainsilversage",L["Mountain Silversage"], 13465},
        { 350,    "inv_misc_herb_netherbloom",L["Netherbloom"], 22791},
        { 350,    "inv_enchant_dustsoul",L["Netherdust Bush"], 32468},
        { 365,    "inv_misc_herb_nightmarevine",L["Nightmare Vine"], 22792},
        { 1,    "inv_misc_flower_02",L["Peacebloom"], 2447},
        { 285,    "inv_misc_herb_plaguebloom",L["Plaguebloom"], 13466},
        { 210,    "inv_misc_herb_17",L["Purple Lotus"], 8831},
        { 325,    "inv_misc_herb_ragveil",L["Ragveil"], 22787},
        { 1,    "inv_misc_herb_10",L["Silverleaf"], 765},
        { 85,    "inv_misc_herb_11",L["Stranglekelp"], 3820},
        { 230,    "inv_misc_herb_18",L["Sungrass"], 8838},
        { 325,    "inv_misc_herb_terrocone",L["Terocone"], 22789},
        { 115,    "inv_misc_flower_01",L["Wild Steelbloom"], 3355},
        { 195,    "inv_misc_flower_03",L["Dragon's Teeth"], 3819},
        { 1,    "inv_mushroom_02",L["Glowcap"], 24245},
        { 350,    "inv_misc_herb_goldclover",L["Goldclover"], 36901},
        { 385,    "inv_misc_herb_talandrasrose",L["Talandra's Rose"], 36907},
        { 400,    "inv_misc_herb_evergreenmoss",L["Adder's Tongue"], 36903},
        { 400,    "inv_misc_herb_goldclover",L["Frozen Herb"], 36908},
        { 400,    "inv_misc_herb_tigerlily",L["Tiger Lily"], 36904},
        { 425,    "inv_misc_herb_whispervine",L["Lichbloom"], 36905},
        { 435,    "inv_misc_herb_icethorn",L["Icethorn"], 36906},
        { 450,    "inv_misc_herb_frostlotus",L["Frost Lotus"], 36908},
        { 360,    "inv_misc_herb_11a",L["Firethorn"], 39970},
        { 425, "inv_misc_herb_azsharasveil", L["Azshara's Veil"], 52983},
        { 425, "inv_misc_herb_cinderbloom", L["Cinderbloom"], 52983},
        { 425, "inv_misc_herb_stormvine", L["Stormvine"], 52987},
        { 475, "inv_misc_herb_heartblossom", L["Heartblossom"], 52986},
        { 500, "inv_misc_herb_whiptail", L["Whiptail"], 52988},
        { 525, "inv_misc_herb_twilightjasmine", L["Twilight Jasmine"], 52984},
        { 600,    "inv_misc_herb_foolscap",L["Fool's Cap"], 79011},
        { 550,    "inv_misc_herb_goldenlotus",L["Golden Lotus"], 72238},
        { 500,    "inv_misc_herb_jadetealeaf",L["Green Tea Leaf"], 72234},
        { 525,    "inv_misc_herb_rainpoppy",L["Rain Poppy"], 72237},
        { 575,    "inv_misc_herb_shaherb",L["Sha-Touched Herb"], 79010},
        { 545,    "inv_misc_herb_silkweed",L["Silkweed"], 72235},
        { 550,    "inv_misc_herb_snowlily",L["Snow Lily"], 79010},
        { 550,    "inv_misc_herb_chamlotus",L["Chameleon Lotus"], 97619},
        -- WoD Herbs
        { 1,    "inv_misc_herb_frostweed",L["Frostweed"], 109124},
        { 1,    "inv_misc_herb_flytrap",L["Gorgrond Flytrap"], 109126},
        { 1,    "inv_misc_herb_starflower",L["Starflower"], 109127},
        { 1,    "inv_misc_herb_arrowbloom",L["Nagrand Arrowbloom"], 109128},
        { 1,    "inv_misc_herb_taladororchid",L["Talador Orchid"], 109129},
        { 1,    "inv_misc_herb_fireweed",L["Fireweed"], 109125},
        { 1,    "inv_farm_pumpkinseed_yellow",L["Withered Herb"], 109125},
        -- Legion Herbs
        { 1,    "inv_herbalism_70_aethril",L["Aethril"], 124101},
        { 1,    "inv_herbalism_70_dreamleaf",L["Dreamleaf"], 124102},
        { 1,    "inv_herbalism_70_felwort",L["Felwort"], 124106},
        { 1,    "inv_herbalism_70_fjarnskaggl",L["Fjarnskaggl"], 124104},
        { 1,    "inv_herbalism_70_foxflower",L["Foxflower"], 124103},
        { 1,    "inv_herbalism_70_starlightrosepetals",L["Starlight Rose"], 124105},
        { 1,    "inv_misc_herb_astralglory",L["Astral Glory"], 151565},
        -- BfA Herbs
        { 1,    "inv_misc_herb_akundasbite",L["Akunda's Bite"], 152507},
        { 1,    "inv_misc_herb_anchorweed",L["Anchor Weed"], 152510},
        { 1,    "inv_misc_herb_riverbud",L["Riverbud"], 152505},
        { 1,    "inv_misc_herb_seastalk",L["Sea Stalks"], 152511},
        { 1,    "inv_misc_herb_pollen",L["Siren's Sting"], 152509},
        { 1,    "inv_misc_herb_starmoss",L["Star Moss"], 152506},
        { 1,    "inv_misc_herb_winterskiss",L["Winter's Kiss"], 152508},
        -- Shadowlands Herbs
        { 1,    "inv_misc_herb_bloodcup",L["Widowbloom"], 168583},
        { 1,    "inv_misc_herb_deathblossom",L["Death Blossom"], 168586},
        { 1,    "inv_misc_herb_risingglory",L["Rising Glory"], 168589},
        { 1,    "inv_misc_herb_marrowroot",L["Marrowroot"], 168583},
        { 1,    "inv_misc_herb_ardenweald",L["Vigil's Torch"], 170554},
        { 1,    "inv_misc_herb_nightshade",L["Nightshade"], 171315},
        -- Dragonflight Herbs
        { 1,    "Inv_misc_herb_dragonsbreath",L["Hochenblume"], 191460},
        { 1,    "Inv_misc_herb_bubblepoppy",L["Bubble Poppy"], 191467},
        { 1,    "Inv_misc_herb_saxifrage",L["Saxifrage"], 191470},
        { 1,    "Inv_misc_herb_writhebark",L["Writhebark"], 191473},
        -- The War Within Herbs
        { 1,    "Inv_misc_herb_mycobloom",L["Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Altered Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Crystallized Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Irradiated Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Lush Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Sporefused Mycobloom"], 210796},
        { 1,    "inv_misc_herb_luredrop",L["Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Altered Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Crystallized Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Irradiated Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Lush Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Sporefused Luredrop"], 210798},
        { 1,    "inv_misc_herb_arathorsspear",L["Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Crystallized Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Irradiated Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Lush Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Sporefused Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_blessingblossom",L["Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Crystallized Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Irradiated Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Lush Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Sporefused Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_orbinid",L["Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Altered Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Crystallized Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Irradiated Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Lush Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Sporefused Orbinid"], 210797},
        -- Midnight Herbs
        { 1,    "inv_misc_herb_silverleaf",L["Argentleaf"], 256963},
        { 1,    "inv_misc_herb_earthroot",L["Azeroot"], 256964},
        { 1,    "inv_misc_herb_mageroyal",L["Mana Lily"], 256965},
        { 1,    "inv_herb_bloodthistle",L["Sanguithorn"], 256966},
        { 1,    "inv_misc_herb_peacebloom",L["Tranquility Bloom"], 256967},
    },
    ["M"] = {    -- Mine node (4th element is itemId for localization)
        { 325,    "inv_ore_adamantium",L["Adamantite Deposit"], 23425},
        { 375,    "inv_misc_gem_01",L["Ancient Gem Vein"], 23426},
        { 1,    "inv_ore_copper_01",L["Copper Vein"], 2770},
        { 230,    "inv_ore_mithril_01",L["Dark Iron Deposit"], 11370},
        { 300,    "inv_ore_feliron",L["Fel Iron Deposit"], 23424},
        { 155,    "inv_ore_copper_01",L["Gold Vein"], 2776},
        { 65,    "inv_ore_thorium_01",L["Incendicite Mineral Vein"], 3340},
        { 150,    "inv_ore_mithril_01",L["Indurium Mineral Vein"], 5833},
        { 125,    "inv_ore_iron_01",L["Iron Deposit"], 2772},
        { 375,    "inv_ore_khorium",L["Khorium Vein"], 23426},
        { 305,    "inv_stone_15",L["Large Obsidian Chunk"], 22203},
        { 75,    "inv_ore_thorium_01",L["Lesser Bloodstone Deposit"], 4278},
        { 175,    "inv_ore_mithril_02",L["Mithril Deposit"], 3858},
        { 275,    "inv_ore_ethernium_01",L["Nethercite Deposit"], 32464},
        { 350,    "inv_ore_adamantium",L["Rich Adamantite Deposit"], 23425},
        { 255,    "inv_ore_thorium_02",L["Rich Thorium Vein"], 10620},
        { 75,    "inv_stone_16",L["Silver Vein"], 2775},
        { 305,    "inv_misc_stonetablet_01",L["Small Obsidian Chunk"], 22202},
        { 230,    "inv_ore_thorium_02",L["Small Thorium Vein"], 10620},
        { 65,    "inv_ore_tin_01",L["Tin Vein"], 2771},
        { 230,    "inv_ore_truesilver_01",L["Truesilver Deposit"], 7911},
        { 350,    "inv_ore_cobalt",L["Cobalt Deposit"], 36909},
        { 375,    "inv_ore_cobalt",L["Rich Cobalt Deposit"], 36909},
        { 425,    "inv_ore_saronite_01",L["Saronite Deposit"], 36912},
        { 425,    "inv_ore_saronite_01",L["Rich Saronite Deposit"], 36912},
        { 450,    "inv_ore_platinum_01",L["Titanium Vein"], 36910},
        { 425,    "item_elementiumore", L["Obsidium Deposit"], 53038},
        { 450,    "item_elementiumore", L["Rich Obsidium Deposit"], 53038},
        { 475,    "item_pyriumore", L["Elementium Vein"], 52185},
        { 500,    "item_pyriumore", L["Rich Elementium Vein"], 52185},
        { 525,    "inv_ore_arcanite_01", L["Pyrite Deposit"], 52183},
        { 525,    "inv_ore_arcanite_01", L["Rich Pyrite Deposit"], 52183},
        { 515,    "inv_ore_ghostiron",L["Ghost Iron Deposit"], 72092},
        { 550,    "inv_ore_ghostiron",L["Rich Ghost Iron Deposit"], 72092},
        { 550,    "inv_ore_manticyte",L["Kyparite Deposit"], 72093},
        { 575,    "inv_ore_manticyte",L["Rich Kyparite Deposit"], 72093},
        { 600,    "inv_ore_trilliumwhite",L["Trillium Vein"], 72094},
        { 600,    "inv_ore_trilliumWhite",L["Rich Trillium Vein"], 72094},
        -- WoD Mining
        { 1,    "inv_ore_trueironore",L["True Iron Deposit"], 109118},
        { 1,    "inv_ore_trueironore",L["Rich True Iron Deposit"], 109118},
        { 1,    "inv_ore_trueironore",L["Smoldering True Iron Deposit"], 109118},
        { 1,    "inv_ore_blackrock_ore",L["Blackrock Deposit"], 109119},
        { 1,    "inv_ore_blackrock_ore",L["Rich Blackrock Deposit"], 109119},
        -- Legion Mining
        { 1,    "inv_felslate",L["Felslate Deposit"], 123919},
        { 1,    "inv_felslate",L["Felslate Seam"], 123919},
        { 1,    "inv_felslate",L["Living Felslate"], 123919},
        { 1,    "inv_leystone",L["Leystone Deposit"], 123918},
        { 1,    "inv_leystone",L["Leystone Seam"], 123918},
        { 1,    "inv_leystone",L["Living Leystone"], 123918},
        { 1,    "inv_misc_starmetal",L["Empyrium Deposit"], 151564},
        { 1,    "inv_misc_starmetal",L["Rich Empyrium Deposit"], 151564},
        { 1,    "inv_misc_starmetal",L["Empyrium Seam"], 151564},
        -- BfA Mining
        { 1,    "inv_ore_monalite",L["Monelite Deposit"], 152512},
        { 1,    "inv_ore_monalite",L["Rich Monelite Deposit"], 152512},
        { 1,    "inv_ore_monalite",L["Monelite Seam"], 152512},
        { 1,    "inv_ore_platinum",L["Platinum Deposit"], 152513},
        { 1,    "inv_ore_platinum",L["Rich Platinum Deposit"], 152513},
        { 1,    "inv_ore_stormsilver",L["Storm Silver Deposit"], 152579},
        { 1,    "inv_ore_stormsilver",L["Rich Storm Silver Deposit"], 152579},
        { 1,    "inv_ore_stormsilver",L["Storm Silver Seam"], 152579},
        -- Shadowlands Mining
        { 1,    "inv_ore_lastrite",L["Laestrite Deposit"], 171828},
        { 1,    "inv_ore_lastrite",L["Rich Laestrite Deposit"], 171828},
        { 1,    "inv_ore_elethium",L["Elethium Deposit"], 171833},
        { 1,    "inv_ore_elethium",L["Rich Elethium Deposit"], 171833},
        { 1,    "inv_ore_solenium",L["Solenium Deposit"], 171829},
        { 1,    "inv_ore_solenium",L["Rich Solenium Deposit"], 171829},
        { 1,    "inv_ore_oxxein",L["Oxxein Deposit"], 171830},
        { 1,    "inv_ore_oxxein",L["Rich Oxxein Deposit"], 171830},
        { 1,    "inv_ore_phaedrite",L["Phaedrum Deposit"], 171831},
        { 1,    "inv_ore_phaedrite",L["Rich Phaedrum Deposit"], 171831},
        { 1,    "inv_ore_sinvyr",L["Sinvyr Deposit"], 171832},
        { 1,    "inv_ore_sinvyr",L["Rich Sinvyr Deposit"], 171832},
        -- Dragonflight Mining
        { 1,    "Inv_ore_tyrivite",L["Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Hardened Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Infurious Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Molten Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Primal Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Rich Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Titan-Touched Serevite Deposit"], 190395},
        { 1,    "Inv_ore_draconium",L["Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Hardened Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Infurious Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Molten Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Primal Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Rich Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Titan-Touched Draconium Deposit"], 189143},
        -- The War Within Mining
        { 1,    "inv_ore_bismuth",L["Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["Crystallized Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["EZ-Mine Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["Rich Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["Weeping Bismuth"], 210930},
        { 1,    "inv_ore_ironclaw_normal",L["Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["Crystallized Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["EZ-Mine Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["Rich Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["Weeping Ironclaw"], 210932},
        { 1,    "inv_ore_nerubian_red",L["Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["Crystallized Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["EZ-Mine Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["Rich Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["Weeping Aqirite"], 210933},
        { 1,    "ui_profession_mining",L["Webbed Ore Deposit"], 210933},
        -- Midnight Mining
        { 1,    "inv_ore_brilliantsilver",L["Brilliant Silver"], 256970},
        { 1,    "inv_ore_refulgentcopper",L["Refulgent Copper"], 256971},
        { 1,    "inv_ore_umbraltin",L["Umbral Tin"], 256972},
    }
}

Nx.GatherRemap = {
    ["NXHerb"] = {
        [47] = 46,        -- Icethorn
    },
    ["NXMine"] = {
        [6] = 9,        -- Gold
        [17] = 20,        -- Silver
        [23] = 22,        -- Rich Cobalt Deposit
        [25] = 24,        -- Rich Saronite Deposit
        [26] = 24,        -- Titanium
    }
}

---
-- Initialize gathering system
-- Must be called after map init for proper node display
--
function Nx:GatherInit()
    if self.DoGatherUpgrade then
        self.DoGatherUpgrade = nil
        Nx:GatherVerUpgrade()
    end
    Nx.GatherVerUpgrade = nil        -- Kill it
    Nx.GatherVerUpgradeType = nil        -- Kill it
end

---
-- Get gather node info by type and ID
-- @param typ  Node type: "H" (herb), "M" (mine)
-- @param id   Node ID number
-- @return     name, iconPath, skillLevel
--
function Nx:GetGather (typ, id)
    local v = Nx.GatherInfo[typ][id]
    if v then
        return v[3], v[2], v[1]
    end
end

-- Cache for quick node type lookups (nil = not yet built)
Nx.GatherCache = {}
Nx.GatherCache.H = nil  -- Herbs
Nx.GatherCache.M = nil  -- Mines

---
-- Check if a spell name is a gathering spell
-- @param nodename  Spell/node name
-- @return          "Herb Gathering" or "Mining" or nil
--
function Nx:IsGathering(nodename)
    if not Nx.GatherCache.H then
        Nx.GatherCache.H = {}
        for k, v in ipairs (Nx.GatherInfo["H"]) do
            if type(v[3]) == "string" then
                Nx.GatherCache.H[v[3]] = true
            end
        end
    end
    if not Nx.GatherCache.M then
        Nx.GatherCache.M = {}
        for k, v in ipairs (Nx.GatherInfo["M"]) do
            if type(v[3]) == "string" then
                Nx.GatherCache.M[v[3]] = true
            end
        end
    end
    if type(nodename) ~= "string" then return end
    local isHerb, isMine = false, false
    pcall(function() isHerb = Nx.GatherCache.H[nodename] end)
    pcall(function() isMine = Nx.GatherCache.M[nodename] end)
    if isHerb then return L["Herb Gathering"] end
    if isMine then return L["Mining"] end
end

---
-- Convert herb name to internal ID
-- @param name  Localized herb name
-- @return      Herb ID or nil if not found
--
function Nx:HerbNameToId (name)
    for k, v in ipairs (Nx.GatherInfo["H"]) do
        if v[3] == name then
            return k
        end
    end

    if Nx.db.profile.Debug.DBGather then
        Nx.prt (L["Unknown herb"] .. " %s", name)
    end
end

---
-- Convert mining node name to internal ID
-- @param name  Localized node name
-- @return      Node ID or nil if not found
--
function Nx:MineNameToId (name)

    name = gsub (name, L["Ooze Covered"] .. " ", "")
    if name == L["Thorium Vein"] then                -- Created when Ooze Covered removed
        name = L["Small Thorium Vein"]
    end
    for k, v in ipairs (Nx.GatherInfo["M"]) do
        if v[3] == name then
            return k
        end
    end

    if Nx.db.profile.Debug.DBGather then
        Nx.prt (L["Unknown ore"] .. " %s", name)
    end
end

--------
-- Upgrade gather data

function Nx:GatherVerUpgrade()
    Nx:GatherVerUpgradeType ("NXHerb")
    Nx:GatherVerUpgradeType ("NXMine")
    Nx:GatherVerUpgradeType ("NXTimber")
end

function Nx:GatherVerUpgradeType (tName)
end

---
-- Record a gathered herb location
-- @param id     Herb ID
-- @param mapId  Map ID
-- @param x      Zone X (0-100)
-- @param y      Zone Y (0-100)
-- @param level  Dungeon level
--
function Nx:GatherHerb (id, mapId, x, y, level)
    self:Gather ("NXHerb", id, mapId, x, y, level)
end

---
-- Record a gathered mining node location
-- @param id     Node ID
-- @param mapId  Map ID
-- @param x      Zone X (0-100)
-- @param y      Zone Y (0-100)
-- @param level  Dungeon level
--
function Nx:GatherMine (id, mapId, x, y, level)
    self:Gather ("NXMine", id, mapId, x, y, level)
end

---
-- Record a gathered timber location
-- @param id     Timber ID (1=Small, 2=Medium, 3=Large)
-- @param mapId  Map ID
-- @param x      Zone X (0-100)
-- @param y      Zone Y (0-100)
-- @param level  Dungeon level
--
function Nx:GatherTimber (id, mapId, x, y, level)
    self:Gather ("NXTimber", id, mapId, x, y, level)
end

---
-- Record a gathered node location (generic)
-- Merges nearby nodes and stores position
-- @param nodeType  "NXHerb", "NXMine", or "Misc"
-- @param id        Node ID
-- @param mapId     Map ID
-- @param x         Zone X (0-100)
-- @param y         Zone Y (0-100)
-- @param level     Dungeon level
--
function Nx:Gather (nodeType, id, mapId, x, y, level)
    level = level or 0  -- Default to 0 if not provided
    local remap = self.GatherRemap[nodeType]
    if remap then
        id = remap[id] or id
    end
    local data = Nx.db.profile.GatherData[nodeType]
    if not data then
        Nx.db.profile.GatherData[nodeType] = {}
        data = Nx.db.profile.GatherData[nodeType]
    end

    local zoneT = data[mapId]

    if not zoneT or not Nx.Map.MapWorldInfo[mapId] then
--        Nx.prt ("Gather new %d", mapId)
        zoneT = {}
        data[mapId] = zoneT
    end

    local maxDist = (5 / Nx.Map:GetWorldZoneScale (mapId)) ^ 2
    local index
    local nodeT = zoneT[id] or {}
    zoneT[id] = nodeT

    for n, node in ipairs (nodeT) do
        local nx, ny, nlevel = Nx.Split("|",node)
        nx, ny, nlevel = tonumber(nx), tonumber(ny), tonumber(nlevel)

        if not nlevel then
            nlevel = 0
        end
        if nlevel == level then
            local dist = (nx - x) ^ 2 + (ny - y) ^ 2
            if dist < maxDist then        -- Squared compare
                index = n
                break
            end
        end
    end
    local cnt = 1
    if not index then
        index = #nodeT + 1
    else
        local nx,xy, level = Nx.Split ("|", nodeT[index])
    end
    nodeT[index] = format ("%f|%f|%d", x, y, level)
end

---
-- Unpack gather node position string
-- Optimized to avoid creating temporary tables
-- @param item  "x|y|level" string
-- @return      x, y, level numbers
--
function Nx:GatherUnpack (item)
    -- Use string.find instead of Split to avoid table creation
    local p1 = string.find(item, "|", 1, true)
    if not p1 then
        return tonumber(item), 0, 0
    end
    local p2 = string.find(item, "|", p1 + 1, true)
    local x = tonumber(string.sub(item, 1, p1 - 1))
    local y, level
    if p2 then
        y = tonumber(string.sub(item, p1 + 1, p2 - 1))
        level = tonumber(string.sub(item, p2 + 1)) or 0
    else
        y = tonumber(string.sub(item, p1 + 1))
        level = 0
    end
    return x, y, level
end

---
-- Delete all herb gathering data
--
function Nx:GatherDeleteHerb()
    Nx.db.profile.GatherData.NXHerb = {}
end

---
-- Delete all mining gathering data
--
function Nx:GatherDeleteMine()
    Nx.db.profile.GatherData.NXMine = {}
end

---
-- Delete all timber gathering data
--
function Nx:GatherDeleteTimber()
    Nx.db.profile.GatherData.NXTimber = {}
end

---
-- Delete all misc gathering data
--
function Nx:GatherDeleteMisc()
    Nx.db.profile.GatherData["Misc"] = {}
end

-------------------------------------------------------------------------------
-- GATHERMATE DATA IMPORT
-- Functions to import node data from Carbonite.Gathermate2_Data addon
-------------------------------------------------------------------------------

---
-- Import herb data from Gathermate2_Data
--
function Nx:GatherImportCarbHerb()
    Nx:GatherImportCarb ("NXHerb")
end

function Nx:GatherImportCarbMine()
    Nx:GatherImportCarb ("NXMine")
end

function Nx:GatherImportCarbMisc()
    Nx:GatherImportCarb ("Misc")
end

function Nx:GatherConvert (id)
    return floor(id/1000000)/10000, floor(id % 1000000 / 100)/10000, id % 100
end

-- Cached lookup table (built once, reused across all import calls)
local GatherNodeToCarbCache = nil

function Nx:GatherNodeToCarb (id)

    if GatherNodeToCarbCache then
        return GatherNodeToCarbCache[id]
    end

    GatherNodeToCarbCache = {
    -- Mining Node Conversions (GatherMate ID -> Carbonite GatherInfo["M"] index)
    -- Classic
        [201] = 3,   -- Copper Vein
        [202] = 20,  -- Tin Vein
        [203] = 9,   -- Iron Deposit
        [204] = 17,  -- Silver Vein
        [205] = 6,   -- Gold Vein
        [206] = 13,  -- Mithril Deposit
        [207] = 13,  -- Ooze Covered Mithril Deposit
        [208] = 21,  -- Truesilver Deposit
        [209] = 17,  -- Ooze Covered Silver Vein
        [210] = 6,   -- Ooze Covered Gold Vein
        [211] = 21,  -- Ooze Covered Truesilver Deposit
        [212] = 16,  -- Ooze Covered Rich Thorium Vein
        [213] = 19,  -- Ooze Covered Thorium Vein
        [214] = 19,  -- Small Thorium Vein
        [215] = 16,  -- Rich Thorium Vein
        [216] = 19,  -- Hakkari Thorium Vein
        [217] = 4,   -- Dark Iron Deposit
        [218] = 12,  -- Lesser Bloodstone Deposit
        [219] = 7,   -- Incendicite Mineral Vein
        [220] = 8,   -- Indurium Mineral Vein
    -- TBC
        [221] = 5,   -- Fel Iron Deposit
        [222] = 1,   -- Adamantite Deposit
        [223] = 15,  -- Rich Adamantite Deposit
        [224] = 10,  -- Khorium Vein
        [225] = 11,  -- Large Obsidian Chunk
        [226] = 18,  -- Small Obsidian Chunk
        [227] = 14,  -- Nethercite Deposit
    -- WotLK
        [228] = 22,  -- Cobalt Deposit
        [229] = 23,  -- Rich Cobalt Deposit
        [230] = 26,  -- Titanium Vein
        [231] = 24,  -- Saronite Deposit
        [232] = 25,  -- Rich Saronite Deposit
    -- Cataclysm
        [233] = 27,  -- Obsidium Deposit
        [234] = 27,  -- Huge Obsidian Slab
        [235] = 24,  -- Pure Saronite Deposit
        [236] = 29,  -- Elementium Vein
        [237] = 30,  -- Rich Elementium Vein
        [238] = 31,  -- Pyrite Deposit
        [239] = 28,  -- Rich Obsidium Deposit
        [240] = 32,  -- Rich Pyrite Deposit
    -- MoP
        [241] = 33,  -- Ghost Iron Deposit
        [242] = 34,  -- Rich Ghost Iron Deposit
        [243] = 37,  -- Black Trillium Deposit
        [244] = 37,  -- White Trillium Deposit
        [245] = 35,  -- Kyparite Deposit
        [246] = 36,  -- Rich Kyparite Deposit
        [247] = 37,  -- Trillium Vein
        [248] = 38,  -- Rich Trillium Vein
    -- WoD
        [249] = 39,  -- True Iron Deposit
        [250] = 40,  -- Rich True Iron Deposit
        [251] = 42,  -- Blackrock Deposit
        [252] = 43,  -- Rich Blackrock Deposit
    -- Legion
        [253] = 47,  -- Leystone Deposit
        [254] = 47,  -- Rich Leystone Deposit
        [255] = 48,  -- Leystone Seam
        [256] = 44,  -- Felslate Deposit
        [257] = 44,  -- Rich Felslate Deposit
        [258] = 45,  -- Felslate Seam
        [259] = 50,  -- Empyrium Deposit
        [260] = 51,  -- Rich Empyrium Deposit
        [261] = 52,  -- Empyrium Seam
    -- BfA
        [262] = 53,  -- Monelite Deposit
        [263] = 54,  -- Rich Monelite Deposit
        [264] = 55,  -- Monelite Seam
        [265] = 56,  -- Platinum Deposit
        [266] = 57,  -- Rich Platinum Deposit
        [267] = 58,  -- Storm Silver Deposit
        [268] = 59,  -- Rich Storm Silver Deposit
        [269] = 60,  -- Storm Silver Seam
        [270] = 53,  -- Osmenite Deposit (map to Monelite)
        [271] = 54,  -- Rich Osmenite Deposit
        [272] = 55,  -- Osmenite Seam
    -- Shadowlands
        [273] = 61,  -- Laestrite Deposit
        [274] = 62,  -- Rich Laestrite Deposit
        [275] = 69,  -- Phaedrum Deposit
        [276] = 70,  -- Rich Phaedrum Deposit
        [277] = 67,  -- Oxxein Deposit
        [278] = 68,  -- Rich Oxxein Deposit
        [280] = 63,  -- Elethium Deposit
        [281] = 64,  -- Rich Elethium Deposit
        [282] = 65,  -- Solenium Deposit
        [283] = 66,  -- Rich Solenium Deposit
        [284] = 71,  -- Sinvyr Deposit
        [285] = 72,  -- Rich Sinvyr Deposit
        [287] = 63,  -- Progenium Deposit (map to Elethium)
        [288] = 64,  -- Rich Progenium Deposit
        [289] = 63,  -- Elusive Progenium
        [290] = 64,  -- Elusive Rich Progenium
        [291] = 63,  -- Elusive Elethium
        [292] = 64,  -- Elusive Rich Elethium
    -- Dragonflight
        [1200] = 73, -- Serevite Seam
        [1201] = 73, -- Serevite Deposit
        [1202] = 78, -- Rich Serevite Deposit
        [1203] = 77, -- Primal Serevite Deposit
        [1204] = 76, -- Molten Serevite Deposit
        [1205] = 74, -- Hardened Serevite Deposit
        [1206] = 75, -- Infurious Serevite Deposit
        [1207] = 79, -- Titan-Touched Serevite Deposit
        [1208] = 80, -- Draconium Seam
        [1209] = 80, -- Draconium Deposit
        [1210] = 85, -- Rich Draconium Deposit
        [1211] = 84, -- Primal Draconium Deposit
        [1212] = 83, -- Molten Draconium Deposit
        [1213] = 81, -- Hardened Draconium Deposit
        [1214] = 82, -- Infurious Draconium Deposit
        [1215] = 86, -- Titan-Touched Draconium Deposit
        [1216] = 73, -- Metamorphic Serevite
        [1217] = 80, -- Metamorphic Draconium
    -- The War Within
        [1218] = 87, -- Bismuth
        [1219] = 90, -- Rich Bismuth
        [1220] = 87, -- Camouflaged Bismuth
        [1221] = 88, -- Crystallized Bismuth
        [1222] = 91, -- Weeping Bismuth
        [1223] = 87, -- Webbed Bismuth
        [1224] = 89, -- EZ-Mine Bismuth
        [1225] = 87, -- Bismuth Seam
        [1226] = 97, -- Aqirite
        [1227] = 100, -- Rich Aqirite
        [1228] = 97, -- Camouflaged Aqirite
        [1229] = 98, -- Crystallized Aqirite
        [1230] = 101, -- Weeping Aqirite
        [1231] = 97, -- Webbed Aqirite
        [1232] = 99, -- EZ-Mine Aqirite
        [1233] = 97, -- Aqirite Seam
        [1234] = 92, -- Ironclaw
        [1235] = 95, -- Rich Ironclaw
        [1236] = 92, -- Camouflaged Ironclaw
        [1237] = 93, -- Crystallized Ironclaw
        [1238] = 96, -- Weeping Ironclaw
        [1239] = 92, -- Webbed Ironclaw
        [1240] = 94, -- EZ-Mine Ironclaw
        [1241] = 92, -- Ironclaw Seam
        [1242] = 102, -- Webbed Ore Deposit
        [1243] = 87, -- Desolate Deposit
        [1244] = 87, -- Rich Desolate Deposit
    -- Midnight Mining (GatherMate IDs 1245-1250)
        [1245] = 103, -- Brilliant Silver
        [1246] = 103, -- Brilliant Silver Seam
        [1247] = 104, -- Refulgent Copper
        [1248] = 104, -- Refulgent Copper Seam
        [1249] = 105, -- Umbral Tin
        [1250] = 105, -- Umbral Tin Seam
    -- Herbalism Nodes (GatherMate ID -> Carbonite GatherInfo["H"] index)
    -- Classic
        [401] = 30,  -- Peacebloom
        [402] = 34,  -- Silverleaf
        [403] = 10,  -- Earthroot
        [404] = 24,  -- Mageroyal
        [405] = 6,   -- Briarthorn
        [406] = 6,   -- Swiftthistle (from Briarthorn)
        [407] = 35,  -- Stranglekelp
        [408] = 7,   -- Bruiseweed
        [409] = 38,  -- Wild Steelbloom
        [410] = 18,  -- Grave Moss
        [411] = 22,  -- Kingsblood
        [412] = 23,  -- Liferoot
        [413] = 11,  -- Fadeleaf
        [414] = 17,  -- Goldthorn
        [415] = 21,  -- Khadgar's Whisker
        [416] = 0,   -- Wintersbite (not in Carbonite)
        [417] = 13,  -- Firebloom
        [418] = 32,  -- Purple Lotus
        [419] = 32,  -- Wildvine (from Purple Lotus)
        [420] = 2,   -- Arthas' Tears
        [421] = 36,  -- Sungrass
        [422] = 4,   -- Blindweed
        [423] = 15,  -- Ghost Mushroom
        [424] = 19,  -- Gromsblood
        [425] = 16,  -- Golden Sansam
        [426] = 8,   -- Dreamfoil
        [427] = 26,  -- Mountain Silversage
        [428] = 31,  -- Plaguebloom
        [429] = 20,  -- Icecap
        [430] = 0,   -- Bloodvine (not in Carbonite)
        [431] = 3,   -- Black Lotus
    -- TBC
        [432] = 12,  -- Felweed
        [433] = 9,   -- Dreaming Glory
        [434] = 37,  -- Terocone
        [435] = 1,   -- Ancient Lichen
        [436] = 5,   -- Bloodthistle
        [437] = 25,  -- Mana Thistle
        [438] = 27,  -- Netherbloom
        [439] = 29,  -- Nightmare Vine
        [440] = 33,  -- Ragveil
        [441] = 14,  -- Flame Cap
        [442] = 28,  -- Netherdust Bush
    -- WotLK
        [443] = 43,  -- Adder's Tongue
        [444] = 0,   -- Constrictor Grass (not in Carbonite)
        [445] = 0,   -- Deadnettle (not in Carbonite)
        [446] = 41,  -- Goldclover
        [447] = 47,  -- Icethorn
        [448] = 46,  -- Lichbloom
        [449] = 42,  -- Talandra's Rose
        [450] = 45,  -- Tiger Lily
        [451] = 49,  -- Firethorn
        [452] = 44,  -- Frozen Herb
        [453] = 48,  -- Frost Lotus
    -- Cataclysm
        [454] = 39,  -- Dragon's Teeth
        [455] = 31,  -- Sorrowmoss (map to Plaguebloom)
        [456] = 50,  -- Azshara's Veil
        [457] = 51,  -- Cinderbloom
        [458] = 52,  -- Stormvine
        [459] = 53,  -- Heartblossom
        [460] = 55,  -- Twilight Jasmine
        [461] = 54,  -- Whiptail
    -- MoP
        [462] = 57,  -- Golden Lotus
        [463] = 56,  -- Fool's Cap
        [464] = 62,  -- Snow Lily
        [465] = 61,  -- Silkweed
        [466] = 58,  -- Green Tea Leaf
        [467] = 59,  -- Rain Poppy
        [468] = 60,  -- Sha-Touched Herb
    -- WoD
        [469] = 68,  -- Talador Orchid
        [470] = 67,  -- Nagrand Arrowbloom
        [471] = 66,  -- Starflower
        [472] = 65,  -- Gorgrond Flytrap
        [473] = 69,  -- Fireweed
        [474] = 64,  -- Frostweed
        [475] = 70,  -- Withered Herb
    -- Legion
        [476] = 71,  -- Aethril
        [477] = 72,  -- Dreamleaf
        [478] = 73,  -- Felwort
        [479] = 74,  -- Fjarnskaggl
        [480] = 75,  -- Foxflower
        [481] = 76,  -- Starlight Rose
        [482] = 71,  -- Fel-Encrusted Herb (map to Aethril)
        [483] = 71,  -- Fel-Encrusted Herb Cluster
        [484] = 77,  -- Astral Glory
    -- BfA
        [485] = 78,  -- Akunda's Bite
        [486] = 79,  -- Anchor Weed
        [487] = 80,  -- Riverbud
        [488] = 81,  -- Sea Stalks
        [489] = 82,  -- Siren's Sting
        [490] = 83,  -- Star Moss
        [491] = 84,  -- Winter's Kiss
        [492] = 84,  -- Zin'anthid (map to Winter's Kiss)
    -- Shadowlands
        [493] = 86,  -- Death Blossom
        [494] = 90,  -- Nightshade
        [495] = 88,  -- Marrowroot
        [496] = 89,  -- Vigil's Torch
        [497] = 87,  -- Rising Glory
        [498] = 85,  -- Widowbloom
        [499] = 90,  -- First Flower (map to Nightshade)
        [1401] = 90, -- Lush Nightshade
        [1402] = 90, -- Elusive Nightshade
        [1403] = 90, -- Lush First Flower
        [1404] = 90, -- Elusive First Flower
        [1405] = 90, -- Lush Elusive First Flower
        [1406] = 90, -- Lush Elusive Nightshade
    -- Dragonflight
        [1407] = 91, -- Hochenblume
        [1408] = 91, -- Lush Hochenblume
        [1409] = 91, -- Frigid Hochenblume
        [1410] = 91, -- Decayed Hochenblume
        [1411] = 91, -- Windswept Hochenblume
        [1412] = 91, -- Infurious Hochenblume
        [1413] = 91, -- Titan-Touched Hochenblume
        [1414] = 92, -- Bubble Poppy
        [1415] = 92, -- Lush Bubble Poppy
        [1416] = 92, -- Frigid Bubble Poppy
        [1417] = 92, -- Decayed Bubble Poppy
        [1418] = 92, -- Windswept Bubble Poppy
        [1419] = 92, -- Infurious Bubble Poppy
        [1420] = 92, -- Titan-Touched Bubble Poppy
        [1421] = 93, -- Saxifrage
        [1422] = 93, -- Lush Saxifrage
        [1423] = 93, -- Frigid Saxifrage
        [1424] = 93, -- Decayed Saxifrage
        [1425] = 93, -- Windswept Saxifrage
        [1426] = 93, -- Infurious Saxifrage
        [1427] = 93, -- Titan-Touched Saxifrage
        [1428] = 94, -- Writhebark
        [1429] = 94, -- Lush Writhebark
        [1430] = 94, -- Frigid Writhebark
        [1431] = 94, -- Decayed Writhebark
        [1432] = 94, -- Windswept Writhebark
        [1433] = 94, -- Infurious Writhebark
        [1434] = 94, -- Titan-Touched Writhebark
        [1435] = 91, -- Lambent Hochenblume
        [1436] = 92, -- Lambent Bubble Poppy
        [1437] = 93, -- Lambent Saxifrage
        [1438] = 94, -- Lambent Writhebark
    -- The War Within
        [1439] = 95,  -- Mycobloom
        [1440] = 99,  -- Lush Mycobloom
        [1441] = 98,  -- Irradiated Mycobloom
        [1442] = 100, -- Sporefused Mycobloom
        [1443] = 95,  -- Sporelusive Mycobloom
        [1444] = 97,  -- Crystallized Mycobloom
        [1445] = 96,  -- Altered Mycobloom
        [1446] = 95,  -- Camouflaged Mycobloom
        [1447] = 112, -- Blessing Blossom
        [1448] = 115, -- Lush Blessing Blossom
        [1449] = 114, -- Irradiated Blessing Blossom
        [1450] = 116, -- Sporefused Blessing Blossom
        [1451] = 112, -- Sporelusive Blessing Blossom
        [1452] = 113, -- Crystallized Blessing Blossom
        [1453] = 112, -- Altered Blessing Blossom
        [1454] = 112, -- Camouflaged Blessing Blossom
        [1455] = 101, -- Luredrop
        [1456] = 105, -- Lush Luredrop
        [1457] = 104, -- Irradiated Luredrop
        [1458] = 106, -- Sporefused Luredrop
        [1459] = 101, -- Sporelusive Luredrop
        [1460] = 103, -- Crystallized Luredrop
        [1461] = 102, -- Altered Luredrop
        [1462] = 101, -- Camouflaged Luredrop
        [1463] = 117, -- Orbinid
        [1464] = 121, -- Lush Orbinid
        [1465] = 120, -- Irradiated Orbinid
        [1466] = 122, -- Sporefused Orbinid
        [1467] = 117, -- Sporelusive Orbinid
        [1468] = 119, -- Crystallized Orbinid
        [1469] = 118, -- Altered Orbinid
        [1470] = 117, -- Camouflaged Orbinid
        [1471] = 107, -- Arathor's Spear
        [1472] = 110, -- Lush Arathor's Spear
        [1473] = 109, -- Irradiated Arathor's Spear
        [1474] = 111, -- Sporefused Arathor's Spear
        [1475] = 107, -- Sporelusive Arathor's Spear
        [1476] = 108, -- Crystallized Arathor's Spear
        [1477] = 107, -- Altered Arathor's Spear
        [1478] = 107, -- Camouflaged Arathor's Spear
        [1479] = 95,  -- Phantom Bloom (map to Mycobloom)
        [1480] = 95,  -- Lush Phantom Bloom
    -- Midnight Herbs (GatherMate IDs 1481-1485)
        [1481] = 123, -- Argentleaf
        [1482] = 124, -- Azeroot
        [1483] = 125, -- Mana Lily
        [1484] = 126, -- Sanguithorn
        [1485] = 127, -- Tranquility Bloom
    }
    return GatherNodeToCarbCache[id]
end

-- Batched import state
Nx.GatherImportState = nil

function Nx:GatherImportCarb (nodeType)
    -- Prevent multiple imports at once
    if Nx.GatherImportState then
        Nx.prt("Import already in progress, please wait...")
        return
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Carbonite.Gathermate2_Data")
    else
        LoadAddOn("Carbonite.Gathermate2_Data")
    end

    -- Validate data exists
    if nodeType == "NXMine" then
        if not GatherMateData2MineDB then
            Nx.prt (L["Carbonite.Gathermate2_Data addon is not loaded!"])
            return
        end
    elseif nodeType == "NXHerb" then
        if not GatherMateData2HerbDB then
            Nx.prt (L["Carbonite.Gathermate2_Data addon is not loaded!"])
            return
        end
    elseif nodeType == "Misc" then
        if not GatherMateData2FishDB and not GatherMateData2TreasureDB then
            Nx.prt (L["Carbonite.Gathermate2_Data addon is not loaded!"])
            return
        end
    end

    -- Get source data table(s)
    local srcT = nil
    local srcTables = {}

    if nodeType == "NXMine" then
        srcT = GatherMateData2MineDB
    elseif nodeType == "NXHerb" then
        srcT = GatherMateData2HerbDB
    elseif nodeType == "Misc" then
        -- Misc includes Fish and Treasure data
        if GatherMateData2FishDB then
            srcTables[#srcTables + 1] = {data = GatherMateData2FishDB, subType = "Fish"}
        end
        if GatherMateData2TreasureDB then
            srcTables[#srcTables + 1] = {data = GatherMateData2TreasureDB, subType = "Treasure"}
        end
    end

    -- For single-source types
    if srcT then
        srcTables[1] = {data = srcT, subType = nodeType}
    end

    if #srcTables == 0 then
        Nx.prt("No data to import for " .. nodeType)
        return
    end

    -- Build a flat list of items to import (for chunked processing)
    local importList = {}
    for _, srcInfo in ipairs(srcTables) do
        for mapId, zoneT in pairs(srcInfo.data) do
            for coords, nodetype in pairs(zoneT) do
                importList[#importList + 1] = {mapId = mapId, coords = coords, nodetype = nodetype, subType = srcInfo.subType}
            end
        end
    end

    local totalCount = #importList
    if totalCount == 0 then
        Nx.prt("No data to import")
        return
    end

    Nx.prt("Starting import of %d nodes (this may take a moment)...", totalCount)

    -- Setup batched import state
    Nx.GatherImportState = {
        nodeType = nodeType,
        importList = importList,
        currentIndex = 1,
        importedCount = 0,
        totalCount = totalCount,
        batchSize = 500,  -- Process 500 nodes per frame
    }

    -- Start the batched import timer
    Nx:ScheduleRepeatingTimer("GatherImportBatch", 0.01)  -- Run every 10ms
end

function Nx:GatherImportBatch()
    local state = Nx.GatherImportState
    if not state then
        Nx:CancelTimer("GatherImportBatch")
        return
    end

    local nodeType = state.nodeType
    local importList = state.importList
    local batchEnd = min(state.currentIndex + state.batchSize - 1, state.totalCount)

    -- Process a batch
    for i = state.currentIndex, batchEnd do
        local item = importList[i]
        local nx, ny = Nx:GatherConvert(item.coords)
        local nodeId = Nx:GatherNodeToCarb(item.nodetype)

        -- For Mine/Herb, use nodetype as fallback; for Misc, always use nodetype
        if not nodeId then
            if nodeType == "NXMine" or nodeType == "NXHerb" then
                nodeId = item.nodetype
            elseif nodeType == "Misc" then
                nodeId = item.nodetype
            end
        end

        if nx and ny and nodeId then
            -- For Misc, store under the "Misc" category
            local storeType = nodeType
            Nx:Gather(storeType, nodeId, item.mapId, nx * 100, ny * 100)
            state.importedCount = state.importedCount + 1
        end
    end

    state.currentIndex = batchEnd + 1

    -- Check if done
    if state.currentIndex > state.totalCount then
        Nx.prt(L["Imported"] .. " %d " .. L["nodes from Carbonite.Gathermate2_Data"], state.importedCount)
        Nx.GatherImportState = nil
        Nx:CancelTimer("GatherImportBatch")
        -- Refresh map icons so newly imported nodes appear immediately
        if Nx.Map and Nx.Map.Guide then
            Nx.Map.Guide:UpdateMapIcons()
        end
    elseif state.currentIndex % 5000 < state.batchSize then
        -- Progress update every 5000 nodes
        local progress = floor(state.currentIndex / state.totalCount * 100)
        Nx.prt("Import progress: %d%% (%d/%d)", progress, state.currentIndex, state.totalCount)
    end
end

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