-- Carbonite.Quests | WatchWindow
-- The Carbonite Quest Watch panel: init, layout, font, show/hide,
-- sort modes, list-control update, watch-list builder, the static
-- emissary/bounty helpers, ClearCompleted, AddQuestToWatch, plus
-- the per-frame Watch:Update entry point called from MapEngine and
-- the main update tick.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed. Mirrors the
-- block at the top of NxQuest.lua; the watch UI does a lot of
-- formatted strings + bit ops so the aliases are worth keeping.
local bit_band   = bit.band
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local floor      = math.floor
local max        = math.max
local strfind    = strfind  or string.find
local strsub     = strsub   or string.sub
local strbyte    = strbyte  or string.byte
local strmatch   = strmatch or string.match
local format     = format   or string.format
local gsub       = gsub     or string.gsub
local tinsert    = tinsert  or table.insert
local sort       = sort     or table.sort
local wipe       = wipe     or table.wipe
local GetTime              = GetTime
local InCombatLockdown     = InCombatLockdown
local GetQuestObjectiveInfo = GetQuestObjectiveInfo

-- Promoted from NxQuest.lua's file-local cache helper.
local GetCachedDifficultyColorStr = Nx.Quest.GetCachedDifficultyColorStr

-- Promoted from NxQuest.lua's file-local compat shim.
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

-- Packed rows can contain quest IDs larger than WoW's 32-bit bit operations.
local GetPackedQuestID = Nx.Quest.GetPackedQuestID

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Quest watch
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Init and open
-------------------------------------------------------------------------------

function Nx.Quest.Watch:Open()
    self.GOpts = opts
    local qopts = Nx.Quest:GetQuestOpts()

    self.Watched = {}

    self.Opened = true

    local fixedSize = Nx.qdb.profile.QuestWatch.FixedSize

    -- Create window

--    Nx.Window:ClrSaveData ("NxQuestWatch")

    Nx.Window:SetCreateFade (1, .15)

    local border = fixedSize and false or 0

    local win = Nx.Window:Create ("NxQuestWatch", nil, nil, nil, 1, border)
    self.Win = win

    win:InitLayoutData (nil, -.80, -.35, -.2, -.1)

    -- The user can treat the two layouts as one movable window or retain the
    -- legacy independent full/minimized positions. Apply this after the normal
    -- default is initialized so a first-time user's independent backup is valid.
    win:SetShareMinimizePosition (Nx.qdb.profile.QuestWatch.ShareMinimizePosition)

    win:CreateButtons (Nx.qdb.profile.QuestWatch.ShowClose, nil, true)

    win:SetUser (self, self.OnWin)
    win:SetBGAlpha (0, 1)
    win.Frm:SetClampedToScreen (true)

    local xo = 0
    local yo = 0

    if fixedSize then
        xo = 7
        yo = 3
        win:SetBorderSize (0, 7)
        win.Sizeable = false
    end

    win:SetTitleXOff (84 + xo, -1 - yo)

--    win:SetTitle ("[  ]")
    win.UserUpdateFade = self.WinUpdateFade

    -- Update helper. Can't call directly due to validation changing function

    local function update (self)
        self:Update()
    end

    -- Buttons

    local function func (self)
        self.Menu:Open()
    end
    self.ButMenu = Nx.Button:Create (win.Frm, "QuestWatchMenu", nil, nil, 4, -5 + yo, "TOPLEFT", 1, 1, func, self)

    local function func (self)
        self.MenuPri:Open()
    end
    self.ButPri = Nx.Button:Create (win.Frm, "QuestWatchPri", nil, nil, 19, -5 + yo, "TOPLEFT", 1, 1, func, self)

    local function func (self, but)
        local qopts = Nx.Quest:GetQuestOpts()
        qopts.NXWShowOnMap = but:GetPressed()
    end
    self.ButShowOnMap = Nx.Button:Create (self.ButMenu.Frm, "QuestWatchShowOnMap", nil, nil, 44, 0, "CENTER", 1, 1, func, self)
    self.ButShowOnMap:SetPressed (qopts.NXWShowOnMap)

    local function func (self, but)
        local qopts = Nx.Quest:GetQuestOpts()
        qopts.NXWATrack = but:GetPressed()
        if not but:GetPressed() and not IsShiftKeyDown() then
            Nx.Quest.Tracking = {}    -- Kill all
        end
        self:Update()
    end
    self.ButATarget = Nx.Button:Create (self.ButMenu.Frm, "QuestWatchATrack", nil, nil, 56, 0, "CENTER", 1, 1, func, self)
    self.ButATarget:SetPressed (qopts.NXWATrack)

    local function func (self, but)
        Nx.db.char.Map.ShowQuestGivers = but:GetState()
        local map = Nx.Map:GetMap (1)
        map.Guide:UpdateGatherFolders()
    end
    self.ButQGivers = Nx.Button:Create (self.ButMenu.Frm, "QuestWatchGivers", nil, nil, 68, 0, "CENTER", 1, 1, func, self)
    self.ButQGivers:SetState (Nx.db.char.Map.ShowQuestGivers)

    local function func (self, but)
        qopts.NXWWatchParty = but:GetPressed()
        Nx.Quest:PartyUpdateTimer()
    end
    self.ButShowParty = Nx.Button:Create (self.ButMenu.Frm, "QuestWatchParty", nil, nil, 80, 0, "CENTER", 1, 1, func, self)
    self.ButShowParty:SetPressed (qopts.NXWWatchParty == nil or qopts.NXWWatchParty)

    -- List

    Nx.List:SetCreateFont ("QuestWatch.WatchFont", 12)

    local list = Nx.List:Create (false, 2, -2, 100, 12 * 3, win.Frm, fixedSize, true)
    self.List = list

    list:SetUser (self, self.OnListEvent)
--    self:SetFont()

    if fixedSize then
        list:SetMinSize (124, 1)        -- Sets the window minimum
        list.Frm:EnableMouse (false)
    end

    list:ColumnAdd ("", 1, 14)
    list:ColumnAdd ("Name", 2, not fixedSize and 900 or 20)
--    list:ColumnAdd ("", 3, 0)
--    list:ColumnAdd ("Type", 4, 60)
--    list:ColumnAdd ("Status", 5, 500)

    win:Attach (list.Frm, 0, 1, 0, 1)

    -- Create menu button menu

    local qlist = Nx.Quest.List

    local menu = Nx.Menu:Create (list.Frm)
    self.Menu = menu

    menu:AddItem (0, L["Watch All Quests"], qlist.Menu_OnWatchAll, qlist)
    menu:AddItem (0, L["Remove All Watches"], self.Menu_OnRemoveAllWatches, self)

    menu:AddItem (0, L["Track None"], qlist.Menu_OnTrackNone, qlist)

--    local item = menu:AddItem (0, L["Max Auto Track"], update, self)
--    item:SetSlider (qopts, 1, 25, 1, "NXWAutoMax")

    local i = 25

    local item = menu:AddItem (0, L["Max Visible In List"], update, self)
    item:SetSlider (qopts, 1, i, 1, "NXWVisMax")

    if Nx.Quest.WQList:IsAvailable() then
        menu:AddItem (0, "")
        local function func()
            Nx.Quest.WQList:Show()
        end
        menu:AddItem (0, L["Open World Quest List"], func)
    end

    local function func()
        Nx.Opts:Open ("Quest Watch")
    end

    menu:AddItem (0, L["Options..."], func)

    --local item = menu:AddItem (0, L["Hide BfA Emmissaries"], update, self)
    --item:SetChecked (qopts, "NXWHideBfAEmmissaries")

    --local item = menu:AddItem (0, L["Hide Legion Emmissaries"], update, self)
    --item:SetChecked (qopts, "NXWHideLegionEmmissaries")

    -- Create priority button menu

    local menu = Nx.Menu:Create (list.Frm, 300)
    self.MenuPri = menu

    local item = menu:AddItem (0, L["Hide Unfinished Quests"], update, self)
    item:SetChecked (qopts, "NXWHideUnfinished")

    local item = menu:AddItem (0, L["Hide 5+ Group Quests"], update, self)
    item:SetChecked (qopts, "NXWHideGroup")

    local item = menu:AddItem (0, L["Hide Quests Not In Zone"], update, self)
    item:SetChecked (qopts, "NXWHideNotInZone")

--    local item = menu:AddItem (0, L["Hide Quests Not On Continent"], update, self)
--    item:SetChecked (qopts, "NXWHideNotInCont")

    local item = menu:AddItem (0, L["Hide Quests Farther Than"], update, self)
    item:SetSlider (qopts, 200, 20000, 1, "NXWHideDist")

    local item = menu:AddItem (0, L["Sort, Distance"], update, self)
    item:SetSlider (qopts, 0, 1, nil, "NXWPriDist")

    local item = menu:AddItem (0, L["Sort, Complete"], update, self)
    item:SetSlider (qopts, -200, 200, 1, "NXWPriComplete")

    local item = menu:AddItem (0, L["Sort, Low Level"], update, self)
    item:SetSlider (qopts, -200, 200, 1, "NXWPriLevel")

    local function func()
        Nx.Map:GetMap (1).Guide:UpdateGatherFolders()
    end

    local item = menu:AddItem (0, L["Quest Giver Lower Levels To Show"], func, self)
    item:SetSlider (Nx.qdb.profile.Quest, 0, 90, 1, "MapQuestGiversLowLevel")

    local item = menu:AddItem (0, L["Quest Giver Higher Levels To Show"], func, self)
    item:SetSlider (Nx.qdb.profile.Quest, 0, 90, 1, "MapQuestGiversHighLevel")

--    local item = menu:AddItem (0, L["Group"], update, self)
--    item:SetSlider (qopts, -200, 200, 1, "NXWPriGroup")

    -- Create watch button menu

    local menu = Nx.Menu:Create (list.Frm)
    self.WatchMenu = menu

    menu:AddItem (0, L["Set as Active Quest"], self.Menu_OnSetActive, self)
    menu:AddItem (0, L["Remove Watch"], self.Menu_OnRemoveWatch, self)
    menu:AddItem (0, L["Link Quest (shift right click)"], self.Menu_OnLinkQuest, self)
    menu:AddItem (0, L["Wowhead Link"], self.Menu_OnWowhead, self)
    menu:AddItem (0, L["Show Quest Log (alt right click)"], self.Menu_OnShowQuest, self)
    menu:AddItem (0, L["Show On Map (shift left click)"], self.Menu_OnShowMap, self)
    menu:AddItem (0, L["Share"], self.Menu_OnShare, self)

    menu:AddItem (0, "")
    menu:AddItem (0, L["Abandon"], self.Menu_OnAbandon, self)

    -- A minimized watch is only its title strip and minimize/restore switch.
    -- Preserve each control's prior shown state so restore also respects the
    -- optional close button and any controls hidden before minimization.
    local minimizedHideFrames = {
        list.Frm,
        self.ButMenu.Frm,
        self.ButPri.Frm,
        self.ButShowOnMap.Frm,
        self.ButATarget.Frm,
        self.ButQGivers.Frm,
        self.ButShowParty.Frm,
    }

    if win.ButClose then
        tinsert (minimizedHideFrames, win.ButClose.Frm)
    end
    if win.ButMaxer then
        tinsert (minimizedHideFrames, win.ButMaxer.Frm)
    end

    win:SetMinimizedHideFrames (minimizedHideFrames)

    self.FirstUpdate = true
    self.FlashColor = 0

    --

    self:SetSortMode (1)

    win:SetMinimize (win.SaveData["Minimized"])
    if Nx.Quest and Nx.Quest.TrackerHider_Apply then
        Nx.Quest:TrackerHider_Apply()
    end
end

-------------------------------------------------------------------------------
-- Setup list font
-------------------------------------------------------------------------------

function Nx.Quest.Watch:FixedChange()

    Nx.Window:ClrSaveData ("NxQuestWatch")
end

-------------------------------------------------------------------------------

function Nx.Quest.Watch:OnWin (typ)
    if self.Win:GetLayoutMode() == "Min" then
        self.FirstUpdate = true
        self.Win:SetTitle ("")
    end
    self:Update()
end

-------------------------------------------------------------------------------

function Nx.Quest.Watch:Menu_OnRemoveWatch (item)

    self:RemoveWatch (self.MenuQId, self.MenuQIndex)
    self:Update()
    Nx.Quest.List:Update()
end

function Nx.Quest.Watch:Menu_OnShowQuest()

    ToggleQuestLog()
    --ShowUIPanel (QuestMapFrame)

    Nx.Quest.List.Bar:Select (1)
    Nx.Quest.List:Select (self.MenuQId, self.MenuQIndex)
