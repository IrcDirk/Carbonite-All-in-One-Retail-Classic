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
        local i = 1
        while GetQuestLogTitle(i) do
            local _, _, _, _, _, _, _, questID = GetQuestLogTitle(i)
            if questID == qId then
                BlizIndex = i
            else
                if (IsQuestWatched(i)) then
                    RemoveQuestWatch(i)
                end
            end
        i = i + 1
        end
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
            if not zone then
                local qse = useEnd and quest["End"] or quest["Start"]
                if qse then
                    questObj = qse
                    name, zone, loc = Quest:UnpackSE (qse)
                end
            end
        end

--        Nx.prt ("TrackOnMap %s %s %s %s %s", qId, qObj, track, name, zone)

        if track > 0 and zone then
            if Nx.qdb.profile.QuestWatch.Sync then
                if BlizIndex then
                    if not (IsQuestWatched(BlizIndex)) then
                        AddQuestWatch(BlizIndex)
                    end
                end
            end
    local QMap = NxMap1.NxMap
    if not InCombatLockdown() then
        local cur = self.QIds[qId]
        if cur then
            -- Don't draw regular quest blob if a world quest blob is being shown
            if not cur.Complete and Nx.BlobsAvailable and not QMap.ShowingWorldQuestBlob then
                QMap.QuestWin:DrawNone();
                -- Hide quest blobs during zoom animation or manual scrolling to prevent position/scale mismatch
                -- Note: We check for scale change rather than StepTime != 0, because StepTime is also set
                -- when following the player (position change only), and we want blobs visible during that
                local isZooming = math.abs(QMap.ScaleDraw - QMap.Scale) > 0.001
                if isZooming or QMap.Scrolling then
                    QMap.QuestWin:Hide()
                elseif Nx.db.char.Map.ShowQuestBlobs and Nx.Quests[-qId] then
                    QMap.QuestWin:DrawBlob(qId,true)
                    QMap.QuestWin:SetFrameLevel(QMap.Level)
                    QMap.QuestWin:SetFillAlpha(255 * QMap.QuestAlpha)
                    QMap.QuestWin:SetBorderAlpha( 255 * QMap.QuestAlpha )
                    QMap.QuestWin:SetMapID(QMap.Zone)
                    QMap.QuestWin:Show()
                    -- Re-anchor AFTER Show() — on retail the
                    -- QuestPOIFrame's internal SetMapID/Show path
                    -- repositions itself relative to the player,
                    -- producing the "blob follows character, snaps
                    -- back" symptom when ClipZoneFrm runs before.
                    -- Putting our clip last gives us the final word
                    -- on position.
                    QMap:ClipZoneFrm( QMap.Cont, QMap.Zone, QMap.QuestWin, 1 )
                else
                    QMap.QuestWin:Hide()
                end
            end
        end
    end

            local mId = zone
            -- Reject sentinel mapId 0: bundled DB writes "<npc>|0|32|0|0"
            -- when an extractor couldn't resolve a position. Letting it
            -- through would call GetWorldPos(0, ...) which returns (0,0)
            -- and the arrow snaps to world origin.
            if mId == 0 then mId = nil end
            if mId then

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
                        if C_QuestLog then
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

                    -- Zero-coord guard: if every coord resolved to 0,
                    -- the source data is unusable (typical for the
                    -- "<npc>|0|32|0|0" sentinel that backfillers write
                    -- when no live position was available). Bailing
                    -- here keeps the arrow on the previous target
                    -- rather than snapping it to world origin and
                    -- thrashing the path on every CalcAutoTrack tick.
                    if (not x1) or (not y1)
                        or (x1 == 0 and y1 == 0 and x2 == 0 and y2 == 0) then
                        return
                    end

                    if skipSame then
                        if self:IsTargeted (qId, qObj, x1, y1, x2, y2) then

                            Map:SetTargetName (name)
                            return
                        end
                    end

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
                        if Nx.qdb.profile.QuestWatch.Sync then
                            RemoveQuestWatch(BlizIndex)
                        end
                        self.Map:ClearTargets()
                        if not InCombatLockdown() and Nx.BlobsAvailable then
                            local QMap = NxMap1.NxMap
                            -- Only clear if not showing a world quest blob
                            if not QMap.ShowingWorldQuestBlob then
                                QMap.QuestWin:DrawNone();
                                QMap.QuestWin:Hide()
                            end
                        end
                    end
                end
            end
        end
    end
end

