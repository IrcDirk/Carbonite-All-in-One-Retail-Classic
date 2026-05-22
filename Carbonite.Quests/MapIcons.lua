-- Carbonite.Quests | MapIcons
-- Per-frame map-icon producer for the quest module. Called by
-- Modules/Map/MapEngine.lua:Update via Nx.Quest:UpdateIcons. Owns
-- the quest watch icons, quest offer / turn-in markers, and the
-- world-quest task overlay (with its retail-only 1-second cache).
--
-- This file deliberately keeps the legacy direct-stamp pattern
-- (map:GetIconStatic) rather than routing through Map:AddPin: the
-- per-frame churn here can exceed 100 icons and the AddPin path
-- isn't yet optimised for that load. See the next-session memory
-- for the design decision context.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed.
local bit_band = _G.bit.band or _G.bit_band
local bit_lshift = _G.bit.lshift or _G.bit_lshift
local floor = _G.math.floor or _G.floor
local format = _G.string.format or _G.format
local gsub = _G.string.gsub or _G.gsub
local max = _G.math.max or _G.max
local wipe = _G.wipe or _G.wipe
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo or _G.GetQuestObjectiveInfo
local InCombatLockdown = _G.InCombatLockdown or _G.InCombatLockdown

-- Promoted from NxQuest.lua's file-local compat shim.
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

-- File-local alias for the shared world-quest map. NxQuest.lua creates
-- Nx.Quest.worldquestdb and aliases it; this module reads from the same
-- table but the alias didn't survive the extraction, leaving line 745's
-- `worldquestdb[questID]` indexing a nil global on retail flight maps.
local worldquestdb = Nx.Quest.worldquestdb

-------------------------------------------------------------------------------
-- Update map icons (called by map)
-------------------------------------------------------------------------------

-- Cache for World Quest task info (refreshes every second, retail only)
local taskInfoCache = nil
local taskInfoCacheTimer = nil
if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
    taskInfoCacheTimer = C_Timer.NewTicker(1, function()
        if Nx.Map and Nx.Map.UpdateMapID then
            -- Preserve the prior good cache when the API returns a nil
            -- or empty list. C_TaskQuest.GetQuestsOnMap occasionally
            -- replies empty mid-refresh on retail; clobbering the
            -- cache then left the next UpdateIcons pass with nothing
            -- to stamp, so ResetIcons/HideExtraIcons hid every WQ /
            -- bonus-task icon for that frame. The next ticker tick
            -- repopulated the cache and the icons came back -- visible
            -- as a once-per-second blink of every retail world-quest
            -- pin on the map.
            local fresh = C_TaskQuest.GetQuestsOnMap(Nx.Map.UpdateMapID)
            if fresh and #fresh > 0 then
                taskInfoCache = fresh
            end
        end
    end)
end

function Nx.Quest:UpdateIcons (map)
    if not Nx.QInit then
        return
    end
    local Nx = Nx
    local Quest = Nx.Quest
    local Map = Nx.Map
    local qLocColors = Quest.QLocColors
    local ptSz = 4 * map.ScaleDraw

    -- Update target — runs every frame regardless of dirty-check.
    -- TrackOnMap re-anchors the quest blob (ClipZoneFrm SetPoint to
    -- the QuestPOIFrame). The blob's anchor is parent-relative; the
    -- parent scrolls with the player when the map follows, so if we
    -- skip this re-anchor on most frames the blob visually drifts
    -- with the character and only "snaps back" on the rare frame
    -- the dirty-check decides to rebuild.
    local navscale = Map.Maps[1].IconNavScale * 16
    local showOnMap = Quest.Watch.ButShowOnMap:GetPressed()

    local typ, tid = Map:GetTargetInfo()
    if typ == "Q" then

--        Nx.prt ("QTar %s", tid)

        local qid = floor (tid / 100)
        local i, cur = Quest:FindCur (qid)

        if cur then
            Quest:CalcDistances (cur.Index, cur.Index)
            Quest:TrackOnMap (cur.QId, tid % 100, cur.QI > 0 or cur.Party, true, true)

