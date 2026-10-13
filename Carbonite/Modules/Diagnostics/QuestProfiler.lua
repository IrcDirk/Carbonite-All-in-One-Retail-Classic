-- Carbonite | Diagnostics / QuestProfiler
-- Optional bounded profiling for the Carbonite quest and map pipelines.
-- Monitoring is disabled by default and allocates no sample tables while off.
local _G = _G
local Carbonite = _G.Carbonite
local Nx = _G.Nx
if not Carbonite or not Nx then return end
local type = type
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local select = select
local unpack = unpack
local floor = math.floor
local max = math.max
local min = math.min
local format = string.format
local lower = string.lower
local match = string.match
local sub = string.sub
local concat = table.concat
local remove = table.remove
local sort = table.sort
local time = time
local GetTime = GetTime
local CreateFrame = CreateFrame
local DEFAULT_LIMIT = 500
local MIN_LIMIT = 100
local MAX_LIMIT = 1000
local REPORT_SCHEMA = "carbonite-quest-map-profile-v4"
local PROFILE_VERSION = 4
local MIN_ANALYSIS_SAMPLES = 8
local MIN_BASELINE_SAMPLES = 8
local MAX_WINDOW = 8
local Profiler = {
    wrapped = {},
    summaries = {},
    active = false,
    activeScopes = { quest = false, map = false },
    reportScope = "all",
    sampleInterval = 250, -- Milliseconds between retained map samples per boundary.
    slowThreshold = 8, -- Retain slow map calls even inside the sampling interval.
    sessionStarts = 0,
    reportFrame = nil,
    sessionKey = tostring(time and time() or 0) .. ":" .. tostring(GetTime and GetTime() or 0),
}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.QuestProfiler = Profiler
Nx.QuestProfiler = Profiler

local function NormalizeScope(scope)
    return (scope == "quest" or scope == "map") and scope or "all"
end

local function ScopeLabel(scope)
    scope = NormalizeScope(scope)
    return scope == "quest" and "Quest" or scope == "map" and "Map" or "Quest/map"
end

local function ReasonScope(reason)
    if reason:match("^map%-") or reason:match("^travel%-") then return "map" end
    return "quest"
end

local function MatchesScope(reason, scope, entry)
    scope = NormalizeScope(scope)
    if scope == "all" then return true end
    if reason == "manual-mark" then
        return entry and (entry.scope == scope or entry.scope == "all")
    end
    if entry and (entry.scope == "quest" or entry.scope == "map") then
        return entry.scope == scope
    end
    return ReasonScope(reason) == scope
end

