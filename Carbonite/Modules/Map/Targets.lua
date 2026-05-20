-- Carbonite | Modules / Map / Targets
-- Waypoint / target queue. The legacy code stored an array of target
-- tables on each Nx.Map.Maps[n] instance and exposed verbs through
-- Nx.Map:SetTarget / ClearTarget / FindTarget / etc. This class owns
-- the queue verbs (the actual rendering still belongs to the Map
-- window) and provides a stable API for other modules:
--
--   Targets:Add({ ... })            adds and returns the target
--   Targets:Remove(uniqueId)        removes by id; returns boolean
--   Targets:Clear(matchType)        clears all (or only if first matches type)
--   Targets:Reorder(srcIdx, dstIdx) moves a target inside the queue
--   Targets:Reverse()               reverses the queue
--   Targets:Each(fn)                iterates in queue order
--   Targets:GetFirst()              returns front of queue (or nil)
--   Targets:Count()
--
-- The first ever target gets a fresh UniqueId; subsequent calls reuse
-- the legacy counter on the map instance. Other modules should use
-- the Carbonite.Modules.Map.Targets entry point rather than reaching
-- into Nx.Map.Maps[1].Targets directly.

local Carbonite = _G.Carbonite

local Targets = {}
Carbonite.Modules.Map.Targets = Targets

local function primaryMap()
    local NxMap = _G.Nx and _G.Nx.Map
    return NxMap and NxMap.Maps and NxMap.Maps[1]
end

local function bumpUid(map)
    map._NextUid = (map._NextUid or 0) + 1
    return map._NextUid
end

-- Add a target. Accepts the same shape the legacy Nx.Map:AddTarget
-- used: a table with MapId / TargetType / TargetX1 / etc. Returns the
-- created target table (now in self.Targets).
function Targets:Add(spec)
    local map = primaryMap()
    if not map then return nil end

    spec = spec or {}
    spec.UniqueId = spec.UniqueId or bumpUid(map)
    map.Targets = map.Targets or {}

    -- The legacy Nx.Map:AddTarget had extra side effects around
    -- "keep" (preserve existing targets) and scale capture. Honor
    -- those behaviors for backwards compat.
    if not spec.keep then map.Targets = {} end

    table.insert(map.Targets, spec)
    map.Tracking = {}        -- invalidate the cached tracking path

    Carbonite.Core.EventBus:Fire("MAP_TARGET_ADDED", spec)
    return spec
end

function Targets:Find(uniqueId)
    local map = primaryMap()
    if not map then return nil end
    for i, t in ipairs(map.Targets or {}) do
        if t.UniqueId == uniqueId then return t, i end
    end
    return nil
end

function Targets:Remove(uniqueId)
    local map = primaryMap()
    if not map then return false end
    local _, i = self:Find(uniqueId)
    if not i then return false end
    table.remove(map.Targets, i)
    map.Tracking = {}
    Carbonite.Core.EventBus:Fire("MAP_TARGET_REMOVED", uniqueId)
    return true
end

function Targets:Clear(matchType)
    local map = primaryMap()
    if not map then return end

    if matchType then
        local first = map.Targets and map.Targets[1]
        if not first or first.TargetType ~= matchType then return end
    end

    map.Targets  = {}
    map.Tracking = {}
    Carbonite.Core.EventBus:Fire("MAP_TARGETS_CLEARED", matchType)
end

function Targets:Reorder(srcIdx, dstIdx)
    local map = primaryMap()
    if not map or not map.Targets then return end
    srcIdx = (srcIdx and srcIdx >= 0) and srcIdx or #map.Targets
    local t = table.remove(map.Targets, srcIdx)
    if t then table.insert(map.Targets, dstIdx, t) end
    map.Tracking = {}
end

function Targets:Reverse()
    local map = primaryMap()
    if not map or not map.Targets then return end
    local t = map.Targets
    local hi = #t
    for lo = 1, math.floor(hi / 2) do
        t[lo], t[hi] = t[hi], t[lo]
        hi = hi - 1
    end
    map.Tracking = {}
end

function Targets:Each(fn)
    local map = primaryMap()
    if not map or not map.Targets then return end
    for i, t in ipairs(map.Targets) do fn(t, i) end
end

function Targets:GetFirst()
    local map = primaryMap()
    return map and map.Targets and map.Targets[1] or nil
end

function Targets:Count()
    local map = primaryMap()
    return map and map.Targets and #map.Targets or 0
end

-- Convenience: header info accessors used by HUD / quest tracker.
function Targets:GetFirstInfo()
    local t = self:GetFirst()
    if not t then return nil end
    return t.TargetType, t.TargetId
end

function Targets:GetFirstPosition()
    local t = self:GetFirst()
    if not t then return nil end
    return t.TargetX1, t.TargetY1, t.TargetX2, t.TargetY2
end

function Targets:SetFirstName(name)
    local t = self:GetFirst()
    if t then t.TargetName = name end
end

-- Legacy rewire. The legacy methods stay reachable for legacy code,
-- but they now call into this class. Note: Nx.Map:SetTarget keeps its
-- positional-arg signature for callers that don't know about AddTarget.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end

    NxMap.SetTarget = function(self, typ, x1, y1, x2, y2, tex, id, name, keep, mapId)
        return Targets:Add({
            MapId      = mapId,
            TargetType = typ,
            TargetX1   = x1, TargetY1 = y1,
            TargetX2   = x2, TargetY2 = y2,
            TargetTex  = tex,
            TargetId   = id,
            TargetName = name,
            keep       = keep,
        })
    end
    NxMap.ClearTargets       = function(_, matchType) Targets:Clear(matchType) end
    NxMap.ClearTarget        = function(_, uid)       Targets:Remove(uid) end
    NxMap.FindTarget         = function(_, uid)       return Targets:Find(uid) end
    NxMap.ChangeTargetOrder  = function(_, src, dst)  Targets:Reorder(src, dst) end
    NxMap.ReverseTargets     = function(_)            Targets:Reverse() end
    NxMap.SetTargetName      = function(_, name)      Targets:SetFirstName(name) end
    NxMap.GetTargetInfo      = function(_)            return Targets:GetFirstInfo() end
    NxMap.GetTargetPos       = function(_)            return Targets:GetFirstPosition() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
