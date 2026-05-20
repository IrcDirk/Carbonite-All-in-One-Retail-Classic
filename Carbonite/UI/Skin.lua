-- Carbonite | UI / Skin
-- Centralized theming: every Carbonite window/button/frame reads its
-- visual style from here rather than hardcoding colors / textures.
-- Replaces Nx.Skin's hardcoded `Nx.Skins[name]` table with a class
-- that also exposes resolved colors and a `Set` / `Update` lifecycle.
--
-- Two ways to use:
--   - Modern: Skin:GetActive() returns the resolved theme; widgets
--     read backdrop/color fields directly.
--   - Legacy: Nx.Skin:* aliases below keep old call sites working.

local Carbonite = _G.Carbonite
local Skin = {}
Carbonite.UI.Skin = Skin

-- Shared backdrop default. Themes copy and override fields they care
-- about. Kept as a function so theme registration order doesn't matter.
local function backdrop(edgeFile, tile, tileSize, edgeSize, insets)
    return {
        bgFile   = "Interface\\Buttons\\White8x8",
        edgeFile = edgeFile,
        tile     = tile ~= false,
        tileSize = tileSize or 9,
        edgeSize = edgeSize or 9,
        insets   = insets or { left = 1, right = 1, top = 1, bottom = 1 },
    }
end

Skin.themes = {
    ["Blackout"] = {
        backdrop = backdrop("Interface\\Addons\\Carbonite\\Gfx\\Skin\\EdgeSquare", true, 8, 8, { left=0, right=0, top=0, bottom=0 }),
        borderColor = "0|0|0|1",
        bgColor     = "0|0|0|1",
    },
    ["Blackout Blues"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = ".8|.8|1|1",
        bgColor     = "0|0|0|1",
    },
    ["Dialog Blue"] = {
        backdrop = backdrop("Interface\\DialogFrame\\UI-DialogBox-Border", true, 16, 16, { left=2, right=2, top=2, bottom=2 }),
        borderColor = ".8|.8|1|1",
        bgColor     = ".125|.125|.125|.88",
    },
    ["Dialog Gold"] = {
        backdrop = backdrop("Interface\\DialogFrame\\UI-DialogBox-Gold-Border", true, 16, 16, { left=2, right=2, top=2, bottom=2 }),
        borderColor = "1|1|1|1",
        bgColor     = ".15|.15|0|.88",
    },
    ["Simple Blue"] = {
        backdrop = backdrop("Interface\\Addons\\Carbonite\\Gfx\\Skin\\EdgeSquare", true, 8, 8, { left=0, right=0, top=0, bottom=0 }),
        borderColor = "0.7|0.7|1|0.8",
        bgColor     = ".125|.125|.125|.88",
    },
    ["Stone"] = {
        backdrop = backdrop("Interface\\Glues\\Common\\TextPanel-Border", nil, 256, 16, { left=3, right=2, top=2, bottom=2 }),
        borderColor = "1|1|1|1",
        bgColor     = "0.06|0.06|0.06|.9",
    },
    ["Tool Blue"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = ".8|1|1|.8",
        bgColor     = ".125|.125|.125|.88",
    },
    -- Modern themes use Blizzard's tooltip border (a clean thin edge
    -- that stays sharp at high UI scales) and a couple of live-state
    -- variants that resolve their border color from the player's
    -- class / faction at apply time.
    ["Modern Dark"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = "0.30|0.36|0.46|0.95",
        bgColor     = "0.06|0.07|0.10|0.92",
    },
    ["Modern Light"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = "0.50|0.55|0.65|0.95",
        bgColor     = "0.88|0.88|0.92|0.92",
    },
    ["Glass"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = "1|1|1|0.40",
        bgColor     = "0|0|0|0.40",
    },
    ["Class Color"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = "0.40|0.55|0.95|0.85",
        bgColor     = "0.06|0.07|0.10|0.92",
        resolveBorder = function()
            local _, class = UnitClass("player")
            local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)
            local c = class and cc and cc[class]
            if c then return ("%f|%f|%f|0.90"):format(c.r, c.g, c.b) end
        end,
    },
    ["Faction"] = {
        backdrop = backdrop("Interface\\Tooltips\\UI-Tooltip-Border"),
        borderColor = "0.40|0.55|0.95|0.85",
        bgColor     = "0.06|0.07|0.10|0.92",
        resolveBorder = function()
            local f = UnitFactionGroup("player")
            if f == "Alliance" then return "0.18|0.45|0.95|0.90" end
            if f == "Horde"    then return "0.85|0.20|0.20|0.90" end
        end,
    },
}

