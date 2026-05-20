-- Carbonite | Core / SavedVariables
-- Wraps AceDB-3.0. The legacy Carbonite.lua already creates
-- `Nx.db = LibStub("AceDB-3.0"):New("CarbData", defaults, true)`
-- and registers a substantial defaults table (profile.General,
-- profile.Battleground, profile.Guide, profile.Map, profile.Track,
-- profile.Skin, ...).  This module's job is to add each
-- Carbonite.Core.Module's `dbDefaults` to the live DB WITHOUT
-- touching AceDB's defaults registration — calling RegisterDefaults
-- a second time triggers removeDefaults on the previous set, which
-- wipes all the legacy General/Battleground/Guide values and
-- breaks every legacy code path that reads them.
--
-- We instead populate db.profile[<Mod>]/char[<Mod>]/global[<Mod>]
-- directly. The legacy defaults stay AceDB-managed (so profile
-- copy / reset honors them); module defaults are lazy / sticky
-- (they persist via the regular SavedVariables flush at logout,
-- but don't auto-restore on profile reset).

local Carbonite = _G.Carbonite
local Logger = Carbonite.Core.Logger:Get("SavedVariables")

local SavedVariables = {}
Carbonite.Core.SavedVariables = SavedVariables

local moduleDB = {}

function SavedVariables:GetModuleDB(name)
    return moduleDB[name]
end

-- Deep-copy a default value so user mutations don't mutate our
-- shared defaults table.
local function copyValue(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, vv in pairs(v) do out[k] = copyValue(vv) end
    return out
end

local function bind()
    local db = Carbonite.db or _G.Nx and _G.Nx.db
    if not db then
        Logger:debug("AceDB not ready, deferring")
        return false
    end
    Carbonite.db = db

    -- Poke each module's defaults directly into the live db scope
    -- tables. Only writes when the destination key is nil so we
    -- never overwrite the user's saved values.
    for _, mod in ipairs(Carbonite.Core.Module.registry or {}) do
        if mod.dbDefaults then
            for scope, subTable in pairs(mod.dbDefaults) do
                local destScope = db[scope]
                if destScope then
                    for k, v in pairs(subTable) do
                        if destScope[k] == nil then
                            destScope[k] = copyValue(v)
                        end
                    end
                end
            end
        end
    end

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

-- The legacy OnInitialize runs at PLAYER_LOGIN. We listen on
-- CARBONITE_INITIALIZE (fired from our Bootstrap's PLAYER_LOGIN
-- handler) and retry-poll briefly if the DB isn't ready yet.
Carbonite.Core.EventBus:Subscribe("CARBONITE_INITIALIZE", function()
    if bind() then return end
    local tries = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self)
        tries = tries + 1
        if bind() or tries > 200 then self:SetScript("OnUpdate", nil) end
    end)
end)
