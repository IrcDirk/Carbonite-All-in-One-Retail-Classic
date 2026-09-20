-- Carbonite.Quests | Tracking
-- "Track quest on map" — the routing layer between the quest watch
-- and Carbonite\'s Map:AddTarget pipeline. Owns CalcAutoTrack (the
-- closest-objective picker), IsTargeted (idempotent check), and
-- TrackOnMap (the actual setter that drives the on-screen arrow).
--
-- This is where the parked "dungeon entrance pointing" feature
-- belongs: when CalcAutoTrack resolves an objective inside an
-- instance map, substitute the dungeon\'s outdoor entry coords
-- instead of the unreachable interior coords.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals.
local bit_band   = bit.band
local bit_lshift = bit.lshift
local floor      = math.floor
local abs        = math.abs
local InCombatLockdown = InCombatLockdown

Nx.Quest.TrackDebug = Nx.Quest.TrackDebug or false
Nx.Quest.TrackQuiet = Nx.Quest.TrackQuiet or false

local TRACK_LOG_MAX = 600

local logBuf
local lastKey
local repeatIdx, repeatN, repeatT0

local function tpush (msg)
    local sv = _G.NXQuest
    if not sv then return end
    local log = sv.TrackLog
    if not log then
        log = {}
        sv.TrackLog = log
    end

    log[#log + 1] = ("%.3f %s"):format (GetTime and GetTime() or 0, msg)

    if #log > TRACK_LOG_MAX then
        local keep, cut = {}, floor (TRACK_LOG_MAX / 4)
        for n = cut + 1, #log do
            keep[#keep + 1] = log[n]
        end
        sv.TrackLog = keep
        repeatIdx = nil
    end
end

local function tflush ()
    local buf = logBuf
    logBuf = nil
    if not buf or #buf == 0 then return end

    local key = table.concat (buf, "|")
    local now = GetTime and GetTime() or 0

    if key == lastKey then
        local sv = _G.NXQuest
        local log = sv and sv.TrackLog
        if log then
            repeatN = (repeatN or 0) + 1
            local line = ("%.3f   ...block above repeated x%d over %.1fs")
                :format (repeatT0 or now, repeatN, now - (repeatT0 or now))
            if repeatIdx and log[repeatIdx] then
                log[repeatIdx] = line
            else
                log[#log + 1] = line
                repeatIdx = #log
            end
        end
        return
    end

    lastKey, repeatIdx, repeatN, repeatT0 = key, nil, 0, now
    for _, m in ipairs (buf) do
        tpush (m)
    end
end

local function tbegin ()
    tflush()
    logBuf = Nx.Quest.TrackDebug and {} or nil
end

function Nx.Quest.TrackLogWrite (msg)
    tflush()
    lastKey = nil
    tpush (msg)
end

local function tdbg (fmt, ...)
    if not Nx.Quest.TrackDebug then return end
    local ok, msg = pcall (string.format, fmt, ...)
    if not ok then return end
    if DEFAULT_CHAT_FRAME and not Nx.Quest.TrackQuiet then
        DEFAULT_CHAT_FRAME:AddMessage ("|cff40c0ff[qtrack]|r " .. msg)
    end
    if logBuf then
        logBuf[#logBuf + 1] = msg
    else
        tpush (msg)
    end
end

local function CanDrawQuestBlob(qId)
    if not qId or qId <= 0 then return false end
    if _G.GetCVarBool and not _G.GetCVarBool("questPOI") then return false end

    local logIdx
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        logIdx = C_QuestLog.GetLogIndexForQuestID (qId)
    elseif _G.GetQuestLogIndexByID then
        logIdx = _G.GetQuestLogIndexByID (qId)
    end
    if not logIdx or logIdx <= 0 then return false end

    if _G.QuestUtils_IsQuestBonusObjective
        and _G.QuestUtils_IsQuestBonusObjective (qId)
        and not (C_QuestLog and C_QuestLog.IsThreatQuest
                 and C_QuestLog.IsThreatQuest (qId)) then
        return false
    end
    return true
end

local function questBlobMap()
    local QMap = _G.NxMap1 and _G.NxMap1.NxMap
    if not QMap or not QMap.QuestWin then return nil end
    return QMap
end

function Nx.Quest:UpdateQuestBlob (qId)

    if InCombatLockdown() then
        tdbg ("  blob(%s): skip - combat lockdown", tostring(qId))
        return
    end
    if not Nx.BlobsAvailable then
        tdbg ("  blob(%s): skip - Nx.BlobsAvailable false", tostring(qId))
        return
    end

    local QMap = questBlobMap()
    if not QMap then
        tdbg ("  blob(%s): skip - no NxMap1.NxMap.QuestWin", tostring(qId))
        return
    end

    if QMap.ShowingWorldQuestBlob then
        tdbg ("  blob(%s): skip - MapEngine owns it (ShowingWorldQuestBlob)",
            tostring(qId))
        return
    end

    local mapOpts = Nx.db and Nx.db.char and Nx.db.char.Map
    if not qId or not (mapOpts and mapOpts.ShowQuestBlobs)
        or not CanDrawQuestBlob (qId) then
        local logIdx
        if qId and C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
            logIdx = C_QuestLog.GetLogIndexForQuestID (qId)
        elseif qId and _G.GetQuestLogIndexByID then
            logIdx = _G.GetQuestLogIndexByID (qId)
        end
        tdbg ("  blob(%s): HIDE (showOpt=%s questPOI=%s logIdx=%s) was=%s",
            tostring(qId),
            tostring(mapOpts and mapOpts.ShowQuestBlobs),
            tostring(_G.GetCVarBool and _G.GetCVarBool("questPOI")),
            tostring(logIdx), tostring(QMap.QuestBlobQId))
        if QMap.QuestBlobQId then
            QMap.QuestWin:DrawNone()
            QMap.QuestWin:Hide()
            QMap.QuestBlobQId = nil
        end
        return
    end

    QMap.QuestWin:DrawNone()

    local isZooming = abs (QMap.ScaleDraw - QMap.Scale) > 0.001
    if isZooming or QMap.Scrolling then
        tdbg ("  blob(%s): HIDE - zooming=%s scrolling=%s",
            tostring(qId), tostring(isZooming), tostring(QMap.Scrolling))
        QMap.QuestWin:Hide()
        QMap.QuestBlobQId = nil
        return
    end

    QMap.QuestWin:DrawBlob (qId, true)
    QMap.QuestWin:SetFrameLevel (QMap.Level)
    QMap.QuestWin:SetFillAlpha (255 * QMap.QuestAlpha)
    QMap.QuestWin:SetBorderAlpha (255 * QMap.QuestAlpha)
    QMap.QuestWin:SetMapID (QMap.Zone)
    QMap.QuestWin:Show()
    QMap:ClipZoneFrm (QMap.Cont, QMap.Zone, QMap.QuestWin, 1)

    tdbg ("  blob(%s): DRAW on displayed zone %s (cont %s), was=%s",
        tostring(qId), tostring(QMap.Zone), tostring(QMap.Cont),
        tostring(QMap.QuestBlobQId))
    QMap.QuestBlobQId = qId
end

-- Walks `mapID`'s parent chain in Nx.Map.MapWorldInfo until it hits
-- a non-instance map (or runs out of parents). Returns the outdoor
-- ancestor's mapID plus the world-space (X, Y) of the *innermost*
-- instance entry — that's the dungeon's portal on the outdoor map.
-- Returns nil when `mapID` isn't an instance, the data is missing,
-- or the walk reaches a dead end.
local function resolveDungeonEntrance(mapID)
    if not mapID then return nil end
    local winfo = Nx.Map and Nx.Map.MapWorldInfo
    local info = winfo and winfo[mapID]
    if not info or not info.Instance then return nil end

    -- The instance's own .X/.Y are stored in the OUTDOOR parent's
    -- world space — that's the entry portal coordinate we want.
    local entryX, entryY = info.X, info.Y
    if not entryX or not entryY then return nil end

    -- Walk parents until we land on a non-instance ancestor. Most
    -- dungeons hit their continent in one hop, but nested cases
    -- (e.g. raid wings inside an instance) need the loop.
    local outdoorID = info.parentMapID or info.EntryMId
    local guard = 0
    while outdoorID and winfo[outdoorID] and winfo[outdoorID].Instance and guard < 8 do
        outdoorID = winfo[outdoorID].parentMapID
        guard = guard + 1
    end
    if not outdoorID then return nil end

    return outdoorID, entryX, entryY
end

-- Preserve a world point calculated from a stable parent map while associating
-- the route with the player's active phased child map. This is derived from the
-- C_Map parent chain for every quest; no quest-specific opt-in is required.
function Nx.Quest:ResolveObjectivePhaseMapID(quest, mapID)
    local function safeMapID(value)
        if value == nil
            or (_G.issecretvalue and _G.issecretvalue(value)) then
            return nil
        end
        value = tonumber(value)
        return value and value > 0 and value or nil
    end

    mapID = safeMapID(mapID)
    if not mapID or not (_G.C_Map and _G.C_Map.GetBestMapForUnit
            and _G.C_Map.GetMapInfo) then
        return mapID
    end

    local ok, playerMapID = pcall(_G.C_Map.GetBestMapForUnit, "player")
    playerMapID = ok and safeMapID(playerMapID) or nil
    if not playerMapID then
        return mapID
    end

    local currentMapID = playerMapID
    for _ = 1, 16 do
        if currentMapID == mapID then
            return playerMapID
        end

        local infoOK, mapInfo = pcall(_G.C_Map.GetMapInfo, currentMapID)
        local nextMapID = infoOK and type(mapInfo) == "table"
            and safeMapID(mapInfo.parentMapID) or nil
        if not nextMapID or nextMapID == currentMapID then
            break
        end
        currentMapID = nextMapID
    end

    return mapID
end

local LIVE_CACHE_TTL = 0.5
local liveCache = {}

local function LiveQuestPos(qId)
    if not (qId and C_QuestLog) then return nil end

    local now = GetTime and GetTime() or 0
    local hit = liveCache[qId]
    if hit and now - hit.t < LIVE_CACHE_TTL then
        return hit.mapID, hit.x, hit.y
    end

    local mapID, x, y
    if C_QuestLog.GetNextWaypoint then
        mapID, x, y = C_QuestLog.GetNextWaypoint(qId)
    end

    if not mapID and C_QuestLog.GetQuestsOnMap then
        local function tryMap(m)
            if mapID or not m then return end
            local list = C_QuestLog.GetQuestsOnMap(m)
            if not list then return end
            for _, e in ipairs(list) do
                if e.questID == qId and e.x and e.y then
                    mapID, x, y = m, e.x, e.y
                    return
                end
            end
        end
        if C_TaskQuest and C_TaskQuest.GetQuestZoneID then
            tryMap(C_TaskQuest.GetQuestZoneID(qId))
        end
        tryMap(C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    end

    if not (mapID and x and y) then
        mapID, x, y = nil, nil, nil
    end
    liveCache[qId] = { t = now, mapID = mapID, x = x, y = y }
    return mapID, x, y
end

local function KnownZone(zone)
    return Nx.Quest:IsKnownZone (zone)
end

local function IsInstanceZone(zone)
    return Nx.Quest:IsInstanceZone (zone)
end

local cityZones

local function ZoneContains(mapID, wx, wy)
    local zx, zy = Nx.Map:GetZonePos (mapID, wx, wy)
    return zx and zy and zx >= 0 and zx <= 100 and zy >= 0 and zy <= 100
end

local function RefineLiveMapId(mapID, wx, wy)
    local winfo = Nx.Map.MapWorldInfo
    local src = winfo[mapID]
    if not src or src.City or src.Instance then return mapID end

    local playerMap = Nx.Map.GetDisplayableMapForPlayer
        and Nx.Map:GetDisplayableMapForPlayer()
    local pinfo = playerMap and winfo[playerMap]
    if pinfo and playerMap ~= mapID and pinfo.City and pinfo.Cont == src.Cont
        and ZoneContains (playerMap, wx, wy) then
        return playerMap
    end

    if not cityZones then
        cityZones = {}
        for id, info in pairs (winfo) do
            if type(info) == "table" and info.City and not info.Instance then
                cityZones[#cityZones + 1] = id
            end
        end
    end
    for _, id in ipairs (cityZones) do
        local info = winfo[id]
        if id ~= mapID and info and info.Cont == src.Cont and ZoneContains (id, wx, wy) then
            return id
        end
    end
    return mapID
end

local function HasInstanceMap(mapID)
    local info = Nx.Map.InstanceInfo
    if info and info[mapID] then return true end
    if Nx.isRetail and C_Map and C_Map.MapHasArt then
        local ok, has = pcall (C_Map.MapHasArt, mapID)
        return ok and has == true
    end
    return false
end

local function CatalogEndpoint(self, quest, useEnd)
    local se = (useEnd and quest["End"]) or quest["Start"]
    if not self:IsUsableLocation (se) then return nil end

    local name, zone, loc = self:UnpackSE (se)
    local x1, y1, x2, y2 = self:GetObjectiveRect (se, loc)
    x1, y1 = Nx.Map:GetWorldPos (zone, x1, y1)
    x2, y2 = Nx.Map:GetWorldPos (zone, x2, y2)
    if not x1 or not y1 or (x1 == 0 and y1 == 0) then return nil end

    return { mId = zone, x1 = x1, y1 = y1, x2 = x2, y2 = y2, name = name, source = "db-se" }
end

local function CatalogObjective(self, quest, qObj, px, py)
    local objs = quest["Objectives"]
    local questObj = objs and objs[qObj]
    local first = type(questObj) == "table" and questObj[1] or nil
    if not first then return nil, false end

    local name, zone, loc = self:UnpackObjectiveNew (first)
    if not self:IsUsableObjective (questObj, zone) then
        return nil, KnownZone (zone)
    end

    local x, y, closeMapId, inside = self:GetClosestObjectivePos (questObj, loc, zone, px, py)
    if not x or not y or (x == 0 and y == 0) then return nil, false end

    return {
        mId = closeMapId or zone, x1 = x, y1 = y, x2 = x, y2 = y,
        name = name, inside = inside, source = "db",
    }
end

local function LiveTarget(qId)
    local mapID, lx, ly = LiveQuestPos (qId)
    if not mapID or not KnownZone (mapID) then return nil end

    local wx, wy = Nx.Map:GetWorldPos (mapID, lx * 100, ly * 100)
    if not wx or not wy or (wx == 0 and wy == 0) then return nil end

    return {
        mId = RefineLiveMapId (mapID, wx, wy),
        x1 = wx, y1 = wy, x2 = wx, y2 = wy, source = "live",
    }
end

local function ResolveTrackTarget(self, quest, qId, qObj, useEnd)
    local map = Nx.Map:GetMap (1)
    local res, inDungeon

    if qObj > 0 then
        res, inDungeon = CatalogObjective (self, quest, qObj, map.PlyrX, map.PlyrY)
        if not res then
            res = LiveTarget (qId)
        end
        if not res and not inDungeon then
            res = CatalogEndpoint (self, quest, useEnd)
        end
    else
        res = CatalogEndpoint (self, quest, useEnd) or LiveTarget (qId)
    end

    if not res then
        return nil, inDungeon and "objective is inside a dungeon, no position" or "no position"
    end

    if IsInstanceZone (res.mId) then
        if IsInInstance and IsInInstance() then
            if not HasInstanceMap (res.mId) then
                return nil, "inside a dungeon without a map"
            end
        else
            local outdoorID, entryX, entryY = resolveDungeonEntrance (res.mId)
            if outdoorID then
                res.mId = outdoorID
                res.x1, res.y1, res.x2, res.y2 = entryX, entryY, entryX, entryY
                res.inside = nil
                res.entrance = true
            end
        end
    end

    return res
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Track quest on map
-------------------------------------------------------------------------------

function Nx.Quest:CalcAutoTrack (cur)

    local Nx = Nx
    local Quest = Nx.Quest
    local curq = Quest.CurQ
    local qopts = Nx.Quest:GetQuestOpts()

    Quest.Tracking = {}
    local closest = false
    local dist = 99999999

    if cur.Q then

--        Quest.Tracking[cur.QId] = cur.TrackMask

        local closeI = cur.CloseObjI

        -- Quest-complete branch: route to the turn-in NPC (End coord),
        -- not whatever stale CloseObjI was left behind from the active
        -- phase. Following objective POIs on a completed delivery /
        -- talk-to-NPC quest sent the goto arrow ping-ponging between
        -- the (now-irrelevant) objective and the actual ender.
        if cur.Complete then
            Quest.Tracking[cur.QId] = cur.TrackMask
            Quest:TrackOnMap (cur.QId, 0, true, true, true)
        elseif closeI and closeI >= 0 then

            Quest.Tracking[cur.QId] = cur.TrackMask            -- bit_lshift (1, closeI)
            Quest:TrackOnMap (cur.QId, closeI, cur.QI > 0 or cur.Party, true, true)
        end

        for objn = 1, 15 do

            local obj = cur.Q[objn + 3]
            if not obj then
                break
            end

            local obit = bit_lshift (1, objn)
            if bit_band (cur.TrackMask, obit) > 0 then

                if Quest:GetObjectiveType (obj) == 1 then

                    local d = cur["OD"..objn]

                    if d and d < dist then
                        dist = d
                        closest = cur
--                        Quest.ClosestSpanI = objn
                    end
                end
            end
        end
    end

--    Quest.ClosestSpanCur = closest
end

-------------------------------------------------------------------------------
-- Is targeted already?
-------------------------------------------------------------------------------

function Nx.Quest:IsTargeted (qId, qObj, x1, y1, x2, y2)

    local typ, tid = Nx.Map:GetTargetInfo()
    if typ == "Q" then

        local tqid = floor (tid / 100)
        if tqid == qId then        -- Same as us?

            if x1 then
                local tx1, ty1, tx2, ty2 = Nx.Map:GetTargetPos()
                -- Tolerance-based compare. Exact coord equality used
                -- to break here: the C_QuestLog title-row override
                -- can hand back two different uiMapIDs for the same
                -- NPC (e.g. Exodar's hippogryph master shows as both
                -- 97 Azuremyst and 103 Exodar in Blizzard's data
                -- because the NPC sits at the city boundary). Each
                -- response resolves to the same world point modulo
                -- sub-yard float wobble, but `x1 ~= tx1` still
                -- returned mismatch -> AddTarget fired on every
                -- CalcAutoTrack tick (~5x/sec) -> UpdateTrackingDelay
                -- reset to 0 every time -> CalcTracking rebuilt the
                -- routing path every frame -> visible flicker plus
                -- arrow direction jitter. ~5 world units ≈ 23 yards
                -- is well below the smallest deliberate target move
                -- the live API makes and well above the float noise.
                local EPS = 5
                if abs(x1 - tx1) > EPS or abs(y1 - ty1) > EPS
                    or abs(x2 - tx2) > EPS or abs(y2 - ty2) > EPS then
                    return
                end
            end

            if not qObj then
                return true
            end

            if tid % 100 == qObj then
                return true
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Track quest on map
-------------------------------------------------------------------------------

function Nx.Quest:TrackOnMap (qId, qObj, useEnd, target, skipSame)

    local Quest = Nx.Quest
    local Map = Nx.Map
    local BlizIndex = nil
    local quest = Nx.Quests[qId]

    if Nx.qdb.profile.QuestWatch.Sync then
        if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
            BlizIndex = C_QuestLog.GetLogIndexForQuestID (qId)
        elseif GetQuestLogIndexByID then
            BlizIndex = GetQuestLogIndexByID (qId)
        else
            local i = 1
            while GetQuestLogTitle (i) do
                local _, _, _, _, _, _, _, questID = GetQuestLogTitle (i)
                if questID == qId then
                    BlizIndex = i
                    break
                end
                i = i + 1
            end
        end
    end
    tbegin()
    tdbg ("call qId=%s qObj=%s useEnd=%s target=%s skipSame=%s inDB=%s",
        tostring(qId), tostring(qObj), tostring(useEnd), tostring(target),
        tostring(skipSame), tostring(quest ~= nil))

    if not quest then
        tdbg ("  BAIL: Nx.Quests[%s] is nil (quest not in bundled DB and not patched)",
            tostring(qId))
        return
    end

    local tbits = Quest.Tracking[qId] or 0

    -- For qObj > 0 (a specific objective): tracking bit must be set.
    -- For qObj == 0 (title-row / "the whole quest"): any tracking bit
    -- counts. cur.TrackMask only ever sets bits 1-15 (per-objective),
    -- never bit 0.
    local track
    if qObj == 0 then
        track = (tbits ~= 0) and 1 or 0
    else
        track = bit_band (tbits, bit_lshift (1, qObj))
    end

    local function clearOwnTarget (force)
        local typ, tid = Map:GetTargetInfo()
        if typ == "Q" and floor (tid / 100) == qId then
            if force or tbits == 0 or (tid == qId * 100 + qObj) then
                -- Clearing an active map target is independent from
                -- removing a quest from either watch list.
                self.Map:ClearTargets()
                Quest:UpdateQuestBlob (nil)
            end
        end
    end

    if track <= 0 then
        tdbg ("  tracking bit not set -> clear own target (tbits=0x%x)", tbits)
        clearOwnTarget()
        return
    end

    local QMapNow = _G.NxMap1 and _G.NxMap1.NxMap
    if QMapNow and QMapNow.QuestBlobQId and QMapNow.QuestBlobQId ~= qId then
        Quest:UpdateQuestBlob (nil)
    end

    local res, why = ResolveTrackTarget (self, quest, qId, qObj, useEnd)
    if not res then
        tdbg ("  NO TARGET: %s", tostring(why))
        clearOwnTarget (true)
        if not skipSame and why == "no position" then
            if not Nx.Quest:PatchQuestFromBlizzard (qId) then
                Nx.Quest:MsgNotInDB ("Z")
            end
        end
        return
    end

    tdbg ("  tbits=0x%x source=%s zone=%s inside=%s",
        tbits, tostring(res.source), tostring(res.mId), tostring(res.inside))

    if BlizIndex and Quest:GetQuest (qId) == "W"
            and Quest.Watch and Quest.Watch.SyncBlizzardWatch then
        Quest.Watch:SyncBlizzardWatch (qId, BlizIndex, true)
    end
    local curBlob = self.QIds[qId]
    Quest:UpdateQuestBlob ((curBlob and not curBlob.Complete) and qId or nil)

    if not target then
        tdbg ("  no target requested (target=false) - blob only")
        self.Map:GotoPlayer()
        return
    end

    local mId = res.mId
    local x1, y1, x2, y2 = res.x1, res.y1, res.x2, res.y2
    local name = res.name

    if qObj == 0 and C_QuestLog then
        local curHere = self.QIds and self.QIds[qId]
        local titlePart = curHere and curHere.Title
            or (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID (qId))
            or name

        -- GetNextWaypointText is only set for quests with explicit waypoint
        -- scripting; fall back to the first unfinished objective text.
        local wpText = C_QuestLog.GetNextWaypointText
            and C_QuestLog.GetNextWaypointText (qId)
        if (not wpText or wpText == "") and C_QuestLog.GetQuestObjectives then
            local objs = C_QuestLog.GetQuestObjectives (qId)
            if objs then
                for _, o in ipairs (objs) do
                    if o and not o.finished and o.text and o.text ~= "" then
                        wpText = o.text
                        break
                    end
                end
                if (not wpText or wpText == "") and #objs > 0 then
                    wpText = objs[#objs] and objs[#objs].text
                end
            end
        end

        if wpText and wpText ~= "" then
            name = wpText
        elseif titlePart then
            name = titlePart
        end
    end

    local cur = self.QIds[qId]
    if cur then
        if qObj > 0 then
            name = cur[qObj] or name
        end
        name = name or cur.Title
        if cur.Complete then
            name = (name or "") .. " |cff80ff80" .. L["(Complete)"]
        end
    end
    name = name or "?"

    if res.entrance then
        name = name .. " |cff80c0ff" .. L["(dungeon entrance)"]
    end

    -- Campaign phases can expose points on a stable parent canvas even
    -- though the player is on a child map. Project both corners onto the
    -- child canvas, then associate the route with that map.
    local sourceMapID = mId
    local phaseMapID = self:ResolveObjectivePhaseMapID (quest, sourceMapID)
    if phaseMapID and phaseMapID ~= sourceMapID and self.ProjectObjectivePoint then
        local zx1, zy1 = Map:GetZonePos (sourceMapID, x1, y1)
        local zx2, zy2 = Map:GetZonePos (sourceMapID, x2, y2)
        local projectedMapID, projectedX1, projectedY1 =
            self:ProjectObjectivePoint (Map:GetMap (1), sourceMapID, zx1, zy1, phaseMapID)
        local projectedMapID2, projectedX2, projectedY2 =
            self:ProjectObjectivePoint (Map:GetMap (1), sourceMapID, zx2, zy2, phaseMapID)
        if projectedMapID and projectedMapID2 then
            mId = projectedMapID
            x1, y1 = projectedX1, projectedY1
            x2, y2 = projectedX2, projectedY2
        else
            tdbg ("  BAIL: phase projection failed (%s -> %s)",
                tostring(sourceMapID), tostring(phaseMapID))
            return
        end
    else
        mId = phaseMapID or sourceMapID
    end

    if (not x1) or (not y1)
        or (x1 == 0 and y1 == 0 and x2 == 0 and y2 == 0) then
        tdbg ("  BAIL: zero/nil world coords (mId=%s x1=%s y1=%s)",
            tostring(mId), tostring(x1), tostring(y1))
        return
    end

    -- A target that sits inside an objective area follows the player, so the
    -- arrow reads "you are here" instead of chasing a stale point. Update it
    -- in place: re-adding it would rebuild the route every frame.
    local tar = self.Map.Targets and self.Map.Targets[1]
    if tar and tar.TargetType == "Q" and tar.TargetId == qId * 100 + qObj
        and (res.inside or tar.Inside) then
        tar.TargetX1, tar.TargetY1, tar.TargetX2, tar.TargetY2 = x1, y1, x2, y2
        tar.TargetMX = (x1 + x2) * .5
        tar.TargetMY = (y1 + y2) * .5
        tar.MapId = mId
        tar.Inside = res.inside or nil
        Map:SetTargetName (name)
        return
    end

    if skipSame and self:IsTargeted (qId, qObj, x1, y1, x2, y2) then
        tdbg ("  same target, name refresh only")
        Map:SetTargetName (name)
        return
    end

    tdbg ("  SET TARGET mId=%s x=%.0f y=%.0f name=%s",
        tostring(mId), x1 or 0, y1 or 0, tostring(name))
    local newTar = self.Map:SetTarget ("Q", x1, y1, x2, y2, false, qId * 100 + qObj, name, false, mId)
    if newTar then
        newTar.Inside = res.inside or nil
    end

    self.Map.Guide:ClearAll()
    self.Map:GotoPlayer()
end


local Carbonite = _G.Carbonite
if Carbonite and Carbonite.Core and Carbonite.Core.EventBus then
    Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
        if not (Carbonite.Core.SlashCommands and Carbonite.Core.Logger) then return end
        local log = Carbonite.Core.Logger:Get("Tracking")
        local sv = _G.NXQuest
        if sv and sv.TrackDebug then
            Nx.Quest.TrackDebug = true
            Nx.Quest.TrackQuiet = sv.TrackQuiet and true or false
            log:info("trace restored from SavedVariables (%s)",
                Nx.Quest.TrackQuiet and "quiet" or "chat")
        end
        Carbonite.Core.SlashCommands:Register("qtrack", function(rest)
            local cmd = tostring(rest or ""):lower():match("^%s*(%S*)")

            local function persist()
                local db = _G.NXQuest
                if not db then return end
                db.TrackDebug = Nx.Quest.TrackDebug or nil
                db.TrackQuiet = Nx.Quest.TrackQuiet or nil
            end

            if cmd == "quiet" then
                Nx.Quest.TrackDebug = true
                Nx.Quest.TrackQuiet = true
                persist()
                log:info("trace ON (quiet) - lines only to NXQuest.TrackLog in")
                log:info("  WTF/Account/<acct>/SavedVariables/Carbonite.Quests.lua")
                log:info("  (written on /reload or logout)")
                return
            elseif cmd == "on" then
                Nx.Quest.TrackDebug = true
                Nx.Quest.TrackQuiet = false
                persist()
                log:info("trace ON - lines also go to NXQuest.TrackLog in")
                log:info("  WTF/Account/<acct>/SavedVariables/Carbonite.Quests.lua")
                log:info("  (written on /reload or logout)")
                return
            elseif cmd == "off" then
                Nx.Quest.TrackDebug = false
                persist()
            elseif cmd == "wipe" then
                if _G.NXQuest then _G.NXQuest.TrackLog = nil end
                log:info("TrackLog wiped")
                return
            elseif cmd == "state" or cmd == "" then
                local function say(fmt, ...)
                    local ok, msg = pcall(string.format, fmt, ...)
                    if not ok then return end
                    log:info("%s", msg)
                    Nx.Quest.TrackLogWrite(msg)
                end

                local QMap = _G.NxMap1 and _G.NxMap1.NxMap
                local typ, tid = Nx.Map:GetTargetInfo()
                say("state: trace %s", Nx.Quest.TrackDebug and "ON" or "OFF")
                say("  blobs=%s showQuestBlobs=%s questPOI=%s blobQId=%s worldBlob=%s",
                    tostring(Nx.BlobsAvailable),
                    tostring(Nx.db and Nx.db.char and Nx.db.char.Map
                        and Nx.db.char.Map.ShowQuestBlobs),
                    tostring(_G.GetCVarBool and _G.GetCVarBool("questPOI")),
                    tostring(QMap and QMap.QuestBlobQId),
                    tostring(QMap and QMap.ShowingWorldQuestBlob))
                say("  autoTarget=%s target=%s/%s superTracked=%s activeQID=%s",
                    tostring(Nx.Quest.Watch and Nx.Quest.Watch.ButATarget
                        and Nx.Quest.Watch.ButATarget:GetPressed()),
                    tostring(typ), tostring(tid),
                    tostring(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
                        and C_SuperTrack.GetSuperTrackedQuestID()),
                    tostring(Nx.Quest.ActiveQID))
                say("  stLastSet=%s stLockoutUntil=%s now=%s",
                    tostring(Nx.Quest._stLastSet),
                    tostring(Nx.Quest._stLockoutUntil),
                    tostring(GetTime and GetTime()))
                local n = 0
                for id, mask in pairs(Nx.Quest.Tracking or {}) do
                    n = n + 1
                    say("  Tracking[%s] = 0x%x", tostring(id), mask or 0)
                end
                if n == 0 then say("  Tracking is empty") end
                log:info("TrackLog: %d lines (in SavedVariables/Carbonite.Quests.lua)",
                    _G.NXQuest and _G.NXQuest.TrackLog and #_G.NXQuest.TrackLog or 0)
                return
            else
                log:info("usage: /cb qtrack [on|off|state|wipe]")
                return
            end
            log:info("trace %s", Nx.Quest.TrackDebug and "ON" or "OFF")
        end, "trace quest tracking decisions (on|off|state|wipe)")
    end)
end
