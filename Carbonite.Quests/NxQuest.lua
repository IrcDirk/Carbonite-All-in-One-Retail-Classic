-------------------------------------------------------------------------------
-- NxQuest - Quest Module
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
-- QUEST MODULE INITIALIZATION
-------------------------------------------------------------------------------

local _G = getfenv(0)

-------------------------------------------------------------------------------
-- LOCAL FUNCTION REFERENCES (Performance optimization)
-- Caching global functions as locals for faster access in hot paths
-------------------------------------------------------------------------------

-- Bit operations (bit library is always available in WoW)
local bit_band = bit.band
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift

-- Math functions
local floor = math.floor
local max = math.max
local min = math.min
local abs = math.abs

-- String functions
local strfind = strfind or string.find
local strsub = strsub or string.sub
local strlower = strlower or string.lower
local strbyte = strbyte or string.byte
local strmatch = strmatch or string.match
local format = format or string.format
local gsub = gsub or string.gsub

-- Table functions
local tinsert = tinsert or table.insert
local tremove = tremove or table.remove
local sort = sort or table.sort
local wipe = wipe or table.wipe

-- WoW API functions used frequently
local GetTime = GetTime
local UnitLevel = UnitLevel
-- GetNumQuestLogEntries, GetQuestLogTitle, SelectQuestLogEntry, GetQuestLogSelection 
-- are defined after shims section
local GetQuestLogLeaderBoard = GetQuestLogLeaderBoard
local GetNumQuestLeaderBoards = GetNumQuestLeaderBoards
local GetQuestLogQuestText = GetQuestLogQuestText
-- GetQuestTagInfo replaced by GetQuestTagInfoCompat in retail
-- GetQuestLogPushable and GetQuestLogIsAutoComplete are defined after shims section
local GetQuestLogTimeLeft = GetQuestLogTimeLeft
local GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo
local GetQuestDifficultyColor = GetQuestDifficultyColor
local GetQuestObjectiveInfo = GetQuestObjectiveInfo
-- IsUnitOnQuest is defined after shims section to use the shimmed version
local UnitName = UnitName
local UnitGUID = UnitGUID
local InCombatLockdown = InCombatLockdown
local GetDailyQuestsCompleted = GetDailyQuestsCompleted
local GetQuestResetTime = GetQuestResetTime
local GetAbandonQuestItems = C_QuestLog.GetAbandonQuestItems or GetAbandonQuestItems

-------------------------------------------------------------------------------
-- API COMPATIBILITY SHIMS
-- Create wrapper functions for Retail API compatibility
-- Classic uses GetQuestLogTitle directly, Retail uses C_QuestLog.GetInfo
-------------------------------------------------------------------------------

