-- Carbonite | Modules / Map / FrameToWorld
-- Frame-pixel ↔ map-coordinate conversion. The legacy code lived as
-- Nx.Map:FramePosToZonePos and Nx.Map:FramePosToWorldPos, with raw
-- arithmetic that mixed PadX / TitleH / MapW / MapH from the live
-- map instance. This class is the canonical owner of those formulas.
--
-- "Frame" here means the on-screen pixel position relative to the
-- Carbonite map window's top-left. "Zone" is the in-game zone-coord
-- (0..100) for the currently displayed map. "World" is Carbonite's
-- continent-relative world space (computed by Coords).
--
--   FrameToWorld:FrameToZone(x, y)  -> (zoneX, zoneY)
--   FrameToWorld:FrameToWorld(x, y) -> (worldX, worldY)
--   FrameToWorld:WorldToFrame(wx,wy)-> (frameX, frameY)
--
-- All methods expect the map instance to be the primary one
-- (Nx.Map.Maps[1]); we read its current pan + scale state.

local Carbonite = _G.Carbonite
local FrameToWorld = {}
Carbonite.Modules.Map.FrameToWorld = FrameToWorld

local function map() return _G.Nx and _G.Nx.Map and _G.Nx.Map.Maps and _G.Nx.Map.Maps[1] end

-- Constant: continent-units-per-zone-percent. This is the "10.02"
-- magic number sprinkled through the legacy code; preserved so the
-- arithmetic matches existing data tables pixel-for-pixel.
local CONTINENT_UNITS_PER_ZONE_PERCENT = 10.02

function FrameToWorld:FrameToZone(x, y)
    local m = map()
    if not m then return 0, 0 end
    local mapW = (m.MapW or 1) - (m.PadX or 0)
    local mapH = (m.MapH or 1) - (m.TitleH or 0)
    if mapW <= 0 or mapH <= 0 then return 0, 0 end
    return x / mapW * 100, y / mapH * 100
end

function FrameToWorld:FrameToWorld(x, y)
    local m = map()
    if not m then return 0, 0 end
    local scale = m.MapScale or 1
    if scale == 0 then return 0, 0 end
    local wx = (m.MapPosX or 0) + (x - (m.PadX or 0)   - (m.MapW or 0) / 2) / CONTINENT_UNITS_PER_ZONE_PERCENT / scale
    local wy = (m.MapPosY or 0) + (y - (m.TitleH or 0) - (m.MapH or 0) / 2) / CONTINENT_UNITS_PER_ZONE_PERCENT / scale
    return wx, wy
end

-- The inverse: world coord -> frame pixel position. Useful when
-- placing pins / overlays.
function FrameToWorld:WorldToFrame(wx, wy)
    local m = map()
    if not m then return 0, 0 end
    local scale = m.MapScale or 1
    local fx = (wx - (m.MapPosX or 0)) * scale * CONTINENT_UNITS_PER_ZONE_PERCENT + (m.PadX or 0)   + (m.MapW or 0) / 2
    local fy = (wy - (m.MapPosY or 0)) * scale * CONTINENT_UNITS_PER_ZONE_PERCENT + (m.TitleH or 0) + (m.MapH or 0) / 2
    return fx, fy
end

-- Convenience: mouse cursor in world coords. Clamps to the map
-- window so off-frame positions don't return wild values.
function FrameToWorld:GetCursorWorld()
    local m = map()
    if not m or not m.Frm or not _G.Nx or not _G.Nx.Util_GetMouseClampedXY then
        return 0, 0
    end
    local mx, my = _G.Nx.Util_GetMouseClampedXY(m.Frm)
    local top    = m.Frm:GetTop() or 0
    local bottom = m.Frm:GetBottom() or 0
    my = top - (my + bottom)
    return self:FrameToWorld(mx, my)
end

local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.FramePosToZonePos  = function(_, x, y) return FrameToWorld:FrameToZone(x, y) end
    NxMap.FramePosToWorldPos = function(_, x, y) return FrameToWorld:FrameToWorld(x, y) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
