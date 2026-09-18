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
    if DEFAULT_CHAT_FRAME then
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
    local outdoorID = info.parentMapID
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

local function HasCatalogPointObjective(questObj)
    if type(questObj) ~= "table" then return false end

    for _, location in ipairs(questObj) do
        if type(location) == "string" then
            local _, mapID, poiType = Nx.Quest:UnpackObjectiveNew(location)
            local x, y = Nx.Quest:UnpackLocPtOff(location)
            if poiType == 32 and tonumber(mapID) and tonumber(mapID) > 0
                and type(x) == "number" and type(y) == "number" then
                return true
            end
        end
    end
    return false
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
    end

    if quest then

        local tbits = Quest.Tracking[qId] or 0
--[[
        if tbits == 0 then    -- Nothing tracked?

            local typ, tid = Map:GetTargetInfo()
            if typ == "Q" then

                local tqid = floor (tid / 100)
                if tqid == qId then        -- Same as us?
                    self.Map:ClearTargets()
                end
            end
            return
        end
--]]
        -- For qObj > 0 (a specific objective): tracking bit must be set.
        -- For qObj == 0 (title-row / "the whole quest"): any tracking bit
        -- counts. cur.TrackMask only ever sets bits 1-15 (per-objective),
        -- never bit 0, so the legacy `tbits & 1` test was always 0 and
        -- the blob/target draw block below silently no-op'd whenever a
        -- click came in via the title row (super-track flow).
        local track
        if qObj == 0 then
            track = (tbits ~= 0) and 1 or 0
        else
            track = bit_band (tbits, bit_lshift (1, qObj))
        end

        if track > 0 then
            local QMapNow = _G.NxMap1 and _G.NxMap1.NxMap
            if QMapNow and QMapNow.QuestBlobQId and QMapNow.QuestBlobQId ~= qId then
                Quest:UpdateQuestBlob (nil)
            end
        end

        local questObj
        local name, zone, loc

        if qObj == 0 then
            questObj = useEnd and quest["End"] or quest["Start"]
            name, zone, loc = Quest:UnpackSE (questObj)
        else
            if quest["Objectives"] ~= nil then
                questObj = quest["Objectives"][qObj]
                if questObj and questObj[1] then
                    name, zone, loc = Nx.Quest:UnpackObjectiveNew (questObj[1])
                end
            end
            -- Fallback for quests that ship with Start/End only (no
            -- Objectives entries, e.g. MoP 31477). Clicking an
            -- objective row would otherwise leave zone nil and the
            -- goto block would silently skip. Use the quest's End
            -- (or Start) coord so the click still resolves to a
            -- usable target.
            --
            -- Zone 0 counts as "no zone" here: PatchQuestFromBlizzard
            -- writes "<text>|0|32|0|0|6|6" when the live API knows an
            -- objective's text but no coordinates (every TBC quest,
            -- where GetQuestObjectives answers but there is no POI
            -- data). Lua treats 0 as true, so the guard used to accept
            -- that sentinel, skip this fallback and hand mId = 0 to the
            -- goto block, which nils it and reports "This objective
            -- zone is not in the database" - on quests whose Start/End
            -- coords were right there (reported for quest 11020).
            if not zone or zone == 0 then
                local qse = useEnd and quest["End"] or quest["Start"]
                if qse then
                    questObj = qse
                    name, zone, loc = Quest:UnpackSE (qse)
                end
            end
        end

