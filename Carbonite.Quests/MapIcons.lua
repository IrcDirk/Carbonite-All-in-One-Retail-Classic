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
local lower = _G.string.lower or _G.lower
local max = _G.math.max or _G.max
local sort = _G.table.sort or _G.sort
local wipe = _G.wipe or _G.wipe
local issecretvalue = _G.issecretvalue
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo or _G.GetQuestObjectiveInfo
local InCombatLockdown = _G.InCombatLockdown or _G.InCombatLockdown
local QuestMapCompat = Nx.QuestMapCompatibility

-- Every shipped TOC loads QuestMapCompatibility.lua first. Keep a minimal
-- fallback for third-party loaders that execute this file directly.
if not QuestMapCompat then
    QuestMapCompat = {
        AreQuestPOIsEnabled = function() return true end,
        IsModernQuestDataProvider = function()
            return C_QuestLog
                and type(C_QuestLog.GetNextWaypointForMap) == "function"
                or false
        end,
        ShouldUseQuestMapEntry = function() return true end,
        GetQuestPinVisual = function(_, _, selected, complete, isWaypoint)
            return {
                tex = complete and "atlas:UI-QuestIcon-TurnIn-Normal"
                    or (isWaypoint and "atlas:poi-traveldirections-arrow"
                    or (selected
                        and "atlas:Quest-In-Progress-Icon-Brown"
                        or "atlas:Quest-In-Progress-Icon-yellow")),
                width = selected and 24 or 20,
                height = selected and 24 or 20,
            }
        end,
    }
end

-- Promoted from NxQuest.lua's file-local compat shim.
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat or function()
    return nil
end

-- File-local alias for the shared world-quest map. NxQuest.lua creates
-- Nx.Quest.worldquestdb and aliases it; this module reads from the same
-- table but the alias didn't survive the extraction, leaving line 745's
-- `worldquestdb[questID]` indexing a nil global on retail flight maps.
local worldquestdb = Nx.Quest.worldquestdb or {}
Nx.Quest.worldquestdb = worldquestdb

local function GetCatalogQuestTitle(questID, fallback, questLogIndex)
    if Nx.Quest.GetCatalogQuestTitle then
        return Nx.Quest:GetCatalogQuestTitle(questID, fallback, questLogIndex)
    end

    if fallback and fallback ~= "" then
        return fallback
    end

    local catalog = Nx.GetQuestCatalog and Nx:GetQuestCatalog() or Nx.Quest.Catalog
    local title = catalog and catalog.GetQuestTitle and catalog:GetQuestTitle(questID)
    if title and title ~= "" then
        return title
    end

    return questID and ("Quest " .. questID) or "Quest"
end

local function IsInstanceIconContext(mapID)
    return Nx.Map and Nx.Map.IsInstanceDisplayContext
        and Nx.Map:IsInstanceDisplayContext(mapID) or false
end

local function IsQuestMapRelevant(mapID, viewMapID)
    if not mapID then
        return false
    end
    if Nx.Map and Nx.Map.IsMapRelevantToInstance then
        return Nx.Map:IsMapRelevantToInstance(mapID, viewMapID)
    end
    return true
end

local GetObjectIconTextureCoords = _G.C_Minimap and _G.C_Minimap.GetObjectIconTextureCoords

local function GetSafeMapID(value)
    if value == nil or (issecretvalue and issecretvalue(value)) then
        return nil
    end

    value = tonumber(value)
    return value and value > 0 and value or nil
end

local function IsMapSameOrDescendant(mapID, ancestorMapID)
    mapID = GetSafeMapID(mapID)
    ancestorMapID = GetSafeMapID(ancestorMapID)
    if not mapID or not ancestorMapID then
        return false
    end
    if mapID == ancestorMapID then
        return true
    end

    local mapAPI = _G.C_Map
    if not mapAPI or not mapAPI.GetMapInfo then
        return false
    end

    local currentMapID = mapID
    for _ = 1, 16 do
        local mapInfo = mapAPI.GetMapInfo(currentMapID)
        local parentMapID = mapInfo and GetSafeMapID(mapInfo.parentMapID)
        if not parentMapID or parentMapID == currentMapID then
            return false
        end
        if parentMapID == ancestorMapID then
            return true
        end
        currentMapID = parentMapID
    end

    return false
end

-- Campaign phases commonly publish objective coordinates on a stable parent
-- Zone while the player is on a child/Micro map. This is a map relationship,
-- not a quest exception: whenever the displayed map is a descendant of the
-- source map, project the point onto the displayed canvas. ProjectObjectivePoint
-- still has to prove that the coordinate lies on that child map, so unrelated
-- dungeons do not inherit every outdoor objective from their parent zone.
local function GetQuestRenderMapID(sourceMapID, viewMapID)
    sourceMapID = GetSafeMapID(sourceMapID)
    viewMapID = GetSafeMapID(viewMapID)
    if not sourceMapID or not viewMapID then
        return nil
    end

    if sourceMapID == viewMapID then
        return sourceMapID
    end

    if IsMapSameOrDescendant(viewMapID, sourceMapID) then
        return viewMapID
    end

    return IsQuestMapRelevant(sourceMapID, viewMapID)
        and sourceMapID or nil
end

local function GetPublicVectorXY(vector)
    if vector == nil or (issecretvalue and issecretvalue(vector)) then
        return nil
    end

    local x, y
    if type(vector.GetXY) == "function" then
        local ok
        ok, x, y = pcall(vector.GetXY, vector)
        if not ok then return nil end
    else
        x, y = vector.x, vector.y
    end

    if type(x) ~= "number" or type(y) ~= "number"
        or (issecretvalue and (issecretvalue(x) or issecretvalue(y))) then
        return nil
    end
    return x, y
end