-- Check if we need to create shims (Retail doesn't have GetQuestLogTitle natively)
if C_QuestLog and C_QuestLog.GetInfo then
    -- Retail: Create shim that wraps C_QuestLog.GetInfo with GetQuestLogTitle signature.
    --
    -- Important: C_QuestLog.GetInfo's `.questID` can be a story/display ID
    -- for replayable content (Chromie Time, Threads of Fate, scaling
    -- campaigns) while C_QuestLog.GetQuestIDForLogIndex returns the
    -- actual playable instance ID. The instance ID is the one that
    -- works with C_SuperTrack, C_QuestLog.IsOnQuest, and the rest of
    -- the live quest API, so we prefer it. q.questID stays as the
    -- displayQuestID slot for any caller that wants the story ID.
    function GetQuestLogTitle(qn)
        local q = C_QuestLog.GetInfo(qn)
        if not q then
            return
        end
        local liveID = q.questID
        if C_QuestLog.GetQuestIDForLogIndex then
            local id = C_QuestLog.GetQuestIDForLogIndex(qn)
            if id and id > 0 then
                liveID = id
            end
        end
        local isComplete = C_QuestLog.IsComplete(liveID) and 1 or (C_QuestLog.IsFailed(liveID) and -1 or nil)
        return q.title, q.level, q.suggestedGroup, q.isHeader, q.isCollapsed, isComplete, q.frequency, liveID, q.startEvent, q.questID, q.isOnMap, q.hasLocalPOI, q.isTask, q.isBounty, q.isStory, q.isHidden, q.isScaling
    end

    -- Retail: Wrap C_QuestLog.GetNumQuestLogEntries if it exists
    if C_QuestLog.GetNumQuestLogEntries then
        function GetNumQuestLogEntries()
            return C_QuestLog.GetNumQuestLogEntries()
        end
    end

    -- Retail: GetQuestLogSelection returns the selected quest ID
    function GetQuestLogSelection()
        return C_QuestLog.GetSelectedQuest()
    end

    -- Retail: SelectQuestLogEntry - handles both log index and questID
    -- Quest IDs are typically 5+ digits, log indices are typically under 100
    function SelectQuestLogEntry(val)
        if val and val > 0 then
            if val > 1000 then
                -- Likely a questID (from GetQuestLogSelection), use directly
                C_QuestLog.SetSelectedQuest(val)
            else
                -- Likely a log index, convert to questID first
                local questID = C_QuestLog.GetQuestIDForLogIndex(val)
                if questID then
                    C_QuestLog.SetSelectedQuest(questID)
                end
            end
        end
    end

    -- Retail: GetQuestLogPushable - uses currently selected quest
    function GetQuestLogPushable()
        local questID = C_QuestLog.GetSelectedQuest()
        if questID then
            return C_QuestLog.IsPushableQuest(questID)
        end
        return false
    end

    -- Retail: GetQuestLogIsAutoComplete - get from quest info
    function GetQuestLogIsAutoComplete(qIndex)
        local qInfo = C_QuestLog.GetInfo(qIndex)
        if qInfo then
            return qInfo.isAutoComplete
        end
        return false
    end

    -- Retail: GetQuestLogIndexByID - get log index for a quest ID
    function GetQuestLogIndexByID(questID)
        return C_QuestLog.GetLogIndexForQuestID(questID) or 0
    end
end

-- WorldMap_AddQuestTimeToTooltip shim for retail
if not WorldMap_AddQuestTimeToTooltip and GameTooltip_AddQuestTimeToTooltip then
    function WorldMap_AddQuestTimeToTooltip(questID)
        GameTooltip_AddQuestTimeToTooltip(GameTooltip, questID)
    end
end

-- GetQuestTagInfo compatibility wrapper.
-- Retail uses C_QuestLog.GetQuestTagInfo(questID); Classic uses
-- GetQuestTagInfo(questID). Published on Nx.Quest so extracted
-- modules can call it; file-local alias below keeps existing
-- NxQuest sites unchanged.
Nx.Quest = Nx.Quest or {}
function Nx.Quest.GetQuestTagInfoCompat(questID)
    if not questID then return nil end
    if C_QuestLog and C_QuestLog.GetQuestTagInfo then
        return C_QuestLog.GetQuestTagInfo(questID)
    elseif GetQuestTagInfo then
        -- Classic: GetQuestTagInfo returns tagID, tagName directly, not a table
        local tagID, tagName = GetQuestTagInfo(questID)
        if tagID then
            return {
                tagID = tagID,
                tagName = tagName,
                worldQuestType = nil,
                quality = nil,
                tradeskillLineID = nil,
                isElite = nil,
                displayExpiration = nil,
            }
        end
    end
    return nil
end
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

-- IsUnitOnQuest shim for retail (uses C_QuestLog.IsUnitOnQuest)
if C_QuestLog and C_QuestLog.IsUnitOnQuest then
    function IsUnitOnQuest(questIndex, unit)
        -- Retail uses questID, not questIndex, so we need to convert
        -- Also retail parameter order is (unit, questID), not (questIndex, unit)
        local questID = C_QuestLog.GetQuestIDForLogIndex(questIndex)
        if questID then
            return C_QuestLog.IsUnitOnQuest(unit, questID)
        end
        return false
    end
end

-- IsQuestWatched shim for retail (uses C_QuestLog.GetQuestWatchType)
if C_QuestLog and C_QuestLog.GetQuestWatchType and not IsQuestWatched then
    function IsQuestWatched(questIndex)
        -- Retail uses questID, not questIndex
        local questID = C_QuestLog.GetQuestIDForLogIndex(questIndex)
        if questID then
            -- GetQuestWatchType returns nil if not watched, or a watch type if watched
            return C_QuestLog.GetQuestWatchType(questID) ~= nil
        end
        return false
    end
end

-- AddQuestWatch shim for retail
if C_QuestLog and C_QuestLog.AddQuestWatch and not AddQuestWatch then
    function AddQuestWatch(questIndex)
        local questID = C_QuestLog.GetQuestIDForLogIndex(questIndex)
        if questID then
            C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Manual)
        end
    end
