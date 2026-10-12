-- Loaded last by every Carbonite.Quests client TOC.
-- Integrated quest/map diagnostic component for v12.1.0-00020.
-- /carb profiler on | off | clear | baseline set [label] | report | selftest
-- Raw samples/baselines persist in Nx.db.profile.Debug.QuestProfiler.
-- Session summaries reset on reload; profiling always starts disabled.
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

local insert = table.insert
local remove = table.remove
local sort = table.sort

local time = time

local GetTime = GetTime

local CreateFrame = CreateFrame

local UIParent = UIParent

local DEFAULT_LIMIT = 500

local MIN_LIMIT = 100

local MAX_LIMIT = 1000

local REPORT_SCHEMA = "carbonite-quest-map-profile-v3"

local PROFILE_VERSION = 3

local MIN_ANALYSIS_SAMPLES = 8

local MIN_BASELINE_SAMPLES = 8

local MAX_WINDOW = 8

local Profiler = {

    wrapped = {},
    summaries = {},
    active = false,
    sampleInterval = 250, -- Milliseconds between retained map samples per boundary.
    slowThreshold = 8, -- Retain slow map calls even inside the sampling interval.

    sessionStarts = 0,

    reportFrame = nil,

}

Carbonite.Modules = Carbonite.Modules or {}

Carbonite.Modules.QuestProfiler = Profiler

Nx.QuestProfiler = Profiler

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

    if type(collectgarbage) ~= "function" then return 0 end

    local ok, value = pcall(collectgarbage, "count")

    if ok and type(value) == "number" then

        return value

    end

    return 0

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

    if previousVersion < 2 then
        -- v1 stored synthetic zeroes for these metrics. They are unknown, not measurements.
        for _, entry in ipairs(store.entries) do
            if type(entry) == "table" then entry.map, entry.dup = nil, nil end
        end
        store.baseline = nil
    end
    if previousVersion < 3 then store.baseline = nil end
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

function Profiler:IsEnabled()

    local store = GetProfileStore()

    return self.active == true

end

function Profiler:SetEnabled(enabled)

    local store = GetProfileStore()

    if not store then return false end

    self:InstallQuestHooks()
    self:InstallMapHooks()
    store.enabled = enabled == true
    self.active = store.enabled

    self.sessionStarts = self.sessionStarts + (store.enabled and 1 or 0)

    Nx.prt("Quest/map profiler: %s", store.enabled and "enabled" or "disabled")

    return store.enabled

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

function Profiler:Record(reason, elapsedMS, memoryKB, mapRefreshes, duplicates, label)

    local store = GetProfileStore()

    if not store or not store.enabled then return end

    AddBoundedEntry(store, {

        reason = Truncate(reason or "event", 48),

        label = label and Truncate(label, 48) or nil,

        savedAt = time and time() or 0,

        sessionAt = GetTime and floor(GetTime() * 1000 + .5) or 0,

        ms = tonumber(elapsedMS) or 0,

        memKB = tonumber(memoryKB),

        map = tonumber(mapRefreshes),

        dup = tonumber(duplicates),

    })

end

function Profiler:Mark(label)

    self:Record("manual-mark", 0, 0, 0, 0, Trim(label) ~= "" and Trim(label) or nil)

end

function Profiler:Clear()

    local store = GetProfileStore()

    if not store then return end

    self.summaries = {}
    store.entries = {}

    store.sequence = 0

    store.baseline = nil

    Nx.prt("Quest/map profiler saved data cleared")

end

