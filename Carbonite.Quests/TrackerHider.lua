-- Carbonite.Quests | TrackerHider
-- Hides Blizzard's quest tracker frames (ObjectiveTrackerFrame,
-- WatchFrame, QuestWatchFrame, QuestTimerFrame) when the user has the Carbonite
-- tracker enabled. Also owns the EditMode hooks that suspend
-- hiding while the user is editing layouts, and the larger
-- ToggleQuestLog overrides that route Blizzard panel state through
-- Carbonite's map. Lifted from NxQuest.lua to keep the engine file
-- focused.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed.
local InCombatLockdown = _G.InCombatLockdown or _G.InCombatLockdown
local UnitName = _G.UnitName or _G.UnitName

-- BLIZZARD TRACKER HIDING (Retail + Classic + Anniversary + MoP Classic)
-- Checked = hide; Unchecked = show.
-------------------------------------------------------------------------------

local NX_TRACKER_FRAMES = {
    "ObjectiveTrackerFrame", -- Retail / modern
    "WatchFrame",            -- Classic / MoP Classic / Anniversary
    "QuestWatchFrame",       -- Fallback (some UI variants)
    "QuestTimerFrame",       -- Anniversary / Classic timed quests
}

local function NxTracker_IsProtectedAndLockedDown(frame)
    return frame and frame.IsProtected and frame:IsProtected() and InCombatLockdown()
end

function Nx.Quest:TrackerHider_Init()
    if self._trackerHider then
        return
    end

    local hiddenParent = CreateFrame("Frame", nil, UIParent)
    -- The hider needs a valid rect: MoP Classic's Wrath-style
    -- WatchFrame_Update computes (WatchFrame:GetTop() -
    -- WatchFrame:GetParent():GetBottom()) on every quest-log event,
    -- even while the tracker is hidden. An unanchored, unsized parent
    -- has no rect, so GetBottom() returns nil and Blizzard's arithmetic
    -- errors out (WatchFrame.lua:471 "arithmetic on a nil value").
    hiddenParent:SetAllPoints(UIParent)
    hiddenParent:Hide()

    self._trackerHider = {
        hiddenParent = hiddenParent,
        hooked = {},
        orig = {},
        pending = false,
    }

    local driver = CreateFrame("Frame", nil, UIParent)
    self._trackerHider.driver = driver

    driver:RegisterEvent("PLAYER_LOGIN")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    driver:RegisterEvent("ADDON_LOADED")

    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and not self._trackerHider.pending then
            return
        end
        self._trackerHider.pending = false
        self:TrackerHider_Apply()
    end)
end

function Nx.Quest:TrackerHider_ShouldHide()
    -- While Blizzard's Edit Mode is open the user almost certainly wants
    -- to position Blizzard's tracker frame, so let it show even if our
    -- "hide blizz tracker" preference is on. We restore the hide on
    -- EditMode exit via the EditMode.Enter / EditMode.Exit hooks.
    if self._editModeActive then
        return false
    end
    local qProfile = Nx.qdb and Nx.qdb.profile
    local enabled = qProfile and qProfile.Quest and qProfile.Quest.Enable
    local watchProfile = qProfile and qProfile.QuestWatch
    return enabled and watchProfile and watchProfile.HideBlizz == true
end

-- Hook EditMode events so TrackerHider yields while the user is
-- positioning frames. Available on retail and Cata Classic onward;
-- the EventRegistry / EditModeManagerFrame check makes this a no-op
-- on flavors without it (Classic Era, TBC).
function Nx.Quest:TrackerHider_BindEditMode()
    if self._editModeBound then return end
    if not (EventRegistry and EditModeManagerFrame) then return end
    self._editModeBound = true
    EventRegistry:RegisterCallback("EditMode.Enter", function()
        Nx.Quest._editModeActive = true
        Nx.Quest:TrackerHider_Apply()
    end)
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        Nx.Quest._editModeActive = false
        Nx.Quest:TrackerHider_Apply()
    end)
end

function Nx.Quest:TrackerHider_CaptureOriginal(frame, key)
    local h = self._trackerHider
    if not h or h.orig[key] then
        return
    end

    local mouseEnabled = true
    if frame.IsMouseEnabled then
        mouseEnabled = frame:IsMouseEnabled()
    end

    h.orig[key] = {
        parent = frame:GetParent(),
        alpha = frame:GetAlpha(),
        mouseEnabled = mouseEnabled,
    }
end

