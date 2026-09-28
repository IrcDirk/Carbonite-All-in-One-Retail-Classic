-- Carbonite.Quests | Init
-- AceAddon lifecycle for the CarboniteQuest plugin: OnInitialize,
-- profile-change handling, per-character data init, addon-comm
-- routing, the legacy ConvertData migration, and OptsReset. Lifted
-- from NxQuest.lua so the legacy file stays focused on the actual
-- quest engine.
--
-- defaults table lives on Nx.Quest.defaults (set up in NxQuest.lua
-- right before this file loads). All Nx.Quest:* methods stay
-- attached to the same namespace so existing callers see no change.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed.
local UnitLevel = _G.UnitLevel or _G.UnitLevel
local format = _G.string.format or _G.format
local tinsert = _G.table.insert or _G.tinsert

-------------------------------------------------------------------------------
-- MODULE INITIALIZATION
-------------------------------------------------------------------------------

---
-- AceAddon initialization callback
-- Sets up database, button types, and initializes quest system
--
function CarboniteQuest:OnInitialize()
    if not Nx.Initialized then
        CarbQuestInit = Nx:ScheduleTimer(CarboniteQuest.OnInitialize,5)
        return
    end
    Nx.qdb = LibStub("AceDB-3.0"):New("NXQuest", Nx.Quest.defaults, true)
    Nx.Quest:ConvertData()
    Nx.Quest:InitQuestCharacter()
    Nx.Font:ModuleAdd("Quest.QuestFont",{ "NxFontQ", "GameFontNormal","qdb" })
    Nx.Font:ModuleAdd("QuestWatch.WatchFont",{ "NxFontW", "GameFontNormal","qdb" })
    Nx.Map.Maps[1].PIconMenu:AddItem (0, L["Get Quests"] or "Get Quests", Nx.Map.Menu_OnGetQuests,Nx.Map.Maps[1])
    Nx.Quest.List.LoggingIn = true
    local qopts = Nx.qdb.profile.QuestOpts

    if not qopts or qopts.Version < Nx.VERSIONQOPTS then

        if qopts then
            Nx.prt (L["Reset old quest options %f"], qopts.Version)
        end

        qopts = {}
        Nx.qdb.profile.QuestOpts = qopts
        qopts.Version = Nx.VERSIONQOPTS

        Nx.Quest:OptsReset()
    end
    tinsert(Nx.ModuleUpdateIcon,"Quest")
    Nx.Button.TypeData["QuestHdr"] = {
        Bool = true,
        Skin = true,
        Up = "RoundMinus",
        Dn = "RoundPlus",
        SizeUp = 11,
        SizeDn = 11,
        VRGBAUp = ".56|.56|.56|1",
        VRGBADn = ".56|.56|.56|1",
    }
    Nx.Button.TypeData["QuestWatching"] = {
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 11,
        SizeDn = 11,
        VRGBAUp = "1|1|.25|.5",
        VRGBADn = ".87|.87|.185|.94",
    }
    Nx.Button.TypeData["QuestWatchMenu"] = {
        Tip = L["Menu"],
        Skin = true,
        Up = "ButWatchMenu",
        Dn = "ButWatchMenu",
        SizeUp = 14,
        SizeDn = 14,
        VRGBAUp = "1|1|1|.5",
        VRGBADn = "1|1|1|.75",
    }
    Nx.Button.TypeData["QuestWatchPri"] = {
        Tip = L["Priorities"],
        Skin = true,
        Up = "ButWatchMenu",
        Dn = "ButWatchMenu",
        SizeUp = 14,
        SizeDn = 14,
        VRGBAUp = "1|1|.5|.5",
        VRGBADn = "1|1|.5|.75",
    }
    Nx.Button.TypeData["QuestWatchSwap"] = {
        Tip = L["Swap Views"],
        Skin = true,
        Up = "ButWatchMenu",
        Dn = "ButWatchMenu",
        SizeUp = 14,
        SizeDn = 14,
        VRGBAUp = "1|1|1|.5",
        VRGBADn = "1|1|1|.75",
    }
    Nx.Button.TypeData["QuestWatchShowOnMap"] = {
        Tip = L["Show Quests On Map"],
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 10,
        SizeDn = 13,
        VRGBAUp = ".25|1|.25|.56",
        VRGBADn = ".25|1|.25|.87",
    }
    Nx.Button.TypeData["QuestWatchATrack"] = {
        Tip = L["Auto Track"],
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 10,
        SizeDn = 13,
        VRGBAUp = "1|0|1|.56",
        VRGBADn = "1|.25|1|.87",
    }
    Nx.Button.TypeData["QuestWatchGivers"] = {
        Tip = L["Quest Givers"],
        States = 3,
        Tx = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        {
            Size = 10,
            VRGBA = "1|.811|.25|.56",
        },
        {
            Size = 13,
            VRGBA = "1|.811|.25|.87",
        },
        {
            Size = 13,
            VRGBA = ".56|.56|1|.87",
        }
    }
    Nx.Button.TypeData["QuestWatchParty"] = {
        Tip = L["Show Party Quests"],
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 10,
        SizeDn = 13,
        VRGBAUp = ".811|.811|.811|.56",
        VRGBADn = "1|1|1|.87",
    }
    Nx.Button.TypeData["QuestWatch"] = {
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 9,
        SizeDn = 9,
        AlphaUp = .3,
        AlphaDn = .85,
    }
    Nx.Button.TypeData["QuestWatchAC"] = {        -- Auto complete
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Map\\IconQuestion",
        SizeUp = 15,
        VRGBAUp = ".75|1|.75|1",
        -- Marker read by the watch-list click handler: this button
        -- triggers ShowQuestComplete, NOT a super-track toggle. Without
        -- this flag the super-track-on-left-click block at the top of
        -- OnListEvent runs first and swallows the click into the
        -- waypoint-arrow toggle, never reaching ShowQuestComplete.
        AutoComplete = true,
    }
    Nx.Button.TypeData["QuestWatchTip"] = {
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 7,
        SizeDn = 7,
        VRGBAUp = "0|0|0|.313",
        VRGBADn = "0|0|0|.5",
        WatchTip = 1
    }
    Nx.Button.TypeData["QuestWatchTipItem"] = {
        SizeUp = 11,
        SizeDn = 11,
        VRGBAUp = "1|1|1|.75",
        VRGBADn = "1|1|1|1",
        WatchTip = 1
    }
    Nx.Button.TypeData["QuestWatchCustomTip"] = {
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 11,
        SizeDn = 11,
        VRGBAUp = "1|1|1|.75",
        VRGBADn = "1|1|1|1",
        CustomTip = 1
    }
    Nx.Button.TypeData["QuestWatchEmissaryTip"] = {
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 9,
        SizeDn = 9,
        AlphaUp = .3,
        AlphaDn = .85,
        EmissaryTip = 1
    }
    Nx.Button.TypeData["QuestWatchTarget"] = {
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 12,
        SizeDn = 12,
        AlphaUp = .4,
        AlphaDn = 1,
    }
    Nx.Button.TypeData["QuestWatchErr"] = {
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 9,
        SizeDn = 12,
        VRGBAUp = "1|.5|.125|.435",
        VRGBADn = "1|.5|.125|.94",
        WatchError = 1
    }
    -- Blizzard-tracker style title-row icons (Watch.Modern). The turn-in
    -- circle comes from the world-map POI sheet with the "?" atlas on top;
    -- in-progress rows use the tracker's ellipsis atlas. Tracked/super-
    -- tracked rows switch to the highlighted variants.
    local poiTex = "Interface\\WorldMap\\UI-QuestPoi-NumberIcons"
    local poiUVNormal = { .5, .625, .875, 1 }
    local poiUVTracked = { .5, .625, .375, .5 }
    local poiUVPushed = { .375, .5, .875, 1 }
    local turnInIcon = "UI-QuestIcon-TurnIn-Normal"
    local progYellow = "Quest-In-Progress-Icon-yellow"
    local progBrown = "Quest-In-Progress-Icon-Brown"
    local modernSize = 15

    Nx.Button.TypeData["QuestWatchDone"] = {
        Bool = true,
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVNormal, DnUV = poiUVTracked,
        IconUp = turnInIcon, IconScale = .72,
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = .85, AlphaDn = 1,
    }
    Nx.Button.TypeData["QuestWatchDoneTarget"] = {
        Bool = true,
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVTracked, DnUV = poiUVTracked,
        IconUp = turnInIcon, IconScale = .72,
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = 1, AlphaDn = 1,
    }
    Nx.Button.TypeData["QuestWatchDoneAC"] = {
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVNormal, DnUV = poiUVPushed,
        IconUp = turnInIcon, IconScale = .72,
        IconVRGBAUp = ".6|1|.6|1",
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = 1, AlphaDn = 1,
        AutoComplete = true,
    }
    Nx.Button.TypeData["QuestWatchDoneErr"] = {
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVNormal, DnUV = poiUVPushed,
        IconUp = turnInIcon, IconScale = .72,
        SizeUp = modernSize, SizeDn = modernSize,
        VRGBAUp = "1|.45|.3|.9", VRGBADn = "1|.45|.3|1",
        WatchError = 1,
    }
    -- The ellipsis atlases hold only the dots (Blizzard draws them on the
    -- POI circle as the Display layer), so the circle comes from the same
    -- sheet as the turn-in icon.
    Nx.Button.TypeData["QuestWatchProgTip"] = {
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVNormal, DnUV = poiUVPushed,
        IconUp = progYellow, IconDn = progBrown, IconScale = 1,
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = .85, AlphaDn = 1,
        WatchTip = 1,
    }
    Nx.Button.TypeData["QuestWatchProgTipTarget"] = {
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVTracked, DnUV = poiUVTracked,
        IconUp = progBrown, IconScale = 1,
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = 1, AlphaDn = 1,
        WatchTip = 1,
    }
    Nx.Button.TypeData["QuestWatchProgTog"] = {
        Bool = true,
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVNormal, DnUV = poiUVTracked,
        IconUp = progYellow, IconDn = progBrown, IconScale = 1,
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = .85, AlphaDn = 1,
    }
    Nx.Button.TypeData["QuestWatchProgTogTarget"] = {
        Bool = true,
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVTracked, DnUV = poiUVTracked,
        IconUp = progBrown, IconScale = 1,
        SizeUp = modernSize, SizeDn = modernSize,
        AlphaUp = 1, AlphaDn = 1,
    }
    Nx.Button.TypeData["QuestWatchProgErr"] = {
        Up = poiTex, Dn = poiTex,
        UpUV = poiUVNormal, DnUV = poiUVPushed,
        IconUp = progYellow, IconScale = 1,
        SizeUp = modernSize, SizeDn = modernSize,
        VRGBAUp = "1|.45|.3|.9", VRGBADn = "1|.45|.3|1",
        WatchError = 1,
    }
    -- Completed objective marker: a flat dash where the objective dot
    -- would be. Inert = the watch list ignores clicks on it.
    Nx.Button.TypeData["QuestWatchObjDone"] = {
        RGBUp = ".62|.62|.62", RGBDn = ".62|.62|.62",
        WidthUp = 7, HeightUp = 2,
        AlphaUp = .9, AlphaDn = .9,
        Inert = 1,
    }
    Nx.Button.TypeData["QuestWatchMinBlizz"] = {
        Tip = MINIMIZE or "Minimize",
        Bool = true,
        AtlasUp = "ui-questtrackerbutton-collapse-all",
        AtlasDn = "ui-questtrackerbutton-expand-all",
        SizeUp = 16, SizeDn = 16,
        AlphaUp = 1, AlphaDn = 1,
    }
    Nx.Button.TypeData["QuestWatchTrial"] = {
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 9,
        SizeDn = 12,
        VRGBAUp = "1|1|.25|.686",
        VRGBADn = "1|1|.25|1",
    }
    Nx.Button.TypeData["QuestListWatch"] = {
        Bool = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\DotOn",
        SizeUp = 9,
        SizeDn = 9,
        VRGBAUp = "1|1|1|.31",
        VRGBADn = "1|1|1|.85",
    }
    Nx.Button.TypeData["WQListMenu"] = {
        Tip = L["Menu"],
        Skin = true,
        Up = "ButWatchMenu",
        Dn = "ButWatchMenu",
        SizeUp = 14,
        SizeDn = 14,
        VRGBAUp = "1|1|1|.5",
        VRGBADn = "1|1|1|.75",
    }
    -- Capture data
    local cap = NXQuest.Gather

    if not cap or cap.Version < Nx.VERSIONCAP then
        cap = {}
        cap.Version = Nx.VERSIONCAP
        cap["Q"] = {}
        NXQuest.Gather = cap
    end

    NXQuest.Gather.UserLocale = GetLocale()

    Nx.Quest:Init()
    if Nx.qdb.profile.Quest.Enable then
        Nx.Quest:HideUIPanel (_G["QuestMapFrame"])
    end
    CarboniteQuest:RegisterComm("carbmodule",Nx.Quest.OnChat_msg_addon)
    Nx:AddToConfig("Quest Module",Nx.Quest:GetOptionsConfig(),L["Quest Module"])
    Nx.Quest:SetCols()
    Nx.Quest.Initialized = true
    Nx.Quest.RecordQuests(true)
    Nx.Quest.List:LogUpdate()
    --CarboniteQuest:OnTrackedAchievementsUpdate()
    Nx.Quest.Watch:Update()
    Nx.Quest.WQList:Update()

    -- Update Emmissaries
    local pLvl = UnitLevel ("player")
    if not hideBfAEmmissaries and pLvl > 111 then Nx.Quest.emmBfA = GetQuestBountyInfoForMapID(875) end
    if not hideLegionEmmissaries and pLvl > 109 then Nx.Quest.emmLegion = GetQuestBountyInfoForMapID(619) end

    tinsert(Nx.BrokerMenuTemplate,{ text = L["Toggle Quest Watch"], func = function() Nx.Quest.Watch.Win:Show(not Nx.Quest.Watch.Win:IsShown()) end })
    tinsert(Nx.Whatsnew.Categories, "Quests")
    Nx.Whatsnew.Quests = {
        [1504562405] = {"Sept 4th 2017","","New feature for world quests.","Carbonite Quests now has it's own WorldQuest Tracker","","You can find it as World Quest List under the menu in the top left of quest watch.","(Play button icon)"}
    }

    -- Register profile callbacks
    Nx.qdb.RegisterCallback(Nx.Quest, "OnProfileChanged", "OnProfileChanged")
    Nx.qdb.RegisterCallback(Nx.Quest, "OnProfileCopied", "OnProfileChanged")
    Nx.qdb.RegisterCallback(Nx.Quest, "OnProfileReset", "OnProfileChanged")
