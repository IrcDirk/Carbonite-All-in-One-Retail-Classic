-- Carbonite | Modules / Map / Pathing
-- Centralized path / route calculation. Owns the algorithms that
-- used to live spread across Nx.Map:Route* (in NxMap.lua) and
-- Nx.Travel:MakePath (in NxTravel.lua):
--
--   PlanRoute(points, opts)   - nearest-neighbor seed + 2-opt refinement
--   OptimizeRoute(route)      - single 2-opt pass over an existing ordering
--   MergePoints(points, opts) - merge points within a yard radius
--   RouteLength(route)        - total length; also stamps per-node Dist
--   ReverseSegment(route, first, len) - in-place 2-opt swap helper
--   BuildPath(src, dst, opts) - inter-zone path via Travel.MakePath
--
-- Old call sites (Nx.Map:RouteGathers / RouteTargets / RouteQuests /
-- RouteMerge / Route / RouteLen / RouteOptimize / RouteSwap) are
-- rewired below so every caller goes through this module.

local Carbonite = _G.Carbonite

local Pathing = {}
Carbonite.Modules.Map.Pathing = Pathing

local log = Carbonite.Core.Logger and Carbonite.Core.Logger:Get("Pathing")

-- --------------------------------------------------------------------------
-- Geometry helpers. All distances are computed in the (X, Y/1.5) coordinate
-- system the legacy router used; Y is squashed to make 1 unit X = 1 unit Y
-- visually because zone tiles are 1.5x taller than they are wide.
-- --------------------------------------------------------------------------