function Nx.Quest:TrackerHider_SetVisible(frame, key, visible)
    local h = self._trackerHider
    if not h or not frame then
        return
    end

    if NxTracker_IsProtectedAndLockedDown(frame) then
        h.pending = true
        return
    end

    self:TrackerHider_CaptureOriginal(frame, key)
    local orig = h.orig[key]

    if visible then
        frame:SetParent((orig and orig.parent) or UIParent)
        frame:SetAlpha((orig and orig.alpha) or 1)
        if frame.EnableMouse then
            frame:EnableMouse(orig and orig.mouseEnabled ~= false or true)
        end

        -- Blizzard_QuestTimer owns whether QuestTimerFrame is shown: its
        -- Update method shows the frame only while GetQuestTimers() returns at
        -- least one active timer. Force-showing it here would leave an empty
        -- timer panel when the Carbonite hide option is disabled. Refresh the
        -- Blizzard state after restoring the frame instead.
        if key == "QuestTimerFrame" then
            if type(frame.Update) == "function" then
                frame:Update()
            elseif frame.numTimers and frame.numTimers > 0 then
                frame:Show()
            else
                frame:Hide()
            end
        else
            frame:Show()
        end
        return
    end

    frame:SetParent(h.hiddenParent)
    frame:SetAlpha(0)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    frame:Hide()
end

function Nx.Quest:TrackerHider_HookFrame(name)
    local h = self._trackerHider
    if not h or h.hooked[name] then
        return
    end

    local frame = _G[name]
    if not frame or not frame.HookScript then
        return
    end

    h.hooked[name] = true
    frame:HookScript("OnShow", function(f)
        if self:TrackerHider_ShouldHide() then
            self:TrackerHider_SetVisible(f, name, false)
        end
    end)
end

function Nx.Quest:TrackerHider_Apply()
    if not self._trackerHider then
        self:TrackerHider_Init()
    end

    -- Lazy-bind EditMode events; safe to call multiple times.
    self:TrackerHider_BindEditMode()

    local hide = self:TrackerHider_ShouldHide()

    for i = 1, #NX_TRACKER_FRAMES do
        local name = NX_TRACKER_FRAMES[i]
        local frame = _G[name]
        if frame then
            self:TrackerHider_HookFrame(name)
            self:TrackerHider_SetVisible(frame, name, not hide)
        end
    end
end

function Nx.Quest:Init()


    self.Enabled = Nx.qdb.profile.Quest.Enable
    if not self.Enabled then

--        Nx.Quest = nil
        Nx.Quests = nil    -- Data
        -- Ensure the Blizzard tracker is not left hidden when the quest module is disabled.
        self:TrackerHider_Apply()

        return
    end

    -- Keep Blizzard tracker visibility in sync with the profile toggle (cross-version safe).
    self:TrackerHider_Apply()


    self.GOpts = Nx.db.profile

    if Nx.qdb.profile.QuestWatch.BlizzModify then
--        if not GetCVarBool ("advancedWatchFrame") then

--            SetCVar ("questFadingDisable", 1)    --V4 gone
            SetCVar ("autoQuestProgress", 0)
            SetCVar ("autoQuestWatch", 0)
--            SetCVar ("advancedWatchFrame", 1)
--            SetCVar ("watchFrameIgnoreCursor", 0)
--        end
    else
        SetCVar ("autoQuestProgress", 1)
        SetCVar ("autoQuestWatch", 1)
    end

    -- DEBUG
