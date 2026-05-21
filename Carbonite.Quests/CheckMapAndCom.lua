-- Carbonite.Quests | CheckMapAndCom
-- Map-presence check, chat-link insertion, captured-quest collection,
-- and the cross-party com receive handler. Pulled out of NxQuest.lua
-- to keep the engine file smaller. Pure handlers / helpers — no UI
-- frames owned here.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals.
local strfind  = strfind or string.find
local strsub   = strsub  or string.sub
local format   = format  or string.format
local gsub     = gsub    or string.gsub
local tinsert  = tinsert or table.insert
local tremove  = tremove or table.remove


-------------------------------------------------------------------------------
-- Check if any part of quest in the map
-------------------------------------------------------------------------------

function Nx.Quest:CheckShow (mapId, qId)

    local nxid = mapId
    local quest = Nx.Quests[qId]

    if not quest then
        return
    end

    local qname, side, lvl, minlvl, next = self:Unpack (quest["Quest"])

    --    Check start, end and objectives
--[[
    if not quest[2] then
        Nx.prt (L["quest error: %s %s"], qname, qId)
        assert (quest[2])
    end
--]]
    local _, startMapId = self:UnpackSE (quest["Start"])
    if startMapId then
        if startMapId == nxid then
            return true
        end
    end

    if quest["End"] then
        local _, endMapId = self:UnpackSE (quest["End"])
        if endMapId then
            if endMapId == nxid then
                return true
            end
        end
    end

    for n = 1, 15 do

        local obj = quest["Objectives"]
        if not obj or not obj[n] then
            break
        end

        local _, objMapId = self:UnpackObjective (obj[n][1])

        if objMapId then

            if objMapId == nxid then
                return true
            end
        end
    end
end

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

function Nx.Quest:WatchAtLogin()

    for n, cur in ipairs (self.CurQ) do

        local qStatus = Nx.Quest:GetQuest (cur.QId)
        if not qStatus then

--            Nx.prt ("Add watch %s", cur.Title)
            self.Watch:Add (n)

--        elseif qStatus == "W" then
--            Nx.prt ("Watched %s", cur.Title)

--        elseif qStatus == "C" then
--            Nx.prt ("Completed %s", cur.Title)

        end
    end
end

function Nx.Quest:WatchAll()

    local curq = self.CurQ
    if curq then
        for i, cur in ipairs (curq) do
            self.Watch:Add (i)
        end
    end
end

function Nx.Quest:Goto (qId)

    if qId == 0 then
        return
    end