-- Convert a catalog coordinate from its source map to the canvas Carbonite is
-- actually displaying. Blizzard's C_Map APIs are the authority here:
-- GetWorldPosFromMapPos turns the parent-map point into a world vector and
-- GetMapPosFromWorldPos projects that vector onto the phased child/Micro map.
-- Carbonite's old code changed only the mapID while leaving the parent world
-- coordinate untouched; ClipFrameMF then interpreted it as a child-local point
-- and placed the icon far outside the fixed instance canvas.
--
-- GetMapRectOnMap is the supported fallback for child maps that do not expose
-- a world vector. If both supported transforms fail, the point is rejected;
-- blindly reusing parent-map normalized coordinates can place it confidently
-- on the wrong instance floor.
function Nx.Quest:ProjectObjectivePoint(map, sourceMapID, mapX, mapY,
    viewMapID)
    sourceMapID = GetSafeMapID(sourceMapID)
    viewMapID = GetSafeMapID(viewMapID)
    if not map or type(map.GetWorldPos) ~= "function"
        or not sourceMapID or not viewMapID
        or type(mapX) ~= "number" or type(mapY) ~= "number" then
        return nil
    end

    local renderMapID = GetQuestRenderMapID(sourceMapID, viewMapID)
    if not renderMapID then return nil end

    local projectedX, projectedY = mapX * .01, mapY * .01
    if renderMapID ~= sourceMapID then
        projectedX, projectedY = nil, nil
        local mapAPI = _G.C_Map
        local makeVector = _G.CreateVector2D

        if mapAPI and type(mapAPI.GetWorldPosFromMapPos) == "function"
            and type(mapAPI.GetMapPosFromWorldPos) == "function"
            and type(makeVector) == "function" then
            local vectorOK, sourcePosition = pcall(
                makeVector, mapX * .01, mapY * .01)
            if vectorOK and sourcePosition then
                local worldOK, continentID, worldPosition = pcall(
                    mapAPI.GetWorldPosFromMapPos,
                    sourceMapID,
                    sourcePosition
                )
                continentID = worldOK and GetSafeMapID(continentID) or nil
                if continentID and worldPosition then
                    local mapOK, returnedMapID, mapPosition = pcall(
                        mapAPI.GetMapPosFromWorldPos,
                        continentID,
                        worldPosition,
                        renderMapID
                    )
                    returnedMapID = mapOK and GetSafeMapID(returnedMapID) or nil
                    if returnedMapID == renderMapID then
                        projectedX, projectedY = GetPublicVectorXY(mapPosition)
                    end
                end
            end
        end

        if not projectedX and mapAPI
            and type(mapAPI.GetMapRectOnMap) == "function" then
            local ok, minX, maxX, minY, maxY = pcall(
                mapAPI.GetMapRectOnMap, renderMapID, sourceMapID)
            if ok and type(minX) == "number" and type(maxX) == "number"
                and type(minY) == "number" and type(maxY) == "number"
                and maxX ~= minX and maxY ~= minY then
                projectedX = (mapX * .01 - minX) / (maxX - minX)
                projectedY = (mapY * .01 - minY) / (maxY - minY)
            end
        end

    end

    if type(projectedX) ~= "number" or type(projectedY) ~= "number"
        or (issecretvalue
            and (issecretvalue(projectedX) or issecretvalue(projectedY)))
        or projectedX < 0 or projectedX > 1
        or projectedY < 0 or projectedY > 1 then
        return nil
    end

    local ok, wx, wy = pcall(
        map.GetWorldPos, map, renderMapID,
        projectedX * 100, projectedY * 100)
    if not ok or type(wx) ~= "number" or type(wy) ~= "number"
        or (wx == 0 and wy == 0) then
        return nil
    end

    return renderMapID, wx, wy, projectedX, projectedY
end

-- Choose one stable marker for an area-only objective. A quest objective can
-- contain many small rectangles; stamping a numbered pin on every rectangle
-- recreates the broken breadcrumb trail. Prefer the largest rectangle and run
-- its centre through the same parent-to-phase projection as point objectives.
local function GetAreaObjectiveMarker(map, objective, viewMapID)
    if type(objective) ~= "table" then
        return false, false
    end

    local hasPointPOI = false
    local hasAreaPOI = false
    local bestMapID, bestX, bestY, bestArea, bestOnView

    for _, loc in pairs(objective) do
        if type(loc) == "string" and loc ~= "" then
            local _, poiMap, poiType = Nx.Quest:UnpackObjectiveNew(loc)
            local renderMapID = GetQuestRenderMapID(poiMap, viewMapID)
            if renderMapID then
                if poiType == 32 then
                    hasPointPOI = true
                elseif poiType == 35 then
                    hasAreaPOI = true
                    local x, y, w, h = Nx.Quest:UnpackLocRect(loc)
                    if x and y and w and h and w > 0 and h > 0 then
                        local area = w * h
                        local onView = renderMapID == viewMapID
                        if not bestMapID
                            or (onView and not bestOnView)
                            or (onView == bestOnView and area > bestArea) then
                            bestMapID = poiMap
                            bestX = x + w / 1002 * 50
                            bestY = y + h / 668 * 50
                            bestArea = area
                            bestOnView = onView
                        end
                    end
                end
            end
        end
    end

    if not bestMapID then
        return hasPointPOI, hasAreaPOI
    end

    local renderMapID, wx, wy = Nx.Quest:ProjectObjectivePoint(
        map,
        bestMapID,
        bestX,
        bestY,
        viewMapID
    )
    if not renderMapID then
        return hasPointPOI, hasAreaPOI
    end
    return hasPointPOI, hasAreaPOI, renderMapID, wx, wy
end

