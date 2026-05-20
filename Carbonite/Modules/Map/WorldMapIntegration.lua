-- Carbonite | Modules / Map / WorldMapIntegration
-- Wraps Nx.Map's WorldMapFrame integration verbs. The legacy
-- AttachWorldMap moves WorldMapFrame's display into Carbonite's
-- own map window when the user opens the Blizzard map; Detach
-- restores it. This class is the public accessor so other
-- modules can ask "is the world map currently attached?" or
-- force a re-attach.
--
-- Public API:
--   WorldMapIntegration:Attach()
--   WorldMapIntegration:Detach()
--   WorldMapIntegration:IsAttached()
--   WorldMapIntegration:Refresh()       -- UpdateWorldMap
--   WorldMapIntegration:SetIconsScale(scale)

local Carbonite = _G.Carbonite
local WorldMapIntegration = {}
Carbonite.Modules.Map.WorldMapIntegration = WorldMapIntegration

local function NxMap() return _G.Nx and _G.Nx.Map end

function WorldMapIntegration:Attach()
    local m = NxMap()
    if m and m.AttachWorldMap then m:AttachWorldMap() end
    Carbonite.Core.EventBus:Fire("WORLDMAP_ATTACHED")
end

function WorldMapIntegration:Detach()
    local m = NxMap()
    if m and m.DetachWorldMap then m:DetachWorldMap() end
    Carbonite.Core.EventBus:Fire("WORLDMAP_DETACHED")
end

function WorldMapIntegration:IsAttached()
    local m = NxMap()
    if not m then return false end
    return m.WorldMapAttached == true or m._worldMapAttached == true
end

function WorldMapIntegration:Refresh()
    local m = NxMap()
    if m and m.UpdateWorldMap then m:UpdateWorldMap() end
end

function WorldMapIntegration:SetIconsScale(scale)
    local m = NxMap()
    if m and m.SetWorldMapIcons then m:SetWorldMapIcons(scale) end
end
