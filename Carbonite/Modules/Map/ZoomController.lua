-- Carbonite | Modules / Map / ZoomController
-- Owns scale + position animation for the Carbonite map. The legacy
-- implementation spread these across Nx.Map:Move / SetScaleOverTime
-- / GotoPlayer / GotoCurrentZone / CenterMap. They all mutate the
-- same fields on the live map instance (Scale, ScaleDraw, MapPosX,
-- MapPosY, MapPosXDraw, MapPosYDraw, StepTime), so this class is
-- the canonical owner of those mutations.
--
-- The per-frame render code reads ScaleDraw / MapPos*Draw and
-- interpolates toward Scale / MapPos*; the StepTime field is the
-- number of frames remaining in the current animation. The legacy
-- distance / snap thresholds (0.25 world units; 0.01 inverse-scale
-- difference) are preserved verbatim so muscle memory holds.
--
-- Public API:
--   ZoomController:GetScale()
--   ZoomController:SetScale(scale, stepTime)
--   ZoomController:ScrollSteps(steps)          discrete in/out delta
--   ZoomController:Move(x, y, scale, stepTime) drive an animation
--   ZoomController:GotoPlayer()                snap to current zone
--   ZoomController:GotoCurrentZone()           re-center the player zone
--   ZoomController:CenterMap(mapID, scale)     center on a known map
--   ZoomController:CenterMap1To1(mapID)        no-anim 1:1 fit

local Carbonite = _G.Carbonite
local ZoomController = {}
Carbonite.Modules.Map.ZoomController = ZoomController

local function mapInst()
    return _G.Nx and _G.Nx.Map and _G.Nx.Map.Maps and _G.Nx.Map.Maps[1]
end

-- Snap tolerances - identical to the legacy thresholds.
local POS_SNAP_DIST       = 0.25
local INV_SCALE_SNAP_DIFF = 0.01
-- Beyond this on-screen distance (in map units * scale / window size)
-- the legacy code accelerates the animation to 1 frame.
local FAR_JUMP_THRESHOLD  = 10

function ZoomController:GetScale()
    local m = mapInst()
    return m and m.Scale
end

function ZoomController:SetScale(scale, stepTime)
    local m = mapInst()
    if not m or not scale then return end
    self:Move(m.MapPosX, m.MapPosY, scale, stepTime or 10)
    -- Explicit external SetScale = user intent. Remember it so any
    -- subsequent teleport into an instance preserves their zoom.
    self:RememberScale(scale)
end

function ZoomController:ScrollSteps(steps)
    local m = mapInst()
    if not m or not m.ScrollScale then return end
    local sign = steps >= 0 and 1 or -1
    for _ = 1, math.abs(steps) do
        m.Scale = m:ScrollScale(sign)
    end
    m.StepTime = 10
    -- Mouse-wheel / minimap zoom buttons drive ScrollSteps. Treat as
    -- user intent for the remembered-scale fix above.
    self:RememberScale(m.Scale)
end

function ZoomController:Move(x, y, scale, stepTime)
    local m = mapInst()
    if not m then return end

    m.MapPosX = x
    m.MapPosY = y
    if scale then m.Scale = scale end

    local dx = (m.MapPosXDraw or 0) - m.MapPosX
    local dy = (m.MapPosYDraw or 0) - m.MapPosY
    local dist = math.sqrt(dx * dx + dy * dy)

    local sz = math.max(m.MapW or 1, m.MapH or 1)

    -- Big on-screen jump while zoomed in -> animate fast.
    if (dist * (m.Scale or 1) / sz) > FAR_JUMP_THRESHOLD then
        stepTime = 1
    end

    -- If we're already in an animation, never extend it. StepTime
    -- may be negative when a continuation has been queued; treat as
    -- duration via abs().
    local st = math.abs(m.StepTime or 0)
    if st > 0 and st < (stepTime or 0) then
        stepTime = st
    end

    m.StepTime = stepTime or 10

    -- Snap on small position deltas so cumulative float drift stops
    -- the drawn copy lagging the logical pos forever.
    if dist < POS_SNAP_DIST then
        m.MapPosXDraw = m.MapPosX
        m.MapPosYDraw = m.MapPosY
    end

    -- Likewise for scale: when the inverse-scale gap is tiny, snap.
    if math.abs(1 / (m.ScaleDraw or 1) - 1 / (m.Scale or 1)) < INV_SCALE_SNAP_DIFF then
        m.ScaleDraw = m.Scale
        if dist < POS_SNAP_DIST then m.StepTime = 0 end
    end
end

