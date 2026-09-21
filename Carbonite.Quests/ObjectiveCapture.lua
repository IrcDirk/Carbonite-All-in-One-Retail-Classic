-- Carbonite.Quests | ObjectiveCapture
-- Runtime recorder for what a quest is actually made of: who hands it out,
-- who takes it back, and for every objective what satisfied it - which mob
-- died, which item dropped and off what, which object got looted, and where
-- on the map it happened.
--
-- The legacy recorder (Detection.lua `Nx.Quest:Capture`, SavedVariable
-- `NXQuest.Gather`) only ever stored packed giver/ender strings plus the
-- coordinates where an objective ticked. It has no idea *what* ticked it, so
-- rebuilding a quest database from it means guessing. This module writes a
-- plain, self-describing table instead (`NXQuest.Cap2`), so the offline
-- converters in ~/gamedev/QuestNPC can read it without a bespoke parser.
--
-- Correlation is deliberately simple: every kill / loot / object interaction
-- is pushed onto a short ring buffer with a timestamp, and when an objective
-- counter goes up we blame the most recent cause of a matching kind. That is
-- how the game presents it to the player as well, and it survives the cases
-- where several objectives advance from one loot window.
--
-- Public API:
--   ObjCap:IsEnabled()
--   ObjCap:SetEnabled(on)
--   ObjCap:Stats()                  - counts for the slash command
--   ObjCap:Wipe()
-- Slash: /carb qcap [on|off|stats|wipe]

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

local Carbonite = _G.Carbonite

local ObjCap = {}
Nx.Quest.ObjCap = ObjCap

-- WoW globals aliased as locals.
local floor     = math.floor
local abs       = math.abs
local time      = time
local GetTime   = GetTime
local format    = format   or string.format
local strsplit  = strsplit
local tonumber  = tonumber
local pairs, ipairs = pairs, ipairs
local UnitGUID  = UnitGUID
local UnitName  = UnitName
local UnitLevel = UnitLevel
local UnitFactionGroup = UnitFactionGroup
local UnitClass = UnitClass
local UnitRace  = UnitRace
local C_Map     = C_Map
local C_QuestLog = C_QuestLog

-- How long after a kill/loot we still consider it the cause of an objective
-- tick. Server-side credit for a group kill can lag a second or two.
local CAUSE_WINDOW  = 4.0
-- Ring buffer length. One loot window can carry a dozen items.
local CAUSE_KEEP    = 32
-- Per-entry position samples. Enough to see a spawn area, small enough that
-- a long play session does not bloat the SavedVariables file.
local MAX_POS       = 12
-- Two samples closer than this (in map percent) count as the same spot.
local POS_GRID      = 0.6
local TALK_GRID     = 0.15
local MAX_TALK      = 64
local SV_VERSION    = 2
-- Quest-log rescans are coalesced; QUEST_LOG_UPDATE can fire in bursts.
local SCAN_DELAY    = 0.25

-------------------------------------------------------------------------------
-- SavedVariables
-------------------------------------------------------------------------------

local function db()
    local sv = _G.NXQuest
    if not sv then return nil end

    local d = sv.Cap2
    if not d or d.Version ~= SV_VERSION then
        local why
        if not d then
            why = "no Cap2 in SavedVariables at first use"
        else
            why = format("format version %s, expected %s",
                tostring(d.Version), tostring(SV_VERSION))
            local n = 0
            for _ in pairs(d.Q or {}) do n = n + 1 end
            why = format("%s (parked %d quests in NXQuest.Cap2Old)", why, n)
            sv.Cap2Old = d
        end

        local prevAudit = d and d.Audit
        d = {
            Version = SV_VERSION,
            Q   = {},   -- [questID] = quest record
            NPC = {},   -- [npcID]   = { name, lvl, pos }
            OBJ = {},   -- [name]    = { pos }          world objects we looted
            ENT = {},   -- [instanceID] = { name, typ, from }  instance entrances
            U2Q = {},   -- [npcID]   = { [questID] = "a"|"e"|"ae" }  who offers/takes what
            H   = {},   -- [questID] = harvested title/level/objective text
            ITEM = {},  -- [itemID]  = name, so objectives can be written by name
            ZONELVL = {},   -- [mapID] = { min, max, sum, n }  mob levels seen
        }
        d.Audit = prevAudit or {}
        d.Audit.resets = (d.Audit.resets or 0) + 1
        d.Audit.lastReset = time and time() or nil
        d.Audit.lastResetWhy = why
        sv.Cap2 = d

        local log = Carbonite and Carbonite.Core and Carbonite.Core.Logger
            and Carbonite.Core.Logger:Get("ObjectiveCapture")
        if log then log:warn("capture reset: %s", why) end
    end

    d.Audit = d.Audit or {}
    if not d.Audit.thisSession then
        d.Audit.thisSession = true
        d.Audit.sessions = (d.Audit.sessions or 0) + 1
        d.Audit.lastLogin = time and time() or nil
        local n = 0
        for _ in pairs(d.Q or {}) do n = n + 1 end
        d.Audit.questsAtLogin = n
    end

    -- Sections added after the first release of this format.
    d.U2Q  = d.U2Q or {}
    d.H    = d.H or {}
    d.ITEM = d.ITEM or {}
    d.ZONELVL = d.ZONELVL or {}

    -- Which character recorded this. The shipping quest DB keys faction onto
    -- the `side` field, and a single character only ever sees one side of it.
    if not d.Faction and UnitFactionGroup then
        d.Faction = UnitFactionGroup("player")
        local _, class = UnitClass and UnitClass("player")
        local _, race = UnitRace and UnitRace("player")
        d.Class, d.Race = class, race
    end

    if d.Enabled == nil then
        -- Default on where we are actively building a database, off elsewhere
        -- so release users do not grow a SavedVariables file for nothing.
        d.Enabled = Nx.isCamelot and true or false
    end

    if not d.Build then
        local ver, build, _, toc = GetBuildInfo()
        d.Build  = format("%s.%s", tostring(ver), tostring(build))
        d.Toc    = toc
        d.Flavor = Nx.isCamelot and "camelot"
            or Nx.isClassicEra and "classic"
            or Nx.isTBCClassic and "tbc"
            or Nx.isWotlkClassic and "wrath"
            or Nx.isCataClassic and "cata"
            or Nx.isMoPClassic and "mop"
            or "retail"
        d.Locale = GetLocale and GetLocale() or nil
    end

    return d
end

-- COMBAT_LOG_EVENT_UNFILTERED fires hundreds of times a second in a raid, so
-- the enabled check on that path must not walk the SavedVariables table.
local enabled = false

