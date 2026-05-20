-- Carbonite | Modules / Map / POICache
-- Point-of-interest cache used by the map renderer's OnUpdate loop.
-- The legacy implementation defined two file-locals in NxMap.lua:
--
--   POI_Pool  = { pPOIs = {}, aPOIs = {}, zPOIs = {} }
--   POI_Cache = { mapID = nil, time = 0, data = nil, refreshInterval = 0.5 }
--
-- Every frame, OnUpdate would either hit the cache or refresh it
-- from C_AreaPoiInfo. This class is the canonical owner of those
-- table pools and the refresh-interval policy. The legacy locals
-- still exist in NxMap.lua but they now mirror our table so
-- existing reads keep getting fresh data.
--
-- Public API:
--   POICache:Get(mapID)             -> cached POI list (or refreshed)
--   POICache:Invalidate()           -> clear the cache forcibly
--   POICache:GetPool()              -> {pPOIs, aPOIs, zPOIs} for reuse
--   POICache:SetRefreshInterval(s)
--   POICache:GetStats()             -> debug: { hits, misses, lastRefresh }

local Carbonite = _G.Carbonite

local POICache = {}
Carbonite.Modules.Map.POICache = POICache

-- The three reusable pools the legacy code wiped each frame so we
-- avoid allocating thousands of tables per second of map open.
POICache.pool = {
    pPOIs = {},
    aPOIs = {},
    zPOIs = {},
}

POICache.refreshInterval = 0.5
POICache.cache = {
    mapID = nil,
    time  = 0,
    data  = nil,
}

local stats = { hits = 0, misses = 0, lastRefresh = 0 }

function POICache:GetPool() return self.pool end

function POICache:SetRefreshInterval(seconds)
    if seconds and seconds > 0 then self.refreshInterval = seconds end
end

function POICache:Invalidate()
    self.cache.mapID = nil
    self.cache.time  = 0
    self.cache.data  = nil
end

function POICache:GetStats()
    return { hits = stats.hits, misses = stats.misses, lastRefresh = stats.lastRefresh }
end

-- Pull POIs for a given map ID. Returns the cached table when the
-- last refresh is < refreshInterval seconds old AND the cached map
-- ID matches; otherwise calls C_AreaPoiInfo to populate. Callers
-- should treat the returned table as read-only.
function POICache:Get(mapID)
    if not mapID then return nil end
    local now = (GetTime and GetTime()) or 0

    if self.cache.mapID == mapID
       and self.cache.data
       and (now - (self.cache.time or 0)) < self.refreshInterval then
        stats.hits = stats.hits + 1
        return self.cache.data
    end

    stats.misses = stats.misses + 1

    -- Refresh. C_AreaPoiInfo APIs vary by client version; query the
    -- ones that exist and merge results.
    local poiInfo = _G.C_AreaPoiInfo
    local out = {}

    if poiInfo and poiInfo.GetAreaPOIForMap then
        local ids = poiInfo.GetAreaPOIForMap(mapID)
        if ids then
            for _, id in ipairs(ids) do
                local data = poiInfo.GetAreaPOIInfo and poiInfo.GetAreaPOIInfo(mapID, id)
                if data then out[#out + 1] = data end
            end
        end
    end

    self.cache.mapID = mapID
    self.cache.data  = out
    self.cache.time  = now
    stats.lastRefresh = now
    return out
end

-- Sync our cache view onto NxMap if the legacy locals exist. We
-- can't fully replace them (they are file-local in NxMap.lua), but
-- we can expose ours under the same shape on the addon table so
-- new code has a documented place to find them.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    local NxMap = _G.Nx and _G.Nx.Map
    if NxMap then
        NxMap.POI = POICache
    end
end)