function ZoomController:GotoPlayer()
    local m = mapInst()
    if not m then return end
    if m.CalcTracking then m:CalcTracking() end
    if m.SetToCurrentZone then m:SetToCurrentZone() end
    m.MoveLastX, m.MoveLastY = -1, -1
end

-- ---------------------------------------------------------------
-- Teleport-aware scale preservation.
--
-- Bug fix: the legacy GotoCurrentZone unconditionally forced
-- Scale = 20 on the instance-entry branch. That value is "very
-- zoomed in" for most maps, which is why users reported the map
-- snapping to maximum zoom after every teleport into a dungeon /
-- raid / scenario / garrison. We instead remember the last user-
-- driven scale and restore that on teleport so muscle memory holds.
--
-- The remembered scale is captured at every Move() that comes from
-- a non-internal call path (mouse wheel, slider, key bind, slash).
-- Internal CenterMap / GotoCurrentZone / instance-entry moves do
-- NOT update the remembered value, so the user's "real" preference
-- survives the teleport.
-- ---------------------------------------------------------------

-- Maximum allowed instance-entry default. The legacy code used 20
-- which is far too zoomed-in for most modern dungeon maps; 5-6
-- shows the whole entrance area while preserving readable icons.
local INSTANCE_DEFAULT_SCALE = 5
local rememberedScale = nil

function ZoomController:RememberScale(scale)
    if scale and scale > 0 then rememberedScale = scale end
end

function ZoomController:GetRememberedScale()
    return rememberedScale
end

function ZoomController:GotoCurrentZone()
    local m = mapInst()
    if not m then return end

    if m.InstanceId then
        -- Prefer the user's remembered scale; fall back to a sane
        -- instance-friendly default. Never the legacy hard-coded 20
        -- which produced the "max zoom after teleport" complaint:
        -- a forced 20 is "very zoomed in" on most maps and wiped
        -- whatever the user had selected before the teleport.
        local scale = rememberedScale or INSTANCE_DEFAULT_SCALE
        self:Move(m.PlyrX, m.PlyrY, scale, 15)
        return
    end

    -- Non-instance teleport (cross-zone, between continents, etc.).
    -- CenterMap fits the new zone to the window, which is what users
    -- expect when arriving in a new area.
    if m.SetToCurrentZone then m:SetToCurrentZone() end
    local MapIDs = Carbonite.Modules.Map.MapIDs
    local mapID = MapIDs and MapIDs:GetDisplayableMapForPlayer()
    if mapID then self:CenterMap(mapID) end
end

function ZoomController:CenterMap(mapID, scale)
    local m = mapInst()
    if not m or mapID == nil or mapID == -1 then return end

    local zone = m.GetWorldZone and m:GetWorldZone(mapID)
    if zone and zone.City then scale = 1 end

    m.MapW = (m.Frm and m.Frm:GetWidth() or 1) - (m.PadX or 0) * 2
    m.MapH = (m.Frm and m.Frm:GetHeight() or 1) - (m.TitleH or 0)

    local Coords = Carbonite.Modules.Map.Coords
    local x, y = Coords:WorldFromZone(mapID, 50, 50)

    local size = math.min(m.MapW / 1002, m.MapH / 668)
    local screenWidth = GetScreenWidth and GetScreenWidth() or 1680
    if m.MapW < screenWidth / 2 then
        size = size * (scale or 1.5)
    end

    local finalScale = size / Coords:GetScale(mapID) * 10.02
    self:Move(x, y, finalScale, 15)
end

function ZoomController:CenterMap1To1(mapID)
    local m = mapInst()
    if not m then return end
    local Coords = Carbonite.Modules.Map.Coords
    m.MapPosX, m.MapPosY = Coords:WorldFromZone(mapID, 50, 50)
    local screenWidth = GetScreenWidth and GetScreenWidth() or 1680
    m.Scale     = 1002 / 100 / Coords:GetScale(mapID) * screenWidth / 1680 * 2
    m.ScaleDraw = m.Scale
    m.StepTime  = 10
end

-- Rewire legacy entry points.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end

    NxMap.SetScaleOverTime = function(_, steps) ZoomController:ScrollSteps(steps) end
    NxMap.Move             = function(_, x, y, scale, stepTime) ZoomController:Move(x, y, scale, stepTime) end
    NxMap.GotoPlayer       = function(_) ZoomController:GotoPlayer() end
    NxMap.GotoCurrentZone  = function(_) ZoomController:GotoCurrentZone() end
    NxMap.CenterMap        = function(_, mapID, scale) ZoomController:CenterMap(mapID, scale) end
    NxMap.CenterMap1To1    = function(_, mapID) ZoomController:CenterMap1To1(mapID) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
