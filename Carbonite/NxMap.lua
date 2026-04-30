---------------------------------------------------------------------------------------
-- NxMap - Main Map Module for Carbonite
-- Copyright 2007-2012 Carbon Based Creations, LLC
---------------------------------------------------------------------------------------
-- This module provides the core map functionality for the Carbonite addon including:
--   - Interactive world map display and navigation
--   - Minimap integration and docking
--   - Player/party/raid member tracking
--   - Waypoint/target system
--   - Zone hotspot detection
--   - Instance map overlays
--   - Route planning and optimization
--   - Icon management and rendering
---------------------------------------------------------------------------------------
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
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
---------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- IMPORTS AND GLOBALS
-------------------------------------------------------------------------------

-- Global environment reference
local _G = getfenv(0)

-- Localization library for multi-language support
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- Extended tooltip library for enhanced tooltips
local ExtToolTip = LibStub('LibQTip-1.0RS')

-------------------------------------------------------------------------------
-- CONFIGURATION CONSTANTS
-------------------------------------------------------------------------------

-- Version number for map options (used for upgrade detection)
NxMAPOPTS_VERSION = .30

-------------------------------------------------------------------------------
-- DEFAULT OPTIONS
-- These defaults are applied when the addon is first installed or when
-- options need to be reset due to version changes
-------------------------------------------------------------------------------

NxMapOptsDefaults = {
    -- Version tracking
    Version = NxMAPOPTS_VERSION,

    -- Auto-scaling settings
    NXAutoScaleOn = true,           -- Enable automatic map scaling
    NXAutoScaleMin = .01,           -- Minimum auto-scale value
    NXAutoScaleMax = 4,             -- Maximum auto-scale value

    -- Display toggles
    NXKillShow = false,             -- Show kill locations on map
    NXShowUnexplored = false,       -- Show unexplored areas

    -- Minimap settings
    NXMMFull = false,               -- Minimap full size mode
    NXMMAlpha = .1,                 -- Minimap transparency
    NXMMDockScale = .4,             -- Minimap docked scale
    NXMMDockScaleBG = .4,           -- Minimap docked scale in battlegrounds
    NXMMDockAlpha = 1,              -- Minimap docked transparency
    NXMMDockOnAtScale = .6,         -- Scale threshold for docking minimap

    -- Map transparency settings
    NXBackgndAlphaFade = .4,        -- Background alpha when faded
    NXBackgndAlphaFull = 1,         -- Background alpha at full
    NXArchAlpha = .3,               -- Archaeology blob transparency
    NXQuestAlpha = .3,              -- Quest blob transparency
    NXDetailAlpha = 1,              -- Detail layer transparency
    NXUnexploredAlpha = .35,        -- Unexplored area transparency

    -- Icon and dot scaling
    NXDotZoneScale = 1,             -- Zone player dot scale
    NXDotPalScale = 1,              -- Friend/guild dot scale
    NXDotPartyScale = 1,            -- Party member dot scale
    NXDotRaidScale = 1,             -- Raid member dot scale
    NXIconNavScale = 1,             -- Navigation icon scale
    NXIconScale = 3,                -- General icon scale
    NXDetailScale = 4,              -- Detail display scale threshold
    NXPOIAtScale = 1,               -- POI display scale threshold

    -- Reserved for future use
    NXOverlayAlpha = nil,
    NXMiniAlpha = nil,
    NXMiniShow = nil,
}

-------------------------------------------------------------------------------
-- PER-MAP DEFAULT OPTIONS
-- Special settings for specific map IDs (battlegrounds, instances, etc.)
-- NXPlyrFollow: Camera follows player
-- NXInstanceMaps: Show instance-specific map overlays
-- NXWorldShow: Show world map background
-------------------------------------------------------------------------------

NXMapOptsMapsDefault = {
    -- Default settings for all maps
    [0] = {
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = true,
    },

    -- Battleground Maps (world view disabled for better visibility)
    [91] = {    -- Alterac Valley
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [92] = {    -- Warsong Gulch
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [93] = {    -- Arathi Basin
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [112] = {   -- Eye of the Storm
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [128] = {   -- Strand of the Ancients
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [169] = {   -- Isle of Conquest
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [206] = {   -- Twin Peaks
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [275] = {   -- The Battle for Gilneas
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [397] = {   -- Eye of the Storm v2
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [417] = {   -- Temple of Kotmogu
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [423] = {   -- Silvershard Mines
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [519] = {   -- Deepwind Gorge
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [623] = {   -- Ashran
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
    [2104] = {  -- Wintergrasp
        NXPlyrFollow = true,
        NXInstanceMaps = true,
        NXWorldShow = false,
    },
}

-------------------------------------------------------------------------------
-- MAP INITIALIZATION
-------------------------------------------------------------------------------

---
-- Initialize the map system
-- Sets up player faction, data structures, and various lookup tables
-- Called once during addon load
--
function Nx.Map:Init()
    -- Determine player faction (Alliance = 0, Horde = 1)
    local plFaction = UnitFactionGroup("player")
    plFaction = strsub(plFaction, 1, 1)
    self.PlFactionNum = plFaction == "A" and 0 or 1
    self.PlFactionShort = plFaction == "A" and "Ally" or "Horde"

    -- Indoor/outdoor state tracking
    Nx.Map.Indoors = false

    -- Core data structures
    self.Maps = {}              -- Container for map instances
    self.Created = false        -- Flag indicating if map UI has been created

    -- Integration with RareScanner addon
    self.RareScannerOverlays = {}

    -- Initialize function tables and map data
    self:InitFuncs()
    self:InitTables()

    -- Player tracking data
    self.PlyrNames = {}         -- List of nearby player names
    self.AFKers = {}            -- List of AFK players
    self.PlyrNamesTipStr = ""   -- Tooltip string for player list

    -- Continent scanning frequency modifier
    self.ScanContinentsMod = 10

    -- Points of Interest per continent
    self.ContPOIs = {}
    for cont = 1, self.ContCnt do
        self.ContPOIs[cont] = {}
    end

    -- Battleground timer tracking
    self.BGTimers = {}

    -- Player movement history for trail display
    -- Each entry stores: time, X position, Y position, direction
    local hist = {}
    self.PlyrHist = hist
    hist.LastX = -99999999
    hist.LastY = -99999999
    hist.Next = 1
    hist.Cnt = Nx.db.profile.Map.TrailCnt

    for n = 1, hist.Cnt * 4, 4 do
        hist[n] = 0         -- Timestamp (seconds)
        hist[n + 1] = 0     -- World X coordinate
        hist[n + 2] = 0     -- World Y coordinate
        hist[n + 3] = 0     -- Movement direction
    end

    -- POI type lookup table for battleground objectives
    -- Values indicate faction ownership: 0 = Neutral, 1 = Alliance, 2 = Horde
    Nx.MapPOITypes = {
        [0] =
        0, 0, 2, 1, 1, 0, 0, 0,  0, 1, 2, 1, 2, 2, 2, 1,
        0, 1, 1, 2, 2, 0, 1, 1,  2, 2, 0, 1, 1, 2, 2, 0,
        1, 1, 2, 2, 0, 1, 1, 2,  2, 0, 0, 1, 2, 0, 1, 1,
        2, 2,
        -- Extended POI types for specific battleground elements
        [136] = 1, [137] = 1, [138] = 2, [139] = 2,
        [141] = 1, [142] = 1, [143] = 2, [144] = 2,
        [146] = 1, [147] = 1, [148] = 2, [149] = 2,
        [151] = 1, [152] = 1, [153] = 2, [154] = 2,
    }

    -- World map elements to hide when using Carbonite map
    self.WorldMapHideNames = {
        "WorldMapCorpse",
        "WorldMapDeathRelease",
        "WorldMapPing",
        "OutlandButton",
        "AzerothButton"
    }

    -- Addon minimap icon patterns to recognize and integrate
    -- The # character is stripped from frame names before matching
    self.AddonMinimapNames = {
        ["GatherNote"] = true,
        ["GatherMatePin"] = true,
        ["MobMapMinimapDot_"] = true,
        ["CartographerNotesPOI"] = true,
        ["RecipeRadarMinimapIcon"] = true,
        ["NauticusMiniIcon"] = true,
        ["ZGVMarkerMini"] = true,       -- Zygor Guide
        ["HandyNotesPin"] = true,       -- HandyNotes addon
    }

    -- TomTom emulation for compatibility with addons that depend on it
    if Nx.db.profile.Track.EmuTomTom and not Nx.RealTom then
        TomTom = {}
        Nx.EmulateTomTom()
    end

    -- Sync with Blizzard's world map (skip during combat to avoid taint)
    Nx.Map.UpdateMapID = WorldMapFrame.mapID
    if Nx.Map.UpdateMapID and not InCombatLockdown() then
        WorldMapFrame:SetMapID(Nx.Map.UpdateMapID)
    end
end

---
-- Set the Blizzard world map to display a specific zone
-- Handles map ID translation for Classic vs retail compatibility
-- @param zone  The map ID to display
--
function Nx.Map:SetMapByID(zone)
    -- Only update if world map is not visible and has zoom data
    if not WorldMapFrame:IsShown() and WorldMapFrame.ScrollContainer.zoomLevels then
        -- Translate continent IDs for non-MoP Classic clients
        if Nx.OldMapIDs then
            if zone == 12 then zone = 1414 end      -- Kalimdor
            if zone == 13 then zone = 1415 end      -- Eastern Kingdoms
        end
        -- Wrap in pcall to catch Blizzard VehicleDataProvider errors
        -- (their code doesn't handle nil from C_PvP.GetBattlefieldVehicles)
        -- Skip during combat to avoid taint from Blizzard's quest data providers
        if not InCombatLockdown() then
            pcall(WorldMapFrame.SetMapID, WorldMapFrame, zone)
        end
    end
end

---
-- Get map information with version-specific ID translation
-- Handles differences between Classic and retail map IDs
-- @param mapId  The map ID to query
-- @return       Map info table or nil if invalid
--
function Nx.Map:GetMapInfo(mapId)
    if mapId and mapId ~= 0 then
        local mapInfo

        if Nx.OldMapIDs then
            -- Translate IDs for Classic WoW compatibility
            if mapId == 12 then mapId = 1414 end    -- Kalimdor
            if mapId == 13 then mapId = 1415 end    -- Eastern Kingdoms

            mapInfo = C_Map.GetMapInfo(mapId)

            -- Reverse translation for continent-level maps (type 2)
            if mapInfo.mapType == 2 then
                if mapInfo.mapID == 1414 then mapInfo.mapID = 12 end
                if mapInfo.mapID == 1415 then mapInfo.mapID = 13 end
            end

            -- Reverse translation for zone-level maps (type 3) parent IDs
            if mapInfo.mapType == 3 then
                if mapInfo.parentMapID == 1414 then mapInfo.parentMapID = 12 end
                if mapInfo.parentMapID == 1415 then mapInfo.parentMapID = 13 end
            end
        else
            -- MoP Classic uses standard IDs
            mapInfo = C_Map.GetMapInfo(mapId)
        end

        return mapInfo
    else
        return nil
    end
end

-------------------------------------------------------------------------------
-- MAP WINDOW MANAGEMENT
-------------------------------------------------------------------------------

---
-- Open the map window or toggle its visibility
-- Initializes settings and creates the map UI on first call
--
function Nx.Map:Open()
    local Map = Nx.Map
    local m = self.Maps[1]

    -- Initialize settings storage if missing
    if not Nx.db.profile.MapSettings then
        Nx.db.profile.MapSettings = {}
        Nx.db.profile.MapSettings.Version = 0
    end

    -- Check for settings version upgrade
    if Nx.db.profile.MapSettings.Version < NxMAPOPTS_VERSION then
        if Nx.db.profile.MapSettings.Version > 0 then
            Nx.prt("Reset map options %f", NxMAPOPTS_VERSION)
        end
        Nx.prt("RESETTING MAP OPTIONS")
        Nx.db.profile.MapSettings = NxMapOptsDefaults
        Nx.db.profile.MapSettings.Maps = NXMapOptsMapsDefault
    end

    -- Toggle visibility if already created
    if self.Created then
        if m.Frm:IsShown() then
            m.Frm:Hide()
        else
            m.Frm:Show()
        end
        return
    end

    -- First-time creation
    Nx.Map:VerifySettings()
    self.Maps[1] = {}
    self.Maps[1] = self:Create(1)
    self.Dock:Create()

    self.Created = true
end

---
-- Verify and repair settings by filling in missing defaults
-- Called during map open to ensure all settings exist
--
function Nx.Map:VerifySettings()
    -- Check global map settings
    for k, v in pairs(NxMapOptsDefaults) do
        if Nx.db.profile.MapSettings[k] == nil then
            Nx.db.profile.MapSettings[k] = v
        end
    end

    -- Check per-map settings
    local opts = Nx.db.profile.MapSettings.Maps
    for k, v in pairs(NXMapOptsMapsDefault) do
        if Nx.db.profile.MapSettings.Maps[k] == nil then
            Nx.db.profile.MapSettings.Maps[k] = v
        end
    end
end

-------------------------------------------------------------------------------
-- OPTIONS MANAGEMENT
-------------------------------------------------------------------------------

---
-- Update saved options from current map state
-- Copies runtime values back to persistent storage
-- @param index  Map index to update options for
--
function Nx.Map:UpdateOptions(index)
    local src = Nx.Map.Maps[index]
    local dst = Nx.db.profile.MapSettings
    assert(src)
    assert(dst)

    -- Display settings
    dst.NXShowUnexplored = src.ShowUnexplored
    dst.NXKillShow = src.KillShow

    -- Transparency settings
    dst.NXBackgndAlphaFade = src.BackgndAlphaFade
    dst.NXBackgndAlphaFull = src.BackgndAlphaFull
    dst.NXArchAlpha = src.ArchAlpha
    dst.NXQuestAlpha = src.QuestAlpha

    -- Scale settings
    dst.NXDotZoneScale = src.DotZoneScale
    dst.NXDotPalScale = src.DotPalScale
    dst.NXDotPartyScale = src.DotPartyScale
    dst.NXDotRaidScale = src.DotRaidScale
    dst.NXIconNavScale = src.IconNavScale
    dst.NXIconScale = src.IconScale

    -- Save current map position and scale
    local opts = src.CurOpts
    if opts then
        opts.NXMapPosX = src.MapPosX
        opts.NXMapPosY = src.MapPosY
        opts.NXScale = src.Scale
    end
end

---
-- Switch to a different set of per-map options
-- Used when changing zones or entering battlegrounds
-- @param id       Map ID to switch options for
-- @param startup  True if this is during initial load
--
function Nx.Map:SwitchOptions(id, startup)
    local opts = Nx.db.profile.MapSettings.Maps
    local copts = opts[id] or opts[0]   -- Fall back to default if no specific options

    -- Only switch if options have changed
    if copts ~= self.CurOpts then
        self.CurOpts = copts

        -- Follow player if enabled
        if copts.NXPlyrFollow then
            self:GotoPlayer()
        end

        -- Restore saved position if not following or during startup
        if (not copts.NXPlyrFollow or startup) and copts.NXMapPosX then
            self.MapPosX = copts.NXMapPosX
            self.MapPosY = copts.NXMapPosY
            self.Scale = copts.NXScale
            self.RealScale = self.Scale
            self.StepTime = 1
        elseif copts.NXPlyrFollow or Nx.InBG then
            -- Center on current zone
            self:GotoCurrentZone()
        end

        -- Switch window layout mode for this map type
        local mode = opts[id] and tostring(id) or ""
        self.Win:SwitchLayoutMode(mode)
    end
end

---
-- Get options table for a specific map
-- @param index  Map index
-- @return       Options table for the current map ID
--
function Nx.Map:GetOptionsT(index)
    local map = Nx.Map.Maps[index]
    local opts = Nx.db.profile.MapSettings.Maps
    return opts[map.UpdateMapID] or opts[0]
end

---
-- Get a specific option value for a map
-- @param index  Map index
-- @param name   Option name
-- @return       Option value
--
function Nx.Map:GetOption(index, name)
    local map = Nx.Map.Maps[index]
    local opts = Nx.db.profile.MapSettings.Maps

    local id = map.UpdateMapID
    id = opts[id] and id or 0

    return opts[id][name]
end

---
-- Set a specific option value for a map
-- @param index  Map index
-- @param name   Option name
-- @param value  New value to set
--
function Nx.Map:SetOption(index, name, value)
    local map = Nx.Map.Maps[index]
    local opts = NxMapOpts.NXMaps[index]

    local id = map.UpdateMapID
    id = opts[id] and id or 0

    opts[id][name] = value
end

-------------------------------------------------------------------------------
-- FUNCTION BINDING SYSTEM
-- Maps localized action names to function implementations
-------------------------------------------------------------------------------

---
-- Initialize the function lookup table
-- These functions can be bound to mouse actions via options
--
function Nx.Map:InitFuncs()
    self.Funcs = {
        [L["None"]] = function() end,               -- No action
        [L["Goto"]] = self.SetTargetAtClick,        -- Set waypoint at click
        [L["Show Player Zone"]] = self.GotoCurrentZone,  -- Center on player
        [L["Show Selected Zone"]] = self.CenterMap,      -- Center on zone
        [L["Menu"]] = self.OpenMenu,                -- Open context menu
        [L["Zoom In"]] = self.ClickZoomIn,          -- Zoom in
        [L["Zoom Out"]] = self.ClickZoomOut,        -- Zoom out
    }
end

---
-- Get sorted list of available function names
-- @return  Sorted table of function names for options UI
--
function Nx.Map:GetFuncs()
    local t = {}

    for name in pairs(self.Funcs) do
        tinsert(t, name)
    end

    sort(t)

    return t
end

---
-- Call a map function by its option name
-- Looks up the function name from settings and executes it
-- @param optName  Option name that contains the function name
-- @return         True if a function was executed, nil otherwise
--
function Nx.Map:CallFunc(optName)
    local name = Nx.db.profile.Map[optName]

    -- "None" means no action should be taken
    if name == L["None"] then
        return nil
    end

    local func = self.Funcs[name]
    if func then
        func(self)
    else
        Nx.prt("Unknown map function %s", name)
    end

    return true
end

-------------------------------------------------------------------------------
-- MAP CREATION
-------------------------------------------------------------------------------

---
-- Debug function to test zone ID to name mapping
-- Identifies duplicate names and missing zones
--
function Nx.Map:Test()
    local arr = {}
    for i = 1, 1000 do
        local znm = Nx.Map:GetMapNameByID(i)

        if not arr[znm] and znm then
            arr[znm] = i
        else
            if znm then
                Nx.prt("dupe " .. znm)
            else
                Nx.prt("no zone " .. i)
            end
        end
    end
end

---
-- Create a new map instance
-- This is the main factory function for map objects
-- @param index  Map index (1 = main map)
-- @return       The created map object
--
function Nx.Map:Create(index)
    local Map = Nx.Map
    local m = {}

    -- Link to settings
    local opts = Nx.db.profile.MapSettings
    m.LOpts = opts                          -- Local options reference

    -- Ensure POI scale has a default
    opts.NXPOIAtScale = opts.NXPOIAtScale or 1

    -- Set up inheritance
    setmetatable(m, self)
    self.__index = self

    ---------------------------------------------------------------------------
    -- Debug Settings
    ---------------------------------------------------------------------------
    m.Tick = 0                              -- Debug tick counter
    m.Debug = nil                           -- Debug mode enabled
    m.DebugTime = nil                       -- Debug timing enabled
    m.DebugFullCoords = nil                 -- High precision coordinates
    m.DebugAdjustScale = .1                 -- Debug scale adjustment

    ---------------------------------------------------------------------------
    -- Map Identity and Display Settings
    ---------------------------------------------------------------------------
    m.MapIndex = index                      -- This map's index
    m.MMOwn = Nx.db.profile.MiniMap.Own and index == 1  -- Owns minimap?

    m.ShowUnexplored = opts.NXShowUnexplored    -- Show unexplored areas
    m.KillShow = opts.NXKillShow                -- Show kill locations

    ---------------------------------------------------------------------------
    -- Layout and Dimensions
    ---------------------------------------------------------------------------
    m.TitleH = 0                            -- Title bar height
    m.PadX = 0                              -- Horizontal padding
    m.Scale = .025                          -- Current scale
    m.RealScale = .025                      -- Target scale for interpolation
    m.ScaleDraw = .025                      -- Actual rendering scale
    m.MapScale = 0.005                      -- Base map scale factor
    m.MapW = 150                            -- Map width in pixels
    m.MapH = 140                            -- Map height in pixels
    m.W = m.MapW + m.PadX * 2               -- Total width with padding
    m.H = m.MapH + m.TitleH + 1             -- Total height with title

    ---------------------------------------------------------------------------
    -- Input State
    ---------------------------------------------------------------------------
    m.LClickTime = 0                        -- Last click timestamp
    m.MouseEnabled = true                   -- Mouse input enabled
    m.Scrolling = false                     -- Currently scrolling
    m.StepTime = 0                          -- Animation step time

    ---------------------------------------------------------------------------
    -- Edit Mode State (for drawing quest objective rectangles)
    ---------------------------------------------------------------------------
    m.EditMode = false                      -- Edit mode enabled
    m.EditDrawing = false                   -- Currently drawing a rectangle
    m.EditStartX = nil                      -- Start X coordinate (zone 0-100)
    m.EditStartY = nil                      -- Start Y coordinate (zone 0-100)
    m.EditMapId = nil                       -- Map ID where drawing started
    m.EditPreviewFrame = nil                -- Preview rectangle frame
    m.EditRectangles = {}                   -- Array of drawn rectangles
    m.EditRectFrames = {}                   -- Array of rectangle display frames
    m.EditFinishButton = nil                -- Button to finish and output all

    ---------------------------------------------------------------------------
    -- Map Position and Zone State
    ---------------------------------------------------------------------------
    m.MapId = 0                             -- Current map ID
    m.BaseScale = 1                         -- Base scale (smaller for instances)
    m.MapPosX = 2200                        -- World X position of map center
    m.MapPosY = -100                        -- World Y position of map center
    m.MapPosXDraw = m.MapPosX               -- Actual draw X position
    m.MapPosYDraw = m.MapPosY               -- Actual draw Y position

    ---------------------------------------------------------------------------
    -- Player State
    ---------------------------------------------------------------------------
    m.PlyrX = 0                             -- Player world X
    m.PlyrY = 0                             -- Player world Y
    m.PlyrRZX = 0                           -- Player relative zone X
    m.PlyrRZY = 0                           -- Player relative zone Y
    m.PlyrDir = 0                           -- Player facing direction
    m.PlyrLastDir = 999                     -- Previous direction
    m.PlyrSpeed = 0                         -- Current speed
    m.PlyrSpeedX = 0                        -- X velocity component
    m.PlyrSpeedY = 0                        -- Y velocity component
    m.PlyrSpeedCalcTime = GetTime()         -- Last speed calculation time

    ---------------------------------------------------------------------------
    -- Movement Tracking
    ---------------------------------------------------------------------------
    m.MoveDir = 0                           -- Movement direction
    m.MoveLastX = 0                         -- Last movement X
    m.MoveLastY = 0                         -- Last movement Y
    m.ViewSavedData = {}                    -- Saved view positions

    ---------------------------------------------------------------------------
    -- Map Layer Management
    ---------------------------------------------------------------------------
    m.MapsDrawnOrder = {}                   -- Drawing order: [index] = map id
    m.MapsDrawnFade = {}                    -- Fade values: [map id] = fade
    m.MiniBlks = Nx.db.profile.Map.DetailSize   -- Detail block count

    ---------------------------------------------------------------------------
    -- Transparency Settings
    ---------------------------------------------------------------------------
    m.ArchAlpha = opts.NXArchAlpha          -- Archaeology blob alpha
    m.QuestAlpha = opts.NXQuestAlpha        -- Quest blob alpha
    m.BackgndAlphaFade = opts.NXBackgndAlphaFade    -- Faded background alpha
    m.BackgndAlphaFull = opts.NXBackgndAlphaFull    -- Full background alpha
    m.BackgndAlpha = 0                      -- Current background alpha
    m.BackgndAlphaTarget = m.BackgndAlphaFade       -- Target background alpha
    m.WorldAlpha = 0                        -- World map overlay alpha

    ---------------------------------------------------------------------------
    -- Icon and Dot Scaling
    ---------------------------------------------------------------------------
    m.DotZoneScale = opts.NXDotZoneScale    -- Zone player dot scale
    m.DotPalScale = opts.NXDotPalScale      -- Friend/guild dot scale
    m.DotPartyScale = opts.NXDotPartyScale  -- Party member dot scale
    m.DotRaidScale = opts.NXDotRaidScale    -- Raid member dot scale
    m.IconNavScale = opts.NXIconNavScale    -- Navigation icon scale
    m.IconScale = opts.NXIconScale          -- General icon scale

    ---------------------------------------------------------------------------
    -- Animation State
    ---------------------------------------------------------------------------
    m.ArrowPulse = 1                        -- Arrow pulse animation
    m.ArrowScroll = 0                       -- Arrow scroll position

    ---------------------------------------------------------------------------
    -- Update Timers
    ---------------------------------------------------------------------------
    m.UpdateTargetDelay = 0                 -- Target update delay counter
    m.UpdateTrackingDelay = 0               -- Tracking update delay counter

    ---------------------------------------------------------------------------
    -- Target and Tracking System
    ---------------------------------------------------------------------------
    m.Targets = {}                          -- Active waypoint targets
    m.TargetNextUniqueId = 1                -- Next unique target ID
    m.Tracking = {}                         -- Active tracking entries
    m.TrackPlyrs = {}                       -- Tracked players

    ---------------------------------------------------------------------------
    -- Icon Frame Pools
    -- These pools prevent constant frame creation/destruction
    ---------------------------------------------------------------------------
    m.Data = {}                             -- General data storage

    -- Interactive icon frames (respond to mouse)
    m.IconFrms = {}
    m.IconFrms.Next = 1
    m.IconFrms.Used = 0

    -- Non-interactive icon frames (decorative)
    m.IconNIFrms = {}
    m.IconNIFrms.Next = 1
    m.IconNIFrms.Used = 0

    -- Static icon frames (persistent display)
    m.IconStaticFrms = {}
    m.IconStaticFrms.Next = 1
    m.IconStaticFrms.Used = 0

    -- World quest icon frames
    m.IconWQFrms = {}
    m.IconWQFrms.Next = 1
    m.IconWQFrms.Used = 0

    -- Text font string pool
    m.TextFStrs = {}
    m.TextFStrs.Next = 1
    m.TextFStrs.Used = 0

    -- Minimap gatherer integration delay
    m.MMGathererUpdateDelay = 1

    ---------------------------------------------------------------------------
    -- WINDOW CREATION
    ---------------------------------------------------------------------------

    Nx.Window:SetCreateFade(1, 0)

    local wname = m:GetWinName()
    local i = Nx.db.profile.Map.ShowTitle2 and 2 or 1

    -- Create the main window container
    local win = Nx.Window:Create(wname, nil, nil, nil, i)
    m.Win = win

    win:SetBGAlpha(0, 1)
    win:CreateButtons(true)

    -- Default layout position
    win:InitLayoutData(nil, -.0001, -.4, -.19, -.3, 1)

    -- Battleground-specific layouts
    win:InitLayoutData("91", -.0001, -.4, -.19, -.3, 1)     -- Alterac Valley
    win:InitLayoutData("92", -.0001, -.4, -.19, -.3, 1)     -- Warsong Gulch
    win:InitLayoutData("93", -.0001, -.4, -.19, -.3, 1)     -- Arathi Basin
    win:InitLayoutData("112", -.0001, -.4, -.19, -.3, 1)    -- Eye of the Storm
    win:InitLayoutData("128", -.0001, -.4, -.19, -.3, 1)    -- Strand of the Ancients
    win:InitLayoutData("169", -.0001, -.4, -.19, -.3, 1)    -- Isle of Conquest
    win:InitLayoutData("206", -.0001, -.4, -.19, -.3, 1)    -- Twin Peaks
    win:InitLayoutData("275", -.0001, -.4, -.19, -.3, 1)    -- Battle for Gilneas
    win:InitLayoutData("397", -.0001, -.4, -.19, -.3, 1)    -- Eye of the Storm v2
    win:InitLayoutData("417", -.0001, -.4, -.19, -.3, 1)    -- Temple of Kotmogu
    win:InitLayoutData("423", -.0001, -.4, -.19, -.3, 1)    -- Silvershard Mines
    win:InitLayoutData("519", -.0001, -.4, -.19, -.3, 1)    -- Deepwind Gorge
    win:InitLayoutData("623", -.0001, -.4, -.19, -.3, 1)    -- Ashran
    win:InitLayoutData("2104", -.0001, -.4, -.19, -.3, 1)   -- Wintergrasp

    -- Set up window callbacks
    win:SetUser(m, self.OnWin)
    win.UserUpdateFade = m.WinUpdateFade

    win.Frm:SetToplevel(true)
    win.Frm.NxMap = m

    m.StartupShown = win:IsShown()
    win.Frm:Show()

    ---------------------------------------------------------------------------
    -- MAIN FRAME CREATION
    ---------------------------------------------------------------------------

    local f = CreateFrame("Frame", nil, UIParent)
    m.Frm = f
    f.NxMap = m

    -- Attach frame to window
    win:Attach(f, 0, 1, 0, 1)

    -- Register for events using AceEvent
    LibStub("AceEvent-3.0"):Embed(Nx.Map)
    Nx.Map:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")    -- Combat start
    Nx.Map:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")     -- Combat end
    Nx.Map:RegisterEvent("ZONE_CHANGED", "OnEvent")             -- Zone change
    Nx.Map:RegisterEvent("ZONE_CHANGED_INDOORS", "OnEvent")     -- Indoor/outdoor
    Nx.Map:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")    -- New area

    -- Set up mouse handlers
    f:SetScript("OnMouseDown", self.OnMouseDown)
    f:SetScript("OnMouseUp", self.OnMouseUp)
    f:SetScript("OnMouseWheel", self.OnMouseWheel)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)

    -- Frame properties
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetFrameStrata("LOW")
    f:SetWidth(m.W)
    f:SetHeight(m.H)
    f:SetResizeBounds(50, 50)
    f:SetClipsChildren(true)  -- Clip child frames (icons) at frame edges

    -- Background texture
    local t = f:CreateTexture()
    t:SetColorTexture(0, 0, 0, .2)
    t:SetAllPoints(f)
    f.texture = t

    f:Show()

    ---------------------------------------------------------------------------
    -- TEXT FRAME CREATION
    -- Scrollable frame for text overlays
    ---------------------------------------------------------------------------

    local tsf = CreateFrame("ScrollFrame", nil, f)
    m.TextScFrm = tsf
    tsf:SetAllPoints(f)

    local tf = CreateFrame("Frame", nil, tsf)
    m.TextFrm = tf
    tf:SetPoint("TOPLEFT", 0, 0)
    tf:SetWidth(100)
    tf:SetHeight(100)
    tsf:SetScrollChild(tf)

    ---------------------------------------------------------------------------
    -- UI ELEMENTS
    ---------------------------------------------------------------------------

    -- Create location tooltip display
    m:CreateLocationTip()

    -- Create tool bar with zoom and other buttons
    m:CreateToolBar()

    ---------------------------------------------------------------------------
    -- BUTTONS
    ---------------------------------------------------------------------------

    local bw, bh = win:GetBorderSize()

    -- Auto-scale toggle button
    local function func(self, but)
        self.LOpts.NXAutoScaleOn = but:GetPressed()
    end

    m.ButAutoScaleOn = Nx.Button:Create(win.Frm, "MapAutoScale", nil, nil, -20, -bh, "TOPRIGHT", 12, 12, func, m)
    m.ButAutoScaleOn:SetPressed(opts.NXAutoScaleOn)

    ---------------------------------------------------------------------------
    -- MAIN CONTEXT MENU
    ---------------------------------------------------------------------------

    local menu = Nx.Menu:Create(f)
    m.Menu = menu

    -- Navigation commands
    menu:AddItem(0, L["Goto"], self.Menu_OnGoto, m)
    menu:AddItem(0, L["Clear Goto"], self.Menu_OnClearGoto, m)

    -- Scale management
    menu:AddItem(0, L["Save Map Scale"], self.Menu_OnScaleSave, m)
    menu:AddItem(0, L["Restore Map Scale"], self.Menu_OnScaleRestore, m)
    menu:AddItem(0, "", nil, self)  -- Separator

    -- View options
    m.MenuIPlyrFollow = menu:AddItem(0, L["Follow You"], self.Menu_OnPlyrFollow, m)

    local item = menu:AddItem(0, L["Select Cities Last"], self.SetLevelWorldHotspots, m)
    item:SetChecked(m, "NXCitiesUnder")

    m.MenuIMonitorZone = menu:AddItem(0, L["Monitor Zone"], self.Menu_OnMonitorZone, m)
    m.MenuIInstanceMaps = menu:AddItem(0, L["Show Instance Map"], self.Menu_InstanceMap, m)

    menu:AddItem(0, "", nil, self)  -- Separator

    ---------------------------------------------------------------------------
    -- ROUTE SUBMENU
    -- Tools for planning and managing routes between waypoints
    ---------------------------------------------------------------------------

    local routeMenu = Nx.Menu:Create(f)
    menu:AddSubMenu(routeMenu, L["Route..."])

    -- Route current gather locations
    local function func(self)
        self:RouteGathers()
    end
    local item = routeMenu:AddItem(0, L["Current Gather Locations"], func, m)

    -- Route current waypoint targets
    local function func(self)
        self:RouteTargets()
    end
    local item = routeMenu:AddItem(0, L["Current Goto Targets"], func, m)

    -- Route unexplored areas
    local function func(self)
        self.ShowUnexplored = false
        self:UpdateOverlayUnexplored()
        self:TargetOverlayUnexplored()
        self:RouteTargets()
    end
    routeMenu:AddItem(0, L["Unexplored Locations"], func, m)

    -- Reverse route direction
    local function func(self)
        self:ReverseTargets()
    end
    routeMenu:AddItem(0, L["Reverse Targets"], func, m)

    -- Route options
    local item = routeMenu:AddItem(0, L["Recycle Reached Targets"])
    item:SetChecked(Nx.db.profile.Route, "Recycle")

    local item = routeMenu:AddItem(0, L["Gather Target Radius"])
    item:SetSlider(Nx.db.profile.Route, 7, 300, nil, "GatherRadius")

    local item = routeMenu:AddItem(0, L["Gather Merge Radius"])
    item:SetSlider(Nx.db.profile.Route, 0, 100, nil, "MergeRadius")

    ---------------------------------------------------------------------------
    -- SHOW SUBMENU
    -- Toggle visibility of various map elements
    ---------------------------------------------------------------------------

    local showMenu = Nx.Menu:Create(f)
    menu:AddSubMenu(showMenu, L["Show..."])

    -- Navigation options
    showMenu:AddItem(0, L["Show Player Zone"], self.Menu_OnShowPlayerZone, m)

    -- Gathering location toggles
    local function func(self)
        self.Guide:UpdateGatherFolders()
    end

    local item = showMenu:AddItem(0, L["Show Herb Locations"], func, m)
    m.MenuIShowHerb = item
    item:SetChecked(Nx.db.char.Map, "ShowGatherH")

    local item = showMenu:AddItem(0, L["Show Mining Locations"], func, m)
    m.MenuIShowMine = item
    item:SetChecked(Nx.db.char.Map, "ShowGatherM")

    -- Timber is WoD+ only (Garrison Lumber Mill)
    if Nx.isRetail then
        local item = showMenu:AddItem(0, L["Show Timber Locations"], func, m)
        m.MenuIShowTimber = item
        item:SetChecked(Nx.db.char.Map, "ShowGatherL")
    end

    -- Archaeology/Artifacts are Cataclysm+ only
    if Nx.CataMaps then
        local item = showMenu:AddItem(0, L["Show Artifact Locations"], func, m)
        m.MenuIShowArt = item
        item:SetChecked(Nx.db.char.Map, "ShowGatherA")
    end

    -- POI visibility toggles
    local function func(self)
        self.Guide.POIDraw = nil
        Nx.Map.Guide:ClearShowFolders()
        Nx.Map.Guide:UpdateMapIcons()
    end

    local item = showMenu:AddItem(0, L["Show Continent POIs"], func, m)
    item:SetChecked(Nx.db.char.Map, "ShowContPois")

    local item = showMenu:AddItem(0, L["Show Guide POIs"], func, m)
    item:SetChecked(Nx.db.char.Map, "ShowMailboxes")

    local item = showMenu:AddItem(0, L["Show Custom Icons"], func, m)
    item:SetChecked(Nx.db.char.Map, "ShowCustom")

    local item = showMenu:AddItem(0, L["Show Instance Raid Bosses"], func, m)
    item:SetChecked(Nx.db.char.Map, "ShowRaidBoss")

    -- World Quests are Legion+ only
    if Nx.LegionMaps then
        local item = showMenu:AddItem(0, L["Show World Quests"], func, m)
        item:SetChecked(Nx.db.char.Map, "ShowWorldQuest")
    end

    -- Blobs are Cataclysm+ only
    if Nx.BlobsAvailable then
        local item = showMenu:AddItem(0, L["Show Archaeology Blobs"], func, m)
        item:SetChecked(Nx.db.char.Map, "ShowArchBlobs")

        local item = showMenu:AddItem(0, L["Show Quest Blobs"], func, m)
        item:SetChecked(Nx.db.char.Map, "ShowQuestBlobs")
    end

    -- Unexplored areas toggle
    local function func(self, item)
        self.ShowUnexplored = item:GetChecked()
    end

    local item = showMenu:AddItem(0, L["Show Unexplored Areas"], func, m)
    item:SetChecked(m.ShowUnexplored)

    -- World map toggle
    m.MenuIShowWorld = showMenu:AddItem(0, L["Show World"], self.Menu_OnShowWorld, m)

    -- Continent POI toggles with refresh
    local function forceShowCont(self)
        self.ScanContinentsMod = 10
    end

    local item = showMenu:AddItem(0, L["Show Cities"], forceShowCont, Map)
    item:SetChecked(Nx.db.profile.Map, "ShowCCity")

    local item = showMenu:AddItem(0, L["Show Towns"], forceShowCont, Map)
    item:SetChecked(Nx.db.profile.Map, "ShowCTown")

    local item = showMenu:AddItem(0, L["Show Extras"], forceShowCont, Map)
    item:SetChecked(Nx.db.profile.Map, "ShowCExtra")

    -- Kill tracking toggle
    local item = showMenu:AddItem(0, L["Show Kill Icons"], self.Menu_OnShowKills, m)
    item:SetChecked(m.KillShow)

    ---------------------------------------------------------------------------
    -- MINIMAP SUBMENU
    -- Controls for minimap integration and display
    ---------------------------------------------------------------------------

    if not Nx.Free then
        local mmmenu = Nx.Menu:Create(f)
        menu:AddSubMenu(mmmenu, L["Minimap..."])

        -- Full size toggle
        local function func(self, item)
            self.LOpts.NXMMFull = item:GetChecked()
            self.MMZoomChanged = true
        end

        local item = mmmenu:AddItem(0, L["Full Size"], func, m)
        self.MMMenuIFull = item
        item:SetChecked(opts.NXMMFull)

        -- Minimap transparency
        local function func(self, item)
            self.LOpts.NXMMAlpha = item:GetSlider()
        end

        local item = mmmenu:AddItem(0, L["Transparency"], func, m)
        item:SetSlider(opts.NXMMAlpha, 0, 1)

        -- Docked minimap scale
        local function func(self, item)
            self.LOpts.NXMMDockScale = item:GetSlider()
            self.MMZoomChanged = true
        end

        local item = mmmenu:AddItem(0, L["Docked Scale"], func, m)
        item:SetSlider(opts.NXMMDockScale, .01, 3)

        -- Docked scale in battlegrounds
        local function func(self, item)
            self.LOpts.NXMMDockScaleBG = item:GetSlider()
            self.MMZoomChanged = true
        end

        local item = mmmenu:AddItem(0, L["Docked Scale In BG"], func, m)
        item:SetSlider(opts.NXMMDockScaleBG, .01, 3)

        -- Docked transparency
        local function func(self, item)
            self.LOpts.NXMMDockAlpha = item:GetSlider()
        end

        local item = mmmenu:AddItem(0, L["Docked Transparency"], func, m)
        item:SetSlider(opts.NXMMDockAlpha, 0, 1)

        -- Auto-dock threshold
        local function func(self, item)
            self.LOpts.NXMMDockOnAtScale = item:GetSlider()
        end

        local item = mmmenu:AddItem(0, L["Docking Below Map Scale"], func, m)
        item:SetSlider(opts.NXMMDockOnAtScale, 0, 5)
    end

    ---------------------------------------------------------------------------
    -- SCALE SUBMENU
    -- Size and scale controls for map elements
    ---------------------------------------------------------------------------

    local smenu = Nx.Menu:Create(f)
    menu:AddSubMenu(smenu, L["Scale..."])

    -- Auto-scale range
    local item = smenu:AddItem(0, L["Auto Scale Min"])
    item:SetSlider(opts, .01, 10, nil, "NXAutoScaleMin")

    local item = smenu:AddItem(0, L["Auto Scale Max"])
    item:SetSlider(opts, .25, 10, nil, "NXAutoScaleMax")

    -- Player dot scales
    local item = smenu:AddItem(0, L["Zone Dot Scale"], self.Menu_OnDotZoneScale, m)
    item:SetSlider(m.DotZoneScale, 0.1, 10)

    local item = smenu:AddItem(0, L["Friend/Guild Dot Scale"], self.Menu_OnDotPalScale, m)
    item:SetSlider(m.DotPalScale, 0.1, 10)

    local item = smenu:AddItem(0, L["Party Dot Scale"], self.Menu_OnDotPartyScale, m)
    item:SetSlider(m.DotPartyScale, 0.1, 10)

    local item = smenu:AddItem(0, L["Raid Dot Scale"], self.Menu_OnDotRaidScale, m)
    item:SetSlider(m.DotRaidScale, 0.1, 10)

    -- Icon scales
    local item = smenu:AddItem(0, L["Icon Scale"], self.Menu_OnIconScale, m)
    item:SetSlider(m.IconScale, 0.1, 10)

    local item = smenu:AddItem(0, L["Navigation Icon Scale"], self.Menu_OnIconNavScale, m)
    item:SetSlider(m.IconNavScale, 0.1, 10)

    -- Detail and POI scale thresholds
    local function func(self, item)
        self.LOpts.NXDetailScale = item:GetSlider()
    end

    local item = smenu:AddItem(0, L["Details At Scale"], func, m)
    item:SetSlider(opts.NXDetailScale, .05, 10)

    local item = smenu:AddItem(0, L["Gather Icons At Scale"])
    item:SetSlider(Nx.db.profile.Map, .01, 10, nil, "IconGatherAtScale")

    local item = smenu:AddItem(0, L["POI Icons At Scale"])
    item:SetSlider(opts, .1, 10, nil, "NXPOIAtScale")

    ---------------------------------------------------------------------------
    -- INSTANCE SCALE SUBMENU
    -- Scale controls specific to instance/dungeon maps
    ---------------------------------------------------------------------------

    local ismenu = Nx.Menu:Create(f)
    menu:AddSubMenu(ismenu, L["Instance Scale..."])

    local item = ismenu:AddItem(0, L["Player Arrow"])
    item:SetSlider(Nx.db.profile.Map, 1, 50, nil, "InstancePlayerSize")

    local item = ismenu:AddItem(0, L["Group Player Size"])
    item:SetSlider(Nx.db.profile.Map, 1, 50, nil, "InstanceGroupSize")

    local item = ismenu:AddItem(0, L["Raid Boss Size"])
    item:SetSlider(Nx.db.profile.Map, 1, 50, nil, "InstanceBossSize")

    local item = ismenu:AddItem(0, L["Icon Scaling Size"])
    item:SetSlider(Nx.db.profile.Map, 1, 50, nil, "InstanceScale")

    ---------------------------------------------------------------------------
    -- TRANSPARENCY SUBMENU
    -- Alpha/opacity controls for various map elements
    ---------------------------------------------------------------------------

    local tmenu = Nx.Menu:Create(f)
    m.TransMenu = tmenu

    menu:AddSubMenu(tmenu, L["Transparency..."])

    -- Detail layer transparency
    local item = tmenu:AddItem(0, L["Detail Transparency"], self.Menu_OnDetailAlpha, m)
    item:SetSlider(opts.NXDetailAlpha, .25, 1)

    -- Background fade settings
    local item = tmenu:AddItem(0, L["Fade In Transparency"], self.Menu_OnBackgndAlphaFull, m)
    item:SetSlider(m.BackgndAlphaFull, .25, 1)

    local item = tmenu:AddItem(0, L["Fade Out Transparency"], self.Menu_OnBackgndAlphaFade, m)
    item:SetSlider(m.BackgndAlphaFade, 0, 1)

    -- Gather icon transparency with update callback
    local function func(self)
        self.Guide:UpdateGatherFolders()
    end

    local item = tmenu:AddItem(0, L["Gather Icon Transparency"], func, m)
    item:SetSlider(Nx.db.profile.Map, .2, 1, nil, "IconGatherA")

    -- POI transparency
    local item = tmenu:AddItem(0, L["POI Icon Transparency"])
    item:SetSlider(Nx.db.profile.Map, .2, 1, nil, "IconPOIAlpha")

    -- Unexplored area transparency
    local function func(self, item)
        self.LOpts.NXUnexploredAlpha = item:GetSlider()
    end

    local item = tmenu:AddItem(0, L["Unexplored Transparency"], func, m)
    item:SetSlider(opts.NXUnexploredAlpha, 0, .9)

    -- Archaeology and quest blob transparency
    local item = tmenu:AddItem(0, L["Archaeology Blob Transparency"], self.Menu_OnArchAlpha, m)
    item:SetSlider(m.ArchAlpha, 0, 1)

    local item = tmenu:AddItem(0, L["Quest Blob Transparency"], self.Menu_OnQuestAlpha, m)
    item:SetSlider(m.QuestAlpha, 0, 1)

    ---------------------------------------------------------------------------
    -- OPTIONS MENU ENTRY
    ---------------------------------------------------------------------------

    local item = menu:AddItem(0, L["Options..."], self.Menu_OnOptions, m)

    ---------------------------------------------------------------------------
    -- DEBUG MENU (only shown when debug mode is enabled)
    ---------------------------------------------------------------------------

    if Nx.db.profile.Debug.DebugMap then
        m.DebugMap = true

        local dbmenu = Nx.Menu:Create(f)

        menu:AddItem(0, "", nil, self)  -- Separator
        menu:AddSubMenu(dbmenu, L["Debug..."])

        -- Debug mode toggle
        local function func(self, item)
            self.Debug = item:GetChecked()
        end

        local item = dbmenu:AddItem(0, L["Map Debug"], func, m)
        item:SetChecked(false)

        -- Hotspot debugging
        local item = dbmenu:AddItem(0, L["Hotspots"], func, m)
        item:SetChecked(m, "DebugHotspots")

        dbmenu:AddItem(0, L["Hotspots pack"], self.PackHotspotsDebug, m)

        -- Timing debug
        local function func(self, item)
            self.DebugTime = item:GetChecked()
        end

        local item = dbmenu:AddItem(0, L["Map Debug Time"], func, m)
        item:SetChecked(false)

        -- Coordinate precision
        local item = dbmenu:AddItem(0, L["Map Full Coords"], self.Menu_OnMapDebugFullCoords, m)
        item:SetChecked(m.DebugFullCoords)

        -- Quest debug (if quest module is loaded)
        if Nx.Quest then
            local item = dbmenu:AddItem(0, L["Quest Debug"], self.Menu_OnQuestDebug, m)
            item:SetChecked(Nx.Quest.Debug)
        end

        -- Scale adjustment slider
        local function func(self, item)
            self.DebugScale = item:GetSlider()
        end

        local item = dbmenu:AddItem(0, L["Scale"], func, m)
        item:SetSlider(0, 4, 6)

        -- Zone offset sliders for calibration
        local item = dbmenu:AddItem(0, L["ZWOff"], function(self, item)
            self.DebugMZWOff = item:GetSlider()
        end, m)
        item:SetSlider(0, -400, 400)

        local item = dbmenu:AddItem(0, L["ZHOff"], function(self, item)
            self.DebugMZHOff = item:GetSlider()
        end, m)
        item:SetSlider(0, -400, 400)

        local item = dbmenu:AddItem(0, L["XOff"], function(self, item)
            self.DebugMXOff = item:GetSlider()
        end, m)
        item:SetSlider(0, -400, 400)

        local item = dbmenu:AddItem(0, L["YOff"], function(self, item)
            self.DebugMYOff = item:GetSlider()
        end, m)
        item:SetSlider(0, -400, 400)

        -- Player offset sliders
        local item = dbmenu:AddItem(0, L["PXOff"], function(self, item)
            self.DebugPXOff = item:GetSlider()
        end, m)
        item:SetSlider(0, -400, 400)

        local item = dbmenu:AddItem(0, L["PYOff"], function(self, item)
            self.DebugPYOff = item:GetSlider()
        end, m)
        item:SetSlider(0, -400, 400)
    end

    ---------------------------------------------------------------------------
    -- PLAYER ICON CONTEXT MENU
    -- Actions available when right-clicking a player icon
    ---------------------------------------------------------------------------

    local menu = Nx.Menu:Create(f)
    m.PIconMenu = menu

    -- Communication options
    menu:AddItem(0, L["Whisper"], self.Menu_OnWhisper, m)
    menu:AddItem(0, L["Invite"], self.Menu_OnInvite, m)

    -- Tracking options
    local item = menu:AddItem(0, L["Track Player"], self.Menu_OnTrackPlyr, m)
    local item = menu:AddItem(0, L["Remove From Tracking"], self.Menu_OnRemoveTracking, m)

    -- Battleground-specific options
    menu:AddItem(0, L["Report Player AFK"], self.Menu_OnReportPlyrAFK, m)

    menu:AddItem(0, "")  -- Separator

    -- Conflict bar display option
    local item = menu:AddItem(0, L["Grow Conflict Bars"], self.Menu_OnGrowConflictBars, m)
    item:SetChecked(true)
    m.BGGrowBars = true

    ---------------------------------------------------------------------------
    -- GENERAL ICON MENU
    ---------------------------------------------------------------------------

    m:CreateIconMenu(f)

    ---------------------------------------------------------------------------
    -- BATTLEGROUND ICON MENU
    -- Quick communication for BG objectives
    ---------------------------------------------------------------------------

    m.BGIncNum = 0

    local menu = Nx.Menu:Create(f)
    m.BGIconMenu = menu

    -- Battleground quick messages
    -- Format: [Menu display text, Chat message text]
    local BGMessages = {
        L["Incoming"], L["Inc"],
        L["Clear"], L["Clear"],
        L["Help"], L["Help"],
        L["Attack"], L["Attack"],
        L["Guard"], L["Guard"],
        L["Well Defended"], L["Well Defended"],
        L["Losing"], L["Losing"],
    }

    -- Add each message as a menu item
    for n = 1, #BGMessages, 2 do
        local function func(self)
            self:BGMenu_Send(BGMessages[n + 1])
        end

        menu:AddItem(0, BGMessages[n], func, m)
    end

    menu:AddItem(0, L["Report Status"], self.BGMenu_OnStatus, m)

    ---------------------------------------------------------------------------
    -- PLAYER ARROW ICON
    -- The arrow showing the player's position and facing direction
    ---------------------------------------------------------------------------

    local plf = CreateFrame("Frame", nil, f)
    m.PlyrFrm = plf
    plf.NxMap = m

    plf:SetWidth(3)
    plf:SetHeight(3)

    -- Create player arrow texture
    t = plf:CreateTexture()
    plf.texture = t
    t:SetTexture("Interface\\Minimap\\MinimapArrow")
    t:SetAllPoints(plf)
    t:SetSnapToPixelGrid(false)
    t:SetTexelSnappingBias(0)

    plf:SetPoint("CENTER", 0, (m.TitleH - 1) * -.5)
    plf:Show()

    ---------------------------------------------------------------------------
    -- INITIALIZE MAP FRAMES
    ---------------------------------------------------------------------------

    m:InitFrames()

    ---------------------------------------------------------------------------
    -- QUEST AND ARCHAEOLOGY BLOB FRAMES
    -- These display colored overlays for quest objectives and dig sites
    ---------------------------------------------------------------------------

    if Nx.BlobsAvailable then
        -- Quest objective blobs
        local questwin = CreateFrame("QuestPOIFrame")
        m.QuestWin = questwin
        m.QuestWin:SetParent(m.TextScFrm:GetScrollChild())
        m.QuestWin:Hide()
        m.QuestWin:SetSize(1002, 668)
        m.QuestWin:SetFillAlpha(255 * m.QuestAlpha)
        m.QuestWin:SetBorderAlpha(255 * m.QuestAlpha)
        m.QuestWin:SetFillTexture([[Interface\WorldMap\UI-QuestBlob-Inside]])
        m.QuestWin:SetBorderTexture([[Interface\WorldMap\UI-QuestBlob-Outside]])
        m.QuestWin:SetBorderScalar(0.15)

        -- Archaeology dig site blobs
        local arch = CreateFrame("ArchaeologyDigSiteFrame")
        m.Arch = arch
        m.Arch:SetParent(m.TextScFrm:GetScrollChild())
        m.Arch:Hide()
        m.Arch:SetSize(1002, 668)
        m.Arch:SetFillAlpha(255 * m.ArchAlpha)
        m.Arch:SetBorderAlpha(255 * m.ArchAlpha)
        m.Arch:SetFillTexture([[Interface\WorldMap\UI-ArchaeologyBlob-Inside]])
        m.Arch:SetBorderTexture([[Interface\WorldMap\UI-ArchaeologyBlob-Outside]])
        m.Arch:SetBorderScalar(0.15)
    end

    ---------------------------------------------------------------------------
    -- FINALIZE MAP CREATION
    ---------------------------------------------------------------------------

    -- Set safe default map IDs
    Nx.Map.RMapId = 9000
    Nx.Map.UpdateMapID = 9000

    -- Initialize options for startup
    m:SwitchOptions(-1, true)

    -- Initial update pass
    m:UpdateAll()

    -- Pre-allocate icon frames to prevent lag during gameplay
    m:PreAllocateIcons(300)

    -- Create the guide system
    m.Guide = Map.Guide:Create(m)

    ---------------------------------------------------------------------------
    -- MINIMAP INTEGRATION
    ---------------------------------------------------------------------------

    self.MMFrm = _G["Minimap"]
    assert(self.MMFrm)

    m:MinimapOwnInit()

    -- Schedule player focus after initialization (skip if in BG)
    local function func(self)
        if not Nx.InBG then
            self:GotoPlayer()
        end
    end

    MapIShow = Nx:ScheduleTimer(func, 1, m)

    -- Set up the update handler
    f:SetScript("OnUpdate", self.OnUpdate)

    return m
end

-------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------------------------------------

---
-- Get the unique window name for this map
-- @return  Window name string (e.g., "NxMap1")
--
function Nx.Map:GetWinName()
    return "NxMap" .. self.MapIndex
end

-------------------------------------------------------------------------------
-- TOOLBAR CREATION AND MANAGEMENT
-------------------------------------------------------------------------------

---
-- Create the map toolbar with zoom and feature buttons
--
function Nx.Map:CreateToolBar()
    local bar = Nx.ToolBar:Create(self:GetWinName() .. "TB", self.Frm, 22, true, true)
    self.ToolBar = bar

    bar:SetUser(self)

    -- Define toolbar button data (shared across instances)
    if not Nx.BarData then
        Nx.BarData = {
            {"MapZIn", L["Zoom In"], self.OnButZoomIn, false},
            {"MapZOut", L["Zoom Out"], self.OnButZoomOut, false},
            {"MapGuide", L["Guide"], self.OnButToggleGuide, false},
            {"MapCombat", L["Combat"], self.OnButToggleCombat, false},
            {"MapEvents", L["Events"], self.OnButToggleEvent, false},
        }
    end

    -- Add buttons (limited in free version)
    for i, b in ipairs(Nx.BarData) do
        if Nx.Free and i > 3 then
            break
        end
        bar:AddButton(b[1], b[2], nil, b[3], b[4])
    end

    bar:Update()
    self:UpdateToolBar()
end

---
-- Update toolbar visibility based on settings
--
function Nx.Map:UpdateToolBar()
    local frm = self.ToolBar.Frm
    if Nx.db.profile.Map.ShowToolBar then
        frm:Show()
    else
        frm:Hide()
    end
end

---
-- Create the general icon context menu
-- @param frm  Parent frame for the menu
--
function Nx.Map:CreateIconMenu(frm)
    local menu = Nx.Menu:Create(frm)
    self.GIconMenu = menu

    -- Instance map toggle
    self.GIconMenuITogInst = menu:AddItem(0, L["Toggle Instance Map"], self.GMenu_OnTogInst, self)

    -- Note finding
    self.GIconMenuIFindNote = menu:AddItem(0, L["Find Note"], self.GMenu_OnFindNote, self)

    -- Clear historical kill/death marker (only visible when right-clicking
    -- a "Kill" or "Death" icon, gated dynamically in GMenuOpen).
    self.GIconMenuIClearKill = menu:AddItem(0, L["Clear"] or "Clear", self.GMenu_OnClearKill, self)

    -- Navigation options
    menu:AddItem(0, L["Goto"], self.GMenu_OnGoto, self)
    menu:AddItem(0, L["Clear Goto"], self.Menu_OnClearGoto, self)
    menu:AddItem(0, L["Paste Link"], self.GMenu_OnPasteLink, self)
end

-------------------------------------------------------------------------------
-- LOCATION TOOLTIP
-- Displays current map location information
-------------------------------------------------------------------------------

---
-- Create the location tooltip frame
--
function Nx.Map:CreateLocationTip()
    local f = CreateFrame("Frame", "NxMapTip", self.Frm)
    self.LocTipFrm = f

    f:SetClampedToScreen(true)

    -- Background texture
    local t = f:CreateTexture()
    f.texture = t
    t:SetAllPoints(f)
    t:SetColorTexture(0, 0, 0, .85)

    -- Create font strings for multi-line display
    local fstrs = {}
    self.LocTipFStrs = fstrs

    local h = Nx.Font:GetH("Font.MapLoc")

    for n = 1, 4 do
        local fstr = f:CreateFontString()
        tinsert(fstrs, fstr)
        fstr:SetFontObject("NxFontMapLoc")
        fstr:SetJustifyH("LEFT")
    end
end

---
-- Set or hide the location tooltip
-- @param tipStr  Tooltip text (multi-line supported) or nil to hide
--
function Nx.Map:SetLocationTip(tipStr)
    local f = self.LocTipFrm
    local a = Nx.db.profile.Map.LocTipAnchor

    if tipStr and a ~= "None" then
        -- Position the tooltip frame
        local ar = Nx.db.profile.Map.LocTipAnchorRel
        ar = ar == "None" and a or ar
        f:ClearAllPoints()
        f:SetPoint(a, self.Frm, ar)

        local h = Nx.Font:GetH("Font.MapLoc")
        local fstrs = self.LocTipFStrs
        local i = 1
        local textW = 0

        -- Parse multi-line text
        for s in gmatch(tipStr, "(%C+)") do
            local fstr = fstrs[i]
            fstr:SetPoint("TOPLEFT", 2, 0 - (i - 1) * h)
            fstr:SetText(s)
            textW = max(textW, fstr:GetStringWidth())
            i = i + 1
        end

        -- Clear unused lines
        for n = i, #fstrs do
            fstrs[n]:SetText("")
        end

        -- Size frame to fit content
        f:SetWidth(4 + textW)
        f:SetHeight(2 + (i - 1) * h)
        f:Show()
    else
        f:Hide()
    end
end

-------------------------------------------------------------------------------
-- UPDATE AND EVENT HANDLING
-------------------------------------------------------------------------------

---
-- Startup zoom handler (currently disabled)
--
function Nx.Map:StartupZoom()
    -- Placeholder for startup zoom behavior
end

---
-- Main frame update event handler
-- Called every frame to process map updates even when hidden
-- @param elapsed  Time since last frame
--
function Nx.Map:MainOnUpdate(elapsed)
    if self.Created then
        local map = self:GetMap(1)
        local win = map.Win
        local show, showsv = win:IsShown()

        if not show then
            -- Check if we were hidden externally (e.g., Escape key)
            if showsv and not win:IsCombatHidden() then
                win:Show()
                map:RestoreSize()
                return
            end

            -- Continue processing updates even when hidden
            self.OnUpdate(map.Frm, elapsed)
        end
    end
end

---
-- Window state change handler
-- @param typ  Event type: "SizeNorm", "SizeMax", or "Close"
--
function Nx.Map:OnWin(typ)
    if typ == "SizeNorm" then
        -- Restored to normal size
        self:RestoreSize()

    elseif typ == "SizeMax" then
        -- Maximized
        if WorldMapFrame:IsShown() then
            HideUIPanel(WorldMapFrame)
        end
        tinsert(UISpecialFrames, self:GetWinName())
        self:AttachWorldMap()

    elseif typ == "Close" then
        -- Window closed (placeholder for future use)
    end
end

---
-- Attach world map elements to our frame (currently disabled)
--
function Nx.Map:AttachWorldMap()
--[[
    -- Legacy code for world map attachment
    if not Nx.db.profile.Map.WOwn then
        return
    end
    local f = _G["WorldMapButton"]
    if f then
        self.WorldMapFrm = f
        self.WorldMapFrmParent = f:GetParent()
        self.WorldMapFrmScale = f:GetScale()

        f:SetParent(self.TextFrm)
        f:Show()
        f:EnableMouse(false)

        self:SetWorldMapIcons (.001)

        local tipf = _G["GameTooltip"]
        if tipf then
            tipf:SetParent (self.Frm)
        end

        local af = _G["WorldMapFrameAreaFrame"]
        if af then
            af:Hide()
--            af:SetParent (self.Frm)
--            af:SetPoint ("TOP", self.Frm, "TOP", 0, 0)
        end

--        Gatherer.MapNotes.MapDraw = function() Nx.prt ("Gath mapdraw") end

        -- Remove leftovers
        for n = 1, NUM_WORLDMAP_POIS do
            local f = _G["WorldMapFramePOI" .. n]
            f:Hide()
        end

        self.WorldMapFrmMapId = 0
    end
]]--
end

--------
--

function Nx.Map:DetachWorldMap()
    ---- THIS DOES NOT WORK, UNTIL FIXED DISABLING IT
--[[
    local f = self.WorldMapFrm

    if f then

--        Nx.prt ("DetachWorldMap")

        self.WorldMapFrm = nil

        f:SetParent (self.WorldMapFrmParent)
        f:SetScale (self.WorldMapFrmScale)
        f:SetPoint ("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", 0, 0)
        f.GetCenter = self.WorldMapFrmGetCenter

        f:EnableMouse (true)

        self:SetWorldMapIcons (1)

        local tipf = _G["GameTooltip"]
        if tipf then
            tipf:SetParent (self.WorldMapFrmParent)
            tipf:SetFrameStrata ("TOOLTIP")
        end

        local af = _G["WorldMapFrameAreaFrame"]
        if af then
            af:Show()
--            af:SetParent (f)
--            af:SetPoint ("TOP", f, "TOP", 0, -10)
        end

    end
]]--
end

--------
-- Update Blizzard world map frame if we grabbed it

function Nx.Map:UpdateWorldMap()

    local f = self.WorldMapFrm

    -- Legacy faction check code - disabled as it only applied to MoP content
    -- and the API has been moved to C_Reputation in newer clients
    --[[
    local GetNumFactions = GetNumFactions or (C_Reputation and C_Reputation.GetNumFactions)
    local GetFactionInfo = GetFactionInfo or (C_Reputation and C_Reputation.GetFactionDataByIndex)
    if GetNumFactions and GetFactionInfo then
        for factionIndex = 1, GetNumFactions() do
            local name = GetFactionInfo(factionIndex)
            if type(name) == "table" then name = name.name end
            if (name == L["Operation: Shieldwall"]) or (name == L["Dominance Offensive"]) then
                self.MapWorldInfo[418].Overlay = "krasarang_terrain1"
            end
        end
    end
    ]]--

    if f then
        -- Hide WorldMapFrm for instance maps with NXInstanceMaps option enabled
        -- These maps are rendered via MoveWorldMap instead to avoid duplicate textures
        local isInstanceWithOverlay = (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps

        if self.StepTime ~= 0 or self.Scrolling or IsShiftKeyDown() or isInstanceWithOverlay then
            f:Hide()
        else

            f:Show()

            self:ClipZoneFrm (self.Cont, self.Zone, f, 1)
            f:SetFrameLevel (self.Level)
            if self.WorldMapFrmMapId ~= self.MapId then
--                Nx.prt ("mapid %s", self.MapId)
                self.WorldMapFrmMapId = self.MapId
                self:SetChildLevels (f, self.Level + 1)
                self.Level = self.Level + 4
            end
        end

        for k, v in ipairs (_G["MAP_VEHICLES"]) do
            v:SetScale (.001)
        end
    end
    if not InCombatLockdown() and Nx.BlobsAvailable then
        -- Skip blob drawing for instance maps as they cause rendering issues with UnitPositionFrame
        local isInstanceMap = self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)

        self.Arch:DrawNone();
        -- Hide arch blobs during zoom animation or manual scrolling to prevent position/scale mismatch
        -- Note: We check for scale change rather than StepTime != 0, because StepTime is also set
        -- when following the player (position change only), and we want blobs visible during that
        local isZooming = abs(self.ScaleDraw - self.Scale) > 0.001
        if isZooming or self.Scrolling or isInstanceMap then
            self.Arch:Hide()
        elseif Nx.db.char.Map.ShowArchBlobs then
            local digSites = C_ResearchInfo.GetDigSitesForMap(Nx.Map:GetCurrentMapAreaID());
            for i, digSite in ipairs(digSites) do
                self.Arch:DrawBlob(digSite.poiBlobID, true)
            end
            self:ClipZoneFrm( self.Cont, self.Zone, self.Arch, 1 )
            self.Arch:SetFrameLevel(self.Level)
            self.Arch:SetFillAlpha(255 * self.ArchAlpha)
            self.Arch:SetBorderAlpha(255 * self.ArchAlpha)
            self.Arch:SetMapID(Nx.Map:GetCurrentMapAreaID())
            self.Arch:Show()
        else
            self.Arch:Hide()
        end

        -- World Quest blob drawing (only for super-tracked world quests)
        -- Regular quest blobs are handled separately in NxQuest.lua
        local superTrackedQuestID = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
        local isWorldQuest = superTrackedQuestID and superTrackedQuestID > 0 and QuestUtils_IsQuestWorldQuest and QuestUtils_IsQuestWorldQuest(superTrackedQuestID)

        if isWorldQuest and not isInstanceMap then
            self.QuestWin:DrawNone()
            if isZooming or self.Scrolling then
                self.QuestWin:Hide()
            elseif Nx.db.char.Map.ShowQuestBlobs then
                self.QuestWin:DrawBlob(superTrackedQuestID, true)
                self:ClipZoneFrm(self.Cont, self.Zone, self.QuestWin, 1)
                self.QuestWin:SetFrameLevel(self.Level)
                self.QuestWin:SetFillAlpha(255 * self.QuestAlpha)
                self.QuestWin:SetBorderAlpha(255 * self.QuestAlpha)
                self.QuestWin:SetMapID(Nx.Map:GetCurrentMapAreaID())
                self.QuestWin:Show()
            else
                self.QuestWin:Hide()
            end
            -- Mark that we're showing a world quest blob so NxQuest.lua doesn't interfere
            self.ShowingWorldQuestBlob = true
        elseif isInstanceMap then
            -- Hide QuestWin for instance maps to prevent world map rendering issues
            self.QuestWin:DrawNone()
            self.QuestWin:Hide()
            self.ShowingWorldQuestBlob = false
        else
            -- Not tracking a world quest - clear the blob if we were showing one
            if self.ShowingWorldQuestBlob then
                self.QuestWin:DrawNone()
                self.QuestWin:Hide()
            end
            -- Let NxQuest.lua handle regular quest blobs
            self.ShowingWorldQuestBlob = false
        end
    end
end

--------
-- Recursively set child levels

function Nx.Map:SetChildLevels (frm, lvl)

    local ch = { frm:GetChildren() }

    for n, chf in pairs (ch) do

        chf:SetFrameLevel (lvl)

        if chf:GetNumChildren() > 0 then
            self:SetChildLevels (chf, lvl + 1)
        end
    end
end

--------
-- Set scale on world map icons

function Nx.Map:SetWorldMapIcons (scale)

    for n = 1, MAX_PARTY_MEMBERS do
        local f = _G["WorldMapParty" .. n]
        if f then
            f:SetScale (scale)
        end
    end
    for n = 1, MAX_RAID_MEMBERS do
        local f = _G["WorldMapRaid" .. n]
        if f then
            f:SetScale (scale)
        end
    end
    local flags = GetNumBattlefieldFlagPositions()
    for n = 1, flags do
        local f = _G["WorldMapFlag" .. n]
        if f then
            f:SetScale (scale)
        end
    end

    for k, f in ipairs (_G["MAP_VEHICLES"]) do
        f:SetScale (scale)
    end

    for k, name in ipairs (Nx.Map.WorldMapHideNames) do

        local f = _G[name]
        if f then
            f:SetScale (scale)
        end
    end
end

--------
--

function Nx.Map:OnButZoomIn()
    self:SetScaleOverTime (2)
end

function Nx.Map:OnButZoomOut()
    self:SetScaleOverTime (-2)
end

function Nx.Map:OnButToggleGuide (but)
    self.Guide:ToggleShow()
end

function Nx.Map:OnButToggleEvent (but)
    Nx.UEvents.List:Open()
end

--------
-- Init static map frames

function Nx.Map:InitFrames()

    local f = self.Frm
    local m = self

    -- Create map zone tile frames

    self.TileFrms = {}

    local tf

    for i = 1, 150 do

        tf = CreateFrame ("Frame", nil, f)
        m.TileFrms[i] = tf

        local t = tf:CreateTexture()
        t:SetAllPoints (tf)
        t:SetSnapToPixelGrid(false)
        t:SetTexelSnappingBias(0)
        tf.texture = t
    end

    -- Init continent frames
    Nx.ContBlks = self.ContBlks
    self.ContFrms = {}

    for n = 1, Nx.Map.ContCnt do

        self.ContFrms[n] = {}

        local mapFileName = self.MapInfo[n].FileName
        local texi = 1

--        Nx.prt ("Map Update ".. mapFileName)
        local tileX    = self.MapInfo[n].TileX or 4
        local tileY    = self.MapInfo[n].TileY or 3
        local numtiles = tileX * tileY

        for i = 1, numtiles do
            if Nx.ContBlks[n][i] ~= 0 then
                local cf = CreateFrame ("Frame", nil, f)
                m.ContFrms[n][i] = cf

                local t = cf:CreateTexture()
                t:SetAllPoints (cf)
                cf.texture = t

                t:SetTexture ("Interface\\WorldMap\\"..mapFileName.."\\"..mapFileName..i)

                t:SetSnapToPixelGrid(false)
                t:SetTexelSnappingBias(0)
            end
        end
    end

    -- Create mini frames

    self.MiniFrms = {}

    for n = 1, self.MiniBlks ^ 2 do

        local tf = CreateFrame ("Frame", nil, f)
        m.MiniFrms[n] = tf

        local t = tf:CreateTexture()
        tf.texture = t
        t:SetAllPoints (tf)
        t:SetSnapToPixelGrid(false)
        t:SetTexelSnappingBias(0)
    end

    self:InitHotspots()
end

--------
-- Init hotspots

function Nx.Map:InitHotspots()

    local quad = {}
    self.WorldHotspots = quad
    local quadCity = {}
    self.WorldHotspotsCity = quadCity

    for contN = 1, Nx.Map.ContCnt do

        cname = self:GetWorldContinentInfo (contN)
        if not cname then
            break
        end
        for _,zoneN in pairs(Nx.Map.MapZones[contN]) do
            zname, zx, zy, zw, zh = self:GetWorldZoneInfo (contN, zoneN)
            if not zx then
                break
            end

            local color, infoStr = self:GetMapNameDesc (zoneN)
            local tipStr = format ("%s, %s%s (%s)", L[cname], color, zname, infoStr)

            local loc = Nx.MapWorldHotspots[nxz]    -- Old way
            local locSize = 4
            local mapId = zoneN

            if not loc then

                loc = Nx.MapWorldHotspots2[mapId]
                if loc then
                    locSize = 12
                else
                    loc = format ("%c%c%c%c", 85, 85, 135, 135)
                end
            end

            for n = 0, 100 do

                local locN = n * locSize + 1

                local loc1 = strsub (loc, locN, locN + locSize - 1)
                if loc1 == "" then
                    break
                end

                local zx, zy, zw, zh

                if locSize == 4 then
                    zx, zy, zw, zh = Nx.Map:UnpackLocRect (loc1)
                else
                    zx = tonumber (strsub (loc1, 1, 3), 16) * 100 / 4095
                    zy = tonumber (strsub (loc1, 4, 6), 16) * 100 / 4095
                    zw = tonumber (strsub (loc1, 7, 9), 16) * 1002 / 4095
                    zh = tonumber (strsub (loc1, 10, 12), 16) * 668 / 4095
                end

                local spot = {}

                local wzone = self:GetWorldZone (mapId)

                if wzone.City or wzone.StartZone then
                    tinsert (quadCity, spot)
                else
                    tinsert (quad, spot)
                end

                spot.MapId = mapId

                spot.x = tonumber (strsub (loc1, 1, 3), 16)
                spot.y = tonumber (strsub (loc1, 4, 6), 16)
                spot.zx = zx
                spot.zy = zy

                local wx, wy = self:GetWorldPos (mapId, zx, zy)
                spot.WX1 = wx
                spot.WY1 = wy
                zw = zw / 1002 * 100
                zh = zh / 668 * 100
                local wx, wy = self:GetWorldPos (mapId, zx + zw, zy + zh)
                spot.WX2 = wx
                spot.WY2 = wy

                spot.NxTipBase = tipStr

--                if contN == 5 then
--                    Nx.prtVar ("Spot", spot)
--                end

            end
        end
    end

end

--------
-- Get description (color) that goes with a map nane

function Nx.Map:GetMapNameDesc (mapId)

--    Nx.prt ("MapId %s", mapId)
    local whichzone = Nx.Zones[mapId] or Nx.Zones[0]
    local _, minLvl, maxLvl, faction = Nx.Split ("|", whichzone)
    minLvl = tonumber (minLvl)
    faction = tonumber (faction)

    local infoStr = format ("%d-%d", minLvl, maxLvl)

    local color = "|cffffffff"
    if self.PlFactionNum == faction then
        color = "|cff20ff20"
    elseif faction == 2 then
        color = "|cffffff00"
    elseif faction < 2 then
        color = "|cffff6060"
    end

    if minLvl == 0 then
        infoStr = L["Any"]
    end
    if self:GetWorldZone(mapId).City then
        infoStr = L["City"]
        minLvl = -1
    end

    return color, infoStr, minLvl
end

--------
-- Init minimap ownership

function Nx.Map:MinimapOwnInit()
    self.MMScales = {}
    for n = 1, 6 do
        self.MMScales[n] = (8 - n) * 66.6666666666666 / 5.0
    end
    self.MMScalesC = { 300, 240, 180, 120, 80, 50 }
    for n = 1, 6 do
        self.MMScalesC[n] = self.MMScalesC[n] / 5.0
    end
    --
    local mm = self.MMFrm
    local mmc = _G["MinimapCluster"]
    self.MMChkDelay = 5        -- Prevent crash here
    self.MMOwnedFrms = {}
    if not self.MMOwn then
        self.Win:Show (self.StartupShown)
        Nx.Map:MinimapButtonShowUpdate()
        return
    end
    mm:SetMaskTexture (Nx.isRetail and "Interface\\CharacterFrame\\TempPortraitAlphaMask" or "textures\\MinimapMask")
    self:MinimapNodeGlowInit()
    Nx.Map:MinimapButtonShowUpdate (true)

    mm:SetClampedToScreen (true)
    mm:SetWidth (140)
    mm:SetHeight (140)
    self.MMAlphaDelay = 100

    mm:SetParent (self.Frm)

    --self.MMFrm:SetQuestBlobRingAlpha(1)
    self.MMFrm:SetPOIArrowTexture("Interface\\Addons\\Carbonite\\Gfx\\Map\\32Transparent")
    self.MMFrm:SetStaticPOIArrowTexture("Interface\\Addons\\Carbonite\\Gfx\\Map\\32Transparent")
    mm:SetScript ("OnMouseDown", self.MinimapOnMouseDown)
    mm:SetScript ("OnMouseUp", self.MinimapOnMouseUp)
    mm:SetScript ("OnEnter", self.MinimapOnEnter)
    mm:SetScript ("OnLeave", self.MinimapOnLeave)

--    local prtFrameChildren = Nx.prtFrameChildren
--    prtFrameChildren ("Minimap", mm)
--    prtFrameChildren ("MinimapCluster", mmc)

--[[
    local mmsf = CreateFrame ("ScrollFrame", nil, self.Frm)
    self.MMScFrm = mmsf

    mm:SetParent (mmsf)

    mmsf:SetAllPoints (self.Frm)
--    mmsf:SetScrollChild (mm)
--]]

    -- Ping

--[[    --V4
    local ping = MinimapPing
    ping:SetParent (UIParent)

    self.MMOwnedFrms[ping] = 0
--]]

    -- Data setup

    self.MMModels = {}
    self.MMAddonFrms = {}

    local f = _G["MinimapBackdrop"]
    if f then
        f:Hide()
        f:SetParent (mmc)
    end

    hooksecurefunc("Minimap_ZoomIn", Nx.Map.Minimap_ZoomInClick)
    hooksecurefunc("Minimap_ZoomOut", Nx.Map.Minimap_ZoomOutClick)
end

-------------------------------------------------------------------------------
-- MINIMAP ZOOM HANDLERS
-------------------------------------------------------------------------------

---
-- Handle minimap zoom in click
--
function Nx.Map.Minimap_ZoomInClick()
    local map = Nx.Map:GetMap(1)
    map:MinimapZoom(2)
end

---
-- Handle minimap zoom out click
--
function Nx.Map.Minimap_ZoomOutClick()
    local map = Nx.Map:GetMap(1)
    map:MinimapZoom(-2)
end

---
-- Handle minimap events
--
function Nx.Map.Minimap_OnEvent()
    local map = Nx.Map:GetMap(1)
    map:MinimapZoom()
end

---
-- Process minimap zoom and re-enable buttons
-- @param value  Zoom amount (positive = in, negative = out)
--
function Nx.Map:MinimapZoom(value)
    if value then
        self:SetScaleOverTime(value)
    end

    -- Re-enable zoom buttons
    local f = _G["MinimapZoomIn"]
    if f then
        f:Enable()
    end

    local f = _G["MinimapZoomOut"]
    if f then
        f:Enable()
    end
end

-------------------------------------------------------------------------------
-- MINIMAP MOUSE HANDLERS
-------------------------------------------------------------------------------

---
-- Handle mouse down on minimap
-- @param button  Mouse button pressed
--
function Nx.Map:MinimapOnMouseDown(button)
    local this = self
    local map = Nx.Map.Maps[1]

    -- Check for ping action (left click when not zoomed, or shift+click)
    if (map.MMZoomType == 0 and button == "LeftButton") or
            (IsShiftKeyDown() and not IsControlKeyDown()) then
        this.NXPing = true
    else
        this.NXPing = nil
        this.NxMap = map
        map.OnMouseDown(this, button)
    end
end

---
-- Handle mouse up on minimap
-- @param button  Mouse button released
--
function Nx.Map:MinimapOnMouseUp(button)
    local this = self
    local map = Nx.Map.Maps[1]

    if this.NXPing then
        -- On retail, both Minimap:OnClick (which calls Minimap:PingLocation
        -- internally) and our own map:Ping (which also calls PingLocation)
        -- are forbidden from this tainted Lua path. Skip the ping silently
        -- on retail — Carbonite-merged minimap pings just aren't available.
        -- The user can disable MMOwn to get natural Blizzard minimap pings.
        if not Nx.isRetail then
            if map.MMZoomType == 0 then
                if _G.Minimap_OnClick then
                    _G.Minimap_OnClick(this)
                elseif this.OnClick then
                    this:OnClick(button or "LeftButton")
                end
            else
                map:Ping()
            end
        end
    else
        this.NxMap = map
        map.OnMouseUp(this, button)
    end
end

---
-- Create a ping at the clicked location
--
function Nx.Map:Ping()
    local frm = self.Frm
    local mx, my = Nx.Util_GetMouseClampedXY(frm)
    local top = frm:GetTop()
    local bottom = frm:GetBottom()
    my = top - (my + bottom)

    local mm = self.MMFrm

    -- Get appropriate scale set based on city status
    local scales = self.MMScales
    local info = self.MapWorldInfo[self.MapId]

    if info.City and not info.MMOutside then
        scales = self.MMScalesC
    end

    local zoom = mm:GetZoom() + 1

    -- Convert frame position to world coordinates
    local wx, wy = self:FramePosToWorldPos(mx, my)

    local sc = scales[zoom] / mm:GetWidth()
    local x = wx - self.PlyrX
    local y = self.PlyrY - wy

    mm:PingLocation(x / sc, y / sc)
end

---
-- Handle mouse entering minimap
-- @param motion  Motion flag
--
function Nx.Map:MinimapOnEnter(motion)
    local map = Nx.Map.Maps[1]
    if map.MMZoomType ~= 0 then
        local this = self
        this.NxMap = map
        map.IconOnEnter(self, motion)
    end
end

---
-- Handle mouse leaving minimap
-- @param motion  Motion flag
--
function Nx.Map:MinimapOnLeave(motion)
    local map = Nx.Map.Maps[1]
    if map.MMZoomType ~= 0 then
        local this = self
        this.NxMap = map
        map.IconOnLeave(self, motion)
    end
end

---
-- Update visibility of minimap buttons based on settings
-- @param justNameplate  If true, only update nameplate setting
--
function Nx.Map:MinimapButtonShowUpdate(justNameplate)
    -- Frame name to setting name mapping
    local t = {
        "MinimapCluster", "ShowOldNameplate",
        "NXMiniMapBut", "ButShowCarb",
        "GameTimeFrame", "ButShowCalendar",
        "TimeManagerClockButton", "ButShowClock",
        "MiniMapWorldMapButton", "ButShowWorldMap",
        "MiniMapLFGFrame", "ButShowLFG",
    }

    for n = 1, #t, 2 do
        local skip

        -- Skip certain frames in free version
        if Nx.Free then
            if t[n] == "MinimapCluster" then
                skip = true
            end
        end

        -- Don't modify during combat
        if InCombatLockdown() then
            skip = true
        end

        if not skip then
            local f = _G[t[n]]
            if f then
                if Nx.db.profile.MiniMap[t[n + 1]] then
                    f:Show()
                else
                    f:Hide()
                end
            end
        end

        if justNameplate then
            break
        end
    end
end

-------------------------------------------------------------------------------
-- MINIMAP NODE GLOW EFFECTS
-- Creates a pulsing effect on gathering nodes
-------------------------------------------------------------------------------

-- Frame for holding blinker textures
CreateFrame("FRAME", "NXMinimapBlinkerFrame")

---
-- Initialize minimap node glow effect
-- Called during init and from options when settings change
-- @param reset  If true, reset to default blip texture
--
function Nx.Map:MinimapNodeGlowInit(reset)
    local mm = self.MMFrm

    -- Cancel existing timer
    Nx:CancelTimer(MapNodeGlow)

    if reset then
        mm:SetBlipTexture("Interface\\Minimap\\ObjectIconsAtlas")
    end

    local delay = Nx.db.profile.MiniMap.NodeGD

    if delay > 0 then
        if not self.MMGlowInited then
            self.MMGlowInited = true

            -- Pre-load textures to prevent corruption when switching
            local t = NXMinimapBlinkerFrame:CreateTexture(nil, "OVERLAY")
            t:SetAllPoints()
            t:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\MMOIcons")

            local t = NXMinimapBlinkerFrame:CreateTexture(nil, "OVERLAY")
            t:SetAllPoints()
            t:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\MMOIconsG")
        end

        -- Start glow timer
        GlowLetter = ""
        MapNodeGlow = Nx:ScheduleRepeatingTimer(self.OnMinimapNodeGlowTimer, Nx.db.profile.MiniMap.NodeGD * 2, self)
    end
end

---
-- Timer callback for node glow animation
-- Alternates between normal and glowing textures
-- @param name  Timer name (unused)
-- @return      Next timer interval
--
function Nx.Map:OnMinimapNodeGlowTimer(name)
    if GlowLetter == "" then
        self:MinimapNodeGlowSet("")
        GlowLetter = "G"
    else
        self:MinimapNodeGlowSet("G")
        GlowLetter = ""
    end
    return Nx.db.profile.MiniMap.NodeGD * 2
end

---
-- Set the minimap blip texture for glow effect
-- @param letter  Texture suffix ("" or "G" for glow)
--
function Nx.Map:MinimapNodeGlowSet(letter)
    self.MMFrm:SetBlipTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\MMOIcons" .. letter)
end

-------------------------------------------------------------------------------
-- MINIMAP UPDATE
-- Main update loop for minimap positioning and state
-------------------------------------------------------------------------------

---
-- Update minimap display and positioning
-- Handles docking, scaling, transparency, and indoor/outdoor transitions
--
function Nx.Map:MinimapUpdate()
    -- Skip if we don't own the minimap
    if not self.MMOwn then
        self:MinimapDetachFrms()
        return
    end

    -- Apply debug scale override if active
    if self.DebugScale then
        self.MMScale = 0
        local sc = self.DebugScale

        for n = 1, 6 do
            self.MMScales[n] = (8 - n) * 66.6666666666666 / sc
        end
    end

    local mm = self.MMFrm
    local lOpts = self.LOpts

    -- Get appropriate scale set based on zone type
    local scales = self.MMScales
    local info = self.MapWorldInfo[Nx.Map.UpdateMapID]
    if not info then
        info = {}
    end
    if info.City and not info.MMOutside then
        scales = self.MMScalesC
    end

    local zoomType = 0
    local zoom = mm:GetZoom(1)

    -- Determine if minimap should be docked
    local dock = lOpts.NXMMFull or Nx.db.profile.MiniMap.DockAlways

    if self.Win:IsSizeMax() and Nx.db.profile.MiniMap.DockOnMax then
        dock = true
    end

    if (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
        dock = true
    end

    -- Position minimap on the main map if not docked
    if not dock and not self.InstanceId
            and self.ScaleDraw > lOpts.NXMMDockOnAtScale then
        if not InCombatLockdown() then
            mm:ClearAllPoints()
        else
            return
        end

        -- Find appropriate zoom level
        for n = 1, 6 do
            local sz = scales[n]

            if self:ClipMMW(mm, self.PlyrX, self.PlyrY, sz, sz) then
                zoomType = n
                break
            end
        end
    end

    -- Calculate transparency
    local al = lOpts.NXMMAlpha

    -- Check indoor/outdoor state
    local indoors = IsIndoors() or Nx.Map.Indoors
    local resting = IsResting()
    local indoorChange = self.Indoors ~= indoors
    self.Indoors = indoors

    -- Check for bugged areas
    local bugged = false
    local bugtest = GetSubZoneText()
    for _, zonetest in ipairs(Nx.BuggedAreas) do
        if Nx.Map:GetCurrentMapAreaID() == zonetest and not indoors then
            bugged = true
        end
    end
    for _, zonetest in ipairs(Nx.BuggedSubZones) do
        if bugtest == zonetest then
            bugged = true
        end
    end

    -- Adjust based on various conditions
    if self.InstanceId and not self.CurOpts.NXInstanceMaps then
        al = 1
    else
        -- Force dock in certain conditions
        if indoors and Nx.db.profile.MiniMap.DockIndoors then
            zoomType = 0
        end
        if bugged and Nx.db.profile.MiniMap.DockBugged then
            zoomType = 0
        end
        if Nx.InBG then
            zoomType = 0
        end

        -- Auto-toggle full size based on indoor state
        if indoorChange and Nx.db.profile.MiniMap.IndoorTogFullSize then
            lOpts.NXMMFull = false
            if not info.City and indoors then
                lOpts.NXMMFull = true
            end
            self.MMMenuIFull:SetChecked(lOpts.NXMMFull)
            Nx.Menu:CheckUpdate(self.MMMenuIFull)
        end

        -- Auto-toggle for bugged areas
        if Nx.db.profile.MiniMap.BuggedTogFullSize then
            if bugged then
                lOpts.NXMMFull = true
            else
                lOpts.NXMMFull = false
            end
            self.MMMenuIFull:SetChecked(lOpts.NXMMFull)
            Nx.Menu:CheckUpdate(self.MMMenuIFull)
        end

        -- Auto-toggle for instances
        if Nx.db.profile.MiniMap.InstanceTogFullSize then
            local _, instanceType = GetInstanceInfo()
            if self:IsInstanceMap(Nx.Map.RMapId) or (instanceType ~= nil and instanceType ~= "none") then
                lOpts.NXMMFull = true
            else
                lOpts.NXMMFull = false
            end
            self.MMMenuIFull:SetChecked(lOpts.NXMMFull)
            Nx.Menu:CheckUpdate(self.MMMenuIFull)
        end

        if zoomType == 0 then
            al = 1
        end

        -- Modifier key overrides
        if IsControlKeyDown() or IsIndoors() or Nx.Map.Indoors then
            al = IsAltKeyDown() and 1 or .8
            self.MMZoomChanged = true
        end
    end

    -- Detect zoom/scale changes
    if self.MMZoomType ~= zoomType or zoomType > 0 and self.MMScale ~= self.ScaleDraw
            or indoorChange then

        self.MMZoomType = zoomType
        self.MMScale = self.ScaleDraw
        self.MMZoomChanged = true

        if self.MMAlphaDelay == 0 then
            self.MMAlphaDelay = 2
        end
    end

    -- Process alpha delay
    if self.MMAlphaDelay > 0 then
        self.MMAlphaDelay = self.MMAlphaDelay - 1
        self.MMZoomChanged = true
    end

    mm:SetAlpha(al)
    self:MinimapDetachFrms()

    -- Apply zoom type specific settings
    if zoomType > 0 then
        self:MinimapUpdateMask("Square")

        local above = IsControlKeyDown()

        if Nx.db.profile.MiniMap.AboveIcons then
            above = not above
        end

        local lvl = self.Level
        if above then
            lvl = lvl + 15
        end

        mm:SetFrameLevel(lvl)
        self:MinimapUpdateDetachedFrms(lvl + 1)
        self.Level = self.Level + 2
    else
        -- Calculate docked scale
        local sc = self.MMFScale

        self.MMFScale = Nx.InBG and lOpts.NXMMDockScaleBG or lOpts.NXMMDockScale
        if lOpts.NXMMFull then
            self.MMFScale = min(self.MapW, self.MapH) / 140
        end
    end
end

---
-- Finalize minimap update pass
-- Sets final position, scale, and visibility
--
function Nx.Map:MinimapUpdateEnd()
    if not self.MMOwn then
        return
    end

    -- Skip during combat
    if InCombatLockdown() then
        return
    end

    local mm = self.MMFrm
    local mmfull = self.LOpts.NXMMFull

    local info = self:GetWorldZone(Nx.Map:GetCurrentMapAreaID())
    local _, class = UnitClass("player")

    -- Check if we should hide minimap
    if (self:IsInstanceMap(Nx.Map.UpdateMapID) or self:IsBattleGroundMap(Nx.Map.UpdateMapID)) and self.CurOpts.NXInstanceMaps then
        -- Keep minimap visible in instances with instance maps enabled
    else
        -- Hide conditions: maximized, very small scale, in instance map, in city, or in garrison
        if self.Win:IsSizeMax() and Nx.db.profile.MiniMap.HideOnMax
                or self.MMFScale < .02
                or Nx.Map.NInstMapId ~= nil
                or info.City and not info.MMOutside
                -- Ensure C_Garrison and GarrisonType enum is valid before calling IsPlayerInGarrison
                or (C_Garrison and Enum.GarrisonType and (
                (Enum.GarrisonType.Type_6_0_Garrison and C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_6_0_Garrison)) or
                (Enum.GarrisonType.Type_7_0_Garrison and C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_7_0_Garrison)) or
                (Enum.GarrisonType.Type_8_0_Garrison and C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_8_0_Garrison)) or
                (Enum.GarrisonType.Type_9_0_Garrison and C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_9_0_Garrison))
                )) then
            mm:SetPoint("TOPLEFT", 1, 0)
            mm:SetScale(.02)
            mm:SetFrameLevel(1)

            -- Also minimize model frames
            for n, f in ipairs(self.MMModels) do
                f:SetScale(.001)
            end
            return
        end
    end

    -- Position docked minimap
    if self.MMZoomType == 0 then
        self:MinimapUpdateMask("DockSquare")

        local iconScale = Nx.db.profile.MiniMap.DockIScale

        self:MinimapSetScale(self.MMFScale, iconScale)

        local x = 0
        local y = 0
        local sz = 140 * self.MMFScale

        if Nx.db.profile.MiniMap.DockRight then
            x = (self.MapW - sz + 1)
        end
        if Nx.db.profile.MiniMap.DockBottom then
            y = (self.MapH - sz + 1)
        end

        mm:ClearAllPoints()
        mm:SetPoint ("TOPLEFT", (x + Nx.db.profile.MiniMap.DXO) / iconScale,
                                        (-y - Nx.db.profile.MiniMap.DYO) / iconScale)
        mm:Show()
        if (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
            mm:SetFrameLevel (self.Level + 50)
        else
            mm:SetFrameLevel (self.Level)
        end
        self:MinimapUpdateDetachedFrms (self.Level + 1)
        self.Level = self.Level + 2
    end

    if self.MMZoomChanged then

        self.MMZoomChanged = false

        local zoom = max (self.MMZoomType - 1, 0)

        if self.MMZoomType == 0 then
            zoom = Nx.db.profile.MiniMap.DockZoom
        end

        local z = zoom - 1
        if z < 0 then
            z = 1
        end

        -- Force icon update
        mm:SetZoom (z)
        mm:SetZoom (zoom)

--        Nx.prt ("zoom %d", zoom)

        if self.MMZoomType == 0 then
            mm:SetAlpha (1)
        end

--        if Gatherer then
--            Nx.Timer:Start ("Gatherer", .1, self, self.OnGathererTimer)
--        end
    end

    -- Transfer window and minimap scale

    --V4 gone TEST!!!!!!!!!
--    MinimapPing:SetScale (self.Win.Frm:GetScale() * mm:GetScale())
end

function Nx.Map:MinimapSetScale (scale, iconScale)
    --if InCombatLockdown() and Nx.db.profile.Map.Compatibility then
    if InCombatLockdown() then
        return
    end
    local mm = self.MMFrm
    local sz = 140 * scale / iconScale
    mm:SetWidth (sz)
    mm:SetHeight (sz)
    mm:SetScale (iconScale)
end

function Nx.Map:MinimapUpdateMask (optName)

    local roundMask = Nx.isRetail and "Interface\\CharacterFrame\\TempPortraitAlphaMask" or "textures\\MinimapMask"
    local name = Nx.db.profile.MiniMap[optName] and "Interface\\Buttons\\White8x8" or roundMask

--    if IsControlKeyDown() then
--        self.MMMaskName = nil
--    end

    if self.MMMaskName ~= name then
        self.MMMaskName = name

        local mm = self.MMFrm
        mm:SetMaskTexture (name)

--        Nx.prt ("MMmask %s", name)
    end

    local name = self.MMZoomType == 0 and "Interface\\Minimap\\MinimapArrow" or "Interface\\Addons\\Carbonite\\Gfx\\Map\\32Transparent"
    if self.MMArrowName ~= name then
        self.MMArrowName = name
        if (name ~= "") then
            self.MMFrm:SetPlayerTexture (name)
        end
    end
end

--[[
function Nx.Map.OnGathererTimer()

    Nx.prt ("Gatherer update")

    local mn = Gatherer["MiniNotes"]
    if mn then
        local update = mn["ForceUpdate"]
        if update then
            update()
        end
    else
        Nx.prt ("no mn")
    end
end
--]]

function Nx.Map:MinimapDetachFrms()

    local mm = self.MMFrm
    local mmc = _G["MinimapCluster"]
    local winf = self.Win.Frm
    local dock = Nx.Map.Dock

    if dock.InitPending then
        return
    end

    self.MMChkDelay = self.MMChkDelay - 1

    if self.MMChkDelay < 1 then

        self.MMChkDelay = 40        -- Reset

        -- Find and own any minimap child windows

        local mmNames = self.AddonMinimapNames
        local ch = { mm:GetChildren() }

        for n = 1, #ch do

            local c = ch[n]
            if c ~= mmc then

--                if not c:IsVisible() then
--                    Nx.prt ("MM Frm v0 %s", c:GetName() or "nil")
--                end

                if c:IsShown() and not self.MMOwnedFrms[c] then

                    if c:IsObjectType ("Model") then
--                        Nx.prt ("MM Model %s", c:GetName() or "nil")

                        if self.MMOwn then

                            c:SetParent (winf)
                            self.MMOwnedFrms[c] = 0
                            tinsert (self.MMModels, c)
                        end

                    elseif c:IsObjectType ("Frame") then

                        local name = gsub (c:GetName() or "", "%d", "")

                        if mmNames[name] then

                            if self.MMOwn then
                                self.MMOwnedFrms[c] = 0
                                self.MMAddonFrms[c] = 1
                            end

                        elseif dock.MMFrms then

                            local excludeFrame = false
                            local excludeFrames = {'HandyNotesPin', 'QuestieFrame'}

                            for k, exF in ipairs (excludeFrames) do
                                if c:GetName() and Nx.strpos(c:GetName(), exF) then excludeFrame = true end
                            end

                            if not excludeFrame then
                                self.MMOwnedFrms[c] = 0
                                tinsert (dock.MMFrms, c)

    --                            Nx.prt ("MM Frm %s #%s %s", c:GetName() or "nil", c:GetNumChildren(), Nx.strpos(c:GetName(), 'QuestieFrame'))
    --                            Nx.prtFrameChildren (c:GetName() or "nil", c)

                                if c:GetNumChildren() > 0 then

                                    local ch = { c:GetChildren() }
                                    for k, c in ipairs (ch) do

    --                                    if not c:IsShown() then
    --                                        Nx.prt ("MM Frm v0 %s", c:GetName() or "nil")
    --                                    end

                                        if c:IsShown() then
                                            if c:IsObjectType ("Frame") then
                                                local pt, relTo = c:GetPoint()
                                                if relTo == mm then
                                                    tinsert (dock.MMFrms, c)
    --                                                Nx.prt ("MMCC %s", c:GetName())
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --
    if HandyNotes then
        HandyNotes:UpdateMinimap()
    end

    dock:MinimapDetachFrms()
end

function Nx.Map:MinimapUpdateDetachedFrms (lvl)

--    self:MinimapDetachFrms()

    local sc = self.MMFScale
    local arrowsc = sc
    local msc = min (1 / sc, 1) * .5

    if Nx.InBG then
        arrowsc = .001
    end

    local mmplyr = Nx.Map.MinimapPlyrModel        -- Old

    for n, f in ipairs (self.MMModels) do

        if f:IsShown() then

            f:SetFrameLevel (lvl)

            local name = f:GetModel()

            if name == "interface\\minimap\\ping\\minimapping.m2" then
                f:SetScale (sc)
                f:SetModelScale (msc)
                f:SetAlpha (1)

            elseif f == mmplyr then
                if self.MMZoomType == 0 then
                    f:SetScale (max (.4, min (.9, sc)) * Nx.db.profile.Map.PlyrArrowSize / 28)
--                    f:SetModelScale (min (.2, sc))
                    f:SetModelScale (1)
                else
                    f:SetScale (.1)
                    f:SetModelScale (1)
                end
            else
                f:SetScale (arrowsc)
                f:SetModelScale (msc)
            end
--[[
            if IsAltKeyDown() then
                Nx.prt ("Model %s (%s %s)", f:GetModel() or "", f:GetScale(), f:GetModelScale())
            end
--]]
        end
    end

    for f, v in pairs (self.MMAddonFrms) do
        f:SetFrameLevel (lvl)
--        f:SetScale (sc)
--        f:SetModelScale (msc)
    end
end

--------

function Nx.Map:Menu_OnGoto (item)
    self:SetTargetAtClick()
end

function Nx.Map:Menu_OnClearGoto (item)
    self:ClearTargets()
    self.Guide:ClearAll()
end

function Nx.Map:Menu_OnMonitorZone (item)
    Nx.Com:MonitorZone (self.MenuMapId, item:GetChecked())
end

function Nx.Map:Menu_OnScaleSave()
    self.CurOpts.NXScaleSave = self.Scale
end

function Nx.Map:Menu_OnScaleRestore()
    local s = Nx.Map:GetMap(1).CurOpts.NXScaleSave
    if s then
        Nx.Map:GetMap(1).Scale = s
        Nx.Map:GetMap(1).RealScale = s
        Nx.Map:GetMap(1).StepTime = 10
    else
--        Nx.prt ("Scale not set")
    end
end

function Nx:NXMapKeyScaleRestore()
    local map = Nx.Map:GetMap (1)
    map:Menu_OnScaleRestore()
end

function Nx.Map:Menu_OnPlyrFollow (item)
    self.CurOpts.NXPlyrFollow = item:GetChecked()
end

function Nx.Map:Menu_InstanceMap (item)
    self.CurOpts.NXInstanceMaps = item:GetChecked()
end

function Nx.Map:Menu_OnShowWorld (item)
    self.CurOpts.NXWorldShow = item:GetChecked()
end

function Nx.Map:Menu_OnShowPlayerZone()
    self:GotoCurrentZone()
end

function Nx.Map:Menu_OnShowKills (item)
    self.KillShow = item:GetChecked()
end

function Nx.Map:Menu_OnDetailAlpha (item)
    self.LOpts.NXDetailAlpha = item:GetSlider()
end

function Nx.Map:Menu_OnBackgndAlphaFade (item)
    self.BackgndAlphaFade = item:GetSlider()
end

function Nx.Map:Menu_OnArchAlpha (item)
    self.ArchAlpha = item:GetSlider()
end

function Nx.Map:Menu_OnQuestAlpha (item)
    self.QuestAlpha = item:GetSlider()
end

function Nx.Map:Menu_OnBackgndAlphaFull (item)
    self.BackgndAlphaFull = item:GetSlider()
end

function Nx.Map:Menu_OnDotZoneScale (item)
    self.DotZoneScale = item:GetSlider()
end

function Nx.Map:Menu_OnDotPalScale (item)
    self.DotPalScale = item:GetSlider()
end

function Nx.Map:Menu_OnDotPartyScale (item)
    self.DotPartyScale = item:GetSlider()
end

function Nx.Map:Menu_OnDotRaidScale (item)
    self.DotRaidScale = item:GetSlider()
end

function Nx.Map:Menu_OnIconScale (item)
    self.IconScale = item:GetSlider()
end

function Nx.Map:Menu_OnIconNavScale (item)
    self.IconNavScale = item:GetSlider()
end

function Nx.Map:Menu_OnOptions (item)
    Nx.Opts:Open ("Map")
end

-- Debug sub menu

function Nx.Map:Menu_OnMapDebugFullCoords (item)
    self.DebugFullCoords = item:GetChecked()
end

function Nx.Map:Menu_OnQuestDebug (item)
    Nx.Quest.Debug = item:GetChecked()
end

-- Plyr icon menu

function Nx.Map:Menu_OnWhisper()

    for _, name in pairs (Nx.Map.PlyrNames) do

        local box = ChatEdit_ChooseBoxForSend()
        ChatEdit_ActivateChat (box)
        box:SetText ("/w " .. name .. " " .. box:GetText())
--[[
        local frm = DEFAULT_CHAT_FRAME
        local eb = frm["editBox"]
        if not eb:IsVisible() then
            ChatFrame_OpenChat ("/w " .. name, frm)
        else
            eb:SetText ("/w " .. name .. " " .. eb:GetText())
        end
--]]
        break
    end
end

-- Plyr icon menu

function Nx.Map:Menu_OnInvite()

    for _, name in pairs (Nx.Map.PlyrNames) do
        InviteUnit (name)
        break
    end
end

function Nx.Map:Menu_OnGetQuests (item)
    if Nx.Quest then
    for _, name in pairs (Nx.Map.PlyrNames) do
        Nx.Quest:GetFromPlyr (name)
        break
    end
    end
end

function Nx.Map:Menu_OnTrackPlyr (item)

    for _, name in pairs (Nx.Map.PlyrNames) do
        self.TrackPlyrs[name] = true
    end
end

function Nx.Map:Menu_OnRemoveTracking (item)

    for _, name in pairs (Nx.Map.PlyrNames) do
        self.TrackPlyrs[name] = nil
    end
end

function Nx.Map:Menu_OnReportPlyrAFK (item)
    local n = 0
    for k, v in pairs (Nx.Map.AFKers) do
        ReportPlayerIsPVPAFK (v)
        n = n + 1
    end
    Nx.prt ("%d " .. L["reported"], n)
end

--[[
function Nx.Map:Menu_OnReportAllAFK (item)

    local members = MAX_PARTY_MEMBERS
    local unitName = "party"

    if IsInRaid() > 0 then
        members = MAX_RAID_MEMBERS
        unitName = "raid"
    end

    local cnt = 0

    for i = 1, members do

        local unit = unitName..i

        if not UnitIsUnit (unit, "player") then
            ReportPlayerIsPVPAFK (unit)
            cnt = cnt + 1
        end
    end

    Nx.prt ("%d reported", cnt)
end
--]]

function Nx.Map:Menu_OnGrowConflictBars (item)
    self.BGGrowBars = item:GetChecked()
end

function Nx.Map:GMenuOpen (icon, typ)

    self.GIconMenuITogInst:Show (false)
    self.GIconMenuIFindNote:Show (false)
    self.GIconMenuIClearKill:Show (false)

    if typ == 3000 then
        if icon.UData then
            self.GIconMenuITogInst:Show()
        end

        if icon.FavData1 then
            self.GIconMenuIFindNote:Show()
        end

        if icon.iconType == "Kill" or icon.iconType == "Death" then
            self.GIconMenuIClearKill:Show()
        end
    end
    self.GIconMenu:Open()
end

---
-- Remove the underlying kill/death event record for the right-clicked icon.
-- The render loop in Carbonite.lua (UEvents:UpdateMap) tags each Kill/Death
-- icon with its source index in Nx.CurCharacter.E; we use that to splice out
-- the record. The next call to UEvents:UpdateMap (driven by the per-tick map
-- update) will re-init the icon types and the dropped record won't reappear.
function Nx.Map:GMenu_OnClearKill()
    local icon = self.ClickIcon
    if not icon or not icon.EventIndex then return end
    local events = Nx.CurCharacter and Nx.CurCharacter.E
    if not events then return end
    table.remove(events, icon.EventIndex)
    if Nx.UEvents and Nx.UEvents.UpdateMap then
        Nx.UEvents:UpdateMap()
    end
end

-------------------------------------------------------------------------------
-- ICON MENU HANDLERS
-------------------------------------------------------------------------------

---
-- Toggle instance map overlay for clicked icon
--
function Nx.Map:GMenu_OnTogInst()
    local icon = self.ClickIcon
    local mapId = icon.UData

    if mapId then
        if self.InstMapId == mapId then
            -- Already showing this instance, hide it
            self:SetInstanceMap()
        else
            -- Check for Atlas addon if needed
            local atlas = _G["AtlasMaps"]

            if not (Nx.Map.InstanceInfo[mapId] or atlas) then
                UIErrorsFrame:AddMessage("This instance map requires the Atlas addon be installed", 1, .1, .1, 1)
                return
            end

            self:SetInstanceMap(mapId)
        end
    end
end

---
-- Find and show note for clicked icon
--
function Nx.Map:GMenu_OnFindNote()
    Nx.Notes:ShowIconNote(self.ClickIcon)
end

---
-- Set goto target at clicked icon location
--
function Nx.Map:GMenu_OnGoto()
    -- Clear quest auto-target if present
    if Nx.Quest then
        if Nx.Quest.Watch then
            Nx.Quest.Watch:ClearAutoTarget()
        end
    end

    if self.ClickType == 3001 then
        -- Punk target
        if Nx.Punks then
            Nx.Punks:GotoPunk(self.ClickIcon)
        end
    else
        -- Standard icon target
        local icon = self.ClickIcon
        local x = icon.X
        local y = icon.Y
        local name = icon.Tip and Nx.Split("\n", icon.Tip) or ""

        self:SetTarget("Goto", x, y, x, y, false, 0, name, IsShiftKeyDown())
    end
end

---
-- Paste icon info as link to chat
--
function Nx.Map:GMenu_OnPasteLink()
    local name

    if self.ClickType == 3001 then
        if Nx.Punks then
            name = Nx.Punks:GetPunkPasteInfo(self.ClickIcon)
        end
    else
        local icon = self.ClickIcon
        name = gsub(icon.Tip, "\n", ", ")
    end

    -- Strip color codes
    name = gsub(name, "|cff......", "")
    name = gsub(name, "|r", "")

    -- Paste to active edit box
    local frm = DEFAULT_CHAT_FRAME
    local eb = frm["editBox"]
    if eb:IsVisible() then
        eb:SetText(eb:GetText() .. name)
    else
        Nx.prt(L["No edit box open!"])
    end
end

-------------------------------------------------------------------------------
-- BATTLEGROUND COMMUNICATION
-- Quick message system for BG objectives
-------------------------------------------------------------------------------

---
-- Send incoming message
--
function Nx.Map:BGMenu_OnIncoming(item)
    self:BGMenu_Send(NXlBGMsgIncoming)
end

---
-- Send clear message
--
function Nx.Map:BGMenu_OnClear(item)
    self:BGMenu_Send("Clear")
end

---
-- Send help message
--
function Nx.Map:BGMenu_OnHelp(item)
    self:BGMenu_Send("Help")
end

---
-- Send attack message
--
function Nx.Map:BGMenu_OnAttack(item)
    self:BGMenu_Send("Attack")
end

---
-- Send guard message
--
function Nx.Map:BGMenu_OnGuard(item)
    self:BGMenu_Send("Guard")
end

---
-- Send losing message
--
function Nx.Map:BGMenu_OnLosing(item)
    self:BGMenu_Send("Losing")
end

---
-- Report status of BG objective
-- @param item  Menu item (unused)
--
function Nx.Map:BGMenu_OnStatus(item)
    local id, x, y, str = Nx.Split("~", self.BGMsg)
    if id == "1" then
        self:BGMenu_Send()
    else
        Nx.prt("No Status")
    end
end

---
-- Send BG communication message with nearby player count
-- @param msg  Optional message prefix
--
function Nx.Map:BGMenu_Send(msg)
    local id, tx, ty, str = Nx.Split("~", self.BGMsg)
    tx, ty = self:GetWorldPos(Nx.Map.UpdateMapID, tonumber(tx), tonumber(ty))

    -- Determine group type
    local members = MAX_PARTY_MEMBERS
    local unitName = "party"

    if IsInRaid() then
        members = MAX_RAID_MEMBERS
        unitName = "raid"
    end

    -- Count nearby friendly players
    local cnt = 0
    local maxDist = (100 / 4.575) ^ 2   -- 100 yards converted to world units squared

    for i = 1, members do
        local unit = unitName .. i
        local pX, pY = Nx.Map.GetPlayerMapPosition(unit)

        if (pX > 0 or pY > 0) and not UnitIsDeadOrGhost(unit) then
            local x, y = self:GetWorldPos(Nx.Map.UpdateMapID, pX * 100, pY * 100)
            local dist = (tx - x) ^ 2 + (ty - y) ^ 2

            if dist <= maxDist then
                cnt = cnt + 1
            end
        end
    end

    -- Build player count string
    local dstr = ", No "
    if cnt > 0 then
        dstr = format(", %d ", cnt)
    end

    dstr = dstr .. Nx.Map.PlFactionShort .. " in area"

    -- Send to instance chat
    if msg then
        SendChatMessage(msg .. " - " .. str .. dstr, "INSTANCE_CHAT")
    else
        SendChatMessage(str .. dstr, "INSTANCE_CHAT")
    end
end

---
-- Timer callback for sending incoming count
--
function Nx.Map:BGIncSendTimer()
    local str = format(L["Incoming"] .. " %s", self.BGIncNum)
    self:BGMenu_Send(str)

    self.BGIncNum = 0
end

-------------------------------------------------------------------------------
-- WORLD MAP INTEGRATION AND HOOKS
-------------------------------------------------------------------------------

-- Flag to track if WorldMapFrame show handling is enabled
Nx.Map.WMFOnShow = true

-- Hook WorldMapFrame OnShow to intercept and potentially redirect to Carbonite map
WorldMapFrame:HookScript("OnShow", function()
    -- Fix for ElvUI constant WorldMapFrame Show and Hide
    if ElvUI then
        ElvUI[1].global.general.fadeMapWhenMoving = false
    end

    if Nx.Map.WMFOnShow then
        -- Determine if we should use original behavior
        local orgin = IsAltKeyDown()
        if not Nx.db.profile.Map.MaxOverride then
            orgin = not orgin
        end

        if Nx.Map.BlizzToggling or orgin then
            -- Use Blizzard world map
            if WorldMapFrame:IsShown() then
                Nx.Map:RestoreBlizzBountyMap()
                local map = Nx.Map:GetMap(1)
                map:DetachWorldMap()
            end
        else
            -- DugisGuide compatibility fix
            if DugisGuideViewer then
                local isGuideMode, isEssentialMode, isOffMode = DugisGuideViewer.GetPluginMode()
                if not isOffMode and GPSArrowIcon and not GPSArrowIcon:IsShown() then
                    HideUIPanel(WorldMapFrame)
                    return
                end
            end

            -- Redirect to Carbonite map
            HideUIPanel(WorldMapFrame)
            Nx.Map:ToggleSize()
        end
    end
end)

---
-- Global function to toggle world map
-- Respects settings for whether to use Carbonite or Blizzard map
--
function ToggleWorldMap()
    if Nx.Map.BlizzToggling or WorldMapFrame:IsShown() or IsAltKeyDown() or not Nx.db.profile.Map.MaxOverride then
        if not Nx.db.profile.Map.MaxOverride and IsAltKeyDown() then
            Nx.Map:ToggleSize()
        else
            Nx.Map:BlizzToggleWorldMap()
        end
    else
        Nx.Map:ToggleSize()
    end
end

-------------------------------------------------------------------------------
-- BOUNTY MAP INTEGRATION (Legacy/Disabled)
-------------------------------------------------------------------------------

---
-- Hijack Blizzard bounty board to Carbonite map
--
function Nx.Map:HijackBlizzBountyMap()
    local map = self:GetMap(1)

    WorldMap_HijackTooltip(map.Frm)

    local bountyBoard = NXBountyBoard
    if bountyBoard == nil then
        bountyBoard = CreateFrame('BUTTON', 'NXBountyBoard', map.Frm, 'WorldMapBountyBoardTemplate')
    end
    bountyBoard:RegisterEvent('QUEST_LOG_UPDATE')
    bountyBoard.FindBestMapForSelectedBounty = function() end
    bountyBoard:SetParent(map.Frm)
    bountyBoard:SetFrameLevel(140)
    bountyBoard:SetMapAreaID(619)
    local bountyBoardLocation = bountyBoard:GetDisplayLocation()
    if bountyBoardLocation then
        WorldMapFrame_SetOverlayLocation(bountyBoard, bountyBoardLocation)
    end
    bountyBoard:Show()
end

---
-- Restore Blizzard bounty map
-- @param tooltip  Whether to restore tooltip (unused, feature disabled)
--
function Nx.Map:RestoreBlizzBountyMap(tooltip)
    -- Feature currently disabled
end

-------------------------------------------------------------------------------
-- BLIZZARD MAP TOGGLE
-------------------------------------------------------------------------------

---
-- Toggle Blizzard's world map visibility
--
function Nx.Map:BlizzToggleWorldMap()
    if WorldMapFrame:IsShown() then
        if not InCombatLockdown() then
            HideUIPanel(WorldMapFrame)
        else
            WorldMapFrame:Hide()
        end
    else
        Nx.Map:RestoreBlizzBountyMap()

        local map = self:GetMap(1)
        map:DetachWorldMap()
        if not InCombatLockdown() then
            WorldMapFrame:HandleUserActionToggleSelf()
        end
    end
end

-------------------------------------------------------------------------------
-- KEY BINDING FUNCTIONS
-- Global functions for key binding actions
-------------------------------------------------------------------------------

---
-- Toggle to original Blizzard map (key binding)
--
function Nx:NXMapKeyTogOriginal()
    Nx.Map.BlizzToggling = true
    ToggleWorldMap()
    Nx.Map.BlizzToggling = nil
end

---
-- Toggle between normal and maximized Carbonite map (key binding)
--
function Nx:NXMapKeyTogNormalMax()
    Nx.Map:ToggleSize()
end

---
-- Toggle between hidden and maximized Carbonite map (key binding)
--
function Nx:NXMapKeyTogNoneMax()
    Nx.Map:ToggleSize(1)
end

---
-- Toggle between hidden and normal Carbonite map (key binding)
--
function Nx:NXMapKeyTogNoneNormal()
    Nx.Map:ToggleSize(0)
end

-------------------------------------------------------------------------------
-- MAP SIZE TOGGLING
-------------------------------------------------------------------------------

---
-- Toggle map window size/visibility
-- @param szmode  Size mode: nil = toggle, 0 = normal, 1 = max
--
function Nx.Map:ToggleSize(szmode)
    -- Guard against early calls before initialization
    if not self.Maps then
        return
    end

    Nx.Map:RestoreBlizzBountyMap(false)

    local map = self:GetMap(1)
    local win = map.Win

    if not win:IsShown() and not win:IsSizeMax() then
        -- Window is hidden, show it
        win:Show()

        if szmode == 0 then
            -- Show at normal size
            map:RestoreSize()
            Nx.Map:RestoreBlizzBountyMap()
        elseif szmode == 1 then
            -- Show maximized
            map:MaxSize()
        elseif Nx.db.profile.Map.MaxCenter then
            -- Default to maximized if configured
            map:MaxSize()
        end

        if Nx.db.char.Map.ShowWorldQuest then
            -- World quest integration (disabled)
        end
    elseif szmode then
        -- Hide window
        win:Show(false)
    elseif not win:IsSizeMax() then
        -- Maximize from normal size
        map:MaxSize()

        if Nx.db.char.Map.ShowWorldQuest then
            -- World quest integration (disabled)
        end
    else
        -- Restore from maximized
        map:RestoreSize()
    end

    -- Clear tooltip if owned by this window
    if Nx.TooltipOwner == win.Frm then
        Nx.TooltipText:Hide()
        Nx.TooltipOwner = nil
    end
end

---
-- Restore map to normal (non-maximized) size
--
function Nx.Map:RestoreSize()
    self:MouseEnable(false)

    if self.Win:IsSizeMax() then
        Nx.Map:RestoreBlizzBountyMap(false)
        self.Win:ToggleSize()

        self:RestoreView("")
        self:DetachWorldMap()

        -- Optionally hide window after restore
        if Nx.db.profile.Map.MaxRestoreHide then
            self.Win:Show(false)
        end
    end

    -- Remove from escape-closable frames list
    local wname = self:GetWinName()
    for n, name in pairs(UISpecialFrames) do
        if name == wname then
            tremove(UISpecialFrames, n)
            break
        end
    end
end

---
-- Maximize map to full screen
--
function Nx.Map:MaxSize()
    if not self.Win:IsSizeMax() then
        -- Debug output if enabled
        if Nx.db.profile.Debug.DBMapMax then
            Nx.prt("MapMax %s", debugstack(2, 4, 0))
        end

        self.Win:ToggleSize()

        self:SaveView ("")

        self:MouseEnable (true)
        if self:IsInstanceMap(Nx.Map.UpdateMapID) then
            self.Scale = 256.0
        end
        if Nx.db.profile.Map.MaxCenter then
            self:CenterMap()
        end
        self.StepTime = min (self.StepTime, 1)
    end
end

--------
-- Key binding toggle owned minimap to full size
-- global func

function Nx:NXMapKeyTogMiniFull()

    if Nx.Free then
        return
    end

    local map = Nx.Map:GetMap (1)
    map.LOpts.NXMMFull = not map.LOpts.NXMMFull
    map.MMZoomChanged = true
    map.MMMenuIFull:SetChecked (map.LOpts.NXMMFull)
    Nx.Menu:CheckUpdate (map.MMMenuIFull)
end

--------
-- Key binding toggle herbs
-- global func

function Nx:NXMapKeyTogHerb()
    local map = Nx.Map:GetMap (1)
    Nx.db.char.Map.ShowGatherH = not Nx.db.char.Map.ShowGatherH
    map.MenuIShowHerb:SetChecked (Nx.db.char.Map, "ShowGatherH")
    map.Guide:UpdateGatherFolders()
end

--------
-- Key binding toggle mining
-- global func

function Nx:NXMapKeyTogMine()
    local map = Nx.Map:GetMap (1)
    Nx.db.char.Map.ShowGatherM = not Nx.db.char.Map.ShowGatherM
    map.MenuIShowMine:SetChecked (Nx.db.char.Map, "ShowGatherM")
    map.Guide:UpdateGatherFolders()
end

--------
-- Key binding toggle timber
-- global func

function Nx:NXMapKeyTogTimber()
    if not Nx.isRetail then return end  -- Timber is WoD+ only
    local map = Nx.Map:GetMap (1)
    Nx.db.char.Map.ShowGatherL = not Nx.db.char.Map.ShowGatherL
    if map.MenuIShowTimber then
        map.MenuIShowTimber:SetChecked (Nx.db.char.Map, "ShowGatherL")
    end
    map.Guide:UpdateGatherFolders()
end

--------
-- Enable or disable map mouse input

function Nx.Map:MouseEnable (max)

--    Nx.prt ("MouseEnable %s %s", max and "max" or "min", alt and 1 or 0)

    local on = true

    if max then
        if Nx.db.profile.Map.MaxMouseIgnore then
            on = IsAltKeyDown() and true or false        -- IsAltKeyDown returns nil or 1
        end
    else
        if Nx.db.profile.Map.MouseIgnore then
            on = IsAltKeyDown() and true or false        -- IsAltKeyDown returns nil or 1
        end
    end

    if self.MouseEnabled ~= on then

--        Nx.prt ("MouseEnable up")

        self.MouseEnabled = on

        self.Win:EnableMouse (on)

        if on then
            self.ButAutoScaleOn.Frm:Show()
            self:UpdateToolBar()        -- Will show or hide
        else
            self.ButAutoScaleOn.Frm:Hide()
            self.ToolBar.Frm:Hide()
        end

        self.Frm:EnableMouse (on)
        self.Frm:EnableMouseWheel (on)

        self.MMFrm:EnableMouse (on)
        self.MMFrm:EnableMouseWheel (on)

        for n, f in ipairs (self.IconFrms) do
            f:EnableMouse (on)
        end

        for n, f in ipairs (self.IconStaticFrms) do
            f:EnableMouse (on)
        end
    end

    --[[if not Nx.db.profile.Map.MaxMouseIgnore and ((Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps) then
        self.Win:EnableMouse (true)
        self.Frm:EnableMouse (true)
        self.ButAutoScaleOn.Frm:Show()
        self:UpdateToolBar()
    end]]--
end

--------
-- Handle events
-- self = map table

function Nx.Map:OnEvent (event, ...)
--    Nx.prtVar ("Map Event", self)
--    Nx.prt ("Map Event %s", event)
    local map = Nx.Map:GetMap (1)
    if event == "WORLD_MAP_UPDATE" then
        if not map.Win then
            return
        end
        if map.Win.Frm:IsVisible() then
            map:UpdateAll()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        local win = map.Win
        if (Nx.db.profile.Map.HideCombat and win:IsSizeMax()) then
            map.Win.Frm:Hide()
        end
        if Nx.BlobsAvailable then
            map.Arch:Hide()
            map.QuestWin:Hide()
            map.Arch:SetParent(nil)
            map.QuestWin:SetParent(nil)
            map.Arch:ClearAllPoints()
            map.QuestWin:ClearAllPoints()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if Nx.BlobsAvailable then
            map.Arch:SetParent(map.TextScFrm:GetScrollChild())
            map.QuestWin:SetParent(map.TextScFrm:GetScrollChild())
            -- Don't show blobs on instance maps as they cause rendering issues
            local isInstanceMap = Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)
            if not isInstanceMap then
                map.Arch:Show()
            end
            map.QuestWin:Hide()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- DETECT EXIT INSTANCE
        if Nx.Map.NInstMapId then
            Nx.Map:Menu_OnScaleRestore()
            Nx.Map.NInstMapId = nil
            Nx.Map:HideNewPlrFrame()
        end
    elseif event == "ZONE_CHANGED" then
        Nx.Map.Indoors = false
        Nx.Map.NInstMapId = nil
        Nx.Map:HideNewPlrFrame()
        Nx.Map:SetToCurrentZone()
    elseif event == "ZONE_CHANGED_INDOORS" then
        Nx.Map.Indoors = true
        Nx.Map.NInstMapId = nil
        Nx.Map:HideNewPlrFrame()
        Nx.Map:SetToCurrentZone()
    end
end

function Nx.Map:OnMouseDown (button)

    local map = self.NxMap    --V4 this
    local this = map.Frm

    local x, y = GetCursorPosition()
    x = x / this:GetEffectiveScale()
    y = y / this:GetEffectiveScale()

    map:CalcClick()

    ResetCursor()

--    Nx.prt ("Map MouseDown %s %s %s %s %s", button, x, y, rgt, bot)

    if button == "LeftButton" then

--[[
        if map["DebugHotspots"] then

            map.HotspotDebugCurT = nil

            if map:IsDoubleClick() then
                map.DebugMapId = map.MapId
            else
                map.LClickTime = GetTime()
                map.Scrolling = true
                map.ScrollingX = x
                map.ScrollingY = y
                map.ScrollingFrm = map.ClickFrm
            end
            return
        end
--]]

        -- Edit mode: Ctrl+Alt+LeftClick starts rectangle drawing
        if map:EditModeMouseDown(button) then
            return
        end

        if IsControlKeyDown() and map:CallFunc ("ButLCtrl") then    -- If func does nothing continue

        elseif IsAltKeyDown() and map:CallFunc ("ButLAlt") then    -- If func does nothing continue

        elseif IsShiftKeyDown() then
            map:Ping()

        else

            if map:IsDoubleClick() then

                map:CenterMap()
                map.DebugMapId = map.MapId

            else
                if (Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)) and map.CurOpts.NXInstanceMaps then
                    return
                end
                map.LClickTime = GetTime()
                map.Scrolling = true
                map.ScrollingX = x
                map.ScrollingY = y
                map.ScrollingFrm = map.ClickFrm
            end
        end

    elseif button == "MiddleButton" then

        if IsControlKeyDown() then
            map:CallFunc ("ButMCtrl")
        elseif IsAltKeyDown() then
            map:CallFunc ("ButMAlt")
        else
            map:CallFunc ("ButM")
        end

    elseif button == "RightButton" then

        if IsControlKeyDown() and map:CallFunc ("ButRCtrl") then

        elseif IsAltKeyDown() and map:CallFunc("ButRAlt") then
            -- Alt+Right click action
        else
            map:CallFunc("ButR")
        end

    elseif button == "Button4" then
        -- Mouse button 4 handling
        if IsControlKeyDown() then
            map:CallFunc("But4Ctrl")
        elseif IsAltKeyDown() then
            map:CallFunc("But4Alt")
        else
            map:CallFunc("But4")
        end
    end
end

-------------------------------------------------------------------------------
-- CLICK AND POSITION CALCULATION
-------------------------------------------------------------------------------

---
-- Calculate click position relative to map frame
--
function Nx.Map:CalcClick()
    local f = self.Frm

    local x, y = GetCursorPosition()
    x = x / f:GetEffectiveScale()
    y = y / f:GetEffectiveScale()

    self.ClickFrmX = x - f:GetLeft()
    self.ClickFrmY = f:GetTop() - y
end

---
-- Check if this is a double click
-- @return  True if double click detected
--
function Nx.Map:IsDoubleClick()
    if GetTime() - self.LClickTime < .5 then
        self.LClickTime = 0
        return true
    end
end

---
-- Open the main context menu with current state
--
function Nx.Map:OpenMenu()
    local opts = self:GetOptionsT(self.MapIndex)

    -- Update menu item states
    self.MenuIInstanceMaps:SetChecked(self.CurOpts.NXInstanceMaps)
    self.MenuIPlyrFollow:SetChecked(self.CurOpts.NXPlyrFollow)
    self.MenuIShowWorld:SetChecked(self.CurOpts.NXWorldShow)
    self.MenuIMonitorZone:SetChecked(Nx.Com:IsZoneMonitored(self.MapId))

    self.MenuMapId = self.MapId
    self.Menu:Open()
end

---
-- Handle mouse button release
-- @param button  Button that was released
--
function Nx.Map:OnMouseUp(button)
    local this = self
    local map = this.NxMap

    -- Edit mode: finalize rectangle on mouse up
    if map:EditModeMouseUp(button) then
        return
    end

    map.Scrolling = false
end

-------------------------------------------------------------------------------
-- ZOOM FUNCTIONS
-------------------------------------------------------------------------------

---
-- Zoom in one step (button handler)
--
function Nx.Map:ClickZoomIn()
    self:MouseWheel(1)
end

---
-- Zoom out one step (button handler)
--
function Nx.Map:ClickZoomOut()
    self:MouseWheel(-1)
end

---
-- Mouse wheel event handler (frame callback)
-- @param value  Wheel direction (+1 = up, -1 = down)
--
function Nx.Map:OnMouseWheel(value)
    self.NxMap:MouseWheel(value)
end

---
-- Process mouse wheel zoom
-- Zooms centered on cursor position
-- @param value  Wheel direction (+1 = up, -1 = down)
--
function Nx.Map:MouseWheel(value)
    local map = self
    local this = map.Frm

    -- Disable zoom in instance/BG maps when using instance overlay
    if (Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)) and map.CurOpts.NXInstanceMaps then
        return
    end

    -- Handle minimap zoom when hovering over docked minimap
    if map.MMZoomType == 0 and Nx.Util_IsMouseOver(map.MMFrm) then
        map.MMZoomChanged = true

        local i = Nx.db.profile.MiniMap.DockZoom

        if value < 0 then
            i = max(i - 1, 0)
        else
            i = min(i + 1, 5)
        end

        Nx.db.profile.MiniMap.DockZoom = i
        return
    end

    -- Get cursor position in frame coordinates
    local x, y = GetCursorPosition()
    x = x / this:GetEffectiveScale()
    y = y / this:GetEffectiveScale()

    local left = this:GetLeft()
    local rgt = this:GetRight()
    local top = this:GetTop()
    local bot = this:GetBottom()

    -- Calculate world position under cursor before zoom
    local ox = map.MapPosX + (x - left - map.PadX - map.MapW / 2) / map.Scale
    local oy = map.MapPosY + (top - y - map.TitleH - map.MapH / 2) / map.Scale

    -- Apply zoom
    map.Scale = map:ScrollScale(value)
    map.StepTime = 10
    map.MapScale = map.Scale / 10.02

    -- Calculate world position under cursor after zoom
    local nx = map.MapPosX + (x - left - map.PadX - map.MapW / 2) / map.Scale
    local ny = map.MapPosY + (top - y - map.TitleH - map.MapH / 2) / map.Scale

    -- Adjust map position to keep cursor over same world point
    map.MapPosX = map.MapPosX + ox - nx
    map.MapPosY = map.MapPosY + oy - ny
end

---
-- Calculate new scale from scroll input
-- @param value  Scroll direction
-- @return       New scale value (minimum 0.015)
--
function Nx.Map:ScrollScale(value)
    local s = self.Scale

    -- Asymmetric zoom for smoother feel
    if value < 0 then
        value = value * .76923
    end

    return math.max(s + value * s * .3, .015)
end

---
-- Animate scale change over multiple frames
-- @param steps  Number of zoom steps (positive = in, negative = out)
--
function Nx.Map:SetScaleOverTime(steps)
    local step = steps >= 0 and 1 or -1

    for n = 1, abs(steps) do
        self.Scale = self:ScrollScale(step)
    end

    self.StepTime = 10
end

-------------------------------------------------------------------------------
-- MAIN UPDATE LOOP
-- This is the heart of the map system, called every frame
-------------------------------------------------------------------------------

-- Time accumulator for update throttling
local ttl = 0

-- Table pools to avoid garbage collection (reused every frame)
local POI_Pool = {
    pPOIs = {},
    aPOIs = {},
    zPOIs = {},
}

-- POI cache to reduce API calls during zoom/scroll (refreshes every 0.5 seconds or on map change)
local POI_Cache = {
    mapID = nil,
    time = 0,
    data = nil,
    refreshInterval = 0.5,  -- Refresh every 0.5 seconds
}

-- Per-frame cached values (set at start of Update)
local FrameCache = {
    time = 0,
    isInstance = false,
    isBG = false,
    mapId = 0,
    dungeonLevel = 0,
}

---
-- Helper function to check if icon is visible at current dungeon level
-- @param iconLevel     Level the icon is on
-- @param dungeonLevel  Current dungeon level
-- @return              True if icon should be visible
--
local function IsVisibleAtLevel(iconLevel, dungeonLevel)
    return (not iconLevel and dungeonLevel == 0) or (iconLevel and iconLevel == dungeonLevel)
end

---
-- Main frame update handler
-- Called every frame, but throttled by mapUpdate setting
-- @param this     The map frame
-- @param elapsed  Time since last frame
--
function Nx.Map.OnUpdate(this, elapsed)
    -- Throttle update rate
    ttl = ttl + elapsed
    if ttl < (Nx.db.profile.Map.mapUpdate or .05) then
        return
    end
    ttl = 0

    -- Fix for ReputationFrame event spam
    if _G['ReputationFrame'] then
        if not _G['ReputationFrame'].CarbFix then
            _G['ReputationFrame'].CarbFix = true
            _G['ReputationFrame']:UnregisterEvent('QUEST_LOG_UPDATE')
            _G['ReputationFrame']:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
            _G['ReputationFrame']:HookScript('OnShow', function(self, event, ...)
                _G['ReputationFrame']:UnregisterEvent('QUEST_LOG_UPDATE')
                _G['ReputationFrame']:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
            end)
            _G['ReputationFrame']:HookScript('OnEvent', function(self, event, ...)
                if (event == "UPDATE_FACTION" or event == "LFG_BONUS_FACTION_ID_UPDATED" or event == "UNIT_QUEST_LOG_CHANGED") and ReputationFrame_Update then
                    ReputationFrame_Update()
                end
            end)
        end
    end

    local Nx = Nx

    -- Cache time once per frame (used throughout update)
    local frameTime = GetTime()
    FrameCache.time = frameTime
    local profileTime = frameTime

    local map = this.NxMap
    local gopts = map.GOpts

    map.Tick = map.Tick + 1
    map.EffScale = this:GetEffectiveScale()

    -- Cache frequently accessed database values
    local dbProfile = Nx.db.profile
    local dbChar = Nx.db.char
    local mapSettings = dbProfile.Map

    map.Size1 = mapSettings.LineThick * .75 / map.EffScale

    Nx.Map:UpdateOptions(map.MapIndex)

    local winx, winy = Nx.Util_IsMouseOver (this)
    if not this:IsVisible() or not map.MouseEnabled then
        winx = nil
        map.Scrolling = false
    end

    if (Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)) and map.CurOpts.NXInstanceMaps then
        winx = nil
        map.Scrolling = false
    end

    if map.MMZoomType == 0 and Nx.Util_IsMouseOver (map.MMFrm) then
        winx = nil
    end

    map.MouseIsOver = winx

    if winx then
        Nx.Map.MouseOver = true
    else
        Nx.Map.MouseOver = false
    end

    if Nx.Map:IsInstanceMap(Nx.Map.RMapId) then
        --winx = nil
        --Nx.Map.MouseOver = false
    end

    -- Scroll map with mouse

    if map.Scrolling then
        local cx, cy = GetCursorPosition()
        cx = cx / map.EffScale
        cy = cy / map.EffScale
        local x = cx - map.ScrollingX
        local y = cy - map.ScrollingY

--[[
        if map["DebugHotspots"] or (map.Debug and IsAltKeyDown()) then
            if map:OnButScrollDebug (0, 0, x, -y) then
                x = 0
                y = 0
            end
        end
--]]

        if x ~= 0 or y ~= 0 then        -- Moved? Cancel double click
            map.LClickTime = 0
        end

        map.ScrollingX = cx
        map.ScrollingY = cy

        local left = this:GetLeft()
        local top = this:GetTop()

        local mx = x / map.ScaleDraw
        local my = y / map.ScaleDraw
        map.MapPosXDraw = map.MapPosXDraw - mx
        map.MapPosYDraw = map.MapPosYDraw + my

        map.MapPosX = map.MapPosXDraw
        map.MapPosY = map.MapPosYDraw
        map.Scale = map.ScaleDraw
    end

    -- Update edit mode preview rectangle while drawing
    map:EditModeUpdate()

    map:Update (elapsed)

    -- Title text

    local title = ""
    if Nx.db.profile.Map.ShowTitleName then
        title = map:IdToName (map.UpdateMapID)
--        for n = 1, MAX_BATTLEFIELD_QUEUES do
        for n = 1, GetMaxBattlefieldID() do        -- Patch 4.3

            local status, _, instId = GetBattlefieldStatus (n)
            if status == "active" then
                title = title .. format (" #%s", instId)
                break
            end
        end
    end

    if Nx.db.profile.Map.ShowTitleXY then
        if map.PlyrRZX ~= 0 or map.PlyrRZY ~= 0 then
            if map.DebugFullCoords then
                title = title .. format (" %4.2f, %4.2f", map.PlyrRZX, map.PlyrRZY)
            else
                title = title .. format (" %4.1f, %4.1f", map.PlyrRZX, map.PlyrRZY)
            end
        end
    end

    if map.PlyrSpeed > 0 and Nx.db.profile.Map.ShowTitleSpeed then

        local speed = map.PlyrSpeed

        local sa = Nx.Map.MapWorldInfo[map.MapId] and Nx.Map.MapWorldInfo[map.MapId].ScaleAdjust or 1
        if sa then
            speed = speed * sa
        end

        speed = speed / 6.4 * 100 - 100
        if abs (speed) < .5 then    -- Removes small -0%
            speed = 0
        end
        title = title..format (" |cffa0a0a0" .. L["Speed"] .. "%+.0f%%", speed)
--        Nx.prt ("Speed %f %f, Tm %.4f, %.3f %.3f", map.PlyrSpeed, speed, elapsed, map.PlyrX, map.PlyrY)        -- DEBUG!
    end

--    title = title..format (" Dir %.1f", map.PlyrDir)

    local cursorLocStr = ""
    local cursorLocXY = ""

    local menuOpened = Nx.Menu:IsAnyOpened()

    if winx then

        map.BackgndAlphaTarget = map.BackgndAlphaFull

        winy = this:GetHeight() - winy

        if winy >= map.TitleH then

            local wx, wy = map:FramePosToWorldPos (winx, winy)
            if not menuOpened then
--                local tm = GetTime()
                map:CheckWorldHotspots (wx, wy)
--                Nx.prt ("CheckWorldHotspots Time %s", GetTime() - tm)
            end

            local x, y = map:GetZonePos (Nx.Map.RMapId, wx, wy)
            x = floor (x * 10) / 10    -- Chop fraction to tenths
            y = floor (y * 10) / 10
            local dist = ((wx - map.PlyrX) ^ 2 + (wy - map.PlyrY) ^ 2) ^ .5 * 4.575

            cursorLocXY = format ("|cff80b080%.1f %.1f %.0f " .. L["yds"], x, y, dist)
            cursorLocStr = cursorLocXY

            -- Check for group members at cursor in instance/BG maps
            -- Show tooltips when in any instance/BG with group members, not just when NXInstanceMaps overlay is enabled
            local inInstanceOrBG = Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)
            if inInstanceOrBG and IsInGroup() then
                local groupMember, groupUnit = map:GetGroupMemberAtCursor(x, y)
                if groupMember and groupUnit then
                    -- Get class color for the player
                    local classColor = "|cff00ff00"  -- Default green
                    local class = select(2, UnitClass(groupUnit))
                    local classColorObj = nil
                    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
                        classColorObj = RAID_CLASS_COLORS[class]
                        classColor = format("|cff%02x%02x%02x", classColorObj.r * 255, classColorObj.g * 255, classColorObj.b * 255)
                    end
                    cursorLocStr = format("%s%s\n%s", classColor, groupMember, cursorLocStr)

                    -- Show GameTooltip with player info
                    if map.InstanceGroupMemberHover ~= groupMember then
                        map.InstanceGroupMemberHover = groupMember
                        map.InstanceGroupMemberUnit = groupUnit

                        Nx.TooltipText:SetOwner(this, "ANCHOR_CURSOR")
                        local className = UnitClass(groupUnit) or ""
                        local level = UnitLevel(groupUnit)
                        local health = UnitHealth(groupUnit)
                        local healthMax = UnitHealthMax(groupUnit)
                        local healthPct = healthMax > 0 and floor(health / healthMax * 100) or 0

                        local r, g, b = 0, 1, 0  -- Default green
                        if classColorObj then
                            r, g, b = classColorObj.r, classColorObj.g, classColorObj.b
                        end
                        Nx.TooltipText:AddLine(groupMember, r, g, b)
                        if level and level > 0 then
                            Nx.TooltipText:AddLine(format("%s %s %d", L["Level"], className, level), 1, 1, 1)
                        else
                            Nx.TooltipText:AddLine(className, 1, 1, 1)
                        end
                        if healthPct < 100 then
                            local healthColor = healthPct > 50 and "|cff00ff00" or (healthPct > 25 and "|cffffff00" or "|cffff0000")
                            Nx.TooltipText:AddLine(format("%s: %s%d%%", L["Health"] or "Health", healthColor, healthPct), 1, 1, 1)
                        end
                        Nx.TooltipText:Show()
                    end
                else
                    -- Hide tooltip when no longer over a group member
                    if map.InstanceGroupMemberHover then
                        map.InstanceGroupMemberHover = nil
                        map.InstanceGroupMemberUnit = nil
                        if Nx.TooltipText:IsOwned(this) then
                            Nx.TooltipText:Hide()
                        end
                    end
                end
            end

            --[[local name = UpdateMapHighlight (x / 100, y / 100)
            if name then
                cursorLocStr = format ("%s\n|cffafafaf%s", cursorLocStr, name)
            end]]--
        end

    else
--        if GameTooltip:IsOwned (map.Win.Frm) and map.TooltipType == 1 then
--            Nx.prt ("map TT hide")
--            map.TooltipType = 0
--            GameTooltip:Hide()
--        end

        if not map.Scrolling and not menuOpened then

            map.BackgndAlphaTarget = map.BackgndAlphaFade

            local rid = map.RMapId

            if rid ~= 9000 then

                local mapId = map:GetCurrentMapId()
                if map:IsInstanceMap (rid) then
                    if not Nx.Map.InstanceInfo[rid] then        -- Don't convert WotLK/Cata instances
                        local lrid = Nx.Map.MapWorldInfo[rid].EntryMId
                        if lrid ~= nil then rid = lrid end
                    end
                    local lvl = Nx.Map:GetCurrentMapDungeonLevel()
                    if lvl ~= map.InstLevelSet then
                        map.MapId = 0    -- Force set
--                        Nx.prt ("map force set inst")
                    end
                end

                if map.UpdateMapID ~= rid then
                    if map:IsBattleGroundMap (rid) then
                        Nx.Map:SetToCurrentZone()
                        Nx.Map.UpdateMapID = WorldMapFrame.mapID
                    else
                        map:SetCurrentMap (rid)
                    end
                end
            end
        end
    end

    if IsIndoors() or Nx.Map.Indoors then
        map.BackgndAlphaTarget = map.BackgndAlphaFull
    end

    -- Check quest window
    if Nx.Quest then
        if map.Guide.Win.Frm:IsVisible() or Nx.Quest.List.Win and Nx.Quest.List.Win.Frm:IsVisible() then
            map.BackgndAlphaTarget = map.BackgndAlphaFull
        end
    end

    -- Profiling

    if map.DebugTime then

        profileTime = GetTime() - profileTime
        local t = map.DebugProfileTime or .01
        t = t * .95 + profileTime * .05
        map.DebugProfileTime = t

        UpdateAddOnMemoryUsage()
        local mem = GetAddOnMemoryUsage ("Carbonite")

        local memdif = mem - (map.DebugMemUse or 0)
        map.DebugMemUse = mem

        title = title..format (" Time %.4f Mem %d %.4f", t, mem, memdif)
    end

    if GetCVar ("scriptProfile") == "1" then

        UpdateAddOnCPUUsage()

        title = title..format (" |cffffffffCPU %6.3f %6.3f", GetAddOnCPUUsage ("CARBONITE"), GetScriptCPUUsage())

        ResetCPUUsage()
    end

    --

    if Nx.Tick % 3 == 0 then    -- Do less often, since tip makes garbage

        local tip = format (" %s", cursorLocStr)
        if map.Debug and winx then
            local x, y = map:FramePosToWorldPos (winx, winy)
            tip = tip .. format ("\n|cffc080a0%.2f WXY %6.2f %6.2f PXY %6.2f %6.2f", map.Scale, x, y, map.PlyrX, map.PlyrY)
            map.DebugWX = x
            map.DebugWY = y
        end

        local over = winx and not Nx.Util_IsMouseOver (map.ToolBar.Frm)
        map:SetLocationTip (over and not menuOpened and map.WorldHotspotTipStr and (map.WorldHotspotTipStr .. tip))
    end

    if map.Win:IsSizeMax() then
        local s = Nx.Map:GetZoneAchievement (true)
        if s then
            title = title .. "  " .. s
        end
    end

    map.Win:SetTitle (title, 1)

    if Nx.db.profile.Map.ShowTitle2 then

        local s = GetSubZoneText()
        local pvpType = GetZonePVPInfo()
        if pvpType then
            s = s .. " (" .. L[pvpType] .. ")"
        end
        map.Win:SetTitle (format ("%s %s", s, cursorLocXY), 2)
    end
end

--------
-- Handle mouse click on icon

--[[
function Nx.Map:WorldHotspotOnMouseDown (button)

--    Nx.prt ("MapWorldHotspotOnMouseDown "..button.." "..(this:GetName() or "?"))

    local map = this.NxMap
    map.ClickFrm = this
    this = map.Frm
    map:OnMouseDown (button)
end
--]]

--------
-- Handle mouse on icon

--[[
function Nx.Map:WorldHotspotOnEnter (motion)

    local map = this.NxMap

    if not map.Scrolling then

        local mapId = this.NxMapId
        map:SetCurrentMap (mapId)

        map:IconOnEnter (motion)
    end
end
--]]

--------
-- Flag for update all map data

function Nx.Map:UpdateAll()

    self.NeedWorldUpdate = true

--    Nx.prt ("%d Map UpdateAll %d (%d)", self.Tick, self:GetCurrentMapId(), self.MapId)
end

--------
-- Update all map data

function Nx.Map:UpdateWorld()

    if self.Debug then
--        Nx.prt ("%d Map UpdateWorld1 %d L%d",
--                self.Tick, self:GetCurrentMapId(), GetCurrentMapDungeonLevel())
    end

    self.NeedWorldUpdate = false
    local mapId
    local dungeonLevel = Nx.Map:GetCurrentMapDungeonLevel()

    -- Quick early-out: if we have cached state, check if anything changed before expensive API calls
    if self.CurWorldUpdateMapId and self.LastDungeonLevel == dungeonLevel then
        -- Use cached map ID for quick check
        mapId = self:GetCurrentMapId()
        if self.CurWorldUpdateMapId == mapId then
            -- Only check overlay count every 2 seconds (expensive API call)
            local now = GetTime()
            if not self.LastOverlayCheckTime or (now - self.LastOverlayCheckTime) > 2 then
                self.LastOverlayCheckTime = now
                local i = self:GetExploredOverlayNum()
                if i == self.CurWorldUpdateOverlayNum then
                    return  -- Nothing changed
                end
                self.CurWorldUpdateOverlayNum = i
            else
                return  -- Use cached overlay count, no update needed
            end
        end
    end

    if not Nx.Map.MouseOver and not Nx.Util_IsMouseOver(self.MMFrm) then
        --Nx.Map:UnregisterEvent ("WORLD_MAP_UPDATE")
        Nx.Map:SetToCurrentZone()
        --Nx.Map:RegisterEvent ("WORLD_MAP_UPDATE", "OnEvent")
        -- Use the player's actual zone when mouse is not over the map
        -- This fixes city maps not showing initially (RMapId may not be updated yet)
        mapId = MapUtil.GetDisplayableMapForPlayer()
    end
    if not mapId or mapId == 9000 then
        mapId = self:GetCurrentMapId()
    end

    local winfo = self.MapWorldInfo[mapId]
    if winfo and self.MapWorldInfo[mapId].BaseMap then
      winfo = self.MapWorldInfo[self.MapWorldInfo[mapId].BaseMap]
    end
    if not winfo then
        winfo = {}
    end
    if winfo.MapLevel then
        if dungeonLevel ~= winfo.MapLevel then    -- Wrong level?
            --SetDungeonMapLevel (winfo.MapLevel)
        end
    end

    -- For full update path, refresh overlay count
    local i = self:GetExploredOverlayNum()
    self.LastOverlayCheckTime = GetTime()

    if self.CurWorldUpdateMapId == mapId and i == self.CurWorldUpdateOverlayNum and dungeonLevel == self.LastDungeonLevel then
        return
    end

    self.CurWorldUpdateMapId = mapId
    self.CurWorldUpdateOverlayNum = i
    self.LastDungeonLevel = dungeonLevel

--    local mapInfo = C_Map.GetMapInfo(mapId)
    local mapInfo = Nx.Map:GetMapInfo(mapId)
    local mapFileName = winfo.Overlay or (mapInfo.name and mapInfo.name:gsub(" ", "") or "")
    if not mapFileName then
        if Nx.Map:GetCurrentMapContinent() == WORLDMAP_COSMIC_ID then
            mapFileName = "Cosmic"
        else
            mapFileName = "World"
        end
    end
    local texPath = "Interface\\WorldMap\\"..(isMicro and "MicroDungeon\\"..mapFileName.."\\"..microTex or mapFileName).."\\"
    local texName = microTex or mapFileName

    self:UpdateOverlayUnexplored()

    Nx.UEvents:UpdateMap (true)
    local dungeonLevel = Nx.Map:GetCurrentMapDungeonLevel();
    --[[if (DungeonUsesTerrainMap()) then
        dungeonLevel = dungeonLevel - 1;
    end]]--
    if dungeonLevel>0 then texName = texName..dungeonLevel.."_" end
    if winfo.MapBaseName and not winfo.Garrison then texName = winfo.MapBaseName end
    if winfo.Garrison and not isMicro and C_Garrison then
        local level, mapTextureKit, townHallX, townHallY = C_Garrison.GetGarrisonInfo(Enum.GarrisonType.Type_6_0_Garrison)

        if level and mapTextureKit then
            texPath = "Interface\\WorldMap\\" .. winfo.MapBaseName .. level .. "\\"
            texName = winfo.MapBaseName .. level
            -- Also update the overlay to match the garrison tier
            mapFileName = winfo.MapBaseName .. level
            -- Dynamically update winfo.Overlay so UpdateOverlay uses the correct tier
            winfo.Overlay = winfo.MapBaseName .. level
        else
            level = 1  -- Default to level 1 if no valid level is returned
            texPath = "Interface\\WorldMap\\" .. winfo.MapBaseName .. level .. "\\"
            texName = winfo.MapBaseName .. level
            mapFileName = winfo.MapBaseName .. level
            winfo.Overlay = winfo.MapBaseName .. level
        end
        -- Store the current garrison tier for use in drawing plot icons
        self.GarrisonTier = level
    end

    if self.Debug then
        Nx.prt ("%d Map UpdateWorld %d", self.Tick, self:GetCurrentMapId())
        Nx.prt (" File %s", texPath..texName..mapId)
    end

    local GetMapArtLayerTexturesMapId = ((self.MapWorldInfo[mapId] and self.MapWorldInfo[mapId].RBaseMap) and self.MapWorldInfo[mapId].RBaseMap or mapId)
    if winfo.Garrison then GetMapArtLayerTexturesMapId = mapId end
    if GetMapArtLayerTexturesMapId == nil then
        return
    end

    local texturesIDs = C_Map and C_Map.GetMapArtLayerTextures and C_Map.GetMapArtLayerTextures(GetMapArtLayerTexturesMapId, 1)
    if not texturesIDs then
        return  -- API not available
    end
    -- Classic Era returns nested table {[1]={textures}}, Retail returns flat array {textures}
    -- Check if first element is a table (nested) or number (flat)
    if type(texturesIDs[1]) == "table" then
        texturesIDs = texturesIDs[1]
    end
    local numtiles = #texturesIDs

    for i = 1, numtiles do
        if self.TileFrms[i] and self.TileFrms[i].texture then
            self.TileFrms[i].texture:SetTexture(texturesIDs[i])
            if self.TileFrms[i].texture.SetSnapToPixelGrid then
                self.TileFrms[i].texture:SetSnapToPixelGrid(false)
                self.TileFrms[i].texture:SetTexelSnappingBias(0)
            end
        end
    end
end

--------
-- Update window fade

function Nx.Map:WinUpdateFade (fade)
    --self.ToolBar:SetFade (fade * .9 + .1)
    self.ButAutoScaleOn.Frm:SetAlpha (fade * .9 + .1)
end

--------
-- Update map. Called every tick, make it quick

function Nx.Map:Update (elapsed)
    if IS_BACKGROUND_WORLD_CACHING then
        return
    end
    if WorldMapFrame:IsVisible() then
        --return
    end
    local Nx = Nx
    local Map = Nx.Map

    -- Debug profiling for stutter detection
    local debugProfile = Nx.db.profile.Debug.DebugMap
    local profileStart, profileSection
    if debugProfile then
        profileStart = debugprofilestop()
    end

    self:MouseEnable (self.Win:IsSizeMax())

    --if self.NeedWorldUpdate then
        self:UpdateWorld()
    --end

    if debugProfile then
        local now = debugprofilestop()
        if (now - profileStart) > 5 then -- More than 5ms
            Nx.prt("Map:Update - UpdateWorld took %.2fms", now - profileStart)
        end
        profileSection = now
    end

    self.MapW = self.Frm:GetWidth() - self.PadX * 2
    self.MapH = self.Frm:GetHeight() - self.TitleH
    self.Level = self.Frm:GetFrameLevel() + 1
    local mapId = Nx.Map:GetCurrentMapAreaID()
    self.Cont, self.Zone = self:IdToContZone (mapId)

    Nx.InSanctuary = C_PvP.GetZonePVPInfo() == "sanctuary"

    local doSetCurZone
    local mapChange

    Nx.Map.mapChange = false
    if self.MapId ~= mapId then

--        Nx.prtD ("%d Map change %d to %d", self.Tick, self.MapId, mapId)

        self.CurMapBG = self:IsBattleGroundMap (mapId)

        if not self:IsBattleGroundMap (self.MapId) then
--            self.MapIdOld = self.MapId
            self:AddOldMap (mapId)
        end

        self.MapId = mapId
        mapChange = true
        Nx.Map.mapChange = mapChange

        -- Hide all world quest icons immediately on map change to prevent stale icons
        local wqFrms = self.IconWQFrms
        for n = 1, wqFrms.Used or 0 do
            if wqFrms[n] then
                wqFrms[n]:Hide()
            end
        end
        wqFrms.Next = 1

        -- Clear quest offer cache on map change to prevent showing wrong quest titles
        if Nx.Quest and Nx.Quest.ClearQuestOfferCache then
            Nx.Quest:ClearQuestOfferCache()
        end

        -- Clear POI cache on map change (POI_Cache is accessed via local reference)
        POI_Cache.mapID = nil
        POI_Cache.data = nil
        POI_Cache.time = 0

        Nx.Com.PlyrChange = GetTime()
    end

    local rid = self.MapId
    Nx.Map.UpdateMapID = rid
    local inBG = self:IsBattleGroundMap (rid)

    -- Cache instance/BG checks for use throughout the frame
    local isInstance = self:IsInstanceMap(rid)
    FrameCache.isInstance = isInstance
    FrameCache.isBG = inBG
    FrameCache.mapId = rid
    FrameCache.dungeonLevel = Nx.Map.DungeonLevel

    if Nx.InBG and Nx.InBG ~= rid then    -- Left or changed BG?

--        Nx.prt ("Left BG %s", Nx.InBG)

        local cb = Nx.Combat

        if Nx.InArena then
            local s = Nx.Map:GetShortName (Nx.InArena)
            Nx.UEvents:AddInfo (format ("Left %s %d %d %dD %dH", s, cb.KBs, cb.Deaths, cb.DamDone, cb.HealDone))

        else
            local total = cb.KBs + cb.Deaths + cb.HKs + cb.Honor
            if total > 0 then
                local sname = Nx.Map:GetShortName (Nx.InBG)
                Nx.UEvents:AddInfo (format ("Left %s %d %d %d %d", sname, cb.KBs, cb.Deaths, cb.HKs, cb.Honor))

                local tm = GetTime() - cb.BGEnterTime
                --local _, honor = GetCurrencyInfo (392)        --V4
                --local hGain = honor - cb.BGEnterHonor

                RequestBattlefieldScoreData();

                for i=1, GetNumBattlefieldScores() do
                    local name, killingBlows, honorableKills, deaths, hGain, faction, rank, race, class = GetBattlefieldScore(i);
                    if (name == UnitName("player")) then
                        Nx.UEvents:AddInfo (format (" %s +%d honor, +%d hour", Nx.Util_GetTimeElapsedMinSecStr (tm), hGain, hGain / tm * 3600))
                    end
                end

                local xpGain = UnitXP ("player") - cb.BGEnterXP
                if xpGain > 0 then
                    Nx.UEvents:AddInfo (format (" +%d xp, +%d hour", xpGain, xpGain / tm * 3600))
                end
            end
        end

        cb.KBs = 0
        cb.Deaths = 0
        cb.HKs = 0
        cb.Honor = 0
        Nx.InBG = nil

        if Nx.InArena then
            self.LOpts.NXMMFull = false
        end
        Nx.InArena = nil
    end

    if inBG and Nx.InBG ~= rid then
        Nx.InBG = rid

        local cb = Nx.Combat
        cb.BGEnterTime = GetTime()
        --local _, honor = GetCurrencyInfo (392)        --V4
        cb.BGEnterHonor = 0
        cb.BGEnterXP = UnitXP ("player")

        if self.MapWorldInfo[rid].Arena then
            Nx.InArena = rid
            self.LOpts.NXMMFull = true
        end

--        Nx.prt ("Entering BG %s", rid)
        doSetCurZone = true
    end

    -- Taxi update

    Nx.Map.DungeonLevel = Nx.Map:GetCurrentMapDungeonLevel()

    local ontaxi = UnitOnTaxi ("player")

    if ontaxi then
        if not Map.TaxiOn then    -- New taxi ride?
            Map.TaxiStartTime = GetTime()
            Map.TaxiOn = true
            if Nx.db.profile.Debug.DebugMap then
                Nx.prt ("Taxi start")
            end
        end

    elseif Map.TaxiOn then    -- Done with taxi
        Map.TaxiOn = false
        Map.TaxiX = nil        -- Clear so if we pop on a taxi by a unhooked method we don't track old

        local tm = GetTime() - Map.TaxiStartTime

        Nx.Travel:TaxiSaveTime (tm)

        if Nx.db.profile.Debug.DebugMap then
            Nx.prt ("Taxi time %.1f seconds", tm)
        end
    end

    -- Real map switch

    if Nx.Map.RMapId ~= rid then
        if rid ~= 9000 then
--            Nx.prtD ("Map zone changed %d, %d", rid, mapId)

            -- Reset InstanceId before switch operations to prevent GotoCurrentZone
            -- from using instance scale (20) when teleporting from instance to normal zone
            if not self:IsInstanceMap(rid) then
                self.InstanceId = false
            end

            if Nx.Map.RMapId == 9000 then    -- Loading?
                self.CurOpts = nil
                self:SwitchOptions (rid, true)
            end
            if not Nx.Menu:IsAnyOpened() then
                Nx.Map:SetMapByID(rid)
                Nx.Map.RMapId = rid
                Nx.Map.DungeonLevel = Nx.Map:GetCurrentMapDungeonLevel()
                self:SwitchOptions (rid)
                self:SwitchRealMap (rid)
            end
        end
        --self.Scale = self.RealScale
    end
    local plZX, plZY = Nx.Map.GetPlayerMapPosition ("player")
    if (Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
        Nx.Map.MoveWorldMap()
        Nx.Map:GetMap(1).PlyrFrm:Hide()
    else
        Nx.Map.RestoreWorldMap()
        Nx.Map:GetMap(1).PlyrFrm:Show()
    end
    if (Nx.Map.RMapId ~= Nx.Map.UpdateMapID) then
        plZX = 0
        plZY = 0
    end
    local dungeontest = Nx.Map:GetCurrentMapDungeonLevel()
    self.InstanceId = false

    if self:IsInstanceMap (Nx.Map.UpdateMapID) and not self.CurOpts.NXInstanceMaps then
        self.InstanceId = Nx.Map.UpdateMapID
        plZX = plZX * 100
        plZY = plZY * 100

--        self.PlyrInstX = plZX
--        self.PlyrInstY = plZY

--        Nx.prt ("XY %s %s", plZX, plZY)

        self.PlyrRZX = plZX
        self.PlyrRZY = plZY

        local x, y = self:GetWorldPos (Nx.Map.UpdateMapID, 0, 0)
        local lvl = max (Nx.Map:GetCurrentMapDungeonLevel(), 1)        -- 0 if no level
        if Nx.Map:GetCurrentMapAreaID() == 520 then
            if Nx.Map:GetCurrentMapDungeonLevel() == 0 then
                lvl = 1
            else
                lvl = 2
            end
        end

        if not self.InstMapId then        -- Not showing instance?
            plZX = 0
            plZY = 0

        elseif plZX == 0 and plZY == 0 then

            self.InstLevelSet = -1
        end

        local layerIndex = WorldMapFrame:GetCanvasContainer():GetCurrentLayerIndex();
        local layers = C_Map.GetMapArtLayers(mapId)

        self.PlyrX = x + plZX * layers[layerIndex].layerWidth / 25600
        self.PlyrY = y + plZY * layers[layerIndex].layerHeight / 25600 + (lvl - 1) * layers[layerIndex].layerHeight / 256
--        self.InstanceLevel = GetCurrentMapDungeonLevel()

        self.PlyrSpeed = 0

        Nx.Map.MouseOver = false
    elseif plZX > 0 or plZY > 0 then    -- Update world position of player if we can get it

        plZX = plZX * 100
        plZY = plZY * 100
        PLMapID = MapUtil.GetDisplayableMapForPlayer()

        if Nx.OldMapIDs then
            if PLMapID == 1414 then PLMapID = 12 end
            if PLMapID == 1415 then PLMapID = 13 end
        end

        local x, y = self:GetWorldPos (PLMapID, plZX, plZY)

        if elapsed > 0 then

            if x == self.PlyrX and y == self.PlyrY then    -- Not moving?
                self.PlyrSpeedCalcTime = GetTime()
                self.PlyrSpeed = 0
                self.PlyrSpeedX = x
                self.PlyrSpeedY = y
            else
                local tmDif = GetTime() - self.PlyrSpeedCalcTime
                if tmDif > .5 then
                    self.PlyrSpeedCalcTime = GetTime()
                    self.PlyrSpeed = ((x - self.PlyrSpeedX) ^ 2 + (y - self.PlyrSpeedY) ^ 2) ^ .5 * 4.575 / tmDif
                    self.PlyrSpeedX = x
                    self.PlyrSpeedY = y
                end
            end
        end

--        if elapsed > 0 then
--            self.PlyrSpeed = ((x - self.PlyrX) ^ 2 + (y - self.PlyrY) ^ 2) ^ .5 * 4.575 / elapsed
--        end

        self.PlyrX = x
        self.PlyrY = y
        if mapId ~= rid then            -- Not in real zone?
            if (self:IsMicroDungeon(mapId)) then
            else
                plZX, plZY = self:GetZonePos (rid, x, y)
            end
        end

        self.PlyrRZX = plZX
        self.PlyrRZY = plZY

        if mapChange then
            self.MoveLastX = x
            self.MoveLastY = y
        end
    end

--    Nx.prt ("Dir %s", GetPlayerFacing())
    self.PlyrDir = 0
    if GetPlayerFacing() ~= nil then
        self.PlyrDir = 360 - GetPlayerFacing() / 2 / math.pi * 360
    end

    local plX = self.PlyrX
    local plY = self.PlyrY
    local x = plX - self.MoveLastX
    local y = plY - self.MoveLastY
    local ang = self.PlyrDir - self.PlyrLastDir

    local moveDist = (x * x + y * y) ^ .5

--    if moveDist > 0 then Nx.prt ("MoveDist %f %f", moveDist, self.BaseScale) end

    if moveDist >= .01 * self.BaseScale or abs (ang) > .01 then
        Nx.Com.PlyrChange = GetTime()

        if self.MoveLastX ~= -1 then
            self.MoveDir = math.deg (math.atan2 (x, -y / 1.5))
        end

        self.MoveLastX = plX
        self.MoveLastY = plY

--        if not rotOk then
--            self.PlyrDir = self.MoveDir
--        end

        self.PlyrLastDir = self.PlyrDir

        if not self.Scrolling and not self.MouseIsOver then
            if self.CurOpts.NXPlyrFollow then
                local scOn = self.LOpts.NXAutoScaleOn        --self.GOpts["MapFollowChangeScale"]
                if plZX ~= 0 or plZY ~= 0 then
                    if #self.Tracking == 0 or not scOn then
                        self:Move (plX, plY, nil, 30)
                    end
                end
                if scOn then
                    local midX
                    local midY
                    local dtx
                    local dty
                    local cX, cY

                    -- Only check corpse if player is actually dead
                    if UnitIsDeadOrGhost("player") and C_Map.GetBestMapForUnit("player") then
                        local CorpseInfo = C_DeathInfo.GetCorpseMapPosition(C_Map.GetBestMapForUnit("player"))
                        if CorpseInfo then
                            cX = CorpseInfo.x or 0
                            cY = CorpseInfo.y or 0
                        end
                    end
                    if cX == nil or cY == nil then
                        cX = 0
                        cY = 0
                    end

                    if cX ~= 0 or cY ~= 0 then

                        midX, midY = self:GetWorldPos (mapId, cX * 100, cY * 100)
                        dtx = 1
                        dty = 1

                    elseif #self.Tracking > 0 then

                        local tr = self.Tracking[1]
                        midX = tr.TargetMX
                        midY = tr.TargetMY
                        dtx = abs (tr.TargetX1 - tr.TargetX2)
                        dty = abs (tr.TargetY1 - tr.TargetY2)

                    elseif Map.TaxiX then

                        midX, midY = self.TaxiX, self.TaxiY
                        dtx = 1
                        dty = 1
                    end

                    if midX then
                        local mX = (midX + self.PlyrX) * .5
                        local mY = (midY + self.PlyrY) * .5
                        local dx = abs (midX - self.PlyrX)
                        local dy = abs (midY - self.PlyrY)

                        -- Minimum distance threshold to prevent extreme scaling
                        -- When player is very close to target, don't auto-scale
                        local MIN_DISTANCE = 10  -- Minimum world units before auto-scale kicks in

                        if dx < MIN_DISTANCE and dy < MIN_DISTANCE then
                            -- Player is very close to target, just follow without scaling
                            self:Move (plX, plY, nil, 30)
                        else
                            -- Ensure minimum distance to prevent division by tiny numbers
                            dx = max(dx, MIN_DISTANCE)
                            dy = max(dy, MIN_DISTANCE)

                            local scaleX = self.MapW / dx
                            local scaleY = self.MapH / dy
                            local scale = min (scaleX, scaleY) * .5

                            -- Target rectangle scaling
                            if dtx and dty then
                                dtx = max(dtx, 1)
                                dty = max(dty, 1)
                                local targetScaleX = self.MapW / dtx
                                local targetScaleY = self.MapH / dty
                                scale = min (min (targetScaleX, targetScaleY), scale)
                            end

                            local scmax = self.InstanceId and 800 or self.LOpts.NXAutoScaleMax
                            local scmin = self.LOpts.NXAutoScaleMin

                            -- Sanity check: don't change scale drastically in one frame
                            local currentScale = self.Scale or 1
                            local maxScaleChange = currentScale * 2  -- Max 2x change per update
                            scale = max(min(scale, maxScaleChange), currentScale / 2)

                            -- Apply final min/max limits
                            scale = max (min (scale, scmax), scmin)
                            self:Move (mX, mY, scale, 30)
                        end
                    end
                end

                if rid ~= mapId then
                    doSetCurZone = true
--                    Nx.prt ("Map Nx.Map:SetToCurrentZone")
                end
            end
        end
    end

    -- Adjust draw scale and position

    local scaleDiff = abs (self.ScaleDraw - self.Scale)
    local xDiff = self.MapPosXDraw - self.MapPosX
    local yDiff = self.MapPosYDraw - self.MapPosY

    if self.StepTime ~= 0 and (scaleDiff > 0 or xDiff ~= 0 or yDiff ~= 0) then
--    if (xDiff ~= 0 or yDiff ~= 0) and (self.Tick % 1 == 0) then

--        Nx.prt ("Tick %f", self.Tick)

        if self.StepTime > 0 then

--            Nx.prt ("Steptime Go #%d %f", self.Tick, self.StepTime)

            self.StepTime = -self.StepTime

            self.ScaleDrawW = 1 / self.ScaleDraw
            self.ScaleW = 1 / self.Scale
        end

        local st = -self.StepTime

        self.MapPosXDraw = Nx.Util_StepValue (self.MapPosXDraw, self.MapPosX, abs (xDiff) / st)
        self.MapPosYDraw = Nx.Util_StepValue (self.MapPosYDraw, self.MapPosY, abs (yDiff) / st)
        self.ScaleDrawW = Nx.Util_StepValue (self.ScaleDrawW, self.ScaleW, abs (self.ScaleDrawW - self.ScaleW) / st)
        self.ScaleDraw = 1 / self.ScaleDrawW

--        Nx.prt ("Map scrl #%d %f %f", self.StepTime, self.MapPosXDraw, self.MapPosX)
--        Nx.prt ("Map scrl %f %f", self.OCur, self.OEnd)
--        Nx.prt ("Map scrl %f %f", self.ScaleDraw, self.Scale)

        self.StepTime = self.StepTime + 1
    end

    local _, zx, zy, zw = self:GetWorldZoneInfo (self.Cont, self.Zone)
    if zx then
        self.MapScale = self.Scale / 10.02
    end

    --

    local plSize = Nx.db.profile.Map.PlyrArrowSize
    if IsShiftKeyDown() then
        plSize = 5
    end
    if self.PlyrFrm:IsVisible() then
        self:ClipFrameW (self.PlyrFrm, self.PlyrX, self.PlyrY, plSize, plSize, self.PlyrDir)
    end
    self.InCombat = UnitAffectingCombat ("player")
    local g = 1
    local b = 1
    local al = 1
    if self.InCombat then
        g = 0
        b = 0
        al = abs (GetTime() % 1 - .5) / .5 * .5 + .4
    end
    self.PlyrFrm.texture:SetVertexColor (1, g, b, al)

--    local str = format ("%s %d %d", UnitName ("player"), UnitHealth ("player"), UnitMana ("player"))
--    self.PlyrFrm.NxTip = str

    self.BackgndAlpha = Nx.Util_StepValue (self.BackgndAlpha, self.BackgndAlphaTarget, .05)
    self.Frm.texture:SetVertexColor (1, 1, 1, self.BackgndAlpha)

    self.WorldAlpha = (self.BackgndAlpha - self.BackgndAlphaFade) / (self.BackgndAlphaFull - self.BackgndAlphaFade) * self.BackgndAlphaFull

    self:ResetIcons()

    self:MoveContinents()
--    self:MoveWorldHotspots()

--    if not (IsAltKeyDown() and IsControlKeyDown()) then
--    end

    local zoneStart = debugProfile and debugprofilestop()
    self:UpdateZones()
    local zoneTime = debugProfile and (debugprofilestop() - zoneStart) or 0

    local instStart = debugProfile and debugprofilestop()
    self:UpdateInstanceMap()
    local instTime = debugProfile and (debugprofilestop() - instStart) or 0

    local mmStart = debugProfile and debugprofilestop()
    self:MinimapUpdate()
    local mmTime = debugProfile and (debugprofilestop() - mmStart) or 0

--    self.MMFrm:GetParent():SetAlpha(0)
    local wmStart = debugProfile and debugprofilestop()
    self:UpdateWorldMap()
    local wmTime = debugProfile and (debugprofilestop() - wmStart) or 0

    if debugProfile then
        local totalTime = zoneTime + instTime + mmTime + wmTime
        if totalTime > 5 then
            Nx.prt("Map:Update - Zone:%.1f Inst:%.1f MM:%.1f WM:%.1f = %.1fms", 
                zoneTime, instTime, mmTime, wmTime, totalTime)
        end
        profileSection = debugprofilestop()
    end

    self:DrawContinentsPOIs()
    self:DrawGarrisonPlots()

    if Nx.db.profile.Map.ShowTrail then
        self:UpdatePlyrHistory()
    end

--[[
    if self["DebugHotspots"] then
        self:UpdateHotspotsDebug()
    end
--]]
    if Nx.Punks and Nx.pkdb then
        if Nx.pkdb.profile.Punks.MapShowPunks then
            Nx.Punks:UpdateIcons (self)
        end
    end

    -- map BG Flags

    if GetNumBattlefieldFlagPositions() > 0 then
        for fpn = 1, GetNumBattlefieldFlagPositions() do
            local fpX, fpY, flagIcon = GetBattlefieldFlagPosition(fpn)
            if fpX and fpY and flagIcon then
                local ficon = self:GetIcon(3)
                fpX = fpX * 100
                fpY = fpY * 100
                fpX, fpY = self:GetWorldPos (self.MapId, fpX, fpY)
                self:ClipFrameWChop(ficon, fpX, fpY, 32 * self.ScaleDraw, 32 * self.ScaleDraw)
                ficon.texture:SetTexture("Interface\\WorldStateFrame\\" .. flagIcon)
            end
        end
    end

    -- POI's (Points of interest)

    local oldLev = self.Level

    if IsShiftKeyDown() or inBG then
        oldLev = oldLev - 4
        self.Level = self.Level + 16
    end

    local type, name, description, txIndex, pX, pY, atlasIcon
    local txX1, txX2, txY1, txY2

    if not IsAltKeyDown() then
        local zPOIs
        local now = GetTime()
        local isZoomingOrScrolling = self.StepTime ~= 0 or self.Scrolling
        local cacheValid = POI_Cache.mapID == rid and POI_Cache.data and (now - POI_Cache.time) < POI_Cache.refreshInterval

        -- Use cached POI data during zoom/scroll to reduce stutter, or if cache is still valid
        if isZoomingOrScrolling and POI_Cache.data and POI_Cache.mapID == rid then
            zPOIs = POI_Cache.data
        elseif cacheValid then
            zPOIs = POI_Cache.data
        else
            -- Fetch fresh POI data
            local tPOIs = C_TaxiMap.GetTaxiNodesForMap(rid) or {}
            -- Reuse pooled tables instead of creating new ones every frame
            local pPOIs = POI_Pool.pPOIs
            wipe(pPOIs)
            local dPOIs = C_ResearchInfo.GetDigSitesForMap(rid) or {}
            local aPOIs = POI_Pool.aPOIs
            wipe(aPOIs)
            local areaPOIIds = C_AreaPoiInfo.GetAreaPOIForMap(rid) or {}
            for j, aPOIId in ipairs(areaPOIIds) do
                aPOIs[j] = C_AreaPoiInfo.GetAreaPOIInfo(rid, aPOIId)
            end
            -- Add Delves POIs
            if C_AreaPoiInfo.GetDelvesForMap then
                local delvePOIIds = C_AreaPoiInfo.GetDelvesForMap(rid) or {}
                local offset = #aPOIs
                for j, delvePOIId in ipairs(delvePOIIds) do
                    aPOIs[offset + j] = C_AreaPoiInfo.GetAreaPOIInfo(rid, delvePOIId)
                end
            end
            -- Add Quest Hubs POIs
            if C_AreaPoiInfo.GetQuestHubsForMap then
                local hubPOIIds = C_AreaPoiInfo.GetQuestHubsForMap(rid) or {}
                local offset = #aPOIs
                for j, hubPOIId in ipairs(hubPOIIds) do
                    aPOIs[offset + j] = C_AreaPoiInfo.GetAreaPOIInfo(rid, hubPOIId)
                end
            end
            -- Add Dragonriding Races POIs
            if C_AreaPoiInfo.GetDragonridingRacesForMap then
                local racePOIIds = C_AreaPoiInfo.GetDragonridingRacesForMap(rid) or {}
                local offset = #aPOIs
                for j, racePOIId in ipairs(racePOIIds) do
                    aPOIs[offset + j] = C_AreaPoiInfo.GetAreaPOIInfo(rid, racePOIId)
                end
            end
            -- Add Events POIs
            if C_AreaPoiInfo.GetEventsForMap then
                local eventPOIIds = C_AreaPoiInfo.GetEventsForMap(rid) or {}
                local offset = #aPOIs
                for j, eventPOIId in ipairs(eventPOIIds) do
                    aPOIs[offset + j] = C_AreaPoiInfo.GetAreaPOIInfo(rid, eventPOIId)
                end
            end

            local bgPOIs = C_PvP.GetBattlefieldVehicles(rid) or {}

            -- Add vignettes (Bliz "special" map markers — Renown Quartermasters,
            -- world-event NPCs, some rares, etc.). They live on a separate
            -- C_VignetteInfo API that the AreaPOI/QuestHub/Event fetches don't
            -- cover. We map the vignette's position-in-this-map to the same
            -- shape as zPOI entries (position + name + atlasName) so the
            -- existing render loop draws them without further changes.
            local vPOIs = {}
            if C_VignetteInfo and C_VignetteInfo.GetVignettes then
                local vGUIDs = C_VignetteInfo.GetVignettes() or {}
                for _, guid in ipairs(vGUIDs) do
                    local vInfo = C_VignetteInfo.GetVignetteInfo(guid)
                    if vInfo and vInfo.onWorldMap then
                        local pos = C_VignetteInfo.GetVignettePosition and C_VignetteInfo.GetVignettePosition(guid, rid)
                        if pos then
                            vPOIs[#vPOIs + 1] = {
                                position = pos,
                                name = vInfo.name,
                                atlasName = vInfo.atlasName,
                                description = vInfo.description,
                            }
                        end
                    end
                end
            end

            -- Use pooled table for concatenation
            zPOIs = POI_Pool.zPOIs
            Nx.ArrayConcatReuse(zPOIs, tPOIs, pPOIs, dPOIs, aPOIs, bgPOIs, vPOIs)

            -- Cache the POI data
            POI_Cache.mapID = rid
            POI_Cache.time = now
            POI_Cache.data = zPOIs

            if debugProfile then
                local now2 = debugprofilestop()
                if (now2 - profileSection) > 5 then
                    Nx.prt("Map:Update - POI fetch took %.2fms", now2 - profileSection)
                end
                profileSection = now2
            end
        end

        for i, zPOI in ipairs(zPOIs) do
            local type = zPOI._type
            local name = zPOI.name
            local txIndex = zPOI.textureIndex
            local pX, pY
            if zPOI.position then
                pX = zPOI.position.x
                pY = zPOI.position.y
            else
                pX = zPOI.x
                pY = zPOI.y
            end

            local atlasIcon = zPOI.atlasName or zPOI.atlas
            local desc = zPOI.description
            local faction = zPOI.faction
            local widgetSet = zPOI.tooltipWidgetSet
            local areaPoiID = zPOI.areaPoiID

            local txW = 6
            local txH = 6

            if zPOI.textureWidth  and not inBG then txW = zPOI.textureWidth  end
            if zPOI.textureHeight and not inBG then txH = zPOI.textureHeight end

            local skip = false

            local _, splitname = strsplit(",", name)
            if type == 1 and not Nx.strpos(Nx.Map:GetMapNameByID(rid), strtrim(splitname and splitname or name)) then
                skip = true
            end

            -- type, name, desc, txIndex, pX, pY = C_WorldMap.GetMapLandmarkInfo (i)
            -- local type, name, desc, txIndex, pX, pY, mapLinkID, inBattleMap, graveyardID, areaID, poiID, isObjectIcon, atlasIcon = C_WorldMap.GetMapLandmarkInfo(i);
            -- Nx.prtCtrl ("LandMs %s, %s, %s, %s, %s, %s, %s, %s", i, poiID, txIndex or '-', name, type, isObjectIcon, atlasIcon, WorldMap_IsSpecialPOI(poiID))
            if (atlasIcon or (pX and txIndex ~= 0)) and not skip then        -- WotLK has 0 index POIs for named locations
                if (type ~= 4 or (type == 4 and Nx.db.char.Map.ShowArchBlobs)) and (faction == nil or faction == 0 or Nx.PlFactionNum == faction) then
                    local tip = name
                    if desc then
                        tip = format ("%s\n%s", name, desc)
                    end
                    pX = pX * 100
                    pY = pY * 100

        --            Nx.prtCtrl ("poi %d %s %s %d", i, name, desc, txIndex)

                    local f = self:GetIcon (5)

                    if self.CurMapBG then

                        f.NXType = 2000

                        local iconType = Nx.MapPOITypes[txIndex]

                        local sideStr = ""
                        if iconType == 1 then    -- Ally?
                            sideStr = " (Ally)"
                        elseif iconType == 2 then    -- Horde?
                            sideStr = " (Horde)"
                        end

                        if desc == L["In Conflict"] then

                            local state = self.BGTimers[name]
                            if state ~= txIndex then
                                self.BGTimers[name] = txIndex
                                self.BGTimers[name.."#"] = GetTime()
                            end

                            local dur = GetTime() - self.BGTimers[name.."#"]
                            local doneDur = (rid == 461 or rid == 540 or rid == 736) and 64 or 241
                            local leftDur = max (doneDur - dur, 0)
                            local tmStr

                            if leftDur < 60 then
                                tmStr = format (":%02d", leftDur)
                            else
                                tmStr = format ("%d:%02d", floor (leftDur / 60), floor (leftDur % 60))
                            end

                            f.NXData = format ("1~%f~%f~%s%s %s", pX, pY, name, sideStr, tmStr)

                            tip = format ("%s\n%s", tip, tmStr)

                            -- Horizontal bar

                            local sz = 30 / self.ScaleDraw

                            local f2 = self:GetIcon (0)
                            self:ClipFrameZTLO (f2, pX, pY, sz, sz, -15, -15)
                            f2.texture:SetColorTexture (0, 0, 0, .35)

                            f2.NXType = 2000
                            f2.NxTip = tip
                            f2.NXData = f.NXData

                            local f2 = self:GetIconNI (1)

                            if leftDur < 10 then

                                if self.BGGrowBars then

                                    local al = abs (GetTime() % .4 - .2) / .2 * .2 + .8

                                    local f3 = self:GetIconNI (2)
                                    self:ClipFrameZTLO (f3, pX, pY, sz * (10 - leftDur) * .1, 3 / self.ScaleDraw, -15, -15)
                                    f3.texture:SetColorTexture (.5, 1, .5, al)

                                    local f3 = self:GetIconNI (2)
                                    self:ClipFrameZTLO (f3, pX, pY, sz * (10 - leftDur) * .1, 3 / self.ScaleDraw, -15, 12)
                                    f3.texture:SetColorTexture (.5, 1, .5, al)
                                end

        --                        f2.texture:SetColorTexture (.5, 1, .5, abs (GetTime() % .6 - .3) / .3 * .7 + .3)
                            end

                            local red = .3
                            local blue = 1
                            if iconType == 2 then    -- Horde?
                                red = 1
                                blue = .3
                            end

                            f2.texture:SetColorTexture (red, .3, blue, abs (GetTime() % 2 - 1) * .5 + .5)

                            local per = leftDur / doneDur
                            local vper = per > .1 and 1 or per * 10

                            if self.BGGrowBars then
                                per = 1 - per
                                vper = 1
                            else
                                per = max (per, .1)
                            end

                            self:ClipFrameZTLO (f2, pX, pY, sz * per, sz * vper, -15, -15)

                        else    -- No conflict

                            f.NXData = format ("0~%f~%f~%s%s", pX, pY, name, sideStr)

                            self.BGTimers[name] = nil

                            -- Rect

                            local sz = 30 / self.ScaleDraw

                            local f2 = self:GetIcon (0)
                            self:ClipFrameZTLO (f2, pX, pY, sz, sz, -15, -15)

        --                    Nx.prtCtrl ("I %s %s %s", name, txIndex, iconType or "nil")

                            if iconType == 1 then    -- Ally?
                                f2.texture:SetColorTexture (0, 0, 1, .3)
        --                        Nx.prtCtrl ("Blue")
                            elseif iconType == 2 then    -- Horde?
                                f2.texture:SetColorTexture (1, 0, 0, .3)
        --                        Nx.prtCtrl ("Red")
                            else
                                f2.texture:SetColorTexture (0, 0, 0, .3)
                            end

                            f2.NXType = 2000
                            f2.NxTip = tip
                            f2.NXData = f.NXData

                        end
                    end

                    f.NxTip = tip
                    f.NxWidgetSet = widgetSet
                    f.NxAreaPoiID = areaPoiID
                    f.NxPoiInfo = zPOI  -- Store full POI info for tooltip

                    -- Set NXType for Quest Hub POIs (type 4000) to enable click handling
                    if atlasIcon and (atlasIcon == "poi-hub" or string.find(atlasIcon, "QuestHub") or string.find(atlasIcon, "questhub")) then
                        f.NXType = 4000
                        f.NXData = {
                            hubPoiID = areaPoiID,
                            mapID = rid,
                            linkedMapID = zPOI.linkedUiMapID,
                            name = name
                        }
                    end

                    -- Add methods for compatibility with Blizzard's AreaPoiUtil.TryShowTooltip
                    f.GetPoiInfo = function(self) return self.NxPoiInfo end
                    f.HasDisplayName = function(self)
                        local poi = self.NxPoiInfo
                        return poi and poi.name and poi.name ~= ""
                    end
                    f.GetDisplayName = function(self)
                        local poi = self.NxPoiInfo
                        return poi and poi.name or ""
                    end
                    f.GetLinkedUIMapID = function(self)
                        local poi = self.NxPoiInfo
                        return poi and poi.linkedUiMapID
                    end

                    -- Sentinax and Broken Shore bosses
                    if atlasIcon and (Nx.strpos(atlasIcon, 'DemonShip') == 1 or Nx.strpos(atlasIcon, 'DemonInvasion') == 1) then
                        pX, pY = self:GetWorldPos (self.MapId, pX, pY)
                        if self.ScaleDraw > 1 then
                            self:ClipFrameTL (f, pX-16, pY-16, 32 / self.ScaleDraw, 32 / self.ScaleDraw, 0)
                        else
                            self:ClipFrameTL (f, pX-16, pY-16, 32, 32, 0)
                        end
                        f.texture:SetAtlas(atlasIcon)
                    else
                        pX, pY = self:GetWorldPos(self.MapId, pX, pY)
                        -- Use ClipFrameWNoChop for all POI icons to avoid squishing at map edges
                        -- Parent frame clips overflow via SetClipsChildren(true)
                        local iconW = txW * self.ScaleDraw
                        local iconH = txH * self.ScaleDraw
                        if self:ClipFrameWNoChop(f, pX, pY, iconW, iconH) then
                            if atlasIcon then
                                f.texture:SetAtlas(atlasIcon)
                            else
                                f.texture:SetTexture ("Interface\\Minimap\\POIIcons")
                                txX1, txX2, txY1, txY2 = C_Minimap.GetPOITextureCoords (txIndex)
                                f.texture:SetTexCoord (txX1 + .003, txX2 - .003, txY1 + .003, txY2 - .003)
                                f.texture:SetVertexColor (1, 1, 1, 1)
                            end
                            if zPOI.facing then
                                f.texture:SetRotation(zPOI.facing)
                            end
                        end
                    end
                end
            end
        end
    end

    self.Level = oldLev + 4

    -- Update misc icons (herbs, ore, ...)
    -- Levels:
    --  +0 quest areas
    --  +1 quest area target
    --  +2-3 com players (++3 if alt key)
    --  +4 quest icons
    --  +5 ?

    Nx.HUD:Update (self)

    local comTrackName, comTrackX, comTrackY = Nx.Com:UpdateIcons (self)

    self.Level = self.Level + 2
    self.Guide:UpdateZonePOIIcons()
    for a,b in pairs(Nx.ModuleUpdateIcon) do
        if b ~= "test" then
            Nx[b]:UpdateIcons(self)
            self.Level = self.Level + 2
        end
    end

    -- Quest offer icons (available quests from quest lines)
    if Nx.Quest and Nx.Quest.UpdateQuestOfferIcons then
        Nx.Quest:UpdateQuestOfferIcons(self)
        self.Level = self.Level + 2
    end

    self:UpdateIcons (self.KillShow)

    -- Battlefield flags

    local fX, fY, fToken
    local flagNum = GetNumBattlefieldFlagPositions()

    for i = 1, flagNum do

        fX, fY, fToken = GetBattlefieldFlagPosition (i)

        if fX ~= 0 or fY ~= 0 then

            local f = self:GetIconNI()
            f.texture:SetTexture (fToken)
            self:ClipFrameZ (f, (fX or 0) * 100, (fY or 0) * 100, 36, 36, 0)
        end
    end

    self.Level = self.Level + 1

    -- Raid or party icons (AKA group)

    local palName, palX, palY = self:UpdateGroup (plX, plY)

    -- Tracking animation

    if self.PlyrSpeed == 0 then

--        self.ArrowPulse = self.ArrowPulse + .05
--        if self.ArrowPulse > cnt then
--            self.ArrowPulse = 1
--        end

        self.ArrowScroll = self.ArrowScroll + .01
        if self.ArrowScroll >= 1 then
            self.ArrowScroll = 0
        end
    end

    -- Corpse or target tracking

    self.TrackDir = false

    self.Guide:OnMapUpdate()    -- For closest target

    if #self.Targets > 0 then

        self:UpdateTargets()
        self:UpdateTracking()
        self.Level = self.Level + 2
    end

    self.TrackETA = false
    local cX, cY
    if C_Map.GetBestMapForUnit("player") then
      local CorpseInfo = C_DeathInfo.GetCorpseMapPosition(C_Map.GetBestMapForUnit("player"))
      if CorpseInfo then
          cX = CorpseInfo.x or 0
          cY = CorpseInfo.y or 0
      end
    end
    if cX == nil or cY == nil then
        cX = 0
        cY = 0
    end

    if (cX > 0 or cY > 0) and not inBG then    -- We dead, but not in BG?

        if Nx.db.profile.Track.ATCorpse then

            self.TrackName = "Corpse"

            local x, y = self:GetWorldPos (C_Map.GetBestMapForUnit("player"), cX * 100, cY * 100)
            self:DrawTracking (plX, plY, x, y, "D")

            local f = self:GetIcon (1)

            f.NxTip = "Your corpse"
            f.texture:SetTexture ("Interface\\Minimap\\POIIcons")
            self:ClipFrameZ (f, cX * 100, cY * 100, 16, 16, 0)
            -- Override clipping (FIX maybe?)
            f.texture:SetTexCoord (0.56640625, 0.6328125, 0.00390625, 0.0703125)    -- 16x16 grid (.0625 uv size)

            self.Level = self.Level + 2
        end

    elseif ontaxi and Map.TaxiX then

        if Nx.db.profile.Track.ATTaxi then

            self.TrackName = Map.TaxiName
            self.TrackETA = Map.TaxiETA

            local x, y = self.TaxiX, self.TaxiY
            self:DrawTracking (plX, plY, x, y, "F")

--            Nx.prt ("taxi %s %s", x, y)

            local f = self:GetIcon (1)

            f.NxTip = Map.TaxiName
            f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Ability_mount_wyvern_01")
            self:ClipFrameByMapType (f, x, y, 16, 16, 0)

            self.Level = self.Level + 2
        end
    end

    -- Battle ground or manual pal tracking

    if (palX or comTrackX) and (inBG or next (self.TrackPlyrs)) then

        if palX then

            self.TrackName = palName
            self:DrawTracking (plX, plY, palX, palY, "B")
        else
            self.TrackName = comTrackName
            self:DrawTracking (plX, plY, comTrackX, comTrackY)
        end

        self.Level = self.Level + 2
    end

    -- Set final levels

    self.TextScFrm:SetFrameLevel (self.Level)
    self.PlyrFrm:SetFrameLevel (self.Level + 1)

    self.ToolBar:SetLevels (self.Level + 2)

    self.Level = self.Level + 3

    self:MinimapUpdateEnd()        -- Uses 2 levels

    self.LocTipFrm:SetFrameLevel (self.Level + 2)

    -- Hide leftovers

    self:HideExtraIcons()

    -- Scan. Switch maps if needed. Do at end so we dont glitch

    if Nx.Tick % self.ScanContinentsMod == 3 then
        self:ScanContinents()
    end

    if doSetCurZone then
        self:SetToCurrentZone()
    end

    self.Frm:SetAlpha(self.BackgndAlpha)

    -- Debug
--[[
    Nx.prt ("Map WPos %s ZPos %s WScale %s", self.GetWorldPosCnt or 0, self.GetZonePosCnt or 0, self.GetWorldZoneScaleCnt or 0)
    self.GetWorldPosCnt = 0
    self.GetZonePosCnt = 0
    self.GetWorldZoneScaleCnt = 0
--]]

end

function Nx.Map:SetInstanceMap (mapId)
    self.InstMapId = nil
    if not mapId then
        return
    end
    local Map = Nx.Map
    local info = Map.InstanceInfo[mapId]

    if not(info) then
        Nx.Map:GetInstanceMapTextures(mapId)
        info=Map.InstanceInfo[mapId]
    end

    local sizex, sizey = 1002, 668
    if info then
        self:SetCurrentMap (mapId)
        self.InstMapId = mapId
        self.InstMapInfo = info
        local winfo = Map.MapWorldInfo[mapId]
        if winfo and winfo.BaseMap then
            winfo = Map.MapWorldInfo[winfo.BaseMap]
        end
        if winfo then
            local wx = winfo.X
            local wy = winfo.Y
            self.InstMapWX1 = wx
            self.InstMapWY1 = wy
            self.InstMapWX2 = wx + sizex / 256
            self.InstMapWY2 = wy + sizey / 256 * #info / 3
        end
    end
end

function Nx.Map:GetNumDungeonMapLevels()
    local maps = { GetNumDungeonMapLevels() }
    local first = GetNumDungeonMapLevels()
    if not first then
        if Nx.Map:GetCurrentMapDungeonLevel() == 0 then
            return 0,0
        end
        return 1, 1
    end
    local count = 0
    for _ in pairs(maps) do
        count = count + 1
    end
    return count, 1
end

function Nx.Map:GetInstanceMapTextures(mapId)
    local areaId = mapId
    if areaId then
        Nx.Map:SetMapByID(areaId)
        local mapName = C_Map.GetMapInfo(mapId).name:gsub('%W','')
--        local levels, first = Nx.Map:GetNumDungeonMapLevels()
--        local useTerrainMap = DungeonUsesTerrainMap()
        Nx.Map.InstanceInfo[mapId] = {}
        local fileName = mapName.."\\"..mapName;
        Nx.Map.InstanceInfo[mapId][4] = 0
        Nx.Map.InstanceInfo[mapId][5] = -100
        Nx.Map.InstanceInfo[mapId][6] = fileName
    end
end

--------
-- Switch to a new map
-- self = map

function Nx.Map:SwitchRealMap (id)
    if self:IsInstanceMap (id) then
        self:SetInstanceMap (id)            -- Turn it on

        self:GotoCurrentZone()
        --self:CenterMap (id)
        --[[local s = 100
        self.Scale = s
        self.RealScale = s
        self.StepTime = 10]]--
    else
        self:SetInstanceMap()                -- Turn it off
    end

    local map = Nx.Map:GetMap (1)
    map.Guide:UpdateMapIcons()
end
--------
-- Scan the continents for POI data

function Nx.Map:ScanContinents()

    Nx.Map.ScanContinentsMod = 500

    local oldCont = Nx.Map:GetCurrentMapContinent()
    if oldCont < 0 then
        return
    end

    --local oldZone = GetCurrentMapZone()
    local mapLvl = Nx.Map:GetCurrentMapDungeonLevel()
    local isMicroDungeon = Nx.Map:IsMicroDungeon(Nx.Map:GetCurrentMapAreaID())

--    Nx.prt ("ScanContinents cont zone, %s %s", oldCont, oldZone)

    --

    --ObjectiveTrackerFrame:UnregisterEvent ("WORLD_MAP_UPDATE")

    local hideT = {}
    hideT[0] = true    -- WotLK has 0 index POIs for named locations
    hideT[6] = not Nx.db.profile.Map.ShowCCity
    hideT[46] = not Nx.db.profile.Map.ShowCCity
    hideT[48] = not Nx.db.profile.Map.ShowCCity
    hideT[41] = not Nx.db.profile.Map.ShowCExtra
    hideT[5] = not Nx.db.profile.Map.ShowCTown

    for cont = 1, self.ContCnt do

        local poiT = {}
        self.ContPOIs[cont] = poiT

        --SetMapZoom (cont)
        local mapId = Nx.Map.MapZones[0][cont]

        local mapId2 = mapId

        if Nx.OldMapIDs then
            if mapId2 == 12 then mapId2 = 1414 end      -- Kalimdor
            if mapId2 == 13 then mapId2 = 1415 end      -- Eastern Kingdoms
        end

        local name, description, txIndex, pX, pY
        local txX1, txX2, txY1, txY2

        local areaPOIs = C_AreaPoiInfo.GetAreaPOIForMap(mapId2);
        -- Add Delves POIs to the list
        if C_AreaPoiInfo.GetDelvesForMap then
            local delvePOIs = C_AreaPoiInfo.GetDelvesForMap(mapId2) or {}
            for _, delveId in ipairs(delvePOIs) do
                tinsert(areaPOIs, delveId)
            end
        end
        -- Add Quest Hubs POIs to the list
        if C_AreaPoiInfo.GetQuestHubsForMap then
            local hubPOIs = C_AreaPoiInfo.GetQuestHubsForMap(mapId2) or {}
            for _, hubId in ipairs(hubPOIs) do
                tinsert(areaPOIs, hubId)
            end
        end
        -- Add Dragonriding Races POIs to the list
        if C_AreaPoiInfo.GetDragonridingRacesForMap then
            local racePOIs = C_AreaPoiInfo.GetDragonridingRacesForMap(mapId2) or {}
            for _, raceId in ipairs(racePOIs) do
                tinsert(areaPOIs, raceId)
            end
        end
        -- Add Events POIs to the list
        if C_AreaPoiInfo.GetEventsForMap then
            local eventPOIs = C_AreaPoiInfo.GetEventsForMap(mapId2) or {}
            for _, eventId in ipairs(eventPOIs) do
                tinsert(areaPOIs, eventId)
            end
        end
        for i, areaPoiID in ipairs(areaPOIs) do
            -- type, name, desc, txIndex, pX, pY = C_WorldMap.GetMapLandmarkInfo (n)
            local cPOI = C_AreaPoiInfo.GetAreaPOIInfo(mapId2, areaPoiID)
            name = cPOI.name
            txIndex = cPOI.textureIndex
            pX = cPOI.position.x
            pY = cPOI.position.y

            if pX and name and not hideT[txIndex] then

                local poi = {}
                tinsert (poiT, poi)
                poi.Name = name
                poi.Desc = desc
                poi.TxIndex = txIndex
                if cPOI.atlasName then
                    poi.atlasIcon = cPOI.atlasName
                end

                local x, y = self:GetWorldPos (mapId, pX * 100, pY * 100)
                poi.WX = x
                poi.WY = y
            end
        end
    end

    --
--[[
    local members = MAX_PARTY_MEMBERS
    local unitName = "party"
    local raid

    if IsInRaid() > 0 then
        members = MAX_RAID_MEMBERS
        unitName = "raid"
        raid = true
    end

    local pals = Nx.Com.PalNames
    local palName
    local palDist = 99999999
    local palX, palY
    local combatName
    local combatUnit
    local combatHealth
    local combatDist = 99999999
    local combatX, combatY

    local palsInfo = Nx.Com.PalsInfo

    for i = 1, members do

        local unit = unitName .. i
        local name, unitRealm = UnitName (unit)

        local mapId = self.MapId

        local pX, pY = Nx.GetPlayerMapPosition (unit)
        if pX <= 0 and pY <= 0 then

            local info = palsInfo[name]
            if info and info.EntryMId == mapId then
                mapId = info.MId
                pX = info.X + .00001
                pY = info.Y
            end

        else
            pX = pX * 100
            pY = pY * 100
        end

        if (pX ~= 0 or pY ~= 0) and not UnitIsUnit (unit, "player") then

            local fullName = unitRealm and (name .. "-" .. unitRealm) or name

            local wx, wy = self:GetWorldPos (mapId, pX, pY)

        end
    end
--]]
    -- Restore

    if(isMicroDungeon)then
        Nx.Map:SetToCurrentZone()
    else
        --SetMapZoom (oldCont, oldZone)
        --SetDungeonMapLevel (mapLvl)
    end

    --ObjectiveTrackerFrame:RegisterEvent ("WORLD_MAP_UPDATE")
end

function Nx.Map:GetAreaPOIs(mapId)
    local areaPOIs = C_AreaPoiInfo.GetAreaPOIForMap(mapId);
    -- Add Delves POIs to the list
    if C_AreaPoiInfo.GetDelvesForMap then
        local delvePOIs = C_AreaPoiInfo.GetDelvesForMap(mapId) or {}
        for _, delveId in ipairs(delvePOIs) do
            tinsert(areaPOIs, delveId)
        end
    end
    -- Add Quest Hubs POIs to the list
    if C_AreaPoiInfo.GetQuestHubsForMap then
        local hubPOIs = C_AreaPoiInfo.GetQuestHubsForMap(mapId) or {}
        for _, hubId in ipairs(hubPOIs) do
            tinsert(areaPOIs, hubId)
        end
    end
    -- Add Dragonriding Races POIs to the list
    if C_AreaPoiInfo.GetDragonridingRacesForMap then
        local racePOIs = C_AreaPoiInfo.GetDragonridingRacesForMap(mapId) or {}
        for _, raceId in ipairs(racePOIs) do
            tinsert(areaPOIs, raceId)
        end
    end
    -- Add Events POIs to the list
    if C_AreaPoiInfo.GetEventsForMap then
        local eventPOIs = C_AreaPoiInfo.GetEventsForMap(mapId) or {}
        for _, eventId in ipairs(eventPOIs) do
            tinsert(areaPOIs, eventId)
        end
    end
    for i, areaPoiID in ipairs(areaPOIs) do
        local cPOI = C_AreaPoiInfo.GetAreaPOIInfo(mapId, areaPoiID)
        areaPOIs[i] = cPOI
    end
    return areaPOIs
end

--------
-- Draw the continents POI data

function Nx.Map:DrawContinentsPOIs()

    if self.ScaleDraw > self.LOpts.NXPOIAtScale then

        if not Nx.db.char.Map.ShowGatherA then
            return
        end
    end

    if not Nx.db.char.Map.ShowContPois then
        return
    end

    local getCoords = C_Minimap.GetPOITextureCoords

    for cont = 1, self.ContCnt do

        for k, poi in ipairs (self.ContPOIs[cont]) do
            local txi = poi.TxIndex
            local z = txi == 177 and 13 or 3

            local f = self:GetIcon (z)

            if self:ClipFrameByMapType (f, poi.WX, poi.WY, 16, 16, 0) then

                f.NxTip = poi.Name             --.. poi.TxIndex

                -- 1 2
                -- 4 3

                local t1x, t1y, t4x, t4y, t2x = f.texture:GetTexCoord()

                f.texture:SetTexture ("Interface\\Minimap\\POIIcons")
                local txX1, txX2, txY1, txY2 = getCoords (txi)
--                f.texture:SetTexCoord (txX1 + .003, txX2 - .003, txY1 + .003, txY2 - .003)

                local x = txX1 + .003
                local y = txY1 + .003
                local w = txX2 - .003 - x
                local h = txY2 - .003 - y
                f.texture:SetTexCoord (x + w * t1x, x + w * t2x,
                            y + h * t1y, y + h * t4y)

--                Nx.prtCtrl ("%s %s %s %s %s %s", t1x, t1y, t4x, t4y, t2x, t2y)
            end
        end
    end

    self.Level = self.Level + 1
end

--------
-- Garrison plot cache (avoid API calls and coordinate conversions every frame)
local GarrisonPlotCache = {
    plots = {},           -- [mapId] = cached plot data with world coords
    lastCheck = {},       -- [mapId] = GetTime() of last check
}

-- Get cached garrison plots (only refresh every 5 seconds)
local function GetCachedGarrisonPlots(map, mapId)
    local now = GetTime()
    local lastCheck = GarrisonPlotCache.lastCheck[mapId] or 0

    -- Only refresh garrison plots every 5 seconds (plot data doesn't change often)
    if (now - lastCheck) < 5 and GarrisonPlotCache.plots[mapId] then
        return GarrisonPlotCache.plots[mapId]
    end

    -- Check if the API exists
    if not C_Garrison or not C_Garrison.GetGarrisonPlotsInstancesForMap then
        return nil
    end

    -- Get the garrison plots for current map
    local plots = C_Garrison.GetGarrisonPlotsInstancesForMap(mapId)
    if not plots or #plots == 0 then
        return nil
    end

    -- Pre-calculate world coordinates for each plot
    local cachedPlots = {}
    for _, plot in ipairs(plots) do
        if plot.position and plot.atlasName then
            -- Convert position (0-1 range) to zone coordinates (0-100 range)
            local zoneX = plot.position.x * 100
            local zoneY = plot.position.y * 100
            -- Convert to world coordinates
            local wx, wy = map:GetWorldPos(mapId, zoneX, zoneY)

            cachedPlots[#cachedPlots + 1] = {
                wx = wx,
                wy = wy,
                name = plot.name or "Garrison Plot",
                atlasName = plot.atlasName,
            }
        end
    end

    GarrisonPlotCache.plots[mapId] = cachedPlots
    GarrisonPlotCache.lastCheck[mapId] = now
    return cachedPlots
end

--------
-- Draw garrison plot icons
-- Uses C_Garrison.GetGarrisonPlotsInstancesForMap to get plot positions and textures

function Nx.Map:DrawGarrisonPlots()
    -- Only draw in garrison maps
    local mapId = self.MapId
    local wzone = self:GetWorldZone(mapId)
    if not wzone or not wzone.Garrison then
        return
    end

    -- Get cached garrison plots (refreshes every 5 seconds)
    local plots = GetCachedGarrisonPlots(self, mapId)
    if not plots then
        return
    end

    -- Pre-calculate icon size outside the loop
    local iconSize = 8 * self.ScaleDraw

    -- Draw each plot icon using cached world coordinates
    for _, plot in ipairs(plots) do
        -- Get an icon frame
        local f = self:GetIcon(3)

        -- Position and display the icon
        -- Use ClipFrameWNoChop to let parent frame clip the icon at edges
        if self:ClipFrameWNoChop(f, plot.wx, plot.wy, iconSize, iconSize) then
            -- Set tooltip to plot name
            f.NxTip = plot.name

            -- Use atlas texture for the icon
            if f.texture.SetAtlas then
                f.texture:SetAtlas(plot.atlasName, true)
                f.texture:SetTexCoord(0, 1, 0, 1)  -- Reset tex coords for atlas
            end
        end
    end

    self.Level = self.Level + 1
end

--------
-- Draw group (raid or party)
-- (player world pos)

function Nx.Map:UpdateGroup(plX, plY)
    local Nx = Nx
    local Map = Nx.Map

    local function IsNumber(v)
        return type(v) == "number"
    end

    local function Clamp(v, lo, hi)
        if v < lo then
            return lo
        end
        if v > hi then
            return hi
        end
        return v
    end

    local function UnitTokenExists(unit)
        return type(unit) == "string" and unit ~= "" and UnitExists(unit)
    end

    local function GetUnitFullName(unit)
        if not UnitTokenExists(unit) then
            return nil
        end

        local name, realm = UnitName(unit)
        if not name or name == "" then
            return nil
        end

        if realm and realm ~= "" then
            return name .. "-" .. realm
        end

        return name
    end

    local function IsUnitDead(unit)
        if not UnitTokenExists(unit) then
            return false
        end

        return UnitIsDeadOrGhost(unit) and true or false
    end

    local function GetClassColor(unit)
        local _, classTag = UnitClass(unit)
        if classTag and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag] then
            local c = RAID_CLASS_COLORS[classTag]
            return c.r or 1, c.g or 1, c.b or 1, classTag
        end

        return 1, 1, 1, nil
    end

    local function GetMapPos(unit)
        if not UnitTokenExists(unit) then
            return nil, nil, nil
        end

        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local mapId = C_Map.GetBestMapForUnit(unit)
            if mapId then
                local pos = C_Map.GetPlayerMapPosition(mapId, unit)
                if pos then
                    local px, py = pos:GetXY()
                    if IsNumber(px) and IsNumber(py) then
                        return mapId, px, py
                    end
                end
            end
        end

        return nil, nil, nil
    end

    local function GetWorldPosFromMap(unit)
        local mapId, px, py = GetMapPos(unit)
        if not mapId or not px or not py then
            return nil, nil, nil, nil, nil
        end

        if type(Map.GetWorldPos) == "function" then
            local ok, wx, wy = pcall(Map.GetWorldPos, Map, mapId, px * 100, py * 100)
            if ok and IsNumber(wx) and IsNumber(wy) then
                return mapId, px, py, wx, wy
            end
        end

        if type(Map.GetWorldPos2) == "function" then
            local ok, wx, wy = pcall(Map.GetWorldPos2, Map, mapId, px * 100, py * 100)
            if ok and IsNumber(wx) and IsNumber(wy) then
                return mapId, px, py, wx, wy
            end
        end

        return mapId, px, py, px * 100, py * 100
    end

    local function GetDistance(wx, wy)
        if not IsNumber(plX) or not IsNumber(plY) or not IsNumber(wx) or not IsNumber(wy) then
            return 99999999
        end

        local dx = wx - plX
        local dy = wy - plY
        return sqrt(dx * dx + dy * dy)
    end

    local alt = IsAltKeyDown and IsAltKeyDown() or false
    local redGlow = 1
    local members = 0
    local unitName = "party"
    local raid = IsInRaid and IsInRaid() or false

    local pals = self.TrackPlyrs or {}
    local palName = nil
    local palDist = 99999999
    local palX = nil
    local palY = nil

    local combatName = nil
    local combatUnit = nil
    local combatHealth = nil
    local combatDist = 99999999
    local combatX = nil
    local combatY = nil

    local palsInfo = {}

    self.TrackPlyrs = self.TrackPlyrs or {}
    self.PalsInfo = self.PalsInfo or {}
    self.GroupInfo = self.GroupInfo or {}

    if raid then
        members = GetNumGroupMembers and (GetNumGroupMembers() or 0) or 0
        unitName = "raid"
    else
        members = GetNumSubgroupMembers and (GetNumSubgroupMembers() or 0) or 0
        unitName = "party"
    end

    do
        local fullName = GetUnitFullName("player")
        local key = "player"

        if fullName then
            local _, px, py, wx, wy = GetWorldPosFromMap("player")
            local healthPer
            local r, g, b, cls = GetClassColor("player")

            if IsUnitDead("player") then
                healthPer = 0
            elseif type(UnitHealthPercent) == "function" then
                local ok, per = pcall(UnitHealthPercent, "player")
                if ok and per ~= nil then
                    if type(issecretvalue) ~= "function" or not issecretvalue(per) then
                        if type(per) == "number" then
                            if per > 1 then
                                per = per / 100
                            end

                            if per < 0 then
                                per = 0
                            elseif per > 1 then
                                per = 1
                            end

                            healthPer = per
                        end
                    end
                end
            else
                local okH, h = pcall(UnitHealth, "player")
                local okM, m = pcall(UnitHealthMax, "player")

                if okH and okM and h ~= nil and m ~= nil then
                    if (type(issecretvalue) ~= "function" or not issecretvalue(h)) and
                       (type(issecretvalue) ~= "function" or not issecretvalue(m)) and
                       type(h) == "number" and type(m) == "number" and m > 0 then
                        healthPer = h / m

                        if healthPer < 0 then
                            healthPer = 0
                        elseif healthPer > 1 then
                            healthPer = 1
                        end
                    end
                end
            end

            self.GroupInfo[key] = self.GroupInfo[key] or {}
            local info = self.GroupInfo[key]

            info.Unit = "player"
            info.Name = fullName
            info.X = wx
            info.Y = wy
            info.MapX = px
            info.MapY = py
            info.InCombat = UnitAffectingCombat("player") and true or false
            info.HealthPer = healthPer or 1
            info.Health = nil
            info.HealthMax = nil
            info.Class = cls
            info.CR = r
            info.CG = g
            info.CB = b
            info.Dead = IsUnitDead("player")
            info.IsPlayer = true
        end
    end

    for i = 1, members do
        local unit = unitName .. i

        if UnitTokenExists(unit) and UnitIsConnected(unit) and not UnitIsUnit(unit, "player") then
            local name = UnitName(unit)
            local fullName = GetUnitFullName(unit)
            local key = unit

            if name and fullName then
                local mapId, pX, pY, wx, wy = GetWorldPosFromMap(unit)
                local sz = 18
                local r, g, b, cls = GetClassColor(unit)
                local inCombat = UnitAffectingCombat(unit) and true or false
                local healthPer
                local dist = GetDistance(wx, wy)

                if IsUnitDead(unit) then
                    healthPer = 0
                elseif type(UnitHealthPercent) == "function" then
                    local ok, per = pcall(UnitHealthPercent, unit)
                    if ok and per ~= nil then
                        if type(issecretvalue) ~= "function" or not issecretvalue(per) then
                            if type(per) == "number" then
                                if per > 1 then
                                    per = per / 100
                                end

                                if per < 0 then
                                    per = 0
                                elseif per > 1 then
                                    per = 1
                                end

                                healthPer = per
                            end
                        end
                    end
                else
                    local okH, h = pcall(UnitHealth, unit)
                    local okM, m = pcall(UnitHealthMax, unit)

                    if okH and okM and h ~= nil and m ~= nil then
                        if (type(issecretvalue) ~= "function" or not issecretvalue(h)) and
                           (type(issecretvalue) ~= "function" or not issecretvalue(m)) and
                           type(h) == "number" and type(m) == "number" and m > 0 then
                            healthPer = h / m

                            if healthPer < 0 then
                                healthPer = 0
                            elseif healthPer > 1 then
                                healthPer = 1
                            end
                        end
                    end
                end

                if healthPer == nil then
                    healthPer = 1
                end

                if healthPer < redGlow then
                    redGlow = healthPer
                end

                self.GroupInfo[key] = self.GroupInfo[key] or {}
                local info = self.GroupInfo[key]

                info.Unit = unit
                info.Name = fullName
                info.MapId = mapId or self.MapId
                info.MapX = pX
                info.MapY = pY
                info.X = wx
                info.Y = wy
                info.Size = sz
                info.Class = cls
                info.CR = r
                info.CG = g
                info.CB = b
                info.InCombat = inCombat
                info.HealthPer = healthPer
                info.Health = nil
                info.HealthMax = nil
                info.Dead = IsUnitDead(unit)
                info.Distance = dist
                info.IsPlayer = false

                palsInfo[key] = true

                if (pals[key] or pals[fullName]) and dist < palDist then
                    palName = fullName
                    palDist = dist
                    palX = wx
                    palY = wy
                end

                if inCombat and dist < combatDist then
                    combatName = fullName
                    combatUnit = unit
                    combatDist = dist
                    combatHealth = healthPer
                    combatX = wx
                    combatY = wy
                end
            end
        end
    end

    if UnitTokenExists("pet") then
        local fullName = GetUnitFullName("pet")
        local key = "pet"

        if fullName then
            local mapId, pX, pY, wx, wy = GetWorldPosFromMap("pet")
            local healthPer

            if IsUnitDead("pet") then
                healthPer = 0
            elseif type(UnitHealthPercent) == "function" then
                local ok, per = pcall(UnitHealthPercent, "pet")
                if ok and per ~= nil then
                    if type(issecretvalue) ~= "function" or not issecretvalue(per) then
                        if type(per) == "number" then
                            if per > 1 then
                                per = per / 100
                            end

                            if per < 0 then
                                per = 0
                            elseif per > 1 then
                                per = 1
                            end

                            healthPer = per
                        end
                    end
                end
            else
                local okH, h = pcall(UnitHealth, "pet")
                local okM, m = pcall(UnitHealthMax, "pet")

                if okH and okM and h ~= nil and m ~= nil then
                    if (type(issecretvalue) ~= "function" or not issecretvalue(h)) and
                       (type(issecretvalue) ~= "function" or not issecretvalue(m)) and
                       type(h) == "number" and type(m) == "number" and m > 0 then
                        healthPer = h / m

                        if healthPer < 0 then
                            healthPer = 0
                        elseif healthPer > 1 then
                            healthPer = 1
                        end
                    end
                end
            end

            self.GroupInfo[key] = self.GroupInfo[key] or {}
            local info = self.GroupInfo[key]

            info.Unit = "pet"
            info.Name = fullName
            info.MapId = mapId or self.MapId
            info.MapX = pX
            info.MapY = pY
            info.X = wx
            info.Y = wy
            info.HealthPer = healthPer or 1
            info.Health = nil
            info.HealthMax = nil
            info.InCombat = UnitAffectingCombat("pet") and true or false
            info.Dead = IsUnitDead("pet")
            info.IsPet = true
        end
    end

    self.PalsInfo = palsInfo
    self.NearPalName = palName
    self.NearPalX = palX
    self.NearPalY = palY
    self.NearPalDist = palDist

    self.NearCombatName = combatName
    self.NearCombatUnit = combatUnit
    self.NearCombatX = combatX
    self.NearCombatY = combatY
    self.NearCombatDist = combatDist
    self.NearCombatHealth = combatHealth

    self.GroupRedGlow = 1 - Clamp(redGlow or 1, 0, 1)

    -- Draw group member icons on map
    if not alt then
        local pals = Nx.Com.PalNames or {}
        local sc = self.ScaleDraw

        for i = 1, members do
            local unit = unitName .. i
            local info = self.GroupInfo[unit]

            if info and info.X and info.Y then
                local wx, wy = info.X, info.Y
                local fullName = info.Name
                local name = fullName and fullName:match("^([^%-]+)") or fullName
                local per = info.HealthPer or 1
                local inCombat = info.InCombat

                local sz = 16 * (self.DotRaidScale or 1)
                if UnitExists(unit) and UnitInParty(unit) then
                    sz = 18 * (self.DotPartyScale or 1)
                end
                if name and (pals[name] ~= nil or (self.TrackPlyrs and self.TrackPlyrs[name])) then
                    sz = 20 * (self.DotPalScale or 1)
                    if self.TrackPlyrs and self.TrackPlyrs[name] then
                        sz = 25 * (self.DotPalScale or 1)
                    end
                end

                local f1 = self:GetIcon(1)
                if self:ClipFrameByMapType(f1, wx, wy, sz, sz, 0) then
                    f1.NXType = 1000
                    f1.NXData = unit
                    f1.NXData2 = fullName

                    local txName = "IconPlyrP"
                    if name then
                        if pals[name] == false then
                            txName = "IconPlyrF"
                        elseif pals[name] == true then
                            txName = "IconPlyrG"
                        end
                    end
                    if inCombat then
                        txName = txName .. "C"
                    end
                    f1.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\" .. txName)

                    -- Health bar
                    local f = self:GetIconNI(2)
                    if per > .33 then
                        self:ClipFrameTL(f, wx - 9 / sc, wy - 10 / sc, 16 * per / sc, 1 / sc)
                        f.texture:SetColorTexture(1, 1, 1, 1)
                    else
                        self:ClipFrameByMapType(f, wx, wy, 7, 7, 0)
                        if per > 0 then
                            f.texture:SetColorTexture(1, .1, .1, 1 - per * 2)
                        else
                            f.texture:SetColorTexture(0, 0, 0, .5)
                        end
                    end

                    -- Tooltip
                    local lvl = UnitExists(unit) and (UnitLevel(unit) or 0) or 0
                    local clsDisplay = (UnitExists(unit) and UnitClass(unit)) or (info.Class or "")
                    local pX = (info.MapX or 0) * 100
                    local pY = (info.MapY or 0) * 100
                    local qStr = Nx.Com and Nx.Com.GetPlyrQStr and Nx.Com:GetPlyrQStr(name) or ""
                    if raid and UnitExists(unit) then
                        local _, _, grp = GetRaidRosterInfo(i)
                        if grp then
                            clsDisplay = clsDisplay .. " G" .. grp
                        end
                    end
                    f1.NxTip = format("%s %d %s %d%%\n(%d,%d)%s", fullName, lvl, clsDisplay, per * 100, pX, pY, qStr or "")
                end
            end
        end
    end

    self.Level = self.Level + 3

    -- Return tracking info for pal/combat tracking
    if palName and Nx.db.profile.Track.ATBGPal then
        if not combatName or combatDist > palDist then
            self.TrackPlayer = palName
            return palName, palX, palY
        end
    end

    if combatName then
        if not self.InCombat or combatDist > 35 then
            self.TrackPlayer = combatName
            return format("Combat, %s %d%%", combatName, combatHealth * 100), combatX, combatY
        end
    end
end

--------
-- Draw player position history

function Nx.Map:UpdatePlyrHistory()

    local Map = Nx.Map            -- Use global map
    local hist = Map.PlyrHist

    local tm = GetTime()

    local scale = self.BaseScale
    local usezone = nil

    local x = hist.LastX - self.MoveLastX
    local y = hist.LastY - self.MoveLastY

    if (self:IsInstanceMap(Nx.Map.UpdateMapID) or self:IsBattleGroundMap(Nx.Map.UpdateMapID)) and self.CurOpts.NXInstanceMaps then
        local _x1, _y1 = self:GetZonePos(Nx.Map.UpdateMapID,hist.LastX,hist.LastY)
        local _x2, _y2 = self:GetZonePos(Nx.Map.UpdateMapID,self.MoveLastX,self.MoveLastY)
        x = _x1 - _x2
        y = _y1 - _y2
        scale = 1
    end

    local moveDist = (x * x + y * y) ^ .5

    if moveDist > Nx.db.profile.Map.TrailDist * scale then

        hist.LastX = self.MoveLastX
        hist.LastY = self.MoveLastY

        hist.Time = tm

        local next = hist.Next
        local o = next * 4 - 3

        hist[o] = GetTime()
        hist[o + 1] = self.PlyrX
        hist[o + 2] = self.PlyrY
        hist[o + 3] = self.PlyrDir

        if next >= hist.Cnt then
            next = 0
        end

        hist.Next = next + 1
    end

    local size = min (max (4 * self.ScaleDraw * self.BaseScale, 3), 25)
    local fadeTime = Nx.db.profile.Map.TrailTime
    for n = 1, hist.Cnt * 4, 4 do

        local secs = hist[n]
        local tmdif = tm - secs

        if tmdif < fadeTime then

            local x = hist[n + 1]
            local y = hist[n + 2]
            local dir = hist[n + 3]

            local f = self:GetIconNI()

            if self:ClipFrameByMapType (f, x, y, size, size, dir) then
                f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconCircleFade")
                local a = (fadeTime - tmdif) / fadeTime * .9
                f.texture:SetVertexColor (1, 0, 0, a)
            end

        end
    end
end

-------------------------------------------------------------------------------
-- TARGET AND TRACKING SYSTEM
-- Manages waypoint targets and tracking arrows
-------------------------------------------------------------------------------

---
-- Update waypoint targets, checking if player has reached them
--
function Nx.Map:UpdateTargets()
    local delay = self.UpdateTargetDelay
    if delay > 0 then
        self.UpdateTargetDelay = delay - 1
        return
    end

    local tar = self.Targets[1]

    -- Calculate distance to target
    local x = tar.TargetMX - self.PlyrX
    local y = tar.TargetMY - self.PlyrY

    local distYd = (x * x + y * y) ^ .5 * 4.575

    -- Use zone-relative coordinates for instances/BGs
    if (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
        local _x1, _y1 = self:GetZonePos(Nx.Map.RMapId, tar.TargetMX, tar.TargetMY)
        local _x2, _y2 = self:GetZonePos(Nx.Map.RMapId, self.PlyrX, self.PlyrY)
        x = _x1 - _x2
        y = _y1 - _y2
        distYd = (x * x + y * y) ^ .5
    end

    -- Check if player has reached target
    if distYd < (tar.Radius or 7) * self.BaseScale then
        -- Don't auto-clear quest targets
        if tar.TargetType ~= "Q" then
            self.UpdateTargetDelay = 20
            self.UpdateTrackingDelay = 0

            -- Remove target from list
            tremove(self.Targets, 1)

            -- Recycle targets if enabled
            if #self.Targets > 0 and Nx.db.profile.Route.Recycle then
                tinsert(self.Targets, tar)
            end

            -- Play sound if enabled
            if Nx.db.profile.Track.TSoundOn then
                Nx:PlaySoundFile(567455)
            end

            -- Notify player
            UIErrorsFrame:AddMessage("Target " .. tar.TargetName .. " reached", 1, 1, 1, 1)

            self.Guide:ClearAll()

            -- Call radius callback if present
            if tar.RadiusFunc then
                tar.RadiusFunc("distance", tar.UniqueId, tar.Radius, distYd, distYd)
                tar.RadiusFunc = nil
            end
        end
    end
end

---
-- Update tracking display (arrows and lines to targets)
--
function Nx.Map:UpdateTracking()
    local delay = self.UpdateTrackingDelay - 1

    -- Recalculate tracking path periodically
    if delay <= 0 then
        self:CalcTracking()
        delay = 45
    end

    self.UpdateTrackingDelay = delay

    self.Level = self.Level + 2

    local dist1
    local dir1

    local srcX = self.PlyrX
    local srcY = self.PlyrY

    -- Draw tracking for each waypoint in sequence
    for n = 1, #self.Tracking do
        local tr = self.Tracking[n]

        self:DrawTracking(srcX, srcY, tr.TargetMX, tr.TargetMY, tr.Mode, tr)

        -- Store first target's tracking info
        if n == 1 then
            self.TrackName = tr.TargetName
            dist1 = self.TrackDistYd
            dir1 = self.TrackDir
        end

        -- Chain from this target to next
        srcX = tr.TargetMX
        srcY = tr.TargetMY
    end

    self.TrackDistYd = dist1
    self.TrackDir = dir1
end

---
-- Calculate tracking path through all targets
-- Uses Travel system for path optimization
--
function Nx.Map:CalcTracking()
    local Travel = Nx.Travel

    local tr = {}
    self.Tracking = tr

    local srcX = self.PlyrX
    local srcY = self.PlyrY
    local srcMapId = MapUtil.GetDisplayableMapForPlayer()

    -- Build path through all targets
    for n, tar in ipairs(self.Targets) do
        Travel:MakePath(tr, srcMapId, srcX, srcY, tar.MapId, tar.TargetMX, tar.TargetMY, tar.TargetType)

        tinsert(tr, tar)

        srcX = tar.TargetMX
        srcY = tar.TargetMY
        srcMapId = tar.MapId
    end
end

---
-- Format large distances with k/m suffixes
-- @param n  Distance value
-- @return   Formatted string
--
local function shortendistance(n)
    if n >= 10 ^ 6 then
        return string.format("%.2fm", n / 10 ^ 6)
    elseif n >= 10 ^ 3 then
        return string.format("%.2fk", n / 10 ^ 3)
    else
        return tostring(n)
    end
end

---
-- Draw tracking arrows and destination icon
-- @param srcX    Source X position
-- @param srcY    Source Y position
-- @param dstX    Destination X position
-- @param dstY    Destination Y position
-- @param mode    Arrow color mode ("B"=blue, "F"=yellow, "D"=red)
-- @param target  Target data table
--
function Nx.Map:DrawTracking(srcX, srcY, dstX, dstY, mode, target)

    local x = dstX - srcX
    local y = dstY - srcY

    local dist = (x * x + y * y) ^ .5
    self.TrackDistYd = dist * 4.575

    if target then
        local f = self:GetIcon (1)
        f.NxTarget = target;
        target.dist = dist;

        -- Disable mouse so this overlay marker doesn't eat clicks meant
        -- for the underlying quest icon. The goto-target marker sits at
        -- the destination, which is exactly where the user wants to
        -- click again to toggle the quest off.
        f:EnableMouse(false)

        local size = 16 * self.IconNavScale
        self:ClipFrameByMapType (f, dstX, dstY, size, size, 0)

        if target.TargetDisplayID then
            SetPortraitTextureFromCreatureDisplayID(f.texture, target.TargetDisplayID)
        else
            f.texture:SetTexture (target.TargetTex or "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconWayTarget")
        end
    end

    self.TrackDir = false

    if 1 then

        local dir = math.deg (math.atan2 (y, x)) + 90

        self.TrackDir = dir

        local sx = self.ScaleDraw
        local sy = self.ScaleDraw / 1.5

        x = x * sx
        y = y * sy

        -- Offset toward target
--        local off = 1 / sqrt (x * x + y * y)
--        local xo = x * off
--        local yo = y * off

        local cnt = (x * x + y * y) ^ .5 / 15 / self.IconNavScale
        if cnt < 5 then
            cnt = cnt + .5
        end
        cnt = min (floor (cnt), 40)

        if cnt >= 1 then

            local dx = x / cnt
            local dy = y / cnt

            local offset = self.ArrowScroll
            x = dx * offset
            y = dy * offset

            local size = 16 * self.IconNavScale
--            local pulse = floor (self.ArrowPulse)
            local usedIcon = true
            local f

            for n = 1, cnt do

                local wx = srcX + x / sx
                local wy = srcY + y / sy

--[[            -- Needed if we use an offset
                if n >= cnt then
                    if sqrt ((wx - srcX) ^ 2 + (wy - plY) ^ 2) > dist then
                        Nx.prt ("Target arrow")
                        break
                    end
                end
--]]
                if usedIcon then
                    usedIcon = false
                    f = self:GetIconNI()
                end

                if self:ClipFrameByMapType (f, wx, wy, size, size, dir) then

                    f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconArrowGrad")

--                    local a = n == pulse and .8 or .2
--                    f.texture:SetVertexColor (1, 1, 1, a)

                    if mode == "B" then
                        f.texture:SetVertexColor (.7, .7, 1, .5)
                    elseif mode == "F" then
                        f.texture:SetVertexColor (1, 1, 0, .9)
                    elseif mode == "D" then
                        f.texture:SetVertexColor (1, 0, 0, 1)
                    end

                    usedIcon = true
                end

                x = x + dx
                y = y + dy
            end
        end
    end
end

-------------------------------------------------------------------------------
-- CONTINENT AND WORLD MAP RENDERING
-------------------------------------------------------------------------------

---
-- Move and display continent map tiles
-- Shows world map background when enabled in options
--
function Nx.Map:MoveContinents()
    -- Skip continent tiles for instance maps with NXInstanceMaps enabled
    -- These maps are rendered via MoveWorldMap instead
    local isInstanceWithOverlay = (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps

    if self.CurOpts and self.CurOpts.NXWorldShow and not isInstanceWithOverlay then
        -- Draw all continent tiles
        for contN = 1, Nx.Map.ContCnt do
            local lvl = contN <= 2 and self.Level or self.Level + 1

            -- Special handling for certain continents
            if contN == 12 then
                lvl = 6
                self.Level = self.Level + 6
            end

            self:MoveZoneTiles(contN, 0, self.ContFrms[contN], self.WorldAlpha, lvl)
        end

        -- Draw fill frame (ocean background)
        local f = self.ContFillFrm
        if f then
            if Nx.V30 then
                self:ClipFrameTL(f, 1600, -1600, 1500, 4400, 0)
            else
                self:ClipFrameTL(f, 1600, -1900, 1500, 4650, 0)
            end
            f:SetFrameLevel(self.Level + 1)
            f:SetAlpha(self.WorldAlpha)
        end

        self.Level = self.Level + 2
    else
        -- Hide all continent tiles
        local frms, frm

        for contN = 1, Nx.Map.ContCnt do
            frms = self.ContFrms[contN]
            local numtiles = 12

            -- Some continents have different tile counts
            if self.MapInfo[contN].TileX and self.MapInfo[contN].TileY then
                numtiles = self.MapInfo[contN].TileX * self.MapInfo[contN].TileY
            end

            for i = 1, numtiles do
                frm = frms[i]
                if frm then
                    frm:Hide()
                end
            end
        end

        if self.ContFillFrm then
            self.ContFillFrm:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- WORLD ZONE HOTSPOT DETECTION
-- Detects which zone the cursor is over
-------------------------------------------------------------------------------

---
-- Check if cursor is over a world zone hotspot
-- Updates current map display based on cursor position
-- @param wx  World X coordinate
-- @param wy  World Y coordinate
--
function Nx.Map:CheckWorldHotspots(wx, wy)
    -- Alt key disables hotspot detection
    if IsAltKeyDown() then
        return
    end

    -- Check if over instance map overlay
    if self.InstMapId then
        if wx >= self.InstMapWX1 and wx <= self.InstMapWX2 and wy >= self.InstMapWY1 and wy <= self.InstMapWY2 then
            local lvl = floor((wy - self.InstMapWY1) / 668 * 256) + 1

            if self.InstMapId ~= self.MapId then
                self:SetCurrentMap(self.InstMapId)
            end

            self.InstLevelSet = -1
            self.WorldHotspotTipStr = self:IdToName(self.InstMapId) .. "\n"

            return
        end
    end

    local quad1 = self.WorldHotspotsCity
    local quad2 = self.WorldHotspots

    if self.NXCitiesUnder then
        quad1, quad2 = quad2, quad1
    end

    if self:CheckWorldHotspotsType (wx, wy, quad1) then
        return
    end

    if self:CheckWorldHotspotsType (wx, wy, quad2) then
        return
    end

    self.WorldHotspotTipStr = false

--    local tt = GameTooltip
--    if tt:IsOwned (self.Win.Frm) and self.TooltipType == 1 then
--        tt:Hide()
--    end
end

--------
-- Check world zone hotspots type
-- This is very fast. No need to make a quad tree

function Nx.Map:CheckDropdownListVisible()
    for i = 1, 10 do
        local _DropdownList = _G["DropDownList" .. i]
        if _DropdownList and _DropdownList:IsVisible() and _DropdownList:GetFrameStrata() == "FULLSCREEN_DIALOG" then
            return true
        end
    end

    return false
end

function Nx.Map:CheckWorldHotspotsType (wx, wy, quad)

    for n, spot in ipairs (quad) do
        -- Skip Quel'Thalas zones based on player location (old vs new)
        if self:ShouldHideQuelThalasZone(spot.MapId) then
            -- Skip this hotspot entirely
        elseif wx >= spot.WX1 and wx <= spot.WX2 and wy >= spot.WY1 and wy <= spot.WY2 then

            local curId = self:GetCurrentMapId()

            if spot.MapId ~= curId then
                local winfo = self.MapWorldInfo[curId]
                if winfo and winfo.Underground then
                    return false
                end
--                Nx.prt ("hotspot %s %s %s %s %s", spot.MapId, spot.WX1, spot.WX2, spot.WY1, spot.WY2)
                if not Nx.Map:CheckDropdownListVisible() then self:SetCurrentMap (spot.MapId) end
            end
            Nx.Map.MouseIsOverMap = spot.MapId
            self.WorldHotspotTipStr = spot.NxTipBase .. "\n"
--[[
            if false then

                local tt = GameTooltip
                local owner = self.Win.Frm

                owner.NXTip = spot.NxTipBase

                if not tt:IsVisible() then

--                    Nx.prt ("hotspot tip")

                    local tippos = "ANCHOR_TOPLEFT"

                    Nx.TooltipOwner = owner
                    self.TooltipType = 1

                    tt:SetOwner (owner, tippos, 0, 0)
                    Nx:SetTooltipText (owner.NXTip .. Nx.Map.PlyrNamesTipStr)

                    owner["UpdateTooltip"] = Nx.Map.OnUpdateTooltip
                end
            end
--]]
            return true
        end
    end
end

--------
-- Called by tooltip
-- self = frame

--[[
function Nx.Map:OnUpdateTooltip()

    local map = self.NxMap
    map:BuildPlyrLists()

    Nx:SetTooltipText (self.NXTip .. map.TipStr .. Nx.Map.PlyrNamesTipStr)

--    Nx.prt ("OnUpdateTooltip %s %s", self.NXTip, map.TipStr)
end
--]]

--------
-- Move world zone hotspot frames

--[[
function Nx.Map:MoveWorldHotspots()

    local clip = self.ClipFrameTL

    local level = self.Level
    local alpha = 0

    if self.Debug then
        level = level + 15
        alpha = self.BackgndAlpha * .5
    end

    self.Level = self.Level + 2

    local cont = self.Cont
    local zone = self.Zone

    local _, zx, zy, zw, zh = self:GetWorldZoneInfo (cont, zone)
    if not zx then
        return
    end

--    Nx.prt ("Map World XY "..basex.." "..basey)

    local frms = self.WorldHotFrms

    frms.UpStart = (frms.UpStart + 1) % 3

    for n = frms.UpStart + 1, #frms, 3 do

        local f = frms[n]

        if clip (self, f, f.NXWX, f.NXWY, f.NXW, f.NXH) then

            if self.DebugMap then
                f.texture:SetVertexColor (1, 1, 1, alpha)
            end

            f:SetFrameLevel (level + f.NXLev)

            f.NxTip = f.NxTipBase .. self.TipStr .. "~T"
        end
    end
end
--]]

--------
-- Update

function Nx.Map:SetLevelWorldHotspots()
--[[
    local lvl =    self.NXCitiesUnder and -1 or 1

    for _, f in ipairs (self.WorldHotFrms) do
        if f.NXLev ~= 0 then        -- A city?
            f.NXLev = lvl
        end
    end
--]]
end

--------
-- Update map zone tiles

function Nx.Map:MoveCurZoneTiles (clear)

    local mapId = self.MapId
    local wzone = self:GetWorldZone (mapId)
    if not wzone then
        wzone = {}
    end

    -- Skip drawing zone tiles for instance maps when NXInstanceMaps option is enabled
    -- These maps are drawn by MoveWorldMap/UpdateWorldMap instead to avoid duplicate textures
    local isInstanceWithOverlay = (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps

    if not clear and not isInstanceWithOverlay and
            (not wzone or wzone.City or (wzone.StartZone and Nx.Map.RMapId == mapId) or
            self:IsBattleGroundMap (Nx.Map.RMapId)) or self:IsMicroDungeon(Nx.Map.RMapId) then

--        Nx.prt ("MoveCurZoneTiles %d", mapId)
        local alpha = self.BackgndAlpha * (wzone.Alpha or 1)

        self:MoveZoneTiles (self.Cont, self.Zone, self.TileFrms, alpha, self.Level)
        self.Level = self.Level + 1

    else
--        Nx.prt ("ClearCurZoneTiles %d", mapId)
        local frms, frm

        frms = self.TileFrms

        for i = 1, 150 do
            frm = frms[i]
            if frm then
                frm:Hide()
            end
        end
    end
end

--------
-- Hide extra (Dalaran) map zone tiles

function Nx.Map:HideExtraZoneTiles()

    local frms = self.TileFrms
    frms[4]:Hide()
    frms[8]:Hide()
    frms[9]:Hide()
    frms[12]:Hide()
end

--------
-- Update map zone tiles (4 x 3 or custom TileX x TileY blocks)

function Nx.Map:MoveZoneTiles (cont, zone, frms, alpha, level)
    local zname, zx, zy, zw, zh = self:GetWorldZoneInfo (cont, zone)
    if not zx then
        return
    end
    -- Nx.prt ("MapZ %f, %f", zx, zy, zone)

    local scale = self.ScaleDraw
    local tilex, tiley
    if zone == 0 then
        tilex = self.MapInfo[cont].TileX or 4
        tiley = self.MapInfo[cont].TileY or 3

        if self.MapInfo[cont].ZXOff and self.MapInfo[cont].ZYOff then
            zx = zx + self.MapInfo[cont].ZXOff
            zy = zy + self.MapInfo[cont].ZYOff
        end

        if self.MapInfo[cont].ZWOff and self.MapInfo[cont].ZHOff then
            zw = zw + self.MapInfo[cont].ZWOff
            zh = zh + self.MapInfo[cont].ZHOff
        end
    else
        -- Get actual tile dimensions from layer info if available
        local layers = C_Map.GetMapArtLayers(zone)
        if layers and layers[1] then
            local layerInfo = layers[1]
            tilex = ceil(layerInfo.layerWidth / layerInfo.tileWidth)
            tiley = ceil(layerInfo.layerHeight / layerInfo.tileHeight)
        else
            tilex = self.MapWorldInfo[zone].TileX or 4
            tiley = self.MapWorldInfo[zone].TileY or 3
        end

        if self.MapWorldInfo[zone].ZXOff and self.MapWorldInfo[zone].ZYOff then
            zx = zx + self.MapWorldInfo[zone].ZXOff
            zy = zy + self.MapWorldInfo[zone].ZYOff
        end

        if self.MapWorldInfo[zone].ZWOff and self.MapWorldInfo[zone].ZHOff then
            zw = zw + self.MapWorldInfo[zone].ZWOff
            zh = zh + self.MapWorldInfo[zone].ZHOff
        end
    end

    --[[if cont == 11 then
        zw = zw + (self.DebugMZWOff or 0)
        zh = zh + (self.DebugMZHOff or 0)
        zx = zx + (self.DebugMXOff or 0)
        zy = zy + (self.DebugMYOff or 0)
    end]]--

    local clipW = self.MapW
    local clipH = self.MapH
    local x = (zx - self.MapPosXDraw) * scale + clipW / 2
    local y = (zy - self.MapPosYDraw) * scale + clipH / 2
    local bx = 0
    local by = 0
    local bw = zw * (tilex == 15 and 1 or 1024 / 1002) / tilex * scale
    local bh = zh * (tiley == 10 and 1 or 768 / 668) / tiley * scale

    local w, h
    local texX1, texX2
    local texY1, texY2
    local numtiles = tilex * tiley

    for i = 1, numtiles do

        local frm = frms[i]
        if frm then
            --Nx.prt ("MapZ %f", i)
            texX1 = 0
            texX2 = 1
            texY1 = 0
            texY2 = 1

            local vx0 = bx * bw + x
            local vx1 = vx0
            local vx2 = vx0 + bw

            if vx1 < 0 then
                vx1 = 0
                texX1 = (vx1 - vx0) / bw
            end

            if vx2 > clipW then
                vx2 = clipW
                texX2 = (vx2 - vx0) / bw
            end

            local vy0 = by * bh + y
            local vy1 = vy0
            local vy2 = vy0 + bh

            if vy1 < 0 then
                vy1 = 0
                texY1 = (vy1 - vy0) / bh
            end

            if vy2 > clipH then
                vy2 = clipH
                texY2 = (vy2 - vy0) / bh
            end

            w = vx2 - vx1
            h = vy2 - vy1

            if w <= 0 or h <= 0 then
                frm:Hide()
            else
                frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)
                frm:SetWidth (w)
                frm:SetHeight (h)
                frm:SetFrameLevel (level)

                frm.texture:SetTexCoord (texX1, texX2, texY1, texY2)
                --frm.texture:SetVertexColor (1, 1, 1, self.BackgndAlpha)

                frm:Show()
            end
        end

        bx = bx + 1

        if bx >= tilex then
            bx = 0
            by = by + 1
        end
    end
end

--------
-- Add old map zone to list

function Nx.Map:AddOldMap (newMapId)

    if self.MapId == 0 then        -- Happens on startup
        return
    end

    -- Remove any for new zone

    local off = 1
    local dup

    for n = 1, #self.MapsDrawnOrder do
        if self.MapsDrawnOrder[off] == newMapId then
            tremove (self.MapsDrawnOrder, off)
            dup = true
        else
            off = off + 1
        end
    end

    local drawCnt = Nx.db.profile.Map.ZoneDrawCnt

    if not dup then

--        Nx.prt ("no dup")

        local extra = #self.MapsDrawnOrder - drawCnt + 2
        for n = 1, extra do
            tremove (self.MapsDrawnOrder, 1)
        end
    end

    if drawCnt > 1 then

        self.MapsDrawnFade[self.MapId] = -1
        tinsert (self.MapsDrawnOrder, self.MapId)        -- Newest at end

--        Nx.prt ("Cur map %s", self:GetCurrentMapId())
--        Nx.prtVar ("order", self.MapsDrawnOrder)
    end
end

--------
-- Caches for overlay optimization (avoid per-frame allocations and API calls)
local OverlayCache = {
    layerInfo = {},           -- [mapId] = layerInfo table
    exploredTextures = {},    -- [mapId] = explored lookup table
    parsedOverlays = {},      -- [txFolder] = pre-parsed overlay data
    lastExploredCheck = {},   -- [mapId] = GetTime() of last exploration check
}

-- Pre-parse overlay string data once (avoids Nx.Split every frame)
local function GetParsedOverlay(txFolder, txName, whxyStr)
    local cacheKey = txFolder .. txName
    local cached = OverlayCache.parsedOverlays[cacheKey]
    if cached then
        return cached
    end

    local oX, oY, txW, txH, mode = Nx.Split(",", whxyStr)
    local arTx
    local isMultiTexture = false
    if string.find(txName, ",") then
        arTx = {Nx.Split(",", txName)}
        isMultiTexture = true
    elseif tonumber(txName) then
        arTx = {txName}
    end

    cached = {
        oX = tonumber(oX),
        oY = tonumber(oY),
        txW = tonumber(txW),
        txH = tonumber(txH),
        mode = mode,
        arTx = arTx,
        isMultiTexture = isMultiTexture,
        whxyKey = oX..","..oY..","..txW..","..txH,
    }
    OverlayCache.parsedOverlays[cacheKey] = cached
    return cached
end

-- Get cached layer info (avoids API calls every frame)
local function GetCachedLayerInfo(mapId)
    local cached = OverlayCache.layerInfo[mapId]
    if cached then
        return cached
    end

    local layers = C_Map.GetMapArtLayers(mapId)
    if not layers or not layers[1] then
        return nil
    end

    -- Try to get layer index from WorldMapFrame (Retail), fallback to 1 (Classic)
    local layerIndex = 1
    if WorldMapFrame and WorldMapFrame.GetCanvasContainer then
        local canvas = WorldMapFrame:GetCanvasContainer()
        if canvas and canvas.GetCurrentLayerIndex then
            layerIndex = canvas:GetCurrentLayerIndex() or 1
        end
    end

    cached = layers[layerIndex] or layers[1]
    OverlayCache.layerInfo[mapId] = cached
    return cached
end

-- Get cached explored textures (only refresh every 2 seconds)
local function GetCachedExploredTextures(mapId, forceRefresh)
    local now = GetTime()
    local lastCheck = OverlayCache.lastExploredCheck[mapId] or 0

    -- Only refresh exploration data every 2 seconds (exploration doesn't change often)
    if not forceRefresh and (now - lastCheck) < 2 and OverlayCache.exploredTextures[mapId] then
        return OverlayCache.exploredTextures[mapId]
    end

    local exploredWHXY = {}
    local explored = C_MapExplorationInfo.GetExploredMapTextures(mapId)
    if explored then
        for i, ex in ipairs(explored) do
            local key = ex.offsetX..","..ex.offsetY..","..ex.textureWidth..","..ex.textureHeight
            exploredWHXY[key] = true
        end
    end

    OverlayCache.exploredTextures[mapId] = exploredWHXY
    OverlayCache.lastExploredCheck[mapId] = now
    return exploredWHXY
end

--------
-- Update the zones

function Nx.Map:UpdateZones()

    local mapId = self.MapId
    local winfo = self.MapWorldInfo[mapId]
    if not winfo then
        winfo = {}
    end
--    Nx.prt ("UpdateZones %s, %s", mapId, winfo.Name or "nil")

    local s = self.LOpts.NXDetailScale

    local freeOrScale = self.ScaleDraw <= s

    -- Skip zone tile updates for instance maps when NXInstanceMaps option is enabled
    -- These are rendered via MoveWorldMap to prevent duplicate moving textures
    local isInstanceWithOverlay = (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps
    if isInstanceWithOverlay then
        self:MoveCurZoneTiles(true)  -- Clear tiles
        self:UpdateMiniFrames()
        return
    end

    if freeOrScale or
        winfo.City or winfo.NoTilemap or
        (winfo.StartZone and Nx.Map.UpdateMapID == mapId) or
        self:IsBattleGroundMap (Nx.Map.UpdateMapID) or
        self:IsMicroDungeon(Nx.Map.UpdateMapID)  then

--        if freeOrScale and self.MapIdOld and self.MapIdOld ~= mapId then
--            self:UpdateOverlay (id, .8, true)
--        end
        -- LOD optimization: when very zoomed out, limit overlay updates
        local scale = self.ScaleDraw
        local maxOverlays = scale < 0.1 and 3 or (scale < 0.2 and 6 or #self.MapsDrawnOrder)
        local overlayCount = 0

        for n, id in ipairs (self.MapsDrawnOrder) do
            overlayCount = overlayCount + 1
            if overlayCount <= maxOverlays then
                self:UpdateOverlay (id, .8, true)
            end
        end
        if winfo.City then
--            Nx.prt ("city %s", self.Level)
            self:UpdateMiniFrames()
            self:MoveCurZoneTiles()
        else
            self:MoveCurZoneTiles()
            self:UpdateOverlay (mapId, 1)
            self:UpdateMiniFrames()
        end

    else
        self:MoveCurZoneTiles (true)        -- Clear
        self:UpdateMiniFrames()
    end
end

function Nx.Map:GetExploredOverlayNum()

--    local overlayNum = GetNumMapOverlays()        -- Cartographer makes this return 0

    local overlays = C_MapExplorationInfo.GetExploredMapTextures(C_Map.GetBestMapForUnit('player') or 0)
    return overlays and #overlays or 0
end

function Nx.Map:UpdateOverlayUnexplored()

    self.CurOverlays = rm
    local txFolder

    local mapId = self:GetCurrentMapId(true)
    local wzone = self:GetWorldZone (mapId)
    if wzone then
        if wzone.City then
            return
        end
        txFolder = wzone.Overlay
    end

    local overlays

    if txFolder then
        overlays = Nx.Map.ZoneOverlays[txFolder]
    end

    if not overlays or not self.ShowUnexplored then
--        local overlayNum = GetNumMapOverlays()        -- Cartographer makes this return 0
--        Nx.prt ("Overlays %s", overlayNum)

        local s1, s2, file
        local ol = {}

        if overlays then
            for txName, whxyStr in pairs (overlays) do    -- Copy overlay table
                ol[txName] = whxyStr
            end
        end

        overlays = ol

        --[[for i = 1, 99 do

            -- Terrokar has 4 overlays with "" for name

            local txName, txW, txH, oX, oY = GetMapOverlayInfo (i)
            if not txName then
                break
            end

            local s1, s2, folder, file = strfind (txName, ".+\\.+\\(.+)\\(.+)")
            if s1 then
                txFolder = folder
                file = strlower (file)
                overlays[file] = format ("%d,%d,%d,%d", oX - 10000, oY, txW, txH)

--                Nx.prt (" %s %s", txName, overlays[file])
            end
        end]]--

        if not txFolder then        -- Can happen on log in
            overlays = false
        end
    end

    self.CurOverlays = overlays
    self.CurOverlaysTexFolder = txFolder
end

function Nx.Map:TargetOverlayUnexplored()

    local mapId = self:GetCurrentMapId(true)
    self:ClearTargets()        -- Will change current mapid

    local wzone = self:GetWorldZone (mapId)
    if wzone and wzone.City then
        return
    end

    local overlays = self.CurOverlays

    if not overlays then    -- Not found? New stuff probably
        return
    end

    for txName, whxyStr in pairs (overlays) do

        local oX, oY, txW, txH = Nx.Split (",", whxyStr)

        oX = tonumber (oX)
        oY = tonumber (oY)

        if oX >= 0 then

            txW = tonumber (txW)
            txH = tonumber (txH)

            if txW == 512 then
                txW = txW * .75
            end
            if txH == 512 then
                txH = txH * .75
            end

--            Nx.prt ("%s %s %s %s %s", txName, oX, oY, txW, txH)

            local x, y = (oX + txW / 2) / 1002 * 100, (oY + txH / 2) / 668 * 100
--            local wx, wy = self:GetWorldPos (mapId, (oX) / 1002 * 100, (oY) / 668 * 100)

            self:SetTargetXY (mapId, x, y, "Explore", true)
        end
    end
end

--------
-- Locale-aware compressed texture path
-- New structure: Conv/{locale}/{zonefolder}/{textureName}
-- Fallback structure: Conv/{textureName} (backwards compatible)
-- External addon structure (retail only): {MediaPath}/{zonefolder}/{textureName}
local function GetCompressedTexturePath(textureName, zoneFolder)
    -- Check if external media addon provides a path (retail only)
    if Nx.isRetail and Nx.GetCarboniteMediaPath then
        local externalPath = Nx.GetCarboniteMediaPath()
        if externalPath then
            return externalPath .. "\\" .. zoneFolder .. "\\" .. textureName
        end
    end

--[[    local basePath = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\Conv\\"

    -- Check if locale textures are enabled
    if Nx.db and Nx.db.profile and Nx.db.profile.Map and Nx.db.profile.Map.UseLocaleTextures then
        local locale = GetLocale()
        return basePath .. locale .. "\\" .. zoneFolder .. "\\" .. textureName
    end
    return basePath .. textureName ]] -- Local path is disabled because we no longer store textures in package
end

--------
-- Update the overlays

function Nx.Map:UpdateOverlay (mapId, bright, noUnexplored)
    if(mapId == 0) then mapId = Nx.Map:GetCurrentMapAreaID(); end
    if (mapId == nil or mapId == -1) then
        return
    end

    -- Skip Quel'Thalas zones based on player location (old vs new)
    if self:ShouldHideQuelThalasZone(mapId) then
        return
    end

    local wzone = self:GetWorldZone (mapId)
    if wzone and (wzone.City or self:IsMicroDungeon(mapId)) then
        return
    end
    local txFolder = wzone and wzone.Overlay or ""
    local overlays = Nx.Map.ZoneOverlays[txFolder]

    local unex
    if not noUnexplored and (not overlays or not self.ShowUnexplored) then
        if not (wzone and wzone.Explored) then
            unex = true
        end
    end
    if self:IsBattleGroundMap(Nx.Map.UpdateMapID) then
        return
    end
    -- Skip overlays for instance maps with NXInstanceMaps enabled
    if self:IsInstanceMap(Nx.Map.RMapId) and self.CurOpts.NXInstanceMaps then
        return
    end
    if not overlays then    -- Not found? New stuff probably
        return
    end

    local bW, bH
    local txIndex
    local txPixelW, txFileW, txPixelH, txFileH

    -- Cache path construction (only changes with mapId/phase)
    local path
    if wzone.Phase then
        path = "Interface\\Worldmap\\" .. txFolder .. "_" .. wzone.Phase .. "\\"
    else
        path = "Interface\\Worldmap\\" .. txFolder .. "\\"
    end
    local alpha = self.BackgndAlpha
    local unExAl = self.LOpts.NXUnexploredAlpha
    local zscale = self:GetWorldZoneScale (mapId) / 10

    -- Use cached explored textures (refreshes every 2 seconds instead of every frame)
    local exploredWHXY = unex and GetCachedExploredTextures(mapId) or {}

    -- Use cached layer info (avoids API calls every frame)
    local layerInfo = GetCachedLayerInfo(mapId)
    if not layerInfo then
        return
    end
    local TILE_SIZE_WIDTH = layerInfo.tileWidth
    local TILE_SIZE_HEIGHT = layerInfo.tileHeight
    local layerWidth = layerInfo.layerWidth
    local layerHeight = layerInfo.layerHeight

    -- LOD: Skip very small overlays when zoomed out (they're not visible anyway)
    local scale = self.ScaleDraw
    local minVisibleSize = scale < 0.15 and 128 or (scale < 0.3 and 64 or 0)

    for oName, whxyStr in pairs (overlays) do
        -- Skip dynamic overlays
        if oName == "dynamic" then
            return
        end

        -- Use pre-parsed overlay data (avoids Nx.Split every frame)
        local parsed = GetParsedOverlay(txFolder, oName, whxyStr)
        local oX, oY = parsed.oX, parsed.oY
        local txW, txH = parsed.txW, parsed.txH
        local mode = parsed.mode
        local arTx = parsed.arTx
        local isMultiTexture = parsed.isMultiTexture
        local whxyKey = parsed.whxyKey

        -- Adjust zscale for multi-texture overlays (comma-separated IDs use different scale)
        local overlayZscale = zscale
        if isMultiTexture then
            overlayZscale = self:GetWorldZoneScale(mapId) / 38
        end

        -- LOD: Skip small overlays when zoomed out
        if txW < minVisibleSize and txH < minVisibleSize then
            -- Skip this overlay, too small to see
        else
            local lev = 0
            local brt = bright
            local txName = path .. oName

            if exploredWHXY[whxyKey] then
                oX = oX - 10000
            end

            if unex then        -- Dimming unexplored?
                if oX < 0 then
                    oX = oX + 10000    -- Fix explored x
                else
                    brt = unExAl        -- Dim
                    lev = 1
                end
            end

            bW = ceil (txW / TILE_SIZE_WIDTH)
            bH = ceil (txH / TILE_SIZE_HEIGHT)
            txIndex = 1

            for bY = 0, bH - 1 do

                if bY < bH - 1 then
                    txPixelH = TILE_SIZE_HEIGHT
                    txFileH = TILE_SIZE_HEIGHT
                else
                    txPixelH = mod (txH, TILE_SIZE_HEIGHT)
                    if txPixelH == 0 then
                        txPixelH = TILE_SIZE_HEIGHT
                    end
                    txFileH = 16
                    while txFileH < txPixelH do
                        txFileH = txFileH * 2
                    end
                end

                for bX = 0, bW - 1 do

                    if bX < bW - 1 then
                        txPixelW = TILE_SIZE_WIDTH
                        txFileW = TILE_SIZE_WIDTH
                    else
                        txPixelW = mod (txW, TILE_SIZE_WIDTH)
                        if txPixelW == 0 then
                            txPixelW = TILE_SIZE_WIDTH
                        end
                        txFileW = 16
                        while txFileW < txPixelW do
                            txFileW = txFileW * 2
                        end
                    end

                    local f = self:GetIconNI (lev)

                    local wx, wy = self:GetWorldPos (mapId, (oX + bX * TILE_SIZE_WIDTH) / layerWidth * 100, (oY + bY * TILE_SIZE_HEIGHT) / layerHeight * 100)

                    local foundUnderscore = string.find(oName, "_")

                    if foundUnderscore == 1 and bX == 0 and bY == 0 then

                        local nName, nW, nH = Nx.Split (",", oName)
                        nW = tonumber(nW)
                        nH = tonumber(nH)
                        if self:ClipFrameTL (f, wx, wy, nW * overlayZscale, nH * overlayZscale) then
                            f.texture:SetColorTexture (1, 0, 0, 0)
                            f.texture:SetTexture (GetCompressedTexturePath(nName, txFolder))
                            f.texture:SetVertexColor (brt, brt, brt, alpha)
                        end

                    else

                        if self:ClipFrameTL (f, wx, wy, txFileW * overlayZscale, txFileH * overlayZscale) then

                            f.texture:SetColorTexture (1, 0, 0, 0) -- fix for background green overlays

                            if arTx then
                                if not string.find(oName, "_") then f.texture:SetTexture (arTx[txIndex]) end
                            elseif wzone.Phase then -- Classic MOP phases support
                                local phasetex = format("%s%s_%s", txName, txIndex, wzone.Phase)
                                f.texture:SetTexture (phasetex)
                            else
                                f.texture:SetTexture (mode and txName or txName .. txIndex)
                            end
                            f.texture:SetVertexColor (brt, brt, brt, alpha)
                        end

                    end

                    txIndex = txIndex + 1
                end
            end
        end -- end LOD size check
    end

    self.Level = self.Level + 2
end

--------
-- Update frames for mini map texture layer (detail layer)

-- Old Blood Elf starting zones that should show old (BloodelfMapBlks) tiles
local OldBloodElfZones = {
    [94] = true,   -- Eversong Woods
    [95] = true,   -- Ghostlands
    [110] = true,  -- Silvermoon City
    [122] = true,  -- Isle of Quel'Danas
    [467] = true,  -- Sunstrider Isle
}

-- New Quel'Thalas zones (Midnight expansion) - hidden when player is in old zones
local NewQuelThalasZones = {
    [2537] = true,  -- Quel'Thalas sub-continent
    [2395] = true,  -- New Eversong Woods
    [2393] = true,  -- New Silvermoon City
    [2437] = true,  -- New Zul'Aman
    [2536] = true,  -- Atal'Aman
    [2424] = true,  -- New Quel'Danas
    [2405] = true,  -- Voidstorm
    [2413] = true,  -- Harandar
}

-- Check if player is currently in an old Blood Elf zone
function Nx.Map:IsPlayerInOldBloodElfZone()
    if Nx.isClassic then
        return true
    end
    local playerMapId = C_Map.GetBestMapForUnit("player")
    return playerMapId and OldBloodElfZones[playerMapId]
end

-- Check if a zone should be hidden because player is in old Blood Elf zone
function Nx.Map:ShouldHideNewQuelThalasZone(mapId)
    if not NewQuelThalasZones[mapId] then
        return false
    end
    return self:IsPlayerInOldBloodElfZone()
end

-- Check if old Blood Elf zone should be hidden because player is NOT in old zone
function Nx.Map:ShouldHideOldBloodElfZone(mapId)
    if not OldBloodElfZones[mapId] then
        return false
    end
    -- Hide old zones when player is NOT in any old zone
    return not self:IsPlayerInOldBloodElfZone()
end

-- Check if any Quel'Thalas zone (old or new) should be hidden based on player location
function Nx.Map:ShouldHideQuelThalasZone(mapId)
    return self:ShouldHideNewQuelThalasZone(mapId) or self:ShouldHideOldBloodElfZone(mapId)
end

function Nx.Map:UpdateMiniFrames()

--[[
    SaveView (5)
--    local x = GetCVar ("cameraYawD")
--    local y = GetCVar ("cameraPitchD")
--    local isLook = IsMouselooking()

--    Nx.prtCtrl ("Cam %s %s %s", x, y, isLook or "nil")

    local vartest = {
        "cameraYaw",
        "cameraYawA",
        "cameraYawB",
        "cameraYawC",
        "cameraYawD",
    }

    for k, name in pairs (vartest) do
        Nx.prtCtrl ("Cam %s %s", name, GetCVar (name) or "nil")
    end
--]]

    local Map = Nx.Map
    local mapId = self.MapId
    local winfo = self.MapWorldInfo[mapId]

    local opts = self.LOpts

    local alphaRange = opts.NXDetailScale * .35
    local s = opts.NXDetailScale - alphaRange

--    s = .1

--    or winfo.City

    if self.ScaleDraw <= s or opts.NXDetailAlpha <= 0 or self:IsBattleGroundMap (Nx.Map.UpdateMapID) or self:IsMicroDungeon(Nx.Map.UpdateMapID) then
        self:HideMiniFrames()
        return
    end

    local alphaPer = min ((self.ScaleDraw - s) / alphaRange, 1)
--    Nx.prt ("alpha %s", alphaPer)

--    local cont = self.Cont
--    local zname, zx, zy

    -- Check if player is in an old Blood Elf zone - if so, use BloodelfMapBlks
    local playerMapId = C_Map.GetBestMapForUnit("player")
    local useBloodElfOverlay = playerMapId and OldBloodElfZones[playerMapId]

    -- If player is in old Blood Elf zone and we're viewing Eastern Kingdoms area,
    -- use the BloodelfMapBlks (MiniMapBlks[94]) instead of normal EK blocks
    local miniT, basex, basey
    if useBloodElfOverlay and winfo and (winfo.Cont == 2 or OldBloodElfZones[mapId]) then
        -- Try to get BloodelfMapBlks overlay
        miniT, basex, basey = self:GetMiniInfo(94)
    end

    -- If no Blood Elf overlay or not applicable, use normal lookup
    if not miniT then
        miniT, basex, basey = self:GetMiniInfo(mapId)
    end
--    basex = basex + (self.DebugPXOff or 0)
--    basey = basey + (self.DebugPYOff or 0)

    if not miniT then
        self:HideMiniFrames()
        return
    end

    local level = self.Level
    self.Level = self.Level + 1

    local f
    local frmNum = 1

    local scale = 256 * 0.416767770014
    local size = scale

--    size = size - 4

    local miniX = floor ((self.MapPosXDraw - basex) / scale - self.MiniBlks / 2 + .5)
    local miniY = floor ((self.MapPosYDraw - basey) / scale - self.MiniBlks / 2 + .5)

--    Nx.prt ("MiniXY %f %f", miniX, miniY)

    basex = basex + miniX * scale
    basey = basey + miniY * scale

    local wx
    local wy = basey
    local al = self.BackgndAlpha * opts.NXDetailAlpha * alphaPer

    for y = miniY, miniY + self.MiniBlks - 1 do

        wx = basex

        for x = miniX, miniX + self.MiniBlks - 1 do

            f = self.MiniFrms[frmNum]
            --Nx.prt(mapId.." | "..miniT[3] .." "..miniT[4] .." "..miniT[7].." | "..x.." "..y.." | "..(tonumber(format("%02d%02d", (x + miniT[3]), (y + miniT[4])))).." | "..(txname and txname or "nil"));
            local txname = miniT[1][tonumber(format("%02d%02d", (x + miniT[3]), (y + miniT[4])))] --Map:GetMiniBlkName (miniT, x, y)

            if txname and txname ~= "" then

                if self:ClipFrameTL (f, wx, wy, size, size) then

                    f:SetFrameLevel (level)
                    f.texture:SetVertexColor (1, 1, 1, al)
--                    txname = "Textures\\Minimap\\"..txname
                    f.texture:SetTexture (txname)

--                    Nx.prtD("%s %s, %s", x, y, txname)
--[[
--                    Nx.prtCtrl ("%s %s, %s", x, y, txname)

                    local r, r2, r3 = f.texture:SetTexture (txname)        --V4 always returns r=1?
                    Nx.prtVar ("mmtex", r)
                    Nx.prtVar ("mmtex2", r2)
                    Nx.prtVar ("mmtex3", r3)
                    if not r then
                        Nx.prtCtrl ("%s %s, %s", x, y, txname)
                    end
--]]
                end

            else

                f:Hide()
            end

            wx = wx + scale
            frmNum = frmNum + 1
        end

        wy = wy + scale
    end

end

function Nx.Map:HideMiniFrames()

    for n = 1, self.MiniBlks ^ 2 do
        self.MiniFrms[n]:Hide()
    end
end

--------
-- Update POI

--[[
Nx.POITypes = { "Mailbox", "Anvil", "Forge", "Moonwell", "Manaloom" }
Nx.POITex = { "Icons\\INV_Letter_15",
    "Icons\\Trade_BlackSmithing",
    "Icons\\INV_Sword_09",
    "Icons\\Spell_Fire_BlueFlameRing",
    "Icons\\Spell_Fire_BlueFlameRing"
}

function Nx.Map:UpdateNxPOI()

    local Map = Nx.Map

    for poiType, v in pairs (Nx.POI) do

        local str = Nx.POI[poiType]

        for n = 1, #str, 5 do

            local zone = strbyte (str, n)
            if not zone then
                break
            end

            zone = zone - 35

            local x = ((strbyte (str, n + 1) - 35) * 221 + (strbyte (str, n + 2) - 35)) / 100
            local y = ((strbyte (str, n + 3) - 35) * 221 + (strbyte (str, n + 4) - 35)) / 100

            if self.Debug then
--                Nx.prt ("POI #%d %d %d %d", (n+4) / 5, zone, x, y)
            end

            local mapId = Map.NxzoneToMapId[tonumber (zone)]

            if not mapId then
--                Nx.prt ("POI #%d %d %d %d", (n+4) / 5, zone, x, y)

            else
                x, y = self:GetWorldPos (mapId, x, y)

                local f = self:GetIcon()

                if self:ClipFrameW (f, x, y, 16, 16, 0) then
                    f.NxTip = format ("%s", Nx.POITypes[poiType])
                    f.texture:SetTexture ("Interface\\" .. Nx.POITex[poiType])
                end
            end
        end
    end
end
--]]

--------
--
--[[
function Nx.Map:DrawZoneRect (mapId, x, y, w, h, tip)

    mapId = mapId or self.MapId

    local wx, wy = self:GetWorldPos (mapId, x, y)
    local scale = self:GetWorldZoneScale (mapId) / 10.02

    local f = map:GetIcon()

    if self:ClipFrameTL (f, wx, wy, w * scale, h * scale) then
        f.NxTip = tip
        f.texture:SetTexture (r, g, b, .5)
    end
end
--]]

--------
-- Zone clip a frame to the map and set position, size and texture coords
-- XY is center. Width and height are not scaled
-- hideOutside: if true, hide frame completely when center is outside visible area

function Nx.Map:ClipFrameZ (frm, x, y, w, h, dir, hideOutside)

    x, y = self:GetWorldPos (self.MapId, x, y)
    return self:ClipFrameByMapType (frm, x, y, w, h, dir, hideOutside)
end

--------
-- Zone clip a frame to the map and set position (top left), size and texture coords
-- Width and height are scaled

function Nx.Map:ClipFrameZTL (frm, x, y, w, h)

    x, y = self:GetWorldPos (self.MapId, x, y)
    return self:ClipFrameTL (frm, x, y, w, h)
end

--------
-- Zone clip a frame (top left with offset)
-- Width and height are scaled

function Nx.Map:ClipFrameZTLO (frm, x, y, w, h, xo, yo)

    x, y = self:GetWorldPos (self.MapId, x, y)
    return self:ClipFrameTL (frm, x + xo / self.ScaleDraw, y + yo / self.ScaleDraw, w, h)
end


function Nx.Map:ClipFrameByMapType (frm, bx, by, w, h, dir, hideOutside)
    if (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
        return self:ClipFrameMF (frm, bx, by, w, h, dir)
    else
        return self:ClipFrameW (frm, bx, by, w, h, dir, hideOutside)
    end
end

--------
-- Clip a frame to the map and set position, size and texture coords
-- XY is center. Width and height are not scaled
-- If hideOutside is true, hides frame completely when center is outside bounds (for icons)

function Nx.Map:ClipFrameW (frm, bx, by, w, h, dir, hideOutside)
    local scale = self.ScaleDraw
    local clipW = self.MapW
    local clipH = self.MapH

    -- Calculate screen position of center point
    local x = (bx - self.MapPosXDraw) * scale + clipW * .5
    local y = (by - self.MapPosYDraw) * scale + clipH * .5

    -- For icons (hideOutside=true), hide completely if center is outside visible area
    if hideOutside then
        if x < 0 or x > clipW or y < 0 or y > clipH then
            if self.ScrollingFrm ~= frm then
                frm:Hide()
            else
                frm:SetWidth (.001)
            end
            return false
        end
    end

    -- Calc x

    local bw = w

    local texX1 = 0
    local texX2 = 1

    local vx0 = x - bw * .5        -- Center frame at bx
    local vx1 = vx0
    local vx2 = vx0 + bw

    if vx1 < 0 then
        vx1 = 0
        texX1 = (vx1 - vx0) / bw
    end

    if vx2 > clipW then
        vx2 = clipW
        texX2 = (vx2 - vx0) / bw
    end

    w = vx2 - vx1

    if w < .3 then

        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    -- Calc y

    local bh = h

    local texY1 = 0
    local texY2 = 1

    local vy0 = y - bh * .5        -- Center frame at by
    local vy1 = vy0
    local vy2 = vy0 + bh

    if vy1 < 0 then
        vy1 = 0
        texY1 = (vy1 - vy0) / bh
    end

    if vy2 > clipH then
        vy2 = clipH
        texY2 = (vy2 - vy0) / bh
    end

    h = vy2 - vy1

    if h < .3 then

        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    -- Set frame

    frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)
    frm:SetWidth (w)
    frm:SetHeight (h)

    if dir == 0 then

        frm.texture:SetTexCoord (texX1, texX2, texY1, texY2)

    else
        -- 13 UV order
        -- 24
        local t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y

        -- Make UV range -.5 to .5
        texX1 = texX1 - .5
        texX2 = texX2 - .5
        texY1 = texY1 - .5
        texY2 = texY2 - .5

        local co = cos (dir)
        local si = sin (dir)
        t1x = texX1 * co + texY1 * si + .5
        t1y = texX1 * -si + texY1 * co + .5
        t2x = texX1 * co + texY2 * si + .5
        t2y = texX1 * -si + texY2 * co + .5
        t3x = texX2 * co + texY1 * si + .5
        t3y = texX2 * -si + texY1 * co + .5
        t4x = texX2 * co + texY2 * si + .5
        t4y = texX2 * -si + texY2 * co + .5
        frm.texture:SetTexCoord (t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)

--        Nx.prt (" T1 "..t1x.." "..t1y)
--        Nx.prt (" T2 "..t2x.." "..t2y)
    end

    -- Note: SetSnapToPixelGrid/SetTexelSnappingBias moved to icon creation for performance

    frm:Show()

    return true
end

--------
-- Position a frame on the map without chopping texture coords
-- Used for rotated icons - parent frame clips at edges via SetClipsChildren
-- XY is center. Width and height are not scaled
-- Returns true if visible, false if hidden (completely off-screen)

function Nx.Map:ClipFrameWNoChop (frm, bx, by, w, h)

    local scale = self.ScaleDraw
    local clipW = self.MapW
    local clipH = self.MapH

    local x = (bx - self.MapPosXDraw) * scale + clipW * .5
    local y = (by - self.MapPosYDraw) * scale + clipH * .5

    -- For rotated icons, use half the diagonal as the effective radius
    local halfDiag = max(w, h) * 0.71  -- ~sqrt(2)/2

    -- Only hide if completely off-screen (no part visible)
    if x + halfDiag < 0 or x - halfDiag > clipW or
       y + halfDiag < 0 or y - halfDiag > clipH then
        frm:Hide()
        return false
    end

    -- Position frame centered at x, y
    -- Parent frame will clip at edges via SetClipsChildren(true)
    local vx = x - w * .5
    local vy = y - h * .5

    frm:SetPoint ("TOPLEFT", vx, -vy - self.TitleH)
    frm:SetWidth (w)
    frm:SetHeight (h)

    frm:Show()

    return true
end

--------
-- Clip a frame to the map and set position, size and texture coords
-- XY is center. Width and height are not scaled

function Nx.Map:ClipFrameWChop (frm, bx, by, w, h)

    local bw = w
    local bh = h
    local clipW = self.MapW
    local clipH = self.MapH

    local scale = self.ScaleDraw
    local x = (bx - self.MapPosXDraw) * scale + clipW / 2
    local y = (by - self.MapPosYDraw) * scale + clipH / 2

    local texX1 = 0
    local texX2 = 1

    -- Center frame at bx, by

    local vx0 = x - bw * .5
    local vx1 = vx0
    local vx2 = vx0 + bw

    if vx1 < 0 then
        vx1 = 0
        texX1 = (vx1 - vx0) / bw
    end

    if vx2 > clipW then
        vx2 = clipW
        texX2 = (vx2 - vx0) / bw
    end

    w = vx2 - vx1

    if w < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    local texY1 = 0
    local texY2 = 1

    local vy0 = y - bh * .5
    local vy1 = vy0
    local vy2 = vy0 + bh

    if vy1 < 0 then
        vy1 = 0
        texY1 = (vy1 - vy0) / bh
    end

    if vy2 > clipH then
        vy2 = clipH
        texY2 = (vy2 - vy0) / bh
    end

    h = vy2 - vy1

    if h < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)
    frm:SetWidth (w)
    frm:SetHeight (h)

    frm.texture:SetTexCoord (texX1 * .9 + .05, texX2 * .9 + .05, texY1 * .9 + .05, texY2 * .9 + .05)

    -- Note: SetSnapToPixelGrid/SetTexelSnappingBias now set once at frame creation

    frm:Show()

    return true
end

--------
-- Clip minimap frame to the map and set position, size and texture coords
-- XY is center. Width and height are not scaled

function Nx.Map:ClipMMW (frm, bx, by, w, h)

    local scale = self.ScaleDraw

    -- Each world unit maps to a pixel, so w * scale == size in pixels

    local bw = w * scale
    local bh = h * scale
    local clipW = self.MapW
    local clipH = self.MapH
    local x = (bx - self.MapPosXDraw) * scale + clipW * .5
    local y = (by - self.MapPosYDraw) * scale + clipH * .5

    local vx0 = x - bw * .5
    local vx1 = vx0
    local vx2 = vx0 + bw

    if vx1 < 0 or vx2 > clipW then
        return false
    end

    w = vx2 - vx1

    if w <= 0 then
        return false
    end

    local vy0 = y - bh * .5
    local vy1 = vy0
    local vy2 = vy0 + bh

    if vy1 < 0 or vy2 > clipH then
        return false
    end

    h = vy2 - vy1

    if h <= 0 then
        return false
    end

--    frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)
--    frm:SetWidth (w)
--    frm:SetHeight (h)

    local sc = w / 140
    self.MMFScale = sc

    local isc = Nx.db.profile.MiniMap.IScale
    self:MinimapSetScale (sc, isc)

--    frm:SetScale (sc)
    frm:SetPoint ("TOPLEFT", self.Frm, "TOPLEFT", vx1 / isc, (-vy1 - self.TitleH) / isc)

    frm:Show()

    return true
end

-------------------------------------------------------------------------------
-- CLIPPING FUNCTIONS
-- These functions handle clipping and positioning frames to fit within
-- the visible map area, calculating texture coordinates for partial visibility
-------------------------------------------------------------------------------

---
-- Clip a frame to the map and set position (top left), size and texture coords
-- Width and height are scaled by base (zone) scale
-- @param frm  Frame to clip
-- @param bx   World X coordinate (top-left)
-- @param by   World Y coordinate (top-left)
-- @param w    Width in world units
-- @param h    Height in world units
-- @return     true if visible, false if completely clipped
--
function Nx.Map:ClipFrameTL (frm, bx, by, w, h)

    -- Each world unit maps to a pixel, so w * scale == size in pixels

    local scale = self.ScaleDraw

    -- Calc x

    local bw = w * scale
    local clipW = self.MapW
    local x = (bx - self.MapPosXDraw) * scale + clipW * .5

    local texX1 = 0
    local texX2 = 1

    local vx1 = x
    local vx2 = x + bw

    if vx1 < 0 then
        vx1 = 0
        texX1 = (vx1 - x) / bw
    end

    if vx2 > clipW then
        vx2 = clipW
        texX2 = (vx2 - x) / bw
    end

    w = vx2 - vx1

    if w < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    -- Calc y

    local bh = h * scale
    local clipH = self.MapH
    local y = (by - self.MapPosYDraw) * scale + clipH * .5

    local texY1 = 0
    local texY2 = 1

    local vy1 = y
    local vy2 = y + bh

    if vy1 < 0 then
        vy1 = 0
        texY1 = (vy1 - y) / bh
    end

    if vy2 > clipH then
        vy2 = clipH
        texY2 = (vy2 - y) / bh
    end

    h = vy2 - vy1

    if h < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)

    if w <= 1.2 then        -- Adjust so we get a clean line
        w = self.Size1
        if w <= 0 then
            frm:SetWidth (.001)
            return
        end
    end

    if h <= 1.2 then
        h = self.Size1
        if h <= 0 then
            frm:SetWidth (.001)
            return
        end
    end

    frm:SetWidth (w)
    frm:SetHeight (h)

    frm.texture:SetTexCoord (Nx.Util_NanToZero(texX1), Nx.Util_NanToZero(texX2), Nx.Util_NanToZero(texY1), Nx.Util_NanToZero(texY2))

    -- Note: SetSnapToPixelGrid/SetTexelSnappingBias now set once at frame creation

    frm:Show()

    return true
end

---
-- Clip a frame to the main carbonite map frame (absolute to TOPLEFT)
-- Used for instance map positioning with rotation support
-- @param frm  Frame to clip
-- @param bx   Zone X coordinate
-- @param by   Zone Y coordinate
-- @param w    Width in pixels
-- @param h    Height in pixels
-- @param dir  Direction/rotation angle in degrees (0 for no rotation)
-- @return     visible, x, y - visibility flag and final screen coordinates
--
function Nx.Map:ClipFrameMF (frm, bx, by, w, h, dir)
    local x, y = Nx.Map:GetZonePos(self.MapId, bx, by)

    local bw = w
    local clipW = self.MapW

    local texX1 = 0
    local texX2 = 1

    local vx0 = x - bw * .5
    local vx1 = vx0
    local vx2 = vx0 + bw

    if vx1 < 0 then
        vx1 = 0
        texX1 = (vx1 - vx0) / bw
    end

    if vx2 > clipW then
        vx2 = clipW
        texX2 = (vx2 - vx0) / bw
    end

    w = vx2 - vx1

    local bh = h
    local clipH = self.MapH

    local texY1 = 0
    local texY2 = 1

    local vy0 = y - bh * .5        -- Center frame at by
    local vy1 = vy0
    local vy2 = vy0 + bh

    if vy1 < 0 then
        vy1 = 0
        texY1 = (vy1 - vy0) / bh
    end

    if vy2 > clipH then
        vy2 = clipH
        texY2 = (vy2 - vy0) / bh
    end

    h = vy2 - vy1

    frm:SetPoint("TOPLEFT", x / 100 * self.MapW - 8, -y  / 100 * self.MapH + 8)

    frm:SetWidth (Nx.db.profile.Map.InstanceScale)
    frm:SetHeight (Nx.db.profile.Map.InstanceScale)

    frm.texture:SetTexCoord (0, 1, 0, 1)

    if dir == 0 then
        if texX1 <= 1 and texX1 >= 0 and texX2 <= 1 and texX2 >= 0 and texY1 <= 1 and texY1 >= 0 and texY2 <= 1 and texY2 >= 0 then
            frm.texture:SetTexCoord (texX1, texX2, texY1, texY2)
        end
    else
        local t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y
        texX1 = texX1 - .5
        texX2 = texX2 - .5
        texY1 = texY1 - .5
        texY2 = texY2 - .5

        local co = cos (dir)
        local si = sin (dir)
        t1x = texX1 * co + texY1 * si + .5
        t1y = texX1 * -si + texY1 * co + .5
        t2x = texX1 * co + texY2 * si + .5
        t2y = texX1 * -si + texY2 * co + .5
        t3x = texX2 * co + texY1 * si + .5
        t3y = texX2 * -si + texY1 * co + .5
        t4x = texX2 * co + texY2 * si + .5
        t4y = texX2 * -si + texY2 * co + .5
        if t1x <= 1 and t1x >= 0 and t2x <= 1 and t2x >= 0 and t3x <= 1 and t3x >= 0 and t4x <= 1 and t4x >= 0 and t1y <= 1 and t1y >= 0 and t2y <= 1 and t2y >= 0 and t3y <= 1 and t3y >= 0 and t4y <= 1 and t4y >= 0 then
            frm.texture:SetTexCoord (t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)
        end
    end
    frm:SetFrameLevel(50)

    -- Note: SetSnapToPixelGrid/SetTexelSnappingBias now set once at frame creation

    frm:Show()

    return true, x, y
end

---
-- Clip a frame to instance map with scroll offset calculation
-- Returns the scroll offsets needed to properly position content
-- @param frm  Frame to clip (typically a ScrollFrame)
-- @param bx   World X coordinate (top-left)
-- @param by   World Y coordinate (top-left)
-- @param w    Width in world units
-- @param h    Height in world units
-- @param ret  Return offset values flag
-- @return     sx1, sy1, sx2, sy2 - scroll offsets for each edge
--
function Nx.Map:ClipFrameINST (frm, bx, by, w, h, ret)

    -- Each world unit maps to a pixel, so w * scale == size in pixels

    local scale = self.ScaleDraw

    -- Calc x

    local bw = w * scale
    local clipW = self.MapW
    local x = (bx - self.MapPosXDraw) * scale + clipW * .5

    local texX1 = 0
    local texX2 = 1

    local sx1 = 0
    local sx2 = 0

    local vx1 = x
    local vx2 = x + bw

    if vx1 < 0 then
        vx1 = 0
        texX1 = (vx1 - x) / bw
        sx1 = vx1 - x
    end

    if vx2 > clipW then
        vx2 = clipW
        texX2 = (vx2 - x) / bw
        sx2 = vx2 - (x + bw)
    end

    w = vx2 - vx1

    if w < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
    end

    -- Calc y

    local bh = h * scale
    local clipH = self.MapH
    local y = (by - self.MapPosYDraw) * scale + clipH * .5

    local texY1 = 0
    local texY2 = 1

    local sy1 = 0
    local sy2 = 0

    local vy1 = y
    local vy2 = y + bh

    if vy1 < 0 then
        vy1 = 0
        texY1 = (vy1 - y) / bh
        sy1 = vy1 - y
    end

    if vy2 > clipH then
        vy2 = clipH
        texY2 = (vy2 - y) / bh
        sy2 = vy2 - (y + bh)
    end

    h = vy2 - vy1

    if h < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
    end

    frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)

    if w <= 1.2 then        -- Adjust so we get a clean line
        --w = self.Size1
        if w <= 0 then
            frm:SetWidth (.001)
            return 0, 0, 0, 0
        end
    end

    if h <= 1.2 then
        --h = self.Size1
        if h <= 0 then
            frm:SetWidth (.001)
            return 0, 0, 0, 0
        end
    end

    frm:SetWidth (w)
    frm:SetHeight (h)
    frm:Show()

    return sx1, sy1, sx2, sy2
end

---
-- Clip a frame to the map and set position (top left), size and texture coords
-- Width and height are scaled by base (zone) scale
-- Solid color texture version - does not calculate texture coordinates
-- @param frm  Frame to clip
-- @param bx   World X coordinate (top-left)
-- @param by   World Y coordinate (top-left)
-- @param w    Width in world units
-- @param h    Height in world units
-- @return     true if visible, false if completely clipped
--
function Nx.Map:ClipFrameTLSolid (frm, bx, by, w, h)

    -- Each world unit maps to a pixel, so w * scale == size in pixels

    local scale = self.ScaleDraw

    -- Calc x

    local clipW = self.MapW
    local vx1 = (bx - self.MapPosXDraw) * scale + clipW * .5
    local vx2 = vx1 + w * scale

    if vx1 < 0 then
        vx1 = 0
    end

    if vx2 > clipW then
        vx2 = clipW
    end

    w = vx2 - vx1

    if w < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    -- Calc y

    local clipH = self.MapH
    local vy1 = (by - self.MapPosYDraw) * scale + clipH * .5
    local vy2 = vy1 + h * scale

    if vy1 < 0 then
        vy1 = 0
    end

    if vy2 > clipH then
        vy2 = clipH
    end

    h = vy2 - vy1

    if h < .3 then
        if self.ScrollingFrm ~= frm then
            frm:Hide()
        else
            frm:SetWidth (.001)
        end
        return false
    end

    frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)

    frm:SetWidth (w)
    frm:SetHeight (h)

    frm:Show()

    return true
end

---
-- Clip and position a full zone frame to the map
-- Used for displaying entire zone textures at the correct scale
-- @param cont   Continent number
-- @param zone   Zone map ID
-- @param frm    Frame to position
-- @param alpha  Alpha transparency value (unused currently)
--
function Nx.Map:ClipZoneFrm (cont, zone, frm, alpha)

    local zname, zx, zy, zw, zh
    zname, zx, zy, zw, zh = self:GetWorldZoneInfo (cont, zone)
    if not zx then
        return
    end

    local scale = self.ScaleDraw

    local clipW = self.MapW
    local clipH = self.MapH
    local x = (zx - self.MapPosXDraw) * scale + clipW / 2
    local y = (zy - self.MapPosYDraw) * scale + clipH / 2
    local bx = 0
    local by = 0
    local bw = zw * scale
    local bh = zh * scale
    local w, h

    local level = self.Level

    if frm then

        local vx0 = bx * bw + x
        local vx1 = vx0
        local vx2 = vx0 + bw

        local vy0 = by * bh + y
        local vy1 = vy0
        local vy2 = vy0 + bh

        w = vx2 - vx1
        h = vy2 - vy1

        if w <= 0 or h <= 0 then
            frm:Hide()
        else
            local sc = w / 1002
            vx1 = vx1 / sc
            vy1 = vy1 / sc
            frm:SetPoint ("TOPLEFT", vx1, -vy1 - self.TitleH)
            frm:SetScale (sc)
            if level then frm:SetFrameLevel (level) end

            frm:Show()

--            Nx.prt ("ClipZF %f, %f (%s)", vx1, vy1, sc)
        end
    end
end

-------------------------------------------------------------------------------
-- ICON TYPE MANAGEMENT
-- Functions for initializing, configuring, and managing map icon types
-- Icon types define how groups of icons are drawn (mode, texture, size, etc.)
-------------------------------------------------------------------------------

---
-- Initialize a map icon type with drawing parameters
-- @param iconType  String identifier for the icon type (e.g. "!QU" for quests)
-- @param drawMode  Drawing mode: "ZP" = zone point, "WP" = world point, "ZR" = zone rect
-- @param texture   Default texture path for this icon type
-- @param w         Default width for icons of this type
-- @param h         Default height for icons of this type
--
function Nx.Map:InitIconType (iconType, drawMode, texture, w, h)

    local d = self.Data

    local t = wipe (d[iconType] or {})
    d[iconType] = t
    t.Num = 0
    t.Enabled = true
    t.DrawMode = drawMode or "ZP"    -- Zone point is default
    t.Tex = texture
    t.W = w
    t.H = h
    t.Scale = 1    -- USED???
end

---
-- Clear/remove a map icon type and all its icons
-- @param iconType  String identifier for the icon type to clear
--
function Nx.Map:ClearIconType (iconType)

    local d = self.Data
    d[iconType] = nil
end

---
-- Set alpha transparency for an icon type
-- @param iconType   String identifier for the icon type
-- @param alpha      Normal alpha value (0-1)
-- @param alphaNear  Alpha when player is near icon (for pulsing effect)
--
function Nx.Map:SetIconTypeAlpha (iconType, alpha, alphaNear)

    local d = self.Data
    assert (d[iconType])

    d[iconType].Alpha = alpha
    d[iconType].AlphaNear = alphaNear
end

---
-- Set minimum scale at which this icon type becomes visible
-- Icons will be hidden when map zoom is below this scale
-- @param iconType  String identifier for the icon type
-- @param scale     Minimum scale threshold for visibility
--
function Nx.Map:SetIconTypeAtScale (iconType, scale)

    local d = self.Data
    assert (d[iconType])

    d[iconType].AtScale = scale
end

---
-- Set frame level offset for an icon type
-- Higher levels render on top of lower levels
-- @param iconType  String identifier for the icon type
-- @param level     Frame level offset to add to base level
--
function Nx.Map:SetIconTypeLevel (iconType, level)

    local d = self.Data
    assert (d[iconType])

    d[iconType].Lvl = level
end

---
-- Enable or disable chopping (edge clipping) for an icon type
-- When enabled, uses ClipFrameWChop for better edge handling
-- @param iconType  String identifier for the icon type
-- @param on        Boolean to enable/disable chopping
--
function Nx.Map:SetIconTypeChop (iconType, on)

    local d = self.Data
    assert (d[iconType])

    d[iconType].ClipFunc = on and self.ClipFrameWChop or self.ClipFrameW
end

---
-- Hide icons of this type when they would overlap the docked minimap
-- @param iconType  String identifier for the icon type
-- @param on        Boolean to enable/disable docked-minimap exclusion
--
function Nx.Map:SetIconTypeNoDockMinimap (iconType, on)

    local d = self.Data
    assert (d[iconType])

    d[iconType].NoDockMinimap = on
end

---
-- Add a point icon to map data
-- @param iconType  String identifier for the icon type (must be initialized)
-- @param x         World X coordinate
-- @param y         World Y coordinate
-- @param level     Dungeon level (nil for surface)
-- @param color     Color hex string (e.g. "FF0000" for red)
-- @param texture   Optional texture path (overrides type default)
-- @param tx1       Texture coord left (0-1)
-- @param ty1       Texture coord top (0-1)
-- @param tx2       Texture coord right (0-1)
-- @param ty2       Texture coord bottom (0-1)
-- @return          Icon table for further customization
--
function Nx.Map:AddIconPt (iconType, x, y, level, color, texture, tx1, ty1, tx2, ty2)
    local d = self.Data

    assert (d[iconType])

    local tdata = d[iconType]
    tdata.Num = tdata.Num + 1 -- Use # instead??

    local icon = {}
    tdata[tdata.Num] = icon

    icon.X = x
    icon.Y = y
    icon.iconType = iconType
    icon.Level = level
    icon.Color = color
    icon.Tex = texture
    if tx1 and ty1 and tx2 and ty2 then
        icon.TX1 = tx1
        icon.TY1 = ty1
        icon.TX2 = tx2
        icon.TY2 = ty2
    end
    assert (tdata.Tex or texture or color)

    return icon
end

---
-- Get the count of icons for a given type
-- @param iconType  String identifier for the icon type
-- @return          Number of icons
--
function Nx.Map:GetIconCnt (iconType)

    return #self.Data[iconType]
end

---
-- Get point icon world position at index
-- Used by routing code to retrieve icon locations
-- @param iconType  String identifier for the icon type
-- @param index     1-based index into the icon array
-- @return          x, y world coordinates (or nil if wrong dungeon level)
--
function Nx.Map:GetIconPt (iconType, index)

    local icon = self.Data[iconType][index]
    if (icon.Level == Nx.Map.DungeonLevel) then
        return icon.X, icon.Y
    end
end

---
-- Add a rectangular icon to map data (zone coordinates)
-- Used for highlighting areas on the map
-- @param iconType  String identifier for the icon type (must be initialized)
-- @param mapId     Map ID the rectangle belongs to
-- @param x         Zone X coordinate of top-left (0-100)
-- @param y         Zone Y coordinate of top-left (0-100)
-- @param x2        Zone X coordinate of bottom-right (0-100)
-- @param y2        Zone Y coordinate of bottom-right (0-100)
-- @param color     Color hex string with alpha (e.g. "80FF0000")
-- @return          Icon table for further customization
--
function Nx.Map:AddIconRect (iconType, mapId, x, y, x2, y2, color)

    local d = self.Data

    assert (d[iconType])

    local tdata = d[iconType]
    tdata.Num = tdata.Num + 1

    local icon = {}
    tdata[tdata.Num] = icon

    icon.MapId = mapId
    icon.X = x
    icon.Y = y
    icon.X2 = x2
    icon.Y2 = y2
    icon.Color = color

    return icon
end

---
-- Set tooltip text for an icon
-- @param icon  Icon table returned from AddIconPt/AddIconRect
-- @param tip   Tooltip string (use ~ for line breaks)
--
function Nx.Map:SetIconTip (icon, tip)
    icon.Tip = tip
end

---
-- Set custom user data on an icon
-- Can store any Lua value for later retrieval
-- @param icon  Icon table returned from AddIconPt/AddIconRect
-- @param data  Any value to associate with this icon
--
function Nx.Map:SetIconUserData (icon, data)
    icon.UData = data
end

---
-- Set favorite-related data on an icon
-- Used by the Notes module for favorite locations
-- @param icon   Icon table returned from AddIconPt/AddIconRect
-- @param data1  First favorite data value
-- @param data2  Second favorite data value
--
function Nx.Map:SetIconFavData (icon, data1, data2)
    icon.FavData1 = data1
    icon.FavData2 = data2
end

---
-- Get favorite-related data from an icon
-- @param icon  Icon table
-- @return      data1, data2 values previously set
--
function Nx.Map:GetIconFavData (icon)
    return icon.FavData1, icon.FavData2
end

--------
-- Update all icons

function Nx.Map:UpdateIcons (drawNonGuide)
    local c2rgb = Nx.Util_c2rgb
    local c2rgba = Nx.Util_c2rgba
    local d = self.Data

    local wpScale = 1
    local wpMin = Nx.db.profile.Map.IconScaleMin
    if wpMin >= 0 then
        wpScale = self.ScaleDraw * .08
    end
    if Nx.Map:GetMap(1).LOpts.NXMMFull then
        return
    end
    for type, v in pairs (d) do
        v.Enabled = drawNonGuide or strbyte (type) == 33    -- "!" is guide types
        if v.AtScale then
            if self.ScaleDraw < v.AtScale then
                v.Enabled = false
            end
        end
        if (self:IsInstanceMap(Nx.Map.UpdateMapID) or self:IsBattleGroundMap(Nx.Map.UpdateMapID)) and self.CurOpts.NXInstanceMaps then
            v.Enabled = true
            v.Lvl = 20
        end
    end
    for k, v in pairs (d) do

--        Nx.prt ("UpdateIcons %s %s", k, v.DrawMode)

        if v.Enabled then

            if v.DrawMode == "ZP" then        -- Zone point
                local scale = self.IconScale
                local w = v.W * scale
                local h = v.H * scale
                -- Cache values outside loop for performance
                local mapDungeonLevel = Nx.Map.DungeonLevel
                local vLvl = v.Lvl
                local vTex = v.Tex

                for n = 1, v.Num do
                    local vn = v[n]
                    if (not vn.Level and mapDungeonLevel == 0) or (vn.Level and vn.Level == mapDungeonLevel) then
                        local icon = vn
                        local f = self:GetIconStatic(vLvl)
                        if self:ClipFrameZ(f, icon.X, icon.Y, w, h, 0) then
                            f.NxTip = icon.Tip

                            local iconTex = icon.Tex
                            if iconTex then
                                f.texture:SetTexture(iconTex)
                                if icon.Color then
                                    f.texture:SetVertexColor(c2rgb(icon.Color))
                                end
                            elseif vTex then
                                f.texture:SetTexture(vTex)
                            else
                                f.texture:SetColorTexture(c2rgb(icon.Color))
                            end
                            if icon.TX1 then
                                f.texture:SetTexCoord(icon.TX1, icon.TY1, icon.TX2, icon.TY2)
                            end
                        end
                    end
                end

            elseif v.DrawMode == "WP" then        -- World point

                local scale = self.IconScale * v.Scale * wpScale
                local w = max (v.W * scale, wpMin)
                local h = max (v.H * scale, wpMin)

                -- Pre-calculate visible bounds for quick culling (huge performance win for many icons)
                local scaleDraw = self.ScaleDraw
                local clipW = self.MapW
                local clipH = self.MapH
                local mapPosX = self.MapPosXDraw
                local mapPosY = self.MapPosYDraw
                -- Calculate world-space bounds of visible area with some margin
                local margin = (w > h and w or h) / scaleDraw
                local visMinX = mapPosX - clipW * 0.5 / scaleDraw - margin
                local visMaxX = mapPosX + clipW * 0.5 / scaleDraw + margin
                local visMinY = mapPosY - clipH * 0.5 / scaleDraw - margin
                local visMaxY = mapPosY + clipH * 0.5 / scaleDraw + margin

                local curMapId = Nx.Map:GetCurrentMapAreaID()
                if self.Win:IsSizeMax() then
                    local myzone = curMapId
                    if (myzone == 87) or (myzone == 125) then
                        w = w / 2
                        h = h / 2
                    end
                end

                if (self:IsInstanceMap(Nx.Map.UpdateMapID) or self:IsBattleGroundMap(Nx.Map.UpdateMapID)) then
                    w = Nx.db.profile.Map.InstanceScale
                    h = Nx.db.profile.Map.InstanceScale
                end

                -- Compute docked-minimap exclusion rect in map-frame pixels for icon types that opt in
                local mmSX1, mmSY1, mmSX2, mmSY2
                if v.NoDockMinimap and self.MMOwn and self.MMZoomType == 0 then
                    local mmSz = 140 * self.MMFScale
                    local mmX = Nx.db.profile.MiniMap.DockRight and (clipW - mmSz) or 0
                    local mmY = Nx.db.profile.MiniMap.DockBottom and (clipH - mmSz) or 0
                    mmSX1 = mmX + (Nx.db.profile.MiniMap.DXO or 0)
                    mmSY1 = mmY + (Nx.db.profile.MiniMap.DYO or 0)
                    mmSX2 = mmSX1 + mmSz
                    mmSY2 = mmSY1 + mmSz
                end

                if v.AlphaNear then

                    local aNear = v.AlphaNear * (abs (GetTime() % .7 - .35) / .7 + .5)    -- 50% to 100% pulse
                    -- Cache values outside loop for performance
                    local mapDungeonLevel = Nx.Map.DungeonLevel
                    local vLvl = v.Lvl
                    local vTex = v.Tex
                    local vAlpha = v.Alpha
                    local plyrX = self.PlyrX
                    local plyrY = self.PlyrY

                    for n = 1, v.Num do
                        local vn = v[n]
                        -- Quick visibility cull before allocating frame
                        local iconX, iconY = vn.X, vn.Y
                        if iconX >= visMinX and iconX <= visMaxX and iconY >= visMinY and iconY <= visMaxY then
                        local skipForDockedMM = false
                        if mmSX1 then
                            local sx = (iconX - self.MapPosXDraw) * scaleDraw + clipW * .5
                            local sy = (iconY - self.MapPosYDraw) * scaleDraw + clipH * .5
                            skipForDockedMM = sx >= mmSX1 and sx <= mmSX2 and sy >= mmSY1 and sy <= mmSY2
                        end
                        if not skipForDockedMM and ((not vn.Level and mapDungeonLevel == 0) or (vn.Level and vn.Level == mapDungeonLevel)) then
                            local icon = vn
                            local f = self:GetIconStatic(vLvl)
                            if self:ClipFrameByMapType (f, icon.X, icon.Y, w, h, 0) then
                                f.NxTip = icon.Tip
                                f.NXType = 3000
                                f.NXData = icon
                                local iconTex = icon.Tex
                                if iconTex then
                                    -- Cache atlas lookup on first use
                                    if icon._isAtlas == nil then
                                        icon._isAtlas = string.find(iconTex, "atlas:") and true or false
                                        if icon._isAtlas then
                                            icon._atlasName = string.sub(iconTex, 7)
                                        end
                                    end
                                    if icon._isAtlas then
                                        f.texture:SetAtlas(icon._atlasName)
                                    else
                                        f.texture:SetTexture(iconTex)
                                    end
                                    if icon.Color then
                                        f.texture:SetVertexColor(c2rgb(icon.Color))
                                    end
                                elseif vTex then
                                    f.texture:SetTexture(vTex)
                                else
                                    f.texture:SetColorTexture(c2rgb(icon.Color))
                                end
                                local a = vAlpha
                                local dist = (icon.X - plyrX) ^ 2 + (icon.Y - plyrY) ^ 2
                                if dist < 306 then    -- 80 yards * 4.575 ^ 2
                                    a = aNear
                                end
                                f.texture:SetVertexColor(1, 1, 1, a)
                            end
                        end
                        end -- visibility cull
                    end
                else
                    -- Cache these values outside the loop for performance
                    local _h = 3 * (668 / 768)
                    local currentDungeonLevel = Nx.Map:GetCurrentMapDungeonLevel()
                    local _dungeonLevel = currentDungeonLevel > 0 and currentDungeonLevel - 1 or 0
                    local isInstanceMap = Nx.Map:IsInstanceMap(Nx.Map.RMapId)
                    local calcOffY = isInstanceMap and not self.CurOpts.NXInstanceMaps
                    local offY = calcOffY and (_h * _dungeonLevel) or 0
                    local mapDungeonLevel = Nx.Map.DungeonLevel
                    local vLvl = v.Lvl
                    local vTex = v.Tex
                    local vAlpha = v.Alpha
                    local frameLevelBase = self.Level + (vLvl or 0)

                    for n = 1, v.Num do
                        local vn = v[n]
                        -- Quick visibility cull before allocating frame
                        local iconX, iconY = vn.X, vn.Y
                        if iconX >= visMinX and iconX <= visMaxX and iconY >= visMinY and iconY <= visMaxY then
                        local Level = vn.Level
                        local skipForDockedMM = false
                        if mmSX1 then
                            local sx = (iconX - self.MapPosXDraw) * scaleDraw + clipW * .5
                            local sy = ((iconY + offY) - self.MapPosYDraw) * scaleDraw + clipH * .5
                            skipForDockedMM = sx >= mmSX1 and sx <= mmSX2 and sy >= mmSY1 and sy <= mmSY2
                        end
                        if not skipForDockedMM and ((not Level and mapDungeonLevel == 0) or (Level and Level == mapDungeonLevel)) then
                            local icon = vn
                            local iconTex = icon.Tex
                            local actuallyIcon = type(iconTex) == "table"
                            local f
                            if actuallyIcon then
                                f = iconTex
                            else
                                f = self:GetIconStatic(vLvl)
                            end
                            if self:ClipFrameByMapType (f, iconX, iconY + offY, w, h, 0) then
                                f.NxTip = icon.Tip
                                f.NXType = 3000
                                f.NXData = icon
                                if actuallyIcon then
                                    f:SetFrameLevel(frameLevelBase)
                                elseif iconTex then
                                    -- Cache atlas lookup on first use
                                    if icon._isAtlas == nil then
                                        icon._isAtlas = string.find(iconTex, "atlas:") and true or false
                                        if icon._isAtlas then
                                            icon._atlasName = string.sub(iconTex, 7)
                                        end
                                    end
                                    if icon._isAtlas then
                                        f.texture:SetAtlas(icon._atlasName)
                                    else
                                        f.texture:SetTexture(iconTex)
                                    end
                                    if icon.Color then
                                        f.texture:SetVertexColor(c2rgb(icon.Color))
                                    end
                                elseif vTex then
                                    f.texture:SetTexture(vTex)
                                else
                                    f.texture:SetColorTexture(c2rgb(icon.Color))
                                end
                                if vAlpha and not actuallyIcon then
                                    f.texture:SetVertexColor(1, 1, 1, vAlpha)
                                end
                                if icon.TX1 then
                                    f.texture:SetTexCoord(icon.TX1, icon.TY1, icon.TX2, icon.TY2)
                                end
                            end
                        end
                        end -- visibility cull
                    end
                end
            elseif v.DrawMode == "ZR" then    -- Zone rectangle
                local x, y, x2, y2
--                local x0, y0, x2, y2 = self:GetWorldRect (self.MapId, 0, 0, 100, 100)

                for n = 1, v.Num do
                    if (not v[n].Level and Nx.Map.DungeonLevel == 0) or (v[n].Level and v[n].Level == Nx.Map.DungeonLevel) then
                        local icon = v[n]
                        local f = self:GetIconStatic (v.Lvl)
--                        Nx.prt ("ZR #%d %f %f %f %f", n, icon.X, icon.Y, icon.X2, icon.Y2)

                        f.NxTip = icon.Tip

                        x, y = self:GetWorldPos (icon.MapId, icon.X, icon.Y)
                        x2, y2 = self:GetWorldPos (icon.MapId, icon.X2, icon.Y2)

    --                    Nx.prt ("%f %f %f %f", x, y, x2, y2)

                        if self:ClipFrameTL (f, x, y, x2-x, y2-y) then
                            if v.Texture then
                                f.texture:SetTexture (v.Tex)
                            else
                                f.texture:SetColorTexture (c2rgba (icon.Color))
                            end
                        end
                    end
                end
            end
        end
    end
    if Nx.Map:GetCurrentMapAreaID() == 85 and Nx.Map.DungeonLevel == 0 then
        Nx.Map.DungeonLevel = 1
    end
end

------
-- Reset icons

function Nx.Map:ResetIcons()

    local frms = self.IconFrms
    frms.Used = frms.Next - 1        -- Save last frame used
    frms.Next = 1

    local frms = self.IconNIFrms
    frms.Used = frms.Next - 1        -- Save last frame used
    frms.Next = 1

    local frms = self.IconStaticFrms
    frms.Used = frms.Next - 1        -- Save last frame used
    frms.Next = 1

    local data = self.TextFStrs
    data.Used = data.Next - 1        -- Save last used
    data.Next = 1

    local data = self.IconWQFrms
    data.Used = data.Next - 1        -- Save last used
    -- Track the maximum icons ever used (high-water mark) to ensure stale icons get hidden
    data.MaxUsed = max(data.MaxUsed or 0, data.Used)
    data.Next = 1
end

------
-- Hide extra icons (a hide and then show will reset mouse state, breaking OnMouseUp)

function Nx.Map:HideExtraIcons()

    local frms = self.IconFrms

    for n = frms.Next, frms.Used do        -- Hide up to last frames used amount
        frms[n]:Hide()
    end

    local frms = self.IconNIFrms

    for n = frms.Next, frms.Used do        -- Hide up to last frames used amount
        frms[n]:Hide()
    end

    local frms = self.IconStaticFrms

    for n = frms.Next, frms.Used do        -- Hide up to last frames used amount
        frms[n]:Hide()
    end

    local data = self.TextFStrs

    for n = data.Next, data.Used do        -- Hide up to last used amount
        data[n]:Hide()
    end

    local data = self.IconWQFrms

    for n = data.Next, data.Used do        -- Hide up to last used amount
        data[n]:Hide()
    end

    -- Also hide any icons beyond Used that might be visible (fixes stale icons on window activation)
    -- This covers edge cases where icons were shown outside the normal update cycle
    local maxWQ = data.MaxUsed or data.Used
    for n = data.Used + 1, maxWQ do
        if data[n] then
            data[n]:Hide()
        end
    end
end

------
-- Get next available map icon or create one
-- ret: icon frame

function Nx.Map:GetIcon (levelAdd)

    local frms = self.IconFrms
    local pos = frms.Next

    if pos > 1500 then
        pos = 1500    -- Too many used. Reuse
    end

    local f = frms[pos]
    if not f then

        f = CreateFrame ("Frame", "NxIcon"..pos, self.Frm)
        frms[pos] = f
        f.NxMap = self

        f:SetScript ("OnMouseDown", self.IconOnMouseDown)
        f:SetScript ("OnMouseUp", self.IconOnMouseUp)
        f:SetScript ("OnEnter", self.IconOnEnter)
        f:SetScript ("OnLeave", self.IconOnLeave)
        f:SetScript ("OnHide", self.IconOnLeave)

        f:EnableMouse (true)

        local t = f:CreateTexture()
        f.texture = t
        t:SetAllPoints (f)
        t:SetSnapToPixelGrid(false)
        t:SetTexelSnappingBias(0)
    end

    f:SetFrameLevel (self.Level + (levelAdd or 0))

    f.texture:SetVertexColor (1, 1, 1, 1)
--    f.texture:SetBlendMode ("BLEND")
    -- Reset texture coordinates to prevent stretched textures from previous atlas use
    f.texture:SetTexCoord (0, 1, 0, 1)

    f.NxTip = nil
    f.NXType = nil            -- 1000 plyr, 2000 BG, 3000 POI, 8000 debug, 8500 quest offer, 9000+ quest
    f.NXData = nil
    f.NXData2 = nil
    f.NxQuestOffer = nil      -- Clear quest offer flag
    f.NxPoiInfo = nil         -- Clear POI data to prevent stale tooltips on reused frames
    f.NxWidgetSet = nil
    f.NxAreaPoiID = nil
    f.GetPoiInfo = nil
    f.HasDisplayName = nil
    f.GetDisplayName = nil
    f.GetLinkedUIMapID = nil

    frms.Next = pos + 1

    return f
end

------
-- Get next available map icon for WorldQuest or create one
-- ret: icon frame

function Nx.Map:GetIconWQ (levelAdd)

    local frms = self.IconWQFrms
    local pos = frms.Next

    if pos > 1500 then
        pos = 1500    -- Too many used. Reuse
    end

    local f = frms[pos]
    if not f then

        f = CreateFrame ("Button", "NxIconWQ"..pos, self.Frm)
        frms[pos] = f
        f.NxMap = self

        f:EnableMouse (true)

        local t = f:CreateTexture()
        f.texture = t
        t:SetAllPoints (f)
        f.texture:SetSnapToPixelGrid(false)
        f.texture:SetTexelSnappingBias(0)

        f:SetFlattensRenderLayers(true);

        f.Texture = f:CreateTexture(f:GetName().."Texture", "BACKGROUND");

        f.Glow = f:CreateTexture(f:GetName().."Glow", "BACKGROUND");
        f.Glow:SetSize(50, 50);
        f.Glow:SetPoint("CENTER");
        f.Glow:SetTexture("Interface/WorldMap/UI-QuestPoi-IconGlow.tga");
        f.Glow:SetBlendMode("ADD");
        f.Glow:SetSnapToPixelGrid(false)
        f.Glow:SetTexelSnappingBias(0)

        f.CriteriaMatchRing = f:CreateTexture(f:GetName().."CriteriaMatchRing", "BACKGROUND", nil);
        f.CriteriaMatchRing:SetAtlas("worldquest-emissary-ring", true)
        f.CriteriaMatchRing:SetPoint("CENTER", 0, 0)

        f.SelectedGlow = f:CreateTexture(f:GetName().."SelectedGlow", "OVERLAY");
        f.SelectedGlow:SetBlendMode("ADD");
        f.SelectedGlow:SetSnapToPixelGrid(false)
        f.SelectedGlow:SetTexelSnappingBias(0)

        f.CriteriaMatchGlow = f:CreateTexture(f:GetName().."CriteriaMatchGlow", "BACKGROUND");
        f.CriteriaMatchGlow:SetAlpha(.6);
        f.CriteriaMatchGlow:SetBlendMode("ADD");
        f.CriteriaMatchGlow:SetSnapToPixelGrid(false)
        f.CriteriaMatchGlow:SetTexelSnappingBias(0)

        f.SpellTargetGlow = f:CreateTexture(f:GetName().."SpellTargetGlow", "OVERLAY");
        f.SpellTargetGlow:SetAtlas("worldquest-questmarker-abilityhighlight", true);
        f.SpellTargetGlow:SetAlpha(.6);
        f.SpellTargetGlow:SetBlendMode("ADD");
        f.SpellTargetGlow:SetPoint("CENTER", 0, 0);
        f.SpellTargetGlow:SetSnapToPixelGrid(false)
        f.SpellTargetGlow:SetTexelSnappingBias(0)

        f.Underlay = f:CreateTexture(f:GetName().."Underlay", "BACKGROUND");
        f.Underlay:SetWidth(34);
        f.Underlay:SetHeight(34);
        f.Underlay:SetPoint("CENTER", 0, -1);
        f.Underlay:SetSnapToPixelGrid(false)
        f.Underlay:SetTexelSnappingBias(0)

        f.TimeLowFrame = CreateFrame("Frame", nil, f);
        f.TimeLowFrame:SetSize(22, 22);
        f.TimeLowFrame:SetPoint("CENTER", -10, -10);
        f.TimeLowFrame.Texture = f.TimeLowFrame:CreateTexture(nil, "OVERLAY");
        f.TimeLowFrame.Texture:SetAllPoints(f.TimeLowFrame);
        f.TimeLowFrame.Texture:SetAtlas("worldquest-icon-clock");

        -- Set size and texture properties once on creation
        f:SetWidth(32);
        f:SetHeight(32);
        f.Texture:SetWidth(28);
        f.Texture:SetHeight(28);
        f.Texture:SetPoint("CENTER", 0, 0);
        f.Texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
        f.Texture:SetSnapToPixelGrid(false)
        f.Texture:SetTexelSnappingBias(0)

        -- Stub methods for Blizzard WorldMapFrame compatibility
        f.OnLegendPinMouseEnter = function() end
        f.OnLegendPinMouseLeave = function() end

        -- Set scripts only once on creation (not every frame)
        f:SetScript ("OnEnter", function (self)
            TaskPOI_OnEnter(self)
        end)
        f:SetScript ("OnLeave", TaskPOI_OnLeave)
    end

    -- Only update highlight texture if it exists (rare case)
    if f.HighlightTexture and not f.HighlightTextureSet then
        f.HighlightTexture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
        f.HighlightTexture:SetSnapToPixelGrid(false)
        f.HighlightTexture:SetTexelSnappingBias(0)
        f.HighlightTextureSet = true
    end

    f:SetFrameLevel (self.Level + (levelAdd or 0))

    --f.texture:SetVertexColor (1, 1, 1, 1)

    f.NxTip = nil
    f.NXType = nil            -- 1000 plyr, 2000 BG, 3000 POI, 8000 debug, 8500 quest offer, 9000+ quest
    f.NXData = nil
    f.NXData2 = nil
    f.NxQuestOffer = nil      -- Clear quest offer flag

    frms.Next = pos + 1

    return f
end

------
-- Get next available map non interactive icon or create one
-- ret: icon frame

function Nx.Map:GetIconNI (levelAdd)

    local frms = self.IconNIFrms
    local pos = frms.Next

    if pos > 1500 then
        pos = 1500    -- Too many used. Reuse
    end

    local f = frms[pos]
    if not f then

        f = CreateFrame ("Frame", "NxIconNI"..pos, self.Frm)
        frms[pos] = f
        f.NxMap = self

        local t = f:CreateTexture()
        f.texture = t
        t:SetAllPoints (f)
        t:SetSnapToPixelGrid(false)
        t:SetTexelSnappingBias(0)
    end

    -- Explicitly disable mouse on every fetch. These frames are used
    -- only for the directional path arrows from player -> goto target;
    -- any click on them would otherwise eat clicks meant for quest
    -- icons stacked underneath (the user reported clicks not
    -- registering whenever the path arrows visually overlapped the
    -- destination icon on TBC).
    f:EnableMouse(false)

    local add = levelAdd or 0
    f:SetFrameLevel (self.Level + add)

    f.texture:SetVertexColor (1, 1, 1, 1)
    f.texture:SetBlendMode ("BLEND")
    -- Reset texture coordinates to prevent stretched textures from previous atlas use
    f.texture:SetTexCoord (0, 1, 0, 1)

    frms.Next = pos + 1

    return f
end

------
-- Get next available map static (for non moving stuff) icon or create one
-- ret: icon frame

function Nx.Map:GetIconStatic (levelAdd)

    local frms = self.IconStaticFrms
    local pos = frms.Next

    if pos > 1500 then
        pos = 1500    -- Too many used. Reuse
    end

    local f = frms[pos]
    if not f then

        f = CreateFrame ("Frame", "NxIconS"..pos, self.Frm)
        frms[pos] = f
        f.NxMap = self

        f:SetScript ("OnMouseDown", self.IconOnMouseDown)
        f:SetScript ("OnMouseUp", self.IconOnMouseUp)
        f:SetScript ("OnEnter", self.IconOnEnter)
        f:SetScript ("OnLeave", self.IconOnLeave)
        f:SetScript ("OnHide", self.IconOnLeave)

        f:EnableMouse (true)

        local t = f:CreateTexture()
        f.texture = t
        t:SetAllPoints (f)
        t:SetSnapToPixelGrid(false)
        t:SetTexelSnappingBias(0)

        -- Halo texture used when this icon is the super-tracked POI.
        -- Drawn behind the main texture (BACKGROUND layer), additive
        -- blend so it brightens whatever's underneath. Same Blizzard
        -- texture the world quest icons already use for their glow.
        local g = f:CreateTexture(nil, "BACKGROUND")
        f.NxGlow = g
        g:SetTexture("Interface\\WorldMap\\UI-QuestPoi-IconGlow")
        g:SetBlendMode("ADD")
        g:SetSnapToPixelGrid(false)
        g:SetTexelSnappingBias(0)
        g:SetSize(40, 40)
        g:SetPoint("CENTER")
        g:SetVertexColor(1, 0.9, 0.4, 1)
        g:Hide()

        -- Objective-number label drawn over the icon for per-objective
        -- POIs. Lets users match map markers to watch-list rows when
        -- a quest has multiple POIs (e.g. "kill 3 things in 3 places").
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.NxLabel = lbl
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetTextColor(1, 1, 1, 1)
        lbl:SetShadowColor(0, 0, 0, 1)
        lbl:SetShadowOffset(1, -1)
        lbl:Hide()
    end

    local add = levelAdd or 0
    f:SetFrameLevel (self.Level + add)

    f.texture:SetVertexColor (1, 1, 1, 1)
--    f.texture:SetBlendMode ("BLEND")
    -- Reset texture coordinates to prevent stretched textures from previous atlas use
    f.texture:SetTexCoord (0, 1, 0, 1)

    -- Default glow / label off; UpdateIcons turns them on as needed.
    if f.NxGlow then
        f.NxGlow:Hide()
    end
    if f.NxLabel then
        f.NxLabel:SetText("")
        f.NxLabel:Hide()
    end

    f.NxTip = nil
    f.NXType = nil            -- 1000 plyr, 2000 BG, 3000 POI, 8000 debug, 8500 quest offer, 9000+ quest
    f.NXData = nil
    f.NXData2 = nil
    f.NxQuestOffer = nil      -- Clear quest offer flag
    f.NxPoiInfo = nil         -- Clear POI data to prevent stale tooltips on reused frames
    f.NxWidgetSet = nil
    f.NxAreaPoiID = nil
    f.GetPoiInfo = nil
    f.HasDisplayName = nil
    f.GetDisplayName = nil
    f.GetLinkedUIMapID = nil

    frms.Next = pos + 1

    return f
end

------
-- Pre-allocate icon frames to avoid runtime frame creation lag
-- Call this during initialization or loading screens
-- count: number of each icon type to pre-create (default 200)

function Nx.Map:PreAllocateIcons (count)
    count = count or 200

    -- Pre-allocate regular icons
    local frms = self.IconFrms
    for i = 1, count do
        if not frms[i] then
            local f = CreateFrame ("Frame", "NxIcon"..i, self.Frm)
            frms[i] = f
            f.NxMap = self
            f:SetScript ("OnMouseDown", self.IconOnMouseDown)
            f:SetScript ("OnMouseUp", self.IconOnMouseUp)
            f:SetScript ("OnEnter", self.IconOnEnter)
            f:SetScript ("OnLeave", self.IconOnLeave)
            f:SetScript ("OnHide", self.IconOnLeave)
            f:EnableMouse (true)
            local t = f:CreateTexture()
            f.texture = t
            t:SetAllPoints (f)
            t:SetSnapToPixelGrid(false)
            t:SetTexelSnappingBias(0)
            f:Hide()
        end
    end

    -- Pre-allocate non-interactive icons
    frms = self.IconNIFrms
    for i = 1, count do
        if not frms[i] then
            local f = CreateFrame ("Frame", "NxIconNI"..i, self.Frm)
            frms[i] = f
            f.NxMap = self
            local t = f:CreateTexture()
            f.texture = t
            t:SetAllPoints (f)
            t:SetSnapToPixelGrid(false)
            t:SetTexelSnappingBias(0)
            f:Hide()
        end
    end

    -- Pre-allocate static icons
    frms = self.IconStaticFrms
    for i = 1, count do
        if not frms[i] then
            local f = CreateFrame ("Frame", "NxIconS"..i, self.Frm)
            frms[i] = f
            f.NxMap = self
            f:SetScript ("OnMouseDown", self.IconOnMouseDown)
            f:SetScript ("OnMouseUp", self.IconOnMouseUp)
            f:SetScript ("OnEnter", self.IconOnEnter)
            f:SetScript ("OnLeave", self.IconOnLeave)
            f:SetScript ("OnHide", self.IconOnLeave)
            f:EnableMouse (true)
            local t = f:CreateTexture()
            f.texture = t
            t:SetAllPoints (f)
            t:SetSnapToPixelGrid(false)
            t:SetTexelSnappingBias(0)
            f:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- ICON MOUSE HANDLERS
-- Handle mouse interactions with map icons
-------------------------------------------------------------------------------

---
-- Handle mouse down on an icon
-- @param button  Mouse button pressed
--
function Nx.Map:IconOnMouseDown(button)
    local this = self

    local map = this.NxMap
    map:CalcClick()
    map.ClickFrm = this
    map.ClickType = this.NXType
    map.ClickIcon = this.NXData
    local shift = IsShiftKeyDown()

    if button == "LeftButton" then
        -- Determine icon category (type / 1000)
        local cat = floor((this.NXType or 0) / 1000)

        if cat == 2 and shift then
            -- BG location with shift - increment incoming counter
            if map.BGIncNum > 0 then
                local _, _, _, str = Nx.Split("~", map.BGMsg)
                local _, _, _, str2 = Nx.Split("~", this.NXData)
                -- Different node check (placeholder)
            end

            map.BGMsg = this.NXData
            map.BGIncNum = map.BGIncNum + 1

            UIErrorsFrame:AddMessage("Inc " .. map.BGIncNum, 1, 1, 1, 1)

            BGInc = Nx:ScheduleTimer(map.BGIncSendTimer, 1.5, map)
        else
            -- Check for double click
            if map:IsDoubleClick() then
                if cat == 3 then
                    map:GMenu_OnGoto()
                end
            else
                -- Handle Quest Hub click - toggle quest offers display
                if cat == 4 and this.NXData and this.NXData.hubPoiID then
                    local hubData = this.NXData
                    Nx.Map.QuestHubToggles = Nx.Map.QuestHubToggles or {}
                    local hubKey = hubData.mapID .. "_" .. hubData.hubPoiID

                    -- Toggle the hub's expanded state
                    Nx.Map.QuestHubToggles[hubKey] = not Nx.Map.QuestHubToggles[hubKey]

                    -- Force map update to show/hide quest offers
                    if Nx.Quest and Nx.Quest.QuestOfferCacheTime then
                        Nx.Quest.QuestOfferCacheTime = 0  -- Invalidate cache to refresh
                    end

                    --local state = Nx.Map.QuestHubToggles[hubKey] and "shown" or "hidden"
                    --Nx.prt("|cff00ff00" .. (hubData.name or "Quest Hub") .. "|r offers " .. state)

                    return  -- Don't process further
                -- Handle RareScanner integration. Entity pins implement
                -- OnMouseDown (RSEntityPinMixin); group pins (RSGroupPinMixin)
                -- don't, so we guard the call. The overlay-icon refresh
                -- still fires regardless.
                elseif map.ClickIcon and map.ClickIcon.iconType == "!RSR" and RareScanner then
                    local rspin = this.NXData.UData
                    if rspin then
                        if not rspin.owningMap then
                            rspin.owningMap = WorldMapFrame
                        end
                        if rspin.OnMouseDown then
                            rspin:OnMouseDown(button)
                        end
                        Nx.Notes.PrevRSPins = 0
                        Nx.Notes:RareScanner(map.MapId)
                    end
                elseif cat == 9 then
                    -- Quest icon left-click → set the active quest. On retail /
                    -- Wrath+ Classic where C_SuperTrack exists this calls
                    -- Blizzard's super-track API and Carbonite's
                    -- OnSuperTrackChanged listener mirrors it into our
                    -- Tracking table. On Classic Era / TBC we polyfill by
                    -- toggling Carbonite tracking directly so the user gets
                    -- the same one-click "make this the active quest" UX.
                    local cur = this.NXData
                    local qId = cur and cur.QId
                    -- Encode the per-objective index in NXType (renderer uses
                    -- 9000 for start/end icons and 9000+N for objective N).
                    -- Capture it so we can re-target the arrow at the actual
                    -- objective the user clicked, not whatever default the
                    -- super-track listener picks (which on classic falls back
                    -- to the static End coord).
                    local objI = ((this.NXType or 0) - 9000)
                    if objI < 0 or objI > 15 then objI = 0 end
                    if qId and qId > 0 then
                        -- cur.QId can drift (saved-vars, etc.); resolve the
                        -- live questID from the log index before calling
                        -- Blizzard's API or it will silently reject.
                        local liveQID = qId
                        local qIndex = cur.QI
                        if qIndex and qIndex > 0 then
                            if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
                                local q = C_QuestLog.GetQuestIDForLogIndex(qIndex)
                                if q and q > 0 then liveQID = q end
                            elseif GetQuestIDFromLogIndex then
                                local q = GetQuestIDFromLogIndex(qIndex)
                                if q and q > 0 then liveQID = q end
                            end
                        end
                        -- Compute toggle state BEFORE invoking any setter.
                        -- The "click the active icon to clear" UX matches the
                        -- whole pair (qId, objI), so clicking objective 1
                        -- while objective 2 is active switches arrows rather
                        -- than toggling the quest off, and clicking the same
                        -- objective twice clears both super-track + arrow.
                        local activeQID = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
                                            and C_SuperTrack.GetSuperTrackedQuestID()) or 0
                        if activeQID == 0 and Nx.Quest then
                            activeQID = Nx.Quest.ActiveQID or 0
                        end
                        local activeObjI = (Nx.Quest and Nx.Quest.ActiveObjI) or 0
                        local toggleOff = (activeQID == liveQID and activeObjI == objI)

                        local _prevAddWatchSuppress
                        if Nx.Quest then
                            _prevAddWatchSuppress = Nx.Quest._addWatchSuppress
                            Nx.Quest._addWatchSuppress = true
                        end

                        if toggleOff then
                            -- Mark the clear as user-initiated so
                            -- OnSuperTrackChanged's "restore previous"
                            -- guard doesn't immediately re-apply the
                            -- quest. Cleared again inside the listener.
                            if Nx.Quest then
                                Nx.Quest.UserClearedActive = true
                            end
                            if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                                C_SuperTrack.SetSuperTrackedQuestID(0)
                            elseif Nx.Quest and Nx.Quest.SetActiveCarboniteQuest then
                                -- Polyfill on classic — second call with the
                                -- same id clears (toggle behavior).
                                Nx.Quest:SetActiveCarboniteQuest(qId, cur.QI)
                            end
                            if Nx.Quest then
                                Nx.Quest.ActiveQID = 0
                                Nx.Quest.ActiveObjI = 0
                                if Nx.Quest.Tracking then
                                    Nx.Quest.Tracking[qId] = nil
                                end
                                -- Drop watch so the next refresh tick
                                -- doesn't see the quest as still-watched
                                -- and re-create the goto arrow target
                                -- via Watch:Update / RecordQuestsLog.
                                local id = cur and cur.QId or qId
                                if id and Nx.Quest:GetQuest(id) == "W"
                                   and Nx.Quest.Watch and Nx.Quest.Watch.RemoveWatch then
                                    Nx.Quest.Watch:RemoveWatch(qId, cur.QI)
                                end
                            end
                            -- Clear the goto arrow so it doesn't keep
                            -- pointing at the now-deactivated objective.
                            if map.ClearTargets then map:ClearTargets() end
                            if PlaySound and SOUNDKIT then
                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                            end
                        else
                            if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                                if C_SuperTrack.SetSuperTrackedUserWaypoint
                                   and C_SuperTrack.IsSuperTrackingUserWaypoint
                                   and C_SuperTrack.IsSuperTrackingUserWaypoint() then
                                    C_SuperTrack.SetSuperTrackedUserWaypoint(false)
                                end
                                if C_SuperTrack.ClearAllSuperTracked then
                                    C_SuperTrack.ClearAllSuperTracked()
                                end
                                C_SuperTrack.SetSuperTrackedQuestID(liveQID)
                            elseif Nx.Quest and Nx.Quest.SetActiveCarboniteQuest then
                                -- Classic Era / TBC: no C_SuperTrack. Use
                                -- Carbonite's own active-quest state. The
                                -- polyfill toggles, so call it only when
                                -- the quest isn't already active to avoid
                                -- clearing here.
                                if activeQID ~= qId then
                                    Nx.Quest:SetActiveCarboniteQuest(qId, cur.QI)
                                end
                            else
                                map.OnMouseDown(map.Frm, button)
                            end
                            if Nx.Quest then Nx.Quest.ActiveObjI = objI end
                            -- Re-target the arrow at the specific objective
                            -- the user clicked (super-track + classic active
                            -- both default to qObj=0 routing, which on
                            -- classic falls back to the static End coord).
                            if objI > 0 and Nx.Quest and Nx.Quest.TrackOnMap then
                                Nx.Quest:TrackOnMap(qId, objI,
                                    cur.QI and cur.QI > 0, true)
                            end
                            if PlaySound and SOUNDKIT then
                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                            end
                        end
                        if Nx.Quest then
                            Nx.Quest._addWatchSuppress = _prevAddWatchSuppress
                        end
                    else
                        map.OnMouseDown(map.Frm, button)
                    end
                else
                    map.OnMouseDown(map.Frm, button)
                end
            end
        end
    else
        -- Right button and other buttons
        if button == "RightButton" then
            local typ = this.NXType

            if typ then
                local i = floor(typ / 1000)

                if i == 1 then
                    -- Player icon - show player menu
                    map:BuildPlyrLists()
                    map.PIconMenu:Open()

                elseif i == 2 then
                    -- BG location - show BG menu
                    map.BGMsg = this.NXData
                    map.BGIconMenu:Open()

                elseif i == 3 then
                    -- General icon - show general menu
                    map:GMenuOpen(this.NXData, typ)

                elseif i == 9 then
                    -- Quest icon
                    Nx.Quest:IconOnMouseDown(this)
                end
            end
        else
            map.OnMouseDown(map.Frm, button)
        end
    end
end

---
-- Build list of players under cursor
-- Used for tooltips showing multiple overlapping players
--
function Nx.Map:BuildPlyrLists()
    local Map = Nx.Map

    Map.PlyrNames = {}
    Map.AFKers = {}
    local tipStr = ""

    local frms = self.IconFrms
    local f

    -- Check all icon frames for player icons under cursor
    for n = 1, frms.Next - 1 do
        f = frms[n]
        local plyr = f.NXType == 1000 and f.NXData2

        if plyr then
            local x, y = Nx.Util_IsMouseOver(f)
            if x then
                tinsert(Map.PlyrNames, plyr)

                if f.NXData then
                    tinsert(Map.AFKers, f.NXData)
                end
            end
        end
    end

    -- Build tooltip string if multiple players
    if #Map.PlyrNames >= 2 then
        tipStr = format("\n\n|cff00cf00%s " .. L["players"] .. ":", #Map.PlyrNames)

        sort(Map.PlyrNames)

        for _, name in ipairs(Map.PlyrNames) do
            tipStr = tipStr .. "\n" .. name
        end
    end

    Map.PlyrNamesTipStr = tipStr
end

---
-- Handle mouse up on an icon
-- @param button  Mouse button released
--
function Nx.Map:IconOnMouseUp(button)
    local this = self
    this.NxMap.OnMouseUp(this.NxMap.Frm, button)

    -- Fire target callback if present
    local target = this.NxTarget
    if target then
        local callbacks = target.TargetCallbacks
        if callbacks and callbacks.OnClick then
            callbacks.OnClick(target, this)
        end
    end
end

---
-- Handle mouse entering an icon
-- Shows tooltip and handles addon integration
-- @param motion  Motion flag
--
function Nx.Map:IconOnEnter(motion)

    local this = self            --V4

--    Nx.prt ("MapIconEnter %s", this:GetName() or "nil")

    local map = this.NxMap

    if this.NXData then
        if this.NXData.iconType == "!RSR" and RareScanner then
            local rspin = this.NXData.UData
            if rspin and rspin.OnMouseEnter then
                -- Cancel the leave ticker if a previous mouseout queued one;
                -- otherwise it could fire after re-entering and close the
                -- popup we just re-opened.
                if rspin._NxLeaveTicker then
                    rspin._NxLeaveTicker:Cancel()
                    rspin._NxLeaveTicker = nil
                end
                rspin:OnMouseEnter()
                tooltip = ExtToolTip:Acquire("RsSimpleMapToolTip")
                tooltip:SmartAnchorTo(self)
                this.NxTip = nil

                -- For group pins RS opens a separate `groupTooltip` and
                -- anchors it to the rspin frame (which lives on RareScanner's
                -- private RSWorldMap canvas, off-screen for our merged map).
                -- Re-anchor that tooltip to our Carbonite icon so it shows
                -- at the cursor. We use the tooltip's own SmartAnchorTo so
                -- it picks a side based on remaining screen space, and we
                -- DON'T touch the rspin frame itself — doing so just gets
                -- fought by RS's own UpdateScale loop.
                if rspin.pinTemplate == "RSGroupPinTemplate" and rspin.groupTooltip then
                    local gt = rspin.groupTooltip
                    gt:ClearAllPoints()
                    if gt.SmartAnchorTo then
                        gt:SmartAnchorTo(self)
                    else
                        gt:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0)
                    end
                    gt:SetClampedToScreen(true)
                end
            end
        end

        if this.NXData.iconType == "!QUE" and Questie then
            -- qpin here is Questie's IconFrame (formerly the HBD pin's `.icon`).
            -- Tooltip text comes from QuestieTooltips lookups against the
            -- frame's IconData (qpin.data); the old code's qpin:OnMouseEnter()
            -- was a vestigial no-op on the HBD pin and has been removed.
            local qpin = this.NXData.UData
            local data = qpin and qpin.data
            local QuestieTooltips = QuestieLoader and QuestieLoader._modules["QuestieTooltips"]
            local TooltipText = ""
            if QuestieTooltips and data then
                if data.Type == "available" then
                    local TooltipKeys = QuestieTooltips.lookupKeysByQuestId[data.Id]
                    if TooltipKeys then
                        for _, TooltipKey in ipairs(TooltipKeys) do
                            local TooltipLines = QuestieTooltips.GetTooltip(TooltipKey)
                            for _, TooltipData in pairs(QuestieTooltips.lookupByKey[TooltipKey]) do
                                if TooltipData.name == data.Name then
                                    TooltipText = format("|cff00ff00%s", TooltipData.name)
                                    if TooltipLines then
                                        TooltipText = TooltipText .. "\n" .. table.concat(TooltipLines, "\n")
                                    end
                                end
                            end
                        end
                    end
                else
                    if data.ObjectiveTargetId then
                        TooltipLines = QuestieTooltips.GetTooltip("m_" .. data.ObjectiveTargetId)
                                    or QuestieTooltips.GetTooltip("o_" .. data.ObjectiveTargetId)
                                    or QuestieTooltips.GetTooltip("i_" .. data.ObjectiveTargetId)
                        if TooltipLines then
                            if TooltipText == "" then
                                TooltipText = table.concat(TooltipLines, "\n")
                            else
                                TooltipText = TooltipText .. "\n" .. table.concat(TooltipLines, "\n")
                            end
                        end
                    end
                end
                this.NxTip = TooltipText
            end
        end
    end

--    map.BackgndAlphaTarget = map.BackgndAlphaFull

    map:BuildPlyrLists()

    --        Nx.prt ("MapIconEnter %s %s", this:GetName() or "nil", this.NxTip)

    local tt = Nx.TooltipText
    local owner = this
    local tippos = "ANCHOR_CURSOR"

    if Nx.db.profile.Map.TopTooltip then
        owner = map.Win.Frm
        tippos = "ANCHOR_TOPLEFT"
    end

    owner.NXIconFrm = this

--        Nx.TooltipOwner = owner
--        map.TooltipType = 2

    Nx.TooltipText:SetOwner (owner, tippos, 0, 0)
    owner["UpdateTooltip"] = Nx.Map.IconOnUpdateTooltip

    local target = this.NxTarget;
    if target then
        local callbacks = target.TargetCallbacks;
        if callbacks then
            local onShow = callbacks.OnTooltipShow;
            if onShow then
                onShow(GameTooltip, target, this);
            elseif onShow ~= false then
                local str = Nx.Split ("~", format ("%s\n%s " .. L["yds"], target.TargetName or this.TrackName, shortendistance(ceil(target.dist * 4.575))));
                Nx:SetTooltipText (str .. Nx.Map.PlyrNamesTipStr);
            end

            local t = this.NXType or -1
            if t >= 9000 then                    -- Quest
                Nx.Quest:IconOnEnter (this)
            end

            -- If we have callbacks, we don't need to do the default behaviour.
            return;
        end
    end

    if this.NxTip then
        local poiInfo = this.NxPoiInfo

        -- Try to find matching Blizzard pin and use its tooltip
        if poiInfo and C_AreaPoiInfo then
            local hasDescription = poiInfo.description and poiInfo.description ~= ""
            local isTimed, hideTimer = false, false
            if C_AreaPoiInfo.IsAreaPOITimed and poiInfo.areaPoiID then
                isTimed, hideTimer = C_AreaPoiInfo.IsAreaPOITimed(poiInfo.areaPoiID)
            end
            local showTimer = not poiInfo.forceHideTimer and (poiInfo.secondsLeft or (isTimed and not hideTimer))
            local hasWidgetSet = poiInfo.tooltipWidgetSet ~= nil

            if hasDescription or showTimer or hasWidgetSet then
                -- Use enhanced POI tooltip via Nx.TooltipText to avoid tainting GameTooltip
                Nx.TooltipText:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip_SetTitle(Nx.TooltipText, poiInfo.name or this.NxTip, HIGHLIGHT_FONT_COLOR)

                if hasDescription then
                    GameTooltip_AddNormalLine(Nx.TooltipText, poiInfo.description)
                end

                if showTimer then
                    local secondsLeft = poiInfo.secondsLeft
                    if not secondsLeft and C_AreaPoiInfo.GetAreaPOISecondsLeft and poiInfo.areaPoiID then
                        secondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft(poiInfo.areaPoiID)
                    end
                    if secondsLeft and secondsLeft > 0 then
                        local timeString = SecondsToTime(secondsLeft)
                        if HIGHLIGHT_FONT_COLOR and HIGHLIGHT_FONT_COLOR.WrapTextInColorCode then
                            timeString = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(timeString)
                        end
                        if MAP_TOOLTIP_TIME_LEFT then
                            GameTooltip_AddNormalLine(Nx.TooltipText, MAP_TOOLTIP_TIME_LEFT:format(timeString))
                        else
                            GameTooltip_AddNormalLine(Nx.TooltipText, "Time left: " .. timeString)
                        end
                    end
                end

                if hasWidgetSet and GameTooltip_AddWidgetSet then
                    GameTooltip_AddWidgetSet(Nx.TooltipText, poiInfo.tooltipWidgetSet, poiInfo.addPaddingAboveTooltipWidgets and 10)
                end

                -- Add Quest Hub related quests if this is a Quest Hub POI
                if poiInfo.areaPoiID and Nx.Quest and Nx.Quest.AddQuestHubTooltipData then
                    local mapID = Nx.Map:GetCurrentMapAreaID()
                    Nx.Quest:AddQuestHubTooltipData(Nx.TooltipText, mapID, poiInfo.areaPoiID)
                end

                Nx.TooltipText:Show()
                return  -- Skip default tooltip handling
            end
        end

        -- Default tooltip handling
        local str = Nx.Split ("~", this.NxTip)
        Nx:SetTooltipText (str .. Nx.Map.PlyrNamesTipStr)
    end

    local t = this.NXType or -1

    if t >= 9000 then                    -- Quest
        Nx.Quest:IconOnEnter (this)
    end
end

---
-- Called by tooltip system to update tooltip content
-- self = frame that owns the tooltip
--
function Nx.Map:IconOnUpdateTooltip()
    local f = self.NXIconFrm

    if f then
        local target = f.NxTarget

        if target then
            local callbacks = target.TargetCallbacks
            if callbacks then
                local onUpdate = callbacks.OnTooltipUpdate
                if onUpdate then
                    onUpdate(Nx.TooltipText, target, f)
                elseif onUpdate ~= false then
                    local map = f.NxMap
                    map:BuildPlyrLists()

                    local str = Nx.Split("~", format("%s\n%s " .. L["yds"], target.TargetName or self.TrackName, shortendistance(ceil(target.dist * 4.575))))
                    Nx:SetTooltipText(str .. Nx.Map.PlyrNamesTipStr)

                    -- Skip TooltipProcess for quest offer icons to avoid adding wrong quest data
                    if Nx.Quest and not f.NxQuestOffer then
                        Nx.Quest:TooltipProcess()
                    end
                end

                -- Callbacks handled, skip default behavior
                return
            end
        end

        -- Default tooltip behavior
        if f.NxTip then
            local map = f.NxMap
            map:BuildPlyrLists()

            local poiInfo = f.NxPoiInfo

            -- Check if this POI has enhanced tooltip content
            if poiInfo and C_AreaPoiInfo then
                local hasDescription = poiInfo.description and poiInfo.description ~= ""
                local isTimed, hideTimer = false, false
                if C_AreaPoiInfo.IsAreaPOITimed and poiInfo.areaPoiID then
                    isTimed, hideTimer = C_AreaPoiInfo.IsAreaPOITimed(poiInfo.areaPoiID)
                end
                local showTimer = not poiInfo.forceHideTimer and (poiInfo.secondsLeft or (isTimed and not hideTimer))
                local hasWidgetSet = poiInfo.tooltipWidgetSet ~= nil

                if hasDescription or showTimer or hasWidgetSet then
                    -- Use enhanced POI tooltip via Nx.TooltipText to avoid tainting GameTooltip
                    GameTooltip_SetTitle(Nx.TooltipText, poiInfo.name or f.NxTip, HIGHLIGHT_FONT_COLOR)

                    if hasDescription then
                        GameTooltip_AddNormalLine(Nx.TooltipText, poiInfo.description)
                    end

                    if showTimer then
                        local secondsLeft = poiInfo.secondsLeft
                        if not secondsLeft and C_AreaPoiInfo.GetAreaPOISecondsLeft and poiInfo.areaPoiID then
                            secondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft(poiInfo.areaPoiID)
                        end
                        if secondsLeft and secondsLeft > 0 then
                            local timeString = SecondsToTime(secondsLeft)
                            if HIGHLIGHT_FONT_COLOR and HIGHLIGHT_FONT_COLOR.WrapTextInColorCode then
                                timeString = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(timeString)
                            end
                            if MAP_TOOLTIP_TIME_LEFT then
                                GameTooltip_AddNormalLine(Nx.TooltipText, MAP_TOOLTIP_TIME_LEFT:format(timeString))
                            else
                                GameTooltip_AddNormalLine(Nx.TooltipText, "Time left: " .. timeString)
                            end
                        end
                    end

                    if hasWidgetSet and GameTooltip_AddWidgetSet then
                        GameTooltip_AddWidgetSet(Nx.TooltipText, poiInfo.tooltipWidgetSet, poiInfo.addPaddingAboveTooltipWidgets and 10)
                    end

                    -- Add Quest Hub related quests if this is a Quest Hub POI
                    if poiInfo.areaPoiID and Nx.Quest and Nx.Quest.AddQuestHubTooltipData then
                        local mapID = Nx.Map:GetCurrentMapAreaID()
                        Nx.Quest:AddQuestHubTooltipData(Nx.TooltipText, mapID, poiInfo.areaPoiID)
                    end

                    Nx.TooltipText:Show()
                else
                    -- No enhanced content, use default
                    local str = Nx.Split("~", f.NxTip)
                    Nx:SetTooltipText(str .. Nx.Map.PlyrNamesTipStr)
                end
            else
                -- No POI info, use default
                local str = Nx.Split("~", f.NxTip)
                Nx:SetTooltipText(str .. Nx.Map.PlyrNamesTipStr)
            end

            -- Skip TooltipProcess for quest offer icons to avoid adding wrong quest data
            if Nx.Quest and not f.NxQuestOffer then
                Nx.Quest:TooltipProcess()
            end
        end
    end
end

---
-- Handle mouse leaving an icon
-- Cleans up tooltips and addon integration
-- @param motion  Motion flag
--
function Nx.Map:IconOnLeave(motion)
    local this = self
    local t = this.NXType or -1

    -- Handle addon-specific leave events (NXData must be a table with iconType)
    if this.NXData and type(this.NXData) == "table" then
        if this.NXData.iconType == "!RSR" and RareScanner then
            local rspin = this.NXData.UData
            if rspin and rspin.OnMouseLeave then
                -- Defer the close as long as the cursor is still over the
                -- tooltip, our icon, or (for groups) any cell within the
                -- popup. A single one-shot timer is too brittle: if the
                -- cursor is in transit between icon and tooltip at the
                -- moment it fires, the tooltip would close even though the
                -- user is heading toward it. Use a recurring 200ms ticker
                -- that stops itself the moment cursor leaves both regions.
                local icon = self
                local isGroup = (rspin.pinTemplate == "RSGroupPinTemplate") and rspin.groupTooltip
                -- Cancel any prior ticker so re-entering doesn't stack
                -- multiple watchdogs.
                if rspin._NxLeaveTicker then
                    rspin._NxLeaveTicker:Cancel()
                end
                rspin._NxLeaveTicker = C_Timer.NewTicker(0.2, function(ticker)
                    local stillThere = false
                    if isGroup then
                        local gt = rspin.groupTooltip
                        if gt and gt.IsShown and gt:IsShown() then
                            if MouseIsOver(gt) then stillThere = true end
                            -- RS attaches a child entity-tooltip on
                            -- gt.tooltip when the user hovers a cell in
                            -- the popup; honour the same protection RS's
                            -- own HideGroupTooltip uses.
                            if not stillThere and gt.tooltip and gt.tooltip.IsShown and gt.tooltip:IsShown() then
                                stillThere = true
                            end
                        end
                    else
                        -- Entity / overlay / guide pins: tooltip lives on
                        -- rspin.tooltip (LibQTip frame). It's recreated on
                        -- each OnMouseEnter so we can't capture it once.
                        local tt = rspin.tooltip
                        if tt and tt.IsShown and tt:IsShown() and MouseIsOver(tt) then
                            stillThere = true
                        end
                    end
                    if not stillThere and icon and icon.IsShown and icon:IsShown() and MouseIsOver(icon) then
                        stillThere = true
                    end
                    if stillThere then
                        return  -- keep polling
                    end
                    ticker:Cancel()
                    rspin._NxLeaveTicker = nil
                    if rspin.OnMouseLeave then
                        rspin:OnMouseLeave()
                    end
                end)
            end
            if rspin and rspin.POI then
                this.NxTip = rspin.POI.name
            end
        end
        -- Questie icon frames have no OnMouseLeave method; the original
        -- qpin:OnMouseLeave() call was a no-op on the HBD pin.
    end

    -- Quest icon leave handling
    if t >= 9000 then
        Nx.Quest:IconOnLeave(this)
    end

    -- Hide tooltip if owned by this icon
    if Nx.TooltipText:IsOwned(this) or Nx.TooltipText:IsOwned(this.NxMap.Win.Frm) then
        Nx.TooltipText:Hide()
    end
end

-------------------------------------------------------------------------------
-- TEXT RENDERING
-------------------------------------------------------------------------------

---
-- Get or create a text font string from the pool
-- @param text      Text to display
-- @param levelAdd  Frame level offset
-- @return          Font string object
--
function Nx.Map:GetText(text, levelAdd)
    local data = self.TextFStrs
    local pos = data.Next

    -- Reset pool if too many used
    if pos > 100 then
        pos = 1
    end

    local fstr = data[pos]
    if not fstr then
        -- Create new font string
        fstr = self.TextFrm:CreateFontString()
        data[pos] = fstr

        fstr:SetFontObject("NxFontMap")
        fstr:SetJustifyH("LEFT")
        fstr:SetJustifyV("TOP")
        fstr:SetHeight (100)
        fstr:SetTextColor (1, 1, 1, 1)
    end

    fstr:SetText (text)

--    local add = levelAdd or 0
--    f:SetFrameLevel (self.Level + add)

    data.Next = pos + 1

    return fstr
end

--------
-- Move text

function Nx.Map:MoveTextToIcon (fstr, icon, ox, oy)

    local f = icon
    local atPt, relTo, relPt, x, y = f:GetPoint()

--    Nx.prt ("Text %s %s %s", relPt, x, y)

    fstr:SetPoint ("TOPLEFT", x + ox, y - oy)
    fstr:Show()
end

--------
-- Update instance map

function Nx.Map:UpdateInstanceMap()

    local mapId = self.InstMapId
    if not mapId or not Nx.Initialized then
        return
    end

    -- Skip drawing tiles when NXInstanceMaps is enabled
    -- MoveWorldMap() handles rendering in that case, so we don't want duplicates
    if (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
        return
    end

    local curId = Nx.Map:GetCurrentMapId()

    if not Nx.Map.NInstMapId or Nx.Map.NInstMapId ~= curId then
        Nx.Map.NInstMapId = curId
    end
    Nx.Map:SetCurrentMap (Nx.Map.NInstMapId)

    local Map = Nx.Map
    local winfo = Map.MapWorldInfo[mapId]
    local info = self.InstMapInfo                -- Valid if Id not nil
    if Map.MapWorldInfo[mapId].BaseMap then
      winfo = Map.MapWorldInfo[Map.MapWorldInfo[mapId].BaseMap]
    end
--    Nx.prt ("Inst id %s", mapId)

    if self.InstMapAtlas then

        local wx = winfo.X
        local wy = winfo.Y

        local n = 4;
        if info then
        --for n = 1, #info, 3 do

            local sc = 668 / 256
            local f = self:GetIconNI()

            if self:ClipFrameTL (f, wx, wy + (n - 1) * 668 / 768, sc, sc) then
                local tex = string.gsub(info[n + 2], " ", "")
                tex = "Interface\\AddOns\\Atlas\\Images\\" .. tex
                f.texture:SetTexture (tex)
            end
        end

        self.Level = self.Level + 1

    else

        local wx = winfo.X
        local wy = winfo.Y

        local is_n = nil

        local n = 4;

        local layerIndex = WorldMapFrame:GetCanvasContainer():GetCurrentLayerIndex();
        local textures = C_Map.GetMapArtLayerTextures(mapId, layerIndex)
        local layers = C_Map.GetMapArtLayers(mapId)

        local lx = ceil(layers[layerIndex].layerWidth / layers[layerIndex].tileHeight)
        local ly = ceil(layers[layerIndex].layerHeight / layers[layerIndex].tileHeight)

        if info then
        --for n = 1, #info, 3 do
            local imgI = 1

            local offx = 0        -- info[n] * .04 * 1002 / 1024
            local offy = 0        -- info[n + 1] * .03 * 668 / 768

            for by = 0, (ly - 1) do

                for bx = 0, (lx - 1) do

                    local sc = 1
                    local f = self:GetIconNI(10)

                    --Nx.prt ("Inst %s, %s %s %s %s", mapId, wx, wy, bx, by)

                    if self:ClipFrameTL (f, wx + bx - offx, wy + by - offy, sc, sc) then
                        if not is_n then is_n = n end
                        local tex = string.gsub(info[n + 2], " ", "")
                        tex = "Interface\\WorldMap\\" .. tex .. imgI
                        f.texture:SetTexture (textures[imgI])
                    end
                    imgI = imgI + 1
                end
            end
        end

        local isInGarrison7 = C_Garrison and Enum.GarrisonType and Enum.GarrisonType.Type_7_0_Garrison and C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_7_0_Garrison)
        if not ((Nx.Map:IsInstanceMap(Nx.Map.RMapId) or Nx.Map:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps) and not isInGarrison7 then

            Nx.Map.MouseOver = false
            Nx.Map:GetMap(1).PlyrFrm:Hide()

            NXWorldMapUnitPositionFrame:ClearAllPoints()
            NXWorldMapUnitPositionFrame:SetFrameLevel(40)
            local c = NXWorldMapUnitPositionFrame
            local f = self.NewPlrFrm
            if not self.NewPlrFrm then
                f = CreateFrame ("ScrollFrame", "NewPlrFrm", self.Frm)
                self.NewPlrFrm = f
                f:SetFrameLevel(20)
                f:SetFrameStrata("HIGH")

                -- RED BG FOR TESTING
                --f.texture = f:CreateTexture()
                --f.texture:SetAllPoints (f)
                --f.texture:SetColorTexture (1, 0, 0, 0.2)
            end

            -- Check if in WoD garrison for special handling
            local isInGarrison6 = C_Garrison and Enum.GarrisonType and Enum.GarrisonType.Type_6_0_Garrison and C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_6_0_Garrison)
            if isInGarrison6 then
                c:SetParent(f)
                c:SetAllPoints()
                c:SetScale(3 * (50 / Nx.db.profile.Map.InstancePlayerSize) * (1 / self.ScaleDraw))

                f:SetScrollChild(c)

                self:ClipZoneFrm(self.Cont, self.Zone, f, 1)
                f:SetWidth(1002)
                f:SetHeight(668)

                f:Show()
            else
                c:SetParent(f)
                c:SetSize(100,100)
                c:SetScale(0.5)

                f:SetScrollChild(c)

                --Nx.prt("%s", info[is_n + 1])
                local w = 4 * (1002 / 1024)  -- (info[is_n + 1] * .04 * 1002 / 1024) * -1
                local h = 3 * (668 / 768) -- (info[is_n + 1] * .03 * 668 / 768) * -1
                local dungeonLevel = Nx.Map:GetCurrentMapDungeonLevel() > 0 and Nx.Map:GetCurrentMapDungeonLevel() -1 or 0

                local x1, y1, x2, y2 = self:ClipFrameINST (f, wx, wy + (h * dungeonLevel), w, h, true)

                --Nx.prt("%s, %s, %s, %s", x1, y1, x2, y2)

                c:SetAllPoints()
                --c:SetPoint("TOPLEFT", x1 * -1, y1) -- -10, 10
                --c:SetPoint("BOTTOMRIGHT", x2 * -1, y2) -- 10, -10
            end

            Nx.Map:NXWorldMapUnitPositionFrame_UpdatePlayerPins()
        else
            Nx.Map:HideNewPlrFrame()
        end

        self.Level = self.Level + 1
    end
end

------------------------------------------
-- Helpers

--------
-- Get a map by index

function Nx.Map:GetMap (mapIndex)
    if self.Maps then
        return self.Maps[mapIndex]
    end
    assert(0, "Erroneous Map Index requested (probably by some other addon): mapIndex = " .. (mapIndex or 'missing'))
end

--------
-- Set map target name

function Nx.Map:SetTargetName (name)

    local tar = self.Maps[1].Targets[1]
    if tar then
        tar.TargetName = name
    end
end

--------
-- Get map target type, id

function Nx.Map:GetTargetInfo()

    local tar = self.Maps[1].Targets[1]
    if tar then
        return tar.TargetType, tar.TargetId
    end
end

--------
-- Get map target pos

function Nx.Map:GetTargetPos()

    local tar = self.Maps[1].Targets[1]
    if tar then
        return tar.TargetX1, tar.TargetY1, tar.TargetX2, tar.TargetY2
    end
end

--------
-- Center the map in view

function Nx.Map:CurrentCenterMap (mapId)

    local map = self.Maps[1]
    map:CenterMap (mapId)
end

------------------------------------------
-- Map table access

--------
-- Init map tables

function Nx.Map:InitTables()

    local Nx = Nx

    local worldInfo = self.MapWorldInfo
    Nx.MapOverlayToMapId = {}

    -- Get Blizzard's alphabetical set of names

    --V403

    if Nx.WOTLKMaps then
        self.ZoneOverlays["lakewintergrasp"]["lakewintergrasp"] = "0,0,1024,768"
    end

    -- Merge external compressed overlay data (retail only)
    if Nx.isRetail and Nx.GetCompressedOverlayData then
        local externalOverlays = Nx.GetCompressedOverlayData()
        if externalOverlays then
            for zoneName, overlayData in pairs(externalOverlays) do
                self.ZoneOverlays[zoneName] = overlayData
            end
        end
        -- Enable locale textures when external media addon is present
        if Nx.db and Nx.db.profile and Nx.db.profile.Map then
            Nx.db.profile.Map.UseLocaleTextures = true
        end
    end

    for k, v in pairs (worldInfo) do
        local winfo = worldInfo[k]
        if Nx.PlFactionNum == 0 and winfo.QAchievementIdA then
            winfo.QAchievementId = winfo.QAchievementIdA                -- Copy Ally Id to generic Id
        end
        if Nx.PlFactionNum == 1 and winfo.QAchievementIdH then
            winfo.QAchievementId = winfo.QAchievementIdH                -- Copy Horde Id to generic Id
        end
        if winfo.BaseMap then
            Nx.Map.MapWorldInfo[k] = Nx.Map.MapWorldInfo[winfo.BaseMap]
            Nx.Map.MapWorldInfo[k].RBaseMap = k
            Nx.Map.MapWorldInfo[k].OBaseMap = winfo.BaseMap
        end
    end
    for k, v in pairs (Nx.Zones) do
        if worldInfo[k] then
            local name, minLvl, maxLvl, faction, cont, entryId, ex, ey = Nx.Split ("|", v)
            worldInfo[k].Cont = tonumber(cont)
            worldInfo[k].Zone = k
            local ov = worldInfo[k].Overlay
            if ov then
                Nx.MapOverlayToMapId[ov] = k
            end
        end
    end
--    for n = 1, self.ContCnt do
--        CZ2Id[n][0] = n * 1000
--    end

    -- Init for getting map id to and from name

--    for _, ci in ipairs (continentNums) do

--        for mi, mapName in pairs (self.MapNames[ci]) do

--            if ci == 2 then
--                Nx.prt ("Map %s %s", mapName, self.CZ2Id[ci][mi] or "nil")
--            end
--            local mid = self.CZ2Id[ci][mi]

--            if Nx.MapNameToId[mapName] then
--                Nx.prt ("Dup map name: %s (%s %s)", mapName, ci, mi)
--                Nx.MapNameToId[mapName .. "2"] = mid
--            else
--                Nx.MapNameToId[mapName] = mid
--            end

--            if not mid then
--                Nx.prt (L["Unknown map name"] .. ": %s (%s %s)", mapName, ci, mi)
--            else
--                Nx.MapIdToName[mid] = mapName
--            end
--        end
--    end

    -- Localize the zone name

--    for id, v in pairs (Nx.Zones) do
--        local i = strfind (v, "|")
--        local name = strsub (v, 1, i - 1)
--        local data = strsub (v, i + 1)
--        Nx.Zones[id] = L[name] .. "|" .. data
--    end

-- Make world coords for each zone
--        Nx.prt ("WC %s %s %s", ci, cx, cy)

    for n = 0, self.ContCnt do
        for _, id in pairs (Nx.Map.MapZones[n]) do
            local winfo = worldInfo[id]
            if winfo then
                local info = self.MapInfo[winfo.Cont]
                if info then
                    if winfo.XOff then    -- Had pos offset?
                        winfo.X = winfo.X + winfo.XOff
                        winfo.Y = winfo.Y + winfo.YOff
                        winfo.XOff = nil
                        winfo.YOff = nil
                    end
                    local cx = info.X
                    local cy = info.Y
                    if winfo.X ~= nil and winfo.Y ~= nil then
                        winfo[4] = cx + winfo.X
                        winfo[5] = cy + winfo.Y
                    else
                        if n ~= nil and n ~= 0 then
                            Nx.prt("Map Error: " .. tostring(n))
                        end
                    end
                else
                end
            end
        end
    end

    for _, id in pairs (Nx.Map.MapZones[90]) do
        local winfo = worldInfo[id]
        if winfo then
            local info = self.MapInfo[90]
            if info then
                local cx = info.X
                local cy = info.Y
                if winfo.X ~= nil and winfo.Y ~= nil then
                    winfo[4] = cx + winfo.X
                    winfo[5] = cy + winfo.Y
                else
                    if n ~= nil and n ~= 0 then
                        Nx.prt("Map Error: " .. tostring(n))
                    end
                end
                winfo.Cont = 90
                winfo.Zone = id
            else
            end
        end
    end

    --
    for id, v in pairs (Nx.Zones) do

        local name, minLvl, maxLvl, faction, cont, entryId, ex, ey = Nx.Split ("|", v)

        -- Faction:
        -- 0 Alliance
        -- 1 Horde
        -- 2 Contested
        -- 3 Instance
        -- 4 Unknown

        -- Continent:
        -- 1 Kalimdor
        -- 2 EasternKingdoms
        -- 3 Outland
        -- 4 Northrend
        -- 5 Maelstorm
        -- 6 Pandaria
        -- 7 Draenor
        -- 8 Broken Isles
        -- 9 Argus
        -- 99 Battlegrounds
        -- 100 Instances

        if faction == "3" and cont == "5" then        -- Instance

            assert (entryId)

            if entryId == "0" then
                Nx.prt("Instance " .. name .. " trying entryId 0")
                entryId = "125"
            end
--[[
            local i = strfind (name, ": ")
            if i then
                name = strsub (name, i + 2)
            end
--]]

--            Nx.prt ("Inst %s %d", name, id)

            local entryZone = Nx.Zones[tonumber (entryId)]
            local ename, _, _, entryfact, entrycont, entrybase = Nx.Split ("|", entryZone)
            local mid = id
            tinsert(Nx.Map.MapZones[100],id)
            local emid = tonumber(entryId)
            while entryfact == "3" and entrycont == "5" do
                Nx.prt(entrybase)
                _, _, _, entryfact, entrycont, entrybase = Nx.Split ("|", entrybase)
            end

            if self.MapWorldInfo[mid] and self.MapWorldInfo[mid].BaseMap then
                mid = self.MapWorldInfo[mid].BaseMap
            end
            if self.MapWorldInfo[mid] then            -- Adjustment exists?
                ex = ex + self.MapWorldInfo[mid].X
                ey = ey + self.MapWorldInfo[mid].Y
            end

--            Nx.prt ("Inst %s %s, %s %s %f %f", name, mid, ename, emid or "nil", ex, ey)
            local x, y = self:GetWorldPos (emid, ex, ey)

--            Nx.prt ("Inst %s %d, %d %f %f", name, mid, emid, x, y)

            local ewinfo = self.MapWorldInfo[emid]
            if not ewinfo then
--                Nx.prt ("? %s %s", ename, emid or "nil")
            end

            local winfo = {}
            winfo.EntryMId = emid
            winfo.Scale = 1002 / 25600 --ewinfo[1]        -- Scale
            winfo.X = x                -- X
            winfo.Y = y                -- Y
            winfo[4] = x                -- X
            winfo[5] = y                -- Y
            winfo.Cont = entrycont
            winfo.Zone = mid
            winfo.Instance = true
            self.MapWorldInfo[mid] = winfo
        end
    end

    --    DEBUG for Jamie

    Nx.ZoneConnections = Nx["ZoneConnections"] or Nx.ZoneConnections    -- Copy unmunged data to munged data

    -- Init zone connections
        for n = 0, 2999 do
            local mapId = n
            local winfo = worldInfo[mapId]
            if not winfo then

            else

            local cons = {}
            winfo.Connections = cons
            if winfo.Short then

            end
            for _, str in ipairs (Nx.ZoneConnections) do

                local flags, conTime, name1, z1, x1, y1, name2, z2, x2, y2 = Nx.Split ("|",str)

                conTime = tonumber(conTime)
                local mapId1 = tonumber(z1)
                local mapId2 = tonumber(z2)

                if not (mapId1 and mapId2) then
                    Nx.prt ("zone conn err %s to %s", z1 - 35, z2 - 35)
                    conTime = 0
                end

                if conTime == 1 and (mapId == mapId1 or (mapId == mapId2 and bit.band (flags, 1) == 1)) then

                    local cont1 = self:IdToContZone (mapId1)
                    local cont2 = self:IdToContZone (mapId2)

                    if cont1 == cont2 then

                        if mapId == mapId2 then        -- Swap?
                            mapId1, mapId2 = mapId2, mapId1
                            x1, y1, x2, y2 = x2, y2, x1, y1
                        end

                        local zcons = cons[mapId2] or {}
                        cons[mapId2] = zcons

                        if x1 ~= 0 and y1 ~= 0 then    -- Specific connection? Else connects anywhere

                            local con = {}
                            tinsert (zcons, con)

                            x1, y1 = self:GetWorldPos (mapId1, x1, y1)
                            x2, y2 = self:GetWorldPos (mapId2, x2, y2)

                            con.StartMapId = mapId1
                            con.StartX = x1
                            con.StartY = y1
                            con.EndMapId = mapId2
                            con.EndX = x2
                            con.EndY = y2
                            con.Dist = ((x1 - x2) ^ 2 + (y1 - y2) ^ 2) ^ .5
                        end

--                    else
--                        Nx.prt ("%s to %s", mapId1, mapId2)
                    end

                elseif (conTime == 0 or conTime == 2 or conTime == 3 or conTime == 5) and (mapId == mapId1 or (mapId == mapId2 and bit.band (flags, 1) == 1)) then
                    -- Transport connections:
                    --   conTime=0: portals
                    --   conTime=2: boats, zeppelins, trams (classic/retail)
                    --   conTime=3: trams (TBC)
                    --   conTime=5: zeppelins (TBC)
                    -- flags bit 1 = Alliance, bit 2 = Horde; both set = neutral/all factions
                    local factionBits = bit.band (flags, 6)
                    local playerFaction = UnitFactionGroup ("player") or ""
                    local accessible = (factionBits == 6) or
                                       (factionBits == 2 and playerFaction == "Alliance") or
                                       (factionBits == 4 and playerFaction == "Horde") or
                                       (factionBits == 0)

                    -- Both endpoints must have valid coordinates
                    if accessible and x1 ~= 0 and y1 ~= 0 and x2 ~= 0 and y2 ~= 0 then
                        if mapId == mapId2 then        -- Swap?
                            mapId1, mapId2 = mapId2, mapId1
                            x1, y1, x2, y2 = x2, y2, x1, y1
                        end

                        local zcons = cons[mapId2] or {}
                        cons[mapId2] = zcons

                        local con = {}
                        tinsert (zcons, con)

                        x1, y1 = self:GetWorldPos (mapId1, x1, y1)
                        x2, y2 = self:GetWorldPos (mapId2, x2, y2)

                        con.StartMapId = mapId1
                        con.StartX = x1
                        con.StartY = y1
                        con.EndMapId = mapId2
                        con.EndX = x2
                        con.EndY = y2
                        -- Portals are instant; boats/zeppelins/trams use actual distance
                        con.Dist = conTime == 0 and 0 or ((x1 - x2) ^ 2 + (y1 - y2) ^ 2) ^ .5
                        con.Transport = true    -- Portal, boat, zeppelin, or tram
                        con.ConTime = conTime   -- Store type for icon selection
                        con.Flags = tonumber(flags)  -- Store flags for icon selection
                    end
                end
            end
            end
        end
end

--------
-- Convert raw cont and zone to mapid
-- self: not used

function Nx.Map:ConnectionUnpack (str)
    -- File needs dungeon level updates
    local flags, typ, nam1, z1, x1, y1, nam2, z2, x2, y2 = Nx.Split ("|",str)
    if not nam1 then
        nam1 = ""
    end
    if not nam2 then
        nam2 = ""
    end
    return tonumber(flags), tonumber(typ), nam1, tonumber(z1), tonumber(x1), tonumber(y1), 0, nam2, tonumber(z2), tonumber(x2), tonumber(y2), 0
end

--------
-- Convert raw cont and zone to mapid
-- self: not used

function Nx.Map:CZ2MapId (cont, zone)

    if cont <= 0 then
        return 9000
    end

    return self.CZ2Id[cont][zone]
end

--------
-- Get the real player location map id without map level calculation

function Nx.Map:GetRealBaseMapId()
        return Nx.Map.UpdateMapID
end

--------
-- Get the real player location map id
-- asdf
function Nx.Map:GetInstanceID(id)
  if Nx.Zones[tonumber(id)] then
    local name, minLvl, maxLvl, faction, cont, entryId, entryPos = Nx.Split ("|", Nx.Zones[tonumber(id)])
    local entryZone = Nx.Zones[tonumber (entryId)]
    if entryZone then
        return entryId
    end
  end
  return 9000
end

function Nx.Map:GetRealMapId()
    return Nx.Map:GetCurrentMapAreaID()
end

--------
-- Get the current selected map id
-- Do not call Nx.Map:SetToCurrentZone() here or crash

function Nx.Map:GetCurrentMapId(conv)
    if Nx.Map.RMapId == 9000 then
        return Nx.Map:GetCurrentMapAreaID()
    end
    return Nx.Map.RMapId
end

--------
-- Set the current using a map id

function Nx.Map:SetCurrentMap (mapId)
    if mapId then
---        Nx.prt ("Nx.Map:SetToCurrentZone %s", mapId)
        self.BaseScale = 1
        for n = 1, Nx.Map.ContCnt do
            for i,j in pairs (Nx.Map.MapZones[n]) do
                if mapId == j then
                    local cont = self.MapWorldInfo[mapId].Cont
                    local zone = self.MapWorldInfo[mapId].Zone

                    if not self.MapWorldInfo[mapId].City and (not cont or not zone or mapId == self:GetRealBaseMapId() or mapId == self:GetRealMapId()) then
                        Nx.Map:SetToCurrentZone()        -- This fixes the Scarlet Enclave map selection, so we get player position
                        --SetDungeonMapLevel (1)
                    else
--                        SetMapZoom (cont, i)
                        Nx.Map:SetMapByID(mapId)
                    end

                    return
                end
            end
        end
        if self:IsInstanceMap(mapId) then    -- Instance?
            local aid = mapId
            if aid then
                self.MapId = 0                -- Force change (needed?)
                if mapId == self:GetRealBaseMapId() then
                    Nx.Map:SetToCurrentZone()
                else
                    local caid = Nx.Map:GetCurrentMapAreaID()
                    if caid ~= aid then
--                        Nx.prt ("SetCurrentMap dif %s", caid)
                        Nx.Map:SetMapByID (aid)
                        --SetDungeonMapLevel (1)
                    end
                end
            else
                if mapId == self:GetRealBaseMapId() then
                    self.MapId = 0                -- Force change
                    Nx.Map:SetToCurrentZone()
                else
                    self.MapId = mapId
                    --SetMapZoom (-1)            -- Cosmic map. Has no POIs
                end
            end
        end
        self.InstLevelSet = Nx.Map:GetCurrentMapDungeonLevel()
    end
end

--------
-- Set the map to current zone

function Nx.Map:SetToCurrentZone()
    Nx.Map:SetMapByID(MapUtil.GetDisplayableMapForPlayer())
end

function Nx.Map:GetCurrentMapAreaID()
    local displayableMapID = MapUtil.GetDisplayableMapForPlayer()
    local mapID = Nx.Map.MouseOver and WorldMapFrame:GetMapID() or displayableMapID

    local _, instanceType = GetInstanceInfo()
    if (instanceType ~= nil and instanceType ~= "none") then mapID = displayableMapID end
    if Nx.OldMapIDs then
        if mapID == 1414 then mapID = 12 end
        if mapID == 1415 then mapID = 13 end
    end
    return mapID
end

--------
-- Save map view

function Nx.Map:SaveView (name)

    local str = format ("%s%s", Nx.InBG or "", name)

--    Nx.prt ("Save view %s", str)

    local v = self.ViewSavedData[str]

    if not v then
        v = {}
        self.ViewSavedData[str] = v
    end

    v.Scale = self.Scale
    v.X = self.MapPosX
    v.Y = self.MapPosY
end

--------
-- Restore map view

function Nx.Map:RestoreView (name)

    local str = format ("%s%s", Nx.InBG or "", name)

--    Nx.prt ("Restore view %s", str)

    local v = self.ViewSavedData[str]

    if v then
        self.Scale = v.Scale
        self.MapPosX = v.X
        self.MapPosY = v.Y

        self.StepTime = 5
    end
end

--------
-- Move map

function Nx.Map:Move (x, y, scale, stepTime)

--    Nx.prt ("Move %s %s sc %s time %s", x, y, scale or "nil", stepTime)

    self.MapPosX = x
    self.MapPosY = y

    if scale then
        self.Scale = scale
    end

    local dist = ((self.MapPosXDraw - self.MapPosX) ^ 2 + (self.MapPosYDraw - self.MapPosY) ^ 2) ^ .5

    local sz = max (self.MapW, self.MapH)

--    Nx.prt ("Move dist %f %f val %f", sz, dist, dist * self.Scale / sz)

    if dist * self.Scale / sz > 10 then    -- Zoomed in and a large jump?
        stepTime = 1    -- Go fast
    end

--    Nx.prt ("Move #%d %f steptime %f ", self.Tick, dist, self.StepTime)

    local st = abs (self.StepTime)    -- Will be neg if triggered

    if st > 0 and st < stepTime then        -- Already stepping? Use short time
        stepTime = st
--        Nx.prt ("Move steptime %f", stepTime)
    end

    self.StepTime = stepTime

    if dist < .25 then

--        Nx.prt ("Move snap XY")

        self.MapPosXDraw = self.MapPosX
        self.MapPosYDraw = self.MapPosY
    end

    if abs (1 / self.ScaleDraw - 1 / self.Scale) < .01 then
        self.ScaleDraw = self.Scale

--        Nx.prt ("Move snap scale")

        if dist < .25 then
            self.StepTime = 0
        end
    end

--[[
    if self.Debug then
        local plZX, plZY = Nx.GetPlayerMapPosition ("player")
        Nx.prt ("Move %f %f (%f %f)", x, y, plZX, plZY)
    end
--]]
end

--------
-- Goto current zone and center map

function Nx.Map:GotoCurrentZone()

--    Nx.prt ("GotoCurrentZone")

    if self.InstanceId then
        self:Move (self.PlyrX, self.PlyrY, 20, 15)
    else
        self:SetToCurrentZone()
        local mapId = MapUtil.GetDisplayableMapForPlayer()
        if Nx.OldMapIDs then
            if mapId == 1414 then mapId = 12 end
            if mapId == 1415 then mapId = 13 end
        end
        self:CenterMap (mapId)
    end
end

--------
-- Goto current zone and cause player moved update

function Nx.Map:GotoPlayer()

--    Nx.prt ("GotoPlayer")

    self:CalcTracking()

    self:SetToCurrentZone()

    self.MoveLastX = -1
    self.MoveLastY = -1
end

--------
-- Center the map in view

function Nx.Map:CenterMap (mapId, scale)
    if (mapId == nil or mapId == -1) then
        return
    end
    mapId = mapId or self.MapId

--[[ -- Map capture
    if 1 then
        self:CenterMap1To1 (floor (mapId / 1000) * 1000)
        return
    end
--]]

    if self:GetWorldZone (mapId).City then
        scale = 1
    end

    self.MapW = self.Frm:GetWidth() - self.PadX * 2
    self.MapH = self.Frm:GetHeight() - self.TitleH

    local x, y = self:GetWorldPos (mapId, 50, 50)
    local size = min (self.MapW / 1002, self.MapH / 668)
    if self.MapW < GetScreenWidth() / 2 then
        size = size * (scale or 1.5)
    end

    local scale = size / self:GetWorldZoneScale (mapId) * 10.02

    self:Move (x, y, scale, 15)

--    Nx.prt ("Center #%d %f (%f %f) (%d %d)", mapId, self.Scale, self.MapPosX, self.MapPosY, self.MapW, self.MapH)
end

--------
-- Center the map in view and 1 to 1 scale

function Nx.Map:CenterMap1To1 (mapId)
    self.MapPosX, self.MapPosY = self:GetWorldPos (mapId, 50, 50)

    self.Scale = 1002 / 100 / self:GetWorldZoneScale (mapId) * GetScreenWidth() / 1680 * 2
    self.ScaleDraw = self.Scale
    self.StepTime = 10
end

--------
-- Get a cont zone from the map id

-- Cache for IdToContZone lookups
local ContZoneCache = {}

function Nx.Map:IdToContZone (mapId)
    local info = self.MapWorldInfo[mapId]
    if info then
        return info.Cont or 90, info.Zone or 0
    end

    -- Check cache first
    if ContZoneCache[mapId] then
        return ContZoneCache[mapId][1], ContZoneCache[mapId][2]
    end

    -- Try to get parent map info for cities/sub-zones (cache result)
    local mapInfo = C_Map.GetMapInfo(mapId)
    if mapInfo and mapInfo.parentMapID then
        info = self.MapWorldInfo[mapInfo.parentMapID]
        if info then
            ContZoneCache[mapId] = {info.Cont or 90, mapInfo.parentMapID}
            return info.Cont or 90, mapInfo.parentMapID
        end
    end

    -- Cache the failure too
    ContZoneCache[mapId] = {90, 0}
    return 90, 0
end

--------
-- Get map name from id

function Nx.Map:IdToName (mapId)
    if not mapId then
        return ""
    end
    local name = Nx.Map:GetMapNameByID(mapId)
    if name then
        return name
    end
    return "?"
end

--------
-- Get map id from name

function Nx.Map:NameToId (mapName)
    return Nx.MapNameToId[mapName]
end

--------
--

function Nx.Map:IsNormalMap (mapId)
    for i = 1,self.ContCnt do
        for a,b in pairs(Nx.Map.MapZones[i]) do
            if b == mapId then
                return true
            end
        end
    end
    return false
end

--------
--

function Nx.Map:IsOutlandMap (mapId)
    return self.MapWorldInfo[zone].Cont == 3
end

--------
--

function Nx.Map:IsInstanceMap (mapId)
    if (Nx.Map:GetCurrentMapAreaID(true) == 20) then return false end
    local winfo = Nx.Map:GetMap(1).MapWorldInfo
    if mapId ~= 9000 and not winfo[mapId] then
        Nx.Map:GetZoneInfo (mapId)
    end
    if not winfo[mapId] then
        return false
    end
    if winfo[mapId].BaseMap then
       mapId = Nx.Map.MapWorldInfo[mapId].BaseMap
    end
    if winfo[mapId].Instance then
        return true
    end
    return false
end

--------
--

function Nx.Map:IsBattleGroundMap (mapId)
    if self.MapWorldInfo[mapId] and self.MapWorldInfo[mapId].Short then
        return true
    else
        return false
    end
end

-- Cache for micro dungeon checks
local MicroDungeonCache = {}

function Nx.Map:IsMicroDungeon(mapId)
    if MicroDungeonCache[mapId] ~= nil then
        return MicroDungeonCache[mapId]
    end

    local mapInfo = C_Map.GetMapInfo(mapId)
    -- mapType 5 = Enum.UIMapType.Micro (Micro Dungeon)
    local isMicro = mapInfo and mapInfo.mapType == 5
    MicroDungeonCache[mapId] = isMicro or false
    return isMicro or false
end

function Nx.Map:IsScenario(mapId)
    local name, instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID = GetInstanceInfo()
    if (Nx.Map:GetCurrentMapId() == mapId) then
        if (difficultyIndex == 1) then
            return true
        end
    end
    return false
end

function Nx.Map:GCMI_OVERRIDE(mapId)
    return mapId and Nx.Map:GetWorldZone(mapId) and Nx.Map:GetWorldZone(mapId).overrideMapWorldId or mapId
end
--------
-- Get map short name (only BGs have)

function Nx.Map:GetShortName (mapId)
    return Nx.Map.MapWorldInfo[mapId].Short
end

--------
-- Get world info for a continent
-- (cont #)

function Nx.Map:GetWorldContinentInfo (cont)
    local info = self.MapInfo[cont]
    if Nx.inBG then
        info = self.MapInfo[90]
    end
    if not info then
        return
    end

    return info.Name, info.X, info.Y
end

--------
-- Cache for parent map lookups (avoid C_Map.GetMapInfo every frame)
local ParentMapCache = {}

--------
-- Get world info for a continent and zone
-- (cont #, zone #)

function Nx.Map:GetWorldZoneInfo (cont, zone)
    local org_zone = zone
    if not cont or not zone then
        return "unknown", 0, 0, 1002, 668
    end
    local name = Nx.Map:GetMapNameByID(zone) or "Unknown Zone"
--    local cont = self.MapWorldInfo[zone].Cont
    local info = self.MapInfo[cont]
    if not info then
        return name, 0, 0, 1002, 668
    end
    if zone == 0 then
        zone = Nx.Map.MapZones[0][cont]
    end
    local winfo = self.MapWorldInfo[zone]
    if not winfo then
        -- Use cached parent lookup (populated by GetWorldZone)
        winfo = ParentMapCache[zone]
        if not winfo or not next(winfo) then
            return name, 0, 0, 1002, 668  -- Return defaults instead of nil
        end
    end
    if not winfo.X then
        return name, 0, 0, 1002, 668
    end
    local x = info.X + winfo.X
    local y = info.Y + winfo.Y

    if (cont == 10 and org_zone == 0) or (cont == 11 and org_zone == 0) then
        --winfo.Scale = (self.DebugPXOff or 1)
    end
    local scale = winfo.Scale * 100

    return name, x, y, scale, scale / 1.5        -- x, y, w, h
end

--------
-- Get world zone from map id
-- (id)

function Nx.Map:GetWorldZone (mapId)
    if self.MapWorldInfo[mapId] then
        return self.MapWorldInfo[mapId]
    end

    -- Check cache first
    if ParentMapCache[mapId] ~= nil then
        return ParentMapCache[mapId]
    end

    -- Try to get parent map info for cities/sub-zones (cache result)
    local mapInfo = C_Map.GetMapInfo(mapId)
    if mapInfo and mapInfo.parentMapID then
        local parentInfo = self.MapWorldInfo[mapInfo.parentMapID]
        if parentInfo then
            local isCityType = mapInfo.mapType == Enum.UIMapType.Zone or mapInfo.mapType == Enum.UIMapType.Orphan
            if isCityType and parentInfo.City then
                ParentMapCache[mapId] = parentInfo
                return parentInfo
            end
        end
    end

    -- Cache empty result too (so we don't keep looking it up)
    ParentMapCache[mapId] = {}
    return {}
end

--------
-- Get world zone scale from map id
-- (id)

function Nx.Map:GetWorldZoneScale (mapId)
    local winfo = self.MapWorldInfo[mapId]
    if winfo and winfo.BaseMap then
        winfo = self.MapWorldInfo[winfo.BaseMap]
    end
    if winfo and winfo.Scale then
        return winfo.Scale
    else
        return 10.02
    end
end

--------
-- Get world position of map (zone) location
-- (id, x (0-100), y (0-100)

function Nx.Map:GetWorldPos (mapId, mapX, mapY)
    if mapId == 9000 then
        return 0,0
    end
    local winfo = self.MapWorldInfo[mapId]
    if winfo then
        if winfo.BaseMap then
            winfo = self.MapWorldInfo[winfo.BaseMap]
        end
        local scale = winfo.Scale
            if not winfo[4] or not winfo[5] then
--            Nx.prt("GetWorldErr (Not Calculated): " .. mapId)
            return 0,0
        end
        if not scale then
--            Nx.prt("GetWorldErr (Scale): " .. mapId)
            return 0,0
        end

        return    winfo[4] + mapX * scale,
                    winfo[5] + mapY * scale / 1.5
    end
    if mapId then
        Nx.prtStack("GetPos Err:" .. mapId)
    else
        Nx.prtStack("GetPos Err")
    end
    return 0, 0
end

--------
-- Get world positions of map (zone) rectangle
-- (id, x, y)

function Nx.Map:GetWorldRect (mapId, mapX, mapY, mapX2, mapY2)

    local x, y = self:GetWorldPos (mapId, mapX, mapY)
    local x2, y2 = self:GetWorldPos (mapId, mapX2, mapY2)

    return x, y, x2, y2
end

--------
-- Get zone position of world location
-- (id, x, y)

function Nx.Map:GetZonePos (mapId, worldX, worldY)

--    self.GetZonePosCnt = (self.GetZonePosCnt or 0) + 1

--    Nx.prt ("WXY for map %s is %f %f", mapId, worldX, worldY)

    local winfo = self.MapWorldInfo[mapId]

    if winfo then
        if winfo.Scale and winfo[4] and winfo[5] then
            local scale = winfo.Scale
                return    (worldX - winfo[4]) / scale,
                        (worldY - winfo[5]) / scale * 1.5
        else
            return 0,0
        end
--        local x = (worldX - info.X - winfo[2]) / scale
--        local y = (worldY - info.Y - winfo[3]) / scale * 1.5

--        Nx.prt ("XY %f %f %f", x, y, scale)

--        return x, y
    end

    return 0, 0
end

--------
-- Get continent of world location
-- (wx, wy)

--[[
function Nx.Map:GetContFromPos (worldX, worldY)

    if worldY < -2050 then
        return 3
    end

    if worldX > 2200 then
        return 2
    end

    return 1
end
--]]

--------
-- Convert frame (top left) to zone positions

function Nx.Map:FramePosToZonePos (x, y)
    x = x / (self.MapW - self.PadX) * 100
    y = y / (self.MapH - self.TitleH) * 100
    return x, y
end


--------
-- Convert frame (top left) to world positions

function Nx.Map:FramePosToWorldPos (x, y)
    x = self.MapPosX + (x - self.PadX - self.MapW / 2) / 10.02 / self.MapScale
    y = self.MapPosY + (y - self.TitleH - self.MapH / 2) / 10.02 / self.MapScale
    return x, y
end


-------------------------------------------------------------------------------
-- TARGET MANAGEMENT
-- Functions for adding, removing, and managing navigation targets
-- Targets are waypoints that guide the player and show on the HUD
-------------------------------------------------------------------------------

---
-- Add a navigation target to the map
-- Handles clearing previous targets, recording to Notes, and assigning IDs
-- @param target  Target table with: MapId, TargetX1, TargetY1, TargetX2, TargetY2,
--                TargetType, TargetTex, TargetId, TargetName, keep (multi-target)
-- @return        The target table with UniqueId assigned
--
function Nx.Map:AddTarget (target)

    assert (target)
    assert (target.TargetX1)

    self.UpdateTrackingDelay = 0

    local sbt = self.ScaleBeforeTarget

--    if self.ScaleBeforeTarget then
--        self.Scale = self.ScaleBeforeTarget
        self.ScaleBeforeTarget = false
--    end

    if not target.keep then
        self:ClearTargets()
    end

    self.ScaleBeforeTarget = sbt or not next (self.Targets) and Nx.db.profile.Map.RestoreScaleAfterTrack and self.Scale

    tinsert (self.Targets, target)

    if not target.MapId then target.MapId = self.MapId; end
    target.TargetMX = (target.TargetX1 + target.TargetX2) * .5        -- Mid point
    target.TargetMY = (target.TargetY1 + target.TargetY2) * .5

    local i = self.TargetNextUniqueId
    target.UniqueId = i
    self.TargetNextUniqueId = i + 1

    if Nx.Notes then
        local zx, zy = self:GetZonePos (target.MapId, target.TargetMX, target.TargetMY)
        Nx.Notes:Record (target.keep and "Target" or "TargetS", target.TargetName, target.MapId, zx, zy)
    end

    return target
end


---
-- Set map target (legacy convenience wrapper for AddTarget)
-- @param typ     Target type string (e.g. "Goto", "Route", "Quest")
-- @param x1      World X coordinate (top-left of area)
-- @param y1      World Y coordinate (top-left of area)
-- @param x2      World X coordinate (bottom-right, same as x1 for point)
-- @param y2      World Y coordinate (bottom-right, same as y1 for point)
-- @param tex     Texture path (nil for default, false for none)
-- @param id      User-defined ID for this target
-- @param name    Display name for the target
-- @param keep    If true, add to existing targets; if false, clear first
-- @param mapId   Map ID for the target location
-- @return        The target table
--
function Nx.Map:SetTarget (typ, x1, y1, x2, y2, tex, id, name, keep, mapId)
    -- This is a legacy function, for more extensibility, use the Nx.Map:AddTarget (target) function instead
    return self:AddTarget({
        MapId = mapId,
        TargetType = typ,
        TargetX1 = x1,
        TargetY1 = y1,
        TargetX2 = x2,
        TargetY2 = y2,
        TargetTex = tex,
        TargetId = id,
        TargetName = name,
        keep = keep,
    });
end

---
-- Clear all navigation targets
-- Optionally only clear if first target matches specified type
-- Restores pre-target zoom scale if configured
-- @param matchType  Only clear if first target matches this type (nil = clear all)
--
function Nx.Map:ClearTargets (matchType)

    if matchType then
        local tar = self.Targets[1]
        if tar then
            if tar.TargetType ~= matchType then
                return
            end
        end
    end

    self.Targets = {}
    self.Tracking = {}

    if self.LOpts.NXAutoScaleOn and self.ScaleBeforeTarget then

--        Nx.prt ("ScaleBeforeTarget trigger %s", matchType or "nil")
--        self.Scale = self.ScaleBeforeTarget

        self:GotoPlayer()        -- Map won't move if cursor on it
        self:Move (self.PlyrX, self.PlyrY, self.ScaleBeforeTarget, 30)
    end

    self.ScaleBeforeTarget = false
end

---
-- Clear a specific target by its unique ID
-- @param uniqueId  The UniqueId assigned when target was created
--
function Nx.Map:ClearTarget (uniqueId)

    self.Tracking = {}

    local tar, i = self:FindTarget (uniqueId)

    if tar then
--        Nx.prt ("ClearTarget %s %s", uniqueId, i)
        tremove (self.Targets, i)
    end

end

---
-- Find a target by its unique ID
-- @param uniqueId  The UniqueId to search for
-- @return          target table and index, or nil if not found
--
function Nx.Map:FindTarget (uniqueId)
    for n, tar in ipairs (self.Targets) do
        if tar.UniqueId == uniqueId then
            return tar, n
        end
    end
end

---
-- Move a target to a different position in the order
-- @param srcI  Source index (-1 for last target)
-- @param dstI  Destination index (1-based)
--
function Nx.Map:ChangeTargetOrder (srcI, dstI)

    srcI = srcI >= 0 and srcI or #self.Targets    -- -1 for last target

    local t = tremove (self.Targets, srcI)
    tinsert (self.Targets, dstI, t)

    self.Tracking = {}
end

---
-- Reverse the order of all targets
-- Useful for going back along a route
--
function Nx.Map:ReverseTargets()

    local tar = self.Targets
    local n2 = #tar

    for n = 1, n2 / 2 do
        local a = tar[n]
        tar[n] = tar[n2]
        tar[n2] = a
        n2 = n2 - 1
    end

    self.Tracking = {}
end

---
-- Set map target at zone coordinates (0-100 range)
-- Converts zone coords to world coords and creates target
-- @param mid   Map ID for the zone
-- @param zx    Zone X coordinate (0-100)
-- @param zy    Zone Y coordinate (0-100)
-- @param name  Display name (defaults to "")
-- @param keep  Keep existing targets if true
-- @param tex   Optional texture path
-- @return      The target table
--
function Nx.Map:SetTargetXY (mid, zx, zy, name, keep, tex)
if Nx.Quest and Nx.Quest.Watch then
    Nx.Quest.Watch:ClearAutoTarget()
end
    local wx, wy = self:GetWorldPos (mid, zx, zy)
    return self:SetTarget ("Goto", wx, wy, wx, wy, tex, nil, name or "", keep, mid)
end

--------
-- Set map target at mouse click

function Nx.Map:SetTargetAtClick()
if Nx.Quest and Nx.Quest.Watch then
    Nx.Quest.Watch:ClearAutoTarget()
end
    local wx, wy
    if (self:IsInstanceMap(Nx.Map.RMapId) or self:IsBattleGroundMap(Nx.Map.RMapId)) and self.CurOpts.NXInstanceMaps then
        local _x, _y = self:FramePosToZonePos (self.ClickFrmX, self.ClickFrmY)
        wx, wy = self:GetWorldPos(self.MapId, _x, _y)
    else
        wx,wy = self:FramePosToWorldPos (self.ClickFrmX, self.ClickFrmY)
    end
    local zx, zy = self:GetZonePos (self.MapId, wx, wy)
    local str = format (L["Goto %.0f, %.0f"], zx, zy)

    self:SetTarget ("Goto", wx, wy, wx, wy, nil, nil, str, IsShiftKeyDown())
end

function Nx.Map:SetTargetAtStr (str, keep)

    local mId, zx, zy, desc = self:ParseTargetStr (str)
    if mId then
        local wx, wy = self:GetWorldPos (mId, zx, zy)
        local str = format ("%.0f, %.0f", zx, zy)
        if desc then
            str = desc
        end
        self:SetTarget ("Goto", wx, wy, wx, wy, nil, nil, str, keep, mId)
    end
end

--------
-- Parse map target string. "[zone] x y"
-- (string)

function Nx.Map:ParseTargetStr (str)

--    Nx.prt (str)

--    local str = gsub (strlower (str), ",", " ")

    local zone
    local zx, zy
    local desc

    for s in gmatch (str, "%S+") do
        if not zx and strsub(s,#s,#s) == "," then
            s = strsub(s,0,#s - 1)
        end
        local i = tonumber (s)
        if i then
            if zx then
                zy = zy or i
            else
                zx = i
            end
        else
            if zx and zy then
                if desc then
                    desc = desc .. " " .. s
                else
                    desc = s
                end
            else
                s = strlower(s)
                if zone then
                    zone = zone .. " " .. s
                else
                    zone = s
                end
            end
        end
    end

    local mid = Nx.Map.UpdateMapID

    if zone then
        mid = nil
        local cont = 0
        local curmid = Nx.Map:GetCurrentMapAreaID()

        for contN = 1, Nx.Map.ContCnt do
            local doesExist = string.find(zone, ":" .. string.lower(Nx.Map.MapInfo[contN].Name))
            if doesExist then
                zone = string.sub(zone,0,doesExist-1)
                cont = contN
            end
        end

        for id, zonedesc in pairs (Nx.Zones) do
            local name = strlower (string.gsub (zonedesc, "|.*", ""))
            if name == zone or string.sub (name, 1, #zone) == zone then
                if (cont > 0) and Nx.Map.MapWorldInfo[id].Cont == cont then
                    mid = id
                elseif (cont == 0) then
                    if not mid or math.abs(mid - curmid) > math.abs(mid - id) then
                        mid = id
                    end
                end
            end
        end

        if not mid then
            if cont ~= 0 then
                Nx.prt("zone %s not found on continent %s",zone,Nx.Map.MapInfo[cont].Name)
            else
                Nx.prt ("zone %s not found", zone)
            end
            return
        end
    end

    if not zx or not zy then
        Nx.prt ("zone coordinate error")
        return
    end

    return mid, zx, zy, desc
end

-------------------------------------------------------------------------------
-- TOMTOM EMULATION API
-- External functions for compatibility with addons expecting TomTom
-- Provides waypoint creation, removal, and callback support
-------------------------------------------------------------------------------

---
-- TomTom:AddWaypoint emulation
-- Creates a navigation waypoint compatible with TomTom v80200-1.0.5 API
-- @param mid  Map ID
-- @param zx   Zone X (0-1 range, will be multiplied by 100)
-- @param zy   Zone Y (0-1 range, will be multiplied by 100)
-- @param opt  Options table with title, callbacks, icons, etc.
-- @return     Unique waypoint ID for later reference
--
function Nx:TTAddWaypoint (mid, zx, zy, opt)

    local map = Nx.Map:GetMap (1)

    if Nx.Quest and Nx.Quest.Watch then
        Nx.Quest.Watch:ClearAutoTarget()
    end

    local TargetCallbacks;
    local callbacks = opt.callbacks;
    if callbacks then
        TargetCallbacks = {};

        local onclick = callbacks.world.onclick or callbacks.minimap.onclick;
        if onclick then
            TargetCallbacks.OnClick = function(target, f)
                pcall(onclick, "onclick", tooltip, target.UniqueId, target.dist);
            end;
        else
            TargetCallbacks.OnClick = false;
        end

        local onupdate = callbacks.world.tooltip_update or callbacks.minimap.tooltip_update;
        if onupdate then
            TargetCallbacks.OnTooltipUpdate = function(tooltip, target, f)
                pcall(onupdate, "tooltip_update", tooltip, target.UniqueId, target.dist);
            end;
        else
            TargetCallbacks.OnTooltipUpdate = false;
        end

        local onshow = callbacks.world.tooltip_show or callbacks.minimap.tooltip_show;
        if onshow then
            TargetCallbacks.OnTooltipShow = function(tooltip, target, f)
                pcall(onshow, "tooltip_show", tooltip, target.UniqueId, target.dist);
            end;
        else
            TargetCallbacks.OnTooltipShow = false;
        end
    end

    local wx, wy = map:GetWorldPos (mid, zx * 100, zy * 100)
    local tar = map:AddTarget({
        MapId = mid,
        TargetType = "Goto",
        TargetX1 = wx,
        TargetY1 = wy,
        TargetX2 = wx,
        TargetY2 = wy,
        TargetDisplayID = opt.worldmap_displayID or opt.minimap_displayID,
        TargetTex = opt.worldmap_icon or opt.minimap_icon,
        --TargetId = nil,    -- Not used
        TargetName = opt.title or "",
        TargetCallbacks = TargetCallbacks,
        keep = true,
    });

    map:ChangeTargetOrder (-1, 1)

    return tar.UniqueId
end

---
-- TomTom slash command handler (/way)
-- @param msg       Command arguments (zone x y description)
-- @param editbox   Calling editbox (unused)
--
function Nx:TTWayCmd(msg,editbox)
    local map = Nx.Map:GetMap(1)
    map:SetTargetAtStr (msg, true)
end

---
-- TomTom:AddZWaypoint emulation (legacy continent/zone based)
-- @param cont       Continent number
-- @param zone       Zone number within continent
-- @param zx         Zone X coordinate (0-100)
-- @param zy         Zone Y coordinate (0-100)
-- @param name       Waypoint name
-- @param _persist   Persistence flag (ignored)
-- @param _minimap   Minimap display (ignored)
-- @param _world     World map display (ignored)
-- @param callbackT  Callback table for distance triggers
-- @return           Unique waypoint ID
--
function Nx:TTAddZWaypoint (cont, zone, zx, zy, name, _persist, _minimap, _world, callbackT)

    local map = Nx.Map:GetMap (1)
    local mid = map:GetCurrentMapId()

    if cont and zone then
        mid = map:CZ2MapId (cont, zone)
    end

    return Nx:TTSetTarget (mid, zx, zy, name, callbackT)
end

---
-- TomTom:DefaultCallbacks emulation
-- Returns empty callback structure for compatibility
-- @param opts  Options (ignored)
-- @return      Default callbacks table structure
--
function Nx:TTDefaultCallbacks(opts)
    return {
        minimap = {},
        world = {},
        distance = {},
    }
end

---
-- TomTom:SetClosestWaypoint emulation
-- No-op as Carbonite handles waypoint ordering differently
-- @return  Always 0
--
function Nx:TTSetClosestWaypoint()
    return 0    -- Do nothing, but at least return the expected data format.
end

---
-- TomTom:SetCustomWaypoint emulation
-- Wrapper around TTAddZWaypoint with minimal parameters
-- @param cont       Continent number
-- @param zone       Zone number
-- @param zx         Zone X coordinate
-- @param zy         Zone Y coordinate
-- @param callbackT  Callback table
-- @return           Unique waypoint ID
--
function Nx:TTSetCustomWaypoint (cont, zone, zx, zy, callbackT)

    return Nx:TTAddZWaypoint (cont, zone, zx, zy, "", false, nil, nil, callbackT)
end

---
-- TomTom:SetCustomMFWaypoint emulation (map/floor based)
-- @param aid     Area ID (map ID)
-- @param _floor  Floor number (ignored, use dungeon levels)
-- @param zx      Zone X (0-1 range)
-- @param zy      Zone Y (0-1 range)
-- @param opts    Options with title, callbacks
-- @return        Unique waypoint ID
--
function Nx:TTSetCustomMFWaypoint (aid, _floor, zx, zy, opts)

    zx = zx * 100
    zy = zy * 100

    return Nx:TTSetTarget (aid, zx, zy, opts["title"], opts["callbacks"])
end


---
-- Internal TomTom target setter
-- Creates target with optional distance-based callbacks
-- @param mid        Map ID
-- @param zx         Zone X coordinate (0-100)
-- @param zy         Zone Y coordinate (0-100)
-- @param name       Target name
-- @param callbackT  Optional callback table with distance triggers
-- @return           Unique target ID
--
function Nx:TTSetTarget (mid, zx, zy, name, callbackT)

--    Nx.prt ("TTSetTarget %s %s %s %s", name or "nil", mid or "nil", zx, zy)

    local map = Nx.Map:GetMap (1)
    local tar = map:SetTargetXY (mid, zx, zy, name, true)

    map:ChangeTargetOrder (-1, 1)

    if callbackT and callbackT["distance"] then

        local d = 99999
        local f

        for dist, func in pairs (callbackT["distance"]) do
            if dist < d then
                d = dist
                f = func
            end
        end

        tar.Radius = d
        tar.RadiusFunc = f

--        Nx.prt (" R %s", d)
    end

    return tar.UniqueId
end

---
-- TomTom:RemoveWaypoint emulation
-- @param id  Unique waypoint ID from Add/Set functions
--
function Nx:TTRemoveWaypoint (id)

    local map = Nx.Map:GetMap (1)
    map:ClearTarget (id)
end

---
-- TomTom:SetCrazyArrow emulation
-- Updates waypoint radius trigger and display name
-- @param id    Unique waypoint ID
-- @param dist  Arrival radius in yards
-- @param str   New display name for the waypoint
--
function Nx:TTSetCrazyArrow (id, dist, str)

    local map = Nx.Map:GetMap (1)
    local tar = map:FindTarget (id)
    if tar then
        tar.Radius = dist
        tar.TargetName = str
    end
end

-------------------------------------------------------------------------------
-- EXTERNAL ICON API
-- Public functions for other addons to add icons to the Carbonite map
-------------------------------------------------------------------------------

---
-- Check if minimap is owned by Carbonite
-- @return  Boolean indicating minimap ownership
--
function Nx.MapMinimapOwned()
    local map = Nx.Map:GetMap (1)
    return map.MMOwn
end

---
-- Initialize an icon type from external addon
-- @param iconType  String identifier for the icon type
-- @param drawMode  Drawing mode: "ZP", "WP", or "ZR"
--
function Nx.MapInitIconType (iconType, drawMode)
    local map = Nx.Map:GetMap (1)
    map:InitIconType (iconType, drawMode)
end

---
-- Add a point icon by map name (external API)
-- @param iconType  String identifier for the icon type
-- @param mapName   Zone name string
-- @param x         Zone X coordinate (0-100)
-- @param y         Zone Y coordinate (0-100)
-- @param texture   Texture path
-- @param level     Dungeon level (nil for surface)
--
function Nx.MapAddIconPoint (iconType, mapName, x, y, texture, level)
    local map = Nx.Map:GetMap (1)
    local mapId = Nx.MapNameToId[mapName]

    if mapId then
        local wx, wy = map:GetWorldPos (mapId, x, y)
        map:AddIconPt (iconType, wx, wy, level, nil, texture)
    end
end

---
-- Add a custom named icon to the map (external API)
-- Icons persist and are redrawn automatically
-- @param name     Unique name for this icon (used for removal)
-- @param mapId    Map ID
-- @param x        Zone X coordinate (0-100)
-- @param y        Zone Y coordinate (0-100)
-- @param level    Dungeon level (nil for surface)
-- @param tip      Tooltip text
-- @param texture  Texture path
-- @param tx1      Texture coord left (optional)
-- @param ty1      Texture coord top (optional)
-- @param tx2      Texture coord right (optional)
-- @param ty2      Texture coord bottom (optional)
--
function Nx.MapAddIcon (name, mapId, x, y, level, tip, texture, tx1, ty1, tx2, ty2)
    if not Nx.CustomIcons then
        Nx.CustomIcons = {}
    end
    local map = Nx.Map:GetMap(1)
    if not Nx.CustomIcons[mapId] then
        Nx.CustomIcons[mapId] = {}
    end
    local wx, wy = map:GetWorldPos (mapId, x, y)
    Nx.CustomIcons[mapId][name] = {}
    Nx.CustomIcons[mapId][name].x = wx
    Nx.CustomIcons[mapId][name].y = wy
    Nx.CustomIcons[mapId][name].Level = level
    Nx.CustomIcons[mapId][name].tip = tip
    Nx.CustomIcons[mapId][name].texture = texture
    if tx1 and ty1 and tx2 and ty2 then
        Nx.CustomIcons[mapId][name].tx1 = tx1
        Nx.CustomIcons[mapId][name].ty1 = ty1
        Nx.CustomIcons[mapId][name].tx2 = tx2
        Nx.CustomIcons[mapId][name].ty2 = ty2
    end
    local CurMapId = map:GetCurrentMapId()
    if not Nx.db.char.Map.ShowCustom then
        return
    end
    if tx1 then
        local icon = map:AddIconPt("!CUSTOM",wx, wy, level, "FF0000", texture, tx1, ty1, tx2, ty2)
        if tip then
            map:SetIconTip(icon,tip)
        end
    else
        local icon = map:AddIconPt("!CUSTOM",wx, wy, level, "FF0000", texture)
        if tip then
            map:SetIconTip(icon,tip)
        end
    end
end

---
-- Remove a custom named icon from the map
-- @param name    Name used when adding the icon
-- @param mapNum  Map ID where icon was added
--
function Nx.MapRemoveIcon (name, mapNum)
    if not Nx.CustomIcons then
        return
    end
    local mapId = Nx.NxzoneToMapId[mapNum]
    if not Nx.CustomIcons[mapId] then
        return
    end
    if not Nx.CustomIcons[mapId][name] then
        return
    end
    Nx.CustomIcons[mapId][name] = nil
    local map = Nx.Map:GetMap (1)
    map:Update(1)
end

---
-- Add a rectangle icon by map name (external API)
-- @param iconType  String identifier for the icon type
-- @param mapName   Zone name string
-- @param x         Zone X top-left (0-100)
-- @param y         Zone Y top-left (0-100)
-- @param x2        Zone X bottom-right (0-100)
-- @param y2        Zone Y bottom-right (0-100)
-- @param color     Color hex with alpha
--
function Nx.MapAddIconRect (iconType, mapName, x, y, x2, y2, color)
    local map = Nx.Map:GetMap (1)
    local mapId = Nx.MapNameToId[mapName]

    if mapId then
        map:AddIconRect (iconType, mapId, x, y, x2, y2, color)
    end
end

---
-- Set tooltip on an icon (external API)
-- @param icon  Icon table from AddIconPoint/AddIconRect
-- @param tip   Tooltip string
--
function Nx.MapSetIconTip (icon, tip)
    local map = Nx.Map:GetMap (1)
    map:SetIconTip (icon, tip)
end

---
-- Keybinding function to skip current target
-- Sets the first target's radius to effectively infinite
--
function Nx.NXMapKeyTargetSkip()
    local self = Nx.Map:GetMap (1)

    local tar = self.Targets[1]
    if tar then
        tar.Radius = 999999999999
    end
end

-------------------------------------------------------------------------------
-- MINIMAP BUTTON DOCK
-- Window for collecting and organizing minimap buttons from other addons
-- Takes ownership of buttons and arranges them in a configurable grid
-------------------------------------------------------------------------------

---
-- Create the minimap button dock window
-- Initializes window and schedules button scanning
--
function Nx.Map.Dock:Create()

--PAIDS!

    if Nx.Free then
        return
    end

    self.UpdateMod = 100        -- Prevent error

    if not Nx.db.profile.MiniMap.ButOwn then
        return
    end

    -- Create Window

    Nx.Window:SetCreateFade (1, 0)

    local win = Nx.Window:Create ("NxMapDock", nil, nil, nil, 1, 1, nil, true)
    self.Win = win

    win:SetBGAlpha (0, 1)


    win:CreateButtons()
    win:InitLayoutData (nil, 100045, -.08, 45, 50, 2)

    win.Frm:SetToplevel (true)

    self:UpdateOptions()

    self.InitPending = true

    DockMinimapScan = Nx:ScheduleTimer(self.MinimapOwnInit,3,self)

--PAIDE!
end

---
-- Initialize minimap button ownership
-- Scans for known buttons and finds others attached to Minimap
-- Reparents all found buttons to the dock window
--
function Nx.Map.Dock:MinimapOwnInit()

    self.InitPending = nil

    local map = Nx.Map:GetMap (1)
    local mm = _G["Minimap"]

    local mmOwnerNames = {
        "NXMiniMapBut","GameTimeFrame","TimeManagerClockButton","MiniMapWorldMapButton","MiniMapMailFrame","MiniMapTracking","MiniMapVoiceChatFrame","QueueStatusMinimapButton","MiniMapInstanceDifficulty","GarrisonLandingPageMinimapButton","MiniMapLFGFrame",
    }

    local f = _G["MinimapBackdrop"]    -- Add so it gets ignored
    map.MMOwnedFrms[f] = 0

    self.MMFrms = {}

    for k, name in ipairs (mmOwnerNames) do
        local f = _G[name]
        if f then

            map.MMOwnedFrms[f] = 0
            tinsert (self.MMFrms, f)

            f:SetParent (self.Win.Frm)

            if name == "MiniMapTracking" then
                f:Show()
            end
        end
    end

    -- Scan all frames

    local texnames = { ["Interface\\AddOns\\CT_Core\\Images\\minimapIcon"] = 1, }

    local mapf = map.Frm
    local winf = self.Win.Frm

    local found = {}

    local f = EnumerateFrames()
    while f do

        if not f:IsObjectType ("Model") then
--        if f:IsShown() and not f:IsObjectType ("Model") then

            if pcall(f.GetPoint, f) then
                local pt, relTo = f:GetPoint()
                if relTo == mm then

                    local parent = f:GetParent()
                    if parent ~= mm and parent ~= mapf then
    --                    Nx.prtFrame ("Dock Scan", f)
                        found[f] = 1
                    end
                end
            end

            local reg = { f:GetRegions() }
            for k, v in ipairs (reg) do
                if v and v.GetObjectType then
                    local okType, objType = pcall(v.GetObjectType, v)
                    if okType and objType == "Texture" then
                        v:SetSnapToPixelGrid(false)
                        v:SetTexelSnappingBias(0)
                        local tname = v:GetTexture()
                        if type(tname) == "string" and texnames[tname] then
                            found[f] = 1
                            break
                        end
                    end
                end
            end
        end

        f = EnumerateFrames (f)
    end

    -- Add found frames to list

    for f in pairs (found) do

        if not map.MMOwnedFrms[f] then
            map.MMOwnedFrms[f] = 0
            tinsert (self.MMFrms, f)
            f:SetParent (winf)
        end
    end

    map.Win:Show (map.StartupShown)

    Nx.Map:MinimapButtonShowUpdate()

    if Nx.db.profile.Debug.DebugDock then
        Nx.prt ("DockScan %s", #self.MMFrms)
    end
end

---
-- Update dock options (transparency when locked)
--
function Nx.Map.Dock:UpdateOptions()

    local win = self.Win
    if win then

        local lock = win:IsLocked()
        win:SetBGAlpha (0, lock and 0 or 1)

        self.UpdateMod = 1
    end
end

---
-- Position and scale minimap buttons in the dock
-- Called periodically to handle newly shown buttons
-- Arranges buttons in a grid based on corner and column settings
--
function Nx.Map.Dock:MinimapDetachFrms()

    if Nx.Map:GetMap (1).Frm.NxMap.Tick % self.UpdateMod ~= 0 then
        return
    end

    if not self.Win then
        return
    end

    self.UpdateMod = 30

    if Nx.db.profile.Debug.DebugDock then
        Nx.prt ("Dock %s", #self.MMFrms)
    end

    local mm = _G["Minimap"]
    local mmClock = _G["TimeManagerClockButton"]
    local win = self.Win
    local winf = win.Frm
    local butLvl = winf:GetFrameLevel() + 1
    local cLvl = butLvl + 1
    local setCLvls = Nx.Util_SetChildLevels
    local strata = winf:GetFrameStrata()

    local mini = Nx.db.profile.MiniMap.ButWinMinimize

    local cx, cy = win:GetClientOffset()
    local cw, ch = win:GetSize()

    local columnCnt = mini and 1 or Nx.db.profile.MiniMap.ButColumns        -- max (floor (cw / 30), 1)
    local columnStart = 0
    local columnEnd = columnCnt - 1

    local colAdd = 1
    local spacing = Nx.db.profile.MiniMap.ButSpacing
    local yAdd = spacing
    local y = cy + 6

    local s = Nx.db.profile.MiniMap.ButCorner
    if s == "TopRight" or s == "BottomRight" then
        columnEnd = -columnEnd
--        columnStart, columnEnd = columnEnd, columnStart
        colAdd = -1
    end
    if s == "BottomLeft" or s == "BottomRight" then
        yAdd = -yAdd
        y = cy - 6
    end

    local column = columnStart
    local borderSize = win:GetBorderSize()
    local baseX = borderSize + 17
    local baseY = y
    local incRow

--    if IsAltKeyDown() then return end

    for n, f in ipairs (self.MMFrms) do

        if f:IsVisible() then

            local w = f:GetWidth()
            if w > 0 then

                local sc = 32 / max (w, 32)

                if incRow then
                    incRow = false
                    column = columnStart
                    y = y + yAdd
                end

                if mini and n > 1 then
                    column = 0
                    y = baseY
                    butLvl = 1
                    cLvl = 1
                    sc = .1
                end

                local x = baseX + column * spacing

                f:SetParent (winf)
                f:ClearAllPoints()

                if f == mmClock then
                    sc = sc * 1.5
--                    f:SetPoint ("CENTER", winf, "TOPLEFT", x / sc - 3, -y / sc + 3)
                end

                f:SetPoint ("CENTER", winf, "TOPLEFT", x / sc, -y / sc)

--                if f == mmt then
--                    sc = .82
--                    f:SetPoint ("CENTER", winf, "TOPLEFT", x / sc - 3, -y / sc + 3)
--                end

                f:SetScale (sc)

                f:SetFrameStrata (strata)
                f:SetFrameLevel (butLvl)
                setCLvls (f, cLvl)
--[[
                if IsControlKeyDown() then
                    Nx.prt ("MMFrms #%d %s %s", n, f:GetName() or "nil", w)
                    Nx.prtFrame ("", f)
                end
--]]
                if column == columnEnd then
                    incRow = true
                end

                column = column + colAdd
            end

        elseif f:IsShown() then        -- Strange? Fixes Outfitter Minimap button not drawing

--            Nx.prt ("Frm vis error %s", f:GetName() or "nil")
            f:Show()
        end
    end

    if not win.MovSizing then
--        local h = min (ch, cy - y)

        local x = winf:GetLeft()
        if not InCombatLockdown() then
            win:SetSize (34, 11)
        end
    end

    -- Debug

--[[

    if IsControlKeyDown() then

        local frms = {}

        for n, f in ipairs (self.MMFrms) do
            if frms[f] then
                Nx.prt ("Dup frm %s #%s", f:GetName() or "nil", n)
            end
            frms[f] = n
        end
    end
--]]
end

-------------------------------------------------------------------------------
-- ROUTING SYSTEM
-- Path optimization for gathering routes, quest targets, and waypoints
-- Uses nearest-neighbor algorithm with 2-opt optimization
-------------------------------------------------------------------------------

---
-- Create optimized route through gather icons
-- Collects all "!Ga" icons, merges nearby points, and optimizes path
--
function Nx.Map:RouteGathers()

    local points = {}
    local cnt = self:GetIconCnt ("!Ga")

    for n = 1, cnt do
        local wx, wy = self:GetIconPt ("!Ga", n)
        local x, y = self:GetZonePos (self.MapId, wx, wy)

        local pt = {}
        tinsert (points, pt)
        pt.X = x
        pt.Y = y
    end

    self:RouteMerge (points)

    local route = self:Route (points)
    if route then
        self:RouteToTargets (route, false)
    end
end

---
-- Create optimized route through current targets
-- Reorders existing targets for shortest travel distance
--
function Nx.Map:RouteTargets()
    local points = {}

    for n, tar in ipairs (self.Targets) do

        local wx = tar.TargetMX
        local wy = tar.TargetMY
        local x, y = self:GetZonePos (self.MapId, wx, wy)

        local pt = {}
        tinsert (points, pt)
        pt.Name = tar.TargetName
        pt.X = x
        pt.Y = y
    end

    local route = self:Route (points)
    if route then
        self:RouteToTargets (route)
    end
end

---
-- Create optimized route through quest objective points
-- @param points  Array of {X, Y, Name, Weight} tables
--
function Nx.Map:RouteQuests (points)
    local route = self:Route (points)
    if route then
        self:RouteToTargets (route, false)
    end
end

---
-- Merge nearby points to reduce route complexity
-- Points within MergeRadius yards are averaged into one
-- @param points  Array of {X, Y} tables (modified in place)
--
function Nx.Map:RouteMerge (points)

    local radius = Nx.db.profile.Route.MergeRadius

    if #points < 2 or radius < 1 then
        return
    end

    local tm = GetTime()

    sort (points, function (a, b) return a.X < b.X end)

--    for n, pt in ipairs (points) do
--        Nx.prt ("%s %s", n, pt.X)
--    end

    radius = radius / Nx.Map:GetWorldZoneScale (self.MapId) / 4.575
--    Nx.prt ("rad %s", radius)

    local radiusSq = radius ^ 2    -- Yards to world space squared

    local startCnt = #points
    local merged = true

    while merged do

        merged = false

        local close = 999999999
        local closeI1
        local closeI2

        for n1, pt1 in ipairs (points) do

--            local done

            for n2 = n1 + 1, #points do

                local pt2 = points[n2]

                if pt2.X - pt1.X > radius then
--                    Nx.prt ("done %s %s", pt1.X, pt2.X)
--                    done = true
                    break
                end

                local d = (pt1.X - pt2.X) ^ 2 + ((pt1.Y - pt2.Y) / 1.5) ^ 2
                if d < close then
                    close = d
                    closeI1 = n1
                    closeI2 = n2
--[[
                    if d ^ .5 < radius * .5 then    -- Close enough? Early out
                        Nx.prt ("%s + %s, %s", n1, n2, d ^ .5)
                        done = true
                        break
                    end
--]]
                end
            end

--            if done then
--                break
--            end
        end

        if close ^ .5 < radius then

--            Nx.prt (" + %s %s", closeI1, closeI2)

            local pt1 = points[closeI1]
            local pt2 = points[closeI2]

            pt1.X = (pt1.X + pt2.X) * .5        -- Average
            pt1.Y = (pt1.Y + pt2.Y) * .5

            tremove (points, closeI2)
            merged = true

            sort (points, function (a, b) return a.X < b.X end)
        end
    end

    Nx.prt ("Merged %s in %.1f secs", startCnt - #points, GetTime() - tm)
end

---
-- Generate optimized route using nearest-neighbor + 2-opt
-- Starting from player position, visits all points in efficient order
-- @param points  Array of {X, Y, Name} tables (consumed)
-- @return        Ordered route array or nil if empty input
--
function Nx.Map:Route (points)

    if #points == 0 then
        return
    end

    -- Test

    local tm = GetTime()
--[[
    local blks = 20
    local scale = 5

    local points = {}
    for n = 0, 399 do
        local pt = {}
        points[n + 1] = pt
        pt.X = n % blks * scale + floor (n / 7) % 2 * 3
        pt.Y = floor (n / blks) * scale + floor (n / 3) % 2 * 4
--        pt.X = random (1, 20)
--        pt.Y = random (1, 20)
    end
--]]

    --

    local route = {}

    for n, pt in ipairs (points) do
        pt.Y = pt.Y / 1.5        -- Make Y same units as X
    end

    -- Nearest neighbor

    if #points > 1 then

        local x = points[1].X
        local y = points[1].Y
        if x == points[#points].X and y == points[#points].Y then    -- End same as start?
            tremove (points)
        end
    end

    local x, y = self:GetZonePos (self.MapId, self.PlyrX, self.PlyrY)
    y = y / 1.5

    while #points > 0 do

        local closeDist = 999999999
        local closeI

        for n, pt in ipairs (points) do

            local dist = (x - pt.X) ^ 2 + (y - pt.Y) ^ 2
            if dist < closeDist then
                closeDist = dist
                closeI = n
            end
        end

        local pt = tremove (points, closeI)

        local r = {}
        tinsert (route, r)
        r.Name = pt.Name
        r.X = pt.X
        r.Y = pt.Y
        r.Weight = pt.Weight or 1

        x = pt.X
        y = pt.Y
    end

    -- Add first node at end if needed for loop

    local x = route[1].X
    local y = route[1].Y

    if x ~= route[#route].X or y ~= route[#route].Y then

--        Nx.prt ("%f %f %f %f", x, route[#route].X, y, route[#route].Y)

        local r = {}
        r.X = x
        r.Y = y
        tinsert (route, r)
    end

    -- Calc length (sets node distances)

    local len = self:RouteLen (route)
--    Nx.prt ("Route len %s, %s secs", len, GetTime() - tm)

    -- Optimize .517 secs on 400

    for n = 1, 5 do
        local swap = self:RouteOptimize (route)
--        local len = self:RouteLen (route)
--        Nx.prt ("Route opt #%s len %s, %s secs", #route, len, GetTime() - tm)
        if not swap then
            break
        end
    end

    -- Show info

    local scale = self:GetWorldZoneScale (self.MapId)
    local len = self:RouteLen (route)
    Nx.prt ("Routed %s nodes, %d yards in %.1f secs", #route, len * scale * 4.575, GetTime() - tm)

    return route
end

---
-- Get quest achievement info for current zone
-- @param always  Show even if achievement is complete
-- @return        Formatted string with progress or nil
--
function Nx.Map:GetZoneAchievement (always)

    local mId = Nx.Map:GetCurrentMapId()
--    local mId = Map:GetRealMapId()
    if not Nx.Map.MapWorldInfo[mId] then
        return
    end
    local a = Nx.Map.MapWorldInfo[mId].QAchievementId
    --[[if a then

        local id, name, _, done = GetAchievementInfo (a)
        if always or not done then
            if GetAchievementNumCriteria(a) > 0 then
                local _, _, done, cnt, need = GetAchievementCriteriaInfo (a, 1)
                local col = done and "|cff808080" or "|cff8080ff"
                return format ("%s%s %d/%d", col, name, cnt, need)
            end
        end
    end]]--
end

---
-- Convert route to navigation targets
-- Creates a target for each route point with radius trigger
-- @param route       Array of {X, Y, Name} from Route()
-- @param targetIcon  Optional texture for target icons (false for none)
--
function Nx.Map:RouteToTargets (route, targetIcon)
    if Nx.Quest and Nx.Quest.Watch then
        Nx.Quest.Watch:ClearAutoTarget()
    end
    local mapId = self.MapId

    for n, r in ipairs (route) do

        local wx, wy = self:GetWorldPos (mapId, r.X, r.Y * 1.5)
        local s = format ("Route%s (%s) %s", n, #route - n + 1, r.Name or "")
        local tar = self:SetTarget ("Route", wx, wy, wx, wy, targetIcon, nil, s, n ~= 1)

        tar.Radius = Nx.db.profile.Route.GatherRadius

--        self:SetTargetXY (mapId, r.X, r.Y * 1.5, "r" .. n, true)
    end
end

---
-- Calculate total route length and per-segment distances
-- Stores Dist on each route node for optimization
-- @param route  Array of {X, Y} route points
-- @return       Total length in world units
--
function Nx.Map:RouteLen (route)

    local len = 0

    for n = 1, #route - 1 do
        local r1 = route[n]
        local r2 = route[n + 1]
        r1.Dist = ((r1.X - r2.X) ^ 2 + (r1.Y - r2.Y) ^ 2) ^ .5
        len = len + r1.Dist
--        Nx.prt ("Route %s len %s", n, ((x - r.X) ^ 2 + (y - r.Y) ^ 2) ^ .5)
    end

    return len
end

---
-- Apply 2-opt optimization to improve route
-- Repeatedly reverses segments where it reduces total length
-- @param route  Route array (modified in place)
-- @return       true if any swaps made, false if optimal
--
function Nx.Map:RouteOptimize (route)

    local swap

---[[ 1394.4788 len
    for len = #route - 2, 2, -1 do

        for n = 1, #route - len - 1 do

            local r1 = route[n]
            local r2 = route[n + 1]
            local n2 = n + len
            local r3 = route[n2]
            local r4 = route[n2 + 1]

            if r1.Dist + r3.Dist >
                ((r1.X - r3.X) ^ 2 + (r1.Y - r3.Y) ^ 2) ^ .5 + ((r2.X - r4.X) ^ 2 + (r2.Y - r4.Y) ^ 2) ^ .5 then

                self:RouteSwap (route, n + 1, len)

--                local dist1 = ((r1.X - r2.X) ^ 2 + (r1.Y - r2.Y) ^ 2) ^ .5 + ((r3.X - r4.X) ^ 2 + (r3.Y - r4.Y) ^ 2) ^ .5
--                local dist2 = ((r1.X - r3.X) ^ 2 + (r1.Y - r3.Y) ^ 2) ^ .5 + ((r2.X - r4.X) ^ 2 + (r2.Y - r4.Y) ^ 2) ^ .5
--                Nx.prt ("Route %s swap %s %s %s", len, n, dist1 or 0, dist2 or 0)

                swap = true
            end
        end
    end
--]]

--[[    Little slower
    for last = #route - 1, 2, -1 do

        for n = 1, last - 2 do

            local r1 = route[n]
            local r2 = route[n + 1]
            local n2 = last
            local r3 = route[n2]
            local r4 = route[n2 + 1]

            if r1.Dist + r3.Dist >
                ((r1.X - r3.X) ^ 2 + (r1.Y - r3.Y) ^ 2) ^ .5 + ((r2.X - r4.X) ^ 2 + (r2.Y - r4.Y) ^ 2) ^ .5 then

                self:RouteSwap (route, n + 1, last - n)

--                local dist1 = ((r1.X - r2.X) ^ 2 + (r1.Y - r2.Y) ^ 2) ^ .5 + ((r3.X - r4.X) ^ 2 + (r3.Y - r4.Y) ^ 2) ^ .5
--                local dist2 = ((r1.X - r3.X) ^ 2 + (r1.Y - r3.Y) ^ 2) ^ .5 + ((r2.X - r4.X) ^ 2 + (r2.Y - r4.Y) ^ 2) ^ .5
                Nx.prt ("Route %s swap %s %s %s", last - n, n, dist1 or 0, dist2 or 0)

                swap = true
            end
        end
    end
--]]

    return swap
end

---
-- Reverse a segment of the route (2-opt swap operation)
-- Example: 1 2 3 4 5 6 7 8 with (3, 4) becomes 1 2 6 5 4 3 7 8
-- @param route  Route array (modified in place)
-- @param first  First index of segment to reverse
-- @param len    Length of segment to reverse
--
function Nx.Map:RouteSwap (route, first, len)

    -- 1 2 3 4 5 6 7 8    Before (3, +4)
    -- 1 2 6 5 4 3 7 8    After

    local last = first + len - 1
    local stop = first + floor (len / 2) - 1

--[[    Loop unroll does not help
    local loops = floor (len / 2)

--    if loops > 1 then

--        Nx.prt ("Route swap loops %s", loops)

        if loops % 2 ~= 0 then
            route[first], route[last] = route[last], route[first]
            first = first + 1
            last = last - 1
        end

        for n = first, stop, 2 do
            route[n], route[last] = route[last], route[n]
            route[n+1], route[last-1] = route[last-1], route[n+1]
            last = last - 2
        end
    else
--]]

    local n2 = last
    for n = first, stop do
        route[n], route[n2] = route[n2], route[n]
        n2 = n2 - 1
    end

    for n = first - 1, last do
        local r1 = route[n]
        local r2 = route[n + 1]
        r1.Dist = ((r1.X - r2.X) ^ 2 + (r1.Y - r2.Y) ^ 2) ^ .5
    end
end

-------------------------------------------------------------------------------
-- LOCATION STRING PACKING/UNPACKING
-- Functions for encoding/decoding map positions to/from compact strings
-- Used for data storage and communication
-------------------------------------------------------------------------------

---
-- Unpack location point relative to vehicle (e.g., airship)
-- @param str  Encoded location string
-- @param loc  Offset into string
-- @return     x, y coordinates adjusted for vehicle position
--
function Nx.Map:UnpackLocPtRelative (str, loc)

    local cnt
    local ox, oy = Nx.Map:UnpackLocPtOff (str, loc)

    ox = ox - 50
    oy = oy - 50

    for n = 1, GetNumBattlefieldVehicles() do

        local x, y, unitName, possessed, typ, dir, player = GetBattlefieldVehicleInfo (n, Nx.Map:GetCurrentMapId())
        if x and not player then

            if typ == Nx.AirshipType then
                cnt = 1

                dir = dir / PI * 180
                oy = oy / 1.5
                ox, oy = ox * cos (dir) + oy * sin (dir), (ox * -sin (dir) + oy * cos (dir)) * 1.5
                ox = x * 100 + ox
                oy = y * 100 + oy

--                Nx.prt ("%s Airship %s %s %s", name, typ, ox, oy)
                break
            end
        end
    end

    if not cnt then
        ox = ox + 62
        oy = oy + 42
    end

    return ox, oy
end

---
-- Unpack location data from string
-- Handles two formats: " xywh" (area) or "!xxyy" (precise point)
-- @param locStr  Encoded location string
-- @param off     Offset into string
-- @return        x, y coordinates (0-100 range)
--
function Nx.Map:UnpackLoc (locStr, off)

    local isPt = strbyte (locStr, off) <= 33        -- Space or !

    if isPt then

        local x1, x2, y1, y2 = strbyte (locStr, 1 + off, 4 + off)
        return    ((x1 - 35) * 221 + (x2 - 35)) / 100,
                    ((y1 - 35) * 221 + (y2 - 35)) / 100
    end

    local x, y, w, h = strbyte (locStr, 0 + off, 3 + off)

    return    (x - 35) * .5,        -- * 100 / 200, Optimised
                (y - 35) * .5        -- * 100 / 200

end

---
-- Unpack rectangle location data "xywh"
-- @param locStr  4-character encoded string
-- @return        x, y, width, height in zone/world units
--
function Nx.Map:UnpackLocRect (locStr)

    local x, y, w, h = strbyte (locStr, 1, 4)

    return    (x - 35) * .5,        -- * 100 / 200    Optimised
                (y - 35) * .5,        -- * 100 / 200
                (w - 35) * 5.01,    -- * 1002 / 200,
                (h - 35) * 3.34    -- * 668 / 200
end

---
-- Unpack precise point location data "xxyy"
-- @param locStr  4-character encoded string
-- @return        x, y coordinates (0-100 range, 0.01 precision)
--
function Nx.Map:UnpackLocPt (locStr)
    local x1, x2, y1, y2 = strbyte (locStr, 1, 4)
    return    ((x1 - 35) * 221 + (x2 - 35)) / 100,
                ((y1 - 35) * 221 + (y2 - 35)) / 100
end

---
-- Unpack precise point location data at offset
-- @param locStr  Encoded string
-- @param off     Starting offset
-- @return        x, y coordinates (0-100 range)
--
function Nx.Map:UnpackLocPtOff (locStr, off)

    local x1, x2, y1, y2 = strbyte (locStr, off, 3 + off)
    return    ((x1 - 35) * 221 + (x2 - 35)) / 100,
                ((y1 - 35) * 221 + (y2 - 35)) / 100
end

---
-- Unpack quest objective data string
-- @param obj  Encoded objective string
-- @return     description, zone, offset (or just description if no location)
--
function Nx.Map:UnpackObjective (obj)
    if not obj then
        return
    end

    local i = strbyte (obj) - 35 + 1
    local desc = strsub (obj, 2, i)

    if #obj == i then
        return desc
    end

    local zone = strbyte (obj, i + 1) - 35
    return desc, zone, i + 2
end

-------------------------------------------------------------------------------
-- EDIT MODE - QUEST OBJECTIVE RECTANGLE DRAWING
-- Allows manual drawing of multiple objective rectangles on the map
-- Activated with /carb editmode, draw with Ctrl+Alt+LeftClick+Drag
-- Each rectangle has a close button, finish button outputs all rectangles
-------------------------------------------------------------------------------

---
-- Toggle edit mode for quest objective rectangle drawing
--
function Nx.Map:ToggleEditMode()
    self.EditMode = not self.EditMode
    if self.EditMode then
        Nx.prt("|cff00ff00Quest Objective Edit Mode ENABLED|r")
        Nx.prt("|cffffffff  Ctrl+Alt+Click = place a point (type 32)|r")
        Nx.prt("|cffffffff  Ctrl+Alt+Click+Drag = draw a rectangle (type 35)|r")
        Nx.prt("|cffffffff  Click [X] to remove, [Finish] to output all|r")
        self:EditModeCreateFinishButton()
    else
        Nx.prt("|cffff0000Quest Objective Edit Mode DISABLED|r")
        self:EditModeClearAll()
    end
end

---
-- Create the finish button for outputting all rectangles
--
function Nx.Map:EditModeCreateFinishButton()
    if self.EditFinishButton then
        self.EditFinishButton:Show()
        return
    end

    local map = self
    local f = CreateFrame("Button", nil, self.Frm, "UIPanelButtonTemplate")
    f:SetSize(80, 22)
    f:SetPoint("TOPRIGHT", self.Frm, "TOPRIGHT", -10, -30)
    f:SetText("Finish")
    f:SetFrameLevel(100)
    f:SetScript("OnClick", function()
        map:EditModeFinish()
    end)
    f:SetScript("OnEnter", function(self)
        Nx.TooltipText:SetOwner(self, "ANCHOR_LEFT")
        Nx.TooltipText:AddLine("Output all rectangles to chat")
        Nx.TooltipText:AddLine("and clear the editor", 0.7, 0.7, 0.7)
        Nx.TooltipText:Show()
    end)
    f:SetScript("OnLeave", function()
        Nx.TooltipText:Hide()
    end)

    -- Add a "Clear All" button next to it
    local clearBtn = CreateFrame("Button", nil, self.Frm, "UIPanelButtonTemplate")
    clearBtn:SetSize(70, 22)
    clearBtn:SetPoint("RIGHT", f, "LEFT", -5, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetFrameLevel(100)
    clearBtn:SetScript("OnClick", function()
        map:EditModeClearRectangles()
        Nx.prt("|cffff8000All rectangles cleared|r")
    end)
    clearBtn:SetScript("OnEnter", function(self)
        Nx.TooltipText:SetOwner(self, "ANCHOR_LEFT")
        Nx.TooltipText:AddLine("Clear all rectangles")
        Nx.TooltipText:AddLine("without outputting", 0.7, 0.7, 0.7)
        Nx.TooltipText:Show()
    end)
    clearBtn:SetScript("OnLeave", function()
        Nx.TooltipText:Hide()
    end)

    -- Rectangle count label
    local countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("RIGHT", clearBtn, "LEFT", -10, 0)
    countLabel:SetText("0 rects")

    self.EditFinishButton = f
    self.EditClearButton = clearBtn
    self.EditCountLabel = countLabel
end

---
-- Update the rectangle count display
--
function Nx.Map:EditModeUpdateCount()
    if self.EditCountLabel then
        local total = #self.EditRectangles
        local points = 0
        local rects = 0
        for _, data in ipairs(self.EditRectangles) do
            if data.isPoint then
                points = points + 1
            else
                rects = rects + 1
            end
        end

        local text
        if points > 0 and rects > 0 then
            text = rects .. "R " .. points .. "P"
        elseif points > 0 then
            text = points .. (points == 1 and " pt" or " pts")
        elseif rects > 0 then
            text = rects .. (rects == 1 and " rect" or " rects")
        else
            text = "0"
        end

        self.EditCountLabel:SetText(text)
        if total > 0 then
            self.EditCountLabel:SetTextColor(0, 1, 0)
        else
            self.EditCountLabel:SetTextColor(0.7, 0.7, 0.7)
        end
    end
end

---
-- Clear all rectangles without output
--
function Nx.Map:EditModeClearRectangles()
    -- Hide all rectangle frames
    for i, frame in ipairs(self.EditRectFrames) do
        frame:Hide()
    end
    self.EditRectFrames = {}
    self.EditRectangles = {}

    if self.EditPreviewFrame then
        self.EditPreviewFrame:Hide()
    end
    self.EditDrawing = false
    self:EditModeUpdateCount()
end

---
-- Clear everything and hide UI
--
function Nx.Map:EditModeClearAll()
    self:EditModeClearRectangles()

    if self.EditFinishButton then
        self.EditFinishButton:Hide()
    end
    if self.EditClearButton then
        self.EditClearButton:Hide()
    end
    if self.EditCountLabel then
        self.EditCountLabel:SetText("")
    end
end

---
-- Create a persistent rectangle frame with close button
-- @param rectData  Table with x, y, w, h, mapId
-- @param index     Index in the rectangles array
--
function Nx.Map:EditModeCreateRectFrame(rectData, index)
    local map = self

    -- Use stable frame level (base + high offset to be above map elements)
    local baseLevel = self.Frm:GetFrameLevel() + 100

    -- Main rectangle frame
    local f = CreateFrame("Frame", nil, self.Frm)
    f:SetFrameLevel(baseLevel)
    f.NxEditIndex = index
    f.NxRectData = rectData
    f.NxBaseLevel = baseLevel  -- Store for later use

    -- Rectangle texture (semi-transparent green with border effect)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(f)
    t:SetColorTexture(0, 0.8, 0, 0.35)
    f.texture = t

    -- Border textures for visibility
    local borderSize = 2
    local borders = {}
    for i = 1, 4 do
        local b = f:CreateTexture(nil, "OVERLAY")
        b:SetColorTexture(0, 1, 0, 0.9)
        borders[i] = b
    end
    -- Top
    borders[1]:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    borders[1]:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    borders[1]:SetHeight(borderSize)
    -- Bottom
    borders[2]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    borders[2]:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    borders[2]:SetHeight(borderSize)
    -- Left
    borders[3]:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    borders[3]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    borders[3]:SetWidth(borderSize)
    -- Right
    borders[4]:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    borders[4]:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    borders[4]:SetWidth(borderSize)
    f.borders = borders

    -- Close button (X) in upper right
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetFrameLevel(baseLevel + 5)
    closeBtn.NxEditIndex = index

    -- Close button background
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.8, 0, 0, 0.8)

    -- Close button X text
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 1, 1)

    closeBtn:SetScript("OnClick", function(self)
        map:EditModeRemoveRect(self.NxEditIndex)
    end)
    closeBtn:SetScript("OnEnter", function(self)
        closeBg:SetColorTexture(1, 0, 0, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        closeBg:SetColorTexture(0.8, 0, 0, 0.8)
    end)

    f.closeBtn = closeBtn

    -- Index label
    local indexLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    indexLabel:SetPoint("CENTER", f, "CENTER", 0, 0)
    indexLabel:SetText(tostring(index))
    indexLabel:SetTextColor(1, 1, 1, 0.7)
    f.indexLabel = indexLabel

    return f
end

---
-- Create a point marker frame with close button
-- @param pointData  Table with x, y, mapId, isPoint=true
-- @param index      Index in the rectangles array
--
function Nx.Map:EditModeCreatePointFrame(pointData, index)
    local map = self

    -- Use stable frame level
    local baseLevel = self.Frm:GetFrameLevel() + 105  -- Slightly above rectangles

    -- Main point frame (fixed size circle/dot)
    local f = CreateFrame("Frame", nil, self.Frm)
    f:SetSize(16, 16)
    f:SetFrameLevel(baseLevel)
    f.NxEditIndex = index
    f.NxRectData = pointData
    f.NxBaseLevel = baseLevel
    f.NxIsPoint = true

    -- Point texture (cyan/blue dot)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(f)
    t:SetTexture("Interface\\MINIMAP\\ObjectIconsAtlas")
    t:SetTexCoord(0.2578125, 0.2890625, 0.0078125, 0.0390625)  -- Small dot
    t:SetVertexColor(0, 1, 1, 1)  -- Cyan color
    f.texture = t

    -- Alternative: colored circle texture
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("CENTER")
    bg:SetSize(14, 14)
    bg:SetColorTexture(0, 0.8, 0.8, 0.6)
    f.bg = bg

    -- Border ring
    local ring = f:CreateTexture(nil, "BORDER")
    ring:SetPoint("CENTER")
    ring:SetSize(16, 16)
    ring:SetColorTexture(0, 1, 1, 0.9)
    f.ring = ring

    -- Inner dot
    local dot = f:CreateTexture(nil, "ARTWORK")
    dot:SetPoint("CENTER")
    dot:SetSize(10, 10)
    dot:SetColorTexture(0, 0.6, 0.6, 1)
    f.dot = dot

    -- Close button (X)
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(12, 12)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
    closeBtn:SetFrameLevel(baseLevel + 5)
    closeBtn.NxEditIndex = index

    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.8, 0, 0, 0.8)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 1, 1)

    closeBtn:SetScript("OnClick", function(self)
        map:EditModeRemoveRect(self.NxEditIndex)
    end)
    closeBtn:SetScript("OnEnter", function(self)
        closeBg:SetColorTexture(1, 0, 0, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        closeBg:SetColorTexture(0.8, 0, 0, 0.8)
    end)

    f.closeBtn = closeBtn

    -- Index label
    local indexLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    indexLabel:SetPoint("BOTTOM", f, "TOP", 0, 2)
    indexLabel:SetText(tostring(index))
    indexLabel:SetTextColor(0, 1, 1, 0.9)
    f.indexLabel = indexLabel

    return f
end

---
-- Position a point frame at world coordinates
-- @param frm  Frame to position
-- @param wx   World X coordinate
-- @param wy   World Y coordinate
-- @return     true if visible, false if off-screen
--
function Nx.Map:EditModePositionPoint(frm, wx, wy)
    local scale = self.ScaleDraw
    local clipW = self.MapW
    local clipH = self.MapH

    -- Calculate screen position from world coordinates (centered)
    local sx = (wx - self.MapPosXDraw) * scale + clipW * 0.5
    local sy = (wy - self.MapPosYDraw) * scale + clipH * 0.5

    -- Check if off screen (with margin for point size)
    if sx < -8 or sx > clipW + 8 or sy < -8 or sy > clipH + 8 then
        frm:Hide()
        return false
    end

    -- Position the frame centered on the point
    frm:ClearAllPoints()
    frm:SetPoint("CENTER", self.Frm, "TOPLEFT", sx, -sy - self.TitleH)
    frm:Show()

    return true
end

---
-- Remove a rectangle or point by index
-- @param index  Index of item to remove
--
function Nx.Map:EditModeRemoveRect(index)
    -- Get type before removing
    local wasPoint = self.EditRectangles[index] and self.EditRectangles[index].isPoint

    -- Hide and remove the frame
    if self.EditRectFrames[index] then
        self.EditRectFrames[index]:Hide()
    end

    -- Remove from arrays
    table.remove(self.EditRectangles, index)
    table.remove(self.EditRectFrames, index)

    -- Re-index remaining frames
    for i, frame in ipairs(self.EditRectFrames) do
        frame.NxEditIndex = i
        frame.closeBtn.NxEditIndex = i
        frame.indexLabel:SetText(tostring(i))
    end

    self:EditModeUpdateCount()
    local itemType = wasPoint and "Point" or "Rectangle"
    Nx.prt("|cff808080%s %d removed (%d remaining)|r", itemType, index, #self.EditRectangles)
end

---
-- Handle mouse down in edit mode
-- Starts rectangle drawing on Ctrl+Alt+LeftButton
-- @param button  Mouse button pressed
-- @return        true if event was consumed, false otherwise
--
function Nx.Map:EditModeMouseDown(button)
    if not self.EditMode then return false end

    if button == "LeftButton" and IsControlKeyDown() and IsAltKeyDown() then
        -- Calculate click position - convert frame pos to world, then to zone coords
        self:CalcClick()
        local wx, wy = self:FramePosToWorldPos(self.ClickFrmX, self.ClickFrmY)
        local x, y = self:GetZonePos(self.MapId, wx, wy)

        -- Clamp to valid range
        x = max(0, min(100, x))
        y = max(0, min(100, y))

        self.EditDrawing = true
        self.EditStartX = x
        self.EditStartY = y
        self.EditMapId = self.MapId

        -- Create preview frame if it doesn't exist
        if not self.EditPreviewFrame then
            local f = CreateFrame("Frame", nil, self.Frm)
            local previewLevel = self.Frm:GetFrameLevel() + 110  -- Above rect frames
            f:SetFrameLevel(previewLevel)
            f.NxBaseLevel = previewLevel
            local t = f:CreateTexture(nil, "OVERLAY")
            t:SetAllPoints(f)
            t:SetColorTexture(0.2, 1, 0.2, 0.4)  -- Bright green for active drawing
            f.texture = t
            self.EditPreviewFrame = f
        end
        self.EditPreviewFrame:Show()

        return true
    end
    return false
end

---
-- Position an edit mode rectangle frame using world coordinates
-- @param frm    Frame to position
-- @param wx1    World X of top-left
-- @param wy1    World Y of top-left
-- @param wx2    World X of bottom-right
-- @param wy2    World Y of bottom-right
-- @return       true if visible, false if off-screen
--
function Nx.Map:EditModePositionRect(frm, wx1, wy1, wx2, wy2)
    local scale = self.ScaleDraw
    local clipW = self.MapW
    local clipH = self.MapH

    -- Calculate screen positions from world coordinates
    local sx1 = (wx1 - self.MapPosXDraw) * scale + clipW * 0.5
    local sy1 = (wy1 - self.MapPosYDraw) * scale + clipH * 0.5
    local sx2 = (wx2 - self.MapPosXDraw) * scale + clipW * 0.5
    local sy2 = (wy2 - self.MapPosYDraw) * scale + clipH * 0.5

    -- Check if completely off screen
    if sx2 < 0 or sx1 > clipW or sy2 < 0 or sy1 > clipH then
        frm:Hide()
        return false
    end

    -- Clamp to visible area
    sx1 = max(0, sx1)
    sy1 = max(0, sy1)
    sx2 = min(clipW, sx2)
    sy2 = min(clipH, sy2)

    local w = sx2 - sx1
    local h = sy2 - sy1

    if w < 1 or h < 1 then
        frm:Hide()
        return false
    end

    -- Position the frame - clear existing points first!
    frm:ClearAllPoints()
    frm:SetPoint("TOPLEFT", self.Frm, "TOPLEFT", sx1, -sy1 - self.TitleH)
    frm:SetSize(w, h)
    frm:Show()

    return true
end

---
-- Update edit mode - preview rectangle and existing rectangles
-- Called during OnUpdate
--
function Nx.Map:EditModeUpdate()
    if not self.EditMode then return end

    -- Update preview rectangle if drawing
    if self.EditDrawing and self.EditPreviewFrame then
        local f = self.Frm
        local cx, cy = GetCursorPosition()
        cx = cx / f:GetEffectiveScale()
        cy = cy / f:GetEffectiveScale()

        local frmX = cx - f:GetLeft()
        local frmY = f:GetTop() - cy

        -- Convert frame position to world, then to zone coordinates
        local wx, wy = self:FramePosToWorldPos(frmX, frmY)
        local endX, endY = self:GetZonePos(self.EditMapId, wx, wy)

        -- Clamp to valid range
        endX = max(0, min(100, endX))
        endY = max(0, min(100, endY))

        -- Calculate rectangle bounds
        local x1 = min(self.EditStartX, endX)
        local y1 = min(self.EditStartY, endY)
        local x2 = max(self.EditStartX, endX)
        local y2 = max(self.EditStartY, endY)

        -- Convert zone coords back to world coordinates for drawing
        local wx1, wy1 = self:GetWorldPos(self.EditMapId, x1, y1)
        local wx2, wy2 = self:GetWorldPos(self.EditMapId, x2, y2)

        if self:EditModePositionRect(self.EditPreviewFrame, wx1, wy1, wx2, wy2) then
            -- Use stored stable frame level
            if self.EditPreviewFrame.NxBaseLevel then
                self.EditPreviewFrame:SetFrameLevel(self.EditPreviewFrame.NxBaseLevel)
            end
            self.EditPreviewFrame.texture:SetColorTexture(0.2, 1, 0.2, 0.4)
        end
    end

    -- Update all existing rectangle/point positions (for map pan/zoom)
    for i, frame in ipairs(self.EditRectFrames) do
        local data = frame.NxRectData
        if data then
            if data.isPoint then
                -- Position point
                local pwx, pwy = self:GetWorldPos(data.mapId, data.x, data.y)
                if self:EditModePositionPoint(frame, pwx, pwy) then
                    if frame.NxBaseLevel then
                        frame:SetFrameLevel(frame.NxBaseLevel)
                    end
                end
            else
                -- Position rectangle
                local wx1, wy1 = self:GetWorldPos(data.mapId, data.x, data.y)
                local wx2, wy2 = self:GetWorldPos(data.mapId, data.x + data.w, data.y + data.h)

                if self:EditModePositionRect(frame, wx1, wy1, wx2, wy2) then
                    if frame.NxBaseLevel then
                        frame:SetFrameLevel(frame.NxBaseLevel)
                    end
                end
            end
        end
    end
end

---
-- Check if two rectangles overlap
-- @param r1  Rectangle 1 {x, y, w, h}
-- @param r2  Rectangle 2 {x, y, w, h}
-- @return    true if overlapping, false otherwise
--
function Nx.Map:EditModeRectsOverlap(r1, r2)
    -- Points don't overlap with anything (they're just markers)
    if r1.isPoint or r2.isPoint then
        return false
    end

    -- Check if r1 and r2 overlap (excluding touching edges)
    local r1x2 = r1.x + r1.w
    local r1y2 = r1.y + r1.h
    local r2x2 = r2.x + r2.w
    local r2y2 = r2.y + r2.h

    -- No overlap if one is completely to the side of the other
    if r1x2 <= r2.x or r2x2 <= r1.x then return false end
    if r1y2 <= r2.y or r2y2 <= r1.y then return false end

    return true
end

---
-- Adjust a new rectangle to eliminate overlap with existing rectangles
-- Creates flush edges for clean blob coverage
-- @param newRect  The new rectangle to adjust {x, y, w, h}
-- @return         Adjusted rectangle (may be split into multiple), or nil if completely inside existing
--
function Nx.Map:EditModeAdjustForOverlap(newRect)
    local adjusted = {x = newRect.x, y = newRect.y, w = newRect.w, h = newRect.h, mapId = newRect.mapId}
    local wasAdjusted = false

    for _, existing in ipairs(self.EditRectangles) do
        if self:EditModeRectsOverlap(adjusted, existing) then
            -- Calculate overlap region
            local overlapX1 = max(adjusted.x, existing.x)
            local overlapY1 = max(adjusted.y, existing.y)
            local overlapX2 = min(adjusted.x + adjusted.w, existing.x + existing.w)
            local overlapY2 = min(adjusted.y + adjusted.h, existing.y + existing.h)

            local overlapW = overlapX2 - overlapX1
            local overlapH = overlapY2 - overlapY1

            -- Determine which edge to adjust (pick the one that removes least area)
            -- Calculate how much we'd lose by trimming each edge
            local trimLeft = overlapX2 - adjusted.x  -- trim from left edge
            local trimRight = (adjusted.x + adjusted.w) - overlapX1  -- trim from right
            local trimTop = overlapY2 - adjusted.y  -- trim from top
            local trimBottom = (adjusted.y + adjusted.h) - overlapY1  -- trim from bottom

            -- Calculate area lost for each trim option
            local areaLeft = trimLeft * adjusted.h
            local areaRight = trimRight * adjusted.h
            local areaTop = trimTop * adjusted.w
            local areaBottom = trimBottom * adjusted.w

            -- Find minimum loss that still leaves a valid rectangle
            local minLoss = math.huge
            local bestTrim = nil

            -- Only consider trims that leave a rectangle with positive dimensions
            if adjusted.w - trimLeft > 0.5 and areaLeft < minLoss then
                minLoss = areaLeft
                bestTrim = "left"
            end
            if adjusted.w - trimRight > 0.5 and areaRight < minLoss then
                minLoss = areaRight
                bestTrim = "right"
            end
            if adjusted.h - trimTop > 0.5 and areaTop < minLoss then
                minLoss = areaTop
                bestTrim = "top"
            end
            if adjusted.h - trimBottom > 0.5 and areaBottom < minLoss then
                minLoss = areaBottom
                bestTrim = "bottom"
            end

            -- Apply the trim
            if bestTrim == "left" then
                adjusted.w = adjusted.w - trimLeft
                adjusted.x = overlapX2
                wasAdjusted = true
            elseif bestTrim == "right" then
                adjusted.w = overlapX1 - adjusted.x
                wasAdjusted = true
            elseif bestTrim == "top" then
                adjusted.h = adjusted.h - trimTop
                adjusted.y = overlapY2
                wasAdjusted = true
            elseif bestTrim == "bottom" then
                adjusted.h = overlapY1 - adjusted.y
                wasAdjusted = true
            else
                -- No valid trim found - rectangle is too small or completely inside existing
                return nil, true
            end

            -- Check if adjusted rectangle is still valid
            if adjusted.w < 0.5 or adjusted.h < 0.5 then
                return nil, true
            end
        end
    end

    return adjusted, wasAdjusted
end

---
-- Handle mouse up in edit mode
-- Finalizes the rectangle and adds it to the list
-- @param button  Mouse button released
-- @return        true if event was consumed, false otherwise
--
function Nx.Map:EditModeMouseUp(button)
    if not self.EditMode or not self.EditDrawing then return false end

    if button == "LeftButton" then
        self.EditDrawing = false

        -- Get final cursor position - convert frame pos to world, then to zone coords
        local f = self.Frm
        local cx, cy = GetCursorPosition()
        cx = cx / f:GetEffectiveScale()
        cy = cy / f:GetEffectiveScale()

        local frmX = cx - f:GetLeft()
        local frmY = f:GetTop() - cy
        local wx, wy = self:FramePosToWorldPos(frmX, frmY)
        local endX, endY = self:GetZonePos(self.EditMapId, wx, wy)

        -- Clamp to valid range
        endX = max(0, min(100, endX))
        endY = max(0, min(100, endY))

        -- Calculate size of drawn area
        local w = abs(endX - self.EditStartX)
        local h = abs(endY - self.EditStartY)

        -- Hide preview
        if self.EditPreviewFrame then
            self.EditPreviewFrame:Hide()
        end

        -- Determine if this is a POINT (small drag) or RECTANGLE (larger drag)
        local isPoint = (w < 1.5 and h < 1.5)

        if isPoint then
            -- Create a POINT at the click location
            local pointX = (self.EditStartX + endX) / 2  -- Center of tiny drag
            local pointY = (self.EditStartY + endY) / 2

            local pointData = {
                x = pointX,
                y = pointY,
                isPoint = true,
                mapId = self.EditMapId
            }

            local index = #self.EditRectangles + 1
            self.EditRectangles[index] = pointData

            -- Create point frame
            local pointFrame = self:EditModeCreatePointFrame(pointData, index)
            self.EditRectFrames[index] = pointFrame

            -- Position the frame
            local pwx, pwy = self:GetWorldPos(pointData.mapId, pointX, pointY)
            self:EditModePositionPoint(pointFrame, pwx, pwy)

            self:EditModeUpdateCount()
            Nx.prt("|cff80ffff Point %d added|r at (%.1f, %.1f)", index, pointX, pointY)
        else
            -- Create a RECTANGLE
            local x = min(self.EditStartX, endX)
            local y = min(self.EditStartY, endY)

            -- Check for minimum size for rectangles
            if w < 0.5 or h < 0.5 then
                Nx.prt("|cffff0000Rectangle too small - cancelled|r")
                return true
            end

            -- Create initial rectangle data
            local rectData = {
                x = x,
                y = y,
                w = w,
                h = h,
                isPoint = false,
                mapId = self.EditMapId
            }

            -- Adjust for overlaps with existing rectangles
            local adjustedRect, wasAdjusted = self:EditModeAdjustForOverlap(rectData)

            if not adjustedRect then
                Nx.prt("|cffff8000Rectangle overlaps existing - skipped|r")
                return true
            end

            -- Use the adjusted rectangle
            rectData = adjustedRect
            rectData.isPoint = false
            x, y, w, h = rectData.x, rectData.y, rectData.w, rectData.h

            local index = #self.EditRectangles + 1
            self.EditRectangles[index] = rectData

            -- Create persistent frame for this rectangle
            local rectFrame = self:EditModeCreateRectFrame(rectData, index)
            self.EditRectFrames[index] = rectFrame

            -- Position the frame using our custom function
            local wx1, wy1 = self:GetWorldPos(rectData.mapId, x, y)
            local wx2, wy2 = self:GetWorldPos(rectData.mapId, x + w, y + h)
            self:EditModePositionRect(rectFrame, wx1, wy1, wx2, wy2)

            self:EditModeUpdateCount()
            if wasAdjusted then
                Nx.prt("|cff80ff80Rectangle %d added (adjusted)|r (%.1f, %.1f) size %.1fx%.1f", index, x, y, w, h)
            else
                Nx.prt("|cff80ff80Rectangle %d added|r (%.1f, %.1f) size %.1fx%.1f", index, x, y, w, h)
            end
        end

        return true
    end
    return false
end

---
-- Finish editing - output all rectangles and clear
--
function Nx.Map:EditModeFinish()
    local count = #self.EditRectangles

    if count == 0 then
        Nx.prt("|cffff0000No items to output|r")
        return
    end

    -- Count points and rectangles
    local points = 0
    local rects = 0
    for _, data in ipairs(self.EditRectangles) do
        if data.isPoint then
            points = points + 1
        else
            rects = rects + 1
        end
    end

    -- Get mapId from first item (assuming all are same zone)
    local mapId = self.EditRectangles[1].mapId

    local summary = ""
    if rects > 0 and points > 0 then
        summary = format("%d rectangles, %d points", rects, points)
    elseif rects > 0 then
        summary = format("%d rectangles", rects)
    else
        summary = format("%d points", points)
    end

    Nx.prt("|cff00ff00=== Quest Objective Output (%s) ===|r", summary)
    Nx.prt("|cffffffffMap ID: |cffffd700%d|r", mapId)
    Nx.prt("")
    Nx.prt("|cff80ff80Quest database format (copy these lines):|r")

    for i, data in ipairs(self.EditRectangles) do
        local str
        if data.isPoint then
            -- Format for points: "|mapId|32|x|y|5.01|3.34" (type 32, default size)
            str = format("\"|%d|32|%.0f|%.0f|5.01|3.34\"",
                data.mapId, data.x, data.y)
        else
            -- Format for rectangles: "|mapId|35|x|y|w|h" (type 35 for rectangles)
            str = format("\"|%d|35|%.0f|%.0f|%.2f|%.2f\"",
                data.mapId, data.x, data.y, data.w, data.h)
        end
        Nx.prt("|cffffffff  %s|r", str)
    end

    Nx.prt("")
    Nx.prt("|cff808080Raw coordinates:|r")
    for i, data in ipairs(self.EditRectangles) do
        if data.isPoint then
            Nx.prt("|cff80ffff  [%d] POINT MapId=%d X=%.2f Y=%.2f|r",
                i, data.mapId, data.x, data.y)
        else
            Nx.prt("|cff808080  [%d] RECT  MapId=%d X=%.2f Y=%.2f W=%.2f H=%.2f|r",
                i, data.mapId, data.x, data.y, data.w, data.h)
        end
    end

    -- Generate hex-encoded string for rectangles (sorted by X)
    if rects > 0 then
        -- Collect rectangles only
        local rectList = {}
        for _, data in ipairs(self.EditRectangles) do
            if not data.isPoint then
                table.insert(rectList, data)
            end
        end

        -- Sort by top-left X coordinate
        table.sort(rectList, function(a, b) return a.x < b.x end)

        -- Helper function to convert to padded hex
        local function toHex3(val)
            local hex = format("%X", floor(val + 0.5))
            while #hex < 3 do
                hex = "0" .. hex
            end
            return strlower(hex)
        end

        -- Generate hex strings
        local hexParts = {}
        for _, rect in ipairs(rectList) do
            local zw = rect.w / 100 * 1002
            local zh = rect.h / 100 * 668
            local wx = rect.x * 4095 / 100
            local wy = rect.y * 4095 / 100
            local ww = zw * 4095 / 1002
            local wh = zh * 4095 / 668

            local hexx = toHex3(wx)
            local hexy = toHex3(wy)
            local hexw = toHex3(ww)
            local hexh = toHex3(wh)

            table.insert(hexParts, hexx .. hexy .. hexw .. hexh)
        end

        local hexString = table.concat(hexParts)
        Nx.prt("")
        Nx.prt("|cffffaa00Hex-encoded rectangles (sorted by X):|r")
        Nx.prt("|cffffffff  %s|r", hexString)
    end

    -- Clear all items
    self:EditModeClearRectangles()
    Nx.prt("|cff00ff00Output complete - cleared|r")
end

-------------------------------------------------------------------------------
-- DEBUG/TEST CODE
-- Development and debugging utilities
-------------------------------------------------------------------------------

---
-- Dump battlefield vehicle positions (debug)
-- Prints vehicle offsets relative to player position
--
function Nx.Map:VehicleDumpPos()

    -- Right Reaver guard .431 -.701  -359

    for n = 1, GetNumBattlefieldVehicles() do

        local x, y, unitName, possessed, typ, dir, player = GetBattlefieldVehicleInfo (n, Nx.Map:GetCurrentMapId())
        if x and not player then

            local xo = self.PlyrRZX - x * 100
            local yo = (self.PlyrRZY - y * 100) / 1.5
            dir = dir / PI * -180
            xo, yo = xo * cos (dir) + yo * sin (dir), (xo * -sin (dir) + yo * cos (dir)) * 1.5

            Nx.prt ("#%s %s %f %f %.3f %s", n, unitName or "nil", xo, yo, dir or -1, typ or "no type")
        end
    end
end

---
-- Restore/hide the world map overlay frame
-- Clears textures and hides encounter journal buttons
--
function Nx.Map.RestoreWorldMap()
    if not Nx.Map.WMDF then
        return
    end

    --[[local layers = C_Map.GetMapArtLayers(Nx.Map.RMapId)
    local layerInfo = layers[1]
    local rows, cols = math.ceil(layerInfo.layerHeight / layerInfo.tileHeight), math.ceil(layerInfo.layerWidth / layerInfo.tileWidth)

    for i=1, cols do
      for j=1, rows do
        local index = (j - 1) * cols + i
        Nx.Map.WMDT[index]:SetTexture(nil)
      end
    end]]--

    foreach(Nx.Map.WMDT, function (k, v)
        Nx.Map.WMDT[k]:SetTexture(nil)
    end)

    Nx.Map.WMDF:Hide()
    local index = 1
    local bossButton = _G["NXEJMapButton"..index]
    while bossButton do
        bossButton:Hide()
        index = index + 1
        bossButton = _G["NXEJMapButton"..index]
    end
    --Nx.Map.NInstMapId = nil
end

---
-- Setup and show world map overlay on Carbonite map
-- Creates texture tiles and positions them to display zone map
-- Also handles player position frame setup
--
function Nx.Map.MoveWorldMap()
    local curId = Nx.Map:GetCurrentMapId()
    if not Nx.Map.NInstMapId or Nx.Map.NInstMapId ~= curId then
        Nx.Map.NInstMapId = curId
    end
    Nx.Map:SetCurrentMap (Nx.Map.NInstMapId)

    local mapInfo = C_Map.GetMapInfo(curId)
    if not mapInfo.name then
        return
    end
    local layers = C_Map.GetMapArtLayers(curId)
    local layerInfo = layers[1]
    local rows, cols = math.ceil(layerInfo.layerHeight / layerInfo.tileHeight), math.ceil(layerInfo.layerWidth / layerInfo.tileWidth)

    if not Nx.Map.WMDF then
        Nx.Map.WMDF = CreateFrame("Frame", "WMDF")
        Nx.Map.WMDF:SetFrameStrata("BACKGROUND")
        Nx.Map.WMDT = {}
        Nx.Map.EJMB = {}
        for i = 1,cols do
            for j = 1, rows do
                local index = (j - 1) * cols + i
                Nx.Map.WMDT[index] = Nx.Map.WMDF:CreateTexture("WMDT" .. index)
            end
        end
        Nx.Map.WMDT[1]:SetPoint("TOPLEFT")
        Nx.Map.WMDT[2]:SetPoint("TOPLEFT","WMDT1","TOPRIGHT")
        Nx.Map.WMDT[3]:SetPoint("TOPLEFT","WMDT2","TOPRIGHT")
        Nx.Map.WMDT[4]:SetPoint("TOPLEFT","WMDT3","TOPRIGHT")
        Nx.Map.WMDT[5]:SetPoint("TOPLEFT","WMDT1","BOTTOMLEFT")
        Nx.Map.WMDT[6]:SetPoint("TOPLEFT","WMDT5","TOPRIGHT")
        Nx.Map.WMDT[7]:SetPoint("TOPLEFT","WMDT6","TOPRIGHT")
        Nx.Map.WMDT[8]:SetPoint("TOPLEFT","WMDT7","TOPRIGHT")
        Nx.Map.WMDT[9]:SetPoint("TOPLEFT","WMDT5","BOTTOMLEFT")
        Nx.Map.WMDT[10]:SetPoint("TOPLEFT","WMDT9","TOPRIGHT")
        Nx.Map.WMDT[11]:SetPoint("TOPLEFT","WMDT10","TOPRIGHT")
        Nx.Map.WMDT[12]:SetPoint("TOPLEFT","WMDT11","TOPRIGHT")
    end
    Nx.Map.WMDF:SetParent(Nx.Map:GetMap(1).Frm)
    Nx.Map.WMDF:SetFrameLevel(20)
    Nx.Map.WMDF:SetWidth(Nx.Map:GetMap(1).MapW)
    Nx.Map.WMDF:SetHeight(Nx.Map:GetMap(1).MapH)
    Nx.Map.WMDF:Show()

    local textures = C_Map.GetMapArtLayerTextures(curId,1)

    for i=1, 12 do
        Nx.Map.WMDT[i]:SetWidth(Nx.Map.WMDF:GetWidth() / 3.9)
        Nx.Map.WMDT[i]:SetHeight(Nx.Map.WMDF:GetHeight() / 2.6)
        Nx.Map.WMDT[i]:SetTexture(textures[i])
    end
    Nx.Map.WMDF:SetAllPoints()
    NXWorldMapUnitPositionFrame:SetParent(Nx.Map.WMDF)
    NXWorldMapUnitPositionFrame:SetAllPoints()
    NXWorldMapUnitPositionFrame:SetFrameLevel(40)
    Nx.Map:NXWorldMapUnitPositionFrame_UpdatePlayerPins()

--[[    local numEncounters = 0;
    if Nx.db.char.Map.ShowRaidBoss then
        local width = Nx.Map.WMDF:GetWidth();
        local height = Nx.Map.WMDF:GetHeight();

        local mapEncounters = C_EncounterJournal.GetCurrentMapEncounters(WorldMapFrame.fromJournal);
        if ( mapEncounters ) then
            numEncounters = #mapEncounters;
            for index, mapEncounterInfo in ipairs(mapEncounters) do
                local bossButton = _G["NXEJMapButton"..index]
                if not bossButton then -- create button
                    bossButton = CreateFrame("Button", "NXEJMapButton"..index, Nx.Map.WMDF, "EncounterMapButtonTemplate");
                end

                local name, description, encounterID, rootSectionID, link, instanceID = EJ_GetEncounterInfo(mapEncounterInfo.encounterID);
                bossButton.instanceID = instanceID;
                bossButton.encounterID = encounterID;
                bossButton.tooltipTitle = name;
                bossButton.tooltipText = description;
                bossButton:SetPoint("CENTER", Nx.Map.WMDF, "BOTTOMLEFT", mapEncounterInfo.mapX*width, mapEncounterInfo.mapY*height);
                bossButton:SetFrameStrata("HIGH");
                local _, _, _, displayInfo = EJ_GetCreatureInfo(1, encounterID);
                bossButton.displayInfo = displayInfo;
                bossButton:SetWidth(Nx.db.profile.Map.InstanceBossSize);
                bossButton:SetHeight(Nx.db.profile.Map.InstanceBossSize);
                if ( displayInfo ) then
                    SetPortraitTexture(bossButton.bgImage, displayInfo);
                    bossButton.bgImage:SetWidth(Nx.db.profile.Map.InstanceBossSize / 1.3);
                    bossButton.bgImage:SetHeight(Nx.db.profile.Map.InstanceBossSize / 1.3);
                else
                    bossButton.bgImage:SetTexture("DoesNotExist");
                end
                bossButton:Show();
            end
        end
    end

    WorldMapFrame.hasBosses = numEncounters > 0;
    index = numEncounters + 1;
    local bossButton = _G["NXEJMapButton"..index];
    while bossButton do
        bossButton:Hide();
        index = index + 1;
        bossButton = _G["NXEJMapButton"..index];
    end    ]]--
end

-------------------------------------------------------------------------------
-- PLAYER POSITION FRAME UPDATES
-- Functions for updating player/group member positions on the map
-------------------------------------------------------------------------------

---
-- Update all player positions on the world map unit frame
-- Based on Blizzard's internal implementation
--
function Nx.Map:UpdatePlayerPositions()
    local timeNow = GetTime()

    NXWorldMapUnitPositionFrame:ClearUnits()

    -- Add player arrow
    local r, g, b = CheckColorOverrideForPVPInactive("player", timeNow, 1, 1, 1)
    NXWorldMapUnitPositionFrame:AddUnit("player", "Interface\\WorldMap\\WorldMapArrow",
        Nx.db.profile.Map.InstancePlayerSize, Nx.db.profile.Map.InstancePlayerSize, r, g, b, 1, 7, true)

    -- Determine group type and size
    local isInRaid = IsInRaid()
    local memberCount = 0
    local unitBase

    if isInRaid then
        memberCount = MAX_RAID_MEMBERS
        unitBase = "raid"
    elseif IsInGroup() then
        memberCount = MAX_PARTY_MEMBERS
        unitBase = "party"
    end

    -- Add group members (only if on the same map)
    for i = 1, memberCount do
        local unit = unitBase .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            -- Only show units that are on the same map as the player
            local unitMapId = C_Map.GetBestMapForUnit(unit)
            if unitMapId and unitMapId == Nx.Map.RMapId then
                local atlas = UnitInSubgroup(unit) and "WhiteCircle-RaidBlips" or "WhiteDotCircle-RaidBlips"
                local class = select(2, UnitClass(unit))
                local r, g, b = CheckColorOverrideForPVPInactive(unit, timeNow, GetClassColor(class))
                NXWorldMapUnitPositionFrame:AddUnit(unit, atlas,
                    Nx.db.profile.Map.InstanceGroupSize, Nx.db.profile.Map.InstanceGroupSize, r, g, b, 1)
            end
        end
    end

    NXWorldMapUnitPositionFrame:FinalizeUnits()
end

---
-- Update player pins, choosing full or periodic update as needed
--
function Nx.Map.NXWorldMapUnitPositionFrame_UpdatePlayerPins()
    if NXWorldMapUnitPositionFrame:NeedsFullUpdate() then
        Nx.Map.NXWorldMapUnitPositionFrame_UpdateFull(GetTime())
    elseif NXWorldMapUnitPositionFrame:NeedsPeriodicUpdate() then
        Nx.Map.NXWorldMapUnitPositionFrame_UpdatePeriodic(GetTime())
    end
end

---
-- Perform a full update of all unit positions
-- @param timeNow  Current timestamp
--
function Nx.Map.NXWorldMapUnitPositionFrame_UpdateFull(timeNow)
    assert(NXWorldMapUnitPositionFrame:NeedsFullUpdate())
    NXWorldMapUnitPositionFrame:ClearUnits()

    -- Add player arrow
    local r, g, b = CheckColorOverrideForPVPInactive("player", timeNow, 1, 1, 1)
    NXWorldMapUnitPositionFrame:AddUnit("player", "Interface\\WorldMap\\WorldMapArrow",
        Nx.db.profile.Map.InstancePlayerSize, Nx.db.profile.Map.InstancePlayerSize, r, g, b, 1, 7, true)

    -- Determine group type and size
    local isInRaid = IsInRaid()
    local memberCount = 0
    local unitBase

    if isInRaid then
        memberCount = MAX_RAID_MEMBERS
        unitBase = "raid"
    elseif IsInGroup() then
        memberCount = MAX_PARTY_MEMBERS
        unitBase = "party"
    end

    -- Add group members (only if on the same map)
    for i = 1, memberCount do
        local unit = unitBase .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            -- Only show units that are on the same map as the player
            local unitMapId = C_Map.GetBestMapForUnit(unit)
            if unitMapId and unitMapId == Nx.Map.RMapId then
                local atlas = UnitInSubgroup(unit) and "WhiteCircle-RaidBlips" or "WhiteDotCircle-RaidBlips"
                local class = select(2, UnitClass(unit))
                local r, g, b = CheckColorOverrideForPVPInactive(unit, timeNow, GetClassColor(class))
                NXWorldMapUnitPositionFrame:AddUnit(unit, atlas,
                    Nx.db.profile.Map.InstanceGroupSize, Nx.db.profile.Map.InstanceGroupSize, r, g, b, 1)
            end
        end
    end

    NXWorldMapUnitPositionFrame:FinalizeUnits()
    NXWorldMapUnitPositionFrame.needsFullUpdate = false
end

---
-- Perform a periodic color update for all units
-- @param timeNow  Current timestamp
--
function Nx.Map.NXWorldMapUnitPositionFrame_UpdatePeriodic(timeNow)
    -- Update player color
    local r, g, b = CheckColorOverrideForPVPInactive("player", timeNow, 1, 1, 1)
    NXWorldMapUnitPositionFrame:SetUnitColor("player", r, g, b, 1)

    -- Determine group type and size
    local isInRaid = IsInRaid()
    local memberCount = 0
    local unitBase

    if isInRaid then
        memberCount = MAX_RAID_MEMBERS
        unitBase = "raid"
    elseif IsInGroup() then
        memberCount = MAX_PARTY_MEMBERS
        unitBase = "party"
    end

    -- Update group member colors
    for i = 1, memberCount do
        local unit = unitBase .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local atlas = UnitInSubgroup(unit) and "WhiteCircle-RaidBlips" or "WhiteDotCircle-RaidBlips"
            local class = select(2, UnitClass(unit))
            local r, g, b = CheckColorOverrideForPVPInactive(unit, timeNow, GetClassColor(class))
            NXWorldMapUnitPositionFrame:SetUnitColor(unit, r, g, b, 1)
        end
    end
end

-------------------------------------------------------------------------------
-- MAP ID AND POSITION UTILITIES
-------------------------------------------------------------------------------

---
-- Get map name by ID
-- @param mapId  Map ID (uses current if nil)
-- @return       Map name string or nil
--
function Nx.Map:GetMapNameByID(mapId)
    if not mapId then
        mapId = Nx.Map:GetCurrentMapAreaID()
    end
    local mapInfo = Nx.Map:GetMapInfo(mapId)
    return mapInfo and mapInfo.name or nil
end

---
-- Get current dungeon level (stub - returns 0)
-- @return  Always 0 (dungeon levels not tracked)
--
function Nx.Map:GetCurrentMapDungeonLevel()
    return 0
end

---
-- Get continent map ID for player's current location
-- @return  Continent ID or 0
--
function Nx.Map:GetCurrentMapContinent()
    return select(1, C_Map.GetWorldPosFromMapPos(C_Map.GetBestMapForUnit("player") or 0, {x = 0, y = 0})) or 0
end

---
-- Hide the new player frame overlay
--
function Nx.Map:HideNewPlrFrame()
    if NewPlrFrm then
        NewPlrFrm:Hide()
    end
end

---
-- Get group member at cursor position in instance/BG maps
-- Checks if mouse cursor is near any group member's position
-- @param cursorZoneX  Cursor X position in zone coordinates (0-100)
-- @param cursorZoneY  Cursor Y position in zone coordinates (0-100)
-- @param hitRadius    Detection radius in zone coordinate units (default 3)
-- @return             Name of group member at cursor, unit ID, or nil
--
function Nx.Map:GetGroupMemberAtCursor(cursorZoneX, cursorZoneY, hitRadius)
    hitRadius = hitRadius or 3  -- Default radius for hit detection

    local members = MAX_PARTY_MEMBERS
    local unitBase = "party"

    if IsInRaid() then
        members = MAX_RAID_MEMBERS
        unitBase = "raid"
    elseif not IsInGroup() then
        return nil, nil
    end

    local closestName = nil
    local closestUnit = nil
    local closestDist = hitRadius * hitRadius  -- Use squared distance for efficiency

    for i = 1, members do
        local unit = unitBase .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local pX, pY = Nx.Map.GetPlayerMapPosition(unit)
            if pX > 0 or pY > 0 then
                -- Convert to zone coordinates (0-100)
                local unitZoneX = pX * 100
                local unitZoneY = pY * 100

                -- Calculate squared distance
                local dx = cursorZoneX - unitZoneX
                local dy = cursorZoneY - unitZoneY
                local distSq = dx * dx + dy * dy

                if distSq < closestDist then
                    closestDist = distSq
                    closestUnit = unit
                    local name, realm = UnitName(unit)
                    if realm and #realm > 0 then
                        closestName = name .. "-" .. realm
                    else
                        closestName = name
                    end
                end
            end
        end
    end

    return closestName, closestUnit
end

---
-- Get unit position on map
-- @param unit  Unit ID ("player", "party1", etc.)
-- @return      x, y coordinates (0-1 range) or 0,0 if unavailable
--
function Nx.Map.GetPlayerMapPosition(unit)
    local mID = C_Map.GetBestMapForUnit(unit)
    local x, y

    if mID then
        -- Only return position if unit is on the same map as player
        if unit ~= "player" and mID ~= Nx.Map.RMapId then
            return 0, 0
        end

        if C_Map.GetPlayerMapPosition(mID, unit) then
            x, y = C_Map.GetPlayerMapPosition(mID, unit):GetXY()
        else
            return 0, 0
        end
    end

    if x == nil or y == nil then
        return 0, 0
    end

    return x, y
end

-------------------------------------------------------------------------------
-- CONTINENT MAP ID LOOKUP
-- Cached lookup to find continent for any map ID
-------------------------------------------------------------------------------

-- Cache for zone to continent mapping
local zoneMapIDtoContinentMapID = {}

---
-- Get continent map ID for a given UI map ID
-- Uses caching to speed up repeated lookups
-- @param uiMapID  The map ID to find continent for
-- @return         Continent map ID or nil
--
function Nx.Map:GetContinentMapID(uiMapID)
    -- Check cache first
    local continentMapID = zoneMapIDtoContinentMapID[uiMapID]
    if continentMapID then
        return continentMapID
    end

    -- Not cached - traverse hierarchy to find continent
    local mapInfo = C_Map.GetMapInfo(uiMapID)

    -- Invalid or cosmic/world map
    if not mapInfo or mapInfo.mapType == 0 or mapInfo.mapType == 1 then
        zoneMapIDtoContinentMapID[uiMapID] = nil
        return nil
    end

    -- Already a continent map
    if mapInfo.mapType == 2 then
        zoneMapIDtoContinentMapID[uiMapID] = mapInfo.mapID
        return mapInfo.mapID
    end

    -- Check parent
    local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    if not parentMapInfo then
        zoneMapIDtoContinentMapID[uiMapID] = nil
        return nil
    else
        if parentMapInfo.mapType == 2 then
            -- Parent is continent
            zoneMapIDtoContinentMapID[uiMapID] = parentMapInfo.mapID
            return parentMapInfo.mapID
        else
            -- Recurse up the hierarchy
            return Nx.Map:GetContinentMapID(parentMapInfo.mapID)
        end
    end
end

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------