local function FilterEntries(entries, scope)
    if NormalizeScope(scope) == "all" then return entries end
    local selected = {}
    for _, entry in ipairs(entries) do
        if MatchesScope(entry.reason or "", scope, entry) then
            selected[#selected + 1] = entry
        end
    end
    return selected
end

local function Catalog()
    return Nx.Quest and Nx.Quest.Catalog
end

local function Pack(...)
    return { n = select("#", ...), ... }
end

local function Trim(text)
    return (tostring(text or ""):match("^%s*(.-)%s*$"))
end

local function Truncate(text, limit)
    text = tostring(text or "")
    if #text > limit then
        return sub(text, 1, limit)
    end
    return text
end

local function SafeNowMS()
    if type(debugprofilestop) == "function" then
        local ok, value = pcall(debugprofilestop)
        if ok and type(value) == "number" then
            return value
        end
    end
    return (GetTime and GetTime() or 0) * 1000
end

local function SafeMemoryKB()
    if type(collectgarbage) ~= "function" then return nil end
    local ok, value = pcall(collectgarbage, "count")
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

local function GetProfileStore()
    local profile = Nx.db and Nx.db.profile
    local debugStore = profile and profile.Debug
    if not debugStore then return nil end
    local store = debugStore.QuestProfiler
    if type(store) ~= "table" then
        store = {}
        debugStore.QuestProfiler = store
    end
    local previousVersion = tonumber(store.version) or 0
    store.enabled = store.enabled == true
    store.limit = min(MAX_LIMIT, max(MIN_LIMIT, tonumber(store.limit) or DEFAULT_LIMIT))
    store.sequence = tonumber(store.sequence) or 0
    store.entries = type(store.entries) == "table" and store.entries or {}
    store.baseline = type(store.baseline) == "table" and store.baseline or nil
    store.baselines = type(store.baselines) == "table" and store.baselines or {}
    if previousVersion < 2 then
        -- v1 stored synthetic zeroes for these metrics. They are unknown, not measurements.
        for _, entry in ipairs(store.entries) do
            if type(entry) == "table" then entry.map, entry.dup = nil, nil end
        end
        store.baseline = nil
    end
    if previousVersion < 4 then store.baseline, store.baselines = nil, {} end
    store.version = PROFILE_VERSION
    return store
end

local function TrimEntriesToLimit(store, targetLimit)
    local entries = store.entries
    targetLimit = max(MIN_LIMIT, min(store.limit, tonumber(targetLimit) or store.limit))
    local excess = #entries - targetLimit
    if excess <= 0 then return end
    local kept, out = {}, 1
    for index = excess + 1, #entries do kept[out], out = entries[index], out + 1 end
    store.entries = kept
end

local function AddBoundedEntry(store, entry)
    store.sequence = store.sequence + 1
    entry.sequence = store.sequence
    store.entries[#store.entries + 1] = entry
    if #store.entries > store.limit then TrimEntriesToLimit(store, floor(store.limit * .9)) end
end

function Profiler:IsEnabled(scope)
    scope = NormalizeScope(scope)
    return scope == "all" and self.active or self.activeScopes[scope] == true
end

function Profiler:SetEnabled(enabled, scope)
    scope = NormalizeScope(scope)
    if scope == "quest" and (type(Nx.Quest) ~= "table" or type(Nx.Quest.RecordQuests) ~= "function") then
        Nx.prt("Quest profiler unavailable: enable Carbonite.Quests.")
        return false
    end
    local store = GetProfileStore()
    if not store then return false end
    self:InstallQuestHooks()
    self:InstallMapHooks()
    enabled = enabled == true
    if scope == "all" then
        self.activeScopes.quest = enabled and type(Nx.Quest) == "table"
            and type(Nx.Quest.RecordQuests) == "function"
        self.activeScopes.map = enabled
    else
        self.activeScopes[scope] = enabled
    end
    self.active = self.activeScopes.quest or self.activeScopes.map
    store.enabled = self.active
    self.sessionStarts = self.sessionStarts + (enabled and 1 or 0)
    Nx.prt("%s profiler: %s", ScopeLabel(scope), enabled and "enabled" or "disabled")
    return enabled
end

function Profiler:SetLimit(value)
    local store = GetProfileStore()
    if not store then return end
    store.limit = min(MAX_LIMIT, max(MIN_LIMIT, floor((tonumber(value) or DEFAULT_LIMIT) + .5)))
    while #store.entries > store.limit do
        remove(store.entries, 1)
    end
    Nx.prt("Quest/map profiler saved-entry limit: %d", store.limit)
end

function Profiler:Record(reason, elapsedMS, memoryKB, mapRefreshes, duplicates, label, scope)
    local store = GetProfileStore()
    if not store or not store.enabled then return end
    AddBoundedEntry(store, {
        reason = Truncate(reason or "event", 48),
        label = label and Truncate(label, 48) or nil,
        scope = scope or ReasonScope(reason or "event"),
        sessionKey = self.sessionKey,
        savedAt = time and time() or 0,
        sessionAt = GetTime and floor(GetTime() * 1000 + .5) or 0,
        ms = tonumber(elapsedMS) or 0,
        memKB = tonumber(memoryKB),
        map = tonumber(mapRefreshes),
        dup = tonumber(duplicates),
    })
end

function Profiler:Mark(label, scope)
    scope = NormalizeScope(scope)
    if not self:IsEnabled(scope) then return false end
    self:Record("manual-mark", 0, nil, nil, nil,
        Trim(label) ~= "" and Trim(label) or nil, scope)
    return true
end

function Profiler:Clear(scope)
    scope = NormalizeScope(scope)
    local store = GetProfileStore()
    if not store then return end
    for reason in pairs(self.summaries) do
        if MatchesScope(reason, scope) then self.summaries[reason] = nil end
    end
    for index = #store.entries, 1, -1 do
        local entry = store.entries[index]
        if entry.reason == "manual-mark" and entry.scope == "all" and scope ~= "all" then
            entry.scope = scope == "quest" and "map" or "quest"
        elseif MatchesScope(entry.reason or "", scope, entry) then
            remove(store.entries, index)
        end
    end
    if scope == "all" then
        store.baseline, store.baselines = nil, {}
        -- Keep sequence monotonic for other saved baseline references.
    else
        store.baselines[scope] = nil
        if store.baseline and store.baseline.boundaries then
            for reason in pairs(store.baseline.boundaries) do
                if MatchesScope(reason, scope) then store.baseline.boundaries[reason] = nil end
            end
        end
    end
    if scope ~= "map" and Catalog() then Catalog():ResetRefreshDiagnostics() end
    Nx.prt("%s profiler saved data cleared", ScopeLabel(scope))
end

-- Timings are inclusive: parent and child durations overlap. No protected
-- Blizzard methods are wrapped. Failed original calls propagate without pcall.

local function MeasureCall(profiler, reason, scope, mapRefreshes, original, ...)
    if not profiler.active or not profiler.activeScopes[scope] then return original(...) end
    local isMap = scope == "map"
    local startMS = SafeNowMS()
    local startMemory = not isMap and SafeMemoryKB() or nil
    local results = Pack(original(...))
    local finishedMS = SafeNowMS()
    local endMemory = not isMap and SafeMemoryKB() or nil
    local elapsedMS = max(0, finishedMS - startMS)
    local summary = profiler.summaries[reason]
    if not summary then
        summary = { calls = 0, totalMS = 0, maxMS = 0, slowCalls = 0,
            samples = 0, lastSampleMS = -math.huge }
        profiler.summaries[reason] = summary
    end
    summary.calls = summary.calls + 1
    summary.totalMS = summary.totalMS + elapsedMS
    summary.maxMS = max(summary.maxMS, elapsedMS)
    if elapsedMS >= profiler.slowThreshold then
        summary.slowCalls = summary.slowCalls + 1
    end
    -- Count every successful call; throttle raw map samples to avoid flooding
    -- the saved-entry buffer. Retain all slow calls within the bounded buffer.
    if not isMap or finishedMS < summary.lastSampleMS
        or finishedMS - summary.lastSampleMS >= profiler.sampleInterval
        or elapsedMS >= profiler.slowThreshold then
        summary.lastSampleMS = finishedMS
        summary.samples = summary.samples + 1
        local memoryDelta = startMemory and endMemory and endMemory - startMemory or nil
        profiler:Record(reason, elapsedMS, memoryDelta, mapRefreshes, nil)
    end
    return unpack(results, 1, results.n)
end

function Profiler:WrapMethod(owner, methodName, reason, mapRefreshes)
    if type(owner) ~= "table" or type(owner[methodName]) ~= "function" then return false end
    local key = tostring(owner) .. ":" .. methodName
    local current = owner[methodName]
    local installed = self.wrapped[key]
    if installed then
        -- Do not stack a second wrapper if another addon replaces our wrapper.
        return installed.wrapper == current
    end
    local original = current
    local scope = ReasonScope(reason)
    local wrapper = function(...) return MeasureCall(Profiler, reason, scope, mapRefreshes, original, ...) end
    owner[methodName] = wrapper
    self.wrapped[key] = { original = original, wrapper = wrapper, reason = reason }
    return true
end

function Profiler:InstallMapHooks()
    local map = Nx.Map
    local names = {
        "MainOnUpdate", "Update", "UpdateAll", "UpdateWorld", "UpdateWorldMap",
        "UpdateIcons", "UpdateTracking", "CalcTracking", "UpdateTargets",
        "DrawTracking", "UpdateZones", "MoveCurZoneTiles", "MoveZoneTiles",
        "UpdateOverlay", "UpdateMiniFrames", "MinimapUpdate",
        "UpdateInstanceMap", "UpdateAreaLabels", "DrawContinentsPOIs",
        "RouteQuests", "Route", "RouteOptimize",
    }
    for _, name in ipairs(names) do
        self:WrapMethod(map, name, "map-" .. name, nil)
    end
    for _, name in ipairs({ "MakePath", "FindConnection", "FindFlight", "FindCrossContinent" }) do
        self:WrapMethod(Nx.Travel, name, "travel-" .. name, nil)
    end
    -- Existing map instances inherit Nx.Map methods in the supplied build.
    -- We deliberately avoid per-icon clipping wrappers: too much observer cost.
    return type(map) == "table"
end

function Profiler:InstallQuestHooks()
    local quest = Nx.Quest
    if type(quest) ~= "table" then return false end
    self:WrapMethod(quest.Catalog, "Rebuild", "catalog-full-rebuild", nil)
    self:WrapMethod(quest.Catalog, "RebuildMapIndex", "catalog-map-rebuild", nil)
    self:WrapMethod(quest, "RecordQuests", "record-quests", nil)
    self:WrapMethod(quest, "RecordQuestsLog", "record-quests-log", nil)
    self:WrapMethod(quest, "UpdateIcons", "quest-icons-update", nil)
    if type(quest.Watch) == "table" then
        self:WrapMethod(quest.Watch, "UpdateList", "watch-list-update", nil)
        self:WrapMethod(quest.Watch, "Update", "watch-update", nil)
    end
    if type(quest.List) == "table" then
        self:WrapMethod(quest.List, "Update", "quest-list-update", nil)
        self:WrapMethod(quest.List, "Refresh", "quest-list-refresh", nil)
    end
    if type(quest.WQList) == "table" then
        self:WrapMethod(quest.WQList, "Update", "world-quest-list-update", nil)
    end
    return true
end

local function GroupMeasuredEntries(entries, newerThan)
    local groups = {}
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and entry.reason and entry.reason ~= "manual-mark"
            and (not newerThan or (tonumber(entry.sequence) or 0) > newerThan) then
            local group = groups[entry.reason]
            if not group then
                group = {}
                groups[entry.reason] = group
            end
            group[#group + 1] = entry
        end
    end
    return groups
end

local function AverageWindow(entries, firstIndex, lastIndex)
    local r = { count=0, ms=0, memKB=0, memCount=0, mapCount=0, dupCount=0 }
    local mapTotal, dupTotal = 0, 0
    for index = firstIndex, lastIndex do
        local e = entries[index]
        if e then
            r.count = r.count + 1; r.ms = r.ms + (tonumber(e.ms) or 0)
            local m = tonumber(e.memKB); if m then r.memKB=r.memKB+m; r.memCount=r.memCount+1 end
            local x = tonumber(e.map); if x then mapTotal=mapTotal+x; r.mapCount=r.mapCount+1 end
            local d = tonumber(e.dup); if d then dupTotal=dupTotal+d; r.dupCount=r.dupCount+1 end
        end
    end
    if r.count == 0 then return nil end
    r.ms=r.ms/r.count; r.memKB=r.memCount>0 and r.memKB/r.memCount or nil
    r.map=r.mapCount>0 and mapTotal/r.mapCount or nil; r.dup=r.dupCount>0 and dupTotal/r.dupCount or nil
    return r
end

local function CompareAverages(previous, recent)
    local flags = {}
    if recent.ms >= previous.ms * 1.5 and recent.ms - previous.ms >= .5 then flags[#flags+1]="duration" end
    if previous.memKB and recent.memKB and recent.memKB-previous.memKB >= 32 then flags[#flags+1]="heap-delta" end
    if previous.dup and recent.dup and recent.dup-previous.dup >= 1 then flags[#flags+1]="duplicates" end
    if previous.map and recent.map and recent.map-previous.map >= .5 then flags[#flags+1]="map-refresh" end
    return #flags > 0 and "watch" or "stable", concat(flags, ",")
end

local function GetEnvironmentInfo()
    local version, build, buildDate, interface = "unknown", "unknown", "unknown", "unknown"
    if type(GetBuildInfo) == "function" then
        local ok,a,b,c,d=pcall(GetBuildInfo); if ok then version,build,buildDate,interface=a or version,b or build,c or buildDate,d or interface end
    end
    return { carboniteBuild=tostring(Nx.BUILD or "unknown"), wowVersion=tostring(version), wowBuild=tostring(build), buildDate=tostring(buildDate), interface=tostring(interface), projectID=tostring(_G.WOW_PROJECT_ID or 0) }
end

local function EnvironmentMatches(a,b)
    if type(a)~="table" or type(b)~="table" then return false end
    return tostring(a.carboniteBuild)==tostring(b.carboniteBuild) and tostring(a.wowBuild)==tostring(b.wowBuild) and tostring(a.interface)==tostring(b.interface) and tostring(a.projectID)==tostring(b.projectID)
end

function Profiler:CaptureBaseline(label, scope)
    scope = NormalizeScope(scope)
    local store = GetProfileStore()
    if not store then return false end
    local current = {}
    for _, entry in ipairs(FilterEntries(store.entries, scope)) do
        if entry.sessionKey == self.sessionKey then current[#current + 1] = entry end
    end
    local groups = GroupMeasuredEntries(current)
    local boundaries = {}
    local count = 0
    for reason, entries in pairs(groups) do
        if #entries >= MIN_BASELINE_SAMPLES then
            local window = min(MAX_WINDOW, #entries)
            boundaries[reason] = AverageWindow(entries, #entries - window + 1, #entries)
            count = count + 1
        end
    end
    if count == 0 then
        Nx.prt("Quest/map profiler baseline requires at least %d samples for one boundary", MIN_BASELINE_SAMPLES)
        return false
    end
    local baseline = {
        schema = REPORT_SCHEMA,
        savedAt = time and time() or 0,
        sequence = store.sequence,
        label = Trim(label) ~= "" and Truncate(Trim(label), 48) or nil,
        build = tostring(Nx.BUILD or "unknown"),
        environment = GetEnvironmentInfo(),
        boundaries = boundaries,
    }
    if scope == "all" then store.baseline = baseline else store.baselines[scope] = baseline end
    Nx.prt("%s profiler baseline captured: %d boundaries", ScopeLabel(scope), count)
    return true
end

function Profiler:ClearBaseline(scope)
    scope = NormalizeScope(scope)
    local store = GetProfileStore()
    if not store then return end
    if scope == "all" then
        store.baseline, store.baselines = nil, {}
    else
        store.baselines[scope] = nil
        if store.baseline and store.baseline.boundaries then
            for reason in pairs(store.baseline.boundaries) do
                if MatchesScope(reason, scope) then store.baseline.boundaries[reason] = nil end
            end
        end
    end
    Nx.prt("%s profiler baseline cleared", ScopeLabel(scope))
end

function Profiler:RunSelfTest()
    local stable, stableFlags = CompareAverages({ ms = 1, memKB = 0, dup = 0, map = 0 }, { ms = 1, memKB = 0, dup = 0, map = 0 })
    local duration = CompareAverages({ ms = 1, memKB = 0, dup = 0, map = 0 }, { ms = 1.6, memKB = 0, dup = 0, map = 0 })
    local absoluteGate = CompareAverages({ ms = .1, memKB = 0, dup = 0, map = 0 }, { ms = .2, memKB = 0, dup = 0, map = 0 })
    local memory = CompareAverages({ ms = 1, memKB = 0, dup = 0, map = 0 }, { ms = 1, memKB = 32, dup = 0, map = 0 })
    local duplicates = CompareAverages({ ms = 1, memKB = 0, dup = 0, map = 0 }, { ms = 1, memKB = 0, dup = 1, map = 0 })
    local mapRefresh = CompareAverages({ ms = 1, memKB = 0, dup = 0, map = 0 }, { ms = 1, memKB = 0, dup = 0, map = .5 })
    local passed = stable == "stable" and stableFlags == ""
        and duration == "watch" and absoluteGate == "stable"
        and memory == "watch" and duplicates == "watch" and mapRefresh == "watch"
    Nx.prt("Quest/map profiler analyzer self-test: %s", passed and "PASS" or "FAIL")
    return passed
end

local function ReportLabel(reason)
    local labels = {
        ["catalog-full-rebuild"] = "Catalog: quest snapshot scan",
        ["catalog-map-rebuild"] = "Catalog: current-map index rebuild",
        ["record-quests"] = "Quest processing",
        ["record-quests-log"] = "Quest log scan",
        ["map-icons-update"] = "Quest icons and objective areas (earlier capture)",
        ["quest-icons-update"] = "Quest icons and objective areas",
        ["catalog-full-rebuild"] = "Quest catalog snapshot",
        ["catalog-map-rebuild"] = "Quest catalog map index",
        ["watch-list-update"] = "Watch list rebuild",
        ["watch-update"] = "Watch window update",
        ["quest-list-update"] = "Quest list update",
        ["quest-list-refresh"] = "Quest list refresh",
        ["world-quest-list-update"] = "World quest list update",
        ["map-MainOnUpdate"] = "Map frame update",
        ["map-Update"] = "Map refresh",
        ["map-UpdateAll"] = "All map views",
        ["map-UpdateWorld"] = "World map content",
        ["map-UpdateWorldMap"] = "Blizzard map integration",
        ["map-UpdateIcons"] = "Map icons",
        ["map-UpdateTracking"] = "Tracking refresh",
        ["map-CalcTracking"] = "Tracking calculation",
        ["map-UpdateTargets"] = "Map target markers",
        ["map-DrawTracking"] = "Tracking drawing",
        ["map-UpdateZones"] = "Zone content",
        ["map-MoveCurZoneTiles"] = "Current zone tiles",
        ["map-MoveZoneTiles"] = "Zone tile movement",
        ["map-UpdateOverlay"] = "Map overlays",
        ["map-UpdateMiniFrames"] = "Minimap frames",
        ["map-MinimapUpdate"] = "Minimap refresh",
        ["map-UpdateInstanceMap"] = "Instance map",
        ["map-UpdateAreaLabels"] = "Area labels",
        ["map-DrawContinentsPOIs"] = "Continent points of interest",
        ["map-RouteQuests"] = "Map quest route",
        ["map-Route"] = "Map route",
        ["map-RouteOptimize"] = "Map route optimization",
        ["travel-MakePath"] = "Travel path calculation",
        ["travel-FindConnection"] = "Travel connection search",
        ["travel-FindFlight"] = "Flight path search",
        ["travel-FindCrossContinent"] = "Cross-continent travel",
    }
    if labels[reason] then return labels[reason] end
    local label = tostring(reason):gsub("^map%-", "Map: "):gsub("^travel%-", "Travel: ")
    return (label:gsub("(%l)(%u)", "%1 %2"))
end

local function FriendlyFlags(flags)
    if flags == "" then return "No threshold exceeded" end
    return (flags:gsub("heap%-delta", "Lua heap change increased")
        :gsub("map%-refresh", "Map refresh count increased")
        :gsub("duplicates", "Duplicate count increased")
        :gsub("duration", "Execution time increased"):gsub(",", "; "))
end

-- Presentation is loaded next from DiagnosticDisplay.lua. Keep data access
-- here so all windows, exports and options use the same scoped measurements.
function Profiler:GetStore()
    return GetProfileStore()
end

function Profiler:ImportEarlierMapCapture()
    local store = GetProfileStore()
    local debugStore = Nx.db and Nx.db.profile and Nx.db.profile.Debug
    local earlier = debugStore and debugStore.MapProfiler
    if not store or store.splitMapImported or type(earlier) ~= "table" then return end
    local ordered = {}
    for _, entry in ipairs(store.entries) do
        ordered[#ordered + 1] = { entry = entry, order = #ordered + 1 }
    end
    for _, entry in ipairs(type(earlier.entries) == "table" and earlier.entries or {}) do
        if type(entry) == "table" then
            local copy = {}
            for key, value in pairs(entry) do copy[key] = value end
            store.sequence = store.sequence + 1
            copy.sequence, copy.scope, copy.sessionKey = store.sequence, "map", nil
            ordered[#ordered + 1] = { entry = copy, order = #ordered + 1 }
        end
    end
    sort(ordered, function(a, b)
        local x, y = tonumber(a.entry.savedAt) or 0, tonumber(b.entry.savedAt) or 0
        if x ~= y then return x < y end
        return a.order < b.order
    end)
    local retained = {}
    for index = max(1, #ordered - store.limit + 1), #ordered do
        retained[#retained + 1] = ordered[index].entry
    end
    store.entries = retained
    if not store.baseline and not store.baselines.map and type(earlier.baseline) == "table" then
        -- Preserve the reference, but its older schema remains visibly incompatible.
        store.baselines.map = earlier.baseline
    end
    store.splitMapImported = true
end

function Profiler:GetEntries(scope, currentSessionOnly)
    local store = GetProfileStore()
    local entries = store and FilterEntries(store.entries, scope) or {}
    if not currentSessionOnly then return entries end
    local current = {}
    for _, entry in ipairs(entries) do
        if entry.sessionKey == self.sessionKey then current[#current + 1] = entry end
    end
    return current
end

function Profiler:GetReasonLabel(reason)
    return ReportLabel(reason)
end

function Profiler:MatchesScope(reason, scope)
    return MatchesScope(reason, scope)
end

function Profiler:GetEnvironment()
    return GetEnvironmentInfo()
end

function Profiler:GetComparison(previous, recent)
    local status, flags = CompareAverages(previous, recent)
    return status, FriendlyFlags(flags)
end

function Profiler:GetSampleGroups(entries, newerThan)
    return GroupMeasuredEntries(entries, newerThan)
end

function Profiler:GetSampleAverage(entries, firstIndex, lastIndex)
    return AverageWindow(entries, firstIndex, lastIndex)
end

function Profiler:IsBaselineCompatible(baseline)
    return type(baseline) == "table" and baseline.schema == REPORT_SCHEMA
        and EnvironmentMatches(baseline.environment, GetEnvironmentInfo())
end

function Profiler:PrintStatus(scope)
    scope = NormalizeScope(scope)
    local store = GetProfileStore()
    if not store then Nx.prt("Profiler store unavailable") return end
    Nx.prt("%s profiler: %s | %d saved samples in this view", ScopeLabel(scope),
        self:IsEnabled(scope) and "enabled" or "disabled", #FilterEntries(store.entries, scope))
    if scope == "all" then
        Nx.prt("Quest: %s | Map: %s", self.activeScopes.quest and "ON" or "OFF",
            self.activeScopes.map and "ON" or "OFF")
    end
end

function Profiler:PrintHelp(scope)
    scope = NormalizeScope(scope)
    local prefix = "/carb profiler " .. (scope == "all" and "" or scope .. " ")
    Nx.prt("|cffffd200%s profiler — capture|r", ScopeLabel(scope))
    Nx.prt("%son / off — start or stop measurements", prefix)
    Nx.prt("%sstatus — monitoring state and saved sample count", prefix)
    Nx.prt("%smark [label] — label a moment while monitoring", prefix)
    Nx.prt("|cffffd200Reports and comparisons|r")
    Nx.prt("%sreport — open the diagnostics overview", prefix)
    Nx.prt("%sexport — open the full report; Select report, then Ctrl+C", prefix)
    Nx.prt("%sbaseline set [label] — save a reference capture", prefix)
    Nx.prt("%sbaseline status / clear — inspect or remove the reference", prefix)
    Nx.prt("|cffffd200Maintenance|r")
    Nx.prt("%sclear — reset this view's samples, timings, and baseline", prefix)
    Nx.prt("/carb profiler limit [100-1000] — shared saved-sample limit")
    Nx.prt("/carb profiler selftest — test the comparison analyzer")
    Nx.prt("Options: Maps > Diagnostics; Quest Module > Diagnostics")
    Nx.prt("Use /carb profiler quest help or map help for a focused command list.")
end

function Profiler:HandleCommand(argument, scope)
    scope = NormalizeScope(scope)
    local command, rest = match(Trim(argument), "^(%S+)%s*(.-)$")
    command, rest = lower(command or "status"), rest or ""
    if command == "quest" or command == "quests" or command == "map" then
        return self:HandleCommand(rest, command == "map" and "map" or "quest")
    elseif command == "on" then self:SetEnabled(true, scope)
    elseif command == "off" then self:SetEnabled(false, scope)
    elseif command == "status" then self:PrintStatus(scope)
    elseif command == "report" or command == "view" then self:OpenReport(scope)
    elseif command == "export" then self:OpenReport(scope, "export")
    elseif command == "clear" then self:Clear(scope)
    elseif command == "mark" then
        if self:Mark(rest, scope) then Nx.prt("Profiler marker saved")
        else Nx.prt("Start monitoring before adding a marker") end
    elseif command == "limit" then self:SetLimit(rest)
    elseif command == "baseline" then
        local subcommand, label = match(rest, "^(%S+)%s*(.-)$")
        subcommand, label = lower(subcommand or "status"), label or ""
        if subcommand == "clear" then self:ClearBaseline(scope)
        elseif subcommand == "status" then
            local store = GetProfileStore()
            local baseline = store and (store.baselines[scope] or store.baseline)
            Nx.prt("%s profiler baseline: %s", ScopeLabel(scope), baseline and "set" or "not set")
        elseif subcommand == "set" then self:CaptureBaseline(label, scope)
        else self:CaptureBaseline(rest, scope) end
    elseif command == "selftest" then self:RunSelfTest()
    else self:PrintHelp(scope) end
    if self.RefreshDisplay then self:RefreshDisplay() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" or addonName == "Carbonite.Quests" or addonName == "Carbonite" then
        Profiler:ImportEarlierMapCapture()
        Profiler:InstallMapHooks()
        Profiler:InstallQuestHooks()
        -- Enablement is per session; reload always starts with monitoring off.
        local store = GetProfileStore()
        if store then store.enabled = Profiler.active end
    end
end)

-- The legacy /carb slash binding calls Nx.slashCommand directly rather than
-- SlashHandler:Dispatch(), so runtime registrations alone are not reachable.
-- Intercept only the profiler subcommand and delegate every other command to
-- the original parser unchanged.
local originalSlashCommand = Nx.slashCommand
if type(originalSlashCommand) == "function" and not Nx._QuestProfilerSlashWrapped then
    Nx.slashCommand = function(text)
        text = Trim(text)
        local command, rest = match(text, "^(%S+)%s*(.-)$")
        if lower(command or "") == "profiler" then
            Profiler:HandleCommand(rest)
            return
        end
        if lower(command or "") == "help" and lower(Trim(rest)) == "profiler" then
            Profiler:PrintHelp()
            return
        end
        return originalSlashCommand(text)
    end
    Nx._QuestProfilerSlashWrapped = true
    -- The slash table is normally assigned later during addon lifecycle, but
    -- update it immediately as well when it already exists (reload/hot-load).
    if type(_G.SlashCmdList) == "table" and _G.SlashCmdList["Carbonite"] == originalSlashCommand then
        _G.SlashCmdList["Carbonite"] = Nx.slashCommand
    end
end
local slashHandler = Carbonite.Modules and Carbonite.Modules.SlashHandler
if slashHandler and slashHandler.Register then
    slashHandler:Register("profiler", function(rest) Profiler:HandleCommand(rest) end, "control quest and map profiling")
end
if Carbonite.Core and Carbonite.Core.SlashCommands and Carbonite.Core.SlashCommands.Register then
    Carbonite.Core.SlashCommands:Register("profiler", function(rest) Profiler:HandleCommand(rest) end, "control quest and map profiling")
end
