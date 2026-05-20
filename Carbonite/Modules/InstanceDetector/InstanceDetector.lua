-- Carbonite | Modules / InstanceDetector
-- Wraps GetInstanceInfo so callers stop branching on the variable
-- shape across client flavors. Carbonite uses this on every
-- ZONE_CHANGED_NEW_AREA pulse to know if the player just entered
-- a dungeon, raid, scenario, or BG.
--
-- Public API:
--   InstanceDetector:GetType()        -> "none"/"party"/"raid"/"pvp"/"arena"/"scenario"
--   InstanceDetector:GetDifficultyID()
--   InstanceDetector:GetMaxPlayers()
--   InstanceDetector:GetInstanceMapID()
--   InstanceDetector:IsInside()       -> bool (non-"none" type)
--   InstanceDetector:IsRaid()
--   InstanceDetector:IsParty()
--   InstanceDetector:IsBattleground()

local Carbonite = _G.Carbonite
local InstanceDetector = {}
Carbonite.Modules.InstanceDetector = InstanceDetector

local function info()
    if not _G.GetInstanceInfo then return nil end
    return _G.GetInstanceInfo()
end

function InstanceDetector:GetType()
    local _, instanceType = info(); return instanceType or "none"
end

function InstanceDetector:GetDifficultyID()
    local _, _, difficultyID = info(); return difficultyID or 0
end

function InstanceDetector:GetMaxPlayers()
    local _, _, _, _, maxPlayers = info(); return maxPlayers or 0
end

function InstanceDetector:GetInstanceMapID()
    local _, _, _, _, _, _, _, instanceMapID = info(); return instanceMapID or 0
end

function InstanceDetector:IsInside()       return self:GetType() ~= "none" end
function InstanceDetector:IsRaid()         return self:GetType() == "raid" end
function InstanceDetector:IsParty()        return self:GetType() == "party" end
function InstanceDetector:IsBattleground() return self:GetType() == "pvp" end
function InstanceDetector:IsArena()        return self:GetType() == "arena" end
function InstanceDetector:IsScenario()     return self:GetType() == "scenario" end
