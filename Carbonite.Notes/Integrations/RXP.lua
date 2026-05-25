-- Carbonite.Notes | Integrations / RXPGuides
-- Mirrors RXPGuides' active-waypoint pins onto the Carbonite map.
-- RXP registers its world-map pins through HereBeDragons-Pins-2.0
-- using its internal addon table (exposed at _G.RXP for debugging)
-- as the registry "ref". We read HBDPins.worldmapPinRegistry[_G.RXP]
-- each frame, copy entries that project onto the current Carbonite
-- map onto our own !RXP layer, and gate the rebuild behind a content
-- hash for the dirty-check.
--
-- Each RXP pin frame carries the formatted step label on
-- `frame.text:GetText()` (set by RXP's pool render() method).
-- Re-using that string directly gives us identical labelling to
-- what shows on Blizzard's world map — step numbers, |T...|t inline
-- icons, "+" stack suffix, etc. We render the label via NxLabel on
-- the Carbonite icon frame; an onStamp callback wired onto the
-- !RXP Pin class copies pin.label onto frame.NxLabel each frame.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

Nx.Notes.RXPCache     = Nx.Notes.RXPCache or {}
Nx.Notes.RXPLastMapId = nil
Nx.Notes.PrevRXPPins  = 0

local Carbonite = _G.Carbonite
local Pin       = Carbonite and Carbonite.Modules
                  and Carbonite.Modules.Map
                  and Carbonite.Modules.Map.Pin

-- Show RXP's step text on the Carbonite icon. The icon pool's
-- NxLabel font-string (created in GetIconStatic) is hidden by
-- default; this stamp callback shows / hides it based on the per-pin
-- label string. Runs every frame, but cheap.
local function stampRXPFrame(pin, frame)
    local lbl = frame.NxLabel
    if not lbl then
        -- Pre-allocated pool frames skip NxLabel creation; lazy-make
        -- one ourselves. OVERLAY layer puts it above the icon
        -- texture; explicit outlined font + larger size matches what
        -- RXP itself uses on Blizzard's map so the step number is
        -- legible against the logo backdrop.
        lbl = frame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetShadowColor(0, 0, 0, 1)
        lbl:SetShadowOffset(1, -1)
        frame.NxLabel = lbl
    end
    if pin.label and pin.label ~= "" then
        lbl:SetText(pin.label)
        lbl:SetTextColor(pin.labelR or 1, pin.labelG or 1, pin.labelB or 1, 1)
        lbl:Show()
    else
        lbl:Hide()
    end
end

---
-- Update RXPGuides waypoint icons on the map.
-- @param mapId  Current map ID
--
function Nx.Notes:RXP(mapId)
    if not Nx.fdb.profile.Notes.RXP then return end
    local rxp = _G.RXP
    if not rxp then return end
    local HBDPins = LibStub("HereBeDragons-Pins-2.0", true)
    local HBD     = LibStub("HereBeDragons-2.0", true)
    if not HBDPins or not HBD then return end

    local registry = HBDPins.worldmapPinRegistry
        and HBDPins.worldmapPinRegistry[rxp]
    local pinData  = HBDPins.worldmapPins
    local map      = Nx.Map:GetMap(1)

    -- Empty / disabled case: clear if we had pins last frame.
    if not registry or not pinData then
        if map and (self.PrevRXPPins or 0) > 0 then
            map:ClearIconType("!RXP")
            self.PrevRXPPins = 0
        end
        return
    end

    -- HBDPins.worldmapPins stores HBD world coords (data.x / data.y
    -- are continent-relative, NOT 0..1 zone fractions). Convert each
    -- world coord back to a zone fraction for the current Carbonite
    -- map; HBD picks the correct sub-map automatically, so a pin
    -- registered for Vale of Eternal Blossoms with
    -- HBD_PINS_WORLDMAP_SHOW_CONTINENT projects onto either Vale or
    -- Pandaria continent depending on which map Carbonite is showing.
    --
    -- Hash includes the pin's step label string so a label change on
    -- the same coord (RXP advances the active step) busts the cache.
    -- Resolve a step label string for the RXP pin: prefer the live
    -- rendered text (set by RXP's pool render() — includes inline
    -- |T..|t icons); fall back to the step index / activeObject so
    -- we still print something useful when the frame's text hasn't
    -- been populated yet (WorldMapFrame never opened this session).
    --
    -- Strip the trailing "+" RXP appends to denote stacked pins
    -- (`label .. "+"` in MapPinPool.creationFunc). The RXP logo
    -- already identifies this as an RXP pin, and the cluster of
    -- adjacent steps speaks to the stack — the suffix is just noise
    -- on the smaller Carbonite icon.
    local function pinLabel(icon)
        local t = icon.text and icon.text.GetText and icon.text:GetText()
        if t and t ~= "" then
            return (t:gsub("%+$", ""))
        end
        local active  = icon.activeObject
        local element = active and active.elements and active.elements[1]
        local step    = element and (element.step or active.step)
        if step then
            return tostring((element and element.label) or step.index or "?")
        end
        return "*"
    end

    local icons = {}
    local hash  = 0
    for icon in pairs(registry) do
        local data = pinData[icon]
        if data and data.x and data.y then
            local fx, fy = HBD:GetZoneCoordinatesFromWorld(data.x, data.y, mapId)
            if fx and fy and fx >= 0 and fx <= 1 and fy >= 0 and fy <= 1 then
                local label = pinLabel(icon)
                icons[#icons + 1] = { x = fx, y = fy, frame = icon, label = label }
                hash = hash
                    + fx * 10000
                    + fy * 100
                    + (#label > 0 and (string.byte(label, 1) or 0) * 1e7 or 0)
            end
        end
    end

    local cacheKey = mapId .. "_RXP"
    if self.RXPCache[cacheKey] == hash
        and self.RXPLastMapId == mapId
        and self.PrevRXPPins == #icons then
        return
    end

    if not map then return end
    map:ClearIconType("!RXP")
    self.RXPCache[cacheKey] = hash
    self.RXPLastMapId       = mapId
    self.PrevRXPPins        = #icons

    local size = Nx.fdb.profile.Notes.RXPSize or 24
    -- Pass nil texture so the renderer falls through to
    -- SetColorTexture(pin.color) — a dark filled square that the
    -- step-number label can sit on top of (mimics RXP's circular
    -- backdrop + numeric label). chop clipping matches the other
    -- integration layers.
    map:InitIconType("!RXP", "WP", nil, size, size)
    map:SetIconTypeChop("!RXP", true)
    map:SetIconTypeNoDockMinimap("!RXP", true)
    map:SetIconTypeLevel("!RXP", 20)

    -- Player class color for the step-number text. Mirrors how RXP
    -- paints the label on Blizzard's map (paladin pink, druid orange,
    -- etc.), so the Carbonite version stays visually consistent.
    local _, classToken = UnitClass("player")
    local cc = _G.RAID_CLASS_COLORS
                and classToken
                and _G.RAID_CLASS_COLORS[classToken]
    local cr, cg, cb = (cc and cc.r) or 1, (cc and cc.g) or 1, (cc and cc.b) or 1

    for _, ic in ipairs(icons) do
        -- HBDPins stores x / y as 0..1 fractions; Nx expects 0..100
        -- zone-percent before converting to world coords.
        local wx, wy = Nx.Map:GetWorldPos(mapId, ic.x * 100, ic.y * 100)
        -- Text-only pin: fully transparent backdrop colour (alpha 0)
        -- so the step label floats over the map. The class-coloured,
        -- outlined text is the visual identifier; the icon frame
        -- keeps a 24x24 mouse-hit area for the tooltip.
        local pin = map:AddIconPt("!RXP", wx, wy, nil, "00000000", nil)
        pin.label   = ic.label
        pin.labelR  = cr
        pin.labelG  = cg
        pin.labelB  = cb
        -- Set onStamp per-pin instead of via Pin.SetClassField:
        -- pooled pins keep their original Mixin-applied class fields
        -- (Pin.Acquire only re-Mixin's freshly created pins, not
        -- recycled ones), so a class-level field set after pin
        -- creation wouldn't reach the pool. Per-pin assignment
        -- bypasses that — the renderer checks `if pin.onStamp` not
        -- `if cls.onStamp`.
        pin.onStamp = stampRXPFrame

        -- Best-effort tooltip from the live activeObject set by RXP's
        -- frame.render(). Falls back to a generic source tag if the
        -- step / element structure has changed shape.
        local active  = ic.frame and ic.frame.activeObject
        local element = active and active.elements and active.elements[1]
        local step    = element and (element.step or active.step)
        local lines   = { "|cff80c0ffRXPGuides|r" }
        if step then
            local label = (element and element.label)
                or step.index
                or ic.label
                or "?"
            lines[#lines + 1] = "Step " .. tostring(label)
            if step.text then
                lines[#lines + 1] = "|cffcccccc" .. tostring(step.text) .. "|r"
            end
        elseif ic.label and ic.label ~= "" then
            lines[#lines + 1] = "Step " .. ic.label
        end
        map:SetIconTip(pin, table.concat(lines, "\n"))
    end
end
