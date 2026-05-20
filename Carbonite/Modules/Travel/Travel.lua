-- Carbonite | Modules / Travel
-- Module wrapper for the taxi / flight-path system. The actual path
-- graph and pathing math still live in NxTravel.lua; this file is
-- the new front door: it owns the saved-variable layout, the slash
-- command, and the option page registration.

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module

local Travel = Module:New("Travel", {
    defaults = {
        profile = {
            Travel = {
                AutoRebuild     = true,
                ShowFlightPaths = true,
                ShowGryphons    = false,
                IncludeHearths  = true,
                IncludeMages    = true,
            },
        },
    },
})

function Travel:Rebuild()
    local legacy = Carbonite.Travel
    if legacy and legacy.Build then legacy:Build() end
    Carbonite.Core.EventBus:Fire("TRAVEL_REBUILT")
end

function Travel:RouteTo(mapID, x, y)
    local legacy = Carbonite.Travel
    if legacy and legacy.RouteTo then return legacy:RouteTo(mapID, x, y) end
end

function Travel:OnEnable()
    Carbonite.Core.SlashCommands:Register("travel", function(rest)
        local args = {}
        for w in rest:gmatch("%S+") do args[#args + 1] = w end
        if args[1] == "rebuild" then
            self:Rebuild()
            self.log:info("travel graph rebuilt")
        else
            self.log:info("usage: /carb travel rebuild")
        end
    end, "travel graph commands")
end

Carbonite.Core.EventBus:Subscribe("MODULE_ENABLED", function(name)
    if name ~= "Options" then return end
    local Options = Carbonite:GetModule("Options", true)
    if not Options then return end
    Options:Register("Travel", function()
        local function db() return Travel:DB().profile end
        return {
            type = "group",
            name = "Travel",
            args = {
                auto = {
                    order = 1, type = "toggle", name = "Auto-rebuild graph", width = "full",
                    get = function() return db().AutoRebuild end,
                    set = function(_, v) db().AutoRebuild = v end,
                },
                flight = {
                    order = 2, type = "toggle", name = "Show flight paths",
                    get = function() return db().ShowFlightPaths end,
                    set = function(_, v) db().ShowFlightPaths = v end,
                },
                gryphons = {
                    order = 3, type = "toggle", name = "Show gryphon icons",
                    get = function() return db().ShowGryphons end,
                    set = function(_, v) db().ShowGryphons = v end,
                },
                hearths = {
                    order = 4, type = "toggle", name = "Include hearthstones in routing",
                    get = function() return db().IncludeHearths end,
                    set = function(_, v) db().IncludeHearths = v end,
                },
                mages = {
                    order = 5, type = "toggle", name = "Include mage portals in routing",
                    get = function() return db().IncludeMages end,
                    set = function(_, v) db().IncludeMages = v end,
                },
                rebuild = {
                    order = 10, type = "execute", name = "Rebuild graph now",
                    func = function() Travel:Rebuild() end,
                },
            },
        }
    end, { displayName = "Travel", order = 30 })
end)
