-- Carbonite | Modules / Integrations / Spy
-- Read-side integration with the Spy addon (enemy-player tracker).
--
-- Spy does the heavy lifting: combat-log + nameplate + mouseover scan,
-- per-character DB, KOS/Ignore lists, alert sounds, list windows. It
-- paints its own pins on the stock WorldMapFrame via HBDP — but it
-- does NOT see the Carbonite map canvas. This integration bridges
-- that gap: Spy.NearbyList -> Carbonite map provider, plus a few
-- ergonomics (middle-click goto, KOS-proximity tooltip augment on
-- our own quest/POI pins).
--
-- Why a provider and not direct icon emission:
--   The MapProvider API isolates plug-ins from the renderer's frame
--   pool and lets us Clear() the layer wholesale on each refresh
--   without affecting other producers. NxQuest uses the same path;
--   see Carbonite.Quests/QuestProvider.lua for prior art.
--
-- Surface exposed back to Carbonite click handlers (Nx.Spy):
--   :GotoPlayer(name)      - navigate the map target to player's last seen pos
--   :GetPlayerPasteInfo(name) - tooltip-style summary for chat-link paste
--   :AugmentTooltip(this)  - append KOS-proximity warning to an icon's NxTip
--
-- Note Spy emits no callbacks of its own; we hook the post-write
-- functions `AddDetectedToLists`/`RemovePlayerFromList`/`ClearList`
-- to mark our refresh dirty, then redraw on a 1.5s ticker.

local Nx = _G.Nx
if not Nx then return end

local Carbonite = _G.Carbonite

Nx.Spy = Nx.Spy or {}

-- Same NXType the deleted Punks producer used. We keep the number
-- so the existing MapEngine click-routing branch (ClickType == 3001
-- in :GMenu_OnGoto / :GMenu_OnPasteLink) stays valid and just gets
-- redirected to Nx.Spy methods.
local NXTYPE_SPY = 3001

-- Distance threshold (zone-coord units, 0..100) under which a KOS
-- player is considered "near" another map pin. Stormwind is ~62 zone
-- units wide, so 5 is roughly the radius of a starting hub — close
-- enough to be relevant, large enough to actually flag overlapping
-- objectives.
local KOS_PROXIMITY = 5.0

-- Refresh cadence. Cheap (just walks NearbyList ~ <= 15 entries), but
-- there's no point flickering pins at 60fps.
local REFRESH_PERIOD = 1.5

local function spyReady()
    return _G.Spy
        and _G.Spy.NearbyList
        and _G.Spy.ActiveList
        and _G.SpyPerCharDB
        and _G.SpyPerCharDB.PlayerData
end

-- Look up the rich PlayerData record (class/level/race/guild/coords)
-- for an entry on Spy's NearbyList. Returns nil if the record was
-- pruned underneath us between Spy emitting it and us reading it.
local function playerInfo(name)
    return _G.SpyPerCharDB and _G.SpyPerCharDB.PlayerData and _G.SpyPerCharDB.PlayerData[name]
end

local function isKOS(name)
    return _G.SpyPerCharDB and _G.SpyPerCharDB.KOSData and _G.SpyPerCharDB.KOSData[name] ~= nil
end

local function isIgnored(name)
    return _G.SpyPerCharDB and _G.SpyPerCharDB.IgnoreData and _G.SpyPerCharDB.IgnoreData[name] ~= nil
end

-- Spy:GetPlayerLocation does the right thing already (Zone, SubZone
-- (x,y)); reuse rather than re-format. Spy:FormatTime gives "Xm Ys".
local function formatLocation(data)
    if _G.Spy and _G.Spy.GetPlayerLocation then
        return _G.Spy:GetPlayerLocation(data)
    end
    return ""
end

local function formatAge(ts)
    if _G.Spy and _G.Spy.FormatTime then
        return _G.Spy:FormatTime(ts)
    end
    return ""
end

