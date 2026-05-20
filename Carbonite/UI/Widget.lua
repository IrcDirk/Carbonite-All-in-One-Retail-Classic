-- Carbonite | UI / Widget
-- Base "create a Carbonite-skinned frame" factory. Replaces the old
-- Nx.Window:Create / Nx.Button:Create / Nx.List:Create scattered
-- factory methods with a single entry point that returns a Blizzard
-- frame with Carbonite mixins attached.
--
-- Specific widget classes (Window, Button, etc.) live as files under
-- this directory and add their own behavior on top of this base.

local Carbonite = _G.Carbonite
local Mixin = Carbonite.UI.Mixin

local Widget = {}
Carbonite.UI.Widget = Widget

-- Common methods every Carbonite widget gets. Composed onto each
-- created frame so derived widgets don't need to repeat them.
local Base = {}

function Base:SetCarbBackdrop(bgFile, edgeFile, tile, tileSize, edgeSize, insets)
    -- Wraps SetBackdrop with sensible defaults. On 9.x+ a Frame needs the
    -- BackdropTemplate to expose SetBackdrop; CreateCarboniteFrame handles
    -- that template selection.
    if not self.SetBackdrop then return end
    self:SetBackdrop({
        bgFile   = bgFile or "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = edgeFile or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = tile ~= false,
        tileSize = tileSize or 16,
        edgeSize = edgeSize or 16,
        insets   = insets or { left = 4, right = 4, top = 4, bottom = 4 },
    })
end

function Base:SetCarbStripe(color)
    local tex = self.carbStripe
    if not tex then
        tex = self:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        self.carbStripe = tex
    end
    color = color or { 0, 0, 0, 0.5 }
    tex:SetColorTexture(color[1], color[2], color[3], color[4] or 0.5)
end

-- Frame creator. Selects the BackdropTemplate when present so
-- :SetBackdrop is available; older clients have it on every Frame.
function Widget.CreateFrame(parent, name, ...)
    local template = "BackdropTemplate"
    if not _G.BackdropTemplateMixin then template = nil end
    local f = CreateFrame("Frame", name, parent or UIParent, template)
    Mixin.Apply(f, Base, ...)
    return f
end

function Widget.CreateButton(parent, name, ...)
    local b = CreateFrame("Button", name, parent or UIParent, "UIPanelButtonTemplate")
    Mixin.Apply(b, Base, ...)
    return b
end

function Widget.CreateScrollFrame(parent, name, ...)
    local sf = CreateFrame("ScrollFrame", name, parent or UIParent, "UIPanelScrollFrameTemplate")
    Mixin.Apply(sf, Base, ...)
    return sf
end

function Widget.CreateEditBox(parent, name, ...)
    local e = CreateFrame("EditBox", name, parent or UIParent, "InputBoxTemplate")
    e:SetAutoFocus(false)
    Mixin.Apply(e, Base, ...)
    return e
end

function Widget.CreateSlider(parent, name, ...)
    local s = CreateFrame("Slider", name, parent or UIParent, "OptionsSliderTemplate")
    Mixin.Apply(s, Base, ...)
    return s
end

function Widget.CreateCheckButton(parent, name, ...)
    local c = CreateFrame("CheckButton", name, parent or UIParent, "InterfaceOptionsCheckButtonTemplate")
    Mixin.Apply(c, Base, ...)
    return c
end
