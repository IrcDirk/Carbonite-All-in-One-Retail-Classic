-- Carbonite | UI / ToolBar
-- Horizontal strip of icon buttons. Replaces the legacy Nx.ToolBar
-- which was tied to Carbonite's custom Window class. This version
-- works as a standalone Frame so it can live inside any container.
--
--   local bar = Carbonite.UI.ToolBar:New {
--       parent = parentFrame,
--       height = 24,
--       spacing = 2,
--       anchor = { point = "TOPLEFT", x = 0, y = 0 },
--       items  = {
--           { icon = "Interface\\Icons\\Achievement_Boss_KelThuzad_02",
--             tooltip = "Open Carbonite map",
--             onClick = function() Carbonite:GetModule("Map"):Open() end },
--           ...
--       },
--   }
--
--   bar:Add(spec)            -- append at runtime; returns the button
--   bar:Clear()              -- drop every button
--   bar:Count()
--   bar:Get(index)           -- by 1-based index
--   bar:SetItemEnabled(i, b)

local Carbonite = _G.Carbonite
local Tooltipable = Carbonite.UI.Mixins and Carbonite.UI.Mixins.Tooltipable
local Mixin = Carbonite.UI.Mixin

local ToolBar = {}
Carbonite.UI.ToolBar = ToolBar

local Methods = {}

local function reflow(bar)
    local x = 0
    local spacing = bar._spacing or 0
    local size    = bar._iconSize or bar._height or 24
    for i, btn in ipairs(bar._items) do
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", bar, "LEFT", x, 0)
        btn:SetSize(size, size)
        x = x + size + spacing
    end
    bar:SetWidth(math.max(1, x - (spacing or 0)))
end

function Methods:Add(spec)
    spec = spec or {}
    local size = self._iconSize or self._height or 24

    local btn = CreateFrame("Button", nil, self)
    btn:SetSize(size, size)

    if spec.icon then
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(btn)
        tex:SetTexture(spec.icon)
        btn.icon = tex
        if spec.iconCoords then
            tex:SetTexCoord(unpack(spec.iconCoords))
        end
    end

    btn:SetScript("OnClick", function(self_, mouseButton)
        if spec.onClick then
            local ok, err = pcall(spec.onClick, self_, mouseButton)
            if not ok and Carbonite.Core.Logger then
                Carbonite.Core.Logger:Get("ToolBar"):error("button onClick failed: %s", err)
            end
        end
    end)
    btn:RegisterForClicks("AnyUp")

    if Tooltipable then Mixin.Apply(btn, Tooltipable) end
    if spec.tooltip and btn.SetCarbTooltip then
        btn:SetCarbTooltip(spec.tooltip, "ANCHOR_TOP")
    end

    if spec.enabled == false then btn:Disable() end

    table.insert(self._items, btn)
    reflow(self)
    return btn
end

function Methods:Clear()
    for _, btn in ipairs(self._items) do
        btn:Hide()
        btn:SetParent(nil)
    end
    self._items = {}
    reflow(self)
end

function Methods:Count()
    return #self._items
end

function Methods:Get(index)
    return self._items[index]
end

function Methods:SetItemEnabled(index, enabled)
    local btn = self._items[index]
    if not btn then return end
    if enabled then btn:Enable() else btn:Disable() end
end

function Methods:Each(fn)
    for i, btn in ipairs(self._items) do fn(btn, i) end
end

function ToolBar:New(spec)
    spec = spec or {}
    local parent = spec.parent or UIParent
    local bar = CreateFrame("Frame", spec.name, parent)
    for k, v in pairs(Methods) do bar[k] = v end

    bar._items    = {}
    bar._spacing  = spec.spacing  or 2
    bar._height   = spec.height   or 24
    bar._iconSize = spec.iconSize or bar._height
    bar:SetHeight(bar._height)

    if spec.anchor then
        bar:SetPoint(spec.anchor.point or "TOPLEFT",
            spec.anchor.relativeTo or parent,
            spec.anchor.relPoint or (spec.anchor.point or "TOPLEFT"),
            spec.anchor.x or 0, spec.anchor.y or 0)
    end

    for _, item in ipairs(spec.items or {}) do bar:Add(item) end
    return bar
end
