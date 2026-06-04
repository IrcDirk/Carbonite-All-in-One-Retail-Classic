-- Carbonite.Quests | QuestWindow
-- The Carbonite Quest panel: window creation, attach-frames,
-- per-frame update, select-quest-in-list, the right-click menu
-- handlers, list-control event routing, chat-link builder, quest-log
-- update handler, the long "Update list security stub" body, the
-- cloned Blizzard quest-POI textures, and the right-side Details
-- frame. Lifted from NxQuest.lua to keep the engine file smaller.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals (mirrors the prelude in NxQuest.lua).
local bit_band   = bit.band
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local max        = math.max
local min        = math.min
local strfind    = strfind  or string.find
local strsub     = strsub   or string.sub
local strlower   = strlower or string.lower
local format     = format   or string.format
local gsub       = gsub     or string.gsub
local tinsert    = tinsert  or table.insert
local sort       = sort     or table.sort
local GetTime              = GetTime
local UnitLevel            = UnitLevel
local UnitName             = UnitName
local InCombatLockdown     = InCombatLockdown
local GetQuestLogLeaderBoard  = GetQuestLogLeaderBoard
local GetNumQuestLeaderBoards = GetNumQuestLeaderBoards
local GetDailyQuestsCompleted = GetDailyQuestsCompleted
local GetQuestResetTime       = GetQuestResetTime

-- Shared mutable state with NxQuest.lua (promoted to namespace
-- during the WorldQuestWindow extraction).
local worldquestdb = Nx.Quest.worldquestdb

-- Promoted from NxQuest.lua's file-local cache helper.
local GetCachedDifficultyColorStr = Nx.Quest.GetCachedDifficultyColorStr

-- Quest list
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Open and init or toggle Quest frame
-------------------------------------------------------------------------------

