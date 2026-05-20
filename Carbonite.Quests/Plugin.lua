-- Carbonite.Quests | Plugin entry
-- New front door for the Quests plugin. Behaves like every other
-- Carbonite plugin: registers options on the central panel, exposes
-- a clean API for other plugins, and routes events through the
-- shared EventBus.
--
-- The actual quest database parsing, tracker UI, and route planning
-- still live in NxQuest.lua and the Data/<expansion>/ folders. This
-- file is the structural change: a single multi-interface TOC will
-- replace the five per-expansion variants, and runtime detection
-- picks the right data folder via Carbonite.Compat.Expansion.

local Carbonite = _G.Carbonite
if not Carbonite then return end

local AceAddon = LibStub("AceAddon-3.0")
local Plugin = Carbonite.Core.Plugin
local Expansion = Carbonite.Compat.Expansion

local QuestAddon = AceAddon:GetAddon("Carbonite.Quest", true)
if not QuestAddon then
    QuestAddon = AceAddon:NewAddon("Carbonite.Quest",
        "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0", "AceHook-3.0")
end

local Quests = {}
QuestAddon.Public = Quests
Carbonite.Quests = Quests

-- Returns the loaded quest database for the running client. The
-- per-flavor data files all populate a single global table; this
-- accessor just exposes it via a stable name.
function Quests:GetDatabase()
    return _G.NXQuestDB or (_G.Nx and _G.Nx.Quest and _G.Nx.Quest.DB)
end

function Quests:Get(questID)
    local db = self:GetDatabase()
    if not db then return nil end
    return db[questID]
end

function Quests:Each(fn)
    local db = self:GetDatabase()
    if not db then return end
    for id, data in pairs(db) do fn(id, data) end
end

function Quests:GetExpansionFolder()
    return Expansion:GetMapDataFolder()
end

function Quests:ToggleTracker()
    local Nx = _G.Nx
    if Nx and Nx.Quest and Nx.Quest.ToggleShow then Nx.Quest:ToggleShow() end
end

Plugin.Bind(QuestAddon, "Quests", {
    displayName = "Quests",
    order       = 15,
    options = function()
        local Nx = _G.Nx
        local function qdb()
            if Nx and Nx.qdb then return Nx.qdb.profile.Quest or {} end
            return {}
        end
        return {
            type = "group",
            name = "Quests",
            args = {
                blurb = {
                    order = 1, type = "description",
                    name = "Quest tracker, watchlist, and database. The full options panel still ships from the legacy module while the rewrite is in progress.\n\nQuest data for this client: |cffd700ff" .. Expansion:GetMapDataFolder() .. "|r",
                },
                tracker = {
                    order = 2, type = "execute", name = "Toggle quest tracker",
                    func = function() Quests:ToggleTracker() end,
                },
                autoTurnin = {
                    order = 3, type = "toggle", name = "Auto-turn-in completed quests",
                    get = function() return qdb().AutoTurnin end,
                    set = function(_, v) qdb().AutoTurnin = v end,
                },
                shareInParty = {
                    order = 4, type = "toggle", name = "Share quest progress in party",
                    get = function() return qdb().ShareInParty end,
                    set = function(_, v) qdb().ShareInParty = v end,
                },
                showRoute = {
                    order = 5, type = "toggle", name = "Show recommended route on map",
                    get = function() return qdb().ShowRoute ~= false end,
                    set = function(_, v) qdb().ShowRoute = v end,
                },
                colorByLevel = {
                    order = 6, type = "toggle", name = "Color quests by level difficulty",
                    get = function() return qdb().ColorByLevel ~= false end,
                    set = function(_, v) qdb().ColorByLevel = v end,
                },
            },
        }
    end,
})

-- Push quest objective pins onto the Map module's "Quests" layer when
-- the map asks for a refresh.
Carbonite.Core.EventBus:Subscribe("MAP_REFRESH", function()
    local MapMod = Carbonite:GetModule("Map", true)
    if not MapMod then return end
    if not MapMod:DB().profile.ShowQuests then return end
    local Nx = _G.Nx
    if not Nx or not Nx.Quest or not Nx.Quest.Watched then return end

    local layer = MapMod:GetLayer("Quests")
    layer:Clear()

    for _, q in pairs(Nx.Quest.Watched) do
        if q.mapID and q.x and q.y then
            MapMod:AddPin("Quests", "Quest", {
                mapID   = q.mapID,
                x       = q.x,
                y       = q.y,
                questID = q.id,
                role    = q.role or "objective",
                title   = q.title,
            })
        end
    end
end)
