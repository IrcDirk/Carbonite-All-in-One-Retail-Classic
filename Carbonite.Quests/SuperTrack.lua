-- Carbonite.Quests | SuperTrack
-- Blizzard UI modifications (QuestMapFrame / ObjectiveTracker
-- overrides), watch-colors initialiser, the right-click watch
-- menu builder, the C_SuperTrack mirror (Carbonite\'s ActiveQID
-- source of truth), QUEST_TURNED_IN handling, and FinishQuest
-- (the GetQuestReward post-hook that commits a turn-in to history).

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals.
local floor      = math.floor
local max        = math.max
local abs        = math.abs
local strsub     = strsub  or string.sub
local format     = format  or string.format
local tinsert    = tinsert or table.insert
local GetTime              = GetTime
local UnitLevel            = UnitLevel
local InCombatLockdown     = InCombatLockdown

-- BLIZZARD UI MODIFICATIONS
-- Override Blizzard functions for quest map integration
-------------------------------------------------------------------------------

--[[local oQuestMapFrame_Show = QuestMapFrame_Show
function QuestMapFrame_Show()
    QuestMapFrame:SetFrameLevel(2)
    if UnitAffectingCombat("player") then
        QuestMapFrame_UpdateAll();
        QuestMapFrame:SetFrameLevel(4)
        QuestMapFrame:Show();

        WorldMapFrame.UIElementsFrame.OpenQuestPanelButton:Hide();
        WorldMapFrame.UIElementsFrame.CloseQuestPanelButton:Show();
        return
    end
    oQuestMapFrame_Show()
end

local oQuestMapFrame_Hide = QuestMapFrame_Hide
function QuestMapFrame_Hide()
    if UnitAffectingCombat("player") then
        QuestMapFrame:Hide();
        QuestMapFrame_UpdateAll();

        WorldMapFrame.UIElementsFrame.OpenQuestPanelButton:Show();
        WorldMapFrame.UIElementsFrame.CloseQuestPanelButton:Hide();
        return
    end
    oQuestMapFrame_Hide()
end]]--

function CarboniteQuest.ShowUIPanel(frame)
    if frame then
        if frame == _G["QuestMapFrame"] and Nx.qdb.profile.Quest.Enable then
            Nx.Quest:ShowUIPanel (frame)
        end
    end
end

function CarboniteQuest.HideUIPanel (frame)
    if frame then
        if frame == _G["QuestMapFrame"] and Nx.qdb.profile.Quest.Enable then
            Nx.Quest:HideUIPanel (frame)
        end
    end
end

