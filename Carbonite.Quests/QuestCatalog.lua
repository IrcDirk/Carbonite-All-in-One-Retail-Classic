-- Carbonite.Quests | QuestCatalog
--
-- Quest catalog foundation with Phase 17 event-driven profiling.
--
-- Blizzard is the authority for mutable runtime quest state. Carbonite's
-- bundled quest database remains versioned fallback knowledge for offline
-- titles, quest chains, NPC/object identities, and curated map coordinates.
-- The two stores are intentionally separate and are never merged in-place.

local ADDON_NAME, Private = ...
if type(Private) ~= "table" then
    Private = {}
end

local _G = _G
local Nx = _G.Nx
if not Nx then
    return
end

Nx.Quest = Nx.Quest or {}

local C_Map = _G.C_Map
local C_QuestInfoSystem = _G.C_QuestInfoSystem
local C_QuestLog = _G.C_QuestLog
local C_TaskQuest = _G.C_TaskQuest
local C_Timer = _G.C_Timer
local Enum = _G.Enum

local CollapseQuestHeader = _G.CollapseQuestHeader
local CreateFrame = _G.CreateFrame
local ExpandQuestHeader = _G.ExpandQuestHeader
local GetBuildInfo = _G.GetBuildInfo
local GetNumQuestLeaderBoards = _G.GetNumQuestLeaderBoards
local GetQuestLink = _G.GetQuestLink
local GetQuestLogLeaderBoard = _G.GetQuestLogLeaderBoard
local GetQuestLogTitle = _G.GetQuestLogTitle
local GetQuestLogIndexByID = _G.GetQuestLogIndexByID
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo
local GetQuestTagInfo = _G.GetQuestTagInfo
local GetQuestUiMapID = _G.GetQuestUiMapID
local GetTime = _G.GetTime
local IsLoggedIn = _G.IsLoggedIn
local WOW_PROJECT_ID = _G.WOW_PROJECT_ID

local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local select = select
local tonumber = tonumber
local tostring = tostring
local type = type
local string_find = string.find
local string_format = string.format
local string_lower = string.lower
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local math_min = math.min

local wipe = _G.wipe
if not wipe then
    wipe = function(target)
        for key in pairs(target) do
            target[key] = nil
        end
        return target
    end
end

local function IsSecretValue(value)
    local checker = _G.issecretvalue
    return checker and checker(value) or false
end

local function AsPositiveNumber(value)
    if IsSecretValue(value) or type(value) ~= "number" then
        return nil
    end
    if value > 0 then
        return value
    end
    return nil
end

local function AsNumber(value, fallback)
    if not IsSecretValue(value) and type(value) == "number" then
        return value
    end
    return fallback
end

local function AsBoolean(value)
    if IsSecretValue(value) or value == nil then
        return false
    end
    return value and true or false
end

local function AsSafeString(value)
    if IsSecretValue(value) or type(value) ~= "string" then
        return nil
    end
    return value
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local ok, a, b, c, d, e, f, g, h, i, j = pcall(func, ...)
    if not ok then
        return nil
    end
    return a, b, c, d, e, f, g, h, i, j
end

local function DetectProjectFlavor()
    if WOW_PROJECT_ID and _G.WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
        return "retail"
    end
    if WOW_PROJECT_ID and _G.WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC then
        return "classic-era"
    end
    if WOW_PROJECT_ID and _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
        and WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return "burning-crusade-classic"
    end
    if WOW_PROJECT_ID and _G.WOW_PROJECT_WRATH_CLASSIC
        and WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC then
        return "wrath-classic"
    end
    if WOW_PROJECT_ID and _G.WOW_PROJECT_CATACLYSM_CLASSIC
        and WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC then
        return "cataclysm-classic"
    end
    if WOW_PROJECT_ID and _G.WOW_PROJECT_MISTS_CLASSIC
        and WOW_PROJECT_ID == _G.WOW_PROJECT_MISTS_CLASSIC then
        return "mists-classic"
    end
    return "unknown"
end

local function GetAddonVersion()
    local getter = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local version = SafeCall(getter, ADDON_NAME, "Version")
    if version and version ~= "" then
        return tostring(version)
    end
    return "development"
end

local clientVersion, clientBuild = GetBuildInfo()
clientBuild = tonumber(clientBuild) or 0

local PROJECT_FLAVOR = DetectProjectFlavor()
local FALLBACK_SCHEMA_VERSION = 1
local CATALOG_SCHEMA_VERSION = 5

-- Refreshes are debounced across short Blizzard event bursts. The maximum
-- window prevents a sustained event stream from starving consumers.
local REFRESH_DELAY_MAP = 0.04
local REFRESH_DELAY_STATE = 0.08
local REFRESH_DELAY_TRANSITION = 0.15
local REFRESH_MAX_DEBOUNCE = 0.30
local MAX_REFRESH_REASON_COUNT = 12

-- Phase 13 change domains. Catalog scans still normalize the complete live
-- snapshot, but consumers advance only when fields relevant to them changed.
local CONSUMER_NAMES = {
    "projection", "watch", "list", "tooltip", "map", "routing",
}

local DELTA_KINDS = {
    "added", "removed", "changed", "progress", "presentation",
    "classification", "map", "visibility", "structure", "index",
}

local function CreateDelta()
    local delta = {
        flags = {},
        reason = "not-initialized",
        kind = "none",
        revision = 0,
        stateRevision = 0,
        mapRevision = 0,
    }
    for index = 1, #DELTA_KINDS do
        local kind = DELTA_KINDS[index]
        delta[kind .. "QuestIDs"] = {}
        delta["_" .. kind .. "Set"] = {}
    end
    return delta
end

local CLASSIFICATION_NAMES = {
    [0] = "important",
    [1] = "legendary",
    [2] = "campaign",
    [3] = "calling",
    [4] = "meta",
    [5] = "recurring",
    [6] = "questline",
    [7] = "normal",
    [8] = "bonus-objective",
    [9] = "threat",
    [10] = "world-quest",
}

local CLASSIFICATION_IDS = {}
for classificationID, classificationName in pairs(CLASSIFICATION_NAMES) do
    CLASSIFICATION_IDS[classificationName] = classificationID
end

-- Prefer the live Enum table when Blizzard exposes it. The numeric fallback
-- above matches the generated QuestInfoShared API documentation, but no
-- consumer needs to depend on those values directly.
local questClassificationEnum = Enum and Enum.QuestClassification
if type(questClassificationEnum) == "table" then
    local enumNames = {
        Important = "important",
        Legendary = "legendary",
        Campaign = "campaign",
        Calling = "calling",
        Meta = "meta",
        Recurring = "recurring",
        Questline = "questline",
        Normal = "normal",
        BonusObjective = "bonus-objective",
        Threat = "threat",
        WorldQuest = "world-quest",
    }
    for enumName, classificationName in pairs(enumNames) do
        local classificationID = questClassificationEnum[enumName]
        if type(classificationID) == "number" and not IsSecretValue(classificationID) then
            CLASSIFICATION_NAMES[classificationID] = classificationName
            CLASSIFICATION_IDS[classificationName] = classificationID
        end
    end
end

local IMPORTANT_LIKE_CLASSIFICATIONS = {
    important = true,
    legendary = true,
    campaign = true,
    calling = true,
    meta = true,
    questline = true,
}

local TAG_CLASSIFICATIONS = {
    [1] = "group",
    [41] = "pvp",
    [62] = "raid",
    [81] = "dungeon",
    [83] = "legendary",
    [85] = "heroic",
    [88] = "raid-10",
    [89] = "raid-25",
    [98] = "scenario",
    [102] = "account",
    [266] = "combat-ally",
    [288] = "delve",
}

local QuestCatalog = {
    schemaVersion = CATALOG_SCHEMA_VERSION,
    projectID = WOW_PROJECT_ID,
    projectFlavor = PROJECT_FLAVOR,
    clientVersion = clientVersion,
    clientBuild = clientBuild,

    -- Canonical, mutable runtime overlay. Only active Blizzard quest-log
    -- entries live here.
    QuestStore = {
        byQuestID = {},
    },

    activeQuestIDs = {},
    activeQuestIDSet = {},

    -- Catalog-owned subset used by Carbonite's active quest list and legacy
    -- CurQ compatibility projection. It contains only visible, non-hidden
    -- quests that have a real Blizzard quest-log row. Current-area task-only
    -- records remain in activeQuestIDs and the classification/map indexes, but
    -- do not leak into the normal quest-log list.
    visibleQuestIDs = {},
    visibleQuestIDsByHeader = {},
    visibleQuestIDSet = {},
    visiblePosition = {},
    visibleHeaderPosition = {},
    byQuestLogIndex = {},
    byTitle = {},

    byMapID = {},
    byCategory = {},
    byHeader = {},
    byClassification = {},
    byCompletion = {
        complete = {},
        incomplete = {},
        failed = {},
    },

    -- Curated Carbonite content. This is a fallback reference, not runtime
    -- state and not a destination for Blizzard API updates.
    fallback = {
        schemaVersion = FALLBACK_SCHEMA_VERSION,
        contentVersion = PROJECT_FLAVOR .. ":" .. GetAddonVersion(),
        projectFlavor = PROJECT_FLAVOR,
        source = "Carbonite bundled quest data",
        byQuestID = Nx.Quests,
        loadedAt = 0,
        questCount = 0,
    },

    revision = 0,
    stateRevision = 0,
    mapRevision = 0,
    structureRevision = 0,
    indexRevision = 0,
    progressRevision = 0,
    presentationRevision = 0,
    classificationRevision = 0,
    consumerRevisions = {
        projection = 0,
        watch = 0,
        list = 0,
        tooltip = 0,
        map = 0,
        routing = 0,
    },
    workingDelta = CreateDelta(),
    lastDelta = CreateDelta(),
    objectiveSignatureScratch = {},
    generation = 0,
    questLogQuestCount = 0,
    hasStateSnapshot = false,
    currentMapID = 0,
    lastRefreshReason = "not-initialized",
    lastRefreshTime = 0,

    callbacks = {},
    bucketPool = {},
    recordPool = {},
    requestedQuestData = {},
    externalEventStamp = {},
    scanSeen = {},
    expandedHeaders = {},
    originallyCollapsedHeaders = {},

    -- Session-scoped compatibility projection for legacy Carbonite consumers
    -- that still expect packed Start/End/Objectives structures. This table is
    -- derived from Blizzard state by copy-on-write and never mutates fallback.
    compatibilityOverlay = {
        byQuestID = {},
        patchFlags = {},
    },

    currentMapRecords = {},
    currentMapRecordsRevision = -1,

    stateDirty = true,
    mapDirty = true,
    refreshScheduled = false,
    refreshTimer = nil,
    refreshToken = 0,
    refreshScheduledFor = 0,
    refreshBurstStartedAt = nil,
    refreshBurstEventCount = 0,
    pendingReasons = {},
    pendingReasonOrder = {},
    fullRefreshPending = false,
    mapRefreshPending = false,
    refreshing = false,
    refreshAgain = false,
    suppressQuestLogEvents = false,

    refreshDiagnostics = {
        scheduled = 0,
        coalesced = 0,
        rescheduled = 0,
        cancelled = 0,
        staleFlushes = 0,
        forcedFlushes = 0,
        fullRebuilds = 0,
        mapRebuilds = 0,
        callbackDispatches = 0,
        callbackErrors = 0,
        selectiveCallbackSkips = 0,
        deltaBuilds = 0,
        noChangeRebuilds = 0,
        addedQuests = 0,
        removedQuests = 0,
        progressChanges = 0,
        legacyObjectiveReads = 0,
        legacyProgressOverrides = 0,
        presentationChanges = 0,
        classificationChanges = 0,
        mapChanges = 0,
        structureChanges = 0,
        indexChanges = 0,
        maxBurstEvents = 0,
        lastBurstEvents = 0,
        lastDelay = 0,
        lastReasons = "",
    },
}

