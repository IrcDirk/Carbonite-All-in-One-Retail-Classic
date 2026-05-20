-- Carbonite | Modules / Integrations / TomTomWaypoints
-- The TT*-function implementations that real-TomTom-aware addons
-- call into when Carbonite is providing the emulation. The legacy
-- code stored these as Nx:TT* methods inside NxMap.lua; this
-- module owns them in a class so future changes (e.g. better
-- proximity callbacks, batched adds) happen in one place.
--
-- This file does NOT define the global `_G.TomTom` table - that's
-- the job of Modules/Integrations/TomTom.lua. We provide the
-- waypoint verb implementations that table exposes.
--
-- Public API (all method-style, called by the TomTom proxy):
--   TomTomWaypoints:AddWaypoint(m, x, y, opts)         -> uid
--   TomTomWaypoints:AddZWaypoint(c, z, zx, zy, name, _, _, _, cb)
--   TomTomWaypoints:SetCustomWaypoint(c, z, zx, zy, cb)
--   TomTomWaypoints:SetCustomMFWaypoint(aid, _floor, zx, zy, opts)
--   TomTomWaypoints:RemoveWaypoint(uid)
--   TomTomWaypoints:SetCrazyArrow(uid, dist, name)
--   TomTomWaypoints:SetClosestWaypoint()               -> 0 (no-op)
--   TomTomWaypoints:DefaultCallbacks(opts)             -> {} stub
--   TomTomWaypoints:HandleWayCommand(message)
--
-- Implementation notes:
--   * We re-use Carbonite.Modules.Map.Targets so the integration
--     doesn't reach into Nx.Map.Maps[1] directly.
--   * Distance callbacks: the legacy code picks the SHORTEST radius
--     from the callbacks.distance table and stores that as the
--     target Radius/RadiusFunc. Behavior preserved verbatim.

local Carbonite = _G.Carbonite

local TomTomWaypoints = {}
Carbonite.Modules.Integrations = Carbonite.Modules.Integrations or {}
Carbonite.Modules.Integrations.TomTomWaypoints = TomTomWaypoints

local function NxMap()  return _G.Nx and _G.Nx.Map end
local function Map1()   local m = NxMap() return m and m.Maps and m.Maps[1] end
local function Targets() return Carbonite.Modules.Map and Carbonite.Modules.Map.Targets end

-- ----------------------------------------------------------------
-- Callbacks: project a TomTom-style callbacks table down to the
-- TargetCallbacks shape the Carbonite map uses. Each Carbonite
-- target hook adapts one TomTom hook so the parameter convention
-- matches what callers expect.
-- ----------------------------------------------------------------

local function adaptCallbacks(opts)
    local callbacks = opts and opts.callbacks
    if not callbacks then return nil end

    local result = {}

    local onclick = (callbacks.world and callbacks.world.onclick)
                 or (callbacks.minimap and callbacks.minimap.onclick)
    if onclick then
        result.OnClick = function(target)
            pcall(onclick, "onclick", nil, target.UniqueId, target.dist)
        end
    end

    local onupdate = (callbacks.world and callbacks.world.tooltip_update)
                  or (callbacks.minimap and callbacks.minimap.tooltip_update)
    if onupdate then
        result.OnTooltipUpdate = function(tooltip, target)
            pcall(onupdate, "tooltip_update", tooltip, target.UniqueId, target.dist)
        end
    end

    local onshow = (callbacks.world and callbacks.world.tooltip_show)
                or (callbacks.minimap and callbacks.minimap.tooltip_show)
    if onshow then
        result.OnTooltipShow = function(tooltip, target)
            pcall(onshow, "tooltip_show", tooltip, target.UniqueId, target.dist)
        end
    end

    return result
end

-- ----------------------------------------------------------------
-- Apply distance triggers from a TomTom callbacks table to a target.
-- ----------------------------------------------------------------

local function applyDistanceCallbacks(target, callbackT)
    if not target or not callbackT or not callbackT.distance then return end

    local minDist, minFn = math.huge, nil
    for dist, fn in pairs(callbackT.distance) do
        if dist < minDist then minDist, minFn = dist, fn end
    end
    if minDist < math.huge then
        target.Radius     = minDist
        target.RadiusFunc = minFn
    end
end

-- ----------------------------------------------------------------
-- Waypoint verbs.
-- ----------------------------------------------------------------

function TomTomWaypoints:AddWaypoint(mid, zx, zy, opts)
    opts = opts or {}
    local map = Map1()
    if not map then return end

    -- Quest watch sets an auto-target that may conflict; clear it so
    -- this waypoint takes the front position. Same as legacy.
    local Nx = _G.Nx
    if Nx and Nx.Quest and Nx.Quest.Watch and Nx.Quest.Watch.ClearAutoTarget then
        Nx.Quest.Watch:ClearAutoTarget()
    end

    local Coords = Carbonite.Modules.Map.Coords
    local wx, wy = (Coords and Coords:WorldFromZone(mid, zx * 100, zy * 100)) or 0, 0
    if Coords then wx, wy = Coords:WorldFromZone(mid, zx * 100, zy * 100) end

    local targetsMod = Targets()
    local tar = targetsMod and targetsMod:Add({
        MapId      = mid,
        TargetType = "Goto",
        TargetX1   = wx, TargetY1 = wy,
        TargetX2   = wx, TargetY2 = wy,
        TargetDisplayID = opts.worldmap_displayID or opts.minimap_displayID,
        TargetTex       = opts.worldmap_icon or opts.minimap_icon,
        TargetName      = opts.title or "",
        TargetCallbacks = adaptCallbacks(opts),
        keep            = true,
    }) or nil

    if targetsMod then targetsMod:Reorder(-1, 1) end       -- move latest to front

    return tar and tar.UniqueId
