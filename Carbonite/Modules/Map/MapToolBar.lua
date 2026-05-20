-- Carbonite | Modules / Map / MapToolBar
-- The icon strip at the top of the Carbonite map. The legacy
-- Nx.Map:CreateToolBar / UpdateToolBar built it directly via the
-- old Nx.ToolBar widget; this class owns the registry of buttons
-- so plugins can add their own entries without touching Nx.BarData.
--
-- Public API:
--   MapToolBar:RegisterButton(spec)   - { id, label, handler, pressed,
--                                          icon, order, group, enabled }
--   MapToolBar:UnregisterButton(id)
--   MapToolBar:Each(fn)               - iterate in stable order
--   MapToolBar:Refresh()              - tell the live toolbar to rebuild
--   MapToolBar:SetVisible(bool)       - mirror of Nx.db.profile.Map.ShowToolBar
--   MapToolBar:IsVisible()
--
-- The actual UI build still happens through the legacy
-- Nx.Map:CreateToolBar pipeline because the buttons are
-- Nx.Button-typed (TypeData lookup). Our registry is mirrored
-- into Nx.BarData so the legacy creator picks up plugin entries.

local Carbonite = _G.Carbonite

local MapToolBar = {}
Carbonite.Modules.Map.MapToolBar = MapToolBar

local registry = {}            -- id -> spec
local order    = {}            -- ordered list of ids

local function syncToLegacy()
    if not _G.Nx then return end
    local bar = {}
    for _, id in ipairs(order) do
        local s = registry[id]
        bar[#bar + 1] = { s.buttonType or id, s.label, s.handler, s.pressed or false }
    end
    _G.Nx.BarData = bar
    -- If the toolbar exists already, prompt a rebuild.
    local mapInst = _G.Nx.Map and _G.Nx.Map.Maps and _G.Nx.Map.Maps[1]
    if mapInst and mapInst.UpdateToolBar then mapInst:UpdateToolBar() end
end

function MapToolBar:RegisterButton(spec)
    if not spec or not spec.id then return end
    if not registry[spec.id] then table.insert(order, spec.id) end
    registry[spec.id] = spec
    table.sort(order, function(a, b)
        return (registry[a].order or 100) < (registry[b].order or 100)
    end)
    syncToLegacy()
end

function MapToolBar:UnregisterButton(id)
    if not registry[id] then return end
    registry[id] = nil
    for i, v in ipairs(order) do
        if v == id then table.remove(order, i); break end
    end
    syncToLegacy()
end

function MapToolBar:Each(fn)
    for _, id in ipairs(order) do fn(id, registry[id]) end
end

function MapToolBar:Refresh() syncToLegacy() end

function MapToolBar:SetVisible(on)
    local Nx = _G.Nx
    if not Nx or not Nx.db or not Nx.db.profile or not Nx.db.profile.Map then return end
    Nx.db.profile.Map.ShowToolBar = on and true or false
    local mapInst = Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1]
    if mapInst and mapInst.UpdateToolBar then mapInst:UpdateToolBar() end
end

function MapToolBar:IsVisible()
    local Nx = _G.Nx
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.Map
       and Nx.db.profile.Map.ShowToolBar == true or false
end

-- Seed the legacy default vocabulary so the toolbar still has its
-- baseline buttons even if no module registered any. The actual
-- handlers stay on Nx.Map because they touch instance state.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    local L = _G.Nx and Carbonite:L() or {}
    MapToolBar:RegisterButton({ id = "MapZIn",     label = L["Zoom In"]  or "Zoom In",   handler = NxMap.OnButZoomIn,        order = 10 })
    MapToolBar:RegisterButton({ id = "MapZOut",    label = L["Zoom Out"] or "Zoom Out",  handler = NxMap.OnButZoomOut,       order = 20 })
    MapToolBar:RegisterButton({ id = "MapGuide",   label = L["Guide"]    or "Guide",     handler = NxMap.OnButToggleGuide,   order = 30 })
    MapToolBar:RegisterButton({ id = "MapCombat",  label = L["Combat"]   or "Combat",    handler = NxMap.OnButToggleCombat,  order = 40 })
    MapToolBar:RegisterButton({ id = "MapEvents",  label = L["Events"]   or "Events",    handler = NxMap.OnButToggleEvent,   order = 50 })
end)