QuestCatalog.byQuestID = QuestCatalog.QuestStore.byQuestID

Private.QuestCatalog = QuestCatalog
Nx.Quest.Catalog = QuestCatalog

local function AcquireBucket(self)
    local pool = self.bucketPool
    local bucket = pool[#pool]
    if bucket then
        pool[#pool] = nil
        return bucket
    end
    return {}
end

local function ReleaseIndex(self, index)
    local pool = self.bucketPool
    for key, bucket in pairs(index) do
        wipe(bucket)
        pool[#pool + 1] = bucket
        index[key] = nil
    end
end

local function AddToIndex(self, index, key, questID)
    if key == nil or key == "" then
        return
    end

    local bucket = index[key]
    if not bucket then
        bucket = AcquireBucket(self)
        index[key] = bucket
    end
    bucket[#bucket + 1] = questID
end

local function AddToMapIndexUnique(self, mapID, questID)
    mapID = AsPositiveNumber(mapID)
    if not mapID then
        return
    end

    local bucket = self.byMapID[mapID]
    if not bucket then
        bucket = AcquireBucket(self)
        self.byMapID[mapID] = bucket
    else
        for index = 1, #bucket do
            if bucket[index] == questID then
                return
            end
        end
    end

    bucket[#bucket + 1] = questID
end

local function AcquireRecord(self)
    local pool = self.recordPool
    local record = pool[#pool]
    if record then
        pool[#pool] = nil
        return record
    end
    return {}
end

local function ReleaseRecord(self, record)
    wipe(record)
    self.recordPool[#self.recordPool + 1] = record
end


local function DeepCopyLegacy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[DeepCopyLegacy(key, seen)] = DeepCopyLegacy(child, seen)
    end
    return copy
end

local function GetFallbackTitle(quest)
    if type(quest) ~= "table" then
        return nil
    end

    local packed = quest.Quest
    if type(packed) ~= "string" or packed == "" then
        return nil
    end

    local separator = string_find(packed, "|", 1, true)
    if separator then
        return packed:sub(1, separator - 1)
    end
    return packed
end

local function GetQuestLogEntryCount()
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        return AsPositiveNumber(SafeCall(C_QuestLog.GetNumQuestLogEntries)) or 0
    end

    local count = SafeCall(_G.GetNumQuestLogEntries)
    if type(count) == "number" and not IsSecretValue(count) and count > 0 then
        return count
    end
    return 0
end

local function GetQuestIDFromLegacyIndex(index, returnedQuestID)
    local questID = AsPositiveNumber(returnedQuestID)
    if questID then
        return questID
    end

    local link = AsSafeString(SafeCall(GetQuestLink, index))
    if link then
        questID = tonumber(link:match("quest:(%d+)"))
        return AsPositiveNumber(questID)
    end
    return nil
end

local function GetQuestTag(questID)
    if C_QuestLog and C_QuestLog.GetQuestTagInfo then
        local tag = SafeCall(C_QuestLog.GetQuestTagInfo, questID)
        if type(tag) == "table" then
            return tag.tagID, tag.tagName, tag
        end
    end

    if GetQuestTagInfo then
        local tagID, tagName = SafeCall(GetQuestTagInfo, questID)
        return tagID, tagName, nil
    end
    return nil, nil, nil
end

local function QuestFlagIsTrue(func, questID)
    if type(func) ~= "function" then
        return false
    end
    return AsBoolean(SafeCall(func, questID))
end

local function GetClassification(questID, info, startEvent, isTask, isBounty,
    isStory, isHidden, tagID, tagName, tagInfo)

    -- Blizzard's explicit classification is authoritative. In particular, an
    -- Important quest can also carry the generic isTask flag; isTask must never
    -- be allowed to overwrite the explicit Important classification.
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local classificationID = SafeCall(
            C_QuestInfoSystem.GetQuestClassification, questID
        )
        if type(classificationID) == "number" and not IsSecretValue(classificationID) then
            return CLASSIFICATION_NAMES[classificationID]
                or ("classification-" .. classificationID),
                classificationID, "C_QuestInfoSystem"
        end
    end

    -- Capability-based fallbacks are deliberately ordered from specific to
    -- generic. A generic task flag is considered only after every API capable
    -- of identifying an important/meta/calling/world quest has been checked.
    if C_QuestLog then
        if QuestFlagIsTrue(C_QuestLog.IsImportantQuest, questID) then
            return "important", CLASSIFICATION_IDS.important,
                "C_QuestLog.IsImportantQuest"
        end
        if QuestFlagIsTrue(C_QuestLog.IsMetaQuest, questID) then
            return "meta", CLASSIFICATION_IDS.meta, "C_QuestLog.IsMetaQuest"
        end
        if QuestFlagIsTrue(C_QuestLog.IsQuestCalling, questID) then
            return "calling", CLASSIFICATION_IDS.calling,
                "C_QuestLog.IsQuestCalling"
        end
        if QuestFlagIsTrue(C_QuestLog.IsWorldQuest, questID) then
            return "world-quest", CLASSIFICATION_IDS["world-quest"],
                "C_QuestLog.IsWorldQuest"
        end
    end

    if tagInfo then
        if AsNumber(tagInfo.worldQuestType, nil) ~= nil then
            return "world-quest", CLASSIFICATION_IDS["world-quest"],
                "quest-tag-world-type"
        end
        if AsBoolean(tagInfo.isElite) then
            return "elite", nil, "quest-tag-elite"
        end
        if AsPositiveNumber(tagInfo.tradeskillLineID) then
            return "profession", nil, "quest-tag-profession"
        end
    end

    tagID = type(tagID) == "number" and not IsSecretValue(tagID) and tagID or nil
    if tagID and TAG_CLASSIFICATIONS[tagID] then
        return TAG_CLASSIFICATIONS[tagID], nil, "quest-tag-id"
    end

    if AsBoolean(isBounty) then
        return "bounty", nil, "quest-log-bounty-flag"
    end
    if AsBoolean(isStory) then
        return "story", nil, "quest-log-story-flag"
    end
    if AsBoolean(isHidden) then
        return "hidden", nil, "quest-log-hidden-flag"
    end
    if (info and AsBoolean(info.startEvent)) or AsBoolean(startEvent) then
        return "event", nil, "quest-log-event-flag"
    end

    -- isTask means the quest participates in Blizzard's task system; it does
    -- not mean BonusObjective. Returning a conservative generic classification
    -- prevents important quests from being presented as bonus objectives when
    -- the explicit classification API is temporarily unavailable.
    if AsBoolean(isTask)
        or (C_QuestLog and QuestFlagIsTrue(C_QuestLog.IsQuestTask, questID)) then
        return "task", nil, "quest-log-task-flag"
    end

    tagName = AsSafeString(tagName)
    if tagName and tagName ~= "" then
        return string_lower(tagName):gsub("%s+", "-"), nil, "quest-tag-name"
    end
    return "normal", CLASSIFICATION_IDS.normal, "default"
end

local function GetQuestMapID(questID)
    if GetQuestUiMapID then
        local mapID = SafeCall(GetQuestUiMapID, questID, false)
        mapID = AsPositiveNumber(mapID)
        if mapID then
            return mapID
        end
    end

    if C_TaskQuest and C_TaskQuest.GetQuestZoneID then
        local mapID = SafeCall(C_TaskQuest.GetQuestZoneID, questID)
        mapID = AsPositiveNumber(mapID)
        if mapID then
            return mapID
        end
    end
    return 0
end

local function GetCurrentMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = AsPositiveNumber(SafeCall(C_Map.GetBestMapForUnit, "player"))
        if mapID then
            return mapID
        end
    end

    if Nx.Map and Nx.Map.GetCurrentMapId then
        local mapID = AsPositiveNumber(SafeCall(Nx.Map.GetCurrentMapId, Nx.Map))
        if mapID then
            return mapID
        end
    end
    return 0
end

local function GetCurrentQuestLogIndex(questID)
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local index = AsPositiveNumber(SafeCall(
            C_QuestLog.GetLogIndexForQuestID, questID
        ))
        if index then
            return index
        end
    end

    if GetQuestLogIndexByID then
        return AsPositiveNumber(SafeCall(GetQuestLogIndexByID, questID)) or 0
    end
    return 0
end

local function GetTaskQuestTitle(questID)
    if not C_TaskQuest or not C_TaskQuest.GetQuestInfoByQuestID then
        return nil
    end

    -- Blizzard documents the first return as a cstring. Do not attempt to
    -- inspect it as a table: on modern restricted encounters the value can
    -- be secret, and even shape-probing it from addon code is unsafe.
    return AsSafeString(SafeCall(C_TaskQuest.GetQuestInfoByQuestID, questID))
end

local function IsActiveTaskQuest(questID, entry)
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local isOnQuest = SafeCall(C_QuestLog.IsOnQuest, questID)
        if isOnQuest ~= nil and not IsSecretValue(isOnQuest) then
            return isOnQuest and true or false
        end
    end

    if type(entry) == "table" then
        if entry.inProgress ~= nil and not IsSecretValue(entry.inProgress) then
            return entry.inProgress and true or false
        end
        if entry.isInArea ~= nil and not IsSecretValue(entry.isInArea) then
            return entry.isInArea and true or false
        end
    end
    return false
end

local function GetTaskCategory(classification)
    if classification == "world-quest" then
        return "World Quests"
    end
    if classification == "bonus-objective" then
        return "Bonus Objectives"
    end
    if classification == "threat" then
        return "Threats"
    end
    return "Tasks"
end

local function ExpandLegacyQuestHeaders(expanded)
    wipe(expanded)
    if C_QuestLog and C_QuestLog.GetInfo then
        return
    end
    if not GetQuestLogTitle or not ExpandQuestHeader or not CollapseQuestHeader then
        return
    end

    local index = 1
    local count = GetQuestLogEntryCount()
    while index <= count do
        local _, _, _, isHeader, isCollapsed = SafeCall(GetQuestLogTitle, index)
        if AsBoolean(isHeader) and AsBoolean(isCollapsed) then
            expanded[#expanded + 1] = index
            SafeCall(ExpandQuestHeader, index)
            count = GetQuestLogEntryCount()
        end
        index = index + 1
    end
end

local function RestoreLegacyQuestHeaders(expanded)
    if not CollapseQuestHeader then
        return
    end
    for index = #expanded, 1, -1 do
        SafeCall(CollapseQuestHeader, expanded[index])
    end
end

local function ReadModernEntry(index)
    local info = SafeCall(C_QuestLog.GetInfo, index)
    if IsSecretValue(info) or type(info) ~= "table" then
        return nil
    end

    local questID = nil
    if C_QuestLog.GetQuestIDForLogIndex then
        questID = AsPositiveNumber(SafeCall(C_QuestLog.GetQuestIDForLogIndex, index))
    end
    questID = questID or AsPositiveNumber(info.questID)

    local isComplete = false
    local isFailed = false
    if questID then
        if C_QuestLog.IsComplete then
            isComplete = AsBoolean(SafeCall(C_QuestLog.IsComplete, questID))
        end
        if C_QuestLog.IsFailed then
            isFailed = AsBoolean(SafeCall(C_QuestLog.IsFailed, questID))
        end
    end

    return questID, AsPositiveNumber(info.questID), AsSafeString(info.title), info.level,
        info.suggestedGroup, info.frequency, AsBoolean(info.isHeader),
        AsBoolean(info.isCollapsed), isComplete, isFailed, info, info.startEvent,
        info.isTask, info.isBounty, info.isStory, info.isHidden
end

local function ReadLegacyEntry(index)
    if not GetQuestLogTitle then
        return nil
    end

    local title, level, suggestedGroup, isHeader, isCollapsed, completion,
        frequency, returnedQuestID, startEvent, displayQuestID, isOnMap,
        hasLocalPOI, isTask, isBounty, isStory, isHidden =
        SafeCall(GetQuestLogTitle, index)

    title = AsSafeString(title)
    if not title then
        return nil
    end

    local safeIsHeader = AsBoolean(isHeader)
    local questID = nil
    if not safeIsHeader then
        questID = GetQuestIDFromLegacyIndex(index, returnedQuestID)
    end

    local isComplete = false
    local isFailed = false
    if not IsSecretValue(completion) then
        isComplete = completion == true or completion == 1
        isFailed = completion == -1
    end

    return questID, AsPositiveNumber(displayQuestID), title, level, suggestedGroup,
        frequency, safeIsHeader, AsBoolean(isCollapsed),
        isComplete, isFailed, nil, startEvent, isTask, isBounty, isStory, isHidden
end

local IsVisibleQuestRecord

local function ReadQuestLogEntry(index)
    if C_QuestLog and C_QuestLog.GetInfo then
        return ReadModernEntry(index)
    end
    return ReadLegacyEntry(index)
end

local function SignatureValue(value)
    if value == nil then
        return "0:"
    end
    if IsSecretValue(value) then
        return "S:"
    end

    local valueType = type(value)
    if valueType == "boolean" then
        return value and "B:1" or "B:0"
    end
    if valueType == "number" then
        return "N:" .. tostring(value)
    end
    if valueType == "string" then
        return "T:" .. #value .. ":" .. value
    end
    return "X:" .. valueType
end

local function AppendObjectiveSignature(parts, text, objectiveType, finished,
    numFulfilled, numRequired)
    parts[#parts + 1] = SignatureValue(text)
    parts[#parts + 1] = SignatureValue(objectiveType)
    parts[#parts + 1] = SignatureValue(finished)
    parts[#parts + 1] = SignatureValue(numFulfilled)
    parts[#parts + 1] = SignatureValue(numRequired)
end

local function SanitizeObjective(objective)
    if IsSecretValue(objective) or type(objective) ~= "table" then
        return nil
    end

    local text = objective.text
    local objectiveType = objective.type
    local finished = objective.finished
    local numFulfilled = objective.numFulfilled
    local numRequired = objective.numRequired
    if IsSecretValue(text) or IsSecretValue(objectiveType)
        or IsSecretValue(finished) or IsSecretValue(numFulfilled)
        or IsSecretValue(numRequired) or type(text) ~= "string" then
        return nil
    end

    return {
        text = text,
        type = AsSafeString(objectiveType),
        finished = AsBoolean(finished),
        numFulfilled = AsNumber(numFulfilled, nil),
        numRequired = AsNumber(numRequired, nil),
    }
end

local function GetObjectiveProgress(text)
    text = AsSafeString(text)
    if not text then
        return nil, nil
    end

    local fulfilled, required = string.match(text, "(%d+)%s*/%s*(%d+)")
    return tonumber(fulfilled), tonumber(required)
end

local function ReconcileLegacyObjective(objective, questID, objectiveIndex, questLogIndex)
    if not AsPositiveNumber(questID) or not AsPositiveNumber(objectiveIndex) then
        return objective
    end

    -- GetQuestObjectiveInfo is Blizzard's questID-keyed numeric objective
    -- authority. Unlike tracker-formatted text, it returns numFulfilled and
    -- numRequired directly and therefore does not depend on localized or
    -- suppressed progress prefixes.
    local text, objectiveType, finished, legacyFulfilled, legacyRequired
    if GetQuestObjectiveInfo then
        text, objectiveType, finished, legacyFulfilled, legacyRequired =
            SafeCall(GetQuestObjectiveInfo, questID, objectiveIndex, false)
    end

    -- Older Classic clients may not expose GetQuestObjectiveInfo. Preserve
    -- the leaderboard fallback there, but use it only as display text unless
    -- a numeric prefix can be read safely.
    if type(text) ~= "string" and GetQuestLogLeaderBoard
        and AsPositiveNumber(questLogIndex) then
        text, objectiveType, finished = SafeCall(
            GetQuestLogLeaderBoard, objectiveIndex, questLogIndex
        )
        legacyFulfilled, legacyRequired = GetObjectiveProgress(text)
    end
    QuestCatalog.refreshDiagnostics.legacyObjectiveReads =
        QuestCatalog.refreshDiagnostics.legacyObjectiveReads + 1
    if IsSecretValue(text) or IsSecretValue(objectiveType)
        or IsSecretValue(finished) or IsSecretValue(legacyFulfilled)
        or IsSecretValue(legacyRequired) or type(text) ~= "string" then
        return objective
    end

    legacyFulfilled = AsNumber(legacyFulfilled, nil)
    legacyRequired = AsNumber(legacyRequired, nil)
    if not objective then
        return {
            text = text,
            type = AsSafeString(objectiveType),
            finished = AsBoolean(finished),
            numFulfilled = legacyFulfilled,
            numRequired = legacyRequired,
        }
    end

    local structuredFulfilled = AsNumber(objective.numFulfilled, nil)
    local structuredRequired = AsNumber(objective.numRequired, nil)
    if legacyFulfilled and legacyRequired and structuredFulfilled
        and structuredRequired and legacyRequired == structuredRequired
        and legacyFulfilled > structuredFulfilled then
        QuestCatalog.refreshDiagnostics.legacyProgressOverrides =
            QuestCatalog.refreshDiagnostics.legacyProgressOverrides + 1
        return {
            text = text,
            type = objective.type or AsSafeString(objectiveType),
            finished = objective.finished or AsBoolean(finished)
                or legacyFulfilled >= legacyRequired,
            numFulfilled = legacyFulfilled,
            numRequired = legacyRequired,
        }
    end

    return objective
end

local function GetCurrentObjectiveSnapshot(questID)
    local objectives
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        objectives = SafeCall(C_QuestLog.GetQuestObjectives, questID)
        if IsSecretValue(objectives) or type(objectives) ~= "table" then
            return nil, 0
        end
    elseif GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        local questLogIndex = GetCurrentQuestLogIndex(questID)
        local count = SafeCall(GetNumQuestLeaderBoards, questLogIndex)
        if IsSecretValue(count) or type(count) ~= "number" then
            return nil, 0
        end
        objectives = {}
        for index = 1, count do
            local text, objectiveType, finished = SafeCall(
                GetQuestLogLeaderBoard, index, questLogIndex
            )
            objectives[index] = {
                text = text,
                type = objectiveType,
                finished = finished,
            }
        end
    else
        return nil, 0
    end

    local count = #objectives
    local questLogIndex = GetCurrentQuestLogIndex(questID)
    local snapshot = {}
    for index = 1, count do
        snapshot[index] = ReconcileLegacyObjective(
            SanitizeObjective(objectives[index]), questID, index, questLogIndex
        )
    end
    return snapshot, count
end

local function GetObjectiveSignature(self, questID, questLogIndex, generation)
    local parts = self.objectiveSignatureScratch
    wipe(parts)
    local objectiveCount = 0
    local objectiveSnapshot = {}
    local reliable = true

    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local objectives = SafeCall(C_QuestLog.GetQuestObjectives, questID)
        if IsSecretValue(objectives) then
            reliable = false
        elseif type(objectives) == "table" then
            objectiveCount = #objectives
            for index = 1, objectiveCount do
                local objective = objectives[index]
                if IsSecretValue(objective) then
                    reliable = false
                elseif type(objective) == "table" then
                    local text = AsSafeString(objective.text)
                    local objectiveType = AsSafeString(objective.type)
                    local finished = objective.finished
                    local numFulfilled = objective.numFulfilled
                    local numRequired = objective.numRequired
                    if IsSecretValue(objective.text)
                        or IsSecretValue(objective.type)
                        or IsSecretValue(finished)
                        or IsSecretValue(numFulfilled)
                        or IsSecretValue(numRequired) then
                        reliable = false
                    end
                    local reconciled = ReconcileLegacyObjective(
                        SanitizeObjective(objective), questID, index, questLogIndex
                    )
                    if reconciled then
                        text = reconciled.text
                        objectiveType = reconciled.type
                        finished = reconciled.finished
                        numFulfilled = reconciled.numFulfilled
                        numRequired = reconciled.numRequired
                    end
                    AppendObjectiveSignature(
                        parts, text, objectiveType, AsBoolean(finished),
                        AsNumber(numFulfilled, nil), AsNumber(numRequired, nil)
                    )
                    objectiveSnapshot[index] = reconciled
                else
                    reliable = false
                end
            end
        else
            -- A nil result can mean Blizzard is still loading quest data.
            -- It is not an authoritative empty objective list.
            reliable = false
        end
    elseif GetNumQuestLeaderBoards and GetQuestLogLeaderBoard
        and AsPositiveNumber(questLogIndex) then
        local count = SafeCall(GetNumQuestLeaderBoards, questLogIndex)
        if IsSecretValue(count) then
            reliable = false
        else
            objectiveCount = AsNumber(count, 0)
            for index = 1, objectiveCount do
                local text, objectiveType, finished = SafeCall(
                    GetQuestLogLeaderBoard, index, questLogIndex
                )
                if IsSecretValue(text) or IsSecretValue(objectiveType)
                    or IsSecretValue(finished) then
                    reliable = false
                end
                AppendObjectiveSignature(
                    parts, AsSafeString(text), AsSafeString(objectiveType),
                    AsBoolean(finished), nil, nil
                )
                if not IsSecretValue(text)
                    and not IsSecretValue(objectiveType)
                    and not IsSecretValue(finished)
                    and type(text) == "string" then
                    objectiveSnapshot[index] = {
                        text = text,
                        type = AsSafeString(objectiveType),
                        finished = AsBoolean(finished),
                    }
                end
            end
        end
    end

    -- Restricted values cannot be compared safely. Include the catalog
    -- generation so a restricted objective event conservatively invalidates
    -- progress consumers instead of silently losing an update.
    if not reliable then
        parts[#parts + 1] = "restricted-generation:" .. tostring(generation or 0)
    end

    return objectiveCount, table_concat(parts, "\031"), reliable,
        objectiveSnapshot
end

local function ResetDelta(delta, reason, kind)
    delta.reason = reason or "catalog-refresh"
    delta.kind = kind or "state"
    delta.revision = 0
    delta.stateRevision = 0
    delta.mapRevision = 0
    wipe(delta.flags)
    for index = 1, #DELTA_KINDS do
        local deltaKind = DELTA_KINDS[index]
        wipe(delta[deltaKind .. "QuestIDs"])
        wipe(delta["_" .. deltaKind .. "Set"])
    end
end

local function MarkDeltaQuest(delta, kind, questID)
    if not questID then
        return
    end
    local seen = delta["_" .. kind .. "Set"]
    if seen[questID] then
        return
    end
    seen[questID] = true
    local list = delta[kind .. "QuestIDs"]
    list[#list + 1] = questID
end

local function MarkDeltaFlag(delta, flag)
    delta.flags[flag] = true
end

local function BuildStructureSignature(record)
    return SignatureValue(record.source) .. "\030"
        .. SignatureValue(record.header) .. "\030"
        .. SignatureValue(record.category) .. "\030"
        .. SignatureValue(record.isActive)
end

local function BuildIndexSignature(record)
    return SignatureValue(record.questLogIndex)
end

local function BuildVisibilitySignature(record)
    return SignatureValue(record.isHidden) .. "\030"
        .. SignatureValue(record.isCollapsed) .. "\030"
        .. SignatureValue(IsVisibleQuestRecord(record))
end

local function BuildPresentationSignature(record)
    return SignatureValue(record.title) .. "\030"
        .. SignatureValue(record.level) .. "\030"
        .. SignatureValue(record.suggestedGroup) .. "\030"
        .. SignatureValue(record.frequency) .. "\030"
        .. SignatureValue(record.tagName)
end

local function BuildClassificationSignature(record)
    return SignatureValue(record.classification) .. "\030"
        .. SignatureValue(record.classificationID) .. "\030"
        .. SignatureValue(record.isTask) .. "\030"
        .. SignatureValue(record.isWorldQuest) .. "\030"
        .. SignatureValue(record.isBonusObjective) .. "\030"
        .. SignatureValue(record.isThreat) .. "\030"
        .. SignatureValue(record.isImportantLike)
end

local function BuildProgressSignature(record)
    return SignatureValue(record.isComplete) .. "\030"
        .. SignatureValue(record.isFailed) .. "\030"
        .. SignatureValue(record.objectiveCount) .. "\030"
        .. SignatureValue(record.objectiveSignature)
end

local function BuildMapSignature(record)
    return SignatureValue(record.mapID)
end

function QuestCatalog:BeginDelta(reason, kind)
    ResetDelta(self.workingDelta, reason, kind)
    return self.workingDelta
end

function QuestCatalog:TrackRecordDelta(record)
    local delta = self.workingDelta
    local isNew = not record._deltaInitialized
    local structureSignature = BuildStructureSignature(record)
    local indexSignature = BuildIndexSignature(record)
    local visibilitySignature = BuildVisibilitySignature(record)
    local presentationSignature = BuildPresentationSignature(record)
    local classificationSignature = BuildClassificationSignature(record)
    local progressSignature = BuildProgressSignature(record)
    local mapSignature = BuildMapSignature(record)
    local changed = false

    if isNew then
        MarkDeltaQuest(delta, "added", record.questID)
        MarkDeltaFlag(delta, "structure")
        MarkDeltaQuest(delta, "index", record.questID)
        MarkDeltaFlag(delta, "index")
        MarkDeltaFlag(delta, "visibility")
        MarkDeltaFlag(delta, "presentation")
        MarkDeltaFlag(delta, "classification")
        MarkDeltaFlag(delta, "progress")
        MarkDeltaFlag(delta, "mapData")
        changed = true
    else
        if record._structureSignature ~= structureSignature then
            MarkDeltaQuest(delta, "structure", record.questID)
            MarkDeltaFlag(delta, "structure")
            changed = true
        end
        if record._indexSignature ~= indexSignature then
            MarkDeltaQuest(delta, "index", record.questID)
            MarkDeltaFlag(delta, "index")
            changed = true
        end
        if record._visibilitySignature ~= visibilitySignature then
            MarkDeltaQuest(delta, "visibility", record.questID)
            MarkDeltaFlag(delta, "visibility")
            changed = true
        end
        if record._presentationSignature ~= presentationSignature then
            MarkDeltaQuest(delta, "presentation", record.questID)
            MarkDeltaFlag(delta, "presentation")
            changed = true
        end
        if record._classificationSignature ~= classificationSignature then
            MarkDeltaQuest(delta, "classification", record.questID)
            MarkDeltaFlag(delta, "classification")
            changed = true
        end
        if record._progressSignature ~= progressSignature then
            MarkDeltaQuest(delta, "progress", record.questID)
            MarkDeltaFlag(delta, "progress")
            changed = true
        end
        if record._mapSignature ~= mapSignature then
            MarkDeltaQuest(delta, "map", record.questID)
            MarkDeltaFlag(delta, "mapData")
            changed = true
        end
    end

    if changed then
        MarkDeltaQuest(delta, "changed", record.questID)
    end

    record._structureSignature = structureSignature
    record._indexSignature = indexSignature
    record._visibilitySignature = visibilitySignature
    record._presentationSignature = presentationSignature
    record._classificationSignature = classificationSignature
    record._progressSignature = progressSignature
    record._mapSignature = mapSignature
    record._deltaInitialized = true
end

function QuestCatalog:TrackRemovedRecord(record)
    if not record or not record.questID then
        return
    end
    local delta = self.workingDelta
    MarkDeltaQuest(delta, "removed", record.questID)
    MarkDeltaQuest(delta, "changed", record.questID)
    MarkDeltaFlag(delta, "structure")
    MarkDeltaFlag(delta, "index")
    MarkDeltaFlag(delta, "visibility")
    MarkDeltaFlag(delta, "presentation")
    MarkDeltaFlag(delta, "classification")
    MarkDeltaFlag(delta, "progress")
    MarkDeltaFlag(delta, "mapData")
end

local function DeltaAffectsConsumer(delta, consumer)
    return delta and delta.flags and delta.flags[consumer] and true or false
end

function QuestCatalog:CommitDelta(reason)
    local delta = self.workingDelta
    delta.reason = reason or delta.reason or "catalog-refresh"

    local flags = delta.flags
    flags.state = flags.structure or flags.index or flags.visibility
        or flags.presentation or flags.classification or flags.progress
    flags.projection = flags.state
    flags.watch = flags.structure or flags.index or flags.visibility
        or flags.presentation or flags.classification or flags.progress
    flags.list = flags.watch
    flags.tooltip = flags.structure or flags.index or flags.visibility
        or flags.presentation or flags.classification or flags.progress
    flags.map = flags.mapData or flags.structure or flags.index
        or flags.visibility or flags.presentation or flags.classification
        or flags.progress
    flags.routing = flags.mapData or flags.structure or flags.visibility
        or flags.classification or flags.progress

    local changed = flags.state or flags.mapData
    local diagnostics = self.refreshDiagnostics
    diagnostics.deltaBuilds = diagnostics.deltaBuilds + 1
    if not changed then
        diagnostics.noChangeRebuilds = diagnostics.noChangeRebuilds + 1
        delta.revision = self.revision
        delta.stateRevision = self.stateRevision
        delta.mapRevision = self.mapRevision
        self.workingDelta, self.lastDelta = self.lastDelta, delta
        return false
    end

    if flags.structure or flags.visibility then
        self.structureRevision = self.structureRevision + 1
    end
    if flags.index then
        self.indexRevision = (self.indexRevision or 0) + 1
    end
    if flags.progress then
        self.progressRevision = self.progressRevision + 1
    end
    if flags.presentation then
        self.presentationRevision = self.presentationRevision + 1
    end
    if flags.classification then
        self.classificationRevision = self.classificationRevision + 1
    end
    if flags.state then
        self.stateRevision = self.stateRevision + 1
    end
    if flags.mapData or flags.structure or flags.visibility then
        self.mapRevision = self.mapRevision + 1
        self.currentMapRecordsRevision = -1
    end

    for index = 1, #CONSUMER_NAMES do
        local consumer = CONSUMER_NAMES[index]
        if flags[consumer] then
            self.consumerRevisions[consumer] = self.consumerRevisions[consumer] + 1
        end
    end

    self.revision = self.revision + 1
    delta.revision = self.revision
    delta.stateRevision = self.stateRevision
    delta.mapRevision = self.mapRevision

    diagnostics.addedQuests = diagnostics.addedQuests + #delta.addedQuestIDs
    diagnostics.removedQuests = diagnostics.removedQuests + #delta.removedQuestIDs
    diagnostics.progressChanges = diagnostics.progressChanges + #delta.progressQuestIDs
    diagnostics.presentationChanges = diagnostics.presentationChanges
        + #delta.presentationQuestIDs
    diagnostics.classificationChanges = diagnostics.classificationChanges
        + #delta.classificationQuestIDs
    diagnostics.mapChanges = diagnostics.mapChanges + #delta.mapQuestIDs
    diagnostics.structureChanges = diagnostics.structureChanges
        + #delta.structureQuestIDs
    diagnostics.indexChanges = (diagnostics.indexChanges or 0)
        + #delta.indexQuestIDs

    self.workingDelta, self.lastDelta = self.lastDelta, delta
    if Nx.Com and Nx.Com.RecordQuestMonitorEvent then
        Nx.Com:RecordQuestMonitorEvent("catalog-delta", delta.reason)
    end
    return true
end

function QuestCatalog:GetLastDelta()
    return self.lastDelta
end

function QuestCatalog:DeltaAffects(consumer, delta)
    return DeltaAffectsConsumer(delta or self.lastDelta, consumer)
end

function QuestCatalog:GetConsumerRevision(consumer)
    return self.consumerRevisions[consumer] or 0
end

function QuestCatalog:SyncFallbackReference()
    if self.fallback.byQuestID ~= Nx.Quests then
        self.fallback.byQuestID = Nx.Quests
    end
end

function QuestCatalog:SetFallbackContent(byQuestID, metadata)
    if type(byQuestID) == "table" then
        self.fallback.byQuestID = byQuestID
    else
        self.fallback.byQuestID = Nx.Quests
    end

    metadata = type(metadata) == "table" and metadata or nil
    if metadata then
        if metadata.contentVersion then
            self.fallback.contentVersion = tostring(metadata.contentVersion)
        end
        if metadata.source then
            self.fallback.source = tostring(metadata.source)
        end
        if metadata.questCount then
            self.fallback.questCount = tonumber(metadata.questCount) or self.fallback.questCount
        end
    end

    -- The bundled data loader may finish after an early live projection was
    -- created. Rebase projections that now have complete fallback content in
    -- place so existing legacy references remain valid. Projections for quests
    -- still absent from fallback content are retained because Blizzard is their
    -- only available knowledge source.
    local overlay = self.compatibilityOverlay.byQuestID
    local patchFlags = self.compatibilityOverlay.patchFlags
    local fallbackStore = self.fallback.byQuestID
    for questID, projected in pairs(overlay) do
        local fallback = fallbackStore and fallbackStore[questID]
        if type(fallback) == "table" and type(projected) == "table" then
            local rebased = DeepCopyLegacy(fallback)
            wipe(projected)
            for key, value in pairs(rebased) do
                projected[key] = value
            end
            patchFlags[questID] = nil
        end
    end

    self.fallback.loadedAt = GetTime and GetTime() or 0
end

function QuestCatalog:GetFallbackMetadata()
    self:SyncFallbackReference()
    return self.fallback
end

function QuestCatalog:GetFallbackQuest(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil
    end
    self:SyncFallbackReference()
    local store = self.fallback.byQuestID
    return store and store[questID] or nil
end

function QuestCatalog:HasFallbackQuest(questID)
    return self:GetFallbackQuest(questID) ~= nil
end

function QuestCatalog:GetLegacyQuestData(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil
    end

    local projected = self.compatibilityOverlay.byQuestID[questID]
    if projected then
        return projected
    end
    return self:GetFallbackQuest(questID)
end

function QuestCatalog:GetMutableLegacyQuestData(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil
    end

    local overlay = self.compatibilityOverlay.byQuestID
    local projected = overlay[questID]
    if projected then
        return projected
    end

    local fallback = self:GetFallbackQuest(questID)
    projected = fallback and DeepCopyLegacy(fallback) or {}
    overlay[questID] = projected
    return projected
end

function QuestCatalog:GetLegacyPatchFlags(questID)
    questID = AsPositiveNumber(questID)
    return questID and (self.compatibilityOverlay.patchFlags[questID] or 0) or 0
end

function QuestCatalog:SetLegacyPatchFlags(questID, flags)
    questID = AsPositiveNumber(questID)
    if not questID then
        return
    end
    self.compatibilityOverlay.patchFlags[questID] = tonumber(flags) or 0
end

function QuestCatalog:ClearLegacyProjection(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return
    end
    self.compatibilityOverlay.byQuestID[questID] = nil
    self.compatibilityOverlay.patchFlags[questID] = nil
end


function QuestCatalog:ResolveQuestID(questID, questLogIndex)
    questID = AsPositiveNumber(questID)
    if questID and self.byQuestID[questID] then
        return questID
    end

    questLogIndex = AsPositiveNumber(questLogIndex)
    if questLogIndex then
        local resolvedQuestID
        if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
            resolvedQuestID = AsPositiveNumber(
                SafeCall(C_QuestLog.GetQuestIDForLogIndex, questLogIndex)
            )
        elseif GetQuestLogTitle then
            local _, _, _, isHeader, _, _, _, returnedQuestID =
                SafeCall(GetQuestLogTitle, questLogIndex)
            if not AsBoolean(isHeader) then
                resolvedQuestID = GetQuestIDFromLegacyIndex(
                    questLogIndex, returnedQuestID
                )
            end
        end

        if resolvedQuestID then
            return resolvedQuestID
        end
    end

    return questID
end

function QuestCatalog:GetQuestRecord(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil
    end
    return self.byQuestID[questID]
end

function QuestCatalog:GetQuestObjectives(questID, allowAPIFallback)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil, 0
    end

    if allowAPIFallback ~= false and self.stateDirty then
        local objectives, count = GetCurrentObjectiveSnapshot(questID)
        if objectives then
            return objectives, count
        end
    end

    local record = self.byQuestID[questID]
    if record and type(record.objectives) == "table" then
        return record.objectives, AsNumber(record.objectiveCount, 0)
    end

    if allowAPIFallback ~= false then
        return GetCurrentObjectiveSnapshot(questID)
    end
    return nil, 0
end

function QuestCatalog:GetQuestObjective(questID, objectiveIndex,
    allowAPIFallback)
    objectiveIndex = AsPositiveNumber(objectiveIndex)
    if not objectiveIndex then
        return nil
    end
    local objectives = self:GetQuestObjectives(questID, allowAPIFallback)
    return objectives and objectives[objectiveIndex] or nil
end

function QuestCatalog:GetQuestLogIndex(questID, allowAPIFallback)
    questID = AsPositiveNumber(questID)
    if not questID then
        return 0
    end

    -- A log index is transient, so this fallback is resolved only when an
    -- action requires it. Consumers must never retain the result as identity.
    -- Passing false restricts a read-only caller to the committed snapshot.
    if allowAPIFallback ~= false and self.stateDirty then
        return GetCurrentQuestLogIndex(questID)
    end

    local record = self.byQuestID[questID]
    local questLogIndex = record and AsPositiveNumber(record.questLogIndex)
    if questLogIndex then
        return questLogIndex
    end

    if allowAPIFallback ~= false then
        return GetCurrentQuestLogIndex(questID)
    end
    return 0
end

function QuestCatalog:GetCurrentQuestLogIndex(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return 0
    end
    return GetCurrentQuestLogIndex(questID)
end

function QuestCatalog:GetQuestStateAndFallback(questID)
    return self:GetQuestRecord(questID), self:GetFallbackQuest(questID)
end

function QuestCatalog:GetQuestClassification(questID)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil
    end

    local record = self.byQuestID[questID]
    if record then
        return record.classification, record.classificationID,
            record.classificationSource
    end

    local tagID, tagName, tagInfo = GetQuestTag(questID)
    return GetClassification(questID, nil, nil, nil, nil, nil, nil,
        tagID, tagName, tagInfo)
end

function QuestCatalog:IsQuestClassification(questID, classification)
    local current = self:GetQuestClassification(questID)
    return current == classification
end

function QuestCatalog:IsQuestImportantLike(questID)
    local classification = self:GetQuestClassification(questID)
    return classification and IMPORTANT_LIKE_CLASSIFICATIONS[classification] or false
end

local function GetCurrentQuestTitle(questID)
    local questLogIndex = GetCurrentQuestLogIndex(questID)
    if questLogIndex <= 0 then
        return nil
    end

    local returnedQuestID, title, _, _, _, _, isHeader =
        ReadQuestLogEntry(questLogIndex)
    if AsPositiveNumber(returnedQuestID) ~= questID or AsBoolean(isHeader) then
        return nil
    end

    title = AsSafeString(title)
    return title and title ~= "" and title or nil
end

function QuestCatalog:GetQuestTitle(questID, fallbackTitle, allowAPIFallback)
    questID = AsPositiveNumber(questID)
    if not questID then
        return fallbackTitle
    end

    if allowAPIFallback ~= false and self.stateDirty then
        local title = GetCurrentQuestTitle(questID)
        if title then
            return title
        end
    end

    local record = self.byQuestID[questID]
    if record and record.title and record.title ~= "" then
        return record.title
    end

    if allowAPIFallback ~= false and C_QuestLog then
        local title
        if C_QuestLog.GetTitleForQuestID then
            title = SafeCall(C_QuestLog.GetTitleForQuestID, questID)
        elseif C_QuestLog.GetQuestInfo then
            title = SafeCall(C_QuestLog.GetQuestInfo, questID)
        end
        title = AsSafeString(title)
        if title and title ~= "" then
            return title
        end

        if C_QuestLog.RequestLoadQuestByID and not self.requestedQuestData[questID] then
            self.requestedQuestData[questID] = true
            SafeCall(C_QuestLog.RequestLoadQuestByID, questID)
        end
    end

    local staticTitle = GetFallbackTitle(self:GetFallbackQuest(questID))
    if staticTitle and staticTitle ~= "" then
        return staticTitle
    end
    return fallbackTitle
end

function QuestCatalog:GetActiveQuestIDs()
    return self.activeQuestIDs
end

function QuestCatalog:GetVisibleQuestIDs(groupByHeader)
    if groupByHeader then
        return self.visibleQuestIDsByHeader
    end
    return self.visibleQuestIDs
end

function QuestCatalog:GetVisibleQuestIDSet()
    return self.visibleQuestIDSet
end

function QuestCatalog:GetVisibleQuestPosition(questID, groupByHeader)
    questID = AsPositiveNumber(questID)
    if not questID then
        return nil
    end
    if groupByHeader then
        return self.visibleHeaderPosition[questID]
    end
    return self.visiblePosition[questID]
end

function QuestCatalog:GetQuestRecordByLogIndex(questLogIndex)
    questLogIndex = AsPositiveNumber(questLogIndex)
    if not questLogIndex then
        return nil
    end
    local questID = self.byQuestLogIndex[questLogIndex]
    return questID and self.byQuestID[questID] or nil
end

function QuestCatalog:GetQuestIDByLogIndex(questLogIndex, allowAPIFallback)
    questLogIndex = AsPositiveNumber(questLogIndex)
    if not questLogIndex then
        return nil
    end

    if allowAPIFallback ~= false and self.stateDirty then
        return self:ResolveQuestID(nil, questLogIndex)
    end

    local questID = self.byQuestLogIndex[questLogIndex]
    if questID then
        return questID
    end

    if allowAPIFallback ~= false then
        return self:ResolveQuestID(nil, questLogIndex)
    end
    return nil
end

local function GetCurrentQuestMetadata(questID)
    local questLogIndex = GetCurrentQuestLogIndex(questID)
    if questLogIndex <= 0 then
        return nil, nil, false
    end

    local returnedQuestID, _, _, level, _, frequency, isHeader =
        ReadQuestLogEntry(questLogIndex)
    if AsPositiveNumber(returnedQuestID) ~= questID or AsBoolean(isHeader) then
        return nil, nil, false
    end
    return AsNumber(level, 0), AsNumber(frequency, 0), true
end

function QuestCatalog:GetQuestLevel(questID, allowAPIFallback)
    questID = AsPositiveNumber(questID)
    if not questID then
        return 0
    end

    if allowAPIFallback ~= false and self.stateDirty then
        local level, _, found = GetCurrentQuestMetadata(questID)
        if found then
            return level
        end
    end

    local record = self.byQuestID[questID]
    if record then
        return AsNumber(record.level, 0)
    end

    if allowAPIFallback ~= false then
        local level, _, found = GetCurrentQuestMetadata(questID)
        if found then
            return level
        end
    end
    return 0
end

function QuestCatalog:GetQuestFrequency(questID, allowAPIFallback)
    questID = AsPositiveNumber(questID)
    if not questID then
        return 0
    end

    if allowAPIFallback ~= false and self.stateDirty then
        local _, frequency, found = GetCurrentQuestMetadata(questID)
        if found then
            return frequency
        end
    end

    local record = self.byQuestID[questID]
    if record then
        return AsNumber(record.frequency, 0)
    end

    if allowAPIFallback ~= false then
        local _, frequency, found = GetCurrentQuestMetadata(questID)
        if found then
            return frequency
        end
    end
    return 0
end

function QuestCatalog:GetVisibleQuestIDsByTitle(title)
    title = AsSafeString(title)
    return title and self.byTitle[title] or nil
end

function QuestCatalog:GetQuestLogQuestCount()
    if not self.hasStateSnapshot then
        return nil
    end
    return self.questLogQuestCount
end

function QuestCatalog:GetQuestIDsForMap(mapID)
    mapID = AsPositiveNumber(mapID)
    return mapID and self.byMapID[mapID] or nil
end

function QuestCatalog:GetQuestIDsForCurrentMap()
    return self.byMapID[self.currentMapID]
end

function QuestCatalog:GetQuestRecordsForCurrentMap()
    if self.currentMapRecordsRevision == self.mapRevision then
        return self.currentMapRecords
    end

    local records = self.currentMapRecords
    wipe(records)
    local questIDs = self:GetQuestIDsForCurrentMap()
    if questIDs then
        for index = 1, #questIDs do
            local record = self.byQuestID[questIDs[index]]
            if record then
                records[#records + 1] = record
            end
        end
    end
    self.currentMapRecordsRevision = self.mapRevision
    return records
end

function QuestCatalog:GetQuestIDsByCategory(category)
    return self.byCategory[category]
end

function QuestCatalog:GetQuestIDsByHeader(header)
    return self.byHeader[header]
end

function QuestCatalog:GetQuestIDsByClassification(classification)
    return self.byClassification[classification]
end

function QuestCatalog:GetQuestIDsByCompletion(isComplete)
    if isComplete then
        return self.byCompletion.complete
    end
    return self.byCompletion.incomplete
end

function QuestCatalog:ForEachActiveQuest(callback, owner)
    if type(callback) ~= "function" then
        return
    end

    local activeQuestIDs = self.activeQuestIDs
    local byQuestID = self.byQuestID
    for index = 1, #activeQuestIDs do
        local record = byQuestID[activeQuestIDs[index]]
        if record then
            if owner ~= nil then
                callback(owner, record)
            else
                callback(record)
            end
        end
    end
end

local function NormalizeCallbackInterests(interests)
    if type(interests) == "string" then
        return { [interests] = true }
    end
    if type(interests) ~= "table" then
        return nil
    end

    local normalized = {}
    for key, value in pairs(interests) do
        if type(key) == "number" and type(value) == "string" then
            normalized[value] = true
        elseif value then
            normalized[key] = true
        end
    end
    return normalized
end

function QuestCatalog:RegisterCallback(owner, callback, interests)
    if type(callback) ~= "function" then
        return false
    end

    local callbacks = self.callbacks
    for index = 1, #callbacks do
        local entry = callbacks[index]
        if entry.owner == owner and entry.callback == callback then
            return true
        end
    end

    callbacks[#callbacks + 1] = {
        owner = owner,
        callback = callback,
        interests = NormalizeCallbackInterests(interests),
    }
    return true
end

function QuestCatalog:UnregisterCallback(owner, callback)
    local callbacks = self.callbacks
    for index = #callbacks, 1, -1 do
        local entry = callbacks[index]
        if entry.owner == owner and (callback == nil or entry.callback == callback) then
            table_remove(callbacks, index)
        end
    end
end

function QuestCatalog:FireCallbacks(reason)
    local diagnostics = self.refreshDiagnostics
    local delta = self.lastDelta
    local callbacks = self.callbacks
    for index = 1, #callbacks do
        local entry = callbacks[index]
        local dispatch = entry.interests == nil
        if not dispatch then
            for consumer in pairs(entry.interests) do
                if DeltaAffectsConsumer(delta, consumer) then
                    dispatch = true
                    break
                end
            end
        end

        if dispatch then
            diagnostics.callbackDispatches = diagnostics.callbackDispatches + 1
            local ok = pcall(
                entry.callback, entry.owner, self, reason, self.revision, delta
            )
            if not ok then
                diagnostics.callbackErrors = diagnostics.callbackErrors + 1
            end
        else
            diagnostics.selectiveCallbackSkips =
                diagnostics.selectiveCallbackSkips + 1
        end
    end
end

function QuestCatalog:ClearIndexes()
    wipe(self.activeQuestIDs)
    wipe(self.activeQuestIDSet)
    wipe(self.visibleQuestIDs)
    wipe(self.visibleQuestIDsByHeader)
    wipe(self.visibleQuestIDSet)
    wipe(self.visiblePosition)
    wipe(self.visibleHeaderPosition)
    wipe(self.byQuestLogIndex)
    ReleaseIndex(self, self.byTitle)
    ReleaseIndex(self, self.byMapID)
    ReleaseIndex(self, self.byCategory)
    ReleaseIndex(self, self.byHeader)
    ReleaseIndex(self, self.byClassification)
    wipe(self.byCompletion.complete)
    wipe(self.byCompletion.incomplete)
    wipe(self.byCompletion.failed)
end

IsVisibleQuestRecord = function(record)
    return record
        and record.source == "blizzard-runtime"
        and not record.isHidden
        and AsPositiveNumber(record.questLogIndex) ~= nil
end

local function CompareVisibleLevel(self, leftQuestID, rightQuestID)
    local left = self.byQuestID[leftQuestID]
    local right = self.byQuestID[rightQuestID]
    if not left then
        return false
    end
    if not right then
        return true
    end

    local leftLevel = AsNumber(left.level, 0)
    local rightLevel = AsNumber(right.level, 0)
    if leftLevel ~= rightLevel then
        return leftLevel < rightLevel
    end

    local leftIndex = AsNumber(left.questLogIndex, 0)
    local rightIndex = AsNumber(right.questLogIndex, 0)
    if leftIndex ~= rightIndex then
        return leftIndex < rightIndex
    end
    return leftQuestID < rightQuestID
end

local function CompareVisibleHeader(self, leftQuestID, rightQuestID)
    local left = self.byQuestID[leftQuestID]
    local right = self.byQuestID[rightQuestID]
    if not left then
        return false
    end
    if not right then
        return true
    end

    local leftHeader = string_lower(left.header or "")
    local rightHeader = string_lower(right.header or "")
    if leftHeader ~= rightHeader then
        return leftHeader < rightHeader
    end
    return CompareVisibleLevel(self, leftQuestID, rightQuestID)
end

function QuestCatalog:BuildVisibleSubset()
    local visible = self.visibleQuestIDs
    local grouped = self.visibleQuestIDsByHeader
    local visibleSet = self.visibleQuestIDSet
    local position = self.visiblePosition
    local groupedPosition = self.visibleHeaderPosition
    local byQuestLogIndex = self.byQuestLogIndex

    wipe(visible)
    wipe(grouped)
    wipe(visibleSet)
    wipe(position)
    wipe(groupedPosition)
    wipe(byQuestLogIndex)
    ReleaseIndex(self, self.byTitle)

    for index = 1, #self.activeQuestIDs do
        local questID = self.activeQuestIDs[index]
        local record = self.byQuestID[questID]
        if IsVisibleQuestRecord(record) then
            visible[#visible + 1] = questID
            grouped[#grouped + 1] = questID
            visibleSet[questID] = true
            byQuestLogIndex[record.questLogIndex] = questID
            AddToIndex(self, self.byTitle, record.title, questID)
        end
    end

    table_sort(visible, function(leftQuestID, rightQuestID)
        return CompareVisibleLevel(self, leftQuestID, rightQuestID)
    end)
    table_sort(grouped, function(leftQuestID, rightQuestID)
        return CompareVisibleHeader(self, leftQuestID, rightQuestID)
    end)

    for index = 1, #visible do
        position[visible[index]] = index
    end
    for index = 1, #grouped do
        groupedPosition[grouped[index]] = index
    end
end

function QuestCatalog:IndexRecord(record)
    local questID = record.questID
    self.activeQuestIDs[#self.activeQuestIDs + 1] = questID
    self.activeQuestIDSet[questID] = true

    AddToIndex(self, self.byHeader, record.header, questID)
    AddToIndex(self, self.byCategory, record.category, questID)
    AddToIndex(self, self.byClassification, record.classification, questID)
    AddToMapIndexUnique(self, record.mapID, questID)

    if record.isComplete then
        self.byCompletion.complete[#self.byCompletion.complete + 1] = questID
    else
        self.byCompletion.incomplete[#self.byCompletion.incomplete + 1] = questID
    end
    if record.isFailed then
        self.byCompletion.failed[#self.byCompletion.failed + 1] = questID
    end
end

function QuestCatalog:AddCurrentMapTaskRecords(mapID, generation, now, seen)
    mapID = AsPositiveNumber(mapID)
    if not mapID or not C_TaskQuest or not C_TaskQuest.GetQuestsOnMap then
        return
    end

    local results = SafeCall(C_TaskQuest.GetQuestsOnMap, mapID)
    if type(results) ~= "table" then
        return
    end

    for index = 1, #results do
        local entry = results[index]
        local questID = type(entry) == "table"
            and AsPositiveNumber(entry.questID) or nil
        if questID and not seen[questID] and IsActiveTaskQuest(questID, entry) then
            local tagID, tagName, tagInfo = GetQuestTag(questID)
            local classification, classificationID, classificationSource =
                GetClassification(questID, nil, nil, true, nil, nil, nil,
                    tagID, tagName, tagInfo)

            -- Generic task is deliberately retained as generic. It is not
            -- promoted into the bonus-objective feed without Blizzard's
            -- explicit BonusObjective classification.
            local record = self.byQuestID[questID]
            if not record then
                record = AcquireRecord(self)
                self.byQuestID[questID] = record
            end

            local category = GetTaskCategory(classification)
            seen[questID] = true
            record.questID = questID
            record.displayQuestID = questID
            record.title = GetTaskQuestTitle(questID)
                or self:GetQuestTitle(questID, "Quest " .. questID)
            record.questLogIndex = GetCurrentQuestLogIndex(questID)
            record.level = 0
            record.suggestedGroup = 0
            record.frequency = tagInfo and AsNumber(tagInfo.frequency, 0) or 0
            record.mapID = mapID
            record.header = category
            record.isHeader = false
            record.isCollapsed = false
            record.isComplete = C_QuestLog
                and QuestFlagIsTrue(C_QuestLog.IsComplete, questID) or false
            record.isFailed = C_QuestLog
                and QuestFlagIsTrue(C_QuestLog.IsFailed, questID) or false
            record.isActive = true
            record.classification = classification
            record.classificationID = classificationID
            record.classificationSource = classificationSource
            record.tagID = type(tagID) == "number" and not IsSecretValue(tagID)
                and tagID or nil
            record.tagName = AsSafeString(tagName)
            record.worldQuestType = tagInfo
                and AsNumber(tagInfo.worldQuestType, nil) or nil
            record.isTask = true
            record.isBounty = false
            record.isStory = false
            record.isHidden = false
            record.isWorldQuest = classification == "world-quest"
            record.isBonusObjective = classification == "bonus-objective"
            record.isThreat = classification == "threat"
            record.isImportant = classification == "important"
            record.isImportantLike = IMPORTANT_LIKE_CLASSIFICATIONS[classification]
                and true or false
            record.lastSeen = now
            record.category = category
            record.source = "blizzard-runtime-task"
            record.fallbackAvailable = self:GetFallbackQuest(questID) ~= nil
            record.objectiveCount, record.objectiveSignature,
                record.objectiveDataReliable, record.objectives =
                GetObjectiveSignature(
                    self, questID, record.questLogIndex, generation
                )
            record._generation = generation

            self:TrackRecordDelta(record)
            self:IndexRecord(record)
        end
    end
end

local function AddMapResultsToIndex(self, mapID, results)
    if type(results) ~= "table" then
        return
    end

    for index = 1, #results do
        local entry = results[index]
        local questID = type(entry) == "table" and AsPositiveNumber(entry.questID) or nil
        if questID and self.byQuestID[questID] then
            AddToMapIndexUnique(self, mapID, questID)
        end
    end
end

function QuestCatalog:IndexCurrentMapQuestIDs(mapID)
    mapID = AsPositiveNumber(mapID)
    if not mapID then
        return
    end

    if C_QuestLog and C_QuestLog.GetQuestsOnMap then
        AddMapResultsToIndex(self, mapID, SafeCall(C_QuestLog.GetQuestsOnMap, mapID))
    end
    if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
        AddMapResultsToIndex(self, mapID, SafeCall(C_TaskQuest.GetQuestsOnMap, mapID))
    end
end

function QuestCatalog:RebuildMapIndex(reason)
    if self.refreshing then
        self.mapRefreshPending = true
        self.refreshAgain = true
        return
    end

    local monitorSample = Nx.Com and Nx.Com.BeginQuestMonitorSample
        and Nx.Com:BeginQuestMonitorSample()
    self.refreshDiagnostics.mapRebuilds = self.refreshDiagnostics.mapRebuilds + 1
    local delta = self:BeginDelta(reason or "map-refresh", "map")
    MarkDeltaFlag(delta, "mapData")
    ReleaseIndex(self, self.byMapID)
    for index = 1, #self.activeQuestIDs do
        local questID = self.activeQuestIDs[index]
        local record = self.byQuestID[questID]
        if record then
            AddToMapIndexUnique(self, record.mapID, questID)
        end
    end

    self.currentMapID = GetCurrentMapID()
    self:IndexCurrentMapQuestIDs(self.currentMapID)
    self.lastRefreshReason = reason or "map-refresh"
    self.lastRefreshTime = GetTime and GetTime() or 0
    self.mapDirty = false
    if self:CommitDelta(self.lastRefreshReason) then
        self:FireCallbacks(self.lastRefreshReason)
    end
    if Nx.Com and Nx.Com.EndQuestMonitorSample then
        local burst = self.refreshDiagnostics.lastBurstEvents or 0
        Nx.Com:EndQuestMonitorSample(
            monitorSample, "catalog-map-rebuild", self.lastRefreshReason,
            { duplicateEvents = burst > 1 and burst - 1 or 0 }
        )
    end
end

function QuestCatalog:Rebuild(reason)
    if self.refreshing then
        self.fullRefreshPending = true
        self.refreshAgain = true
        return
    end

    local monitorSample = Nx.Com and Nx.Com.BeginQuestMonitorSample
        and Nx.Com:BeginQuestMonitorSample()
    self.refreshing = true
    self.refreshDiagnostics.fullRebuilds = self.refreshDiagnostics.fullRebuilds + 1
    local delta = self:BeginDelta(reason or "quest-log-refresh", "state")
    local previousMapID = self.currentMapID
    self:SyncFallbackReference()
    self.generation = self.generation + 1
    local generation = self.generation
    local seen = self.scanSeen
    wipe(seen)
    local expandedHeaders = self.expandedHeaders
    self.suppressQuestLogEvents = true
    ExpandLegacyQuestHeaders(expandedHeaders)
    local originallyCollapsedHeaders = self.originallyCollapsedHeaders
    wipe(originallyCollapsedHeaders)
    for index = 1, #expandedHeaders do
        originallyCollapsedHeaders[expandedHeaders[index]] = true
    end

    self:ClearIndexes()

    local currentHeader = "Uncategorized"
    local currentHeaderCollapsed = false
    local questLogQuestCount = 0
    local entryCount = GetQuestLogEntryCount()
    local now = GetTime and GetTime() or 0

    for questLogIndex = 1, entryCount do
        local questID, displayQuestID, title, level, suggestedGroup, frequency,
            isHeader, isCollapsed, isComplete, isFailed, info, startEvent,
            isTask, isBounty, isStory, isHidden = ReadQuestLogEntry(questLogIndex)

        if title ~= nil then
            if isHeader then
                title = AsSafeString(title)
                currentHeader = (title and title ~= "") and title or "Uncategorized"
                currentHeaderCollapsed = originallyCollapsedHeaders[questLogIndex]
                    or isCollapsed
            else
                questID = AsPositiveNumber(questID)
                if questID and not seen[questID] then
                    seen[questID] = true
                    questLogQuestCount = questLogQuestCount + 1

                    local record = self.byQuestID[questID]
                    if not record then
                        record = AcquireRecord(self)
                        self.byQuestID[questID] = record
                    end

                    record.questID = questID
                    record.displayQuestID = displayQuestID or questID
                    title = AsSafeString(title)
                    record.title = (title and title ~= "") and title or ("Quest " .. questID)
                    record.questLogIndex = questLogIndex
                    record.level = AsNumber(level, 0)
                    record.suggestedGroup = AsNumber(suggestedGroup, 0)
                    record.frequency = AsNumber(frequency, 0)
                    record.mapID = GetQuestMapID(questID)
                    record.header = currentHeader
                    record.isHeader = false
                    record.isCollapsed = currentHeaderCollapsed
                    record.isComplete = isComplete
                    record.isFailed = isFailed
                    record.isActive = true

                    local tagID, tagName, tagInfo = GetQuestTag(questID)
                    local classification, classificationID, classificationSource =
                        GetClassification(questID, info, startEvent, isTask, isBounty,
                            isStory, isHidden, tagID, tagName, tagInfo)

                    record.classification = classification
                    record.classificationID = classificationID
                    record.classificationSource = classificationSource
                    record.tagID = type(tagID) == "number" and not IsSecretValue(tagID)
                        and tagID or nil
                    record.tagName = AsSafeString(tagName)
                    record.worldQuestType = tagInfo
                        and AsNumber(tagInfo.worldQuestType, nil) or nil
                    record.isTask = AsBoolean(isTask)
                        or (C_QuestLog and QuestFlagIsTrue(C_QuestLog.IsQuestTask, questID))
                        or classification == "bonus-objective"
                        or classification == "world-quest"
                        or classification == "threat"
                    record.isBounty = AsBoolean(isBounty)
                    record.isStory = AsBoolean(isStory)
                    record.isHidden = AsBoolean(isHidden)
                    record.isWorldQuest = classification == "world-quest"
                    record.isBonusObjective = classification == "bonus-objective"
                    record.isThreat = classification == "threat"
                    record.isImportant = classification == "important"
                    record.isImportantLike = IMPORTANT_LIKE_CLASSIFICATIONS[classification]
                        and true or false
                    record.lastSeen = now
                    record.category = currentHeader
                    record.source = "blizzard-runtime"
                    record.fallbackAvailable = self:GetFallbackQuest(questID) ~= nil
                    record.objectiveCount, record.objectiveSignature,
                        record.objectiveDataReliable, record.objectives =
                        GetObjectiveSignature(
                            self, questID, questLogIndex, generation
                        )
                    record._generation = generation

                    self:TrackRecordDelta(record)
                    self:IndexRecord(record)
                end
            end
        end
    end

    local currentMapID = GetCurrentMapID()
    self:AddCurrentMapTaskRecords(currentMapID, generation, now, seen)
    self.questLogQuestCount = questLogQuestCount
    self:BuildVisibleSubset()

    RestoreLegacyQuestHeaders(expandedHeaders)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            QuestCatalog.suppressQuestLogEvents = false
        end)
    else
        self.suppressQuestLogEvents = false
    end

    for questID, record in pairs(self.byQuestID) do
        if record._generation ~= generation then
            self:TrackRemovedRecord(record)
            self.byQuestID[questID] = nil
            ReleaseRecord(self, record)
        end
    end

    if previousMapID ~= currentMapID then
        MarkDeltaFlag(delta, "mapData")
    end
    self.currentMapID = currentMapID
    self:IndexCurrentMapQuestIDs(self.currentMapID)

    self.lastRefreshReason = reason or "quest-log-refresh"
    self.lastRefreshTime = now
    self.hasStateSnapshot = true
    self.stateDirty = false
    self.mapDirty = false
    self.refreshing = false

    if self:CommitDelta(self.lastRefreshReason) then
        self:FireCallbacks(self.lastRefreshReason)
    end

    if self.refreshAgain then
        self.refreshAgain = false
        self:ScheduleRefresh("refresh-during-rebuild", self.fullRefreshPending)
    end
    if Nx.Com and Nx.Com.EndQuestMonitorSample then
        local burst = self.refreshDiagnostics.lastBurstEvents or 0
        Nx.Com:EndQuestMonitorSample(
            monitorSample, "catalog-full-rebuild", self.lastRefreshReason,
            { duplicateEvents = burst > 1 and burst - 1 or 0 }
        )
    end
end

local function GetRefreshDelay(reason, fullRefresh)
    if reason == "PLAYER_LOGIN"
        or reason == "PLAYER_ENTERING_WORLD"
        or reason == "ZONE_CHANGED_NEW_AREA"
        or reason == "catalog-initialize"
        or reason == "fallback-content-ready" then
        return REFRESH_DELAY_TRANSITION
    end
    if fullRefresh then
        return REFRESH_DELAY_STATE
    end
    return REFRESH_DELAY_MAP
end

function QuestCatalog:AddPendingReason(reason)
    if type(reason) ~= "string" or reason == "" then
        return
    end

    local pendingReasons = self.pendingReasons
    if pendingReasons[reason] then
        return
    end

    pendingReasons[reason] = true
    local order = self.pendingReasonOrder
    if #order < MAX_REFRESH_REASON_COUNT then
        order[#order + 1] = reason
    elseif not pendingReasons["additional-events"] then
        pendingReasons["additional-events"] = true
        order[#order + 1] = "additional-events"
    end
end

function QuestCatalog:ConsumePendingReasons(fallbackReason)
    local order = self.pendingReasonOrder
    local reason
    if #order > 0 then
        reason = table_concat(order, "+")
    else
        reason = fallbackReason
    end

    wipe(order)
    wipe(self.pendingReasons)
    return reason or "catalog-refresh"
end

function QuestCatalog:ResetRefreshBurst()
    local diagnostics = self.refreshDiagnostics
    diagnostics.lastBurstEvents = self.refreshBurstEventCount
    if self.refreshBurstEventCount > diagnostics.maxBurstEvents then
        diagnostics.maxBurstEvents = self.refreshBurstEventCount
    end
    self.refreshBurstStartedAt = nil
    self.refreshBurstEventCount = 0
end

function QuestCatalog:CancelScheduledRefresh(countCancellation)
    local hadScheduled = self.refreshScheduled
    local timer = self.refreshTimer
    if timer and timer.Cancel then
        pcall(timer.Cancel, timer)
    end

    self.refreshTimer = nil
    self.refreshScheduled = false
    self.refreshScheduledFor = 0
    self.refreshToken = self.refreshToken + 1

    if hadScheduled and countCancellation then
        self.refreshDiagnostics.cancelled = self.refreshDiagnostics.cancelled + 1
    end
end

function QuestCatalog:ArmRefreshTimer(delay)
    delay = AsNumber(delay, 0)
    if delay < 0 then
        delay = 0
    end

    local diagnostics = self.refreshDiagnostics
    local hadScheduled = self.refreshScheduled
    if hadScheduled then
        diagnostics.rescheduled = diagnostics.rescheduled + 1
    else
        diagnostics.scheduled = diagnostics.scheduled + 1
    end

    local timer = self.refreshTimer
    if timer and timer.Cancel then
        pcall(timer.Cancel, timer)
    end

    self.refreshToken = self.refreshToken + 1
    local token = self.refreshToken
    self.refreshScheduled = true
    self.refreshScheduledFor = (GetTime and GetTime() or 0) + delay
    diagnostics.lastDelay = delay

    local function Flush()
        QuestCatalog:FlushScheduledRefresh(token)
    end

    if C_Timer and C_Timer.NewTimer then
        self.refreshTimer = C_Timer.NewTimer(delay, Flush)
    elseif C_Timer and C_Timer.After then
        self.refreshTimer = nil
        C_Timer.After(delay, Flush)
    else
        self.refreshTimer = nil
        Flush()
    end
end

function QuestCatalog:EnsureFresh(reason)
    if self.refreshing then
        self.refreshAgain = true
        self.fullRefreshPending = true
        self:AddPendingReason(reason or "consumer-state-refresh")
        return false
    end

    if self.stateDirty or self.fullRefreshPending or not self.hasStateSnapshot then
        self.refreshDiagnostics.forcedFlushes = self.refreshDiagnostics.forcedFlushes + 1
        self:CancelScheduledRefresh(true)
        local pendingReason = self:ConsumePendingReasons(reason or "consumer-state-refresh")
        self.refreshDiagnostics.lastReasons = pendingReason
        self.fullRefreshPending = false
        self.mapRefreshPending = false
        self:ResetRefreshBurst()
        self:Rebuild(pendingReason)
        return true
    end

    if self.mapDirty or self.mapRefreshPending then
        self.refreshDiagnostics.forcedFlushes = self.refreshDiagnostics.forcedFlushes + 1
        self:CancelScheduledRefresh(true)
        local pendingReason = self:ConsumePendingReasons(reason or "consumer-map-refresh")
        self.refreshDiagnostics.lastReasons = pendingReason
        self.mapRefreshPending = false
        self:ResetRefreshBurst()
        self:RebuildMapIndex(pendingReason)
        return true
    end
    return false
end

function QuestCatalog:FlushScheduledRefresh(token)
    if token and token ~= self.refreshToken then
        self.refreshDiagnostics.staleFlushes = self.refreshDiagnostics.staleFlushes + 1
        return
    end

    self.refreshTimer = nil
    self.refreshScheduled = false
    self.refreshScheduledFor = 0

    local doFullRefresh = self.fullRefreshPending
    local doMapRefresh = self.mapRefreshPending
    local reason = self:ConsumePendingReasons("event-coalesced-refresh")
    self.fullRefreshPending = false
    self.mapRefreshPending = false

    local diagnostics = self.refreshDiagnostics
    diagnostics.lastReasons = reason
    self:ResetRefreshBurst()

    if self.refreshing then
        self.fullRefreshPending = doFullRefresh
        self.mapRefreshPending = doMapRefresh and not doFullRefresh
        self.refreshAgain = doFullRefresh or doMapRefresh
        self:AddPendingReason(reason)
        return
    end

    if doFullRefresh then
        self:Rebuild(reason)
    elseif doMapRefresh then
        self:RebuildMapIndex(reason)
    end
end

function QuestCatalog:ScheduleRefresh(reason, fullRefresh)
    if fullRefresh then
        self.stateDirty = true
        self.mapDirty = true
        self.fullRefreshPending = true
        self.mapRefreshPending = false
    elseif not self.fullRefreshPending then
        self.mapDirty = true
        self.mapRefreshPending = true
    end

    self:AddPendingReason(reason)
    self.refreshBurstEventCount = self.refreshBurstEventCount + 1
    local now = GetTime and GetTime() or 0
    if not self.refreshBurstStartedAt then
        self.refreshBurstStartedAt = now
    end

    if self.refreshing then
        self.refreshAgain = true
        self.refreshDiagnostics.coalesced = self.refreshDiagnostics.coalesced + 1
        return
    end

    local delay = GetRefreshDelay(reason, fullRefresh or self.fullRefreshPending)
    local maximumFireTime = self.refreshBurstStartedAt + REFRESH_MAX_DEBOUNCE
    local desiredFireTime = math_min(now + delay, maximumFireTime)
    local desiredDelay = desiredFireTime - now
    if desiredDelay < 0 then
        desiredDelay = 0
    end

    if self.refreshScheduled then
        self.refreshDiagnostics.coalesced = self.refreshDiagnostics.coalesced + 1
        -- Extend the debounce window when useful, but never beyond the hard
        -- maximum. An earlier already-armed refresh is retained when it would
        -- satisfy the current request sooner.
        if desiredFireTime <= self.refreshScheduledFor + 0.001 then
            return
        end
    end

    self:ArmRefreshTimer(desiredDelay)
end

function QuestCatalog:GetRefreshDiagnostics()
    local diagnostics = self.refreshDiagnostics
    return {
        scheduled = diagnostics.scheduled,
        coalesced = diagnostics.coalesced,
        rescheduled = diagnostics.rescheduled,
        cancelled = diagnostics.cancelled,
        staleFlushes = diagnostics.staleFlushes,
        forcedFlushes = diagnostics.forcedFlushes,
        fullRebuilds = diagnostics.fullRebuilds,
        mapRebuilds = diagnostics.mapRebuilds,
        callbackDispatches = diagnostics.callbackDispatches,
        callbackErrors = diagnostics.callbackErrors,
        selectiveCallbackSkips = diagnostics.selectiveCallbackSkips,
        deltaBuilds = diagnostics.deltaBuilds,
        noChangeRebuilds = diagnostics.noChangeRebuilds,
        addedQuests = diagnostics.addedQuests,
        removedQuests = diagnostics.removedQuests,
        progressChanges = diagnostics.progressChanges,
        legacyObjectiveReads = diagnostics.legacyObjectiveReads or 0,
        legacyProgressOverrides = diagnostics.legacyProgressOverrides or 0,
        presentationChanges = diagnostics.presentationChanges,
        classificationChanges = diagnostics.classificationChanges,
        mapChanges = diagnostics.mapChanges,
        structureChanges = diagnostics.structureChanges,
        indexChanges = diagnostics.indexChanges or 0,
        maxBurstEvents = diagnostics.maxBurstEvents,
        lastBurstEvents = diagnostics.lastBurstEvents,
        lastDelay = diagnostics.lastDelay,
        lastReasons = diagnostics.lastReasons,
        refreshScheduled = self.refreshScheduled and true or false,
        fullRefreshPending = self.fullRefreshPending and true or false,
        mapRefreshPending = self.mapRefreshPending and true or false,
        stateRevision = self.stateRevision,
        mapRevision = self.mapRevision,
        structureRevision = self.structureRevision,
        indexRevision = self.indexRevision or 0,
        progressRevision = self.progressRevision,
        presentationRevision = self.presentationRevision,
        classificationRevision = self.classificationRevision,
        projectionRevision = self.consumerRevisions.projection,
        watchRevision = self.consumerRevisions.watch,
        listRevision = self.consumerRevisions.list,
        tooltipRevision = self.consumerRevisions.tooltip,
        mapConsumerRevision = self.consumerRevisions.map,
        routingRevision = self.consumerRevisions.routing,
        revision = self.revision,
    }
end

function QuestCatalog:ResetRefreshDiagnostics()
    local diagnostics = self.refreshDiagnostics
    for key in pairs(diagnostics) do
        if type(diagnostics[key]) == "number" then
            diagnostics[key] = 0
        elseif type(diagnostics[key]) == "string" then
            diagnostics[key] = ""
        end
    end
end

function QuestCatalog:ProcessEvent(event, ...)
    if event == "QUEST_LOG_UPDATE" and self.suppressQuestLogEvents then
        return
    end

    if event == "ZONE_CHANGED" then
        self:ScheduleRefresh(event, false)
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" then
        -- Entering a new map can auto-activate task quests that have no stable
        -- normal quest-log row. Rebuild the live overlay so those records are
        -- added or retired before watch/map consumers render.
        self:ScheduleRefresh(event, true)
        return
    end

    if event == "QUEST_DATA_LOAD_RESULT" then
        local questID, success = ...
        questID = AsPositiveNumber(questID)
        if questID and success then
            self.requestedQuestData[questID] = nil
        end
    end

    self:ScheduleRefresh(event, true)
end

function QuestCatalog:NotifyExternalEvent(event, ...)
    if type(event) ~= "string" then
        return
    end

    self.externalEventStamp[event] = GetTime and GetTime() or 0
    self:ProcessEvent(event, ...)
end

function QuestCatalog:OnEvent(event, ...)
    local stamp = self.externalEventStamp[event]
    if stamp then
        local now = GetTime and GetTime() or stamp
        self.externalEventStamp[event] = nil
        if now - stamp <= 0.25 then
            return
        end
    end
    self:ProcessEvent(event, ...)
end

function QuestCatalog:Initialize()
    if self.initialized then
        return
    end
    self.initialized = true

    local frame = CreateFrame("Frame")
    self.eventFrame = frame
    frame:SetScript("OnEvent", function(_, event, ...)
        QuestCatalog:OnEvent(event, ...)
    end)

    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:RegisterEvent("QUEST_REMOVED")
    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    if C_QuestLog and C_QuestLog.RequestLoadQuestByID then
        frame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    end

    if not IsLoggedIn or IsLoggedIn() then
        self:ScheduleRefresh("catalog-initialize", true)
    end
end


function Nx.Quest:ResolveCatalogQuestID(questID, questLogIndex)
    return QuestCatalog:ResolveQuestID(questID, questLogIndex)
end

function Nx.Quest:GetCatalogQuestTitle(questID, fallbackTitle, questLogIndex)
    local resolvedQuestID = QuestCatalog:ResolveQuestID(questID, questLogIndex)
    return QuestCatalog:GetQuestTitle(resolvedQuestID, fallbackTitle)
end

function Nx.Quest:GetQuestKnowledge(questID)
    return QuestCatalog:GetLegacyQuestData(questID)
end

function Nx.Quest:GetMutableQuestProjection(questID)
    return QuestCatalog:GetMutableLegacyQuestData(questID)
end

function Nx.Quest:GetQuestProjectionFlags(questID)
    return QuestCatalog:GetLegacyPatchFlags(questID)
end

function Nx.Quest:SetQuestProjectionFlags(questID, flags)
    QuestCatalog:SetLegacyPatchFlags(questID, flags)
end

function Nx.Quest:GetCatalogQuestClassification(questID)
    return QuestCatalog:GetQuestClassification(questID)
end

function Nx.Quest:IsCatalogQuestClassification(questID, classification)
    return QuestCatalog:IsQuestClassification(questID, classification)
end

function Nx.Quest:IsCatalogQuestImportantLike(questID)
    return QuestCatalog:IsQuestImportantLike(questID)
end

-- Carbonite integration surface. These methods intentionally return borrowed
-- catalog tables; callers must treat them as read-only and must not retain
-- quest-log indexes across catalog revisions.
function Nx:GetQuestCatalog()
    return QuestCatalog
end

function Nx:GetQuestRecord(questID)
    return QuestCatalog:GetQuestRecord(questID)
end

function Nx:GetQuestIDByLogIndex(questLogIndex, allowAPIFallback)
    return QuestCatalog:GetQuestIDByLogIndex(
        questLogIndex, allowAPIFallback
    )
end

function Nx:GetQuestTitle(questID, fallbackTitle, allowAPIFallback)
    return QuestCatalog:GetQuestTitle(
        questID, fallbackTitle, allowAPIFallback
    )
end

function Nx:GetQuestLevel(questID, allowAPIFallback)
    return QuestCatalog:GetQuestLevel(questID, allowAPIFallback)
end

function Nx:GetQuestFrequency(questID, allowAPIFallback)
    return QuestCatalog:GetQuestFrequency(questID, allowAPIFallback)
end

function Nx:GetQuestObjectives(questID, allowAPIFallback)
    return QuestCatalog:GetQuestObjectives(questID, allowAPIFallback)
end

function Nx:GetQuestObjective(questID, objectiveIndex, allowAPIFallback)
    return QuestCatalog:GetQuestObjective(
        questID, objectiveIndex, allowAPIFallback
    )
end

function Nx:GetQuestLogIndex(questID, allowAPIFallback)
    return QuestCatalog:GetQuestLogIndex(questID, allowAPIFallback)
end

function Nx:GetCurrentQuestLogIndex(questID)
    return QuestCatalog:GetCurrentQuestLogIndex(questID)
end

function Nx:GetQuestFallback(questID)
    return QuestCatalog:GetFallbackQuest(questID)
end

function Nx:GetQuestRecordsForCurrentMap()
    return QuestCatalog:GetQuestRecordsForCurrentMap()
end

function Nx:GetQuestLogQuestCount()
    return QuestCatalog:GetQuestLogQuestCount()
end

function Nx:GetQuestCatalogRefreshDiagnostics()
    return QuestCatalog:GetRefreshDiagnostics()
end

function Nx:GetQuestCatalogDelta()
    return QuestCatalog:GetLastDelta()
end

function Nx:GetQuestCatalogConsumerRevision(consumer)
    return QuestCatalog:GetConsumerRevision(consumer)
end

function Nx:GetVisibleQuestIDs(groupByHeader)
    return QuestCatalog:GetVisibleQuestIDs(groupByHeader)
end

function Nx:GetVisibleQuestRecordByLogIndex(questLogIndex)
    return QuestCatalog:GetQuestRecordByLogIndex(questLogIndex)
end

QuestCatalog:Initialize()
