-- Carbonite | Modules / HUD / HUDArrow
-- Documented surface around the directional arrow in NxHUD. The
-- legacy code's heart is Nx.HUD:Update which rotates a quad-mapped
-- arrow texture toward the active target. This class is the public
-- accessor for the dynamic state the arrow renders.
--
-- Public API:
--   HUDArrow:GetDirectionDegrees()    -> 0..360, relative to player
--   HUDArrow:GetDistanceYards()
--   HUDArrow:GetTargetName()
--   HUDArrow:GetETA()
--   HUDArrow:SetTexture(styleKey)
--   HUDArrow:Show()  / Hide() / IsShown()
--
-- The style key matches the legacy Nx.HUD.TexNames keys: "", "Chip",
-- "Gloss", "Glow", "Neon". An invalid key falls back to "".

local Carbonite = _G.Carbonite

local HUDArrow = {}
Carbonite.Modules.HUD = Carbonite.Modules.HUD or {}
Carbonite.Modules.HUD.Arrow = HUDArrow

local function hud() return _G.Nx and _G.Nx.HUD end
local function map1()
    local M = _G.Nx and _G.Nx.Map
    return M and M.Maps and M.Maps[1]
end

function HUDArrow:GetDirectionDegrees()
    local m = map1()
    if not m then return 0 end
    local dir = (m.TrackDir or 0) - (m.PlyrDir or 0)
    dir = dir % 360
    return dir
end

function HUDArrow:GetDistanceYards()
    local m = map1()
    return m and m.TrackDistYd or 0
end

function HUDArrow:GetTargetName()
    local m = map1()
    return m and m.TrackName or ""
end

function HUDArrow:GetETA()
    local m = map1()
    return m and m.TrackETA or false
end

function HUDArrow:SetTexture(styleKey)
    local h = hud()
    if not h or not h.TexNames then return end
    -- Map the human name to a TexNames entry.
    for _, key in ipairs(h.TexNames) do
        if key == styleKey then
            local Nx = _G.Nx
            if Nx and Nx.db and Nx.db.profile and Nx.db.profile.Track then
                Nx.db.profile.Track.AGfx = styleKey
            end
            if h.UpdateOptions then h:UpdateOptions() end
            return
        end
    end
end

function HUDArrow:Show()
    local h = hud()
    if h and h.Open then h:Open() end
end

function HUDArrow:Hide()
    local h = hud()
    if h and h.Win and h.Win.Show then h.Win:Show(false) end
end

function HUDArrow:IsShown()
    local h = hud()
    return h and h.Win and h.Win.IsShown and h.Win:IsShown() or false
end
