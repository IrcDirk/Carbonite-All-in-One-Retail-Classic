-- Carbonite diagnostics presentation. Reads snapshots on demand; no update
-- loop, quest API scans, or timing hooks belong in this file.
local Carbonite, Nx = _G.Carbonite, _G.Nx
local Profiler = Nx and Nx.QuestProfiler
if not Carbonite or not Profiler then return end

local format, concat = string.format, table.concat
local min, max, floor = math.min, math.max, math.floor
local MIN_SAMPLES, MAX_WINDOW = 8, 8
local PRIMARY = { .94, .95, .97 }
local SECONDARY = { .72, .77, .83 }
local ACCENT = { .45, .76, 1 }
local REVIEW = { 1, .80, .43 }
local FRAME_WIDTH, FRAME_HEIGHT = 850, 650
local CONTENT_WIDTH = FRAME_WIDTH - 74

local function Scope(scope)
    return (scope == "map" or scope == "quest") and scope or "all"
end

local function Label(scope)
    return scope == "map" and "Map" or scope == "quest" and "Quest" or "Map and Quest"
end

local function Prefix(scope)
    return "/carb profiler " .. (scope == "all" and "" or scope .. " ")
end

local function Number(value, decimals)
    if type(value) ~= "number" then return "Not available" end
    return format("%." .. (decimals or 0) .. "f", value)
end

local function Stamp()
    return type(_G.date) == "function" and _G.date("%H:%M:%S") or "now"
end

local function RefreshOptions()
    local options = Carbonite.GetModule and Carbonite:GetModule("Options", true)
        or Carbonite.Modules.Options
    if options and options.Refresh then options:Refresh() end
end

local function Available(scope)
    return scope ~= "quest" or (type(Nx.Quest) == "table" and type(Nx.Quest.RecordQuests) == "function")
end