function Nx.Quest.List:Open()
    local qopts = Nx.Quest:GetQuestOpts()
    self.QOpts = qopts

    local TabBar = Nx.TabBar

    self.ShowAllZones = false
    self.Opened = true

    -- Create window

    local win = Nx.Window:Create ("NxQuestList")
    self.Win = win

    win:CreateButtons (true, true)
    win:InitLayoutData (nil, -.24, -.15, -.52, -.65)

    tinsert (UISpecialFrames, "QuestMapFrame")
    tinsert (UISpecialFrames, win.Frm:GetName())

    win.Frm:SetToplevel (true)
    win.Frm:SetResizeBounds (250, 120)

    win:SetUser (self, self.OnWin)
    CarboniteQuest:RegisterEvent ("PLAYER_LOGIN", "OnQuestUpdate")
    --CarboniteQuest:RegisterEvent ("UPDATE_FACTION", "OnQuestUpdate")
    --CarboniteQuest:RegisterEvent ("GARRISON_MISSION_COMPLETE_RESPONSE", "OnQuestUpdate")
    --CarboniteQuest:RegisterEvent ("WORLD_QUEST_COMPLETED_BY_SPELL", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("UNIT_QUEST_LOG_CHANGED", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("QUEST_PROGRESS", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("QUEST_COMPLETE", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("QUEST_ACCEPTED", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("QUEST_REMOVED", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("QUEST_TURNED_IN", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("QUEST_DETAIL", "OnQuestUpdate")
    if C_SuperTrack then
        -- Retail / Wrath+ Classic. Lets the map blob/arrow follow Blizzard's
        -- super-tracked quest (e.g. set by clicking a quest POI).
        CarboniteQuest:RegisterEvent ("SUPER_TRACKING_CHANGED", "OnQuestUpdate")

        -- Toggle-on-second-click for the super-tracked quest. Blizzard's
        -- world-map quest pin sits on top of Carbonite's icon and eats
        -- the click, so our IconOnMouseDown never runs and the user can
        -- never deactivate the active quest by clicking the pin again.
        -- This hook intercepts every SetSuperTrackedQuestID call (Blizz
        -- pin click, objective tracker, addons, etc.) and converts a
        -- second call with the same id into a clear.
        if C_SuperTrack.SetSuperTrackedQuestID and not Nx.Quest._stHookInstalled then
            Nx.Quest._stHookInstalled = true
            Nx.Quest._stLastSet = 0
            hooksecurefunc(C_SuperTrack, "SetSuperTrackedQuestID", function(qID)
                qID = qID or 0
                local now = GetTime and GetTime() or 0

                -- Lockout window after a user-initiated toggle-off. Blizzard's
                -- own QuestObjectiveTracker / WorldMap pin code likes to
                -- auto-restore the super-track to the next available quest
                -- right after we clear it; squash any non-zero set during
                -- the lockout so the user's "click off" decision sticks.
                if Nx.Quest._stLockoutUntil and now < Nx.Quest._stLockoutUntil then
                    if qID > 0 then
                        -- Defer in combat: this hook can run inside
                        -- Blizzard's secure call chain, and re-firing
                        -- SUPER_TRACKING_CHANGED from our taint trips the
                        -- combat-protected SetPassThroughButtons in the
                        -- QuestDataProvider listeners. The suppress flag
                        -- moves inside so it's armed right before the call.
                        Nx.SuperTrackSafe(function()
                            Nx.Quest._stSuppressHook = true
                            C_SuperTrack.SetSuperTrackedQuestID(0)
                        end)
                    end
                    return
                end

                -- Skip our own toggle-clear so the hook doesn't recurse.
                if Nx.Quest._stSuppressHook then
                    Nx.Quest._stSuppressHook = false
                    return
                end

                -- Ignore clears for last-set tracking. Blizzard's map pin
                -- code emits a clear-then-set pair on every click, so
                -- letting the clear reset _stLastSet meant the matching
                -- set never appeared as a duplicate of the previous click.
                if qID == 0 then
                    return
                end

                -- Setting the same id that's already active -> toggle off.
                if qID == Nx.Quest._stLastSet
                   and qID == (Nx.Quest.ActiveQID or 0) then
                    -- Secure clear + the flags it depends on go through
                    -- SuperTrackSafe (deferred in combat — the tainted
                    -- SUPER_TRACKING_CHANGED chain trips the protected
                    -- SetPassThroughButtons). The blob hide rides along:
                    -- WorldMapBlobFrame refuses insecure calls in combat.
                    Nx.SuperTrackSafe(function()
                        Nx.Quest._stSuppressHook = true
                        Nx.Quest.UserClearedActive = true
                        C_SuperTrack.SetSuperTrackedQuestID(0)
                        -- Blizzard quest area blob is drawn into a
                        -- separate WorldMapBlobFrame (QMap.QuestWin) and
                        -- doesn't auto-hide on super-track clear; do it
                        -- explicitly so the area stops shading the map.
                        local f = NxMap1 and NxMap1.NxMap
                        if f and f.QuestWin then
                            if f.QuestWin.DrawNone then f.QuestWin:DrawNone() end
                            if f.QuestWin.Hide then f.QuestWin:Hide() end
                        end
                    end)
                    Nx.Quest.ActiveQID = 0
                    Nx.Quest.ActiveObjI = 0
                    if Nx.Quest.Tracking then
                        Nx.Quest.Tracking[qID] = nil
                    end
                    if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1] then
                        local m1 = Nx.Map.Maps[1]
                        if m1.ClearTargets then m1:ClearTargets() end
                    end
                    Nx.Quest._stLastSet = 0
                    Nx.Quest._stLockoutUntil = now + 0.6
                else
                    Nx.Quest._stLastSet = qID
                end
            end)
        end
    elseif AddQuestWatch and not Nx.Quest._addWatchHookInstalled then
        -- Classic flavors without C_SuperTrack (TBC 2.5, Era 1.15). Blizzard's
        -- world-map quest pin can sit on top of Carbonite's typ=32 point
        -- icon and eat the click — Blizzard's classic pin click ultimately
        -- calls AddQuestWatch(questIndex), so hooking that gives us a
        -- reliable "user clicked a quest pin" signal. Route to
        -- SetActiveCarboniteQuest so the goto arrow follows the
        -- first-incomplete-objective heuristic instead of staying anchored
        -- on whatever the quest log was last pointing at.
        Nx.Quest._addWatchHookInstalled = true
        hooksecurefunc("AddQuestWatch", function(questIndex)
            if Nx.Quest._addWatchSuppress then return end
            local qId
            if GetQuestIDFromLogIndex then
                qId = GetQuestIDFromLogIndex(questIndex)
            elseif C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
                qId = C_QuestLog.GetQuestIDForLogIndex(questIndex)
            end
            if not qId or qId <= 0 then return end
            -- Toggle: same active quest -> clear; new -> activate.
            if (Nx.Quest.ActiveQID or 0) == qId then
                Nx.Quest._addWatchSuppress = true
                Nx.Quest:SetActiveCarboniteQuest(qId, questIndex) -- toggles off
                Nx.Quest.ActiveObjI = 0
                if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1]
                   and Nx.Map.Maps[1].ClearTargets then
                    Nx.Map.Maps[1]:ClearTargets()
                end
                Nx.Quest._addWatchSuppress = false
            else
                Nx.Quest._addWatchSuppress = true
                Nx.Quest:SetActiveCarboniteQuest(qId, questIndex)
                Nx.Quest._addWatchSuppress = false
            end
        end)
    end
    --CarboniteQuest:RegisterEvent ("QUEST_WATCH_UPDATE", "OnQuestUpdate")
    --CarboniteQuest:RegisterEvent ("SCENARIO_UPDATE", "OnQuestUpdate")
    --CarboniteQuest:RegisterEvent ("SCENARIO_CRITERIA_UPDATE", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("WORLD_STATE_TIMER_START", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("WORLD_STATE_TIMER_STOP", "OnQuestUpdate")
    --CarboniteQuest:RegisterEvent ("QUEST_POI_UPDATE", "OnQuestUpdate")
    CarboniteQuest:RegisterEvent ("TRACKED_ACHIEVEMENT_UPDATE", "OnTrackedAchievementUpdate")
    CarboniteQuest:RegisterEvent ("TRACKED_ACHIEVEMENT_LIST_CHANGED", "OnTrackedAchievementsUpdate")
    CarboniteQuest:RegisterEvent ("CHAT_MSG_COMBAT_FACTION_CHANGE", "OnChat_msg_combat_faction_change")
    CarboniteQuest:RegisterEvent ("CHAT_MSG_RAID_BOSS_WHISPER", "OnChat_msg_raid_boss_whisper")
    -- Filter Edit Box

    local f = CreateFrame ("EditBox", "NxQuestFilter", win.Frm)
    self.FilterFrm = f

    f.NxInst = self

    f:SetScript ("OnEditFocusGained", self.FilterOnEditFocusGained)
    f:SetScript ("OnEditFocusLost", self.FilterOnEditFocusLost)
    f:SetScript ("OnTextChanged", self.FilterOnTextChanged)
    f:SetScript ("OnEnterPressed", self.FilterOnEnterPressed)
    f:SetScript ("OnEscapePressed", self.FilterOnEscapePressed)

    f:SetFontObject ("NxFontS")

    local t = f:CreateTexture()
    t:SetColorTexture (.1, .2, .3, 1)
    t:SetAllPoints (f)
    f.texture = t

    f:SetAutoFocus (false)
    f:ClearFocus()

    win:Attach (f, 0, 1, 0, 18)

    self.FilterDesc = L["Search: [click]"]
    self.FilterDescEsc = L["Search: %[click%]"]

--    if Nx.Free then
--        self.FilterDesc = L["Search: "] .. Nx.FreeMsg
--    end

    self.Filters = { "", "", "", ""}

    f:SetText (self.FilterDesc)
    f:SetMaxLetters (30)

    -- List

    Nx.List:SetCreateFont ("Quest.QuestFont", 12)

    local list = Nx.List:Create ("Quest", 0, 0, 1, 1, win.Frm)
    self.List = list

    list:SetUser (self, self.OnListEvent)

    list:SetLineHeight (0, 6)

    list:ColumnAdd ("", 1, 20)
    list:ColumnAdd ("", 2, 300)
--    list:ColumnAdd ("Lvl", 3, 20, "CENTER")
    list:ColumnAdd ("", 3, 0)
    list:ColumnAdd ("", 4, 600)
    list:ColumnAdd ("", 5, 200)
    list:ColumnAdd ("", 6, 500)

    -- Create menu

    local menu = Nx.Menu:Create (list.Frm, 240)
    self.Menu = menu

    local menui1 = {}
    self.MenuItems1 = menui1

    local menui2 = {}
    self.MenuItems2 = menui2

    local menui3 = {}
    self.MenuItems3 = menui3

    local menui4 = {}
    self.MenuItems4 = menui4

    local item = menu:AddItem (0, L["Toggle High Watch Priority"], self.Menu_OnHighPri, self)
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Show Category Headers"], self.Menu_OnShowHeaders, self)
    item:SetChecked (qopts.NXShowHeaders)
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Show Objectives"], self.Menu_OnShowObjectives, self)
    item:SetChecked (qopts.NXShowObj)
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Show Only Party Quests"], self.Menu_OnShowParty, self)
    item:SetChecked (false)
    tinsert (menui1, item)

    local item = menu:AddItem (0, "")
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Watch All Quests"], self.Menu_OnWatchAll, self)
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Watch All Completed Quests"], self.Menu_OnWatchCompleted, self)
    tinsert (menui1, item)

    local item = menu:AddItem (0, "")
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Broadcast Quest Changes To Party"], nil, self)
    item:SetChecked (Nx.qdb.profile.Quest, "BroadcastQChanges")
    tinsert (menui1, item)
    local item = menu:AddItem (0, L["Send Quest Status To Party"], self.Menu_OnSendQInfo, self)
    tinsert (menui1, item)
    local item = menu:AddItem (0, L["Share"], self.Menu_OnShare, self)
    self.MenuIShare = item
    tinsert (menui1, item)

    local item = menu:AddItem (0, "")
    tinsert (menui1, item)
    local item = menu:AddItem (0, L["Abandon"], self.Menu_OnAbandon, self)
    tinsert (menui1, item)

    local item = menu:AddItem (0, L["Remove"], self.Menu_OnCompleted, self)
    tinsert (menui2, item)

    local item = menu:AddItem (0, L["Remove All"], self.Menu_OnHistoryRemoveAll, self)
    tinsert (menui2, item)

    local function func()
        QHistLogin = Nx:ScheduleTimer(Nx.Quest.QuestQueryTimer,.1,Nx.Quest)
    end
    local item = menu:AddItem (0, L["Get Completed From Server"], func, self)
    tinsert (menui2, item)

    local item = menu:AddItem (0, L["Mark As Previously Completed"], self.Menu_OnCompleted, self)
    tinsert (menui3, item)

    tinsert (menui3, menu:AddItem (0, L["Goto Quest Giver"], self.Menu_OnGoto, self))

    local item = menu:AddItem (0, "")
    tinsert (menui2, item)
    tinsert (menui3, item)

    local item = menu:AddItem (0, L["Show All Quests"], self.Menu_OnShowAllQuests, self)
    item:SetChecked (false)
    tinsert (menui2, item)
    tinsert (menui3, item)

    local item = menu:AddItem (0, L["Show Low Level Quests"], self.Menu_OnShowLowLevel, self)
    item:SetChecked (false)
--    tinsert (menui2, item)
    tinsert (menui3, item)

    local item = menu:AddItem (0, L["Show High Level Quests"], self.Menu_OnShowHighLevel, self)
    item:SetChecked (false)
--    tinsert (menui2, item)
    tinsert (menui3, item)

    local item = menu:AddItem (0, L["Show Quests From All Zones"], self.Menu_OnShowAllZones, self)
    item:SetChecked (false)
    tinsert (menui2, item)
    tinsert (menui3, item)

    local item = menu:AddItem (0, L["Show Finished Quests"], self.Menu_OnShowFinished, self)
    item:SetChecked (false)
    tinsert (menui3, item)

    local item = menu:AddItem (0, L["Show Only Non Dungeon Dailies"], self.Menu_OnShowOnlyDailies, self)
    item:SetChecked (false)
    tinsert (menui3, item)

    local item = menu:AddItem (0, "")
    tinsert (menui3, item)
    local item = menu:AddItem (0, L["Track None"], self.Menu_OnTrackNone, self)
    tinsert (menui3, item)

    local item = menu:AddItem (0, "")
    tinsert (menui1, item)
    tinsert (menui2, item)
    tinsert (menui3, item)

    local function func()
        Nx.Opts:Open ("Quest")
    end
    local item = menu:AddItem (0, L["Options..."], func)
    tinsert (menui1, item)
    tinsert (menui2, item)
    tinsert (menui3, item)

    -- Quest details

    local f = CreateFrame ("ScrollFrame", "NxQuestD", win.Frm, "NxQuestDetails")

    self.DetailsFrm = f
    f.NxSetSize = self.OnDetailsSetSize

    f:SetMovable (true)
    f:EnableMouse (true)
    f:SetFrameStrata ("MEDIUM")
    local t = f:CreateTexture()
    if Nx.qdb.profile.Quest.ScrollIMG then
        t:SetTexture ("Interface\\QuestFrame\\QuestBG", true, true)
    else
        t:SetColorTexture(Nx.Util_str2rgba(Nx.qdb.profile.Quest.DetailBC))
    end
    t:SetAllPoints (f)
    t:SetTexCoord(0, .585, 0.02, .655)
    f.texture = t

    f:Show()

    -- Create Tab Bar

    local bar = TabBar:Create (nil, win.Frm, 1, 1)
    self.Bar = bar

    local tbH = TabBar:GetHeight()

    win:Attach (bar.Frm, 0, 1, -tbH, 1)

    bar:SetUser (self, self.OnTabBar)

    self.TabSelected = 1

    bar:AddTab (L["Current"], 1, nil, true)
    bar:AddTab (L["History"], 2)
    bar:AddTab (L["Database"], 3)
    bar:AddTab (L["Player"], 4)

    -- Old attach

--    local qdf = getglobal ("QuestLogDetailScrollFrame")
--    win:Attach (qdf, 0, 1, .6, 1)
--[[
    local t = qdf:CreateTexture()
    t:SetColorTexture (.7, .7, .5, .7)
    t:SetAllPoints (qdf)
    qdf.texture = t
--]]
    -- Quest log

--    local qlogf = getglobal ("QuestLogFrame")
--    win:Attach (qlogf, .8, 1, 0, 1, true)

    --

    self:AttachFrames()
end

-------------------------------------------------------------------------------
-- Attach our frames
-------------------------------------------------------------------------------

function Nx.Quest.List:AttachFrames()
    local win = self.Win
    local list = self.List
    local tbH = Nx.TabBar:GetHeight()

    if Nx.qdb.profile.Quest.SideBySide then

        local r = .55
        if self.TabSelected ~= 1 then
            r = 1
        end
        win:Attach (list.Frm, 0, r, 18, -tbH)
        win:Attach (self.DetailsFrm, .55, 1, 18, -tbH)

    else
        local bot = .6
        if self.TabSelected ~= 1 then
            bot = -tbH
        end
        win:Attach (list.Frm, 0, 1, 18, bot)
        win:Attach (self.DetailsFrm, 0, 1, .6, -tbH)
    end
end

function Nx.Quest.List:UpdateMenu()

    local showi = self.MenuItems1
    local hidei1 = self.MenuItems2
    local hidei2 = self.MenuItems3

    if self.TabSelected == 2 then

        showi = self.MenuItems2
        hidei1 = self.MenuItems1

    elseif self.TabSelected == 3 then

        showi = self.MenuItems3
        hidei2 = self.MenuItems1
    end

    for k, v in pairs (hidei1) do
        v:Show (false)
    end

    for k, v in pairs (hidei2) do
        v:Show (false)
    end

    for k, v in pairs (showi) do        -- Do last so items in multiple lists work
        v:Show()
    end

    if self.TabSelected == 1 then

        local show = -1
        local i = self.List:ItemGetData()
        if i then

            local qi = bit_band (i, 0xff)
            if qi > 0 then
                local i, cur = Nx.Quest:FindCurByIndex (qi)
                if cur then
                    if cur.CanShare then
                        show = true
                    end
                end
            end
        end

        self.MenuIShare:Show (show)
    end
end

-------------------------------------------------------------------------------

function Nx.Quest:ShowUIPanel (frame)
    if self.InShowUIPanel then
        return
    end
    self.InShowUIPanel = true
    local detailFrm = QuestLogDetailFrame
    local orig = IsAltKeyDown() and not self.IgnoreAlt
    local opts = self.GOpts
    if Nx.qdb.profile.Quest.UseAltLKey then
        orig = not orig
    end
    if orig then    -- Show original quest log?
        self.IsOrigOpen = true
        --frame:SetScale (1)
        --QuestMapFrame:SetAttribute ("UIPanelLayout-enabled", true)
        --ShowUIPanel (WorldMapFrame)
        --if detailFrm then
            --detailFrm:SetScale (1)
        --end
        self:LightHeadedAttach (frame)
    else
        Nx.Quest.List:Refresh()
        self.IsOpen = true
        local win = self.List.Win
        if win and not GameMenuFrame:IsShown() then
            self:ExpandQuests()
            local wf    = win.Frm
            win:Show()
            self.List:Update()
            wf:Raise()
            --frame:Show()
            --if detailFrm then
                --detailFrm:SetScale (.1)
            --end
            self:LightHeadedAttach (wf, true)
        end
    end
    self.InShowUIPanel = false
end

-------------------------------------------------------------------------------

function Nx.Quest:HideUIPanel (frame)
    local orig = IsAltKeyDown() and not self.IgnoreAlt
    if Nx.qdb.profile.Quest.UseAltLKey then
        orig = not orig
    end
    if orig then
        --QuestMapFrame:SetAttribute ("UIPanelLayout-enabled", true)
        --HideUIPanel(WorldMapFrame)
        --Nx.Quest.OldWindow()
        --Nx.Quest.OldWindow()
        self.IsOrigOpen = false
    else
        self.IsOpen = false
        local detailFrm = QuestLogDetailFrame
        --if detailFrm then
            --detailFrm:SetScale (1)
        --end
        self.List.Win:Show (false)
        if self.List.List:ItemGetNum() > 0 then
            self.List.List:Empty()
        end
        self:RestoreExpandQuests()        -- Hide window first, then restore
        self.LHAttached = nil
    end
end

function Nx.Quest:LightHeadedAttach (frm, attach, onlyLevels)

    local lh = _G["LightHeaded"]
    local lhf = _G["LightHeadedFrame"]
    if not (lh and lhf) then
        return
    end

    local db = lh["db"]
    if not db then
        return
    end

    local profile = db["profile"]
    if not profile then
        return
    end

--    Nx.prtFrame ("LightHeaded", lhf)
--    Nx.prtFrameChildren ("LightHeaded", lhf)

    lhf:SetParent (frm)

    local lvl = frm:GetFrameLevel()
    local open = profile["open"]

    if not attach then

        lvl = lvl - 1
        local x = open and -15 or -328
        lhf:ClearAllPoints()
        lhf:SetPoint ("LEFT", frm, "RIGHT", x, 0)        --  OLD -50, 19

    else

        self.LHAttached = profile
        self.LHOpen = open

        lvl = open and lvl or 1
        local x = open and -4 or -326
        lhf:ClearAllPoints()
        lhf:SetPoint ("TOPLEFT", frm, "TOPRIGHT", x, -19)
    end

    lhf:SetFrameLevel (lvl)
    Nx.Util_SetChildLevels (lhf, lvl + 1)

    if not onlyLevels then

        lhf:Show()

        if not profile["attached"] then
            lh["LockUnlockFrame"](lh)
        end
    end
end

-------------------------------------------------------------------------------
-- Frame update. Called by main addon frame
-------------------------------------------------------------------------------

local elap = nil
function Nx.Quest:OnUpdate (elapsed)
    if not Nx.Quest.Initialized then
        return
    end

    -- DeaTHCorE - missing questwatch update... the quest range as a example are updated very late without updates,
    -- so i have added here a update every 1 secound. this update is any more required for update questwatch itembutton in
    -- conjunction with the InCombatLockdown() call ( :Hide() quest itembutton is a example for missing update by InCombatLockdown(),
    -- the call of :Hide() are not called a the frame lists etcetera are wiped.    )
    -- I have tested with a CPU Profiling addon and no performence lost i have seen...
    -- I call the update here to spare one more timer ;)
    if not elap then
        elap = GetTime()
        return
    end
    local t = GetTime()
    if t - elap >= 1 then
        Nx.Quest.Watch:Update()
        elap = t
    end

    if not self.List.Win:IsShown() then
--        Nx.prt ("skip")
        return
    end

    if self.LHAttached then

        local profile = self.LHAttached
        if self.LHOpen ~= profile["open"] then
            self:LightHeadedAttach (self.List.Win.Frm, true)
        end

        if Nx.Tick % 20 == 0 then
            self:LightHeadedAttach (self.List.Win.Frm, true, true)
        end
    end
end

-------------------------------------------------------------------------------
-- Select quest in list
-------------------------------------------------------------------------------

function Nx.Quest.List:Select (qId, qI)

    local list = self.List

    for n = 1, list:ItemGetNum() do

        local i = list:ItemGetData (n)
        if i then

            local qi = bit_band (i, 0xff)
            local qid = bit_rshift (i, 16)

            if qi == qI and qid == qId then

                Nx.Quest:SelectBlizz (qi)
                list:Select (n)
                self:Update()

                break
            end
        end
    end
end

-------------------------------------------------------------------------------

function Nx.Quest.List:GetCurSelected()

    local i = self.List:ItemGetData()
    if i then

        local qi = bit_band (i, 0xff)
        local qid = bit_rshift (i, 16)
        if qid > 0 or qi > 0 then
            local _, cur = Nx.Quest:FindCur (qid, qi)
            return cur
        end
--[[
        local qi = bit_band (i, 0xff)
        if qi > 0 then

            local i, cur = Nx.Quest:FindCurByIndex (qi)
            return cur
        else

            local qid = bit_rshift (i, 16)
            local i, cur = Nx.Quest:FindCur (qid)
            return cur
        end
--]]
    end
end

-------------------------------------------------------------------------------

function Nx.Quest.List:OnWin (typ)

    if typ == "Close" then
        HideUIPanel (QuestMapFrame)
--        QuestLogFrame:Hide()
    end
end

-------------------------------------------------------------------------------

function Nx.Quest.List:FilterOnEditFocusGained()

    Nx.ShowMessageTrial()

    local this = self            --V4
    local self = this.NxInst

    local s = self.Filters[self.TabSelected]
    if s ~= "" then
        this:SetText (s)
    else
        this:SetText ("")
    end
end

function Nx.Quest.List:FilterOnEditFocusLost()

    local this = self            --V4
    local self = this.NxInst

    if self.Filters[self.TabSelected] == "" then
        this:SetText (self.FilterDesc)
    end
end

function Nx.Quest.List:FilterOnTextChanged()

    local this = self            --V4
    local self = this.NxInst
    self.Filters[self.TabSelected] = gsub (this:GetText(), self.FilterDescEsc, "")
--    Nx.prt ("Filter #%s = %s", self.TabSelected, self.Filters[self.TabSelected])
    self:Update()
end

function Nx.Quest.List:FilterOnEnterPressed()
    local this = self            --V4
    this:ClearFocus()
end

function Nx.Quest.List:FilterOnEscapePressed()

    local this = self            --V4
    local self = this.NxInst
    self.Filters[self.TabSelected] = ""

    this:ClearFocus()
end

-------------------------------------------------------------------------------

function Nx.Quest.List:OnTabBar (index, click)

    self.FilterFrm:ClearFocus()

    self.TabSelected = index

    if index == 1 then
        self.DetailsFrm:Show()
        self:AttachFrames()
    else
        self.DetailsFrm:Hide()
        self:AttachFrames()
    end

    local s = self.Filters[self.TabSelected]
    s = s ~= "" and s or self.FilterDesc
    self.FilterFrm:SetText (s)

    self:Update()
end

-------------------------------------------------------------------------------
-- Menu handlers
-------------------------------------------------------------------------------

function Nx.Quest.List:Menu_OnGoto (item)

    local i = self.List:ItemGetData()
    if i then

        local qIndex = bit_band (i, 0xff)

        if qIndex > 0 then
            Nx.prt (L["Already have the quest!"])

        else
            local qId = bit_rshift (i, 16)
            Nx.Quest:Goto (qId)

            self:Update()
        end
    end
end

function Nx.Quest.List:Menu_OnHighPri (item)

    local cur = self:GetCurSelected()
    if cur then
        cur.HighPri = not cur.HighPri
        self:Update()
    end
end

function Nx.Quest.List:Menu_OnShowHeaders (item)

    self.QOpts.NXShowHeaders = item:GetChecked()
    Nx.Quest:SortQuests()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowObjectives (item)

    self.QOpts.NXShowObj = item:GetChecked()
--    Nx.Quest:SortQuests()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowAllQuests (item)
    self.ShowAllQuests = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowLowLevel (item)
    self.ShowLowLevel = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowHighLevel (item)
    self.ShowHighLevel = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowAllZones (item)
    self.ShowAllZones = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowFinished (item)
    self.ShowFinished = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowOnlyDailies (item)
    self.ShowOnlyDailies = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnShowParty (item)
    self.ShowParty = item:GetChecked()
    self:Update()
end

function Nx.Quest.List:Menu_OnCompleted (item)

    local i = self.List:ItemGetData()
    if i then

        local qId = bit_rshift (i, 16)
        local qStatus, qTime = Nx.Quest:GetQuest (qId)

        if qStatus == "C" then
            qStatus = "c"
        else
            qStatus = "C"
            qTime = time()
        end

--        Nx.prt ("ToggleQuestComplete %d %s %s", qId, qStatus, qTime)

        Nx.Quest:SetQuest (qId, qStatus, qTime)

        self:Update()
    end
end

function Nx.Quest.List:Menu_OnHistoryRemoveAll()

    local idT = Nx.Quest.IdToCurQ
    local questT = Nx.Quest.CurCharacter.Q

    for id in pairs (questT) do
        if not idT[id] then
            questT[id] = nil
        end
    end

    Nx.prt (L["History cleared"])
    self:Update()
end


function Nx.Quest.List:Menu_OnSortWatched (item)
    local on = item:GetChecked()
    Nx.Quest:SetWatchSortMode (on and 1 or 0)
end

function Nx.Quest.List:Menu_OnWatchAll()
    Nx.Quest:WatchAll()
    self:Update()
end

function Nx.Quest.List:Menu_OnWatchCompleted (item)

    local curq = Nx.Quest.CurQ

    if curq then

        for i, cur in ipairs (curq) do

--            Nx.prt ("Q #%d %s %s", i, cur.Title, cur.Complete or "nil")

            if cur.Complete and cur.Complete == 1 then
                Nx.Quest.Watch:Add (i)
            end
        end

        self:Update()
    end
end

function Nx.Quest.List:Menu_OnSendQInfo (item)

    local i = self.List:ItemGetData()
    if i then

        local qi = bit_band (i, 0xff)
        self:SendQuestInfo (qi)
    end
end

function Nx.Quest.List:SendQuestInfo (qi)

    if qi > 0 then

        self.SendQInfoQI = qi
        self.SendQInfoMode = -1
        self.SendQTarget = nil

        local box = Nx.FindActiveChatFrameEditBox()
        if box then
            local typ = box:GetAttribute ("chatType")
--            Nx.prt ("chattype %s", typ)
            if typ == "WHISPER" then
                self.SendQTarget = box:GetAttribute ("tellTarget")
                self.SendQLanguage = box["language"]
                ChatEdit_OnEscapePressed (box)
            end
        end

        QSendInfo = Nx:ScheduleTimer(self.OnSendQuestInfoTimer,0,self)
    end
end

function Nx.Quest.List:OnSendQuestInfoTimer()

    local qi = self.SendQInfoQI
    local i, cur = Nx.Quest:FindCurByIndex (qi) --qi > 0 and Nx.Quest:FindCurByIndex (qi) or nil, nil

    if not i then
        return
    end

    local sendStr
    local mode = self.SendQInfoMode

    if mode == -1 then

        sendStr = self:MakeDescLink (cur)
        mode = 0
--[[
    elseif mode == 0 then
        local str = strsub (cur.ObjText, 1, 180)
        str = format (" %s", str)
        str = gsub (str, "[\n\r\t]", "")
        if #cur.ObjText > 180 then
            str = str .. "..."
        end
        Nx.Com:Send ("P", str)
--]]
    else

        local desc = cur[mode]
        if not desc then
            return
        end

        sendStr = format ("  %s", desc)
    end

    if self.SendQTarget then
--        Nx.Com:Send ("W", sendStr, self.SendQTarget)
        SendChatMessage (sendStr, "WHISPER", self.SendQLanguage, self.SendQTarget);
    else
        Nx.Com:Send ("P", sendStr)
    end

    self.SendQInfoMode = mode + 1

    return .33
end

function Nx.Quest.List:Menu_OnShare (item)

    local i = self.List:ItemGetData()
    if i then

        local qi = bit_band (i, 0xff)
        if qi > 0 then
            if GetNumSubgroupMembers() > 0 then
                QuestLogPushQuest()
            else
                Nx.prt (L["Must be in party to share"])
            end
        end
    end
end

function Nx.Quest.List:Menu_OnAbandon (item)

    local i = self.List:ItemGetData()
    if i then

        local qIndex = bit_band (i, 0xff)
        local qId = bit_rshift (i, 16)
        Nx.Quest:Abandon (qIndex, qId)

--        self:Update()    -- Dialog gets closed!
    end
end

--[[
function Nx.Quest.List:Menu_OnTrackAll (item)

    local curq = Nx.Quest.CurQ

    if curq then

        for _, cur in ipairs (curq) do

            local quest = cur.Q
            if quest then
                Nx.Quest.Tracking[cur.QId] = 0xffffffff        -- Track all
            end
        end

        self:Update()
    end
end
--]]

function Nx.Quest.List:Menu_OnTrackNone (item)
    Nx.Quest.Watch:ClearAutoTarget()
    self:Update()
end

-------------------------------------------------------------------------------
-- On list control updates
-------------------------------------------------------------------------------

function Nx.Quest.List:OnListEvent (eventName, sel, val2, click)

    local Quest = Nx.Quest
    local Map = Nx.Map

    local itemData = self.List:ItemGetData (sel) or 0
    local hdrCur = self.List:ItemGetDataEx (sel, 1)

    local qIndex = bit_band (itemData, 0xff)
    local qId = bit_rshift (itemData, 16)

    local shift = IsShiftKeyDown() or eventName == "mid"

--    Nx.prt (format ("Data #%d, Id%d", qIndex, qId))

    if eventName == "select" or eventName == "mid" or eventName == "back" then

        local columnId = val2

        if shift then

            if hdrCur then        -- Header?

                local setStr

                for n = sel + 1, sel + 99 do        -- Toggle watch of all

                    local itemData = self.List:ItemGetData (n)
                    if not itemData or itemData == 0 then
                        break
                    end

                    local qIndex = bit_band (itemData, 0xff)
                    local qId = bit_rshift (itemData, 16)

                    local i, cur, id = Quest:FindCur (qId, qIndex)

                    if not setStr then

                        local qStatus = Nx.Quest:GetQuest (id)
                        setStr = qStatus == "W" and "c" or "W"
                    end

                    Nx.Quest:SetQuest (id, setStr)
                end

                Quest:PartyStartSend()

            else

                -- Track or paste to chat

                local i, cur, id = Quest:FindCur (qId, qIndex)

                local box = Nx:FindActiveChatFrameEditBox()
                if box then

                    local s = self:MakeDescLink (cur, id or qId, IsControlKeyDown())
                    if s then
                        box:Insert (s)
                    end

                else

                    if cur then

                        -- Shift click toggles quest-watch

                        local qStatus = Nx.Quest:GetQuest (id)
                        if qStatus == "W" then
                            Nx.Quest:SetQuest (id, "c")
                        else
                            Nx.Quest:SetQuest (id, "W")
                        end

                        Quest:PartyStartSend()
                    end
                end
            end
        end

        Nx.Quest:SelectBlizz (qIndex)

        self:Update()

        if qId > 0 then

            -- 0 is quest name line
            local qObj = bit_band (bit_rshift (itemData, 8), 0xff)

            local mapId = Map:GetCurrentMapId()
            Quest:TrackOnMap (qId, qObj, qIndex > 0, shift)
            Map:SetCurrentMap (mapId)

            -- LightHeaded select

            if self.TabSelected == 3 then
                local lh = _G["LightHeaded"]
                if lh then
                    lh["UpdateFrame"] (lh, qId)
--                    Nx.prt ("LH qid %s", qId)
                end
            end
        end

    elseif eventName == "button" then

        if hdrCur then        -- Header?

            local v
            if not Quest.HeaderHide[hdrCur.Header] then
                v = true
            end
            Quest.HeaderHide[hdrCur.Header] = v

            self:Update()

        else
            -- 0 is quest name line
            local qObj = bit_band (bit_rshift (itemData, 8), 0xff)

            if self.TabSelected == 1 then

                self:ToggleWatch (qId, qIndex, qObj, shift)

            elseif self.TabSelected == 3 then

                local tbits = Quest.Tracking[qId] or 0

                if qObj == 0 then
                    Quest.Tracking[qId] = bit.bxor (tbits, 1)
                else
                    Quest.Tracking[qId] = bit.bxor (tbits, bit_lshift (1, qObj))
                end

                self:Update()
            end
        end

    elseif eventName == "menu" then

        if qIndex > 0 then

            Quest:SelectBlizz (qIndex)
            self:Update()
        end

        if self.TabSelected ~= 4 then

            self:UpdateMenu()
            self.Menu:Open()
        end
    end
end

function Nx.Quest.List:ToggleWatch (qId, qIndex, qObj, shift)

    local Quest = Nx.Quest
    local Map = Nx.Map

    -- Quest-list click (retail / Wrath+ Classic). Toggle semantics mirror
    -- the map-icon click handler: clicking the same (quest, objective)
    -- pair a second time clears super-track + arrow, switching objectives
    -- on the same quest just retargets the arrow.
    if not shift
       and qId and qId > 0
       and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then

        local i, cur, id = Quest:FindCur (qId, qIndex)
        if cur then
            local liveQID = qId
            if qIndex and qIndex > 0 then
                if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
                    local q = C_QuestLog.GetQuestIDForLogIndex(qIndex)
                    if q and q > 0 then liveQID = q end
                elseif GetQuestIDFromLogIndex then
                    local q = GetQuestIDFromLogIndex(qIndex)
                    if q and q > 0 then liveQID = q end
                end
            end

            if Quest.PatchQuestFromBlizzard then
                Quest:PatchQuestFromBlizzard(liveQID)
            end

            local activeQID = (C_SuperTrack.GetSuperTrackedQuestID
                                and C_SuperTrack.GetSuperTrackedQuestID()) or 0
            if activeQID == 0 then activeQID = Quest.ActiveQID or 0 end
            local activeObjI = Quest.ActiveObjI or 0
            local toggleOff = (activeQID == liveQID and activeObjI == qObj)

            if toggleOff then
                -- Secure clear goes through SuperTrackSafe (deferred in
                -- combat — tainted SUPER_TRACKING_CHANGED chain trips the
                -- protected SetPassThroughButtons). The flag arms inside
                -- the closure so it's set when the call actually fires.
                Nx.SuperTrackSafe(function()
                    Quest.UserClearedActive = true
                    C_SuperTrack.SetSuperTrackedQuestID(0)
                end)
                Quest.ActiveQID = 0
                Quest.ActiveObjI = 0
                Quest.Tracking[qId] = nil
                if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1]
                   and Nx.Map.Maps[1].ClearTargets then
                    Nx.Map.Maps[1]:ClearTargets()
                end
                -- Title-row toggle also clears the watch flag (Blizz parity).
                if qObj == 0 and Nx.Quest:GetQuest(id) == "W" then
                    Nx.Quest.Watch:RemoveWatch(qId, qIndex)
                end
            else
                if Nx.Quest:GetQuest(id) ~= "W" then
                    Nx.Quest:SetQuest(id, "W")
                end
                local _live = liveQID
                Nx.SuperTrackSafe(function()
                    C_SuperTrack.SetSuperTrackedQuestID(_live)
                end)
                Quest.ActiveObjI = qObj
                if qObj > 0 and Quest.TrackOnMap then
                    Quest:TrackOnMap(qId, qObj, qIndex and qIndex > 0, true)
                end
            end
            Quest:PartyStartSend()
            self:Update()
        end
        return
    end

    if qObj == 0 and not shift then

        -- Classic Era / TBC title-row click. Toggle on (qId, 0) pair.
        local i, cur, id = Quest:FindCur (qId, qIndex)
        if cur then
            local activeQID = Quest.ActiveQID or 0
            local activeObjI = Quest.ActiveObjI or 0
            local toggleOff = (activeQID == qId and activeObjI == 0)

            local prevSuppress = Quest._addWatchSuppress
            Quest._addWatchSuppress = true

            if toggleOff then
                if Quest.SetActiveCarboniteQuest then
                    -- Polyfill toggles when called twice with same id.
                    Quest:SetActiveCarboniteQuest(qId, qIndex)
                end
                Quest.ActiveQID = 0
                Quest.ActiveObjI = 0
                Quest.Tracking[qId] = nil
                if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1]
                   and Nx.Map.Maps[1].ClearTargets then
                    Nx.Map.Maps[1]:ClearTargets()
                end
                if Nx.Quest:GetQuest(id) == "W" then
                    Nx.Quest.Watch:RemoveWatch(qId, qIndex)
                end
            else
                if Nx.Quest:GetQuest(id) ~= "W" then
                    Nx.Quest:SetQuest(id, "W")
                end
                if qId and qId > 0 and Quest.SetActiveCarboniteQuest then
                    Quest:SetActiveCarboniteQuest(qId, qIndex)
                end
                Quest.ActiveObjI = 0
            end

            Quest._addWatchSuppress = prevSuppress
            Quest:PartyStartSend()
        end
    else

        if qId > 0 and qObj > 0 then    -- FIX: Diabled qObj == 0 case

            -- Per-objective click on classic. Toggle on (qId, qObj) pair.
            local i, cur, id = Quest:FindCur (qId, qIndex)
            local activeQID = Quest.ActiveQID or 0
            local activeObjI = Quest.ActiveObjI or 0
            local toggleOff = (activeQID == qId and activeObjI == qObj)

            -- Wrap both branches in the AddQuestWatch hook suppress so any
            -- AddQuestWatch fired by TrackOnMap's QuestWatch.Sync codepath
            -- doesn't recursively re-toggle this quest in the hook (which
            -- would activate-then-instantly-clear the user's first click).
            local prevSuppress = Quest._addWatchSuppress
            Quest._addWatchSuppress = true

            if toggleOff then
                -- Clear: drop watch state if active, drop this objective
                -- bit, clear arrow.
                Quest.Tracking[qId] = nil
                Quest.ActiveObjI = 0
                if cur and id and Nx.Quest:GetQuest(id) == "W" then
                    Nx.Quest.Watch:RemoveWatch(qId, qIndex)
                end
                -- SetActiveCarboniteQuest with same id as Active = clears
                -- (the polyfill toggles when called twice on the same id),
                -- so this both resets ActiveQID and triggers TrackOnMap's
                -- clear-targets path internally.
                if Quest.SetActiveCarboniteQuest then
                    Quest:SetActiveCarboniteQuest(qId, qIndex)
                end
                if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1]
                   and Nx.Map.Maps[1].ClearTargets then
                    Nx.Map.Maps[1]:ClearTargets()
                end
            else
                -- Activate: ensure quest is watched + active, set tracking
                -- bit for this objective, point the arrow at it.
                if cur and id and Nx.Quest:GetQuest(id) ~= "W" then
                    Nx.Quest:SetQuest(id, "W")
                end
                if Quest.SetActiveCarboniteQuest and activeQID ~= qId then
                    Quest:SetActiveCarboniteQuest(qId, qIndex)
                end
                local tbits = Quest.Tracking[qId] or 0
                Quest.Tracking[qId] = bit.bor (tbits, bit_lshift (1, qObj))
                Quest.ActiveObjI = qObj
                local mapId = Map:GetCurrentMapId()
                Quest:TrackOnMap (qId, qObj, qIndex > 0, true)
                Map:SetCurrentMap (mapId)
            end

            Quest._addWatchSuppress = prevSuppress
            self:Update()
        end
    end

    self:Update()
end

-------------------------------------------------------------------------------
-- Make a quest link
-- (cur or id can be nil)
-------------------------------------------------------------------------------

function Nx.Quest.List:MakeDescLink (cur, id, debug)

    local qId = cur and cur.QId or id    -- Database list will have nil cur

    local Quest = Nx.Quest
    local quest = cur and cur.Q or Nx.Quests[qId]

    local title = cur and cur.Title or ''
    local realLevel = cur and cur.RealLevel or 0

    if quest then
        local t = GetQuestLogTitle(GetQuestLogIndexByID(qId))
        local s
        s, _, realLevel = Quest:Unpack (quest["Quest"])
        title = s or title
        title = t or title
    end

    local level = realLevel or 0

    if level <= 0 then
        level = UnitLevel ("player") or 0
    end

    -- Try to get the proper quest link from WoW API
    local questLink
    local questLogIndex = GetQuestLogIndexByID(qId)
    if questLogIndex and questLogIndex > 0 and GetQuestLink then
        questLink = GetQuestLink(questLogIndex)
    end

    -- Fall back to manually created link if GetQuestLink not available or quest not in log
    if not questLink then
        questLink = Quest:CreateLink(qId, realLevel, title)
    end

    local s = questLink or title

    -- Needs a leading space according to Blizzard. White color breaks link
    if quest and Nx.qdb.profile.Quest.ShowLinkExtra then
        local part = Quest:GetPartTitle (quest, cur) or ''
        if part ~= "" then
            part = " " .. part
        end
        if level > 0 then
            s = format (" [%s] %s%s", level, s, part)
        else
            s = format (" %s%s", s, part)
        end
    else
        s = format (" %s", s)
    end

    if debug then
        local fac = strsub (UnitFactionGroup ("player"), 1, 1)
        s = format ("%s[%s %d]", s, fac, qId)
    end

--    Nx.prt ("quest %s", gsub (s, "|", "^"))

    return s
end

-------------------------------------------------------------------------------
-- On quest updates
-------------------------------------------------------------------------------

local QuestListRefreshTimer
function Nx.Quest.List:Refresh(event)
    if QuestListRefreshTimer then
        QuestListRefreshTimer:Cancel()
    end

    local func = function ()
        Nx.prtD("Nx.Quest.List:Refresh")
        if QuestListRefreshTimer then
            QuestListRefreshTimer:Cancel()
        end

        local isInst = IsInInstance()
        -- Update Emmissaries
        if not isInst then
            local pLvl = UnitLevel ("player")
            if not hideBfAEmmissaries and pLvl > 111 then Nx.Quest.emmBfA = GetQuestBountyInfoForMapID(875) end
            if not hideLegionEmmissaries and pLvl > 109 then Nx.Quest.emmLegion = GetQuestBountyInfoForMapID(619) end
        end

        Nx.Quest.List:LogUpdate()
        Nx.Quest:RecordQuests(1)
    end

    --Nx.Quest.List:LogUpdate()

    --[[local func = function(timer)
        C_Timer.After(.5, function()
            --Nx.Quest:ScanBlizzQuestDataZone()
            Nx.Quest:RecordQuests()
            --Nx.Quest:RecordQuests(event == "QUEST_LOG_UPDATE" and true or nil)
            Nx.Quest.List:LogUpdate()
            Nx.prtD ("R %s", "Nx.Quest.List:Refresh")
        end)
    end]]--

    if event == "QUEST_ACCEPTED" then
        func()
    else
        QuestListRefreshTimer = C_Timer.NewTimer(IsInInstance() and 2 or 1, func)
    end
end

function CarboniteQuest:OnQuestUpdate (event, ...)
    local Quest = Nx.Quest
    local arg1, arg2, arg3 = select (1, ...)

    Nx.prtD ("OnQuestUpdate %s", event)

    if event == "PLAYER_LOGIN" then
        self.LoggingIn = true
    elseif event == "QUEST_TURNED_IN" then
        -- Server confirmed the turn-in. Commit the history "C" write
        -- that FinishQuest deferred (see comment there for the reason
        -- the GetQuestReward post-hook can't be trusted on its own).
        local turnedQID = arg1
        local pend = Quest._pendingTurnIn
        if pend and (GetTime() - (pend.t or 0)) < 30 then
            local commitID = (turnedQID and turnedQID > 0) and turnedQID or pend.id
            Quest:SetQuest (commitID, "C", time())
            Quest._pendingTurnIn = nil
        elseif turnedQID and turnedQID > 0 then
            Quest:SetQuest (turnedQID, "C", time())
        end
        Nx.Quest.List:Refresh(event)
    elseif event == "SUPER_TRACKING_CHANGED" then
        Nx.Quest:OnSuperTrackChanged()
    elseif event == "QUEST_POI_UPDATE" then
        local oldmap = Nx.Map:GetCurrentMapAreaID()
        if Nx.Quest.OldMap ~= oldmap then
            Nx.Quest.OldMap = oldmap
            Nx.Quest:MapChanged()
            Nx.Quest.Watch:Update()
        end
    elseif event == "QUEST_PROGRESS" then
        local auto = Nx.qdb.profile.Quest.AutoTurnIn

        if IsShiftKeyDown() and IsControlKeyDown() then
            auto = not auto
        end

        if auto then
            CompleteQuest()
--            Nx.prt ("Auto turn in")
        end
        Nx.Quest.List:Refresh(event)
        return
    elseif event == "QUEST_COMPLETE" then
        -- Snapshot title/questID while the reward UI is still up. The
        -- GetQuestReward post-hook (FinishQuest) consumes this; by the
        -- time the post-hook runs Blizzard has already fired
        -- QUEST_FINISHED and GetTitleText()/GetQuestID() may be empty.
        Quest._completeSnapshot = {
            title   = GetTitleText() or "",
            questID = (GetQuestID and GetQuestID()) or 0,
            time    = GetTime(),
        }

        local auto = Nx.qdb.profile.Quest.AutoTurnIn
        if IsShiftKeyDown() and IsControlKeyDown() then
            auto = not auto
        end
        if auto then
            if GetNumQuestChoices() == 0 then
                GetQuestReward()
--                Nx.prt ("Auto turn in choice")
            end
        end
        Nx.Quest.List:Refresh(event)
        return
    elseif event == "QUEST_ACCEPTED" then
        --[[if QuestGetAutoAccept() then
            local auto = Nx.qdb.profile.Quest.AutoAccept
            if IsShiftKeyDown() and IsControlKeyDown() then
                auto = not auto
            end
            if auto then
                QuestFrameDetailPanel:Hide();
                CloseQuest();
            end
        end]]--
        -- Get the questID - handle different API versions
        -- Classic: arg1 = questLogIndex (small number 1-25)
        -- Retail: arg1 = questID directly (large number)
        local questId
        if Nx.isRetail then
            -- Retail: arg1 is the questID directly
            questId = arg1
        else
            -- Classic versions: arg1 is quest log index, need to get questID from it
            if arg1 and arg1 > 0 then
                questId = Nx.Quest:GetQuestID(arg1)
            end
        end

        if questId and questId > 0 then
            -- Add to AcceptPool so it gets watched during Refresh
            -- Check if not already in the pool (QUEST_DETAIL may have added it)
            local found = false
            for _, qn in ipairs(Quest.AcceptPool) do
                if qn == questId then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(Quest.AcceptPool, questId)
                Nx.prtD("QUEST_ACCEPTED added to pool: %s", questId)
            end
            -- Synthesize Carbonite quest data from Blizzard's API so the
            -- bundled DB doesn't need to know about brand-new quests.
            -- Function self-checks for the C_QuestLog API.
            Quest:PatchQuestFromBlizzard(questId)
        end
        Nx.Quest:RecordQuests()
        --Nx.Quest.List:Refresh(event)
        Nx.Quest.List:Refresh()

        --for bag = 0, NUM_BAG_SLOTS do for slot = 1, GetContainerNumSlots(bag) do local itemLink = GetContainerItemLink(bag,slot); itemString = strfind(itemLink, "|H(.+)|h"); print(itemLink:gsub('\124','\124\124')); end end
        --Nx.Quest:RecordQuests()
    elseif event == "QUEST_REMOVED" then
        local questId = arg1
        if QuestUtils_IsQuestWorldQuest and QuestUtils_IsQuestWorldQuest(questId) then
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                -- QUEST_REMOVED fires mid-combat all the time (WQ done
                -- while fighting); the secure clear must defer or the
                -- tainted SUPER_TRACKING_CHANGED chain trips the
                -- combat-protected SetPassThroughButtons.
                Nx.SuperTrackSafe(function()
                    C_SuperTrack.SetSuperTrackedQuestID(0)
                end)
            end
            worldquestdb[questId] = nil
            if Nx.Quest.WQList then
                Nx.Quest.WQList:UpdateDB()
            end
        else
            -- Regular quest abandoned/turned-in: clear our tracking +
            -- super-track + map target so the icon, blob and goto arrow
            -- don't linger pointing at a quest that's no longer in the
            -- log. RecordQuestsLog will rebuild CurQ on the next refresh.
            if Quest.Tracking then
                Quest.Tracking[questId] = nil
            end
            if Nx.Quest.ActiveQID == questId then
                Nx.Quest.ActiveQID = 0
                if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
                   and C_SuperTrack.GetSuperTrackedQuestID() == questId then
                    -- Combat-defer (see WQ branch above). Re-check the id
                    -- at fire time in case the super-track moved on.
                    Nx.SuperTrackSafe(function()
                        if C_SuperTrack.GetSuperTrackedQuestID() == questId then
                            C_SuperTrack.SetSuperTrackedQuestID(0)
                        end
                    end)
                end
            end
            -- Drop any map target pointing at this quest.
            if Quest.Map and Quest:IsTargeted(questId) then
                Quest.Map:ClearTargets()
            end
            -- Hide a lingering blob if this was the one being drawn.
            if Nx.BlobsAvailable and not InCombatLockdown() then
                local QMap = NxMap1 and NxMap1.NxMap
                if QMap and QMap.QuestWin then
                    QMap.QuestWin:DrawNone()
                    QMap.QuestWin:Hide()
                end
            end
            if Nx.Quest.Watch and Nx.Quest.Watch.Update then
                Nx.Quest.Watch:Update()
            end
        end
    elseif event == "QUEST_DETAIL" then        -- Happens when auto accept quest is given
        --if QuestGetAutoAccept() and QuestIsFromAreaTrigger() then
            Quest:RecordQuestAcceptOrFinish()
            local auto = Nx.qdb.profile.Quest.AutoAccept
            if IsShiftKeyDown() and IsControlKeyDown() then
                auto = not auto
            end
            if auto then
                CloseQuest();
            end
--            Quest.AcceptQId = GetQuestID()
            table.insert(Quest.AcceptPool, GetQuestID())
            Nx.prtD ("QUEST_DETAIL %s", GetQuestID())
            Nx.Quest.List:Refresh(event)
        --end
    elseif event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" or event == "WORLD_QUEST_COMPLETED_BY_SPELL" then

--        Nx.prtStack ("QUpdate")
--        Nx.prt ("#%d", GetNumQuestLogEntries())

        if self.LoggingIn then
            Quest:AccessAllQuests()
            QLogUpdate = Nx:ScheduleTimer(self.LogUpdate,.5,self)    -- Small delay, so access works (0 does work)
        else
            Nx.Quest.List:Refresh("QUEST_LOG_UPDATE")
            -- Objective progress doesn't fire SUPER_TRACKING_CHANGED, but
            -- the waypoint Blizzard's arrow targets advances each time an
            -- objective completes. Re-trigger OnSuperTrackChanged so our
            -- goto arrow re-resolves through GetNextWaypoint and follows
            -- the new objective. Cheap: it just re-runs TrackOnMap for
            -- the active quest.
            Nx.Quest:OnSuperTrackChanged()
            -- Broad cur.QId self-heal. OnSuperTrackChanged only
            -- repairs the cur tied to the live super-tracked quest;
            -- other cur entries can still hold a stale QId from
            -- before a quest was accepted/abandoned mid-RecordQuestsLog
            -- pass. Walk every cur, resolve via its log index, and
            -- re-key Nx.Quest.QIds / IdToCurQ when the ID drifted —
            -- otherwise the skew persists until the user opens the
            -- quest log (which triggers a full RecordQuestsLog scan).
            if Nx.Quest.CurQ and C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
                for _, c in ipairs(Nx.Quest.CurQ) do
                    if c.QI and c.QI > 0 then
                        local live = C_QuestLog.GetQuestIDForLogIndex(c.QI)
                        if live and live > 0 and live ~= c.QId then
                            -- Title-check guard: log indices shift when a
                            -- quest is accepted/abandoned, so c.QI may
                            -- now point at a *different* quest. Only
                            -- re-key when titles still match (Blizzard
                            -- renumbered the same quest, e.g. Inoculation
                            -- 9303 -> 37444). On a title mismatch the
                            -- cur is stale from a log shift -- leave it
                            -- for RecordQuestsLog to rebuild rather than
                            -- silently inheriting the wrong ID.
                            local liveTitle
                            if C_QuestLog.GetInfo then
                                local info = C_QuestLog.GetInfo(c.QI)
                                liveTitle = info and info.title
                            end
                            if not liveTitle and GetQuestLogTitle then
                                liveTitle = GetQuestLogTitle(c.QI)
                            end
                            if liveTitle and c.Title and liveTitle == c.Title then
                                local oldQId = c.QId
                                if Nx._dbgQId then
                                    Nx.prt("|cffff8000[QId-DBG]|r broadHeal cur#%s QI=%s QId %s->%s Title=%q liveTitle=%q",
                                        tostring(c.Index), tostring(c.QI), tostring(oldQId), tostring(live),
                                        tostring(c.Title or "?"), tostring(liveTitle or "?"))
                                end
                                c.QId = live
                                if Nx.Quest.QIds then
                                    if oldQId then Nx.Quest.QIds[oldQId] = nil end
                                    Nx.Quest.QIds[live] = c
                                end
                                if Nx.Quest.IdToCurQ then
                                    if oldQId then Nx.Quest.IdToCurQ[oldQId] = nil end
                                    Nx.Quest.IdToCurQ[live] = c
                                end
                            end
                        end
                    end
                end
            end
            -- Map-icon producer caches its tooltip text (`pin.tip`,
            -- which embeds cur[n+400] progress strings) at stamp
            -- time. The fingerprint dirty-check in UpdateIcons only
            -- includes hover / super-track / tick-bucket, so objective
            -- progress changes ("0/5" → "1/5") would otherwise wait
            -- up to a 10-tick bucket (~166ms) before being reflected.
            -- Flagging dirty here forces the rebuild on the very next
            -- producer pass.
            Nx.Quest._iconDirty = true
            -- The Questie integration scrapes Questie's tooltip data
            -- (data.ObjectiveData.Description, etc.) into pin.tip at
            -- icon-stamp time. Its own hash doesn't include progress
            -- text, so without busting the cache here the icon
            -- tooltip would still show the pre-progress objective
            -- text until the next zone change. (HandyNotes /
            -- RareScanner tooltips don't depend on quest progress.)
            if Nx.Notes and Nx.Notes.BustIntegrationCache then
                Nx.Notes:BustIntegrationCache("Questie")
            end
            -- Bust the quest-offer cache in WorldQuestWindow so a
            -- just-accepted quest stops rendering as an available
            -- POI icon on the map. GetQuestOffersForMap caches its
            -- C_QuestLine.GetAvailableQuestLines result for 2s, which
            -- otherwise makes the accepted quest's "available"
            -- marker linger until the cache naturally expires.
            Nx.Quest.QuestOfferCacheTime = 0
        end
    elseif event == "GARRISON_MISSION_COMPLETE_RESPONSE" then
        Nx.Quest.List:LogUpdate()
    else
        Nx.Quest.Watch:Update()
    end

--    Nx.prtD ("OnQuestUpdate %s Done", event)
    -- Keep Blizzard tracker visibility in sync with the profile toggle.
    if Nx.Quest and Nx.Quest.TrackerHider_Apply then
        Nx.Quest:TrackerHider_Apply()
    end
end


Nx.Quest.TrackedAchievements = {}
function CarboniteQuest:OnTrackedAchievementsUpdate (event, ...)
    Nx.Quest.TrackedAchievements = {}
    local ach = { GetTrackedAchievements() }
    for _, id in ipairs (ach) do
        CarboniteQuest:OnTrackedAchievementUpdate(event, id)
    end
end

function CarboniteQuest:OnTrackedAchievementUpdate (event, id)
    local achT = {}
    local aId, aName, aPoints, aComplete, aMonth, aDay, aYear, aDesc = GetAchievementInfo (id)
    achT = { aId, aName, aPoints, aComplete, aMonth or false, aDay or false, aYear or false, aDesc }

    local numC = GetAchievementNumCriteria (id)
    achT[9] = numC
    achT[10] = {}
    local progressCnt = 0
    local tip = aDesc
    for n = 1, numC do
        local cName, cType, cComplete, cQuantity, cReqQuantity, _, _, _, cQuantityString = GetAchievementCriteriaInfo (id, n)
        achT[10][n] = { cName, cType, cComplete, cQuantity, cReqQuantity, _, _, _, cQuantityString }
    end

    Nx.Quest.TrackedAchievements[id] = achT
end

-------------------------------------------------------------------------------
-- Quest Log update
-------------------------------------------------------------------------------

function Nx.Quest.List:LogUpdate()

--    Nx.prtStack ("QUpdate")
--    Nx.prt ("#%d", GetNumQuestLogEntries())

    local Quest = Nx.Quest

    local qn

    Quest:ExpandQuests()

    if not self.LoggingIn then
        qn = Quest:FindNewQuest()
        if not qn then
--            Quest:CheckForNewCompleted()
            Quest:TellPartyOfChanges()
        end
    end
    Quest:RecordQuests(0)

    if self.LoggingIn then
        QWatchLogin = Nx:ScheduleTimer(Quest.WatchAtLogin,.7,Quest)
        QSetPDLogin = Nx:ScheduleTimer(Quest.CurQSetPreviousDone,2,Quest)
        if Nx.qdb.profile.Quest.HCheckCompleted  then
            QHistLogin = Nx:ScheduleTimer(Quest.QuestQueryTimer, 1, Quest)
        end
    end

    -- Iterate backward: table.remove shifts later entries down, so a
    -- forward ipairs loop would skip the entry that follows each removal.
    -- Zoning into a new area can drop several quests into AcceptPool at
    -- once (QUEST_DETAIL + QUEST_ACCEPTED, auto-accept chains) and the
    -- skipped ones never got Watch:Add, so they didn't show up in the
    -- tracker or get map-tracked until /reload re-ran WatchAtLogin.
    for k = #Quest.AcceptPool, 1, -1 do
        local qn = Quest.AcceptPool[k]
        local qi = GetQuestLogIndexByID (qn)
        if qi > 0 then
            local curi, cur = Quest:FindCurByIndex (qi)
            if cur then
                Quest.QIdsNew[cur.QId] = time()
                if Nx.qdb.profile.QuestWatch.AddNew and not Quest.DailyPVPIds[cur.QId] then
                    Quest.Watch:Add (curi,true)
                end
                Quest:Capture (curi)
            end
            table.remove(Quest.AcceptPool, k)
        end
    end

    Quest:RestoreExpandQuests()

    self.LoggingIn = nil

    Quest.Watch:ClearCompleted()
    self:Update()
    Quest.Watch:Update()
    Quest.WQList:Update()
end

-------------------------------------------------------------------------------
-- Update list security stub
-------------------------------------------------------------------------------

function Nx.Quest.List:Update()

    if not self.Win:IsShown() then
        return
    end

--    Nx.prt ("QuestListUpdate")

    local Nx = Nx
    local Quest = Nx.Quest
    local Map = Nx.Map
    local qLocColors = Quest.QLocColors
    local showQId = Nx.qdb.profile.Quest.ShowId

    -- Title

    local _, i = GetNumQuestLogEntries()

    local dailyStr = ""
    local dailysDone = GetDailyQuestsCompleted()
    if Nx.qdb.profile.Quest.ShowDailyCount then
        if dailysDone > 0 then
            dailyStr = L["Daily Quests Completed:"] .. " |cffffffff" .. dailysDone
        end
    end
    if Nx.qdb.profile.Quest.ShowDailyReset then
        dailyStr = dailyStr .. "|r  " .. L["Daily reset:"] .. " |cffffffff" .. Nx.Util_GetTimeElapsedStr (GetQuestResetTime())
    end

    self.Win:SetTitle (format (L["Quests:"] .. " |cffffffff%d/%d|r  %s", i, MAX_QUESTS, dailyStr))

    -- List

    local list = self.List
    list:Empty()

    local greenRange = 5

    if UnitQuestTrivialLevelRange then
        greenRange = UnitQuestTrivialLevelRange("player")
    elseif GetQuestGreenRange then
        greenRange = GetQuestGreenRange()
    end

    if self.TabSelected == 1 then

        local oldSel = GetQuestLogSelection()

        local header
        local curq = Quest.CurQ

        for n = 1, curq and #curq or 0 do

            local cur = curq[n]
            local quest = cur.Q
            local qId = cur.QId

            local title, level, tag, isComplete = cur.Title, cur.Level, cur.Tag, cur.Complete
            local qn = cur.QI

            if qn > 0 then
                SelectQuestLogEntry (qn)
            end

            local onQ = 0
            local onQStr = ""

            if qn > 0 then
                for n = 1, 4 do
                    if IsUnitOnQuest (qn, "party"..n) then
                        if onQ > 0 then
                            onQStr = onQStr .. "," .. UnitName ("party" .. n)
                        else
                            onQStr = onQStr .. UnitName ("party" .. n)
                        end
                        onQ = onQ + 1
                    end
                end
            end

            if not self.ShowParty or onQ > 0 then

                local lvlStr = "  "
                if level > 0 then
                    lvlStr = format ("|cffd0d0d0%2d", level)
                end

                local color = GetCachedDifficultyColorStr(level)

                local nameStr = format ("%s %s%s", lvlStr, color, title)

                if quest and quest.CNum then
                    nameStr = nameStr .. format (L[" (Part %d of %d)"], quest.CNum, cur.CNumMax)
                end

                if onQ > 0 then
                    nameStr = format ("(%d) %s (%s)", onQ, nameStr, onQStr)
                end

                if isComplete then
                    nameStr = nameStr .. (isComplete == 1 and "|cff80ff80 - "..L["Complete"] or "|cfff04040 - "..FAILED)
                end

                if tag and cur.GCnt > 0 then
                    tag = tag .. " " .. cur.GCnt
                end

                if cur.Daily == LE_QUEST_FREQUENCY_DAILY then
                    if tag then
                        tag = format (DAILY_QUEST_TAG_TEMPLATE, tag)
                    else
                        tag = DAILY
                    end
                end

                local show = true

                if self.Filters[self.TabSelected] ~= "" then

                    local str = strlower (format ("%s %s", nameStr, tag or ""))
                    local filtStr = strlower (self.Filters[self.TabSelected])

                    show = strfind (str, filtStr, 1, true)
                end

                if self.QOpts.NXShowHeaders and cur.Header ~= header then
                    header = cur.Header
                    if show then
                        list:ItemAdd (0)
                        list:ItemSet (2, format ("|cff8f8fff---- %s ----", header))
                        list:ItemSetDataEx (list:ItemGetNum(), cur, 1)
                        list:ItemSetButton ("QuestHdr", Quest.HeaderHide[cur.Header])
                    end
                end

                if show and not Quest.HeaderHide[cur.Header] then

                    local id = qId > 0 and qId or cur.Title
                    local qStatus = Nx.Quest:GetQuest (id)
                    local qWatched = qStatus == "W"

                    list:ItemAdd (qId * 0x10000 + qn)

                    local trackMode = Quest.Tracking[qId] or 0

                    local butType = "QuestWatch"
                    local butOn

                    local trkStr = " "
                    if bit_band(trackMode, 1) > 0 then
                        trkStr = "*"
                        butOn = true
                    end

                    if qWatched then
                        butType = "QuestWatching"
                        butOn = true
                    end

                    list:ItemSetButton (butType, butOn)

                    if quest and showQId then
                        nameStr = nameStr .. format (" [%s]", qId)
                    end

                    if cur.HighPri then
                        nameStr = "> " .. nameStr
                    end

                    list:ItemSet (2, nameStr)
                    list:ItemSet (4, tag)

                    if self.QOpts.NXShowObj then

                        local num = GetNumQuestLeaderBoards (qn)
                        local oCompColor = Nx.Quest.Cols["oCompColor"]
                        local oIncompColor = Nx.Quest.Cols["oIncompColor"]

                        local str = ""
                        local desc, typ, done
                        local zone, loc

                        for ln = 1, num do

                            zone = nil

                            local obj = quest and quest["Objectives"]

                            if obj then
                                desc, zone, loc = Nx.Quest:UnpackObjectiveNew (obj[n])
                            end
                            if ln <= num then
                                desc, typ, done = GetQuestLogLeaderBoard (ln, qn)
                                desc = desc or "?"    --V4

                            else
                                if not obj then
                                    break
                                end

                                done = false
                            end
                            if not desc then desc = "?" end
                            color = done and oCompColor or oIncompColor
                            str = format ("     %s%s", color, desc)

                            list:ItemAdd (qId * 0x10000 + ln * 0x100 + qn)

                            local trkStr = ""

                            if zone then
--                                trkStr = "|cff505050o"
                                list:ItemSetButton ("QuestWatch", false)
                            end

                            if bit_band (trackMode, bit_lshift (1, ln)) > 0 then
                                list:ItemSetButton (qLocColors[ln][5], true)
                            end
                            list:ItemSet (1, trkStr)

                            list:ItemSet (2, str)
                        end
                    end
                end
            end
        end

        SelectQuestLogEntry (oldSel)

    end

    -- Add history quests

    if Nx.Quests and self.TabSelected == 2 then

        local qIds = Quest.QIds

        local sortT = {}

        local showAllZones = self.ShowAllZones or self.ShowAllQuests
        local showLowLevel = self.ShowLowLevel or self.ShowAllQuests
        local showHighLevel = self.ShowHighLevel or self.ShowAllQuests
        local showFinished = self.ShowFinished or self.ShowAllQuests
        local showOnlyDailies = self.ShowOnlyDailies and not self.ShowAllQuests

        local mapId = Map:GetCurrentMapId()
        local minLevel = UnitLevel ("player") - greenRange
        local maxLevel = showHighLevel and Nx.MaxPlayerLevel or UnitLevel ("player") + 6

        -- Divider

        list:ItemAdd (0)
        list:ItemAdd (0)
        local dbTitleIndex = list:ItemGetNum()
        local dbTitleNum = 0
        list:ItemAdd (0)

        for qId in pairs (Nx.Quest.CurCharacter.Q) do            -- Loop over quests with history

            local quest = Nx.Quests[qId]
            local status, qTime = Nx.Quest:GetQuest (qId)
            local qCompleted = status == "C"

            local show = qCompleted

            if show and not showAllZones then
                show = Quest:CheckShow (mapId, qId)
            end

            if show then

                local qname, side_, lvl

                if quest then
                    qname, side_, lvl = Quest:Unpack (quest["Quest"])
                else
                    qname = format ("%s?", qId)
                    lvl = 0
                end

--                Nx.prt ("%s [%s] %s", qname, qId, quest.CNum or "")

                local lvlStr = format ("|cffd0d0d0%2d", lvl)
                local title = qname

                if quest and quest.CNum then
                    title = title .. format (L[" (Part %d)"], quest.CNum)
                end

                if showQId then
                    title = title .. format (" [%s]", qId)
                end

                local dailyName = ""

                local dailyStr = Quest.DailyIds[qId] or Quest.DailyDungeonIds[qId] or Quest.DailyPVPIds[qId]
                if dailyStr then

                    local typ = Nx.Split ("^", dailyStr)
                    dailyName = format (" |cffd060d0(%s)", Quest.DailyTypes[typ])

                    local age = time() - qTime
                    local dayChange = 86400 - GetQuestResetTime()

                    if age < dayChange then
                        dailyName = dailyName .. L[" |cffff8080today"]
                    end
                end

                local show = true

                if self.Filters[self.TabSelected] ~= "" then

                    local str = strlower (format ("%2d %s %s%s", lvl, title, date ("%m/%d %H:%M:%S", qTime), dailyName))
                    local filtStr = strlower (self.Filters[self.TabSelected])

                    show = strfind (str, filtStr, 1, true)
                end

                if show then

                    local t = {}
                    tinsert (sortT, t)

                    t.T = qTime
                    t.QId = qId

                    dbTitleNum = dbTitleNum + 1

                    local haveStr = ""

                    if qIds[qId] then
                        haveStr = "|cffe0e0e0+ "
                    end

                    local color = GetCachedDifficultyColorStr(lvl)

                    t.Desc = format ("%s %s%s%s", lvlStr, haveStr, color, title)
                    t.Col4 = format ("%s %s", date ("|cff9f9fcf%m/%d %H:%M:%S", qTime), dailyName)
                end
            end
        end

        sort (sortT, function (a, b) return a.T > b.T end)

        for _, qEntry in ipairs (sortT) do

            list:ItemAdd (qEntry.QId * 0x10000)
            list:ItemSet (2, qEntry.Desc)
            list:ItemSet (4, qEntry.Col4)
        end

        local str = (showAllZones and "All" or Map:IdToName (mapId)) .. L[" Completed"]

        list:ItemSet (2, format ("|cffc0c0c0--- %s (%d) ---", str, dbTitleNum), dbTitleIndex)
    end

    -- Add database quests

    if Nx.Quests and self.TabSelected == 3 then

        local qIds = Quest.QIds

        local sortT = {}

        local showAllZones = self.ShowAllZones or self.ShowAllQuests
        local showLowLevel = self.ShowLowLevel or self.ShowAllQuests
        local showHighLevel = self.ShowHighLevel or self.ShowAllQuests
        local showFinished = self.ShowFinished or self.ShowAllQuests
        local showOnlyDailies = self.ShowOnlyDailies and not self.ShowAllQuests

        local mapId = Map:GetCurrentMapId()

        local minLevel = UnitLevel ("player") - greenRange
        local maxLevel = showHighLevel and Nx.MaxPlayerLevel or UnitLevel ("player") + 6

        -- Divider

        list:ItemAdd (0)
        list:ItemAdd (0)
        local dbTitleIndex = list:ItemGetNum()
        local dbTitleNum = 0
        list:ItemAdd (0)

        local addBlank

--        local qsIndex = 1
--        local qsLast = #Quest.Sorted
--        while qsIndex <= qsLast do

        for qsIndex, qId in pairs (Quest.Sorted) do

--            local qId = Quest.Sorted[qsIndex]

            local quest = Nx.Quests[qId]
            if not quest then
                Nx.prt (L["nil quest %s"], qId)
            end
            local qname, side, lvl, minlvl, next = Quest:Unpack (quest["Quest"])

            local status, qTime = Nx.Quest:GetQuest (qId)
            local qCompleted = status == "C"

            if not quest.CNum or quest.CNum == 1 then
                addBlank = true
            end

            -- Compute show fresh per quest. The previous implementation
            -- carried `showchain` across iterations to "show all members of a
            -- chain together" — but pairs(Quest.Sorted) doesn't traverse in
            -- chain order, so the inherited show leaked into unrelated
            -- quests and broke both zone and level filters in this tab.
            -- Each quest is now evaluated independently; chain heads still
            -- get the CLvlMax-based "any reachable level in the chain"
            -- relaxation, while chain members are filtered by their own lvl.
            local show = true

            if not showLowLevel then
                if quest.CLvlMax then
                    show = show and quest.CLvlMax >= minLevel
                else
                    show = show and ((lvl == 0) or (lvl >= minLevel))
                end
            end
            show = show and lvl <= maxLevel

            if show and not showAllZones then
                show = self:CheckShow (mapId, qsIndex)
            end

            if not Quest.DailyIds[qId] then
                if (not showFinished and qCompleted) or showOnlyDailies then
                    show = false
                end
            end

            if show then

                local lvlStr = format ("|cffd0d0d0%2d", lvl)
                -- Prefer the live, localized title; fall back to Questie's
                -- per-locale patch table; final fallback is the English
                -- name baked into the Quest header. A live-cache miss kicks
                -- a server request so the next refresh picks up the real
                -- localized name (see Quest:GetLocalizedName).
                local title = Quest:GetLocalizedName (qId, qname)

                local cati = Quest:UnpackCategory (quest["Quest"])
                if cati > 0 then
                    title = title .. " <" .. Nx.QuestCategory[cati] .. ">"
                end

                if quest.CNum then

--                    if quest.CNum > 1 then
--                        lvlStr = "    " .. lvlStr
--                    end
                    title = title .. format (L[" (Part %d)"], quest.CNum)
                end

                local tag = qCompleted and L["(History) "] or ""

                local dailyStr = Quest.DailyIds[qId] or Quest.DailyDungeonIds[qId]
                if dailyStr then
                    local typ, money, rep, req = Nx.Split ("^", dailyStr)
                    tag = format ("|cffd060d0(%s %.2fg", Quest.DailyTypes[typ], money / 100)
                    for n = 0, 1 do    -- Only support 2 reps
                        local i = n * 4 + 1
                        local repChar = strsub (rep or "", i, i)
                        if repChar == "" then
                            break
                        end
                        tag = format ("%s, %s %s", tag, strsub (rep, i + 1, i + 3), Quest.Reputations[repChar])
                    end
                    if req and Quest.Requirements[req] then    -- 1 and 2 (Ally, Horde) not in table
                        tag = tag .. L[", |cffe0c020Need "] .. Quest.Requirements[req]
                    end
                    tag = tag .. ")"
                end

                local filterName = ""

                -- Resolve Start/End through the alt-spawn picker so a
                -- multi-city quest (holiday turn-in, capital quartermaster)
                -- displays the spawn matching the player's zone or faction
                -- instead of whichever copy the curated data happened to
                -- pick from.
                local sMapName
                local sName, sMapId = Quest:UnpackSE (Quest:ResolveStart (qId))
                if sMapId then
                    sMapName = Map:IdToName (sMapId)
                    filterName = format ("%s(%s)", sName, sMapName)
                end

                local eMapName
                local eName, eMapId = Quest:UnpackSE (Quest:ResolveEnd (qId))
                if eMapId then
                    eMapName = Map:IdToName (eMapId)
                    if sName ~= eName then
                        filterName = format ("%s%s(%s)", filterName, eName, eMapName)
                    end
                end

                local show = true

                if self.Filters[self.TabSelected] ~= "" then

                    for n = 1, 15 do

                        local obj = quest["Objectives"]
                        if obj then obj = quest["Objectives"][n] end
                        if not obj then
                            break
                        end

                        local name, zone = Nx.Quest:UnpackObjectiveNew (obj)
                        if zone then
                            filterName = filterName .. Map:IdToName (zone)
                        end
                    end

                    local str = strlower (format ("%2d %s %s %s", lvl, title, filterName, tag))
                    local filtStr = strlower (self.Filters[self.TabSelected])

                    show = strfind (str, filtStr, 1, true)
                end

                if show then

                    if addBlank then
                        addBlank = false
                        list:ItemAdd (0)
                    end

                    dbTitleNum = dbTitleNum + 1

                    local trackMode = Quest.Tracking[qId] or 0

                    list:ItemAdd (qId * 0x10000)

                    local haveStr = ""

                    if qIds[qId] then
                        haveStr = "|cffe0e0e0+ "
                    end

                    local color = GetCachedDifficultyColorStr(lvl)

                    local str = format ("%s %s%s%s", lvlStr, haveStr, color, title)

                    if showQId then
                        str = str .. format (" [%s]", qId)
                    end

                    local questTip = "@" .. qId

                    list:ItemSet (2, str)
                    list:ItemSet (4, tag)

                    if sName then
                        list:ItemAdd (qId * 0x10000)

                        if not eName then
                            list:ItemSet (2, "     |cff6060ff" ..L["Start/End: "] .. sName)
                        else
                            list:ItemSet (2, "     |cff6060ff" ..L["Start: "] .. sName)
                        end
                        list:ItemSet (4, sMapName)

                        list:ItemSetButton ("QuestWatch", false)
                        if bit_band (trackMode, 1) > 0 then
                            list:ItemSetButton ("QuestWatch", true)
                        end
                        list:ItemSetButtonTip (questTip)
                    end
                    if eName then
                        list:ItemAdd (qId * 0x10000 + 16 * 0x100)
                        list:ItemSet (2, L["     |cff6060ffEnd: "] .. eName)
                        list:ItemSet (4, eMapName)

                        list:ItemSetButton ("QuestWatch", false)
                        if bit_band (trackMode, 0x10000) > 0 then
                            list:ItemSetButton ("QuestWatch", true)
                        end
                        list:ItemSetButtonTip (questTip)
                    end

                    -- Objective rows intentionally omitted from the
                    -- Database tab. Many quests have only one POI baked in
                    -- (a single city for multi-city/multi-faction quests,
                    -- a single chosen spawn cluster for spread-out kill
                    -- objectives) so the row would mislead more than help.
                    -- Tracked-quest objective POIs in the live tracker are
                    -- unaffected — they get their text from the API.
                end
            end

--            qsindex = qsindex + 1
        end

        local str = (showAllZones and "Full" or Map:IdToName (mapId)) .. L[" Database"]

        list:ItemSet (2, format ("|cffc0c0c0--- %s (%d) ---", str, dbTitleNum), dbTitleIndex)

        local low = max (1, showLowLevel and 1 or minLevel)
        local high = min (Nx.MaxPlayerLevel, maxLevel)
        list:ItemSet (2, format (L["|cffc0c0c0--- Levels %d to %d ---"], low, high), dbTitleIndex + 1)
    end

    -- Add other player quests

    if self.TabSelected == 4 then

        local qIds = Quest.QIds

        list:ItemAdd (0)
        list:ItemSet (2, format ("|cffc0c0c0--- %s %s/%s ---", Quest.RcvPlyrLast, Quest.RcvCnt, Quest.RcvTotal))

        for n = 1, #Quest.FriendQuests do

            local data = Quest.FriendQuests[n]
            local mode = strsub (data, 1, 1)

            list:ItemAdd (0)

            if mode == " " then        -- Simple text

                list:ItemSet (2, strsub (data, 3))

            elseif mode == "H" then

                list:ItemSet (2, format ("|cff8f8fff---- %s ----", strsub (data, 3)))

            elseif mode == "T" then

                local _, qId, watched, done, lvl, name = Nx.Split ("^", data)

                if qId and name then

                    qId = tonumber (qId)

                    if qId >= 0 then

--                        watched = watched == "0" and "" or "*"

                        if watched ~= "0" then
                            list:ItemSet (1, "|cffcfcfcfw")
                        end

                        local haveStr = ""
                        if qIds[qId] then
                            haveStr = "|cffe0e0e0+ "
                        end

                        done = done == "0" and "" or "|cff80ff80 - " .. L["Complete"]

                        list:ItemSet (2, format ("%s %s%s%s", lvl, haveStr, name, done))
                    end
                end

            elseif mode == "O" then

                local _, qId, name = Nx.Split ("^", data)

                if name then

                    local color = done and "|cff5f5f6f" or "|cff9f9faf"
                    local str = format ("     %s%s", color, name)

                    list:ItemSet (2, str)
                end
            end
        end
    end

    --

    list:Update()

    Quest.Watch:Update()

    if self.TabSelected == 1 then

        local i = list:GetSelected()
        local data = list:ItemGetData (i) or 0

--        Nx.prt ("%s %s", i, data)

        if data > 0 then
            Nx.Quest:SelectBlizz (bit_band (data, 0xff))
            NxQuestD:Show()

            Quest:UpdateQuestDetails()
        else
            NxQuestD:Hide()
        end
    end

end

function Nx.Quest.List:CheckShow (mapId, index)
    local Quest = Nx.Quest
    local _qids = {}
    local cnum = 0

    while true do
        cnum = cnum + 1
        local qId = Quest.Sorted[index]

        if Quest:CheckShow (mapId, qId) then
            return true
        end

        local quest = Nx.Quests[qId]
        local qnext = Quest:UnpackNext (quest["Quest"])

        if not qnext or qnext == 0 or _qids[qnext] == true or cnum > 40 then
            return
        end

        _qids[qnext] = true

        index = index + 1
    end
end

-------------------------------------------------------------------------------
-- CLONED BLIZZARD TEXTURE FUNCTIONS
-------------------------------------------------------------------------------

local function ApplyTextureToPOI(texture, width, height)
    texture:SetTexCoord(0, 1, 0, 1);
    texture:ClearAllPoints();
    texture:SetPoint("CENTER", texture:GetParent());
    texture:SetSize(width or 32, height or 32);
end

local function ApplyAtlasTexturesToPOI(button, normal, pushed, highlight, width, height)
    button:SetSize(20, 20);
    button:SetNormalAtlas(normal);
    ApplyTextureToPOI(button:GetNormalTexture(), width, height);

    button:SetPushedAtlas(pushed);
    ApplyTextureToPOI(button:GetPushedTexture(), width, height);

    button:SetHighlightAtlas(highlight);
    ApplyTextureToPOI(button:GetHighlightTexture(), width, height);

    if button.SelectedGlow then
        button.SelectedGlow:SetAtlas(pushed);
        ApplyTextureToPOI(button.SelectedGlow, width, height);
    end
end

local function ApplyStandardTexturesToPOI(button, selected)
    button:SetSize(20, 20);
    button:SetNormalTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");
    ApplyTextureToPOI(button:GetNormalTexture());
    if selected then
        button:GetNormalTexture():SetTexCoord(0.500, 0.625, 0.375, 0.5);
    else
        button:GetNormalTexture():SetTexCoord(0.875, 1, 0.375, 0.5);
    end


    button:SetPushedTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");
    ApplyTextureToPOI(button:GetPushedTexture());
    if selected then
        button:GetPushedTexture():SetTexCoord(0.375, 0.500, 0.375, 0.5);
    else
        button:GetPushedTexture():SetTexCoord(0.750, 0.875, 0.375, 0.5);
    end

    button:SetHighlightTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");
    ApplyTextureToPOI(button:GetHighlightTexture());
    button:GetHighlightTexture():SetTexCoord(0.625, 0.750, 0.875, 1);
end

-- Called when details frame size changes
-------------------------------------------------------------------------------

function Nx.Quest.List:OnDetailsSetSize (w, h)

--    Nx.prt ("QDetails %d %d", w, h)

    local scale = Nx.qdb.profile.Quest.DetailScale

    NXQuestLogDetailScrollChildFrame:SetScale (scale)

    local upH = NxQuestDScrollBarScrollUpButton:GetHeight()

    local bar = NxQuestDScrollBar
    local barW = bar:GetWidth()

    local details = NxQuestD
    bar:SetPoint ("TOPLEFT", details, "TOPRIGHT", 1, -upH)
    details:SetWidth (w - barW - 1)

    local dw = (w - barW - 8) / scale

--    Nx.Quest.List:DetailsSetWidth (dw)
end

function Nx.Quest.List:DetailsSetWidth (w)

--    NXQuestLogDetailScrollChildFrame:SetWidth (w)
--    QuestInfoFrame:SetWidth (w)
    QuestInfoObjectivesText:SetWidth (w)
    QuestInfoDescriptionText:SetWidth (w)
    QuestInfoItemChooseText:SetWidth (w)
--    QuestInfoRewardText:SetWidth (w)
end

-------------------------------------------------------------------------------
-- Details
-------------------------------------------------------------------------------

function Nx.Quest:UpdateQuestDetails()

    -- 1 tick delay, since Blizz is hiding/resetting on log open
    QDetail = Nx:ScheduleTimer(self.UpdateQuestDetailsTimer,0,self)
end

function Nx.Quest:UpdateQuestDetailsTimer()

    QuestInfo_Display (CBQUEST_TEMPLATE, NXQuestLogDetailScrollChildFrame, nil, nil, "Carb")

    local r, g, b, a = Nx.Util_str2rgba (Nx.qdb.profile.Quest.DetailBC)
    -- 0.18, 0.12, 0.06 parchment
    local r, g, b = Nx.Util_str2rgba (Nx.qdb.profile.Quest.DetailTC)

    local t = {
            "QuestInfoTitleHeader", "QuestInfoDescriptionHeader", "QuestInfoObjectivesHeader",
            "QuestInfoDescriptionText", "QuestInfoObjectivesText", "QuestInfoGroupSize", "QuestInfoRewardText",
    }

    for k, name in ipairs (t) do
        if not _G[name] then
--            Nx.prt ("QDetails missing %s", name)
                if( name =="QuestInfoRewardsHeader") then
                local qirFrame = _G["QuestInfoRewardsFrame"]
                if qirFrame then
                    local headerFrame = qirFrame.Header

                    if headerFrame then
                        local frameName = headerFrame:GetName() or "unnamed"
                        --Nx.prt("Frame Name: " .. frameName)
                        headerFrame:SetTextColor (r, g, b)
                    end
                end
            end
        else
            _G[name]:SetTextColor (r, g, b)
        end
    end

    -- Set text colors on reward frame elements (with nil checks for compatibility)
    if MapQuestInfoRewardsFrame then
        if MapQuestInfoRewardsFrame["ItemChooseText"] then
            MapQuestInfoRewardsFrame["ItemChooseText"]:SetTextColor(r, g, b)
        end
        if MapQuestInfoRewardsFrame["ItemReceiveText"] then
            MapQuestInfoRewardsFrame["ItemReceiveText"]:SetTextColor(r, g, b)
        end
        if MapQuestInfoRewardsFrame["PlayerTitleText"] then
            MapQuestInfoRewardsFrame["PlayerTitleText"]:SetTextColor(r, g, b)
        end
    end

    for n = 1, 10 do
        if _G["QuestInfoObjective" .. n] then
            _G["QuestInfoObjective" .. n]:SetTextColor (r, g, b)
        end
    end
end

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

function Nx.Quest:FrameItems_Update (questState)

    NxQuestDSCRewardTitleText:SetPoint ("TOPLEFT", "NxQuestDSC", "TOPLEFT", 0, -10)

    local questState = "NxQuestDSC"
    local questItemName = "NxQuestDSCItem"

    local numQuestRewards
    local numQuestChoices
    local money = GetQuestLogRewardMoney()
    local spacerFrame = NxQuestDSCSpacerFrame

    numQuestRewards = GetNumQuestLogRewards()
    numQuestChoices = GetNumQuestLogChoices()

    local numQuestSpellRewards = 0
    if GetQuestLogRewardSpell() then
        numQuestSpellRewards = 1
    end

    local totalRewards = numQuestRewards + numQuestChoices + numQuestSpellRewards
    local material = QuestFrame_GetMaterial()
    local questItemReceiveText = _G[QuestState.."ItemReceiveText"]

    if totalRewards == 0 and money == 0 then
        _G[questState.."RewardTitleText"]:Hide()
    else
        _G[questState.."RewardTitleText"]:Show()
        QuestFrame_SetTitleTextColor (_G[questState.."RewardTitleText"], material)
        QuestFrame_SetAsLastShown (_G[questState.."RewardTitleText"], spacerFrame)
    end

    if money == 0 then
        _G[questState.."MoneyFrame"]:Hide()
    else
        _G[questState.."MoneyFrame"]:Show()
        QuestFrame_SetAsLastShown (_G[questState.."MoneyFrame"], spacerFrame)
        MoneyFrame_Update (questState.."MoneyFrame", money)
    end

    -- Hide unused rewards

    for n = totalRewards + 1, MAX_NUM_ITEMS do
        _G[questItemName..n]:Hide()
    end

    local questItem, name, texture, isTradeskillSpell, isSpellLearned, quality, isUsable, numItems = 1
    local rewardsCount = 0

    -- Setup choosable rewards

    if numQuestChoices > 0 then
        local itemChooseText = _G[questState.."ItemChooseText"]
        itemChooseText:Show()
        QuestFrame_SetTextColor (itemChooseText, material)
        QuestFrame_SetAsLastShown (itemChooseText, spacerFrame)

        local index
        local baseIndex = rewardsCount

        for i = 1, numQuestChoices do

            index = i + baseIndex
            questItem = _G[questItemName..index]
            questItem.type = "choice"
            numItems = 1

            name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo (i)

            questItem:SetID (i)
            questItem:Show()

            -- For the tooltip
            questItem.rewardType = "item"

            _G[questItemName..index.."Name"]:SetText(name)
            SetItemButtonCount (questItem, numItems)
            SetItemButtonTexture (questItem, texture)

            if isUsable then
                SetItemButtonTextureVertexColor (questItem, 1.0, 1.0, 1.0)
                SetItemButtonNameFrameVertexColor (questItem, 1.0, 1.0, 1.0)
            else
                SetItemButtonTextureVertexColor (questItem, 0.9, 0, 0)
                SetItemButtonNameFrameVertexColor (questItem, 0.9, 0, 0)
            end

            if i > 1 then

                if mod (i, 2) == 1 then
                    questItem:SetPoint ("TOPLEFT", questItemName..(index - 2), "BOTTOMLEFT", 0, -2)
                    QuestFrame_SetAsLastShown (questItem, spacerFrame)

                else
                    questItem:SetPoint ("TOPLEFT", questItemName..(index - 1), "TOPRIGHT", 1, 0)
                end

            else
                questItem:SetPoint ("TOPLEFT", itemChooseText, "BOTTOMLEFT", 0, -5)
                QuestFrame_SetAsLastShown (questItem, spacerFrame)
            end

            rewardsCount = rewardsCount + 1
        end
    else
        _G[questState.."ItemChooseText"]:Hide()
    end

    -- Setup spell rewards

    local learnSpellText = _G[questState.."SpellLearnText"]

    if numQuestSpellRewards > 0 then

        learnSpellText:Show()
        QuestFrame_SetTextColor (learnSpellText, material)
        QuestFrame_SetAsLastShown (learnSpellText, spacerFrame)

        --Anchor learnSpellText if there were choosable rewards
        if rewardsCount > 0 then
            learnSpellText:SetPoint("TOPLEFT", questItemName..rewardsCount, "BOTTOMLEFT", 3, -5)
        else
            learnSpellText:SetPoint("TOPLEFT", questState.."RewardTitleText", "BOTTOMLEFT", 0, -5)
        end

        texture, name, isTradeskillSpell, isSpellLearned = GetQuestLogRewardSpell()

        if isTradeskillSpell then
            learnSpellText:SetText (REWARD_TRADESKILL_SPELL)
        elseif not isSpellLearned then
            learnSpellText:SetText (REWARD_AURA)
        else
            learnSpellText:SetText (REWARD_SPELL)
        end

        rewardsCount = rewardsCount + 1

        questItem = _G[questItemName..rewardsCount]
        questItem:Show()
        -- For the tooltip
        questItem.rewardType = "spell"
        SetItemButtonCount (questItem, 0)
        SetItemButtonTexture (questItem, texture)
        _G[questItemName..rewardsCount.."Name"]:SetText(name)

        QuestFrame_SetAsLastShown (questItem, spacerFrame)

        questItem:SetPoint ("TOPLEFT", learnSpellText, "BOTTOMLEFT", 0, -5)
    else
        learnSpellText:Hide()
    end

    -- Setup mandatory rewards
    if numQuestRewards > 0 or money > 0 then
        QuestFrame_SetTextColor (questItemReceiveText, material)

        -- Anchor the reward text differently if there are choosable rewards
        if numQuestSpellRewards > 0 then
            questItemReceiveText:SetText (REWARD_ITEMS)
            questItemReceiveText:SetPoint ("TOPLEFT", questItemName..rewardsCount, "BOTTOMLEFT", 3, -5)

        elseif numQuestChoices > 0 then
            questItemReceiveText:SetText (REWARD_ITEMS)
            local index = numQuestChoices
            if mod (index, 2) == 0 then
                index = index - 1
            end
            questItemReceiveText:SetPoint ("TOPLEFT", questItemName..index, "BOTTOMLEFT", 3, -5)

        else
            questItemReceiveText:SetText (REWARD_ITEMS_ONLY)
            questItemReceiveText:SetPoint ("TOPLEFT", questState.."RewardTitleText", "BOTTOMLEFT", 3, -5)
        end

        questItemReceiveText:Show()
        QuestFrame_SetAsLastShown (questItemReceiveText, spacerFrame)

        -- Setup mandatory rewards
        local index
        local baseIndex = rewardsCount

        for i = 1, numQuestRewards do

            index = i + baseIndex
            questItem = _G[questItemName..index]
            questItem.type = "reward"
            numItems = 1

            name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo (i)

            questItem:SetID (i)
            questItem:Show()
            -- For the tooltip
            questItem.rewardType = "item"
            _G[questItemName..index.."Name"]:SetText(name)
            SetItemButtonCount (questItem, numItems)
            SetItemButtonTexture (questItem, texture)

            if isUsable then
                SetItemButtonTextureVertexColor (questItem, 1.0, 1.0, 1.0)
                SetItemButtonNameFrameVertexColor (questItem, 1.0, 1.0, 1.0)
            else
                SetItemButtonTextureVertexColor (questItem, 0.5, 0, 0)
                SetItemButtonNameFrameVertexColor (questItem, 1.0, 0, 0)
            end

            if i > 1 then

                if mod (i, 2) == 1 then
                    questItem:SetPoint ("TOPLEFT", questItemName..(index - 2), "BOTTOMLEFT", 0, -2)
                    QuestFrame_SetAsLastShown (questItem, spacerFrame)

                else
                    questItem:SetPoint ("TOPLEFT", questItemName..(index - 1), "TOPRIGHT", 1, 0)
                end

            else
                questItem:SetPoint ("TOPLEFT", questState.."ItemReceiveText", "BOTTOMLEFT", 0, -5)
                QuestFrame_SetAsLastShown (questItem, spacerFrame)

            end

            rewardsCount = rewardsCount + 1
        end
    else
        questItemReceiveText:Hide()
    end
end

-------------------------------------------------------------------------------
