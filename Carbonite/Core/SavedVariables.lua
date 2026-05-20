-- Carbonite | Core / SavedVariables
-- Wraps AceDB-3.0. Because the legacy Carbonite.lua already creates
-- `Nx.db = LibStub("AceDB-3.0"):New("CarbData", defaults, true)`
-- during its own OnInitialize, this module's job is NOT to create
-- a second DB. Instead:
--   1. It waits for the legacy DB to appear.
--   2. It merges every Module's `dbDefaults` into the existing DB
--      via db:RegisterDefaults.
--   3. It exposes per-module sub-DBs to keep keys namespaced.

local Carbonite = _G.Carbonite
local Logger = Carbonite.Core.Logger:Get("SavedVariables")

local SavedVariables = {}
Carbonite.Core.SavedVariables = SavedVariables

local moduleDB = {}

function SavedVariables:GetModuleDB(name)
    return moduleDB[name]
end

-- Snapshots each module's dbDefaults and merges them into the live
-- AceDB instance. Safe to call multiple times - AceDB de-dupes
-- repeat RegisterDefaults calls by replacing the defaults table.
local function bind()
    local db = Carbonite.db or _G.Nx and _G.Nx.db
    if not db then
        Logger:debug("AceDB not ready, deferring")
        return false
    end
    Carbonite.db = db

    -- Build a merged defaults table for every module then register it.
    local merged = { profile = {}, char = {}, global = {}, realm = {}, factionrealm = {} }
    for _, mod in ipairs(Carbonite.Core.Module.registry or {}) do
        if mod.dbDefaults then
            for scope, subTable in pairs(mod.dbDefaults) do
                merged[scope] = merged[scope] or {}
                for k, v in pairs(subTable) do
                    merged[scope][k] = v
                end
            end
        end
    end
    db:RegisterDefaults(merged)

    -- Build per-module DB views over the now-populated db.
    for _, mod in ipairs(Carbonite.Core.Module.registry or {}) do
        local name = mod:GetName()
        db.profile[name] = db.profile[name] or {}
        db.char[name]    = db.char[name]    or {}
        db.global[name]  = db.global[name]  or {}
        moduleDB[name] = {
            profile = db.profile[name],
            char    = db.char[name],
            global  = db.global[name],
        }
    end

    Logger:debug("AceDB bound; %d modules registered", #(Carbonite.Core.Module.registry or {}))
    return true
end

-- The legacy OnInitialize runs at PLAYER_LOGIN. We listen there.
-- If the DB still is not ready we retry once a frame for a few
-- seconds before giving up.
Carbonite.Core.EventBus:Subscribe("CARBONITE_INITIALIZE", function()
    if bind() then return end
    local tries = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self)
        tries = tries + 1
        if bind() or tries > 200 then self:SetScript("OnUpdate", nil) end
    end)
end)
