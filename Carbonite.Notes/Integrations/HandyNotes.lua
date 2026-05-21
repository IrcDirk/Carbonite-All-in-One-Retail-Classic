-- Carbonite.Notes | Integrations / HandyNotes
-- Display HandyNotes pins on the Carbonite map. Walks every
-- registered HandyNotes plugin, harvests its node iterator, and
-- routes each node through the legacy Nx.Map AddIconPt facade. The
-- tooltip is read by parenting a reusable Frame onto WorldMapFrame's
-- canvas, firing the plugin's OnEnter, then scraping GameTooltip's
-- visible lines.
--
-- Attaches as Nx.Notes:HandyNotes(mapId). Called from
-- Nx.Notes:UpdateIcons.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- safecall lives on the Nx.Notes namespace (see NxFav.lua) so we
-- can reach it without depending on file-local scope.
local safecall = Nx.Notes.safecall

-- Distinct-but-readable colours cycled per patrol-path NPC so
-- overlapping routes can be told apart. AARRGGBB hex (the renderer
-- defaults to AA = FF when missing). Mid-saturation to stay legible
-- against both light and dark map backgrounds.
local PATH_PALETTE = {
    "FF60C0FF",  -- sky blue
    "FFFFB060",  -- orange
    "FF80FF80",  -- green
    "FFFF80FF",  -- magenta
    "FFFFFF60",  -- yellow
    "FF80FFFF",  -- cyan
    "FFFF6060",  -- red
    "FFC080FF",  -- violet
    "FF60FFB0",  -- mint
    "FFFFA0C0",  -- pink
}

