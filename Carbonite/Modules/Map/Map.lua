-- Carbonite | Modules / Map
-- Module entry for the Carbonite map. The heavy rendering code still
-- lives in the legacy NxMap.lua and is reachable through `Carbonite.Map`;
-- this file owns module lifecycle, layer registry, options page, and
-- the public Pin/Layer API new code should use.
--
-- Public API exposed on `Carbonite:GetModule("Map")`:
--   Map:GetLayer(name)        - returns or creates a named layer
--   Map:AddPin(layerName, kind, opts) - adds a pin and returns it
--   Map:Open()                - opens the Carbonite map window
--   Map:Close()
--   Map:Refresh()             - notifies all layers to re-render
--   Map:GetPlayerMapID()      - convenience accessor
--   Map:OnZoneChanged(fn)     - subscribe to player-zone changes

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module
local Pin = Carbonite.Modules.Map.Pin
local Layer = Carbonite.Modules.Map.Layer
local MapApi = Carbonite.Compat.MapApi

local Map = Module:New("Map", {
    defaults = {
        profile = {
            Map = {
                ShowQuests       = true,
                ShowGather       = true,
                ShowTrainers     = false,
                ShowNotes        = true,
                ShowGroup        = true,
                ShowPlayer       = true,
                MinimapBlobs     = false,
            },
        },
    },
})

local layers = {}

function Map:GetLayer(name)
    local l = layers[name]
    if not l then
        l = Layer.New(name)
        layers[name] = l
    end
    return l
end

function Map:RemoveLayer(name)
    if layers[name] then
        layers[name]:Clear()
        layers[name] = nil
    end
end

function Map:Layers()
    return layers
end

function Map:AddPin(layerName, kind, opts)
    local layer = self:GetLayer(layerName)
    local pin = Pin.Acquire(kind, opts)
    layer:Add(pin)
    return pin
end

function Map:GetPlayerMapID()
    return MapApi:GetPlayerMapID()
end

function Map:Open()
    local legacy = Carbonite.Map
    if legacy and legacy.Open then legacy:Open() end
    Carbonite.Core.EventBus:Fire("MAP_OPENED")
end

function Map:Close()
    local legacy = Carbonite.Map
    if legacy and legacy.Close then legacy:Close()
    elseif legacy and legacy.Win and legacy.Win.Hide then legacy.Win:Hide() end
    Carbonite.Core.EventBus:Fire("MAP_CLOSED")
end

function Map:Toggle()
    -- Defer to legacy code if available, otherwise toggle our open state.
    local legacy = Carbonite.Map
    if legacy and legacy.Toggle then legacy:Toggle()
    elseif legacy and legacy.Win then
        if legacy.Win:IsShown() then self:Close() else self:Open() end
    end
end

function Map:Refresh()
    for _, layer in pairs(layers) do layer.version = layer.version + 1 end
    Carbonite.Core.EventBus:Fire("MAP_REFRESH")
end

-- Path planning shortcuts. Callers should prefer these over reaching
-- into Carbonite.Modules.Map.Pathing directly.
function Map:PlanRoute(points, opts)
    return Carbonite.Modules.Map.Pathing:PlanRoute(points, opts)
end

function Map:BuildPath(tracking, src, dst)
    return Carbonite.Modules.Map.Pathing:BuildPath(tracking, src, dst)
end

function Map:OnEnable()
    -- Watch zone changes and broadcast through the EventBus so other
    -- modules can react without independent ZONE_CHANGED listeners.
    self:RegisterEvent("ZONE_CHANGED",            "OnZoneChange")
    self:RegisterEvent("ZONE_CHANGED_INDOORS",    "OnZoneChange")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA",   "OnZoneChange")

    Carbonite.Core.SlashCommands:Register("map", function(rest)
        rest = rest:lower()
        if rest == "show" then self:Open()
        elseif rest == "hide" then self:Close()
        else self:Toggle() end
    end, "show / hide / toggle the Carbonite map")
end

function Map:OnZoneChange()
    Carbonite.Core.EventBus:Fire("MAP_ZONE_CHANGED", MapApi:GetPlayerMapID())
end

-- Options page.
Carbonite.Core.EventBus:Subscribe("MODULE_ENABLED", function(name)
    if name ~= "Options" then return end
    local Options = Carbonite:GetModule("Options", true)
    if not Options then return end
    Options:Register("Map", function()
        local function db() return Map:DB().profile end
        return {
            type = "group",
            name = "Map",
            args = {
                quests = {
                    order = 1, type = "toggle", name = "Show quest pins",
                    get = function() return db().ShowQuests end,
                    set = function(_, v) db().ShowQuests = v; Map:Refresh() end,
                },
                gather = {
                    order = 2, type = "toggle", name = "Show gathering nodes",
                    get = function() return db().ShowGather end,
                    set = function(_, v) db().ShowGather = v; Map:Refresh() end,
                },
                trainers = {
                    order = 3, type = "toggle", name = "Show trainer pins",
                    get = function() return db().ShowTrainers end,
                    set = function(_, v) db().ShowTrainers = v; Map:Refresh() end,
                },
                notes = {
                    order = 4, type = "toggle", name = "Show waypoint notes",
                    get = function() return db().ShowNotes end,
                    set = function(_, v) db().ShowNotes = v; Map:Refresh() end,
                },
                group = {
                    order = 5, type = "toggle", name = "Show party/raid pins",
                    get = function() return db().ShowGroup end,
                    set = function(_, v) db().ShowGroup = v; Map:Refresh() end,
                },
                player = {
                    order = 6, type = "toggle", name = "Show player arrow",
                    get = function() return db().ShowPlayer end,
                    set = function(_, v) db().ShowPlayer = v; Map:Refresh() end,
                },
                blobs = {
                    order = 7, type = "toggle", name = "Quest blobs on minimap",
                    get = function() return db().MinimapBlobs end,
                    set = function(_, v) db().MinimapBlobs = v; Map:Refresh() end,
                },
            },
        }
    end, { displayName = "Map", order = 10 })
end)
