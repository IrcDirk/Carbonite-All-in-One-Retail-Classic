-- Carbonite.Quests | DataAndComm
-- Quest-data unpackers (the packed `(b)name|zone|loc` string format
-- Carbonite ships its bundled QuestData in), the quest hash + Blizzard
-- title/level/objective fuzzy-find used during the data-not-in-DB
-- fallback, party-quest com send/receive + sharing timer, and the
-- public data-access helpers (GetQuestOpts / unpack* / GetQuest /
-- SetQuest / ClearQuest / etc.). Lifted from NxQuest.lua to keep
-- the engine file smaller. Pure functions, no UI coupling.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals (mirrors NxQuest's prelude).
local bit_band   = bit.band
local bit_lshift = bit.lshift
local floor      = math.floor
local max        = math.max
local min        = math.min
local strfind    = strfind  or string.find
local strsub     = strsub   or string.sub
local strbyte    = strbyte  or string.byte
local format     = format   or string.format
local tinsert    = tinsert  or table.insert
local UnitLevel  = UnitLevel
local UnitName   = UnitName

-- Unpack quest info
-- Format: (b) is byte
--  name len (b), name str, side (b), level (b), min lvl (b), next id (b3), category (b)
-------------------------------------------------------------------------------

function Nx.Quest:Unpack (info)
    if not info then return end
    local name, side, lvl, minlvl, nextId, category, xp = Nx.Split("|",info)
    return name, tonumber(side), tonumber(lvl), tonumber(minlvl), tonumber(nextId), tonumber(category), tonumber(xp)
end

-------------------------------------------------------------------------------
-- Resolve a localized quest title with progressive fallback.
-- Order:
--   1. Live Blizzard cache (C_QuestLog.GetTitleForQuestID / GetQuestInfo).
--      Always returns the player's locale when populated.
--   2. Nx.QuestName[qId] — the offline lookup populated from
--      Carbonite.Quests/Data/<exp>/QuestName.lua plus the matching
--      QuestName_<locale>.lua patch (sourced from Questie's lookupQuests).
--   3. The static English `fallback` baked into the Quest header string.
-- On a live-cache miss we fire RequestLoadQuestByID once per id per session
-- so subsequent refreshes pick up the real localized title.
-------------------------------------------------------------------------------

function Nx.Quest:GetLocalizedName (qId, fallback)
    if not qId then
        return fallback
    end
    if C_QuestLog then
        if C_QuestLog.GetTitleForQuestID then
            local n = C_QuestLog.GetTitleForQuestID(qId)
            if n and n ~= "" then
                return n
            end
        elseif C_QuestLog.GetQuestInfo then
            local n = C_QuestLog.GetQuestInfo(qId)
            if n and n ~= "" then
                return n
            end
        end
        if C_QuestLog.RequestLoadQuestByID then
            self._requestedNames = self._requestedNames or {}
            if not self._requestedNames[qId] then
                self._requestedNames[qId] = true
                C_QuestLog.RequestLoadQuestByID(qId)
            end
        end
    end
    if Nx.QuestName and Nx.QuestName[qId] then
        return Nx.QuestName[qId]
    end
    return fallback
end

-------------------------------------------------------------------------------
-- Unpack quest name
-------------------------------------------------------------------------------

function Nx.Quest:UnpackName (info)
    local name, side, lvl, minlvl, nextId, category = Nx.Split("|",info)
    return name
end

-------------------------------------------------------------------------------
-- Unpack quest next id
-------------------------------------------------------------------------------

function Nx.Quest:UnpackNext (info)
    local name, side, lvl, minlvl, nextId, category = Nx.Split("|",info)
    return tonumber(nextId)
end

-------------------------------------------------------------------------------
-- Unpack quest category
-------------------------------------------------------------------------------

function Nx.Quest:UnpackCategory (info)
    local name, side, lvl, minlvl, nextId, category = Nx.Split("|",info)
    return tonumber(category)
end

-------------------------------------------------------------------------------
-- Unpack start/end
-- Format: name index (byte x2), zone (byte), location data (may start with space)
-- Example: 00,1, xxyy
-- Example: 00,1,xywh
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Resolve a Start/End packed string for the player's current city when the
-- quest has alternate spawns (Nx.QuestStartAlts / Nx.QuestEndAlts populated
-- for multi-city/multi-faction quests like the holiday turn-ins).
--
-- Picks, in order:
--   1. The alt whose UiMapID matches the player's current map.
--   2. The alt whose UiMapID belongs to the player's faction (capital
--      cities — see CITY_FACTION below).
--   3. The primary `Start`/`End` string already on the quest record.
-------------------------------------------------------------------------------

-- UiMapID → faction marker for the capital cities a multi-city quest can
-- land on. 1=Alliance, 2=Horde. Two conventions are mixed here because
-- Carbonite ships per-flavor RMapID sets:
--   * classic / tbc / wrath / cata use the legacy "1453-1958" range.
--   * mop / retail use the modern "84-110" range (matches Blizzard's
--     UiMapID system after the Cataclysm map revamp).
-- Each flavor only ever sees its own IDs at runtime, but the same
-- NxQuest.lua loads in all of them, so the table covers both.
-- Neutral hubs (Shattrath, Dalaran, Pandaren capitals) intentionally
-- absent — when the player is in one of those, the step 1 current-map
-- match handles them; otherwise the primary is used.
local CITY_FACTION = {
    -- Legacy / tbc-cata RMapIDs
    [1453] = 1,  -- Stormwind
    [1455] = 1,  -- Ironforge
    [1457] = 1,  -- Darnassus
    [1947] = 1,  -- The Exodar
    [1454] = 2,  -- Orgrimmar
    [1456] = 2,  -- Thunder Bluff
    [1458] = 2,  -- Undercity
    [1954] = 2,  -- Silvermoon City
    -- Modern / mop+ RMapIDs
    [84]   = 1,  -- Stormwind
    [87]   = 1,  -- Ironforge
    [89]   = 1,  -- Darnassus
    [103]  = 1,  -- The Exodar
    [85]   = 2,  -- Orgrimmar
    [86]   = 2,  -- Orgrimmar (alt instance map)
    [88]   = 2,  -- Thunder Bluff
    [90]   = 2,  -- Undercity
    [110]  = 2,  -- Silvermoon City
}

local function _pickAltSE (alts, primary)
    if not alts or alts == "" then
        return primary
    end
    -- Match player's current map first
    local Map = Nx.Map
    local curMap = Map and Map.GetCurrentMapId and Map:GetCurrentMapId() or 0
    -- Player faction byte (matches the side bitmask: 1=Alliance, 2=Horde)
    local plFact = 0
    if Nx.PlFactionNum == 0 then
        plFact = 1
    elseif Nx.PlFactionNum == 1 then
        plFact = 2
    end
    local factionFallback
    for entry in (alts .. ";"):gmatch ("([^;]+);") do
        local _, m = strsplit ("|", entry)
        m = tonumber (m) or 0
        if m == curMap then
            return entry
        end
        if not factionFallback and plFact > 0 and CITY_FACTION[m] == plFact then
            factionFallback = entry
        end
    end
    return factionFallback or primary
end

function Nx.Quest:ResolveStart (qId)
    local quest = qId and Nx.Quests and Nx.Quests[qId]
    local primary = quest and quest["Start"]
    local alts = Nx.QuestStartAlts and Nx.QuestStartAlts[qId]
    return _pickAltSE (alts, primary)
end

function Nx.Quest:ResolveEnd (qId)
    local quest = qId and Nx.Quests and Nx.Quests[qId]
    local primary = quest and quest["End"]
    local alts = Nx.QuestEndAlts and Nx.QuestEndAlts[qId]
    return _pickAltSE (alts, primary)
end

function Nx.Quest:UnpackSE (obj)
    if not obj then
        return
    end
--    Nx.prt("checking quest obj %s", obj)
    local i, zone, typ, x, y = Nx.Split("|",obj)
--    Nx.prt("npc id should be %s", i)
    local name
    local id = tonumber(i)
    if id then
        -- New schema: ID lookup walks NPC → Object → Item, with a
        -- fall-through to the legacy combined Nx.QuestStartEnd table
        -- so unmigrated expansion data still resolves. The split tables
        -- are populated from Questie/ATT for expansions where the
        -- Carbonite.Quests/Data/<flavor>/QuestStartEnd*.lua files exist.
        name = (Nx.QuestStartEndNPC and Nx.QuestStartEndNPC[id])
            or (Nx.QuestStartEndObject and Nx.QuestStartEndObject[id])
            or (Nx.QuestStartEndItem   and Nx.QuestStartEndItem[id])
            or (Nx.QuestStartEnd       and Nx.QuestStartEnd[id])
    elseif i and i ~= "" then
        -- Synthesized entries from PatchQuestFromBlizzard write the
        -- quest title in the first field instead of a numeric NPC id
        -- (Blizzard's API doesn't expose the giver's id for live data).
        name = i
    end

    if not name then
        name = "?"
    end

    if #obj == 2 then
        return name
    end
    return name, tonumber(zone), tonumber(typ), tonumber(x), tonumber(y)
end

-------------------------------------------------------------------------------
-- Unpack objective or start/end
-- Format: name length (byte), name string, zone (byte), location data (may start with space)
-- Example: 3,the,1, xxyy
-- Example: 3,end,1,xywh
-------------------------------------------------------------------------------

function Nx.Quest:UnpackObjective (obj)

    if not obj then
        return
    end
    local desc, zone = Nx.Split("|",obj)
    return desc, tonumber(zone)
end

-------------------------------------------------------------------------------
-- Get type of objective (not start/end)
-------------------------------------------------------------------------------

function Nx.Quest:GetObjectiveType (obj)

    local desc, zone, typ = Nx.Split("|",obj)
    typ = tonumber(typ)
    if typ <= 33 then  -- Points
        return 0
    end

    return 1        -- Spans
end

-------------------------------------------------------------------------------
-- Get centered position of start/end
-------------------------------------------------------------------------------

function Nx.Quest:GetSEPos (str)

    local name, zone, typ, x, y = self:UnpackSE (str)

    if zone then
        return name, tonumber(zone), self:GetPosLoc (str)        -- x, y
    end
end

-------------------------------------------------------------------------------
-- Get centered position of objective
-------------------------------------------------------------------------------

function Nx.Quest:GetObjectivePos (str)

    local name, zone, typ, x, y = self:UnpackObjective (str)

    if zone then
        return name, tonumber(zone), self:GetPosLoc (str)        -- x, y
    end
end

-------------------------------------------------------------------------------
-- Get centered position from location string
-------------------------------------------------------------------------------

function Nx.Quest:GetPosLoc (str)

    local cnt = 0
    local ox = 0
    local oy = 0

    if type(str) == "table" then
        for i = 1,32 do
            if str[i] then
                local desc, zone, typ, x, y, w, h = Nx.Split("|",str[i])
                if tonumber(typ) == 32 then
                    cnt = i
                    ox = ox + tonumber(x)
                    oy = oy + tonumber(y)
                elseif tonumber(typ) == 33 then
                    cnt = 1
                    ox, oy = self:UnpackLocPtRelative (str, loc + 1)
                else
                    w = tonumber(w) / 1002 * 100
                    h = tonumber(h) / 668 * 100
                    local area = w * h
                    cnt = cnt + area
                    ox = ox + (tonumber(x) + w * .5) * area
                    oy = oy + (tonumber(y) + h * .5) * area
                end
            end
        end
    elseif type(str) == "string" then
        local desc, zone, typ, x, y, w, h = Nx.Split("|",str)
        if tonumber(typ) == 32 then
            cnt = 1
            ox = ox + tonumber(x)
            oy = oy + tonumber(y)
        elseif tonumber(typ) == 33 then
            cnt = 1
            ox, oy = self:UnpackLocPtRelative (str, loc + 1)
        else
            w = tonumber(w) / 1002 * 100
            h = tonumber(h) / 668 * 100
            local area = w * h
            cnt = cnt + area
            ox = ox + (tonumber(x) + w * .5) * area
            oy = oy + (tonumber(y) + h * .5) * area
        end
    end

    ox = ox / cnt
    oy = oy / cnt
    return ox, oy
end

-------------------------------------------------------------------------------
-- Calc watch distance
-------------------------------------------------------------------------------

function Nx.Quest:CalcDistances (n1, n2)

    local Nx = Nx
    local Quest = Nx.Quest
    local qopts = Nx.Quest:GetQuestOpts()
    local Map = Nx.Map
    local map = Map:GetMap (1)
    local px = map.PlyrX
    local py = map.PlyrY
    local playerLevel = UnitLevel ("player")

    local curq = self.CurQ
    if not curq then    -- Bad stuff?
        return
    end

    for n = n1, n2 do

        local cur = curq[n]

        if not cur then
            break
        end

        local qi = cur.QI
        local qId = cur.QId

        local id = qId > 0 and qId or cur.Title
        local qStatus = Nx.Quest:GetQuest (id)
        local qWatched = (qStatus == "W")
        local quest = cur.Q

        cur.Priority = 1
        cur.Distance = 999999999
        cur.CloseObjI = -1

        if cur.Complete and cur.IsAutoComplete then
            cur.Distance = 0
        end

--        if quest and (qWatched or Nx.Free) then
        if quest then

            local cnt = (cur.CompleteMerge or cur.LBCnt == 0) and 0 or 99
            for qObj = 0, cnt do

                local questObj

                if qObj == 0 then
                    questObj = (qi > 0 or cur.Party) and quest["End"] or quest["Start"]    -- Start if goto or no end?
                else
                    if quest["Objectives"] then
                        questObj = quest["Objectives"][qObj]
                    end
                end

                if not questObj then
                    break
                end

                if bit_band (cur.TrackMask, bit_lshift (1, qObj)) > 0 then

                    local _, zone, loc

                    if qObj == 0 then
                        _, zone, loc = self:UnpackSE (questObj)
                    else
                        if (type (questObj) == "table") then
                            _, zone = self:UnpackObjective (questObj[1])
                        else
                            _, zone = self:UnpackObjective (questObj)
                        end
                    end

                    if zone then

                        local mId = zone
                        if mId and mId ~= 9000 then
                            local x, y = self:GetClosestObjectivePos (questObj, loc, mId, px, py)
                            if not x or not y then
                                return
                            end
                            local dist = ((x - px) ^ 2 + (y - py) ^ 2) ^ .5

                            if dist < cur.Distance then
                                cur.CloseObjI = qObj
                                cur.Distance = dist
                            end
                            cur["OX"..qObj] = x
                            cur["OY"..qObj] = y
                            cur["OD"..qObj] = dist
                        end
                    end
                end
            end

--PAIDS!
            local pri = 0

            -- Player lvl 30. PriLevel = 20
            -- Q1  100 Lvl 30: 0 ldif = 0
            -- Q2  400 Lvl 20: 10 ldif = 200, .1, 90% = 360
            -- Q3 2000 Lvl 25: 5 ldif = 100, .05, 95% = 1900

            -- Player lvl 30. PriLevel = 200
            -- Q1  100 Lvl 30: 0 ldif = 0
            -- Q2  400 Lvl 20: 10 ldif = 2000, .99, 1% = 4
            -- Q3 2000 Lvl 25: 5 ldif = 1000, .5, 50% = 1000

            -- Formula: cur.Distance * priDist * cur.Priority * 10 + cur.Priority * 100

            if cur.CompleteMerge then
                pri = qopts.NXWPriComplete * 8    -- +-1600

            else
                -- 20 default. 10 lvls max diff * 200 = +-2000
                local l = min (playerLevel - cur.Level, 10)
                l = max (l, -10)
                pri = l * qopts.NXWPriLevel
            end

            cur.Priority = 1 - pri / 2010

            cur.InZone = Quest:CheckShow (map.UpdateMapID, qId)
--PAIDE!
        end
    end
end

-------------------------------------------------------------------------------
-- Get closest position of objective or start/end
-------------------------------------------------------------------------------

-- Returns (closeX, closeY, closeMapId). `closeMapId` is the zone of the
-- entry that won the distance race, which can differ from the caller's
-- `mapId` when a multi-zone Objectives[] list mixes zones (e.g. kill
-- areas spanning a zone border). TrackOnMap relies on the third return
-- to set the goto target's mapId, otherwise CalcTracking sees src vs
-- dst on different maps and the router detours through whatever
-- transit zone connects them.
function Nx.Quest:GetClosestObjectivePos (str, loc, mapId, px, py)
    local Map = Nx.Map
    if type(str) == "string" then
        local npc, zone, typ = Nx.Split("|",str)
        if tonumber(typ) <= 33 then  -- Point
            local x1, y1, x2, y2 = self:GetObjectiveRect (str, loc)
            x1, y1 = Map:GetWorldPos (mapId, (x1 + x2) / 2, (y1 + y2) / 2)
            return x1, y1, mapId
        else -- Multiple locations
            local closeDist = 999999999
            local closeX, closeY
            loc = loc - 1
            local loopCnt = floor ((#str - loc) / 4)
            cnt = 0
            for locN = loc + 1, loc + loopCnt * 4, 4 do
                local x, y
                local loc1 = strsub (str, locN, locN + 3)
                assert (loc1 ~= "")
                local x, y, w, h = Nx.Quest:UnpackLocRect (loc1)
                w = w / 1002 * 100
                h = h / 668 * 100
                local wx1, wy1 = Map:GetWorldPos (mapId, x, y)
                local wx2, wy2 = Map:GetWorldPos (mapId, x + w, y + h)
                x = wx1        -- Top left
                y = wy1
                if px >= wx1 and px <= wx2 then
                    if py >= wy1 and py <= wy2 then        -- Within span?
                        return px, py, mapId
                    end
                    x = px
                elseif px >= wx2 then    -- Right of span?
                    x = wx2
                end
                if py >= wy1 then        -- Y within span?
                    y = py
                end
                if py >= wy2 then    -- Below span?
                    y = wy2
                end
                local dist = (x - px) ^ 2 + (y - py) ^ 2
                if dist < closeDist then
                    closeDist = dist
                    closeX = x
                    closeY = y
                end
            end
            return closeX, closeY, mapId
        end
    elseif type(str) == "table" then
        local closeDist = 999999999
        local closeX, closeY, closeMapId
        cnt = 0
        for a,b in pairs(str) do
            local npc,zone,typ,x, y, w, h = Nx.Split ("|",b)
            local poiTyp = tonumber(typ) or 35
            local poiMap = tonumber(zone) or mapId
            local pX = tonumber(x); local pY = tonumber(y)
            -- Skip sentinel entries with mapId=0 (PatchQuestFromBlizzard
            -- writes these when live coords aren't available yet).
            if not pX or not pY or poiMap == 0 then
                -- skip
            elseif poiTyp <= 33 then
                -- Point: compare against the bare coord, no bounding box.
                -- Mixing typ 32 entries into a list (after our refactor
                -- to have point + span coexist per objective) used to be
                -- silently treated as a span with leftover w/h, which
                -- offset goto targets to a phantom corner of the box.
                local wx, wy = Map:GetWorldPos (poiMap, pX, pY)
                if wx and wy then
                    local dist = (wx - px) ^ 2 + (wy - py) ^ 2
                    if dist < closeDist then
                        closeDist = dist
                        closeX = wx
                        closeY = wy
                        closeMapId = poiMap
                    end
                end
            else
            w = (tonumber(w) or 0) / 1002 * 100
            h = (tonumber(h) or 0) / 668 * 100
            local wx1, wy1 = Map:GetWorldPos (poiMap, pX, pY)
            local wx2, wy2 = Map:GetWorldPos (poiMap, pX + w, pY + h)
            x = wx1        -- Top left
            y = wy1
            if px >= wx1 and px <= wx2 then
                if py >= wy1 and py <= wy2 then        -- Within span?
                    return px, py, poiMap
                end
                x = px
            elseif px >= wx2 then    -- Right of span?
                x = wx2
            end
            if py >= wy1 then        -- Y within span?
                y = py
            end
            if py >= wy2 then    -- Below span?
                y = wy2
            end
            local dist = (x - px) ^ 2 + (y - py) ^ 2
            if dist < closeDist then
                closeDist = dist
                closeX = x
                closeY = y
                closeMapId = poiMap
            end
            end -- end of else (span) branch
        end
        return closeX, closeY, closeMapId
    end
end

-------------------------------------------------------------------------------
-- Get size of objective or start/end
-------------------------------------------------------------------------------

function Nx.Quest:GetObjectiveRect (str, loc)

    local Quest = Nx.Quest

    local x1 = 100
    local y1 = 100
    local x2 = 0
    local y2 = 0
    local cnt

    if type(str) == "string" then
        local desc,zone,typ,x,y,w,h = Nx.Split("|",str)
        if tonumber(typ) == 32 then
          x1 = min (x1, x)
          x2 = max (x2, x)
          y1 = min (y1, y)
          y2 = max (y2, y)
        end
    else
        if tonumber(typ) == 32 then  -- Point
        cnt = 0
        local x, y
        for locN = loc + 1, loc + cnt * 4, 4 do

--            local loc1 = strsub (str, locN, locN + 3)
--            assert (loc1 ~= "")

            x, y = Nx.Map:UnpackLocPtOff (str, locN)
            x1 = min (x1, x)
            y1 = min (y1, y)
            x2 = max (x2, x)
            y2 = max (y2, y)
        end

    elseif strbyte (str, loc) == 33 then  -- Point

        x1, y1 = Nx.Map:UnpackLocPtRelative (str, loc + 1)
        x2, y2 = x1, y1

    else -- Multiple locations

        loc = loc - 1

        cnt = floor ((#str - loc) / 4)

        for locN = loc + 1, loc + cnt * 4, 4 do

            local loc1 = strsub (str, locN, locN + 3)
--            assert (loc1 ~= "")

            local x, y, w, h = Nx.Quest:UnpackLocRect (loc1)

            x1 = min (x1, x)
            y1 = min (y1, y)
            x2 = max (x2, x + w / 1002 * 100)
            y2 = max (y2, y + h / 668 * 100)

--            Nx.prt ("Rect %f %f %f %f", x, y, w, h)
        end
    end

--    Nx.prt ("RectMinMax %f %f %f %f", x1, y1, x2, y2)
    end
    return x1, y1, x2, y2
end

-------------------------------------------------------------------------------
-- Calculate first level 24 bit quest hash
-------------------------------------------------------------------------------

--[[
function Nx.Quest:Hash (title, level)

    local str = title..level
    local h1 = 0
    local h2 = 0
    local h3 = 0
    local b1
    local b2
    local b3

    local strLen = #str
    local len = floor (strLen / 3) * 3

--    Nx.prt (format ("Hash %d %d"))

    for n = 1, len, 3 do

        b1, b2, b3 = strbyte (str, n, n + 2)
        h1 = h1 + b1
        h2 = h2 + b2
        h3 = h3 + b3
    end

    if strLen - len == 1 then
        h1 = h1 + strbyte (str, strLen)

    elseif strLen - len == 2 then
        h1 = h1 + strbyte (str, strLen - 1)
        h2 = h2 + strbyte (str, strLen)
    end

    return bit_band (h1, 0xff) + bit_band (h2, 0xff) * 0x100 + bit_band (h3, 0xff) * 0x10000
end
--]]

-------------------------------------------------------------------------------
-- Find quest in quests data from Blizzard title, level, description and objective
-------------------------------------------------------------------------------

--[[
function Nx.Quest:Find (title, level, desc, obj)

    local hash = self:Hash (title, level)

    local quest = Nx.Quests[hash]

    if quest then

        local hashPat = self:UHash (quest[1])
        if #hashPat > 0 then

            local found

            for n = 1, #hashPat, 4 do

                local mode = strbyte (hashPat, n, n)
                local off = tonumber (strsub (hashPat, n + 1, n + 2), 16) + 1
                local match = strsub (hashPat, n + 3, n + 3)

--                Nx.prt ("QFind #%d %d %d %s", n, mode, off, match)

                if mode == 48 then

                    found = strsub (obj, off, off) == match

                elseif mode == 49 then

                    found = strsub (obj, -off, -off) == match

                elseif mode == 50 then

                    found = strsub (desc, off, off) == match

                elseif mode == 51 then

                    found = strsub (desc, -off, -off) == match

                elseif mode >= 97 then

                    local cnt = mode - 96
                    local match = ","

                    if mode >= 103 then
                        cnt = mode - 102
                        match = "."
                    end

                    local i = 1
                    for findN = 1, cnt do
                        i = strfind (desc, match, i)
                        if not i then
                            break
                        end
                        i = i + 1
                    end

                    if i then
                        off = off + i - 1
                        found = strsub (desc, off, off) == match
                    end

                else
                    Nx.prt (L["QFind bad mode %d"], mode)

                end

                if found then
                    return Nx.Quests[hash + (n - 1) / 4 * 0x1000000]
                end

            end

            quest = nil
        end
    end

    if not quest then

        if level > 0 then    -- Only recurse once
            -- Quest level my be -1, so Jamie exports as 0
            return self:Find (title, 0, desc, obj)
        end

        if Nx.Quest.Debug then
            Nx.prt (L["QFind Failed to find"] .. "%s %d", title, level)
        end
    end

    return quest
end
--]]

-------------------------------------------------------------------------------
-- Com send / rcv
-------------------------------------------------------------------------------

function Nx.Quest:BuildComSend()

    local _
    local cur = self.Watch.ClosestCur
    local obj = 0
    local flgs = 2            -- Not a targeted quest flag

    if self.QLastChanged then    -- Quest change? Com nils this once send to zone

        cur = self.QLastChanged
--        Nx.prt ("Q Send Change %s", cur.Title)

    else
        local typ, tid = Nx.Map:GetTargetInfo()
        if typ == "Q" then

            local qid = floor (tid / 100)
            _, cur = self:FindCur (qid)
            obj = tid % 100
            flgs = 0
        end
    end

    if cur then

        if cur.Complete then
            flgs = flgs + 1
        end

        local str = format ("%04x%c%c%c", cur.QId, obj+35, flgs+35, cur.LBCnt+35)

        for n = 1, cur.LBCnt do

            local s1, _, cnt, total = strfind (cur[n], "(%d+)/(%d+)")
            if s1 then
                total = tonumber (total)
                if total > 50 then
                    cnt = cnt / total * 60
                    total = 60
                end
                cnt = cnt + 2
            else
                cnt = 0
                if cur[n + 100] then        -- Done?
                    cnt = 1
                end
                total = 0
            end

            str = str .. format ("%c%c", cnt + 35, total + 35)
        end

--        Nx.prt ("QSend %s", str)

        return str, 4
    end

    return "", 0
end

function Nx.Quest:DecodeComRcv (info, msg)

    --    msg = "0000###"
    if not msg or #msg < 7 then    -- Too short?
        return    -- error, so nil length
    end

    local lbcnt = strbyte (msg, 7) - 35

    if not self.Enabled then
        return 7 + lbcnt * 2        -- Message length
    end

    local qId = tonumber (strsub (msg, 1, 4), 16) or 0
    local quest = Nx.Quests[qId]
    if not quest then                        -- Unknown quest?
        if Nx.Com.PalsInfo[Nx.qTEMPname] ~= nil then
          Nx.Com.PalsInfo[Nx.qTEMPname].QStr = format ("\n" ..L["Quest"] .. " %s", qId)
        end
        if Nx.Com.ZPInfo[Nx.qTEMPname] ~= nil then
            Nx.Com.ZPInfo[Nx.qTEMPname].QStr = format ("\n" ..L["Quest"] .. " %s", qId)
        end
        return
    end
    if not quest[1] then
        if Nx.Com.PalsInfo[Nx.qTEMPname] ~= nil then
          Nx.Com.PalsInfo[Nx.qTEMPname].QStr = format ("\n" ..L["Quest"] .. " %s", qId)
        end
        if Nx.Com.ZPInfo[Nx.qTEMPname] ~= nil then
            Nx.Com.ZPInfo[Nx.qTEMPname].QStr = format ("\n" ..L["Quest"] .." %s", qId)
        end
        return
    end
    local name, side, lvl = self:Unpack (quest[1])

    local obji = strbyte (msg, 5) - 35
    local flgs = strbyte (msg, 6) - 35

    local targetStr = ""

    if bit_band (flgs, 2) == 0 then
        targetStr = "*"
    end

    local str = format ("\n|r%s%d |cffcfcf0f%s", targetStr, lvl, name)

    if bit_band (flgs, 1) > 0 then
        str = str .. L[" (Complete)"]
    end

    if #msg >= 7 + lbcnt * 2 then

        for n = 1, lbcnt do
            local off = (n - 1) * 2
            local cnt = strbyte (msg, 8 + off) - 35
            local total = strbyte (msg, 9 + off) - 35

            local obj = quest["Objectives"]
            if obj and obj[n] then
                obj = quest["Objectives"][n]
                local oname = self:UnpackObjective (obj)

                if obji == n then
                    oname = "|cffcfcfff" .. oname
                else
                    oname = "|cffafafaf" .. oname
                end

                if cnt == 0 then
                    str = str .. format ("\n  %s", oname)
                elseif cnt == 1 then
                    str = str .. format ("\n  %s " ..L["(done)"], oname)
                else
                    str = str .. format ("\n  %s %d/%d", oname, cnt - 2, total)
                end
            end
        end

--    else
--        Nx.prt ("DecodeComRcv error quest %s", qId)

    end

    if Nx.Com.PalsInfo[Nx.qTEMPname] ~= nil then
      Nx.Com.PalsInfo[Nx.qTEMPname].QStr = str
    end
    if Nx.Com.ZPInfo[Nx.qTEMPname] ~= nil then
      Nx.Com.ZPInfo[Nx.qTEMPname].QStr = str
    end
    return 7 + lbcnt * 2        -- Message length
end

-------------------------------------------------------------------------------
-- Party quests
-------------------------------------------------------------------------------

function Nx.Quest.OnParty_members_changed()
    if not Nx.Quest.Initialized then
        return
    end
    local self = Nx.Quest

--    Nx.prt ("OnParty_members_changed")


    self.Watch:ShowUpdate()


    local pq = self.PartyQ

    for name in pairs (pq) do

        local found

        for n = 1, GetNumSubgroupMembers() do

            local pname = UnitName ("party" .. n)
            if name == pname then
                found = true
                break
            end
        end

        if not found then
            pq[name] = nil
--            Nx.prt ("Old %s", name)

            QPartyUpdate = Nx:ScheduleTimer(self.PartyUpdateTimer,1,self)
        end
    end

    if IsInRaid() then    -- In raid?
        return
    end

    if GetNumSubgroupMembers() == 0 then    -- Left party?
        return
    end

    local doSend

    for n = 1, GetNumSubgroupMembers() do

        local unit = "party" .. n
        local name = UnitName (unit)

        if not pq[name] then
            doSend = true
            pq[name] = {}
--            Nx.prt ("New %s %s", unit, name)
        end
    end

    if doSend then
        self:PartyStartSend()
    end
end

-------------------------------------------------------------------------------
-- Handle party message
-------------------------------------------------------------------------------

local pmsg_elapsed = 0
local pmsg_lasttime
local pmsg_ttl = 9999

-------------------------------------------------------------------------------
-- Return one canonical objective-progress string for party synchronization.
--
-- Modern clients can put the numeric progress at the start of objective.text,
-- while older clients commonly put it at the end. Carbonite's party protocol
-- also carries the numeric values separately. Strip matching edge tokens before
-- appending the protocol values so repeated send/receive passes cannot turn
-- "1/1 Objective" into "1/1 Objective: 1/1".
-------------------------------------------------------------------------------

function Nx.Quest:NormalizeObjectiveProgressText (text, count, required)
    if type (text) ~= "string" then
        text = "?"
    end

    count = tonumber (count)
    required = tonumber (required)

    text = string.match (text, "^%s*(.-)%s*$") or text

    if not count or not required or required <= 0 then
        return text ~= "" and text or "?"
    end

    local token = tostring (count) .. "%s*/%s*" .. tostring (required)
    local previous

    repeat
        previous = text

        -- Count-first forms: "1/1 Objective", "(1/1) Objective", etc.
        text = string.gsub (text, "^%s*" .. token .. "%s*:?%s*", "", 1)
        text = string.gsub (text, "^%s*%(" .. token .. "%)%s*:?%s*", "", 1)
        text = string.gsub (text, "^%s*%[" .. token .. "%]%s*:?%s*", "", 1)

        -- Count-last forms: "Objective: 1/1", "Objective (1/1)", etc.
        text = string.gsub (text, "%s*:%s*" .. token .. "%s*$", "", 1)
        text = string.gsub (text, "%s*%(" .. token .. "%)%s*$", "", 1)
        text = string.gsub (text, "%s*%[" .. token .. "%]%s*$", "", 1)
        text = string.gsub (text, "%s+" .. token .. "%s*$", "", 1)

        text = string.match (text, "^%s*(.-)%s*$") or text
    until text == previous

    if text == "" then
        text = "?"
    end

    return format ("%s: %d/%d", text, count, required)
end

function Nx.Quest:OnPartyMsg (plName, msg)

    if Nx.qdb and Nx.qdb.profile and not Nx.qdb.profile.Quest.PartyShare then
        return
    end

    local msgA = {Nx.Split("|", msg)}

    msg = msgA[1]

    -- msg = "Qp1iiiifo111122223333"

--    Nx.prt ("OnPartyMsg %s: %s", plName, msg)

    local pq = self.PartyQ or {}
    local pl = pq[plName]

    if pl then

        if strbyte (msg, 3) == 49 then    -- "1" clear?
            pl = {}
            pq[plName] = pl
        end

        local Quest = Nx.Quest
        local off = 4

        for n = 1, 99 do

            if #msg < off + 5 then    -- No more?
                break
            end

            local qId = tonumber (strsub (msg, off, off + 3), 16) or 0
            local flgs, oCnt = strbyte (msg, off + 4, off + 5)
            flgs = flgs - 35
            oCnt = oCnt - 35

            if #msg < off + 5 + oCnt * 4 then    -- Too short?
                break
            end

            local quest = Nx.Quests[qId]
            if quest then

                local q = pl[qId] or {}
                pl[qId] = q

                q.Complete = bit_band (flgs, 1) == 1 and 1 or nil

    --            Nx.prt ("%s: %s %x %s", plName, qId, flgs, oCnt)

                for i = 1, oCnt do

                    local desc, done = Nx.Split("^", msgA[i + 1])

                    local o = off + 6 + (i - 1) * 4
                    local cnt = tonumber (strsub (msg, o, o + 1), 16) or 0
                    local total = tonumber (strsub (msg, o + 2, o + 3), 16) or 0

                    desc = self:NormalizeObjectiveProgressText (desc, cnt, total)

                    q[i] = cnt
                    q[i + 100] = total
                    q[i + 200] = desc
                    q[i + 300] = done == 1 and true or false
                end
            end

            off = off + 6 + oCnt * 4
        end
    end

    if pmsg_lasttime then
        local curtime = debugprofilestop()
        pmsg_elapsed = curtime - pmsg_lasttime
        pmsg_lasttime = curtime
    else
        pmsg_lasttime = debugprofilestop()
    end
    pmsg_ttl = pmsg_ttl + pmsg_elapsed
    if pmsg_ttl < 2000 then
        return
    end
    pmsg_ttl = 0

    QPartyUpdate = Nx:ScheduleTimer(self.PartyUpdateTimer,.5,self)
end

---
-- Timer callback for party quest updates
--
function Nx.Quest:PartyUpdateTimer()
    self:RecordQuests(0)
    self.Watch:Update()
end

-------------------------------------------------------------------------------
-- PARTY QUEST SHARING
-- Share quest progress with party members
-------------------------------------------------------------------------------

---
-- Start sending quest data to party
--
function Nx.Quest:PartyStartSend()

    if IsInRaid() or GetNumSubgroupMembers() == 0 then
        return
    end

    if Nx.qdb.profile.Quest.PartyShare then
        QSendParty = Nx:ScheduleTimer(self.PartyBuildSendData,.5,self)
    end
end

local PartySendTimer
function Nx.Quest:PartyBuildSendData()

    local data = {}

    self.PartySendData = data
    self.PartySendDataI = 1

    local sendStr = ""

    for n, cur in ipairs (self.CurQ) do

        local qId = cur.QId

        if not cur.Goto and Nx.Quest:GetQuest (qId) == "W" then

            local flgs = 0

            if cur.Complete then
                flgs = flgs + 1
            end

            local str = format ("%04x%c%c", qId, flgs + 35, cur.LBCnt + 35)
            local strO = ""

            for n = 1, cur.LBCnt do

                local _, _, parsedCnt, parsedTotal = strfind (cur[n] or "", "(%d+)%s*/%s*(%d+)")
                local _, _, _, liveCnt, liveTotal = self:GetQuestObjectiveInfo (qId, n, false)
                local cnt = tonumber (liveCnt) or tonumber (parsedCnt) or 0
                local total = tonumber (liveTotal) or tonumber (parsedTotal) or 0

                local desc, done = self:CalcDesc (qId, n, cnt, total, cur[n])

                if cnt and total then
                    if cnt > 200 then
                        cnt = 200
                    end
                else
                    cnt = 0
                    if cur[n + 100] then        -- Done?
                        cnt = 1
                    end
                    total = 0
                end

                str = str .. format ("%02x%02x", cnt, total)

                if desc then
                    strO = strO .. "|" .. desc .. "^" .. (done and 1 or 0)
                end
            end

            sendStr = sendStr .. str .. strO


            tinsert (data, sendStr)
            sendStr = ""
        end
    end

    PartySendTimer = Nx:ScheduleRepeatingTimer(self.PartySendTimer,0,self)

    return 0
end

function Nx.Quest:PartySendTimer()

    local qi = self.PartySendDataI
    local data = self.PartySendData[qi]

    if data then
        local s = qi == 1 and "1" or " "
        Nx.Com:Send ("p", "Qp" .. s .. data)
--        Nx.prt ("PQSend %s", data)
    end

    self.PartySendDataI = qi + 1

    if not self.PartySendData[self.PartySendDataI] then
        Nx:CancelTimer(PartySendTimer)
    end
end

-------------------------------------------------------------------------------
-- QUEST DATA ACCESS FUNCTIONS
-------------------------------------------------------------------------------

---
-- Get quest options table
-- @return  Quest options profile table
--
function Nx.Quest:GetQuestOpts()
    return Nx.qdb.profile.QuestOpts
end

---
-- Unpack objective data from string format
-- @param obj  Objective string
-- @return     desc, zone, typ
--
function Nx.Quest:UnpackObjectiveNew(obj)
    if not obj then
        return
    end
    if type(obj) == "table" then
        obj = obj[1]
    end
    local desc, zone, typ = Nx.Split("|",obj)
    return desc, tonumber(zone), tonumber(typ)
end

---
-- Unpack location rectangle from string
-- @param locStr  Location string
-- @return        x, y, w, h
--
function Nx.Quest:UnpackLocRect(locStr)
    local _, _, _, x, y, w, h = Nx.Split("|", locStr)
    return tonumber(x), tonumber(y), tonumber(w), tonumber(h)
end

---
-- Unpack location point offset from string
-- @param locStr  Location string
-- @return        x1, x2, y1, y2
--
function Nx.Quest:UnpackLocPtOff(locStr)
    if type(locStr) == "string" then
        local _,_,_,x1,x2,y1,y2 = Nx.Split("|",locStr)
        return tonumber(x1), tonumber(x2), tonumber(y1), tonumber(y2)
    else
        local _,_,_,x1,x2,y1,y2 = Nx.Split("|",locStr[1])
        return tonumber(x1), tonumber(x2), tonumber(y1), tonumber(y2)
    end
end

---
-- Get quest status for character
-- @param qId  Quest ID
-- @return     status, time
--
function Nx.Quest:GetQuest(qId)
    local quest = Nx.Quest.CurCharacter.Q[qId]
    if not quest then
        return
    end
    if type(quest) == "table" then
        Nx.Quest.CurCharacter.Q[qId] = ""
        return
    end
    local s1, s2, status, time = strfind(quest, "(%a)(%d+)")
    return status, time
end

---
-- Set quest status for character
-- @param qId      Quest ID
-- @param qStatus  Quest status
-- @param qTime    Quest time
--
function Nx.Quest:SetQuest(qId, qStatus, qTime)
    qTime = qTime or 0
    Nx.Quest.CurCharacter.Q[qId] = qStatus .. qTime
end

---
-- Clear quest data for character
-- @param qId  Quest ID
--
function Nx.Quest:NullQuest(qId)
    Nx.Quest.CurCharacter.Q[qId] = ""

    if Nx.Quest.Tracking[qId] then
        Nx.Quest.Tracking[qId] = nil
    end
end

---
-- Get quest ID from log location
-- @param loc  Quest log index
-- @return     Quest ID
--
function Nx.Quest:GetQuestID(loc)
    local _, _, _, _, _, _, _, questId, _, _, _, _, _, _ = GetQuestLogTitle(loc)
    return questId
end
