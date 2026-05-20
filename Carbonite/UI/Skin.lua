-- Carbonite | UI / Skin
-- Centralized theming: every Carbonite window/button/frame reads its
-- visual style from here rather than hardcoding colors / textures.
-- Old code had a dozen places computing the same dim-blue tint.

local Carbonite = _G.Carbonite
local Skin = {}
Carbonite.UI.Skin = Skin

Skin.themes = {
    classic = {
        backdrop = {
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 16,
            edgeSize = 16,
            insets   = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        textTitle  = { r = 0.75, g = 0.75, b = 1.0 },
        textBody   = { r = 1.0,  g = 1.0,  b = 1.0 },
        textWarn   = { r = 1.0,  g = 0.82, b = 0.0 },
        textError  = { r = 1.0,  g = 0.25, b = 0.25 },
        stripeBg   = { 0, 0, 0, 0.5 },
        titleBg    = { 0, 0, 0, 0.6 },
    },
}

Skin.active = Skin.themes.classic

function Skin:Apply(frame)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(self.active.backdrop)
end

function Skin:GetColor(key)
    return self.active[key]
end

function Skin:SetTheme(name)
    if self.themes[name] then self.active = self.themes[name] end
end
