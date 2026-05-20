-- Carbonite | Modules / Map / MapDrag
-- Public surface around mouse drag-to-pan on the Carbonite map.
-- The legacy implementation hooks OnMouseDown / OnMouseUp /
-- OnUpdate on the map frame and stores the live drag offset on
-- Nx.Map.Maps[1].DragX / DragY.
--
-- Public API:
--   MapDrag:IsDragging()
--   MapDrag:GetOffset()      -> dx, dy (world units)
--   MapDrag:Begin(x, y)      -- force a drag start
--   MapDrag:End()
--   MapDrag:EnableDragging(on)

local Carbonite = _G.Carbonite
local MapDrag = {}
Carbonite.Modules.Map.MapDrag = MapDrag

local function map1()
    local M = _G.Nx and _G.Nx.Map
    return M and M.Maps and M.Maps[1]
end

function MapDrag:IsDragging()
    local m = map1()
    return m and m.Dragging == true
end

function MapDrag:GetOffset()
    local m = map1()
    if not m then return 0, 0 end
    return m.DragX or 0, m.DragY or 0
end

function MapDrag:Begin(x, y)
    local m = map1()
    if not m then return end
    m.Dragging = true
    m.DragStartX, m.DragStartY = x, y
    Carbonite.Core.EventBus:Fire("MAP_DRAG_BEGAN", x, y)
end

function MapDrag:End()
    local m = map1()
    if not m then return end
    m.Dragging = false
    Carbonite.Core.EventBus:Fire("MAP_DRAG_ENDED")
end

function MapDrag:EnableDragging(on)
    local m = map1()
    if not m then return end
    m.DragEnabled = on and true or false
end