--    self.OldSelectQuestLogEntry = SelectQuestLogEntry
--    SelectQuestLogEntry = Nx.Quest.SelectQuestLogEntry

    -- Force it to create/enable and then we disable
    -- Use QuestMapFrame for retail, QuestLogFrame for classic
    local questFrame = QuestMapFrame or QuestLogFrame
    if questFrame then
        GetUIPanelWidth(questFrame)
        questFrame:SetAttribute("UIPanelLayout-enabled", false)
    end

    if QuestLogDetailFrame then    -- Patch 3.2
        GetUIPanelWidth(QuestLogDetailFrame)
        QuestLogDetailFrame:SetAttribute("UIPanelLayout-enabled", false)
    end

    local Map = Nx.Map

    self.QIds = {}                    -- Our quests by id
    self.QIdsNew = {}                -- Time stamp of getting a new quest. [Id] = time()

    self.Tracking = {}
    self.Sorted = {}

    self.CurQ = {}                    -- Current quests (including gotos)
    self.RealQ = {}                -- Real Blizzard quests
    self.RealQEntries = 0
    self.PartyQ = {}                -- Party quests

    self.IdToCurQ = {}

    self.HeaderExpanded = {}    -- Blizzard quest headers we expanded
    self.HeaderHide = {}            -- Names of quest headers to hide

    self.RcvPlyrLast = "None"
    self.RcvCnt = 0
    self.RcvTotal = 0
    self.FriendQuests = {}

    self.IconTracking = {}
    self.QInit = false

    self:CalcWatchColors()

    self.TagNames = {
        ["Group"] = "+",
        ["Legendary"] = "L",
        ["Heroic"] = "H",
        ["Account"] = "A",
        ["Raid"] = "R",
    }

    self.PerColors = {
        "|cffc00000", "|cffc03000", "|cffc06000", "|cffc09000", "|cffc0c000", "|cff90c000", "|cff60c000", "|cff30c000", "|cff00c000",
    }

    self.CapturePlyrData = {}

    self.CapFactionAbr = {
        ["Argent Crusade"] = 1,
        ["Argent Dawn"] = 2,
        ["Ashtongue Deathsworn"] = 3,
        ["Bloodsail Buccaneers"] = 4,
        ["Booty Bay"] = 5,
        ["Brood of Nozdormu"] = 6,
        ["Cenarion Circle"] = 7,
        ["Cenarion Expedition"] = 8,
        ["Darkmoon Faire"] = 9,
        ["Darkspear Trolls"] = 10,
        ["Darnassus"] = 11,
        ["Everlook"] = 12,
        ["Exodar"] = 13,
        ["Explorers' League"] = 14,
        ["Frenzyheart Tribe"] = 15,
        ["Frostwolf Clan"] = 16,
        ["Gadgetzan"] = 17,
        ["Gelkis Clan Centaur"] = 18,
        ["Gnomeregan Exiles"] = 19,
        ["Honor Hold"] = 20,
        ["Hydraxian Waterlords"] = 21,
        ["Ironforge"] = 22,
        ["Keepers of Time"] = 23,
        ["Kirin Tor"] = 24,
        ["Knights of the Ebon Blade"] = 25,
        ["Kurenai"] = 26,
        ["Lower City"] = 27,
        ["Magram Clan Centaur"] = 28,
        ["Netherwing"] = 29,
        ["Ogri'la"] = 30,
        ["Orgrimmar"] = 31,
        ["Ratchet"] = 32,
        ["Ravenholdt"] = 33,
        ["Sha'tari Skyguard"] = 34,
        ["Shattered Sun Offensive"] = 35,
        ["Shen'dralar"] = 36,
        ["Silvermoon City"] = 37,
        ["Silverwing Sentinels"] = 38,
        ["Sporeggar"] = 39,
        ["Stormpike Guard"] = 40,
        ["Stormwind"] = 41,
        ["Syndicate"] = 42,
        ["The Aldor"] = 43,
        ["The Consortium"] = 44,
        ["The Defilers"] = 45,
        ["The Frostborn"] = 46,
        ["The Hand of Vengeance"] = 47,
        ["The Kalu'ak"] = 48,
        ["The League of Arathor"] = 49,
        ["The Mag'har"] = 50,
        ["The Oracles"] = 51,
        ["The Scale of the Sands"] = 52,
        ["The Scryers"] = 53,
        ["The Sha'tar"] = 54,
        ["The Silver Covenant"] = 55,
        ["The Sons of Hodir"] = 56,
        ["The Taunka"] = 57,
        ["The Violet Eye"] = 58,
        ["The Wyrmrest Accord"] = 59,
        ["Thorium Brotherhood"] = 60,
        ["Thrallmar"] = 61,
        ["Thunder Bluff"] = 62,
        ["Timbermaw Hold"] = 63,
        ["Tranquillien"] = 64,
        ["Undercity"] = 65,
        ["Valiance Expedition"] = 66,
        ["Warsong Offensive"] = 67,
        ["Warsong Outriders"] = 68,
        ["Wildhammer Clan"] = 69,
        ["Wintersaber Trainers"] = 70,
        ["Zandalar Tribe"] = 71,
    }

    -- Frequency labels for Nx.QuestFreq codes (replaces the old hardcoded
    -- DailyTypes/DailyIds/DailyDungeonIds/DailyPVPIds tables; daily/weekly
    -- detection now comes from the generated Nx.QuestFreq data file and the
    -- reward payload from Nx.QuestReward).
    self.QuestFreqLabels = {
        ["d"]  = L["Daily"],
        ["w"]  = L["Weekly"],
        ["dd"] = L["Daily Dungeon"],
        ["dh"] = L["Daily Heroic"],
        ["dp"] = L["Daily PvP"],
    }

    --    DEBUG for Jamie
    Nx.Quest:LoadQuestDB()
    --

    self.List:Open()
    self.Watch:Open()
    self.WQList:Open()

    -- Menu

    local menu = Nx.Menu:Create (self.Map.Frm)
    self.IconMenu = menu

    menu:AddItem (0, "Track", self.Menu_OnTrack, self)
    menu:AddItem (0, "Show Quest Log", self.Menu_OnShowQuest, self)
    self.IconMenuIWatch = menu:AddItem (0, "Watch", self.Menu_OnWatch, self)

    menu:AddItem (0, "Add Note", self.Map.Menu_OnAddNote, self.Map)

    -- Hook quests
    --
    -- We use hooksecurefunc (post-call) instead of replacing the globals.
    -- Replacing AcceptQuest / GetQuestReward meant any error inside our
    -- wrapper aborted the original Blizzard call and the quest never
    -- actually accepted/turned in. With a post-hook the user-visible
    -- action always completes; our bookkeeping is best-effort and
    -- protected by pcall so a Lua error here can never block turn-in.

    hooksecurefunc("AcceptQuest", function(...)
        local ok, err = pcall(Nx.Quest.RecordQuestAcceptOrFinish, Nx.Quest)
        if not ok then
            Nx.prtD("AcceptQuest hook error: %s", tostring(err))
        end
    end)

    hooksecurefunc("GetQuestReward", function(choice, ...)
        local ok, err = pcall(Nx.Quest.FinishQuest, Nx.Quest)
        if not ok then
            Nx.prtD("GetQuestReward hook error: %s", tostring(err))
        end
    end)

    QuestFrameDetailPanel:HookScript ("OnShow", function ()
        local auto = Nx.qdb.profile.Quest.AutoAccept
        if IsShiftKeyDown() and IsControlKeyDown() then
            auto = not auto
        end
        if auto then
            AcceptQuest()
            QuestFrame:Hide();
            QuestFrameDetailPanel:Hide()
        end
    end);

    -- Hook tooltip

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        -- Retail/DF+ secure tooltip API: avoids tainting GameTooltip layout state,
        -- which otherwise breaks Blizzard code like AddSuppressedPinsToTooltip.
        local function questPostCall(tooltip)
            if tooltip == GameTooltip then
                Nx.Quest:TooltipProcess()
            end
        end
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, questPostCall)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, questPostCall)
        if Enum.TooltipDataType.Quest then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Quest, questPostCall)
        end
    else
        local ttHooks = {
            "SetAction",
--            "SetAuctionItem",
            "SetBagItem",
            "SetGuildBankItem",
            "SetHyperlink",
            "SetInboxItem",
            "SetInventoryItem",
            "SetLootItem",
            "SetLootRollItem",
            "SetMerchantItem",
            --"SetRecipeReagentItem",
            --"SetRecipeResultItem",
            "SetQuestItem",
            "SetQuestLogItem",
            "SetTradeTargetItem",
        }

        for k, name in ipairs (ttHooks) do
                hooksecurefunc (GameTooltip, name, Nx.Quest.TooltipHook)
        end
