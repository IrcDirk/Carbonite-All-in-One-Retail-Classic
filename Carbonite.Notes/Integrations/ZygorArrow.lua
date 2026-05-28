-- Carbonite.Notes | Integrations / ZygorGuidesViewer navigation arrow
-- Routes the Zygor Guides Viewer navigation arrow through Carbonite's
-- own HUD travel arrow instead of letting Zygor draw its own. Zygor's
-- pointer keeps a live destination waypoint (ZGV.Pointer.ArrowFrame
-- .waypoint / ZGV.Pointer.DestinationWaypoint) with .m (uiMapID) and
-- .x / .y zone-fraction coords. We read that waypoint, push it onto the
-- Carbonite target queue as a "Goto" waypoint via the TomTom-emulation
-- bridge (Nx:TTAddWaypoint), and the HUD arrow then points at it just
-- like any other goto target.
--
-- Zygor's own on-screen arrow is suppressed by post-hooking its render
-- driver (Pointer.ArrowFrame_OnUpdate_Common) and force-hiding the
-- arrow frame after Zygor's own update runs. Zygor re-shows the frame
-- on every tick while a waypoint is active (Pointer.lua, the
-- `ArrowFrame:Show()` near the end of that function), so a one-shot
-- Hide would not stick; the post-hook keeps it down without touching
-- Zygor's persistent `profile.arrowshow` saved variable, so the user's
-- own arrow preference is left intact and is restored verbatim when the
-- feature is turned back off.
--
-- This mirrors the RXPGuides arrow bridge ([[RXPArrow]]); here the
-- source is Zygor's pointer and the caption is built from the current
-- step's goals (Goal:GetText), each on its own line in the multi-line
-- HUD caption, with a localized "Step N:" prefix on the heading.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- Notes-module locale, for the "Step N:" caption prefix. Silent fetch
-- (locale files load before this integration, but guard regardless).
local L = LibStub and LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

-- Active Carbonite goto-target UniqueId and the last waypoint signature
-- we pushed, so we only churn the target when the Zygor step changes.
-- lastTitle tracks the waypoint label so a live objective update (e.g.
-- "3/10 mobs slain") refreshes the name in place without rebuilding.
local activeUid
local lastSig
local lastTitle

-- Arrow-suppression state. We post-hook Zygor's arrow render driver once
-- and force-hide the arrow frame while suppression is on, rather than
-- flipping Zygor's persistent profile.arrowshow -- so nothing leaks into
-- Zygor's saved variables.
local zygorSuppressed
local hookInstalled

local POLL_INTERVAL = 0.2
local pollAccum     = 0

-- _G.ZGV is the Zygor Guides Viewer addon table (alias of
-- ZygorGuidesViewer). Its .Pointer owns the waypoint / arrow system.
local function zygorPointer()
    local ZGV = _G.ZGV
    local P = ZGV and ZGV.Pointer
    if type(P) == "table" then return P, ZGV end
end

-- The live destination waypoint Zygor is pointing at, or nil.
local function activeWaypoint(P)
    if not P then return nil end
    local way = (P.ArrowFrame and P.ArrowFrame.waypoint) or P.DestinationWaypoint
    if type(way) == "table" then return way end
end

-- Quantize a number for a stable signature key.
local function q(n, scale)
    if type(n) ~= "number" then return 0 end
    return math.floor(n * scale + 0.5)
end

-- Build a stable signature for a Zygor waypoint. Returns nil when the
-- waypoint carries no usable position.
local function waypointSig(way)
    if not way then return nil end
    local m = (type(way.m) == "number") and way.m or 0
    local x = (type(way.x) == "number") and q(way.x, 10000) or 0
    local y = (type(way.y) == "number") and q(way.y, 10000) or 0
    if m == 0 and x == 0 and y == 0 then return nil end
    return m .. ":" .. x .. ":" .. y
end

-- Resolve a Zygor waypoint to (mapId, zoneFracX, zoneFracY) the TomTom
-- bridge expects (0..1 fractions). Zygor stores .x / .y already as
-- zone fractions.
local function waypointTarget(way)
    if not way then return end
    local map, x, y = way.m, way.x, way.y
    if not (type(map) == "number" and type(x) == "number" and type(y) == "number") then
        return
    end
    if x < 0 or y < 0 or x > 1 or y > 1 then return end
    return map, x, y
end

