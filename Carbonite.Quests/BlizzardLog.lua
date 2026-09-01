-- Carbonite.Quests | BlizzardLog
-- Blizzard quest-log integration. Selecting / expanding / recording
-- quests from the live API; the QUEST_POI map callback; "set done"
-- write-through; the login fetch; sort; and the Scan dispatcher.
-- The legacy main quest-log → Carbonite refresh path used to be a
-- chunk in the middle of NxQuest.lua; this file owns it now.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals.
local bit_band   = bit.band
local bit_lshift = bit.lshift
local strfind    = strfind  or string.find
local strsub     = strsub   or string.sub
local format     = format   or string.format
local gsub       = gsub     or string.gsub
local tinsert    = tinsert  or table.insert
local sort       = sort     or table.sort
local GetTime              = GetTime
local InCombatLockdown     = InCombatLockdown
local GetQuestLogLeaderBoard      = GetQuestLogLeaderBoard
local GetNumQuestLeaderBoards     = GetNumQuestLeaderBoards
local GetQuestLogQuestText        = GetQuestLogQuestText
local GetQuestLogTimeLeft         = GetQuestLogTimeLeft
local GetQuestLogSpecialItemInfo  = GetQuestLogSpecialItemInfo
local GetQuestObjectiveInfo       = GetQuestObjectiveInfo

-- Promoted from NxQuest.lua.
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

-- QUEST_ACCEPTED can arrive while Blizzard is still re-indexing the quest
-- log. Keep the previous watched set authoritative for a short, bounded
-- window so a transient scan cannot publish a collection that silently drops
-- an older watched quest.
local ACCEPT_REFRESH_GUARD_SECONDS = 5
local ACCEPT_REFRESH_GUARD_ATTEMPTS = 10

-------------------------------------------------------------------------------
-- Quest-log snapshot validation
-------------------------------------------------------------------------------

function Nx.Quest:BeginAcceptedQuestRefresh (questId)
    local guard = self.AcceptRefreshGuard
    if not guard then
        guard = {
            AcceptedQuestIds = {},
            WatchedQuestIds = {},
            Attempts = 0,
        }
        self.AcceptRefreshGuard = guard
    end

    local now = GetTime()
    guard.Expires = now + ACCEPT_REFRESH_GUARD_SECONDS
    guard.Attempts = 0

    local removed = self.RecentlyRemovedQuestIds
    if removed then
        for removedQuestId, expires in pairs (removed) do
            if expires <= now then
                removed[removedQuestId] = nil
            end
        end
    end

    for _, cur in ipairs (self.CurQ or {}) do
        local qId = cur.QId
        if cur.QI and cur.QI > 0 and not cur.Party
                and qId and qId > 0
                and (not removed or not removed[qId] or removed[qId] <= now)
                and self:GetQuest (qId) == "W" then
            guard.WatchedQuestIds[qId] = true
        end
    end

    if questId and questId > 0 then
        guard.AcceptedQuestIds[questId] = true
    end
end

function Nx.Quest:NoteQuestLogRemoval (questId)
    if not questId or questId <= 0 then
        return
    end

    local removed = self.RecentlyRemovedQuestIds
    if not removed then
        removed = {}
        self.RecentlyRemovedQuestIds = removed
    end
    removed[questId] = GetTime() + ACCEPT_REFRESH_GUARD_SECONDS

    local guard = self.AcceptRefreshGuard
    if guard then
        guard.WatchedQuestIds[questId] = nil
        guard.AcceptedQuestIds[questId] = nil
    end
end

function Nx.Quest:GetValidatedQuestLogCount()
    local qcnt = GetNumQuestLogEntries()
    if type (qcnt) ~= "number" or qcnt < 0 then
        return
    end

    local seenQuestIds = {}
    for qn = 1, qcnt do
        local title, level, _, isHeader, _, _, _, questId = GetQuestLogTitle (qn)
        if title == nil or type (level) ~= "number" or level < 0 then
            return
        end

        if not isHeader then
            if type (questId) ~= "number" or questId <= 0 or seenQuestIds[questId] then
                return
            end
            seenQuestIds[questId] = true
        end
    end

    local guard = self.AcceptRefreshGuard
    if not guard then
        return qcnt
    end

    local now = GetTime()
    local removed = self.RecentlyRemovedQuestIds
    local missingQuestId

    for questId in pairs (guard.AcceptedQuestIds) do
        local removalExpires = removed and removed[questId]
        local completed = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
            and C_QuestLog.IsQuestFlaggedCompleted (questId)

        if not seenQuestIds[questId] and not completed
                and not (removalExpires and removalExpires > now) then
            missingQuestId = questId
            break
        end
    end

    for questId in pairs (guard.WatchedQuestIds) do
        if missingQuestId then
            break
        end

        local removalExpires = removed and removed[questId]
        local completed = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
            and C_QuestLog.IsQuestFlaggedCompleted (questId)

        if seenQuestIds[questId] or completed or (removalExpires and removalExpires > now) then
            if completed or (removalExpires and removalExpires > now) then
                guard.WatchedQuestIds[questId] = nil
            end
        else
            missingQuestId = questId
            break
        end
    end

    if missingQuestId then
        guard.Attempts = guard.Attempts + 1
        if guard.Attempts <= ACCEPT_REFRESH_GUARD_ATTEMPTS and now < guard.Expires then
            Nx.prtD ("Quest log snapshot deferred; watched quest %s is temporarily missing", missingQuestId)
            return
        end

        -- Bound recovery attempts. A matching QUEST_REMOVED / QUEST_TURNED_IN
        -- normally releases the guard; this fallback prevents a malformed
        -- third-party event sequence from blocking all future quest updates.
        Nx.prtD ("Quest log snapshot guard expired for watched quest %s", missingQuestId)
    end

    self.AcceptRefreshGuard = nil
    return qcnt
