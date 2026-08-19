-- Carbonite | Modules / Map / MapIDs
-- Map-ID identification and classification. Sits beside Coords:
-- Coords converts between coordinate spaces; MapIDs answers "which
-- map is the player on?" and "what kind of map is this?" questions.
-- The legacy Nx.Map:* equivalents are rewired to delegate here so
-- there is one place to fix when Blizzard renames a C_Map API again.

local Carbonite = _G.Carbonite

local MapIDs = {}
Carbonite.Modules.Map.MapIDs = MapIDs

-- Per-process cache for IdToContZone lookups (the legacy code had
-- this as a file-local `ContZoneCache`).
local contZoneCache = {}
local playerMapAliasCache = {}

local function nxMap() return _G.Nx and _G.Nx.Map end

-- ---------------------------------------------------------------------
-- "Current" map ID. There are three concepts here:
--   1) The Blizzard-displayable map for the player's actual location
--      (returned by MapUtil.GetDisplayableMapForPlayer).
--   2) The map the user is hovering / has zoomed into on the open
--      WorldMapFrame (returned by WorldMapFrame:GetMapID()).
--   3) Carbonite's internal RMapId, which is normally the displayable
--      map but can be sentinel 9000 when no zone is selected.
-- ---------------------------------------------------------------------

-- Convert a Blizzard player/art map alias to the canonical Carbonite map ID.
-- Most maps are already canonical. A small number of layered cities are not:
-- MoP Undercity, for example, is reported as uiMapID 998 while Carbonite's
-- world geometry and quest data intentionally remain keyed by city ID 90.
function MapIDs:CanonicalizeMapID(mapID)
    if not mapID or mapID == 0 then return mapID end

    local NxMap = nxMap()
    local worldInfo = NxMap and NxMap.MapWorldInfo
    if not worldInfo then return mapID end

    local cached = playerMapAliasCache[mapID]
    if cached then return cached end

    for canonicalID, info in pairs(worldInfo) do
        local aliases = info and info.PlayerMapID
        if aliases == mapID then
            playerMapAliasCache[mapID] = canonicalID
            return canonicalID
        elseif type(aliases) == "table" then
            for _, aliasID in pairs(aliases) do
                if aliasID == mapID then
                    playerMapAliasCache[mapID] = canonicalID
                    return canonicalID
                end
            end
        end
    end

    -- Explicit aliases win even if another subsystem has already created a
    -- transient MapWorldInfo entry for Blizzard's alias ID.
    playerMapAliasCache[mapID] = mapID
    return mapID
end

-- Displayable map for the player, with Carbonite city aliases and the legacy
-- OldMapIDs remap applied (1414 → 12, 1415 → 13 on pre-MoP clients).
function MapIDs:GetDisplayableMapForPlayer()
    local MapUtil = _G.MapUtil
    local C_Map = _G.C_Map
    local rawMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local displayableMapID = (MapUtil and MapUtil.GetDisplayableMapForPlayer and MapUtil.GetDisplayableMapForPlayer())
        or rawMapID
        or 0

    -- Blizzard's displayable helper deliberately climbs away from maps that
    -- have no C_Map art. Carbonite can still render its legacy city tiles, so
    -- retain a raw city map only when its flavor data declares legacy art
    -- (Exodar is the common MoP example), and canonicalize aliases such as
    -- Undercity 998 → 90. Every other map keeps Blizzard's displayable-parent
    -- behavior.
    local rawCanonicalID = self:CanonicalizeMapID(rawMapID)
    local NxMap = nxMap()
    local rawInfo = NxMap and NxMap.MapWorldInfo and NxMap.MapWorldInfo[rawCanonicalID]
    local mapID = rawInfo and rawInfo.City and rawInfo.LegacyMapArt and rawCanonicalID
        or self:CanonicalizeMapID(displayableMapID)
        or 0

    if _G.Nx and _G.Nx.OldMapIDs then
        if mapID == 1414 then return 12 end
        if mapID == 1415 then return 13 end
    end
    return mapID
end

