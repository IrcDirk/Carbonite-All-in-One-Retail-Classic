-- Carbonite | Modules / Map / ContinentLookup
-- Cached "which continent does this UI map ID belong to?" lookup.
-- Walks the C_Map parent hierarchy until it hits a map of type
-- Enum.UIMapType.Continent (== 2), caching each step so repeat
-- queries are O(1).
--
-- The legacy implementation lived as Nx.Map:GetContinentMapID with
-- a file-local zoneMapIDtoContinentMapID cache. This class is the
-- canonical owner; the legacy method is rewired.
--
--   ContinentLookup:Get(mapID)        -> continent mapID, or nil
--   ContinentLookup:GetCached(mapID)  -> cached entry without lookup
--   ContinentLookup:Clear()           -> reset the cache (debug only)

local Carbonite = _G.Carbonite
local ContinentLookup = {}
Carbonite.Modules.Map.ContinentLookup = ContinentLookup

local cache = {}

local UIMAP_TYPE_COSMIC    = 0
local UIMAP_TYPE_WORLD     = 1
local UIMAP_TYPE_CONTINENT = 2

local function getMapInfo(mapID)
    return _G.C_Map and _G.C_Map.GetMapInfo and _G.C_Map.GetMapInfo(mapID) or nil
end

function ContinentLookup:GetCached(mapID)
    return cache[mapID]
end

function ContinentLookup:Get(uiMapID)
    if not uiMapID then return nil end

    local cached = cache[uiMapID]
    if cached ~= nil then return cached end

    local info = getMapInfo(uiMapID)
    if not info or info.mapType == UIMAP_TYPE_COSMIC or info.mapType == UIMAP_TYPE_WORLD then
        cache[uiMapID] = false           -- false = "we tried, no continent"
        return nil
    end

    if info.mapType == UIMAP_TYPE_CONTINENT then
        cache[uiMapID] = info.mapID
        return info.mapID
    end

    -- Walk up the parent chain. We accept the recursion because the
    -- WoW hierarchy is shallow (~4 levels worst case) and every step
    -- is cached, so a cold zone resolves once and never recurses
    -- again. Guarded against missing parent.
    local parentInfo = info.parentMapID and getMapInfo(info.parentMapID)
    if not parentInfo then
        cache[uiMapID] = false
        return nil
    end

    if parentInfo.mapType == UIMAP_TYPE_CONTINENT then
        cache[uiMapID] = parentInfo.mapID
        return parentInfo.mapID
    end

    local found = self:Get(parentInfo.mapID)
    cache[uiMapID] = found or false
    return found
end

function ContinentLookup:Clear()
    for k in pairs(cache) do cache[k] = nil end
end

-- The legacy code stored `nil` to mean "not found" but also `nil` to
-- mean "not yet looked up". We disambiguate above by storing `false`.
-- The rewire below preserves the legacy API (returns nil for both).
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.GetContinentMapID = function(_, mapID)
        local v = ContinentLookup:Get(mapID)
        if v == false then return nil end
        return v
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