--        GameTooltip:HookScript("OnTooltipSetUnit", Nx.Quest.TooltipHook)
    end

    local unitNames = {    -- 5 letter and shorter words are already blocked
        "Hunter", "Paladin", "Priest", "Monk",
        "Shaman", "Warlock", "Warrior", "Deathknight"
    }

    self.TTIgnore = {
        ["Attack"] = true,
        ["Lumber Mill"] = true,
        ["Stables"] = true,
        ["Blacksmith"] = true,
        ["Gold Mine"] = true,
    }

    self.TTIgnore[UnitName ("player")] = true

    for _, v in pairs (unitNames) do
        self.TTIgnore[v] = true
    end

    self.TTChange = {
        ["Bloodberry Bush"] = "Bloodberries",
        ["Erratic Sentry"] = "Erratic Sentries",
    }

    -- Quest log toggle handling - different approach for Classic vs Retail
    if QuestLogFrame then
        -- Classic: Hook the QuestLogFrame OnShow
        local func = function ()
            local testAlt = IsAltKeyDown() and not self.IgnoreAlt
            if Nx.qdb.profile.Quest.UseAltLKey then
                testAlt = not testAlt
            end
            if not testAlt then
                HideUIPanel(QuestLogFrame)
                if self.InShowUIPanel then
                    Nx.Quest:HideUIPanel(QuestMapFrame)
                    self.InShowUIPanel = false
                else
                    Nx.Quest:ShowUIPanel(QuestMapFrame)
                    self.InShowUIPanel = true
                end
            end
        end
        QuestLogFrame:HookScript("OnShow", func)
    else
        -- Retail: Override ToggleQuestLog
        Nx.Quest.OldToggleQuestLog = ToggleQuestLog
        function ToggleQuestLog(...)
            Nx.Map.WMFOnShow = false
            local orig = IsAltKeyDown() and not self.IgnoreAlt
            if Nx.qdb.profile.Quest.UseAltLKey then
                orig = not orig
            end
            if not orig then
                if self.InShowUIPanel then
                    Nx.Quest:HideUIPanel(QuestMapFrame)
                    self.InShowUIPanel = false
                else
                    Nx.Quest:ShowUIPanel(QuestMapFrame)
                    self.InShowUIPanel = true
                end
            else
                Nx.Quest.OldToggleQuestLog(...)
            end
            Nx.Map.WMFOnShow = true
        end
    end
end
