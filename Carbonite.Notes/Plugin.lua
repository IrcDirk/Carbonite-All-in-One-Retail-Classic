-- Carbonite.Notes | Plugin entry
-- New, clean front door for the Notes plugin. Hosts the public API
-- that the rest of the Carbonite ecosystem should use, layered on
-- top of the legacy NxFav.lua storage and UI.
--
-- The legacy CarboniteNotes AceAddon and its Nx.Notes namespace
-- still exist for backwards-compat; this file:
--   - Exposes a typed Notes:Add / Notes:Remove / Notes:Each API.
--   - Registers options on the new Carbonite Options panel.
--   - Re-broadcasts note add/remove via the EventBus so the Map
--     module can drop NotePins automatically.
--
-- Load order: this file is listed BEFORE NxFav.lua in the TOC so
-- the namespace is created early; NxFav.lua's OnInitialize then
-- populates the legacy storage Notes:Each reads from.

local Carbonite = _G.Carbonite
if not Carbonite then return end  -- main Carbonite missing; nothing to do

local AceAddon = LibStub("AceAddon-3.0")
local Plugin = Carbonite.Core.Plugin

-- Reuse the existing CarboniteNotes AceAddon object - NxFav.lua may
-- have already created it. NewAddon errors on duplicates, so we
-- check GetAddon first.
local NotesAddon = AceAddon:GetAddon("CarboniteNotes", true)
if not NotesAddon then
    NotesAddon = AceAddon:NewAddon("CarboniteNotes",
        "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceHook-3.0")
end

local Notes = {}
NotesAddon.Public = Notes
-- Cross-plugin access slot. We can NOT use `Carbonite.Notes` here:
-- `Carbonite` is the same table as the legacy `Nx`, and NxFav.lua
-- has already populated `Nx.Notes` with its own method table
-- (Init / Update / Folders / etc.). Overwriting that table erases
-- those methods and the AceTimer-deferred OnInitialize crashes at
-- `Nx.Notes:Init()`. Hang our public API off Carbonite.Plugins
-- instead, which is a namespace we own.
Carbonite.Plugins = Carbonite.Plugins or {}
Carbonite.Plugins.Notes = Notes

-- Pull a note iterator from the legacy storage. The legacy storage
-- has changed shape several times; this normalizes them to a flat
-- list of { mapID, x, y, text, icon } regardless of folder layout.
function Notes:Each(fn)
    local Nx = _G.Nx
    if not Nx or not Nx.Notes or not Nx.Notes.Folders then return end

    local function walk(folder)
        if not folder or not folder.Items then return end
        for _, item in ipairs(folder.Items) do
            if item.Items then
                walk(item)
            else
                fn({
                    mapID = item.MapId or item.mapID,
                    x     = item.x or item.X,
                    y     = item.y or item.Y,
                    text  = item.Name or item.text or "",
                    icon  = item.IconIdx and Nx.Notes:GetIconFile(item.IconIdx),
                })
            end
        end
    end

    walk(Nx.Notes.Folders)
end

function Notes:Add(opts)
    local Nx = _G.Nx
    if not Nx or not Nx.Notes or not Nx.Notes.AddNoteAt then return false end
    Nx.Notes:AddNoteAt(opts.mapID, opts.x, opts.y, opts.text or "")
    Carbonite.Core.EventBus:Fire("NOTES_ADDED", opts)
    return true
end

function Notes:ToggleWindow()
    local Nx = _G.Nx
    if Nx and Nx.Notes and Nx.Notes.ToggleShow then Nx.Notes:ToggleShow() end
end

-- Bind to the Carbonite plugin registry so the EventBus and options
-- pages know about us.
Plugin.Bind(NotesAddon, "Notes", {
    displayName = "Notes",
    order       = 40,
    options = function()
        local Nx = _G.Nx
        local function notesDB()
            if Nx and Nx.fdb then return Nx.fdb.profile.Notes else return {} end
        end
        return {
            type = "group",
            name = "Notes",
            args = {
                showMap = {
                    order = 1, type = "toggle", name = "Show notes on map",
                    get = function() return notesDB().ShowMap end,
                    set = function(_, v) notesDB().ShowMap = v end,
                },
                handy = {
                    order = 2, type = "toggle", name = "HandyNotes integration",
                    get = function() return notesDB().HandyNotes end,
                    set = function(_, v) notesDB().HandyNotes = v end,
                },
                handySize = {
                    order = 3, type = "range", name = "HandyNotes icon size",
                    min = 8, max = 48, step = 1,
                    get = function() return notesDB().HandyNotesSize or 15 end,
                    set = function(_, v) notesDB().HandyNotesSize = v end,
                },
                rareScanner = {
                    order = 4, type = "toggle", name = "RareScanner integration",
                    get = function() return notesDB().RareScanner end,
                    set = function(_, v) notesDB().RareScanner = v end,
                },
                rareScannerSize = {
                    order = 5, type = "range", name = "RareScanner icon size",
                    min = 8, max = 64, step = 1,
                    get = function() return notesDB().RareScannerSize or 32 end,
                    set = function(_, v) notesDB().RareScannerSize = v end,
                },
                questie = {
                    order = 6, type = "toggle", name = "Questie integration",
                    get = function() return notesDB().Questie end,
                    set = function(_, v) notesDB().Questie = v end,
                },
                questieSE = {
                    order = 7, type = "toggle", name = "Questie available quests",
                    get = function() return notesDB().QuestieSE end,
                    set = function(_, v) notesDB().QuestieSE = v end,
                },
                questieSize = {
                    order = 8, type = "range", name = "Questie icon size",
                    min = 8, max = 64, step = 1,
                    get = function() return notesDB().QuestieSize or 32 end,
                    set = function(_, v) notesDB().QuestieSize = v end,
                },
            },
        }
    end,
})

-- When the Map module asks for note pins to render, hand them over.
-- Layer name must match the Pin kind so the Renderer's per-layer
-- Pin.GetClass(layer.name) lookup finds the metadata. Currently the
-- legacy NxFav:UpdateIcons populates the parallel "!Fav" layer per
-- frame; this handler is the event-driven new path and only fires
-- on explicit Map:Refresh(). We leave the legacy producer in place
-- until the NxFav port migrates UpdateIcons over.
Carbonite.Core.EventBus:Subscribe("MAP_REFRESH", function()
    local MapMod = Carbonite:GetModule("Map", true)
    if not MapMod then return end
    local layer = MapMod:GetLayer("Note")
    layer:Clear()
    Notes:Each(function(note)
        if not note.mapID or not note.x or not note.y then return end
        MapMod:AddPin("Note", "Note", note)
    end)
end)