local function refreshEnabled()
    local d = db()
    enabled = (d and d.Enabled) == true

    if not d and C_Timer and C_Timer.After and not ObjCap._svRetry then
        ObjCap._svRetry = true
        C_Timer.After(5, function()
            ObjCap._svRetry = nil
            if not db() then
                refreshEnabled()
            else
                refreshEnabled()
                local log = Carbonite and Carbonite.Core and Carbonite.Core.Logger
                    and Carbonite.Core.Logger:Get("ObjectiveCapture")
                if log then log:info("SavedVariables arrived late; capture armed") end
            end
        end)
    end
end

function ObjCap:IsEnabled()
    return enabled
end

function ObjCap:SetEnabled(on)
    local d = db()
    if d then d.Enabled = on and true or false end
    refreshEnabled()
end

function ObjCap:Wipe()
    local sv = _G.NXQuest
    if sv and sv.Cap2 then sv.Cap2Old = sv.Cap2 end
    if sv then sv.Cap2 = nil end
    if ObjCap.ResetSnapshots then ObjCap.ResetSnapshots() end
    db()
    refreshEnabled()
end

function ObjCap:Stats()
    local d = db()
    if not d then return 0, 0, 0, 0, 0, 0, 0 end
    local q, n, o, e, u, h, named = 0, 0, 0, 0, 0, 0, 0
    for _ in pairs(d.Q)   do q = q + 1 end
    for _, rec in pairs(d.NPC) do
        n = n + 1
        if rec.name then named = named + 1 end
    end
    for _ in pairs(d.OBJ) do o = o + 1 end
    for _ in pairs(d.ENT) do e = e + 1 end
    for _ in pairs(d.U2Q) do u = u + 1 end
    for _ in pairs(d.H)   do h = h + 1 end
    return q, n, o, e, u, h, named
end

-------------------------------------------------------------------------------
-- Small helpers
-------------------------------------------------------------------------------

-- The 12.0 engine (retail Midnight and, by the same rules, Forever/camelot)
-- hands insecure code "secret" values in some contexts - see C_Secrets and
-- SecrecyLevel.ContextuallySecret. Storing one is an outright error in
-- Blizzard's own containers ("attempted to store a secret value"), so every
-- value this module writes to SavedVariables goes through here first.
local function plain(v)
    if _G.issecretvalue and _G.issecretvalue(v) then return nil end
    return v
end

-- Player position as mapID plus percent coordinates with one decimal, which
-- is the precision Carbonite's own data tables use.
local function playerPos()
    if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
    local mapID = plain(C_Map.GetBestMapForUnit("player"))
    if not mapID then return nil end
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return mapID end
    local x, y = pos:GetXY()
    x, y = plain(x), plain(y)
    if not x or not y then return mapID end
    return mapID, floor(x * 1000 + 0.5) / 10, floor(y * 1000 + 0.5) / 10
end

-- Append a position sample, collapsing near-duplicates so standing in one
-- spot killing twenty mobs stores one entry, not twenty.
local function addPos(rec, mapID, x, y, field, grid, maxn)
    if not mapID then return end
    field = field or "pos"
    grid = grid or POS_GRID
    rec[field] = rec[field] or {}
    local list = rec[field]
    for i = 1, #list do
        local p = list[i]
        if p[1] == mapID and (not x or not p[2]
            or (abs(p[2] - x) < grid and abs(p[3] - y) < grid)) then
            p[4] = (p[4] or 1) + 1      -- how often we saw this spot
            return
        end
    end
    if #list < (maxn or MAX_POS) then
        list[#list + 1] = { mapID, x, y, 1 }
    end
end

-- "Creature-0-3299-0-6-448-000082C98F" -> "Creature", 448
local function guidKind(guid)
    guid = plain(guid)
    if type(guid) ~= "string" then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" or kind == "Pet"
        or kind == "GameObject" or kind == "Vignette" then
        return kind, tonumber(id)
    end
    return kind
end

local function noteNPC(npcID, name, lvl, mapID, x, y)
    if not npcID then return end
    local d = db()
    if not d then return end
    local rec = d.NPC[npcID]
    if not rec then
        rec = {}
        d.NPC[npcID] = rec
    end
    rec.name = rec.name or name
    rec.lvl  = rec.lvl or lvl
    addPos(rec, mapID, x, y)
end

-------------------------------------------------------------------------------
-- Cause ring buffer
--
-- Everything that could satisfy an objective lands here. `kind` is what the
-- objective types in the quest log map onto: "monster", "item", "object".
-------------------------------------------------------------------------------

local causes = {}
local causeNext = 1

-- Fallback source for kill credit. COMBAT_LOG_EVENT_UNFILTERED (and the
-- filtered COMBAT_LOG_EVENT) are documented HasRestrictions = true on the 12.0
-- engine, so an insecure addon may not register them - on Forever that raises
-- "attempted to call a forbidden function from a tainted execution path".
-- Without the combat log we cannot see UNIT_DIED, so remember the hostile unit
-- the player last dealt with (target first, then mouseover / nameplate) and
-- blame that when a monster objective ticks. Coarser than the combat log, so
-- anything attributed this way is marked approx for the offline side.
local lastHostile = { target = nil, any = nil }

local function noteHostile(slot, npcID, name, mapID, x, y)
    if not npcID then return end
    lastHostile[slot] = {
        npc = npcID, name = name, map = mapID, x = x, y = y, t = GetTime(),
    }
end

local function hostileFallback()
    local now = GetTime()
    local best
    for _, slot in ipairs({ "target", "any" }) do
        local c = lastHostile[slot]
        if c and (now - c.t) <= CAUSE_WINDOW * 4 then
            -- Prefer the target: a kill almost always goes through one.
            if not best or slot == "target" then best = c end
        end
    end
    return best
end

local function pushCause(kind, data)
    data.kind = kind
    data.t = GetTime()
    causes[causeNext] = data
    causeNext = causeNext % CAUSE_KEEP + 1
end

local function findItemCause(objText)
    local now = GetTime()
    local d = db()
    local names = d and d.ITEM
    local best, bestT, fallback, fallbackT

    for i = 1, CAUSE_KEEP do
        local c = causes[i]
        if c and c.kind == "item" and (now - c.t) <= CAUSE_WINDOW then
            if not fallbackT or c.t > fallbackT then
                fallback, fallbackT = c, c.t
            end
            local name = c.item and names and names[c.item]
            if objText and name and name ~= ""
                and objText:find(name, 1, true) then
                if not bestT or c.t > bestT then
                    best, bestT = c, c.t
                end
            end
        end
    end

    return best or fallback
end

-- Most recent cause of `kind` still inside the correlation window.
local function findCause(kind)
    local best, bestT
    local now = GetTime()
    for i = 1, CAUSE_KEEP do
        local c = causes[i]
        if c and c.kind == kind and (now - c.t) <= CAUSE_WINDOW then
            if not bestT or c.t > bestT then
                best, bestT = c, c.t
            end
        end
    end
    return best
end

-------------------------------------------------------------------------------
-- Quest records
-------------------------------------------------------------------------------

local function questRec(questID)
    local d = db()
    if not d or not questID or questID <= 0 then return nil end
    local rec = d.Q[questID]
    if not rec then
        rec = { obj = {} }
        d.Q[questID] = rec
    end
    return rec
end

-- Objective snapshot for one quest, normalized across flavors. Modern
-- clients answer with C_QuestLog.GetQuestObjectives; the leaderboard path is
-- the fallback for clients (or moments) where that returns nothing.
local function readObjectives(questID)
    local out

    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objs = pcall(C_QuestLog.GetQuestObjectives, questID)
        if ok and objs and #objs > 0 then
            out = {}
            for i = 1, #objs do
                local o = objs[i]
                out[i] = {
                    text = plain(o.text),
                    typ  = plain(o.type),
                    have = plain(o.numFulfilled) or 0,
                    need = plain(o.numRequired) or 0,
                    done = o.finished and true or false,
                }
            end
            return out
        end
    end

    local qi = _G.GetQuestLogIndexByID and GetQuestLogIndexByID(questID)
        or (C_QuestLog and C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID))
    if not qi or qi == 0 then return nil end

    local cnt = _G.GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(qi) or 0
    if cnt == 0 or not _G.GetQuestLogLeaderBoard then return nil end

    out = {}
    for i = 1, cnt do
        local text, typ, done = GetQuestLogLeaderBoard(i, qi)
        local have, need = 0, 0
        if text then
            local h, n = text:match("(%d+)%s*/%s*(%d+)")
            have, need = tonumber(h) or 0, tonumber(n) or 0
        end
        out[i] = {
            text = text,
            typ  = typ,
            have = done and need > 0 and need or have,
            need = need,
            done = done and true or false,
        }
    end
    return out