end

function Nx.Quest.Watch:Menu_OnShowMap (item)

    self:Set (self.MenuItemData, true)
end

function Nx.Quest.Watch:Menu_OnLinkQuest()

    Nx.Quest:LinkChat (self.MenuQId)
end

-- Build the Wowhead URL for a quest, with the per-flavor subdomain.
-- Retail uses the bare domain; Classic flavors use their slug
-- (classic / tbc / wotlk / cata / mop-classic).
function Nx.Quest:WowheadURL (qId)
    local sub = ""
    if Nx.isClassicEra then sub = "classic/"
    elseif Nx.isTBCClassic then sub = "tbc/"
    elseif Nx.isWotlkClassic then sub = "wotlk/"
    elseif Nx.isCataClassic then sub = "cata/"
    elseif Nx.isMoPClassic then sub = "mop-classic/"
    end
    return format ("https://www.wowhead.com/%squest=%d", sub, qId)
end

-- Show a small popup with the quest's Wowhead URL, pre-selected and
-- locked to the URL so it can be copied (Ctrl+C) but not edited.
-- Carbonite's packed/stored qId can drift from Blizzard's live questID
-- (saved-vars from a previous session, story/display IDs, etc.), so when
-- a quest-log index is available resolve the live ID off it -- the same
-- guard the left-click super-track path uses.
function Nx.Quest:ShowWowheadLink (qId, qIndex)
    if qIndex and qIndex > 0 then
        if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
            local q = C_QuestLog.GetQuestIDForLogIndex (qIndex)
            if q and q > 0 then qId = q end
        elseif GetQuestIDFromLogIndex then
            local q = GetQuestIDFromLogIndex (qIndex)
            if q and q > 0 then qId = q end
        end
    end
    if not qId or qId == 0 then return end
    local url = self:WowheadURL (qId)
    if not StaticPopupDialogs["NxWowheadLink"] then
        StaticPopupDialogs["NxWowheadLink"] = {
            text = "Wowhead (Ctrl+C):",
            button1 = OKAY or "Okay",
            hasEditBox = 1,
            editBoxWidth = 280,
            whileDead = 1,
            hideOnEscape = 1,
            timeout = 0,
            preferredIndex = 3,        -- avoid taint of the default index
            OnShow = function (self)
                local eb = self.editBox or (self.GetName and _G[self:GetName() .. "EditBox"])
                if eb then
                    eb:SetText (self.data or "")
                    eb:HighlightText()
                    eb:SetFocus()
                end
            end,
            EditBoxOnTextChanged = function (eb)
                local parent = eb:GetParent()
                if eb:GetText() ~= parent.data then
                    eb:SetText (parent.data or "")
                    eb:HighlightText()
                end
            end,
            EditBoxOnEnterPressed  = function (eb) eb:GetParent():Hide() end,
            EditBoxOnEscapePressed = function (eb) eb:GetParent():Hide() end,
        }
    end
    StaticPopup_Show ("NxWowheadLink", nil, nil, url)
end

function Nx.Quest.Watch:Menu_OnWowhead()
    Nx.Quest:ShowWowheadLink (self.MenuQId, self.MenuQIndex)
end

function Nx.Quest.Watch:Menu_OnShare (item)

    local qi = self.MenuQIndex
    if qi > 0 then

        if GetNumSubgroupMembers() > 0 then
            Nx.Quest:ExpandQuests()
--            Nx.Quest.List:Select (self.MenuQId, self.MenuQIndex)
            QuestLogPushQuest (qi)
            Nx.Quest:RestoreExpandQuests()
        else
            Nx.prt (L["Must be in party to share"])
        end
    end
end

function Nx.Quest.Watch:Menu_OnAbandon (item)
    Nx.Quest.List:Select (self.MenuQId, self.MenuQIndex)
    Nx.Quest:Abandon (self.MenuQIndex, self.MenuQId)
end

function Nx.Quest.Watch:Menu_OnSetActive (item)
    -- "Set as Active Quest" — Blizzard's super-track on retail / Wrath+
    -- Classic; on older flavors fall back to mirroring it as the only
    -- Carbonite-tracked quest, which drives the same map blob/arrow.
    local qId = self.MenuQId
    if not qId or qId <= 0 then
        return
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
        -- Combat-defer: insecure super-track mutations fire
        -- SUPER_TRACKING_CHANGED in our taint and trip the protected
        -- SetPassThroughButtons in Blizzard's QuestDataProvider.
        Nx.SuperTrackSafe(function()
            Nx.SetSuperTrackedQuestIDSafe(qId)
        end)
        return
    end
    local cur = Nx.Quest.CurQ and self.MenuQIndex and Nx.Quest:FindCurByIndex(self.MenuQIndex)
    local mask = cur and cur.TrackMask
    if not mask or mask == 0 then mask = 0xffffffff end
    Nx.Quest.Tracking = {}
    Nx.Quest.Tracking[qId] = mask
    if not InCombatLockdown() then
        Nx.Quest:TrackOnMap(qId, 0, true, true)
    end
    self:Update()
end

function Nx.Quest.Watch:Menu_OnRemoveAllWatches (item)

    local curq = Nx.Quest.CurQ

    for n = 1, curq and #curq or 0 do

        local cur = curq[n]
        self:RemoveWatch (cur.QId, cur.QI)
    end

    self:Update()
    Nx.Quest.List:Update()
end

local function GetBlizzardQuestWatchState (questId, questIndex)
    if not questId or questId <= 0 then
        return nil
    end

    if C_QuestLog and C_QuestLog.GetQuestWatchType then
        return C_QuestLog.GetQuestWatchType (questId) ~= nil
    end

    if questIndex and questIndex > 0 and IsQuestWatched then
        return IsQuestWatched (questIndex) and true or false
    end

    return nil
end

local function GetLiveQuestIndex (questId, fallbackIndex)
    local questIndex

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        questIndex = C_QuestLog.GetLogIndexForQuestID (questId)
    elseif GetQuestLogIndexByID then
        questIndex = GetQuestLogIndexByID (questId)
    end

    if questIndex and questIndex > 0 then
        return questIndex
    end

    -- During quest-log rebuilds Carbonite can still hold the prior index.
    -- Reuse it only when the client can confirm that it still names this ID.
    if fallbackIndex and fallbackIndex > 0 then
        if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
            if C_QuestLog.GetQuestIDForLogIndex (fallbackIndex) == questId then
                return fallbackIndex
            end
        elseif GetQuestIDFromLogIndex then
            if GetQuestIDFromLogIndex (fallbackIndex) == questId then
                return fallbackIndex
            end
        else
            return fallbackIndex
        end
    end

    return 0
end

function Nx.Quest.Watch:SyncBlizzardWatch (questId, questIndex, watched)
    local profile = Nx.qdb and Nx.qdb.profile
    if not profile or not profile.QuestWatch or not profile.QuestWatch.Sync
            or not questId or questId <= 0 then
        return false
    end

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        questIndex = C_QuestLog.GetLogIndexForQuestID (questId)
    elseif GetQuestLogIndexByID then
        questIndex = GetQuestLogIndexByID (questId)
    end

    if not questIndex or questIndex <= 0 then
        return false
    end

    local currentlyWatched = GetBlizzardQuestWatchState (questId, questIndex)
    if currentlyWatched == watched then
        return false
    end

    local Quest = Nx.Quest
    Nx.SuperTrackSafe (function()
        local liveIndex = questIndex
        if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
            liveIndex = C_QuestLog.GetLogIndexForQuestID (questId)
        elseif GetQuestLogIndexByID then
            liveIndex = GetQuestLogIndexByID (questId)
        end

        if not liveIndex or liveIndex <= 0
                or GetBlizzardQuestWatchState (questId, liveIndex) == watched then
            return
        end

        if Nx.isRetail and C_QuestLog then
            local isWorldQuest = QuestUtils_IsQuestWorldQuest
                and QuestUtils_IsQuestWorldQuest (questId)
            local changeWatch
            if isWorldQuest then
                changeWatch = watched and C_QuestLog.AddWorldQuestWatch
                    or C_QuestLog.RemoveWorldQuestWatch
            else
                changeWatch = watched and C_QuestLog.AddQuestWatch
                    or C_QuestLog.RemoveQuestWatch
            end
            if changeWatch then
                changeWatch (questId)
            end
            return
        end

        local changeWatch = watched and AddQuestWatch or RemoveQuestWatch
        if not changeWatch then
            return
        end

        -- Classic hooks AddQuestWatch to infer map-pin clicks. Mirroring a
        -- watch-list change is not a click and must not toggle the active quest.
        local previousSuppress = Quest._addWatchSuppress
        Quest._addWatchSuppress = true
        changeWatch (liveIndex)
        Quest._addWatchSuppress = previousSuppress
    end)

    return true
end

function Nx.Quest.Watch:OnBlizzardWatchChanged (questId, added)
    local Quest = Nx.Quest
    local profile = Nx.qdb and Nx.qdb.profile
    if not profile or not profile.QuestWatch or not profile.QuestWatch.Sync
            or not Quest.CurCharacter or not Quest.CurCharacter.Q then
        return
    end

    local function ApplyWatchState (changedQuestId, questIndex, watched)
        if type (changedQuestId) ~= "number" or changedQuestId <= 0
                or watched == nil then
            return false
        end

        local currentStatus, currentTime = Quest:GetQuest (changedQuestId)
        local changed = false
        if watched then
            if currentStatus ~= "W" then
                self.ApplyingBlizzardWatch = true
                Quest:SetQuest (changedQuestId, "W", currentTime)
                self.ApplyingBlizzardWatch = nil
                changed = true
            end
        else
            local liveIndex = GetLiveQuestIndex (changedQuestId, questIndex)
            local shouldSetUnwatched = currentStatus == "W"
                or (liveIndex > 0 and currentStatus == nil)

            -- A historical "C" normally belongs to a quest already turned
            -- in and must survive Blizzard's automatic watch removal. Only
            -- repair it when Blizzard confirms the still-active quest has not
            -- actually been completed by this character.
            if currentStatus == "C" and liveIndex > 0
                    and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
                    and not C_QuestLog.IsQuestFlaggedCompleted (changedQuestId) then
                shouldSetUnwatched = true
            end

            -- Preserve completed history after turn-in, when the quest has
            -- already left the log. If it is still an active log entry, an
            -- unwatch is authoritative even when stale data marked it "C".
            if shouldSetUnwatched then
                self.ApplyingBlizzardWatch = true
                Quest:SetQuest (changedQuestId, "c", currentTime)
                self.ApplyingBlizzardWatch = nil
                changed = true
            end

            if Quest.Tracking then
                Quest.Tracking[changedQuestId] = nil
            end

            if Quest.AcceptRefreshGuard and Quest.AcceptRefreshGuard.WatchedQuestIds then
                Quest.AcceptRefreshGuard.WatchedQuestIds[changedQuestId] = nil
            end

            if Quest.IsTargeted and Quest:IsTargeted (changedQuestId)
                    and Quest.Map and Quest.Map.ClearTargets then
                Quest.Map:ClearTargets()
            end
        end

        return changed
    end

    local changed = false
    local refresh = false
    if type (questId) == "number" and questId > 0 then
        local cur = Quest.QIds and Quest.QIds[questId]
        if not cur and Quest.CurQ then
            for _, candidate in ipairs (Quest.CurQ) do
                if candidate.QId == questId and candidate.QI and candidate.QI > 0 then
                    cur = candidate
                    break
                end
            end
        end

        local questIndex = GetLiveQuestIndex (questId, cur and cur.QI)
        if added == nil then
            added = GetBlizzardQuestWatchState (questId, questIndex)
        end
        changed = ApplyWatchState (questId, questIndex, added)

        -- The event itself is authoritative. Rebuild even when Carbonite's
        -- saved status already matched it so a stale rendered row is removed.
        refresh = added ~= nil
    else
        local seenQuestIds = {}
        for _, cur in ipairs (Quest.CurQ or {}) do
            local currentQuestId = cur.QId
            if cur.QI and cur.QI > 0 and currentQuestId and currentQuestId > 0
                    and not seenQuestIds[currentQuestId] then
                seenQuestIds[currentQuestId] = true
                local questIndex = GetLiveQuestIndex (currentQuestId, cur.QI)
                local watched = GetBlizzardQuestWatchState (currentQuestId, questIndex)
                changed = ApplyWatchState (currentQuestId, questIndex, watched) or changed
            end
        end
    end

    if not changed and not refresh then
        return
    end

    self.ForceListRefresh = true
    self:Update()

    local questList = Quest.List
    if questList and questList.Win and questList.Win.IsShown
            and questList.Win:IsShown() then
        questList:Update()
    end