end

-------------------------------------------------------------------------------
-- Do Blizzard select quest
-------------------------------------------------------------------------------

function Nx.Quest:SelectBlizz (qi)
    if qi > 0 then
        SelectQuestLogEntry (qi)
    end
end

-------------------------------------------------------------------------------
-- Expand any collapsed quests
-------------------------------------------------------------------------------

function Nx.Quest:ExpandQuests()

--    if next (self.HeaderExpanded) then    -- Currently expanded?
--        Nx.prt ("ExpandQuests skip")
--        return
--    end

--    Nx.prt ("ExpandQuests")

    repeat
        local found = false
        local cnt = GetNumQuestLogEntries()

        for qn = 1, cnt do

            local title, level, groupCnt, isHeader, isCollapsed, _, _, questID = GetQuestLogTitle (qn)
            local questTagInfo = GetQuestTagInfoCompat(questID)
            local tagID = questTagInfo and questTagInfo.tagID
            local tag = questTagInfo and questTagInfo.tagName
            if isHeader and isCollapsed then
                local he = self.HeaderExpanded
                he[title] = true
                ExpandQuestHeader (qn)
--                Nx.prt ("Expand #%s %s %s", qn, title, isCollapsed or "nil")
                found = true
                break
            end
        end
    until not found
end

-------------------------------------------------------------------------------
-- Expand any collapsed quests
-------------------------------------------------------------------------------

function Nx.Quest:RestoreExpandQuests()

--[[

    if self.List.Win:IsShown() then        -- Don't restore if our window is shown
--        Nx.prt ("RestoreExpandQuests skip")
        return
    end

--    Nx.prt ("RestoreExpandQuests")

    for hName in pairs (self.HeaderExpanded) do

--        Nx.prt ("Collapse %s", hName)

        local cnt = GetNumQuestLogEntries()
        for qn = 1, cnt do

            local title, level, groupCnt, isHeader, isCollapsed = GetQuestLogTitle (qn)
            if isHeader and title == hName then
                CollapseQuestHeader (qn)
--                Nx.prt ("Collapse #%s %s %s", qn, title, isCollapsed or "nil")
                break
            end
        end

        self.HeaderExpanded[hName] = nil
    end

--]]

end

-------------------------------------------------------------------------------
-- Access all quests. Forces game to fetch data, so we do not get ": x/x" objectives
-------------------------------------------------------------------------------

function Nx.Quest:AccessAllQuests()

--    Nx.prt ("AccessAllQuests")

    self:ExpandQuests()

    local qcnt = GetNumQuestLogEntries()

    for qi = 1, qcnt do

        local title, level = GetQuestLogTitle (qi)

        local lbCnt = GetNumQuestLeaderBoards (qi)
        for n = 1, lbCnt do
            GetQuestLogLeaderBoard (n, qi)
        end
    end

    self:RestoreExpandQuests()
end

-------------------------------------------------------------------------------
-- Record quests
-- Example:
--  1 Get Attack << Fake quest (no blizz Num)
--  2 Bring
--  3 Capture
-------------------------------------------------------------------------------

function Nx.Quest:RecordQuests(worldcheck)
--    Nx.prt ("Record Quests")
    local self = Nx.Quest
    local qcnt = self:GetValidatedQuestLogCount()
    if not qcnt then
        return false
    end
--    local tm = GetTime()
    self:ScanBlizzQuestDataZone()            -- Capture current zone
    if worldcheck == nil then
        self:ScanBlizzQuestData()                -- Triggers RecordQuestsLog() after done
    end
    return self:RecordQuestsLog (qcnt)

--    Nx.prt ("%f secs", GetTime() - tm)
end

-------------------------------------------------------------------------------

function Nx.Quest:RecordQuestsLog (validatedQuestCount)

    local qcnt = validatedQuestCount or self:GetValidatedQuestLogCount()
    if not qcnt then
        return false
    end

    local opts = self.GOpts
    local previousCurq = self.CurQ
    if not previousCurq then return false end
    local curq = previousCurq
    local oldSel = GetQuestLogSelection()