--    Nx.prt ("Goto %s", qId)

    local i = self:FindCur (qId)

    if i then
        Nx.prt (L["Already going to quest"])
        return
    end

    local curq = self.CurQ
    local quest = Nx.Quests[qId]

    if not quest["Start"] then
        Nx.prt ("No quest starter")
        return
    end

    local name, side, lvl = self:Unpack (quest["Quest"])

    local cur = {}
    cur.Goto = true
    cur.Q = quest
    cur.QI = 0
    cur.QId = qId
    cur.Header = L["Goto"]
    cur.Title = L["Goto: "] .. name
    cur.ObjText = ""
    cur.Level = lvl
    cur.PartySize = 1
    cur.LBCnt = 0
    cur.TrackMask = 1
    cur.TagShort = ""

    cur.Priority = 1
    cur.Distance = 999999999

    cur.HighPri = true

    self:CalcCNumMax (cur, quest)

    tinsert (curq, cur)
    cur.Index = #curq

    self.Watch:Add (#curq)

    self:RecordQuests(0)
    self.List:Update()
end

function Nx.Quest:Abandon (qIndex, qId)

    if qIndex > 0 then

        self:ExpandQuests()

        local title, level, groupCnt, isHeader = GetQuestLogTitle (qIndex)

        if not isHeader then

--            Nx.prt ("Abandon %s %s", qIndex, title)
--            QuestLog_SetSelection (qIndex)

            local text = format(ABANDON_QUEST_CONFIRM, title);
            local items = GetAbandonQuestItems()
            if items then
                text = format(ABANDON_QUEST_CONFIRM_WITH_ITEMS, title, items);
            end

            Nx:ShowMessage (
                text,
                YES,
                function(self)
                    if not Nx.isClassic then
                        C_QuestLog.SetSelectedQuest (C_QuestLog.GetQuestIDForLogIndex(qIndex))				
                        C_QuestLog.SetAbandonQuest()
                        -- native blizz
                        C_QuestLog.AbandonQuest();
                        if ( QuestLogPopupDetailFrame:IsShown() ) then
                            HideUIPanel(QuestLogPopupDetailFrame);
                        end
                    else
                         SelectQuestLogEntry (qIndex)
                         SetAbandonQuest()
                         -- native blizz
                         AbandonQuest();
                    end

                    PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
                    -- carb
                    if qId > 0 then
                        --Nx.Quest.CurQ[qIndex] = nil
                        Nx.Quest:NullQuest (qId)
                    end
                end,
                NO,
                function(self)
                end
            )
        end

        self:RestoreExpandQuests()

    else
        if qId > 0 then

            self.Watch:RemoveWatch (qId, qIndex)
            local i = self:FindCur (qId)
            if i then
                local curq = self.CurQ
                tremove (curq, i)
            end
            Nx.Quest:NullQuest (qId)
        end
    end
end

-------------------------------------------------------------------------------
-- Link a quest to chat edit frame
-------------------------------------------------------------------------------

function Nx.Quest:LinkChat (qId)

    local box = ChatEdit_ChooseBoxForSend()
    ChatEdit_ActivateChat (box)

    if box then
        local s = self.List:MakeDescLink (nil, qId, IsControlKeyDown())
        if s then
            box:Insert (s)
        end
    else

        Nx.prt (L["|cffff4040No edit box open!"])
    end
end

-------------------------------------------------------------------------------
-- Get quests from a player
-------------------------------------------------------------------------------

function Nx.Quest:GetFromPlyr (plName)

    Nx.ShowMessageTrial()

--    Nx.prt ("GetFromPlyr %s", plName)

    self.List.Bar:Select (4)

    self.FriendQuests = {}

    self.RcvPlyr = plName
    self.RcvPlyrLast = plName

    Nx.Com:Send ("W", "Q*", plName)
end

-------------------------------------------------------------------------------
-- Clear captured quests
-------------------------------------------------------------------------------

function Nx.Quest:ClearCaptured()
    NXQuest.Gather["Q"] = {}
end

-------------------------------------------------------------------------------
-- Quest com message from a player
-------------------------------------------------------------------------------

function Nx.Quest:OnMsgQuest (plName, msg)

--    Nx.prt ("OnMsgQuest (%s) %s", plName, msg)
    loc = strfind(plName,"-")
    if loc and loc > 0 then
        plName = string.gsub(plName,strsub(plName,loc),"")
    end
    local id = strsub (msg, 2, 2)

    if id == "*" then        -- Request for all quests

--        if nil then
        if not self.SendPlyr or self.SendPlyr == plName then

            Nx.prt (L["Sending quests to %s"], plName)

            self.SendPlyr = plName
            self:BuildQSendData()
            QSendAll = Nx:ScheduleTimer(self.QSendAllTimer,0,self)
        else

            Nx.Com:Send ("W", "QB", plName)
        end

    elseif id == "B" then    -- Busy

        if plName == self.RcvPlyr then

            local mode = strsub (msg, 3, 3)

            if mode == "s" then
                Nx.prt (L[" %s -share"], self.RcvPlyr)
            elseif mode == "C" then
                Nx.prt (L[" %s busy"], self.RcvPlyr)
            else
                tinsert (self.FriendQuests, L[" ^Player is busy"])
            end

            self.RcvPlyr = nil

            local pd = self.CapturePlyrData[plName]
            if pd then
                pd.RcvPlyrCapName = nil
            end
        end

    elseif id == "D" then    -- Incoming quest data

        if plName == self.RcvPlyr then

            if #msg >= 4 then

                local data = strsub (msg, 3)
                local mode = strsub (msg, 3, 3)

                if mode == "0" then

                    self.RcvCnt = 0
                    self.RcvTotal = tonumber (strsub (data, 3)) or 0

                elseif mode == "H" then

                    tinsert (self.FriendQuests, data)
                    self.List:Update()

                elseif mode == "T" then

                    self.RcvCnt = self.RcvCnt + 1
                    tinsert (self.FriendQuests, data)

--                    Nx.prt ("Quest Data %s", data)

                    self.List:Update()

                elseif mode == "O" then

                    tinsert (self.FriendQuests, data)
                    self.List:Update()
                end
            else
                self.RcvPlyr = nil
            end
        end

    elseif id == "p" then    -- Incoming party data

        self:OnPartyMsg (plName, msg)

    end
end

function Nx.Quest:BuildQSendData()

    local data = {}

    self.QSendData = data
    self.QSendDataI = 1

    local header
    local cnt = 0

    for n, cur in ipairs (self.CurQ) do

        if not cur.Goto then

            if cur.Header ~= header then
                header = cur.Header

                local str = format ("QDH^%s", header)
                tinsert (data, str)
            end

            local qStatus = Nx.Quest:GetQuest (cur.QId)
            local watched = qStatus == "W" and 1 or 0

            local str = format ("QDT^%s^%s^%s^%s^%s", cur.QId, watched, cur.Complete or 0, cur.Level, cur.Title)
            tinsert (data, str)

            for n = 1, cur.LBCnt do
                local str = format ("QDO^%s^%s", -n, cur[n])
                tinsert (data, str)
            end

            cnt = cnt + 1
        end
    end

    tinsert (data, "QD")

    local str = format ("QD0^%d", cnt)
    tinsert (data, 1, str)
end

function Nx.Quest:QSendAllTimer()

    local qi = self.QSendDataI
    local data = self.QSendData[qi]

    if data then

        Nx.Com:Send ("W", data, self.SendPlyr)

--        Nx.prt ("QSendAllTimer: %s", data)
    end

    self.QSendDataI = qi + 1

    if self.QSendData[self.QSendDataI] then
        return .2
    end

    self.SendPlyr = nil
end