end

function Nx.Quest.Watch:RemoveWatch (qId, qI)

    local i, cur, id = Nx.Quest:FindCur (qId, qI)

    if i then

        local qStatus, qTime = Nx.Quest:GetQuest (id)
        if qStatus ~= "c" and qStatus ~= "C" then

            Nx.Quest:SetQuest (id, "c", qTime)
            Nx.Quest:PartyStartSend()
        end

        if qId > 0 then
            Nx.Quest.Tracking[qId] = nil

            if Nx.Quest:IsTargeted (qId) then
                Nx.Quest.Map:ClearTargets()
            end

            self:SyncBlizzardWatch (qId, qI, false)
        end

        self.ForceListRefresh = true
    end
end

-------------------------------------------------------------------------------
-- Show or hide
-------------------------------------------------------------------------------

function Nx.NXWatchKeyToggleMini()

    local self = Nx.Quest.Watch
--    self.ButMini:SetPressed (not self.ButMini:GetPressed())

    self.Win:ToggleMinimize()
    self:Update()
end

function Nx.NXWatchKeyUseItem()

    if NxListFrms1 then
        NxListFrms1:Click()
    end
end

function Nx.Quest.Watch:ClearAutoTarget (keepTracking)

    if Nx.Quest.Enabled then

        if not keepTracking then
            Nx.Quest.Tracking = {}    -- Kill all
        end
        self.ButATarget:SetPressed (false)
        self:Update()
    end
end

-------------------------------------------------------------------------------
-- Set sort mode
-------------------------------------------------------------------------------

local QuestWatchDistUp

function Nx.Quest.Watch:SetSortMode (mode)
    QuestWatchUpdate = Nx:ScheduleTimer(self.OnUpdateTimer,.01,self)
end

function Nx.Quest.Watch:OnUpdateTimer (item)

    if Nx:TimeLeft(QuestWatchDistUp) == 0 then
        self:Update()
        self.CalcDistCnt = 3
    end
    return 1.5
end

-------------------------------------------------------------------------------
-- Update list security stub
-------------------------------------------------------------------------------

local qw_elapsed = 0
local qw_lasttime
local qw_ttl = 9999

local function checkWatchTimer()
    if qw_lasttime then
        local curtime = debugprofilestop()
        qw_elapsed = curtime - qw_lasttime
        qw_lasttime = curtime
    else
        qw_lasttime = debugprofilestop()
    end
    qw_ttl = qw_ttl + qw_elapsed
    if qw_ttl < Nx.qdb.profile.QuestWatch.RefreshTimer then
        return false
    end
    qw_ttl = 0
    return true
end

function Nx.Quest.Watch:Update()
    self.CalcDistI = 1
    self.CalcDistCnt = 25

    if QuestWatchDistUp then
        Nx:CancelTimer(QuestWatchDistUp)
        QuestWatchDistUp = nil
    end

    -- Explicit membership changes must rebuild on the next timer tick instead
    -- of waiting behind the ordinary distance/objective refresh delay.
    local delay = self.ForceListRefresh and 0.01 or 0.5
    QuestWatchDistUp = Nx:ScheduleTimer(self.OnTimer, delay, self)
end

function Nx.Quest.Watch:ClearCustom ()
    Nx.Quest.Custom = {}
end

function Nx.Quest.Watch:AddCustom(newstring, newstring2, newstring3)
    local num = #Nx.Quest.Custom
    num = num + 1
    Nx.Quest.Custom[num] = {}
    Nx.Quest.Custom[num].str = newstring
    if newstring2 then
        Nx.Quest.Custom[num].buttontxt = newstring2
    end
    if newstring3 then
        Nx.Quest.Custom[num].buttonfunc = newstring3
    end
end

function Nx.Quest.Watch:OnTimer (item)

    local curq = Nx.Quest.CurQ
    if not curq then
        QuestWatchDistUp = nil
        return
    end

    local i = self.CalcDistI
    local cnt = self.CalcDistCnt

    Nx.Quest:CalcDistances (i, i + cnt - 1)

    i = i + cnt

    if i <= #curq then
        self.CalcDistI = i
        QuestWatchDistUp = Nx:ScheduleTimer(self.OnTimer,.2,self)
        return
    end

    local watched = self:UpdateList()
    QuestWatchDistUp = nil

--    Nx.Quest:Route (watched)
end

-------------------------------------------------------------------------------
-- Update watch list helper functions (moved outside for performance)
-------------------------------------------------------------------------------

-- Emissary click handler (static function to avoid recreation)
local function WatchList_EmmFunc(id)
    local qId = GetPackedQuestID(id)
    local bId = bit_band(id, 0xff)
    --WorldMapFrame.overlayFrames[3].SetSelectedBountyIndex(bId)
end

-- Add objectives to tooltip (static function)
local function WatchList_AddObjectives(tip, questID, numObjectives)
    for objectiveIndex = 1, numObjectives do
        local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(questID, objectiveIndex, false)
        if objectiveText and #objectiveText > 0 then
            local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR
            tip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true)
        end
    end
end