end

---
-- Handle profile change events
-- @param event            Event type
-- @param database         Database reference
-- @param newProfileKey    New profile key
--
function Nx.Quest:OnProfileChanged(event, database, newProfileKey)
    if event == "OnProfileReset" then
        qopts = {}
        Nx.qdb.profile.QuestOpts = qopts
        qopts.Version = Nx.VERSIONQOPTS
        Nx.Quest:OptsReset()
    end

    Nx.Opts.NXCmdReload()
end

---
-- Initialize quest data for current character
--
function Nx.Quest:InitQuestCharacter()
    local chars = Nx.qdb.global.Characters
    local fullName = Nx:GetRealmCharName()
    local ch = chars[fullName]
    if not ch then
        ch = {}
    end
    if not ch.Q then
        ch.Q = {}
    end
    Nx.Quest.CurCharacter = ch
end

---
-- Handle addon communication messages
-- @param msg     Message string
-- @param dist    Distribution type
-- @param target  Target player
--
function Nx.Quest:OnChat_msg_addon(msg, dist, target)
    if msg == "QUEST_DECODE" then
        Nx.Quest:DecodeComRcv (Nx.qTEMPinfo, Nx.qTEMPmsg)
    end
end

---
-- Convert quest data from old format to new
-- Migrates character quest data from main db to quest db
--
function Nx.Quest:ConvertData()
    if not Nx.qdb.global then
        Nx.qdb.global = {}
    end
    if not Nx.qdb.global.Characters then
        Nx.qdb.global.Characters = {}
    end
    for ch, data in pairs(Nx.db.global.Characters) do
        if not Nx.qdb.global.Characters[ch] then
            Nx.qdb.global.Characters[ch] = {}
        end
        if Nx.db.global.Characters[ch].Q then
            Nx.qdb.global.Characters[ch].Q = Nx.db.global.Characters[ch].Q
            Nx.db.global.Characters[ch].Q = nil
        end
    end
end

---
-- Reset quest options to defaults
--
function Nx.Quest:OptsReset()

    local qopts = Nx.Quest:GetQuestOpts()

    Nx.qdb.profile.Quest.MapQuestGiversHighLevel = Nx.MaxPlayerLevel

    qopts.NXShowHeaders = true
    qopts.NXSortWatchMode = 1

    qopts.NXWAutoMax = nil
    qopts.NXWVisMax = 8
    qopts.NXWShowOnMap = true
    qopts.NXWWatchParty = true
    qopts.NXWATrack = false

    qopts.NXWHideBfAEmmissaries = false
    qopts.NXWHideLegionEmmissaries = false

    qopts.NXWHideUnfinished = false
    qopts.NXWHideGroup = false
    qopts.NXWHideNotInZone = false
    qopts.NXWHideNotInCont = false
    qopts.NXWHideDist = 20000

    qopts.NXWPriDist = 1
    qopts.NXWPriComplete = 50
    qopts.NXWPriLevel = 20

    qopts.NXWPriGroup = -100            -- Not used yet
    Nx.qdb.profile.QuestOpts = qopts
end