--    Nx.prt ("RecordQuestsLog %s, %s", qcnt, #curq)

    local lastChanged

    local qIds = {}

    --

    local partySend

    if self.RealQEntries == qcnt then    -- No quests added or removed?

        for curi, cur in ipairs (curq) do

            local qi = cur.QI
            if qi > 0 then

                local title, level, groupCnt, isHeader, isCollapsed, isComplete, _, questID = GetQuestLogTitle (qi)
                title = self:ExtractTitle (title)

--                Nx.prt ("QD %s %s %s %s", title, qi, isHeader and "H1" or "H0", isComplete and "C1" or "C0")

                if cur.Title == title then        -- Still matches?

                    local change

                    if isComplete == 1 and not cur.Complete then
                        Nx.prt (L["Quest Complete '%s'"], title)

                        if Nx.qdb.profile.Quest.SndPlayCompleted then
                            self:PlaySound()
                        end

                        if Nx.qdb.profile.Quest.AutoTurnInAC and cur.IsAutoComplete then
                            -- ShowQuestComplete on retail takes questID, on
                            -- Classic it takes the log index.
                            if Nx.isRetail then
                                ShowQuestComplete (cur.QId)
                            else
                                ShowQuestComplete (qi)
                            end
                        end

                        if Nx.qdb.profile.QuestWatch.RemoveComplete and not cur.IsAutoComplete then
                            self.Watch:RemoveWatch (cur.QId, cur.QI)
                            self.Watch:Update()
                            self.WQList:Update()
                            change = false
                        else
                            change = true
                        end

                    end

                    -- Sync cur.Complete in the fast path. The block
                    -- above only fires the "Quest Complete" toast on
                    -- the rising edge; it doesn't write back. Without
                    -- this assignment, cur.Complete stays at whatever
                    -- it was at the last full rebuild — so a quest
                    -- that completes (or un-completes via Abandon /
                    -- partial-progress edge cases) mid-session leaves
                    -- cur.Complete out of sync. Downstream effects:
                    -- CalcAutoTrack's `if cur.Complete` branch never
                    -- fires for the newly-complete quest, the
                    -- CalcDistances loop keeps computing objective
                    -- distances (instead of stopping at qObj=0), and
                    -- the goto arrow lands on cur.CloseObjI (the
                    -- closest leftover objective POI) instead of the
                    -- End / turn-in NPC. Quest 9663 "The Kessel Run"
                    -- surfaced this: arrow snapped to the last
                    -- objective POI after the third warn instead of
                    -- back to the ender.
                    cur.Complete = isComplete

                    local lbCnt = GetNumQuestLeaderBoards (qi)
                    for n = 1, lbCnt do

                        local desc, _, done = GetQuestLogLeaderBoard (n, qi)

                        --V4

                        if desc and (desc ~= cur[n] or done ~= cur[n + 100]) then

--                            Nx.prt ("Q Change %s->%s", desc, cur[n] or "nil")

                            if Nx.qdb.profile.QuestWatch.AddChanged then
                                if change == nil then
                                    change = true
                                end
                            end

                            local s1, _, oldCnt = strfind (cur[n] or "", "(%d+)/%d+ ")
                            if s1 then
                                oldCnt = tonumber (oldCnt)
                            end

                            local s1, _, newCnt = strfind (desc, "(%d+)/%d+ ")
                            if s1 then
--                                Nx.prt ("%s %s", i, total)
                                newCnt = tonumber (newCnt)
                            end

                            if done or (oldCnt and newCnt and newCnt > oldCnt) then
                                self:Capture (curi, n)
                            end

                            lastChanged = cur

                            partySend = true
                        end

                        -- Persist the live leaderboard text + done flag
                        -- onto cur. The change-check above only used
                        -- these values to decide whether to fire the
                        -- watch refresh; the actual sync to cur[n] /
                        -- cur[n+100] used to wait for the next full
                        -- rebuild. That left stale "0/3" descriptions
                        -- and stale `done` flags driving CalcDistances
                        -- / picker logic until the quest count itself
                        -- changed (accept / abandon / turn-in).
                        if desc then
                            cur[n] = desc
                            cur[n + 100] = done
                        end
                    end

                    if change and Nx.qdb.profile.QuestWatch.AddChanged then
                        self.Watch:AddFromObjectiveChange (curi)
                    end
                end
            end
        end

    else

        partySend = true
    end

    -- Build the replacement collection away from self.CurQ. A quest-log event
    -- can therefore never expose a half-cleared list to the watch window.

    local fakeq = {}
    curq = {}
    for _, cur in ipairs (previousCurq) do
        if cur.Goto and not cur.Party then
            tinsert (curq, cur)
            fakeq[cur.Q] = cur
        end
    end

    -- Add blizz quests

    local realQ = {}

    local header = "?"

    local index = #curq + 1

    for qn = 1, qcnt do
        local title, level, groupCnt, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden = GetQuestLogTitle(qn)
        local questTagInfo = GetQuestTagInfoCompat(questID)
        local tagID = questTagInfo and questTagInfo.tagID
        local tag = questTagInfo and questTagInfo.tagName
        local worldQuestType = questTagInfo and questTagInfo.worldQuestType
        local rarity = questTagInfo and questTagInfo.quality
        local isElite = questTagInfo and questTagInfo.isElite
        local tradeskillLineIndex = questTagInfo and questTagInfo.tradeskillLineID

        groupCnt = tonumber(groupCnt)

        local isDaily = frequency
--        Nx.prt ("Q %d %s %s %d %s %s %s %s", qn, isHeader and "H" or " ", title, level, tag or "nil", groupCnt or "nil", isDaily or "not daily", isComplete and "C1" or "C0")

        if isHeader then
            header = title or "?"
--            if isCollapsed then
--                Nx.prt ("Q %s collapsed!", title)
--            end
        else
            title = self:ExtractTitle (title)
            SelectQuestLogEntry (qn)
            local qDesc, qObj = GetQuestLogQuestText()
            --local qId, qLevel = self:GetLogIdLevel (qn)

            local qId = questID
            local qLevel = level

            --Nx.prt ("%d",GetQuestLogQuestType(qn)) -- Seeing what quest type function returns
            --Nx.prt("%s", qDesc)
            if qId and not isHidden then
                -- Pull live data from Blizzard for any quest our bundled DB
                -- doesn't fully cover. Also re-syncs chained-objective text
                -- (same questID, objective replaced in place on progress).
                -- Available on retail + Wrath+ Classic; PatchQuestFromBlizzard
                -- self-checks for the C_QuestLog API so older flavors no-op.
                self:PatchQuestFromBlizzard (qId)
                local quest = Nx.Quests[qId]
                local lbCnt = GetNumQuestLeaderBoards (qn)
                local cur = quest and fakeq[quest]
                if not cur then
                    cur = {}
                    curq[index] = cur
                    cur.Index = index
                    index = index + 1
                else
                    cur.Goto = nil                    -- Might have been a goto quest
                    cur.Index = index
                    if quest then
                        self.Tracking[qId] = 0
                        self:TrackOnMap (qId, 0, true)
                    end
                end

                qIds[qId] = cur

                cur.Q = quest
                cur.QI = qn                        -- Blizzard index
                if Nx._dbgQId and cur.QId and cur.QId ~= qId then
                    Nx.prt("|cffff8000[QId-DBG]|r RecordQuestsLog:set cur#%s QI=%s QId %s->%s Title=%q",
                        tostring(cur.Index), tostring(qn), tostring(cur.QId), tostring(qId), tostring(title or "?"))
                end
                cur.QId = qId
                cur.Header = header
                cur.Title = title
                cur.ObjText = qObj
                cur.DescText = qDesc
                cur.Level = level
                cur.RealLevel = qLevel
                cur.NewTime = self.QIdsNew[qId]                -- Copy new time

                cur.Tag = tag
                cur.GCnt = groupCnt or 0

                --Nx.prt("%s", cur.Title)

                cur.PartySize = groupCnt or 1
--            if cur.Tag then Nx.prt ("%s %s", cur.Tag, cur.GCnt) end
                if tag == "Heroic" then
                    cur.PartySize = 5
                end

                cur.TagShort = self.TagNames[tag] or ""

                cur.Daily = isDaily
                if isDaily == LE_QUEST_FREQUENCY_DAILY then
                    cur.TagShort = "$" .. cur.TagShort
                end
                if isDaily == LE_QUEST_FREQUENCY_WEEKLY then
                    cur.TagShort = "#" .. cur.TagShort
                end
                cur.CanShare = GetQuestLogPushable()
                cur.Complete = isComplete            -- 1 is Done, nil not. Otherwise failed
                cur.IsAutoComplete = GetQuestLogIsAutoComplete (qn)

                -- Recovery for a now-fixed bug where FinishQuest wrote
                -- "C" history before the server confirmed the turn-in
                -- (auto-complete quest + full bags rejected the turn-in
                -- but the local hook had already flagged the quest as
                -- completed). The quest then stayed in the live log but
                -- got filtered out of the watch list. If we still see
                -- the contradiction (in log + history says "C") and
                -- Blizzard's per-character completed-quest flag confirms
                -- the server has NOT recorded this quest as completed,
                -- the "C" is stale -- restore it to "W" so the quest is
                -- watched again and the "?" button is visible.
                if cur.QId and cur.QId > 0 and C_QuestLog
                        and C_QuestLog.IsQuestFlaggedCompleted then
                    local qStatus = self:GetQuest (cur.QId)
                    if qStatus == "C"
                            and not C_QuestLog.IsQuestFlaggedCompleted (cur.QId) then
                        self:SetQuest (cur.QId, "W", time())
                    end
                end

                local left = GetQuestLogTimeLeft()
                if left then
                    cur.TimeExpire = time() + left
                    cur.HighPri = true
                end

                cur.ItemLink, cur.ItemImg, cur.ItemCharges, cur.ItemShowOnComplete = GetQuestLogSpecialItemInfo (qn)

                --Nx.prt("Q num: %d itmLink: %s item: %s charges: %d", qn, cur.ItemLink or " ", cur.ItemImg or " ", cur.ItemCharges)
                if cur.ItemLink then
                    local itemString = string.match(cur.ItemLink, ".+|Hitem:([^:]+):.+")
                    if itemString then
                    --    Nx.prt("itemID: %s",itemString)
                        cur.ItemID = tonumber(itemString)
                    else
                        cur.ItemID = 0
                    end
                end
                cur.Priority = 1
                cur.Distance = 999999999
                cur.LBCnt = lbCnt

                for n = 1, lbCnt do
                    local desc, _, done = GetQuestLogLeaderBoard (n, qn)
                    cur[n] = desc or "?"        --V4
                    cur[n + 100] = done
                end

                local mask = 0
                local ender = quest and (quest["End"] or quest["Start"])

                if (isComplete and ender) or lbCnt == 0 or (cur.Goto and quest["Start"]) then
                    mask = 1

                else
                    if self.BuildCatalogObjectiveMask then
                        mask = self:BuildCatalogObjectiveMask(
                            quest, cur, qId)
                    else
                        for n = 1, 15 do
                            local obj = quest and quest["Objectives"]
                                and quest["Objectives"][n]
                            if obj and not cur[n + 100] then
                                mask = mask + bit_lshift (1, n)
                            end
                        end
                    end
                end
                cur.TrackMask = mask

--            Nx.prt ("%s %x", title, mask)

                realQ[title] = cur            -- For diff

            -- Calc total number in quest chain

                if quest then
                    self:CalcCNumMax (cur, quest)
                end
            end
        end
    end


    if Nx.qdb.profile.Quest.PartyShare and self.Watch.ButShowParty:GetPressed() then

--        Nx.prt ("-PQuest-")

        local pq = self.PartyQ

        for plName, pdata in pairs (pq) do

        --Nx.prt ("PQuest %s", plName)
            for qId, qT in pairs (pdata) do
                local quest = Nx.Quests[qId]
                local cur = qIds[qId]

                if cur then        -- We have the quest?
                    local s = format ("\n|cff8080f0%s|r", plName)

                    if not cur.PartyDesc then

                        cur.PartyDesc = ""
                        cur.PartyNames = "\n|cfff080f0Me"
                        cur.PartyCnt = 0
                        cur.PartyComplete = cur.Complete

                        for n, cnt in ipairs (qT) do
                            cur[n + 200] = cur[n + 100]
                            cur[n + 400] = "\n|cfff080f0Me" .. s
                        end
                    end

                    cur.PartyDesc = cur.PartyDesc .. s
                    cur.PartyNames = cur.PartyNames .. s
                    cur.PartyCnt = cur.PartyCnt + 1
                    cur.PartyComplete = cur.PartyComplete and qT.Complete

                    local mask = (cur.PartyComplete or #qT == 0) and 1 or 0

                    for n, cnt in ipairs (qT) do

                        local total = qT[n + 100]

                        --local desc, done = self:CalcDesc (qId, n, cnt, total)

                        desc = qT[n + 200]
                        cur[n] = desc

                        local done = qT[n + 300]

                        done = cur[n + 200] and done
                        cur[n + 200] = done

                        cur.PartyDesc = cur.PartyDesc .. "\n " .. desc
                        cur[n + 400] = cur[n + 400] .. " " .. desc

                        if not done then
                            mask = mask + bit_lshift (1, n)
                        end
                    end

                    cur.TrackMask = mask

                elseif quest then

                    local name, side, lvl = self:Unpack (quest["Quest"])

--                    Nx.prt ("PartyQ %s", name)

                    local cur = {}
                    cur.Goto = true
                    cur.Party = plName
                    cur.PartyDesc = format ("\n|cff8080f0%s|r", plName)
                    cur.PartyNames = cur.PartyDesc
                    cur.Q = quest
                    cur.QI = 0
                    if Nx._dbgQId then
                        Nx.prt("|cffff8000[QId-DBG]|r RecordQuestsLog:partyNew QId=%s plName=%s Title=%q",
                            tostring(qId), tostring(plName), tostring(name or "?"))
                    end
                    cur.QId = qId
                    cur.Header = "Party, " .. plName
                    cur.Title = name
                    cur.ObjText = ""
                    cur.Level = lvl
                    cur.PartySize = 1
                    cur.TagShort = ""
                    cur.Complete = qT.Complete
                    cur.Priority = 1
                    cur.Distance = 999999999

                    self:CalcCNumMax (cur, quest)

                    tinsert (curq, cur)
                    cur.Index = #curq

                    cur.LBCnt = #qT

                    local mask = (qT.Complete or #qT == 0) and 1 or 0

                    for n, cnt in ipairs (qT) do

                        local total = qT[n + 100]

                        --cur[n], cur[n + 100] = self:CalcDesc (qId, n, cnt, total)

                        cur[n] = qT[n + 200]
                        cur[n + 100] = qT[n + 300]

                        cur[n + 400] = cur.PartyNames

                        if not cur[n + 100] then
                            mask = mask + bit_lshift (1, n)
                        end
                    end

                    cur.TrackMask = mask
                end
            end
        end
    end

    for curi, cur in ipairs (curq) do
        if cur.PartyCnt then
            cur.CompleteMerge = cur.PartyComplete

            for n, desc in ipairs (cur) do
                cur[n + 300] = cur[n + 200]
            end

        else
            cur.CompleteMerge = cur.Complete

            for n, desc in ipairs (cur) do
                cur[n + 300] = cur[n + 100]
            end
        end
    end

    --

    -- Publish only after the candidate is complete. Watch state itself lives
    -- in the character database keyed by questID, so replacing CurQ cannot
    -- alter which quests the user chose to watch.
    self.CurQ = curq
    self.QIds = qIds
    self.RealQ = realQ
    self.RealQEntries = qcnt

    if lastChanged then
        self.QLastChanged = self:FindCurFromOld (lastChanged)
    end

    SelectQuestLogEntry (oldSel)

--    Nx.prt ("CurQ %d", #curq)

    self:SortQuests()

    if partySend then
        self:PartyStartSend()
    end

    -- Bypass the ordinary display throttle for this completed snapshot. The
    -- prior implementation could render an early/incomplete pass and then
    -- suppress the corrected pass because it landed inside RefreshTimer.
    if self.Watch then
        self.Watch.ForceListRefresh = true
    end

--    local map = Nx.Map:GetMap (1)
    self.Map.Guide:UpdateMapIcons()
    return true
end

-------------------------------------------------------------------------------
-- Scan
-- <QuestPOIFrame name="WorldMapBlobFrame">
--  DrawQuestBlob (id, bool)
--  UpdateMouseOverTooltip
--  GetNumTooltips()
--  GetTooltipIndex (i)
-------------------------------------------------------------------------------

function Nx.Quest:ScanBlizzQuestData()
    -- Skip if a scan is already running or pending
    if IS_BACKGROUND_WORLD_CACHING or QScanBlizz then
        return
    end

    SetCVar ("questPOI", 1)        -- Enable or no POI data returned

    self.ScanBlizzMapId = 1
    -- Use delay or some quests won't be ready
    QScanBlizz = C_Timer.After(1, function()
        QScanBlizz = nil
        Nx.Quest:ScanBlizzQuestDataTimer()
    end)
end

function Nx.Quest:IsDaily(checkID)
    local isdaily = false
    for qn = 1, GetNumQuestLogEntries() do
        local title, level, groupCnt, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle (qn)
        if questID == checkID then
            if frequency == LE_QUEST_FREQUENCY_DAILY or frequency == LE_QUEST_FREQUENCY_WEEKLY then
                isdaily = true
            end
            break
        end
    end
    return isdaily
end

-------------------------------------------------------------------------------
-- Is a quest's prerequisite satisfied (offerable right now)?
--
-- Carbonite stores chain links forward as nextId; the generated Nx.QuestPrev
-- table is the reverse (Nx.QuestPrev[B] = A means A.nextId == B, i.e. A must be
-- completed before B is offered). A quest with no entry has no known
-- prerequisite -> treated as offerable. Checking only the IMMEDIATE previous
-- part is enough: you cannot have completed part N-1 without N-2 ... N-1.
--
-- Used to stop showing quest givers / list entries for later parts of a chain
-- the player hasn't reached yet (e.g. "Worgen in the Woods (Part 2/3/4)" while
-- still on Part 1). Completion is read from C_QuestLog.IsQuestFlaggedCompleted
-- (reliable on retail AND classic) with a fallback to Carbonite's own status.
-------------------------------------------------------------------------------

function Nx.Quest:PrereqMet (qId)
    local prev = Nx.QuestPrev and Nx.QuestPrev[qId]
    if not prev then
        return true
    end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
            and C_QuestLog.IsQuestFlaggedCompleted (prev) then
        return true
    end
    return self:GetQuest (prev) == "C"
end

function Nx.Quest:ScanBlizzQuestDataTimer()
    if IS_BACKGROUND_WORLD_CACHING then
        return
    end
    IS_BACKGROUND_WORLD_CACHING = true
    --ObjectiveTrackerFrame:UnregisterEvent ("WORLD_MAP_UPDATE")        -- Map::ScanContinents can enable this again
--    local tm = GetTime()

    local Map = Nx.Map
    local curMapId = Map:GetCurrentMapId()
        for a,b in pairs(Nx.Zones) do
            local mapId = a
            if Nx.Map.MapWorldInfo[mapId] then
                if InCombatLockdown() then
                    --ObjectiveTrackerFrame:RegisterEvent ("WORLD_MAP_UPDATE")    -- Back on when done
                    Nx.Quest.WorldUpdate = false
                    IS_BACKGROUND_WORLD_CACHING = false
                    return
                end
                C_QuestLog.SetMapForQuestPOIs(mapId)
                Nx.Quest:MapChanged()
                --C_Timer.After(.01, function(mapId) Nx.Quest:MapChanged(mapId) end)
                --Nx.Quest:MapChanged()
                --WorldMapFrame:SetMapID(mapId)            -- Triggers WORLD_MAP_UPDATE, which calls MapChanged
                --local cont = Nx.Map.MapWorldInfo[mapId].Cont
                --local info = Map.MapInfo[cont]
            end
        end
    Nx.Quest.Watch:Update()
    --ObjectiveTrackerFrame:RegisterEvent ("WORLD_MAP_UPDATE")
    -- Back on when done
    --Map:SetCurrentMap (curMapId)
    C_QuestLog.SetMapForQuestPOIs(curMapId)
    IS_BACKGROUND_WORLD_CACHING = false
    self:RecordQuestsLog()
end

-------------------------------------------------------------------------------
-- Called by map QUEST_POI_UPDATE
-------------------------------------------------------------------------------

local qelapsed = 0
local qlasttime
local qttl = 9999

function Nx.Quest:MapChanged()
    if Nx.ModQAction == "QUEST_DECODE" then
        Nx.ModQAction = ""
        Nx.Quest:DecodeComRcv (Nx.qTEMPinfo, Nx.qTEMPmsg)
    end
    if qlasttime then
        local curtime = debugprofilestop()
        qelapsed = curtime - qlasttime
        qlasttime = curtime
    else
        qlasttime = debugprofilestop()
    end
    qttl = qttl + qelapsed
    if qttl < 2000 and not IS_BACKGROUND_WORLD_CACHING then
        return
    end
    qttl = 0
    if Nx.QInit then    -- Quests inited?
        self:ScanBlizzQuestDataZone(true)
    end
end

-- /dump Nx.Quest:ScanBlizzQuestDataTimer()
function Nx.Quest:ScanBlizzQuestDataZone(WatchUpdate)
    if not Nx.QInit then
        return
    end


    local mapId = Nx.Map:GetCurrentMapId() --C_QuestLog.GetMapForQuestPOIs()  -- try old way as POI's messing up with quest objective data when bliz map shows quests from neighbor map thus causing pathing issues
    if not mapId then
        return
    end
    --local tm = GetTime()
    local mapQuests = C_QuestLog.GetQuestsOnMap(mapId)

    local num = mapQuests and #mapQuests or 0--QuestMapUpdateAllQuests()        -- Blizz calls these in this order
    if num > 0 then
--        QuestPOIUpdateIcons()
--        Nx.prt("%s %s", num or 0, mapId)
        if Nx.Map:IsBattleGroundMap(mapId) then
            return
        end
        for n = 1, num do
            local id = mapQuests[n] and mapQuests[n].questID or -1
            local qi = GetQuestLogIndexByID(id)
--            Nx.prt("%s %s", id, qi)
            if mapQuests[n] and qi and qi > 0 then
                local objectives = C_QuestLog.GetQuestObjectives(id)
                local title, level, groupCnt, isHeader, isCollapsed, isComplete, _, questID = GetQuestLogTitle (qi)
                local questTagInfo = GetQuestTagInfoCompat(id)
                local tagID = questTagInfo and questTagInfo.tagID
                local tagName = questTagInfo and questTagInfo.tagName
                local worldQuestType = questTagInfo and questTagInfo.worldQuestType
                local rarity = questTagInfo and questTagInfo.quality
                local isElite = questTagInfo and questTagInfo.isElite
                local tradeskillLineIndex = questTagInfo and questTagInfo.tradeskillLineID
                local lbCnt = objectives and #objectives or 0; --GetNumQuestLeaderBoards (qi)
                local qObjl = 0;
                local quest = Nx.Quests[id] or {}
                local patch = Nx.Quests[-id] or 0
                if quest and quest["Objectives"] then
                    qObjl = #quest["Objectives"]
                end
                local needEnd = isComplete and not quest["End"]
                local fac = UnitFactionGroup ("player") == "Horde" and 1 or 2

                -- Enter the patch block whenever Blizzard's API has objectives
                -- to contribute (lbCnt > 0) — even if we already have static
                -- POIs, we want to append the live ones too so both render.
                if worldQuestType == nil and (patch > 0 or needEnd or (not isComplete and lbCnt > 0)) then
                    local x, y, objective;
                    x = mapQuests[n].x
                    y = mapQuests[n].y
                    objective = objectives[1] or nil;
                    if x then    -- Miner's Fortune was found in org, but x, y, obj were nil
                        x = x * 100
                        y = y * 100
--                        Nx.prt ("%s #%s %s %s %s %s", mapId, n, id, x or "nil", y or "nil", objective and objective.text or "nil")
                        if not quest["Quest"] then
                            quest["Quest"] = format ("[[%s|%s|%s|0|0|0]]",title,fac,level)
                        end
                        if needEnd or bit_band (patch, 1) then
                            if not quest["End"] then --or (bit_band(patch,1) and mapId == MapUtil.GetDisplayableMapForPlayer()) then --disable this check as it's logic fails when there's no objectives defined in QuestDB for QuestID
                                local safeTitle = (title or "?"):gsub("|", "")
                                if safeTitle == "" then safeTitle = "?" end
                                quest["End"] = format ("%s|%s|32|%f|%f", safeTitle, mapId, x, y)
                            end
                            patch = bit.bor (patch, 1)        -- Flag as a patched quest
                        end

                        if not isComplete then
                            -- Static catalog POIs are authoritative for both
                            -- position and identity grouping. Do not rename
                            -- slot i from live row i: catalog slots are
                            -- location records, and several slots may belong
                            -- to one Blizzard objective. MapIcons resolves
                            -- live tooltip/completion state by normalized
                            -- objective identity at render time. Only quests
                            -- with no catalog geometry receive the public
                            -- quest-level POI as a fallback.
                            local hadObjectives = quest["Objectives"] ~= nil
                            if not quest["Objectives"] then
                                quest["Objectives"] = {}
                            end
                            patch = bit.bor (patch, 2)

                            for i = 1, lbCnt do
                                local objText = (objectives[i] and objectives[i].text) or "?"
                                objText = (objText:gsub("|", ""))
                                if not hadObjectives then
                                    local obj = format ("%s|%s|32|%f|%f|6|6",
                                        objText, mapId, x, y)
                                    quest["Objectives"][i] = {obj}
                                end
                            end
                        end
                    end
                    Nx.Quests[-id] = patch
                    Nx.Quests[id] = quest
                end
            end
        end
    end
    if not Nx.Quest.List.LoggingIn and not WatchUpdate then
        Nx.Quest.Watch:Update()
    end
--    Nx.prt ("%f secs", GetTime() - tm)
end


-------------------------------------------------------------------------------

function Nx.Quest:CalcCNumMax (cur, quest)
    if quest.CNum then
        cur.CNumMax = quest.CNum - 1

        local qc = quest
        local _qids = {}
        local cnum = 0
        while qc do
            cnum = cnum + 1
            cur.CNumMax = cur.CNumMax + 1
            qnext = self:UnpackNext (qc["Quest"])
            if not qnext or qnext == 0 or _qids[qnext] == true or cnum > 40 then
                break
            end
            _qids[qnext] = true;
            qc = Nx.Quests[qnext]
        end
    end
end

-------------------------------------------------------------------------------
-- Set quests done
-------------------------------------------------------------------------------

function Nx.Quest:CurQSetPreviousDone()

--    local sTime = GetTime()

    local cnt = 0

    for curi, cur in ipairs (self.CurQ) do
        if cur.QI > 0 then
            cnt = cnt + self:CalcPreviousDone (cur.QId)
        end
    end

    if cnt > 0 then
        Nx.prt (L["Set %d chain quests as done"], cnt)
    end

--    Nx.prt ("Calc %f secs", GetTime() - sTime)
end

function Nx.Quest:CalcPreviousDone (qId)

    local cnt = 0

    for mungeId, q in pairs (Nx.Quests) do
        if mungeId < 0 then
            break
        end

        if q.CNum == 1 then        -- Only look at chain starters

            local id = (mungeId + 3) / 2 - 7
            local qc = q
            -- Guard against cycles in the nextId chain (e.g. A->B->A). Without
            -- a visited set a looped chain spins forever -> "script ran too
            -- long" watchdog kill (surfaces in NxSplit/UnpackNext), which
            -- aborts this timer mid-run and stalls dependent updates. The
            -- inner walk also needs a qc nil-guard (a dangling nextId would
            -- otherwise deref nil qc["Quest"]).
            local seen = {}
            while qc and not seen[id] do
                seen[id] = true

                if id == qId then        -- Found me in chain? Mark before me complete

                    local id = (mungeId + 3) / 2 - 7
                    local qc = q
                    local seen2 = {}
                    while qc and id ~= qId and not seen2[id] do
                        seen2[id] = true

                        local qStatus = Nx.Quest:GetQuest (id)
                        if qStatus ~= "C" then

                            cnt = cnt + 1

--                            Nx.prt ("%s %s", id, qId)
                            Nx.Quest:SetQuest (id, "C", time())
                        end

                        id = self:UnpackNext (qc["Quest"])
                        qc = Nx.Quests[id]
                    end

                    break
                end

                id = self:UnpackNext (qc["Quest"])
                qc = Nx.Quests[id]
            end
        end
    end

    return cnt
end

-------------------------------------------------------------------------------
-- Fired on login
-------------------------------------------------------------------------------

function Nx.Quest:GetHistoryTimer()

--    local down = GetNetStats()        -- .08 to 4. Seems to be an average since it creeps down

--    Nx.prt ("GetNetStats %f", down)

--    if down > 2.5 then    -- Wait?
--        return 2
--    end
    if not Nx.Quest.CurCharacter["QHAskedGet"] then
        Nx.Quest.CurCharacter["QHAskedGet"] = true
        local function func()
            QHistQuery = Nx:ScheduleTimer(Nx.Quest.QuestQueryTimer, .1, Nx.Quest)
        end

        Nx:ShowMessage (L["Get character's quest completion data from the server?"], "Get", func, "Cancel")
    end
end

function Nx.Quest:QuestQueryTimer()

    local qc

    -- Retail uses C_QuestLog.GetAllCompletedQuestIDs (returns array)
    -- Classic uses GetQuestsCompleted (returns table with quest IDs as keys)
    if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
        qc = C_QuestLog.GetAllCompletedQuestIDs()
    elseif GetQuestsCompleted then
        qc = GetQuestsCompleted()
    end

    if not qc then
        Nx.prt (L["QuestQueryTimer wait"])
        return 1
    end

--    Nx.prtVar ("OnQuest_query_complete", qc)

    local cnt = 0

    -- Handle both array format (retail) and table format (classic)
    if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
        -- Retail: qc is an array of quest IDs
        for _, id in ipairs(qc) do
            local qStatus = Nx.Quest:GetQuest(id)
            if qStatus ~= "C" then
                cnt = cnt + 1
                Nx.Quest:SetQuest(id, "C", time())
            end
        end
    else
        -- Classic: qc is a table with quest IDs as keys
        for id in pairs(qc) do
            local qStatus = Nx.Quest:GetQuest(id)
            if qStatus ~= "C" then
                cnt = cnt + 1
                Nx.Quest:SetQuest(id, "C", time())
            end
        end
    end

    if cnt > 0 then
        Nx.prt (L["Set %d previous quests as done"], cnt)
        Nx.Quest.List:Update()
    end
end

function Nx.Quest:CalcDesc (qId, objI, cnt, total, fallbackDesc)

    local odesc, _, objectiveDone, liveCnt, liveTotal = Nx.Quest:GetQuestObjectiveInfo (qId, objI, false)
    cnt = tonumber (liveCnt) or tonumber (cnt) or 0
    total = tonumber (liveTotal) or tonumber (total) or 0
    local desc = self:NormalizeObjectiveProgressText (odesc or fallbackDesc, cnt, total)

--    Nx.prt("%s, %s, %s, %s, %s", qId, objI, desc, cnt, total)

    if total == 0 then
        return desc, objectiveDone or cnt == 1
    else
        return desc, objectiveDone or cnt >= total
    end
end

function Nx.Quest:GetQuestObjectiveInfo(qId, objI, qText)
    if not C_QuestLog or not C_QuestLog.GetQuestObjectives then
        return
    end

    local obj = C_QuestLog.GetQuestObjectives(qId)

    obj = (obj and obj[objI]) or nil

    if obj then
        return obj.text, obj.type, obj.finished, obj.numFulfilled, obj.numRequired
    end

    return
end

function Nx.Quest:GetLogIdLevel (questID)
    if questID > 0 then
        local qlink = nil --GetQuestLink (questID)
        if qlink then
            --local s1, _, id, level = strfind (qlink, "Hquest:(%d+):(.%d*)")
            local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(i);
            if s1 then
--                Nx.prt ("qlink %s", gsub (qlink, "|", "^"))
                return tonumber (id), tonumber (level)
            end
        end
    end
end

function Nx.Quest:CreateLink (qId, realLevel, title)

    if realLevel <= 0 then    -- Could be a 0
        realLevel = -1
    end
    return format ("\124cffffff00\124Hquest:%s:%s\124h[%s]\124h\124r", qId, realLevel, title)
end

function Nx.Quest:ExtractTitle (title)

--    Nx.prt ("Orig '%s'", title)

    local _, e = strfind (title, "^%[%S+%] ")
    if e then
        title = strsub (title, e + 1)

    else
        local _, e = strfind (title, "^%d+%S* ")
        if e then
            title = strsub (title, e + 1)
        end
    end

--    Nx.prt ("'%s'", title)

    return title
end

-------------------------------------------------------------------------------
-- Sort quests
-------------------------------------------------------------------------------

function Nx.Quest:SortQuests()

    local curq = self.CurQ

    -- Sort by level

    repeat
        local done = true

        for n = 1, #curq - 1 do

            if curq[n].Level > curq[n + 1].Level then
                curq[n], curq[n + 1] = curq[n + 1], curq[n]
                done = false
            end
        end

    until done

    -- Sort by header

    if self.List.QOpts.NXShowHeaders then

        local hdrNames = {}

        for n = 1, #curq do
            hdrNames[curq[n].Header] = 1
        end

        local hdrs = {}

        for name in pairs (hdrNames) do
            tinsert (hdrs, name)
        end

        sort (hdrs)

--        Nx.prtVar ("HDR", hdrs)

        local curq2 = curq
        curq = {}

        for _, name in ipairs (hdrs) do

            for n = 1, #curq2 do

                if curq2[n].Header == name then
                    tinsert (curq, curq2[n])
                end
            end
        end

        self.CurQ = curq

--        Nx.prtVar ("curq", curq)
    end

    -- Build id mapping

    local t = {}
    self.IdToCurQ = t

    for k, cur in ipairs (curq) do

        if cur.Q then
            local id = cur.QId
            t[id] = cur
        end
    end
end

-------------------------------------------------------------------------------
