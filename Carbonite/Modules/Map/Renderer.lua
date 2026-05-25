-- Carbonite | Modules / Map / Renderer
-- Per-frame walk that stamps icon-pool frames for every visible Pin
-- across every Layer. Replaces the old Nx.Map:UpdateIcons body which
-- walked Nx.Map.Data[<type>][n] for every iconType.
--
-- Three legacy draw modes preserved:
--   ZP  Zone point     — coords are zone-relative, ClipFrameZ stamps
--   WP  World point    — coords are world-space, ClipFrameByMapType
--                        stamps; this is the path 99% of icons use
--   ZR  Zone rect      — area highlight, ClipFrameTL stamps
--
-- Per-class metadata (drawMode, W, H, Tex, Alpha, etc.) lives on the
-- Pin class (see Pin.lua); per-instance overrides live on each pin.
-- Renderer hoists the class fields once per layer to keep the inner
-- pin loop tight.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Layer = Carbonite.Modules.Map.Layer

local Renderer = {}
Carbonite.Modules.Map.Renderer = Renderer

local strbyte, abs, max = strbyte, math.abs, math.max
local pairs, type = pairs, type
local GetTime = GetTime

-- Texture/atlas dispatch. Strings may be either `atlas:<name>` or a
-- regular texture path; numbers are FileDataIDs (HandyNotes plugins
-- commonly hand those out). Detection is inline because pin
-- instances are pooled — a cache on the pin would survive Release
-- and mis-route the next user of the same pin.
local function applyTexture(tex, fTex, color, c2rgb)
    local t = type(tex)
    if t == "string" then
        if tex:sub(1, 6) == "atlas:" then
            fTex:SetAtlas(tex:sub(7))
        else
            fTex:SetTexture(tex)
        end
        if color then fTex:SetVertexColor(c2rgb(color)) end
        return true
    elseif t == "number" then
        fTex:SetTexture(tex)            -- FileDataID
        if color then fTex:SetVertexColor(c2rgb(color)) end
        return true
    end
    return false
end

local function clipFn(map, kind)
    if kind == "z"    then return map.ClipFrameZ end
    if kind == "w"    then return map.ClipFrameW end
    if kind == "chop" then return map.ClipFrameWChop end
    if kind == "tl"   then return map.ClipFrameTL end
    return map.ClipFrameByMapType  -- "map" / default
end

local function computeDockMinimapRect(map, cls)
    if not cls.noDockMinimap then return nil end
    if not (map.MMOwn and map.MMZoomType == 0) then return nil end
    local mm = Nx.db.profile.MiniMap
    local mmSz = 140 * map.MMFScale
    local clipW, clipH = map.MapW, map.MapH
    local mmX = mm.DockRight and (clipW - mmSz) or 0
    local mmY = mm.DockBottom and (clipH - mmSz) or 0
    local x1 = mmX + (mm.DXO or 0)
    local y1 = mmY + (mm.DYO or 0)
    return x1, y1, x1 + mmSz, y1 + mmSz
end

local function isHiddenByDockMM(mmSX1, mmSY1, mmSX2, mmSY2,
                                iconX, iconY, offY, map, clipW, clipH, scaleDraw)
    if not mmSX1 then return false end
    local sx = (iconX - map.MapPosXDraw) * scaleDraw + clipW * .5
    local sy = ((iconY + offY) - map.MapPosYDraw) * scaleDraw + clipH * .5
    return sx >= mmSX1 and sx <= mmSX2 and sy >= mmSY1 and sy <= mmSY2
end

-- Decide per-class Enabled state for this frame (legacy parity:
-- guide vs non-guide gate, atScale gate, instance-map override).
local function computeEnabled(cls, layer, drawNonGuide, map)
    if not layer.visible then return false, nil end
    local enabled = drawNonGuide or strbyte(layer.name, 1) == 33   -- "!" prefix
    if cls.enabled == false then enabled = false end
    if cls.atScale and map.ScaleDraw < cls.atScale then enabled = false end
    local frameLvl = cls.frameLvl
    if (map:IsInstanceMap(map.UpdateMapID) or map:IsBattleGroundMap(map.UpdateMapID))
        and map.CurOpts.NXInstanceMaps then
        enabled = true
        frameLvl = 20
    end
    return enabled, frameLvl