end

-- RemoveQuestWatch shim for retail
if C_QuestLog and C_QuestLog.RemoveQuestWatch and not RemoveQuestWatch then
    function RemoveQuestWatch(questIndex)
        local questID = C_QuestLog.GetQuestIDForLogIndex(questIndex)
        if questID then
            C_QuestLog.RemoveQuestWatch(questID)
        end
    end
end

-- Update local references to use the shims
local GetQuestLogTitle = GetQuestLogTitle
local GetNumQuestLogEntries = GetNumQuestLogEntries
local SelectQuestLogEntry = SelectQuestLogEntry
local GetQuestLogSelection = GetQuestLogSelection
local GetQuestLogPushable = GetQuestLogPushable
local GetQuestLogIsAutoComplete = GetQuestLogIsAutoComplete
local GetQuestLogIndexByID = GetQuestLogIndexByID
local IsUnitOnQuest = IsUnitOnQuest

-------------------------------------------------------------------------------
-- COLOR UTILITY FUNCTIONS (Performance optimization)
-- Cache frequently used color format strings
-------------------------------------------------------------------------------

-- Cache for difficulty color strings (avoids repeated format calls).
-- Lives on Nx.Quest so the extracted Watch/Quest window modules can
-- reach it. File-local aliases below keep existing NxQuest sites
-- unchanged.
Nx.Quest = Nx.Quest or {}
Nx.Quest.difficultyColorCache = Nx.Quest.difficultyColorCache or {}
local difficultyColorCache = Nx.Quest.difficultyColorCache

-- Get cached difficulty color string for a level.
-- @param level: Quest level
-- @return: Color escape sequence string like "|cffRRGGBB"
function Nx.Quest.GetCachedDifficultyColorStr(level)
    local cached = difficultyColorCache[level]
    if cached then
        return cached
    end
    local color = GetQuestDifficultyColor(level)
    cached = format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
    difficultyColorCache[level] = cached
    return cached
end
local GetCachedDifficultyColorStr = Nx.Quest.GetCachedDifficultyColorStr

-- Create the AceAddon for the Quest module
CarboniteQuest = LibStub("AceAddon-3.0"):NewAddon("Carbonite.Quest", "AceEvent-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Quest", true)

-------------------------------------------------------------------------------
-- VERSION AND MODULE NAMESPACES
-------------------------------------------------------------------------------

Nx.VERSIONQOPTS = .21                   -- Quest options data version
Nx.VERSIONCAP = .80                     -- Capture data version

-- Quest module namespaces
Nx.Quest = Nx.Quest or {}               -- Main quest module (idempotent: extracted Locals.lua sets up the namespace earlier)
Nx.Quest.List = {}                      -- Quest list window
Nx.Quest.AcceptPool = {}                -- Quest acceptance pool
Nx.Quest.Watch = {}                     -- Quest watch window
Nx.Quest.WQList = {}                    -- World quest list
Nx.Quest.Cols = {}                      -- Color settings
Nx.Quests = {}                          -- Quest database
Nx.qdb = {}                             -- Quest profile database
Nx.Quest.Tick = 0                       -- Update tick counter
Nx.QInit = false                        -- Initialization flag
Nx.Quest.Custom = {}                    -- Custom quest data
Nx.Quest.OldMap = 0                     -- Previous map ID

-------------------------------------------------------------------------------
-- KEYBINDING DEFINITIONS
-------------------------------------------------------------------------------