-- Scan tooltip for bounty info (static function)
local function WatchList_ScanTip(bounty)
    local tipVisible = GameTooltip:IsShown()
    local tipText = ""
    local questIndex = GetQuestLogIndexByID(bounty.questID)
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(questIndex)

    if title and not tipVisible then
        -- Use Nx.TooltipText as scratchpad to avoid tainting GameTooltip
        local scanTip = Nx.TooltipText
        scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
        if scanTip.ItemTooltip then scanTip.ItemTooltip:Hide() end

        scanTip:SetText(title, HIGHLIGHT_FONT_COLOR:GetRGB())
        if Nx.Quest.AddQuestTimeToTooltipCompat then
            Nx.Quest.AddQuestTimeToTooltipCompat(scanTip, bounty.questID)
        end

        local _, questDescription = GetQuestLogQuestText(questIndex)
        scanTip:AddLine(questDescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)

        WatchList_AddObjectives(scanTip, bounty.questID, bounty.numObjectives)

        if bounty.turninRequirementText then
            scanTip:AddLine(bounty.turninRequirementText, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
        end

        if GameTooltip_AddQuestRewardsToTooltip then
            GameTooltip_AddQuestRewardsToTooltip(scanTip, bounty.questID, TOOLTIP_QUEST_REWARDS_STYLE_EMISSARY_REWARD)
        end

        local numLines = scanTip:NumLines()
        for i = 1, numLines do
            local lineText = scanTip["TextLeft"..i] and scanTip["TextLeft"..i]:GetText() or ""
            if lineText then
                if i == 2 or i == 3 or strfind(lineText, "Rewards") then
                    tipText = tipText .. format("|cff%02x%02x%02x%s", NORMAL_FONT_COLOR.r * 255, NORMAL_FONT_COLOR.g * 255, NORMAL_FONT_COLOR.b * 255, lineText) .. "|r\n"
                else
                    if i == numLines then
                        local money = GetQuestLogRewardMoney(bounty.questID)
                        if money > 0 then
                            tipText = tipText .. GetCoinTextureString(money)
                        end
                    end
                    tipText = tipText .. lineText .. "\n"
                end
            end
        end
        local itemTip = scanTip.ItemTooltip
        if itemTip and itemTip.NumLines then
            for i = 1, itemTip:NumLines() do
                local tipTexture = itemTip.Icon and itemTip.Icon:GetTexture()
                local textFrame = itemTip["TextLeft"..i]
                if textFrame then
                    local r, g, b = textFrame:GetTextColor()
                    tipText = tipText .. ((i == 1 and tipTexture) and "|T"..tipTexture..":33|t " or "\n") .. format("|cff%02x%02x%02x%s", r * 255, g * 255, b * 255, textFrame:GetText()) .. "|r\n"
                end
            end
        end
        scanTip:Hide()
    end

    return tipText
end

-------------------------------------------------------------------------------
-- Scenario compatibility and rendering
-------------------------------------------------------------------------------

-- C_ScenarioInfo is the current structured API. Keep the tuple-returning
-- C_Scenario path as a fallback for supported Classic clients and older
-- branches that have not exposed the structured functions yet.
local function WatchList_GetScenarioInfo()
    if C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo then
        local info = C_ScenarioInfo.GetScenarioInfo()
        if info then
            return info
        end
    end

    if C_Scenario and C_Scenario.GetInfo then
        local name, currentStage, numStages, flags, isComplete = C_Scenario.GetInfo()
        if name then
            return {
                name = name,
                currentStage = currentStage or 0,
                numStages = numStages or 0,
                flags = flags or 0,
                isComplete = isComplete or false,
            }
        end
    end
end

local function WatchList_GetScenarioStepInfo(stepID)
    if C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo then
        local info = C_ScenarioInfo.GetScenarioStepInfo(stepID)
        if info then
            return info
        end
    end

    if C_Scenario and C_Scenario.GetStepInfo then
        local title, description, numCriteria, stepFailed, isBonusStep,
            isForCurrentStepOnly, shouldShowBonusObjective, _, _,
            weightedProgress, rewardQuestID, widgetSetID, returnedStepID =
            C_Scenario.GetStepInfo(stepID)
        if title then
            return {
                title = title,
                description = description or "",
                numCriteria = numCriteria or 0,
                stepFailed = stepFailed or false,
                isBonusStep = isBonusStep or false,
                isForCurrentStepOnly = isForCurrentStepOnly or false,
                shouldShowBonusObjective = shouldShowBonusObjective or false,
                weightedProgress = weightedProgress,
                rewardQuestID = rewardQuestID or 0,
                widgetSetID = widgetSetID,
                stepID = returnedStepID or stepID,
            }
        end
    end
end

local function WatchList_GetScenarioCriteriaInfo(criteriaIndex, stepID)
    if C_ScenarioInfo then
        local info
        if stepID and C_ScenarioInfo.GetCriteriaInfoByStep then
            info = C_ScenarioInfo.GetCriteriaInfoByStep(stepID, criteriaIndex)
        elseif C_ScenarioInfo.GetCriteriaInfo then
            info = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
        end
        if info then
            return info
        end
    end

    if C_Scenario then
        local getter
        if stepID and C_Scenario.GetCriteriaInfoByStep then
            getter = function()
                return C_Scenario.GetCriteriaInfoByStep(stepID, criteriaIndex)
            end
        elseif C_Scenario.GetCriteriaInfo then
            getter = function()
                return C_Scenario.GetCriteriaInfo(criteriaIndex)
            end
        end

        if getter then
            local description, criteriaType, completed, quantity, totalQuantity,
                flags, assetID, quantityString, criteriaID, duration, elapsed,
                failed, isWeightedProgress, isFormatted = getter()
            if description then
                return {
                    description = description,
                    criteriaType = criteriaType or 0,
                    completed = completed or false,
                    quantity = quantity or 0,
                    totalQuantity = totalQuantity or 0,
                    flags = flags or 0,
                    assetID = assetID or 0,
                    quantityString = quantityString or "",
                    criteriaID = criteriaID or 0,
                    duration = duration or 0,
                    elapsed = elapsed or 0,
                    failed = failed or false,
                    isWeightedProgress = isWeightedProgress or false,
                    isFormatted = isFormatted or false,
                }
            end
        end
    end
end

local function WatchList_FormatScenarioCriteria(info)
    local description = info.description or ""

    if info.isFormatted then
        return description
    end

    if info.isWeightedProgress then
        local quantityString = info.quantityString
        if quantityString and quantityString ~= "" then
            return format("%s %s", quantityString, description)
        end
    end

    local quantity = info.quantity or 0
    local totalQuantity = info.totalQuantity or 0
    if totalQuantity > 0 then
        return format("%d/%d %s", quantity, totalQuantity, description)
    end

    return description
end

local function WatchList_AddScenarioCriteria(list, info)
    local text = WatchList_FormatScenarioCriteria(info)
    local status
    if info.completed then
        status = L["Complete"] or "Complete"
    elseif info.failed then
        status = FAILED or "Failed"
    end

    if status then
        text = format("%s |cffff0000[|cffffffff%s|cffff0000]", text, status)
    end

    list:ItemAdd(0)
    list:ItemSetOffset(16, -1)
    list:ItemSet(2, "|cffffffff" .. text)
    list:ItemSetButton("QuestWatch", false)

    local duration = info.duration or 0
    local elapsed = info.elapsed or 0
    if duration > 0 and elapsed <= duration and not info.completed and not info.failed then
        list:ItemAdd(0)
        list:ItemSetOffset(16, -1)
        list:ItemSet(2, format("|cffffffff%s: %s",
            L["Time Left"] or "Time Left",
            Nx.Util_GetTimeElapsedMinSecStr(duration - elapsed)))
    end
end

local function WatchList_AddScenario(list)
    local scenarioInfo = WatchList_GetScenarioInfo()
    if not scenarioInfo or not scenarioInfo.name or (scenarioInfo.numStages or 0) <= 0 then
        return false
    end

    local currentStage = scenarioInfo.currentStage or 0
    local numStages = scenarioInfo.numStages or 0
    local scenarioComplete = scenarioInfo.isComplete or currentStage > numStages
    local stepInfo = WatchList_GetScenarioStepInfo()

    list:ItemAdd(0)
    list:ItemSet(2, format("|cffff8888%s%s", L["Scenario: "] or "Scenario: ", scenarioInfo.name))
    if stepInfo and stepInfo.description and stepInfo.description ~= "" then
        list:ItemSetButtonTip(stepInfo.description)
    end
    list:ItemSetButton("QuestWatch", false)

    local stageText
    if scenarioComplete then
        stageText = format(" |cffff0000[|cffffffff%s|cffff0000]", L["Complete"] or "Complete")
    elseif currentStage > 0 then
        stageText = format(" |cffff0000%s[|cffffffff%d|cffff0000/|cffffffff%d|cffff0000]",
            L["Stage "] or "Stage ", currentStage, numStages)
        if stepInfo and stepInfo.title and stepInfo.title ~= "" then
            stageText = stageText .. ": |cff00ff00" .. stepInfo.title
        end
    end

    if stageText then
        list:ItemAdd(0)
        list:ItemSet(2, stageText)
    end

    local shouldShowCriteria = true
    if C_Scenario and C_Scenario.ShouldShowCriteria then
        shouldShowCriteria = C_Scenario.ShouldShowCriteria()
    end

    if shouldShowCriteria and not scenarioComplete and stepInfo then
        for criteriaIndex = 1, stepInfo.numCriteria or 0 do
            local criteriaInfo = WatchList_GetScenarioCriteriaInfo(criteriaIndex)
            if criteriaInfo then
                WatchList_AddScenarioCriteria(list, criteriaInfo)
            end
        end
    end

    -- Bonus step enumeration remains on C_Scenario in current clients. Render
    -- each visible step independently so a Delve with more than one bonus
    -- objective does not collapse them into a single mismatched row.
    if C_Scenario and C_Scenario.GetBonusSteps then
        local bonusSteps = C_Scenario.GetBonusSteps() or {}
        for _, stepID in ipairs(bonusSteps) do
            local bonusInfo = WatchList_GetScenarioStepInfo(stepID)
            if bonusInfo then
                local bonusTitle = bonusInfo.title
                if not bonusTitle or bonusTitle == "" then
                    bonusTitle = BONUS_OBJECTIVE or "Bonus Objective"
                end

                list:ItemAdd(0)
                list:ItemSet(2, format(" |cffff0000%s: |cff00ff00%s",
                    BONUS_OBJECTIVE or "Bonus Objective", bonusTitle))

                for criteriaIndex = 1, bonusInfo.numCriteria or 0 do
                    local criteriaInfo = WatchList_GetScenarioCriteriaInfo(criteriaIndex, stepID)
                    if criteriaInfo then
                        WatchList_AddScenarioCriteria(list, criteriaInfo)
                    end
                end
            end
        end
    end

    return true
end

-- GetQuestsOnMap is not exclusively a bonus-objective feed on modern retail:
-- Midnight also includes ordinary campaign/story quests. Blizzard routes those
-- through CampaignQuestObjectiveTracker, which enumerates the actual quest
-- watches, rather than through its task tracker. Keep the same separation here
-- so a map entry cannot resurrect a quest that the player explicitly unwatched.
local function WatchList_ShouldShowTask (Quest, questId, questIndex)
    if type (questId) ~= "number" or questId <= 0
            or Quest:GetQuest (questId) == "c" then
        return false
    end

    local questInfo
    if C_QuestLog then
        if (not questIndex or questIndex <= 0)
                and C_QuestLog.GetLogIndexForQuestID then
            questIndex = C_QuestLog.GetLogIndexForQuestID (questId)
        end

        if questIndex and questIndex > 0 and C_QuestLog.GetInfo then
            questInfo = C_QuestLog.GetInfo (questIndex)
        end
    end

    local classifications = Enum and Enum.QuestClassification
    local classification = questInfo and questInfo.questClassification
    if classification == nil and C_QuestInfoSystem
            and C_QuestInfoSystem.GetQuestClassification then
        classification = C_QuestInfoSystem.GetQuestClassification (questId)
    end

    local campaignClassification = classifications and classifications.Campaign
    if campaignClassification ~= nil
            and classification == campaignClassification then
        return false
    end

    if questInfo and (questInfo.campaignID ~= nil or questInfo.isStory) then
        return false
    end

    local isWorldQuest = false
    if C_QuestLog and C_QuestLog.IsWorldQuest then
        isWorldQuest = C_QuestLog.IsWorldQuest (questId)
    elseif QuestUtils_IsQuestWorldQuest then
        isWorldQuest = QuestUtils_IsQuestWorldQuest (questId)
    end

    -- A normal accepted quest can also appear in the map feed. Only genuine
    -- bonus/task objectives and world quests belong in the separate section.
    if questInfo and questInfo.isTask == false and not isWorldQuest then
        return false
    end

    if C_QuestLog and C_QuestLog.IsQuestTask
            and not C_QuestLog.IsQuestTask (questId)
            and not isWorldQuest then
        return false
    end

    return true
end

-- Blizzard distinguishes a world quest the player deliberately pinned from
-- the Automatic watch created while the player is inside the quest's area.
-- Only the former is persistent: an Automatic watch must not keep a task in
-- Carbonite's tracker after GetTaskInfo reports that the player left it.
--
-- Older clients do not expose GetQuestWatchType. On those clients an entry in
-- the world-quest watch list is treated as persistent, preserving the legacy
-- behaviour instead of guessing at a watch type that the API cannot report.
local function WatchList_IsPersistentWorldQuestWatch (
    isWatched,
    watchType,
    watchTypesKnown
)
    if not isWatched then
        return false
    end

    if not watchTypesKnown then
        return true
    end

    local questWatchTypes = Enum and Enum.QuestWatchType
    if not questWatchTypes or questWatchTypes.Manual == nil then
        return true
    end

    return watchType == questWatchTypes.Manual
end

-- GetTaskInfo is still Blizzard's authoritative in-area predicate on Retail
-- (and is what Blizzard_WorldQuestObjectiveTracker uses). IsOnQuest only says
-- that a quest is in the log; using it as an area test caused Automatic world
-- quest watches to survive after QUEST_REMOVED. Keep IsOnQuest solely as a
-- compatibility fallback for clients that do not provide GetTaskInfo.
local function WatchList_IsTaskInArea (questId)
    if GetTaskInfo then
        local isInArea = GetTaskInfo (questId)
        return isInArea == true
    end

    return C_QuestLog and C_QuestLog.IsOnQuest
        and C_QuestLog.IsOnQuest (questId) == true or false
end

-- Queue every world-quest feed into one ordered section. Current-map tasks,
-- quest-log task fallbacks, and manually watched off-map quests can report the
-- same quest, so use the quest ID as the stable de-duplication key.
local function WatchList_QueueWorldQuest(
    worldQuests,
    queuedQuestIDs,
    questId,
    title,
    numObjectives
)
    if type(questId) ~= "number" or questId <= 0 then
        return false
    end

    if queuedQuestIDs[questId] then
        return false
    end

    queuedQuestIDs[questId] = true
    worldQuests[#worldQuests + 1] = {
        questId = questId,
        title = title,
        numObjectives = numObjectives,
    }
    return true
end

local function WatchList_AddTaskQuestRows(
    list,
    questId,
    title,
    numObjectives,
    titleRowID
)
    if type(questId) ~= "number" or questId <= 0 then
        return false
    end

    if (not title or title == "")
        and C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
        title = C_TaskQuest.GetQuestInfoByQuestID(questId)
    end
    if (not title or title == "")
        and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        title = C_QuestLog.GetTitleForQuestID(questId)
    end

    if type(titleRowID) ~= "number" then
        titleRowID = questId * 0x10000
    end
    list:ItemAdd(titleRowID)
    list:ItemSet(
        2,
        Nx.Util_str2colstr(Nx.qdb.profile.QuestWatch.OIncompleteColor)
            .. (title or L["Retrieving data"] or "")
    )

    if type(numObjectives) ~= "number" then
        numObjectives = C_QuestLog and C_QuestLog.GetNumQuestObjectives
            and C_QuestLog.GetNumQuestObjectives(questId)
    end
    if type(numObjectives) == "number" and numObjectives > 0 then
        for objectiveIndex = 1, numObjectives do
            local text, objectiveType =
                GetQuestObjectiveInfo(questId, objectiveIndex, false)
            if objectiveType == "progressbar" then
                list:ItemAdd(0)
                list:ItemSetOffset(16, -1)
                local percent = C_TaskQuest
                    and C_TaskQuest.GetQuestProgressBarInfo
                    and C_TaskQuest.GetQuestProgressBarInfo(questId) or 0
                if Nx.qdb.profile.QuestWatch.BonusBar then
                    local filled = floor(percent)
                    local empty = 100 - filled
                    local bar = filled > 0
                        and format(
                            " |TInterface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarB:12:%d:|t",
                            filled
                        )
                        or " "
                    if empty > 0 then
                        bar = bar .. format(
                            "|TInterface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarBG:12:%d:|t",
                            empty
                        )
                    end
                    list:ItemSet(2, format("%s %.2f%%", bar, percent))
                else
                    list:ItemSet(
                        2,
                        format("|cff00ff00%s %.2f%%", L["Progress: "], percent)
                    )
                end
            elseif text and text ~= "" then
                list:ItemAdd(0)
                list:ItemSetOffset(16, -1)
                list:ItemSet(2, "|cff00ff00" .. text)
            end
        end
    end

    return true
end

local function WatchList_AddWorldQuestSection(list, worldQuests)
    if #worldQuests == 0 then
        return false
    end

    list:ItemAdd(0)
    list:ItemSet(
        2,
        "|cffff00ff----[ |cffffff00"
            .. L["WORLD QUEST"]
            .. " |cffff00ff]----"
    )

    for _, worldQuest in ipairs(worldQuests) do
        WatchList_AddTaskQuestRows(
            list,
            worldQuest.questId,
            worldQuest.title,
            worldQuest.numObjectives
        )
    end

    list:ItemAdd(0)
    list:ItemSet(2, "|cffff00ff------------------------------")
    return true
end

-------------------------------------------------------------------------------
-- Update watch list
-------------------------------------------------------------------------------

function Nx.Quest.Watch:UpdateList()
--    Nx.prt ("QWatchUpdate")

    local Nx = Nx
    local Quest = Nx.Quest
    local Map = Nx.Map
    local map = Map:GetMap(1)
    local qopts = Nx.Quest:GetQuestOpts()

    -- Cache quest options (accessed once at start)
    local hideBfAEmmissaries = qopts["NXWHideBfAEmmissaries"]
    local hideLegionEmmissaries = qopts["NXWHideLegionEmmissaries"]
    local hideUnfinished = qopts["NXWHideUnfinished"]
    local hideGroup = qopts["NXWHideGroup"]
    local hideNotInZone = qopts["NXWHideNotInZone"]
    local hideNotInCont = qopts["NXWHideNotInCont"]
    local rawHideDist = qopts["NXWHideDist"]
    local hideDist = (rawHideDist >= 19900 and 99999 or rawHideDist) / 4.575  -- Convert to world units
    local priDist = qopts.NXWPriDist

    local gopts = self.GOpts

    -- Cache profile settings (avoid repeated deep lookups)
    local qwProfile = Nx.qdb.profile.QuestWatch
    local fixedSize = qwProfile.FixedSize
    local showDist = qwProfile.ShowDist
    local showPerColor = qwProfile.ShowPerColor
    local hideDoneObj = qwProfile.HideDoneObj
    local itemScale = qwProfile.ItemScale
    local itemAlpha = qwProfile.ItemAlpha
    local oMaxLen = qwProfile.OMaxLen
    local hideBlizz = qwProfile.HideBlizz

    -- Cache color settings
    local Cols = Quest.Cols
    local compColor = Cols["compColor"]
    local incompColor = Cols["incompColor"]
    local oCompColor = Cols["oCompColor"]
    local oIncompColor = Cols["oIncompColor"]

    -- Cache the super-tracked quest so each row can flag the active one.
    -- Matches what the rest of the modern WoW UI considers "the quest the
    -- arrow is pointing at" — POI on map, objective tracker row, etc.
    -- Same source as UpdateIcons: super-track on retail / Wrath+,
    -- Carbonite ActiveQID on older flavors.
    local superTrackedQID = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()) or 0
    if superTrackedQID == 0 then
        superTrackedQID = Nx.Quest.ActiveQID or 0
    end

    -- List

    local list = self.List

    local oldw, oldh = list:GetSize()

    local clearlist = checkWatchTimer()
    if self.ForceListRefresh then
        clearlist = true
        self.ForceListRefresh = nil
    end

    if clearlist then
        list:SetBGColor (Nx.Quest.Cols["BGColorR"], Nx.Quest.Cols["BGColorG"], Nx.Quest.Cols["BGColorB"], Nx.Quest.Cols["BGColorA"])
        list:Empty()
    end
    local watched = wipe (self.Watched)
    local curq = Quest.CurQ

    if curq then

        for n, cur in ipairs (curq) do
            local qId = cur.QId
            local id = qId > 0 and qId or cur.Title
            local qStatus = Nx.Quest:GetQuest (id)
            -- Party progress annotates our own watched quests; it must not
            -- override an explicit unwatch. Keep showing party-only quests
            -- until the user explicitly removes their watch as well.
            local qWatched = qStatus == "W"
                or (cur.Party and cur.PartyDesc and qStatus ~= "c")