end

-- ZP — zone-relative point. Coords are already in the map's local
-- space; ClipFrameZ does the screen transform.
local function renderZP(map, layer, cls, frameLvl)
    local c2rgb = Nx.Util_c2rgb
    local scale = map.IconScale
    local w = (cls.w or 16) * scale
    local h = (cls.h or 16) * scale
    local dungeonLevel = map.DungeonLevel
    local clsTex = cls.tex
    local clip = clipFn(map, cls.clipKind)

    for i = 1, #layer.pins do
        local pin = layer.pins[i]
        local pinLevel = pin.level
        if (not pinLevel and dungeonLevel == 0) or pinLevel == dungeonLevel then
            local f = map:GetIconStatic(frameLvl)
            if clip(map, f, pin.x, pin.y, w, h, 0) then
                f.NxTip = pin.tip
                f.NxPin = pin
                local fTex = f.texture
                if not applyTexture(pin.tex, fTex, pin.color, c2rgb) then
                    if clsTex then fTex:SetTexture(clsTex)
                    else fTex:SetColorTexture(c2rgb(pin.color)) end
                end
                if pin.tx1 then fTex:SetTexCoord(pin.tx1, pin.ty1, pin.tx2, pin.ty2) end
            end
        end
    end
end

-- WP — world point. The dominant path. Adds vis-cull, dock-minimap
-- exclusion, optional AlphaNear pulse, dungeon-level Y offset.
local function renderWP(map, layer, cls, frameLvl, wpScale, wpMin)
    -- c2rgba handles both "AARRGGBB" hex strings (legacy) and
    -- {r,g,b,a} tables (Quest area-span pins). c2rgb only handled
    -- strings — area pins with table colors rendered invisible
    -- because SetColorTexture received nils.
    local c2rgb = Nx.Util_c2rgba
    local scale = map.IconScale * (cls.scale or 1) * wpScale
    local w = max((cls.w or 16) * scale, wpMin)
    local h = max((cls.h or 16) * scale, wpMin)

    -- Size override for fullscreen Eastern Kingdoms / Kalimdor.
    if map.Win:IsSizeMax() then
        local zone = map:GetCurrentMapAreaID()
        if zone == 87 or zone == 125 then
            w, h = w * .5, h * .5
        end
    end

    local isInst = map:IsInstanceMap(map.UpdateMapID)
        or map:IsBattleGroundMap(map.UpdateMapID)
    if isInst then
        w = Nx.db.profile.Map.InstanceScale
        h = Nx.db.profile.Map.InstanceScale
    end

    local scaleDraw = map.ScaleDraw
    local clipW, clipH = map.MapW, map.MapH
    local margin = (w > h and w or h) / scaleDraw
    local mapPosX, mapPosY = map.MapPosXDraw, map.MapPosYDraw
    local visMinX = mapPosX - clipW * .5 / scaleDraw - margin
    local visMaxX = mapPosX + clipW * .5 / scaleDraw + margin
    local visMinY = mapPosY - clipH * .5 / scaleDraw - margin
    local visMaxY = mapPosY + clipH * .5 / scaleDraw + margin

    local mmSX1, mmSY1, mmSX2, mmSY2 = computeDockMinimapRect(map, cls)

    -- Dungeon-level Y offset only matters on instance maps when the
    -- per-level overlay is off; otherwise offY stays 0.
    local _h = 3 * (668 / 768)
    local curLvl = map:GetCurrentMapDungeonLevel()
    local zeroBased = curLvl > 0 and curLvl - 1 or 0
    local isInstance = map:IsInstanceMap(map.RMapId)
    local calcOff = isInstance and not map.CurOpts.NXInstanceMaps
    local offY = calcOff and (_h * zeroBased) or 0

    local dungeonLevel = map.DungeonLevel
    local clsTex = cls.tex
    local clsAlpha = cls.alpha
    local clip = clipFn(map, cls.clipKind)
    local clsAlphaNear = cls.alphaNear
    local aNear = clsAlphaNear and clsAlphaNear * (abs(GetTime() % .7 - .35) / .7 + .5)
    local frameLevelBase = map.Level + (frameLvl or 0)
    local plyrX, plyrY = map.PlyrX, map.PlyrY

    -- Classes that flag rawSize get their per-pin w/h passed
    -- straight to the clip function (no renderer scale applied)
    -- AND skip the center-anchored cull (TL-anchored rects extend
    -- one quadrant from pin.x/y, so the center-based visibility
    -- window doesn't apply). Used by Quest area-span pins where
    -- pin.w/h are world units already.
    local rawSize = cls.rawSize
    for i = 1, #layer.pins do
        local pin = layer.pins[i]
        local iconX, iconY = pin.x, pin.y
        if rawSize or (iconX >= visMinX and iconX <= visMaxX
            and iconY >= visMinY and iconY <= visMaxY) then
            local pinLevel = pin.level
            local levelOK = (not pinLevel and dungeonLevel == 0)
                or pinLevel == dungeonLevel
            local hidden = isHiddenByDockMM(mmSX1, mmSY1, mmSX2, mmSY2,
                                            iconX, iconY, offY,
                                            map, clipW, clipH, scaleDraw)
            if levelOK and not hidden then
                local pinTex = pin.tex
                local pinIsFrame = type(pinTex) == "table"
                local f = pinIsFrame and pinTex or map:GetIconStatic(frameLvl)
                local pw, ph = w, h
                if rawSize then
                    if pin.w then pw = pin.w end
                    if pin.h then ph = pin.h end
                elseif not isInst then
                    -- POI / regular WP pins: any per-pin w/h still
                    -- gets the renderer's icon-scale applied (the
                    -- legacy semantics that integration pins rely on).
                    --
                    -- Skipped on instance / BG maps: Pin.Acquire runs
                    -- Mixin.Apply, which copies the class's w/h onto
                    -- the pin instance — so pin.w is truthy for every
                    -- pin, not just ones that explicitly opted into a
                    -- per-instance size. On tight-scale instance maps
                    -- (Scale ≈ 0.039 → ScaleDraw 100+ → wpScale 10+)
                    -- this branch would immediately clobber the
                    -- InstanceScale override above with pin.w * scale,
                    -- producing icons the size of the entire map.
                    if pin.w then pw = max(pin.w * scale, wpMin) end
                    if pin.h then ph = max(pin.h * scale, wpMin) end
                end
                if clip(map, f, iconX, iconY + offY, pw, ph, 0) then
                    f.NxTip = pin.tip
                    -- pin.NXType / pin.NXData override the defaults so
                    -- pin-based icons can route through the legacy
                    -- IconOnEnter / IconOnMouseDown dispatcher's category
                    -- bands (e.g. Quest pins set NXType = 9000+i +
                    -- NXData = the cur quest, hitting the `t >= 9000`
                    -- branch that calls Nx.Quest:IconOnEnter).
                    f.NXType = pin.NXType or 3000
                    f.NXData = pin.NXData or pin
                    f.NxPin = pin
                    if pinIsFrame then
                        f:SetFrameLevel(frameLevelBase)
                    else
                        local fTex = f.texture
                        if not applyTexture(pinTex, fTex, pin.color, c2rgb) then
                            if clsTex then fTex:SetTexture(clsTex)
                            else fTex:SetColorTexture(c2rgb(pin.color)) end
                        end
                        if aNear then
                            local dist = (iconX - plyrX)^2 + (iconY - plyrY)^2
                            local a = (dist < 306) and aNear or clsAlpha   -- 80 yd^2 * ratio
                            fTex:SetVertexColor(1, 1, 1, a)
                        elseif clsAlpha then
                            fTex:SetVertexColor(1, 1, 1, clsAlpha)
                        end
                        if pin.tx1 then fTex:SetTexCoord(pin.tx1, pin.ty1, pin.tx2, pin.ty2) end
                    end
                    -- Per-pin custom stamping (vertex color overrides,
                    -- glow visibility, objective labels) without
                    -- bloating the renderer with class-specific code.
                    if pin.onStamp then pin.onStamp(pin, f) end
                end
            end
        end
    end