-- Build the multi-line tooltip text for a Spy pin. Layout mirrors
-- Punks' old "Name lvl, age ago / Zone (x,y)" pattern so users
-- transitioning don't have to relearn the readout.
local function buildTip(name, data, ts, kos)
    local lvl = (data.level and data.level > 0) and tostring(data.level) or "?"
    local cls = data.class or "?"
    local race = data.race or ""
    local guild = data.guild and ("<" .. data.guild .. ">") or ""
    local age = formatAge(ts or data.time or 0)
    local loc = formatLocation(data)

    local color = kos and "|cffff2020" or "|cffff8080"
    local line1 = string.format("%s%s|r  L%s %s %s", color, name, lvl, cls, race)
    local line2 = guild ~= "" and ("|cffa0a0ff" .. guild .. "|r") or nil
    local line3 = string.format("|cffc0c0c0%s ago|r", age)
    local line4 = loc ~= "" and ("|cff80a0ff" .. loc .. "|r") or nil
    if kos then
        line1 = line1 .. " |cffff00ff[KOS]|r"
    end

    local lines = { line1 }
    if line2 then lines[#lines + 1] = line2 end
    lines[#lines + 1] = line3
    if line4 then lines[#lines + 1] = line4 end
    return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------
-- Provider setup (lazy)
-- ---------------------------------------------------------------

local _provider
local function provider()
    if _provider then return _provider end
    if not (Carbonite and Carbonite.Map and Carbonite.Map.CreateProvider) then
        return nil
    end
    local p = Carbonite.Map:CreateProvider("Carbonite.Spy")

    local tex = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconPlyrZ"

    -- Three kinds let us color/scale per category without inflating
    -- the pin def into a per-pin texture override path:
    --   Enemy    - normal Nearby/Active entry
    --   KOS      - KOSData hit, brighter + larger so it's the first
    --              thing the eye catches
    --   Inactive - Spy timed out the ActiveList but kept it on
    --              NearbyList; render dimmer so the user can tell
    --              the difference at a glance.
    p:DefinePin("Enemy", {
        drawMode = "WP",
        tex      = tex,
        w        = 14,
        h        = 14,
    })
    p:DefinePin("KOS", {
        drawMode = "WP",
        tex      = tex,
        w        = 18,
        h        = 18,
    })
    p:DefinePin("Inactive", {
        drawMode = "WP",
        tex      = tex,
        w        = 12,
        h        = 12,
    })

    _provider = p
    return p
end

-- ---------------------------------------------------------------
-- Refresh loop
-- ---------------------------------------------------------------

Nx.Spy._dirty   = true
Nx.Spy._lastMid = nil

local function markDirty()
    Nx.Spy._dirty = true
end

-- Resolve player's world position from the per-zone (mapID, mapX, mapY)
-- record Spy stores. Spy keeps mapX/mapY as 0..1 fractions; Carbonite
-- :GetWorldPos expects zone-percent (0..100), so multiply by 100.
local function pinPlayer(p, name, data, ts)
    if not (data.mapID and data.mapX and data.mapY) then return end
    local map = Nx.Map:GetMap(1)
    if not map then return end
    local wx, wy = map:GetWorldPos(data.mapID, data.mapX * 100, data.mapY * 100)
    if not (wx and wy) then return end

    local kos = isKOS(name)
    local active = _G.Spy.ActiveList[name] ~= nil
    local kind = kos and "KOS" or (active and "Enemy" or "Inactive")

    -- Brighten KOS, fade Inactive. Active/Enemy stays solid.
    local color
    if kos then
        color = "FFFF4040"   -- bright red
    elseif active then
        color = "FFE08080"   -- normal red
    else
        color = "B0A06060"   -- faded brown — recent but gone quiet
    end

    p:Add(kind, wx, wy, {
        tip     = buildTip(name, data, ts, kos),
        color   = color,
        NXType  = NXTYPE_SPY,
        NXData  = name,           -- routed to ClickType==3001 handlers
        mapID   = data.mapID,
        userData = { name = name },
    })
end

local function refresh()
    if not spyReady() then return end
    local p = provider()
    if not p then return end

    p:Clear()

    local now = time()
    for name, ts in pairs(_G.Spy.NearbyList) do
        if not isIgnored(name) then
            local data = playerInfo(name)
            if data then
                pinPlayer(p, name, data, ts)
            end
        end
    end
end

-- ---------------------------------------------------------------
-- Click-handler surface (consumed by MapEngine ClickType==3001)
-- ---------------------------------------------------------------

function Nx.Spy:GotoPlayer(name)
    if not (name and spyReady()) then return end
    local data = playerInfo(name)
    if not (data and data.mapID and data.mapX and data.mapY) then return end
    local map = Nx.Map:GetMap(1)
    if not map then return end
    local wx, wy = map:GetWorldPos(data.mapID, data.mapX * 100, data.mapY * 100)
    if not (wx and wy) then return end
    map:SetTarget("Goto", wx, wy, wx, wy, false, 0, name)
end

function Nx.Spy:GetPlayerPasteInfo(name)
    if not (name and spyReady()) then return "" end
    local data = playerInfo(name)
    if not data then return name end
    local lvl = (data.level and data.level > 0) and data.level or "?"
    local cls = data.class or "?"
    local loc = formatLocation(data)
    return string.format("Enemy: %s, %s %s at %s", name, tostring(lvl), cls, loc)
end

-- ---------------------------------------------------------------
-- KOS-proximity tooltip augment (point #3)
-- ---------------------------------------------------------------
--
-- Called from Nx.Map:IconOnEnter just before NxTip is emitted to
-- the actual tooltip widget. If a KOS-flagged player from Spy's
-- NearbyList sits within KOS_PROXIMITY zone units of this pin's
-- coords (same mapID), append a one-line warning so the user gets
-- the heads-up while reading a regular quest / POI tooltip.
--
-- Returns nothing; mutates `this.NxTip` in place.
function Nx.Spy:AugmentTooltip(this)
    if not (this and this.NxTip and spyReady()) then return end
    -- Skip our own Spy pins so we don't double up; their tip already
    -- has the KOS marker baked in by buildTip.
    if this.NXType == NXTYPE_SPY then return end

    -- Pin coordinates are stored on the pin instance attached at
    -- render time (pin.x / pin.y are world coords, pin.mapID is the
    -- source map). Legacy icons skip this; bail silently when we
    -- can't resolve a comparable position.
    local pin = this.NxPin
    if not (pin and pin.mapID and pin.x and pin.y) then return end

    local map = Nx.Map:GetMap(1)
    if not map then return end

    -- Project the pin's world coords back into mapID-local zone
    -- percent so we can compare against Spy's per-zone mapX/mapY.
    local pinZX, pinZY = map:GetZonePos(pin.mapID, pin.x, pin.y)
    if not (pinZX and pinZY) then return end

    local hits
    for name, _ in pairs(_G.Spy.NearbyList) do
        if isKOS(name) and not isIgnored(name) then
            local d = playerInfo(name)
            if d and d.mapID == pin.mapID and d.mapX and d.mapY then
                local dx = pinZX - d.mapX * 100
                local dy = pinZY - d.mapY * 100
                if dx * dx + dy * dy <= KOS_PROXIMITY * KOS_PROXIMITY then
                    hits = hits or {}
                    hits[#hits + 1] = string.format("%s (%s ago)",
                        name, formatAge(d.time or 0))
                end
            end
        end
    end

    if hits then
        this.NxTip = this.NxTip
            .. "\n|cffff00ff[KOS nearby]|r |cffff8080"
            .. table.concat(hits, ", ") .. "|r"
    end
end

-- ---------------------------------------------------------------
-- Wire-up
-- ---------------------------------------------------------------

local _wired

local function install()
    if _wired then return end
    if not spyReady() then return end
    _wired = true

    -- Force-create the provider so it exists before the first
    -- refresh tick (otherwise the first MapEngine pass would draw
    -- nothing).
    provider()

    -- Dirty-flag hooks. AddDetectedToLists / RemovePlayerFromList /
    -- ClearList are all non-secure post-write functions, so a plain
    -- hooksecurefunc works without taint side-effects.
    hooksecurefunc(_G.Spy, "AddDetectedToLists",  markDirty)
    hooksecurefunc(_G.Spy, "RemovePlayerFromList", markDirty)
    hooksecurefunc(_G.Spy, "ClearList", function()
        local p = provider()
        if p then p:Clear() end
        Nx.Spy._dirty = false
    end)

    Nx.Spy._ticker = C_Timer.NewTicker(REFRESH_PERIOD, function()
        if Nx.Spy._dirty then
            Nx.Spy._dirty = false
            refresh()
        end
    end)

    -- Render once now so the user doesn't wait for the first dirty
    -- event to see their existing NearbyList show up.
    refresh()
end

if spyReady() then
    install()
else
    -- Spy uses AceAddon-3.0 :OnInitialize, which fires from
    -- ADDON_LOADED -> 0-frame later. Defer install via the event
    -- loop. The pcall around RegisterEvent matches the pattern in
    -- Carbonite.Notes/Integrations/RareScanner.lua: harmless on the
    -- happy path, swallows the rare classic-flavor case where the
    -- event isn't yet defined when the file loads.
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self, event, name)
        if event == "ADDON_LOADED" and name ~= "Spy" then return end
        if spyReady() then
            -- One frame's slack so Spy:OnInitialize has populated
            -- its tables before we read them.
            C_Timer.After(0, function()
                if spyReady() then
                    self:UnregisterAllEvents()
                    install()
                end
            end)
        end
    end)
end