local function AddComparison(rows, reason, prior, recent, count, needed)
    local row = {
        reason = reason, label = Profiler:GetReasonLabel(reason),
        count = count, needed = needed,
    }
    if prior and recent then
        row.previous, row.current = prior.ms, recent.ms
        row.previousHeap, row.currentHeap = prior.memKB, recent.memKB
        row.change = recent.ms - prior.ms
        row.percent = prior.ms > 0 and (recent.ms / prior.ms - 1) * 100 or nil
        row.status, row.explanation = Profiler:GetComparison(prior, recent)
        row.samples = recent.count
    else
        row.status = "waiting"
        row.explanation = format("Waiting for samples: %d of %d.", count, needed)
    end
    rows[#rows + 1] = row
end

local function SortComparisons(rows)
    local rank = { watch = 1, stable = 2, waiting = 3 }
    table.sort(rows, function(a, b)
        if rank[a.status] ~= rank[b.status] then return rank[a.status] < rank[b.status] end
        if (a.change or 0) ~= (b.change or 0) then return (a.change or 0) > (b.change or 0) end
        return a.reason < b.reason
    end)
end

function Profiler:GetSnapshot(scope)
    scope = Scope(scope)
    local store = self:GetStore()
    local data = {
        scope = scope, label = Label(scope), updated = Stamp(),
        available = Available(scope) and store ~= nil,
        recording = self:IsEnabled(scope), rows = {}, recent = {}, baselineRows = {},
        calls = 0, slowCalls = 0, samples = 0, currentSamples = 0,
        retained = store and #store.entries or 0, limit = store and store.limit or 500,
        peak = nil, baselineState = "none", baselineReady = false,
        mapRecording = self:IsEnabled("map"), questRecording = self:IsEnabled("quest"),
        questAvailable = Available("quest"),
    }
    if not data.available then
        data.nextStep = scope == "quest" and "Enable Carbonite.Quests to collect quest measurements."
            or "Wait for Carbonite to finish loading, then refresh."
        return data
    end
    for reason, summary in pairs(self.summaries) do
        if self:MatchesScope(reason, scope) and summary.calls > 0 then
            local row = {
                reason = reason, label = self:GetReasonLabel(reason),
                calls = summary.calls, average = summary.totalMS / summary.calls,
                peak = summary.maxMS, slowCalls = summary.slowCalls,
                total = summary.totalMS, samples = summary.samples,
            }
            data.rows[#data.rows + 1] = row
            data.calls = data.calls + row.calls
            data.slowCalls = data.slowCalls + row.slowCalls
        end
    end
    table.sort(data.rows, function(a, b)
        if a.peak ~= b.peak then return a.peak > b.peak end
        return a.reason < b.reason
    end)
    data.peak = data.rows[1] and data.rows[1].peak or nil
    data.entries = {}
    for _, entry in ipairs(self:GetEntries(scope)) do data.entries[#data.entries + 1] = entry end
    data.samples = #data.entries
    local current = self:GetEntries(scope, true)
    data.currentSamples = #current
    local groups = self:GetSampleGroups(current)
    for reason, entries in pairs(groups) do
        if #entries >= MIN_SAMPLES then
            data.baselineReady = true
            local window = min(MAX_WINDOW, floor(#entries / 2))
            AddComparison(data.recent, reason,
                self:GetSampleAverage(entries, #entries - 2 * window + 1, #entries - window),
                self:GetSampleAverage(entries, #entries - window + 1, #entries),
                #entries, MIN_SAMPLES)
        else
            AddComparison(data.recent, reason, nil, nil, #entries, MIN_SAMPLES)
        end
    end
    SortComparisons(data.recent)
    local baseline = store.baselines[scope] or store.baseline
    data.separateReferences = scope == "all" and (store.baselines.quest or store.baselines.map) ~= nil
    if type(baseline) == "table" and type(baseline.boundaries) == "table" then
        data.baselineLabel = tostring(baseline.label or "Idle reference")
        data.baselineState = self:IsBaselineCompatible(baseline) and "ready" or "incompatible"
        if data.baselineState == "ready" then
            local newer = self:GetSampleGroups(current, tonumber(baseline.sequence) or 0)
            for reason, previous in pairs(baseline.boundaries) do
                if self:MatchesScope(reason, scope) then
                    local entries = newer[reason] or {}
                    local window = min(MAX_WINDOW, #entries)
                    local recent = #entries >= MIN_SAMPLES
                        and self:GetSampleAverage(entries, #entries - window + 1, #entries) or nil
                    AddComparison(data.baselineRows, reason, previous, recent, #entries, MIN_SAMPLES)
                end
            end
            SortComparisons(data.baselineRows)
            if #data.baselineRows == 0 then data.baselineState = "none" end
        end
    end
    local catalog = scope ~= "map" and Nx.Quest and Nx.Quest.Catalog
    if catalog and catalog.GetRefreshDiagnostics then
        data.catalog = catalog:GetRefreshDiagnostics()
        data.questCount = catalog:GetQuestLogQuestCount()
        data.displayCount = #catalog:GetVisibleQuestIDs()
        data.activeCount = #catalog:GetActiveQuestIDs()
    end
    if data.catalog and data.catalog.callbackErrors > 0 then
        data.nextStep = "The quest catalog recorded callback errors. Select the report and include your error log."
    elseif data.calls == 0 then
        data.nextStep = data.recording
            and "Reproduce the issue, then stop recording and refresh this snapshot."
            or "Start recording, reproduce the issue for about 60 seconds, then stop recording."
    elseif data.baselineRows[1] and data.baselineRows[1].status == "watch" then
        data.nextStep = "Review the increases on the Compare tab, then select the report to share the evidence."
    elseif data.recent[1] and data.recent[1].status == "watch" then
        data.nextStep = "A recent sample window increased. Open Compare to review the measured change."
    elseif data.slowCalls > 0 then
        data.nextStep = "Review the largest calls on the Functions tab. Their timings are leads for further investigation."
    else
        data.nextStep = "Review Functions or save an idle reference before reproducing the issue again."
    end
    return data
end

local function BaselineText(data)
    if data.baselineState == "none" and data.separateReferences then
        return "Choose Map or Quest to review its separately saved idle reference."
    end
    if data.baselineState == "incompatible" then
        return "Reference skipped: different client or addon build. Save a new idle reference."
    elseif data.baselineState == "ready" then
        return "Saved reference: " .. data.baselineLabel
    end
    return "No idle reference saved. Record an idle period first."
end

local function StateText(data)
    if not data.available then return "Unavailable" end
    if data.scope == "all" then
        return "Map: " .. (data.mapRecording and "Recording" or "Stopped")
            .. "   |   Quest: " .. (not data.questAvailable and "Unavailable"
                or data.questRecording and "Recording" or "Stopped")
    end
    return data.recording and "Recording" or "Stopped"
end

function Profiler:BuildReport(scope, snapshot)
    local data = snapshot or self:GetSnapshot(scope)
    local lines = {}
    local function Add(text) lines[#lines + 1] = text or "" end
    local function Section(title) Add(); Add(title); Add() end
    Add("CARBONITE " .. string.upper(data.label) .. " DIAGNOSTICS")
    Add("Snapshot: " .. data.updated .. " | Report format: 6")
    Section("OVERVIEW")
    Add("Recording state: " .. StateText(data))
    if not data.available then Add(data.nextStep); return concat(lines, "\n") end
    Add("Measured function calls this session: " .. data.calls)
    Add(format("Slow calls (at least %d ms): %d", self.slowThreshold, data.slowCalls))
    Add("Largest single call: " .. (data.peak and Number(data.peak, 3) .. " ms" or "Not measured yet"))
    Add(format("Retained samples in this view: %d (%d from this session)", data.samples, data.currentSamples))
    Add(format("Shared storage: %d of %d samples", data.retained, data.limit))
    Add("Next step: " .. data.nextStep)
    Add("Session totals cover all successful wrapped calls since reload or clear.")
    Add("Parent calls include child work. Calls and durations must not be added as frame totals.")
    if data.catalog then
        Section("QUEST CATALOG — since reload or quest data reset")
        Add("Quests in log: " .. Number(data.questCount))
        Add("Display records: " .. data.displayCount .. " | Active records including map tasks: " .. data.activeCount)
        local fields = {
            { "Full quest scans", "fullRebuilds" }, { "Map index scans", "mapRebuilds" },
            { "Scans with no changes", "noChangeRebuilds" },
            { "Refresh requests scheduled", "scheduled" }, { "Refresh requests combined", "coalesced" },
            { "Refreshes forced by a display read", "forcedFlushes" },
            { "Quests added", "addedQuests" }, { "Quests removed", "removedQuests" },
            { "Objective progress changes", "progressChanges" },
            { "Consumer callbacks", "callbackDispatches" }, { "Unchanged consumers skipped", "selectiveCallbackSkips" },
            { "Callback errors", "callbackErrors" }, { "Legacy objective checks", "legacyObjectiveReads" },
            { "Progress corrections", "legacyProgressOverrides" },
        }
        for _, field in ipairs(fields) do Add(field[1] .. ": " .. Number(data.catalog[field[2]])) end
        Add("Catalog activity is counted even while optional timing capture is stopped.")
    end
    Section("FUNCTION TIMINGS — largest single calls first")
    for index, row in ipairs(data.rows) do
        Add(format("%d. %s", index, row.label))
        Add(format("   Calls: %d | Average: %.3f ms | Largest: %.3f ms | Slow: %d",
            row.calls, row.average, row.peak, row.slowCalls))
        Add(format("   Inclusive total: %.3f ms | Samples recorded: %d", row.total, row.samples))
        Add("   Function key: " .. row.reason)
        Add()
    end
    if #data.rows == 0 then Add("No calls measured this session. Earlier saved samples are separate from session totals.") end
    local function Comparisons(title, rows)
        Section(title)
        for _, row in ipairs(rows) do
            Add(row.label)
            if row.status == "waiting" then
                Add("   " .. row.explanation)
            else
                Add("   " .. (row.status == "watch" and "REVIEW INCREASE" or "WITHIN COMPARISON THRESHOLDS"))
                Add(format("   Average: %.3f ms -> %.3f ms | Change: %+.3f ms",
                    row.previous, row.current, row.change))
                Add("   Relative change: " .. (row.percent and format("%+.1f%%", row.percent) or "Not defined (reference is zero)"))
                Add("   " .. row.explanation .. " | Samples per current window: " .. row.samples)
                if row.previousHeap and row.currentHeap then
                    Add(format("   Average shared Lua heap change: %.2f KB -> %.2f KB", row.previousHeap, row.currentHeap))
                end
            end
            Add()
        end
        if #rows == 0 then Add("No comparable measurements available yet.") end
    end
    Comparisons("IDLE REFERENCE COMPARISON", data.baselineRows)
    Add(BaselineText(data))
    Comparisons("RECENT SAMPLE COMPARISON", data.recent)
    Section("READING THE RESULTS")
    Add("Review increase is a diagnostic lead, not a confirmed fault.")
    Add("Within comparison thresholds does not guarantee smooth frames.")
    Add("Timing comparison: at least 50% AND 0.5 ms increase; shared Lua heap change: +32 KB.")
    Add("Adjacent recent windows need 8 samples total. An idle reference needs 8 samples for at least one function.")
    Add("Reference comparison needs 8 NEW samples per function after the reference is saved.")
    Add("Comparisons use this session's retained samples. Timing totals include calls whose raw samples expired.")
    Add(format("Map samples are retained at most once per function per %d ms, plus every call of at least %d ms.",
        self.sampleInterval, self.slowThreshold))
    Add("Map samples favor slow calls; sample averages are not whole-session averages.")
    Add("Lua timings do not measure GPU frame time. Optional profiling adds measurement overhead.")
    Add("Map/travel heap changes, map refresh counts and duplicate counts are not measured.")
    Section("CLIENT AND ADDON")
    local environment = self:GetEnvironment()
    Add("Carbonite build: " .. environment.carboniteBuild)
    Add("WoW version: " .. environment.wowVersion .. " | Build: " .. environment.wowBuild)
    Add("Interface: " .. environment.interface .. " | Project: " .. environment.projectID)
    Add("Build date: " .. environment.buildDate)
    Section("INSTALLED MEASUREMENTS")
    local hooks = {}
    for _, hook in pairs(self.wrapped) do
        if self:MatchesScope(hook.reason, data.scope) then hooks[#hooks + 1] = hook.reason end
    end
    table.sort(hooks)
    for _, reason in ipairs(hooks) do Add(self:GetReasonLabel(reason) .. " [" .. reason .. "]") end
    if #hooks == 0 then Add("No functions available to measure.") end
    Section("RETAINED SAMPLES — technical detail")
    Add("Sequence | Run | Session time (ms) | Function | Duration (ms) | Lua heap change (KB)")
    for _, entry in ipairs(data.entries) do
        Add(format("%d | %s | %d | %s | %s | %s%s", tonumber(entry.sequence) or 0,
            entry.sessionKey == self.sessionKey and "current" or "earlier",
            tonumber(entry.sessionAt) or 0, tostring(entry.reason or "unknown"),
            Number(entry.ms, 3), Number(entry.memKB, 2),
            entry.label and " | Marker: " .. entry.label or ""))
    end
    Add(); Add("END OF REPORT")
    return concat(lines, "\n")
end

local function CommandRows(scope)
    local prefix = Prefix(scope)
    return {
        { prefix .. "on", "Start recording" },
        { prefix .. "off", "Stop recording" },
        { prefix .. "report", "Open the diagnostics window" },
        { prefix .. "export", "Open the copyable full report" },
        { prefix .. "status", "Print recording state and sample count" },
        { prefix .. "mark [label]", "Label a moment while recording" },
        { prefix .. "baseline set [label]", "Save an idle reference" },
        { prefix .. "baseline status", "Check the saved reference" },
        { prefix .. "baseline clear", "Remove this reference" },
        { prefix .. "clear", "Clear this view's samples and timing totals" },
        { "/carb profiler limit [100-1000]", "Set the shared sample capacity" },
        { "/carb profiler selftest", "Test the comparison calculations" },
        { prefix .. "help", "Print the command guide" },
    }
end

function Profiler:GetOptionsConfig(scope)
    scope = Scope(scope)
    self.optionGroups = self.optionGroups or {}
    if self.optionGroups[scope] then return self.optionGroups[scope] end
    local function Data() return self:GetSnapshot(scope) end
    local function Changed() self:RefreshDisplay(); RefreshOptions() end
    local function Description(order, name)
        return { type = "description", width = "full", fontSize = "medium", order = order, name = name }
    end
    local function Button(order, name, action, description, disabled)
        return { type = "execute", width = "full", order = order, name = name,
            desc = description, disabled = disabled,
            func = function() action(); Changed() end }
    end
    local overview = {
        heading = { type = "header", name = Label(scope) .. " diagnostics", order = 1 },
        intro = Description(2, "Record the issue, stop recording, then review the results."),
        state = Description(3, function() return "Recording state: " .. StateText(Data()) end),
        record = Button(4, function() return self:IsEnabled(scope) and "Stop recording" or "Start recording" end,
            function() self:SetEnabled(not self:IsEnabled(scope), scope) end,
            "Recording starts stopped after every reload.", function() return not Data().available end),
        open = Button(5, "Open diagnostics window", function() self:OpenReport(scope) end,
            "See the overview, ranked functions, comparisons, help and export."),
        metricsHeading = { type = "header", name = "This session", order = 6 },
        calls = Description(7, function() return "Measured function calls: " .. Data().calls end),
        slow = Description(8, function() return format("Slow calls (at least %d ms): %d", self.slowThreshold, Data().slowCalls) end),
        peak = Description(9, function()
            local data = Data()
            return "Largest single call: " .. (data.peak and Number(data.peak, 3) .. " ms" or "Not measured yet")
        end),
        next = Description(10, function() return "Next step: " .. Data().nextStep end),
        refresh = Button(11, "Refresh summary", function() end),
        meaning = Description(12, "Calls may contain other measured calls. These totals are not frame timings."),
    }
    local compare = {
        intro = Description(1, "Record an idle period, save it as a reference, then reproduce the issue."),
        state = Description(2, function() return BaselineText(Data()) end),
        requirement = Description(3, "Save needs 8 current-session samples for one function. Comparison needs 8 new samples for that function."),
        save = Button(4, "Save idle reference", function() self:CaptureBaseline("idle", scope) end,
            "Replace this view's reference with the latest idle sample window.",
            function() return not Data().baselineReady end),
        open = Button(5, "Review comparisons", function() self:OpenReport(scope, "compare") end),
        clear = Button(6, "Clear idle reference", function() self:ClearBaseline(scope) end, nil,
            function() return Data().baselineState == "none" end),
        meaning = Description(7, "Review increase means a comparison threshold was exceeded. It does not confirm the cause of stuttering."),
    }
    local help = {
        steps = Description(1, "1. Start recording.\n2. Reproduce the issue for about 60 seconds.\n3. Stop recording and open the diagnostics window.\n4. Select report, then press Ctrl+C."),
        heading = { type = "header", name = "Chat shortcuts", order = 2 },
    }
    for index, command in ipairs(CommandRows(scope)) do
        help["command" .. index] = Description(index + 2, command[1] .. "\n" .. command[2])
    end
    local advanced = {
        samples = Description(1, function()
            local data = Data()
            return format("Retained samples in this view: %d\nShared capacity used: %d of %d", data.samples, data.retained, data.limit)
        end),
        limit = { type = "range", width = "full", order = 2, name = "Shared sample capacity",
            min = 100, max = 1000, step = 50,
            desc = "Map and Quest share this bounded buffer. Lowering the capacity removes the oldest samples.",
            get = function() local store = self:GetStore(); return store and store.limit or 500 end,
            set = function(_, value) self:SetLimit(value); Changed() end },
        textSize = { type = "range", width = "full", order = 3, name = "Diagnostic window text size",
            min = 12, max = 18, step = 1,
            get = function() local store = self:GetStore(); return store and store.displayTextSize or 14 end,
            set = function(_, value)
                local store = self:GetStore()
                if store then store.displayTextSize = value end
                Changed()
            end },
        clear = Button(4, "Clear captured data", function() self:Clear(scope) end,
            "Clear this view's samples, timing totals and reference. Quest clears also reset catalog counters."),
        retention = Description(5, "Saved samples and references remain after reload. Recording stops and session timing totals reset."),
    }
    advanced.clear.confirm = "Clear this view's samples, timing totals and idle reference?"
    local group = {
        type = "group", name = "Diagnostics", order = 90, childGroups = "tab",
        args = {
            overview = { type = "group", name = "Overview", order = 1, args = overview },
            compare = { type = "group", name = "Compare", order = 2, args = compare },
            help = { type = "group", name = "Help", order = 3, args = help },
            advanced = { type = "group", name = "Advanced", order = 4, args = advanced },
        },
    }
    self.optionGroups[scope] = group
    return group
end

-- Native frame primitives work across the supplied clients and do not alter
-- any bundled library. All snapshot values have text labels; color is secondary.
local function SetFont(fontString, size)
    local path = _G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    if _G.GameFontNormal and _G.GameFontNormal.GetFont then
        path = _G.GameFontNormal:GetFont() or path
    end
    fontString:SetFont(path, size, "")
end

local function Button(parent, label, width, action)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 28)
    button:SetText(label)
    button:SetScript("OnClick", action)
    return button
end

local function Tooltip(region, text)
    region:EnableMouse(true)
    region:SetScript("OnEnter", function(self)
        local tooltip = _G.GameTooltip
        if not tooltip then return end
        tooltip:SetOwner(self, "ANCHOR_RIGHT")
        tooltip:SetText(text, 1, 1, 1, true)
        tooltip:Show()
    end)
    region:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
end

local function NewCanvas(frame)
    local content = frame.content
    for _, region in ipairs(frame.regions) do region:Hide() end
    frame.regionCount = 0
    local canvas = { y = 0, size = frame.textSize }
    function canvas:Text(text, x, y, width, size, color, justify)
        frame.regionCount = frame.regionCount + 1
        local index = frame.regionCount
        local region = frame.regions[index]
        if not region then
            region = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            frame.regions[index] = region
        end
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", x or 0, -(y or self.y))
        region:SetWidth(width or CONTENT_WIDTH)
        SetFont(region, size or self.size)
        region:SetJustifyH(justify or "LEFT")
        region:SetJustifyV("TOP")
        region:SetTextColor(unpack(color or PRIMARY))
        region:SetText(text)
        region:Show()
        local height = max((size or self.size) + 4, region:GetStringHeight())
        region:SetHeight(height)
        return height
    end
    function canvas:Line(text, color)
        self.y = self.y + self:Text(text, 0, self.y, CONTENT_WIDTH, self.size, color) + 10
    end
    function canvas:Heading(text)
        self.y = self.y + 10
        self.y = self.y + self:Text(text, 0, self.y, CONTENT_WIDTH, self.size + 3, ACCENT) + 12
    end
    function canvas:Finish()
        content:SetHeight(max(1, self.y + 16))
    end
    for _, bar in ipairs(frame.bars) do bar:Hide() end
    frame.barCount = 0
    return canvas
end

local function DrawBar(frame, x, y, width, value, largest)
    frame.barCount = frame.barCount + 1
    local bar = frame.bars[frame.barCount]
    if not bar then
        bar = CreateFrame("StatusBar", nil, frame.content)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetStatusBarColor(unpack(ACCENT))
        local background = bar:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetTexture("Interface\\Buttons\\WHITE8X8")
        background:SetVertexColor(.19, .24, .30, 1)
        frame.bars[frame.barCount] = bar
    end
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", x, -y)
    bar:SetSize(width, 7)
    bar:SetMinMaxValues(0, largest > 0 and largest or 1)
    bar:SetValue(max(0, value))
    bar:Show()
end

local function DrawFunctions(frame, canvas, data, limit, compact)
    if #data.rows == 0 then
        canvas:Line("No calls measured this session.")
        if data.samples > 0 then canvas:Line("Earlier saved samples remain available on Export.", SECONDARY) end
        return
    end
    local width = CONTENT_WIDTH
    if compact then
        for index = 1, min(limit or #data.rows, #data.rows) do
            local row = data.rows[index]
            local textHeight = canvas:Text(index .. ". " .. row.label, 0, canvas.y, width - 170)
            canvas:Text(Number(row.peak, 3) .. " ms", width - 150, canvas.y, 150, canvas.size, ACCENT, "RIGHT")
            local barOffset = textHeight + 7
            DrawBar(frame, 0, canvas.y + barOffset, width - 180, row.peak, data.peak)
            canvas.y = canvas.y + barOffset + 22
        end
        return
    end
    local left = width * .40
    local columns = {
        { "Calls", left, width * .12 }, { "Average (ms)", left + width * .12, width * .17 },
        { "Largest (ms)", left + width * .29, width * .17 },
        { "Slow calls", left + width * .46, width * .14 },
    }
    canvas:Line("Bars show the largest single call; this view uses one scale in milliseconds.", SECONDARY)
    canvas:Text("Function", 0, canvas.y, left - 12, canvas.size, SECONDARY)
    for _, column in ipairs(columns) do
        canvas:Text(column[1], column[2], canvas.y, column[3] - 8, canvas.size, SECONDARY, "RIGHT")
    end
    canvas.y = canvas.y + canvas.size * 2 + 10
    for index = 1, min(limit or #data.rows, #data.rows) do
        local row = data.rows[index]
        local textHeight = canvas:Text(index .. ". " .. row.label, 0, canvas.y, left - 16)
        local values = { Number(row.calls), Number(row.average, 3), Number(row.peak, 3), Number(row.slowCalls) }
        for columnIndex, column in ipairs(columns) do
            textHeight = max(textHeight,
                canvas:Text(values[columnIndex], column[2], canvas.y, column[3] - 8, canvas.size,
                    columnIndex == 3 and ACCENT or PRIMARY, "RIGHT"))
        end
        local barOffset = max(canvas.size * 2 + 5, textHeight + 8)
        DrawBar(frame, 0, canvas.y + barOffset, left - 24, row.peak, data.peak)
        canvas.y = canvas.y + max(62, barOffset + 19)
    end
end

local function DrawComparisons(canvas, rows)
    if #rows == 0 then canvas:Line("No comparable measurements available yet.", SECONDARY) end
    for _, row in ipairs(rows) do
        canvas:Heading(row.label)
        if row.status == "waiting" then
            canvas:Line(row.explanation, SECONDARY)
        else
            canvas:Line(row.status == "watch" and "Review increase" or "Within comparison thresholds",
                row.status == "watch" and REVIEW or PRIMARY)
            canvas:Line(format("Average: %.3f ms  ->  %.3f ms    Change: %+.3f ms",
                row.previous, row.current, row.change))
            canvas:Line("Relative change: " .. (row.percent and format("%+.1f%%", row.percent) or "Not defined (reference is zero)"),
                SECONDARY)
            canvas:Line(row.explanation .. "   Samples in current window: " .. row.samples, SECONDARY)
            if row.previousHeap and row.currentHeap then
                canvas:Line(format("Average shared Lua heap change: %.2f KB  ->  %.2f KB",
                    row.previousHeap, row.currentHeap), SECONDARY)
            end
        end
    end
end

function Profiler:RenderDisplay()
    local frame = self.reportFrame
    if not frame then return end
    local data = frame.snapshot
    if not data then return end
    frame.title:SetText("Carbonite | " .. data.label .. " diagnostics")
    frame.state:SetText("Recording state: " .. StateText(data))
    frame.record:SetText(data.recording and "Stop recording" or "Start recording")
    if data.available then frame.record:Enable() else frame.record:Disable() end
    frame.footer:SetText("Snapshot: " .. data.updated .. "  |  Refresh to update")
    for key, button in pairs(frame.tabs) do
        if key == frame.view then button:Disable() else button:Enable() end
    end
    for key, button in pairs(frame.scopes) do
        if key == data.scope then button:Disable() else button:Enable() end
    end
    local export = frame.view == "export"
    frame.scroll:SetShown(not export)
    frame.exportScroll:SetShown(export)
    local compare = frame.view == "compare" and data.available
    frame.baselineSave:SetShown(compare)
    frame.baselineClear:SetShown(compare)
    if data.baselineReady then frame.baselineSave:Enable() else frame.baselineSave:Disable() end
    if data.baselineState ~= "none" then frame.baselineClear:Enable() else frame.baselineClear:Disable() end
    if export then
        frame.editBox:SetText(self:BuildReport(data.scope, data))
        frame.editBox:SetHeight(max(1, frame.editBox:GetStringHeight() + 24))
        return
    end
    local canvas = NewCanvas(frame)
    if not data.available then
        canvas:Heading("Measurements unavailable")
        canvas:Line(data.nextStep)
        canvas:Finish()
        return
    end
    if frame.view == "overview" then
        local gap, height = 12, 92
        local cardWidth = (CONTENT_WIDTH - 2 * gap) / 3
        local cards = {
            { "Measured calls", Number(data.calls) },
            { "Slow calls (>= " .. self.slowThreshold .. " ms)", Number(data.slowCalls) },
            { "Largest call (ms)", data.peak and Number(data.peak, 3) or "Not measured" },
        }
        for index, card in ipairs(cards) do
            local x = (index - 1) * (cardWidth + gap)
            canvas:Text(card[1], x, 0, cardWidth, canvas.size, SECONDARY)
            canvas:Text(card[2], x, 32, cardWidth,
                (index ~= 3 or data.peak) and canvas.size + 10 or canvas.size + 4)
        end
        canvas.y = height
        canvas:Line(format("Retained samples: %d in this view   |   %d from this session", data.samples, data.currentSamples), SECONDARY)
        if data.catalog then
            canvas:Line("Quests in log: " .. Number(data.questCount)
                .. format("   |   Full scans: %d   |   Requests combined: %d",
                    data.catalog.fullRebuilds, data.catalog.coalesced), SECONDARY)
        end
        canvas:Heading("Next step")
        canvas:Line(data.nextStep)
        canvas:Heading("Largest function calls")
        DrawFunctions(frame, canvas, data, 3, true)
        canvas:Line("Bars share one scale within this view. Parent timings include child work; these are not frame timings.", SECONDARY)
    elseif frame.view == "functions" then
        canvas:Heading("Functions ranked by largest single call")
        DrawFunctions(frame, canvas, data)
        canvas:Line(format("Slow calls last at least %d ms. A slow call alone does not confirm a fault.", self.slowThreshold), SECONDARY)
    elseif frame.view == "compare" then
        canvas.y = 46
        canvas:Heading("Idle reference")
        canvas:Line(BaselineText(data))
        canvas:Line("Save needs 8 current-session samples for one function; comparison needs 8 new samples.", SECONDARY)
        DrawComparisons(canvas, data.baselineRows)
        canvas:Heading("Recent sample windows")
        canvas:Line("Compares adjacent windows from this session; 8 samples total are needed per function.", SECONDARY)
        DrawComparisons(canvas, data.recent)
        canvas:Heading("Interpretation")
        canvas:Line("Review increase is a lead for investigation. Within comparison thresholds does not guarantee smooth frames.", SECONDARY)
        canvas:Line("Timing must rise by at least 50% and 0.5 ms. Lua heap-change comparisons use a 32 KB threshold.", SECONDARY)
        canvas:Line("Map samples favor slow calls. These window averages differ from the all-call average on Functions.", SECONDARY)
    elseif frame.view == "help" then
        canvas:Heading("Capture and share an issue")
        canvas:Line("1. Start recording.\n2. Reproduce the issue for about 60 seconds.\n3. Stop recording.\n4. Select report, then press Ctrl+C.")
        canvas:Heading("What the measurements mean")
        canvas:Line("Measured calls: successful wrapped functions since reload or clear. A parent call can include other measured calls.")
        canvas:Line("Largest call: the longest observed function call this session, in milliseconds (ms).")
        canvas:Line(format("Slow calls: calls lasting at least %d ms. This label does not confirm a fault.", self.slowThreshold))
        canvas:Line("Retained samples: saved detail from this or earlier runs. Map sampling favors slow calls; not every call has a saved sample.")
        canvas:Line("Quest catalog counters continue while optional timing capture is stopped. Lua timings do not measure GPU frame time.")
        canvas:Heading("Chat shortcuts")
        for _, command in ipairs(CommandRows(data.scope)) do
            canvas:Line(command[1], ACCENT)
            canvas:Line(command[2], SECONDARY)
            canvas.y = canvas.y + 8
        end
        canvas:Heading("Where to find diagnostics")
        canvas:Line("Options > Maps > Diagnostics\nOptions > Quest Module > Diagnostics")
    end
    canvas:Finish()
end

function Profiler:RefreshDisplay()
    local frame = self.reportFrame
    if not frame or not frame:IsShown() then return end
    local store = self:GetStore()
    frame.textSize = min(18, max(12, tonumber(store and store.displayTextSize) or 14))
    SetFont(frame.editBox, frame.textSize)
    frame.snapshot = self:GetSnapshot(self.reportScope)
    self:RenderDisplay()
end

function Profiler:OpenReport(scope, view)
    self.reportScope = Scope(scope)
    local frame = self.reportFrame
    if not frame then
        local template = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
        frame = CreateFrame("Frame", "NxOriginalQuestProfilerReportFrame", UIParent, template)
        self.reportFrame = frame
        frame:Hide()
        frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
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
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false,
                edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            frame:SetBackdropColor(.055, .070, .09, 1)
            frame:SetBackdropBorderColor(.32, .39, .47, 1)
        end
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOPLEFT", 22, -20)
        frame.title:SetWidth(470)
        frame.title:SetHeight(28)
        frame.title:SetJustifyH("LEFT")
        SetFont(frame.title, 21)
        frame.title:SetTextColor(unpack(PRIMARY))
        frame.state = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.state:SetPoint("TOPLEFT", 22, -62)
        frame.state:SetWidth(480)
        frame.state:SetHeight(20)
        frame.state:SetJustifyH("LEFT")
        SetFont(frame.state, 14)
        frame.scopes, frame.tabs, frame.regions, frame.bars = {}, {}, {}, {}
        for index, key in ipairs({ "map", "quest", "all" }) do
            local scopeKey = key
            local button = Button(frame, key == "all" and "Both" or Label(key), 88, function()
                Profiler.reportScope = scopeKey
                frame.scroll:SetVerticalScroll(0)
                frame.exportScroll:SetVerticalScroll(0)
                Profiler:RefreshDisplay()
            end)
            button:SetPoint("TOPRIGHT", -22 - (3 - index) * 96, -18)
            frame.scopes[key] = button
        end
        frame.record = Button(frame, "Start recording", 142, function()
            Profiler:SetEnabled(not Profiler:IsEnabled(Profiler.reportScope), Profiler.reportScope)
            Profiler:RefreshDisplay()
            RefreshOptions()
        end)
        frame.record:SetPoint("TOPRIGHT", -22, -53)
        Tooltip(frame.record, "Start or stop optional timing capture for the selected view. Existing results remain.")
        frame.refresh = Button(frame, "Refresh", 98, function() Profiler:RefreshDisplay(); RefreshOptions() end)
        frame.refresh:SetPoint("RIGHT", frame.record, "LEFT", -8, 0)
        local views = { { "overview", "Overview" }, { "functions", "Functions" },
            { "compare", "Compare" }, { "help", "Help" }, { "export", "Export" } }
        for index, entry in ipairs(views) do
            local key = entry[1]
            local button = Button(frame, entry[2], 112, function()
                frame.view = key
                frame.scroll:SetVerticalScroll(0)
                frame.exportScroll:SetVerticalScroll(0)
                Profiler:RenderDisplay()
            end)
            button:SetPoint("TOPLEFT", 22 + (index - 1) * 120, -99)
            frame.tabs[key] = button
        end
        frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        frame.scroll:SetPoint("TOPLEFT", 22, -143)
        frame.scroll:SetPoint("BOTTOMRIGHT", -42, 60)
        frame.content = CreateFrame("Frame", nil, frame.scroll)
        frame.content:SetSize(CONTENT_WIDTH, 1)
        frame.scroll:SetScrollChild(frame.content)
        frame.baselineSave = Button(frame.content, "Save idle reference", 180, function()
            Profiler:CaptureBaseline("idle", Profiler.reportScope)
            Profiler:RefreshDisplay()
            RefreshOptions()
        end)
        frame.baselineSave:SetPoint("TOPLEFT", 0, 0)
        Tooltip(frame.baselineSave, "Replace this view's reference with the latest idle window. Needs 8 samples for one function from this session.")
        frame.baselineClear = Button(frame.content, "Clear idle reference", 180, function()
            Profiler:ClearBaseline(Profiler.reportScope)
            Profiler:RefreshDisplay()
            RefreshOptions()
        end)
        frame.baselineClear:SetPoint("LEFT", frame.baselineSave, "RIGHT", 10, 0)
        frame.exportScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        frame.exportScroll:SetPoint("TOPLEFT", 22, -143)
        frame.exportScroll:SetPoint("BOTTOMRIGHT", -42, 60)
        frame.editBox = CreateFrame("EditBox", nil, frame.exportScroll)
        frame.editBox:SetMultiLine(true)
        frame.editBox:SetAutoFocus(false)
        frame.editBox:SetWidth(CONTENT_WIDTH)
        frame.editBox:SetTextColor(unpack(PRIMARY))
        frame.editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        frame.editBox:SetScript("OnTextChanged", function(self)
            self:SetHeight(max(1, self:GetStringHeight() + 24))
        end)
        frame.exportScroll:SetScrollChild(frame.editBox)
        frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.footer:SetPoint("BOTTOMLEFT", 22, 23)
        frame.footer:SetWidth(520)
        frame.footer:SetHeight(20)
        frame.footer:SetJustifyH("LEFT")
        SetFont(frame.footer, 13)
        frame.footer:SetTextColor(unpack(SECONDARY))
        local selectReport = Button(frame, "Select report", 122, function()
            frame.view = "export"
            Profiler:RenderDisplay()
            frame.editBox:SetFocus()
            frame.editBox:HighlightText()
            frame.footer:SetText("Press Ctrl+C to copy the selected report.")
        end)
        selectReport:SetPoint("BOTTOMRIGHT", -112, 16)
        local close = Button(frame, "Close", 82, function() frame:Hide() end)
        close:SetPoint("BOTTOMRIGHT", -22, 16)
        frame:SetScript("OnShow", function()
            local screenWidth = UIParent.GetWidth and UIParent:GetWidth() or 1024
            local screenHeight = UIParent.GetHeight and UIParent:GetHeight() or 768
            frame:SetScale(min(1, max(.5, (screenWidth - 32) / FRAME_WIDTH),
                max(.5, (screenHeight - 32) / FRAME_HEIGHT)))
            Profiler:RefreshDisplay()
        end)
        frame:SetScript("OnHide", function()
            frame.editBox:ClearFocus()
            if _G.GameTooltip then _G.GameTooltip:Hide() end
        end)
        if type(_G.UISpecialFrames) == "table" then
            _G.UISpecialFrames[#_G.UISpecialFrames + 1] = frame:GetName()
        end
    end
    frame.view = view or "overview"
    frame.scroll:SetVerticalScroll(0)
    frame.exportScroll:SetVerticalScroll(0)
    frame:Show()
    self:RefreshDisplay()
end