end

-- ContZone-shaped variant used by older TomTom clients.
function TomTomWaypoints:AddZWaypoint(cont, zone, zx, zy, name, _persist, _minimap, _world, callbackT)
    local map = Map1()
    if not map then return end
    local MapIDs = Carbonite.Modules.Map.MapIDs
    local mid    = MapIDs and MapIDs:GetCurrentMapId() or (map and map.MapId)
    if cont and zone and map.CZ2MapId then
        mid = map:CZ2MapId(cont, zone)
    end
    return self:SetTarget(mid, zx, zy, name, callbackT)
end

function TomTomWaypoints:SetCustomWaypoint(cont, zone, zx, zy, callbackT)
    return self:AddZWaypoint(cont, zone, zx, zy, "", false, nil, nil, callbackT)
end

function TomTomWaypoints:SetCustomMFWaypoint(aid, _floor, zx, zy, opts)
    opts = opts or {}
    return self:SetTarget(aid, zx * 100, zy * 100, opts.title, opts.callbacks)
end

function TomTomWaypoints:SetTarget(mid, zx, zy, name, callbackT)
    local map = Map1()
    if not map or not map.SetTargetXY then return end
    local tar = map:SetTargetXY(mid, zx, zy, name, true)
    local targetsMod = Targets()
    if targetsMod then targetsMod:Reorder(-1, 1) end
    applyDistanceCallbacks(tar, callbackT)
    return tar and tar.UniqueId
end

function TomTomWaypoints:RemoveWaypoint(uid)
    local targetsMod = Targets()
    if targetsMod then targetsMod:Remove(uid) end
end

function TomTomWaypoints:SetCrazyArrow(uid, dist, name)
    local targetsMod = Targets()
    if not targetsMod then return end
    local tar = targetsMod:Find(uid)
    if not tar then return end
    tar.Radius     = dist
    tar.TargetName = name
end

function TomTomWaypoints:SetClosestWaypoint()
    -- Carbonite manages target ordering itself; the closest-waypoint
    -- concept doesn't map cleanly. Real TomTom returns the uid of the
    -- waypoint it picked; we return 0 (no-op) for compatibility.
    return 0
end

function TomTomWaypoints:DefaultCallbacks(_opts)
    return { minimap = {}, world = {}, distance = {} }
end

function TomTomWaypoints:HandleWayCommand(message)
    local map = Map1()
    if map and map.SetTargetAtStr then map:SetTargetAtStr(message, true) end
end

-- ----------------------------------------------------------------
-- Rewire the legacy Nx:TT* methods to delegate into this class.
-- Done after CARBONITE_LOADED so the legacy NxMap.lua has had a
-- chance to define them first; we overwrite intentionally so all
-- TomTom-bound calls go through one place.
-- ----------------------------------------------------------------

local function rewireLegacy()
    local Nx = _G.Nx
    if not Nx then return end
    Nx.TTAddWaypoint         = function(_, m, x, y, opts)         return TomTomWaypoints:AddWaypoint(m, x, y, opts) end
    Nx.TTAddZWaypoint        = function(_, c, z, zx, zy, n, p, mm, w, cb) return TomTomWaypoints:AddZWaypoint(c, z, zx, zy, n, p, mm, w, cb) end
    Nx.TTSetCustomWaypoint   = function(_, c, z, zx, zy, cb)      return TomTomWaypoints:SetCustomWaypoint(c, z, zx, zy, cb) end
    Nx.TTSetCustomMFWaypoint = function(_, aid, fl, zx, zy, opts) return TomTomWaypoints:SetCustomMFWaypoint(aid, fl, zx, zy, opts) end
    Nx.TTSetTarget           = function(_, m, zx, zy, n, cb)      return TomTomWaypoints:SetTarget(m, zx, zy, n, cb) end
    Nx.TTRemoveWaypoint      = function(_, uid)                   TomTomWaypoints:RemoveWaypoint(uid) end
    Nx.TTSetCrazyArrow       = function(_, uid, dist, str)        TomTomWaypoints:SetCrazyArrow(uid, dist, str) end
    Nx.TTSetClosestWaypoint  = function(_)                        return TomTomWaypoints:SetClosestWaypoint() end
    Nx.TTDefaultCallbacks    = function(_, opts)                  return TomTomWaypoints:DefaultCallbacks(opts) end
    Nx.TTWayCmd              = function(_, msg)                   TomTomWaypoints:HandleWayCommand(msg) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