--        Nx.prt ("TrackOnMap %s %s %s %s %s", qId, qObj, track, name, zone)

        tdbg ("  tbits=0x%x track=%s name=%s zone=%s",
            tbits, tostring(track), tostring(name), tostring(zone))
        if not (track > 0 and zone) then
            tdbg ("  BAIL: %s -> falls into the clear-tracking branch",
                track > 0 and "zone unresolved" or "tracking bit not set")
        end

        if track > 0 and zone then
            if BlizIndex and Quest:GetQuest (qId) == "W"
                    and Quest.Watch and Quest.Watch.SyncBlizzardWatch then
                Quest.Watch:SyncBlizzardWatch (qId, BlizIndex, true)
            end
            local curBlob = self.QIds[qId]
            Quest:UpdateQuestBlob ((curBlob and not curBlob.Complete) and qId or nil)

            local mId = zone
            -- Reject sentinel mapId 0: bundled DB writes "<npc>|0|32|0|0"
            -- when an extractor couldn't resolve a position. Letting it
            -- through would call GetWorldPos(0, ...) which returns (0,0)
            -- and the arrow snaps to world origin.
            if mId == 0 then mId = nil end
            if not mId then
                tdbg ("  BAIL: mapId sentinel 0 -> 'objective zone not in database'")
            end
            if mId then

                if not target then
                    tdbg ("  no target requested (target=false) - blob only")
                end

                if target then

                    local x1, y1, x2, y2

                    if qObj > 0 then

                        local map = Map:GetMap (1)
                        local px = map.PlyrX
                        local py = map.PlyrY

                        -- FIX!!!!!!!!!!!!

