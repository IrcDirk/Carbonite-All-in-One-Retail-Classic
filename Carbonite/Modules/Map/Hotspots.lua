-- Carbonite | Modules / Map / Hotspots
-- Spatial lookup table for "interesting" map regions - quest hubs,
-- cities, starting zones, dungeon entrances. The legacy implementation
-- baked this into Nx.Map:InitHotspots which assembled two long arrays
-- (`WorldHotspots` and `WorldHotspotsCity`) at startup. This class
-- exposes the same data through a stable, query-friendly API.
--
-- Source data:
--   Nx.MapWorldHotspots   - per-continent string (4-byte packed rects)
--   Nx.MapWorldHotspots2  - per-map-id string (12-byte packed wide rects)
--   Nx.Map.MapZones       - continent -> zone-list
--   Nx.Zones              - zone descriptions (level / faction)
--
-- A "hotspot" entry:
--   mapID, zx, zy        - zone-space anchor (0..100)
--   WX1/WY1/WX2/WY2      - world-space bounding rect
--   NxTipBase            - prebuilt tooltip header text
--   city                 - true if part of the city subset

local Carbonite = _G.Carbonite
local Hotspots = {}
Carbonite.Modules.Map.Hotspots = Hotspots

local function nxMap() return _G.Nx and _G.Nx.Map end

local function unpackWideLoc(s)
    -- 12-byte packed: x(3) y(3) w(3) h(3) hex
    local zx = tonumber(s:sub(1, 3),  16) * 100  / 4095
    local zy = tonumber(s:sub(4, 6),  16) * 100  / 4095
    local zw = tonumber(s:sub(7, 9),  16) * 1002 / 4095
    local zh = tonumber(s:sub(10,12), 16) * 668  / 4095
    return zx, zy, zw, zh
end

local function unpackSmallLoc(NxMap, s)
    -- 4-byte legacy format. Delegated to the legacy unpacker because
    -- it depends on a continent-relative offset table baked in NxMap.
    if NxMap and NxMap.UnpackLocRect then
        return NxMap:UnpackLocRect(s)
    end
    return 0, 0, 0, 0
end

-- Build the hotspot arrays. Returns (general, city). Idempotent.
function Hotspots:Build()
    local NxMap = nxMap()
    if not NxMap or not NxMap.ContCnt or not NxMap.MapZones then return {}, {} end

    local Nx = _G.Nx
    local general, city = {}, {}

    for contN = 1, NxMap.ContCnt do
        local cname = NxMap.GetWorldContinentInfo and NxMap:GetWorldContinentInfo(contN)
        if not cname then break end

        for _, zoneN in pairs(NxMap.MapZones[contN] or {}) do
            local zname = NxMap.GetWorldZoneInfo and NxMap:GetWorldZoneInfo(contN, zoneN)
            if not zname then break end

            -- Tooltip header built once per zone so per-spot iteration
            -- in the map renderer can copy it cheaply.
            local color, infoStr = "|cffffffff", ""
            if Carbonite.Modules.Map.MapIDs then
                color, infoStr = Carbonite.Modules.Map.MapIDs:GetZoneDescription(zoneN)
            end
            local tipStr = ("%s, %s%s (%s)"):format(cname, color, zname, infoStr)

            local mapId = zoneN
            local loc      = Nx.MapWorldHotspots and Nx.MapWorldHotspots[zoneN]
            local locSize  = 4
            if not loc then
                loc = Nx.MapWorldHotspots2 and Nx.MapWorldHotspots2[mapId]
                if loc then
                    locSize = 12
                else
                    loc = string.char(85, 85, 135, 135)  -- default 4-byte rect
                end
            end

            local wzone = NxMap.GetWorldZone and NxMap:GetWorldZone(mapId) or {}
            local target = (wzone.City or wzone.StartZone) and city or general

            for n = 0, 100 do
                local i = n * locSize + 1
                local chunk = loc:sub(i, i + locSize - 1)
                if chunk == "" then break end

                local zx, zy, zw, zh
                if locSize == 4 then
                    zx, zy, zw, zh = unpackSmallLoc(NxMap, chunk)
                else
                    zx, zy, zw, zh = unpackWideLoc(chunk)
                end

                local spot = {
                    mapID = mapId,
                    zx    = zx,
                    zy    = zy,
                    x     = tonumber(chunk:sub(1, 3), 16) or 0,
                    y     = tonumber(chunk:sub(4, 6), 16) or 0,
                    NxTipBase = tipStr,
                    city  = wzone.City or wzone.StartZone or false,
                }

                if NxMap.GetWorldPos then
                    spot.WX1, spot.WY1 = NxMap:GetWorldPos(mapId, zx, zy)
                    local zw100 = zw / 1002 * 100
                    local zh100 = zh / 668  * 100
                    spot.WX2, spot.WY2 = NxMap:GetWorldPos(mapId, zx + zw100, zy + zh100)
                end

                target[#target + 1] = spot
            end
        end
    end

    self.general = general
    self.city = city

    -- Mirror onto legacy field names so existing readers find them.
    if NxMap then
        NxMap.WorldHotspots = general
        NxMap.WorldHotspotsCity = city
    end

    return general, city
end

function Hotspots:General() return self.general or {} end
function Hotspots:Cities()  return self.city or {} end

-- Iterate spots for a specific map ID. Linear scan; the dataset is
-- small enough (~2-3K spots total) that any index would be overkill.
function Hotspots:Each(mapID, fn)
    for _, spot in ipairs(self.general or {}) do
        if spot.mapID == mapID then fn(spot) end
    end
    for _, spot in ipairs(self.city or {}) do
        if spot.mapID == mapID then fn(spot) end
    end
end

-- Rewire the legacy entry point.
local function rewireLegacy()
    local NxMap = nxMap()
    if not NxMap then return end
    NxMap.InitHotspots = function(_) Hotspots:Build() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