end

-- Where the record for objective `i` lives, created on demand.
local function objRec(rec, i, snap)
    local o = rec.obj[i]
    if not o then
        o = {}
        rec.obj[i] = o
    end
    o.typ  = o.typ or snap.typ
    o.need = snap.need > 0 and snap.need or o.need
    -- Objective text is locale-specific; keep it, the converters match on it.
    o.text = o.text or snap.text
    return o
end

local function bumpCount(tbl, key, delta)
    if not key then return end
    tbl[key] = (tbl[key] or 0) + (delta or 1)
end

-- An objective went up by `delta`. Blame the freshest matching cause and
-- write down everything we know about it.
local function attribute(rec, index, snap, delta)
    local o = objRec(rec, index, snap)
    local mapID, x, y = playerPos()
    addPos(o, mapID, x, y)

    local typ = snap.typ

    if typ == "monster" or typ == "player" then
        local c = findCause("monster")
        if not c then
            c = hostileFallback()
            if c then o.approx = true end
        end
        if c and c.npc then
            o.kills = o.kills or {}
            bumpCount(o.kills, c.npc, delta)
            o.names = o.names or {}
            o.names[c.npc] = o.names[c.npc] or c.name
            addPos(o, c.map, c.x, c.y)
        end

    elseif typ == "item" then
        local c = findItemCause(snap.text)
        if c and c.item then
            o.items = o.items or {}
            local it = o.items[c.item]
            if not it then
                it = { n = 0 }
                o.items[c.item] = it
            end
            it.n = it.n + (delta or 1)
            -- What it dropped off: creature id, object id, or "self" when the
            -- item arrived without a loot source (quest start item, crafted).
            if c.srcKind and c.srcID then
                it.src = it.src or {}
                local key = format("%s:%d", c.srcKind, c.srcID)
                bumpCount(it.src, key, delta)
                if c.approxSrc then it.approxSrc = true end
                if c.srcKind == "Creature" then
                    noteNPC(c.srcID, c.srcName, nil, c.map, c.x, c.y)
                end
            elseif c.srcName then
                it.src = it.src or {}
                bumpCount(it.src, "object:" .. c.srcName, delta)
            end
            addPos(o, c.map, c.x, c.y)
        end

    elseif typ == "object" then
        local c = findCause("object") or findCause("item")
        if c then
            o.objects = o.objects or {}
            local key = c.srcID and format("GameObject:%d", c.srcID) or c.srcName
            if key then bumpCount(o.objects, key, delta) end
            addPos(o, c.map, c.x, c.y)
        end
    end
    -- "event", "progressbar", "log" and friends carry no cause we can name;
    -- the position sample above is the useful part.
end

-------------------------------------------------------------------------------
-- Quest-log scanning
-------------------------------------------------------------------------------

-- questID -> last seen objective snapshot
local snapshots = {}

-- Called by ObjCap:Wipe(), which is declared before this table exists.
function ObjCap.ResetSnapshots()
    snapshots = {}
end

local function scanQuest(questID, title, level, group, freq)
    local snap = readObjectives(questID)
    if not snap then return end

    local prev = snapshots[questID]
    local rec = questRec(questID)
    if not rec then return end

    rec.title = rec.title or title
        or (C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID))
    rec.qlvl  = rec.qlvl or level
    rec.group = rec.group or (group and group > 0 and group or nil)
    rec.freq  = rec.freq or (freq and freq > 1 and freq or nil)

    for i = 1, #snap do
        local now = snap[i]
        local was = prev and prev[i]
        local delta = now.have - ((was and was.have) or 0)
        -- Objectives can reset (abandon/turn-in), only credit forward motion.
        if delta > 0 and prev then
            attribute(rec, i, now, delta)
        elseif not prev then
            -- First sight of this quest in this session: keep the shape but do
            -- not blame anything for progress that happened before we looked.
            objRec(rec, i, now)
        end
    end

    snapshots[questID] = snap
end

-- NxQuest.lua installs the classic GetQuestLogTitle signature on every
-- flavor, and its 8th return is the *live* quest ID (not the story/display ID
-- C_QuestLog.GetInfo hands out for replayable content), which is the one the
-- rest of the quest API answers to. Reuse it rather than branching here.
local function eachLoggedQuest(fn)
    local num = _G.GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
    for i = 1, num do
        local title, level, group, isHeader, _, _, freq, questID = GetQuestLogTitle(i)
        if questID and questID > 0 and not isHeader then
            fn(questID, title, level, group, freq)
        end
    end
end

local scanPending = false

local function scanSoon()
    if scanPending or not ObjCap:IsEnabled() then return end
    if not (C_Timer and C_Timer.After) then
        eachLoggedQuest(scanQuest)
        return
    end
    scanPending = true
    C_Timer.After(SCAN_DELAY, function()
        scanPending = false
        if not ObjCap:IsEnabled() then return end
        eachLoggedQuest(scanQuest)
    end)
