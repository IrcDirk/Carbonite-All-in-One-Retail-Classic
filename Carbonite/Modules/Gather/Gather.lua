-- Carbonite | Modules / Gather
-- Public class around the Carbonite gathering-node database. The
-- legacy code exposed it via Nx.GatherInfo (data) + a bag of
-- Nx:XxxNameToId / Nx:GatherXxx / Nx:GetGather / Nx:IsGathering
-- helpers. This module wraps those into a stable API, keeping the
-- legacy global as the source of truth so existing callers and
-- the data files keep working.
--
-- Public API:
--   Gather:Get(typ, id)               -> name, item, color    (legacy 3-tuple)
--   Gather:NameToID(typ, name)        -> id or nil
--   Gather:HerbNameToID(name)
--   Gather:MineNameToID(name)
--   Gather:IsGathering(spellName)     -> "Herb Gathering"/"Mining"/nil
--   Gather:RecordHerb(id, mapID, x, y, level)
--   Gather:RecordMine(id, mapID, x, y, level)
--   Gather:GetMaxSkill()              -> per-client cap
--   Gather:ShouldShowNode(skill, exp) -> bool
--
-- `typ` is the legacy single-letter key: "H" = herbs, "M" = mines,
-- "L" = timber. Other letters can be added by the data files.

local Carbonite = _G.Carbonite

local Gather = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Gather = Gather

local function nx() return _G.Nx end
local function info(typ)
    local n = nx()
    return n and n.GatherInfo and n.GatherInfo[typ]
end

-- ----------------------------------------------------------------
-- Lookups
-- ----------------------------------------------------------------

function Gather:Get(typ, id)
    local i = info(typ)
    if not i or not i[id] then return nil end
    local v = i[id]
    return v[3], v[2], v[1]
end

function Gather:NameToID(typ, name)
    local i = info(typ)
    if not i or not name then return nil end
    for k, v in ipairs(i) do
        if v[3] == name then return k end
    end
end

function Gather:HerbNameToID(name)
    return self:NameToID("H", name)
end

function Gather:MineNameToID(name)
    local n = nx()
    if not name then return nil end
    -- Mirror the legacy normalization: strip "Ooze Covered" prefix
    -- and translate the special "Thorium Vein" case.
    local L = n and n.L or nil
    if n and n.gsub then
        local oozePrefix = (L and L["Ooze Covered"] or "Ooze Covered") .. " "
        name = name:gsub(oozePrefix, "")
        if name == (L and L["Thorium Vein"] or "Thorium Vein") then
            name = (L and L["Small Thorium Vein"]) or "Small Thorium Vein"
        end
    end
    return self:NameToID("M", name)
end

-- ----------------------------------------------------------------
-- Spell -> category. Cached so per-pulse tradeskill checks stay
-- O(1) after first call.
-- ----------------------------------------------------------------

local spellCache = { H = nil, M = nil }

local function buildSpellCache(typ)
    spellCache[typ] = {}
    local i = info(typ) or {}
    for _, v in ipairs(i) do
        if type(v[3]) == "string" then spellCache[typ][v[3]] = true end
    end
end

function Gather:IsGathering(spellName)
    if type(spellName) ~= "string" then return nil end
    if not spellCache.H then buildSpellCache("H") end
    if not spellCache.M then buildSpellCache("M") end
    if spellCache.H[spellName] then return "Herb Gathering" end
    if spellCache.M[spellName] then return "Mining" end
end

-- Bust the cache; called when gather data is reloaded (rare).
function Gather:InvalidateCache()
    spellCache.H, spellCache.M = nil, nil
end

-- ----------------------------------------------------------------
-- Recording. Forwards to the legacy Nx:GatherHerb / Nx:GatherMine
-- because the storage layout lives there and is read by the map
-- renderer; we don't reimplement.
-- ----------------------------------------------------------------

function Gather:RecordHerb(id, mapID, x, y, level)
    local n = nx()
    if n and n.GatherHerb then n:GatherHerb(id, mapID, x, y, level) end
    Carbonite.Core.EventBus:Fire("GATHER_RECORDED", "herb", id, mapID, x, y)
end

function Gather:RecordMine(id, mapID, x, y, level)
    local n = nx()
    if n and n.GatherMine then n:GatherMine(id, mapID, x, y, level) end
    Carbonite.Core.EventBus:Fire("GATHER_RECORDED", "mine", id, mapID, x, y)
end

-- ----------------------------------------------------------------
-- Expansion-aware show / hide filters. Forward to the legacy
-- helpers on the addon table; both already exist (added in earlier
-- commits to fix WoD+ gather node detection).
-- ----------------------------------------------------------------

function Gather:GetMaxSkill()
    local n = nx()
    if n and n.GetMaxGatherSkill then return n:GetMaxGatherSkill() end
    return Carbonite.Compat.Expansion and Carbonite.Compat.Expansion:GetMaxGatherSkill() or 9999
end

function Gather:ShouldShowNode(skill, isExpansionNode)
    local n = nx()
    if n and n.ShouldShowGatherNode then return n:ShouldShowGatherNode(skill, isExpansionNode) end
    if not skill then return true end
    return skill <= self:GetMaxSkill()
end
