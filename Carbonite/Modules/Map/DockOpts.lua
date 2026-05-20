-- Carbonite | Modules / Map / DockOpts
-- Public surface around Nx.Map.Dock, the subsystem that controls
-- the minimap-button dock (docked/floating, scale-on-dock, alpha).
-- The legacy code lives on the Nx.Map.Dock table and reads
-- Nx.db.profile.MiniMap.* fields for its settings.
--
-- Public API:
--   DockOpts:Update()           -> re-evaluate dock state
--   DockOpts:IsDocked()
--   DockOpts:GetScale()
--   DockOpts:SetScale(s)
--   DockOpts:GetDockAlpha()
--   DockOpts:SetDockAlpha(a)
--   DockOpts:GetMinScale()      -- legacy NXMMDockOnAtScale

local Carbonite = _G.Carbonite

local DockOpts = {}
Carbonite.Modules.Map.DockOpts = DockOpts

local function dock()
    local m = _G.Nx and _G.Nx.Map
    return m and m.Dock
end

local function db()
    local Nx = _G.Nx
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.MiniMap
end

function DockOpts:Update()
    local d = dock()
    if d and d.UpdateOptions then d:UpdateOptions() end
    Carbonite.Core.EventBus:Fire("MAP_DOCK_UPDATED")
end

function DockOpts:IsDocked()
    local d = dock()
    return d and d.IsDocked == true
end

function DockOpts:GetScale()
    local d = db(); return d and d.NXMMDockScale or 0.4
end

function DockOpts:SetScale(s)
    local d = db(); if d then d.NXMMDockScale = s end
    self:Update()
end

function DockOpts:GetDockAlpha()
    local d = db(); return d and d.NXMMDockAlpha or 1
end

function DockOpts:SetDockAlpha(a)
    local d = db(); if d then d.NXMMDockAlpha = a end
    self:Update()
end

function DockOpts:GetMinScale()
    local d = db(); return d and d.NXMMDockOnAtScale or 0.6
end
