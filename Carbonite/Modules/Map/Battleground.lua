-- Carbonite | Modules / Map / Battleground
-- Owns battleground / instance-type detection. The old code peppered
-- IsBattleGroundMap / IsMicroDungeon / IsScenario / GCMI_OVERRIDE
-- across NxMap and checked the global Nx.InBG / Nx.inBG flag ad hoc.
-- This class is one place those answers live, plus a single event
-- listener that keeps Nx.InBG in sync via PLAYER_ENTERING_WORLD.
--
--   Battleground:IsBGMap(mapID)        -> bool
--   Battleground:IsMicroDungeon(mapID) -> bool
--   Battleground:IsScenario(mapID)     -> bool
--   Battleground:GetShortName(mapID)   -> "AB", "WSG", etc.
--   Battleground:GetOverrideMapID(id)  -> overrideMapWorldId or id
--   Battleground:IsInBG()              -> bool, mirrors Nx.InBG
--   Battleground:Refresh()             -> recompute Nx.InBG now

local Carbonite = _G.Carbonite
local Battleground = {}
Carbonite.Modules.Map.Battleground = Battleground

local function NxMap() return _G.Nx and _G.Nx.Map end

-- micro-dungeon mapType is 5 in Enum.UIMapType.Micro
local UIMAP_TYPE_MICRO = 5

local microCache = {}

function Battleground:IsBGMap(mapID)
    local m = NxMap()
    if not m or not m.MapWorldInfo or not m.MapWorldInfo[mapID] then return false end
    return m.MapWorldInfo[mapID].Short ~= nil
end

function Battleground:IsMicroDungeon(mapID)
    if microCache[mapID] ~= nil then return microCache[mapID] end
    local info = _G.C_Map and _G.C_Map.GetMapInfo and _G.C_Map.GetMapInfo(mapID)
    local enum = _G.Enum and _G.Enum.UIMapType
    local micro = enum and enum.Micro or UIMAP_TYPE_MICRO
    local isMicro = info and info.mapType == micro or false
    microCache[mapID] = isMicro
    return isMicro
end

function Battleground:IsScenario(mapID)
    local m = NxMap()
    if not m or not _G.GetInstanceInfo then return false end
    local _, _, difficultyIndex = _G.GetInstanceInfo()
    if m.GetCurrentMapId and m:GetCurrentMapId() == mapID and difficultyIndex == 1 then
        return true
    end
    return false
end

function Battleground:GetShortName(mapID)
    local m = NxMap()
    return m and m.MapWorldInfo and m.MapWorldInfo[mapID] and m.MapWorldInfo[mapID].Short or nil
end

function Battleground:GetOverrideMapID(mapID)
    if not mapID then return mapID end
    local zone = Carbonite.Modules.Map.ZoneIterator
    if zone then
        local info = zone:GetZone(mapID)
        if info and info.overrideMapWorldId then return info.overrideMapWorldId end
    end
    return mapID
end

function Battleground:IsInBG()
    return _G.Nx and _G.Nx.InBG == true
end

-- Recompute Nx.InBG from the live instance type. Called from the
-- listener registered below; safe to invoke from outside too.
function Battleground:Refresh()
    local Nx = _G.Nx
    if not Nx then return end
    if not _G.GetInstanceInfo then return end
    local _, instanceType = _G.GetInstanceInfo()
    Nx.InBG = (instanceType == "pvp" or instanceType == "arena")
    Carbonite.Core.EventBus:Fire("BG_STATE_CHANGED", Nx.InBG)
end

-- Single listener for BG transitions. Subscribed at addon enable.
local function bindListener()
    local frame = CreateFrame("Frame", "CarbBattlegroundListener")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:SetScript("OnEvent", function() Battleground:Refresh() end)
    Battleground:Refresh()
end

local function rewireLegacy()
    local m = NxMap()
    if not m then return end
    m.IsBattleGroundMap = function(_, mapID) return Battleground:IsBGMap(mapID) end
    m.IsMicroDungeon    = function(_, mapID) return Battleground:IsMicroDungeon(mapID) end
    m.IsScenario        = function(_, mapID) return Battleground:IsScenario(mapID) end
    m.GetShortName      = function(_, mapID) return Battleground:GetShortName(mapID) end
    m.GCMI_OVERRIDE     = function(_, mapID) return Battleground:GetOverrideMapID(mapID) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function() rewireLegacy(); bindListener() end)