--            Nx.prt ("UpIcons target %s %s", typ or "nil", tid or "nil")
        end
    end

    -- Dirty-check fingerprint for the heavier per-quest POI walk
    -- below. Every POI / area / distance-arrow site now lives on
    -- the persistent Pin/Layer-backed provider — the Renderer
    -- iterates the pin layer every frame regardless of whether this
    -- producer runs, so on a clean frame we skip the entire
    -- per-quest walk. The fingerprint coalesces ticks into 10-frame
    -- buckets (matching the tracking-rebuild cadence at line ~143),
    -- plus map / super-track / hover state so visual feedback stays
    -- snappy. Quest log changes are picked up at the next 10-tick
    -- bucket.
    local activeQID = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
        and C_SuperTrack.GetSuperTrackedQuestID()) or 0
    if activeQID == 0 then activeQID = Nx.Quest.ActiveQID or 0 end
    local hoverCur  = Quest.IconHoverCur
    local hoverObjI = Quest.IconHoverObjI or 0
    local tickBucket = math.floor((map.Tick or 0) / 10)
    local fp = (map.MapId or 0) .. "|" .. activeQID .. "|"
            .. (hoverCur and hoverCur.QId or 0) .. "|" .. hoverObjI
            .. "|" .. tickBucket
    -- The dirty-check now guards only the heavy per-quest walk
    -- (Pin/Layer-backed POIs). The BONUS TASKS / WORLD QUESTS block
    -- below uses the legacy direct-stamp pool (IconWQFrms), which the
    -- MapEngine resets to Next=1 every frame -- so on clean frames
    -- where this early-returned we never re-stamped the WQ icons and
    -- HideExtraIcons silently hid them. Player saw it as every retail
    -- world-quest pin blinking at ~2 Hz (the dirty-frame cadence).
    -- Run the per-quest walk only when dirty; always run the WQ block.
    local _walkDirty = (self._lastIconFP ~= fp) or self._iconDirty
    self._lastIconFP = fp
    self._iconDirty  = false

    if _walkDirty then

    -- Reset the Pin/Layer-backed POI provider for this pass. Every
    -- icon site below adds back into this same layer, so clearing
    -- before re-stamping mirrors the old HideExtraIcons cycle and
    -- prevents pin duplication on rebuild.
    if Nx.Quest.ClearProviderPins then
        Nx.Quest:ClearProviderPins()
    end

    local opts = self.GOpts
    local showWatchAreas = Nx.qdb.profile.Quest.MapShowWatchAreas
    local trkR, trkG, trkB, trkA =  Nx.Quest.Cols["trkR"], Nx.Quest.Cols["trkG"], Nx.Quest.Cols["trkB"], Nx.Quest.Cols["trkA"]
    local hovR, hovG, hovB, hovA =  Nx.Quest.Cols["hovR"], Nx.Quest.Cols["hovG"], Nx.Quest.Cols["hovB"], Nx.Quest.Cols["hovA"]

    -- Blob

--    local f = self.BlobFrm


    -- Draw completed quests

    for k, cur in ipairs (Quest.CurQ) do

        if cur.Q and cur.CompleteMerge then

            local q = cur.Q
            local obj = q["End"] or q["Start"]

            local endName, zone, x, y = Quest:GetSEPos (obj)
            local mapId = zone

            if mapId then

                local wx, wy = map:GetWorldPos (mapId, x, y)
                if Nx.Quest.AddPOI then
                    local qname = Nx.TXTBLUE .. L["Quest: "] .. cur.Title
                    local tip = format (L["%s\nEnd: %s (%.1f %.1f)"], qname, endName, x, y)
                    if cur.PartyNames then
                        tip = tip .. "\n" .. cur.PartyNames
                    end
                    Nx.Quest:AddPOI(wx, wy, {
                        tip    = tip,
                        tex    = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQuestion",
                        NXType = 9000,
                        NXData = cur,
                        mapID  = mapId,
                    })
                else
                    local f = map:GetIconStatic (4)
                    if map:ClipFrameByMapType (f, wx, wy, navscale, navscale, 0) then
                        f.NXType = 9000
                        f.NXData = cur
                        local qname = Nx.TXTBLUE .. L["Quest: "] .. cur.Title
                        f.NxTip = format (L["%s\nEnd: %s (%.1f %.1f)"], qname, endName, x, y)
                        if cur.PartyNames then
                            f.NxTip = f.NxTip .. "\n" .. cur.PartyNames
                        end
                        f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQuestion")
                    end
                end
            end
        end
    end

    -- Update tracking data

    local tracking = self.IconTracking

    if Nx.Map:GetMap (1).Frm.NxMap.Tick % 10 == 0 then