Skin.activeName = "Modern Dark"

-- Parse a "r|g|b|a" string the legacy save format uses.
local function parseColor(s)
    if type(s) ~= "string" then return 1, 1, 1, 1 end
    local r, g, b, a = s:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
    return tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1
end

function Skin:GetActive()
    return self.themes[self.activeName] or self.themes["Modern Dark"]
end

function Skin:GetBackdrop()
    return self:GetActive().backdrop
end

function Skin:GetBorderColor()
    local t = self:GetActive()
    if type(t.resolveBorder) == "function" then
        local ok, val = pcall(t.resolveBorder)
        if ok and val then return { parseColor(val) } end
    end
    return { parseColor(t.borderColor) }
end

function Skin:GetBackgroundColor()
    return { parseColor(self:GetActive().bgColor) }
end

function Skin:GetFixedBackgroundColor()
    return { parseColor(".5|.5|.5|.5") }
end

-- Apply current theme's backdrop to a frame in one call.
function Skin:Apply(frame)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(self:GetActive().backdrop)
    local r, g, b, a = unpack(self:GetBorderColor())
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(r, g, b, a) end
    local br, bg, bb, ba = unpack(self:GetBackgroundColor())
    if frame.SetBackdropColor then frame:SetBackdropColor(br, bg, bb, ba) end
end

function Skin:Set(name, init)
    if not self.themes[name] then name = "Modern Dark" end
    self.activeName = name
    if _G.Nx and _G.Nx.db and _G.Nx.db.profile and _G.Nx.db.profile.Skin then
        _G.Nx.db.profile.Skin.Name = name
        if not init then
            local t = self.themes[name]
            _G.Nx.db.profile.Skin.WinBdColor      = t.borderColor
            _G.Nx.db.profile.Skin.WinFixedBgColor = ".5|.5|.5|.5"
            _G.Nx.db.profile.Skin.WinSizedBgColor = t.bgColor
        end
    end
    self:Update()
end

function Skin:Update()
    Carbonite.Core.EventBus:Fire("SKIN_UPDATED", self.activeName)
    -- Push to legacy Window/Menu resets so existing widgets restyle.
    if _G.Nx and _G.Nx.Window and _G.Nx.Window.ResetBackdrops then _G.Nx.Window:ResetBackdrops() end
    if _G.Nx and _G.Nx.Menu   and _G.Nx.Menu.ResetSkins      then _G.Nx.Menu:ResetSkins()      end
end

function Skin:ListThemes()
    local out = {}
    for k in pairs(self.themes) do out[#out + 1] = k end
    table.sort(out)
    return out
end

-- Legacy aliases. Installed after the addon is loaded so that any
-- legacy code that already grabbed `Nx.Skin` gets the new methods.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    if not _G.Nx then return end
    _G.Nx.Skin = _G.Nx.Skin or {}
    local target = _G.Nx.Skin
    target.Init                = function() if _G.Nx.db then Skin:Set(_G.Nx.db.profile.Skin.Name, true) end end
    target.Set                 = function(_, name, init) Skin:Set(name, init) end
    target.Update              = function() Skin:Update() end
    target.GetBackdrop         = function() return Skin:GetBackdrop() end
    target.GetBorderCol        = function() return Skin:GetBorderColor() end
    target.GetBGCol            = function() return Skin:GetBackgroundColor() end
    target.GetFixedSizeBGCol   = function() return Skin:GetFixedBackgroundColor() end
    target.GetNineSliceLayout  = function() return Skin:GetActive().nineSlice end
    target.GetTex              = function(_, name) return "Interface\\Addons\\Carbonite\\Gfx\\Skin\\" .. (name or "") end
    -- The legacy code reads Nx.Skins (the full table) and self.Data.
    _G.Nx.Skins = Skin.themes
    target.Data = Skin:GetActive()
    target.Path = "Interface\\Addons\\Carbonite\\Gfx\\Skin\\"
end)
