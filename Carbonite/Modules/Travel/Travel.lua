-- Carbonite | Modules / Travel
-- Module shell for the taxi / flight-path system. Owns the saved
-- variable layout, the /travel slash command, and the option page.
-- The engine (taxi capture, FindFlight, MakePath, GetRidingSkill,
-- etc.) lives in TravelEngine.lua and attaches to the same module
-- instance, re-anchoring Nx.Travel so legacy callsites keep working.

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

function Travel:OnEnable()
    Carbonite.Core.SlashCommands:Register("travel", function(rest)
        local args = {}
        for w in rest:gmatch("%S+") do args[#args + 1] = w end
        if args[1] == "add" and self.Add then
            -- Re-scan the flight-master guide data into self.Travel.
            self:Add(LibStub("AceLocale-3.0"):GetLocale("Carbonite")["Flight Master"])
            self.log:info("flight master locations reloaded")
        else
            self.log:info("usage: /carb travel add")
        end
    end, "travel commands")
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
                reload = {
                    order = 10, type = "execute", name = "Reload flight master data",
                    func = function()
                        if Travel.Add then
                            Travel:Add(LibStub("AceLocale-3.0"):GetLocale("Carbonite")["Flight Master"])
                        end
                    end,
                },
            },
        }
    end, { displayName = "Travel", order = 30 })
end)
