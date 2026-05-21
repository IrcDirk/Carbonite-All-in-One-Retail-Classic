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

function Map:GetLayer(name)
    return Layer.Get(name)
end

function Map:RemoveLayer(name)
    Layer.Remove(name)
end

function Map:Layers()
    return Layer.All()
end

function Map:AddPin(layerName, kind, opts)
    local layer = Layer.Get(layerName)
    local pin = Pin.Acquire(kind, opts)
    layer:Add(pin)
    return pin
end

-- Adds a line segment to the layer's pin list. The line connects
-- two world-space points with optional color/thickness. Lines are
-- drawn each frame by Renderer.lua's LINE drawMode path.
--   layerName  the layer to put the line into (usually mirrors kind)
--   kind       the Pin class (must have drawMode = "LINE")
--   opts       table { x, y, x2, y2, mapID, color, thickness, tex }
function Map:AddLine(layerName, kind, opts)
    local layer = Layer.Get(layerName)
    local pin = Pin.Acquire(kind)
    pin.x       = opts.x
    pin.y       = opts.y
    pin.x2      = opts.x2
    pin.y2      = opts.y2
    pin.mapID   = opts.mapID
    pin.color   = opts.color
    pin.thickness = opts.thickness
    pin.tex     = opts.tex
    pin.show    = true
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
    for _, layer in pairs(Layer.All()) do layer.version = layer.version + 1 end
    Carbonite.Core.EventBus:Fire("MAP_REFRESH")
end

-- Path planning shortcuts. Callers should prefer these over reaching
-- into Carbonite.Modules.Map.Pathing directly.
function Map:PlanRoute(points, opts)
    return Carbonite.Modules.Map.Pathing:PlanRoute(points, opts)
end

function Map:BuildPath(tracking, srcMapID, srcX, srcY, dstMapID, dstX, dstY, dstType)
    return Carbonite.Modules.Map.Pathing:BuildPath(tracking,
        srcMapID, srcX, srcY, dstMapID, dstX, dstY, dstType)
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