end

-------------------------------------------------------------------------------
-- Layer 2: what an NPC offers and takes back
--
-- Everything above only learns about a quest once we accept it, which leaves
-- out every quest this character cannot or will not take. Walking past an NPC
-- is enough to read its quest list, so the gossip and greeting frames fill in
-- Start/End and Units2Quests without playing the quest at all.
-------------------------------------------------------------------------------

-- Merge a role into d.U2Q: "a" offered by this NPC, "e" turned in here.
local function noteU2Q(npcID, questID, role)
    questID = plain(questID)
    if not npcID or type(questID) ~= "number" or questID <= 0 then return end
    local d = db()
    if not d then return end
    local t = d.U2Q[npcID]
    if not t then
        t = {}
        d.U2Q[npcID] = t
    end
    local cur = t[questID]
    if cur == nil then
        t[questID] = role
    elseif cur ~= role and #cur < 2 then
        t[questID] = "ae"
    end
end

-- Gossip hands us title/level/repeat flags for free; keep them in the harvest
-- table so a quest we never accept still gets a name.
local function noteHarvestFromGossip(questID, info)
    questID = plain(questID)
    if type(questID) ~= "number" or questID <= 0 then return end
    local d = db()
    if not d then return end
    local h = d.H[questID]
    if not h then
        h = {}
        d.H[questID] = h
    end
    h.title = h.title or plain(info.title)
    h.lvl   = h.lvl or plain(info.questLevel)
    local freq = plain(info.frequency)
    if type(freq) == "number" and freq > 1 then h.freq = freq end
    if plain(info.repeatable) then h.rep = true end
    h.src = h.src or "gossip"
end

local function scanQuestGiver()
    if not enabled then return end
    local kind, npcID = guidKind(UnitGUID("npc"))
    if not npcID then return end

    local mapID, x, y = playerPos()
    noteNPC(kind == "Creature" and npcID or nil, plain(UnitName("npc")), plain(UnitLevel("npc")), mapID, x, y)

    local d = db()
    if not d then return end

    -- Modern path: C_GossipInfo returns GossipQuestUIInfo entries with the
    -- quest ID, which is all we need.
    if C_GossipInfo then
        local avail = C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests()
        for _, info in ipairs(avail or {}) do
            noteU2Q(npcID, plain(info.questID), "a")
            noteHarvestFromGossip(info.questID, info)
        end
        local active = C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests()
        for _, info in ipairs(active or {}) do
            noteU2Q(npcID, plain(info.questID), "e")
            noteHarvestFromGossip(info.questID, info)
        end
    end

    -- Greeting frame (an NPC with several quests and no gossip options). Only
    -- the active side exposes IDs here; available quests give us a title, so
    -- record those by name for the offline matcher.
    if _G.GetNumActiveQuests and _G.GetActiveQuestID then
        for i = 1, plain(GetNumActiveQuests()) or 0 do
            local ok, qid = pcall(GetActiveQuestID, i)
            if ok then noteU2Q(npcID, qid, "e") end
        end
    end
    if _G.GetNumAvailableQuests and _G.GetAvailableTitle then
        local names
        for i = 1, plain(GetNumAvailableQuests()) or 0 do
            local ok, title = pcall(GetAvailableTitle, i)
            title = ok and plain(title) or nil
            if type(title) == "string" and title ~= "" then
                names = names or {}
                names[title] = true
            end
        end
        if names then
            d.U2QNames = d.U2QNames or {}
            d.U2QNames[npcID] = d.U2QNames[npcID] or {}
            for title in pairs(names) do
                d.U2QNames[npcID][title] = "a"
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Layer 3: bulk harvest of every quest ID
--
-- C_QuestLog.RequestLoadQuestByID makes the server send a quest we are not on,
-- and after QUEST_DATA_LOAD_RESULT the title, difficulty level and objective
-- text are readable. Walking the whole ID space therefore gives names and
-- objectives for the entire game - still no coordinates, which only playing
-- (or the layer above) can provide.
--
-- QuestV2 of build 1.60.1.69893 holds 6600 quests with IDs up to 99234, so the
-- default range covers it. Requests are throttled; this talks to the server.
-------------------------------------------------------------------------------

local HARVEST_DEFAULT_TO = 100000
local HARVEST_TIMEOUT    = 10        -- seconds before we give up on an ID
local HARVEST_INTERVAL   = 0.25

local harvest = {
    running  = false,
    batch    = 8,                    -- requests per interval
    inflight = {},
    nflight  = 0,
}

local function harvestLog()
    return (Carbonite and Carbonite.Core and Carbonite.Core.Logger)
        and Carbonite.Core.Logger:Get("ObjectiveCapture") or nil
end