BINDING_HEADER_CarboniteQuests = "|cffc0c0ff" .. L["Carbonite Quests"] .. "|r"
BINDING_NAME_NxTOGGLEWATCHMINI = L["NxTOGGLEWATCHMINI"]
BINDING_NAME_NxWATCHUSEITEM = L["NxWATCHUSEITEM"]

-------------------------------------------------------------------------------
-- CLASSIC COMPATIBILITY
-- Stub functions for Classic WoW where retail APIs don't exist
-------------------------------------------------------------------------------

local IsClassic = select(4, GetBuildInfo()) < 60000

if IsClassic then
    function GetQuestLogCriteriaSpell()
        return
    end

    function ProcessQuestLogRewardFactions()
        return
    end

    function GetQuestLogPortraitGiver()
        return
    end

    function GetQuestLogRewardSkillPoints()
        return 0
    end

    function GetQuestLogRewardArtifactXP()
        return 0
    end
end

-------------------------------------------------------------------------------
-- QUEST LOG TEMPLATE
-- Template for displaying quest details in the quest log
-------------------------------------------------------------------------------

CQUEST_TEMPLATE_LOG = {
    questLog = true,
    chooseItems = nil,
    contentWidth = 285,
    canHaveSealMaterial = false,
    sealXOffset = 160,
    sealYOffset = -6,
    elements = {
        QuestInfo_ShowTitle, 5, -10,
        QuestInfo_ShowDescriptionText, 0, -5,
        QuestInfo_ShowSeal, 0, 0,
        QuestInfo_ShowObjectives, 0, -10,
        QuestInfo_ShowObjectivesHeader, 0, -15,
        QuestInfo_ShowObjectivesText, 0, -5,
        QuestInfo_ShowSpecialObjectives, 0, -10,
        QuestInfo_ShowGroupSize, 0, -10,
        QuestInfo_ShowRewards, 0, -15,
        QuestInfo_ShowSpacer, 0, -15,
    }
}

CBQUEST_TEMPLATE = CQUEST_TEMPLATE_LOG
CBQUEST_TEMPLATE.canHaveSealMaterial = nil

-------------------------------------------------------------------------------
-- DEFAULT OPTIONS
-- Default profile settings for quest module
-------------------------------------------------------------------------------

