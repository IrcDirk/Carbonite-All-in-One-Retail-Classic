-- Carbonite.Quests | Options
-- AceConfig options table for the Quest module. Lazily built on
-- first request and cached so subsequent /config opens don't
-- rebuild it. Registered with Nx:AddToConfig from CarboniteQuest's
-- OnInitialize.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed.
local format = _G.string.format or _G.format
local max = _G.math.max or _G.max
local min = _G.math.min or _G.min

local questoptions

-------------------------------------------------------------------------------
-- OPTIONS CONFIGURATION
-- AceConfig options table for quest module settings
-------------------------------------------------------------------------------

---
-- Get or create quest options configuration
-- @return  Quest options table for AceConfig
--
function Nx.Quest:GetOptionsConfig()
    if not questoptions then
        questoptions = {
            type = "group",
            name = L["Quest Options"],
            childGroups    = "tab",
            args = {
                quest = {
                    type = "group",
                    name = L["Quest Options"],
                    order = 1,
                    args = {
                        name = {
                            order = 1,
                            type = "description",
                            name = L["Quest Window Options"],
                        },
                        qaltl = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            name = L["Use Alt-L instead of L for Carbonite Quests"],
                            desc = L["When enabled, leaves L as the default blizzard window and Alt-L for carbonite quests"],
                            get = function()
                                return Nx.qdb.profile.Quest.UseAltLKey
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.UseAltLKey = not Nx.qdb.profile.Quest.UseAltLKey
                            end,
                        },
                        qlsidebyside = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Show Quests Side by Side"],
                            desc = L["When enabled, shows the quest details to the right side of the quest window"],
                            get = function()
                                return Nx.qdb.profile.Quest.SideBySide
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.SideBySide = not Nx.qdb.profile.Quest.SideBySide
                                Nx.Quest.List:AttachFrames()
                            end,
                        },
                        qlshowreset = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Show Daily Reset Time"],
                            desc = L["When enabled, shows the time until dailies reset"],
                            get = function()
                                return Nx.qdb.profile.Quest.ShowDailyReset
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.ShowDailyReset = not Nx.qdb.profile.Quest.ShowDailyReset
                            end,
                        },
                        qlshowcount = {
                            order = 5,
                            type = "toggle",
                            width = "full",
                            name = L["Show Daily Quest Count"],
                            desc = L["When enabled, shows the number of daily quests you've done"],
                            get = function()
                                return Nx.qdb.profile.Quest.ShowDailyCount
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.ShowDailyCount = not Nx.qdb.profile.Quest.ShowDailyCount
                            end,
                        },
                        qlshowid = {
                            order = 6,
                            type = "toggle",
                            width = "full",
                            name = L["Show Quest ID"],
                            desc = L["When enabled, shows the quest ID beside the quest"],
                            get = function()
                                return Nx.qdb.profile.Quest.ShowId
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.ShowId = not Nx.qdb.profile.Quest.ShowId
                            end,
                        },
                        qlshowoffers = {
                            order = 7,
                            type = "toggle",
                            width = "full",
                            name = L["Show Quest Offers on Map"],
                            desc = L["When enabled, shows available quest offers from quest lines on the map"],
                            get = function()
                                return Nx.qdb.profile.Quest.ShowQuestOffers
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.ShowQuestOffers = not Nx.qdb.profile.Quest.ShowQuestOffers
                            end,
                        },
                        ImgorBG = {
                            order = 8,
                            type = "toggle",
                            width = "full",
                            name = L["Use scroll image in quest log"],
                            desc = L["When enabled, uses paper looking background for quest details"],
                            get = function()
                                return Nx.qdb.profile.Quest.ScrollIMG
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.ScrollIMG = not Nx.qdb.profile.Quest.ScrollIMG
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        qbgcol = {
                            order = 9,
                            type = "color",
                            width = "full",
                            name = L["Quest Details Background Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.DetailBC) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.DetailBC = r .. "|" .. g .. "|" .. b .. "|" .. a
                            end,
                        },
                        qtcol = {
                            order = 10,
                            type = "color",
                            width = "full",
                            name = L["Quest Details Text Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.DetailTC) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                if(not Nx.qdb.profile.Quest["DetailTC"]) then Nx.qdb.profile.Quest["DetailTC"] = Nx.Quest.defaults.profile.Quest["DetailTC"]; end;
                                Nx.qdb.profile.Quest.DetailTC = r .. "|" .. g .. "|" .. b .. "|" .. a
                            end,
                        },
                        qtscale = {
                            order = 11,
                            type = "range",
                            name = L["Quest Details Scale"],
                            desc = L["Sets the size of the quest details"],
                            min = .5,
                            max = 2,
                            step = .01,
                            bigStep = .01,
                            get = function()
                                return Nx.qdb.profile.Quest.DetailScale
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.Quest.DetailScale = value
                            end,
                        },
                        spacer = {
                            order = 12,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        spacer2 = {
                            order = 13,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        questdesc = {
                            order = 14,
                            type = "description",
                            name = L["Quest Options"],
                        },
                        qtool = {
                            order = 15,
                            type = "toggle",
                            width = "full",
                            name = L["Show Quest Tooltips"],
                            desc = L["When enabled, adds quest information to tooltips"],
                            get = function()
                                return Nx.qdb.profile.Quest.AddTooltip
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.AddTooltip = not Nx.qdb.profile.Quest.AddTooltip
                            end,
                        },
                        qparty = {
                            order = 16,
                            type = "toggle",
                            width = "full",
                            name = L["Share Quest Progress"],
                            desc = L["When enabled, shares your quest progress to group members and accepts their shares"],
                            get = function()
                                return Nx.qdb.profile.Quest.PartyShare
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.PartyShare = not Nx.qdb.profile.Quest.PartyShare
                            end,
                        },
                        qauto = {
                            order = 17,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Accept Quests"],
                            desc = L["When enabled, will auto accept quests that get offered to you"],
                            get = function()
                                return Nx.qdb.profile.Quest.AutoAccept
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.AutoAccept = not Nx.qdb.profile.Quest.AutoAccept
                            end,
                        },
                        qautoturn = {
                            order = 18,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Turn In Quests"],
                            desc = L["When enabled, automatically turns in quests"],
                            get = function()
                                return Nx.qdb.profile.Quest.AutoTurnIn
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.AutoTurnIn = not Nx.qdb.profile.Quest.AutoTurnIn
                            end,
                        },
                        qautoac = {
                            order = 19,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Turn In Self-Completion Quests"],
                            desc = L["When enabled, auto turns in quests that are self-completing"],
                            get = function()
                                return Nx.qdb.profile.Quest.AutoTurnInAC
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.AutoTurnInAC = not Nx.qdb.profile.Quest.AutoTurnInAC
                            end,
                        },
                        qbroad = {
                            order = 20,
                            type = "toggle",
                            width = "double",
                            name = L["Broadcast Quest Changes"],
                            desc = L["When enabled, will send a group/raid message when you complete an objective"],
                            get = function()
                                return Nx.qdb.profile.Quest.BroadcastQChanges
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.BroadcastQChanges = not Nx.qdb.profile.Quest.BroadcastQChanges
                            end,
                        },
                        qbroadnum = {
                            order = 21,
                            type = "range",
                            name = L["Broadcast after number of changes"],
                            desc = L["Sets the number of objective changes before it sends the group/raid message"],
                            min = 1,
                            max = 999,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.Quest.BroadcastQChangesNum
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.Quest.BroadcastQChangesNum = value
                            end,
                        },
                        qextra = {
                            order = 21,
                            type = "toggle",
                            width = "full",
                            name = L["Show Extended Info in Quest Links"],
                            desc = L["When enabled, adds information about level and part number in quest links"],
                            get = function()
                                return Nx.qdb.profile.Quest.ShowLinkExtra
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.ShowLinkExtra = not Nx.qdb.profile.Quest.ShowLinkExtra
                            end,
                        },
                        qlogin = {
                            order = 22,
                            type = "toggle",
                            width = "full",
                            name = L["Get Completed Quest Information on Login"],
                            desc = L["When enabled, will get all your completed quests from the server each login"],
                            get = function()
                                return Nx.qdb.profile.Quest.HCheckCompleted
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.HCheckCompleted = not Nx.qdb.profile.Quest.HCheckCompleted
                            end,
                        },
                        spacer3 = {
                            order = 23,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        questmaps = {
                            order = 24,
                            type = "description",
                            name = L["Quest Map Options"],
                        },
                        qmshow = {
                            order = 25,
                            type = "toggle",
                            width = "full",
                            name = L["Always Show Quest Watched Areas"],
                            desc = L["When enabled, will always show your watched quests on the map. This only works for quests carbonite knows"],
                            get = function()
                                return Nx.qdb.profile.Quest.MapShowWatchAreas
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.MapShowWatchAreas = not Nx.qdb.profile.Quest.MapShowWatchAreas
                            end,
                        },
                        qmwcol = {
                            order = 26,
                            type = "color",
                            width = "full",
                            name = L["Color of Watched Areas When Tracked"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchAreaTrackColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchAreaTrackColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                            end,
                        },
                        qmwtrackcol = {
                            order = 27,
                            type = "color",
                            width = "full",
                            name = L["Color of Watched Areas on Mouse Over"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchAreaHoverColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchAreaHoverColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                            end,
                        },
                        qmwtracktrans = {
                            order = 28,
                            type = "color",
                            width = "full",
                            name = L["Alpha of Watched Areas"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchAreaAlpha) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchAreaAlpha = r .. "|" .. g .. "|" .. b .. "|" .. a
                            end,
                        },
                        qmgraph = {
                            order = 29,
                            type = "select",
                            name = L["Watched Area Graphic"],
                            desc = L["Sets the graphic to be used for watched areas"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("QArea")
                                for a,b in pairs(vals) do
                                if (b == Nx.qdb.profile.Quest.MapWatchAreaGfx) then
                                    return a
                                end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("QArea")
                                Nx.qdb.profile.Quest.MapWatchAreaGfx = vals[name]
                                Nx.Quest:CalcWatchColors()
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("QArea")
                            end,
                        },
                        spacer4 = {
                            order = 30,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        qmcolperq = {
                            order = 31,
                            type = "toggle",
                            name = L["Use One Color Per Quest"],
                            width = "full",
                            desc = L["When enabled, will use one specific color per quest area"],
                            get = function()
                                return Nx.qdb.profile.Quest.MapWatchColorPerQ
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.MapWatchColorPerQ = not Nx.qdb.profile.Quest.MapWatchColorPerQ
                            end,
                        },
                        qttlcols = {
                            order = 32,
                            type = "range",
                            name = L["Total Colors To Use"],
                            desc = L["Sets the number of possible colors to use for quest watching"],
                            min = 1,
                            max = 12,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.Quest.MapWatchColorCnt
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.Quest.MapWatchColorCnt = value
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol1 = {
                            order = 33,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 1"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC1) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC1 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol2 = {
                            order = 34,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 2"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC2) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC2 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol3 = {
                            order = 35,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 3"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC3) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC3 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol4 = {
                            order = 36,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 4"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC4) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC4 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol5 = {
                            order = 37,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 5"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC5) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC5 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol6 = {
                            order = 38,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 6"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC6) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC6 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol7 = {
                            order = 39,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 7"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC7) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC7 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol8 = {
                            order = 40,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 8"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC8) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC8 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol9 = {
                            order = 41,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 9"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC9) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC9 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol10 = {
                            order = 42,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 10"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC10) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC10 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol11 = {
                            order = 43,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 11"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC11) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC11 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        qcol12 = {
                            order = 44,
                            type = "color",
                            width = "full",
                            name = L["Watch Color 12"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.Quest.MapWatchC12) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.Quest.MapWatchC12 = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:CalcWatchColors()
                            end,
                        },
                        spacer5 = {
                            order = 45,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        QuestFont = {
                            order = 46,
                            type = "select",
                            name = L["Quest Font"],
                            desc = L["Sets the font to be used on the quest window"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                for a,b in pairs(vals) do
                                  if (b == Nx.qdb.profile.Quest.QuestFont) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                Nx.qdb.profile.Quest.QuestFont = vals[name]
                                Nx.Opts:NXCmdFontChange()
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("FontFace","Get")
                            end,
                        },
                        QuestFontSize = {
                            order = 47,
                            type = "range",
                            name = L["Quest Font Size"],
                            desc = L["Sets the size of the quest window font"],
                            min = 6,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.Quest.QuestFontSize
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.Quest.QuestFontSize = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        QuestFontSpacing = {
                            order = 48,
                            type = "range",
                            name = L["Quest Font Spacing"],
                            desc = L["Sets the spacing of the quest window font"],
                            min = -10,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.Quest.QuestFontSpacing
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.Quest.QuestFontSpacing = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        QuestFontOutline = {
                            order = 49,
                            type = "select",
                            name = L["Font Outline"],
                            desc = L["Sets the outline style of this font"],
                            values = {
                                [""]             = L["None"],
                                ["OUTLINE"]      = L["Outline"],
                                ["THICKOUTLINE"] = L["Thick Outline"],
                            },
                            get = function() return Nx.qdb.profile.Quest.QuestFontOutline or "" end,
                            set = function(_, v)
                                Nx.qdb.profile.Quest.QuestFontOutline = v
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        QuestFontShadow = {
                            order = 50,
                            type = "toggle",
                            name = L["Font Shadow"],
                            desc = L["Adds a drop shadow to this font"],
                            get = function() return Nx.qdb.profile.Quest.QuestFontShadow end,
                            set = function(_, v)
                                Nx.qdb.profile.Quest.QuestFontShadow = v
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                    },
                },
                watch = {
                    type = "group",
                    name = L["Watch Options"],
                    order = 2,
                    args = {
                        qwhide = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Hide Quest Watch Window"],
                            desc = L["When enabled, stops carbonite from displaying the quest watch window"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.Hide
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.Hide = not Nx.qdb.profile.QuestWatch.Hide
                                Nx.Window:SetAttribute("NxQuestWatch","H",Nx.qdb.profile.QuestWatch.Hide)
                            end,
                        },
                        qwraidhide = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            name = L["Hide Quest Watch Window in Raids"],
                            desc = L["When enabled, stops carbonite from displaying the quest watch window while your in a raid"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.HideRaid
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.HideRaid = not Nx.qdb.profile.QuestWatch.HideRaid
                            end,
                        },
                        qwlock = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Lock Quest Watch Window"],
                            desc = L["When enabled, stops carbonite from being able to move"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.Lock
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.Lock = not Nx.qdb.profile.QuestWatch.Lock
                                Nx.Window:SetAttribute("NxQuestWatch","L",Nx.qdb.profile.QuestWatch.Lock)
                            end,
                        },
                        qwgrowup = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Grow quest watch window Upwards"],
                            desc = L["When enabled, objectives and quests get added in an upward direction instead of down"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.GrowUp
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.GrowUp = not Nx.qdb.profile.QuestWatch.GrowUp
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwfixedsize = {
                            order = 5,
                            type = "toggle",
                            width = "full",
                            name = L["Use A Fixed Size for Quest Watch"],
                            desc = L["When enabled, the carbonite quest watch window does not allow resizing, just movement (RELOAD REQUIRED)"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.FixedSize
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.FixedSize = not Nx.qdb.profile.QuestWatch.FixedSize
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        qwhideblizz = {
                            order = 6,
                            type = "toggle",
                            width = "full",
                            name = L["Hide Blizzards Quest Track Window"],
                            desc = L["When enabled, hides blizzards version of the track window"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.HideBlizz
                            end,
                            set = function(info, val)
                                Nx.qdb.profile.QuestWatch.HideBlizz = (val == true)
                                if Nx.Quest and Nx.Quest.TrackerHider_Apply then
                                    Nx.Quest:TrackerHider_Apply()
                                end
                            end,
                        },
                        qwblizzauto = {
                            order = 7,
                            type = "toggle",
                            width = "full",
                            name = L["Disable Blizzards Auto Quest Tracking"],
                            desc = L["When enabled, turns off blizzards quest watch window auto adding new quests (RELOAD REQUIRED)"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.BlizzModify
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.BlizzModify = not Nx.qdb.profile.QuestWatch.BlizzModify
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        qwtextsize = {
                            order = 8,
                            type = "range",
                            name = L["Object Text Length Before Linewrap"],
                            desc = L["Sets the number of characters before an objective wraps"],
                            min = 20,
                            max = 999,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.QuestWatch.OMaxLen
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.OMaxLen = value
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qsync = {
                            order = 9,
                            type = "toggle",
                            width = "full",
                            name = L["Sync Carbonite Quest Watch with Blizzard Quest Watch"],
                            desc = L["When enabled, syncs the two watch lists which enables blizzard quest blobs to appear on the minimap"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.Sync
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.Sync = not Nx.qdb.profile.QuestWatch.Sync
                            end,
                        },
                        qrefresh = {
                            order = 10,
                            type = "range",
                            name = L["Watch Delay Time"],
                            desc = L["Sets the forced delay time of watch update in ms, performance toggle for systems that need it"],
                            min = 250,
                            max = 1000,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.QuestWatch.RefreshTimer
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.RefreshTimer = value
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        spacer = {
                            order = 11,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        spacer1 = {
                            order = 12,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        qwautonew = {
                            order = 13,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Watch New Quests"],
                            desc = L["When enabled, any new quest you pickup is automatically watched"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.AddNew
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.AddNew = not Nx.qdb.profile.QuestWatch.AddNew
                            end,
                        },
                        qwaddchanged = {
                            order = 14,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Watch Changed Quests"],
                            desc = L["When enabled, any quest whose objective changes from you looting an item, or talking to someone is automatically watched"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.AddChanged
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.AddChanged = not Nx.qdb.profile.QuestWatch.AddChanged
                            end,
                        },
                        qwremovecomplete = {
                            order = 15,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Remove Completed Quests"],
                            desc = L["When enabled, when you complete a quest it will be removed from your watch list"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.RemoveComplete
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.RemoveComplete = not Nx.qdb.profile.QuestWatch.RemoveComplete
                            end,
                        },
                        qwshowdist = {
                            order = 16,
                            type = "toggle",
                            width = "full",
                            name = L["Show distance to quest objectives"],
                            desc = L["When enabled, attempts to display how far approximately you are from a quest or objective"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.ShowDist
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.ShowDist = not Nx.qdb.profile.QuestWatch.ShowDist
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwhideobject = {
                            order = 17,
                            type = "toggle",
                            width = "full",
                            name = L["Auto Hide Finished Objectives"],
                            desc = L["When enabled, objectives that are 100% complete will be removed from the list"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.HideDoneObj
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.HideDoneObj = not Nx.qdb.profile.QuestWatch.HideDoneObj
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwobjfirst = {
                            order = 18,
                            type = "toggle",
                            width = "full",
                            name = L["Show Objective Amount First"],
                            desc = L["When enabled, puts your objective progress before the objective instead of after"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.OCntFirst
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.OCntFirst = not Nx.qdb.profile.QuestWatch.OCntFirst
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        spacer2 = {
                            order = 19,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        qwwatchscen = {
                            order = 20,
                            type = "toggle",
                            width = "full",
                            name = L["Watch Scenarios"],
                            desc = L["When enabled, will place scenario status at the top of your watch window"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.ScenTrack
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.ScenTrack = not Nx.qdb.profile.QuestWatch.ScenTrack
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwwatchach = {
                            order = 21,
                            type = "toggle",
                            width = "full",
                            name = L["Watch Achievements"],
                            desc = L["When enabled, will place any tracked achievements at the top of your watch window"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.AchTrack
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.AchTrack = not Nx.qdb.profile.QuestWatch.AchTrack
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwwatchtask = {
                            order = 22,
                            type = "toggle",
                            width = "full",
                            name = L["Watch Bonus Tasks"],
                            desc = L["When enabled, will place bonus tasks onto the quest tracker when your in range."],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.BonusTask
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.BonusTask = not Nx.qdb.profile.QuestWatch.BonusTask
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwwatchpbar = {
                            order = 23,
                            type = "toggle",
                            width = "full",
                            name = L["Show Progress Bar instead of Text"],
                            desc = L["If active, instead of a text, the percentage of progress will be shown with a bar."],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.BonusBar
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.BonusBar = not Nx.qdb.profile.QuestWatch.BonusBar
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwwatchchal = {
                            order = 24,
                            type = "toggle",
                            width = "full",
                            name = L["Watch Challenge Modes"],
                            desc = L["When enabled, will place the timer for your challenge mode at the top of your watch window"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.ChalTrack
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.ChalTrack = not Nx.qdb.profile.QuestWatch.ChalTrack
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwwatchzone = {
                            order = 25,
                            type = "toggle",
                            width = "full",
                            name = L["Show Zone Achievement if Known"],
                            desc = L["When enabled, if carbonite knows there is a zone achievement for number of quests it will display it"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.AchZoneShow
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.AchZoneShow = not Nx.qdb.profile.QuestWatch.AchZoneShow
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        spacer3 = {
                            order = 26,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        qwshowclose = {
                            order = 27,
                            type = "toggle",
                            width = "full",
                            name = L["Show Close Button"],
                            desc = L["When enabled, will place a button on the watch window to close it (RELOADS UI)"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.ShowClose
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.ShowClose = not Nx.qdb.profile.QuestWatch.ShowClose
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        qwfadeall = {
                            order = 28,
                            type = "toggle",
                            width = "full",
                            name = L["Fade Entire Window"],
                            desc = L["When enabled, if the quest watch window fades, will ensure all of it fades text and all instead of just the window itself"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.FadeAll
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.FadeAll = not Nx.qdb.profile.QuestWatch.FadeAll
                                Nx.Quest.Watch:WinUpdateFade (Nx.qdb.profile.QuestWatch.FadeAll and Nx.Quest.Watch.Win:GetFade() or 1, true)
                            end,
                        },
                        qwbgcol = {
                            order = 29,
                            type = "color",
                            width = "full",
                            name = L["Quest Watch Background Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.QuestWatch.BGColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.QuestWatch.BGColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwcompletecol = {
                            order = 30,
                            type = "color",
                            width = "full",
                            name = L["Quest Complete Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.QuestWatch.CompleteColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.QuestWatch.CompleteColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwicompletecol = {
                            order = 31,
                            type = "color",
                            width = "full",
                            name = L["Quest Incomplete Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.QuestWatch.IncompleteColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.QuestWatch.IncompleteColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwocompletecol = {
                            order = 32,
                            type = "color",
                            width = "full",
                            name = L["Objective Complete Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.QuestWatch.OCompleteColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.QuestWatch.OCompleteColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwoincompletecol = {
                            order = 33,
                            type = "color",
                            width = "full",
                            name = L["Objective Incomplete Color"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.QuestWatch.OIncompleteColor) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.QuestWatch.OIncompleteColor = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest:SetCols()
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        qwobjshade = {
                            order = 34,
                            type = "toggle",
                            width = "full",
                            name = L["Color Objective Based on Progress"],
                            desc = L["When enabled, will color your objectives based on how complete they are"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.ShowPerColor
                            end,
                            set = function()
                                Nx.qdb.profile.QuestWatch.ShowPerColor = not Nx.qdb.profile.QuestWatch.ShowPerColor
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        spacer4 = {
                            order = 35,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        qwiconsize = {
                            order = 36,
                            type = "range",
                            name = L["Clickable Icon Size (0 disables)"],
                            desc = L["If a quest has an item to be used, will draw it beside the quest at the size defined here"],
                            min = 0,
                            max = 50,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.QuestWatch.ItemScale
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.ItemScale = value
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        spacer5 = {
                            order = 37,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        qwitemalpha = {
                            order = 38,
                            type = "color",
                            width = "full",
                            name = L["Item Transparency"],
                            desc = L["Only uses the Alpha value, and is used to make clickable items in the watch list transparent"],
                            hasAlpha = true,
                            get = function()
                                local arr = { Nx.Split("|",Nx.qdb.profile.QuestWatch.ItemAlpha) }
                                local r = arr[1]
                                local g = arr[2]
                                local b = arr[3]
                                local a = arr[4]
                                return r,g,b,tonumber(a)
                            end,
                            set = function(_,r,g,b,a)
                                Nx.qdb.profile.QuestWatch.ItemAlpha = r .. "|" .. g .. "|" .. b .. "|" .. a
                                Nx.Quest.Watch:Update()
                            end,
                        },
                        spacer6 = {
                            order = 39,
                            type = "description",
                            width = "full",
                            name = " ",
                        },
                        QuestWatchFont = {
                            order = 40,
                            type = "select",
                            name = L["Quest Watch Font"],
                            desc = L["Sets the font to be used on the quest watch window"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                for a,b in pairs(vals) do
                                  if (b == Nx.qdb.profile.QuestWatch.WatchFont) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                Nx.qdb.profile.QuestWatch.WatchFont = vals[name]
                                Nx.Opts:NXCmdFontChange()
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("FontFace","Get")
                            end,
                        },
                        QuestWatchFontSize = {
                            order = 41,
                            type = "range",
                            name = L["Watch Font Size"],
                            desc = L["Sets the size of the quest watch font"],
                            min = 6,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.QuestWatch.WatchFontSize
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.WatchFontSize = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        QuestWatchFontSpacing = {
                            order = 42,
                            type = "range",
                            name = L["Watch Font Spacing"],
                            desc = L["Sets the spacing of the quest watch font"],
                            min = -10,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.QuestWatch.WatchFontSpacing
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.WatchFontSpacing = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        QuestWatchFontOutline = {
                            order = 43,
                            type = "select",
                            name = L["Watch Font Outline"],
                            desc = L["Sets the outline style of the quest watch font"],
                            values = {
                                [""]             = L["None"],
                                ["OUTLINE"]      = L["Outline"],
                                ["THICKOUTLINE"] = L["Thick Outline"],
                            },
                            get = function()
                                return Nx.qdb.profile.QuestWatch.WatchFontOutline or ""
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.WatchFontOutline = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        QuestWatchFontShadow = {
                            order = 44,
                            type = "toggle",
                            name = L["Watch Font Shadow"],
                            desc = L["Adds a drop shadow to the quest watch font"],
                            get = function()
                                return Nx.qdb.profile.QuestWatch.WatchFontShadow
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.QuestWatch.WatchFontShadow = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                    },
                },
                sounds = {
                    type = "group",
                    name = L["Sound Options"],
                    order = 3,
                    args = {
                        sndEnable = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Play Quest Complete Sound"],
                            desc = L["When enabled, one of the selected sounds below will play on quest completion"],
                            get = function()
                                return Nx.qdb.profile.Quest.SndPlayCompleted
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.SndPlayCompleted = not Nx.qdb.profile.Quest.SndPlayCompleted
                            end,
                        },
                        sndtitle = {
                            order = 2,
                            type = "description",
                            width = "full",
                            name = L["Place a check in sounds you want carbonite to play when a quest is complete.\nChecking a box will play the sound for you to hear."]
                        },
                        snd1 = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Carbonite Quest Complete"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd1
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd1 = not Nx.qdb.profile.Quest.Snd1
                                if Nx.qdb.profile.Quest.Snd1 then
                                    Nx.Quest:PlaySound(1)
                                end
                            end,
                        },
                        snd2 = {
                            order = 4,
                            type = "toggle",
                            width = "full",
                            name = L["Peon Work Complete"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd2
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd2 = not Nx.qdb.profile.Quest.Snd2
                                if Nx.qdb.profile.Quest.Snd2 then
                                    Nx.Quest:PlaySound(2)
                                end
                            end,
                        },
                        snd3 = {
                            order = 5,
                            type = "toggle",
                            width = "full",
                            name = L["Undead Well Done"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd3
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd3 = not Nx.qdb.profile.Quest.Snd3
                                if Nx.qdb.profile.Quest.Snd3 then
                                    Nx.Quest:PlaySound(3)
                                end
                            end,
                        },
                        snd4 = {
                            order = 6,
                            type = "toggle",
                            width = "full",
                            name = L["Female Congratulations"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd4
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd4 = not Nx.qdb.profile.Quest.Snd4
                                if Nx.qdb.profile.Quest.Snd4 then
                                    Nx.Quest:PlaySound(4)
                                end
                            end,
                        },
                        snd5 = {
                            order = 7,
                            type = "toggle",
                            width = "full",
                            name = L["Dwarven Well Done"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd5
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd5 = not Nx.qdb.profile.Quest.Snd5
                                if Nx.qdb.profile.Quest.Snd5 then
                                    Nx.Quest:PlaySound(5)
                                end
                            end,
                        },
                        snd6 = {
                            order = 8,
                            type = "toggle",
                            width = "full",
                            name = L["Gnome Good Job"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd6
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd6 = not Nx.qdb.profile.Quest.Snd6
                                if Nx.qdb.profile.Quest.Snd6 then
                                    Nx.Quest:PlaySound(6)
                                end
                            end,
                        },
                        snd7 = {
                            order = 9,
                            type = "toggle",
                            width = "full",
                            name = L["Tauren Well Done"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd7
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd7 = not Nx.qdb.profile.Quest.Snd7
                                if Nx.qdb.profile.Quest.Snd7 then
                                    Nx.Quest:PlaySound(7)
                                end
                            end,
                        },
                        snd8 = {
                            order = 10,
                            type = "toggle",
                            width = "full",
                            name = L["Undead What Now"],
                            get = function()
                                return Nx.qdb.profile.Quest.Snd8
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Snd8 = not Nx.qdb.profile.Quest.Snd8
                                if Nx.qdb.profile.Quest.Snd8 then
                                    Nx.Quest:PlaySound(8)
                                end
                            end,
                        },
                    },
                },
                database = {
                    type = "group",
                    name = L["Databases"],
                    order = 4,
                    args = {
                        title = {
                            order = 1,
                            type = "description",
                            name = L["Reload the UI with the button at the bottom to change which quests are loaded."],
                        },
                        spacer1 = {
                            order = 2,
                            type = "description",
                            name = " ",
                        },
                        maxLoadLevel = {
                            order = 3,
                            type = "toggle",
                            width = "full",
                            name = L["Load quest data by threshold"],
                            desc = format(L["Loads all the carbonite quest data between player level - level threshold to %s"], Nx.MaxPlayerLevel),
                            get = function()
                                return Nx.qdb.profile.Quest.maxLoadLevel
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.maxLoadLevel = not Nx.qdb.profile.Quest.maxLoadLevel
                                Nx.Opts.NXCmdReload()
                            end,
                        },
                        LevelsToLoad = {
                            order = 4,
                            type = "range",
                            name = L["Level Threshold"],
                            desc = L["Levels above player level to load quest data on reload"],
                            min = 1,
                            max = Nx.MaxPlayerLevel,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.qdb.profile.Quest.LevelsToLoad
                            end,
                            set = function(info,value)
                                Nx.qdb.profile.Quest.LevelsToLoad = value
                                --Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        spacer2 = {
                            order = 5,
                            type = "description",
                            name = " ",
                        },
                        q0 = {
                            order = 6,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Level 0 (holidays, professions, etc)"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load0
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load0 = not Nx.qdb.profile.Quest.Load0
                            end,
                        },
                        q1 = {
                            order = 7,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 1-10"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load1
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load1 = not Nx.qdb.profile.Quest.Load1
                            end,
                        },
                        q2 = {
                            order = 8,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 11-20"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load2
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load2 = not Nx.qdb.profile.Quest.Load2
                            end,
                        },
                        q3 = {
                            order = 9,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 21-30"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load3
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load3 = not Nx.qdb.profile.Quest.Load3
                            end,
                        },
                        q4 = {
                            order = 10,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 31-40"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load4
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load4 = not Nx.qdb.profile.Quest.Load4
                            end,
                        },
                        q5 = {
                            order = 11,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 41-50"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load5
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load5 = not Nx.qdb.profile.Quest.Load5
                            end,
                        },
                        q6 = {
                            order = 12,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 51-60"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load6
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load6 = not Nx.qdb.profile.Quest.Load6
                            end,
                        },
                        q7 = {
                            order = 13,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 61-70"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load7
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load7 = not Nx.qdb.profile.Quest.Load7
                            end,
                        },
                        q8 = {
                            order = 14,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 71-80"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load8
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load8 = not Nx.qdb.profile.Quest.Load8
                            end,
                        },
                        q9 = {
                            order = 14,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 81-85"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load9
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load9 = not Nx.qdb.profile.Quest.Load9
                            end,
                        },
                        q10 = {
                            order = 14,
                            type = "toggle",
                            width = "full",
                            name = L["Load Quests for Levels 86-90"],
                            desc = L["Loads all the carbonite quest data in this range on reload"],
                            get = function()
                                return Nx.qdb.profile.Quest.Load10
                            end,
                            set = function()
                                Nx.qdb.profile.Quest.Load10 = not Nx.qdb.profile.Quest.Load10
                            end,
                        },
                        spacer3 = {
                            order = 19,
                            type = "description",
                            name = " ",
                        },
                        gather = {        -- Change to qgather perhaps?
                            order = 20,
                            type = "toggle",
                            width = "full",
                            name = L["Quests Data Gathering"],
                            desc = L["Gathers quests data"],
                            get = function()
                                return Nx.db.profile.General.CaptureEnable
                            end,
                            set = function()
                                Nx.db.profile.General.CaptureEnable = not Nx.db.profile.General.CaptureEnable
                            end,
                        },
                        spacer4 = {
                            order = 21,
                            type = "description",
                            name = " ",
                        },
                        reboot = {
                            order = 22,
                            type = "execute",
                            width = "full",
                            func = function()
                                Nx.Opts.NXCmdReload()
                            end,
                            name = L["Reload UI"]
                        },
                    },
                },
            },
        }
    end
    Nx.Opts:AddToProfileMenu(L["Quest"], 3, Nx.qdb)

    -- Remove database options for levels above max player level
    if Nx.MaxPlayerLevel < 90 then
        questoptions.args.database.args.q10 = nil
    end
    if Nx.MaxPlayerLevel < 85 then
        questoptions.args.database.args.q9 = nil
    end
    if Nx.MaxPlayerLevel < 80 then
        questoptions.args.database.args.q8 = nil
    end
    if Nx.MaxPlayerLevel < 70 then
        questoptions.args.database.args.q7 = nil
    end
    return questoptions
end
