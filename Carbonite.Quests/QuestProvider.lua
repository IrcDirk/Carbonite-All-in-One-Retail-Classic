-- Carbonite.Quests | QuestProvider
-- The Quest module's icon producer was historically the only major
-- icon source still using the legacy `map:GetIconStatic` pool-stamp
-- pipeline. That meant the whole 600-line UpdateIcons had to run
-- every frame to keep the pool slots filled — no caching, no early
-- exit, no way for a third party to plug in alongside.
--
-- This file defines a MapProvider for the Quest module so its icons
-- live on a persistent Pin/Layer like every other producer. MapIcons.lua
-- consumes it and gates the per-frame work behind a content-hash
-- dirty-check.
--
-- Two pin kinds:
--   POI        - quest start / end / objective POI icons. WP draw mode.
--                Uses an `onStamp` callback to apply per-icon vertex
--                colors, super-tracked glow visibility, and the
--                objective-number label (NxLabel) that the legacy
--                code wrote directly to the pool frame.
--   POI_Inv    - same as POI but no glow / label. Used for the
--                completed-quest "complete" marker.
--
-- Quest watch-area rectangles (drawn with ClipFrameTL + per-instance
-- width/height + hover state) stay on the legacy GetIconStatic path;
-- they're cheap, low-volume, and the renderer's WP mode doesn't yet
-- support per-pin geometry.

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

local Carbonite = _G.Carbonite

-- Lazy initialisation: the MapProvider module loads from
-- Carbonite/Modules/Map/MapProvider.lua via Modules.xml during the
-- main addon's loader. Carbonite.Quests is a sibling addon and may
-- load before MapProvider is available, so defer creation until the
-- first read.
local _provider
local function provider()
    if _provider then return _provider end
    if not (Carbonite and Carbonite.Map and Carbonite.Map.CreateProvider) then
        return nil
    end
    local p = Carbonite.Map:CreateProvider("Carbonite.Quests")

    -- Stamping callback shared by both kinds. Quest icons want full
    -- per-pin control of vertex color, glow, and objective label —
    -- legacy code set these directly on the pool frame after
    -- GetIconStatic. With pin/layer we run the same logic after the
    -- renderer's standard texture stamping via the onStamp hook.
    local function stampQuestFrame(pin, frame)
        local fTex = frame.texture
        if pin.vertexColor then
            local c = pin.vertexColor
            fTex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        else
            fTex:SetVertexColor(1, 1, 1, 1)
        end
        local glow = frame.NxGlow
        if glow then
            if pin.showGlow then glow:Show() else glow:Hide() end
        end
        local lbl = frame.NxLabel
        if lbl then
            if pin.label and pin.label ~= "" then
                lbl:SetText(pin.label)
                lbl:Show()
            else
                lbl:Hide()
            end
        end
    end

    -- POI size picked to roughly match the legacy navscale (16)
    -- after the renderer's icon-scale multiplier kicks in. Going
    -- much higher (32) made them dominate the map next to Questie's
    -- own available-quest pins; sticking close to legacy keeps the
    -- map readable.
    p:DefinePin("POI", {
        drawMode = "WP",
        w        = 20,
        h        = 20,
        onStamp  = stampQuestFrame,
    })

    -- Distance-arrow pins stay smaller — they're directional
    -- pointers along the edge of an objective area, drawn alongside
    -- the main POI; matching POI size would crowd the map.
    p:DefinePin("Arrow", {
        drawMode = "WP",
        w        = 14,
        h        = 14,
        onStamp  = stampQuestFrame,
    })

    -- Quest-objective area spans (the colored rectangles laid over
    -- the search area). These differ from POI pins in three ways:
    --   * top-left anchored (clipKind = "tl") rather than centered,
    --   * the renderer reads pin.w / pin.h per-pin (the rect's
    --     extent in world units),
    --   * rawSize tells the renderer to pass pin.w / pin.h raw to
    --     the clip function and to skip the center-anchored cull
    --     (the rect's extent isn't bounded by class defaults).
    p:DefinePin("Area", {
        drawMode = "WP",
        clipKind = "tl",
        rawSize  = true,
        onStamp  = stampQuestFrame,
    })

    _provider = p
    return p
end

-- Public accessors used by MapIcons.lua.
function Nx.Quest:GetMapProvider()
    return provider()
end

-- Convenience wrapper so call sites can read like the legacy
-- "stamp this icon" code without sprouting nil-checks.
local function IsQuestPinRelevant(opts)
    local mapID = opts and opts.mapID
    local map = Nx.Map
    if map and map.IsMapRelevantToInstance then
        return map:IsMapRelevantToInstance(
            mapID,
            map.UpdateMapID or map.RMapId or map.MapId
        )
    end
    return true
end

function Nx.Quest:AddPOI(wx, wy, opts)
    if not IsQuestPinRelevant(opts) then return nil end
    local p = provider()
    if not p then return nil end
    return p:Add("POI", wx, wy, opts)
end

function Nx.Quest:AddArea(wx, wy, opts)
    if not IsQuestPinRelevant(opts) then return nil end
    local p = provider()
    if not p then return nil end
    return p:Add("Area", wx, wy, opts)
end

function Nx.Quest:AddArrow(wx, wy, opts)
    if not IsQuestPinRelevant(opts) then return nil end
    local p = provider()
    if not p then return nil end
    return p:Add("Arrow", wx, wy, opts)
end

function Nx.Quest:ClearProviderPins()
    local p = provider()
    if p then p:Clear() end
end