Nx.Quest.defaults = {
    profile = {
        -- Quest window options
        Quest = {
            QuestFont = "Friz",                         -- Quest list font
            QuestFontSize = 10,                         -- Font size
            QuestFontSpacing = 1,                       -- Line spacing
            Enable = true,                              -- Enable quest module
            AddTooltip = true,                          -- Add quest info to tooltips
            AutoAccept = false,                         -- Auto-accept quests
            AutoTurnIn = false,                         -- Auto-turn-in quests
            AutoTurnInAC = false,                       -- Auto-turn-in self-completion
            BroadcastQChanges = true,                   -- Broadcast quest progress
            BroadcastQChangesNum = 999,                 -- Broadcast threshold
            DetailBC = ".75|.75|.44|1",                 -- Detail background color
            DetailTC = ".125|.06|.03|1",                -- Detail text color
            DetailScale = .95,                          -- Detail window scale
            HCheckCompleted = false,                    -- Check completed on login
            maxLoadLevel = false,                       -- Load by level threshold
            LevelsToLoad = 10,                          -- Level threshold
            MapQuestGiversHighLevel = Nx.MaxPlayerLevel, -- Max quest giver level
            MapQuestGiversLowLevel = 1,                 -- Min quest giver level
            MapShowWatchAreas = true,                   -- Show watched areas on map
            MapWatchAreaAlpha = "1|1|1|.4",             -- Watch area alpha
            MapWatchAreaGfx = "Solid",                  -- Watch area graphic
            MapWatchAreaTrackColor = ".7|.7|.7|.5",    -- Tracked area color
            MapWatchAreaHoverColor = "1|1|1|.6",       -- Hover area color
            MapWatchColorPerQ = true,                   -- Unique color per quest
            MapWatchColorCnt = 12,                      -- Number of watch colors
            -- Watch area colors (12 distinct colors)
            MapWatchC1 = "1|0|0|1",                    -- Red
            MapWatchC2 = "0|1|0|1",                    -- Green
            MapWatchC3 = ".2|.2|1|1",                  -- Blue
            MapWatchC4 = "1|1|0|1",                    -- Yellow
            MapWatchC5 = "0|1|1|1",                    -- Cyan
            MapWatchC6 = "1|0|1|1",                    -- Magenta
            MapWatchC7 = "1|.5|0|1",                   -- Orange
            MapWatchC8 = "0|1|.5|1",                   -- Spring green
            MapWatchC9 = ".5|.066|1|1",                -- Purple
            MapWatchC10 = ".5|1|0|1",                  -- Lime
            MapWatchC11 = "0|.5|1|1",                  -- Sky blue
            MapWatchC12 = "1|0|.5|1",                  -- Pink
            PartyShare = true,                          -- Share quest progress
            ShowDailyCount = true,                      -- Show daily quest count
            ShowDailyReset = true,                      -- Show daily reset time
            ShowId = false,                             -- Show quest ID
            ShowQuestOffers = true,                     -- Show quest offers on map
            ShowAllMapPOIs = (C_QuestLog and C_QuestLog.GetQuestsOnMap) and true or false, -- Show every in-log quest on the map (Blizzard parity). On any flavor where C_QuestLog.GetQuestsOnMap exists (retail + Wrath/Cata/MoP Classic) the patcher fills in missing data; on Era/TBC this stays off so we don't show stale bundled-DB entries.
            ShowLinkExtra = true,                       -- Show extra link info
            SideBySide = true,                          -- Side by side layout
            UseAltLKey = false,                         -- Use Alt-L keybind
            SndPlayCompleted = true,                    -- Play completion sound
            -- Sound options
            Snd1 = true,                                -- Sound 1 enabled
            Snd2 = false,
            Snd3 = false,
            Snd4 = false,
            Snd5 = false,
            Snd6 = false,
            Snd7 = false,
            Snd8 = false,
            -- Quest database loading by level range
            Load0 = true,                               -- Dailies/special
            Load1 = true,                               -- Levels 1-10
            Load2 = true,                               -- Levels 11-20
            Load3 = true,                               -- Levels 21-30
            Load4 = true,                               -- Levels 31-40
            Load5 = true,                               -- Levels 41-50
            Load6 = true,                               -- Levels 51-60
            Load7 = (Nx.MaxPlayerLevel > 60),           -- Levels 61-70
            Load8 = (Nx.MaxPlayerLevel > 70),           -- Levels 71-80
            Load9 = (Nx.MaxPlayerLevel > 80),           -- Levels 81-85
            Load10 = (Nx.MaxPlayerLevel > 85),          -- Levels 86-90
            Load11 = (Nx.MaxPlayerLevel > 90),          -- Levels 91-100
            Load12 = (Nx.MaxPlayerLevel > 100),         -- Levels 101-110
            ScrollIMG = true,                           -- Use scroll image
        },

        -- Quest watch window options
        QuestWatch = {
            AchTrack = true,                            -- Track achievements
            AchZoneShow = true,                         -- Show zone achievements
            AddNew = true,                              -- Auto-watch new quests
            AddChanged = true,                          -- Auto-watch changed quests
            BGColor = "0|0|0|.4",                       -- Background color
            BlizzModify = true,                         -- Modify Blizzard watch
            BonusBar = false,                           -- Show progress bars (bonus tasks)
            BonusTask = true,                           -- Show bonus tasks
            ChalTrack = true,                           -- Track challenge modes
            FadeAll = false,                            -- Fade entire window
            FixedSize = true,                           -- Fixed window size
            GrowUp = false,                             -- Grow upward
            HideBlizz = true,                           -- Hide Blizzard watch
            HideDoneObj = false,                        -- Hide done objectives
            HideRaid = false,                           -- Hide in raids
            ItemAlpha = "1|1|1|.6",                     -- Item button alpha
            ItemScale = 10,                             -- Item button scale
            KeyUseItem = "",                            -- Use item keybind
            OCntFirst = false,                          -- Count first
            OMaxLen = 60,                               -- Max objective length
            RefreshTimer = 500,                         -- Refresh delay (ms)
            RemoveComplete = false,                     -- Remove completed
            ScenTrack = true,                           -- Track scenarios
            ShowClose = false,                          -- Show close button
            ShowDist = true,                            -- Show distance
            ShowPerColor = false,                       -- Color by progress
            CompleteColor = "1|.82|0|1",                -- Complete quest color
            IncompleteColor = ".75|.6|0|1",             -- Incomplete quest color
            OCompleteColor = "1|1|1|1",                 -- Complete objective color
            OIncompleteColor = ".8|.8|.8|1",            -- Incomplete objective color
            Sync = true,                                -- Sync with Blizzard
            WatchFont = "Arial",                        -- Watch font
            WatchFontSize = 11,                         -- Watch font size
            WatchFontSpacing = 2,                       -- Watch line spacing
        },

        -- World quest list options
        WQList = {
            showgear = true,                            -- Show gear rewards
            showap = true,                              -- Show artifact power
            showorder = true,                           -- Show order resources
            showgold = true,                            -- Show gold rewards
            showother = true,                           -- Show other rewards
            showpvp = true,                             -- Show PVP rewards
            showbounty = false,                         -- Bounty only
            sortmode = 1,                               -- Sort mode
            zoneonly = false,                           -- Current zone only
            -- Faction filters
            showfaronis = true,
            showdreamweaver = true,
            showhighmountain = true,
            showlegionfall = true,
            showargussian = true,
            shownightfallen = true,
            showwardens = true,
            showkirintor = true,
            showarmyoflight = true,
            showvalarjar = true,
            bountycolor = true,                         -- Color bounty quests
        },
    },
}

