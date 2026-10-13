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
local instanceMapSelection = {}

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
-- Most maps are already canonical; a flavor's data may declare PlayerMapID
-- aliases for maps it keys under a different ID.
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

local function GetSafeMapInfo(mapID)
    local C_Map = _G.C_Map
    if not mapID or mapID <= 0 or not C_Map or not C_Map.GetMapInfo then
        return nil
    end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    return ok and type(info) == "table" and info or nil
end

local function IsInteriorMap(mapID)
    local NxMap = nxMap()
    local row = NxMap and NxMap.MapWorldInfo and NxMap.MapWorldInfo[mapID]
    if row then return row.Instance == true end

    local info = GetSafeMapInfo(mapID)
    local mapTypes = _G.Enum and _G.Enum.UIMapType or {}
    return info and (info.mapType == (mapTypes.Dungeon or 4)
        or info.mapType == (mapTypes.Micro or 5)
        or info.mapType == (mapTypes.Orphan or 6)) or false
end

local function HasInstanceMapArt(mapID)
    local NxMap = nxMap()
    if NxMap and NxMap.GetInstanceMapArt then
        local ok, layer = pcall(NxMap.GetInstanceMapArt, NxMap, mapID)
        return ok and layer ~= nil
    end
    local C_Map = _G.C_Map
    if C_Map and C_Map.MapHasArt then
        local ok, hasArt = pcall(C_Map.MapHasArt, mapID)
        return ok and hasArt == true
    end
    return false
end