--            Nx.prt ("qid %s %s dist %s", qId, qStatus, cur.Distance)

            if qWatched and (cur.Distance < hideDist or cur.Distance > 999999) then

                if (not hideUnfinished or cur.CompleteMerge) and
                    (not hideGroup or cur.PartySize < 5) and
                    (not hideNotInZone or cur.InZone) and
                    (not hideNotInCont or cur.InCont) then

                    local d = max (cur.Distance * priDist * cur.Priority * 10 + cur.Priority * 100, 0)
                    d = cur.HighPri and 0 or d
                    d = floor (d) * 256 + n
                    tinsert (watched, d)
                end
            end
        end

        sort (watched)
        local disti = watched[1]

        -- Auto target objective of closest quest

        if self.ButATarget:GetPressed() then
            if disti then
                local cur = curq[bit_band (disti, 0xff)]
                Quest:CalcAutoTrack (cur)
            end
        end

        -- Remember closest quest for com

        self.ClosestCur = disti and curq[bit_band(disti, 0xff)]

        --

        -- Emmissaries (using static helper functions defined above UpdateList)
        local emmBfA_Sel = nil --WorldMapFrame.overlayFrames[3].selectedBountyIndex
        local emmLegion_Sel = nil --WorldMapFrame.overlayFrames[3].selectedBountyIndex

        -- BfA
        if not hideBfAEmmissaries and #Nx.Quest.emmBfA > 0 then
            list:ItemAdd(0)
            list:ItemSet(2,"|cff00ff00----[ |cffffff00" .. "BfA Emissaries" .. " |cff00ff00]----")

            for bountyIndex, bounty in ipairs(Nx.Quest.emmBfA) do
                local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(bounty.questID, 1, false)
                if objectiveText then
                    list:ItemAdd(bounty.questID * 0x10000 + bountyIndex)
                    list:ItemSetOffset (16, -1)
                    list:ItemSet(2,"|cffcccccc" .. objectiveText)
                    list:ItemSetButtonTip(WatchList_ScanTip(bounty))
                    list:ItemSetButton("QuestWatchEmissaryTip", emmBfA_Sel == bountyIndex)
                    list:ItemSetFunc(WatchList_EmmFunc, bounty.questID * 0x10000 + bountyIndex)
                end
            end

            if #Nx.Quest.emmLegion == 0 or hideLegionEmmissaries then
                list:ItemAdd(0)
                list:ItemSet(2,"|cff00ff00--------------------------------")
            end
        end

        -- Legion
        if not hideLegionEmmissaries and #Nx.Quest.emmLegion > 0 then
            list:ItemAdd(0)
            list:ItemSet(2,"|cff00ff00----[ |cffffff00" .. "Legion Emissaries" .. " |cff00ff00]----")

            for bountyIndex, bounty in ipairs(Nx.Quest.emmLegion) do
                local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(bounty.questID, 1, false)

                if objectiveText then
                    list:ItemAdd(bounty.questID * 0x10000 + bountyIndex)
                    list:ItemSetOffset (16, -1)
                    list:ItemSet(2,"|cffcccccc" .. objectiveText)
                    list:ItemSetButtonTip(WatchList_ScanTip(bounty))
                    list:ItemSetButton("QuestWatchEmissaryTip", emmLegion_Sel == bountyIndex)
                    list:ItemSetFunc(WatchList_EmmFunc, bounty.questID * 0x10000 + bountyIndex)
                end
            end

            list:ItemAdd(0)
            list:ItemSet(2,"|cff00ff00-------------------------------------")
        end

        if not self.Win:IsSizeMin() and self.Win:IsVisible() then
            self.FlashColor = (self.FlashColor + 1) % 2
            list:SetItemFrameScaleAlpha (itemScale, Nx.Util_str2a (itemAlpha))
            if hideBlizz and not InCombatLockdown() then
                --ObjectiveTrackerFrame:Hide()        -- Hide Blizzard's
            end
            if Nx.Quest.AltView then
                local curnum = 1
                for a,b in pairs (Nx.Quest.Custom) do
                    list:ItemAdd(curnum)
                    list:ItemSet(2,Nx.Quest.Custom[a].str)
                    if Nx.Quest.Custom[a].buttontxt then
                        list:ItemSetButtonTip(Nx.Quest.Custom[a].buttontxt)
                        list:ItemSetButton("QuestWatchCustomTip",false)
                    end
                    if Nx.Quest.Custom[a].buttonfunc then
                        list:ItemSetFunc(Nx.Quest.Custom[a].buttonfunc)
                    end
                    curnum = curnum + 1
                end
            else
                if clearlist then
                if Nx.qdb.profile.QuestWatch.ChalTrack then
                  local cTimer = {} --{GetWorldElapsedTimers()}
                    for a,id in ipairs(cTimer) do
                      local ProvingGroundsType, _, _, _ = C_Scenario.GetProvingGroundsInfo()
                      if ProvingGroundsType ~= 0 then
                        id = 2
                      end
                      local description, elapsedTime, isChallengeModeTimer = GetWorldElapsedTime(id)
                      if isChallengeModeTimer == 2 then
                        list:ItemAdd(0)
                        list:ItemSet(2,format("|cffff8888%s",description))
                        list:ItemSetButton("QuestWatch",false)
                        local s = "  |cffffffff" .. SecondsToTime(elapsedTime)
                        list:ItemAdd(0)
                        list:ItemSet(2,s)
                      end
                      if isChallengeModeTimer == 3 then
                        local difficulty, curWave, maxWave, duration = C_Scenario.GetProvingGroundsInfo()
                        local diff = ""
                        list:ItemAdd(0)
                        if difficulty == 1 then
                            diff = "|cffffffff" ..L["Difficulty: "] .."|cff8C7853" ..L["Bronze"]
                        end
                        if difficulty == 2 then
                            diff = "|cffffffff" ..L["Difficulty: "] .."|cffC0C0C0" ..L["Silver"]
                        end
                        if difficulty == 3 then
                            diff = "|cffffffff" ..L["Difficulty: "] .."|cffC77826" ..L["Gold"]
                        end
                        list:ItemSet(2,format("|cffff8888%s",diff))
                        list:ItemSetButton("QuestWatch",false)
                        local s = "  |cffff0000 " ..L["Wave: "] .."[|cffffffff" .. curWave .. "|cffff0000/|cffffffff" .. maxWave .. "|cffff0000]|cff00ff00 " .. SecondsToTime(duration-elapsedTime)
                        list:ItemAdd(0)
                        list:ItemSet(2,s)
                      end
                    end
                end
                if qwProfile.ScenTrack then
                    WatchList_AddScenario(list)
                end
                local tasks = {}
                local worldQuests = {}
                local queuedWorldQuestIDs = {}
                local watchedWorldQuestIDs = {}
                local watchedWorldQuests = {}
                local watchedWorldQuestTypes = {}
                local worldQuestWatchTypesKnown = C_QuestLog
                    and C_QuestLog.GetQuestWatchType ~= nil

                -- Blizzard's world-quest watch list is independent of the
                -- current map and quest-log task lists. Preserve its order and
                -- use a set for the two existing feed paths to avoid duplicates.
                if C_QuestLog
                    and C_QuestLog.GetNumWorldQuestWatches
                    and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
                    local watchCount = C_QuestLog.GetNumWorldQuestWatches()
                    for watchIndex = 1, watchCount do
                        local questId =
                            C_QuestLog.GetQuestIDForWorldQuestWatchIndex(watchIndex)
                        if questId and questId > 0 and not watchedWorldQuests[questId] then
                            watchedWorldQuests[questId] = true
                            if worldQuestWatchTypesKnown then
                                watchedWorldQuestTypes[questId] =
                                    C_QuestLog.GetQuestWatchType(questId)
                            end
                            watchedWorldQuestIDs[#watchedWorldQuestIDs + 1] = questId
                        end
                    end
                end
                -- World quests / bonus tasks feed. The 12.0 engine is unified
                -- across flavors, but some C_TaskQuest functions are disabled
                -- on individual Classic clients. Discover candidates through
                -- GetQuestsOnMap, then use GetTaskInfo (when available) only
                -- for its authoritative in-area flag. Gate the feed so a
                -- client missing the discovery API skips it without erroring.
                local taskApiOK = C_TaskQuest and C_TaskQuest.GetQuestsOnMap
                    and C_TaskQuest.GetQuestInfoByQuestID
                if Nx.qdb.profile.QuestWatch.BonusTask and taskApiOK then
                    local taskInfo = C_TaskQuest.GetQuestsOnMap(Nx.Map.UpdateMapID)
                    if taskInfo then
                        for i=1,#taskInfo do
                            local questId = taskInfo[i].questID
                            local numObjectives = taskInfo[i].numObjectives
                            tasks[questId] = true
                            local persistentWatch =
                                WatchList_IsPersistentWorldQuestWatch(
                                    watchedWorldQuests[questId],
                                    watchedWorldQuestTypes[questId],
                                    worldQuestWatchTypesKnown
                                )
                            -- Manual watches remain visible outside the area.
                            -- Automatic/unwatched tasks require Blizzard's
                            -- live in-area flag and the ordinary task filter.
                            if persistentWatch
                                or WatchList_IsTaskInArea(questId)
                                    and WatchList_ShouldShowTask (Quest, questId) then
                                local title, factionID = C_TaskQuest.GetQuestInfoByQuestID(questId)
                                local questTagInfo = GetQuestTagInfoCompat(questId)
                                local tagID = questTagInfo and questTagInfo.tagID
                                local tagName = questTagInfo and questTagInfo.tagName
                                local worldQuestType = questTagInfo and questTagInfo.worldQuestType
                                local rarity = questTagInfo and questTagInfo.quality
                                local isElite = questTagInfo and questTagInfo.isElite
                                local tradeskillLineIndex = questTagInfo and questTagInfo.tradeskillLineID
                                if worldQuestType ~= nil then
                                    WatchList_QueueWorldQuest(
                                        worldQuests,
                                        queuedWorldQuestIDs,
                                        questId,
                                        title,
                                        numObjectives
                                    )
                                else
                                    list:ItemAdd(0)
                                    list:ItemSet(2,"|cffff00ff----[ |cffffff00" .. L["BONUS TASK"] .. " |cffff00ff]----")
                                    WatchList_AddTaskQuestRows(
                                        list,
                                        questId,
                                        title,
                                        numObjectives,
                                        questId * 0x10000
                                    )
                                    list:ItemAdd(0)
                                    list:ItemSet(2,"|cffff00ff----------------------------")
                                end
                            end
                        end
                    end
                    local taskInfo = GetNumQuestLogEntries()
                    if taskInfo > 0 then
                        for i=1,taskInfo do
                            local title, _, _, _, _, _, _, questId, _, _, _, _, isTask, _ = GetQuestLogTitle(i)
                            if isTask and tasks[questId] ~= true
                                    and WatchList_ShouldShowTask (Quest, questId, i) then
                                tasks[questId] = true
                                local title, factionID = C_TaskQuest.GetQuestInfoByQuestID(questId)
                                local questTagInfo = GetQuestTagInfoCompat(questId)
                                local tagID = questTagInfo and questTagInfo.tagID
                                local tagName = questTagInfo and questTagInfo.tagName
                                local worldQuestType = questTagInfo and questTagInfo.worldQuestType
                                local rarity = questTagInfo and questTagInfo.quality
                                local isElite = questTagInfo and questTagInfo.isElite
                                local tradeskillLineIndex = questTagInfo and questTagInfo.tradeskillLineID
                                local numObjectives = C_QuestLog and C_QuestLog.GetNumQuestObjectives
                                    and C_QuestLog.GetNumQuestObjectives(questId)
                                if worldQuestType ~= nil then
                                    WatchList_QueueWorldQuest(
                                        worldQuests,
                                        queuedWorldQuestIDs,
                                        questId,
                                        title,
                                        numObjectives
                                    )
                                else
                                    list:ItemAdd(0)
                                    list:ItemSet(2,"|cffff00ff----[ |cffffff00" .. L["BONUS TASK"] .. " |cffff00ff]----")
                                    WatchList_AddTaskQuestRows(
                                        list,
                                        questId,
                                        title,
                                        numObjectives,
                                        0
                                    )
                                    list:ItemAdd(0)
                                    list:ItemSet(2,"|cffff00ff-------------------------------")
                                end
                            end
                        end
                    end

                    -- A manually watched WQ can be outside the current map and
                    -- absent from the regular quest log. Add only persistent
                    -- (Manual, or legacy untyped) watches here. Automatic
                    -- watches are area-scoped and must not leak into this feed.
                    for _, questId in ipairs(watchedWorldQuestIDs) do
                        local persistentWatch =
                            WatchList_IsPersistentWorldQuestWatch(
                                true,
                                watchedWorldQuestTypes[questId],
                                worldQuestWatchTypesKnown
                            )
                        if persistentWatch and tasks[questId] ~= true then
                            tasks[questId] = true
                            WatchList_QueueWorldQuest(
                                worldQuests,
                                queuedWorldQuestIDs,
                                questId
                            )
                        end
                    end

                    -- Emit one shared section after all three feeds have been
                    -- merged. Individual world quests keep their own title and
                    -- objectives, but no longer repeat the section header.
                    WatchList_AddWorldQuestSection(list, worldQuests)
                end
                if Nx.qdb.profile.QuestWatch.AchTrack then
                    local achs = Nx.Quest.TrackedAchievements
                    for id, ach in pairs (achs) do
                        local aId, aName, aPoints, aComplete, aMonth, aDay, aYear, aDesc, numC, aCriteria = unpack(ach)
                        if aName then        -- Person had nil name happen
                            list:ItemAdd (0)
                            list:ItemSet (2, format ("|cffdf9fff" ..L["Achievement:"] .. " %s", aName))
                            local progressCnt = 0
                            local tip = aDesc
                            for n = 1, numC do
                                local cName, cType, cComplete, cQuantity, cReqQuantity, _, _, _, cQuantityString = unpack(aCriteria[n])
                                local color = cComplete and "|cff80ff80" or "|cffa0a0a0"
                                if not cComplete and cReqQuantity > 1 and cQuantity > 0 then
                                    progressCnt = progressCnt + 1
                                    tip = tip .. (cQuantityString and format ("\n%s%s: %s", color, cName, cQuantityString) or format ("\n%s%s: %s / %s", color, cName, cQuantity, cReqQuantity))
                                else
                                    tip = tip .. format ("\n%s%s", color, cName)
                                end
                            end
                            list:ItemSetButton ("QuestWatchTip", false)
                            list:ItemSetButtonTip (tip)
                            local showCnt = 0
                            for n = 1, numC do
                                local cName, cType, cComplete, cQuantity, cReqQuantity, _, _, _, cQuantityString = unpack(aCriteria[n])
                                if not cComplete and (progressCnt <= 3 or cQuantity > 0) then
                                    list:ItemAdd (0)
                                    local s = "  |cffcfafcf"
                                    if numC == 1 then
                                        if cReqQuantity > 1 then
                                            s = s .. (cQuantityString or format ("%s/%s", cQuantity, cReqQuantity))
                                        else
                                            s = s .. cName
                                        end
                                    else
                                        s = s .. cName
                                        if cReqQuantity > 1 then
                                            s = s .. format (": %s/%s", cQuantity, cReqQuantity)
                                        end
                                    end
                                    showCnt = showCnt + 1
                                    if showCnt >= 3 then
                                        s = s .. "..."
                                    end
                                    list:ItemSet (2, s)
                                    if showCnt >= 3 then
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                local s = Nx.qdb.profile.QuestWatch.AchZoneShow and Nx.Map:GetZoneAchievement()
                if s then
                    list:ItemAdd (0)
                    list:ItemSet (2, s)
                end

    --            Nx.prtVar ("Watched", watched)

                local watchNum = 1

                for _, distn in ipairs (watched) do

                    local n = bit_band (distn, 0xff)

                    local cur = curq[n]
                    local qId = cur.QId
                    --if not IsQuestTask(qId) then
                    if true then
                        if 1 then
                            local level, isComplete = cur.Level, cur.CompleteMerge
                            local isAC = cur.IsAutoComplete
                            -- Cached flags can drift from server truth between
                            -- RecordQuestsLog passes. In particular, once
                            -- Blizzard's AutoQuestPopup processes a
                            -- ShowQuestComplete call the popup is removed,
                            -- and a follow-up RecordQuestsLog can drop
                            -- cur.IsAutoComplete even when the quest is still
                            -- pending server-side (e.g. user closed the
                            -- completion dialog because bags were full).
                            -- Re-check live completion and auto-complete state
                            -- so stale transition flags cannot drive the row.
                            if qId and qId > 0 and C_QuestLog then
                                local liveCompletion = Quest.GetQuestCompletionState
                                    and Quest.GetQuestCompletionState(qId)

                                -- Never let a stale/transient failure replace
                                -- an already confirmed completion. If the live
                                -- state is now merely active, clear a cached
                                -- failure so the row cannot flash red while
                                -- Blizzard finishes the completion transition.
                                if liveCompletion == 1 then
                                    isComplete = 1
                                elseif isComplete ~= 1 then
                                    isComplete = liveCompletion
                                end
                                if not isAC and GetQuestLogIndexByID then
                                    local logIdx = GetQuestLogIndexByID(qId)
                                    if logIdx and logIdx > 0
                                            and GetQuestLogIsAutoComplete(logIdx) then
                                        isAC = true
                                    end
                                end
                            end
                            local quest = cur.Q
                            local qi = cur.QI
                            local lbNum = cur.LBCnt
--                            local link, item, charges = GetQuestLogSpecialItemInfo (questIndex)
                            list:ItemAdd (qId * 0x10000 + qi)
                            local trackMode = Quest.Tracking[qId] or 0
                            local obj = quest and (quest["End"] or quest["Start"])
                            if qId == 0 then
                                list:ItemSetButton ("QuestWatchErr", false)
                            elseif isComplete or lbNum == 0 then
                                local butType = "QuestWatch"
                                local pressed = false
                                if bit_band (trackMode, 1) > 0 then
                                    pressed = true
                                end
                                if Quest:IsTargeted (qId, 0) then
                                    butType = "QuestWatchTarget"
                                end
                                if obj then
                                    local name, zone = Quest:GetSEPos (obj)
                                    if not zone or not zone then
                                        butType = "QuestWatchErr"
                                    end
                                end
                                if isComplete and isAC then
                                    butType = "QuestWatchAC"
                                    pressed = false
                                end
                                list:ItemSetButton (butType, pressed)
                            elseif not obj then
                                list:ItemSetButton ("QuestWatchErr", false)
                            else
                                list:ItemSetButton ("QuestWatchTip", false)        -- QuestWatchTip  >  QuestWatch?
                            end
                            -- Skip the WatchItem icon when the quest is
                            -- finished, unless Blizzard's API explicitly
                            -- says to keep it visible after completion
                            -- (some hand-in items must stay clickable).
                            local showItem = cur.ItemLink
                                and Nx.qdb.profile.QuestWatch.ItemScale >= 1
                                and (not isComplete or cur.ItemShowOnComplete)
                            if showItem then
                                list:ItemSetFrame ("WatchItem~" .. cur.QI .. "~" .. cur.ItemImg .. "~" .. cur.ItemCharges)
                            end
                            list:ItemSetButtonTip ((cur.ObjText or "?") .. (cur.PartyDesc or ""))
                            local color = isComplete and compColor or incompColor
                            local lvlStr = ""
                            if level > 0 then
                                local colStr = GetCachedDifficultyColorStr(level)
                                lvlStr = format ("%s%2d%s ", colStr, level, cur.TagShort)
                            end
                            local nameStr = format ("%s%s%s", lvlStr, color, cur.Title)
                            if superTrackedQID > 0 and qId == superTrackedQID then
                                -- Yellow chevron marks the super-tracked quest.
                                nameStr = "|cffffd200>|r " .. nameStr
                            end
                            if cur.NewTime and time() < cur.NewTime + 60 then
                                nameStr = format ("|cff00%2x00" ..L["New: "] .."%s", self.FlashColor * 200 + 55, nameStr)
                            end
                            if isComplete then
                                local obj = quest and (quest["End"] or quest["Start"])
                                if lbNum > 0 or not obj then
                                    nameStr = nameStr .. (isComplete == 1 and "|cff80ff80 " ..L["(Complete)"] or "|cfff04040 - " .. FAILED)
                                else
                                    local desc = Quest:UnpackSE (obj)
                                    nameStr = format ("%s |cffffffff(%s)", nameStr, desc)
                                end
                            end
                            if showDist then
                                local d = cur.Distance * 4.575
                                if d < 1000 then
                                    nameStr = format ("%s |cff808080%d " .. L["yds"], nameStr, d)
                                elseif cur.Distance < 99999 then
                                    nameStr = format ("%s |cff808080%.1fK " .. L["yds"], nameStr, d / 1000)
                                end
                            end
                            if cur.PartyCnt then
                                nameStr = format ("%s |cffb0b0f0(+%s)", nameStr, cur.PartyCnt)
                            end
                            if cur.Party then
                                nameStr = nameStr .. " |cffb0b0f0" .. cur.Party
                            end
                            list:ItemSet (2, nameStr)
                            if cur.TimeExpire then    -- Have a timer?
                                list:ItemAdd (0)
                                list:ItemSet (2, format ("  |cfff06060%s %s", TIME_REMAINING, SecondsToTime (cur.TimeExpire - time())))
                            end
                            if isComplete and isAC then
                                list:ItemAdd (0)
                                list:ItemSet (2, format ("|cff%2x0000--- " ..L["Click ? to complete"] .." ---", self.FlashColor * 200 + 55))
                            end
                            if qi > 0 or cur.Party then
                                local desc, done
                                local zone, loc
                                local lnOffset = -1
                                for ln = 1, 31 do
                                    local obj = quest and quest["Objectives"]
                                    if obj then
                                        obj = quest and quest["Objectives"][ln]
                                    end
                                    if not obj and ln > lbNum then
                                        break
                                    end
                                    zone = nil
                                    done = isComplete
                                    if obj then
                                        desc, zone = Nx.Quest:UnpackObjectiveNew (obj[1])
                                    end
                                    if ln <= lbNum then
                                        desc = cur[ln]
                                        done = cur[ln + 300]
                                    end
                                    -- Skip rows where the only desc we have
                                    -- is the "nil" placeholder (POI desc not
                                    -- filled in our DB) AND Blizzard's API
                                    -- didn't supply objective text either —
                                    -- otherwise the watch list would render
                                    -- a literal "nil" line.
                                    local skipRow = (not desc) or desc == ""
                                                    or desc == "nil"
                                                    or desc == "?"
                                    if not skipRow and not (hideDoneObj and done) then
                                        if showPerColor then
                                            if done then
                                                color = Quest.PerColors[9]
                                            else
                                                local s1, _, i, total = strfind (desc, "(%d+)/(%d+)")
                                                if s1 then
--                                                    Nx.prt ("%s %s", i, total)
                                                    i = floor (tonumber (i) / tonumber (total) * 8.99) + 1
                                                else
                                                    i = 1
                                                end
                                                color = Quest.PerColors[i]
                                            end
                                        else
                                            color = done and oCompColor or oIncompColor
                                        end
                                        if Nx.qdb.profile.QuestWatch.OCntFirst then
                                            local s1, s2 = strmatch (desc, "(.+): (.+)")
                                            if s2 then
                                                desc = format ("%s: %s", s2, s1)
                                            end
                                        end
                                        local str = color .. (desc or "?")    --V4
                                        if not done then
                                            local d = cur["OD"..ln]
                                            if d and d < .5 then            -- Not in yards
                                                str = "*" .. str
                                            end
                                        end
                                        list:ItemAdd (qId * 0x10000 + ln * 0x100 + qi)
                                        list:ItemSetOffset (16, lnOffset)
                                        local butType = "QuestWatchErr"
                                        if zone then
                                            if zone then
                                                butType = "QuestWatch"
                                                if Quest:IsTargeted (qId, ln) then
                                                    butType = "QuestWatchTarget"
                                                end
                                            end
                                        end
    --                                    Nx.prt ("watch %s %s %s", qId, zone or "nil", butType or "nil")
                                        if not done and butType then
                                            if bit_band (trackMode, bit_lshift (1, ln)) > 0 then
                                                list:ItemSetButton (butType, true)
                                            else
                                                list:ItemSetButton (butType, nil)
                                            end
                                        end
                                        if fixedSize then
                                            local maxCOpt = Nx.qdb.profile.QuestWatch.OMaxLen + 10
                                            local maxC = maxCOpt
                                            while #str > maxC do
                                                for cn = maxC, 12, -1 do
                                                    if strbyte (str, cn) == 32 then        -- Find last space
                                                        maxC = cn - 1
                                                        break
                                                    end
                                                end
                                                local s = strsub (str, 1, maxC)
                                                list:ItemSet (2, s)
                                                str = color .. strsub (str, maxC + 1)
                                                list:ItemAdd (qId * 0x10000 + ln * 0x100 + qi)
                                                list:ItemSetOffset (16, lnOffset)
                                                maxC = maxCOpt
                                            end
                                        end
                                        list:ItemSet (2, str)
                                        lnOffset = lnOffset - 1
                                    end
                                end
                            end
                            if fixedSize and watchNum >= qopts.NXWVisMax then
                                list:ItemAdd (0)
                                list:ItemSet (2, " ...")
                                break
                            end
                            watchNum = watchNum + 1
                        end
                    end
                end
            end
            end
        end
    end
    if not fixedSize then
        list:FullUpdate()
    else
        if clearlist then
            list:Update()
        end
    end

    -- Grow upwards

    if self.Win:IsSizeMin() then
        self.FirstUpdate = true
        self.Win:SetTitle ("")

    else

        local w, h = list:GetSize()

        if Nx.qdb.profile.QuestWatch.GrowUp and not self.FirstUpdate then

            h = h - oldh
--            Nx.prt ("h dif %s", h)
            self.Win:OffsetPos (0, h)
        end

        if w < 127 then
            self.Win:SetTitle ("")
        else
            -- Prefer the modern C_QuestLog API; its 2nd return is the real
            -- quest count (excludes headers). Fall back to the legacy global
            -- on Classic flavors that lack C_QuestLog.GetNumQuestLogEntries.
            local _, i
            if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
                _, i = C_QuestLog.GetNumQuestLogEntries()
            else
                _, i = GetNumQuestLogEntries()
            end
            -- MAX_QUESTS is the legacy 25-quest cap; retail's log holds more,
            -- so prefer the live API max (works on the 12.0 engine; falls back
            -- to MAX_QUESTS/25 where the API is missing).
            local maxQ = (C_QuestLog and C_QuestLog.GetMaxNumQuests and C_QuestLog.GetMaxNumQuests()) or MAX_QUESTS or 25
            self.Win:SetTitle (format ("          |cff40af40%d/%d", i, maxQ))
        end

        self.FirstUpdate = nil
    end

    return watched
end

-------------------------------------------------------------------------------

function Nx.Quest.Watch:ShowUpdate()
    self.Win.RaidHid = nil
    if Nx.qdb.profile.QuestWatch.HideRaid then
        if IsInRaid() then
            self.Win.Frm:Hide()
            self.Win.RaidHid = true
        else
            self.Win.Frm:Show()
        end
    end
end

-------------------------------------------------------------------------------
-- Called by Window update
-- Self = win
-------------------------------------------------------------------------------

function Nx.Quest.Watch:WinUpdateFade (fade, force)

    if Nx.qdb.profile.QuestWatch.FadeAll or force then

        self.Win:SetTitleColors (1, 1, 1, fade)
        self.List.Frm:SetAlpha (fade)

        self.ButMenu.Frm:SetAlpha (fade)
        self.ButPri.Frm:SetAlpha (fade)
        self.ButShowOnMap.Frm:SetAlpha (fade)
        self.ButATarget.Frm:SetAlpha (fade)
    end
end

-------------------------------------------------------------------------------
-- On list control updates
-------------------------------------------------------------------------------

function Nx.Quest.Watch:OpenQuestContextMenu (data)
    if not data or not self.WatchMenu or not self.WatchMenu.Open then
        return false
    end

    local qId = GetPackedQuestID (data)
    if not qId or qId <= 0 then
        return false
    end

    self.MenuItemData = data
    self.MenuQIndex = bit_band (data, 0xff)
    self.MenuQId = qId
    self.WatchMenu:Open()
    return true
end

function Nx.Quest.Watch:OnListEvent (eventName, val1, val2, click, but)

--    Nx.prt ("QuestListUpdate "..eventName)

    if eventName == "menu" then
        self:OpenQuestContextMenu (self.List:ItemGetData (val1))
        return
    end

    if eventName == "button" then

        local Quest = Nx.Quest
        -- val1 = id
        -- val2 = pressed

        local data = self.List:ItemGetData (val1)
        if data then
            local qIndex = bit_band (data, 0xff)
            local qId = GetPackedQuestID(data)
            local typ = but:GetType()
            if (typ.CustomTip or typ.EmissaryTip) and click ~= "RightButton" then
                local func = self.List:ItemGetFunc(data)
                func(data)
                return
            end
            if click == "LeftButton" then

                -- Drive Blizzard super-track for any left-click on a
                -- quest row button (title OR objective row). Carbonite's
                -- cur.QId can drift away from Blizzard's actual questID
                -- (saved-vars from a previous session, etc.) so look up
                -- the *live* questID via the quest log index before
                -- calling Blizzard's API — passing a stale ID means the
                -- call is silently dropped and the arrow doesn't move.
                -- Also clear any user-waypoint / map-pin super-track
                -- since those out-prioritize quest super-track.
                --
                -- Skip when the button's `AutoComplete` flag is set
                -- (the "?" QuestWatchAC button): that button has its
                -- own action (ShowQuestComplete) handled further down,
                -- and super-tracking on its click swallows the input
                -- into the waypoint-arrow toggle instead of completing
                -- the quest.
                local _wasToggledOff = false
                if qId and qId > 0 and not typ.WatchError and not typ.AutoComplete
                   and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
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
                    if liveQID == qId
                       and C_QuestLog and C_QuestLog.IsOnQuest
                       and not C_QuestLog.IsOnQuest(liveQID) then
                        for i = 1, GetNumQuestLogEntries() do
                            local _, _, _, _, _, _, _, qid = GetQuestLogTitle(i)
                            if i == qIndex and qid and qid > 0 then
                                liveQID = qid
                                break
                            end
                        end
                    end

                    Quest:PatchQuestFromBlizzard(liveQID)

                    -- Combat-defer the secure trio: the tainted
                    -- SUPER_TRACKING_CHANGED chain trips the protected
                    -- SetPassThroughButtons in combat. Out of combat the
                    -- closure runs synchronously, preserving the
                    -- toggle-off detection just below.
                    Nx.SuperTrackSafe(function()
                        if C_SuperTrack.SetSuperTrackedUserWaypoint
                           and C_SuperTrack.IsSuperTrackingUserWaypoint
                           and C_SuperTrack.IsSuperTrackingUserWaypoint() then
                            Nx.SetSuperTrackedUserWaypointSafe(false)
                        end
                        if C_SuperTrack.ClearAllSuperTracked then
                            Nx.ClearAllSuperTrackedSafe()
                        end
                        -- Will trigger our SetSuperTrackedQuestID hook. If that
                        -- hook toggles off (clicking the active quest again), it
                        -- clears ActiveQID + the goto arrow + the blob. We have
                        -- to remember the toggle happened so the rest of this
                        -- handler doesn't immediately re-add tracking via
                        -- Watch:Set (which would put the arrow right back).
                        Nx.SetSuperTrackedQuestIDSafe(liveQID)
                    end)
                    if Quest._stLockoutUntil and GetTime
                       and GetTime() < Quest._stLockoutUntil then
                        _wasToggledOff = true
                    end
                end

                if typ.WatchError then
                    -- WatchError means we couldn't resolve a zone for this
                    -- objective. Try one more synthesis from Blizzard; if
                    -- it patches we re-render and skip the message. If
                    -- the live API isn't available on this flavor (Era /
                    -- TBC) we show the legacy "not in database" toast.
                    if Quest:PatchQuestFromBlizzard(qId) then
                        self:Update()
                    elseif not (C_QuestLog and C_QuestLog.GetQuestObjectives) then
                        Quest:MsgNotInDB ("O")
                    end
                elseif _wasToggledOff then
                    -- The SetSuperTrackedQuestID hook just toggled off this
                    -- quest in response to the click. Don't run the rest of
                    -- the handler — Watch:Set / SetActiveCarboniteQuest
                    -- below would immediately re-add the tracking + goto
                    -- arrow that we just cleared.
                    self:Update()
                else

                    if IsAltKeyDown() then
                        Quest.List:SendQuestInfo (qIndex)

                    else

                        if typ.WatchTip then
                            -- Title-row click. Super-track is driven by
                            -- the top-of-handler block above (with the
                            -- live questID); on Classic without
                            -- C_SuperTrack we drive the active quest via
                            -- Carbonite's own state instead.
                            if not (C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID) then
                                Quest:SetActiveCarboniteQuest(qId, qIndex)
                            else
                                self:Update()
                            end