-- Carbonite's catalog stores location records, not a guaranteed mirror of
-- Blizzard's live objective array. One live objective can have several known
-- locations, and those locations can occupy several catalog slots. Treating
-- catalog slot N as live objective N hides valid locations as soon as an
-- unrelated live row completes. Build identity groups from the objective text
-- instead, then apply one live completion state to every location in a group.
local function NormalizeObjectiveLabel(text)
    if type(text) ~= "string"
        or (issecretvalue and issecretvalue(text)) then
        return nil, nil, 0
    end

    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = gsub(text, "|r", "")
    text = gsub(text, "%d+%s*/%s*%d+", " ")
    text = lower(text)
    text = gsub(text, "[^%w\128-\255]+", " ")

    local tokens = {}
    local tokenSet = {}
    for token in string.gmatch(text, "[%w\128-\255]+") do
        if #token > 4 and string.sub(token, -3) == "ies" then
            token = string.sub(token, 1, -4) .. "y"
        elseif #token > 3 and string.sub(token, -1) == "s"
            and string.sub(token, -2) ~= "ss" then
            token = string.sub(token, 1, -2)
        end

        if token ~= "" and not tokenSet[token] then
            tokenSet[token] = true
            tokens[#tokens + 1] = token
        end
    end

    if #tokens == 0 then
        return nil, nil, 0
    end
    return table.concat(tokens, " "), tokenSet, #tokens
end

local function GetCatalogObjectiveLabel(objective)
    if type(objective) ~= "table" then return nil end

    for _, location in ipairs(objective) do
        if type(location) == "string" then
            local label = string.match(location, "^([^|]*)")
            local key = NormalizeObjectiveLabel(label)
            if key and key ~= "nil" and key ~= "unknown" then
                return label, key
            end
        end
    end
    return nil
end

local function ObjectiveLabelScore(group, live)
    if not group.key or not live.key then return 0 end
    if group.key == live.key then return 1000 end

    local shared = 0
    for token in pairs(group.tokens) do
        if live.tokens[token] then shared = shared + 1 end
    end

    if shared == group.tokenCount and group.tokenCount >= 2 then
        return 700 + shared * 10 - live.tokenCount
    end
    if shared == live.tokenCount and live.tokenCount >= 2 then
        return 650 + shared * 10 - group.tokenCount
    end
    if shared >= 2 then
        return 500 + shared * 10
    end
    return 0
end

local function GetLiveObjectiveRows(cur, questID)
    local rows = {}
    local questLog = _G.C_QuestLog
    if questID and questLog
        and type(questLog.GetQuestObjectives) == "function" then
        local ok, objectives = pcall(questLog.GetQuestObjectives, questID)
        if ok and type(objectives) == "table" then
            for index, objective in ipairs(objectives) do
                if index > 15 then break end
                if type(objective) == "table" then
                    local text = objective.text
                    local finished = objective.finished
                    if type(text) == "string"
                        and not (issecretvalue and issecretvalue(text))
                        and not (issecretvalue and issecretvalue(finished)) then
                        local key, tokens, tokenCount =
                            NormalizeObjectiveLabel(text)
                        rows[#rows + 1] = {
                            index = index,
                            text = text,
                            finished = finished and true or false,
                            key = key,
                            tokens = tokens or {},
                            tokenCount = tokenCount,
                        }
                    end
                end
            end
        end
    end

    -- Classic clients and a few protected quest states do not expose the
    -- structured table. Carbonite already snapshots the equivalent text and
    -- done flags on cur, so use that as the supported fallback.
    if #rows == 0 and cur then
        local liveCount = tonumber(cur.LBCnt) or 0
        for index = 1, math.min(liveCount, 15) do
            local text = cur[index]
            if type(text) == "string"
                and not (issecretvalue and issecretvalue(text)) then
                local key, tokens, tokenCount = NormalizeObjectiveLabel(text)
                rows[#rows + 1] = {
                    index = index,
                    text = text,
                    finished = cur[index + 300] and true or false,
                    key = key,
                    tokens = tokens or {},
                    tokenCount = tokenCount,
                }
            end
        end
    end

    return rows
end

function Nx.Quest:BuildObjectiveRenderState(quest, cur, questID)
    local states = {}
    local objectives = quest and quest["Objectives"]
    if type(objectives) ~= "table" then return states end

    local groups = {}
    local groupsByKey = {}
    for slot = 1, 15 do
        local objective = objectives[slot]
        if objective then
            local label, key = GetCatalogObjectiveLabel(objective)
            local group
            if key then
                group = groupsByKey[key]
            end
            if not group then
                local normalizedKey, tokens, tokenCount =
                    NormalizeObjectiveLabel(label)
                group = {
                    key = normalizedKey,
                    tokens = tokens or {},
                    tokenCount = tokenCount,
                    label = label,
                    firstSlot = slot,
                    slots = {},
                    liveRows = {},
                }
                groups[#groups + 1] = group
                if key then groupsByKey[key] = group end
            end
            group.slots[#group.slots + 1] = slot
        end
    end

    local liveRows = GetLiveObjectiveRows(cur, questID)
    local assignedRows = {}

    -- Assign each named live objective to the best catalog identity. More than
    -- one live row may legitimately feed the same group; the group remains
    -- visible until all of those rows are complete.
    for _, live in ipairs(liveRows) do
        local bestGroup, bestScore
        for _, group in ipairs(groups) do
            local score = ObjectiveLabelScore(group, live)
            if score > (bestScore or 0) then
                bestGroup, bestScore = group, score
            end
        end
        if bestGroup then
            bestGroup.liveRows[#bestGroup.liveRows + 1] = live
            assignedRows[live] = true
        end
    end

    -- When the two feeds have equal cardinality, pair any remaining unnamed or
    -- localized groups by order. This is deliberately gated on equal counts;
    -- otherwise an index guess can once again hide unrelated locations.
    if #groups == #liveRows then
        local remainingGroups = {}
        local remainingRows = {}
        for _, group in ipairs(groups) do
            if #group.liveRows == 0 then
                remainingGroups[#remainingGroups + 1] = group
            end
        end
        for _, live in ipairs(liveRows) do
            if not assignedRows[live] then
                remainingRows[#remainingRows + 1] = live
            end
        end
        sort(remainingGroups, function(a, b)
            return a.firstSlot < b.firstSlot
        end)
        sort(remainingRows, function(a, b)
            return a.index < b.index
        end)
        if #remainingGroups == #remainingRows then
            for index, group in ipairs(remainingGroups) do
                group.liveRows[1] = remainingRows[index]
            end
        end
    end

    local questDone = cur and cur.CompleteMerge and true or false
    for _, group in ipairs(groups) do
        local selectedLive
        local allDone = #group.liveRows > 0
        for _, live in ipairs(group.liveRows) do
            if not selectedLive or (selectedLive.finished and not live.finished) then
                selectedLive = live
            end
            if not live.finished then allDone = false end
        end

        for _, slot in ipairs(group.slots) do
            states[slot] = {
                done = questDone or allDone,
                objectiveIndex = selectedLive and selectedLive.index or slot,
                text = selectedLive and selectedLive.text or group.label,
                matched = selectedLive ~= nil,
                groupFirstSlot = group.firstSlot,
            }
        end
    end

    return states
end

function Nx.Quest:BuildCatalogObjectiveMask(quest, cur, questID)
    local mask = 0
    local objectives = quest and quest["Objectives"]
    if type(objectives) ~= "table" then return mask end

    local states = self:BuildObjectiveRenderState(quest, cur, questID)
    for slot = 1, 15 do
        if objectives[slot]
            and not (states[slot] and states[slot].done) then
            mask = mask + bit_lshift(1, slot)
        end
    end
    return mask
end

-- C_TaskQuest.GetQuestsOnMap can include watched, nearby, and map-indicator
-- quests whose coordinates were projected onto the requested canvas. The
-- feed's `mapID` alone is therefore not sufficient proof that the quest belongs
-- to that zone. Match Blizzard's map-owner rules, then confirm ownership with
-- GetQuestZoneID so a Valarjar/Kirin Tor/Highmountain quest cannot be stamped
-- on an unrelated zone merely because the feed projected it there.
local function GetVisibleTaskMapID(info, viewMapID, trackedQuestID)
    if not info or type(info.questID) ~= "number"
        or type(info.x) ~= "number" or type(info.y) ~= "number" then
        return nil
    end

    viewMapID = GetSafeMapID(viewMapID)
    local feedMapID = GetSafeMapID(info.mapID or info.mapId)
    if not viewMapID or not feedMapID then
        return nil
    end

    local questMapID
    if _G.C_TaskQuest and _G.C_TaskQuest.GetQuestZoneID then
        questMapID = GetSafeMapID(
            _G.C_TaskQuest.GetQuestZoneID(info.questID)
        )
    end
    questMapID = questMapID or feedMapID

    -- The normal WorldMap data-provider path requires the feed map to equal
    -- the displayed map. Carbonite additionally verifies that the canonical
    -- quest zone is that map or one of its children.
    if feedMapID == viewMapID then
        return IsMapSameOrDescendant(questMapID, viewMapID)
            and questMapID or nil
    end

    local mapAPI = _G.C_Map
    local mapTypes = _G.Enum and _G.Enum.UIMapType
    if not mapAPI or not mapAPI.GetMapInfo or not mapTypes then
        return nil
    end

    local viewMapInfo = mapAPI.GetMapInfo(viewMapID)
    if not viewMapInfo then
        return nil
    end

    local childDepth = info.childDepth
    if childDepth ~= nil and issecretvalue and issecretvalue(childDepth) then
        childDepth = nil
    end
    childDepth = tonumber(childDepth)

    local isChildMapQuest = childDepth and childDepth > 0
        and viewMapInfo.mapType == mapTypes.Zone
    local isTrackedContinentQuest = info.questID == trackedQuestID
        and viewMapInfo.mapType == mapTypes.Continent
    if not isChildMapQuest and not isTrackedContinentQuest then
        return nil
    end

    if IsMapSameOrDescendant(feedMapID, viewMapID)
        and IsMapSameOrDescendant(questMapID, viewMapID) then
        return questMapID
    end

    return nil
end

-- Build the map candidates once per icon refresh. Blizzard's minimap quest
-- icons are rendered inside the native Minimap object rather than as child
-- frames, so Carbonite must mirror their public quest-POI coordinates. The
-- shared feed cache prevents GetQuestsOnMap from being called once per watched
-- quest when several quests are tracked in the same zone.
local function BuildLiveQuestPOIContext(viewMapID)
    local context = {
        mapIDs = {},
        seenMapIDs = {},
        questsByMap = {},
    }

    local function addMapID(value)
        value = GetSafeMapID(value)
        if value and value ~= 9000 and not context.seenMapIDs[value] then
            context.seenMapIDs[value] = true
            context.mapIDs[#context.mapIDs + 1] = value
        end
    end

    local function addMapWithParent(value)
        value = GetSafeMapID(value)
        addMapID(value)
        if not value or not (C_Map and C_Map.GetMapInfo) then
            return
        end

        -- Blizzard frequently reports an outdoor campaign phase as a Micro
        -- map while GetQuestsOnMap publishes its quest POI on the parent Zone.
        -- Query that immediate parent as a second canvas; the questID match
        -- below prevents unrelated parent-map quests from being mirrored.
        local ok, info = pcall(C_Map.GetMapInfo, value)
        if ok and type(info) == "table" then
            addMapID(info.parentMapID)
        end
    end

    context.addMapWithParent = addMapWithParent

    -- The Carbonite view is authoritative. The native minimap and player map
    -- are fallbacks for micro-zones whose parent map is displayed by Carbonite.
    addMapWithParent(viewMapID)
    if C_Minimap and C_Minimap.GetUiMapID then
        local ok, minimapID = pcall(C_Minimap.GetUiMapID)
        if ok then addMapWithParent(minimapID) end
    end
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then addMapWithParent(playerMapID) end
    end

    return context
end

local function GetLiveQuestsOnMap(context, mapID)
    local cached = context.questsByMap[mapID]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    local quests
    if C_QuestLog and C_QuestLog.GetQuestsOnMap then
        local ok, value = pcall(C_QuestLog.GetQuestsOnMap, mapID)
        if ok and type(value) == "table" then
            quests = value
        end
    end
    context.questsByMap[mapID] = quests or false
    return quests
end

-- Return one watched quest's Blizzard-published coordinate in Carbonite world
-- space. This follows the supplied QuestDataProvider sources precisely:
-- GetQuestsOnMap is shared by all clients; Retail alone adds
-- GetNextWaypointForMap, and only for the focused/super-tracked quest. The
-- unrelated GetNextWaypoint API is intentionally not used as a fallback.
local function GetLiveTrackedQuestPOI(map, questID, viewMapID, context,
    activeQuestID)
    questID = GetSafeMapID(questID)
    if not questID or not C_QuestLog then
        return
    end

    local function isPublicNumber(value)
        return type(value) == "number"
            and (not issecretvalue or not issecretvalue(value))
    end

    context = context or BuildLiveQuestPOIContext(viewMapID)
    if C_TaskQuest and C_TaskQuest.GetQuestZoneID
        and context.addMapWithParent then
        local ok, questMapID = pcall(C_TaskQuest.GetQuestZoneID, questID)
        if ok then context.addMapWithParent(questMapID) end
    end
    local mapIDs = context.mapIDs

    local function convert(mapID, x, y)
        if not mapID or not isPublicNumber(x) or not isPublicNumber(y)
            or x < 0 or x > 1 or y < 0 or y > 1 then
            return
        end
        local ok, wx, wy = pcall(map.GetWorldPos, map, mapID, x * 100, y * 100)
        if ok and isPublicNumber(wx) and isPublicNumber(wy)
            and (wx ~= 0 or wy ~= 0) then
            return mapID, wx, wy
        end
    end

    if not QuestMapCompat:AreQuestPOIsEnabled() then return end

    local focusedQuestID
    if type(_G.QuestMapFrame_GetFocusedQuestID) == "function" then
        local ok, value = pcall(_G.QuestMapFrame_GetFocusedQuestID)
        if ok then focusedQuestID = GetSafeMapID(value) end
    end
    local mayUseWaypoint = QuestMapCompat:IsModernQuestDataProvider()
        and (questID == GetSafeMapID(activeQuestID)
            or questID == focusedQuestID)

    local poiMapID, worldX, worldY, isWaypoint
    if mayUseWaypoint then
        for _, mapID in ipairs(mapIDs) do
            local ok, x, y = pcall(
                C_QuestLog.GetNextWaypointForMap,
                questID, mapID)
            if ok and QuestMapCompat:ShouldUseQuestMapEntry(
                questID, mapID, nil) then
                poiMapID, worldX, worldY = convert(mapID, x, y)
                if poiMapID then
                    isWaypoint = true
                    break
                end
            end
        end
    end

    if not poiMapID and C_QuestLog.GetQuestsOnMap then
        for _, mapID in ipairs(mapIDs) do
            local quests = GetLiveQuestsOnMap(context, mapID)
            if quests then
                for _, info in ipairs(quests) do
                    local infoQuestID = info and GetSafeMapID(info.questID)
                    if infoQuestID == questID
                        and QuestMapCompat:ShouldUseQuestMapEntry(
                            questID, mapID, info) then
                        poiMapID, worldX, worldY = convert(mapID, info.x, info.y)
                        if poiMapID then break end
                    end
                end
            end
            if poiMapID then break end
        end
    end

    if not poiMapID then
        return
    end

    local title
    if C_QuestLog.GetTitleForQuestID then
        local ok, value = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and type(value) == "string"
            and (not issecretvalue or not issecretvalue(value)) then
            title = value
        end
    end
    title = GetCatalogQuestTitle(questID, title)

    local objectiveText
    if C_QuestLog.GetNextWaypointText then
        local ok, value = pcall(C_QuestLog.GetNextWaypointText, questID)
        if ok and type(value) == "string"
            and (not issecretvalue or not issecretvalue(value)) then
            objectiveText = value
        end
    end

    local complete = false
    if C_QuestLog.IsComplete then
        local ok, value = pcall(C_QuestLog.IsComplete, questID)
        if ok and (not issecretvalue or not issecretvalue(value)) then
            complete = value == true
        end
    end

    return questID, poiMapID, worldX, worldY, title, objectiveText,
        complete, isWaypoint == true
end

local function FindCurForLiveQuestID(Quest, questID)
    local cur = Quest.IdToCurQ and Quest.IdToCurQ[questID]
    if cur then return cur end

    for _, candidate in ipairs(Quest.CurQ or {}) do
        local liveQID = Quest.ResolveCatalogQuestID
            and Quest:ResolveCatalogQuestID(candidate.QId, candidate.QI)
            or candidate.QId
        if liveQID == questID then
            return candidate
        end
    end
end

-- Collect every quest Carbonite or Blizzard considers tracked. Retail exposes
-- indexed regular/world-quest watch lists; older clients are covered through
-- Carbonite's tracking table and the legacy IsQuestWatched(logIndex) API.
local function GetTrackedQuestIDs(Quest, activeQID)
    local questIDs, seen = {}, {}
    local function addQuestID(value)
        value = GetSafeMapID(value)
        if value and not seen[value] then
            seen[value] = true
            questIDs[#questIDs + 1] = value
        end
    end

    addQuestID(activeQID)

    local function addIndexedWatches(countFunc, idFunc)
        if not countFunc or not idFunc then return end
        local ok, count = pcall(countFunc)
        if not ok or type(count) ~= "number"
            or (issecretvalue and issecretvalue(count)) then
            return
        end
        count = math.min(math.max(floor(count), 0), 100)
        for index = 1, count do
            local idOK, questID = pcall(idFunc, index)
            if idOK then addQuestID(questID) end
        end
    end

    if C_QuestLog then
        addIndexedWatches(
            C_QuestLog.GetNumQuestWatches,
            C_QuestLog.GetQuestIDForQuestWatchIndex
        )
        addIndexedWatches(
            C_QuestLog.GetNumWorldQuestWatches,
            C_QuestLog.GetQuestIDForWorldQuestWatchIndex
        )
    end

    -- Carbonite's own active/tracking state is authoritative on Classic and
    -- also covers the brief Retail interval before QUEST_WATCH_LIST_CHANGED.
    for trackID in pairs(Quest.Tracking or {}) do
        local cur = Quest.IdToCurQ and Quest.IdToCurQ[trackID]
        local liveQID = cur and Quest.ResolveCatalogQuestID
            and Quest:ResolveCatalogQuestID(cur.QId, cur.QI)
            or trackID
        addQuestID(liveQID)
    end

    for _, cur in ipairs(Quest.CurQ or {}) do
        local liveQID = Quest.ResolveCatalogQuestID
            and Quest:ResolveCatalogQuestID(cur.QId, cur.QI)
            or cur.QId
        local watched = false

        if liveQID and C_QuestLog and C_QuestLog.GetQuestWatchType then
            local ok, watchType = pcall(C_QuestLog.GetQuestWatchType, liveQID)
            if ok and (not issecretvalue or not issecretvalue(watchType)) then
                watched = watchType ~= nil
            end
        elseif cur.QI and cur.QI > 0 and _G.IsQuestWatched then
            local ok, value = pcall(_G.IsQuestWatched, cur.QI)
            if ok and (not issecretvalue or not issecretvalue(value)) then
                watched = value == true
            end
        end

        if not watched and Quest.GetQuest then
            local ok, status = pcall(Quest.GetQuest, Quest, cur.QId)
            watched = ok and status == "W"
        end
        if watched then addQuestID(liveQID) end
    end

    return questIDs
end

-------------------------------------------------------------------------------
-- Update map icons (called by map)
-------------------------------------------------------------------------------

-- Cache for world-quest task info (refreshes every second, retail only).
-- The cache is bound to the map that produced it. A same-map grace period
-- absorbs Blizzard's occasional transient empty refresh without ever
-- retaining outdoor tasks across a map or instance boundary.
local TASK_CACHE_EMPTY_GRACE = 2
local taskInfoCache = {
    mapID = nil,
    data = nil,
    lastGood = 0,
}

local function ClearTaskInfoCache()
    taskInfoCache.mapID = nil
    taskInfoCache.data = nil
    taskInfoCache.lastGood = 0
end

function Nx.Quest:ClearTaskInfoCache()
    ClearTaskInfoCache()
end

local function RefreshTaskInfoCache(mapID, forceMapBoundary)
    if not mapID or mapID == 9000
        or IsInstanceIconContext(mapID)
        or not (C_TaskQuest and C_TaskQuest.GetQuestsOnMap) then
        ClearTaskInfoCache()
        return nil
    end

    if taskInfoCache.mapID ~= mapID then
        taskInfoCache.mapID = mapID
        taskInfoCache.data = nil
        taskInfoCache.lastGood = 0
        forceMapBoundary = true
    end

    local fresh = C_TaskQuest.GetQuestsOnMap(mapID)
    local now = GetTime()
    if fresh and #fresh > 0 then
        taskInfoCache.data = fresh
        taskInfoCache.lastGood = now
    elseif forceMapBoundary
        or taskInfoCache.lastGood == 0
        or now - taskInfoCache.lastGood > TASK_CACHE_EMPTY_GRACE then
        taskInfoCache.data = nil
    end

    return taskInfoCache.data
end

local taskInfoCacheTimer = nil
if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
    taskInfoCacheTimer = C_Timer.NewTicker(1, function()
        if Nx.Map and Nx.Map.UpdateMapID then
            RefreshTaskInfoCache(Nx.Map.UpdateMapID, false)
        end
    end)
end

-- Blizzard's QuestLogMixin synchronizes the quest POI subsystem to the map
-- before its QuestDataProvider asks for C_QuestLog.GetQuestsOnMap. Carbonite
-- previously queried that feed without performing the synchronization, so a
-- zone/phase transition could leave the feed describing the previous map
-- until Blizzard's World Map happened to be opened. Cache by mapID to avoid
-- writing the global POI map every frame.
local synchronizedQuestPOIMapID
function Nx.Quest:SyncQuestPOIMap(mapID, force)
    mapID = GetSafeMapID(mapID)
    if not mapID or not C_QuestLog
        or type(C_QuestLog.SetMapForQuestPOIs) ~= "function" then
        return false
    end
    if not force and synchronizedQuestPOIMapID == mapID then
        return true
    end

    local ok = pcall(C_QuestLog.SetMapForQuestPOIs, mapID)
    if ok then
        synchronizedQuestPOIMapID = mapID
        self._iconDirty = true
        return true
    end
    return false
end

function Nx.Quest:UpdateIcons (map)
    if not Nx.QInit then
        return
    end
    local Nx = Nx
    local Quest = Nx.Quest
    local Map = Nx.Map
    local viewMapID = Map.UpdateMapID or map.MapId
    Quest:SyncQuestPOIMap(viewMapID)
    local instanceIconContext = IsInstanceIconContext(viewMapID)
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
    local isMinimizedMap = map.Win and not map.Win:IsSizeMax()
    local showOnMap = Quest.Watch.ButShowOnMap:GetPressed()

    local typ, tid = Map:GetTargetInfo()
    if typ == "Q" then

--        Nx.prt ("QTar %s", tid)

        local qid = floor (tid / 100)
        local i, cur = Quest:FindCur (qid)

        if cur then
            Quest:CalcDistances (cur.Index, cur.Index)
            local liveQID = Quest.ResolveCatalogQuestID
                and Quest:ResolveCatalogQuestID(cur.QId, cur.QI)
                or cur.QId
            Quest:TrackOnMap (liveQID, tid % 100, cur.QI > 0 or cur.Party, true, true)

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
            .. "|" .. tickBucket .. "|" .. (instanceIconContext and 1 or 0)
            .. "|" .. (isMinimizedMap and 1 or 0)
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

    local authoritativeLiveQuestPins = {}

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

    -- Mirror Blizzard's one-pin-per-quest model onto both Carbonite map sizes.
    -- Every supplied client uses C_QuestLog.GetQuestsOnMap. Retail alone adds
    -- the focused/super-tracked quest's GetNextWaypointForMap result; the
    -- compatibility adapter supplies Retail's composite POI atlases or the
    -- legacy numbered textures used unchanged by Era/TBC/Mists. Once accepted,
    -- that live pin is authoritative for the whole quest and the catalog is a
    -- fallback only when Blizzard publishes no usable coordinate.
    if Nx.Quest.AddLivePOI then
        local liveContext = BuildLiveQuestPOIContext(viewMapID)
        local trackedQuestIDs = GetTrackedQuestIDs(Quest, activeQID)
        for questNumber, trackedQID in ipairs(trackedQuestIDs) do
            local liveQID, liveMapID, liveX, liveY, liveTitle,
                liveObjective, liveComplete, liveIsWaypoint =
                GetLiveTrackedQuestPOI(
                    map,
                    trackedQID,
                    viewMapID,
                    liveContext,
                    activeQID
                )
            if liveQID and liveMapID and liveX and liveY then
                local cur = FindCurForLiveQuestID(Quest, liveQID)
                local liveRenderMapID = GetQuestRenderMapID(
                    liveMapID,
                    viewMapID
                )
                if liveRenderMapID and liveRenderMapID ~= liveMapID then
                    local liveMapX, liveMapY = map:GetZonePos(
                        liveMapID, liveX, liveY)
                    liveRenderMapID, liveX, liveY =
                        Quest:ProjectObjectivePoint(
                            map,
                            liveMapID,
                            liveMapX,
                            liveMapY,
                            viewMapID
                        )
                end
                local isActive = liveQID == activeQID
                local objectiveIndex = isActive
                    and (tonumber(Quest.ActiveObjI) or 0) or 0
                if objectiveIndex < 0 or objectiveIndex > 15 then
                    objectiveIndex = 0
                end

                local tip = Nx.TXTBLUE .. L["Quest: "] .. liveTitle
                if liveObjective and liveObjective ~= "" then
                    tip = tip .. "\n" .. liveObjective
                end
                local visual = QuestMapCompat:GetQuestPinVisual(
                    liveQID,
                    isActive,
                    liveComplete,
                    liveIsWaypoint,
                    questNumber
                )
                local texCoord = visual.texCoord
                local livePin = liveRenderMapID and Nx.Quest:AddLivePOI(liveX, liveY, {
                    tip         = tip,
                    tex         = visual.tex,
                    tx1         = texCoord and texCoord[1] or nil,
                    ty1         = texCoord and texCoord[2] or nil,
                    tx2         = texCoord and texCoord[3] or nil,
                    ty2         = texCoord and texCoord[4] or nil,
                    displayAtlas = visual.displayAtlas,
                    displayTex = visual.displayTex,
                    displayTexCoord = visual.displayTexCoord,
                    displayWidth = visual.displayWidth,
                    displayHeight = visual.displayHeight,
                    NXType      = cur and (9000 + objectiveIndex) or 3000,
                    NXData      = cur,
                    mapID       = liveRenderMapID,
                    vertexColor = {1, 1, 1, 1},
                    -- Blizzard's selected/super-tracked ring already carries
                    -- the active state. Do not add Carbonite's separate halo
                    -- or an objective number over Blizzard's own display.
                    showGlow    = false,
                    label       = nil,
                    w           = visual.width,
                    h           = visual.height,
                })
                if livePin then
                    authoritativeLiveQuestPins[liveQID] = true
                end
            end
        end
    end

    -- Blob

--    local f = self.BlobFrm


    -- Draw completed quests

    for k, cur in ipairs (Quest.CurQ) do

        if cur.Q and cur.CompleteMerge then

            local q = cur.Q
            local obj = q["End"] or q["Start"]

            local endName, zone, x, y = Quest:GetSEPos (obj)
            local mapId = zone

            if mapId and IsQuestMapRelevant(mapId, viewMapID) then

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

        local cur = Quest.IdToCurQ and Quest.IdToCurQ[trackId]
        local quest = cur and cur.Q or Nx.Quests[trackId]
        if not cur and not quest then
            -- tracking entry exists but quest data is gone, skip
        else
            local resolvedQuestID
            if cur then
                resolvedQuestID = Quest.ResolveCatalogQuestID
                    and Quest:ResolveCatalogQuestID(cur.QId, cur.QI)
                    or cur.QId
            end
            local isSuperTracked = activeQID > 0
                and resolvedQuestID == activeQID
            local qname = Nx.TXTBLUE .. L["Quest: "] .. (cur and cur.Title or Quest:UnpackName (quest["Quest"]))

            local mask = showOnMap and cur and cur.TrackMask or trackMode
            local showEnd

            if bit_band (mask, 1) > 0 then

                if not (cur and (cur.QI > 0 or cur.Party)) then

                    local startName, zone, x, y = Quest:GetSEPos (quest["Start"])
                    local mapId = zone

                    if mapId and IsQuestMapRelevant(mapId, viewMapID) then
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

                if mapId and IsQuestMapRelevant(mapId, viewMapID)
                    and (not cur or not cur.CompleteMerge) then

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

                local objectiveStates = Quest:BuildObjectiveRenderState(
                    quest, cur, resolvedQuestID or trackId)

                for n = 1, 15 do

                    local obj = quest["Objectives"]
                    if obj then
                        obj = quest["Objectives"][n]
                    end
                    if obj then

                    local objName, objZone, typ = Nx.Quest:UnpackObjectiveNew (obj)
                    local objectiveState = objectiveStates[n] or {}
                    local objectiveIndex = tonumber(
                        objectiveState.objectiveIndex) or n

                    local objectiveRenderMapID = GetQuestRenderMapID(
                        objZone,
                        viewMapID
                    )

                    if objZone and objZone ~= 9000
                        and objectiveRenderMapID then

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
                        local renderObj = bit_band (
                            mask, bit_lshift (1, n)) > 0
                            or (cur and cur.QI and cur.QI > 0)
                        -- Completion comes from the identity group, not the
                        -- catalog slot number. Every known location for one
                        -- live objective therefore appears and disappears as
                        -- a unit.
                        local objDone = objectiveState.done == true
                        if objDone then renderObj = false end
                        if renderObj then
                            local colI = objectiveState.groupFirstSlot or n

                            if colorPerQ then
                                colI = ((cur and cur.Index or 1) - 1) % colMax + 1
                            end

                            local col = qLocColors[colI]
                            local r = col[1]
                            local g = col[2]
                            local b = col[3]

                            local oname = objectiveState.text or objName or "?"

                            -- Per-POI dispatch. The objective list can mix
                            -- typ 32 (points) and typ 35 (area spans) — e.g.
                            -- a quest that has a static area-blob in its
                            -- data files AND a runtime point pin from
                            -- Blizzard's API. Render each POI according to
                            -- its own typ so the area span isn't hidden by
                            -- the first-POI dispatch.

                            local hover = Quest.IconHoverCur == cur
                                and Quest.IconHoverObjI == n
                            local tracking = bit_band (
                                trackMode, bit_lshift (1, n)) > 0
                            local tip = format ("%s\nObj: %s", qname, oname)
                            if cur and cur[objectiveIndex + 400] then
                                tip = tip .. "\n" .. cur[objectiveIndex + 400]
                            end

                            -- Blizzard's QuestDataProvider publishes one live
                            -- marker for the quest rather than one marker for
                            -- every possible object spawn. Suppress every
                            -- catalog point for that quest only after the live
                            -- pin has actually entered Carbonite's provider.
                            -- Area geometry remains visible, and if the live
                            -- pin is unavailable/rejected the catalog points
                            -- below continue to provide the legacy fallback.
                            local hasLiveQuestPin = resolvedQuestID
                                and authoritativeLiveQuestPins[resolvedQuestID]
                                == true

                            -- Resolve the stable point/area geometry once.
                            -- The old closest-edge IconAreaArrows marker used
                            -- cur.OX/cur.OY, which changes with player position
                            -- and produced the moving arrow trail. It is now
                            -- intentionally disabled on both Carbonite map
                            -- sizes; area-only objectives use the fixed center
                            -- marker below instead.
                            local hasPointPOI, hasSpanForArrow,
                                areaMarkerMapID, areaMarkerX, areaMarkerY =
                                GetAreaObjectiveMarker(
                                    map,
                                    obj,
                                    viewMapID
                                )

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
                                    local poiRenderMapID = GetQuestRenderMapID(
                                        pmap,
                                        viewMapID
                                    )
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
                                    elseif not poiRenderMapID then
                                        -- The POI belongs to an outdoor or unrelated
                                        -- map and must not cross an instance boundary.
                                    elseif poiTyp == 32 then
                                        -- Catalog point fallback. A successful
                                        -- live quest pin suppresses these so a
                                        -- multi-location objective still shows
                                        -- exactly one Blizzard-style marker.
                                        if not hasLiveQuestPin then
                                            local px, py = Nx.Quest:UnpackLocPtOff (loc1)
                                            if px and py then
                                                local projectedMapID, wx, wy =
                                                    Quest:ProjectObjectivePoint(
                                                        map,
                                                        pmap,
                                                        px,
                                                        py,
                                                        viewMapID
                                                    )
                                                if projectedMapID and Nx.Quest.AddPOI then
                                                    local ptip = format ("%s\nObj: %s (%.1f %.1f)", qname, oname, px, py)
                                                    if cur and cur[objectiveIndex + 400] then
                                                        ptip = ptip .. "\n" .. cur[objectiveIndex + 400]
                                                    end
                                                    local pvc = isSuperTracked
                                                        and {1, 0.85, 0, 1}
                                                        or  {r, g, b, .9}
                                                    Nx.Quest:AddPOI(wx, wy, {
                                                        tip         = ptip,
                                                        tex         = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQTarget",
                                                        NXType      = 9000 + n,
                                                        NXData      = cur,
                                                        mapID       = projectedMapID,
                                                        vertexColor = pvc,
                                                        showGlow    = isSuperTracked,
                                                        label       = tostring(objectiveIndex),
                                                    })
                                                elseif projectedMapID then
                                                    local f = map:GetIconStatic (4)
                                                    if map:ClipFrameByMapType (f, wx, wy, navscale, navscale, 0) then
                                                        f.NXType = 9000 + n
                                                        f.NXData = cur
                                                        f.NxTip = format ("%s\nObj: %s (%.1f %.1f)", qname, oname, px, py)
                                                        if cur and cur[objectiveIndex + 400] then
                                                            f.NxTip = f.NxTip .. "\n" .. cur[objectiveIndex + 400]
                                                        end
                                                        f.texture:SetTexture ("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQTarget")
                                                        if isSuperTracked then
                                                            f.texture:SetVertexColor (1, 0.85, 0, 1)
                                                            if f.NxGlow then f.NxGlow:Show() end
                                                        else
                                                            f.texture:SetVertexColor (r, g, b, .9)
                                                        end
                                                        if f.NxLabel then
                                                            f.NxLabel:SetText(tostring(objectiveIndex))
                                                            f.NxLabel:Show()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    elseif drawSpans
                                        and poiRenderMapID == pmap then
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
                                                    mapID       = poiRenderMapID,
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

                            -- Area-only objectives use one stable numbered
                            -- center marker on both the Carbonite map and
                            -- minimap only when Blizzard did not supply the
                            -- authoritative quest-level marker.
                            if hasSpanForArrow and not hasPointPOI
                                and not hasLiveQuestPin
                                and areaMarkerMapID and areaMarkerX and areaMarkerY then
                                local mvc = isSuperTracked
                                    and {1, 0.85, 0, 1}
                                    or  {r, g, b, .9}
                                if Nx.Quest.AddPOI then
                                    Nx.Quest:AddPOI(areaMarkerX, areaMarkerY, {
                                        tip         = tip,
                                        tex         = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQTarget",
                                        NXType      = 9000 + n,
                                        NXData      = cur,
                                        mapID       = areaMarkerMapID,
                                        vertexColor = mvc,
                                        showGlow    = isSuperTracked,
                                        label       = tostring(objectiveIndex),
                                    })
                                else
                                    local f = map:GetIconStatic(4)
                                    if map:ClipFrameByMapType(f, areaMarkerX,
                                        areaMarkerY, navscale, navscale, 0) then
                                        f.NXType = 9000 + n
                                        f.NXData = cur
                                        f.NxTip = tip
                                        f.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconQTarget")
                                        f.texture:SetVertexColor(mvc[1], mvc[2], mvc[3], mvc[4])
                                        if isSuperTracked and f.NxGlow then f.NxGlow:Show() end
                                        if f.NxLabel then
                                            f.NxLabel:SetText(tostring(objectiveIndex))
                                            f.NxLabel:Show()
                                        end
                                    end
                                end
                            end
                        end -- if bit_band(mask, ...)
                    end -- if objZone
                    end -- if objective slot exists
                end -- for n
            end -- if quest
        end -- if not cur and not quest
    end

    end -- if _walkDirty then (per-quest walk guarded by dirty-check)

    -- BONUS TASKS and WORLD QUESTS icons
    local taskIconIndex = 1
    if C_TaskQuest and C_TaskQuest.GetQuestsOnMap
        and viewMapID ~= 9000 and not instanceIconContext then
        local taskInfo = RefreshTaskInfoCache(viewMapID, Nx.Map.mapChange)
        if taskInfo and Nx.db.char.Map.ShowWorldQuest then
            for i = 1, #taskInfo do
                local info = taskInfo[i]
                local taskMapID = GetVisibleTaskMapID(info, viewMapID, activeQID)
                if taskMapID then
                local questID = info.questID
                local title, faction
                if C_TaskQuest.GetQuestInfoByQuestID then
                    title, faction = C_TaskQuest.GetQuestInfoByQuestID(questID)
                    if type(title) == "table" then
                        local questInfo = title
                        title = questInfo.title or questInfo.questName
                        faction = questInfo.factionID or questInfo.factionId or questInfo.faction
                    end
                end
                title = GetCatalogQuestTitle(questID, title)

                -- Fetch the quest tag information using the new API function
                local questTagInfo = GetQuestTagInfoCompat(questID)

                -- C_TaskQuest.GetQuestsOnMap returns world quests AND
                -- bonus objectives / threats. Bonus + threat are now
                -- drawn by MapEngine's dedicated _type=9 slot under the
                -- "Show Bonus Objectives" toggle with the Blizzard
                -- Bonus-Objective-Star atlas, so skip them in BOTH
                -- branches of this loop -- the questTagInfo branch
                -- (WQ-style icon) AND the fallback else-branch (which
                -- otherwise stamps a "Bonus Task" ObjectIconsAtlas
                -- pin). Real world quests still pass through.
                local skipBonusOrThreat = false
                if _G.C_QuestInfoSystem and _G.C_QuestInfoSystem.GetQuestClassification
                    and _G.Enum and _G.Enum.QuestClassification then
                    local cls = _G.C_QuestInfoSystem.GetQuestClassification(questID)
                    skipBonusOrThreat = cls == _G.Enum.QuestClassification.BonusObjective
                                     or cls == _G.Enum.QuestClassification.Threat
                end

                if not skipBonusOrThreat then
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
                    local isWorldQuest = not info.isMeta
                    if _G.QuestUtils_IsQuestWorldQuest then
                        isWorldQuest =
                            _G.QuestUtils_IsQuestWorldQuest(questID) == true
                    end
                    -- Important/campaign quests already use Carbonite's quest
                    -- offer and active-quest providers. Only actual world
                    -- quests or Blizzard map-indicator tasks belong in this
                    -- World Quest icon pool.
                    local isOwnedMapIndicator =
                        info.isMapIndicatorQuest == true
                        and taskMapID == viewMapID
                    local canShowAsWorldQuest = isWorldQuest
                        or isOwnedMapIndicator
                    if canShowAsWorldQuest
                        and (QuestUtils_ShouldDisplayExpirationWarning(questID)
                            or (timeLeft and timeLeft > 0) or isImportantQuest) then
                        local x, y = info.x * 100, info.y * 100
                        -- Task coordinates are normalized to the map passed
                        -- to GetQuestsOnMap, even for a valid child-map quest.
                        local worldX, worldY = map:GetWorldPos(viewMapID, x, y)
                        local f = map:GetIconWQ(120)
                        f.questID = info.questID
                        f.mapID = taskMapID

                        -- Use hideOutside=true to completely hide icon when outside visible area
                        if not map:ClipFrameByMapType(
                            f, worldX, worldY, 24, 24, 0, true
                        ) then
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
                            -- Toggle the Goto waypoint instead of
                            -- unconditionally re-setting it; second
                            -- click on the same WQ clears it (parity
                            -- with the bonus-objective pin behaviour).
                            map:ToggleGotoQuest(self.questID, worldX, worldY,
                                C_TaskQuest.GetQuestInfoByQuestID(self.questID),
                                self.mapID)
                            if not InCombatLockdown() and self.worldQuest then
                                if not ChatEdit_TryInsertQuestLinkForQuestID(self.questID) then
                                    -- Capture click-time inputs and defer the
                                    -- mutations to the next tick. The actual
                                    -- C APIs are then invoked through the
                                    -- secure-call helpers; a timer by itself
                                    -- still runs as Carbonite and does not
                                    -- remove execution taint.
                                    -- Calling C_SuperTrack.* / QuestUtil from
                                    -- this Carbonite click stack propagates taint
                                    -- through Blizzard's CallbackRegistry
                                    -- super-track chain, which ends at
                                    -- QuestDataProvider:RefreshAllData
                                    -- → AcquirePin → SetPassThroughButtons
                                    -- — a protected call that throws
                                    -- ADDON_ACTION_BLOCKED blaming
                                    -- Carbonite (typically surfaces on WQ
                                    -- completion when Blizzard auto-clears it).
                                    local questID = self.questID
                                    local mapID = self.mapID
                                    local shift = IsShiftKeyDown()
                                    local watchType = C_QuestLog.GetQuestWatchType(questID)
                                    local isSuperTracked = C_SuperTrack.GetSuperTrackedQuestID() == questID

                                    if ZygorGuidesViewer and ZygorGuidesViewer.WorldQuests then
                                        ZygorGuidesViewer.WorldQuests:SuggestWorldQuestGuideFromMap(nil, questID, "force", mapID)
                                    end

                                    C_Timer.After(0, function()
                                        -- Combat may begin within the tick;
                                        -- SuperTrackSafe re-defers to
                                        -- PLAYER_REGEN_ENABLED then, since
                                        -- the tainted SUPER_TRACKING_CHANGED
                                        -- chain trips the combat-protected
                                        -- SetPassThroughButtons.
                                        Nx.SuperTrackSafe(function()
                                        if shift then
                                            if watchType == Enum.QuestWatchType.Manual or (watchType == Enum.QuestWatchType.Automatic and isSuperTracked) then
                                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                                                Nx.RemoveWorldQuestWatchSafe(questID)
                                            else
                                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                                Nx.AddWorldQuestWatchSafe(questID, Enum.QuestWatchType.Manual)
                                            end
                                        else
                                            if isSuperTracked then
                                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                                                Nx.SetSuperTrackedQuestIDSafe(0)
                                            else
                                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                                if watchType ~= Enum.QuestWatchType.Manual then
                                                    Nx.AddWorldQuestWatchSafe(questID, Enum.QuestWatchType.Automatic)
                                                end
                                                Nx.SetSuperTrackedQuestIDSafe(questID)
                                            end
                                        end
                                        end)
                                    end)
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
                        local x, y = info.x * 100, info.y * 100
                        local worldX, worldY = map:GetWorldPos(viewMapID, x, y)
                        local f = map:GetIcon(3)
                        f.mapID = taskMapID

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
                                if not map:ClipFrameByMapType(
                                    f, worldX, worldY, 22, 22, 0, true
                                ) then
                                    f:Hide()
                                else
                                    local left, right, top, bottom
                                    if GetObjectIconTextureCoords then
                                        left, right, top, bottom = GetObjectIconTextureCoords(4713)
                                    end

                                    if left and right and top and bottom then
                                        f.texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas")
                                        f.texture:SetTexCoord(left, right, top, bottom)
                                        f.texture:Show()
                                    elseif f.texture.SetAtlas then
                                        f.texture:SetAtlas("Bonus-Objective-Star")
                                        f.texture:Show()
                                    else
                                        f:Hide()
                                    end

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
                            if map:ClipFrameByMapType(
                                f, worldX, worldY, 22, 22, 0, true
                            ) then
                                local left, right, top, bottom
                                if GetObjectIconTextureCoords then
                                    left, right, top, bottom = GetObjectIconTextureCoords(4734)
                                end

                                if left and right and top and bottom then
                                    f.texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas")
                                    f.texture:SetTexCoord(left, right, top, bottom)
                                    f.texture:Show()
                                elseif f.texture.SetAtlas then
                                    f.texture:SetAtlas("Bonus-Objective-Star")
                                    f.texture:Show()
                                else
                                    f:Hide()
                                end
                            else
                                f:Hide()
                            end
                        end
                    end
                end
                end -- if not skipBonusOrThreat
                end -- if task belongs to the displayed map
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