-- Keep newlines (each goal stays on its own row in the multi-line HUD
-- caption); only surrounding whitespace is trimmed. Zygor's Goal:GetText
-- already emits WoW colour escapes, so no token translation is needed.
local function formatText(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("%s*\n%s*", "\n")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

-- One readable line for a single Zygor goal, or nil to skip it.
-- mapmarker goals render empty by design; we also drop goals whose text
-- collapses to nothing. GetText(showcompleteness, brief) gives the same
-- coloured, counted text Zygor's own guide window shows.
local function goalLine(goal)
    if type(goal) ~= "table" or type(goal.GetText) ~= "function" then return nil end
    if goal.action == "mapmarker" then return nil end
    local ok, txt = pcall(goal.GetText, goal, true, true)
    if not ok or type(txt) ~= "string" then return nil end
    txt = txt:gsub("%s*\n%s*", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if txt == "" then return nil end
    return txt
end

-- The current step's objective text: every non-empty goal of the active
-- step, one per line. The first goal reads as the heading; any further
-- ones become a bulleted list beneath it (left-aligned in the HUD).
local function objectiveText(step)
    if type(step) ~= "table" or type(step.goals) ~= "table" then return nil end
    local parts = {}
    for _, goal in ipairs(step.goals) do
        local line = goalLine(goal)
        if line then parts[#parts + 1] = line end
    end
    if #parts == 0 then return nil end
    for i = 2, #parts do parts[i] = "• " .. parts[i] end
    return table.concat(parts, "\n")
end

-- Waypoint title: the current step's objectives, with a localized step
-- number prefixed to the heading line. Falls back to the waypoint's own
-- title (often the quest name) and finally a plain label.
local function buildTitle(ZGV, way)
    local step  = ZGV and ZGV.CurrentStep
    local title = formatText(objectiveText(step))
        or formatText(way and way.title)
        or "ZygorGuides"

    local idx = (step and step.num) or (ZGV and ZGV.CurrentStepNum)
    if type(idx) == "number" then
        local prefix = (L and L["Step"] or "Step") .. " " .. idx .. ": "
        local nl = title:find("\n", 1, true)
        if nl then
            title = prefix .. title:sub(1, nl - 1) .. title:sub(nl)
        else
            title = prefix .. title
        end
    end

    return title
end

-- Drop our goto target if we have one.
local function clearTarget()
    if activeUid and Nx.TTRemoveWaypoint then
        Nx:TTRemoveWaypoint(activeUid)
    end
    activeUid = nil
    lastSig   = nil
    lastTitle = nil
end

-- Resolve our live Carbonite target object (nil if it no longer exists).
local function findTarget()
    if not activeUid then return nil end
    local Carbonite = _G.Carbonite
    local Targets   = Carbonite and Carbonite.Modules
                      and Carbonite.Modules.Map
                      and Carbonite.Modules.Map.Targets
    if Targets and Targets.Find then
        return Targets:Find(activeUid)
    end
    return nil
end

-- Update the live target's label in place (the HUD arrow builds its
-- caption from tar.TargetName every frame), reflecting a changing
-- objective counter without re-adding the waypoint.
local function updateTargetName(title)
    local tar = findTarget()
    if tar then tar.TargetName = title end
end

-- Install the one-shot post-hook on Zygor's arrow render driver. After
-- Zygor finishes a frame (which may re-show the arrow), we hide it again
-- while suppression is on. hooksecurefunc cannot be undone, so the gate
-- is the zygorSuppressed flag, not the hook's presence.
local function installArrowHook()
    if hookInstalled then return end
    local P = zygorPointer()
    if not (P and type(P.ArrowFrame_OnUpdate_Common) == "function"
            and type(hooksecurefunc) == "function") then
        return
    end
    hooksecurefunc(P, "ArrowFrame_OnUpdate_Common", function(frame)
        if zygorSuppressed and type(frame) == "table" and frame.Hide then
            frame:Hide()
        end
    end)
    hookInstalled = true
end

-- Hide / restore Zygor's own navigation arrow. Suppression installs the
-- post-hook and hides the frame now; restoration lets Zygor re-evaluate
-- visibility from its own profile (UpdateArrowVisibility).
local function suppressZygorArrow(on)
    local P = zygorPointer()
    if not P then return end

    if on then
        installArrowHook()
        zygorSuppressed = true
        if P.ArrowFrame and P.ArrowFrame.Hide then P.ArrowFrame:Hide() end
    elseif zygorSuppressed then
        zygorSuppressed = false
        if P.UpdateArrowVisibility then pcall(P.UpdateArrowVisibility, P) end
    end
end

---
-- Sync Zygor's navigation arrow into Carbonite's HUD travel arrow.
-- Cheap to call every frame: bails early when disabled and only rebuilds
-- the goto target when the Zygor waypoint actually changes.
--
function Nx.Notes:ZygorArrowSync()
    local enabled = Nx.fdb and Nx.fdb.profile.Notes.ZygorArrow
    local P, ZGV  = zygorPointer()

    if not (enabled and P) then
        suppressZygorArrow(false)
        clearTarget()
        return
    end

    suppressZygorArrow(true)

    local way = activeWaypoint(P)
    local sig = waypointSig(way)
    if not sig then
        clearTarget()
        return
    end

    local title = buildTitle(ZGV, way)

    -- Same destination and our target is still live: the coords didn't
    -- change, but the objective label might have (a kill / collect
    -- counter ticking up), so refresh the name in place and bail.
    if sig == lastSig and findTarget() then
        if title ~= lastTitle then
            updateTargetName(title)
            lastTitle = title
        end
        return
    end

    local map, x, y = waypointTarget(way)
    if not map then
        clearTarget()
        return
    end

    -- Replace the previous waypoint so the HUD arrow re-points cleanly.
    if activeUid and Nx.TTRemoveWaypoint then
        Nx:TTRemoveWaypoint(activeUid)
    end

    activeUid = Nx.TTAddWaypoint and Nx:TTAddWaypoint(map, x, y, { title = title }) or nil
    lastSig   = sig
    lastTitle = title
    if activeUid and Nx.TTSetCrazyArrow then
        Nx:TTSetCrazyArrow(activeUid, 0, title)
    end
end

-- Polling driver. Zygor updates its waypoint from its own pointer loop,
-- so a light poll is plenty; it also keeps the suppression applied if
-- Zygor re-enables its arrow.
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
    pollAccum = pollAccum + elapsed
    if pollAccum < POLL_INTERVAL then return end
    pollAccum = 0
    if not (Nx.fdb and Nx.Notes) then return end
    pcall(Nx.Notes.ZygorArrowSync, Nx.Notes)
end)
