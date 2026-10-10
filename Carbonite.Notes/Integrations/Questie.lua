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
                    or dataType == "complete"
                    or dataType == "monster" or dataType == "item" then
                    pushIcon(frame, data)
                end
            end
        end
    end

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

    local townSize = math.floor((Nx.fdb.profile.Notes.QuestieSize or 32) * 0.45)
    if townSize < 12 then townSize = 12 end
    map:InitIconType("!QUE_T", "WP", "", townSize, townSize)
    map:SetIconTypeChop("!QUE_T", true)
    map:SetIconTypeNoDockMinimap("!QUE_T", true)
    map:SetIconTypeLevel("!QUE_T", 20)

    local QuestieLib  = _G.QuestieLoader and _G.QuestieLoader:ImportModule("QuestieLib")
    local QuestieDBQ  = _G.QuestieLoader and _G.QuestieLoader:ImportModule("QuestieDB")
    local function buildQuestieTip(data)
        if not data then return nil end

        local lines = {}

        if data.Type == "manual" and data.ManualTooltipData then
            local m = data.ManualTooltipData
            if m.Title then
                lines[#lines+1] = "|cFF33FF33" .. tostring(m.Title) .. "|r"
            end
            if type(m.Body) == "table" then
                for _, row in ipairs(m.Body) do
                    if type(row) == "table" and row[1] and row[2] then
                        lines[#lines+1] = "|cFFCCCCCC" .. tostring(row[1]) .. " " .. tostring(row[row[2] and 2 or 1]) .. "|r"
                    elseif type(row) == "string" then
                        lines[#lines+1] = "|cFFCCCCCC" .. row .. "|r"
                    end
                end
            end
            if #lines > 0 then
                lines[#lines+1] = " \t|cff80ff80Questie|r"
                return table.concat(lines, "\n")
            end
        end

        local isGiver = data.Type == "available" or data.Type == "complete"

        local nm = data.Name
        if not nm and data.QuestData then
            nm = data.QuestData.starterName or data.QuestData.finisherName or data.QuestData.name
        end

        if isGiver and nm then
            lines[#lines+1] = "|cFF33FF33" .. tostring(nm) .. "|r"
        end

        local q = data.QuestData
        local title = nil

        if q then
            if QuestieLib and QuestieLib.GetColoredQuestName and q.Id then
                local ok, result = pcall(QuestieLib.GetColoredQuestName, QuestieLib, q.Id, true, true)
                if ok and type(result) == "string" and result ~= "" then
                    title = result
                end
            end

            if not title then
                local name = q.name or q.Name or q.questName
                if QuestieDBQ and QuestieDBQ.QueryQuestSingle and q.Id and not name then
                    local ok, n = pcall(QuestieDBQ.QueryQuestSingle, q.Id, "name")
                    if ok and n then name = n end
                end
                if name then
                    title = "|cFFFFFFFF" .. tostring(name) .. "|r"
                end
            end
        end

        if not title then
            if q and q.Id then
                title = "|cFFFFFFFFQuest #" .. tostring(q.Id) .. "|r"
            elseif data.id then
                title = "|cFFFFFFFFQuest #" .. tostring(data.id) .. "|r"
            else
                title = "|cFFFFFFFFZakończone zadanie (Complete)|r"
            end
        end

        if data.Type == "monster" or data.Type == "item" or data.Type == "event" then
            title = title .. " |cFFFFFF00(Active)|r"
        elseif data.Type == "available" then
            title = title .. " |cFFAAAAAA(Available)|r"
        elseif data.Type == "complete" then
            title = title .. " |cFF33FF33(Complete)|r"
        end

        lines[#lines+1] = title

        if not isGiver and data.Name then
            lines[#lines+1] = "|cFFAAAAAA   " .. tostring(data.Name) .. "|r"
        end
        if data.ObjectiveData and data.ObjectiveData.Description then
            lines[#lines+1] = "|cFFCCCCCC   " .. tostring(data.ObjectiveData.Description) .. "|r"
        end

        lines[#lines+1] = " \t|cff80ff80Questie|r"

        return table.concat(lines, "\n")
    end

    for _, icon in ipairs(icons) do
        local texture = icon.texture and icon.texture:GetTexture()
        local wx, wy = Nx.Map:GetWorldPos(mapId, icon.x, icon.y)

        local isManual = icon.isManualIcon
            or (icon.data and icon.data.Type == "manual")
            or (icon.data and (icon.data.IconScale or 1) < 0.85)
        local layer = isManual and "!QUE_T" or "!QUE"
        
        local qnote = map:AddIconPt(layer, wx, wy, nil, "FFFFFF", texture)
        if qnote then
            qnote.mapID, qnote.MapId = mapId, mapId
            
            local tipText = buildQuestieTip(icon.data)
            if tipText then 
                -- Key fix: Assigning the text and a function that returns the text directly to Carbonite
                qnote.tip = tipText
                qnote.Tip = tipText
                qnote.Tooltip = tipText
                qnote.TipFunc = function() return tipText end
                
                map:SetIconTip(qnote, tipText)
            end
        end
    end

    -- Patrol-path harvester
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
                local seen     = {}
                local tipCache = {}

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
                    local sxp, syp = fx + sx, fy + sy
                    local exp, eyp = fx + ex, fy + ey
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
