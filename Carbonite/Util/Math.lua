-- Carbonite | Util / Math
-- Math helpers used by the map module and the routing/path code.

local Carbonite = _G.Carbonite
local Math = {}
Carbonite.Util.Math = Math

function Math.Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Math.Lerp(a, b, t)
    return a + (b - a) * t
end

function Math.Round(v)
    if v >= 0 then return math.floor(v + 0.5) end
    return -math.floor(-v + 0.5)
end

function Math.Distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Math.DistanceSq(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

-- Angle in radians from (x1,y1) to (x2,y2). 0 = east, pi/2 = north.
function Math.Angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function Math.Sign(v)
    if v > 0 then return 1 end
    if v < 0 then return -1 end
    return 0
end

-- Wraps an angle into [-pi, pi]. Used by the minimap rotation code.
function Math.WrapAngle(a)
    while a > math.pi  do a = a - 2 * math.pi end
    while a < -math.pi do a = a + 2 * math.pi end
    return a
end
