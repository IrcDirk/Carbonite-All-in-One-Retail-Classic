-------------------------------------------------------------------------------
-- NxOptions - Options Configuration
-- Copyright 2007-2012 Carbon Based Creations, LLC
-------------------------------------------------------------------------------
-- Carbonite - Addon for World of Warcraft(tm)
-- Copyright 2007-2012 Carbon Based Creations, LLC
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- LIBRARY IMPORTS
-- Ace3 configuration libraries for options panel
-------------------------------------------------------------------------------

local AceConfig         = LibStub("AceConfig-3.0")
local AceConfigReg      = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog   = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- Configuration tables for modular addon support
local modular_config = {}

-- Profiles configuration table (lazy initialized)
local profiles

-------------------------------------------------------------------------------
-- PROFILE CONFIGURATION
-- Manages AceDB profile options for Carbonite and modules
-------------------------------------------------------------------------------

---
-- Get or create the profiles configuration table
-- @return  Profiles options table for AceConfig
--
local function profilesConfig()
    if not profiles then
        profiles = {
            type = "group",
            name = L["Profiles"],
            childGroups = "tab",
            args = {
                main = {
                    type = "group",
                    name = L["Main"],
                    order = 1,
                    args = {},
                },
            },
        }
    end
    profiles.args.main.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(Nx.db)
    return profiles
end

---
-- Add a module's profile options to the profile menu
-- @param ProfileName   Display name for the profile tab
-- @param ProfileOrder  Order in the tab list
-- @param ProfileDB     AceDB database for the module
--
function Nx.Opts:AddToProfileMenu(ProfileName, ProfileOrder, ProfileDB)
    if not profiles then
        return
    end
    profiles.args[ProfileName] = {
        type = "group",
        name = ProfileName,
        order = ProfileOrder,
        args = {},
    }
    profiles.args[ProfileName].args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(ProfileDB)
end

-------------------------------------------------------------------------------
-- MAIN CONFIGURATION
-- Root configuration table with addon info and credits
-------------------------------------------------------------------------------

-- Main config table (lazy initialized)
local config

---
-- Get or create the main configuration table
-- Includes addon info, credits, and all sub-modules
-- @return  Main options table for AceConfig
--
local function mainConfig()
    if not config then
        config = {
            type = "group",
            name = "Carbonite Classic",
            args = {
                main = {
                    order = 1,
                    type = "group",
                    name = L["Main Options"],
                    args = {
                        -- Addon description and credits display
                        title = {
                            type = "description",
                            name = L["\nCarbonite is a full featured, powerful map addon providing a versitile easy to use google style map which either can replace or work with the current blizzard maps.\n\nThrough modules it can also be expanded to do even more to help make your game easier."] ..
                                "\n\n\n|cff9999ff" .. L["Release Version"] .. ": |cffd700ff" .. Nx.VERMAJOR .. "." .. (Nx.VERMINOR * 10) .. " Build " .. Nx.BUILD .. "\n" ..
                                "|cff9999ff" .. L["Maintained by"] .. ": |cffd700ffIrcDirk\n" ..
                                "|cff9999ff" .. L["Website"] .. ": |cffd700ffhttps://github.com/IrcDirk/Carbonite-Classic\n" ..
                                "\n" ..
                                "|cd700ffff" .. L["For support, please visit the forums for Carbonite on WoW Interface or Curse/Twitch."] .. "\n" ..
                                "|cd700ffff" .. L["Special thanks to"] .. ": \n\n" ..
                                "|cff9999ff" .. L["Rythal for hard work in all those years"] .. "\n" ..
                                "|cff9999ff" .. L["Cirax for Carbonite2 Logo"] .. "\n" ..
                                "|cff9999ff" .. L["ircdirk & atl77 for Quest Database updates"] .. "\n" ..
                                "|cff9999ff" .. L["nelegalno for many cleanups, api fixes"] .. "\n" ..
                                "|cff9999ff" .. L["Naharis for quest watchlist fixes"] .. "\n" ..
                                "|cff9999ff" .. L["JimJoBlue for guide location updates"] .. "\n" ..
                                "|cff9999ff" .. L["Localization Efforts By:"] .. "\n" ..
                                "|cff9999ff" .. L["frFR - powerstrk"] .. "\n" ..
                                "|cff9999ff" .. L["deDE - atl77 & samyonair"] .. "\n" ..
                                "|cff9999ff" .. L["itIT - ThorwaldOdin"] .. "\n" ..
                                "|cff9999ff" .. L["ruRU - NotDead"] .. "\n" ..
                                "|cff9999ff" .. L["zhCN - Raka-loah"] .. "\n" ..
                                "|cff9999ff" .. L["zhTW - kc305chen"] .. "\n",
                        },
                    },
                },
            },
        }
        -- Merge in modular addon configurations
        for k, v in pairs(modular_config) do
            config.args[k] = (type(v) == "function") and v() or v
        end
    end
    return config
end

-------------------------------------------------------------------------------
-- BATTLEGROUND OPTIONS
-------------------------------------------------------------------------------

local battlegrounds

---
-- Get or create battleground options configuration
-- @return  Battleground options table
--
local function BGConfig()
    if not battlegrounds then
        battlegrounds = {
            type = "group",
            name = L["Battlegrounds"],
            args = {
                bgstats = {
                    type = "toggle",
                    name = L["Show Battleground Stats"],
                    width = "full",
                    desc = L["Turns on or off displaying your battleground k/d and honor gained in chat during a match."],
                    get = function()
                        return Nx.db.profile.Battleground.ShowStats
                    end,
                    set = function()
                        Nx.db.profile.Battleground.ShowStats = not Nx.db.profile.Battleground.ShowStats
                    end,
                },
            },
        }
    end
    return battlegrounds
end

-------------------------------------------------------------------------------
-- GENERAL OPTIONS
-- Login behavior, chat settings, camera, UI appearance
-------------------------------------------------------------------------------

local general

---
-- Get or create general options configuration
-- @return  General options table
--
local function generalOptions()
    if not general then
        general = {
            type = "group",
            name = L["General Options"],
            args = {
                -- Login message toggle
                loginMsg = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L["Show Login Message"],
                    desc = L["When Enabled, displays the Carbonite loading messages in chat."],
                    get = function()
                        return Nx.db.profile.General.LoginHideVer
                    end,
                    set = function()
                        Nx.db.profile.General.LoginHideVer = not Nx.db.profile.General.LoginHideVer
                    end,
                },
                -- Login graphic toggle
                loginWin = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = L["Show Login Graphic"],
                    desc = L["When Enabled, displays the Carbonite graphic during initialization."] .. "\n",
                    get = function()
                        return Nx.db.profile.General.TitleOff
                    end,
                    set = function()
                        Nx.db.profile.General.TitleOff = not Nx.db.profile.General.TitleOff
                    end,
                },
                -- Login sound toggle
                loginSnd = {
                    order = 3,
                    type = "toggle",
                    width = "full",
                    name = L["Play Login Sound"],
                    desc = L["When Enabled, plays a sound when Carbonite is loaded."],
                    get = function()
                        return Nx.db.profile.General.TitleSoundOn
                    end,
                    set = function()
                        Nx.db.profile.General.TitleSoundOn = not Nx.db.profile.General.TitleSoundOn
                    end,
                },
                spacer1 = {
                    order = 4,
                    type = "description",
                    name = "\n",
                },
                -- Chat window selection
                chatWindow = {
                    order = 5,
                    type = "select",
                    name = L["Default Chat Channel"],
                    desc = L["Allows selection of which chat window to display Carbonite messages"],
                    get = function()
                        local vals = Nx.Opts:CalcChoices("Chat")
                        for a, b in pairs(vals) do
                            if (b == Nx.db.profile.General.ChatMsgFrm) then
                                return a
                            end
                        end
                        return ""
                    end,
                    set = function(info, name)
                        local vals = Nx.Opts:CalcChoices("Chat")
                        Nx.db.profile.General.ChatMsgFrm = vals[name]
                        Nx.Opts:NXCmdUIChange()
                    end,
                    values = function()
                        return Nx.Opts:CalcChoices("Chat")
                    end,
                },
                spacer2 = {
                    order = 6,
                    type = "description",
                    name = "\n",
                },
                -- Camera distance override
                maxCamera = {
                    order = 7,
                    type = "toggle",
                    width = "full",
                    name = L["Force Max Camera Distance"] .. "\n",
                    desc = L["When enabled, sets the max camera distance higher then Blizzards options normally allows."],
                    get = function()
                        return Nx.db.profile.General.CameraForceMaxDist
                    end,
                    set = function()
                        Nx.db.profile.General.CameraForceMaxDist = not Nx.db.profile.General.CameraForceMaxDist
                        Nx.Opts:NXCmdCamForceMaxDist()
                    end,
                },
                -- Gryphon graphics toggle
                hideGriff = {
                    order = 8,
                    type = "toggle",
                    width = "full",
                    name = L["Hide Action Bar Gryphon Graphics"],
                    desc = L["Attempts to hide the two gryphons on your action bar."],
                    get = function()
                        return Nx.db.profile.General.GryphonsHide
                    end,
                    set = function()
                        Nx.db.profile.General.GryphonsHide = not Nx.db.profile.General.GryphonsHide
                        Nx.Opts:NXCmdGryphonsUpdate()
                    end,
                },
            },
        }
    end
    return general
end

-------------------------------------------------------------------------------
-- MAP OPTIONS
-- Main map display, behavior, tooltips, icons, mouse bindings
-------------------------------------------------------------------------------

local map

---
-- Get or create map options configuration
-- Contains tabs for: Main Map, Minimap, Button Frame, Icons
-- @return  Map options table
--
local function mapConfig()
    if not map then
        map = {
            type = "group",
            name = L["Map Options"],
            childGroups = "tab",
            args = {
                -- Main map options tab
                mainMap = {
                    order = 1,
                    type = "group",
                    name = L["Map Options"],
                    args = {
                        -- Use Carbonite instead of Blizzard map
                        maxMap = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Use Carbonite Map instead of Blizzards (Alt-M will open world map)"] .. "\n",
                            desc = L["When enabled, pressing 'M' will maximize the carbonite map instead of opening the world map."],
                            get = function()
                                return Nx.db.profile.Map.MaxOverride
                            end,
                            set = function()
                                Nx.db.profile.Map.MaxOverride = not Nx.db.profile.Map.MaxOverride
                            end,
                        },
                        -- Combat compatibility mode
                        Compatibility = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            name = L["Enable Combat Compatibility Mode"],
                            desc = L["When Enabled, Carbonite will performe combat checks before any map/window functions. This eliminates other UI's from causing protected mode errors."],
                            get = function()
                                return Nx.db.profile.Map.Compatibility
                            end,
                            set = function()
                                Nx.db.profile.Map.Compatibility = not Nx.db.profile.Map.Compatibility
                            end,
                        },
                        -- Hide map in combat
                        hidecombat = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Hide Map In Combat"],
                            desc = L["If large map is open when you enter combat attempts to hide it."],
                            get = function()
                                return Nx.db.profile.Map.HideCombat
                            end,
                            set = function()
                                Nx.db.profile.Map.HideCombat = not Nx.db.profile.Map.HideCombat
                            end,
                        },
                        centerMap = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Center map when maximizing"] .. "\n",
                            desc = L["When enabled, the map will center on your current zone when you maximize it"],
                            get = function()
                                return Nx.db.profile.Map.MaxCenter
                            end,
                            set = function()
                                Nx.db.profile.Map.MaxCenter = not Nx.db.profile.Map.MaxCenter
                            end,
                        },
                        mouseIgnore = {
                            order = 5,
                            type = "toggle",
                            width = "full",
                            name = L["Ignore mouse on map except when ALT is pressed"] .. "\n",
                            desc = L["When enabled, the small game map will ignore all mouse clicks unless the ALT key is held down."],
                            get = function()
                                return Nx.db.profile.Map.MouseIgnore
                            end,
                            set = function()
                                Nx.db.profile.Map.MouseIgnore = not Nx.db.profile.Map.MouseIgnore
                            end,
                        },
                        maxMouseIgnore = {
                            order = 6,
                            type = "toggle",
                            width = "full",
                            name = L["Ignore mouse on full-sized map except when ALT is pressed"] .. "\n",
                            desc = L["When enabled, the full size map will ignore all mouse clicks unless the ALT key is held down."],
                            get = function()
                                return Nx.db.profile.Map.MaxMouseIgnore
                            end,
                            set = function()
                                Nx.db.profile.Map.MaxMouseIgnore = not Nx.db.profile.Map.MaxMouseIgnore
                            end,
                        },