local function readHarvested(questID)
    local d = db()
    if not d then return false end

    local title = plain(C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID))
    local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)
    if (not title or title == "") and not (objs and #objs > 0) then
        return false
    end

    local h = d.H[questID]
    if not h then
        h = {}
        d.H[questID] = h
    end
    h.title = title ~= "" and title or h.title
    h.src = "load"
    if C_QuestLog.GetQuestDifficultyLevel then
        local ok, lvl = pcall(C_QuestLog.GetQuestDifficultyLevel, questID)
        lvl = plain(lvl)
        if ok and type(lvl) == "number" and lvl > 0 then h.lvl = lvl end
    end
    if C_QuestLog.IsRepeatableQuest then
        local ok, rep = pcall(C_QuestLog.IsRepeatableQuest, questID)
        if ok and rep then h.rep = true end
    end
    if C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok and done then h.done = true end
    end
    if C_QuestLog.GetQuestTagInfo then
        local ok, tag = pcall(C_QuestLog.GetQuestTagInfo, questID)
        if ok and tag then
            h.tag = plain(tag.tagID or tag.tagId)
            h.tagName = plain(tag.tagName)
            if tag.worldQuestType then h.wq = tag.worldQuestType end
        end
    end
    if objs and #objs > 0 then
        h.objs = {}
        for i = 1, #objs do
            local o = objs[i]
            h.objs[i] = { typ = plain(o.type), text = plain(o.text), need = plain(o.numRequired) }
        end
    end
    return true
end

local function harvestTick()
    local d = db()
    if not harvest.running or not d then return end

    local prog = d.HProg
    if not prog then
        harvest.running = false
        return
    end

    -- Drop requests the server never answered.
    local now = GetTime()
    for id, t in pairs(harvest.inflight) do
        if (now - t) > HARVEST_TIMEOUT then
            harvest.inflight[id] = nil
            harvest.nflight = harvest.nflight - 1
        end
    end

    while harvest.nflight < harvest.batch and prog.cur <= prog.to do
        local id = prog.cur
        prog.cur = id + 1
        if not d.H[id] or not d.H[id].objs then
            harvest.inflight[id] = now
            harvest.nflight = harvest.nflight + 1
            pcall(C_QuestLog.RequestLoadQuestByID, id)
        end
    end

    if prog.cur > prog.to and harvest.nflight <= 0 then
        harvest.running = false
        if harvest.ticker then
            harvest.ticker:Cancel()
            harvest.ticker = nil
        end
        local log = harvestLog()
        if log then log:info("harvest finished: %d quests known", prog.found or 0) end
        return
    end

    if prog.cur - (prog.lastReport or prog.from) >= 2000 then
        prog.lastReport = prog.cur
        local log = harvestLog()
        if log then
            log:info("harvest at id %d/%d, %d quests known", prog.cur, prog.to, prog.found or 0)
        end
    end
end

function ObjCap:HarvestStart(from, to)
    local d = db()
    if not d then return end
    if not (C_QuestLog and C_QuestLog.RequestLoadQuestByID) then
        local log = harvestLog()
        if log then log:info("this client has no C_QuestLog.RequestLoadQuestByID") end
        return
    end

    d.Enabled = true
    refreshEnabled()

    local prog = d.HProg
    if from or not prog or (prog.cur or 0) > (prog.to or 0) then
        prog = {
            from = from or 1,
            to = to or HARVEST_DEFAULT_TO,
            cur = from or 1,
            found = prog and prog.found or 0,
        }
        d.HProg = prog
    end

    harvest.running = true
    harvest.inflight = {}
    harvest.nflight = 0
    if harvest.ticker then harvest.ticker:Cancel() end
    harvest.ticker = C_Timer.NewTicker(HARVEST_INTERVAL, harvestTick)

    local log = harvestLog()
    if log then
        log:info("harvest running: ids %d..%d (resuming at %d), %d per %.2fs",
            prog.from, prog.to, prog.cur, harvest.batch, HARVEST_INTERVAL)
    end
end

function ObjCap:HarvestStop()
    harvest.running = false
    if harvest.ticker then
        harvest.ticker:Cancel()
        harvest.ticker = nil
    end
    local log = harvestLog()
    local d = db()
    if log and d and d.HProg then
        log:info("harvest stopped at id %d/%d, %d quests known",
            d.HProg.cur or 0, d.HProg.to or 0, d.HProg.found or 0)
    end
end

function ObjCap:HarvestStatus()
    local d = db()
    local prog = d and d.HProg
    local known = 0
    if d then for _ in pairs(d.H) do known = known + 1 end end
    return harvest.running, prog and prog.cur or 0, prog and prog.to or 0, known
end

function ObjCap:SetHarvestBatch(n)
    n = tonumber(n)
    if n and n >= 1 and n <= 64 then harvest.batch = floor(n) end
    return harvest.batch
end

-------------------------------------------------------------------------------
-- Layer 4: NPC names, levels and spawn areas
--
-- No API turns an npcID into a name - a creature's name can only be learned by
-- meeting it, which is why the shipped Nx.QuestStartEnd tables have to be
-- harvested per locale. Nameplates make that nearly free: every unit entering
-- nameplate range fires NAME_PLATE_UNIT_ADDED, so simply walking a zone
-- collects its whole population. Mouseover and target cover what nameplates
-- miss (friendly NPCs when hostile-only plates are on, quest givers).
--
-- Positions are the player's own, as at nameplate range (~40 yards, under 1%
-- of a zone) that is close enough for a spawn map and matches what the
-- combat-log path already records.
-------------------------------------------------------------------------------

local function noteZoneLevel(mapID, lvl, react)
    -- Neutral or hostile creatures define a zone's level range; friendly NPCs
    -- (react > 4) are city guards and vendors scaled to other rules.
    if not mapID or not lvl or lvl <= 0 then return end
    if react and react > 4 then return end
    local d = db()
    if not d then return end
    local z = d.ZONELVL[mapID]
    if not z then
        z = { min = lvl, max = lvl, sum = 0, n = 0 }
        d.ZONELVL[mapID] = z
    end
    if lvl < z.min then z.min = lvl end
    if lvl > z.max then z.max = lvl end
    z.sum = z.sum + lvl
    z.n = z.n + 1
end

local unitSubtitle

local function noteUnit(unit)
    if not enabled or not unit or not UnitGUID then return end

    local kind, npcID = guidKind(plain(UnitGUID(unit)))
    if (kind ~= "Creature" and kind ~= "Vehicle") or not npcID then return end

    local d = db()
    if not d then return end

    local rec = d.NPC[npcID]
    if not rec then
        rec = {}
        d.NPC[npcID] = rec
    end

    rec.name = rec.name or plain(UnitName(unit))
    if not rec.sub then rec.sub = unitSubtitle(unit) end

    local lvl = plain(UnitLevel(unit))
    if type(lvl) == "number" and lvl > 0 then
        rec.lvl = rec.lvl or lvl
        if not rec.lmin or lvl < rec.lmin then rec.lmin = lvl end
        if not rec.lmax or lvl > rec.lmax then rec.lmax = lvl end
    else
        lvl = nil
    end

    if not rec.cls and _G.UnitClassification then
        local cls = plain(UnitClassification(unit))
        if cls and cls ~= "normal" then rec.cls = cls end
    end
    if not rec.ctype and _G.UnitCreatureType then
        rec.ctype = plain(UnitCreatureType(unit))
    end
    if rec.react == nil and _G.UnitReaction then
        local react = plain(UnitReaction(unit, "player"))
        if type(react) == "number" then rec.react = react end
    end

    local mapID, x, y = playerPos()
    addPos(rec, mapID, x, y)
    noteZoneLevel(mapID, lvl, rec.react)

    -- Hostile or neutral units are kill candidates for the fallback above.
    if not rec.react or rec.react <= 4 then
        noteHostile(unit == "target" and "target" or "any",
            npcID, rec.name, mapID, x, y)
    end
end

local pendingUnits = {}
local function noteUnitSoon(unit)
    if not enabled or not unit then return end
    if not (C_Timer and C_Timer.After) then
        noteUnit(unit)
        return
    end
    if pendingUnits[unit] then return end
    pendingUnits[unit] = true
    C_Timer.After(0, function()
        pendingUnits[unit] = nil
        noteUnit(unit)
    end)
end

-------------------------------------------------------------------------------
-- Event handling
-------------------------------------------------------------------------------

-- Dedicated frame. Carbonite must never put unit events on AceEvent's shared
-- frame: secret payloads there have leaked taint into Blizzard code before
-- (see the castbar and SetCooldown regressions).
local frame = CreateFrame("Frame")