-- The map ID Carbonite considers "current" - prefers the open map's
-- selection when the user is hovering it.
function MapIDs:GetCurrentMapAreaID()
    local displayable = self:GetDisplayableMapForPlayer()
    local NxMap = nxMap()
    -- Use Carbonite's resolved hovered zone (MouseIsOverMap), not
    -- WorldMapFrame:GetMapID(). Reading the Blizzard frame would require
    -- SetMapID'ing into it from insecure code, tainting its data providers
    -- (SetPassThroughButtons block on world-quest pins).
    local playerMapInfo = NxMap and NxMap.MapWorldInfo
        and NxMap.MapWorldInfo[displayable]
    local mapID = displayable

    -- Standalone areas such as Emerald Dreamway have their own instance-style
    -- map, but GetInstanceInfo reports "none". Their outdoor entry-zone
    -- hotspot overlaps Carbonite's synthetic map anchor and must not replace
    -- the player's actual map when the map or minimap receives mouse focus.
    if not (playerMapInfo and playerMapInfo.Instance) then
        mapID = (NxMap and NxMap.MouseOver and NxMap.MouseIsOverMap)
            or displayable
    end

    -- Instance maps always use the displayable one because
    -- WorldMapFrame:GetMapID() can lag behind on first entry. The
    -- nil-guard handles environments where GetInstanceInfo is not
    -- yet available (e.g. before login or in static analysis).
    if _G.GetInstanceInfo then
        local _, instanceType = _G.GetInstanceInfo()
        if instanceType ~= nil and instanceType ~= "none" then
            mapID = displayable
        end
    end

    if _G.Nx and _G.Nx.OldMapIDs then
        if mapID == 1414 then mapID = 12 end
        if mapID == 1415 then mapID = 13 end
    end
    return mapID
end

-- Carbonite's primary "current map" used by every routing and pin
-- query. Returns RMapId unless that is the no-zone sentinel.
function MapIDs:GetCurrentMapId()
    local NxMap = nxMap()
    if not NxMap then return self:GetCurrentMapAreaID() end
    if NxMap.RMapId == 9000 then return self:GetCurrentMapAreaID() end
    return NxMap.RMapId
end

-- ---------------------------------------------------------------------
-- Continent / zone lookup with cache. The legacy code returned
-- (Cont or 90, Zone or 0); 90 was the sentinel for "unknown
-- continent". Behavior preserved verbatim.
-- ---------------------------------------------------------------------

function MapIDs:IdToContZone(mapID)
    local NxMap = nxMap()
    local info = NxMap and NxMap.MapWorldInfo and NxMap.MapWorldInfo[mapID]
    if info then
        return info.Cont or 90, info.Zone or 0
    end

    if contZoneCache[mapID] then
        return contZoneCache[mapID][1], contZoneCache[mapID][2]
    end

    -- C_Map.GetMapInfo can hand us the parent map for city / sub-zones.
    local mapInfo = _G.C_Map and _G.C_Map.GetMapInfo and _G.C_Map.GetMapInfo(mapID)
    if mapInfo and mapInfo.parentMapID and NxMap and NxMap.MapWorldInfo then
        local parent = NxMap.MapWorldInfo[mapInfo.parentMapID]
        if parent then
            contZoneCache[mapID] = { parent.Cont or 90, mapInfo.parentMapID }
            return parent.Cont or 90, mapInfo.parentMapID
        end
    end

    contZoneCache[mapID] = { 90, 0 }
    return 90, 0
end

-- ---------------------------------------------------------------------
-- Classification helpers used by Map / Quest / Travel call sites.
-- ---------------------------------------------------------------------

function MapIDs:IsNormalMap(mapID)
    local NxMap = nxMap()
    if not NxMap or not NxMap.ContCnt or not NxMap.MapZones then return false end
    for i = 1, NxMap.ContCnt do
        for _, b in pairs(NxMap.MapZones[i] or {}) do
            if b == mapID then return true end
        end
    end
    return false
end