--                        x1, y1, x2, y2 = Quest:GetClosestObjectiveRect (questObj, mId, px, py)
                        -- The third return value is the zone of the
                        -- winning entry. Necessary when a multi-zone
                        -- Objectives[] list (e.g. an area straddling
                        -- a zone border) puts the geometrically
                        -- closest entry in a different zone than the
                        -- first-listed one. Without this, mId stays
                        -- on the first entry's zone and CalcTracking
                        -- sees src/dst on different maps -> router
                        -- builds a detour through whatever transit
                        -- zone connects them (e.g. Azuremyst player +
                        -- Exodar-tagged first entry sent the path
                        -- through Exodar even when the closest
                        -- Azuremyst entry was 10y away).
                        local closeMapId
                        x1, y1, closeMapId = Quest:GetClosestObjectivePos (questObj, loc, mId, px, py)
                        if closeMapId then
                            mId = closeMapId
                        end

                        -- On retail/Wrath+, prefer Blizzard's live
                        -- waypoint over the bundled coord whenever
                        -- the API has one. Bundled DB carries legacy
                        -- mapIds that may no longer resolve (e.g.
                        -- quest 37444 "Inoculation" lists mapId 468
                        -- but retail Azuremyst Isle is uiMapID 97)
                        -- — GetWorldPos either returns 0,0 or a
                        -- stale-but-wrong coord, sending tracking to
                        -- the wrong place. The API knows the live
                        -- current-objective coord regardless.
                        -- Objectives with catalogued individual points must
                        -- keep those exact points. Blizzard's public
                        -- GetNextWaypoint/GetQuestsOnMap values are one
                        -- representative quest POI, not one position per
                        -- objective; replacing a Warding Totem coordinate with
                        -- that quest-level value makes the route point away
                        -- from the selected totem.
                        local keepCatalogObjective =
                            HasCatalogPointObjective(questObj)
                        if C_QuestLog and not keepCatalogObjective then
                            local wpMapID, wpX, wpY
                            if C_QuestLog.GetNextWaypoint then
                                wpMapID, wpX, wpY = C_QuestLog.GetNextWaypoint(qId)
                            end
                            if not wpMapID and C_QuestLog.GetQuestsOnMap then
                                local function tryMap(m)
                                    if wpMapID or not m then return end
                                    local list = C_QuestLog.GetQuestsOnMap(m)
                                    if not list then return end
                                    for _, e in ipairs(list) do
                                        if e.questID == qId and e.x and e.y then
                                            wpMapID, wpX, wpY = m, e.x, e.y
                                            return
                                        end
                                    end
                                end
                                if C_TaskQuest and C_TaskQuest.GetQuestZoneID then
                                    tryMap(C_TaskQuest.GetQuestZoneID(qId))
                                end
                                -- Use the PLAYER's actual zone, NOT
                                -- Map:GetCurrentMapId() (returns the
                                -- displayed map, which Carbonite swaps
                                -- on mouseover) and NOT MapUtil's
                                -- GetDisplayableMapForPlayer (can also
                                -- follow WorldMapFrame's override on
                                -- retail). C_Map.GetBestMapForUnit
                                -- always returns the player's true
                                -- zone, independent of UI state.
                                tryMap(C_Map and C_Map.GetBestMapForUnit
                                    and C_Map.GetBestMapForUnit("player"))
                            end
                            if wpMapID and wpX and wpY then
                                -- Retail's MapWorldInfo is keyed by the
                                -- same uiMapIDs that Blizzard hands us,
                                -- so use wpMapID directly. Earlier code
                                -- ran wpMapID through GetLegacyMapInfo,
                                -- which translates to HBD's legacy ids
                                -- (e.g. uiMapID 103 -> 471). Those
                                -- collide with unrelated Carbonite
                                -- mapIds — 471 in Carbonite is the
                                -- Mogu'shan Vaults raid-entry record,
                                -- so the translated GetWorldPos call
                                -- handed back the Pandaria dungeon
                                -- entrance and the arrow snapped to
                                -- the wrong continent.
                                local mapForPos = wpMapID
                                local nx, ny = Map:GetWorldPos(mapForPos, wpX * 100, wpY * 100)
                                if nx and ny and (nx ~= 0 or ny ~= 0) then
                                    x1, y1 = nx, ny
                                    mId = mapForPos
                                end
                            end
                        end

                        x2 = x1
                        y2 = y1
                    else

                        x1, y1, x2, y2 = Quest:GetObjectiveRect (questObj, loc)
                        x1, y1 = Map:GetWorldPos (mId, x1, y1)
                        x2, y2 = Map:GetWorldPos (mId, x2, y2)
                    end

                    -- Title-row click on retail / Wrath+: prefer Blizzard's
                    -- live next-waypoint over the static End coord. Blizz's
                    -- own arrow uses GetNextWaypoint(questID) and advances
                    -- it as objectives complete; using the same call makes
                    -- the goto arrow follow the *current* objective rather
                    -- than parking at one fixed turn-in point.
                    -- The arrow label is composed as "Quest Title\n
                    -- Objective Hint" so the user sees both.
                    -- Title-row click on retail / Wrath+: compose a richer
                    -- arrow label, and when Blizzard knows a live waypoint
                    -- for this quest also override the static End coords
                    -- so the arrow follows the *current* objective.
                    --
                    -- The two are independent: most quests have no scripted
                    -- waypoint (GetNextWaypoint returns nil) but they still
                    -- have objective text from GetQuestObjectives, so we
                    -- always try to add the objective to the label even
                    -- when the coords stay static.
                    if qObj == 0 and C_QuestLog then
                        local overrideMID, overrideX, overrideY
                        if C_QuestLog.GetNextWaypoint then
                            local wpMapID, wpX, wpY = C_QuestLog.GetNextWaypoint(qId)
                            if wpMapID and wpX and wpY then
                                overrideMID, overrideX, overrideY = wpMapID, wpX, wpY
                            end
                        end
                        -- Fallback: walk the live POI list for the relevant
                        -- map and pick this quest's current entry. Most
                        -- non-scripted quests have no GetNextWaypoint but
                        -- their POI x/y in GetQuestsOnMap *does* advance as
                        -- objectives complete, so this keeps the arrow
                        -- pointed at the current objective.
                        if not overrideMID and C_QuestLog.GetQuestsOnMap then
                            local function tryMap(m)
                                if overrideMID or not m then return end
                                local list = C_QuestLog.GetQuestsOnMap(m)
                                if not list then return end
                                for _, e in ipairs(list) do
                                    if e.questID == qId and e.x and e.y then
                                        overrideMID, overrideX, overrideY = m, e.x, e.y
                                        return
                                    end
                                end
                            end
                            if C_TaskQuest and C_TaskQuest.GetQuestZoneID then
                                tryMap(C_TaskQuest.GetQuestZoneID(qId))
                            end
                            tryMap(Map.GetCurrentMapId and Map:GetCurrentMapId())
                        end
                        if overrideMID then
                            -- See the matching note in the qObj>0 path
                            -- above: use the Blizzard uiMapID directly,
                            -- not the GetLegacyMapInfo translation.
                            -- That HBD-legacy id collides with
                            -- unrelated Carbonite mapIds (uiMapID 103
                            -- -> 471 = Mogu'shan Vaults instance),
                            -- which is the "arrow snaps to wrong
                            -- continent / world origin" symptom.
                            local mapForPos = overrideMID
                            local nx, ny = Map:GetWorldPos(mapForPos,
                                overrideX * 100, overrideY * 100)
                            -- Reject 0,0: GetWorldPos returns that when
                            -- the mapForPos can't be resolved, and the
                            -- bundled End coord (already converted above)
                            -- is then clobbered by a world-origin point,
                            -- sending the arrow ~15000y across the map.
                            if nx and ny and (nx ~= 0 or ny ~= 0) then
                                x1, y1, x2, y2 = nx, ny, nx, ny
                                mId = mapForPos
                            end
                        end

                        local titlePart
                        local curHere = self.QIds and self.QIds[qId]
                        if curHere and curHere.Title then
                            titlePart = curHere.Title
                        else
                            local titleFromAPI = C_QuestLog.GetTitleForQuestID
                                and C_QuestLog.GetTitleForQuestID(qId)
                            titlePart = titleFromAPI or name
                        end

                        -- GetNextWaypointText is only set for quests with
                        -- explicit waypoint scripting (rare); fall back to
                        -- the first unfinished objective from the live
                        -- objective list (covers the common case).
                        local wpText = C_QuestLog.GetNextWaypointText
                            and C_QuestLog.GetNextWaypointText(qId)
                        if (not wpText or wpText == "") and C_QuestLog.GetQuestObjectives then
                            local objs = C_QuestLog.GetQuestObjectives(qId)
                            if objs then
                                for _, o in ipairs(objs) do
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

                        -- Prefer the objective text (it's the actionable
                        -- bit); fall back to the quest title when no
                        -- objective is available.
                        if wpText and wpText ~= "" then
                            name = wpText
                        elseif titlePart then
                            name = titlePart
                        end
                    end

                    local cur = self.QIds[qId]
--                    local _, cur = self:FindCur (qId)
                    if cur then
                        if qObj > 0 then
                            name = cur[qObj] or name
--                            Nx.prt ("TrackOnMap name %s", name)
                        end

                        if cur.Complete then
                            name = name .. " |cff80ff80" ..L["(Complete)"]
                        end
                    end

                    -- If the resolved objective sits inside a dungeon
                    -- (instance map), the interior coords are unreachable
                    -- from the open world — the player can't run there.
                    -- Substitute the dungeon's entrance on the outdoor
                    -- parent map so the arrow points to where the player
                    -- actually needs to go. Title-row overrides above
                    -- (GetNextWaypoint / GetQuestsOnMap) may already have
                    -- handed us an outdoor mapID; only redirect when the
                    -- target is still inside the instance.
                    local outdoorID, entryX, entryY = resolveDungeonEntrance(mId)
                    if outdoorID then
                        mId = outdoorID
                        x1, y1 = entryX, entryY
                        x2, y2 = entryX, entryY
                        name = name .. " |cff80c0ff" .. L["(dungeon entrance)"]
                    end

                    -- Campaign phases can expose points on a stable parent
                    -- canvas even though the player is on a child map. Do not
                    -- merely relabel that parent-world coordinate: the fixed
                    -- child canvas interprets it as local and sends the target
                    -- far off-map. Project both corners onto the child canvas
                    -- through the same C_Map-backed transform used by the icon
                    -- provider, then associate the route with that map.
                    local sourceMapID = mId
                    local phaseMapID = self:ResolveObjectivePhaseMapID(
                        quest, sourceMapID)
                    if phaseMapID and phaseMapID ~= sourceMapID
                        and self.ProjectObjectivePoint then
                        local zx1, zy1 = Map:GetZonePos(sourceMapID, x1, y1)
                        local zx2, zy2 = Map:GetZonePos(sourceMapID, x2, y2)
                        local projectedMapID, projectedX1, projectedY1 =
                            self:ProjectObjectivePoint(
                                Map:GetMap(1),
                                sourceMapID,
                                zx1,
                                zy1,
                                phaseMapID
                            )
                        local projectedMapID2, projectedX2, projectedY2 =
                            self:ProjectObjectivePoint(
                                Map:GetMap(1),
                                sourceMapID,
                                zx2,
                                zy2,
                                phaseMapID
                            )
                        if projectedMapID and projectedMapID2 then
                            mId = projectedMapID
                            x1, y1 = projectedX1, projectedY1
                            x2, y2 = projectedX2, projectedY2
                        else
                            -- Projection failure is safer as an untracked
                            -- point than a confidently wrong cross-map route.
                            tdbg ("  BAIL: phase projection failed (%s -> %s)",
                                tostring(sourceMapID), tostring(phaseMapID))
                            return
                        end
                    else
                        mId = phaseMapID or sourceMapID
                    end

                    -- Zero-coord guard: if every coord resolved to 0,
                    -- the source data is unusable (typical for the
                    -- "<npc>|0|32|0|0" sentinel that backfillers write
                    -- when no live position was available). Bailing
                    -- here keeps the arrow on the previous target
                    -- rather than snapping it to world origin and
                    -- thrashing the path on every CalcAutoTrack tick.
                    if (not x1) or (not y1)
                        or (x1 == 0 and y1 == 0 and x2 == 0 and y2 == 0) then
                        tdbg ("  BAIL: zero/nil world coords (mId=%s x1=%s y1=%s)",
                            tostring(mId), tostring(x1), tostring(y1))
                        return
                    end

                    if skipSame then
                        if self:IsTargeted (qId, qObj, x1, y1, x2, y2) then

                            tdbg ("  same target, name refresh only")
                            Map:SetTargetName (name)
                            return
                        end
                    end

                    tdbg ("  SET TARGET mId=%s x=%.0f y=%.0f name=%s",
                        tostring(mId), x1 or 0, y1 or 0, tostring(name))
                    self.Map:SetTarget ("Q", x1, y1, x2, y2, false, qId * 100 + qObj, name, false, mId)
--                    Nx.prt ("TrackOnMap %s %s %s", qId, qObj, name)

                    self.Map.Guide:ClearAll()
                end

                self.Map:GotoPlayer()

            else
                -- No zone resolved for the objective. Try a live patch
                -- first; if it filled in coords the next refresh will
                -- pick them up and the user never sees the message.
                -- PatchQuestFromBlizzard self-checks API availability;
                -- when it returns false (no API or no Blizzard data),
                -- fall back to the legacy toast.
                if not Nx.Quest:PatchQuestFromBlizzard(qId) then
                    Nx.Quest:MsgNotInDB ("Z")
                end
--                Nx.prt ("quest zone %s", zone)
            end

        else    -- Clear tracking

            local typ, tid = Map:GetTargetInfo()
            if typ == "Q" then

                local tqid = floor (tid / 100)
                if tqid == qId then        -- Same quest as us?

                    if tbits == 0 or (tid == qId * 100 + qObj) then
                        -- Clearing an active map target is independent from
                        -- removing a quest from either watch list.
                        self.Map:ClearTargets()
                        Quest:UpdateQuestBlob (nil)
                    end
                end
            end
        end
    end
end


local Carbonite = _G.Carbonite
if Carbonite and Carbonite.Core and Carbonite.Core.EventBus then
    Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
        if not (Carbonite.Core.SlashCommands and Carbonite.Core.Logger) then return end
        local log = Carbonite.Core.Logger:Get("Tracking")
        Carbonite.Core.SlashCommands:Register("qtrack", function(rest)
            local cmd = tostring(rest or ""):lower():match("^%s*(%S*)")

            if cmd == "on" then
                Nx.Quest.TrackDebug = true
                log:info("trace ON - lines also go to NXQuest.TrackLog in")
                log:info("  WTF/Account/<acct>/SavedVariables/Carbonite.Quests.lua")
                log:info("  (written on /reload or logout)")
                return
            elseif cmd == "off" then
                Nx.Quest.TrackDebug = false
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
