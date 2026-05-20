-- Carbonite | Modules / Map / TravelGraph
-- Higher-level queries against the travel graph (flight masters,
-- zone connections, riding skill). The actual graph and the heavy
-- pathing routines (FindFlight / FindConnection / MakePath) still
-- live in NxTravel.lua because they share state with the taxi-
-- capture system. This class exposes the small but frequently used
-- accessors as a clean public API.
--
--   TravelGraph:GetRidingSkill()         -> int
--   TravelGraph:GetFlightSpeed()         -> world units per second
--   TravelGraph:HasFlyingMount()         -> bool / spell name
--   TravelGraph:FindClosestFM(mapID, x, y) -> dist, node, tex
--   TravelGraph:RefreshFlying(continent, riding)
--
-- Other modules should prefer Carbonite.Modules.Map.Pathing for
-- actual path planning (it already exists). This class is for
-- one-shot questions like "do I have flying here?" or "which is
-- the nearest flight master?".

local Carbonite = _G.Carbonite

local TravelGraph = {}
Carbonite.Modules.Map.TravelGraph = TravelGraph

local function nxTravel() return _G.Nx and _G.Nx.Travel end

function TravelGraph:GetRidingSkill()
    local t = nxTravel()
    if not t or not t.GetRidingSkill then return 0 end
    return t:GetRidingSkill() or 0
end

function TravelGraph:GetFlightSpeed()
    local t = nxTravel()
    return t and t.Speed or 0
end

function TravelGraph:HasFlyingMount()
    local t = nxTravel()
    return t and t.FlyingMount or false
end

-- Recalculate flying status for `continent` at `riding` skill, then
-- store the result inside Nx.Travel. Mirrors Travel:UpdateFlyingForCont.
function TravelGraph:RefreshFlying(continent, riding)
    local t = nxTravel()
    if t and t.UpdateFlyingForCont then
        t:UpdateFlyingForCont(continent, riding or self:GetRidingSkill())
    end
    Carbonite.Core.EventBus:Fire("TRAVEL_FLYING_REFRESHED", continent, t and t.FlyingMount)
end

-- Returns (distance, node, texture) for the closest known flight
-- master from (mapID, posX, posY). Whatever Travel:FindClosest
-- returns is forwarded.
function TravelGraph:FindClosestFM(mapID, posX, posY)
    local t = nxTravel()
    if not t or not t.FindClosest then return nil end
    return t:FindClosest(mapID, posX, posY)
end

-- ----------------------------------------------------------------
-- Slash command convenience: /cb fly tells the user whether they
-- have flying on their current continent and what the active speed
-- multiplier is. Useful for debugging path-cost calculations.
-- ----------------------------------------------------------------

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("fly", function()
        local log = Carbonite.Core.Logger:Get("TravelGraph")
        local mm = TravelGraph:HasFlyingMount()
        log:info("riding skill: %d", TravelGraph:GetRidingSkill())
        log:info("flying: %s", mm and tostring(mm) or "no")
        log:info("speed:  %.3f world u/s", TravelGraph:GetFlightSpeed())
    end, "show flying-mount status on current continent")
end)