-------------------------------------------------------------------------------
-- LOCAL VARIABLES
-------------------------------------------------------------------------------

local GlobalAddonName = ...

-- Tooltip for inspecting world quest items
local inspectScantip = CreateFrame("GameTooltip", GlobalAddonName.."WQInspectScanningTooltip", nil, "GameTooltipTemplate")
inspectScantip:SetOwner(UIParent, "ANCHOR_NONE")

-- World quest data. worldquestdb / worldquesttip / ITEM_LEVEL are
-- promoted to Nx.Quest so the extracted WorldQuestWindow.lua can
-- read them. File-local aliases keep existing NxQuest sites
-- unchanged.
local WQTable = {}
Nx.Quest.ITEM_LEVEL = (ITEM_LEVEL or "NO DATA FOR ITEM_LEVEL"):gsub("%%d", "(%%d+%+*)")
local ITEM_LEVEL = Nx.Quest.ITEM_LEVEL

-- Options and world quest state
Nx.Quest.worldquestdb = Nx.Quest.worldquestdb or {}
local worldquestdb = Nx.Quest.worldquestdb
Nx.Quest.emmBfA = Nx.Quest.emmBfA or {}
Nx.Quest.emmLegion = Nx.Quest.emmLegion or {}

-- Tooltip for world quest list
Nx.Quest.worldquesttip = Nx.Quest.worldquesttip
    or CreateFrame("GameTooltip", "WQListTip", nil, "GameTooltipTemplate")
Nx.Quest.worldquesttip:SetOwner(UIParent, "ANCHOR_NONE")
local worldquesttip = Nx.Quest.worldquesttip



-------------------------------------------------------------------------------
-- DEBUG
-------------------------------------------------------------------------------

--function Nx.Quest.SelectQuestLogEntry (qn)
--    Nx.prt ("QSel %s", qn)
--    Nx.Quest.OldSelectQuestLogEntry (qn)
--end

-------------------------------------------------------------------------------
-- QUEST SYSTEM INITIALIZATION
-- Initialize quest and watch data structures and windows
-------------------------------------------------------------------------------

---
-- Initialize the quest system
-- Sets up tracking tables, hooks, and windows
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------