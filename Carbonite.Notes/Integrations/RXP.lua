-- Carbonite.Notes | Integrations / RXPGuides
-- Mirrors RXPGuides' active-waypoint pins onto the Carbonite map.
-- RXP registers its world-map pins through HereBeDragons-Pins-2.0
-- using its internal addon table (exposed at _G.RXP for debugging)
-- as the registry "ref". We read HBDPins.worldmapPinRegistry[_G.RXP]
-- each frame, copy matching uiMapID entries onto our own !RXP layer,
-- and gate the rebuild behind a content hash for the dirty-check.
--
-- The pin's `activeObject` is set by RXP's frame.render() and carries
-- the underlying guide step + element, which gives us a tooltip with
-- step number / label without having to walk RXP's guide data
-- ourselves.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

Nx.Notes.RXPCache     = Nx.Notes.RXPCache or {}
Nx.Notes.RXPLastMapId = nil
Nx.Notes.PrevRXPPins  = 0

-- The waypoint icon. Re-uses RXP's own logo so the pin is visually
-- consistent with the addon's branding; HBDPins texture-style icons
-- aren't exposed for individual pin frames so this is the most
-- distinctive non-frame-cloning option.
local RXP_TEX = "Interface\\AddOns\\RXPGuides\\Textures\\rxp_logo-128"

---
-- Update RXPGuides waypoint icons on the map.
-- @param mapId  Current map ID
--
function Nx.Notes:RXP(mapId)
    if not Nx.fdb.profile.Notes.RXP then return end
    local rxp = _G.RXP
    if not rxp then return end
    local HBDPins = LibStub("HereBeDragons-Pins-2.0", true)
    if not HBDPins then return end

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

    local icons = {}
    local hash  = 0
    for icon in pairs(registry) do
        local data = pinData[icon]
        if data and data.uiMapID == mapId then
            icons[#icons + 1] = { x = data.x, y = data.y, frame = icon }
            hash = hash + (data.x or 0) * 10000 + (data.y or 0) * 100
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
    map:InitIconType("!RXP", "WP", "", size, size)
    map:SetIconTypeChop("!RXP", true)
    map:SetIconTypeNoDockMinimap("!RXP", true)
    map:SetIconTypeLevel("!RXP", 20)

    for _, ic in ipairs(icons) do
        -- HBDPins stores x / y as 0..1 fractions of the uiMapID; Nx
        -- expects 0..100 zone-percent before converting to world.
        local wx, wy = Nx.Map:GetWorldPos(mapId, ic.x * 100, ic.y * 100)
        local pin    = map:AddIconPt("!RXP", wx, wy, nil, "FFFFFFFF", RXP_TEX)

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
                or "?"
            lines[#lines + 1] = "Step " .. tostring(label)
            if step.text then
                lines[#lines + 1] = "|cffcccccc" .. tostring(step.text) .. "|r"
            end
        end
        map:SetIconTip(pin, table.concat(lines, "\n"))
    end
end