--[[
                            local i, cur = Quest:FindCur (qId, qIndex)
                            if i then

                                for n = cur.LBCnt, 1, -1 do

                                    data = bit_band (data, 0xffff00ff) + n * 0x100

--                                    Nx.prtVar ("", data)
                                    self:Set (data, val2, not IsShiftKeyDown())
                                end
                            end
--]]
                        else

                            -- Shortcut for the "?" autocomplete button: the
                            -- button type itself is the contract. The render
                            -- pass only stamps QuestWatchAC (with its
                            -- AutoComplete = true marker) when the quest is
                            -- both complete and auto-completable, so trust
                            -- that signal directly instead of re-checking
                            -- cur.CompleteMerge / cur.IsAutoComplete here
                            -- (both of which can be stale or nil-ed out by
                            -- a RecordQuestsLog pass between render and click).
                            if typ.AutoComplete then
                                -- API signature differs between Classic and Retail:
                                --   Classic (MoP / Wrath / etc.): ShowQuestComplete(questLogIndex)
                                --   Retail (11.x):                ShowQuestComplete(questID)
                                -- Carbonite has historically passed the log index
                                -- everywhere, which silently no-ops on retail.
                                --
                                -- Defer the call to next tick via C_Timer.After.
                                -- Calling ShowQuestComplete from this click
                                -- handler runs in a Carbonite-tainted stack;
                                -- the popup processing chain that follows
                                -- (AutoQuestPopupTracker + map data refresh)
                                -- inherits our taint and the popup silently
                                -- no-ops — auto-turnin via RecordQuestsLog
                                -- works because that path fires from a clean
                                -- event-handler context.
                                if ShowQuestComplete then
                                    -- Resolve the LIVE questID via the log
                                    -- index. cur.QId is matched out of
                                    -- Carbonite's bundled DB by title and
                                    -- can pin to a legacy/story ID that no
                                    -- longer matches the player's actual
                                    -- live questID (the debug example was
                                    -- qId=28827 "The Eye of the Storm" /
                                    -- cata "In die Tiefe" — IsOnQuest=false
                                    -- and AddAutoQuestPopUp -> false because
                                    -- 28827 isn't anywhere in the live log).
                                    -- C_QuestLog.GetQuestIDForLogIndex on the
                                    -- log index Carbonite has stored as cur.QI
                                    -- gives Blizzard's real questID; that's
                                    -- what ShowQuestComplete /
                                    -- AddAutoQuestPopUp expect.
                                    local _liveID = qId
                                    if qIndex and qIndex > 0
                                        and C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
                                        local id = C_QuestLog.GetQuestIDForLogIndex(qIndex)
                                        if id and id > 0 then _liveID = id end
                                    end
                                    local _qIndex = qIndex
                                    if Nx.isRetail then
                                        C_Timer.After(0, function()
                                            -- Force the quest into Blizzard's
                                            -- AutoQuestPopUp queue first. The
                                            -- queue is populated on the
                                            -- QUEST_AUTOCOMPLETE event (rising
                                            -- edge of completion) and emptied
                                            -- when the popup is dismissed or
                                            -- the user finishes via a NPC, so
                                            -- a "?" click after that point
                                            -- hits ShowQuestComplete with an
                                            -- empty queue and the call
                                            -- silently no-ops. Re-queueing
                                            -- replicates what the QUEST_-
                                            -- AUTOCOMPLETE handler does in
                                            -- blizzard_questobjectivetracker.
                                            if AddAutoQuestPopUp then
                                                AddAutoQuestPopUp(_liveID, "COMPLETE")
                                            end
                                            ShowQuestComplete(_liveID)
                                        end)
                                    else
                                        local qi = (GetQuestLogIndexByID and GetQuestLogIndexByID(_liveID)) or _qIndex
                                        if qi and qi > 0 then
                                            C_Timer.After(0, function()
                                                ShowQuestComplete(qi)
                                            end)
                                        end
                                    end
                                end
                                return
                            end

                            local i, cur = Quest:FindCur (qId, qIndex)
                            local isComplete = cur and cur.CompleteMerge
                            local isAC = cur and cur.IsAutoComplete
                            -- Both flags can be stale between render and click:
                            --   * IsAutoComplete is nil-ed out if RecordQuestsLog
                            --     ran in the gap.
                            --   * CompleteMerge can lag the server when the
                            --     player just turned the last objective and the
                            --     QuestLog hasn't redrawn yet.
                            -- Fall back to live C_QuestLog state for both so the
                            -- "?" autocomplete button always autocompletes when
                            -- the API agrees, instead of toggling tracking
                            -- (user-reported bug: ? click switches tracking).
                            if cur and C_QuestLog then
                                local apiComplete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(qId)
                                local logIdx = GetQuestLogIndexByID and GetQuestLogIndexByID(qId)
                                local apiAC = logIdx and logIdx > 0
                                    and GetQuestLogIsAutoComplete(logIdx)
                                if apiComplete then isComplete = true end
                                if apiAC       then isAC       = true end
                            end
                            if isComplete and isAC then
                                -- Use fresh log index in case quest log was reshuffled
                                local qi = GetQuestLogIndexByID(qId)
                                ShowQuestComplete (qi > 0 and qi or qIndex)

                            else
                                self:Set (data, val2, not IsShiftKeyDown())

                            end

                        end
                    end
                end

            elseif click == "RightButton" then

                if IsAltKeyDown() then
                    Quest.IgnoreAlt = true
                    ToggleQuestLog()
                    Quest.IgnoreAlt = nil
                    Quest.List.Bar:Select (1)
                    Quest.List:Select (qId, qIndex)

                elseif IsShiftKeyDown() then

                    Quest:LinkChat (qId)

                else
                    self:OpenQuestContextMenu (data)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

function Nx.Quest.Watch:Set (data, on, track)

    local Quest = Nx.Quest

    local qIndex = bit_band (data, 0xff)
    local qId = GetPackedQuestID(data)

    if qId > 0 then

        local i, cur = Quest:FindCur (qId, qIndex)

        -- Synthesize quest data from Blizzard's API before giving up.
        -- RecordQuestsLog already runs the patcher, but the player can
        -- race it (click watch the same frame the quest accepted).
        -- PatchQuestFromBlizzard self-checks for API availability.
        if not (cur and cur.Q) then
            Quest:PatchQuestFromBlizzard(qId)
            i, cur = Quest:FindCur (qId, qIndex)
        end

        if not (cur and cur.Q) then
            if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then
                Quest:MsgNotInDB()
            end
            return
        end

--        Nx.prt ("Q Set %s %s", i, cur and cur.Name or "nil")

        local q = cur.Q
        if not q["Start"] and not q["End"] then
            -- One more shot at a live patch; End coords often come in
            -- on a later QUEST_POI_UPDATE.
            Quest:PatchQuestFromBlizzard(qId)
            q = cur.Q
        end
        -- Some quests (e.g. MoP 32505) only ship Objectives data, no
        -- Start/End. The legacy check bailed on those, so clicking a
        -- specific objective row silently no-op'd. Accept the click
        -- as long as either Start/End OR any Objectives entry is
        -- present — TrackOnMap dispatches on qObj and only needs
        -- Start/End for the title-row (qObj == 0) path.
        if not q["Start"] and not q["End"]
           and not (q["Objectives"] and next(q["Objectives"])) then
            if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then
                Quest:MsgNotInDB()
            end
            return
        end

        self:ClearAutoTarget (true)

        -- 0 is quest name line
        local qObj = bit_band (bit_rshift (data, 8), 0xff)

        local tbits = Quest.Tracking[qId] or 0

        if track then

            Quest.Tracking = {}    -- Kill all
            tbits = 0

            if not Quest:IsTargeted (qId, qObj) then
                on = true    -- Force on if on but not tracked
            end
        end

        if IsControlKeyDown() then
            on = false        -- Force off
        end

        if qObj == 0 then

            if on == false then
                Quest.Tracking[qId] = nil
            else
                Quest.Tracking[qId] = cur.TrackMask        -- Track all
            end
        else

            if on == false then
                Quest.Tracking[qId] = bit_band (tbits, bit.bnot (bit_lshift (1, qObj)))
            else
                Quest.Tracking[qId] = bit.bor (tbits, bit_lshift (1, qObj))
            end
        end

        if track then
            self:ClearCompleted (qId)
        end

        Quest:TrackOnMap (qId, qObj, qIndex > 0, track)

        self:Update()
        Quest.List:Update()

    else
        if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then
            Quest:MsgNotInDB()
        end
    end

end

-------------------------------------------------------------------------------
-- Add quest to watch
-- (CurQ number)
-------------------------------------------------------------------------------

function Nx.Quest.Watch:Add (curi,addnew)

    local Quest = Nx.Quest
    local cur = Quest.CurQ[curi]
    if not cur then
        return
    end

    local qId = cur.QId > 0 and cur.QId or cur.Title
    local qStatus = Nx.Quest:GetQuest (qId)
    if qStatus ~= "W" then
        Nx.Quest:SetQuest (qId, "W")
        Quest:PartyStartSend()
    end

    if type (qId) == "number" and qId > 0 then
        self:SyncBlizzardWatch (qId, cur.QI, true)
    end
end

-- Objective progress may auto-watch an unwatched quest when AddChanged is
-- enabled. A lowercase "c" records an explicit user unwatch and must win over
-- that automation until the user deliberately watches the quest again.
function Nx.Quest.Watch:AddFromObjectiveChange (curi)
    local Quest = Nx.Quest
    local cur = Quest.CurQ and Quest.CurQ[curi]
    if not cur then
        return false
    end

    local qId = cur.QId > 0 and cur.QId or cur.Title
    if Quest:GetQuest (qId) == "c" then
        self.ForceListRefresh = true
        return false
    end

    self:Add (curi)
    return true
end

-------------------------------------------------------------------------------
-- Clear completed quests
-------------------------------------------------------------------------------

function Nx.Quest.Watch:ClearCompleted (qIdMatch)

    local Quest = Nx.Quest

    self:Update()    -- Get list in sync with quests if added or removed

    local list = self.List

    for ln = 1, list:ItemGetNum() do

        local i = list:ItemGetData (ln)
        if i then

            local qIndex = bit_band (i, 0xff)
            local qId = GetPackedQuestID(i)

            if qId > 0 and (not qIdMatch or qIdMatch == qId) then

                local _, cur = Quest:FindCur (qId)
                if cur then

                    local qComplete = cur.CompleteMerge    -- Remember for objectives
                    local qObj = bit_band (bit_rshift (i, 8), 0xff)

--                    Nx.prt ("Data #%d Id %d Obj %d C=%s", qIndex, qId, qObj, tostring (cur.CompleteMerge))

                    local tbits = Quest.Tracking[qId] or 0

                    if tbits > 0 then
                        local objmask = bit_lshift (1, qObj)

                        if qObj == 0 then
                            if qComplete then

                                local qStatus, qTime = Nx.Quest:GetQuest (qId)

                                if qStatus ~= "C" then
--                                    Nx.prt ("track on")
                                    -- Turn on

                                    if Nx.Quest:IsTargeted (qId) then
                                        Quest.Tracking[qId] = bit.bor (tbits, objmask)
                                        Quest:TrackOnMap (qId, 0, qIndex > 0, true)
                                    end
                                end
                            end

                        else
                            local desc
                            local done = qComplete
                            local num = cur.LBCnt

                            if qObj <= num then
                                desc = cur[qObj]
                                done = cur[qObj + 300]
                            end

                            if done then

                                local on = bit_band (tbits, objmask)

                                if on > 0 then
                                    -- Turn off
                                    Quest.Tracking[qId] = bit_band (tbits, bit.bnot (objmask))
                                    Quest:TrackOnMap (qId, qObj, qIndex > 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function Nx.Quest:CreateGiverIconMenu (mainMenu, frm)
    local completedMenu = Nx.Menu:Create (frm)
    self.GiverIconMenuCompleted = completedMenu
    self.GiverIconMenuICompleted = mainMenu:AddSubMenu (completedMenu, L["Quest Completion..."])

    self.GiverIconMenuICompletedT = {}

    for n = 1, 29 do

        local function func (self, item)

            local s = item:GetChecked() and "C" or "c"
            Nx.Quest:SetQuest (item.UData, s, time())

            if item:GetChecked() then
                self:CalcPreviousDone (item.UData)
            end

            self:UpdateGiverIconMenu()
            self.GiverIconMenuCompleted:Update()

            local map = Nx.Map:GetMap (1)
            map.Guide:UpdateMapIcons()
        end

        self.GiverIconMenuICompletedT[n] = completedMenu:AddItem (0, "?", func, self)
        self.GiverIconMenuICompletedT[n]:SetChecked()
    end

    --

    local infoMenu = Nx.Menu:Create (frm)
    self.GiverIconMenuInfo = infoMenu
    self.GiverIconMenuIInfo = mainMenu:AddSubMenu (infoMenu, L["Quest Info (shift click - goto)..."])

    self.GiverIconMenuIInfoT = {}

    for n = 1, 29 do

        local function func (self, item)
--            Nx.prt ("%s", item.Text)

            if not IsShiftKeyDown() then
                local link = self:CreateLink (item.UData, -1, "x")
                SetItemRef (link)
            else

                self:Goto (item.UData)
            end
        end

        self.GiverIconMenuIInfoT[n] = infoMenu:AddItem (0, "?", func, self)
    end
end

function Nx.Quest:OpenGiverIconMenu (icon, typ)
    self.GiverIconMenuICompleted:Show (false)
    self.GiverIconMenuIInfo:Show (false)

    if typ ~= 3000 then
        return
    end

    self.GiverIconMenuCompleted:Show (false)
    self.GiverIconMenuInfo:Show (false)

    if icon.UDataQuestGiverD then
        self.GiverIconMenuICompleted:Show()
        self.GiverIconMenuIInfo:Show()

        self.GiverIconMenuCompletedD = icon.UDataQuestGiverD

        self:UpdateGiverIconMenu()
    end
end

function Nx.Quest:UpdateGiverIconMenu()

    local qdata = self.GiverIconMenuCompletedD

    local qIds = self.QIds
    local curI = 1

    for n = 1, #qdata, 4 do
        local qId = tonumber (strsub (qdata, n, n + 3), 16)

        local quest = Nx.Quests[qId]
        local qname, _, lvl, minlvl = self:Unpack (quest["Quest"])

        local col = ""

        local status, qTime = Nx.Quest:GetQuest (qId)
        if status == "C" then
            col = "|cff808080"
        else
            if qIds[qId] then
                col = "|cffa0f0a0"
            end
        end

        local s = format ("%s%d %s", col, lvl, qname)

--        Nx.prt ("Menu %s", s)

        local menuI = self.GiverIconMenuICompletedT[curI]
        if not menuI then
            break
        end

        menuI:Show()
        menuI:SetText (s)
        menuI.UData = qId
        menuI:SetChecked (status == "C")

        local menuI = self.GiverIconMenuIInfoT[curI]

        menuI:Show()
        menuI:SetText (s)
        menuI.UData = qId

        curI = curI + 1
    end
end