function MapIDs:IsInstanceMap(mapID)
    local NxMap = nxMap()
    if not NxMap then return false end
    if self:GetCurrentMapAreaID() == 20 then return false end

    local winfo = NxMap.MapWorldInfo
    if mapID ~= 9000 and (not winfo or not winfo[mapID]) then
        if NxMap.GetZoneInfo then NxMap:GetZoneInfo(mapID) end
    end
    if not winfo or not winfo[mapID] then return false end

    if winfo[mapID].BaseMap then
        mapID = winfo[mapID].BaseMap
    end
    return winfo[mapID] and winfo[mapID].Instance == true or false
end

-- ---------------------------------------------------------------------
-- Display helpers.
-- ---------------------------------------------------------------------

function MapIDs:IdToName(mapID)
    if not mapID then return "" end
    local NxMap = nxMap()
    if NxMap and NxMap.GetMapNameByID then
        local name = NxMap:GetMapNameByID(mapID)
        if name then return name end
    end
    if _G.C_Map and _G.C_Map.GetMapInfo then
        local info = _G.C_Map.GetMapInfo(mapID)
        if info then return info.name or "?" end
    end
    return "?"
end

function MapIDs:NameToId(name)
    return _G.Nx and _G.Nx.MapNameToId and _G.Nx.MapNameToId[name]
end

-- Returns colored level-range / faction description for a zone:
--   color, descriptionString, minLevel
-- color is a Blizzard color escape; descriptionString is "min-max"
-- (or "Any" / "City"); minLevel is -1 for cities.
function MapIDs:GetZoneDescription(mapID)
    local Nx = _G.Nx
    if not Nx or not Nx.Zones then return "|cffffffff", "?", 0 end

    local whichzone = Nx.Zones[mapID] or Nx.Zones[0]
    if not whichzone or not Nx.Split then return "|cffffffff", "?", 0 end

    local _, minLvl, maxLvl, faction = Nx.Split("|", whichzone)
    minLvl  = tonumber(minLvl) or 0
    faction = tonumber(faction) or 0

    local infoStr = ("%d-%d"):format(minLvl, maxLvl or 0)
    local color   = "|cffffffff"

    local NxMap = nxMap()
    if NxMap and NxMap.PlFactionNum == faction then
        color = "|cff20ff20"
    elseif faction == 2 then
        color = "|cffffff00"
    elseif faction < 2 then
        color = "|cffff6060"
    end

    if minLvl == 0 then infoStr = "Any" end

    if NxMap and NxMap.GetWorldZone then
        local zone = NxMap:GetWorldZone(mapID)
        if zone and zone.City then
            infoStr = "City"
            minLvl = -1
        end
    end

    return color, infoStr, minLvl
end

-- ---------------------------------------------------------------------
-- Legacy rewire. Replaces the corresponding Nx.Map: methods so all
-- existing callers route through here.
-- ---------------------------------------------------------------------

local function rewireLegacy()
    local NxMap = nxMap()
    if not NxMap then return end

    NxMap.GetDisplayableMapForPlayer = function(_) return MapIDs:GetDisplayableMapForPlayer() end
    NxMap.CanonicalizeMapID = function(_, mapID) return MapIDs:CanonicalizeMapID(mapID) end
    NxMap.GetCurrentMapAreaID = function(_) return MapIDs:GetCurrentMapAreaID() end
    NxMap.GetCurrentMapId     = function(_) return MapIDs:GetCurrentMapId() end
    NxMap.IdToContZone        = function(_, mapID) return MapIDs:IdToContZone(mapID) end
    NxMap.IsNormalMap         = function(_, mapID) return MapIDs:IsNormalMap(mapID) end
    NxMap.IsInstanceMap       = function(_, mapID) return MapIDs:IsInstanceMap(mapID) end
    NxMap.IdToName            = function(_, mapID) return MapIDs:IdToName(mapID) end
    NxMap.NameToId            = function(_, name)  return MapIDs:NameToId(name) end
    NxMap.GetMapNameDesc      = function(_, mapID) return MapIDs:GetZoneDescription(mapID) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
