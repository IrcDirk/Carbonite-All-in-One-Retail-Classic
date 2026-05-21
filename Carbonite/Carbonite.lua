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

-- The 468-line AceDB defaults table lives in
-- Modules/PlayerCharacter/Defaults.lua and is exposed as
-- Nx.Defaults. OnInitialize and OnProfileChanged read it directly.
-------------------------------------------------------------------------------
-- Nx.BrokerMenuTemplate + Nx.Broker (LibDataBroker integration
-- and right-click menu) live in Modules/Integrations/LDBEngine.lua.
-------------------------------------------------------------------------------


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
    Nx.db = LibStub("AceDB-3.0"):New("CarbData", Nx.Defaults, true)
    tinsert(Nx.dbs,Nx.db)
    Nx.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    Nx.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    Nx.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    Nx.SetupConfig()
    Nx:RegisterComm("carbmodule",Nx.ModChatReceive)
end

function Nx:OnProfileChanged(event, database, newProfileKey)
    if not Nx.db.profile.MapSettings then
        Nx.db:RegisterDefaults(Nx.Defaults)
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

-------------------------------------------------------------------------------
-- Nx.slashCommand (the /carb dispatcher) lives in
-- Modules/SlashHandler/SlashCommandEngine.lua.
-------------------------------------------------------------------------------


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

-------------------------------------------------------------------------------
-- Nx:InitEvents (AceEvent embedding + WoW event registration for
-- the Nx / Nx.Com / Nx.Map.Guide / Nx.AuctionAssist / Nx.Travel
-- subsystems) lives in Modules/InitFlow/EventRegistration.lua.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Nx:NXOnEvent (legacy frame-event router), Nx:OnPlayer_login
-- and Nx:OnUpdate_mouseover_unit moved to
-- Modules/UserEvents/EventHandlers.lua.
-------------------------------------------------------------------------------

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
-- Nx:NXOnUpdate (the per-frame OnUpdate handler, plus its
-- _tt_lenOf / _tt_neq tooltip-taint pcall helpers) lives in
-- Modules/MainUpdater/NXOnUpdate.lua. Carbonite.xmls NxFrame
-- OnUpdate script still calls Nx:NXOnUpdate(elapsed).
-------------------------------------------------------------------------------


-- Nx:WhatsNewUnread and the Nx.Whatsnew window methods live in
-- Modules/Whatsnew/WhatsnewEngine.lua.

-------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------------------------------------
-- Nx:LootIt / Nx:Time / Nx:UnitIsPlusMob live in
-- Modules/PlayerCharacter/MiscHelpers.lua.
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- GLOBAL DATA MANAGEMENT
-- Functions for managing saved variables and persistent data
-------------------------------------------------------------------------------

-- Gather format:
--   [nodeType] = { [mapId] = { [nodeId] = { "x|y|level", ... } } }
--   Herb and Mine node data organized by map

-------------------------------------------------------------------------------
-- Nx:InitGlobal (saved-variable migration + default installation)
-- lives in Modules/PlayerCharacter/InitGlobal.lua.
-------------------------------------------------------------------------------


---
-- Get named data from appropriate storage
-- @param name  Data category: "Events", "List", "Quests", "Win", "Herb", "Mine"
-- @param ch    Character table (defaults to current)
-- @return      Requested data table
--
-- Nx:GetData / GetDataToolBar / GetHUDOpts / GetCap / CaptureFind
-- moved to Modules/PlayerCharacter/CharacterData.lua alongside the
-- saved-variable character ops (Init/Find/Copy/Delete/RealmChars).

-------------------------------------------------------------------------------
-- Nx:PackXY / Nx:UnpackXY (hex coord packing) live in
-- Modules/Map/CoordPack.lua.
-------------------------------------------------------------------------------


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
-- The Nx.UEvents class (per-character event log + windowed display:
-- Init / AddInfo / AddDeath / AddKill / AddHonor / AddHerb / AddMine /
-- AddTimber / AddOpen / GetPlyrPos / UpdateAll / SortCmp / Sort /
-- List:Open / List:Update / UpdateMap) lives in
-- Modules/UserEvents/UEventsEngine.lua.
-------------------------------------------------------------------------------



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
-- Nx.Proc (the lightweight tick scheduler used by Title and other
-- multi-frame work) lives in Modules/MainUpdater/ProcScheduler.lua.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------