-- Who we are talking to right now, so QUEST_ACCEPTED / QUEST_TURNED_IN can
-- name the giver even though their own payload does not.
local talkTo = {}

local function noteTalkTarget()
    local guid = plain(UnitGUID("npc"))
    local kind, id = guidKind(guid)
    local mapID, x, y = playerPos()
    talkTo.npc  = (kind == "Creature" or kind == "GameObject") and id or nil
    talkTo.kind = kind
    talkTo.name = plain(UnitName("npc"))
    talkTo.map, talkTo.x, talkTo.y = mapID, x, y
    talkTo.t = GetTime()
    if talkTo.npc and kind == "Creature" then
        noteNPC(talkTo.npc, talkTo.name, plain(UnitLevel("npc")), mapID, x, y)
    end
end

local ROLE_BY_TYPE = {}
if Enum and Enum.PlayerInteractionType then
    for k, v in pairs(Enum.PlayerInteractionType) do ROLE_BY_TYPE[v] = k end
end

local LEGACY_ROLE = {
    MERCHANT_SHOW      = "Merchant",
    TRAINER_SHOW       = "Trainer",
    BANKFRAME_OPENED   = "Banker",
    AUCTION_HOUSE_SHOW = "Auctioneer",
    MAIL_SHOW          = "MailInfo",
    TAXIMAP_OPENED     = "TaxiNode",
}

local useManager = false

function unitSubtitle(unit)
    local get = C_TooltipInfo and C_TooltipInfo.GetUnit
    if not get then return nil end
    local ok, data = pcall(get, unit)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local line = data.lines[2]
    local text = type(line) == "table" and plain(line.leftText) or nil
    if type(text) == "string" and text ~= "" and not text:find("%d") then
        return text
    end
end

local function serviceTarget()
    local kind, id = guidKind(plain(UnitGUID("npc")))
    if not id then
        kind, id = guidKind(plain(UnitGUID("softinteract")))
    end
    return kind, id
end

local OBJ_ROLE = {
    MailInfo = true, TaxiNode = true, Banker = true, GuildBanker = true,
    Auctioneer = true, BlackMarketAuctioneer = true, VoidStorageBanker = true,
    Binder = true, StableMaster = true, Transmogrifier = true, Merchant = true,
}

local function serviceRec(d, kind, id, role, mapID, x, y)
    if kind == "Creature" and id then
        noteNPC(id, plain(UnitName("npc")), plain(UnitLevel("npc")), mapID, x, y)
        local rec = d.NPC[id]
        if rec and not rec.sub then rec.sub = unitSubtitle("npc") end
        return rec
    end
    local key = (kind == "GameObject" and id) and ("GameObject:" .. id)
        or (OBJ_ROLE[role] and role)
    if not key then return nil end
    local rec = d.OBJ[key]
    if not rec then
        rec = {}
        d.OBJ[key] = rec
    end
    rec.name = rec.name or plain(UnitName("npc"))
    return rec
end

local function noteTrainer(rec)
    if not (GetNumTrainerServices and GetTrainerServiceSkillLine) then return end
    local n = plain(GetNumTrainerServices()) or 0
    for i = 1, n do
        local skill = plain(GetTrainerServiceSkillLine(i))
        if type(skill) == "string" and skill ~= "" then
            rec.train = skill
            break
        end
    end
    if IsTradeskillTrainer then
        rec.tradeskill = plain(IsTradeskillTrainer()) and true or nil
    end
end

local function noteGossip(rec)
    if not (C_GossipInfo and C_GossipInfo.GetOptions) then return end
    local ok, opts = pcall(C_GossipInfo.GetOptions)
    if not ok or type(opts) ~= "table" then return end
    for _, o in ipairs(opts) do
        local icon = plain(o.icon)
        if icon then
            rec.gossip = rec.gossip or {}
            rec.gossip[icon] = plain(o.name) or true
        end
    end
end

local function noteService(role)
    if not enabled or not role or role == "None" then return end
    local d = db()
    if not d then return end
    local kind, id = serviceTarget()
    local mapID, x, y = playerPos()
    local rec = serviceRec(d, kind, id, role, mapID, x, y)
    if not rec then return end
    rec.roles = rec.roles or {}
    rec.roles[role] = (rec.roles[role] or 0) + 1
    addPos(rec, mapID, x, y, "talk", TALK_GRID, MAX_TALK)
    if role == "Gossip" then
        noteGossip(rec)
    elseif role == "Trainer" then
        noteTrainer(rec)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function() noteTrainer(rec) end)
        end
    end
end

local function talkSnapshot()
    if not talkTo.t or (GetTime() - talkTo.t) > 30 then return nil end
    return {
        npc  = talkTo.npc,
        kind = talkTo.kind,
        name = talkTo.name,
        map  = talkTo.map,
        x    = talkTo.x,
        y    = talkTo.y,
        t    = time(),
    }
end

local function onLoot()
    if not ObjCap:IsEnabled() then return end
    local mapID, x, y = playerPos()
    local num = _G.GetNumLootItems and GetNumLootItems() or 0
    for slot = 1, num do
        local link = plain(_G.GetLootSlotLink and GetLootSlotLink(slot))
        local itemID = link and tonumber(link:match("item:(%d+)"))
        if itemID then
            -- The link carries the localized name; the quest DB writes
            -- objectives by name, so keep it.
            local d = db()
            local iname = link:match("%[(.-)%]")
            if d and iname and iname ~= "" then d.ITEM[itemID] = d.ITEM[itemID] or iname end
            local srcKind, srcID, srcName, approxSrc

            if _G.GetLootSourceInfo then
                local guid = plain((GetLootSourceInfo(slot)))
                srcKind, srcID = guidKind(guid)
            end

            if not srcID then
                local kind, id = guidKind(plain(UnitGUID("target")))
                if id and (kind == "Creature" or kind == "Vehicle"
                    or kind == "GameObject") then
                    srcKind, srcID = kind, id
                end
            end

            if not srcID then
                local recent = hostileFallback()
                if recent and recent.npc then
                    srcKind, srcID, approxSrc = "Creature", recent.npc, true
                end
            end

            if not srcID then
                -- Herb/mineral nodes and chests answer through the loot
                -- window title rather than a GUID on some clients.
                srcName = plain(_G.GetUnitName and GetUnitName("target")) or nil
            end
            pushCause("item", {
                item = itemID, srcKind = srcKind, srcID = srcID, srcName = srcName,
                approxSrc = approxSrc, map = mapID, x = x, y = y,
            })
            if srcKind == "GameObject" and srcID then
                pushCause("object", {
                    srcKind = srcKind, srcID = srcID,
                    map = mapID, x = x, y = y,
                })
                local d = db()
                if d then
                    local key = format("GameObject:%d", srcID)
                    d.OBJ[key] = d.OBJ[key] or {}
                    addPos(d.OBJ[key], mapID, x, y)
                end
            end
        end
    end
