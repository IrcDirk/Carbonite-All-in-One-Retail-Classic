-- Carbonite | Modules / Map / HotspotsRenderer
-- Public surface around the legacy Nx.Map:MoveWorldHotspots draw
-- pass. The Hotspots data class (already extracted) owns the data;
-- this class owns the trigger to redraw / refresh the visible
-- hotspot overlays.
--
-- Public API:
--   HotspotsRenderer:Refresh()          - re-draw all hotspots
--   HotspotsRenderer:SetVisible(on)
--   HotspotsRenderer:IsVisible()

local Carbonite = _G.Carbonite
local HotspotsRenderer = {}
Carbonite.Modules.Map.HotspotsRenderer = HotspotsRenderer

local function NxMap() return _G.Nx and _G.Nx.Map end

function HotspotsRenderer:Refresh()
    local m = NxMap()
    if m and m.MoveWorldHotspots then m:MoveWorldHotspots() end
    Carbonite.Core.EventBus:Fire("MAP_HOTSPOTS_REFRESHED")
end

function HotspotsRenderer:SetVisible(on)
    local Nx = _G.Nx
    if Nx and Nx.db and Nx.db.profile and Nx.db.profile.Map then
        Nx.db.profile.Map.ShowHotspots = on and true or false
    end
    self:Refresh()
end

function HotspotsRenderer:IsVisible()
    local Nx = _G.Nx
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.Map
       and Nx.db.profile.Map.ShowHotspots ~= false
end
