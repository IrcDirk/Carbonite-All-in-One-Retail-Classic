-- Carbonite | Modules / Map / ScrollScale
-- The scale-step calculator used by mouse-wheel zoom and the
-- ZoomController. The legacy implementation lived as a one-line
-- method on Nx.Map (Nx.Map:ScrollScale). Owning it here lets us
-- document the constants and reuse them from other classes (e.g.
-- the ZoomController tests) without depending on a live map
-- instance.
--
-- The formula:
--   delta = value (>= 0 zoom in, < 0 zoom out)
--   if value < 0 then value = value * 0.76923  -- asymmetric feel
--   new = max(current + value * current * 0.3, MIN_SCALE)
--
-- The 0.76923 factor (≈ 10/13) is the legacy magic that makes zoom-
-- out feel slower than zoom-in. The 0.3 factor controls how much one
-- scroll tick changes the scale. MIN_SCALE clamps to 0.015 so we
-- can't drop below "world view".

local Carbonite = _G.Carbonite

local ScrollScale = {}
Carbonite.Modules.Map.ScrollScale = ScrollScale

ScrollScale.MIN_SCALE          = 0.015
ScrollScale.STEP               = 0.3
ScrollScale.ZOOM_OUT_DAMPING   = 0.76923    -- = 10 / 13

-- Pure function: compute next scale from (current, ticks).
-- Useful in tests + the zoom controller without touching live state.
function ScrollScale:Compute(currentScale, value)
    if not currentScale or currentScale <= 0 then currentScale = 1 end
    if value < 0 then value = value * self.ZOOM_OUT_DAMPING end
    local next_ = currentScale + value * currentScale * self.STEP
    if next_ < self.MIN_SCALE then next_ = self.MIN_SCALE end
    return next_
end

-- Method-style version that mutates the live primary map. Mirrors the
-- legacy Nx.Map:ScrollScale signature so callers don't have to
-- change.
function ScrollScale:Apply(value)
    local map = _G.Nx and _G.Nx.Map and _G.Nx.Map.Maps and _G.Nx.Map.Maps[1]
    if not map then return end
    map.Scale = self:Compute(map.Scale, value)
    map.StepTime = 10
    if map.Scale then map.MapScale = map.Scale / 10.02 end
    return map.Scale
end

-- Rewire the legacy method.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.ScrollScale = function(self_, value)
        -- The legacy method expected `self` to be the map instance
        -- and returned the new scale.
        return ScrollScale:Compute(self_.Scale or 1, value or 0)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