end

local function onCombatLog()
    if not ObjCap:IsEnabled() then return end
    local _, sub, _, _, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
    sub, destGUID, destName = plain(sub), plain(destGUID), plain(destName)
    if sub ~= "UNIT_DIED" and sub ~= "PARTY_KILL" then return end
    local kind, id = guidKind(destGUID)
    if kind ~= "Creature" and kind ~= "Vehicle" then return end
    local mapID, x, y = playerPos()
    pushCause("monster", { npc = id, name = destName, map = mapID, x = x, y = y })
    noteNPC(id, destName, nil, mapID, x, y)
end

-- Last position we held outdoors, which is where an instance portal is.
local lastOutdoor = {}

local function noteZone()
    if not _G.GetInstanceInfo then return end
    local name, itype, _, _, _, _, _, instanceID = GetInstanceInfo()
    name, itype, instanceID = plain(name), plain(itype), plain(instanceID)
    if not itype or itype == "none" then
        local mapID, x, y = playerPos()
        if mapID then
            lastOutdoor.map, lastOutdoor.x, lastOutdoor.y = mapID, x, y
        end
        return
    end
    if not ObjCap:IsEnabled() then return end
    local d = db()
    if not d or not instanceID then return end
    local rec = d.ENT[instanceID]
    if not rec then
        rec = {}
        d.ENT[instanceID] = rec
    end
    rec.name = rec.name or name
    rec.typ  = rec.typ or itype
    -- Entrance coordinates for Nx.Zones: the outdoor spot we stood on right
    -- before the portal took us. Only the first one is trustworthy; later
    -- entries can come from a summon or a teleport.
    if not rec.from and lastOutdoor.map then
        rec.from = { lastOutdoor.map, lastOutdoor.x, lastOutdoor.y }
    end
end

local function onQuestAccepted(questID)
    if not ObjCap:IsEnabled() then return end
    local rec = questRec(questID)
    if not rec then return end
    rec.accept = rec.accept or talkSnapshot()
    rec.plvl = rec.plvl or UnitLevel("player")
    local qi = _G.GetQuestLogIndexByID and GetQuestLogIndexByID(questID)
        or (C_QuestLog and C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID))
    if qi and qi > 0 and _G.GetQuestLogTitle then
        local title, level, group, _, _, _, freq = GetQuestLogTitle(qi)
        rec.title = rec.title or title
        rec.qlvl  = rec.qlvl or level
        rec.group = rec.group or (group and group > 0 and group or nil)
        rec.freq  = rec.freq or (freq and freq > 1 and freq or nil)
    end
    snapshots[questID] = readObjectives(questID)
    scanSoon()
end

local function onQuestTurnedIn(questID, xp, money)
    if not ObjCap:IsEnabled() then return end
    local rec = questRec(questID)
    if not rec then return end
    rec.turnin = rec.turnin or talkSnapshot()
    rec.xp = rec.xp or xp
    rec.money = rec.money or money
    snapshots[questID] = nil
end

-- Reward items are only readable while the completion frame is open.
local function onQuestComplete()
    if not ObjCap:IsEnabled() then return end
    noteTalkTarget()
    local questID = _G.GetQuestID and GetQuestID()
    if not questID or questID == 0 then return end
    local rec = questRec(questID)
    if not rec then return end
    rec.turnin = rec.turnin or talkSnapshot()

    local num = _G.GetNumQuestRewards and GetNumQuestRewards() or 0
    if num > 0 then
        rec.rew = rec.rew or {}
        for i = 1, num do
            local link = plain(_G.GetQuestItemLink and GetQuestItemLink("reward", i))
            local itemID = link and tonumber(link:match("item:(%d+)"))
            if itemID then rec.rew[itemID] = (rec.rew[itemID] or 0) + 1 end
        end
    end
    local choices = _G.GetNumQuestChoices and GetNumQuestChoices() or 0
    if choices > 0 then
        rec.rewChoice = rec.rewChoice or {}
        for i = 1, choices do
            local link = plain(_G.GetQuestItemLink and GetQuestItemLink("choice", i))
            local itemID = link and tonumber(link:match("item:(%d+)"))
            if itemID then rec.rewChoice[itemID] = true end
        end
    end
end

frame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLog()

    elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
        onLoot()

    elseif event == "CHAT_MSG_LOOT" then
        -- Auto-loot with no loot window still names the item; no source, but
        -- the itemID keeps item objectives attributable.
        if ObjCap:IsEnabled() and arg1 then
            local msg = tostring(arg1)
            local itemID = tonumber(msg:match("item:(%d+)"))
            if itemID then
                local mapID, x, y = playerPos()
                pushCause("item", { item = itemID, map = mapID, x = x, y = y })
                local d = db()
                local iname = msg:match("%[(.-)%]")
                if d and iname and iname ~= "" then d.ITEM[itemID] = d.ITEM[itemID] or iname end
            end
        end

    elseif event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "GOSSIP_SHOW"
        or event == "QUEST_GREETING" then
        if enabled then
            noteTalkTarget()
            scanQuestGiver()
            if event == "GOSSIP_SHOW" then
                if useManager then
                    local d = db()
                    local kind, id = serviceTarget()
                    local rec = d and kind == "Creature" and id and d.NPC[id]
                    if rec then noteGossip(rec) end
                else
                    noteService("Gossip")
                end
            end
        end

    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        noteService(ROLE_BY_TYPE[arg1])

    elseif LEGACY_ROLE[event] then
        noteService(LEGACY_ROLE[event])

    elseif event == "TRAINER_UPDATE" then
        if enabled then
            local d = db()
            local kind, id = serviceTarget()
            local rec = d and kind == "Creature" and id and d.NPC[id]
            if rec then noteTrainer(rec) end
        end

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        noteUnitSoon(arg1)

    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        noteUnitSoon("mouseover")

    elseif event == "PLAYER_TARGET_CHANGED" then
        noteUnitSoon("target")

    elseif event == "PLAYER_SOFT_INTERACT_CHANGED" then
        noteUnitSoon("softinteract")

    elseif event == "QUEST_DATA_LOAD_RESULT" then
        -- arg1 questID, arg2 success
        if harvest.inflight[arg1] then
            harvest.inflight[arg1] = nil
            harvest.nflight = harvest.nflight - 1
        end
        if arg2 and enabled and readHarvested(arg1) then
            local d = db()
            if d and d.HProg then d.HProg.found = (d.HProg.found or 0) + 1 end
        end

    elseif event == "QUEST_COMPLETE" then
        onQuestComplete()

    elseif event == "QUEST_ACCEPTED" then
        -- Modern clients pass the quest ID; older ones passed
        -- (questLogIndex, questID). A log index is always small.
        local questID = arg1
        if arg2 and type(arg2) == "number" and arg2 > 0 and (arg1 or 0) < 1000 then
            questID = arg2
        end
        onQuestAccepted(questID)

    elseif event == "QUEST_TURNED_IN" then
        onQuestTurnedIn(arg1, arg2, arg3)

    elseif event == "QUEST_REMOVED" then
        snapshots[arg1] = nil

    elseif event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        scanSoon()

    elseif event == "PLAYER_LOGIN" then
        refreshEnabled()

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "ZONE_CHANGED" then
        refreshEnabled()
        noteZone()
        scanSoon()
    end
