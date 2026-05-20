-- Carbonite | UI / Window
-- Replacement for Nx.Window. A Window is a Frame with: title bar,
-- close button, draggable mixin, optional resizable mixin, ESC-to-close
-- handling, and a content area child that holds the body widgets.

local Carbonite = _G.Carbonite
local Widget = Carbonite.UI.Widget
local Mixin = Carbonite.UI.Mixin
local Draggable  = Carbonite.UI.Mixins.Draggable
local Resizable  = Carbonite.UI.Mixins.Resizable

local Window = {}
Carbonite.UI.Window = Window

local escTargets = {}
local escFrame

local function ensureEscWatcher()
    if escFrame then return end
    escFrame = CreateFrame("Frame", "CarbWindowEscWatcher", UIParent)
    escFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    escFrame:SetScript("OnEvent", function() end) -- placeholder
end

local Methods = {}

function Methods:SetTitle(text)
    self.titleText:SetText(text or "")
end

function Methods:GetContent()
    return self.content
end

-- Builds a new Carbonite window. `spec` keys:
--   name      string  Global frame name (optional but recommended).
--   title     string  Title-bar text.
--   width     number  Default width.
--   height    number  Default height.
--   parent    frame   Parent frame (defaults to UIParent).
--   dbAnchor  table   Anchor persistence target (Draggable mixin).
--   dbSize    table   Size persistence target (Resizable mixin).
--   resizable bool    Enable corner resize.
--   strata    string  Frame strata.
function Window:Create(spec)
    spec = spec or {}
    local f = Widget.CreateFrame(spec.parent or UIParent, spec.name)
    Mixin.Apply(f, Methods, Draggable)
    if spec.resizable then Mixin.Apply(f, Resizable) end

    f:SetSize(spec.width or 400, spec.height or 300)
    f:SetFrameStrata(spec.strata or "MEDIUM")
    f:SetCarbBackdrop()
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()

    -- Title bar
    local titleBar = f:CreateTexture(nil, "ARTWORK")
    titleBar:SetColorTexture(0, 0, 0, 0.6)
    titleBar:SetPoint("TOPLEFT", 6, -6)
    titleBar:SetPoint("TOPRIGHT", -6, -6)
    titleBar:SetHeight(20)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    title:SetText(spec.title or "")
    f.titleText = title

    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Content frame
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT",     8,  -28)
    content:SetPoint("BOTTOMRIGHT", -8,  8)
    f.content = content

    f:EnableDragging(spec.dbAnchor)
    if spec.resizable then f:EnableResizing(spec.dbSize, spec.minWidth, spec.minHeight) end

    -- ESC support: register so the default UISpecialFrames stack closes
    -- us. Use the global name to play nicely with Blizzard's queue.
    if spec.name then
        tinsert(UISpecialFrames, spec.name)
    end

    return f
end