local function distSq(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

local function dist(ax, ay, bx, by)
    return math.sqrt(distSq(ax, ay, bx, by))
end

-- --------------------------------------------------------------------------
-- MergePoints: collapse points within `radius` (yards) into their midpoint.
-- Reduces input size before running the more expensive route optimizer.
-- Operates on the array in place; returns it for chaining.
-- --------------------------------------------------------------------------

function Pathing:MergePoints(points, opts)
    opts = opts or {}
    local radiusYards = opts.radiusYards or 0
    local zoneScale = opts.zoneScale or 1

    if #points < 2 or radiusYards < 1 then return points end

    -- The legacy code divides by zoneScale * 4.575 to convert yards into the
    -- map's normalized world units. Same constant kept for behavioral parity.
    local radius = radiusYards / zoneScale / 4.575
    local radiusSq = radius * radius

    table.sort(points, function(a, b) return a.X < b.X end)

    local merged = true
    local startCount = #points
    while merged do
        merged = false
        local closest, closeI1, closeI2 = math.huge, nil, nil

        for n1 = 1, #points do
            local pt1 = points[n1]
            for n2 = n1 + 1, #points do
                local pt2 = points[n2]
                if pt2.X - pt1.X > radius then break end       -- sweep prune
                -- y is squashed by 1.5 for visual-isotropic distance
                local dy = (pt1.Y - pt2.Y) / 1.5
                local dx = pt1.X - pt2.X
                local d = dx * dx + dy * dy
                if d < closest then
                    closest, closeI1, closeI2 = d, n1, n2
                end
            end
        end

        if closest < radiusSq then
            local p1, p2 = points[closeI1], points[closeI2]
            p1.X = (p1.X + p2.X) * 0.5
            p1.Y = (p1.Y + p2.Y) * 0.5
            table.remove(points, closeI2)
            merged = true
            table.sort(points, function(a, b) return a.X < b.X end)
        end
    end

    if log then log:debug("MergePoints: %d -> %d (radius %.1f yd)", startCount, #points, radiusYards) end
    return points
end

-- --------------------------------------------------------------------------
-- RouteLength: total length of a route, also stamping per-node `Dist`
-- so OptimizeRoute can do its arithmetic without recomputing twice.
-- --------------------------------------------------------------------------

function Pathing:RouteLength(route)
    local len = 0
    for n = 1, #route - 1 do
        local r1, r2 = route[n], route[n + 1]
        r1.Dist = dist(r1.X, r1.Y, r2.X, r2.Y)
        len = len + r1.Dist
    end
    return len
end

-- --------------------------------------------------------------------------
-- ReverseSegment: in-place segment reversal used by 2-opt. After reversal
-- the per-node Dist values around the segment are recomputed so successive
-- swaps remain valid.
-- Example: 1 2 3 4 5 6 7 8 with (3, 4) becomes 1 2 6 5 4 3 7 8
-- --------------------------------------------------------------------------

function Pathing:ReverseSegment(route, first, len)
    local last = first + len - 1
    local stop = first + math.floor(len / 2) - 1

    local n2 = last
    for n = first, stop do
        route[n], route[n2] = route[n2], route[n]
        n2 = n2 - 1
    end

    for n = math.max(first - 1, 1), math.min(last, #route - 1) do
        local r1, r2 = route[n], route[n + 1]
        if r1 and r2 then
            r1.Dist = dist(r1.X, r1.Y, r2.X, r2.Y)
        end
    end
end

-- --------------------------------------------------------------------------
-- OptimizeRoute: one pass of 2-opt across all (i, j) segments. Returns
-- true if at least one swap improved the route, allowing the caller to
-- iterate until no further gains.
-- --------------------------------------------------------------------------

function Pathing:OptimizeRoute(route)
    local swap = false
    for len = #route - 2, 2, -1 do
        for n = 1, #route - len - 1 do
            local r1 = route[n]
            local r2 = route[n + 1]
            local n2 = n + len
            local r3 = route[n2]
            local r4 = route[n2 + 1]

            if r1.Dist + r3.Dist > dist(r1.X, r1.Y, r3.X, r3.Y) + dist(r2.X, r2.Y, r4.X, r4.Y) then
                self:ReverseSegment(route, n + 1, len)
                swap = true
            end
        end
    end
    return swap
end

-- --------------------------------------------------------------------------
-- PlanRoute: full pipeline.
--   opts.startX, opts.startY     starting position (player by default)
--   opts.optimizeRounds          number of 2-opt passes; default 5
--   opts.closeLoop               when true (default) appends start node to
--                                end of route so player can loop back
-- Input points are CONSUMED. Each must have X, Y; Name and Weight are
-- propagated to the output route.
-- --------------------------------------------------------------------------

function Pathing:PlanRoute(points, opts)
    if not points or #points == 0 then return nil end
    opts = opts or {}

    local startTime = GetTime and GetTime() or 0

    -- Squash Y into X units. Restored by caller via RouteToTargets.
    for _, pt in ipairs(points) do pt.Y = pt.Y / 1.5 end

    -- If the input loops back to its start, drop the duplicate endpoint.
    if #points > 1 then
        local last = points[#points]
        if last.X == points[1].X and last.Y == points[1].Y then
            table.remove(points)
        end
    end

    -- Nearest-neighbor seed from the supplied start position.
    local x = opts.startX or 0
    local y = (opts.startY or 0) / 1.5

    local route = {}
    while #points > 0 do
        local best, bestI = math.huge, nil
        for n, pt in ipairs(points) do
            local d = distSq(x, y, pt.X, pt.Y)
            if d < best then best, bestI = d, n end
        end

        local pt = table.remove(points, bestI)
        table.insert(route, {
            X      = pt.X,
            Y      = pt.Y,
            Name   = pt.Name,
            Weight = pt.Weight or 1,
        })
        x, y = pt.X, pt.Y
    end

    -- Close the loop so the player ends where they started.
    if opts.closeLoop ~= false then
        local first = route[1]
        local last  = route[#route]
        if first and (first.X ~= last.X or first.Y ~= last.Y) then
            table.insert(route, { X = first.X, Y = first.Y })
        end
    end

    self:RouteLength(route)

    -- 2-opt refinement, capped so a degenerate input cannot stall the client.
    for _ = 1, (opts.optimizeRounds or 5) do
        if not self:OptimizeRoute(route) then break end
    end

    if log then
        local elapsed = GetTime and (GetTime() - startTime) or 0
        log:debug("PlanRoute: %d nodes, length %.1f, %.2fs", #route, self:RouteLength(route), elapsed)
    end

    return route
end

-- --------------------------------------------------------------------------
-- BuildPath: build a cross-zone path between two world points. This is
-- the high-level API every caller should use; the heavy graph traversal
-- still lives in Nx.Travel:MakePath, but Pathing is the single front
-- door so call sites do not couple to the legacy table directly.
--
-- HOT PATH: called from CalcTracking once per waypoint per ~45 frames.
-- Takes scalar arguments rather than a {mapID=..., x=..., y=...}
-- table because allocating wrapper tables here was a measurable
-- per-frame leak (every CalcTracking pulse cost #targets * 2 table
-- allocations). Callers that want the table-arg ergonomics can use
-- BuildPathFromSpec below; do NOT use it on hot paths.
--
--   BuildPath(tracking, srcMapID, srcX, srcY, dstMapID, dstX, dstY, dstType)
-- --------------------------------------------------------------------------

function Pathing:BuildPath(tracking, srcMapID, srcX, srcY, dstMapID, dstX, dstY, dstType)
    local Travel = Carbonite.Travel or (Carbonite.Modules and Carbonite.Modules.Map and Carbonite.Modules.Map.Travel)
    if Travel and Travel.MakePath then
        return Travel:MakePath(tracking, srcMapID, srcX, srcY, dstMapID, dstX, dstY, dstType)
    end
    if log then log:warn("BuildPath: Travel module not available") end
    return nil
end

-- Table-arg variant for one-shot callers (slash commands, debug
-- tooling). Allocates: do not use in a per-frame path.
function Pathing:BuildPathFromSpec(tracking, src, dst)
    if not src or not dst then return nil end
    return self:BuildPath(tracking,
        src.mapID, src.x, src.y,
        dst.mapID, dst.x, dst.y, dst.type)
end

-- --------------------------------------------------------------------------
-- Legacy compatibility: rewire Nx.Map:Route* into Pathing so all the
-- existing call sites in NxMap.lua continue to work but the actual
-- algorithm runs from this class. Done lazily (subscribed on enable)
-- because Nx.Map is created by the legacy NxMap.lua at file-load time,
-- which happens before Carbonite is enabled.
-- --------------------------------------------------------------------------

local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end

    NxMap.Route = function(self, points)
        local plyrX, plyrY = self.PlyrX or 0, self.PlyrY or 0
        local startX, startY = self:GetZonePos(self.MapId, plyrX, plyrY)
        return Pathing:PlanRoute(points, { startX = startX, startY = startY })
    end

    NxMap.RouteMerge = function(self, points)
        local radius = (_G.Nx.db and _G.Nx.db.profile and _G.Nx.db.profile.Route)
            and _G.Nx.db.profile.Route.MergeRadius or 0
        local zoneScale = self.GetWorldZoneScale and self:GetWorldZoneScale(self.MapId) or 1
        return Pathing:MergePoints(points, {
            radiusYards = radius,
            zoneScale = zoneScale,
        })
    end

    NxMap.RouteLen = function(_, route)
        return Pathing:RouteLength(route)
    end

    NxMap.RouteOptimize = function(_, route)
        return Pathing:OptimizeRoute(route)
    end

    NxMap.RouteSwap = function(_, route, first, len)
        return Pathing:ReverseSegment(route, first, len)
    end

    if log then log:debug("Legacy Nx.Map routing functions rewired to Pathing") end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
-- ADDON_LOADED also useful because NxMap.lua runs during ADDON_LOADED,
-- before PLAYER_LOGIN. Try then too for fastest takeover.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