-- Some instance overview/micro maps have no art assignment. Blizzard's
-- displayable helper then climbs to the outdoor entrance zone. Keep the
-- actual interior, or a uniquely identifiable floor from its own map family.
function MapIDs:GetPlayerInstanceMapID(rawMapID, displayableMapID)
    if not rawMapID or rawMapID <= 0 then return nil end

    local inInstance = false
    if _G.IsInInstance then
        local ok, value = pcall(_G.IsInInstance)
        inInstance = ok and value == true
    end
    if not inInstance then
        local NxMap = nxMap()
        local canonicalID = self:CanonicalizeMapID(rawMapID)
        local row = NxMap and NxMap.MapWorldInfo and NxMap.MapWorldInfo[canonicalID]
        if not (row and row.Instance) then
            local info = not row and GetSafeMapInfo(rawMapID)
            local mapTypes = _G.Enum and _G.Enum.UIMapType or {}
            if not info or info.mapType ~= (mapTypes.Dungeon or 4) then return nil end
        end
    end

    local function finish(mapID)
        mapID = self:CanonicalizeMapID(mapID)
        local NxMap = nxMap()
        if NxMap and NxMap.MapWorldInfo and not NxMap.MapWorldInfo[mapID]
            and NxMap.GetZoneInfo then
            -- Register a new floor before IdToContZone/Coords reads its row.
            pcall(NxMap.GetZoneInfo, NxMap, mapID)
        end
        return mapID
    end

    if rawMapID == displayableMapID then return finish(rawMapID) end

    local now = _G.GetTime and _G.GetTime() or 0
    if _G.GetTime and instanceMapSelection.rawMapID == rawMapID
        and instanceMapSelection.displayableMapID == displayableMapID
        and now < (instanceMapSelection.retryTime or 0) then
        return finish(instanceMapSelection.mapID)
    end

    local function selectMap(mapID)
        instanceMapSelection.rawMapID = rawMapID
        instanceMapSelection.displayableMapID = displayableMapID
        instanceMapSelection.mapID = mapID
        instanceMapSelection.retryTime = now + 0.5
        return finish(mapID)
    end

    if HasInstanceMapArt(rawMapID) then return selectMap(rawMapID) end

    -- An artless micro map can sit inside a renderable dungeon floor. Stop
    -- at the outdoor boundary instead of inheriting its unrelated artwork.
    local info = GetSafeMapInfo(rawMapID)
    local seen = { [rawMapID] = true }
    for _ = 1, 16 do
        local parentID = info and info.parentMapID
        if not parentID or parentID <= 0 or seen[parentID]
            or not IsInteriorMap(parentID) then break end
        seen[parentID] = true
        if HasInstanceMapArt(parentID) then return selectMap(parentID) end
        info = GetSafeMapInfo(parentID)
    end

    local C_Map = _G.C_Map
    local candidates, candidateSet = {}, {}
    local function addCandidates(members)
        if type(members) ~= "table" then return end
        for _, member in ipairs(members) do
            local mapID = member.mapID
            if mapID and mapID ~= rawMapID and not candidateSet[mapID]
                and IsInteriorMap(mapID) then
                candidateSet[mapID] = true
                candidates[#candidates + 1] = mapID
            end
        end
    end

    if C_Map and C_Map.GetMapGroupID and C_Map.GetMapGroupMembersInfo then
        local groupOK, groupID = pcall(C_Map.GetMapGroupID, rawMapID)
        if groupOK and groupID and groupID > 0 then
            local membersOK, members = pcall(C_Map.GetMapGroupMembersInfo, groupID)
            if membersOK and type(members) == "table" then
                for _, member in ipairs(members) do
                    -- The raw ID already identifies a floor: wait for that
                    -- floor's art rather than showing another ready floor.
                    if member.mapID == rawMapID then return selectMap(rawMapID) end
                end
                addCandidates(members)
            end
        end
    end
    if C_Map and C_Map.GetMapChildrenInfo then
        local childrenOK, children = pcall(C_Map.GetMapChildrenInfo, rawMapID, nil, true)
        if childrenOK then addCandidates(children) end
    end

    local artMapID, artCount, positionMapID, positionCount = nil, 0, nil, 0
    for _, mapID in ipairs(candidates) do
        if HasInstanceMapArt(mapID) then
            artMapID, artCount = mapID, artCount + 1
            local x, y = self:GetPlayerPositionOnMap(mapID)
            if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                positionMapID, positionCount = mapID, positionCount + 1
            end
        end
    end
    if positionCount == 1 then return selectMap(positionMapID) end
    if #candidates == 1 and artCount == 1 then return selectMap(artMapID) end

    -- Missing/ambiguous art is transient. Retry without replacing the
    -- instance with its entrance zone or permanently caching a failed lookup.
    return selectMap(rawMapID)
end

-- Displayable map for the player, with Carbonite city aliases and the legacy
-- OldMapIDs remap applied (1414 → 12, 1415 → 13 on pre-MoP clients).
function MapIDs:GetDisplayableMapForPlayer()
    local MapUtil = _G.MapUtil
    local C_Map = _G.C_Map
    local rawMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local displayableMapID = rawMapID or 0
    if MapUtil and MapUtil.GetDisplayableMapForPlayer then
        local ok, mapID = pcall(MapUtil.GetDisplayableMapForPlayer)
        if ok and mapID then displayableMapID = mapID end
    end

    -- Blizzard's displayable helper deliberately climbs away from maps that
    -- have no C_Map art. Carbonite can still render its legacy city tiles, so
    -- retain a raw city map only when its flavor data declares legacy art
    -- (Exodar is the common MoP example), and canonicalize declared aliases.
    -- Outdoor maps keep Blizzard's displayable-parent behavior; interiors
    -- retain their own art or a floor resolved from their map family.
    local rawCanonicalID = self:CanonicalizeMapID(rawMapID)
    local NxMap = nxMap()
    local rawInfo = NxMap and NxMap.MapWorldInfo and NxMap.MapWorldInfo[rawCanonicalID]
    local mapID = rawInfo and rawInfo.City and rawInfo.LegacyMapArt and rawCanonicalID
        or self:GetPlayerInstanceMapID(rawMapID, displayableMapID)
        or self:CanonicalizeMapID(displayableMapID)
        or 0

    if _G.Nx and _G.Nx.OldMapIDs then
        if mapID == 1414 then return 12 end
        if mapID == 1415 then return 13 end
    end
    return mapID
end

-- Player position expressed on a specific map. Returns nil when the player's
-- location cannot be represented there, so callers can keep their own value.
function MapIDs:GetPlayerPositionOnMap(mapID)
    local C_Map = _G.C_Map
    if not mapID or mapID == 0 or not C_Map or not C_Map.GetPlayerMapPosition then
        return nil
    end

    local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok or not pos then return nil end

    local x, y = pos:GetXY()
    if not x or not y then return nil end
    if x == 0 and y == 0 then return nil end
    return x, y
end

-- The map whose coordinate space the player's position is reported in, when
-- the flavor data places that map in Carbonite's world grid. City maps such as
-- Ironforge are reported by GetBestMapForUnit but climbed away from by
-- MapUtil.GetDisplayableMapForPlayer, and the parent zone cannot express the
-- position at all, so the conversion has to use the city's own row.
function MapIDs:GetPlayerWorldMapID()
    local C_Map = _G.C_Map
    local rawID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not rawID or rawID == 0 then return nil end

    local mapID = self:CanonicalizeMapID(rawID)
    local NxMap = nxMap()
    local info = NxMap and NxMap.MapWorldInfo and NxMap.MapWorldInfo[mapID]
    if info and info.Scale and info[4] and info[5] then
        return mapID
    end

    return nil
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
    local Nx = _G.Nx
    local zone = Nx and Nx.Zones and Nx.Zones[mapID]
    if zone and Nx.Split then
        local name = Nx.Split("|", zone)
        if name and name ~= "" then return name end
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
    NxMap.GetPlayerPositionOnMap = function(_, mapID) return MapIDs:GetPlayerPositionOnMap(mapID) end
    NxMap.GetPlayerWorldMapID = function(_) return MapIDs:GetPlayerWorldMapID() end
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