end)

for _, e in ipairs({
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
    "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED",
    "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW",
    "QUEST_GREETING", "QUEST_DATA_LOAD_RESULT",
    "LOOT_READY", "LOOT_OPENED", "CHAT_MSG_LOOT",
    -- Layer 4 (npc harvest). PLAYER_SOFT_INTERACT_CHANGED only exists where
    -- soft targeting does; pcall registration skips it elsewhere.
    "NAME_PLATE_UNIT_ADDED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_TARGET_CHANGED",
    "PLAYER_SOFT_INTERACT_CHANGED",
}) do
    -- Events differ per flavor; a missing one must not abort registration.
    pcall(frame.RegisterEvent, frame, e)
end
-- Player-filtered, so we never see another unit's secret quest payload.
pcall(frame.RegisterUnitEvent, frame, "UNIT_QUEST_LOG_CHANGED", "player")
pcall(frame.RegisterEvent, frame, "TRAINER_UPDATE")
useManager = pcall(frame.RegisterEvent, frame, "PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
if not useManager then
    for e in pairs(LEGACY_ROLE) do pcall(frame.RegisterEvent, frame, e) end
end


-------------------------------------------------------------------------------
-- Slash command
-------------------------------------------------------------------------------

if Carbonite and Carbonite.Core and Carbonite.Core.EventBus then
    Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
        if not (Carbonite.Core.SlashCommands and Carbonite.Core.Logger) then return end
        local log = Carbonite.Core.Logger:Get("ObjectiveCapture")
        Carbonite.Core.SlashCommands:Register("qcap", function(rest)
            local args = {}
            for word in tostring(rest or ""):lower():gmatch("[^%s]+") do
                args[#args + 1] = word
            end
            local cmd = args[1]

            if cmd == "on" then
                ObjCap:SetEnabled(true)
            elseif cmd == "off" then
                ObjCap:SetEnabled(false)
            elseif cmd == "wipe" then
                ObjCap:Wipe()
                log:info("objective capture wiped")
                return
            elseif cmd == "batch" then
                log:info("harvest batch size: %d", ObjCap:SetHarvestBatch(args[2]))
                return
            elseif cmd == "harvest" then
                local sub = args[2]
                if sub == "stop" then
                    ObjCap:HarvestStop()
                elseif sub == "status" then
                    local running, cur, to, known = ObjCap:HarvestStatus()
                    log:info("harvest %s at id %d/%d, %d quests known",
                        running and "running" or "idle", cur, to, known)
                else
                    -- "harvest" resumes, "harvest 1 30000" restarts on a range
                    ObjCap:HarvestStart(tonumber(sub), tonumber(args[3]))
                end
                return
            end

            local q, n, o, e, u, h, named = ObjCap:Stats()
            local d = db()
            local secrets = _G.C_Secrets and C_Secrets.HasSecretRestrictions
                and C_Secrets.HasSecretRestrictions()
            -- IsAddOnRestrictionActive takes an Enum.AddOnRestrictionType
            -- (Combat, Encounter, ...); calling it bare is a hard error.
            local restricted
            if _G.C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive
                and _G.Enum and Enum.AddOnRestrictionType then
                local active = {}
                for name, value in pairs(Enum.AddOnRestrictionType) do
                    local ok, on = pcall(C_RestrictedActions.IsAddOnRestrictionActive, value)
                    if ok and on then active[#active + 1] = name end
                end
                restricted = #active > 0 and table.concat(active, "+") or "none"
            end
            log:info("  kill credit: %s",
                ObjCap.CombatLogAllowed and "combat log (exact)"
                    or "target/nameplate fallback (approx)")
            log:info("  restrictions: secrets %s, addon restriction %s",
                secrets == nil and "n/a" or tostring(secrets),
                restricted or "n/a")
            log:info("objective capture: %s | build %s (%s, %s)",
                ObjCap:IsEnabled() and "on" or "off",
                d and d.Build or "?", d and d.Flavor or "?", d and d.Locale or "?")
            log:info("  played: quests %d, npcs %d (%d named), objects %d, instance entrances %d",
                q, n, named, o, e)
            log:info("  seen:   quest givers %d, quests harvested %d", u, h)
            local running, cur, to = ObjCap:HarvestStatus()
            if running or (cur or 0) > 0 then
                log:info("  harvest %s at id %d/%d", running and "running" or "idle", cur, to)
            end
        end, "quest capture (/cb qcap [on|off|wipe|batch N|harvest [stop|status|from to]])")
    end)
end

-------------------------------------------------------------------------------
-- Combat log, attempted last on purpose
--
-- Both COMBAT_LOG_EVENT and COMBAT_LOG_EVENT_UNFILTERED are documented
-- HasRestrictions = true on the 12.0 engine, and registering one from an addon
-- raises ADDON_ACTION_FORBIDDEN. That error is not something pcall can contain:
-- it aborts the running chunk. Registering it half way up this file therefore
-- killed everything below - including the slash command, which is why
-- "/cb qcap" answered "unknown subcommand". So this goes dead last: if the
-- client refuses, the module is already fully wired and only exact kill credit
-- is lost (hostileFallback covers it, flagged approx).
-------------------------------------------------------------------------------

local combatLogAllowed = false
if C_CombatLog and C_CombatLog.IsCombatLogRestricted then
    local ok, restricted = pcall(C_CombatLog.IsCombatLogRestricted)
    combatLogAllowed = ok and restricted == false
elseif not C_CombatLog then
    -- Pre-12.0 clients have no namespace and no restriction.
    combatLogAllowed = true
end

ObjCap.CombatLogAllowed = combatLogAllowed

if combatLogAllowed then
    if not pcall(frame.RegisterEvent, frame, "COMBAT_LOG_EVENT_UNFILTERED") then
        ObjCap.CombatLogAllowed = false
    end
end
