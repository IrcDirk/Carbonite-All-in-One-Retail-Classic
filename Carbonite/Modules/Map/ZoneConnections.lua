-- Carbonite | Modules / Map / ZoneConnections
-- Wraps Nx.Travel:FindConnection / FindCrossContinent, the
-- functions that walk Carbonite's zone-portal graph to answer
-- "how do I get from zone A to zone B without flying?". The
-- legacy implementations live in NxTravel.lua because they
-- depend on Nx.Map.MapWorldInfo[*].Connections; this class is
-- the documented public accessor.
--
-- Public API:
--   ZoneConnections:Find(srcMapID, srcX, srcY,
--                         dstMapID, dstX, dstY, skipIndirect)
--                             -> dist, connectionData (or straight-line
--                                distance when player can fly)
--   ZoneConnections:FindCrossContinent(cont1, srcMapID, srcX, srcY,
--                                       cont2, dstMapID, dstX, dstY)
--   ZoneConnections:HasDirect(srcMapID, dstMapID) -> bool
--   ZoneConnections:GetConnectionsFrom(mapID)     -> table or {}
--
-- The returned `connectionData` is the legacy table shape (Start*,
-- End*, StartMapId, EndMapId) so existing path-building code keeps
-- consuming it unchanged.

local Carbonite = _G.Carbonite

local ZoneConnections = {}
Carbonite.Modules.Map.ZoneConnections = ZoneConnections

local function travel() return _G.Nx and _G.Nx.Travel end
local function NxMap()  return _G.Nx and _G.Nx.Map end

function ZoneConnections:Find(srcMapID, srcX, srcY, dstMapID, dstX, dstY, skipIndirect)
    local t = travel()
    if not t or not t.FindConnection then return nil end
    -- Reset the visited-set used by FindConnection so successive calls
    -- can't accidentally short-circuit due to a stale traversal state.
    t.VisitedMapIds = t.VisitedMapIds or {}
    return t:FindConnection(srcMapID, srcX, srcY, dstMapID, dstX, dstY, skipIndirect)
end

function ZoneConnections:FindCrossContinent(cont1, srcMapID, srcX, srcY,
                                            cont2, dstMapID, dstX, dstY)
    local t = travel()
    if not t or not t.FindCrossContinent then return nil end
    return t:FindCrossContinent(cont1, srcMapID, srcX, srcY,
                                cont2, dstMapID, dstX, dstY)
end

function ZoneConnections:GetConnectionsFrom(mapID)
    local m = NxMap()
    local info = m and m.MapWorldInfo and m.MapWorldInfo[mapID]
    return (info and info.Connections) or {}
end

function ZoneConnections:HasDirect(srcMapID, dstMapID)
    local conns = self:GetConnectionsFrom(srcMapID)
    return conns[dstMapID] ~= nil
end

-- Counts every direct connection currently catalogued for a given map.
function ZoneConnections:CountDirect(mapID)
    local conns = self:GetConnectionsFrom(mapID)
    local n = 0
    for _ in pairs(conns) do n = n + 1 end
    return n
end