-- Timings are inclusive: parent and child durations overlap. No protected
-- Blizzard methods are wrapped. Failed original calls propagate without pcall.
local function MeasureCall(profiler, reason, mapRefreshes, original, ...)
    if not profiler.active then return original(...) end
    local isMap = reason:match("^map%-") or reason:match("^travel%-")
    local startMS = SafeNowMS()
    local startMemory = not isMap and SafeMemoryKB() or nil
    local results = Pack(original(...))
    local finishedMS = SafeNowMS()
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
        profiler:Record(reason, elapsedMS,
            startMemory and SafeMemoryKB() - startMemory or nil, mapRefreshes, nil)
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
    local wrapper = function(...) return MeasureCall(Profiler, reason, mapRefreshes, original, ...) end
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

    self:WrapMethod(quest, "RecordQuests", "record-quests", nil)

    self:WrapMethod(quest, "RecordQuestsLog", "record-quests-log", nil)

    self:WrapMethod(quest, "UpdateIcons", "map-icons-update", nil)

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

function Profiler:CaptureBaseline(label)

    local store = GetProfileStore()

    if not store then return false end

    local groups = GroupMeasuredEntries(store.entries)

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

    store.baseline = {

        schema = REPORT_SCHEMA,

        savedAt = time and time() or 0,

        sequence = store.sequence,

        label = Trim(label) ~= "" and Truncate(Trim(label), 48) or nil,

        build = tostring(Nx.BUILD or "unknown"),

        environment = GetEnvironmentInfo(),

        boundaries = boundaries,

    }

    Nx.prt("Quest/map profiler baseline captured: %d boundaries", count)

    return true

end

function Profiler:ClearBaseline()

    local store = GetProfileStore()

    if store then store.baseline = nil end

    Nx.prt("Quest/map profiler baseline cleared")

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

local function FormatMetric(value, decimals)
    if type(value) ~= "number" then return "n/a" end
    return format("%." .. tostring(decimals or 2) .. "f", value)
end

local function ReportLabel(reason)
    local labels = {
        ["record-quests"] = "Quest processing",
        ["record-quests-log"] = "Quest log scan",
        ["map-icons-update"] = "Quest icons and objective areas",
        ["watch-list-update"] = "Watch list rebuild",
        ["watch-update"] = "Watch window update",
        ["quest-list-update"] = "Quest list update",
        ["quest-list-refresh"] = "Quest list refresh",
        ["world-quest-list-update"] = "World quest list update",
    }
    if labels[reason] then return labels[reason] end
    local label = tostring(reason):gsub("^map%-", "Map: "):gsub("^travel%-", "Travel: ")
    return (label:gsub("(%l)(%u)", "%1 %2"))
end

