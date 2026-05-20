-- Carbonite | Modules / Map / GuideLocations
-- Lookup helpers for the NPC location database that ships with the
-- guide data file (NxMapGuide.lua). The legacy code exposes one
-- function Nx.Map.Guide:FindTaxis(name) plus the underlying
-- Nx.NPCData table. This class is the documented accessor.
--
-- Public API:
--   GuideLocations:FindTaxi(locName)    -> npcName, worldX, worldY
--   GuideLocations:FindNPC(predicate)   -> npcName, mapID, worldX, worldY
--   GuideLocations:Each(fn)             - iterate every entry
--   GuideLocations:GetCount()           - number of entries
--
-- The legacy faction filter (Horde hides Alliance-only NPCs, vice
-- versa) is preserved verbatim so the user's view stays consistent.

local Carbonite = _G.Carbonite

local GuideLocations = {}
Carbonite.Modules.Map.GuideLocations = GuideLocations

local function npcData() return _G.Nx and _G.Nx.NPCData end

local function hideFaction()
    local PC = Carbonite.Modules.PlayerCharacter
    if PC then
        local f = PC:GetFactionGroup()
        if f == "Horde" then return 1 end
        if f == "Alliance" then return 2 end
        return 0
    end
    -- Fallback when PlayerCharacter module isn't loaded yet.
    local fg = _G.UnitFactionGroup and _G.UnitFactionGroup("player")
    if fg == "Horde" then return 1 end
    if fg == "Alliance" then return 2 end
    return 0
end

local function split(npcStr)
    local Util = Carbonite.Util.LegacyStrings
    if Util and Util.Split then return Util.Split("|", npcStr) end
    return strsplit("|", npcStr)
end

-- Returns the world position of a taxi-master (or any guide NPC)
-- by location name, while skipping the opposite-faction entries.
function GuideLocations:FindTaxi(campName)
    local data = npcData()
    if not data or not campName then return nil end

    local hide = hideFaction()
    for _, npcStr in pairs(data) do
        local fac, name, locName, zone, x, y = split(npcStr)
        fac  = tonumber(fac) or 0
        zone = tonumber(zone)
        x    = tonumber(x)
        y    = tonumber(y)
        if fac ~= hide and locName == campName then
            local Coords = Carbonite.Modules.Map.Coords
            local wx, wy = 0, 0
            if Coords and zone then wx, wy = Coords:WorldFromZone(zone, x, y) end
            return name, wx, wy, zone
        end
    end
end

-- Generic search. predicate(name, locName, mapID, x, y, faction)
-- returns true to stop and return the match.
function GuideLocations:FindNPC(predicate)
    local data = npcData()
    if not data or type(predicate) ~= "function" then return nil end
    for _, npcStr in pairs(data) do
        local fac, name, locName, zone, x, y = split(npcStr)
        fac, zone, x, y = tonumber(fac), tonumber(zone), tonumber(x), tonumber(y)
        if predicate(name, locName, zone, x, y, fac) then
            local Coords = Carbonite.Modules.Map.Coords
            local wx, wy = 0, 0
            if Coords and zone then wx, wy = Coords:WorldFromZone(zone, x, y) end
            return name, zone, wx, wy
        end
    end
end

function GuideLocations:Each(fn)
    local data = npcData()
    if not data then return end
    for _, npcStr in pairs(data) do
        local fac, name, locName, zone, x, y = split(npcStr)
        fn(name, locName, tonumber(zone), tonumber(x), tonumber(y), tonumber(fac))
    end
end

function GuideLocations:GetCount()
    local data = npcData()
    if not data then return 0 end
    local n = 0; for _ in pairs(data) do n = n + 1 end
    return n
end
