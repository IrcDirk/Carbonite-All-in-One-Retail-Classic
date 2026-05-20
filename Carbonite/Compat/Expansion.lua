-- Carbonite | Compat / Expansion
-- Centralizes every "which expansion are we on?" check. Old code
-- scattered `Nx.isClassic`, `Nx.isRetail`, `Nx.MOPMaps`, etc. across
-- 50+ files. The new architecture goes through this module:
--
--   if Carbonite.Compat.Expansion:HasFeature("WORLD_QUESTS") then ... end
--   local maxGather = Carbonite.Compat.Expansion:GetMaxGatherSkill()
--
-- A single TOC ships with all expansion interfaces declared, and
-- this file detects the running client at load time.

local Carbonite = _G.Carbonite

local Expansion = {}
Carbonite.Compat.Expansion = Expansion

-- WOW_PROJECT_ID constants. We treat unknown values as retail so
-- a brand-new expansion does not break Carbonite for users.
local PROJECT_IDS = {
    MAINLINE                  = _G.WOW_PROJECT_MAINLINE,
    CLASSIC                   = _G.WOW_PROJECT_CLASSIC,
    BURNING_CRUSADE_CLASSIC   = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC,
    WRATH_CLASSIC             = _G.WOW_PROJECT_WRATH_CLASSIC,
    CATACLYSM_CLASSIC         = _G.WOW_PROJECT_CATACLYSM_CLASSIC,
    MISTS_CLASSIC             = _G.WOW_PROJECT_MISTS_CLASSIC,
}

local function project(id) return _G.WOW_PROJECT_ID == id end

Expansion.projectId    = _G.WOW_PROJECT_ID
Expansion.isMainline   = project(PROJECT_IDS.MAINLINE)
Expansion.isClassic    = not Expansion.isMainline
Expansion.isClassicEra = project(PROJECT_IDS.CLASSIC)
Expansion.isTBC        = project(PROJECT_IDS.BURNING_CRUSADE_CLASSIC)
Expansion.isWrath      = project(PROJECT_IDS.WRATH_CLASSIC)
Expansion.isCata       = project(PROJECT_IDS.CATACLYSM_CLASSIC)
Expansion.isMoP        = project(PROJECT_IDS.MISTS_CLASSIC)

-- Numeric expansion level - useful for level-gated content checks.
-- Values match Blizzard's LE_EXPANSION_* constants.
local LEVEL = {
    CLASSIC      = 0,
    BC           = 1,
    WRATH        = 2,
    CATACLYSM    = 3,
    MISTS        = 4,
    WOD          = 5,
    LEGION       = 6,
    BFA          = 7,
    SHADOWLANDS  = 8,
    DRAGONFLIGHT = 9,
    WAR_WITHIN   = 10,
    MIDNIGHT     = 11,
}
Expansion.LEVEL = LEVEL

local _, _, _, tocVersion = GetBuildInfo()
Expansion.tocVersion = tocVersion or 0

-- Highest expansion level whose maps and quests are present on the
-- running client. Calculated from the TOC version so we don't have
-- to maintain a project->level table.
local function levelFromToc(toc)
    if toc >= 110000 then return LEVEL.WAR_WITHIN end
    if toc >= 100000 then return LEVEL.DRAGONFLIGHT end
    if toc >= 90000  then return LEVEL.SHADOWLANDS end
    if toc >= 80000  then return LEVEL.BFA end
    if toc >= 70000  then return LEVEL.LEGION end
    if toc >= 60000  then return LEVEL.WOD end
    if toc >= 50000  then return LEVEL.MISTS end
    if toc >= 40000  then return LEVEL.CATACLYSM end
    if toc >= 30000  then return LEVEL.WRATH end
    if toc >= 20000  then return LEVEL.BC end
    return LEVEL.CLASSIC
end
Expansion.level = levelFromToc(Expansion.tocVersion)

if Expansion.tocVersion >= 120000 then
    Expansion.level = LEVEL.MIDNIGHT
end

-- Feature flag table. Code asks "does this client support X?" instead
-- of testing project IDs. Most flags follow expansion gates, but a
-- few are conditional on the project (e.g. some retail-only APIs that
-- never made it into Classic backports).
local F = {}
Expansion.features = F

F.WORLD_QUESTS        = Expansion.isMainline and Expansion.level >= LEVEL.LEGION
F.GARRISONS           = Expansion.isMainline and Expansion.level >= LEVEL.WOD
F.QUEST_BLOBS         = Expansion.level >= LEVEL.CATACLYSM
F.MAP_C_MAP_API       = type(_G.C_Map) == "table" and type(_G.C_Map.GetMapInfo) == "function"
F.MAP_EXPLORATION_API = type(_G.C_MapExplorationInfo) == "table"
F.ITEM_C_ITEM_API     = type(_G.C_Item) == "table" and type(_G.C_Item.GetItemInfo) == "function"
F.NEW_TAXI_API        = type(_G.C_TaxiMap) == "table"
F.FLIGHT_PATHS_2X     = Expansion.level >= LEVEL.BC
F.DUAL_SPEC           = Expansion.level >= LEVEL.WRATH and Expansion.level < LEVEL.LEGION
F.TRANSMOG            = Expansion.isMainline and Expansion.level >= LEVEL.MISTS
F.PET_BATTLES         = Expansion.isMainline and Expansion.level >= LEVEL.MISTS

function Expansion:HasFeature(name)
    return F[name] == true
end

-- Map data folder name. Replaces the per-TOC `Data\<flavor>\` include
-- with a runtime-selected path. The data files themselves stay where
-- they are.
function Expansion:GetMapDataFolder()
    if self.isClassicEra then return "classic" end
    if self.isTBC        then return "tbc" end
    if self.isWrath      then return "wrath" end
    if self.isCata       then return "cata" end
    if self.isMoP        then return "mop" end
    return "retail"
end

function Expansion:GetMaxGatherSkill()
    if self.isMainline then return 9999 end
    if self.isMoP      then return 600 end
    if self.isCata     then return 525 end
    if self.isWrath    then return 450 end
    if self.isTBC      then return 375 end
    if self.isClassicEra then return 300 end
    return 9999
end

-- Old code reads `Nx.isRetail` and friends directly. Mirror the
-- canonical flags back onto the Nx/Carbonite namespace so we do not
-- have to touch every call site at once.
Carbonite.isRetail       = Expansion.isMainline
Carbonite.isClassic      = Expansion.isClassic
Carbonite.isClassicEra   = Expansion.isClassicEra
Carbonite.isTBCClassic   = Expansion.isTBC
Carbonite.isWotlkClassic = Expansion.isWrath
Carbonite.isCataClassic  = Expansion.isCata
Carbonite.isMoPClassic   = Expansion.isMoP
