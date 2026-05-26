-- Carbonite.Notes | Integrations / RXPGuides navigation arrow
-- Routes RXPGuides' navigation arrow through Carbonite's own HUD
-- travel arrow instead of letting RXP draw its own. RXP keeps an
-- always-updated element on its arrow frame (RXPG_ARROW.element,
-- populated by ProcessWaypoint with .zone / .x / .y zone-percent and
-- .wx / .wy world coords). We read that element, push it onto the
-- Carbonite target queue as a "Goto" waypoint via the TomTom-emulation
-- bridge (Nx:TTAddWaypoint), and the HUD arrow then points at it just
-- like any other goto target.
--
-- RXP's own on-screen arrow is suppressed through its supported
-- `settings.profile.disableArrow` toggle (the same switch its options
-- panel flips). DrawArrow then early-returns and ProcessWaypoint hides
-- the frame, but the element keeps updating on every step change — so
-- our mirror stays live. The user's original disableArrow value is
-- snapshotted and restored when the feature is turned back off.
--
-- This mirrors the approach RestedXP-TomTom uses against TomTom; here
-- the destination is Carbonite's emulated TomTom waypoint queue, which
-- the legacy code rewires onto Carbonite.Modules.Map.Targets.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- Active Carbonite goto-target UniqueId and the last element signature
-- we pushed, so we only churn the target when the RXP step changes.
-- lastTitle tracks the waypoint label so a live objective update (e.g.
-- "3/10 mobs slain") refreshes the name in place without rebuilding.
local activeUid
local lastSig
local lastTitle

-- Arrow-suppression state. We swap RXPG_ARROW's OnUpdate (its render
-- driver, addon.DrawArrow) for a no-op and zero its alpha, rather than
-- flipping RXP's persistent settings.profile.disableArrow — so nothing
-- leaks into RXP's saved variables and the user's own arrow preference
-- is left untouched.
local rxpArrowSuppressed
local savedOnUpdate
local function noopOnUpdate() end

local POLL_INTERVAL = 0.2
local pollAccum     = 0

