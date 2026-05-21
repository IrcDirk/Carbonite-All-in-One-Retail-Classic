-- Carbonite.Notes | Integrations / Questie
-- Reads Questie's icon frames directly from QuestieMap.questIdFrames
-- instead of waiting for HBD-Pins to populate a WorldMapFrame pin
-- pool. This means Carbonite picks up quest objectives as soon as
-- Questie creates them, even if the user hasn't opened the world
-- map.
--
-- Attaches as Nx.Notes:Questie(mapId). Called from Nx.Notes:UpdateIcons
-- once the user has enabled the Questie integration in the options.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

Nx.Notes.QuestieCache     = Nx.Notes.QuestieCache or {}
Nx.Notes.QuestieLastMapId = nil

-- 10-color palette cycled per NPC so overlapping patrols can be
-- distinguished. Matches the convention used by the HandyNotes
-- patrol-path harvester (different palette so Questie and HandyNotes
-- routes don't visually collide).
local QUESTIE_PALETTE = {
    "FFFF8060", "FF60FFFF", "FFFF60FF", "FF60FF80",
    "FFFFFF60", "FF6080FF", "FFFFA0A0", "FFA0FFA0",
    "FFA0A0FF", "FFFFC080",
}
local function pickQuestiePathColor(npcId)
    if type(npcId) ~= "number" then npcId = 0 end
    return QUESTIE_PALETTE[(npcId % #QUESTIE_PALETTE) + 1]
end

-- Resolves Questie's icon frame from a stored frame name. Questie
-- keeps frame names (not direct refs) in questIdFrames; the actual
-- frame lives in _G.
local function resolveQuestieFrame(name)
    return name and _G[name]
end

---
-- Update Questie icons on the map.
-- @param mapId  Current map ID
--
function Nx.Notes:Questie(mapId)
    if not (Nx.fdb.profile.Notes.Questie and _G.Questie) then return end
    if not _G.QuestieLoader then return end

    local QuestieMap = _G.QuestieLoader:ImportModule("QuestieMap")
    if not QuestieMap or not QuestieMap.questIdFrames then return end

    local showAvailable = Nx.fdb.profile.Notes.QuestieSE

    -- Harvest Questie's frames for this map, building a content hash
    -- for dirty detection. Questie uses FakeShow/FakeHide rather than
    -- recreating frames when its display-type toggles flip, so the
    -- hash must include `frame.hidden` — otherwise toggling "Available
    -- Quests" off→on inside Questie's menu won't invalidate our
    -- cache and the icons won't reappear until the user changes zone.
    local icons = {}
    local currentHash = 0
    local function pushIcon(frame, data)
        icons[#icons + 1] = frame
        local qid = (data.QuestData and data.QuestData.Id)
            or (data.id) or 0
        currentHash = currentHash
            + (frame.x or 0) * 10000
            + (frame.y or 0) * 100
            + qid
            + (frame.hidden and 1 or 0) * 1e7
    end

    for questId, frameNames in pairs(QuestieMap.questIdFrames) do
        for _, name in pairs(frameNames) do
            local frame = resolveQuestieFrame(name)
            local data  = frame and frame.data
            if frame and data and data.QuestData and frame.UiMapID == mapId
                and not frame.hidden then
                local dataType = data.Type
                if (showAvailable and dataType == "available")
                    or dataType == "monster" or dataType == "item" then
                    pushIcon(frame, data)
                end
            end
        end
    end

    -- Manual icons (townsfolk: bankers, mailboxes, profession trainers,
    -- vendors, etc.) live in QuestieMap.manualFrames keyed by `typ` and
    -- then by data.id. Questie's right-click menu toggles these via
    -- Show/HideManualIcons (also Fake-hide based) so we skip hidden
    -- frames the same way.
    if QuestieMap.manualFrames then
        for _, byId in pairs(QuestieMap.manualFrames) do
            for _, frameList in pairs(byId) do
                for _, name in pairs(frameList) do
                    local frame = resolveQuestieFrame(name)
                    local data  = frame and frame.data
                    if frame and data and frame.UiMapID == mapId
                        and not frame.hidden then
                        pushIcon(frame, data)
                    end
                end
            end
        end
    end

    local cacheKey = mapId .. "_QUE"
    if self.QuestieCache[cacheKey] == currentHash
        and self.QuestieLastMapId == mapId
        and self.PrevQuestiePins == #icons then
        return
    end

    local map = Nx.Map:GetMap(1)
    map:ClearIconType("!QUE")
    self.QuestieCache[cacheKey] = currentHash
    self.QuestieLastMapId       = mapId
    self.PrevQuestiePins        = #icons

    map:InitIconType("!QUE", "WP", "",
        Nx.fdb.profile.Notes.QuestieSize or 32,
        Nx.fdb.profile.Notes.QuestieSize or 32)
    map:SetIconTypeChop("!QUE", true)
    map:SetIconTypeNoDockMinimap("!QUE", true)
    map:SetIconTypeLevel("!QUE", 20)

    -- Townsfolk (manualFrames) — bankers, mailboxes, profession trainers,
    -- vendors, etc. — get a smaller icon size than quest POIs. Questie
    -- itself renders these at 16 * iconScale (≈ 11px default); putting
    -- them in the !QUE layer makes them stamp at QuestieSize (32+),
    -- which dominates the map. Separate layer with a townsfolk size.
    local townSize = math.floor((Nx.fdb.profile.Notes.QuestieSize or 32) * 0.45)
    if townSize < 12 then townSize = 12 end
    map:InitIconType("!QUE_T", "WP", "", townSize, townSize)
    map:SetIconTypeChop("!QUE_T", true)
    map:SetIconTypeNoDockMinimap("!QUE_T", true)
    map:SetIconTypeLevel("!QUE_T", 20)

    -- Format a Questie-style tooltip directly from frame.data. Trying
    -- to scrape Questie's live MapIconTooltip:Show output is fragile —
    -- it walks HBDPins.worldmapProvider, which is empty unless
    -- Blizzard's WorldMap is currently visible. The data we need
    -- (quest name, type, objective description) lives on the frame
    -- regardless, so we just build the lines ourselves.
    local QuestieLib  = _G.QuestieLoader and _G.QuestieLoader:ImportModule("QuestieLib")
    local QuestieDBQ  = _G.QuestieLoader and _G.QuestieLoader:ImportModule("QuestieDB")
    local function buildQuestieTip(data)
        if not data then return nil end
        local lines = {}
        -- Townsfolk / manual icons (Type="manual") carry their tooltip
        -- pre-built in ManualTooltipData = { Title, Body = {{label,
        -- value}, ...} }. Use it verbatim and skip the quest-tooltip
        -- path entirely.
        if data.Type == "manual" and data.ManualTooltipData then
            local m = data.ManualTooltipData
            if m.Title then
                lines[#lines+1] = "|cFF33FF33" .. tostring(m.Title) .. "|r"
            end
            if type(m.Body) == "table" then
                for _, row in ipairs(m.Body) do
                    if type(row) == "table" and row[1] and row[2] then
                        lines[#lines+1] = "|cFFCCCCCC" .. tostring(row[1]) .. " " .. tostring(row[2]) .. "|r"
                    elseif type(row) == "string" then
                        lines[#lines+1] = "|cFFCCCCCC" .. row .. "|r"
                    end
                end
            end
            if #lines == 0 then return nil end
            lines[#lines+1] = " \t|cff80ff80Questie|r"
            return table.concat(lines, "\n")
        end
        local isGiver = data.Type == "available" or data.Type == "complete"
        -- Top line: giver name (green) for available/complete, NPC
        -- name (gray, indented) for an active objective. Same color
        -- convention Questie's own tooltip uses.
        local nm = data.Name
        if isGiver and nm then
            lines[#lines+1] = "|cFF33FF33" .. tostring(nm) .. "|r"
        end
        -- Quest title with level + state tag, via Questie's own
        -- helper so we match Questie's formatting exactly.
        local q = data.QuestData
        if q and q.Id then
            local title
            if QuestieLib and QuestieLib.GetColoredQuestName then
                local ok, result = pcall(QuestieLib.GetColoredQuestName,
                    QuestieLib, q.Id, true, true)
                if ok and type(result) == "string" and result ~= "" then
                    title = result
                end
            end
            if not title then
                local name = q.name or q.Name
                if QuestieDBQ and QuestieDBQ.QueryQuestSingle and not name then
                    local ok, n = pcall(QuestieDBQ.QueryQuestSingle, q.Id, "name")
                    if ok and n then name = n end
                end
                title = "|cFFFFFFFF" .. tostring(name or ("Quest " .. q.Id)) .. "|r"
            end
            if data.Type == "monster" or data.Type == "item" or data.Type == "event" then
                title = title .. " |cFFFFFF00(Active)|r"
            elseif data.Type == "available" then
                title = title .. " |cFFAAAAAA(Available)|r"
            elseif data.Type == "complete" then
                title = title .. " |cFF33FF33(Complete)|r"
            end
            lines[#lines+1] = title
        end
        -- For active-objective frames, indent the source NPC + the
        -- objective description (matches Questie's tooltip layout).
        if not isGiver and nm then
            lines[#lines+1] = "|cFFAAAAAA   " .. tostring(nm) .. "|r"
        end
        if data.ObjectiveData and data.ObjectiveData.Description then
            lines[#lines+1] = "|cFFCCCCCC   " .. tostring(data.ObjectiveData.Description) .. "|r"
        end
        if #lines == 0 then return nil end
        -- Right-aligned source tag, matches the HandyNotes icon tip
        -- and the patrol-path hover tooltip.
        lines[#lines+1] = " \t|cff80ff80Questie|r"
        return table.concat(lines, "\n")
    end

    for _, icon in ipairs(icons) do
        local texture = icon.texture and icon.texture:GetTexture()
        -- frame.x / frame.y are stored in 0..100 percentage form
        local wx, wy = Nx.Map:GetWorldPos(mapId, icon.x, icon.y)
        -- Townsfolk (manual icons) render smaller than quest POIs.
        -- Detect via the Questie-set frame flag isManualIcon (most
        -- reliable), data.Type, or data.IconScale (manual icons use
        -- 0.7; quest icons use 1.0).
        local isManual = icon.isManualIcon
            or (icon.data and icon.data.Type == "manual")
            or (icon.data and (icon.data.IconScale or 1) < 0.85)
        local layer = isManual and "!QUE_T" or "!QUE"
        local qnote = map:AddIconPt(layer, wx, wy, nil, "FFFFFF", texture)
        map:SetIconUserData(qnote, icon)
        local tip = buildQuestieTip(icon.data)
        if tip then map:SetIconTip(qnote, tip) end
    end

    -- Patrol-path harvester. Questie stores its rendered patrol
    -- segments as Button frames inside `frame.data.lineFrames`
    -- (see QuestieFramePool:CreateLine). Each entry's `.line` is a
    -- Line region anchored to the WorldMap canvas; reading its
    -- start/end points back out and converting pixel offsets to
    -- 0..100 map coords lets us replot the exact same path on
    -- Carbonite's canvas, even when the underlying npc.waypoints
    -- entry isn't in our snapshot of the Questie DB. This is the
    -- only path that catches item-start patrols like quest 9871
    -- "Murkblood Invaders".
    do
        local MapMod  = Carbonite:GetModule("Map", true)
        local Layer   = Carbonite.Modules.Map.Layer
        local canvas  = _G.WorldMapFrame and _G.WorldMapFrame.GetCanvas
            and _G.WorldMapFrame:GetCanvas()

        if MapMod and Layer and canvas then
            if Layer.All()["!QuestiePath"] then
                Layer.Get("!QuestiePath"):Clear()
            end

            local cw, ch = canvas:GetWidth(), canvas:GetHeight()
            if cw and ch and cw > 0 and ch > 0 then
                local seen     = {}  -- dedupe by lineFrame ref (icons share lines)
                local tipCache = {}  -- frame.data -> built tooltip

                local function dataTip(data)
                    if not data then return nil end
                    if tipCache[data] ~= nil then
                        return tipCache[data] or nil
                    end
                    local t = buildQuestieTip(data)
                    tipCache[data] = t or false
                    return t
                end

                local function emitLine(lineFrame, npcId, tipText)
                    if seen[lineFrame] then return end
                    seen[lineFrame] = true
                    local line = lineFrame.line
                    if not line or not line.GetStartPoint then return end
                    local _, _, sx, sy = line:GetStartPoint()
                    local _, _, ex, ey = line:GetEndPoint()
                    if not (sx and sy and ex and ey) then return end
                    local _, _, _, fx, fy = lineFrame:GetPoint(1)
                    if not (fx and fy) then return end
                    -- canvas-relative pixel offsets (Y is negative-down
                    -- under a TOPLEFT anchor)
                    local sxp, syp = fx + sx, fy + sy
                    local exp, eyp = fx + ex, fy + ey
                    -- back to 0..100 percent
                    local sxPct = sxp / cw * 100
                    local syPct = -syp / ch * 100
                    local exPct = exp / cw * 100
                    local eyPct = -eyp / ch * 100
                    local wx1, wy1 = Nx.Map:GetWorldPos(mapId, sxPct, syPct)
                    local wx2, wy2 = Nx.Map:GetWorldPos(mapId, exPct, eyPct)
                    if wx1 and wy1 and wx2 and wy2 then
                        local pin = MapMod:AddLine("!QuestiePath", "!QuestiePath", {
                            x = wx1, y = wy1, x2 = wx2, y2 = wy2,
                            mapID     = mapId,
                            color     = pickQuestiePathColor(npcId or 0),
                            thickness = 2,
                        })
                        if pin then
                            pin.npcId = npcId
                            pin.tip   = tipText
                                or (npcId and ("NPC ID: " .. tostring(npcId)))
                                or nil
                        end
                    end
                end

                for _, frameNames in pairs(QuestieMap.questIdFrames) do
                    for _, name in pairs(frameNames) do
                        local frame = resolveQuestieFrame(name)
                        local data  = frame and frame.data
                        if frame and data and frame.UiMapID == mapId
                            and type(data.lineFrames) == "table" then
                            -- Best-effort NPC id: prefer the objective
                            -- target, fall back to the first spawnList
                            -- key (Questie uses npcId as the spawn key).
                            local npcId = data.ObjectiveTargetId
                            if not npcId and data.ObjectiveData
                                and data.ObjectiveData.spawnList then
                                for spawnId in pairs(data.ObjectiveData.spawnList) do
                                    if type(spawnId) == "number" then
                                        npcId = spawnId
                                        break
                                    end
                                end
                            end
                            local tipText = dataTip(data)
                            for _, lf in ipairs(data.lineFrames) do
                                emitLine(lf, npcId, tipText)
                            end
                        end
                    end
                end
            end
        end
    end
end
