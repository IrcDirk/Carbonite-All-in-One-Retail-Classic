-- Carbonite | Modules / Integrations / TomTom
-- TomTom-compatible API surface so other addons that expect TomTom
-- (e.g. WoWPro, Routes, RareScanner, Questie integrations) Just Work
-- when Carbonite is loaded without the real TomTom addon.
--
-- Surface is modeled on the real TomTom addon (blizzard/addons/TomTom)
-- and includes:
--
--   Waypoint verbs:
--     AddWaypoint(m, x, y, opts)
--     AddZWaypoint(cont, zone, zx, zy, name, persist, minimap, world, callbacks)
--     AddMFWaypoint / SetCustomMFWaypoint(aid, floor, zx, zy, opts)
--     SetCustomWaypoint(cont, zone, zx, zy, callbacks)
--     RemoveWaypoint(uid)
--     ClearAllWaypoints()
--     AddWaypointToCurrentZone(x, y, desc)
--     SetCrazyArrow(uid, dist, text)
--     SetClosestWaypoint() / GetClosestWaypoint()
--
--   Query helpers:
--     GetCurrentPlayerPosition()   -> m, x, y
--     GetCurrentCoords()           -> x, y
--     GetKey(waypoint) / GetKeyArgs(m, x, y, title)
--     WaypointExists(m, x, y, desc)
--     IsValidWaypoint(waypoint)
--     UIDIsSaved(uid)
--
--   Defaults:
--     DefaultCallbacks(opts)
--
--   Slash commands:
--     /way, /tway, /tomtomway  -> set waypoint
--     /cbway                   -> Carbonite-prefixed alias
--     /cway, /closestway       -> route closest
--     /wayb, /wayback          -> reverse trip
--
-- Most operations delegate to Carbonite's own routing / target /
-- map APIs, so they stay in sync with whatever the user sees on
-- the Carbonite map.

local Carbonite = _G.Carbonite
local TomTom = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Integrations = Carbonite.Modules.Integrations or {}
Carbonite.Modules.Integrations.TomTom = TomTom

local API_VERSION = "v40200"

-- =====================================================================
-- Internal helpers
-- =====================================================================

local function NxMap()    return _G.Nx and _G.Nx.Map end
local function MapInst()  local m = NxMap() return m and m.Maps and m.Maps[1] end

local function MapApi()  return Carbonite.Compat and Carbonite.Compat.MapApi end
local function Targets() return Carbonite.Modules and Carbonite.Modules.Map and Carbonite.Modules.Map.Targets end

local function currentPlayerMapID()
    if MapApi() then return MapApi():GetPlayerMapID() end
    if _G.C_Map and _G.C_Map.GetBestMapForUnit then return _G.C_Map.GetBestMapForUnit("player") end
end

-- =====================================================================
-- Standalone-detection API
-- =====================================================================

function TomTom:IsReal()      return _G.Nx and _G.Nx.RealTom == true end
function TomTom:IsEmulating() return _G.TomTom ~= nil and not self:IsReal() end

-- =====================================================================
-- Stable identity / key helpers (mirrors TomTom:GetKey exactly)
-- =====================================================================

function TomTom:GetKey(waypoint)
    if not waypoint then return nil end
    local m, x, y = waypoint[1], waypoint[2], waypoint[3]
    return self:GetKeyArgs(m, x, y, waypoint.title)
end

function TomTom:GetKeyArgs(m, x, y, title)
    if not (m and x and y) then return nil end
    x, y = x * 10000, y * 10000
    return ("%d:%s:%s:%s"):format(m, x * 10e4, y * 10e4, tostring(title))
end

-- =====================================================================
-- Position queries
-- =====================================================================

function TomTom:GetCurrentPlayerPosition()
    local mapID = currentPlayerMapID()
    if not mapID then return nil end
    if MapApi() then
        local x, y = MapApi():GetPlayerPosition(mapID)
        if x and y then return mapID, x, y end
    end
    if _G.C_Map and _G.C_Map.GetPlayerMapPosition then
        local pos = _G.C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then return mapID, pos:GetXY() end
    end
end

function TomTom:GetCurrentCoords()
    local _, x, y = self:GetCurrentPlayerPosition()
    return x, y
end

-- =====================================================================
-- Waypoint storage. We do NOT keep our own list - Carbonite's targets
-- ARE the waypoints. Real TomTom keeps a parallel store keyed by map;
-- we accept the table shape it expects so calling code can iterate
-- a returned uid, but the canonical state lives in Carbonite.
-- =====================================================================

local uidIndex = {}                 -- uid -> { mapID, x, y, title } (weak set on uid)

local function legacyTT(name) return _G.Nx and _G.Nx[name] end

function TomTom:AddWaypoint(m, x, y, opts)
    opts = opts or {}
    local fn = legacyTT("TTAddWaypoint")
    local uid = fn and fn(_G.Nx, m, x, y, opts)
    if uid then uidIndex[uid] = { m, x, y, title = opts.title or "" } end
    return uid
