-- Carbonite | Modules / Map / MapTooltip
-- The little black "you are here" tooltip the legacy NxMap shows
-- attached to a corner of the map window. The legacy implementation
-- (Nx.Map:CreateLocationTip + Nx.Map:SetLocationTip) created its own
-- private frame (NxMapTip) and font strings; this class lifts the
-- creation + update flow into a public API.
--
-- The frame still lives on Nx.Map.LocTipFrm so the rendering side
-- and any code looking it up by global name keep working. We just
-- wrap the verbs so other modules don't poke that field directly.
--
-- Public API:
--   MapTooltip:Init(parentFrame)     - one-time frame + font setup
--   MapTooltip:Set(text)             - show multi-line tip (nil = hide)
--   MapTooltip:Hide()
--   MapTooltip:IsVisible()
--   MapTooltip:GetFrame()
--   MapTooltip:SetAnchor(point, relPoint)
--                                    - lower-level override
-- The legacy methods Nx.Map:CreateLocationTip / SetLocationTip are
-- rewired to delegate.

local Carbonite = _G.Carbonite

local MapTooltip = {}
Carbonite.Modules.Map.MapTooltip = MapTooltip

local MAX_LINES = 4

local function map1()
    local NxMap = _G.Nx and _G.Nx.Map
    return NxMap and NxMap.Maps and NxMap.Maps[1]
end

local function fontHeight()
    local Nx = _G.Nx
    if Nx and Nx.Font and Nx.Font.GetH then return Nx.Font:GetH("Font.MapLoc") end
    return 12
end

function MapTooltip:Init(parent)
    parent = parent or (map1() and map1().Frm) or UIParent
    local NxMap = _G.Nx and _G.Nx.Map

    local f = (NxMap and NxMap.LocTipFrm) or CreateFrame("Frame", "NxMapTip", parent)
    self.frame = f
    if NxMap then NxMap.LocTipFrm = f end

    f:SetClampedToScreen(true)

    local tex = f.texture or f:CreateTexture()
    tex:SetAllPoints(f)
    tex:SetColorTexture(0, 0, 0, 0.85)
    f.texture = tex

    self.lines = NxMap and NxMap.LocTipFStrs or {}
    for n = #self.lines + 1, MAX_LINES do
        local fs = f:CreateFontString()
        fs:SetFontObject("NxFontMapLoc")
        fs:SetJustifyH("LEFT")
        self.lines[n] = fs
    end
    if NxMap then NxMap.LocTipFStrs = self.lines end
end

function MapTooltip:GetFrame() return self.frame end

function MapTooltip:Hide()
    if self.frame and self.frame.Hide then self.frame:Hide() end
end

function MapTooltip:IsVisible()
    return self.frame and self.frame.IsShown and self.frame:IsShown() or false
end

-- Override the anchor that ::Set uses (otherwise it pulls from
-- Nx.db.profile.Map.LocTipAnchor / LocTipAnchorRel).
function MapTooltip:SetAnchor(point, relPoint)
    self._override = { point = point, relPoint = relPoint }
end

function MapTooltip:Set(tipStr)
    if not self.frame then self:Init() end
    if not tipStr then self:Hide(); return end

    local map = map1()
    local mapFrame = map and map.Frm
    if not mapFrame then return end

    local db = _G.Nx and _G.Nx.db and _G.Nx.db.profile and _G.Nx.db.profile.Map or {}
    local anchor    = (self._override and self._override.point)    or db.LocTipAnchor
    local relAnchor = (self._override and self._override.relPoint) or db.LocTipAnchorRel

    if not anchor or anchor == "None" then self:Hide(); return end
    if not relAnchor or relAnchor == "None" then relAnchor = anchor end

    self.frame:ClearAllPoints()
    self.frame:SetPoint(anchor, mapFrame, relAnchor)

    local h = fontHeight()
    local textW = 0
    local i = 1
    for s in tipStr:gmatch("(%C+)") do
        local fs = self.lines[i]
        if not fs then break end
        fs:SetPoint("TOPLEFT", 2, 0 - (i - 1) * h)
        fs:SetText(s)
        local w = fs:GetStringWidth() or 0
        if w > textW then textW = w end
        i = i + 1
    end

    -- Blank unused lines.
    for n = i, #self.lines do self.lines[n]:SetText("") end

    self.frame:SetWidth(4 + textW)
    self.frame:SetHeight(2 + (i - 1) * h)
    self.frame:Show()
end

-- Legacy rewire so existing callers stay routed through this class.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.CreateLocationTip = function(self_) MapTooltip:Init(self_ and self_.Frm) end
    NxMap.SetLocationTip    = function(_, tipStr) MapTooltip:Set(tipStr) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