function Nx.Quest:ProcessQuestDB(questTotal)
    if InCombatLockdown() then
        C_Timer.After(5, function() Nx.Quest:ProcessQuestDB(questTotal) end)
        return
    end
    local maxLoadLevel = Nx.qdb.profile.Quest.maxLoadLevel
    local enFact = Nx.PlFactionNum == 1 and 1 or 2
    local qLoadLevel = max(1, UnitLevel ("player") + Nx.qdb.profile.Quest.LevelsToLoad)
    local qMaxLevel = 999

    for mungeId, q in pairs (Nx.Quests) do
        if mungeId < 0 then
            if Nx.Quests[abs(mungeId)] then
                --Nx.prt(mungeId)
                Nx.Quests[mungeId] = nil
            end
        else
            local name, side, level, minlevel, qnext = self:Unpack (q["Quest"])
            -- Used to `Nx.Quests[mungeId] = nil` here for opposite-
            -- faction / out-of-level-range quests as a memory
            -- optimization. The wipe caused the patch code to later
            -- synthesize a single-point stub over rich bundled data
            -- (e.g. quest 10302's many area-rect objectives) when the
            -- player accepted the quest anyway — and even when fully
            -- filtered, the quest vanished from Carbonite's watch
            -- panel entirely. Keep the data; just skip the chain-
            -- walker / sort-insert work for irrelevant quests.
            if side == enFact or level > 0 and (maxLoadLevel and level > qLoadLevel) or level > qMaxLevel then
                -- skip processing, but preserve the bundled data
            else
                --[[if q["End"] and q["End"] == q["Start"] then
                no enders
                end]]
                self:CheckQuestSE (q, 3)
                for n = 1, 99 do
                    if not q[n] then
                        break
                    end
                    self:CheckQuestObj (q, n)
                end
                -- insert to sorted table (need to do proper sorting)
                tinsert(self.Sorted, mungeId)
                if not q.CNum and qnext and qnext > 0 then
                    local clvlmax = level
                    local qc = q
                    local cnum = 0
                    local _qids = {}
                    while qc do
                        cnum = cnum + 1
                        qc.CNum = cnum
                        local name, side, level, minlevel, qnext = self:Unpack (qc["Quest"])
                        -- Defensive: a malformed Quest field can produce a
                        -- nil level; default to 0 instead of crashing the
                        -- chain walker.
                        clvlmax = max (clvlmax, level or 0)
                        if not qnext or qnext == 0 or _qids[qnext] == true or cnum > 40 then
                            break
                        end
                        _qids[qnext] = true;
                        qc = Nx.Quests[qnext]
                    end
                    q.CLvlMax = clvlmax        -- Max level in chain
                end
            end
        end
    end

    -- Invalidate the bundled-name → bundled-id reverse index so the
    -- next PatchQuestFromBlizzard miss rebuilds it from the now-
    -- complete Nx.Quests (the per-flavor Load1/Load2/... chunks
    -- finish over several C_Timer.After ticks). Used to recover
    -- bundled data when Blizzard renumbered a quest, e.g. TBC 9303
    -- "Inoculation" → retail 37444.
    Nx.QuestsByTitle = nil

--[[
    for lvl = 0, 110 do
        local grp = {}
        for id, q in pairs (Nx.Quests) do
            if id > 0 then
                local name, side, level = self:Unpack (q["Quest"])
                if level == lvl then
                    if side ~= enFact then
                        if not q.CNum then
                            tinsert (grp, format ("%s^%d", name, id))
                        elseif q.CNum == 1 then
                            local qc = q
                            local _qids = {}
                            while qc do
                                local pname, side, _, _, next = self:Unpack (qc["Quest"])
                                if _qids[next] == true then
                                    break
                                end
                                _qids[next] = true;
                                tinsert (grp, format ("%s%2d^%d", name, qc.CNum, id))
                                qc = Nx.Quests[next]
                                id = next
                            end
                        end
                    end
                end
            end
        end
        for _, v in ipairs (grp) do
            local name, id = Nx.Split ("^", v)
            tinsert (self.Sorted, tonumber (id))
        end
    end
    ]]--
    local usedIds = {}
    local starters = {}
    self.QGivers = starters
    for qsIndex, qId in pairs (self.Sorted) do
        if not usedIds[qId] then
            local quest = Nx.Quests[qId]
            if quest then
                local sName, zone, x, y = self:GetSEPos (quest["Start"])
                if zone and x ~= 0 and y ~= 0 then
                    usedIds[qId] = true
                    local sNameO = sName
                    sName = format ("%s=%d%d", sName, x, y)
                    local stmap = starters[zone] or {}
                    starters[zone] = stmap
                    local s = stmap[sName] or ""
                    stmap[sName] = s .. format ("%6x", qId)
                end
            end
        end
    end
    Nx.prt("|cff00ff00[|cffffff00QUEST LOADER|cff00ff00] |cffffffff" .. questTotal .. " Quests Loaded")
    Nx.QInit = true
    --Nx.Quest.List:LogUpdate()
    C_Timer.After(1, function() Nx.Quest:RecordQuests() end)
    --Nx.Quest.Watch:Update()

    -- The DB loads asynchronously across ~11 chained C_Timer ticks, so a
    -- player who opens the quest window (default L) before all chunks
    -- finish sees an empty Database tab — the iteration is over
    -- Quest.Sorted, which is only populated here. Force a refresh on the
    -- already-open window so it picks up the freshly-sorted list without
    -- requiring the player to close and reopen.
    if Nx.Quest.List and Nx.Quest.List.Opened and Nx.Quest.List.Update then
        Nx.Quest.List:Update()
    end
end

function Nx.Quest:LoadQuestDB()
    local questTotal = 0
    local timeDelay = 1
    local numQLoad = 0;
    local maxQLoad = 0;
    local Map = Nx.Map
    self.Map = Map:GetMap (1)
    Nx.Quests = {}
    Nx.prt("|cff00ff00[|cffffff00QUEST LOADER|cff00ff00] |cffffffffStarting Background Quest Data Loading...")
    if Nx.qdb.profile.Quest.Load0 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load0(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear0()
    end
    if Nx.qdb.profile.Quest.Load1 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load1(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear1()
    end
    if Nx.qdb.profile.Quest.Load2 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load2(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear2()
    end
    if Nx.qdb.profile.Quest.Load3 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load3(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear3()
    end
    if Nx.qdb.profile.Quest.Load4 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load4(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear4()
    end
    if Nx.qdb.profile.Quest.Load5 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load5(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear5()
    end
    if Nx.qdb.profile.Quest.Load6 then
        C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load6(); numQLoad = numQLoad - 1; end)
        timeDelay = timeDelay + 1
        numQLoad = numQLoad + 1
        maxQLoad = maxQLoad + 1
    else
        Nx.ModQuests:Clear6()
    end
    if Nx.MaxPlayerLevel > 60 then
        if Nx.qdb.profile.Quest.Load7 then
            C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load7(); numQLoad = numQLoad - 1; end)
            timeDelay = timeDelay + 1
            numQLoad = numQLoad + 1
            maxQLoad = maxQLoad + 1
        else
            Nx.ModQuests:Clear7()
        end
    end
    if Nx.MaxPlayerLevel > 70 then
        if Nx.qdb.profile.Quest.Load8 then
            C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load8(); numQLoad = numQLoad - 1; end)
            timeDelay = timeDelay + 1
            numQLoad = numQLoad + 1
            maxQLoad = maxQLoad + 1
        else
            Nx.ModQuests:Clear8()
        end
    end
    if Nx.isClassic then
        if Nx.MaxPlayerLevel > 80 then
            if Nx.qdb.profile.Quest.Load9 then
                C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load9(); numQLoad = numQLoad - 1; end)
                timeDelay = timeDelay + 1
                numQLoad = numQLoad + 1
                maxQLoad = maxQLoad + 1
            else
                Nx.ModQuests:Clear9()
            end
        end
        if Nx.MaxPlayerLevel > 85 then
            if Nx.qdb.profile.Quest.Load10 then
                C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load10(); numQLoad = numQLoad - 1; end)
                timeDelay = timeDelay + 1
                numQLoad = numQLoad + 1
                maxQLoad = maxQLoad + 1
            else
                Nx.ModQuests:Clear10()
            end
        end
    else
        if Nx.MaxPlayerLevel > 80 then  -- Midnight (level 81-90+ bucket)
            if Nx.qdb.profile.Quest.Load9 then
                C_Timer.After(1, function() questTotal = questTotal + Nx.ModQuests:Load9(); numQLoad = numQLoad - 1; end)
                timeDelay = timeDelay + 1
                numQLoad = numQLoad + 1
                maxQLoad = maxQLoad + 1
            else
                Nx.ModQuests:Clear9()
            end
        end
    end
    C_Timer.After(1, function() Nx.Units2Quests:Load(); end)

    if maxQLoad > 0 then
        local qStep = 100 / maxQLoad
        C_Timer.NewTicker(1, function(self)
            if (Nx.Initialized == true and numQLoad == 0) or self._remainingIterations == 0 then
                self:Cancel()
                Nx.ModQuests = {} -- Destroing unused table to free memory as we never use it again
                C_Timer.After(1, function() Nx.Quest:ProcessQuestDB(questTotal) end)
                return
            end
            --Nx.prt("|cff00ff00[|cffffff00QUEST LOADER|cff00ff00] |cffffffffLoading Quest Data... (%d%%)", ( math.floor(qStep * (maxQLoad - numQLoad)) ))
        end, 120)
    end
end

function Nx.Quest:SetCols()
    Nx.Quest.Cols["compColor"] = Nx.Util_str2colstr (Nx.qdb.profile.QuestWatch.CompleteColor)
    Nx.Quest.Cols["incompColor"] = Nx.Util_str2colstr (Nx.qdb.profile.QuestWatch.IncompleteColor)
    Nx.Quest.Cols["oCompColor"] = Nx.Util_str2colstr (Nx.qdb.profile.QuestWatch.OCompleteColor)
    Nx.Quest.Cols["oIncompColor"] = Nx.Util_str2colstr (Nx.qdb.profile.QuestWatch.OIncompleteColor)
    do
        local r, g, b, a = Nx.Util_str2rgba (Nx.qdb.profile.QuestWatch.BGColor)
        Nx.Quest.Cols["BGColorR"] = tonumber(r) or 0
        Nx.Quest.Cols["BGColorG"] = tonumber(g) or 0
        Nx.Quest.Cols["BGColorB"] = tonumber(b) or 0
        Nx.Quest.Cols["BGColorA"] = tonumber(a) or .4

        r, g, b, a = Nx.Util_str2rgba (Nx.qdb.profile.Quest.MapWatchAreaTrackColor)
        Nx.Quest.Cols["trkR"] = tonumber(r) or 1
        Nx.Quest.Cols["trkG"] = tonumber(g) or 1
        Nx.Quest.Cols["trkB"] = tonumber(b) or 1
        Nx.Quest.Cols["trkA"] = tonumber(a) or 1

        r, g, b, a = Nx.Util_str2rgba (Nx.qdb.profile.Quest.MapWatchAreaHoverColor)
        Nx.Quest.Cols["hovR"] = tonumber(r) or 1
        Nx.Quest.Cols["hovG"] = tonumber(g) or 1
        Nx.Quest.Cols["hovB"] = tonumber(b) or 1
        Nx.Quest.Cols["hovA"] = tonumber(a) or 1
    end
end

function Nx.Quest:CheckQuestSE (q, n)

    local _, zone, x, y = self:GetSEPos (q[n])
    local mapId = zone

    if (x == 0 or y == 0) and mapId and not Nx.Map:IsInstanceMap (mapId) then
        q[n] = format ("%s# ####", strsub (q[n], 1, 2))    -- Zero it to get a red button
--        local oName = self:UnpackSE (q[n])
--        Nx.prt ("zeroed %s, %s", self:UnpackName (q[1]), oName)
    end
end

function Nx.Quest:CheckQuestObj (q, n)

    local oName, zone, x, y = self:GetObjectivePos (q[n])
    local mapId = zone

    if (x == 0 or y == 0) and mapId and not Nx.Map:IsInstanceMap (mapId) then
        q[n] = format ("%c%s# ####", #oName + 35, oName)    -- Zero it to get a red button
--        Nx.prt ("zeroed %s, %s", self:UnpackName (q[1]), oName)
    end
end

-------------------------------------------------------------------------------
-- Calculate the watch colors
-------------------------------------------------------------------------------

function Nx.Quest:CalcWatchColors()

--    Nx.QLocColors = { 1,0,0, "QuestWatchR", 0,1,0, "QuestWatchG", .2,.2,1, "QuestWatchB" }

    local opts = self.GOpts

    local colors = {}
    self.QLocColors = colors

    local a = Nx.Util_str2a (Nx.qdb.profile.Quest.MapWatchAreaAlpha)

    local colMax = Nx.qdb.profile.Quest.MapWatchColorCnt
    local colI = 1

    for n = 1, 15 do

        local color = {}
        colors[n] = color

        local r, g, b = Nx.Util_str2rgba (Nx.qdb.profile.Quest["MapWatchC" .. colI])
        color[1] = r
        color[2] = g
        color[3] = b
        color[4] = a
        color[5] = "QuestListWatch"

        colI = colI + 1
        colI = colI > colMax and 1 or colI
    end
end

-------------------------------------------------------------------------------
-- Menu
-------------------------------------------------------------------------------

function Nx.Quest:Menu_OnTrack()

    local cur = self.IconMenuCur
    local v = cur.QId * 0x10000 + self.IconMenuObjI * 0x100 + cur.QI

--    Nx.prt ("Track %x (%d)", v, self.IconMenuObjI)

    self.Watch:Set (v, true, true)

--    self.IconMenuCur
--    self.IconMenuObjI
end

function Nx.Quest:Menu_OnShowQuest()

    ToggleQuestLog()
    --ShowUIPanel (QuestMapFrame)

    self.List.Bar:Select (1)

    local cur = self.IconMenuCur
    self.List:Select (cur.QId, cur.QI)
end

function Nx.Quest:Menu_OnWatch (item)

    local cur = self.IconMenuCur
    self.List:ToggleWatch (cur.QId, cur.QI, 0)
end

-------------------------------------------------------------------------------
-- Track quest acception
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Sync Carbonite's tracked quest with Blizzard's super-track.
--
-- Blizzard's super-track is the "active quest" — the one the on-screen arrow
-- and POI highlights point at. The user sets it by clicking a quest POI on
-- the map (or a row in the objective tracker). When this fires we mirror it
-- as Carbonite's tracked quest so the map blob and Carbonite arrow follow
-- the same quest the rest of the UI is showing.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ActiveQID: Carbonite's single source of truth for "the active quest".
--
-- On retail / Wrath+ Classic this mirrors C_SuperTrack.GetSuperTrackedQuestID
-- (set in OnSuperTrackChanged). On older flavors that lack the API the
-- click handlers set it directly so the icon highlight + blob behavior
-- still works. UpdateIcons consumes it to paint the active POI gold.
-------------------------------------------------------------------------------

Nx.Quest.ActiveQID = 0

function Nx.Quest:SetActiveCarboniteQuest(qId, qIndex)
    -- Suppress the AddQuestWatch hook for the duration of this call.
    -- TrackOnMap below calls AddQuestWatch(BlizIndex) when QuestWatch.Sync
    -- is enabled, which would otherwise re-fire our hook and recursively
    -- toggle the quest off in the same click.
    local prevSuppress = self._addWatchSuppress
    self._addWatchSuppress = true

    if not qId or qId <= 0 then
        self.ActiveQID = 0
        self.Tracking = {}
        self._addWatchSuppress = prevSuppress
        return
    end

    local cur = self.QIds and self.QIds[qId]
    if not cur and qIndex and qIndex > 0 then
        cur = self:FindCurByIndex(qIndex)
    end

    -- Click again on the same active quest = clear it.
    if self.ActiveQID == qId then
        self.ActiveQID = 0
        self.Tracking = {}
        if not InCombatLockdown() then
            local Map = Nx.Map
            local mapId = Map:GetCurrentMapId()
            self:TrackOnMap(qId, 0, false, true)
            Map:SetCurrentMap(mapId)
        end
        if self.Watch and self.Watch.Update then
            self.Watch:Update()
        end
        self._addWatchSuppress = prevSuppress
        return
    end

    local mask = cur and cur.TrackMask
    if not mask or mask == 0 then mask = 0xffffffff end

    self.ActiveQID = qId
    self.Tracking = {}
    self.Tracking[qId] = mask

    -- Pick the first incomplete objective for arrow targeting instead of
    -- routing as title-row (qObj=0). Title-row falls back to the static
    -- End coord on classic flavors (no GetNextWaypoint), which means the
    -- arrow always points at the turn-in NPC even when the player is
    -- mid-quest. Mirror the picked objective into ActiveObjI so the
    -- (qId, objI) toggle logic in the click handlers can match it.
    --
    -- Complete-quest short-circuit: keep pickedObj at 0 so the title-
    -- row path drives the arrow to the turn-in NPC. The objective
    -- walker below misbehaves on delivery / collect-from-one-of-N
    -- quests where bundled Objectives[] holds N alternative pickup
    -- locations but Blizzard reports < N leaderboards: the trailing
    -- cur[n+300] flags are nil (no leaderboard at that index), the
    -- "not done" branch fires for them, and the arrow snaps to the
    -- highest-indexed alternate spot instead of the ender. Quest
    -- 9663 "The Kessel Run" hit this — three pickup waypoints, only
    -- one Blizzard leaderboard, last-index alternate got picked.
    local pickedObj = 0
    if cur and not cur.Complete and cur.Q and cur.Q["Objectives"] then
        for n = 1, 15 do
            local obj = cur.Q["Objectives"][n]
            if not obj then break end
            local done = cur[n + 300]
            if not done then
                local first = type(obj) == "table" and obj[1] or obj
                local _, zone = self:UnpackObjectiveNew(first)
                if zone then
                    pickedObj = n
                    break
                end
            end
        end
    end
    self.ActiveObjI = pickedObj

    if not InCombatLockdown() then
        local Map = Nx.Map
        local mapId = Map:GetCurrentMapId()
        self:TrackOnMap(qId, pickedObj, qIndex and qIndex > 0, true)
        Map:SetCurrentMap(mapId)
    end
    if self.Watch and self.Watch.Update then
        self.Watch:Update()
    end
    self._addWatchSuppress = prevSuppress
end

function Nx.Quest:OnSuperTrackChanged()
    if not C_SuperTrack then
        return
    end

    local liveQID = C_SuperTrack.GetSuperTrackedQuestID()
    if not liveQID or liveQID == 0 then
        -- Blizzard sometimes drops the super-track value to 0 during
        -- objective-completion transitions on chained quests. If we
        -- have a remembered ActiveQID and that quest is still in the
        -- player's log, restore it so the Blizzard arrow / tracker
        -- stays pointing at the right quest.
        --
        -- Skip the restore when the user *intentionally* cleared via the
        -- icon-click toggle (UserClearedActive flag set by the click
        -- handler). Without this guard the toggle-off click flips back
        -- to the previous quest immediately.
        --
        -- In both "we're not going to restore" branches the Blizzard quest
        -- area blob (drawn into WorldMapBlobFrame / QMap.QuestWin) doesn't
        -- auto-hide on super-track clear, so explicitly hide it here. Skips
        -- in combat lockdown — the secure frame would refuse the call.
        local function clearBlob()
            if InCombatLockdown() then return end
            local f = NxMap1 and NxMap1.NxMap
            if f and f.QuestWin then
                if f.QuestWin.DrawNone then f.QuestWin:DrawNone() end
                if f.QuestWin.Hide then f.QuestWin:Hide() end
            end
        end
        if self.UserClearedActive then
            self.UserClearedActive = nil
            self.ActiveQID = 0
            self.ActiveObjI = 0
            clearBlob()
            return
        end
        local prev = self.ActiveQID
        if prev and prev > 0
           and C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(prev)
           and C_SuperTrack.SetSuperTrackedQuestID then
            -- Combat-defer the restore: this listener runs off
            -- SUPER_TRACKING_CHANGED, which Blizzard fires mid-combat
            -- (auto-track on quest complete etc.); re-entering the
            -- secure API from our taint trips the combat-protected
            -- SetPassThroughButtons in the QuestDataProvider chain.
            Nx.SuperTrackSafe(function()
                Nx.SetSuperTrackedQuestIDSafe(prev)
            end)
            return
        end
        self.ActiveQID = 0
        self.ActiveObjI = 0
        clearBlob()
        return
    end
    self.ActiveQID = liveQID

    -- Skip world quests; their click path already calls SetSuperTrackedQuestID
    -- and they don't live in CurQ anyway.
    if QuestUtils_IsQuestWorldQuest and QuestUtils_IsQuestWorldQuest(liveQID) then
        if self.Watch and self.Watch.Update then
            self.Watch:Update()
        end
        return
    end

    -- Find cur. FindCur matches by cur.QId, which can drift away from
    -- the live questID (saved-vars / cross-session). When that happens
    -- walk CurQ resolving each cur's log index to the live questID.
    local i, cur = self:FindCur(liveQID, 0)
    if not cur then
        for n, c in ipairs(self.CurQ) do
            if c.QI and c.QI > 0
               and C_QuestLog and C_QuestLog.GetQuestIDForLogIndex
               and C_QuestLog.GetQuestIDForLogIndex(c.QI) == liveQID then
                i, cur = n, c
                break
            end
        end
    end
    if not cur then
        return
    end

    -- Self-heal stale cur.QId so downstream code (icon draw, watch
    -- list, blob render) sees the live ID.
    if cur.QId ~= liveQID then
        if Nx._dbgQId then
            Nx.prt("|cffff8000[QId-DBG]|r SuperTrack:heal cur#%s QI=%s QId %s->%s Title=%q",
                tostring(cur.Index), tostring(cur.QI), tostring(cur.QId), tostring(liveQID), tostring(cur.Title or "?"))
        end
        cur.QId = liveQID
        if Nx.Quest.QIds then
            Nx.Quest.QIds[liveQID] = cur
        end
        if Nx.Quest.IdToCurQ then
            Nx.Quest.IdToCurQ[liveQID] = cur
        end
    end

    -- Mark this quest as the only Carbonite-tracked one and redraw map.
    -- TrackMask can be 0 for quests whose bundled objective data is
    -- missing (Lua: 0 is truthy, so `or` won't substitute); fall back
    -- to a mask that draws everything so the click is never invisible.
    -- TrackOnMap uses this qId as the key for DrawBlob — must be the
    -- live questID or the WorldMapBlobFrame won't have data for it.
    local mask = cur.TrackMask
    if not mask or mask == 0 then mask = 0xffffffff end
    self.Tracking = {}
    self.Tracking[liveQID] = mask

    -- Pick a per-objective target instead of qObj=0. Title-row routing
    -- relies on Blizzard's GetNextWaypoint / GetQuestsOnMap to advance
    -- the arrow to the current objective; on classic flavors (and
    -- legacy retail quests) those return nothing, so qObj=0 falls back
    -- to the static End coord — the arrow always points at the turn-in
    -- NPC regardless of which POI the user clicked. Walk our objective
    -- data and pick the first incomplete objective with a coord; that
    -- way the arrow follows the actual work, not the ender.
    local quest = cur.Q
    local pickedObj = 0
    if quest and quest["Objectives"] then
        for n = 1, 15 do
            local obj = quest["Objectives"][n]
            if not obj then break end
            local done = cur[n + 300]
            if not done then
                local first = type(obj) == "table" and obj[1] or obj
                local _, zone = self:UnpackObjectiveNew(first)
                if zone then
                    pickedObj = n
                    break
                end
            end
        end
    end
    if not InCombatLockdown() then
        self:TrackOnMap(liveQID, pickedObj, true, true)
    end
    -- Mirror the picked objective into ActiveObjI so the (qId, objI) toggle
    -- check in the click handlers can see it. Without this, super-track
    -- changes that originate outside Carbonite (Blizzard's world-map pin
    -- click eating our IconOnMouseDown, the objective tracker title click,
    -- macros calling SetSuperTrackedQuestID, etc.) leave ActiveObjI at its
    -- previous value, so a follow-up click on the same icon never sees a
    -- match and can't toggle off.
    self.ActiveObjI = pickedObj
    if self.Watch and self.Watch.Update then
        self.Watch:Update()
    end
end

-- FinishQuest runs from the GetQuestReward post-hook. By the time we get
-- there Blizzard has already triggered QUEST_FINISHED and the QuestFrame
-- may be hidden, so GetTitleText()/GetQuestID() can return empty/nil.
-- We snapshot the values in OnQuestUpdate when QUEST_COMPLETE fires
-- (reward UI still visible) and prefer that snapshot here.

function Nx.Quest:FinishQuest()

    local snap = self._completeSnapshot
    self._completeSnapshot = nil

    local finTitle, finQID
    if snap and (GetTime() - (snap.time or 0)) < 30 then
        finTitle = snap.title
        finQID   = snap.questID
    end
    if not finTitle or finTitle == "" then
        finTitle = GetTitleText()
    end
    if (not finQID or finQID <= 0) and GetQuestID then
        finQID = GetQuestID()
    end

    finTitle = self:ExtractTitle (finTitle or "")

    local i, cur
    if finQID and finQID > 0 then
        i, cur = self:FindCur (finQID, 0)
    end
    if not i and finTitle and finTitle ~= "" then
        i, cur = self:FindCur (finTitle)
    end

    if not i or not cur then
        return
    end

    cur.QI = 0        -- 0 so we dont get a final party message

    local qId = cur.QId

    -- Earlier code had assert(type(qId) ~= "string") here; that aborted
    -- the wrapper before Blizzard's GetQuestReward could run, leaving the
    -- player unable to turn in. Soft-fail instead.
    if type (qId) == "string" then
        Nx.prtD ("FinishQuest: cur.QId is string for '%s'", tostring (finTitle))
        return
    end

    local id = qId and qId > 0 and qId or cur.Title

    if Nx.isClassicEra then
        -- Classic Era never fires QUEST_TURNED_IN, so we have to
        -- commit the history record from the GetQuestReward hook.
        Nx.Quest:SetQuest (id, "C", time())
    else
        -- Defer the "C" history write until QUEST_TURNED_IN confirms
        -- the server actually accepted the turn-in. GetQuestReward
        -- firing only means the client SENT the turn-in attempt; the
        -- server can still reject it (e.g. inventory full when
        -- completing an auto-complete quest). If we wrote "C" here
        -- and the server rejected, the quest stayed in the log but
        -- got filtered out of the watch list (UpdateList drops
        -- anything whose qStatus isn't "W"), so the "?" autocomplete
        -- button vanished and the player couldn't retry.
        Nx.Quest._pendingTurnIn = {
            id    = id,
            qId   = qId,
            title = cur.Title,
            t     = GetTime(),
        }
    end

    self:RecordQuestAcceptOrFinish()
    self:Capture (i, -1)

    if cur.Q and qId then

        self.Tracking[qId] = 0
        self:TrackOnMap (qId, 0)
    end

    self.Watch:Update()
    self.WQList:Update()
end
