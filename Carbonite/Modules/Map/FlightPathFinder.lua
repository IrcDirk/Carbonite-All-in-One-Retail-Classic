-- Carbonite | Modules / Map / FlightPathFinder
-- Wraps Nx.Travel:FindFlight, the search that picks the best
-- (source flight master, destination flight master) pair for a
-- given world-position pair. The legacy implementation lives in
-- NxTravel.lua because it traverses Nx.Travel.Travel[continent]
-- and uses the captured TaxiTable to filter unreachable masters;
-- this class is the public accessor + a tiny convenience layer.
--
-- Public API:
--   FlightPathFinder:Find(src, dst)        -> totalDist, path
--   FlightPathFinder:CanFly(srcMapID, dstMapID) -> bool
--   FlightPathFinder:GetSpeedMultiplier()  -> world units per second
--
-- `src` / `dst` are { mapID, x, y } tables. The returned `path`
-- matches the legacy shape (two-node array with Flight = true on the
-- destination) so the existing MakePath consumer logic keeps working.

local Carbonite = _G.Carbonite

local FlightPathFinder = {}
Carbonite.Modules.Map.FlightPathFinder = FlightPathFinder

local function travel() return _G.Nx and _G.Nx.Travel end

function FlightPathFinder:Find(src, dst)
    if not src or not dst then return nil end
    local t = travel()
    if not t or not t.FindFlight then return nil end
    return t:FindFlight(src.mapID, src.x, src.y, dst.mapID, dst.x, dst.y)
end

-- Quick "is there any flight path between these two zones?" query
-- without computing the full route. Uses the closest-FM helper which
-- is cheap (a linear scan over per-continent FM list).
function FlightPathFinder:CanFly(srcMapID, dstMapID)
    local t = travel()
    if not t or not t.FindClosest then return false end
    local d1, n1 = t:FindClosest(srcMapID, 0, 0)
    if not n1 then return false end
    local d2, n2 = t:FindClosest(dstMapID, 0, 0)
    return n2 ~= nil and (n1.Name ~= n2.Name)
end

function FlightPathFinder:GetSpeedMultiplier()
    local t = travel()
    return t and t.Speed or 0
end