-- Stable hash → palette index. Prefer the point's identity (npc id,
-- group string, or first route coord) so the same NPC keeps the same
-- colour across refreshes.
local function pickPathColor(point)
    local seed = point.npc or point.group
    if not seed and point.routes and point.routes[1] and point.routes[1][1] then
        seed = point.routes[1][1]
    end
    if not seed then return PATH_PALETTE[1] end
    if type(seed) == "string" then
        local sum = 0
        for i = 1, #seed do sum = sum + seed:byte(i) end
        seed = sum
    end
    return PATH_PALETTE[(seed % #PATH_PALETTE) + 1]
end

-- Cache for tracking map/level changes.
Nx.Notes.HandyNotesLastMapId = nil
Nx.Notes.HandyNotesLastLevel = nil

-- Reusable temp frame for tooltip extraction (avoids garbage
-- collection churn each update).
local handyTempFrame = nil
local function getHandyTempFrame()
    if not handyTempFrame then
        handyTempFrame = CreateFrame("Frame", "CarbHandyTemp", UIParent)
    end
    return handyTempFrame
end

---
-- Update HandyNotes icons on the map.
-- @param mapId  Current map ID
--
function Nx.Notes:HandyNotes(mapId)
    local map = Nx.Map:GetMap(1)
    if not (Nx.fdb.profile.Notes.HandyNotes and _G.HandyNotes) then return end

    local mapInfo = _G.C_Map.GetMapInfo(mapId)
    if not mapInfo or mapInfo.mapType ~= 3 then return end

    local lvl = Nx.Map:GetCurrentMapDungeonLevel()

    -- Quick check: if map and level haven't changed, skip entirely.
    if self.HandyNotesLastMapId == mapId and self.HandyNotesLastLevel == lvl then
        return
    end

    -- Map/level changed — clear and rebuild.
    map:ClearIconType("!HANDY")
    -- And the parallel patrol-path line layer harvested below.
    do
        local Layer = Carbonite.Modules.Map.Layer
        if Layer and Layer.All()["!HandyNotesPath"] then
            Layer.Get("!HandyNotesPath"):Clear()
        end
    end
    self.HandyNotesLastMapId = mapId
    self.HandyNotesLastLevel = lvl

    map:InitIconType("!HANDY", "WP", "",
        Nx.fdb.profile.Notes.HandyNotesSize or 15,
        Nx.fdb.profile.Notes.HandyNotesSize or 15)
    map:SetIconTypeChop("!HANDY", true)
    map:SetIconTypeNoDockMinimap("!HANDY", true)
    map:SetIconTypeLevel("!HANDY", 20)

    -- Reuse temp frame instead of creating new ones.
    local tempIcon = getHandyTempFrame()
    local tmpFrame = _G.WorldMapFrame:GetCanvas()
    tempIcon:SetParent(tmpFrame)

    for pluginName, pluginHandler in pairs(_G.HandyNotes.plugins) do
        _G.HandyNotes:UpdateWorldMapPlugin(pluginName)
        local pluginNodes, mapFile
        if type(pluginHandler.GetNodes) == "function" then
            mapFile = select(3, Nx.Map:GetLegacyMapInfo(mapId))
            pluginNodes = { pluginHandler:GetNodes(mapFile, false, lvl) }
        else
            pluginNodes = { pluginHandler:GetNodes2(mapId, false) }
        end
        Nx.pluginNodes = pluginNodes

        for coord, mapFile2, iconpath, scale, alpha, level2 in unpack(pluginNodes) do
            local x, y = floor(coord / 10000) / 100, (coord % 10000) / 100
            local wx, wy = Nx.Map:GetWorldPos(mapId, x, y)
            local texture, x1, x2, y1, y2
            if type(iconpath) == "table" then
                texture = iconpath.icon
                if iconpath.tCoordLeft then
                    x1 = iconpath.tCoordLeft
                    x2 = iconpath.tCoordRight
                    y1 = iconpath.tCoordTop
                    y2 = iconpath.tCoordBottom
                end
            else
                texture = iconpath
            end

            -- Reuse temp frame for tooltip extraction.
            tempIcon:ClearAllPoints()
            tempIcon:SetHeight(scale or 15)
            tempIcon:SetWidth(scale or 15)
            tempIcon:SetPoint("CENTER", tmpFrame, "TOPLEFT",
                              x * tmpFrame:GetWidth(),
                              -y * tmpFrame:GetHeight())
            safecall(_G.HandyNotes.plugins[pluginName].OnEnter, tempIcon,
                     mapFile and mapFile or mapId, coord)

            local tooltip = ""
            local tooltipName = "GameTooltip"
            local handynote
            if x1 then
                handynote = map:AddIconPt("!HANDY", wx, wy, level2, "FFFFFF", texture, x1, x2, y1, y2)
            else
                handynote = map:AddIconPt("!HANDY", wx, wy, level2, "FFFFFF", texture)
            end
            for i = 1, 10 do
                local text = _G[tooltipName .. "TextLeft" .. i]
                if text and text:IsShown() then
                    local R, G, B = text:GetTextColor()
                    R = Nx.Util_dec2hex(R * 255)
                    G = Nx.Util_dec2hex(G * 255)
                    B = Nx.Util_dec2hex(B * 255)
                    if #tooltip == 0 then
                        tooltip = "|cFF" .. R .. G .. B .. text:GetText()
                    else
                        tooltip = tooltip .. "\n|cFF" .. R .. G .. B .. text:GetText()
                    end
                end
            end
            -- Tab-separated trailing line renders as a right-aligned
            -- AddDoubleLine via Nx:SetTooltipText, matching the source
            -- tag shown on the patrol-path hover tooltip.
            if tooltip ~= "" then
                tooltip = tooltip .. "\n \t|cff60c0ffHandyNotes|r"
            end
            map:SetIconTip(handynote, tooltip)
            -- Attach (plugin, mapFile/mapID, coord) as user data so
            -- MapEngine:IconOnMouseDown can route clicks back to the
            -- source HandyNotes plugin's OnClick handler.
            map:SetIconUserData(handynote, {
                __handy   = true,
                plugin    = pluginName,
                mapFile   = mapFile or mapId,
                coord     = coord,
            })
            safecall(_G.HandyNotes.plugins[pluginName].OnLeave, tempIcon,
                     mapFile and mapFile or mapId, coord)
        end

        -- Patrol-path harvester. HandyNotes plugins that draw
        -- patrol routes (HandyNotes_BurningCrusade, NPCsClassic,
        -- etc.) build their own MapCanvasDataProvider that walks
        -- `ns.points[mapID]` looking for `point.routes` (an array of
        -- {coord1, coord2, ...} arrays). That same point table is
        -- the iterator STATE returned by GetNodes2 — pluginNodes[2].
        -- We can walk it ourselves and emit Map:AddLine segments to
        -- mirror the route lines on Carbonite's map.
        --
        -- coord packing: HandyNotes uses (x*10000)*10000 + y*10000,
        -- both in 0..1 normalised form. Decode with floor/mod, then
        -- multiply by 100 to feed Nx.Map:GetWorldPos (which wants
        -- zone-percentage 0..100).
        local pointTable = pluginNodes[2]
        if type(pointTable) == "table" then
            local MapMod = Carbonite:GetModule("Map", true)
            if MapMod then
                for pointCoord, point in pairs(pointTable) do
                    if type(point) == "table" and point.routes then
                        -- One colour per NPC so overlapping patrols
                        -- are distinguishable. The plugin can still
                        -- override per-route via route.color.
                        local pointColor = pickPathColor(point)

                        -- Tooltip text: scrape HandyNotes' OWN
                        -- tooltip for this point by firing the
                        -- plugin's OnEnter at the point's anchor
                        -- coord (same mechanism used for the icons
                        -- a few lines up). This gives us identical
                        -- text to what hovering the icon shows.
                        local scrapedTip
                        do
                            tempIcon:ClearAllPoints()
                            tempIcon:SetHeight(15)
                            tempIcon:SetWidth(15)
                            tempIcon:SetPoint("CENTER", tmpFrame, "TOPLEFT", 0, 0)
                            safecall(_G.HandyNotes.plugins[pluginName].OnEnter,
                                tempIcon, mapFile and mapFile or mapId, pointCoord)
                            local buf = ""
                            for i = 1, 10 do
                                local text = _G["GameTooltipTextLeft" .. i]
                                if text and text:IsShown() and text:GetText() then
                                    local R, G, B = text:GetTextColor()
                                    R = Nx.Util_dec2hex(R * 255)
                                    G = Nx.Util_dec2hex(G * 255)
                                    B = Nx.Util_dec2hex(B * 255)
                                    if #buf == 0 then
                                        buf = "|cFF" .. R .. G .. B .. text:GetText()
                                    else
                                        buf = buf .. "\n|cFF" .. R .. G .. B .. text:GetText()
                                    end
                                end
                            end
                            safecall(_G.HandyNotes.plugins[pluginName].OnLeave,
                                tempIcon, mapFile and mapFile or mapId, pointCoord)
                            scrapedTip = (buf ~= "") and buf or nil
                        end

                        -- Fallback chain if scraping returned empty:
                        -- per-route label → point label → "NPC <id>".
                        local pointTipBase = scrapedTip
                        if not pointTipBase then
                            if type(point.label) == "string" then
                                pointTipBase = point.label
                            elseif point.npc then
                                pointTipBase = "NPC " .. tostring(point.npc)
                            end
                        end

                        for _, route in ipairs(point.routes) do
                            local segColor = route.color or pointColor
                            local segThick = route.thickness or 2
                            local segTip   = (type(route.label) == "string" and route.label)
                                or pointTipBase
                            local function emit(wx1, wy1, wx2, wy2)
                                local pin = MapMod:AddLine("!HandyNotesPath", "!HandyNotesPath", {
                                    x = wx1, y = wy1, x2 = wx2, y2 = wy2,
                                    mapID     = mapId,
                                    color     = segColor,
                                    thickness = segThick,
                                })
                                if pin then
                                    pin.tip    = segTip
                                    pin.plugin = pluginName
                                    pin.npcId  = point.npc
                                end
                            end
                            -- route[1..N] are packed coords; walk
                            -- consecutive pairs to emit segments.
                            local lastX, lastY
                            for _, segCoord in ipairs(route) do
                                if type(segCoord) == "number" then
                                    local px = floor(segCoord / 10000) / 100
                                    local py = (segCoord % 10000) / 100
                                    if lastX then
                                        local wx1, wy1 = Nx.Map:GetWorldPos(mapId, lastX, lastY)
                                        local wx2, wy2 = Nx.Map:GetWorldPos(mapId, px,    py)
                                        if wx1 and wy1 and wx2 and wy2 then
                                            emit(wx1, wy1, wx2, wy2)
                                        end
                                    end
                                    lastX, lastY = px, py
                                end
                            end
                            -- Close the loop if requested.
                            if route.loop and lastX and #route > 1 then
                                local firstCoord = route[1]
                                local fx = floor(firstCoord / 10000) / 100
                                local fy = (firstCoord % 10000) / 100
                                local wx1, wy1 = Nx.Map:GetWorldPos(mapId, lastX, lastY)
                                local wx2, wy2 = Nx.Map:GetWorldPos(mapId, fx,    fy)
                                if wx1 and wy1 and wx2 and wy2 then
                                    emit(wx1, wy1, wx2, wy2)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
