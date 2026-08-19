-- Carbonite | Modules / Map / GroupTracking
-- Party + raid member position polling and proximity queries. The
-- legacy NxMap.lua spread these across Nx.Map:GetGroupMemberAtCursor
-- and a raw GetPlayerMapPosition helper. This class is the single
-- public API; the legacy entry points are rewired to delegate.
--
--   GroupTracking:GetUnitPosition(unit) -> x, y in [0..1] or 0,0
--   GroupTracking:EachMember(fn)        -> iterate party/raid units
--   GroupTracking:GetMemberAtCursor(zx, zy, radiusZone) -> name, unit
--   GroupTracking:GetGroupSize()        -> { party = N, raid = N }
--
-- Coordinate convention: unit positions returned by C_Map are in
-- [0..1]. The cursor queries take zone coords in [0..100] to match
-- the legacy GetGroupMemberAtCursor signature, so internal conversion
-- happens here. Callers stop mixing the two scales by accident.

local Carbonite = _G.Carbonite
local GroupTracking = {}
Carbonite.Modules.Map.GroupTracking = GroupTracking

local DEFAULT_HIT_RADIUS = 3       -- zone units (zone is 0..100)

-- ---------------------------------------------------------------
-- Position read, with a "different map => zero" guard that matches
-- the legacy GetPlayerMapPosition. Callers don't want pins jumping
-- onto the wrong zone after a group member changes maps.
-- ---------------------------------------------------------------

function GroupTracking:GetUnitPosition(unit)
    if not unit or not _G.C_Map then return 0, 0 end
    local queryMapID = _G.C_Map.GetBestMapForUnit and _G.C_Map.GetBestMapForUnit(unit)
    if not queryMapID then return 0, 0 end

    local NxMap = _G.Nx and _G.Nx.Map
    local MapIDs = Carbonite.Modules.Map.MapIDs
    local logicalMapID = MapIDs and MapIDs.CanonicalizeMapID
        and MapIDs:CanonicalizeMapID(queryMapID)
        or queryMapID

    -- Compare Carbonite's logical map IDs (for example Undercity 90), but
    -- query the position on Blizzard's actual player map (Undercity 998).
    if unit ~= "player" and NxMap and NxMap.RMapId and logicalMapID ~= NxMap.RMapId then
        return 0, 0
    end

    local pos = _G.C_Map.GetPlayerMapPosition and _G.C_Map.GetPlayerMapPosition(queryMapID, unit)
    if not pos then return 0, 0 end
    local x, y = pos:GetXY()
    return x or 0, y or 0
end

-- ---------------------------------------------------------------
-- Iteration. Returns the canonical unit token ("party1", "raid12")
-- for the current group composition. Skips the player itself.
-- ---------------------------------------------------------------

function GroupTracking:EachMember(fn)
    if not _G.IsInGroup or not _G.IsInGroup() then return end
    local raid = _G.IsInRaid and _G.IsInRaid()
    local unitBase = raid and "raid" or "party"
    local max = raid and (_G.MAX_RAID_MEMBERS or 40) or (_G.MAX_PARTY_MEMBERS or 4)

    for i = 1, max do
        local unit = unitBase .. i
        if _G.UnitExists and _G.UnitExists(unit) and not _G.UnitIsUnit(unit, "player") then
            fn(unit, i)
        end
    end
end

-- ---------------------------------------------------------------
-- Cursor proximity query. Returns the closest party / raid member
-- within `radiusZone` zone units of the supplied cursor zone coord.
-- ---------------------------------------------------------------

function GroupTracking:GetMemberAtCursor(cursorZX, cursorZY, radiusZone)
    radiusZone = radiusZone or DEFAULT_HIT_RADIUS
    local bestSq = radiusZone * radiusZone
    local bestUnit, bestName

    self:EachMember(function(unit)
        local px, py = self:GetUnitPosition(unit)
        if px > 0 or py > 0 then
            local zx, zy = px * 100, py * 100
            local dx, dy = cursorZX - zx, cursorZY - zy
            local d = dx * dx + dy * dy
            if d < bestSq then
                bestSq = d
                bestUnit = unit
                local name, realm = _G.UnitName(unit)
                bestName = (realm and #realm > 0) and (name .. "-" .. realm) or name
            end
        end
    end)

    return bestName, bestUnit
end

function GroupTracking:GetGroupSize()
    local raidN  = (_G.GetNumGroupMembers and _G.IsInRaid and _G.IsInRaid()) and _G.GetNumGroupMembers() or 0
    local partyN = (_G.GetNumGroupMembers and not _G.IsInRaid()) and _G.GetNumGroupMembers() or 0
    return { party = partyN, raid = raidN }
end

-- Legacy rewire so existing callers route through here.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.GetGroupMemberAtCursor = function(_, zx, zy, r) return GroupTracking:GetMemberAtCursor(zx, zy, r) end
    NxMap.GetPlayerMapPosition   = function(unit)         return GroupTracking:GetUnitPosition(unit) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