--        tracking = {}        -- garbage creator
        wipe (tracking)

        for trackId, trackMode in pairs (Quest.Tracking) do
            tracking[trackId] = trackMode
        end

        if showOnMap then
            local showAllPOIs = Nx.qdb.profile.Quest.ShowAllMapPOIs
            for k, cur in ipairs (Quest.CurQ) do
                if cur.Q then
                    -- Watched quests + party-shared quests have always been drawn.
                    -- ShowAllMapPOIs (default on for retail) extends this to every
                    -- in-log quest, matching the modern Blizzard map UX where any
                    -- quest in your log shows a POI on the open map. The icon
                    -- clip-test in the draw pass below skips quests whose
                    -- objective zone doesn't match the open map, so unrelated
                    -- quests don't appear.
                    if showAllPOIs
                        or Nx.Quest:GetQuest (cur.QId) == "W"
                        or cur.PartyDesc then
                        tracking[cur.QId] = (tracking[cur.QId] or 0) + 0x10000        -- cur.TrackMask + i
                    end
                end
            end
        end

        self.IconTracking = tracking
    end

    -- Draw

    local areaTex = Nx.Opts.ChoicesQAreaTex[Nx.qdb.profile.Quest.MapWatchAreaGfx]

    local colorPerQ = Nx.qdb.profile.Quest.MapWatchColorPerQ
    local colMax = Nx.qdb.profile.Quest.MapWatchColorCnt

    -- Cache the active questID so each icon can paint itself as the
    -- "active" POI (Blizzard parity). On retail / Wrath+ Classic this
    -- comes from C_SuperTrack; on older flavors we use Carbonite's
    -- internal ActiveQID set by SetActiveCarboniteQuest. cur.QId may
    -- be stale, so we also resolve via the live log index for the
    -- comparison.
    local activeQID = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
        and C_SuperTrack.GetSuperTrackedQuestID()) or 0
    if activeQID == 0 then
        activeQID = Nx.Quest.ActiveQID or 0
    end

    for trackId, trackMode in pairs (tracking) do

        local cur = Quest.IdToCurQ[trackId]
        local quest = cur and cur.Q or Nx.Quests[trackId]
        if not cur and not quest then
            -- tracking entry exists but quest data is gone, skip
        else
            local isSuperTracked = false
            if activeQID > 0 and cur then
                if cur.QId == activeQID then
                    isSuperTracked = true
                elseif cur.QI and cur.QI > 0
                       and C_QuestLog and C_QuestLog.GetQuestIDForLogIndex
                       and C_QuestLog.GetQuestIDForLogIndex(cur.QI) == activeQID then
                    isSuperTracked = true
                end
            end
            local qname = Nx.TXTBLUE .. L["Quest: "] .. (cur and cur.Title or Quest:UnpackName (quest["Quest"]))

            local mask = showOnMap and cur and cur.TrackMask or trackMode
            local showEnd

            if bit_band (mask, 1) > 0 then

                if not (cur and (cur.QI > 0 or cur.Party)) then

                    local startName, zone, x, y = Quest:GetSEPos (quest["Start"])
                    local mapId = zone

                    if mapId then
                        -- Quest-start POI is the first site ported to
                        -- the Pin/Layer-backed Carbonite.Quests
                        -- provider. The renderer reads pin.NXType +
                        -- pin.NXData so the legacy `t >= 9000`
                        -- dispatcher routes hover / click into
                        -- Nx.Quest:IconOnEnter unchanged. Other POI
                        -- sites below still use the pool-stamp
                        -- GetIconStatic path until they're ported.
                        local wx, wy = map:GetWorldPos (mapId, x, y)
                        if Nx.Quest.AddPOI then
                            local tip = format (L["%s\nStart: %s (%.1f %.1f)"], qname, startName, x, y)
                            Nx.Quest:AddPOI(wx, wy, {
                                tip      = tip,
                                tex      = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconExclaim",
                                NXType   = 9000,
                                NXData   = cur,
                                mapID    = mapId,
                            })
                        else
                            local f = map:GetIconStatic (4)
                            if map:ClipFrameByMapType (f, wx, wy, navscale, navscale, 0) then
                                f.NxTip = format (L["%s\nStart: %s (%.1f %.1f)"], qname, startName, x, y)
                                f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconExclaim")
                            end
                        end
                    end
                else

                    showEnd = true
                end
            end

            if showEnd or bit_band (mask, 0x10000) > 0 then

                local obj = quest["End"] or quest["Start"]

                local endName, zone, x, y = Quest:GetSEPos (obj)
                local mapId = zone

                if mapId and (not cur or not cur.CompleteMerge) then

                    local wx, wy = map:GetWorldPos (mapId, x, y)
                    if Nx.Quest.AddPOI then
                        local tip = format ("%s\n" .. L["End: "] .. "%s (%.1f %.1f)", qname, endName, x, y)
                        if cur and cur.PartyNames then
                            tip = tip .. "\n" .. cur.PartyNames
                        end
                        local vc = isSuperTracked
                            and {1, 0.85, 0, 1}      -- Active quest: Blizzard gold
                            or  {.6, 1, .6, 1}
                        Nx.Quest:AddPOI(wx, wy, {
                            tip         = tip,
                            tex         = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQuestion",
                            NXType      = 9000,
                            NXData      = cur,
                            mapID       = mapId,
                            vertexColor = vc,
                            showGlow    = isSuperTracked,
                        })
                    else
                        local f = map:GetIconStatic (4)
                        if map:ClipFrameByMapType (f, wx, wy, navscale, navscale, 0) then
                            f.NXType = 9000
                            f.NXData = cur
                            f.NxTip = format ("%s\n" .. L["End: "] .. "%s (%.1f %.1f)", qname, endName, x, y)
                            if cur and cur.PartyNames then
                                f.NxTip = f.NxTip .. "\n" .. cur.PartyNames
                            end
                            if isSuperTracked then
                                f.texture:SetVertexColor (1, 0.85, 0, 1)
                                if f.NxGlow then f.NxGlow:Show() end
                            else
                                f.texture:SetVertexColor (.6, 1, .6, 1)
                            end
                            f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQuestion")
                        end
                    end
                end
            end

            -- Objectives (max of 15)

            if not cur or cur.QI > 0 or cur.Party then

                local drawArea

                if cur then
                    local qStatus = Nx.Quest:GetQuest (cur.QId)
                    drawArea = showWatchAreas and qStatus == "W"
                end

                for n = 1, 15 do

                    local obj = quest["Objectives"]
                    if obj then
                        obj = quest["Objectives"][n]
                    end
                    if not obj then
                        break
                    end

                    local objName, objZone, typ = Nx.Quest:UnpackObjectiveNew (obj)

                    if objZone and objZone ~= 9000 then

                        local mapId = objZone

                        if not mapId then