local function rxpAddon()
    -- _G.RXP is the RXPGuides addon table (RXP = addon, "debug
    -- purposes" in RXPGuides.lua). Same object exposes settings.
    return _G.RXP
end

local function arrowFrame()
    local af = _G.RXPG_ARROW
    if type(af) == "table" then return af end
end

-- Quantize a number for a stable signature key.
local function q(n, scale)
    if type(n) ~= "number" then return 0 end
    return math.floor(n * scale + 0.5)
end

-- Build a stable signature for an RXP arrow element. Returns nil when
-- the element carries no usable position (no active waypoint).
local function elementSig(el)
    if not el then return nil end
    local zone = (type(el.zone) == "number") and el.zone or 0
    local x    = (type(el.x) == "number") and q(el.x, 100) or 0
    local y    = (type(el.y) == "number") and q(el.y, 100) or 0
    if zone == 0 and x == 0 and y == 0 then return nil end
    return zone .. ":" .. x .. ":" .. y
end

-- Resolve an RXP element to (mapId, zoneFracX, zoneFracY) the
-- TomTom bridge expects (0..1 fractions). Prefer the element's
-- zone-percent coords; fall back to HereBeDragons world coords.
local function elementTarget(el)
    if not el then return end

    local map = el.zone
    local x   = el.x and el.x / 100
    local y   = el.y and el.y / 100

    if not (type(map) == "number" and x and y) then
        local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
        if HBD and el.wx and el.wy then
            map = (type(map) == "number" and map) or HBD:GetPlayerZone()
            if type(map) == "number" then
                x, y = HBD:GetZoneCoordinatesFromWorld(el.wx, el.wy, map, true)
            end
        end
    end

    if not (type(map) == "number" and type(x) == "number" and type(y) == "number") then
        return
    end
    if x < 0 or y < 0 or x > 1 or y > 1 then return end
    return map, x, y
end

-- Collapse a step instruction to a single readable line, keeping RXP's
-- colour markup. RXP wraps coloured words as `|cRXP_FOO_word|r`; we
-- convert the RXP_FOO_ token into its real |cAARRGGBB hex (exactly what
-- RXP's own arrow does) so the title renders coloured rather than
-- stripped. Newlines are kept (each sub-objective stays on its own row
-- in the multi-line HUD caption); only surrounding whitespace is trimmed.
local function formatText(s, rxp)
    if type(s) ~= "string" then return nil end
    local gtc = rxp and rxp.guideTextColors
    if gtc then
        s = s:gsub("RXP_[A-Z]+_", function(tok)
            return gtc[tok] or (gtc.default and gtc.default[tok]) or tok
        end)
    end
    s = s:gsub("%s*\n%s*", "\n")             -- trim around newlines, collapse blanks
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

-- True when a step-text line is quest bookkeeping (accept / turn in)
-- rather than a real objective. RXP renders those lines as
-- "<indent><|Ticon|t>Accept ..." / "...Turn in ..." using the
-- localised ACCEPT / TURN_IN_QUEST globals, so we strip the leading
-- indent, inline texture and colour escape, then prefix-match.
local function lineIsBookkeeping(line)
    local s = line:gsub("^%s+", "")
    s = s:gsub("^|[Tt].-|[Tt]", "")            -- leading inline texture
    s = s:gsub("^|[cC]%x%x%x%x%x%x%x%x", "")   -- leading colour escape
    s = s:gsub("^%s+", "")
    local accept = _G.ACCEPT
    local turnin = _G.TURN_IN_QUEST
    if accept and s:find(accept, 1, true) == 1 then return true end
    if turnin and s:find(turnin, 1, true) == 1 then return true end
    return false
end

-- The current step's objective text. step.text is the rendered step
-- block RXP builds in its guide window — newline-separated, each line
-- indented, covering every element (accept, turn in, talk, …). We keep
-- only the real objective lines and join them onto one line.
local function objectiveText(step)
    local stepText = step and step.text
    if type(stepText) ~= "string" or stepText == "" then return nil end
    local parts = {}
    for line in (stepText .. "\n"):gmatch("(.-)\n") do
        if line:match("%S") and not lineIsBookkeeping(line) then
            parts[#parts + 1] = (line:gsub("^%s+", ""):gsub("%s+$", ""))
        end
    end
    if #parts == 0 then return nil end
    -- One objective per line: the HUD arrow caption renders the target
    -- name across multiple title rows, so newline-separated sub-objectives
    -- stack instead of running into one long line. With several of them,
    -- prefix a bullet so the (left-aligned) caption reads as a list.
    if #parts > 1 then
        for i = 1, #parts do parts[i] = "• " .. parts[i] end
    end
    return table.concat(parts, "\n")
end

-- Waypoint title: just the current step's description, one line. Prefer
-- the arrow element's own caption (the goto ">>" text), then an
-- explicit arrowtext, then the filtered objective, with the step
-- title / number as a last resort.
local function elementTitle(el)
    local step = el and el.step
    local rxp  = rxpAddon()

    local t = (el and el.title)
        or (step and step.arrowtext)
        or objectiveText(step)
        or (step and (step.mapTooltip or step.title))
        or (step and step.index and ("Step " .. tostring(step.index)))

    if rxp and rxp.ReplaceNpcIds and type(t) == "string" then
        local ok, res = pcall(rxp.ReplaceNpcIds, t)
        if ok and type(res) == "string" then t = res end
    end

    return formatText(t, rxp) or "RXPGuides"
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

-- Resolve our live Carbonite target object (nil if it no longer exists,
-- e.g. the user cleared the goto or a guide reload wiped it).
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

-- Update the live target's label in place. The HUD / track arrow builds
-- its caption from tar.TargetName every frame (MapEngine), so this is
-- enough to reflect a changing objective counter without re-adding the
-- waypoint (which would clear the auto-target and reorder the queue).
local function updateTargetName(title)
    local tar = findTarget()
    if tar then tar.TargetName = title end
end

-- Hide / restore RXP's own navigation arrow. Suppression replaces the
-- frame's OnUpdate render driver with a no-op and zeroes its alpha;
-- RXP keeps updating .element from its own map loop regardless. We
-- re-apply on every tick because RXP re-installs DrawArrow whenever it
-- runs SetupArrow (guide load, arrow-scale change), which would
-- otherwise un-suppress the arrow.
local function suppressRxpArrow(on)
    local af = arrowFrame()
    if not af then return end

    if on then
        local current = af.GetScript and af:GetScript("OnUpdate")
        if current ~= noopOnUpdate then
            -- Capture whatever RXP last installed so we can restore it.
            savedOnUpdate = current
            if af.SetScript then af:SetScript("OnUpdate", noopOnUpdate) end
        end
        rxpArrowSuppressed = true
        if af.SetAlpha then af:SetAlpha(0) end
    elseif rxpArrowSuppressed then
        rxpArrowSuppressed = false
        if af.SetScript then af:SetScript("OnUpdate", savedOnUpdate) end
        if af.SetAlpha then af:SetAlpha(1) end
        savedOnUpdate = nil
        -- Let RXP re-evaluate / reposition the arrow immediately.
        local rxp = rxpAddon()
        if rxp and rxp.DrawArrow then pcall(rxp.DrawArrow, af) end
    end
end

---
-- Sync the RXP navigation arrow into Carbonite's HUD travel arrow.
-- Cheap to call every frame: bails early when disabled and only
-- rebuilds the goto target when the RXP step actually changes.
--
function Nx.Notes:RXPArrowSync()
    local enabled = Nx.fdb and Nx.fdb.profile.Notes.RXPArrow
    local rxp     = rxpAddon()

    if not (enabled and rxp) then
        suppressRxpArrow(false)
        clearTarget()
        return
    end

    suppressRxpArrow(true)

    local af  = arrowFrame()
    local el  = af and af.element
    local sig = elementSig(el)
    if not sig then
        clearTarget()
        return
    end

    local title = elementTitle(el)

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

    local map, x, y = elementTarget(el)
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

-- Polling driver. RXP populates the arrow element from its own map
-- update loop (not every frame), so a light poll is plenty; it also
-- keeps the suppression applied if RXP re-enables its arrow.
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
    pollAccum = pollAccum + elapsed
    if pollAccum < POLL_INTERVAL then return end
    pollAccum = 0
    if not (Nx.fdb and Nx.Notes) then return end
    pcall(Nx.Notes.RXPArrowSync, Nx.Notes)
end)
