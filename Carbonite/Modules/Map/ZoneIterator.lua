-- Carbonite | Modules / Map / ZoneIterator
-- Iteration + lookup helpers across the legacy zone data tables
-- (Nx.Map.MapInfo, Nx.Map.MapZones, Nx.Map.MapWorldInfo). Old code
-- queried these directly from a dozen places; this class is the
-- single canonical accessor so renderers, options pages, and other
-- modules don't have to know the table shapes.
--
--   ZoneIterator:GetContinent(contN)      -> name, x, y
--   ZoneIterator:GetZoneInfo(cont, zone)  -> name, x, y, w, h
--   ZoneIterator:GetZone(mapID)           -> info table (Cont/Zone/Scale/etc.)
--   ZoneIterator:EachContinent(fn)        -> iterates all continents
--   ZoneIterator:EachZoneInContinent(c,fn)-> iterates zones in c
--   ZoneIterator:GetContinentCount()      -> int

local Carbonite = _G.Carbonite
local ZoneIterator = {}
Carbonite.Modules.Map.ZoneIterator = ZoneIterator

local function NxMap() return _G.Nx and _G.Nx.Map end

-- Parent-map cache. The legacy code kept a ParentMapCache file-local
-- in NxMap.lua; we mirror it here so cache lookups remain shared
-- between this class and any rewired legacy reader.
local parentCache = {}

function ZoneIterator:GetContinent(cont)
    local m = NxMap()
    if not m or not m.MapInfo then return nil end
    local info = m.MapInfo[cont]
    if _G.Nx and _G.Nx.inBG then info = m.MapInfo[90] end
    if not info then return nil end
    return info.Name, info.X, info.Y
end

function ZoneIterator:GetZoneInfo(cont, zone)
    local m = NxMap()
    if not m or not cont or not zone then
        return "unknown", 0, 0, 1002, 668
    end

    local name = (m.GetMapNameByID and m:GetMapNameByID(zone)) or "Unknown Zone"
    local info = m.MapInfo and m.MapInfo[cont]
    if not info then return name, 0, 0, 1002, 668 end

    local origZone = zone
    if zone == 0 and m.MapZones and m.MapZones[0] then
        zone = m.MapZones[0][cont]
    end

    local winfo = m.MapWorldInfo and m.MapWorldInfo[zone]
    if not winfo then
        winfo = parentCache[zone]
        if not winfo or not next(winfo) then
            return name, 0, 0, 1002, 668
        end
    end
    if not winfo.X then return name, 0, 0, 1002, 668 end

    local x = info.X + winfo.X
    local y = info.Y + winfo.Y
    local scale = (winfo.Scale or 1) * 100

    return name, x, y, scale, scale / 1.5
end

function ZoneIterator:GetZone(mapID)
    local m = NxMap()
    if not m then return {} end

    if m.MapWorldInfo and m.MapWorldInfo[mapID] then
        return m.MapWorldInfo[mapID]
    end

    if parentCache[mapID] ~= nil then return parentCache[mapID] end

    local mapInfo = _G.C_Map and _G.C_Map.GetMapInfo and _G.C_Map.GetMapInfo(mapID)
    if mapInfo and mapInfo.parentMapID and m.MapWorldInfo then
        local parentInfo = m.MapWorldInfo[mapInfo.parentMapID]
        if parentInfo then
            local enum = _G.Enum and _G.Enum.UIMapType
            local isCityType = enum and (mapInfo.mapType == enum.Zone or mapInfo.mapType == enum.Orphan)
            if isCityType and parentInfo.City then
                parentCache[mapID] = parentInfo
                return parentInfo
            end
        end
    end

    parentCache[mapID] = {}
    return {}
end

function ZoneIterator:GetContinentCount()
    local m = NxMap()
    return m and m.ContCnt or 0
end

function ZoneIterator:EachContinent(fn)
    local count = self:GetContinentCount()
    for n = 1, count do
        local name, x, y = self:GetContinent(n)
        if name then fn(n, name, x, y) end
    end
end

function ZoneIterator:EachZoneInContinent(cont, fn)
    local m = NxMap()
    if not m or not m.MapZones or not m.MapZones[cont] then return end
    for _, zoneID in pairs(m.MapZones[cont]) do
        local name, x, y, w, h = self:GetZoneInfo(cont, zoneID)
        fn(zoneID, name, x, y, w, h)
    end
end

-- Rewire legacy entry points so existing callers route through here.
-- Note: GetWorldZoneScale stays in Coords.lua (already extracted).
local function rewireLegacy()
    local m = NxMap()
    if not m then return end
    m.GetWorldContinentInfo = function(_, cont)        return ZoneIterator:GetContinent(cont) end
    m.GetWorldZoneInfo      = function(_, cont, zone)  return ZoneIterator:GetZoneInfo(cont, zone) end
    m.GetWorldZone          = function(_, mapID)       return ZoneIterator:GetZone(mapID) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
