-- Carbonite.Notes | Options
-- AceConfig options table for the Notes module. Lazily built on
-- first request and cached so subsequent /config opens don't
-- rebuild it. Registered with Nx:AddToConfig from NxFav's
-- OnInitialize.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

local notesoptions

function Nx.Notes:GetOptionsConfig()
    if not notesoptions then
        notesoptions = {
            type = "group",
            name = L["Note Options"],
            args = {
                notemap = {
                    order = 1, type = "toggle", width = "full",
                    name = L["Show Notes On Map"],
                    desc = L["Shows your notes on the carbonite map"],
                    get = function() return Nx.fdb.profile.Notes.ShowMap end,
                    set = function()
                        Nx.fdb.profile.Notes.ShowMap = not Nx.fdb.profile.Notes.ShowMap
                    end,
                },
                handy = {
                    order = 2, type = "toggle", width = "full",
                    name = L["Display Handynotes On Map"],
                    desc = L["If you have HandyNotes installed, allows them on the Carbonite map"],
                    get = function() return Nx.fdb.profile.Notes.HandyNotes end,
                    set = function()
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.HandyNotes = not Nx.fdb.profile.Notes.HandyNotes
                        if Nx.fdb.profile.Notes.HandyNotes then
                            Nx.Notes:HandyNotes(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!HANDY")
                        end
                    end,
                    disabled = function() return not _G.HandyNotes end,
                },
                handysize = {
                    order = 3, type = "range", width = "normal",
                    min = 10, max = 60, step = 5,
                    name = L["Handnotes Icon Size"],
                    get = function() return Nx.fdb.profile.Notes.HandyNotesSize end,
                    set = function(_, value)
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.HandyNotesSize = value
                        map:ClearIconType("!HANDY")
                        Nx.Notes:HandyNotes(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function() return not _G.HandyNotes end,
                },
                rarescanner = {
                    order = 4, type = "toggle", width = "full",
                    name = L["Display RareScanner icons On Map"],
                    desc = L["If you have RareScanner installed, allows its icons on the Carbonite map"],
                    get = function() return Nx.fdb.profile.Notes.RareScanner end,
                    set = function()
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.RareScanner = not Nx.fdb.profile.Notes.RareScanner
                        if Nx.fdb.profile.Notes.RareScanner then
                            Nx.Notes:BustIntegrationCache("RareScanner")
                            Nx.Notes:RareScanner(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!RSR")
                        end
                    end,
                    disabled = function() return not _G.RareScanner end,
                },
                raresize = {
                    order = 5, type = "range", width = "normal",
                    min = 10, max = 60, step = 5,
                    name = L["RareScanner Icon Size"],
                    get = function() return Nx.fdb.profile.Notes.RareScannerSize end,
                    set = function(_, value)
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.RareScannerSize = value
                        map:ClearIconType("!RSR")
                        Nx.Notes:RareScanner(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function() return not _G.RareScanner end,
                },
                questie = {
                    order = 6, type = "toggle", width = "full",
                    name = L["Display Questie quest objective icons On Map (Beware: might cause lags and fps loss)"],
                    desc = L["If you have Questie installed, allows its icons for quest objectives on the Carbonite map"],
                    get = function() return Nx.fdb.profile.Notes.Questie end,
                    set = function()
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.Questie = not Nx.fdb.profile.Notes.Questie
                        if Nx.fdb.profile.Notes.Questie then
                            Nx.Notes:BustIntegrationCache("Questie")
                            Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!QUE")
                            map:ClearIconType("!QUE_T")
                        end
                    end,
                    disabled = function() return not _G.Questie end,
                },
                questieSE = {
                    order = 7, type = "toggle", width = "full",
                    name = L["Display icons for Available quests from Questie on Carbonite Map"],
                    desc = L["If you have Questie installed, allows its icons for available quests on the Carbonite map"],
                    get = function() return Nx.fdb.profile.Notes.QuestieSE end,
                    set = function()
                        Nx.fdb.profile.Notes.QuestieSE = not Nx.fdb.profile.Notes.QuestieSE
                        if Nx.fdb.profile.Notes.Questie then
                            Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
                        end
                    end,
                    disabled = function() return not _G.Questie end,
                },
                questiesize = {
                    order = 8, type = "range", width = "normal",
                    min = 10, max = 40, step = 1,
                    name = L["Questie Icon Size"],
                    get = function() return Nx.fdb.profile.Notes.QuestieSize end,
                    set = function(_, value)
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.QuestieSize = value
                        map:ClearIconType("!QUE")
                        map:ClearIconType("!QUE_T")
                        Nx.Notes:BustIntegrationCache("Questie")
                        Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function() return not _G.Questie end,
                },
                rxp = {
                    order = 9, type = "toggle", width = "full",
                    name = L["Display RXPGuides waypoints On Map"],
                    desc = L["If you have RXPGuides installed, mirrors its active-step waypoint pins onto the Carbonite map"],
                    get = function() return Nx.fdb.profile.Notes.RXP end,
                    set = function()
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.RXP = not Nx.fdb.profile.Notes.RXP
                        if Nx.fdb.profile.Notes.RXP then
                            Nx.Notes:BustIntegrationCache("RXP")
                            Nx.Notes:RXP(Nx.Map:GetCurrentMapAreaID())
                        else
                            map:ClearIconType("!RXP")
                        end
                    end,
                    disabled = function() return not _G.RXP end,
                },
                rxpsize = {
                    order = 10, type = "range", width = "normal",
                    min = 16, max = 48, step = 2,
                    name = L["RXPGuides Icon Size"],
                    get = function() return Nx.fdb.profile.Notes.RXPSize end,
                    set = function(_, value)
                        local map = Nx.Map:GetMap(1)
                        Nx.fdb.profile.Notes.RXPSize = value
                        map:ClearIconType("!RXP")
                        Nx.Notes:BustIntegrationCache("RXP")
                        Nx.Notes:RXP(Nx.Map:GetCurrentMapAreaID())
                    end,
                    disabled = function() return not _G.RXP end,
                },
                rxparrow = {
                    order = 11, type = "toggle", width = "full",
                    name = L["Route RXPGuides arrow through Carbonite"],
                    desc = L["Replaces the RXPGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"],
                    get = function() return Nx.fdb.profile.Notes.RXPArrow end,
                    set = function()
                        Nx.fdb.profile.Notes.RXPArrow = not Nx.fdb.profile.Notes.RXPArrow
                        if Nx.Notes.RXPArrowSync then Nx.Notes:RXPArrowSync() end
                    end,
                    disabled = function() return not _G.RXP end,
                },
                zygorarrow = {
                    order = 12, type = "toggle", width = "full",
                    name = L["Route ZygorGuides arrow through Carbonite"],
                    desc = L["Replaces the ZygorGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"],
                    get = function() return Nx.fdb.profile.Notes.ZygorArrow end,
                    set = function()
                        Nx.fdb.profile.Notes.ZygorArrow = not Nx.fdb.profile.Notes.ZygorArrow
                        if Nx.Notes.ZygorArrowSync then Nx.Notes:ZygorArrowSync() end
                    end,
                    disabled = function() return not _G.ZGV end,
                },
            },
        }
    end
    Nx.Opts:AddToProfileMenu(L["Notes"], 4, Nx.fdb)
    return notesoptions
end