--                            Nx.prt ("Nxzone error %s %s", objName, objZone)
                            break
                        end
                        -- Render this objective whenever:
                        --   * the explicit mask bit is set (watched/tracked
                        --     by user), OR
                        --   * the quest is in the player's log (cur exists
                        --     with QI > 0). This keeps the in-log POIs
                        --     visible even when the user hasn't toggled
                        --     "Show on map" — matching the modern UX where
                        --     accepted quests draw their data automatically.
                        local renderObj = bit_band (mask, bit_lshift (1, n)) > 0
                            or (cur and cur.QI and cur.QI > 0)
                        -- Skip completed objectives (and skip everything if
                        -- the whole quest is complete) — there's no point
                        -- showing a static area span / point you've already
                        -- finished. cur[n+300] holds the per-objective done
                        -- flag set during RecordQuestsLog.
                        local objDone = cur and (cur.CompleteMerge or cur[n + 300])
                        if objDone then renderObj = false end
                        if renderObj then
                            local colI = n

                            if colorPerQ then
                                colI = ((cur and cur.Index or 1) - 1) % colMax + 1
                            end

                            local col = qLocColors[colI]
                            local r = col[1]
                            local g = col[2]
                            local b = col[3]

                            local oname = cur and cur[n] or objName

                            -- Per-POI dispatch. The objective list can mix
                            -- typ 32 (points) and typ 35 (area spans) — e.g.
                            -- a quest that has a static area-blob in its
                            -- data files AND a runtime point pin from
                            -- Blizzard's API. Render each POI according to
                            -- its own typ so the area span isn't hidden by
                            -- the first-POI dispatch.

                            local hover = Quest.IconHoverCur == cur and Quest.IconHoverObjI == n
                            local tracking = bit_band (trackMode, bit_lshift (1, n)) > 0
                            local tip = format ("%s\nObj: %s", qname, oname)
                            if cur and cur[n + 400] then
                                tip = tip .. "\n" .. cur[n + 400]
                            end

                            -- Distance arrow (per-objective). Draws an
                            -- IconAreaArrows pointer at the closest edge
                            -- of the objective area to the player. Only
                            -- meaningful when the objective actually has a
                            -- spannable area (typ 35) — for typ 32 point
                            -- objectives the "closest edge" is the point
                            -- itself, so the arrow icon ends up right on
                            -- top of the real point and looks like a
                            -- duplicate ghost icon next to it.
                            local hasSpanForArrow = false
                            for _, loc1 in pairs(obj) do
                                if type(loc1) == "string" and loc1 ~= "" then
                                    local _, _, poiTyp = Nx.Quest:UnpackObjectiveNew(loc1)
                                    if poiTyp == 35 then hasSpanForArrow = true; break end
                                end
                            end
                            if cur and hasSpanForArrow then
                                local d = cur["OD"..n]
                                if d and d > 0 then
                                    local ax = cur["OX"..n]
                                    local ay = cur["OY"..n]
                                    if ax and ay then
                                        if Nx.Quest.AddArrow then
                                            local avc = tracking
                                                and {.8, .8, .8, 1}
                                                or  {r, g, b, .7}
                                            Nx.Quest:AddArrow(ax, ay, {
                                                tip         = tip,
                                                tex         = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconAreaArrows",
                                                NXType      = 9000 + n,
                                                NXData      = cur,
                                                mapID       = pmap,
                                                vertexColor = avc,
                                            })
                                        else
                                            local f = map:GetIcon (4)
                                            local sz = navscale
                                            if not hover then sz = sz * .8 end
                                            if map:ClipFrameByMapType (f, ax, ay, sz, sz, 0) then
                                                f.NXType = 9000 + n
                                                f.NXData = cur
                                                f.NxTip = tip
                                                f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconAreaArrows")
                                                if tracking then
                                                    f.texture:SetVertexColor (.8, .8, .8, 1)
                                                else
                                                    f.texture:SetVertexColor (r, g, b, .7)
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- Spans always render when this objective has any
                            -- POI data. The original gating (only draw on
                            -- hover / explicit-track / drawAll-areas) was a
                            -- perf hint for the all-quests overview render —
                            -- but for a quest in your log with both a point
                            -- icon and an area blob, the user's intent is
                            -- to see both at once. Hover/tracking still
                            -- override the *color* via existing branches.
                            local drawSpans = true

                            for _, loc1 in pairs(obj) do
                                if loc1 ~= "" and type(loc1) == "string" then
                                    local _, poiMap, poiTyp = Nx.Quest:UnpackObjectiveNew (loc1)
                                    local pmap = poiMap or mapId
                                    -- PatchQuestFromBlizzard writes sentinel
                                    -- entries with mapId=0 when the live API
                                    -- hasn't returned coords yet (the watch
                                    -- list still shows the text; the map is
                                    -- meant to skip it until QUEST_POI_UPDATE
                                    -- replaces it with real coords). Without
                                    -- this guard those sentinels render at
                                    -- the world origin as a tiny ghost icon
                                    -- next to the real POI.
                                    if not poiMap or poiMap == 0 then
                                        -- skip
                                    elseif poiTyp == 32 then
                                        -- Point objective POI
                                        local px, py = Nx.Quest:UnpackLocPtOff (loc1)
                                        if px and py then
                                            local wx, wy = map:GetWorldPos (pmap, px, py)
                                            if Nx.Quest.AddPOI then
                                                local ptip = format ("%s\nObj: %s (%.1f %.1f)", qname, oname, px, py)
                                                if cur and cur[n + 400] then
                                                    ptip = ptip .. "\n" .. cur[n + 400]
                                                end
                                                local pvc = isSuperTracked
                                                    and {1, 0.85, 0, 1}
                                                    or  {r, g, b, .9}
                                                Nx.Quest:AddPOI(wx, wy, {
                                                    tip         = ptip,
                                                    tex         = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQTarget",
                                                    NXType      = 9000 + n,
                                                    NXData      = cur,
                                                    mapID       = pmap,
                                                    vertexColor = pvc,
                                                    showGlow    = isSuperTracked,
                                                    label       = tostring(n),
                                                })
                                            else
                                                local f = map:GetIconStatic (4)
                                                if map:ClipFrameByMapType (f, wx, wy, navscale, navscale, 0) then
                                                    f.NXType = 9000 + n
                                                    f.NXData = cur
                                                    f.NxTip = format ("%s\nObj: %s (%.1f %.1f)", qname, oname, px, py)
                                                    if cur and cur[n + 400] then
                                                        f.NxTip = f.NxTip .. "\n" .. cur[n + 400]
                                                    end
                                                    f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQTarget")
                                                    if isSuperTracked then
                                                        f.texture:SetVertexColor (1, 0.85, 0, 1)
                                                        if f.NxGlow then f.NxGlow:Show() end
                                                    else
                                                        f.texture:SetVertexColor (r, g, b, .9)
                                                    end
                                                    if f.NxLabel then
                                                        f.NxLabel:SetText(tostring(n))
                                                        f.NxLabel:Show()
                                                    end
                                                end
                                            end
                                        end
                                    elseif drawSpans then
                                        -- Span / area
                                        local scale = map:GetWorldZoneScale (pmap) / 10.02
                                        local x, y, w, h = Nx.Quest:UnpackLocRect (loc1)
                                        if x and y and w and h then
                                            local wx, wy = map:GetWorldPos (pmap, x, y)
                                            if Nx.Quest.AddArea then
                                                -- Color tuple matching the legacy hover /
                                                -- tracking / normal branch the renderer
                                                -- applies via onStamp (vertexColor path) or
                                                -- via SetColorTexture (pin.color path when
                                                -- areaTex is nil).
                                                local avc
                                                if hover then
                                                    avc = { hovR, hovG, hovB, tonumber(hovA) or 1 }
                                                elseif tracking then
                                                    avc = { trkR, trkG, trkB, tonumber(trkA) or 1 }
                                                else
                                                    avc = { r, g, b, tonumber(col[4]) or 1 }
                                                end
                                                Nx.Quest:AddArea(wx, wy, {
                                                    tip         = tip,
                                                    tex         = areaTex,
                                                    color       = (not areaTex) and avc or nil,
                                                    NXType      = 9000 + n,
                                                    NXData      = cur,
                                                    mapID       = pmap,
                                                    w           = w * scale,
                                                    h           = h * scale,
                                                    vertexColor = areaTex and avc or nil,
                                                })
                                            elseif areaTex then
                                                local f = map:GetIconStatic (hover and 1)
                                                if map:ClipFrameTL (f, wx, wy, w * scale, h * scale) then
                                                    f.NXType = 9000 + n
                                                    f.NXData = cur
                                                    f.NxTip = tip
                                                    f.texture:SetTexture (areaTex)
                                                    if hover then
                                                        f.texture:SetVertexColor (hovR, hovG, hovB, tonumber(hovA))
                                                    elseif tracking then
                                                        f.texture:SetVertexColor (trkR, trkG, trkB, tonumber(trkA))
                                                    else
                                                        f.texture:SetVertexColor (r, g, b, tonumber(col[4]))
                                                    end
                                                end
                                            else
                                                local f = map:GetIconStatic (hover and 1)
                                                if map:ClipFrameTLSolid (f, wx, wy, w * scale, h * scale) then
                                                    f.NXType = 9000 + n
                                                    f.NXData = cur
                                                    f.NxTip = tip
                                                    if hover then
                                                        f.texture:SetColorTexture (hovR, hovG, hovB, hovA)
                                                    elseif tracking then
                                                        f.texture:SetColorTexture (trkR, trkG, trkB, trkA)
                                                    else
                                                        f.texture:SetColorTexture (r, g, b, tonumber(col[4]))
                                                    end
                                                end
                                            end -- if areaTex / else
                                        end -- if x and y and w and h
                                    end -- elseif drawSpans
                                end -- if loc1 ~= ""
                            end -- for _, loc1 in pairs(obj)
                        end -- if bit_band(mask, ...)
                    end -- if objZone
                end -- for n
            end -- if quest
        end -- if not cur and not quest
    end

    end -- if _walkDirty then (per-quest walk guarded by dirty-check)

    -- BONUS TASKS and WORLD QUESTS icons
    local taskIconIndex = 1
    local activeWQ = {}
    if Map.UpdateMapID ~= 9000 then
        -- Refresh cache on map change
        if Nx.Map.mapChange then
            taskInfoCache = C_TaskQuest.GetQuestsOnMap(Map.UpdateMapID)
        end
        local taskInfo = taskInfoCache
        if taskInfo and Nx.db.char.Map.ShowWorldQuest then
            for i = 1, #taskInfo do
                local info = taskInfo[i]
                local questID = taskInfo[i].questID
                local title, faction = C_TaskQuest.GetQuestInfoByQuestID(questID)

                -- Fetch the quest tag information using the new API function
                local questTagInfo = GetQuestTagInfoCompat(questID)

                if questTagInfo then
                    local isCriteria = false
                    local isElite = questTagInfo.isElite
                    local isDaily = questTagInfo.isDaily
                    local isRepeatable = questTagInfo.isRepeatable
                    local tagName = questTagInfo.tagName

                    local timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(questID)
                    -- Check if quest is Important, Campaign, or Legendary (these have no time limit)
                    local isImportantQuest = false
                    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
                        local classification = C_QuestInfoSystem.GetQuestClassification(questID)
                        if classification then
                            isImportantQuest = (classification == Enum.QuestClassification.Important) or
                                               (classification == Enum.QuestClassification.Campaign) or
                                               (classification == Enum.QuestClassification.Legendary)
                        end
                    end
                    if QuestUtils_ShouldDisplayExpirationWarning(questID) or (timeLeft and timeLeft > 0) or isImportantQuest then
                        local x, y = info.x * 100, info.y * 100
                        local f = map:GetIconWQ(120)
                        f.questID = info.questID

                        -- Use hideOutside=true to completely hide icon when outside visible area
                        if not map:ClipFrameZ(f, x, y, 24, 24, 0, true) then
                            -- Icon is outside visible area, skip processing
                            f:Hide()
                        else

                        local selected = info.questID == C_SuperTrack.GetSuperTrackedQuestID()

                        local function WQTGetOverlay(memberName)
                            for j = 1, #WorldMapFrame.overlayFrames do
                                local overlay = WorldMapFrame.overlayFrames[j]
                                if overlay[memberName] then
                                    return overlay
                                end
                            end
                        end
                        local overlayFrame = WQTGetOverlay("IsWorldQuestCriteriaForSelectedBounty")
                        if overlayFrame then
                            isCriteria = overlayFrame:IsWorldQuestCriteriaForSelectedBounty(info.questID)
                        end

                        f.worldQuest = true
                        f.questID = info.questID
                        f.numObjectives = info.numObjectives
                        f.Texture:SetDrawLayer("OVERLAY")
                        f:SetScript("OnClick", function(self, button)
                            map:SetTargetAtStr(string.format("%s, %s", x, y))
                            if not InCombatLockdown() and self.worldQuest then
                                if not ChatEdit_TryInsertQuestLinkForQuestID(self.questID) then
                                    local watchType = C_QuestLog.GetQuestWatchType(self.questID)
                                    local isSuperTracked = C_SuperTrack.GetSuperTrackedQuestID() == self.questID

                                    if ZygorGuidesViewer and ZygorGuidesViewer.WorldQuests then
                                        ZygorGuidesViewer.WorldQuests:SuggestWorldQuestGuideFromMap(nil, self.questID, "force", self.mapID)
                                    end

                                    if IsShiftKeyDown() then
                                        if watchType == Enum.QuestWatchType.Manual or (watchType == Enum.QuestWatchType.Automatic and isSuperTracked) then
                                            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                                            QuestUtil.UntrackWorldQuest(self.questID)
                                        else
                                            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                            QuestUtil.TrackWorldQuest(self.questID, Enum.QuestWatchType.Manual)
                                        end
                                    else
                                        if isSuperTracked then
                                            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                                            C_SuperTrack.SetSuperTrackedQuestID(0)
                                        else
                                            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                            if watchType ~= Enum.QuestWatchType.Manual then
                                                QuestUtil.TrackWorldQuest(self.questID, Enum.QuestWatchType.Automatic)
                                            end
                                            C_SuperTrack.SetSuperTrackedQuestID(self.questID)
                                        end
                                    end
                                end
                            end
                        end)

                        if isImportantQuest then
                            -- Use QuestUtil.GetQuestIconOffer for important/campaign/legendary quests
                            local classification = C_QuestInfoSystem.GetQuestClassification(questID)
                            local isLegendary = classification == Enum.QuestClassification.Legendary
                            local isCampaign = classification == Enum.QuestClassification.Campaign
                            local isImportant = classification == Enum.QuestClassification.Important
                            local isMeta = classification == Enum.QuestClassification.Meta
                            local isCalling = classification == Enum.QuestClassification.Calling
                            local frequency = questTagInfo and questTagInfo.frequency or 0
                            local isRepeatable = questTagInfo and questTagInfo.isRepeatable or false
                            
                            if QuestUtil.GetQuestIconOffer then
                                local atlasName, useAtlas = QuestUtil.GetQuestIconOffer(isLegendary, frequency, isRepeatable, isCampaign, isCalling, isImportant, isMeta)
                                if useAtlas then
                                    f.Texture:SetAtlas(atlasName)
                                else
                                    f.Texture:SetTexture(atlasName)
                                end
                                f.Texture:Show()
                                f:Show()
                            else
                                f:Hide()
                            end
                        elseif tagName then
                            QuestUtil.SetupWorldQuestButton(f, questTagInfo, tagName, selected, isCriteria, false, true)
                        else
                            f:Hide()
                        end

                        f.texture:Hide()
                        end -- Close the hideOutside else block
                    end
                else
                    if not worldquestdb[questID] and title then
                        taskIconIndex = taskIconIndex + 1
                        local x, y = taskInfo[i].x * 100, taskInfo[i].y * 100
                        local f = map:GetIcon(3)

                        local objTxt = ""
                        for objectiveIndex = 1, taskInfo[i].numObjectives do
                            local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(questID, objectiveIndex, false)
                            if objectiveText and #objectiveText > 0 then
                                local color = finished and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
                                color = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
                                objTxt = objTxt .. "\n- " .. color .. objectiveText
                            end
                        end

                        if taskInfo[i].isCombatAllyQuest or taskInfo[i].isDaily then
                            if not taskInfo[i].inProgress then
                                f.questID = taskInfo[i].questID
                                f.NxTip = L["|cffffd100Daily Task:\n"] .. title:gsub("Daily Objective: ", "") .. objTxt .. "\n" .. GREEN_FONT_COLOR:GenerateHexColorMarkup() .. GRANTS_FOLLOWER_XP
                                f.texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas")
                                if not map:ClipFrameZ(f, x, y, 22, 22, 0, true) then
                                    f:Hide()
                                else
                                f.texture:SetTexCoord(C_Minimap.GetObjectIconTextureCoords(4713))
                                f:SetScript("OnMouseDown", function(self, button)
                                    map:SetTargetAtStr(string.format("%s, %s", x, y))
                                    if not InCombatLockdown() then
                                        if not ChatEdit_TryInsertQuestLinkForQuestID(self.questID) then
                                            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                            if ZygorGuidesViewer and ZygorGuidesViewer.WorldQuests then
                                                ZygorGuidesViewer.WorldQuests:SuggestWorldQuestGuideFromMap(nil, self.questID, "force", self.mapID)
                                            end
                                        end
                                    end
                                end)
                                end -- Close hideOutside else block
                            end
                        else
                            f.NxTip = L["|cffffd100Bonus Task:\n"] .. title:gsub("Bonus Objective: ", "") .. objTxt
                            f.texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas")
                            if map:ClipFrameZ(f, x, y, 22, 22, 0, true) then
                                f.texture:SetTexCoord(C_Minimap.GetObjectIconTextureCoords(4734))
                            else
                                f:Hide()
                            end
                        end
                    end
                end
            end
        end
    end
end

function Nx.Quest:IconOnEnter (frm)

    local i = frm.NXType - 9000
    local cur = frm.NXData

    self.IconHoverCur = cur
    self.IconHoverObjI = i
    self._iconDirty = true   -- area-pin hover color redraws next tick
end

function Nx.Quest:IconOnLeave (frm)

    self.IconHoverCur = nil
    self._iconDirty = true
end

function Nx.Quest:IconOnMouseDown (frm)

    local cur = self.IconHoverCur
    if cur then

        self.IconMenuCur = cur
        self.IconMenuObjI = self.IconHoverObjI

        local qStatus = Nx.Quest:GetQuest (cur.QId)
        self.IconMenuIWatch:SetChecked (qStatus == "W")

        self.IconMenu:Open()
    end
end

-------------------------------------------------------------------------------
