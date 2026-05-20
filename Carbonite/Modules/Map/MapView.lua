-- Carbonite | Modules / Map / MapView
-- Public state accessor for the Carbonite map view. Carbonite
-- maintains a registry of "map instances" (Nx.Map.Maps) keyed by
-- a small integer; in normal use only Maps[1] exists, but the
-- legacy code permits a secondary instance for debug views. This
-- class is the documented accessor for it.
--
-- Public API:
--   MapView:GetPrimary()
--   MapView:Get(index)
--   MapView:Each(fn)
--   MapView:Count()
--   MapView:GetCurrentMapID()
--   MapView:GetPlayerWorldPos()        -> wx, wy

local Carbonite = _G.Carbonite
local MapView = {}
Carbonite.Modules.Map.MapView = MapView

function MapView:GetPrimary()
    local M = _G.Nx and _G.Nx.Map
    return M and M.Maps and M.Maps[1]
end

function MapView:Get(index)
    local M = _G.Nx and _G.Nx.Map
    return M and M.Maps and M.Maps[index or 1]
end

function MapView:Each(fn)
    local M = _G.Nx and _G.Nx.Map
    if not M or not M.Maps then return end
    for i, map in pairs(M.Maps) do fn(i, map) end
end

function MapView:Count()
    local M = _G.Nx and _G.Nx.Map
    if not M or not M.Maps then return 0 end
    local n = 0
    for _ in pairs(M.Maps) do n = n + 1 end
    return n
end

function MapView:GetCurrentMapID()
    local MapIDs = Carbonite.Modules.Map.MapIDs
    if MapIDs and MapIDs.GetCurrentMapId then return MapIDs:GetCurrentMapId() end
    local m = self:GetPrimary()
    return m and m.MapId
end

function MapView:GetPlayerWorldPos()
    local m = self:GetPrimary()
    return (m and m.PlyrX) or 0, (m and m.PlyrY) or 0
end
