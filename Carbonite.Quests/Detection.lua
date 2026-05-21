-- Carbonite.Quests | Detection
-- New-quest detection, quest capture from the log, completed-sound
-- player, tell-party-of-changes pipeline, and the FindCurFromOld
-- continuity helper. All scan-side logic for noticing what changed
-- between two QUEST_LOG_UPDATE events.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals.
local floor      = math.floor
local strsub     = strsub   or string.sub
local strmatch   = strmatch or string.match
local format     = format   or string.format
local gsub       = gsub     or string.gsub
local tinsert    = tinsert  or table.insert
local GetTime    = GetTime
local UnitLevel  = UnitLevel
local UnitName   = UnitName
local UnitGUID   = UnitGUID

-- Promoted from NxQuest.lua.
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

-- Detect a new quest
-------------------------------------------------------------------------------

function Nx.Quest:FindNewQuest()

    -- Id
    if self.AcceptQId then    -- Auto accept quest triggered?

        local qi = GetQuestLogIndexByID (self.AcceptQId)
        self.AcceptQId = nil

        local title = self:ExtractTitle (GetQuestLogTitle (qi))

        if not self.RealQ[title] then
            return qi
        end
    end

    -- Scan by name

    local aQName = self.AcceptQName

    if not aQName then
        return
    end

    local cnt = GetNumQuestLogEntries()

--    Nx.prt ("FindNewQuest %d", cnt)

    for qn = 1, cnt do

        local title, level, groupCnt, isHeader, isCollapsed, _, _, questID = GetQuestLogTitle (qn)
        local questTagInfo = GetQuestTagInfoCompat(questID)
        local tagID = questTagInfo and questTagInfo.tagID
        local tag = questTagInfo and questTagInfo.tagName

        if not isHeader then
            title = self:ExtractTitle (title)
            if title == aQName then
                if not self.RealQ[title] then
--                    Nx.prtVar ("RealQ", self.RealQ)
                    self.AcceptQName = nil
                    return qn
                end
            end
        end
    end
end

--------

function Nx.Quest:RecordQuestAcceptOrFinish()

    local giver = UnitName ("npc") or "?"

    local guid = UnitGUID ("npc")
    if guid then

    local typ, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit ("-", guid)
        if typ == "Player" then
            giver = "p"
        elseif typ == "GameObject" then
            giver = format ("%s#o%x", giver, npc_id)
        elseif typ == "Creature" then        -- NPC
            giver = format ("%s#%x", giver, npc_id)
        end
    end

    self.AcceptGiver = giver

    local qname = GetTitleText()        -- Also works for auto accept
    self.AcceptQName = qname
    local id = Nx.Map:GetRealMapId()
    self.AcceptAId = id or 0
    self.AcceptDLvl = 0

    if Nx.Map:GetCurrentMapId() == id then
        self.AcceptDLvl = Nx.Map:GetCurrentMapDungeonLevel()
    end

    local map = Nx.Map and Nx.Map:GetMap (1)
    self.AcceptX = (map and map.PlyrRZX) or 0
    self.AcceptY = (map and map.PlyrRZY) or 0

--    Nx.prt ("AcceptQuest (%s) (%s) %s,%s", giver, qname, self.AcceptAId, self.AcceptDLvl)

end

-------------------------------------------------------------------------------

function CarboniteQuest:OnChat_msg_combat_faction_change (event, arg1)

    local self = Nx.Quest

--    Nx.prt ("OnChat_msg_combat_faction_change %s", arg1)

    local form = FACTION_STANDING_INCREASED
    form = gsub (form, "%%s", "(.+)")
    form = gsub (form, "%%d", "(%%d+)")
    local facName, rep = strmatch (arg1, form)
    rep = tonumber (rep)

    if facName and rep and self.CaptureQEndTime and GetTime() - self.CaptureQEndTime < 2 then

        local facNum = self.CapFactionAbr[facName]
        if facNum then

            local _, race = UnitRace ("player")
            if race == "Human" then
                rep = rep / 1.1 + .5
            end