end

-- Continent / Zone (deprecated TomTom 1.x signature; some old addons
-- still use it). The legacy NxMap:TTAddZWaypoint accepts both.
function TomTom:AddZWaypoint(cont, zone, zx, zy, name, persist, minimap, world, callbacks)
    local fn = legacyTT("TTAddZWaypoint")
    return fn and fn(_G.Nx, cont, zone, zx, zy, name, persist, minimap, world, callbacks)
end

function TomTom:SetCustomWaypoint(cont, zone, zx, zy, callbacks)
    local fn = legacyTT("TTSetCustomWaypoint")
    return fn and fn(_G.Nx, cont, zone, zx, zy, callbacks)
end

function TomTom:SetCustomMFWaypoint(aid, floor, zx, zy, opts)
    local fn = legacyTT("TTSetCustomMFWaypoint")
    return fn and fn(_G.Nx, aid, floor, zx, zy, opts)
end

TomTom.AddMFWaypoint = TomTom.SetCustomMFWaypoint

function TomTom:RemoveWaypoint(uid)
    uidIndex[uid] = nil
    local fn = legacyTT("TTRemoveWaypoint")
    return fn and fn(_G.Nx, uid)
end

function TomTom:SetCrazyArrow(uid, dist, str)
    local fn = legacyTT("TTSetCrazyArrow")
    return fn and fn(_G.Nx, uid, dist, str)
end

function TomTom:SetClosestWaypoint()
    local fn = legacyTT("TTSetClosestWaypoint")
    return fn and fn(_G.Nx)
end

function TomTom:DefaultCallbacks(opts)
    local fn = legacyTT("TTDefaultCallbacks")
    return fn and fn(_G.Nx, opts) or {}
end

-- New / extended verbs (real TomTom has these; we synthesize them):

function TomTom:ClearAllWaypoints()
    if Targets() then Targets():Clear() end
    -- Also clear our weak index so :IsValidWaypoint stops recognizing
    -- the old uids.
    for k in pairs(uidIndex) do uidIndex[k] = nil end
end

function TomTom:AddWaypointToCurrentZone(x, y, desc)
    local m = currentPlayerMapID()
    if not m then return nil end
    return self:AddWaypoint(m, x, y, { title = desc })
end

function TomTom:WaypointExists(m, x, y, desc)
    local key = self:GetKeyArgs(m, x, y, desc)
    if not key then return false end
    for uid in pairs(uidIndex) do
        if self:GetKeyArgs(uid[1], uid[2], uid[3], uid.title) == key then return true end
    end
    return false
end

function TomTom:IsValidWaypoint(waypoint)
    return waypoint ~= nil and uidIndex[waypoint] ~= nil
end

TomTom.UIDIsSaved = TomTom.IsValidWaypoint

-- Closest-waypoint: prefer Carbonite's Targets list and compare against
-- player position.
function TomTom:GetClosestWaypoint()
    local m, px, py = self:GetCurrentPlayerPosition()
    if not (m and px and py) then return nil end

    local best, bestDist
    for uid, w in pairs(uidIndex) do
        if w[1] == m then
            local dx = px - w[2]
            local dy = py - w[3]
            local d = dx * dx + dy * dy
            if not bestDist or d < bestDist then
                bestDist = d; best = uid
            end
        end
    end
    return best
end

-- Send waypoint to a chat channel. Real TomTom sends an addon-comm
-- message; we use the chat channel as a fallback because Carbonite's
-- addon-comm protocol does not yet carry waypoints.
function TomTom:SendWaypoint(uid, channel)
    if not uid then return end
    local m, x, y = uid[1], uid[2], uid[3]
    if not (m and x and y) then return end
    channel = channel or "PARTY"
    local msg = ("|cffffff78TomTom:|r %d %.2f %.2f %s"):format(m, x * 100, y * 100, uid.title or "")
    if _G.SendChatMessage then _G.SendChatMessage(msg, channel) end
end

-- =====================================================================
-- Forwarded convenience. New code should prefer these over reaching
-- into _G.TomTom directly when Carbonite is the one supplying the API.
-- =====================================================================

function TomTom:AddWaypointForward(mapID, x, y, opts)
    if not _G.TomTom or not _G.TomTom.AddWaypoint then return nil end
    return _G.TomTom.AddWaypoint(_G.TomTom, mapID, x, y, opts)
end

-- =====================================================================
-- Install / uninstall
-- =====================================================================