end

-- Project a world-space point to map-frame pixel coords. Returns
-- (sx, sy, inside) where inside is true when the point lands within
-- the visible map rectangle. Used by renderLINE to decide whether
-- to skip a segment entirely.
local function worldToFramePixel(map, wx, wy)
    local scale = map.ScaleDraw
    local clipW, clipH = map.MapW, map.MapH
    local sx = (wx - map.MapPosXDraw) * scale + clipW * .5
    local sy = (wy - map.MapPosYDraw) * scale + clipH * .5
    local inside = sx >= 0 and sx <= clipW and sy >= 0 and sy <= clipH
    return sx, sy, inside
end

-- Cached pin layer table for tooltip hit-test (filled by renderLINE,
-- read by the hover ticker installed in Renderer:Render).
local lastLineMap

-- Closest-point-on-segment squared distance, in screen pixels.
-- Used by the hover ticker to find which line the cursor is on.
local function pointToSegmentSq(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 < 0.0001 then
        local ex, ey = px - ax, py - ay
        return ex * ex + ey * ey
    end
    local t = ((px - ax) * dx + (py - ay) * dy) / len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local qx, qy = ax + t * dx, ay + t * dy
    local ex, ey = px - qx, py - qy
    return ex * ex + ey * ey
end

-- Render-time cache for path screen-coords. Each entry:
--   { sx1, sy1, sx2, sy2, pin }
-- Re-built every renderLINE pass so hover hit-tests use the same
-- transform as what's drawn.
local lineHits = {}

-- LINE — connect two world-space points with a line on the map
-- frame. Used for patrol paths, navigation polylines, etc. Each pin
-- carries (x, y) and (x2, y2) in world coords, optional color (hex
-- string or {r,g,b,a}), optional thickness.
local function renderLINE(map, layer, cls)
    local c2rgba = Nx.Util_c2rgba
    local hostFrm = map.Frm
    if not (hostFrm and map.GetLineStatic) then return end
    lastLineMap = map

    for i = 1, #layer.pins do
        local pin = layer.pins[i]
        local x1, y1 = pin.x,  pin.y
        local x2, y2 = pin.x2, pin.y2
        if x1 and y1 and x2 and y2 then
            local sx1, sy1, in1 = worldToFramePixel(map, x1, y1)
            local sx2, sy2, in2 = worldToFramePixel(map, x2, y2)
            -- Cheap cull: skip when both endpoints sit outside. Lines
            -- with one inside and one outside still draw (Blizzard's
            -- Line region clips at the host frame edge for us).
            if in1 or in2 then
                local line = map:GetLineStatic()
                line:SetThickness(pin.thickness or cls.thickness or 2)
                line:SetStartPoint("TOPLEFT", hostFrm, sx1, -sy1 - map.TitleH)
                line:SetEndPoint("TOPLEFT", hostFrm, sx2, -sy2 - map.TitleH)
                local tex = pin.tex or cls.tex
                if tex then
                    line:SetTexture(tex)
                elseif pin.color or cls.color then
                    line:SetColorTexture(c2rgba(pin.color or cls.color))
                else
                    line:SetColorTexture(1, 1, 1, 1)
                end
                line:Show()
                -- Append to the hit cache so the hover ticker can
                -- find which line is under the cursor.
                lineHits[#lineHits + 1] = {
                    sx1, sy1, sx2, sy2, pin,
                }
            end
        end
    end
end

-- ZR — zone rectangle. Two corners in zone space; both transform to
-- world via GetWorldPos. Used very rarely (area highlights).
local function renderZR(map, layer, cls, frameLvl)
    local c2rgba = Nx.Util_c2rgba
    local clsTex = cls.tex
    local clip = clipFn(map, cls.clipKind)
    local dungeonLevel = map.DungeonLevel

    for i = 1, #layer.pins do
        local pin = layer.pins[i]
        local pinLevel = pin.level
        if (not pinLevel and dungeonLevel == 0) or pinLevel == dungeonLevel then
            local f = map:GetIconStatic(frameLvl)
            f.NxTip = pin.tip
            f.NxPin = pin
            local x1, y1 = map:GetWorldPos(pin.mapID, pin.x,  pin.y)
            local x2, y2 = map:GetWorldPos(pin.mapID, pin.x2, pin.y2)
            if clip(map, f, x1, y1, x2 - x1, y2 - y1) then
                if clsTex then f.texture:SetTexture(clsTex)
                else f.texture:SetColorTexture(c2rgba(pin.color)) end
            end
        end
    end
end

function Renderer:Render(map, drawNonGuide)
    -- Legacy short-circuit: minimap-fullscreen hides every icon.
    if map:GetMap(1).LOpts.NXMMFull then return end

    local wpMin = Nx.db.profile.Map.IconScaleMin
    local wpScale = (wpMin >= 0) and (map.ScaleDraw * .08) or 1

    -- Reset the line hit-test cache. renderLINE will repopulate it
    -- for layers that get drawn this pass.
    for i = #lineHits, 1, -1 do lineHits[i] = nil end

    for _, layer in pairs(Layer.All()) do
        local cls = Pin.GetClass(layer.name)
        if cls then
            local enabled, frameLvl = computeEnabled(cls, layer, drawNonGuide, map)
            if enabled and #layer.pins > 0 then
                local mode = cls.drawMode or "WP"
                if mode == "WP" then
                    renderWP(map, layer, cls, frameLvl, wpScale, wpMin)
                elseif mode == "ZP" then
                    renderZP(map, layer, cls, frameLvl)
                elseif mode == "ZR" then
                    renderZR(map, layer, cls, frameLvl)
                elseif mode == "LINE" then
                    renderLINE(map, layer, cls)
                end
            end
        end
    end

    -- Legacy quirk preserved: zone 85 (Orgrimmar pre-Cata) seeded
    -- DungeonLevel=1 from inside the icon walk. Keep it for now.
    if map:GetCurrentMapAreaID() == 85 and map.DungeonLevel == 0 then
        map.DungeonLevel = 1
    end
end

-- ---------------------------------------------------------------
-- Hover ticker: shows GameTooltip with addon-aware text when the
-- cursor passes over a LINE-drawMode pin. Frame:CreateLine doesn't
-- receive mouse events, so we hit-test against the cached endpoint
-- screen-coords in `lineHits` on a 100ms tick.
-- ---------------------------------------------------------------

-- Best-effort resolution of an NPC display name. QuestieDB names
-- come from .name; HandyNotes plugins typically populate pin.tip
-- directly during their OnEnter render.
local function resolveNpcName(npcId)
    if not npcId then return nil end
    local QuestieDB = _G.QuestieLoader and _G.QuestieLoader:ImportModule("QuestieDB")
    if QuestieDB and QuestieDB.QueryNPC then
        local ok, name = pcall(QuestieDB.QueryNPC, npcId, "name")
        if ok and name then return name end
    end
    return nil
end

local hoverTicker
local function ensureHoverTicker()
    if hoverTicker then return end
    hoverTicker = CreateFrame("Frame")
    -- pathTooltipActive — true only while WE own GameTooltip. Lets
    -- us hide our own tooltip without clobbering an icon's tooltip
    -- that started showing in the same frame.
    local lastPin, lastT, pathTooltipActive = nil, 0, false
    hoverTicker:SetScript("OnUpdate", function(_, elapsed)
        -- Fast exit when there's no LINE work this pass and we
        -- aren't holding a tooltip open. The host frame ticks every
        -- frame regardless; this skips the throttle counter, the
        -- cursor math, and the host-frame visibility lookup that
        -- otherwise ran 60×/sec on maps with no patrol paths.
        if #lineHits == 0 and not pathTooltipActive and not lastPin then
            return
        end
        lastT = lastT + elapsed
        if lastT < 0.1 then return end
        lastT = 0

        local map = lastLineMap
        if not (map and map.Frm and map.Frm:IsShown()) then
            if pathTooltipActive then
                GameTooltip:Hide()
                pathTooltipActive = false
            end
            lastPin = nil
            return
        end

        -- Cursor → host-frame-local pixel coords.
        local fx, fy = GetCursorPosition()
        local scale = map.Frm:GetEffectiveScale()
        fx, fy = fx / scale, fy / scale
        local frmLeft = map.Frm:GetLeft() or 0
        local frmTop  = map.Frm:GetTop() or 0
        local lx = fx - frmLeft
        local ly = frmTop - fy

        -- Find the closest line within hit threshold (6px²).
        local bestPin, bestD = nil, 36
        for i = 1, #lineHits do
            local h = lineHits[i]
            local d = pointToSegmentSq(lx, ly, h[1], h[2] + map.TitleH, h[3], h[4] + map.TitleH)
            if d < bestD then
                bestD, bestPin = d, h[5]
            end
        end

        -- Yield to existing tooltip owners (icon hovers etc.) unless
        -- we already own the tooltip. Two cases:
        --   1. GameTooltip belongs to someone else (an external addon's
        --      pin OnEnter).
        --   2. Carbonite's own icon tooltip (Nx.TooltipText) is showing
        --      — that happens when the cursor is over a Carbonite map
        --      icon, including the icons our HandyNotes / Questie
        --      integrations harvested. Without this yield the path tip
        --      visually stacks on top of the icon tip for the same NPC.
        if bestPin then
            local owner = GameTooltip:GetOwner()
            if GameTooltip:IsShown() and owner and owner ~= map.Frm and not pathTooltipActive then
                lastPin = nil
                return
            end
            if Nx.TooltipText and Nx.TooltipText:IsShown() then
                if pathTooltipActive then
                    GameTooltip:Hide()
                    pathTooltipActive = false
                end
                lastPin = nil
                return
            end
        end

        if bestPin and bestPin ~= lastPin then
            lastPin = bestPin
            GameTooltip:SetOwner(map.Frm, "ANCHOR_CURSOR")
            local layerName = bestPin.kind
            local isQuestie = layerName == "!QuestiePath"
            local isHandy   = layerName == "!HandyNotesPath"
            local sourceTag = isQuestie and "|cff80ff80Questie|r"
                or isHandy and "|cff60c0ffHandyNotes|r"
                or "Patrol"

            -- Both HandyNotes and Questie integrations pre-scrape /
            -- build the source addon's own tooltip into pin.tip:
            -- multi-line, with |cFFRRGGBB color codes, and a trailing
            -- " \t<sourceTag>" line that should render as a
            -- right-aligned AddDoubleLine (matches how Nx.TooltipText
            -- handles the same icon tip for hovered icons).
            local tip = bestPin.tip
            if (isHandy or isQuestie) and tip and tip:find("\n") then
                local sawTabbedTag = false
                for line in tip:gmatch("[^\n]+") do
                    local lhs, rhs = line:match("^(.-)\t(.+)$")
                    if lhs and rhs then
                        sawTabbedTag = true
                        GameTooltip:AddDoubleLine(lhs, rhs, 1, 1, 1, 0.7, 0.7, 0.7)
                    else
                        GameTooltip:AddLine(line, 1, 1, 1, true)
                    end
                end
                if not sawTabbedTag then
                    GameTooltip:AddDoubleLine(" ", sourceTag, 1, 1, 1, 0.7, 0.7, 0.7)
                end
            else
                local name = tip
                if isQuestie and bestPin.npcId and (not name or name == "") then
                    local viaDB = resolveNpcName(bestPin.npcId)
                    if viaDB then name = viaDB end
                end
                if name then
                    GameTooltip:AddDoubleLine(name, sourceTag, 1, 1, 1, 0.7, 0.7, 0.7)
                else
                    GameTooltip:AddLine(sourceTag .. " patrol")
                end
                if bestPin.npcId then
                    GameTooltip:AddLine("NPC #" .. tostring(bestPin.npcId), 0.6, 0.6, 0.6)
                end
            end
            GameTooltip:Show()
            pathTooltipActive = true
        elseif not bestPin and lastPin then
            if pathTooltipActive then
                GameTooltip:Hide()
                pathTooltipActive = false
            end
            lastPin = nil
        end
    end)
end

-- Hook the ticker once Renderer is ready.
ensureHoverTicker()