local function SortedKeys(values)
    local keys = {}
    for key in pairs(values) do keys[#keys + 1] = key end
    sort(keys)
    return keys
end

local function FriendlyFlags(flags)
    if flags == "" then return "No threshold exceeded" end
    return (flags:gsub("heap%-delta", "Lua heap change increased")
        :gsub("map%-refresh", "Map refresh count increased")
        :gsub("duplicates", "Duplicate count increased")
        :gsub("duration", "Execution time increased"):gsub(",", "; "))
end

function Profiler:BuildReport()
    local store = GetProfileStore()
    if not store then return "Carbonite profiler: saved-data store unavailable." end
    local lines = {}
    local function Add(text) lines[#lines + 1] = text or "" end
    local function Section(title) Add(); Add(title); Add() end
    local environment = GetEnvironmentInfo()
    local reasons = SortedKeys(self.summaries)
    sort(reasons, function(a, b)
        local x, y = self.summaries[a], self.summaries[b]
        if x.maxMS == y.maxMS then return a < b end
        return x.maxMS > y.maxMS
    end)
    local calls, slow = 0, 0
    for _, reason in ipairs(reasons) do
        local summary = self.summaries[reason]
        calls, slow = calls + summary.calls, slow + summary.slowCalls
    end
    Add("CARBONITE QUEST AND MAP PROFILER")
    Add("Report format: 4 | Measurement schema: " .. REPORT_SCHEMA)
    Section("SUMMARY")
    Add("Monitoring: " .. (self.active and "ON" or "OFF"))
    Add(format("Saved samples: %d of %d maximum", #store.entries, store.limit))
    Add(format("Current session: %d measured function calls; %d slow calls (at least %d ms)", calls, slow, self.slowThreshold))
    Add("Counts include nested functions; they are not frame counts.")
    if #reasons > 0 then
        local worst = self.summaries[reasons[1]]
        Add(format("Largest observed call: %s — %.3f ms", ReportLabel(reasons[1]), worst.maxMS))
        Add("Start with the largest calls below; a slow call alone does not prove the cause of stuttering.")
    else
        Add("No calls measured this session. Run /carb profiler on, reproduce the issue, then turn it off.")
        if #store.entries > 0 then Add("Saved samples below may be from an earlier session.") end
    end
    Section("CLIENT AND BUILD")
    Add("Carbonite: " .. environment.carboniteBuild)
    Add(format("WoW: %s | Build: %s | Interface: %s | Project ID: %s",
        environment.wowVersion, environment.wowBuild, environment.interface, environment.projectID))
    Add("Client build date: " .. environment.buildDate)
    Section("FUNCTION TIMINGS — largest single calls first")
    Add("All durations are milliseconds (ms). Parent timings include child calls; do not add them together.")
    Add("Session totals accumulate since reload or /carb profiler clear, across on/off captures.")
    for index, reason in ipairs(reasons) do
        local summary = self.summaries[reason]
        Add()
        Add(format("%d. %s [%s]", index, ReportLabel(reason), reason))
        Add(format("   Calls: %d | Average: %.3f ms | Maximum: %.3f ms | Slow calls: %d",
            summary.calls, summary.totalMS / summary.calls, summary.maxMS, summary.slowCalls))
        Add(format("   Inclusive total: %.3f ms | Samples recorded: %d (older samples may have expired)",
            summary.totalMS, summary.samples))
    end
    if #reasons == 0 then Add("No current-session timing totals available.") end
    local groups = GroupMeasuredEntries(store.entries)
    local function Comparison(reason, prior, recent, context)
        local status, flags = CompareAverages(prior, recent)
        Add()
        Add(ReportLabel(reason) .. " [" .. reason .. "]")
        Add("   Result: " .. (status == "watch" and "REVIEW" or "WITHIN THRESHOLDS") .. " — " .. FriendlyFlags(flags))
        Add(format("   %s: %s ms -> %s ms | Change: %+.3f ms",
            context, FormatMetric(prior.ms, 3), FormatMetric(recent.ms, 3), recent.ms - prior.ms))
        if prior.ms > 0 then Add(format("   Relative timing change: %+.1f%%", (recent.ms / prior.ms - 1) * 100)) end
        if prior.memKB and recent.memKB then
            Add(format("   Average Lua heap change: %.2f KB -> %.2f KB (shared heap, not allocations)", prior.memKB, recent.memKB))
        end
    end
    Section("RECENT SAMPLE COMPARISON")
    Add("Compares adjacent sample windows. Map samples favor slow calls, so these are not session-wide averages.")
    local analyzed = 0
    for _, reason in ipairs(SortedKeys(groups)) do
        local entries = groups[reason]
        if #entries >= MIN_ANALYSIS_SAMPLES then
            local window = min(MAX_WINDOW, floor(#entries / 2))
            Comparison(reason, AverageWindow(entries, #entries - window * 2 + 1, #entries - window),
                AverageWindow(entries, #entries - window + 1, #entries), "Previous -> recent")
            Add(format("   Samples in each window: %d", window))
            analyzed = analyzed + 1
        else
            Add(format("%s: need %d saved samples; have %d.", ReportLabel(reason), MIN_ANALYSIS_SAMPLES, #entries))
        end
    end
    if analyzed == 0 then Add("Not enough saved samples for a recent-window comparison.") end
    Section("BASELINE COMPARISON")
    local baseline = store.baseline
    if type(baseline) ~= "table" or type(baseline.boundaries) ~= "table" then
        Add("No baseline saved. After an idle capture, run /carb profiler baseline set idle.")
    elseif not EnvironmentMatches(baseline.environment, environment) then
        Add("Comparison skipped: baseline was captured on a different or unidentified build.")
        Add("Clear and recapture a baseline on this client before comparing results.")
    else
        Add("Baseline: " .. tostring(baseline.label or "Unlabelled"))
        local newer = GroupMeasuredEntries(store.entries, tonumber(baseline.sequence) or 0)
        for _, reason in ipairs(SortedKeys(baseline.boundaries)) do
            local entries = newer[reason] or {}
            if #entries >= MIN_BASELINE_SAMPLES then
                local window = min(MAX_WINDOW, #entries)
                Comparison(reason, baseline.boundaries[reason], AverageWindow(entries, #entries - window + 1, #entries), "Baseline -> current")
                Add(format("   Current window: %d samples", window))
            else
                Add(format("%s: need %d new samples after baseline; have %d.", ReportLabel(reason), MIN_BASELINE_SAMPLES, #entries))
            end
        end
    end
    Section("HOW TO READ THESE RESULTS")
    Add("REVIEW means a comparison threshold was exceeded; it is a diagnostic lead, not a confirmed fault.")
    Add("WITHIN THRESHOLDS means no comparison threshold was exceeded; it does not guarantee smooth frames.")
    Add("Timing threshold: at least 50% AND 0.5 ms increase. Lua heap threshold: +32 KB.")
    Add(format("Map/travel raw samples: one per function per %d ms, plus every call lasting at least %d ms.", self.sampleInterval, self.slowThreshold))
    Add("Every successful wrapped call contributes to session timing totals. Failed calls are not sampled.")
    Add("Lua timings do not measure GPU frame time. Profiling itself adds overhead while enabled.")
    Add("Map/travel memory, refresh counts, and duplicate counts are not measured.")
    Add("Saved samples and baselines persist. Session timing totals reset on reload or clear.")
    Section("INSTALLED MEASUREMENTS")
    local hooks = {}
    for _, hook in pairs(self.wrapped) do hooks[#hooks + 1] = hook.reason end
    sort(hooks)
    for _, reason in ipairs(hooks) do Add("- " .. ReportLabel(reason) .. " [" .. reason .. "]") end
    if #hooks == 0 then Add("None installed.") end
    Section("RAW SAMPLES — technical detail")
    Add("Sequence | Session time (ms) | Function | Duration (ms) | Lua heap change (KB)")
    for _, entry in ipairs(store.entries) do
        Add(format("%d | %d | %s | %s | %s%s", tonumber(entry.sequence) or 0,
            tonumber(entry.sessionAt) or 0, tostring(entry.reason or "unknown"),
            FormatMetric(tonumber(entry.ms), 3), FormatMetric(tonumber(entry.memKB), 2),
            entry.label and " | Marker: " .. entry.label or ""))
    end
    Add()
    Add("Validation status: in-game validation required.")
    Add("END OF REPORT")
    return concat(lines, "\n")
end

function Profiler:OpenReport()

    if self.reportFrame then

        self.reportFrame:Show()

        self.reportFrame.editBox:SetText(self:BuildReport())

        self.reportFrame.editBox:HighlightText()

        return

    end

    local template = _G.BackdropTemplateMixin and "BackdropTemplate" or nil

    local frame = CreateFrame("Frame", "NxOriginalQuestProfilerReportFrame", UIParent, template)

    frame:SetSize(800, 590)

    frame:SetPoint("CENTER")

    frame:SetFrameStrata("DIALOG")

    frame:SetClampedToScreen(true)

    frame:SetMovable(true)

    frame:EnableMouse(true)

    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)

    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    if frame.SetBackdrop then

        frame:SetBackdrop({

            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",

            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",

            tile = true, tileSize = 32, edgeSize = 32,

            insets = { left = 8, right = 8, top = 8, bottom = 8 },

        })

    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

    title:SetPoint("TOPLEFT", 18, -16)

    title:SetText("Carbonite Quest and Map Profiling Report")

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")

    scroll:SetPoint("TOPLEFT", 18, -48)

    scroll:SetPoint("BOTTOMRIGHT", -38, 54)

    local edit = CreateFrame("EditBox", nil, scroll)

    edit:SetMultiLine(true)

    edit:SetAutoFocus(false)

    edit:SetFontObject(_G.ChatFontNormal or _G.GameFontHighlightSmall)

    edit:SetWidth(720)

    edit:SetScript("OnEscapePressed", function() frame:Hide() end)

    scroll:SetScrollChild(edit)

    local selectAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")

    selectAll:SetSize(92, 22)

    selectAll:SetPoint("BOTTOMLEFT", 18, 16)

    selectAll:SetText("Select All")

    selectAll:SetScript("OnClick", function() edit:SetFocus(); edit:HighlightText() end)

    local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")

    refresh:SetSize(92, 22)

    refresh:SetPoint("LEFT", selectAll, "RIGHT", 8, 0)

    refresh:SetText("Refresh")

    refresh:SetScript("OnClick", function() edit:SetText(Profiler:BuildReport()); edit:HighlightText() end)

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")

    close:SetSize(80, 22)

    close:SetPoint("BOTTOMRIGHT", -18, 16)

    close:SetText("Close")

    close:SetScript("OnClick", function() frame:Hide() end)

    frame.editBox = edit

    frame:SetScript("OnShow", function() edit:SetText(Profiler:BuildReport()) end)

    self.reportFrame = frame

    if type(_G.UISpecialFrames) == "table" then

        _G.UISpecialFrames[#_G.UISpecialFrames + 1] = frame:GetName()

    end

    frame:Show()

    edit:SetText(self:BuildReport())

    edit:SetFocus()

    edit:HighlightText()

end

function Profiler:PrintStatus()

    local store = GetProfileStore()

    if not store then

        Nx.prt("Quest/map profiler store unavailable")

        return

    end

    Nx.prt("Quest/map profiler: %s, entries %d/%d, baseline %s",

        store.enabled and "enabled" or "disabled", #store.entries, store.limit,

        store.baseline and "set" or "not set")

end

function Profiler:HandleCommand(argument)

    argument = Trim(argument)

    local command, rest = match(argument, "^(%S+)%s*(.-)$")

    command = lower(command or "status")

    if command == "on" then

        self:SetEnabled(true)

    elseif command == "off" then

        self:SetEnabled(false)

    elseif command == "status" then

        self:PrintStatus()

    elseif command == "report" or command == "export" then

        self:OpenReport()

    elseif command == "clear" then

        self:Clear()

    elseif command == "mark" then

        self:Mark(rest)

        Nx.prt("Quest/map profiler mark saved")

    elseif command == "limit" then

        self:SetLimit(rest)

    elseif command == "baseline" then

        local subcommand, label = match(rest, "^(%S+)%s*(.-)$")

        subcommand = lower(subcommand or "status")

        if subcommand == "clear" then

            self:ClearBaseline()

        elseif subcommand == "status" then

            local store = GetProfileStore()

            Nx.prt("Quest/map profiler baseline: %s", store and store.baseline and "set" or "not set")

        elseif subcommand == "set" then

            self:CaptureBaseline(label)

        else

            self:CaptureBaseline(rest)

        end

    elseif command == "selftest" then

        self:RunSelfTest()

    else

        Nx.prt("Usage: /carb profiler on|off|status|report|export|clear|mark [label]|limit [100-1000]|baseline [set|status|clear] [label]|selftest")

    end

end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, addonName)

    if event == "PLAYER_LOGIN" or addonName == "Carbonite.Quests" or addonName == "Carbonite" then

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
