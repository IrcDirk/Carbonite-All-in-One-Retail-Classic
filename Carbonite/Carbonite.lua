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

-- The 468-line AceDB defaults table lives in
-- Modules/PlayerCharacter/Defaults.lua and is exposed as
-- Nx.Defaults. OnInitialize and OnProfileChanged read it directly.
-------------------------------------------------------------------------------
-- Nx.BrokerMenuTemplate + Nx.Broker (LibDataBroker integration
-- and right-click menu) live in Modules/Integrations/LDBEngine.lua.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- EXTRACTED SUBSYSTEMS (where to look)
-- ============================================================================
-- This file used to be ~5000 lines; it now only holds version constants,
-- per-flavor flags, the Nx.* namespace stubs, the AceDB defaults pointer,
-- and a handful of state flags. Everything else lives under Modules/* or
-- Util/. Lookup table:
--
-- Lifecycle / event plumbing
--   AceAddon lifecycle (OnInitialize/OnEnable/OnDisable/OnProfileChanged)
--   + NXOnLoad ........................ Modules/InitFlow/AceAddonLifecycle.lua
--   SetupEverything + ADDON_LOADED + UNIT_NAME_UPDATE + LocaleInit
--                                    .. Modules/InitFlow/SetupPipeline.lua
--   InitEvents (AceEvent registrations) Modules/InitFlow/EventRegistration.lua
--   NXOnEvent + OnPlayer_login + OnUpdate_mouseover_unit + the six WoW
--   event handlers (regen/spellcast/zone/level/party/BG score)
--                                    .. Modules/UserEvents/EventHandlers.lua
--   NXOnUpdate (per-frame pump)     .. Modules/MainUpdater/NXOnUpdate.lua
--   Slash command dispatcher       .. Modules/SlashHandler/SlashCommandEngine.lua
--
-- State / data
--   AceDB defaults                 .. Modules/PlayerCharacter/Defaults.lua
--   InitGlobal (SV migration)      .. Modules/PlayerCharacter/InitGlobal.lua
--   Character record ops           .. Modules/PlayerCharacter/CharacterData.lua
--   Misc helpers (LootIt/Time/etc).. Modules/PlayerCharacter/MiscHelpers.lua
--   UEvents class                  .. Modules/UserEvents/UEventsEngine.lua
--   EventLog (per-character kills/deaths/gathers)
--                                  .. Modules/UserEvents/EventLog.lua
--   Gather subsystem               .. Modules/Gather/GatherStorage.lua
--   PackXY / UnpackXY              .. Modules/Map/CoordPack.lua
--
-- UI / windows
--   Title splash                   .. Modules/TitleScreen/TitleScreenEngine.lua
--   Whatsnew window                .. Modules/Whatsnew/WhatsnewEngine.lua
--   AuctionAssist                  .. Modules/AuctionAssist/AuctionAssistEngine.lua
--   Item handler                   .. Modules/ItemRegistry/ItemEngine.lua
--   Minimap button                 .. Modules/Map/MinimapButtonEngine.lua
--   ShowMessage / ShowEditBox      .. Modules/UI/Dialogs.lua
--   UnitData mouseover capture     .. Modules/DebugFlags/UnitDataCapture.lua
--
-- Integrations
--   LDB broker                     .. Modules/Integrations/LDBEngine.lua
--   TomTom emulation               .. Modules/Integrations/TomTom.lua
--
-- Util
--   Nx.Split (legacy unpack split) .. Util/NxSplit.lua
--   Nx.Proc tick scheduler         .. Modules/MainUpdater/ProcScheduler.lua
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------