--            Nx.prt ("Fac %s %s", facName, rep)

            local cap = NXQuest.Gather
            local quests = Nx:CaptureFind (cap, "Q")
            local qdata = { Nx.Split ("~", quests[self.CaptureQEndId]) }
            local ender, reps = Nx.Split ("@", qdata[2])

            local repdata = reps and { Nx.Split ("^", reps) } or {}
            tinsert (repdata, format ("%d %x", rep, facNum))
            reps = table.concat (repdata, "^")

            qdata[2] = format ("%s@%s", ender, reps)
            quests[self.CaptureQEndId] = table.concat (qdata, "~")    -- concat is not global!!!
        end
    end

    self.CaptureQEndTime = nil
end

-------------------------------------------------------------------------------
-- Capture a quest
-- (current index, objective # (nil for start, -1 end)
-------------------------------------------------------------------------------

function Nx.Quest:Capture (curi, objNum)

    local Nx = Nx
    local opts = self.GOpts

    if not Nx.db.profile.General.CaptureEnable then
        return
    end

    local cur = self.CurQ[curi]
    local id = cur.QId

    if Nx.db.profile.Debug.DebugMap and (not objNum or objNum < 0) then    -- Start or end
        Nx.prt ("Quest Capture %s", id or "nil")
    end

    if not id then
        return
    end

    local cap = NXQuest.Gather

    local facI = UnitFactionGroup ("player") == "Horde" and 1 or 0
    local quests = Nx:CaptureFind (cap, "Q")
    local saveId = id * 2 + facI

    local len = 0

    for id, str in pairs (quests) do
        len = len + 4 + #str + 1
    end

    if len > 110 * 1024 then
        return
    end

    local qTitle = cur.Title
    local currentMapID = C_Map.GetBestMapForUnit("player")

--    Nx.prt ("Cap len %s", len)

--[[
    if not objNum or objNum < 0 then
        Nx.prt (L["Capture %s %s %s %.2f,%.2f"], self.AcceptGiver, self.AcceptAId or 0, self.AcceptDLvl, self.AcceptX, self.AcceptY)
    else
        local map = self.Map
        Nx.prt (L["Capture #%s %s %.2f,%.2f"], objNum, map.RMapId, map.PlyrRZX, map.PlyrRZY)
    end
--]]

--    local ids = self:CaptureGet (quests, id)
--    ids["I"] = format ("%d^%s^%s", cur.RealLevel, cur.Title, cur.Header)

    local q = quests[saveId]

    if not q then
        q = strrep ("~", cur.LBCnt + 1)
    end

    local qdata = { Nx.Split ("~", q) }

    if not objNum then    -- Starter

--        local flags = bit.bor (tonumber (strsub (qdata[1], 1, 1), 16) or 0, facMask)
        local plLvl = UnitLevel ("player")

        -- 0 is reserved
        local s = Nx:PackXY (self.AcceptX, self.AcceptY)
--        qdata[1] = format ("0%s^%02x%02x%s", self.AcceptGiver, plLvl, self.AcceptAId, s)
        qdata[1] = format ("0|%s|%s^%03x%x%s", qTitle, self.AcceptGiver, currentMapID, self.AcceptDLvl, s)

--        Nx.prt ("Capture start %s", qdata[1])

    elseif objNum < 0 then    -- Ender

        local s = Nx:PackXY (self.AcceptX, self.AcceptY)
        qdata[2] = format ("|%s|%s^%03x%x%s", qTitle, self.AcceptGiver, currentMapID, self.AcceptDLvl, s)

        self.CaptureQEndTime = GetTime()
        self.CaptureQEndId = saveId

--        Nx.prt ("Capture end %s", qdata[2])

    else

        local map = self.Map:GetMap(1)
        local nxzone = map.UpdateMapID
        if nxzone then

            local index = objNum + 2
            local obj = qdata[index]

            if not obj then
--                Nx.prt (L["Capture err %s, %s"], cur.Title, objNum)    -- Debug message
                return
            end

            if #obj >= 3 then
                local z = tonumber (strsub (obj, 1, 3), 16)
                if nxzone ~= z then
                    return
                end
            else
                obj = format ("%03x", nxzone)
            end

            local cnt = (#obj - 3) / 6
            if cnt >= 15 then
                return
            end

            qdata[index] = obj .. Nx:PackXY (map.PlyrRZX, map.PlyrRZY)

--            Nx.prt ("Capture%d #%d %s", objNum, cnt, qdata[index])
        end
    end

    quests[saveId] = table.concat (qdata, "~")    -- concat is not global!!!

--    Nx.prt ("CapStr %s", quests[saveId])
end

function Nx.Quest:CaptureGetCount()

    local cap = NXQuest.Gather
    local quests = Nx:CaptureFind (cap, "Q")

    local cnt = 0

    for id, str in pairs (quests) do
        cnt = cnt + 1
    end

    return cnt
end

-------------------------------------------------------------------------------
-- Play a completed sound
-- (snd index or nil for random)
-------------------------------------------------------------------------------

function Nx.Quest:PlaySound (sndI)

    if not sndI then

        local opts = self.GOpts
        local cnt = 0

        for n = 1, 10 do
            if Nx.qdb.profile.Quest["Snd" .. n] then
                cnt = cnt + 1
            end
        end

        if cnt > 0 then

            local i = random (1, cnt)
            cnt = 0

            for n = 1, 10 do
                if Nx.qdb.profile.Quest["Snd" .. n] then
                    cnt = cnt + 1
                    if cnt == i then
                        sndI = n
                        break
                    end
                end
            end
        end
    end

    if sndI then
        local snd = Nx.OptsDataSounds[sndI]
        Nx:PlaySoundFile (snd)
    end
end

-------------------------------------------------------------------------------
-- Tell party of quest changes
-------------------------------------------------------------------------------

function Nx.Quest:TellPartyOfChanges()

--PAIDS!

    if self.RealQEntries ~= GetNumQuestLogEntries() then    -- Quests added or removed?
        return
    end

    local opts = self.GOpts
    if not Nx.qdb.profile.Quest.BroadcastQChanges then
        return
    end

    local curq = self.CurQ

    for _, cur in ipairs (curq) do

        if cur.QI > 0 then

            for n = 1, cur.LBCnt do

                local skip
                local desc, _, done = GetQuestLogLeaderBoard (n, cur.QI)
                if desc then
                    if not done then

                        local num = Nx.qdb.profile.Quest.BroadcastQChangesNum
                        local oldCnt = tonumber (strmatch (cur[n] or "", "(%d+)/"))
                        local newCnt = tonumber (strmatch (desc, "(%d+)/"))
                        if oldCnt and newCnt then
                            if floor (oldCnt / num) == floor (newCnt / num) then
                                skip = true
                            end
                        end
                    end
                    if not skip and desc ~= cur[n] then
                        Nx.Com:Send ("P", desc)
--                        Nx.prt ("%s", desc)
                    end
                end
            end
        end
    end

--PAIDE!
end

-------------------------------------------------------------------------------
-- unused???
-------------------------------------------------------------------------------

function Nx.Quest:GetLongTitle (cur)

    local title = format ("[%d] %s", cur.Level, cur.Title)

    local quest = cur.Q
    if quest and quest.CNum then
        title = title .. format (L[" (Part %d of %d)"], quest.CNum, cur.CNumMax)
    end

    return title
end

function Nx.Quest:GetPartTitle (quest, cur)

    local s = ""

    if quest and quest.CNum then
        if cur then
            s = s .. format (L["(Part %d of %d)"], quest.CNum, cur.CNumMax)
        else
            s = s .. format (L["(Part %d)"], quest.CNum)
        end
    end

    return s
end

function Nx.Quest:FindCur (qId, qIndex)

    if type (qId) == "string" then    -- Quest title?

        for n, v in ipairs (self.CurQ) do
            if v.Title == qId then
                return n, v, qId
            end
        end

        return
    end

    if qIndex and qIndex > 0 and qId == 0 then
        local i, cur = self:FindCurByIndex (qIndex)
        return i, cur, cur.Title    -- Also return string type id
    end

    assert (qId > 0)

    for n, v in ipairs (self.CurQ) do
        if v.QId == qId then
            return n, v, qId
        end
    end
end

function Nx.Quest:FindCurByIndex (qi)
    assert (qi > 0)
    local curq = self.CurQ

    for n, v in ipairs (curq) do
        if v.QI == qi then
            return n, v
        end
    end
end

function Nx.Quest:FindCurFromOld (oldCur)

    for n, cur in ipairs (self.CurQ) do
        if cur.Title == oldCur.Title and cur.ObjText == oldCur.ObjText then
            return cur
        end
    end
end
