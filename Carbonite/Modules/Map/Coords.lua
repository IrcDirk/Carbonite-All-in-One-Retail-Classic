-- Carbonite | Modules / Map / Coords
-- Coordinate-space conversion. Carbonite stores three coordinate
-- systems:
--   - Zone coords  (x, y in 0..1 for the current zone)
--   - World coords (x, y in continent-relative scaled units)
--   - Map ID       (Blizzard's `mapID` for the map shown)
--
-- These three were intermingled across NxMap as `Nx.Map:GetWorldPos`,
-- `Nx.Map:GetZonePos`, `Nx.Map:GetWorldRect`, and friends. This file
-- gives them a single public class. The legacy table-driven data
-- (`Nx.Map.MapWorldInfo`) is still the source of truth; this class
-- reads from it.
--
-- New code should call:
--   Carbonite.Modules.Map.Coords:WorldFromZone(mapID, x, y)
--   Carbonite.Modules.Map.Coords:ZoneFromWorld(mapID, wx, wy)
--   Carbonite.Modules.Map.Coords:GetScale(mapID)
-- The legacy Nx.Map:* methods are rewired below so old call sites
-- transparently route through the new code.

local Carbonite = _G.Carbonite

local Coords = {}
Carbonite.Modules.Map.Coords = Coords

local DEFAULT_SCALE = 10.02

-- Pull the world-info row for a map ID, following BaseMap when set so
-- micro-zones inherit their parent continent's scale.
local function rowFor(mapID)
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap or not NxMap.MapWorldInfo then return nil end
    local row = NxMap.MapWorldInfo[mapID]
    if row and row.BaseMap then row = NxMap.MapWorldInfo[row.BaseMap] end
    return row
end

function Coords:GetScale(mapID)
    local row = rowFor(mapID)
    return (row and row.Scale) or DEFAULT_SCALE
end

-- Map (zone) -> world. (mapID, x in 0..100, y in 0..100) -> (wx, wy)
function Coords:WorldFromZone(mapID, mapX, mapY)
    if mapID == 9000 then return 0, 0 end
    local row = rowFor(mapID)
    if not row then return 0, 0 end
    local scale = row.Scale
    if not row[4] or not row[5] or not scale then return 0, 0 end
    return row[4] + mapX * scale,
           row[5] + mapY * scale / 1.5
end

-- World -> map (zone). (mapID, wx, wy) -> (x in 0..100, y in 0..100)
function Coords:ZoneFromWorld(mapID, worldX, worldY)
    local row = rowFor(mapID)
    if not row or not row.Scale or not row[4] or not row[5] then return 0, 0 end
    local scale = row.Scale
    return (worldX - row[4]) / scale,
           (worldY - row[5]) / scale * 1.5
end

-- Rectangle convenience: both corners in one call.
function Coords:WorldRectFromZone(mapID, x1, y1, x2, y2)
    local wx1, wy1 = self:WorldFromZone(mapID, x1, y1)
    local wx2, wy2 = self:WorldFromZone(mapID, x2, y2)
    return wx1, wy1, wx2, wy2
end

-- Yard distance estimate between two world points on the same scale.
-- The legacy code multiplies world units by zoneScale * 4.575 to get
-- yards; encapsulate that constant here.
function Coords:YardsBetween(mapID, wx1, wy1, wx2, wy2)
    local scale = self:GetScale(mapID)
    local dx, dy = wx2 - wx1, wy2 - wy1
    return math.sqrt(dx * dx + dy * dy) * scale * 4.575
end

-- Rewire the legacy table-method versions onto Coords so every
-- existing caller in NxMap.lua flows through this class. Done after
-- ADDON_LOADED so the legacy NxMap.lua has had a chance to create
-- Nx.Map and populate MapWorldInfo.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.GetWorldZoneScale = function(self, mapID) return Coords:GetScale(mapID) end
    NxMap.GetWorldPos       = function(self, mapID, x, y) return Coords:WorldFromZone(mapID, x, y) end
    NxMap.GetZonePos        = function(self, mapID, wx, wy) return Coords:ZoneFromWorld(mapID, wx, wy) end
    NxMap.GetWorldRect      = function(self, mapID, x1, y1, x2, y2)
        return Coords:WorldRectFromZone(mapID, x1, y1, x2, y2)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