--[[                        Doesn't work for now.

                            ownMap = {
                            order = 7,
                            type = "toggle",
                            width = "full",
                            name = L["Move Worldmap Data into Maximized Map"] .. "\n",
                            desc = L["When enabled, Carbonite will attempt to move anything drawn on your world map onto the Maximized Map."],
                            get = function()
                                return Nx.db.profile.Map.WOwn
                            end,
                            set = function()
                                Nx.db.profile.Map.WOwn = not Nx.db.profile.Map.WOwn
                            end,
                        },
]]--
                        restoreMap = {
                            order = 7,
                            type = "toggle",
                            width = "full",
                            name = L["Close Map instead of minimize"] .. "\n",
                            desc = L["When enabled, pressing either 'M' or ESC will close the maximized map instead of switching back to small map."],
                            get = function()
                                return Nx.db.profile.Map.MaxRestoreHide
                            end,
                            set = function()
                                Nx.db.profile.Map.MaxRestoreHide = not Nx.db.profile.Map.MaxRestoreHide
                            end,
                        },
                        mapUpdate = {
                            order = 7,
                            type = "range",
                            name = L["Map update rate"],
                            desc = L["sets map update refresh rate"],
                            min = 0,
                            max = .25,
                            step = .01,
                            bigStep = .01,
                            get = function()
                                return Nx.db.profile.Map.mapUpdate
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.mapUpdate = value
                            end,
                        },
                        spacer1 = {
                            order = 8,
                            type = "description",
                            name = "\n",
                        },
                        showPals = {
                            order = 9,
                            type = "toggle",
                            name = L["Show Friends/Guildmates in Cities"],
                            width = "full",
                            desc = L["When enabled, will attempt to draw a marker on the map for friends & guildmates positions."],
                            get = function()
                                return Nx.db.profile.Map.ShowPalsInCities
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowPalsInCities = not Nx.db.profile.Map.ShowPalsInCities
                            end,
                        },
                        showOthers = {
                            order = 10,
                            type = "toggle",
                            width = "full",
                            name = L["Show Other people in Cities"],
                            desc = L["When enabled, will attempt to draw a marker on the map for other Carbonite users."],
                            get = function()
                                return Nx.db.profile.Map.ShowOthersInCities
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowOthersInCities = not Nx.db.profile.Map.ShowOthersInCities
                            end,
                        },
                        showOthersZ = {
                            order = 11,
                            type = "toggle",
                            width = "full",
                            name = L["Show Other people In Zone"],
                            desc = L["When enabled, will attempt to draw a marker on the map for other Carbonite users."],
                            get = function()
                                return Nx.db.profile.Map.ShowOthersInZone
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowOthersInZone = not Nx.db.profile.Map.ShowOthersInZone
                            end,
                        },
                        spacer2 = {
                            order = 12,
                            type = "description",
                            name = "\n",
                        },
                        restoreScale = {
                            order = 13,
                            type = "toggle",
                            name = L["Restore map scale after track"],
                            width = "full",
                            desc = L["When enabled, restores your previous map scale when tracking is cleared."],
                            get = function()
                                return Nx.db.profile.Map.RestoreScaleAfterTrack
                            end,
                            set = function()
                                Nx.db.profile.Map.RestoreScaleAfterTrack = not Nx.db.profile.Map.RestoreScaleAfterTrack
                            end,
                        },
                        useRoute = {
                            order = 14,
                            type = "toggle",
                            name = L["Use Travel Routing"],
                            width = "full",
                            desc = L["When enabled, attempts to route your travel when destination is in another zone."],
                            get = function()
                                return Nx.db.profile.Map.RouteUse
                            end,
                            set = function()
                                Nx.db.profile.Map.RouteUse = not Nx.db.profile.Map.RouteUse
                            end,
                        },
                        spacer3 = {
                            order = 15,
                            type = "description",
                            name = "\n",
                        },
                        showTrail = {
                            order = 16,
                            type = "toggle",
                            name = L["Show Movement Trail"],
                            width = "full",
                            desc = L["When enabled, draws a trail on the map to show your movements."],
                            get = function()
                                return Nx.db.profile.Map.ShowTrail
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowTrail = not Nx.db.profile.Map.ShowTrail
                            end,
                        },
                        trailDist = {
                            order = 17,
                            type = "range",
                            name = L["Movement trail distance"],
                            desc = L["sets the distance of movement between the trail marks"],
                            min = .1,
                            max = 20,
                            step = .1,
                            bigStep = .1,
                            get = function()
                                return Nx.db.profile.Map.TrailDist
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.TrailDist = value
                            end,
                        },
                        trailCnt = {
                            order = 18,
                            type = "range",
                            name = L["Movement dot count"],
                            desc = L["sets the number of movement dots to draw on the map"],
                            min = 0,
                            max = 1000,
                            step = 10,
                            bigStep = 10,
                            get = function()
                                return Nx.db.profile.Map.TrailCnt
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.TrailCnt = value
                            end,
                        },
                        trailTime = {
                            order = 19,
                            type = "range",
                            name = L["Movement trail fade time"],
                            desc = L["sets the time trail marks last on the map (in seconds)"],
                            min = 0,
                            max = 1000,
                            step = 10,
                            bigStep = 10,
                            get = function()
                                return Nx.db.profile.Map.TrailTime
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.TrailTime = value
                            end,
                        },
                        spacer4 = {
                            order = 20,
                            type = "description",
                            name = "\n",
                        },
                        showToolBar = {
                            order = 21,
                            type = "toggle",
                            name = L["Show Map Toolbar"],
                            width = "full",
                            desc = L["When enabled, shows the quickbutton toolbar on the map."],
                            get = function()
                                return Nx.db.profile.Map.ShowToolBar
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowToolBar = not Nx.db.profile.Map.ShowToolBar
                                Nx.Opts:NXCmdMapToolBarUpdate()
                            end,
                        },
                        TooltipAnchor = {
                            order = 22,
                            type    = "select",
                            name    = "  " .. L["Map Tooltip Anchor"],
                            desc    = L["Sets the anchor point for tooltips on the map"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("Anchor0")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.LocTipAnchor) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("Anchor0")
                                Nx.db.profile.Map.LocTipAnchor = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("Anchor0")
                            end,
                        },
                        TooltipAnchorRel = {
                            order = 23,
                            type    = "select",
                            name    = "  " .. L["Map Tooltip Anchor To Map"],
                            desc    = L["Sets the secondary anchor point for tooltips on the map"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("Anchor0")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.LocTipAnchorRel) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("Anchor0")
                                Nx.db.profile.Map.LocTipAnchorRel = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("Anchor0")
                            end,
                        },
                        TopToolTip = {
                            order = 24,
                            type = "toggle",
                            name = L["Show All Tooltips Above Map"],
                            width = "full",
                            desc = L["When enabled, makes sure the map tooltips are always on the top layer."],
                            get = function()
                                return Nx.db.profile.Map.TopTooltip
                            end,
                            set = function()
                                Nx.db.profile.Map.TopTooltip = not Nx.db.profile.Map.TopTooltip
                            end,
                        },
                        showTitleName = {
                            order = 25,
                            type = "toggle",
                            name = L["Show Map Name"],
                            desc = L["When enabled, shows current map zone name in the titlebar."],
                            get = function()
                                return Nx.db.profile.Map.ShowTitleName
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowTitleName = not Nx.db.profile.Map.ShowTitleName
                            end,
                        },
                        showTitleXY = {
                            order = 26,
                            type = "toggle",
                            name = L["Show Coordinates"],
                            desc = L["When enabled, Shows your current coordinates in the titlebar."],
                            get = function()
                                return Nx.db.profile.Map.ShowTitleXY
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowTitleXY = not Nx.db.profile.Map.ShowTitleXY
                            end,
                        },
                        showTitleSpeed = {
                            order = 27,
                            type = "toggle",
                            name = L["Show Speed"],
                            desc = L["When enabled, Shows your current movement speed in the titlebar."],
                            get = function()
                                return Nx.db.profile.Map.ShowTitleSpeed
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowTitleSpeed = not Nx.db.profile.Map.ShowTitleSpeed
                            end,
                        },
                        showTitle2 = {
                            order = 28,
                            type = "toggle",
                            name = L["Show Second Title Line"],
                            width = "full",
                            desc = L["When enabled, Shows a second line of info in the titlebar with PVP & subzone info. (REQUIRES RELOAD)"],
                            get = function()
                                return Nx.db.profile.Map.ShowTitle2
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowTitle2 = not Nx.db.profile.Map.ShowTitle2
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        spacer5 = {
                            order = 29,
                            type = "description",
                            name = "\n",
                        },
                        showPOI = {
                            order = 30,
                            type = "toggle",
                            name = L["Show Map POI"],
                            width = "full",
                            desc = L["When enabled, shows Points of Interest on the map."],
                            get = function()
                                return Nx.db.profile.Map.ShowPOI
                            end,
                            set = function()
                                Nx.db.profile.Map.ShowPOI = not Nx.db.profile.Map.ShowPOI
                            end,
                        },
                        spacer6 = {
                            order = 31,
                            type = "description",
                            name = "\n",
                        },
                        plyrArrowSize = {
                            order = 32,
                            type = "range",
                            name = L["Player Arrow Size"],
                            width = "double",
                            desc = L["Sets the size of the player arrow on the map"],
                            min = 10,
                            max = 100,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.Map.PlyrArrowSize
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.PlyrArrowSize = value
                            end,
                        },
                        iconScaleMin = {
                            order = 33,
                            type = "range",
                            width = "double",
                            name = L["Icon Scale Min"],
                            desc = L["Sets the smallest size for icons on the map while zooming (-1 disabled any size changes)"],
                            min = -1,
                            max = 50,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.Map.IconScaleMin
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.IconScaleMin = value
                            end,
                        },
                        mapLineThick = {
                            order = 34,
                            type = "range",
                            width = "double",
                            name = L["Map Health Bar Thickness"],
                            desc = L["Sets the thickness of the health bar (0 disables)"],
                            min = 0,
                            max = 10,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.Map.LineThick
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.LineThick = value
                            end,
                        },
                        zoneDrawCnt = {
                            order = 35,
                            type = "range",
                            width = "double",
                            name = L["Maximum Zones To Draw At Once"],
                            desc = L["Sets the number of zones you can display at once on the map"],
                            min = 1,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.Map.ZoneDrawCnt
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.ZoneDrawCnt = value
                            end,
                        },
                        detailSize = {
                            order = 36,
                            type = "range",
                            name = L["Detail Graphics Visible Area"],
                            width = "double",
                            desc = L["Sets the area size available when zoomed into satellite mode on the map (REQUIRES RELOAD)"],
                            min = 2,
                            max = 40,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.Map.DetailSize
                            end,
                            set = function(info,value)
                                Nx.db.profile.Map.DetailSize = value
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        spacer7 = {
                            order = 37,
                            type = "description",
                            name = "\n",
                        },
                        header = {
                            order = 38,
                            type = "header",
                            name = L["Map Mouse Button Binds"],
                        },
                        ButLAlt = {
                            order = 39,
                            type = "select",
                            name = "           " .. L["Alt Left Click"],
                            desc = L["Sets the action performed when left clicking holding ALT"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButLAlt) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButLAlt = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButLCtrl = {
                            order = 40,
                            type    = "select",
                            name    = "           " .. L["Ctrl Left Click"],
                            desc    = L["Sets the action performed when left clicking holding CTRL"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButLCtrl) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButLCtrl = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButM = {
                            order = 41,
                            type    = "select",
                            name    = "           " .. L["Middle Click"],
                            desc    = L["Sets the action performed when clicking your middle mouse button"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButM) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButM = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButMAlt = {
                            order = 42,
                            type    = "select",
                            name    = "           " .. L["Alt Middle Click"],
                            desc    = L["Sets the action performed when middle clicking holding ALT"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButMAlt) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButMAlt = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButMCtrl = {
                            order = 43,
                            type    = "select",
                            name    = "           " .. L["Ctrl Middle Click"],
                            desc    = L["Sets the action performed when middle clicking holding CTRL"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButMCtrl) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButMCtrl = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButR = {
                            order = 44,
                            type    = "select",
                            name    = "           " .. L["Right Click"],
                            desc    = L["Sets the action performed when right clicking the map"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButR) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButR = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButRAlt = {
                            order = 45,
                            type    = "select",
                            name    = "           " .. L["Alt Right Click"],
                            desc    = L["Sets the action performed when Right clicking holding ALT"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButRAlt) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButRAlt = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        ButRCtrl = {
                            order = 46,
                            type    = "select",
                            name    = "           " .. L["Ctrl Right Click"],
                            desc    = L["Sets the action performed when right clicking holding CTRL"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.ButRCtrl) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.ButRCtrl = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        But4 = {
                            order = 47,
                            type    = "select",
                            name    = "           " .. L["Button 4 Click"],
                            desc    = L["Sets the action performed when clicking mouse button 4"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.But4) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.But4 = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        But4Alt = {
                            order = 48,
                            type    = "select",
                            name    = "           " .. L["Alt Button 4 Click"],
                            desc    = L["Sets the action performed when pressing mouse 4 while holding ALT"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.But4Alt) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.But4Alt = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                        But4Ctrl = {
                            order = 49,
                            type    = "select",
                            name    = "           " .. L["Ctrl Button 4 Click"],
                            desc    = L["Sets the action performed when clicking 4th mouse button holding CTRL"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.Map.But4Ctrl) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("MapFunc")
                                Nx.db.profile.Map.But4Ctrl = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("MapFunc")
                            end,
                        },
                    },
                },
                miniMap = {
                    order = 2,
                    type = "group",
                    name = L["MiniMap Options"],
                    args = {
                        MMOwn = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Combine Blizzard Minimap with Carbonite Minimap"],
                            desc = L["When enabled, Carbonite will combine the minimap into itself to create a more functional minimap for you (RELOAD REQUIRED)"],
                            get = function()
                                return Nx.db.profile.MiniMap.Own
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.Own = not Nx.db.profile.MiniMap.Own
                                Nx.Opts:NXCmdMMOwnChange(_,Nx.db.profile.MiniMap.Own)
                            end,
                        },
                        spacer1 = {
                            order = 2,
                            type = "description",
                            name = "\n",
                        },
                        --[[MMSquare = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap Shape is Square"],
                            desc = L["When enabled, Carbonite will change the minimap shape from circle to square"],
                            get = function()
                                return Nx.db.profile.MiniMap.Square
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.Square = not Nx.db.profile.MiniMap.Square
                            end,
                        },]]--
                        MMAboveIcons = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap is drawn above icons"],
                            desc = L["When enabled, Carbonite will draw the minimap above your map icons, you can use the CTRL key on your keyboard to toggle which layer is top"],
                            get = function()
                                return Nx.db.profile.MiniMap.AboveIcons
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.AboveIcons = not Nx.db.profile.MiniMap.AboveIcons
                            end,
                        },
                        MMIconScale = {
                            order = 5,
                            type = "range",
                            name = L["Minimap Icon Scale"],
                            desc = L["Sets the scale of the icons drawn in the minimap portion of the map"],
                            min = .1,
                            max = 10,
                            step = .1,
                            bigStep = .1,
                            get = function()
                                return Nx.db.profile.MiniMap.IScale
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.IScale = value
                            end,
                        },
                        MMDockIScale = {
                            order = 6,
                            type = "range",
                            name = L["Docked Minimap Icon Scale"],
                            desc = L["Sets the scale of the icons drawn in the minimap portion of the map while docked"],
                            min = .1,
                            max = 10,
                            step = .1,
                            bigStep = .1,
                            get = function()
                                return Nx.db.profile.MiniMap.DockIScale
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.DockIScale = value
                            end,
                        },

                        MMGlow = {
                            order = 7,
                            type = "range",
                            name = L["Minimap Node Glow Delay"],
                            desc = L["Sets the delay (in seconds) between the glow change on gathering nodes (0 is off)"],
                            min = 0,
                            max = 4,
                            step = .1,
                            bigStep = .1,
                            get = function()
                                return Nx.db.profile.MiniMap.NodeGD
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.NodeGD = value
                                Nx.Opts:NXCmdMMChange()
                            end,
                        },
                        spacer2 = {
                            order = 8,
                            type = "description",
                            name = "\n",
                        },
                        MMDockAlways = {
                            order = 9,
                            type = "toggle",
                            width = "full",
                            name = L["Always dock minimap"],
                            desc = L["When enabled, The minimap will always dock into the corner of the carbonite map."],
                            get = function()
                                return Nx.db.profile.MiniMap.DockAlways
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockAlways = not Nx.db.profile.MiniMap.DockAlways
                            end,
                        },
                        MMDockIndoors = {
                            order = 10,
                            type = "toggle",
                            width = "full",
                            name = L["Dock The Minimap when indoors"],
                            desc = L["When enabled, The minimap will dock if wow says your indoors"],
                            get = function()
                                return Nx.db.profile.MiniMap.DockIndoors
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockIndoors = not Nx.db.profile.MiniMap.DockIndoors
                            end,
                        },
                        MMDockBugged = {
                            order = 11,
                            type = "toggle",
                            width = "full",
                            name = L["Dock The Minimap in Bugged Zones"],
                            desc = L["When enabled, The minimap will dock if your in a known transparency bug zone (Pitch black minimap)"],
                            get = function()
                                return Nx.db.profile.MiniMap.DockBugged
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockBugged = not Nx.db.profile.MiniMap.DockBugged
                            end,
                        },
                        MMDockOnMax = {
                            order = 12,
                            type = "toggle",
                            width = "full",
                            name = L["Dock The Minimap when Fullsized"],
                            desc = L["When enabled, The minimap will dock if your viewing the fullsized map."],
                            get = function()
                                return Nx.db.profile.MiniMap.DockOnMax
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockOnMax = not Nx.db.profile.MiniMap.DockOnMax
                            end,
                        },
                        MMHideOnMax = {
                            order = 13,
                            type = "toggle",
                            width = "full",
                            name = L["Hide The Minimap when Fullsized"],
                            desc = L["When enabled, The minimap will hide if your viewing the fullsized map."],
                            get = function()
                                return Nx.db.profile.MiniMap.HideOnMax
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.HideOnMax = not Nx.db.profile.MiniMap.HideOnMax
                            end,
                        },

                        MMDockSquare = {
                            order = 14,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap Docked Shape is Square"],
                            desc = L["When enabled, The minimap will be square shaped while docked."],
                            get = function()
                                return Nx.db.profile.MiniMap.DockSquare
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockSquare = not Nx.db.profile.MiniMap.DockSquare
                            end,
                        },
                        MMDockBottom = {
                            order = 15,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap Docks Bottom"],
                            desc = L["When enabled, The minimap will dock to the bottom of the map."],
                            get = function()
                                return Nx.db.profile.MiniMap.DockBottom
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockBottom = not Nx.db.profile.MiniMap.DockBottom
                            end,
                        },
                        MMDockRight = {
                            order = 16,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap Docks Right"],
                            desc = L["When enabled, The minimap will dock to the right side of the map."],
                            get = function()
                                return Nx.db.profile.MiniMap.DockRight
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.DockRight = not Nx.db.profile.MiniMap.DockRight
                            end,
                        },
                        MMDXO = {
                            order = 17,
                            type = "range",
                            name = L["Minimap Dock X-Offset"],
                            desc = L["Sets the X - offset the minimap draws while docked"],
                            min = -2000,
                            max = 2000,
                            step = 1,
                            bigStep = 25,
                            get = function()
                                return Nx.db.profile.MiniMap.DXO
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.DXO = value
                            end,
                        },
                        MMDYO = {
                            order = 18,
                            type = "range",
                            name = L["Minimap Dock Y-Offset"],
                            desc = L["Sets the Y - offset the minimap draws while docked"],
                            min = -2000,
                            max = 2000,
                            step = 1,
                            bigStep = 25,
                            get = function()
                                return Nx.db.profile.MiniMap.DYO
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.DYO = value
                            end,
                        },
                        MMIndoorTogFullSize = {
                            order = 19,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap goes full sized Indoors"],
                            desc = L["When enabled, The minimap will expand to full map window size when indoors."],
                            get = function()
                                return Nx.db.profile.MiniMap.IndoorTogFullSize
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.IndoorTogFullSize = not Nx.db.profile.MiniMap.IndoorTogFullSize
                            end,
                        },
                        MMDockBuggedTogFullSize = {
                            order = 20,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap goes full sized in bugged areas"],
                            desc = L["When enabled, The minimap will expand to full map window size in known transparency bugged areas."],
                            get = function()
                                return Nx.db.profile.MiniMap.BuggedTogFullSize
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.BuggedTogFullSize = not Nx.db.profile.MiniMap.BuggedTogFullSize
                            end,
                        },
                        MMDockInstanceTogFullSize = {
                            order = 21,
                            type = "toggle",
                            width = "full",
                            name = L["Minimap goes full sized in instances"],
                            desc = L["When enabled, The minimap expand to full map window size when you enter a raid/instance."],
                            get = function()
                                return Nx.db.profile.MiniMap.InstanceTogFullSize
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.InstanceTogFullSize = not Nx.db.profile.MiniMap.InstanceTogFullSize
                            end,
                        },
                        MMMoveCapBars = {
                            order = 22,
                            type = "toggle",
                            width = "full",
                            name = L["Move capture bars under map"],
                            desc = L["When enabled, Objective capture bars will be drawn under the map."],
                            get = function()
                                return Nx.db.profile.MiniMap.MoveCapBars
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.MoveCapBars = not Nx.db.profile.MiniMap.MoveCapBars
                            end,
                        },
                        MMShowOldNameplate = {
                            order = 23,
                            type = "toggle",
                            width = "full",
                            name = L["Show Old Nameplates"],
                            desc = L["When enabled, The minimap will display the old nameplates above the map."],
                            get = function()
                                return Nx.db.profile.MiniMap.ShowOldNameplate
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ShowOldNameplate = not Nx.db.profile.MiniMap.ShowOldNameplate
                                Nx.Opts:NXCmdMMButUpdate()
                            end,
                        },
                    },
                },
                buttonFrame = {
                    order = 3,
                    type = "group",
                    name = L["Minimap Button Options"],
                    args = {
                        MMButOwn = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Move Minimap Buttons into Carbonite Minimap Frame"],
                            desc = L["When enabled, Carbonite will pull all minimap icons into it's own button frame which can be moved around and minimized as needed (RELOAD REQUIRED)"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButOwn
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButOwn = not Nx.db.profile.MiniMap.ButOwn
                                Nx.Opts:NXCmdReload()
                            end,
                        },
                        spacer1 = {
                            order = 2,
                            type = "description",
                            name = "\n",
                        },
                        MMButHide = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Hide Minimap Button Window"],
                            desc = L["Hides the button frame holding minimap icons"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButHide
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButHide = not Nx.db.profile.MiniMap.ButHide
                                Nx.Window:SetAttribute("NxMapDock","H",Nx.db.profile.MiniMap.ButHide)
                            end,
                        },
                        MMButLock = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Lock Minimap Button Window"],
                            desc = L["Locks the button frame holding minimap icons"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButLock
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButLock = not Nx.db.profile.MiniMap.ButLock
                                Nx.Window:SetAttribute("NxMapDock","L",Nx.db.profile.MiniMap.ButLock)
                            end,
                        },
                        spacer2 = {
                            order = 5,
                            type = "description",
                            name = "\n",
                        },
                        MMButColumns = {
                            order = 6,
                            type = "range",
                            name = L["# Of Minimap Button Columns"],
                            width = "double",
                            desc = L["Sets the number of columns to be used for minimap icons"],
                            min = 1,
                            max = 10,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.MiniMap.ButColumns
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.ButColumns = value
                            end,
                        },
                        MMButSpacing = {
                            order = 7,
                            type = "range",
                            name = L["Minimap Button Spacing"],
                            width = "double",
                            desc = L["Sets the spacing between buttons in the minimap button bar"],
                            min = 25,
                            max = 90,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.MiniMap.ButSpacing
                            end,
                            set = function(info,value)
                                Nx.db.profile.MiniMap.ButSpacing = value
                            end,
                        },
                        ButCorner = {
                            order = 8,
                            type    = "select",
                            name    = L["Corner For First Button"],
                            desc    = L["Sets the anchor point in multi-column setups for first minimap button"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("Corner")
                                for a,b in pairs(vals) do
                                  if (b == Nx.db.profile.MiniMap.ButCorner) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("Corner")
                                Nx.db.profile.MiniMap.ButCorner = vals[name]
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("Corner")
                            end,
                        },
                        spacer3 = {
                            order = 9,
                            type = "description",
                            name = "\n",
                        },
                        MMButShowCarb = {
                            order = 10,
                            type = "toggle",
                            width = "full",
                            name = L["Enable Carbonite Minimap Button"],
                            desc = L["Shows the carbonite minimap button in the button panel"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButShowCarb
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButShowCarb = not Nx.db.profile.MiniMap.ButShowCarb
                                Nx.Opts:NXCmdMMButUpdate()
                            end,
                        },
                        MMButShowCalendar = {
                            order = 11,
                            type = "toggle",
                            width = "full",
                            name = L["Enable Calendar Minimap Button"],
                            desc = L["Shows the calendar minimap button in the button panel"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButShowCalendar
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButShowCalendar = not Nx.db.profile.MiniMap.ButShowCalendar
                                Nx.Opts:NXCmdMMButUpdate()
                            end,
                        },
                        MMButShowClock = {
                            order = 12,
                            type = "toggle",
                            width = "full",
                            name = L["Enable Clock Minimap Button"],
                            desc = L["Shows the clock minimap button in the button panel"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButShowClock
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButShowClock = not Nx.db.profile.MiniMap.ButShowClock
                                Nx.Opts:NXCmdMMButUpdate()
                            end,
                        },
                        MMButShowWorldMap = {
                            order = 13,
                            type = "toggle",
                            width = "full",
                            name = L["Enable World Map Minimap Button"],
                            desc = L["Shows the world map minimap button in the button panel"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButShowWorldMap
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButShowWorldMap = not Nx.db.profile.MiniMap.ButShowWorldMap
                                Nx.Opts:NXCmdMMButUpdate()
                            end,
                        },
                        MMButShowLFG = {
                            order = 14,
                            type = "toggle",
                            width = "full",
                            name = L["Enable Dungeon Finder Minimap Button"],
                            desc = L["Shows the dungeon finder minimap button in the button panel"],
                            get = function()
                                return Nx.db.profile.MiniMap.ButShowLFG
                            end,
                            set = function()
                                Nx.db.profile.MiniMap.ButShowLFG = not Nx.db.profile.MiniMap.ButShowLFG
                                Nx.Opts:NXCmdMMButUpdate()
                            end,
                        },
                    },
                },
            },
        }
    end
    return map
end

-------------------------------------------------------------------------------
-- FONT OPTIONS
-- Font face, size, and spacing settings for UI text
-------------------------------------------------------------------------------

local font

---
-- Get or create font options configuration
-- @return  Font options table
--
local function fontConfig()
    if not font then
        font = {
            type = "group",
            name = L["Font Options"],
            args = {
                SmallFont = {
                    order = 1,
                    type = "select",
                    name = L["Small Font"],
                    desc = L["Sets the font to be used for small text"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Font.Small) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        Nx.db.profile.Font.Small = vals[name]
                        Nx.Opts:NXCmdFontChange()
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("FontFace","Get")
                    end,
                },
                SmallFontSize = {
                    order = 2,
                    type = "range",
                    name = L["Small Font Size"],
                    desc = L["Sets the size of the small font"],
                    min = 6,
                    max = 14,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.SmallSize
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.SmallSize = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                SmallFontSpacing = {
                    order = 3,
                    type = "range",
                    name = L["Small Font Spacing"],
                    desc = L["Sets the spacing of the small font"],
                    min = -10,
                    max = 20,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.SmallSpacing
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.SmallSpacing = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                MediumFont = {
                    order = 4,
                    type = "select",
                    name = L["Normal Font"],
                    desc = L["Sets the font to be used for normal text"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Font.Medium) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        Nx.db.profile.Font.Medium = vals[name]
                        Nx.Opts:NXCmdFontChange()
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("FontFace","Get")
                    end,
                },
                MediumFontSize = {
                    order = 5,
                    type = "range",
                    name = L["Medium Font Size"],
                    desc = L["Sets the size of the normal font"],
                    min = 6,
                    max = 20,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MediumSize
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MediumSize = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                MediumFontSpacing = {
                    order = 6,
                    type = "range",
                    name = L["Medium Font Spacing"],
                    desc = L["Sets the spacing of the normal font"],
                    min = -10,
                    max = 20,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MediumSpacing
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MediumSpacing = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                MapFont = {
                    order = 7,
                    type = "select",
                    name = L["Map Font"],
                    desc = L["Sets the font to be used on the map"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Font.Map) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        Nx.db.profile.Font.Map = vals[name]
                        Nx.Opts:NXCmdFontChange()
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("FontFace","Get")
                    end,
                },
                MapFontSize = {
                    order = 8,
                    type = "range",
                    name = L["Map Font Size"],
                    desc = L["Sets the size of the map font"],
                    min = 6,
                    max = 14,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MapSize
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MapSize = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                MapFontSpacing = {
                    order = 9,
                    type = "range",
                    name = L["Map Font Spacing"],
                    desc = L["Sets the spacing of the map font"],
                    min = -10,
                    max = 20,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MapSpacing
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MapSpacing = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                spacer = {
                    order = 10,
                    type = "description",
                    name = "",
                },
                MapLocFont = {
                    order = 11,
                    type = "select",
                    name = L["Map Location Tip Font"],
                    desc = L["Sets the font to be used on the map tooltip"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Font.MapLoc) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        Nx.db.profile.Font.MapLoc = vals[name]
                        Nx.Opts:NXCmdFontChange()
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("FontFace","Get")
                    end,
                },
                MapLocFontSize = {
                    order = 12,
                    type = "range",
                    name = L["Map Location Tip Font Size"],
                    desc = L["Sets the size of the map tooltip font"],
                    min = 6,
                    max = 14,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MapLocSize
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MapLocSize = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                MapLocFontSpacing = {
                    order = 13,
                    type = "range",
                    name = L["Map Loc Font Spacing"],
                    desc = L["Sets the spacing of the map loc font"],
                    min = -10,
                    max = 20,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MapLocSpacing
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MapLocSpacing = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                spacer2 = {
                    order = 14,
                    type = "description",
                    name = "",
                },
                MenuFont = {
                    order = 15,
                    type = "select",
                    name = L["Menu Font"],
                    desc = L["Sets the font to be used on the memus"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Font.Menu) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("FontFace","Get")
                        Nx.db.profile.Font.Menu = vals[name]
                        Nx.Opts:NXCmdFontChange()
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("FontFace","Get")
                    end,
                },
                MenuFontSize = {
                    order = 16,
                    type = "range",
                    name = L["Menu Font Size"],
                    desc = L["Sets the size of the menu font"],
                    min = 6,
                    max = 14,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MenuSize
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MenuSize = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
                MenuFontSpacing = {
                    order = 17,
                    type = "range",
                    name = L["Menu Font Spacing"],
                    desc = L["Sets the spacing of the menu font"],
                    min = -10,
                    max = 20,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Font.MenuSpacing
                    end,
                    set = function(info,value)
                        Nx.db.profile.Font.MenuSpacing = value
                        Nx.Opts:NXCmdFontChange()
                    end,
                },
            },
        }
    end
    return font
end

-------------------------------------------------------------------------------
-- GUIDE AND GATHER OPTIONS
-- Vendor recording, gathering node settings, and data import/export
-------------------------------------------------------------------------------

local guidegather

---
-- Get or create guide and gather options configuration
-- @return  Guide/Gather options table
--
local function guidegatherConfig()
    if not guidegather then
        guidegather = {
            type = "group",
            name = L["Guide Options"],
            childGroups = "tab",
            args = {
                guideOpts = {
                    order = 1,
                    type = "group",
                    name = L["Guide Options"],
                    args = {
                        GuideVendorVMax = {
                            order = 1,
                            type = "range",
                            name = L["Max Vendors To Record"],
                            desc = L["Sets the number of vendors you visit that will be held in memory for recall in the guide."],
                            min = 0,
                            max = 100,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.db.profile.Guide.VendorVMax
                            end,
                            set = function(info,value)
                                Nx.db.profile.Guide.VendorVMax = value
                            end,
                        },
                    },
                },
                gatherOpts = {
                    order = 2,
                    type = "group",
                    name = L["Gather Options"],
                    args = {
                        gatherEnable = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Enable Saving Gathered Nodes"],
                            desc = L["When enabled, will record all the resource nodes you gather"],
                            get = function()
                                return Nx.db.profile.Guide.GatherEnabled
                            end,
                            set = function()
                                Nx.db.profile.Guide.GatherEnabled = not Nx.db.profile.Guide.GatherEnabled
                            end,
                        },
                        spacer1 = {
                            order = 2,
                            type = "description",
                            name = "\n",
                        },
                        CmdDelHerb = {
                            order = 3,
                            type = "execute",
                            width = "full",
                            name = L["Delete Herbalism Gather Locations"],
                            func = function ()
                                Nx.Opts:NXCmdDeleteHerb()
                            end,
                        },
                        CmdDelMine = {
                            order = 4,
                            type = "execute",
                            width = "full",
                            name = L["Delete Mining Gather Locations"],
                            func = function ()
                                Nx.Opts:NXCmdDeleteMine()
                            end,
                        },
                        CmdDelTimber = {
                            order = 5,
                            type = "execute",
                            width = "full",
                            name = L["Delete Timber Gather Locations"],
                            hidden = function() return not Nx.isRetail end,
                            func = function ()
                                Nx.Opts:NXCmdDeleteTimber()
                            end,
                        },
                        CmdDelMisc = {
                            order = 6,
                            type = "execute",
                            width = "full",
                            name = L["Delete Misc Gather Locations"],
                            func = function ()
                                Nx.Opts:NXCmdDeleteMisc()
                            end,
                        },
                        spacer2 = {
                            order = 7,
                            type = "description",
                            name = "\n",
                        },
                        CmdImportHerb = {
                            order = 8,
                            type = "execute",
                            width = "full",
                            name = L["Import Herbs From GatherMate2_Data"],
                            func = function ()
                                Nx.Opts:NXCmdImportCarbHerb()
                            end,
                        },
                        CmdImportMine = {
                            order = 9,
                            type = "execute",
                            width = "full",
                            name = L["Import Mines From GatherMate2_Data"],
                            func = function ()
                                Nx.Opts:NXCmdImportCarbMine()
                            end,
                        },
                        CmdImportMisc = {
                            order = 10,
                            type = "execute",
                            width = "full",
                            name = L["Import Misc From GatherMate2_Data"],
                            func = function ()
                                Nx.Opts:NXCmdImportCarbMisc()
                            end,
                        },
                    },
                },
                -- Hardcoded herb options matching GatherInfo order with expansion filtering
                -- Uses Nx:ShouldShowGatherNode() for filtering based on skill level
                HerbDisp = {
                    order = 3,
                    type = "group",
                    name = L["Herbalism"],
                    args = {
                        enableall = {
                            order = 1,
                            type = "execute",
                            width = "double",
                            name = L["Enable All"],
                            func = function()
                                for i = 1, 160 do
                                    Nx.db.profile.Guide.ShowHerbs[i] = true
                                end
                            end,
                        },
                        disableall = {
                            order = 2,
                            type = "execute",
                            width = "double",
                            name = L["Disable All"],
                            func = function()
                                for i = 1, 160 do
                                    Nx.db.profile.Guide.ShowHerbs[i] = false
                                end
                            end,
                        },
                        -- ============================================
                        -- CLASSIC
                        -- ============================================
                        hdrClassic = { order = 10, type = "header", name = "|cff00ff00Classic|r" },
                        h2 = { order = 11, type = "toggle", width = "full", name = L["Arthas' Tears"], get = function() return Nx.db.profile.Guide.ShowHerbs[2] end, set = function() Nx.db.profile.Guide.ShowHerbs[2] = not Nx.db.profile.Guide.ShowHerbs[2] end },
                        h3 = { order = 12, type = "toggle", width = "full", name = L["Black Lotus"], get = function() return Nx.db.profile.Guide.ShowHerbs[3] end, set = function() Nx.db.profile.Guide.ShowHerbs[3] = not Nx.db.profile.Guide.ShowHerbs[3] end },
                        h4 = { order = 13, type = "toggle", width = "full", name = L["Blindweed"], get = function() return Nx.db.profile.Guide.ShowHerbs[4] end, set = function() Nx.db.profile.Guide.ShowHerbs[4] = not Nx.db.profile.Guide.ShowHerbs[4] end },
                        h6 = { order = 14, type = "toggle", width = "full", name = L["Briarthorn"], get = function() return Nx.db.profile.Guide.ShowHerbs[6] end, set = function() Nx.db.profile.Guide.ShowHerbs[6] = not Nx.db.profile.Guide.ShowHerbs[6] end },
                        h7 = { order = 15, type = "toggle", width = "full", name = L["Bruiseweed"], get = function() return Nx.db.profile.Guide.ShowHerbs[7] end, set = function() Nx.db.profile.Guide.ShowHerbs[7] = not Nx.db.profile.Guide.ShowHerbs[7] end },
                        h8 = { order = 16, type = "toggle", width = "full", name = L["Dreamfoil"], get = function() return Nx.db.profile.Guide.ShowHerbs[8] end, set = function() Nx.db.profile.Guide.ShowHerbs[8] = not Nx.db.profile.Guide.ShowHerbs[8] end },
                        h39 = { order = 17, type = "toggle", width = "full", name = L["Dragon's Teeth"], get = function() return Nx.db.profile.Guide.ShowHerbs[39] end, set = function() Nx.db.profile.Guide.ShowHerbs[39] = not Nx.db.profile.Guide.ShowHerbs[39] end },
                        h10 = { order = 18, type = "toggle", width = "full", name = L["Earthroot"], get = function() return Nx.db.profile.Guide.ShowHerbs[10] end, set = function() Nx.db.profile.Guide.ShowHerbs[10] = not Nx.db.profile.Guide.ShowHerbs[10] end },
                        h11 = { order = 19, type = "toggle", width = "full", name = L["Fadeleaf"], get = function() return Nx.db.profile.Guide.ShowHerbs[11] end, set = function() Nx.db.profile.Guide.ShowHerbs[11] = not Nx.db.profile.Guide.ShowHerbs[11] end },
                        h13 = { order = 20, type = "toggle", width = "full", name = L["Firebloom"], get = function() return Nx.db.profile.Guide.ShowHerbs[13] end, set = function() Nx.db.profile.Guide.ShowHerbs[13] = not Nx.db.profile.Guide.ShowHerbs[13] end },
                        h15 = { order = 21, type = "toggle", width = "full", name = L["Ghost Mushroom"], get = function() return Nx.db.profile.Guide.ShowHerbs[15] end, set = function() Nx.db.profile.Guide.ShowHerbs[15] = not Nx.db.profile.Guide.ShowHerbs[15] end },
                        h16 = { order = 22, type = "toggle", width = "full", name = L["Golden Sansam"], get = function() return Nx.db.profile.Guide.ShowHerbs[16] end, set = function() Nx.db.profile.Guide.ShowHerbs[16] = not Nx.db.profile.Guide.ShowHerbs[16] end },
                        h17 = { order = 23, type = "toggle", width = "full", name = L["Goldthorn"], get = function() return Nx.db.profile.Guide.ShowHerbs[17] end, set = function() Nx.db.profile.Guide.ShowHerbs[17] = not Nx.db.profile.Guide.ShowHerbs[17] end },
                        h18 = { order = 24, type = "toggle", width = "full", name = L["Grave Moss"], get = function() return Nx.db.profile.Guide.ShowHerbs[18] end, set = function() Nx.db.profile.Guide.ShowHerbs[18] = not Nx.db.profile.Guide.ShowHerbs[18] end },
                        h19 = { order = 25, type = "toggle", width = "full", name = L["Gromsblood"], get = function() return Nx.db.profile.Guide.ShowHerbs[19] end, set = function() Nx.db.profile.Guide.ShowHerbs[19] = not Nx.db.profile.Guide.ShowHerbs[19] end },
                        h20 = { order = 26, type = "toggle", width = "full", name = L["Icecap"], get = function() return Nx.db.profile.Guide.ShowHerbs[20] end, set = function() Nx.db.profile.Guide.ShowHerbs[20] = not Nx.db.profile.Guide.ShowHerbs[20] end },
                        h21 = { order = 27, type = "toggle", width = "full", name = L["Khadgar's Whisker"], get = function() return Nx.db.profile.Guide.ShowHerbs[21] end, set = function() Nx.db.profile.Guide.ShowHerbs[21] = not Nx.db.profile.Guide.ShowHerbs[21] end },
                        h22 = { order = 28, type = "toggle", width = "full", name = L["Kingsblood"], get = function() return Nx.db.profile.Guide.ShowHerbs[22] end, set = function() Nx.db.profile.Guide.ShowHerbs[22] = not Nx.db.profile.Guide.ShowHerbs[22] end },
                        h23 = { order = 29, type = "toggle", width = "full", name = L["Liferoot"], get = function() return Nx.db.profile.Guide.ShowHerbs[23] end, set = function() Nx.db.profile.Guide.ShowHerbs[23] = not Nx.db.profile.Guide.ShowHerbs[23] end },
                        h24 = { order = 30, type = "toggle", width = "full", name = L["Mageroyal"], get = function() return Nx.db.profile.Guide.ShowHerbs[24] end, set = function() Nx.db.profile.Guide.ShowHerbs[24] = not Nx.db.profile.Guide.ShowHerbs[24] end },
                        h26 = { order = 31, type = "toggle", width = "full", name = L["Mountain Silversage"], get = function() return Nx.db.profile.Guide.ShowHerbs[26] end, set = function() Nx.db.profile.Guide.ShowHerbs[26] = not Nx.db.profile.Guide.ShowHerbs[26] end },
                        h30 = { order = 32, type = "toggle", width = "full", name = L["Peacebloom"], get = function() return Nx.db.profile.Guide.ShowHerbs[30] end, set = function() Nx.db.profile.Guide.ShowHerbs[30] = not Nx.db.profile.Guide.ShowHerbs[30] end },
                        h31 = { order = 33, type = "toggle", width = "full", name = L["Plaguebloom"], get = function() return Nx.db.profile.Guide.ShowHerbs[31] end, set = function() Nx.db.profile.Guide.ShowHerbs[31] = not Nx.db.profile.Guide.ShowHerbs[31] end },
                        h32 = { order = 34, type = "toggle", width = "full", name = L["Purple Lotus"], get = function() return Nx.db.profile.Guide.ShowHerbs[32] end, set = function() Nx.db.profile.Guide.ShowHerbs[32] = not Nx.db.profile.Guide.ShowHerbs[32] end },
                        h34 = { order = 35, type = "toggle", width = "full", name = L["Silverleaf"], get = function() return Nx.db.profile.Guide.ShowHerbs[34] end, set = function() Nx.db.profile.Guide.ShowHerbs[34] = not Nx.db.profile.Guide.ShowHerbs[34] end },
                        h35 = { order = 36, type = "toggle", width = "full", name = L["Stranglekelp"], get = function() return Nx.db.profile.Guide.ShowHerbs[35] end, set = function() Nx.db.profile.Guide.ShowHerbs[35] = not Nx.db.profile.Guide.ShowHerbs[35] end },
                        h36 = { order = 37, type = "toggle", width = "full", name = L["Sungrass"], get = function() return Nx.db.profile.Guide.ShowHerbs[36] end, set = function() Nx.db.profile.Guide.ShowHerbs[36] = not Nx.db.profile.Guide.ShowHerbs[36] end },
                        h38 = { order = 38, type = "toggle", width = "full", name = L["Wild Steelbloom"], get = function() return Nx.db.profile.Guide.ShowHerbs[38] end, set = function() Nx.db.profile.Guide.ShowHerbs[38] = not Nx.db.profile.Guide.ShowHerbs[38] end },
                        -- ============================================
                        -- THE BURNING CRUSADE
                        -- ============================================
                        hdrTBC = { order = 100, type = "header", name = "|cff1eff00The Burning Crusade|r", hidden = function() return Nx.isClassicEra end },
                        h1 = { order = 101, type = "toggle", width = "full", name = L["Ancient Lichen"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[1] end, set = function() Nx.db.profile.Guide.ShowHerbs[1] = not Nx.db.profile.Guide.ShowHerbs[1] end },
                        h5 = { order = 102, type = "toggle", width = "full", name = L["Bloodthistle"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[5] end, set = function() Nx.db.profile.Guide.ShowHerbs[5] = not Nx.db.profile.Guide.ShowHerbs[5] end },
                        h9 = { order = 103, type = "toggle", width = "full", name = L["Dreaming Glory"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[9] end, set = function() Nx.db.profile.Guide.ShowHerbs[9] = not Nx.db.profile.Guide.ShowHerbs[9] end },
                        h12 = { order = 104, type = "toggle", width = "full", name = L["Felweed"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[12] end, set = function() Nx.db.profile.Guide.ShowHerbs[12] = not Nx.db.profile.Guide.ShowHerbs[12] end },
                        h14 = { order = 105, type = "toggle", width = "full", name = L["Flame Cap"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[14] end, set = function() Nx.db.profile.Guide.ShowHerbs[14] = not Nx.db.profile.Guide.ShowHerbs[14] end },
                        h40 = { order = 106, type = "toggle", width = "full", name = L["Glowcap"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[40] end, set = function() Nx.db.profile.Guide.ShowHerbs[40] = not Nx.db.profile.Guide.ShowHerbs[40] end },
                        h25 = { order = 107, type = "toggle", width = "full", name = L["Mana Thistle"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[25] end, set = function() Nx.db.profile.Guide.ShowHerbs[25] = not Nx.db.profile.Guide.ShowHerbs[25] end },
                        h27 = { order = 108, type = "toggle", width = "full", name = L["Netherbloom"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[27] end, set = function() Nx.db.profile.Guide.ShowHerbs[27] = not Nx.db.profile.Guide.ShowHerbs[27] end },
                        h28 = { order = 109, type = "toggle", width = "full", name = L["Netherdust Bush"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[28] end, set = function() Nx.db.profile.Guide.ShowHerbs[28] = not Nx.db.profile.Guide.ShowHerbs[28] end },
                        h29 = { order = 110, type = "toggle", width = "full", name = L["Nightmare Vine"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[29] end, set = function() Nx.db.profile.Guide.ShowHerbs[29] = not Nx.db.profile.Guide.ShowHerbs[29] end },
                        h33 = { order = 111, type = "toggle", width = "full", name = L["Ragveil"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[33] end, set = function() Nx.db.profile.Guide.ShowHerbs[33] = not Nx.db.profile.Guide.ShowHerbs[33] end },
                        h37 = { order = 112, type = "toggle", width = "full", name = L["Terocone"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowHerbs[37] end, set = function() Nx.db.profile.Guide.ShowHerbs[37] = not Nx.db.profile.Guide.ShowHerbs[37] end },
                        -- ============================================
                        -- WRATH OF THE LICH KING
                        -- ============================================
                        hdrWotLK = { order = 200, type = "header", name = "|cff0070ddWrath of the Lich King|r", hidden = function() return not Nx.WOTLKMaps end },
                        h43 = { order = 201, type = "toggle", width = "full", name = L["Adder's Tongue"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[43] end, set = function() Nx.db.profile.Guide.ShowHerbs[43] = not Nx.db.profile.Guide.ShowHerbs[43] end },
                        h49 = { order = 202, type = "toggle", width = "full", name = L["Firethorn"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[49] end, set = function() Nx.db.profile.Guide.ShowHerbs[49] = not Nx.db.profile.Guide.ShowHerbs[49] end },
                        h48 = { order = 203, type = "toggle", width = "full", name = L["Frost Lotus"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[48] end, set = function() Nx.db.profile.Guide.ShowHerbs[48] = not Nx.db.profile.Guide.ShowHerbs[48] end },
                        h44 = { order = 204, type = "toggle", width = "full", name = L["Frozen Herb"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[44] end, set = function() Nx.db.profile.Guide.ShowHerbs[44] = not Nx.db.profile.Guide.ShowHerbs[44] end },
                        h41 = { order = 205, type = "toggle", width = "full", name = L["Goldclover"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[41] end, set = function() Nx.db.profile.Guide.ShowHerbs[41] = not Nx.db.profile.Guide.ShowHerbs[41] end },
                        h47 = { order = 206, type = "toggle", width = "full", name = L["Icethorn"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[47] end, set = function() Nx.db.profile.Guide.ShowHerbs[47] = not Nx.db.profile.Guide.ShowHerbs[47] end },
                        h46 = { order = 207, type = "toggle", width = "full", name = L["Lichbloom"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[46] end, set = function() Nx.db.profile.Guide.ShowHerbs[46] = not Nx.db.profile.Guide.ShowHerbs[46] end },
                        h42 = { order = 208, type = "toggle", width = "full", name = L["Talandra's Rose"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[42] end, set = function() Nx.db.profile.Guide.ShowHerbs[42] = not Nx.db.profile.Guide.ShowHerbs[42] end },
                        h45 = { order = 209, type = "toggle", width = "full", name = L["Tiger Lily"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[45] end, set = function() Nx.db.profile.Guide.ShowHerbs[45] = not Nx.db.profile.Guide.ShowHerbs[45] end },
                        -- ============================================
                        -- CATACLYSM
                        -- ============================================
                        hdrCata = { order = 300, type = "header", name = "|cffa335eeCataclysm|r", hidden = function() return not Nx.CataMaps end },
                        h50 = { order = 301, type = "toggle", width = "full", name = L["Azshara's Veil"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[50] end, set = function() Nx.db.profile.Guide.ShowHerbs[50] = not Nx.db.profile.Guide.ShowHerbs[50] end },
                        h51 = { order = 302, type = "toggle", width = "full", name = L["Cinderbloom"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[51] end, set = function() Nx.db.profile.Guide.ShowHerbs[51] = not Nx.db.profile.Guide.ShowHerbs[51] end },
                        h53 = { order = 303, type = "toggle", width = "full", name = L["Heartblossom"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[53] end, set = function() Nx.db.profile.Guide.ShowHerbs[53] = not Nx.db.profile.Guide.ShowHerbs[53] end },
                        h52 = { order = 304, type = "toggle", width = "full", name = L["Stormvine"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[52] end, set = function() Nx.db.profile.Guide.ShowHerbs[52] = not Nx.db.profile.Guide.ShowHerbs[52] end },
                        h55 = { order = 305, type = "toggle", width = "full", name = L["Twilight Jasmine"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[55] end, set = function() Nx.db.profile.Guide.ShowHerbs[55] = not Nx.db.profile.Guide.ShowHerbs[55] end },
                        h54 = { order = 306, type = "toggle", width = "full", name = L["Whiptail"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[54] end, set = function() Nx.db.profile.Guide.ShowHerbs[54] = not Nx.db.profile.Guide.ShowHerbs[54] end },
                        -- ============================================
                        -- MISTS OF PANDARIA
                        -- ============================================
                        hdrMoP = { order = 400, type = "header", name = "|cff00ff96Mists of Pandaria|r", hidden = function() return not Nx.MOPMaps end },
                        h63 = { order = 401, type = "toggle", width = "full", name = L["Chameleon Lotus"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[63] end, set = function() Nx.db.profile.Guide.ShowHerbs[63] = not Nx.db.profile.Guide.ShowHerbs[63] end },
                        h56 = { order = 402, type = "toggle", width = "full", name = L["Fool's Cap"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[56] end, set = function() Nx.db.profile.Guide.ShowHerbs[56] = not Nx.db.profile.Guide.ShowHerbs[56] end },
                        h57 = { order = 403, type = "toggle", width = "full", name = L["Golden Lotus"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[57] end, set = function() Nx.db.profile.Guide.ShowHerbs[57] = not Nx.db.profile.Guide.ShowHerbs[57] end },
                        h58 = { order = 404, type = "toggle", width = "full", name = L["Green Tea Leaf"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[58] end, set = function() Nx.db.profile.Guide.ShowHerbs[58] = not Nx.db.profile.Guide.ShowHerbs[58] end },
                        h59 = { order = 405, type = "toggle", width = "full", name = L["Rain Poppy"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[59] end, set = function() Nx.db.profile.Guide.ShowHerbs[59] = not Nx.db.profile.Guide.ShowHerbs[59] end },
                        h60 = { order = 406, type = "toggle", width = "full", name = L["Sha-Touched Herb"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[60] end, set = function() Nx.db.profile.Guide.ShowHerbs[60] = not Nx.db.profile.Guide.ShowHerbs[60] end },
                        h61 = { order = 407, type = "toggle", width = "full", name = L["Silkweed"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[61] end, set = function() Nx.db.profile.Guide.ShowHerbs[61] = not Nx.db.profile.Guide.ShowHerbs[61] end },
                        h62 = { order = 408, type = "toggle", width = "full", name = L["Snow Lily"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowHerbs[62] end, set = function() Nx.db.profile.Guide.ShowHerbs[62] = not Nx.db.profile.Guide.ShowHerbs[62] end },
                        -- ============================================
                        -- WARLORDS OF DRAENOR
                        -- ============================================
                        hdrWoD = { order = 500, type = "header", name = "|cffff8000Warlords of Draenor|r", hidden = function() return not Nx.isRetail end },
                        h69 = { order = 501, type = "toggle", width = "full", name = L["Fireweed"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[69] end, set = function() Nx.db.profile.Guide.ShowHerbs[69] = not Nx.db.profile.Guide.ShowHerbs[69] end },
                        h64 = { order = 502, type = "toggle", width = "full", name = L["Frostweed"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[64] end, set = function() Nx.db.profile.Guide.ShowHerbs[64] = not Nx.db.profile.Guide.ShowHerbs[64] end },
                        h65 = { order = 503, type = "toggle", width = "full", name = L["Gorgrond Flytrap"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[65] end, set = function() Nx.db.profile.Guide.ShowHerbs[65] = not Nx.db.profile.Guide.ShowHerbs[65] end },
                        h67 = { order = 504, type = "toggle", width = "full", name = L["Nagrand Arrowbloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[67] end, set = function() Nx.db.profile.Guide.ShowHerbs[67] = not Nx.db.profile.Guide.ShowHerbs[67] end },
                        h66 = { order = 505, type = "toggle", width = "full", name = L["Starflower"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[66] end, set = function() Nx.db.profile.Guide.ShowHerbs[66] = not Nx.db.profile.Guide.ShowHerbs[66] end },
                        h68 = { order = 506, type = "toggle", width = "full", name = L["Talador Orchid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[68] end, set = function() Nx.db.profile.Guide.ShowHerbs[68] = not Nx.db.profile.Guide.ShowHerbs[68] end },
                        h70 = { order = 507, type = "toggle", width = "full", name = L["Withered Herb"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[70] end, set = function() Nx.db.profile.Guide.ShowHerbs[70] = not Nx.db.profile.Guide.ShowHerbs[70] end },
                        -- ============================================
                        -- LEGION
                        -- ============================================
                        hdrLegion = { order = 600, type = "header", name = "|cffe268a8Legion|r", hidden = function() return not Nx.isRetail end },
                        h71 = { order = 601, type = "toggle", width = "full", name = L["Aethril"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[71] end, set = function() Nx.db.profile.Guide.ShowHerbs[71] = not Nx.db.profile.Guide.ShowHerbs[71] end },
                        h77 = { order = 602, type = "toggle", width = "full", name = L["Astral Glory"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[77] end, set = function() Nx.db.profile.Guide.ShowHerbs[77] = not Nx.db.profile.Guide.ShowHerbs[77] end },
                        h72 = { order = 603, type = "toggle", width = "full", name = L["Dreamleaf"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[72] end, set = function() Nx.db.profile.Guide.ShowHerbs[72] = not Nx.db.profile.Guide.ShowHerbs[72] end },
                        h73 = { order = 604, type = "toggle", width = "full", name = L["Felwort"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[73] end, set = function() Nx.db.profile.Guide.ShowHerbs[73] = not Nx.db.profile.Guide.ShowHerbs[73] end },
                        h74 = { order = 605, type = "toggle", width = "full", name = L["Fjarnskaggl"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[74] end, set = function() Nx.db.profile.Guide.ShowHerbs[74] = not Nx.db.profile.Guide.ShowHerbs[74] end },
                        h75 = { order = 606, type = "toggle", width = "full", name = L["Foxflower"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[75] end, set = function() Nx.db.profile.Guide.ShowHerbs[75] = not Nx.db.profile.Guide.ShowHerbs[75] end },
                        h76 = { order = 607, type = "toggle", width = "full", name = L["Starlight Rose"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[76] end, set = function() Nx.db.profile.Guide.ShowHerbs[76] = not Nx.db.profile.Guide.ShowHerbs[76] end },
                        -- ============================================
                        -- BATTLE FOR AZEROTH
                        -- ============================================
                        hdrBfA = { order = 700, type = "header", name = "|cff4169e1Battle for Azeroth|r", hidden = function() return not Nx.isRetail end },
                        h78 = { order = 701, type = "toggle", width = "full", name = L["Akunda's Bite"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[78] end, set = function() Nx.db.profile.Guide.ShowHerbs[78] = not Nx.db.profile.Guide.ShowHerbs[78] end },
                        h79 = { order = 702, type = "toggle", width = "full", name = L["Anchor Weed"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[79] end, set = function() Nx.db.profile.Guide.ShowHerbs[79] = not Nx.db.profile.Guide.ShowHerbs[79] end },
                        h80 = { order = 703, type = "toggle", width = "full", name = L["Riverbud"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[80] end, set = function() Nx.db.profile.Guide.ShowHerbs[80] = not Nx.db.profile.Guide.ShowHerbs[80] end },
                        h81 = { order = 704, type = "toggle", width = "full", name = L["Sea Stalks"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[81] end, set = function() Nx.db.profile.Guide.ShowHerbs[81] = not Nx.db.profile.Guide.ShowHerbs[81] end },
                        h82 = { order = 705, type = "toggle", width = "full", name = L["Siren's Sting"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[82] end, set = function() Nx.db.profile.Guide.ShowHerbs[82] = not Nx.db.profile.Guide.ShowHerbs[82] end },
                        h83 = { order = 706, type = "toggle", width = "full", name = L["Star Moss"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[83] end, set = function() Nx.db.profile.Guide.ShowHerbs[83] = not Nx.db.profile.Guide.ShowHerbs[83] end },
                        h84 = { order = 707, type = "toggle", width = "full", name = L["Winter's Kiss"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[84] end, set = function() Nx.db.profile.Guide.ShowHerbs[84] = not Nx.db.profile.Guide.ShowHerbs[84] end },
                        -- ============================================
                        -- SHADOWLANDS
                        -- ============================================
                        hdrSL = { order = 800, type = "header", name = "|cff9370dbShadowlands|r", hidden = function() return not Nx.isRetail end },
                        h86 = { order = 801, type = "toggle", width = "full", name = L["Death Blossom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[86] end, set = function() Nx.db.profile.Guide.ShowHerbs[86] = not Nx.db.profile.Guide.ShowHerbs[86] end },
                        h88 = { order = 802, type = "toggle", width = "full", name = L["Marrowroot"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[88] end, set = function() Nx.db.profile.Guide.ShowHerbs[88] = not Nx.db.profile.Guide.ShowHerbs[88] end },
                        h90 = { order = 803, type = "toggle", width = "full", name = L["Nightshade"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[90] end, set = function() Nx.db.profile.Guide.ShowHerbs[90] = not Nx.db.profile.Guide.ShowHerbs[90] end },
                        h87 = { order = 804, type = "toggle", width = "full", name = L["Rising Glory"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[87] end, set = function() Nx.db.profile.Guide.ShowHerbs[87] = not Nx.db.profile.Guide.ShowHerbs[87] end },
                        h89 = { order = 805, type = "toggle", width = "full", name = L["Vigil's Torch"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[89] end, set = function() Nx.db.profile.Guide.ShowHerbs[89] = not Nx.db.profile.Guide.ShowHerbs[89] end },
                        h85 = { order = 806, type = "toggle", width = "full", name = L["Widowbloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[85] end, set = function() Nx.db.profile.Guide.ShowHerbs[85] = not Nx.db.profile.Guide.ShowHerbs[85] end },
                        -- ============================================
                        -- DRAGONFLIGHT
                        -- ============================================
                        hdrDF = { order = 900, type = "header", name = "|cff33937fDragonflight|r", hidden = function() return not Nx.isRetail end },
                        h92 = { order = 901, type = "toggle", width = "full", name = L["Bubble Poppy"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[92] end, set = function() Nx.db.profile.Guide.ShowHerbs[92] = not Nx.db.profile.Guide.ShowHerbs[92] end },
                        h91 = { order = 902, type = "toggle", width = "full", name = L["Hochenblume"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[91] end, set = function() Nx.db.profile.Guide.ShowHerbs[91] = not Nx.db.profile.Guide.ShowHerbs[91] end },
                        h93 = { order = 903, type = "toggle", width = "full", name = L["Saxifrage"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[93] end, set = function() Nx.db.profile.Guide.ShowHerbs[93] = not Nx.db.profile.Guide.ShowHerbs[93] end },
                        h94 = { order = 904, type = "toggle", width = "full", name = L["Writhebark"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[94] end, set = function() Nx.db.profile.Guide.ShowHerbs[94] = not Nx.db.profile.Guide.ShowHerbs[94] end },
                        -- ============================================
                        -- THE WAR WITHIN
                        -- ============================================
                        hdrTWW = { order = 1000, type = "header", name = "|cff00ccffThe War Within|r", hidden = function() return not Nx.isRetail end },
                        h107 = { order = 1001, type = "toggle", width = "full", name = L["Arathor's Spear"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[107] end, set = function() Nx.db.profile.Guide.ShowHerbs[107] = not Nx.db.profile.Guide.ShowHerbs[107] end },
                        h112 = { order = 1002, type = "toggle", width = "full", name = L["Blessing Blossom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[112] end, set = function() Nx.db.profile.Guide.ShowHerbs[112] = not Nx.db.profile.Guide.ShowHerbs[112] end },
                        h101 = { order = 1003, type = "toggle", width = "full", name = L["Luredrop"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[101] end, set = function() Nx.db.profile.Guide.ShowHerbs[101] = not Nx.db.profile.Guide.ShowHerbs[101] end },
                        h95 = { order = 1004, type = "toggle", width = "full", name = L["Mycobloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[95] end, set = function() Nx.db.profile.Guide.ShowHerbs[95] = not Nx.db.profile.Guide.ShowHerbs[95] end },
                        h117 = { order = 1005, type = "toggle", width = "full", name = L["Orbinid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[117] end, set = function() Nx.db.profile.Guide.ShowHerbs[117] = not Nx.db.profile.Guide.ShowHerbs[117] end },
                       -- TWW Variants (collapsible or hidden by default could be nice, but keeping simple for now)
                        h96 = { order = 1010, type = "toggle", width = "full", name = "  " .. L["Altered Mycobloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[96] end, set = function() Nx.db.profile.Guide.ShowHerbs[96] = not Nx.db.profile.Guide.ShowHerbs[96] end },
                        h97 = { order = 1011, type = "toggle", width = "full", name = "  " .. L["Crystallized Mycobloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[97] end, set = function() Nx.db.profile.Guide.ShowHerbs[97] = not Nx.db.profile.Guide.ShowHerbs[97] end },
                        h98 = { order = 1012, type = "toggle", width = "full", name = "  " .. L["Irradiated Mycobloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[98] end, set = function() Nx.db.profile.Guide.ShowHerbs[98] = not Nx.db.profile.Guide.ShowHerbs[98] end },
                        h99 = { order = 1013, type = "toggle", width = "full", name = "  " .. L["Lush Mycobloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[99] end, set = function() Nx.db.profile.Guide.ShowHerbs[99] = not Nx.db.profile.Guide.ShowHerbs[99] end },
                        h100 = { order = 1014, type = "toggle", width = "full", name = "  " .. L["Sporefused Mycobloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[100] end, set = function() Nx.db.profile.Guide.ShowHerbs[100] = not Nx.db.profile.Guide.ShowHerbs[100] end },
                        h102 = { order = 1015, type = "toggle", width = "full", name = "  " .. L["Altered Luredrop"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[102] end, set = function() Nx.db.profile.Guide.ShowHerbs[102] = not Nx.db.profile.Guide.ShowHerbs[102] end },
                        h103 = { order = 1016, type = "toggle", width = "full", name = "  " .. L["Crystallized Luredrop"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[103] end, set = function() Nx.db.profile.Guide.ShowHerbs[103] = not Nx.db.profile.Guide.ShowHerbs[103] end },
                        h104 = { order = 1017, type = "toggle", width = "full", name = "  " .. L["Irradiated Luredrop"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[104] end, set = function() Nx.db.profile.Guide.ShowHerbs[104] = not Nx.db.profile.Guide.ShowHerbs[104] end },
                        h105 = { order = 1018, type = "toggle", width = "full", name = "  " .. L["Lush Luredrop"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[105] end, set = function() Nx.db.profile.Guide.ShowHerbs[105] = not Nx.db.profile.Guide.ShowHerbs[105] end },
                        h106 = { order = 1019, type = "toggle", width = "full", name = "  " .. L["Sporefused Luredrop"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[106] end, set = function() Nx.db.profile.Guide.ShowHerbs[106] = not Nx.db.profile.Guide.ShowHerbs[106] end },
                        h108 = { order = 1020, type = "toggle", width = "full", name = "  " .. L["Crystallized Arathor's Spear"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[108] end, set = function() Nx.db.profile.Guide.ShowHerbs[108] = not Nx.db.profile.Guide.ShowHerbs[108] end },
                        h109 = { order = 1021, type = "toggle", width = "full", name = "  " .. L["Irradiated Arathor's Spear"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[109] end, set = function() Nx.db.profile.Guide.ShowHerbs[109] = not Nx.db.profile.Guide.ShowHerbs[109] end },
                        h110 = { order = 1022, type = "toggle", width = "full", name = "  " .. L["Lush Arathor's Spear"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[110] end, set = function() Nx.db.profile.Guide.ShowHerbs[110] = not Nx.db.profile.Guide.ShowHerbs[110] end },
                        h111 = { order = 1023, type = "toggle", width = "full", name = "  " .. L["Sporefused Arathor's Spear"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[111] end, set = function() Nx.db.profile.Guide.ShowHerbs[111] = not Nx.db.profile.Guide.ShowHerbs[111] end },
                        h113 = { order = 1024, type = "toggle", width = "full", name = "  " .. L["Crystallized Blessing Blossom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[113] end, set = function() Nx.db.profile.Guide.ShowHerbs[113] = not Nx.db.profile.Guide.ShowHerbs[113] end },
                        h114 = { order = 1025, type = "toggle", width = "full", name = "  " .. L["Irradiated Blessing Blossom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[114] end, set = function() Nx.db.profile.Guide.ShowHerbs[114] = not Nx.db.profile.Guide.ShowHerbs[114] end },
                        h115 = { order = 1026, type = "toggle", width = "full", name = "  " .. L["Lush Blessing Blossom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[115] end, set = function() Nx.db.profile.Guide.ShowHerbs[115] = not Nx.db.profile.Guide.ShowHerbs[115] end },
                        h116 = { order = 1027, type = "toggle", width = "full", name = "  " .. L["Sporefused Blessing Blossom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[116] end, set = function() Nx.db.profile.Guide.ShowHerbs[116] = not Nx.db.profile.Guide.ShowHerbs[116] end },
                        h118 = { order = 1028, type = "toggle", width = "full", name = "  " .. L["Altered Orbinid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[118] end, set = function() Nx.db.profile.Guide.ShowHerbs[118] = not Nx.db.profile.Guide.ShowHerbs[118] end },
                        h119 = { order = 1029, type = "toggle", width = "full", name = "  " .. L["Crystallized Orbinid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[119] end, set = function() Nx.db.profile.Guide.ShowHerbs[119] = not Nx.db.profile.Guide.ShowHerbs[119] end },
                        h120 = { order = 1030, type = "toggle", width = "full", name = "  " .. L["Irradiated Orbinid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[120] end, set = function() Nx.db.profile.Guide.ShowHerbs[120] = not Nx.db.profile.Guide.ShowHerbs[120] end },
                        h121 = { order = 1031, type = "toggle", width = "full", name = "  " .. L["Lush Orbinid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[121] end, set = function() Nx.db.profile.Guide.ShowHerbs[121] = not Nx.db.profile.Guide.ShowHerbs[121] end },
                        h122 = { order = 1032, type = "toggle", width = "full", name = "  " .. L["Sporefused Orbinid"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[122] end, set = function() Nx.db.profile.Guide.ShowHerbs[122] = not Nx.db.profile.Guide.ShowHerbs[122] end },
                        -- ============================================
                        -- MIDNIGHT
                        -- ============================================
                        hdrMidnight = { order = 1100, type = "header", name = "|cffaa00ffMidnight|r", hidden = function() return not Nx.isRetail end },
                        h123 = { order = 1101, type = "toggle", width = "full", name = L["Argentleaf"],        hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[123] end, set = function() Nx.db.profile.Guide.ShowHerbs[123] = not Nx.db.profile.Guide.ShowHerbs[123] end },
                        h124 = { order = 1102, type = "toggle", width = "full", name = L["Azeroot"],           hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[124] end, set = function() Nx.db.profile.Guide.ShowHerbs[124] = not Nx.db.profile.Guide.ShowHerbs[124] end },
                        h125 = { order = 1103, type = "toggle", width = "full", name = L["Mana Lily"],         hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[125] end, set = function() Nx.db.profile.Guide.ShowHerbs[125] = not Nx.db.profile.Guide.ShowHerbs[125] end },
                        h126 = { order = 1104, type = "toggle", width = "full", name = L["Sanguithorn"],       hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[126] end, set = function() Nx.db.profile.Guide.ShowHerbs[126] = not Nx.db.profile.Guide.ShowHerbs[126] end },
                        h127 = { order = 1105, type = "toggle", width = "full", name = L["Tranquility Bloom"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowHerbs[127] end, set = function() Nx.db.profile.Guide.ShowHerbs[127] = not Nx.db.profile.Guide.ShowHerbs[127] end },
                    },
                },
                -- Hardcoded mining options matching GatherInfo order with expansion filtering
                MinesDisp = {
                    order = 4,
                    type = "group",
                    name = L["Mining"],
                    args = {
                        menableall = {
                            order = 1,
                            type = "execute",
                            width = "double",
                            name = L["Enable All"],
                            func = function()
                                for i = 1, 125 do
                                    Nx.db.profile.Guide.ShowMines[i] = true
                                end
                            end,
                        },
                        mdisableall = {
                            order = 2,
                            type = "execute",
                            width = "double",
                            name = L["Disable All"],
                            func = function()
                                for i = 1, 125 do
                                    Nx.db.profile.Guide.ShowMines[i] = false
                                end
                            end,
                        },
                        -- ============================================
                        -- CLASSIC
                        -- ============================================
                        mhdrClassic = { order = 10, type = "header", name = "|cff00ff00Classic|r" },
                        m3 = { order = 11, type = "toggle", width = "full", name = L["Copper Vein"], get = function() return Nx.db.profile.Guide.ShowMines[3] end, set = function() Nx.db.profile.Guide.ShowMines[3] = not Nx.db.profile.Guide.ShowMines[3] end },
                        m4 = { order = 12, type = "toggle", width = "full", name = L["Dark Iron Deposit"], get = function() return Nx.db.profile.Guide.ShowMines[4] end, set = function() Nx.db.profile.Guide.ShowMines[4] = not Nx.db.profile.Guide.ShowMines[4] end },
                        m6 = { order = 13, type = "toggle", width = "full", name = L["Gold Vein"], get = function() return Nx.db.profile.Guide.ShowMines[6] end, set = function() Nx.db.profile.Guide.ShowMines[6] = not Nx.db.profile.Guide.ShowMines[6] end },
                        m7 = { order = 14, type = "toggle", width = "full", name = L["Incendicite Mineral Vein"], get = function() return Nx.db.profile.Guide.ShowMines[7] end, set = function() Nx.db.profile.Guide.ShowMines[7] = not Nx.db.profile.Guide.ShowMines[7] end },
                        m8 = { order = 15, type = "toggle", width = "full", name = L["Indurium Mineral Vein"], get = function() return Nx.db.profile.Guide.ShowMines[8] end, set = function() Nx.db.profile.Guide.ShowMines[8] = not Nx.db.profile.Guide.ShowMines[8] end },
                        m9 = { order = 16, type = "toggle", width = "full", name = L["Iron Deposit"], get = function() return Nx.db.profile.Guide.ShowMines[9] end, set = function() Nx.db.profile.Guide.ShowMines[9] = not Nx.db.profile.Guide.ShowMines[9] end },
                        m11 = { order = 17, type = "toggle", width = "full", name = L["Large Obsidian Chunk"], get = function() return Nx.db.profile.Guide.ShowMines[11] end, set = function() Nx.db.profile.Guide.ShowMines[11] = not Nx.db.profile.Guide.ShowMines[11] end },
                        m12 = { order = 18, type = "toggle", width = "full", name = L["Lesser Bloodstone Deposit"], get = function() return Nx.db.profile.Guide.ShowMines[12] end, set = function() Nx.db.profile.Guide.ShowMines[12] = not Nx.db.profile.Guide.ShowMines[12] end },
                        m13 = { order = 19, type = "toggle", width = "full", name = L["Mithril Deposit"], get = function() return Nx.db.profile.Guide.ShowMines[13] end, set = function() Nx.db.profile.Guide.ShowMines[13] = not Nx.db.profile.Guide.ShowMines[13] end },
                        m16 = { order = 20, type = "toggle", width = "full", name = L["Rich Thorium Vein"], get = function() return Nx.db.profile.Guide.ShowMines[16] end, set = function() Nx.db.profile.Guide.ShowMines[16] = not Nx.db.profile.Guide.ShowMines[16] end },
                        m17 = { order = 21, type = "toggle", width = "full", name = L["Silver Vein"], get = function() return Nx.db.profile.Guide.ShowMines[17] end, set = function() Nx.db.profile.Guide.ShowMines[17] = not Nx.db.profile.Guide.ShowMines[17] end },
                        m18 = { order = 22, type = "toggle", width = "full", name = L["Small Obsidian Chunk"], get = function() return Nx.db.profile.Guide.ShowMines[18] end, set = function() Nx.db.profile.Guide.ShowMines[18] = not Nx.db.profile.Guide.ShowMines[18] end },
                        m19 = { order = 23, type = "toggle", width = "full", name = L["Small Thorium Vein"], get = function() return Nx.db.profile.Guide.ShowMines[19] end, set = function() Nx.db.profile.Guide.ShowMines[19] = not Nx.db.profile.Guide.ShowMines[19] end },
                        m20 = { order = 24, type = "toggle", width = "full", name = L["Tin Vein"], get = function() return Nx.db.profile.Guide.ShowMines[20] end, set = function() Nx.db.profile.Guide.ShowMines[20] = not Nx.db.profile.Guide.ShowMines[20] end },
                        m21 = { order = 25, type = "toggle", width = "full", name = L["Truesilver Deposit"], get = function() return Nx.db.profile.Guide.ShowMines[21] end, set = function() Nx.db.profile.Guide.ShowMines[21] = not Nx.db.profile.Guide.ShowMines[21] end },
                        -- ============================================
                        -- THE BURNING CRUSADE
                        -- ============================================
                        mhdrTBC = { order = 100, type = "header", name = "|cff1eff00The Burning Crusade|r", hidden = function() return Nx.isClassicEra end },
                        m1 = { order = 101, type = "toggle", width = "full", name = L["Adamantite Deposit"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowMines[1] end, set = function() Nx.db.profile.Guide.ShowMines[1] = not Nx.db.profile.Guide.ShowMines[1] end },
                        m2 = { order = 102, type = "toggle", width = "full", name = L["Ancient Gem Vein"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowMines[2] end, set = function() Nx.db.profile.Guide.ShowMines[2] = not Nx.db.profile.Guide.ShowMines[2] end },
                        m5 = { order = 103, type = "toggle", width = "full", name = L["Fel Iron Deposit"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowMines[5] end, set = function() Nx.db.profile.Guide.ShowMines[5] = not Nx.db.profile.Guide.ShowMines[5] end },
                        m10 = { order = 104, type = "toggle", width = "full", name = L["Khorium Vein"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowMines[10] end, set = function() Nx.db.profile.Guide.ShowMines[10] = not Nx.db.profile.Guide.ShowMines[10] end },
                        m14 = { order = 105, type = "toggle", width = "full", name = L["Nethercite Deposit"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowMines[14] end, set = function() Nx.db.profile.Guide.ShowMines[14] = not Nx.db.profile.Guide.ShowMines[14] end },
                        m15 = { order = 106, type = "toggle", width = "full", name = L["Rich Adamantite Deposit"], hidden = function() return Nx.isClassicEra end, get = function() return Nx.db.profile.Guide.ShowMines[15] end, set = function() Nx.db.profile.Guide.ShowMines[15] = not Nx.db.profile.Guide.ShowMines[15] end },
                        -- ============================================
                        -- WRATH OF THE LICH KING
                        -- ============================================
                        mhdrWotLK = { order = 200, type = "header", name = "|cff0070ddWrath of the Lich King|r", hidden = function() return not Nx.WOTLKMaps end },
                        m22 = { order = 201, type = "toggle", width = "full", name = L["Cobalt Deposit"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowMines[22] end, set = function() Nx.db.profile.Guide.ShowMines[22] = not Nx.db.profile.Guide.ShowMines[22] end },
                        m23 = { order = 202, type = "toggle", width = "full", name = L["Rich Cobalt Deposit"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowMines[23] end, set = function() Nx.db.profile.Guide.ShowMines[23] = not Nx.db.profile.Guide.ShowMines[23] end },
                        m25 = { order = 203, type = "toggle", width = "full", name = L["Rich Saronite Deposit"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowMines[25] end, set = function() Nx.db.profile.Guide.ShowMines[25] = not Nx.db.profile.Guide.ShowMines[25] end },
                        m24 = { order = 204, type = "toggle", width = "full", name = L["Saronite Deposit"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowMines[24] end, set = function() Nx.db.profile.Guide.ShowMines[24] = not Nx.db.profile.Guide.ShowMines[24] end },
                        m26 = { order = 205, type = "toggle", width = "full", name = L["Titanium Vein"], hidden = function() return not Nx.WOTLKMaps end, get = function() return Nx.db.profile.Guide.ShowMines[26] end, set = function() Nx.db.profile.Guide.ShowMines[26] = not Nx.db.profile.Guide.ShowMines[26] end },
                        -- ============================================
                        -- CATACLYSM
                        -- ============================================
                        mhdrCata = { order = 300, type = "header", name = "|cffa335eeCataclysm|r", hidden = function() return not Nx.CataMaps end },
                        m29 = { order = 301, type = "toggle", width = "full", name = L["Elementium Vein"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowMines[29] end, set = function() Nx.db.profile.Guide.ShowMines[29] = not Nx.db.profile.Guide.ShowMines[29] end },
                        m27 = { order = 302, type = "toggle", width = "full", name = L["Obsidium Deposit"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowMines[27] end, set = function() Nx.db.profile.Guide.ShowMines[27] = not Nx.db.profile.Guide.ShowMines[27] end },
                        m31 = { order = 303, type = "toggle", width = "full", name = L["Pyrite Deposit"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowMines[31] end, set = function() Nx.db.profile.Guide.ShowMines[31] = not Nx.db.profile.Guide.ShowMines[31] end },
                        m30 = { order = 304, type = "toggle", width = "full", name = L["Rich Elementium Vein"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowMines[30] end, set = function() Nx.db.profile.Guide.ShowMines[30] = not Nx.db.profile.Guide.ShowMines[30] end },
                        m28 = { order = 305, type = "toggle", width = "full", name = L["Rich Obsidium Deposit"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowMines[28] end, set = function() Nx.db.profile.Guide.ShowMines[28] = not Nx.db.profile.Guide.ShowMines[28] end },
                        m32 = { order = 306, type = "toggle", width = "full", name = L["Rich Pyrite Deposit"], hidden = function() return not Nx.CataMaps end, get = function() return Nx.db.profile.Guide.ShowMines[32] end, set = function() Nx.db.profile.Guide.ShowMines[32] = not Nx.db.profile.Guide.ShowMines[32] end },
                        -- ============================================
                        -- MISTS OF PANDARIA
                        -- ============================================
                        mhdrMoP = { order = 400, type = "header", name = "|cff00ff96Mists of Pandaria|r", hidden = function() return not Nx.MOPMaps end },
                        m33 = { order = 401, type = "toggle", width = "full", name = L["Ghost Iron Deposit"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowMines[33] end, set = function() Nx.db.profile.Guide.ShowMines[33] = not Nx.db.profile.Guide.ShowMines[33] end },
                        m35 = { order = 402, type = "toggle", width = "full", name = L["Kyparite Deposit"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowMines[35] end, set = function() Nx.db.profile.Guide.ShowMines[35] = not Nx.db.profile.Guide.ShowMines[35] end },
                        m34 = { order = 403, type = "toggle", width = "full", name = L["Rich Ghost Iron Deposit"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowMines[34] end, set = function() Nx.db.profile.Guide.ShowMines[34] = not Nx.db.profile.Guide.ShowMines[34] end },
                        m36 = { order = 404, type = "toggle", width = "full", name = L["Rich Kyparite Deposit"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowMines[36] end, set = function() Nx.db.profile.Guide.ShowMines[36] = not Nx.db.profile.Guide.ShowMines[36] end },
                        m38 = { order = 405, type = "toggle", width = "full", name = L["Rich Trillium Vein"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowMines[38] end, set = function() Nx.db.profile.Guide.ShowMines[38] = not Nx.db.profile.Guide.ShowMines[38] end },
                        m37 = { order = 406, type = "toggle", width = "full", name = L["Trillium Vein"], hidden = function() return not Nx.MOPMaps end, get = function() return Nx.db.profile.Guide.ShowMines[37] end, set = function() Nx.db.profile.Guide.ShowMines[37] = not Nx.db.profile.Guide.ShowMines[37] end },
                        -- ============================================
                        -- WARLORDS OF DRAENOR
                        -- ============================================
                        mhdrWoD = { order = 500, type = "header", name = "|cffff8000Warlords of Draenor|r", hidden = function() return not Nx.isRetail end },
                        m42 = { order = 501, type = "toggle", width = "full", name = L["Blackrock Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[42] end, set = function() Nx.db.profile.Guide.ShowMines[42] = not Nx.db.profile.Guide.ShowMines[42] end },
                        m43 = { order = 502, type = "toggle", width = "full", name = L["Rich Blackrock Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[43] end, set = function() Nx.db.profile.Guide.ShowMines[43] = not Nx.db.profile.Guide.ShowMines[43] end },
                        m40 = { order = 503, type = "toggle", width = "full", name = L["Rich True Iron Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[40] end, set = function() Nx.db.profile.Guide.ShowMines[40] = not Nx.db.profile.Guide.ShowMines[40] end },
                        m41 = { order = 504, type = "toggle", width = "full", name = L["Smoldering True Iron Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[41] end, set = function() Nx.db.profile.Guide.ShowMines[41] = not Nx.db.profile.Guide.ShowMines[41] end },
                        m39 = { order = 505, type = "toggle", width = "full", name = L["True Iron Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[39] end, set = function() Nx.db.profile.Guide.ShowMines[39] = not Nx.db.profile.Guide.ShowMines[39] end },
                        -- ============================================
                        -- LEGION
                        -- ============================================
                        mhdrLegion = { order = 600, type = "header", name = "|cffe268a8Legion|r", hidden = function() return not Nx.isRetail end },
                        m50 = { order = 601, type = "toggle", width = "full", name = L["Empyrium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[50] end, set = function() Nx.db.profile.Guide.ShowMines[50] = not Nx.db.profile.Guide.ShowMines[50] end },
                        m52 = { order = 602, type = "toggle", width = "full", name = L["Empyrium Seam"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[52] end, set = function() Nx.db.profile.Guide.ShowMines[52] = not Nx.db.profile.Guide.ShowMines[52] end },
                        m44 = { order = 603, type = "toggle", width = "full", name = L["Felslate Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[44] end, set = function() Nx.db.profile.Guide.ShowMines[44] = not Nx.db.profile.Guide.ShowMines[44] end },
                        m45 = { order = 604, type = "toggle", width = "full", name = L["Felslate Seam"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[45] end, set = function() Nx.db.profile.Guide.ShowMines[45] = not Nx.db.profile.Guide.ShowMines[45] end },
                        m47 = { order = 605, type = "toggle", width = "full", name = L["Leystone Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[47] end, set = function() Nx.db.profile.Guide.ShowMines[47] = not Nx.db.profile.Guide.ShowMines[47] end },
                        m48 = { order = 606, type = "toggle", width = "full", name = L["Leystone Seam"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[48] end, set = function() Nx.db.profile.Guide.ShowMines[48] = not Nx.db.profile.Guide.ShowMines[48] end },
                        m46 = { order = 607, type = "toggle", width = "full", name = L["Living Felslate"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[46] end, set = function() Nx.db.profile.Guide.ShowMines[46] = not Nx.db.profile.Guide.ShowMines[46] end },
                        m49 = { order = 608, type = "toggle", width = "full", name = L["Living Leystone"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[49] end, set = function() Nx.db.profile.Guide.ShowMines[49] = not Nx.db.profile.Guide.ShowMines[49] end },
                        m51 = { order = 609, type = "toggle", width = "full", name = L["Rich Empyrium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[51] end, set = function() Nx.db.profile.Guide.ShowMines[51] = not Nx.db.profile.Guide.ShowMines[51] end },
                        -- ============================================
                        -- BATTLE FOR AZEROTH
                        -- ============================================
                        mhdrBfA = { order = 700, type = "header", name = "|cff4169e1Battle for Azeroth|r", hidden = function() return not Nx.isRetail end },
                        m53 = { order = 701, type = "toggle", width = "full", name = L["Monelite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[53] end, set = function() Nx.db.profile.Guide.ShowMines[53] = not Nx.db.profile.Guide.ShowMines[53] end },
                        m55 = { order = 702, type = "toggle", width = "full", name = L["Monelite Seam"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[55] end, set = function() Nx.db.profile.Guide.ShowMines[55] = not Nx.db.profile.Guide.ShowMines[55] end },
                        m56 = { order = 703, type = "toggle", width = "full", name = L["Platinum Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[56] end, set = function() Nx.db.profile.Guide.ShowMines[56] = not Nx.db.profile.Guide.ShowMines[56] end },
                        m54 = { order = 704, type = "toggle", width = "full", name = L["Rich Monelite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[54] end, set = function() Nx.db.profile.Guide.ShowMines[54] = not Nx.db.profile.Guide.ShowMines[54] end },
                        m57 = { order = 705, type = "toggle", width = "full", name = L["Rich Platinum Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[57] end, set = function() Nx.db.profile.Guide.ShowMines[57] = not Nx.db.profile.Guide.ShowMines[57] end },
                        m59 = { order = 706, type = "toggle", width = "full", name = L["Rich Storm Silver Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[59] end, set = function() Nx.db.profile.Guide.ShowMines[59] = not Nx.db.profile.Guide.ShowMines[59] end },
                        m58 = { order = 707, type = "toggle", width = "full", name = L["Storm Silver Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[58] end, set = function() Nx.db.profile.Guide.ShowMines[58] = not Nx.db.profile.Guide.ShowMines[58] end },
                        m60 = { order = 708, type = "toggle", width = "full", name = L["Storm Silver Seam"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[60] end, set = function() Nx.db.profile.Guide.ShowMines[60] = not Nx.db.profile.Guide.ShowMines[60] end },
                        -- ============================================
                        -- SHADOWLANDS
                        -- ============================================
                        mhdrSL = { order = 800, type = "header", name = "|cff9370dbShadowlands|r", hidden = function() return not Nx.isRetail end },
                        m63 = { order = 801, type = "toggle", width = "full", name = L["Elethium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[63] end, set = function() Nx.db.profile.Guide.ShowMines[63] = not Nx.db.profile.Guide.ShowMines[63] end },
                        m61 = { order = 802, type = "toggle", width = "full", name = L["Laestrite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[61] end, set = function() Nx.db.profile.Guide.ShowMines[61] = not Nx.db.profile.Guide.ShowMines[61] end },
                        m67 = { order = 803, type = "toggle", width = "full", name = L["Oxxein Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[67] end, set = function() Nx.db.profile.Guide.ShowMines[67] = not Nx.db.profile.Guide.ShowMines[67] end },
                        m69 = { order = 804, type = "toggle", width = "full", name = L["Phaedrum Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[69] end, set = function() Nx.db.profile.Guide.ShowMines[69] = not Nx.db.profile.Guide.ShowMines[69] end },
                        m64 = { order = 805, type = "toggle", width = "full", name = L["Rich Elethium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[64] end, set = function() Nx.db.profile.Guide.ShowMines[64] = not Nx.db.profile.Guide.ShowMines[64] end },
                        m62 = { order = 806, type = "toggle", width = "full", name = L["Rich Laestrite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[62] end, set = function() Nx.db.profile.Guide.ShowMines[62] = not Nx.db.profile.Guide.ShowMines[62] end },
                        m68 = { order = 807, type = "toggle", width = "full", name = L["Rich Oxxein Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[68] end, set = function() Nx.db.profile.Guide.ShowMines[68] = not Nx.db.profile.Guide.ShowMines[68] end },
                        m70 = { order = 808, type = "toggle", width = "full", name = L["Rich Phaedrum Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[70] end, set = function() Nx.db.profile.Guide.ShowMines[70] = not Nx.db.profile.Guide.ShowMines[70] end },
                        m72 = { order = 809, type = "toggle", width = "full", name = L["Rich Sinvyr Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[72] end, set = function() Nx.db.profile.Guide.ShowMines[72] = not Nx.db.profile.Guide.ShowMines[72] end },
                        m66 = { order = 810, type = "toggle", width = "full", name = L["Rich Solenium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[66] end, set = function() Nx.db.profile.Guide.ShowMines[66] = not Nx.db.profile.Guide.ShowMines[66] end },
                        m71 = { order = 811, type = "toggle", width = "full", name = L["Sinvyr Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[71] end, set = function() Nx.db.profile.Guide.ShowMines[71] = not Nx.db.profile.Guide.ShowMines[71] end },
                        m65 = { order = 812, type = "toggle", width = "full", name = L["Solenium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[65] end, set = function() Nx.db.profile.Guide.ShowMines[65] = not Nx.db.profile.Guide.ShowMines[65] end },
                        -- ============================================
                        -- DRAGONFLIGHT
                        -- ============================================
                        mhdrDF = { order = 900, type = "header", name = "|cff33937fDragonflight|r", hidden = function() return not Nx.isRetail end },
                        m80 = { order = 901, type = "toggle", width = "full", name = L["Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[80] end, set = function() Nx.db.profile.Guide.ShowMines[80] = not Nx.db.profile.Guide.ShowMines[80] end },
                        m73 = { order = 902, type = "toggle", width = "full", name = L["Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[73] end, set = function() Nx.db.profile.Guide.ShowMines[73] = not Nx.db.profile.Guide.ShowMines[73] end },
                        m81 = { order = 910, type = "toggle", width = "full", name = "  " .. L["Hardened Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[81] end, set = function() Nx.db.profile.Guide.ShowMines[81] = not Nx.db.profile.Guide.ShowMines[81] end },
                        m74 = { order = 911, type = "toggle", width = "full", name = "  " .. L["Hardened Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[74] end, set = function() Nx.db.profile.Guide.ShowMines[74] = not Nx.db.profile.Guide.ShowMines[74] end },
                        m82 = { order = 912, type = "toggle", width = "full", name = "  " .. L["Infurious Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[82] end, set = function() Nx.db.profile.Guide.ShowMines[82] = not Nx.db.profile.Guide.ShowMines[82] end },
                        m75 = { order = 913, type = "toggle", width = "full", name = "  " .. L["Infurious Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[75] end, set = function() Nx.db.profile.Guide.ShowMines[75] = not Nx.db.profile.Guide.ShowMines[75] end },
                        m83 = { order = 914, type = "toggle", width = "full", name = "  " .. L["Molten Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[83] end, set = function() Nx.db.profile.Guide.ShowMines[83] = not Nx.db.profile.Guide.ShowMines[83] end },
                        m76 = { order = 915, type = "toggle", width = "full", name = "  " .. L["Molten Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[76] end, set = function() Nx.db.profile.Guide.ShowMines[76] = not Nx.db.profile.Guide.ShowMines[76] end },
                        m84 = { order = 916, type = "toggle", width = "full", name = "  " .. L["Primal Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[84] end, set = function() Nx.db.profile.Guide.ShowMines[84] = not Nx.db.profile.Guide.ShowMines[84] end },
                        m77 = { order = 917, type = "toggle", width = "full", name = "  " .. L["Primal Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[77] end, set = function() Nx.db.profile.Guide.ShowMines[77] = not Nx.db.profile.Guide.ShowMines[77] end },
                        m85 = { order = 918, type = "toggle", width = "full", name = "  " .. L["Rich Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[85] end, set = function() Nx.db.profile.Guide.ShowMines[85] = not Nx.db.profile.Guide.ShowMines[85] end },
                        m78 = { order = 919, type = "toggle", width = "full", name = "  " .. L["Rich Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[78] end, set = function() Nx.db.profile.Guide.ShowMines[78] = not Nx.db.profile.Guide.ShowMines[78] end },
                        m86 = { order = 920, type = "toggle", width = "full", name = "  " .. L["Titan-Touched Draconium Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[86] end, set = function() Nx.db.profile.Guide.ShowMines[86] = not Nx.db.profile.Guide.ShowMines[86] end },
                        m79 = { order = 921, type = "toggle", width = "full", name = "  " .. L["Titan-Touched Serevite Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[79] end, set = function() Nx.db.profile.Guide.ShowMines[79] = not Nx.db.profile.Guide.ShowMines[79] end },
                        -- ============================================
                        -- THE WAR WITHIN
                        -- ============================================
                        mhdrTWW = { order = 1000, type = "header", name = "|cff00ccffThe War Within|r", hidden = function() return not Nx.isRetail end },
                        m97 = { order = 1001, type = "toggle", width = "full", name = L["Aqirite"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[97] end, set = function() Nx.db.profile.Guide.ShowMines[97] = not Nx.db.profile.Guide.ShowMines[97] end },
                        m87 = { order = 1002, type = "toggle", width = "full", name = L["Bismuth"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[87] end, set = function() Nx.db.profile.Guide.ShowMines[87] = not Nx.db.profile.Guide.ShowMines[87] end },
                        m92 = { order = 1003, type = "toggle", width = "full", name = L["Ironclaw"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[92] end, set = function() Nx.db.profile.Guide.ShowMines[92] = not Nx.db.profile.Guide.ShowMines[92] end },
                        m102 = { order = 1004, type = "toggle", width = "full", name = L["Webbed Ore Deposit"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[102] end, set = function() Nx.db.profile.Guide.ShowMines[102] = not Nx.db.profile.Guide.ShowMines[102] end },
                        m98 = { order = 1010, type = "toggle", width = "full", name = "  " .. L["Crystallized Aqirite"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[98] end, set = function() Nx.db.profile.Guide.ShowMines[98] = not Nx.db.profile.Guide.ShowMines[98] end },
                        m88 = { order = 1011, type = "toggle", width = "full", name = "  " .. L["Crystallized Bismuth"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[88] end, set = function() Nx.db.profile.Guide.ShowMines[88] = not Nx.db.profile.Guide.ShowMines[88] end },
                        m93 = { order = 1012, type = "toggle", width = "full", name = "  " .. L["Crystallized Ironclaw"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[93] end, set = function() Nx.db.profile.Guide.ShowMines[93] = not Nx.db.profile.Guide.ShowMines[93] end },
                        m99 = { order = 1013, type = "toggle", width = "full", name = "  " .. L["EZ-Mine Aqirite"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[99] end, set = function() Nx.db.profile.Guide.ShowMines[99] = not Nx.db.profile.Guide.ShowMines[99] end },
                        m89 = { order = 1014, type = "toggle", width = "full", name = "  " .. L["EZ-Mine Bismuth"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[89] end, set = function() Nx.db.profile.Guide.ShowMines[89] = not Nx.db.profile.Guide.ShowMines[89] end },
                        m94 = { order = 1015, type = "toggle", width = "full", name = "  " .. L["EZ-Mine Ironclaw"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[94] end, set = function() Nx.db.profile.Guide.ShowMines[94] = not Nx.db.profile.Guide.ShowMines[94] end },
                        m100 = { order = 1016, type = "toggle", width = "full", name = "  " .. L["Rich Aqirite"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[100] end, set = function() Nx.db.profile.Guide.ShowMines[100] = not Nx.db.profile.Guide.ShowMines[100] end },
                        m90 = { order = 1017, type = "toggle", width = "full", name = "  " .. L["Rich Bismuth"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[90] end, set = function() Nx.db.profile.Guide.ShowMines[90] = not Nx.db.profile.Guide.ShowMines[90] end },
                        m95 = { order = 1018, type = "toggle", width = "full", name = "  " .. L["Rich Ironclaw"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[95] end, set = function() Nx.db.profile.Guide.ShowMines[95] = not Nx.db.profile.Guide.ShowMines[95] end },
                        m101 = { order = 1019, type = "toggle", width = "full", name = "  " .. L["Weeping Aqirite"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[101] end, set = function() Nx.db.profile.Guide.ShowMines[101] = not Nx.db.profile.Guide.ShowMines[101] end },
                        m91 = { order = 1020, type = "toggle", width = "full", name = "  " .. L["Weeping Bismuth"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[91] end, set = function() Nx.db.profile.Guide.ShowMines[91] = not Nx.db.profile.Guide.ShowMines[91] end },
                        m96 = { order = 1021, type = "toggle", width = "full", name = "  " .. L["Weeping Ironclaw"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[96] end, set = function() Nx.db.profile.Guide.ShowMines[96] = not Nx.db.profile.Guide.ShowMines[96] end },
                        -- ============================================
                        -- MIDNIGHT
                        -- ============================================
                        mhdrMidnight = { order = 1100, type = "header", name = "|cffaa00ffMidnight|r", hidden = function() return not Nx.isRetail end },
                        m103 = { order = 1101, type = "toggle", width = "full", name = L["Brilliant Silver"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[103] end, set = function() Nx.db.profile.Guide.ShowMines[103] = not Nx.db.profile.Guide.ShowMines[103] end },
                        m104 = { order = 1102, type = "toggle", width = "full", name = L["Refulgent Copper"], hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[104] end, set = function() Nx.db.profile.Guide.ShowMines[104] = not Nx.db.profile.Guide.ShowMines[104] end },
                        m105 = { order = 1103, type = "toggle", width = "full", name = L["Umbral Tin"],       hidden = function() return not Nx.isRetail end, get = function() return Nx.db.profile.Guide.ShowMines[105] end, set = function() Nx.db.profile.Guide.ShowMines[105] = not Nx.db.profile.Guide.ShowMines[105] end },
                    },
                },
                TimberDisp = {
                    order = 5,
                    type = "group",
                    name = L["Timber"],
                    hidden = function() return not Nx.isRetail end,
                    args = {
                        tenableall = {
                            order = 1,
                            type = "execute",
                            width = "double",
                            name = L["Enable All"],
                            func = function()
                                for i = 1,3 do
                                    Nx.db.profile.Guide.ShowTimber[i] = true
                                end
                            end,
                        },
                        tdisableall = {
                            order = 2,
                            type = "execute",
                            width = "double",
                            name = L["Disable All"],
                            func = function()
                                for i = 1,3 do
                                    Nx.db.profile.Guide.ShowTimber[i] = false
                                end
                            end,
                        },
                        small = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Small Timber"],
                            desc = L["Display"] .. " " .. L["Small Timber"] .. " " .. L["Nodes On Map"],
                            get = function()
                                return Nx.db.profile.Guide.ShowTimber[1]
                            end,
                            set = function()
                                Nx.db.profile.Guide.ShowTimber[1] = not Nx.db.profile.Guide.ShowTimber[1]
                            end,
                        },
                        med = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Medium Timber"],
                            desc = L["Display"] .. " " .. L["Medium Timber"] .. " " .. L["Nodes On Map"],
                            get = function()
                                return Nx.db.profile.Guide.ShowTimber[2]
                            end,
                            set = function()
                                Nx.db.profile.Guide.ShowTimber[2] = not Nx.db.profile.Guide.ShowTimber[2]
                            end,
                        },
                        large = {
                            order = 5,
                            type = "toggle",
                            width = "full",
                            name = L["Large Timber"],
                            desc = L["Display"] .. " " .. L["Large Timber"] .. " " .. L["Nodes On Map"],
                            get = function()
                                return Nx.db.profile.Guide.ShowTimber[3]
                            end,
                            set = function()
                                Nx.db.profile.Guide.ShowTimber[3] = not Nx.db.profile.Guide.ShowTimber[3]
                            end,
                        },
                    },
                },
            },
        }
    end
    return guidegather
end

-------------------------------------------------------------------------------
-- MENU OPTIONS
-- Context menu positioning settings
-------------------------------------------------------------------------------

local menuoptions

---
-- Get or create menu options configuration
-- @return  Menu options table
--
local function menuConfig()
    if not menuoptions then
        menuoptions = {
            type = "group",
            name = L["Menu Options"],
            args = {
                menuCenterX = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L["Center Menus Horizontally On Cursor"],
                    desc = L["When Enabled, Carbonite Menus Will Be Drawn Horizontally Centered On The Mouse"],
                    get = function()
                        return Nx.db.profile.Menu.CenterH
                    end,
                    set = function()
                        Nx.db.profile.Menu.CenterH = not Nx.db.profile.Menu.CenterH
                    end,
                },
                menuCenterY = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = L["Center Menus Vertically On Cursor"],
                    desc = L["When Enabled, Carbonite Menus Will Be Drawn Vertically Centered On The Mouse"],
                    get = function()
                        return Nx.db.profile.Menu.CenterV
                    end,
                    set = function()
                        Nx.db.profile.Menu.CenterV = not Nx.db.profile.Menu.CenterV
                    end,
                },
            },
        }
    end
    return menuoptions
end

-------------------------------------------------------------------------------
-- COMMUNICATION/PRIVACY OPTIONS
-- Settings for sharing position with friends/guild
-------------------------------------------------------------------------------

local commoptions

---
-- Get or create communication options configuration
-- @return  Communication options table
--
local function commConfig()
    if not commoptions then
        commoptions = {
            type = "group",
            name = L["Privacy Options"],
            args = {
                commLTF = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L["Send Position & Level Ups To Friends"],
                    desc = L["When Enabled, Carbonite will send your current location and any levelups you get to your other friends using carbonite"],
                    get = function()
                        return Nx.db.profile.Comm.SendToFriends
                    end,
                    set = function()
                        Nx.db.profile.Comm.SendToFriends = not Nx.db.profile.Comm.SendToFriends
                    end,
                },
                commLTG = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = L["Send Position & Level Ups To Guild"],
                    desc = L["When Enabled, Carbonite will send your current location and any levelups you get to your other guildmates using carbonite"],
                    get = function()
                        return Nx.db.profile.Comm.SendToGuild
                    end,
                    set = function()
                        Nx.db.profile.Comm.SendToGuild = not Nx.db.profile.Comm.SendToGuild
                    end,
                },
                commLTZ = {
                    order = 3,
                    type = "toggle",
                    width = "full",
                    name = L["Send Position & Level Ups To Zone"],
                    desc = L["When Enabled, Carbonite will send your current location and any levelups you get to other carbonite useres in your current zone"],
                    get = function()
                        return Nx.db.profile.Comm.SendToZone
                    end,
                    set = function()
                        Nx.db.profile.Comm.SendToZone = not Nx.db.profile.Comm.SendToZone
                    end,
                },
                commShowLevel = {
                    order = 4,
                    type = "toggle",
                    width = "full",
                    name = L["Show Received Levelups"],
                    desc = L["When Enabled, Carbonite will show a message in chat whenever it gets a notice someone leveled up"],
                    get = function()
                        return Nx.db.profile.Comm.LvlUpShow
                    end,
                    set = function()
                        Nx.db.profile.Comm.LvlUpShow = not Nx.db.profile.Comm.LvlUpShow
                    end,
                },
                commDisG = {
                    order = 5,
                    type = "toggle",
                    width = "full",
                    name = L["Enable Global Channel (Used for version checks/notices)"],
                    desc = L["When Enabled, Carbonite will listen on a global channel for versions others are using so it can tell you if an update is available"],
                    get = function()
                        return Nx.db.profile.Comm.Global
                    end,
                    set = function()
                        Nx.db.profile.Comm.Global = not Nx.db.profile.Comm.Global
                    end,
                },
                commDisZ = {
                    order = 6,
                    type = "toggle",
                    width = "full",
                    name = L["Enable Zone Channel (Used for locations of others in your zone)"],
                    desc = L["When Enabled, Carbonite will send your current location and listen for messages from others who are in the same zone as you"],
                    get = function()
                        return Nx.db.profile.Comm.Zone
                    end,
                    set = function()
                        Nx.db.profile.Comm.Zone = not Nx.db.profile.Comm.Zone
                    end,
                },

            },
        }
    end
    return commoptions
end

-------------------------------------------------------------------------------
-- SKIN OPTIONS
-- Window theme, border color, and background color settings
-------------------------------------------------------------------------------

local skinoptions

---
-- Get or create skin options configuration
-- @return  Skin options table
--
local function skinConfig()
    if not skinoptions then
        skinoptions = {
            type = "group",
            name = L["Skin Options"],
            args = {
                SkinSelect = {
                    order = 1,
                    type = "select",
                    name = L["Current Skin"],
                    desc = L["Sets the current skin for carbonite windows"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("Skins")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Skin.Name) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("Skins")
                        Nx.db.profile.Skin.Name = vals[name]
                        if vals[name] == "Default" then
                            Nx.db.profile.Skin.Name = ""
                        end
                        Nx.Skin:Set(Nx.db.profile.Skin.Name)
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("Skins")
                    end,
                },
                skinBord = {
                    order = 2,
                    type = "color",
                    width = "full",
                    name = L["Border Color of Windows"],
                    hasAlpha = true,
                    get = function()
                        local arr = { Nx.Split("|",Nx.db.profile.Skin.WinBdColor) }
                        local r = arr[1]
                        local g = arr[2]
                        local b = arr[3]
                        local a = arr[4]
                        return r,g,b,tonumber(a)
                    end,
                    set = function(_,r,g,b,a)
                        Nx.db.profile.Skin.WinBdColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                        Nx.Skin:Update()
                    end,
                },
                skinFixBG = {
                    order = 3,
                    type = "color",
                    width = "full",
                    name = L["Background Color of Fixed Sized Windows"],
                    hasAlpha = true,
                    get = function()
                        local arr = { Nx.Split("|",Nx.db.profile.Skin.WinFixedBgColor) }
                        local r = arr[1]
                        local g = arr[2]
                        local b = arr[3]
                        local a = arr[4]
                        return r,g,b,tonumber(a)
                    end,
                    set = function(_,r,g,b,a)
                        Nx.db.profile.Skin.WinFixedBgColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                        Nx.Skin:Update()
                    end,
                },
                skinSizeBG = {
                    order = 4,
                    type = "color",
                    width = "full",
                    name = L["Background Color of Resizable Windows"],
                    hasAlpha = true,
                    get = function()
                        local arr = { Nx.Split("|",Nx.db.profile.Skin.WinSizedBgColor) }
                        local r = arr[1]
                        local g = arr[2]
                        local b = arr[3]
                        local a = arr[4]
                        return r,g,b,tonumber(a)
                    end,
                    set = function(_,r,g,b,a)
                        Nx.db.profile.Skin.WinSizedBgColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                        Nx.Skin:Update()
                    end,
                },

            },
        }
    end
    return skinoptions
end

-------------------------------------------------------------------------------
-- TRACKING HUD OPTIONS
-- Waypoint arrow and HUD display settings
-------------------------------------------------------------------------------

local trackoptions

---
-- Get or create tracking HUD options configuration
-- @return  Tracking options table
--
local function trackConfig()
    if not trackoptions then
        trackoptions = {
            type = "group",
            name = L["Tracking Options"],
            args = {
                hideHUD = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L["Hide Tracking HUD"],
                    desc = L["When Enabled, Carbonite will hide the tracking hud from display"],
                    get = function()
                        return Nx.db.profile.Track.Hide
                    end,
                    set = function()
                        Nx.db.profile.Track.Hide = not Nx.db.profile.Track.Hide
                    end,
                },
                hideHUDBG = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = L["Hide Tracking HUD in BG's"],
                    desc = L["When Enabled, Carbonite will hide the tracking hud from display in Battlegrounds"],
                    get = function()
                        return Nx.db.profile.Track.HideInBG
                    end,
                    set = function()
                        Nx.db.profile.Track.HideInBG = not Nx.db.profile.Track.HideInBG
                    end,
                },
                hideLock = {
                    order = 3,
                    type = "toggle",
                    width = "full",
                    name = L["Lock Tracking HUD Position"],
                    desc = L["When Enabled, Carbonite will lock the Tracking HUD in position"],
                    get = function()
                        return Nx.db.profile.Track.Lock
                    end,
                    set = function()
                        Nx.db.profile.Track.Lock = not Nx.db.profile.Track.Lock
                        Nx.HUD:UpdateOptions()
                    end,
                },
                TrackArrow = {
                    order = 4,
                    type = "select",
                    name = L["Tracking HUD Arrow Graphic"],
                    desc = L["Sets the current arrow to be used in the tracking hud"],
                    get    = function()
                        local vals = Nx.Opts:CalcChoices("HUDAGfx")
                        for a,b in pairs(vals) do
                          if (b == Nx.db.profile.Track.AGfx) then
                             return a
                          end
                        end
                        return ""
                    end,
                    set    = function(info, name)
                        local vals = Nx.Opts:CalcChoices("HUDAGfx")
                        Nx.db.profile.Track.AGfx = vals[name]
                        Nx.HUD:UpdateOptions()
                    end,
                    values    = function()
                        return Nx.Opts:CalcChoices("HUDAGfx")
                    end,
                },
                spacer = {
                    order = 5,
                    type = "description",
                    width = "double",
                    name = "",
                },
                ArrowSize = {
                    order = 6,
                    type = "range",
                    name = L["Arrow Size"],
                    desc = L["Sets the number of size of the tracking hud arrow."],
                    min = 8,
                    max = 100,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Track.ASize
                    end,
                    set = function(info,value)
                        Nx.db.profile.Track.ASize = value
                        Nx.HUD:UpdateOptions()
                    end,
                },
                AXO = {
                    order = 7,
                    type = "range",
                    name = L["Arrow X Offset"],
                    desc = L["Sets the X offset of the tracking hud arrow."],
                    min = -100,
                    max = 100,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Track.AXO
                    end,
                    set = function(info,value)
                        Nx.db.profile.Track.AXO = value
                        Nx.HUD:UpdateOptions()
                    end,
                },
                AYO = {
                    order = 8,
                    type = "range",
                    name = L["Arrow Y Offset"],
                    desc = L["Sets the Y offset of the tracking hud arrow."],
                    min = -100,
                    max = 100,
                    step = 1,
                    bigStep = 1,
                    get = function()
                        return Nx.db.profile.Track.AYO
                    end,
                    set = function(info,value)
                        Nx.db.profile.Track.AYO = value
                        Nx.HUD:UpdateOptions()
                    end,
                },
                showText = {
                    order = 9,
                    type = "toggle",
                    width = "full",
                    name = L["Show Direction Text"],
                    desc = L["When Enabled, shows additional direction text in the hud"],
                    get = function()
                        return Nx.db.profile.Track.ShowDir
                    end,
                    set = function()
                        Nx.db.profile.Track.ShowDir = not Nx.db.profile.Track.ShowDir
                        Nx.HUD:UpdateOptions()
                    end,
                },
                addTbut = {
                    order = 10,
                    type = "toggle",
                    width = "full",
                    name = L["Enable Target Button"],
                    desc = L["When Enabled, Adds a target button to the tracking hud"],
                    get = function()
                        return Nx.db.profile.Track.TBut
                    end,
                    set = function()
                        Nx.db.profile.Track.TBut = not Nx.db.profile.Track.TBut
                        Nx.HUD:UpdateOptions()
                    end,
                },
                Tbutcol = {
                    order = 11,
                    type = "color",
                    width = "full",
                    name = L["Color of target button"],
                    hasAlpha = true,
                    get = function()
                        local arr = { Nx.Split("|",Nx.db.profile.Track.TButColor) }
                        local r = arr[1]
                        local g = arr[2]
                        local b = arr[3]
                        local a = arr[4]
                        return r,g,b,tonumber(a)
                    end,
                    set = function(_,r,g,b,a)
                        Nx.db.profile.Track.TButColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                        Nx.HUD:UpdateOptions()
                    end,
                },
                Tbutcomcol = {
                    order = 12,
                    type = "color",
                    width = "full",
                    name = L["Color of target button in combat"],
                    hasAlpha = true,
                    get = function()
                        local arr = { Nx.Split("|",Nx.db.profile.Track.TButCombatColor) }
                        local r = arr[1]
                        local g = arr[2]
                        local b = arr[3]
                        local a = arr[4]
                        return r,g,b,tonumber(a)
                    end,
                    set = function(_,r,g,b,a)
                        Nx.db.profile.Track.TButCombatColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                        Nx.Skin:Update()
                    end,
                },
                addsound = {
                    order = 13,
                    type = "toggle",
                    width = "full",
                    name = L["Enable Target Reached Sound"],
                    desc = L["When Enabled, Plays a sound when you reach your target destination"],
                    get = function()
                        return Nx.db.profile.Track.TSoundOn
                    end,
                    set = function()
                        Nx.db.profile.Track.TSoundOn = not Nx.db.profile.Track.TSoundOn
                        Nx.HUD:UpdateOptions()
                    end,
                },
                spacer2 = {
                    order = 14,
                    type = "description",
                    width = "full",
                    name = " ",
                },
                autopals = {
                    order = 15,
                    type = "toggle",
                    width = "full",
                    name = L["Auto Track Pals In BattleGrounds"],
                    desc = L["When Enabled, Will auto track your friends in battleground"],
                    get = function()
                        return Nx.db.profile.Track.ATBGPal
                    end,
                    set = function()
                        Nx.db.profile.Track.ATBGPal = not Nx.db.profile.Track.ATBGPal
                    end,
                },
                autotaxi = {
                    order = 16,
                    type = "toggle",
                    width = "full",
                    name = L["Auto Track Taxi Destination"],
                    desc = L["When Enabled, Will automatically track your taxi destination"],
                    get = function()
                        return Nx.db.profile.Track.ATTaxi
                    end,
                    set = function()
                        Nx.db.profile.Track.ATTaxi = not Nx.db.profile.Track.ATTaxi
                        Nx.HUD:UpdateOptions()
                    end,
                },
                autocorpse = {
                    order = 17,
                    type = "toggle",
                    width = "full",
                    name = L["Auto Track Corpse"],
                    desc = L["When Enabled, Will automatically track your corpse upon death"],
                    get = function()
                        return Nx.db.profile.Track.ATCorpse
                    end,
                    set = function()
                        Nx.db.profile.Track.ATCorpse = not Nx.db.profile.Track.ATCorpse
                        Nx.HUD:UpdateOptions()
                    end,
                },
                spacer3 = {
                    order = 18,
                    type = "description",
                    width = "full",
                    name = " ",
                },
                emutomtom = {
                    order = 19,
                    type = "toggle",
                    width = "full",
                    name = L["Enable TomTom Emulation"],
                    desc = L["When Enabled, Attempts to emulate tomtom's features (requires reload)"],
                    get = function()
                        return Nx.db.profile.Track.EmuTomTom
                    end,
                    set = function()
                        Nx.db.profile.Track.EmuTomTom = not Nx.db.profile.Track.EmuTomTom
                        Nx.HUD:UpdateOptions()
                    end,
                },
            },
        }
    end
    return trackoptions
end
---
-- Hand every NxOptions section to the new Carbonite.Modules.Options
-- module so they appear under the single unified Carbonite options
-- panel instead of each section getting its own Blizzard panel.
-- The new Options module owns the AceConfig:RegisterOptionsTable call
-- and the AddToBlizOptions root; this file just contributes section
-- providers.
--
function Nx:SetupConfig()
    local Options = _G.Carbonite and _G.Carbonite.GetModule and _G.Carbonite:GetModule("Options", true)
    if not Options then
        -- Fallback to legacy registration if the new module hasn't loaded
        -- (e.g. during an unmigrated TOC load order).
        AceConfig:RegisterOptionsTable("Carbonite", mainConfig)
        Nx.optionsFrame, Nx.optionsPanelID = AceConfigDialog:AddToBlizOptions("Carbonite", "Carbonite", nil, "main")
        Nx:AddToConfig("General",       generalOptions(),     L["General"])
        Nx:AddToConfig("Battlegrounds", BGConfig(),           L["Battlegrounds"])
        Nx:AddToConfig("Fonts",         fontConfig(),         L["Fonts"])
        Nx:AddToConfig("Guide & Gather",guidegatherConfig(),  L["Guide & Gather"])
        Nx:AddToConfig("Maps",          mapConfig(),          L["Maps"])
        Nx:AddToConfig("Menus",         menuConfig(),         L["Menus"])
        Nx:AddToConfig("Privacy",       commConfig(),         L["Privacy"])
        Nx:AddToConfig("Profiles",      profilesConfig(),     L["Profiles"])
        Nx:AddToConfig("Skin",          skinConfig(),         L["Skin"])
        Nx:AddToConfig("Tracking HUD",  trackConfig(),        L["Tracking HUD"])
        return
    end

    -- The legacy mainConfig() returns a wrapped "Carbonite Classic"
    -- group with a child "main" that holds the version blurb / credits.
    -- Strip the outer wrapper so the new unified panel uses that block
    -- as its own About tab.
    Options:Register("Main", function()
        local m = mainConfig()
        return (m and m.args and m.args.main) or { type = "group", name = L["Main Options"], args = {} }
    end, { displayName = L["Main Options"], order = 0 })

    Options:Register("General",        generalOptions,    { displayName = L["General"],        order = 1 })
    Options:Register("Battlegrounds",  BGConfig,          { displayName = L["Battlegrounds"],  order = 5 })
    Options:Register("Fonts",          fontConfig,        { displayName = L["Fonts"],          order = 60 })
    Options:Register("Guide & Gather", guidegatherConfig, { displayName = L["Guide & Gather"], order = 35 })
    Options:Register("Maps",           mapConfig,         { displayName = L["Maps"],           order = 10 })
    Options:Register("Menus",          menuConfig,        { displayName = L["Menus"],          order = 65 })
    Options:Register("Privacy",        commConfig,        { displayName = L["Privacy"],        order = 70 })
    Options:Register("Skin",           skinConfig,        { displayName = L["Skin"],           order = 55 })
    Options:Register("Tracking HUD",   trackConfig,       { displayName = L["Tracking HUD"],   order = 20 })

    -- Plugin/legacy compatibility: Nx.optionsFrame is read by NxFav,
    -- NxWarehouse, and NxQuest as a way to "have somewhere to anchor
    -- a sub-panel onto". Provide a stub object so those reads do not
    -- nil-out; the new Options module makes a single unified panel
    -- and does not need per-section frames.
    Nx.optionsFrame = setmetatable({}, { __index = function() return Options.frame end })
    Nx.optionsPanelID = Options.panelID
end

---
-- Plugin entry point: a sibling addon (Notes, Warehouse, Quest, etc.)
-- registers its options page here. The new Options module is the
-- canonical owner; this function forwards on for backwards compat.
--
function Nx:AddToConfig(name, optionsTable, displayName)
    modular_config[name] = optionsTable
    local Options = _G.Carbonite and _G.Carbonite.GetModule and _G.Carbonite:GetModule("Options", true)
    if Options then
        Options:Register(name, optionsTable, { displayName = displayName or name })
        Nx.optionsFrame = Nx.optionsFrame or setmetatable({}, { __index = function() return Options.frame end })
        Nx.optionsFrame[name] = Options.frame
        return
    end
    -- Legacy fallback when new module is not present.
    if Nx.optionsFrame then
        Nx.optionsFrame[name] = AceConfigDialog:AddToBlizOptions("Carbonite", displayName, "Carbonite", name)
    end
end

---
-- Get profiles options table
-- @return  AceDBOptions profiles table
--
local function giveProfiles()
    return LibStub("AceDBOptions-3.0"):GetOptionsTable(Nx.db)
end

-------------------------------------------------------------------------------
-- SOUND DATA
-- Sound file paths for notifications
-------------------------------------------------------------------------------

Nx.OptsDataSounds = {
    "Interface\\AddOns\\Carbonite\\Snd\\QuestComplete.ogg",
    "Sound\\Creature\\Peon\\PeonBuildingComplete1.ogg",
    "Sound\\Character\\Scourge\\ScourgeVocalMale\\UndeadMaleCongratulations02.ogg",
    "Sound\\Character\\Human\\HumanVocalFemale\\HumanFemaleCongratulations01.ogg",
    "Sound\\Character\\Dwarf\\DwarfVocalMale\\DwarfMaleCongratulations04.ogg",
    "Sound\\Character\\Gnome\\GnomeVocalMale\\GnomeMaleCongratulations03.ogg",
    "Sound\\Creature\\Tauren\\TaurenYes3.ogg",
    "Sound\\Creature\\UndeadMaleWarriorNPC\\UndeadMaleWarriorNPCGreeting01.ogg",
}

-- Sound file IDs for modern WoW sound system
Nx.OptsDataSoundsIDs = {
    "Interface\\AddOns\\Carbonite\\Snd\\QuestComplete.ogg",  -- Interface path, no conversion needed
    558132,
    542775,
    540654,
    540042,
    540512,
    561484,
    563198,
}

-------------------------------------------------------------------------------
-- OPTIONS INITIALIZATION
-- Setup and initialization functions
-------------------------------------------------------------------------------

---
-- Initialize options data
-- Called before UI init to set up choice tables
--
function Nx.Opts:Init()

    self.ChoicesAnchor = {
        "TopLeft", "Top", "TopRight",
        "Left", "Center", "Right",
        "BottomLeft", "Bottom", "BottomRight",
    }
    self.ChoicesAnchor0 = {
        "None",
        "TopLeft", "Top", "TopRight",
        "Left", "Center", "Right",
        "BottomLeft", "Bottom", "BottomRight",
    }
    self.Skins = {
        "Modern Dark","Modern Light","Glass","Class Color","Faction",
        "Blackout","Blackout Blues","Dialog Blue",
        "Dialog Gold","Simple Blue","Stone","Tool Blue",
    }
    self.ChoicesCorner = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", }

    self.ChoicesQArea = {
        "Solid", "SolidTexture", "HGrad",
    }
    self.ChoicesQAreaTex = {
        ["SolidTexture"] = "Interface\\Buttons\\White8x8",
        ["HGrad"] = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\AreaGrad",
    }

    self:Reset (true)
    self:UpdateCom()

    OptsInit = Nx:ScheduleTimer(self.InitTimer, .5, self)

--    Nx.prt ("cvar %s", GetCVar ("farclip") or "nil")

--    RegisterCVar ("dog", "hi")
--    Nx.prt ("dog %s", GetCVar ("dog") or "nil")
end

--------
-- Init timer

function Nx.Opts:InitTimer()

--    Nx.prt ("cvar %s", GetCVar ("farclip") or "nil")

--    Nx.prt ("dog2 %s", GetCVar ("dog") or "nil")

    self:NXCmdGryphonsUpdate()
    self:NXCmdCamForceMaxDist()

    OptsQO = Nx:ScheduleTimer(self.QuickOptsTimer,2,self)
end

--------
-- Show quick options timer

function Nx.Opts:QuickOptsTimer()

    local i = Nx.db.profile.Version.QuickVer or 0

    local ver = 5

    Nx.db.profile.Version.QuickVer = ver

    if i < ver then

        local function func()
            Nx.db.profile.MiniMap.Own = true
            Nx.db.profile.MiniMap.ButOwn = true
            Nx.db.profile.MiniMap.ShowOldNameplate = false
            ReloadUI()
        end

        local s = L["Put the game minimap into the Carbonite map?\n\nThis will make one unified map. The minimap buttons will go into the Carbonite button window. This can also be changed using the Map Minimap options page."]

        Nx:ShowMessage (s, L["Yes"], func, L["No"])
    end

    -- Suggest compressed maps addon for retail (one-time dialog)
    if Nx.isRetail and not Nx.GetCarboniteMediaPath then
        local mediaVer = Nx.db.profile.Version.MediaAddonNotice or 0
        local gameLocale = GetLocale()
        if gameLocale == "zhCN" or locale == "zhTW" or gameLocale == "esMX" then
            gameLocale = string.upper(string.sub(GetLocale(), -2))
        else
            gameLocale = string.upper(string.sub(GetLocale(), 1, 2))
        end
        if mediaVer < 1 then
            Nx.db.profile.Version.MediaAddonNotice = 1
            Nx:ShowMessage(format(L["Consider installing Carbonite.Combined.Maps.%s addon to gain FPS using compressed maps."], gameLocale), L["Ok"])
        end
        -- Also print to chat
        Nx.prt(L["Consider installing Carbonite.Combined.Maps.%s addon to gain FPS using compressed maps."], gameLocale)
    end
end

--------
-- Reset options (can be called before Init)

function Nx.Opts:Reset (onlyNew)
    self.COpts = Nx.CurCharacter["Opts"]
    self.Opts = Nx.db.profile

    if not onlyNew then
        Nx.prt (L["Reset global options"])
        Nx.db:ResetDB("Default")
    end
end

--------
-- Open options
function Nx.Opts:Open (pageName)
    -- Use the registered options frame
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(AceConfigDialog.BlizOptionsIDMap["Carbonite"])
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- Classic fallback
        if Nx.optionsFrame then
            InterfaceOptionsFrame_OpenToCategory(Nx.optionsFrame)
            InterfaceOptionsFrame_OpenToCategory(Nx.optionsFrame)
        end
    end
end


function Nx.Opts:Create()

    -- Create Window

    local win = Nx.Window:Create ("NxOpts", nil, nil, nil, 1)
    self.Win = win
    local frm = win.Frm

    win:CreateButtons (true, true)
    win:InitLayoutData (nil, -.25, -.1, -.5, -.7)

    tinsert (UISpecialFrames, frm:GetName())

    frm:SetToplevel (true)

    win:SetTitle (Nx.TXTBLUE.."CARBONITE " .. Nx.VERSION .. "|cffffffff Options")

    -- Page list

    local listW = 115

    local list = Nx.List:Create (false, 0, 0, 1, 1, frm)
    self.PageList = list

    list:SetUser (self, self.OnPageListEvent)
    win:Attach (list.Frm, 0, listW, 0, 1)

    list:SetLineHeight (8)

    list:ColumnAdd ("Page", 1, listW)

    for k, t in ipairs (Nx.OptsData) do

        list:ItemAdd (k)
        list:ItemSet (1, t.N)
    end

    self.PageSel = 1

    -- Item list

    Nx.List:SetCreateFont ("Font.Medium", 24)

    local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm)
    self.List = list

    list:SetUser (self, self.OnListEvent)

    list:SetLineHeight (12, 3)

    list:ColumnAdd ("", 1, 40)
    list:ColumnAdd ("", 2, 900)

    win:Attach (list.Frm, listW, 1, 0, 1)

    --

    self:Update()
end

-------------------------------------------------------------------------------
-- COMMAND FUNCTIONS
-- Functions called when options are changed
-------------------------------------------------------------------------------

---
-- Import favorites from Cartographer addon
--
function Nx.Opts:NXCmdFavCartImport()
    Nx.Notes:CartImportNotes()
end

---
-- Apply font changes to all UI elements
--
function Nx.Opts:NXCmdFontChange()
    Nx.Font:Update()
end

---
-- Apply camera distance override if enabled
--
function Nx.Opts:NXCmdCamForceMaxDist()
    if Nx.db.profile.General.CameraForceMaxDist then
        SetCVar("cameraDistanceMaxZoomFactor", 2.6)
    end
end

---
-- Show or hide action bar gryphon graphics
--
function Nx.Opts:NXCmdGryphonsUpdate()
    if not Nx.isRetail then
        if Nx.db.profile.General.GryphonsHide then
            MainMenuBarLeftEndCap:Hide()
            MainMenuBarRightEndCap:Hide()
        else
            MainMenuBarLeftEndCap:Show()
            MainMenuBarRightEndCap:Show()
        end
    end
end

---
-- Delete all herbalism gather locations (with confirmation)
--
function Nx.Opts:NXCmdDeleteHerb()
    local function func()
        Nx:GatherDeleteHerb()
    end
    Nx:ShowMessage(L["Delete Herbalism Gather Locations"] .. "?", L["Delete"], func, L["Cancel"])
end

---
-- Delete all mining gather locations (with confirmation)
--
function Nx.Opts:NXCmdDeleteMine()
    local function func()
        Nx:GatherDeleteMine()
    end
    Nx:ShowMessage(L["Delete Mining Gather Locations"] .. "?", L["Delete"], func, L["Cancel"])
end

---
-- Delete all timber gather locations (with confirmation)
--
function Nx.Opts:NXCmdDeleteTimber()
    local function func()
        Nx:GatherDeleteTimber()
    end
    Nx:ShowMessage(L["Delete Timber Gather Locations"] .. "?", L["Delete"], func, L["Cancel"])
end

---
-- Delete all misc gather locations (with confirmation)
--
function Nx.Opts:NXCmdDeleteMisc()
    local function func()
        Nx:GatherDeleteMisc()
    end
    Nx:ShowMessage(L["Delete Misc Gather Locations"] .. "?", L["Delete"], func, L["Cancel"])
end

function Nx.Opts:NXCmdImportCarbHerb()

    local function func()
        Nx:GatherImportCarbHerb()
    end
    Nx:ShowMessage (L["Import Herbs"] .. "?", L["Import"], func, L["Cancel"])
end

function Nx.Opts:NXCmdImportCarbMine()

    local function func()
        Nx:GatherImportCarbMine()
    end
    Nx:ShowMessage (L["Import Mining"] .. "?", L["Import"], func, L["Cancel"])
end

function Nx.Opts:NXCmdImportCarbMisc()

    local function func()
        Nx:GatherImportCarbMisc()
    end
    Nx:ShowMessage (L["Import Misc"] .. "?", L["Import"], func, L["Cancel"])
end

--[[
function Nx.Opts:NXCmdImportCartHerb()

    local function func()
        Nx:GatherImportCartHerb()
    end
    Nx:ShowMessage ("Import Herbs?", "Import", func, "Cancel")
end

function Nx.Opts:NXCmdImportCartMine()

    local function func()
        Nx:GatherImportCartMine()
    end
    Nx:ShowMessage ("Import Mining?", "Import", func, "Cancel")
end
--]]

function Nx.Opts:NXCmdInfoWinUpdate()
    if Nx.Info then
        Nx.Info:OptionsUpdate()
    end
end

function Nx.Opts:NXCmdMMOwnChange (item, var)
    Nx.db.profile.MiniMap.ShowOldNameplate = not var        -- Nameplate is opposite of integration
    Nx.db.profile.MiniMap.ButOwn = var
    self:Update()
    self:NXCmdReload()
end

function Nx.Opts:NXCmdMMButUpdate()
    Nx.Map:MinimapButtonShowUpdate()
    Nx.Map.Dock:UpdateOptions()
end

-- Generic minimap change

function Nx.Opts:NXCmdMMChange()
    local map = Nx.Map:GetMap (1)
    map:MinimapNodeGlowInit (true)
end

function Nx.Opts:NXCmdMapToolBarUpdate()
    local map = Nx.Map:GetMap (1)
    map:UpdateToolBar()
end

--function Nx.Opts:NXCmdWatchFont()
--    Nx.Quest.Watch:SetFont()
--end

function Nx.Opts:NXCmdQWFadeAll (item, var)
    Nx.Quest.Watch:WinUpdateFade (var and Nx.Quest.Watch.Win:GetFade() or 1, true)
end

function Nx.Opts:NXCmdQWHideRaid()
    Nx.Quest.Watch.Win.Frm:Show()
end

function Nx.Opts:NXCmdImportCharSettings()

    local function func (self, name)

        local function func()

--            Nx.prt ("OK %s", name)

            if Nx:CopyCharacterData (name, UnitName ("player")) then
                ReloadUI()
            end
        end

        Nx:ShowMessage (format ("Import %s character data and reload?", name), "Import", func, "Cancel")
    end

    local t = {}

    for rc in pairs (Nx.db.global.Characters) do
        tinsert (t, rc)
    end

    sort (t)

    Nx.DropDown:Start (self, func)
    Nx.DropDown:AddT (t, 1)
    Nx.DropDown:Show (self.List.Frm)
end

function Nx.Opts:NXCmdDeleteCharSettings()

    local function func (self, name)

        local function func()

--            Nx.prt ("OK %s", name)

            Nx:DeleteCharacterData (name)
        end

        Nx:ShowMessage (format ("Delete %s character data?", name), "Delete", func, "Cancel")
    end

    local rcName = Nx:GetRealmCharName()

    local t = {}

    for rc in pairs (Nx.db.global.Characters) do
        if rc ~= rcName then
            tinsert (t, rc)
        end
    end

    sort (t)

    Nx.DropDown:Start (self, func)
    Nx.DropDown:AddT (t, 1)
    Nx.DropDown:Show (self.List.Frm)
end

function Nx.Opts:NXCmdResetOpts()

    local function func()
        local self = Nx.Opts
        self:Reset()
        self:Update()
        Nx.Skin:Set()
        Nx.Font:Update()
        Nx.Quest:OptsReset()
        Nx.Quest:CalcWatchColors()
        self:NXCmdHUDChange()
        self:NXCmdGryphonsUpdate()
        self:NXCmdInfoWinUpdate()
        self:NXCmdUIChange()
    end

    Nx:ShowMessage (L["Reset options"] .. "?", "Reset", func, "Cancel")
end

function Nx.Opts:NXCmdResetWinLayouts()

    local function func()
        Nx.Window:ResetLayouts()
    end

    Nx:ShowMessage (L["Reset window layouts"] .. "?", "Reset", func, "Cancel")
end

function Nx.Opts:NXCmdResetWatchWinLayout()
    Nx.Quest.Watch.Win:ResetLayout()
end

function Nx.Opts:NXCmdReload()

    local function func()
        ReloadUI()
    end

    Nx:ShowMessage (L["Reload UI"] .. "?", L["Reload"], func, L["Cancel"])
end

function Nx.Opts:NXCmdHUDChange()
    Nx.HUD:UpdateOptions()
end

--------
-- Do simple call anytime UI changes

function Nx.Opts:NXCmdUIChange()
    Nx:prtSetChatFrame()
end

--------

function Nx.Opts:OnSetSize (w, h)

    Nx.Opts.FStr:SetWidth (w)
end

function Nx.Opts:OnPageListEvent (eventName, sel, val2)

    if eventName == "select" or eventName == "back" then
        self.PageSel = sel
        self:Update()
    end
end

function Nx.Opts:OnListEvent (eventName, sel, val2)

    local page = Nx.OptsData[self.PageSel]
    local item = page[sel]

    if eventName == "select" or eventName == "back" then

        if item then

            if type (item) == "table" then
                if item.F then
                    local var = self:GetVar (item.V)
                    Nx.Opts[item.F](self, item, var)
                end

                if item.V then
                    self:EditItem (item)
                end
            end
        end

    elseif eventName == "button" then

--        Nx.prt ("but %s", val2 and "T" or "F")

        if item then
            if type (item) == "table" then
                if item.V then
                    self:SetVar (item.V, val2)
                end
                if item.VF then
                    local var = self:GetVar (item.V)
                    Nx.Opts[item.VF](self, item, var)
                end
            end
        end

    elseif eventName == "color" then

        if item then
            if type (item) == "table" then
                if item.VF then
                    Nx.Opts[item.VF](self, item)
                end
            end
        end
    end

    self:Update()
end

-------------------------------------------------------------------------------
-- LIST UPDATE FUNCTIONS
-- Update options list display
-------------------------------------------------------------------------------

---
-- Update the options list display
-- Refreshes list items based on current page selection
--
function Nx.Opts:Update()

    local opts = self.Opts
    local list = self.List

    if not list then
        return
    end

    list:Empty()

    local page = Nx.OptsData[self.PageSel]

    for k, item in ipairs (page) do

        list:ItemAdd (k)

        if type (item) == "table" then

            if item.N then

                local col = "|cff9f9f9f"

                if item.F then                -- Function?
                    col = "|cff8fdf8f"
                elseif item.V then
                    col = "|cffdfdfdf"
                end

                local istr = format ("%s%s", col, item.N)

                if item.V then

                    local typ, pressed, tx = self:ParseVar (item.V)
                    if typ == "B" then

                        if pressed ~= nil then
                            local tip
                            list:ItemSetButton ("Opts", pressed, tx, tip)
                        end

                    elseif typ == "C" then

                        list:ItemSetColorButton (opts, item.V, true)

                    elseif typ == "RGB" then

                        list:ItemSetColorButton (opts, item.V, false)

                    elseif typ == "CH" then        -- Choice

                        local i = self:GetVar (item.V)
                        istr = format ("%s  |cffffff80%s", istr, i)

                    elseif typ == "F" then

                        local i = self:GetVar (item.V)
                        istr = format ("%s  |cffffff80%s", istr, i)

                    elseif typ == "I" then

                        local i = self:GetVar (item.V)
                        istr = format ("%s  |cffffff80%s", istr, i)

                    elseif typ == "S" then

                        local s = self:GetVar (item.V)
                        istr = format ("%s  |cffffff80%s", istr, s)

                    elseif typ == "Frm" then

--                        list:ItemSetFrame ("Color")

                    end
                end

                list:ItemSet (2, istr)
            end

        elseif type (item) == "string" then

            local col = "|cff9f9f9f"
            list:ItemSet (2, format ("%s%s", col, item))
        end
    end

    list:FullUpdate()

    self:UpdateCom()
end

function Nx.Opts:UpdateCom()

    local opts = self.Opts

    local mask = 0

    if Nx.db.profile.Comm.SendToFriends then
        mask = mask + 1
    end

    if Nx.db.profile.Comm.SendToGuild then
        mask = mask + 2
    end

    if Nx.db.profile.Comm.SendToZone then
        mask = mask + 4
    end

    Nx.Com:SetSendPalsMask (mask)
end

--------

function Nx.Opts:EditItem (item)

    local var = self:GetVar (item.V)
    local typ, r1 = self:ParseVar (item.V)

    if typ == "CH" then

        self.CurItem = item

        local data = self:CalcChoices (r1, "Get")
        if not data then
            Nx.prt ("EditItem error (%s)", r1)
        end
        Nx.DropDown:Start (self, self.EditCHAccept)
        for k, name in ipairs (data) do
            Nx.DropDown:Add (name, name == var)
        end
        Nx.DropDown:Show (self.List.Frm)
--[[
        local s = self:CalcChoices (r1, "Inc", var)
        self:SetVar (item.V, s)
        self:Update()

        if item.VF then
            local var = self:GetVar (item.V)
            self[item.VF](self, item, var)
        end
--]]
    elseif typ == "F" then
        Nx:ShowEditBox (item.N, var, item, self.EditFAccept)

    elseif typ == "I" then
        Nx:ShowEditBox (item.N, var, item, self.EditIAccept)

    elseif typ == "S" then
        Nx:ShowEditBox (item.N, var, item, self.EditSAccept)

    end
end

function Nx.Opts:EditCHAccept (name)

    local item = self.CurItem

    self:SetVar (item.V, name)
    self:Update()

    if item.VF then
        local var = self:GetVar (item.V)
        self[item.VF](self, item, var)
    end
end

function Nx.Opts.EditFAccept (str, item)

    local self = Nx.Opts

    local i = tonumber (str)
    if i then
        self:SetVar (item.V, i)
        self:Update()

        if item.VF then
            local var = self:GetVar (item.V)
            self[item.VF](self, item, var)
        end
    end
end

function Nx.Opts.EditIAccept (str, item)

    local self = Nx.Opts

    local i = tonumber (str)
    if i then
        self:SetVar (item.V, floor (i))
        self:Update()

        if item.VF then
            local var = self:GetVar (item.V)
            self[item.VF](self, item, var)
        end
    end
end

function Nx.Opts.EditSAccept (str, item)

    local self = Nx.Opts

    if str then
        self:SetVar (item.V, str)
        self:Update()

        if item.VF then
            local var = self:GetVar (item.V)
            self[item.VF](self, item, var)
        end
    end
end

-------------------------------------------------------------------------------
-- CHOICE CALCULATION
-- Get available choices for dropdown options
-------------------------------------------------------------------------------

---
-- Calculate available choices for a dropdown option
-- @param name  Choice type (FontFace, Skins, Anchor, etc.)
-- @param mode  Operation mode (Inc, Get)
-- @param val   Current value (for increment mode)
-- @return      Table of choices or single value
--
function Nx.Opts:CalcChoices(name, mode, val)

    if name == "FontFace" then

        if mode == "Inc" then
            local i = Nx.Font:GetIndex (val) + 1
            return Nx.Font:GetName (i) or Nx.Font:GetName (1)

        elseif mode == "Get" then

            data = {}

            for n = 1, 999 do
                local name = Nx.Font:GetName (n)
                if not name then
                    break
                end

                tinsert (data, name)
            end

            sort (data)

            return data
        end

        return
    elseif name == "Skins" then
        return self.Skins
    elseif name == "HUDAGfx" then

        return Nx.HUD.TexNames

    elseif name == "Anchor" then

        return self.ChoicesAnchor

    elseif name == "Anchor0" then

        return self.ChoicesAnchor0

    elseif name == "Chat" then

        return Nx:prtGetChatFrames()

    elseif name == "Corner" then

        return self.ChoicesCorner

    elseif name == "MapFunc" then

        return Nx.Map:GetFuncs()

    elseif name == "QArea" then

        return self.ChoicesQArea

    end
end

-------------------------------------------------------------------------------
-- VARIABLE PARSING AND ACCESS
-- Parse, get, and set option variables
-------------------------------------------------------------------------------

---
-- Parse a variable definition string
-- @param varName  Variable name
-- @return         Type, value state, texture (for buttons)
--
function Nx.Opts:ParseVar(varName)

    local data = Nx.OptsVars[varName]
    local scope, typ, val, a1 = Nx.Split ("~", data)
    local opts = scope == "-" and self.COpts or self.Opts

--    Nx.prtVar ("Parse " .. varName, opts[varName])

    local pressed
    local tx

    if typ == "B" then

        pressed = false
        tx = "But"

        if opts[varName] then
            pressed = true
            tx = "ButChk"
        end

        return typ, pressed, tx

    elseif typ == "CH" then

        return typ, a1

    elseif typ == "W" then

        local winName, atName = Nx.Split ("^", val)
        local typ, val = Nx.Window:GetAttribute (winName, atName)

        if typ == "B" then
            if val then
                return typ, true, "ButChk"
            end
            return typ, false, "But"
        end

        return typ, val
    end

    return typ
end

---
-- Get a variable value
-- @param varName  Variable name
-- @return         Current value
--
function Nx.Opts:GetVar(varName)

    local data = Nx.OptsVars[varName]
    if data then

        local scope, typ, val = Nx.Split ("~", data)
        local opts = scope == "-" and self.COpts or self.Opts

        if typ == "B" then
            return opts[varName]

        elseif typ == "CH" then
            return opts[varName]

        elseif typ == "F" or typ == "I" or typ == "S" then
            return opts[varName]

        end
    end
end

---
-- Set a variable value
-- @param varName  Variable name
-- @param val      New value
--
function Nx.Opts:SetVar(varName, val)

--    Nx.prtVar ("Set " .. varName, val)

    local data = Nx.OptsVars[varName]
    local scope, typ, vdef, vmin, vmax = Nx.Split ("~", data)
    local opts = scope == "-" and self.COpts or self.Opts

    if typ == "B" then
        opts[varName] = val

    elseif typ == "CH" then
        opts[varName] = val

    elseif typ == "F" or typ == "I" then

        vmin = tonumber (vmin)
        if vmin then
            val = max (val, vmin)
        end

        vmax = tonumber (vmax)
        if vmax then
            val = min (val, vmax)
        end

        opts[varName] = val

    elseif typ == "S" then
        opts[varName] = gsub (val, "~", "?")

    elseif typ == "W" then

        local winName, atName = Nx.Split ("^", vdef)
        Nx.Window:SetAttribute (winName, atName, val)

    else
        return
    end
end

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------