local function bindLegacyTomTomTable(tom)
    -- Method-style bindings (TomTom:Foo). Wrap our `:` methods so the
    -- caller can use either tom:Foo() or tom.Foo(tom, ...) which is
    -- how some legacy addons call them.
    local function wrap(name)
        return function(_, ...) return TomTom[name](TomTom, ...) end
    end

    tom.version              = API_VERSION
    tom.AddWaypoint          = wrap("AddWaypoint")
    tom.AddZWaypoint         = wrap("AddZWaypoint")
    tom.SetCustomWaypoint    = wrap("SetCustomWaypoint")
    tom.SetCustomMFWaypoint  = wrap("SetCustomMFWaypoint")
    tom.AddMFWaypoint        = wrap("SetCustomMFWaypoint")
    tom.RemoveWaypoint       = wrap("RemoveWaypoint")
    tom.SetCrazyArrow        = wrap("SetCrazyArrow")
    tom.DefaultCallbacks     = wrap("DefaultCallbacks")
    tom.SetClosestWaypoint   = wrap("SetClosestWaypoint")
    tom.GetClosestWaypoint   = wrap("GetClosestWaypoint")

    tom.GetCurrentPlayerPosition = wrap("GetCurrentPlayerPosition")
    tom.GetCurrentCoords         = wrap("GetCurrentCoords")
    tom.GetKey                   = wrap("GetKey")
    tom.GetKeyArgs               = wrap("GetKeyArgs")

    tom.ClearAllWaypoints        = wrap("ClearAllWaypoints")
    tom.AddWaypointToCurrentZone = wrap("AddWaypointToCurrentZone")
    tom.WaypointExists           = wrap("WaypointExists")
    tom.IsValidWaypoint          = wrap("IsValidWaypoint")
    tom.UIDIsSaved               = wrap("UIDIsSaved")
    tom.SendWaypoint             = wrap("SendWaypoint")

    -- Stub `profile` so callers checking config flags do not crash.
    -- We expose Carbonite's own track/route settings under names that
    -- mirror TomTom's persistence/arrow tree closely enough that the
    -- common reads succeed.
    tom.profile = tom.profile or {
        general     = { announce = false },
        minimap     = { enable = true },
        worldmap    = { enable = true },
        arrow       = { autoqueue = true, arrival = 15, enablePing = false },
        persistence = { savewaypoints = false, cleardistance = 0 },
    }
end

local function bindSlashCommands()
    -- Primary set waypoint commands. The legacy Nx.TTWayCmd parses
    -- the line and dispatches to AddWaypoint.
    local function setWay(msg) if _G.Nx and _G.Nx.TTWayCmd then _G.Nx:TTWayCmd(msg) end end
    _G.SLASH_TOMTOM_WAY1 = "/way"
    _G.SLASH_TOMTOM_WAY2 = "/tway"
    _G.SLASH_TOMTOM_WAY3 = "/tomtomway"
    _G.SLASH_TOMTOM_WAY4 = "/cbway"
    _G.SlashCmdList["TOMTOM_WAY"] = setWay

    -- Closest-waypoint aliases.
    _G.SLASH_TOMTOM_CWAY1 = "/cway"
    _G.SLASH_TOMTOM_CWAY2 = "/closestway"
    _G.SlashCmdList["TOMTOM_CWAY"] = function() TomTom:SetClosestWaypoint() end

    -- Wayback: reverse the current target order so the last waypoint
    -- becomes the first. Maps onto our Targets:Reverse().
    _G.SLASH_TOMTOM_WAYBACK1 = "/wayb"
    _G.SLASH_TOMTOM_WAYBACK2 = "/wayback"
    _G.SlashCmdList["TOMTOM_WAYBACK"] = function()
        if Targets() then Targets():Reverse() end
    end
end

function TomTom:Emulate()
    if _G.TomTom and self:IsReal() then return false end

    local tom = _G.TomTom or {}
    _G.TomTom = tom
    bindLegacyTomTomTable(tom)
    bindSlashCommands()

    Carbonite.Core.EventBus:Fire("INTEGRATION_TOMTOM_EMULATED")
    return true
end

function TomTom:Stop()
    if self:IsReal() then return end
    _G.TomTom = nil
    Carbonite.Core.EventBus:Fire("INTEGRATION_TOMTOM_STOPPED")
end

-- Auto-install at enable. Idempotent.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function() TomTom:Emulate() end)

-- Legacy alias: install Nx.EmulateTomTom at FILE-LOAD time, not via the
-- CARBONITE_LOADED event. Carbonite's UNIT_NAME_UPDATE handler in
-- Carbonite.lua calls Nx.EmulateTomTom() during the early AceEvent
-- dispatch, and that dispatch can fire BEFORE ADDON_LOADED for
-- Carbonite (and therefore before CARBONITE_LOADED). Map:Init in
-- MapEngine also calls it from inside SetupEverything; if it was nil
-- there the error aborted the rest of Init and left Nx.Map.Maps[1]
-- unpopulated, cascading into a second crash inside Nx.UEvents:GetPlyrPos.
if _G.Nx then
    _G.Nx.EmulateTomTom = function() TomTom:Emulate() end
end
