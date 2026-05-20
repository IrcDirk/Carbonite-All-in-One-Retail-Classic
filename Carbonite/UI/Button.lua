-- Carbonite | UI / Button
-- Cleaner Button widget. Provides two ways to create a button:
--
--   1. The new modern API (preferred for new code):
--        Carbonite.UI.Button:New {
--            parent = someFrame,
--            text   = "OK",
--            tooltip = "Confirm and close",
--            width = 80, height = 22,
--            anchor = { point = "TOPLEFT", x = 10, y = -10 },
--            onClick = function(b, mouseButton) ... end,
--            template = "UIPanelButtonTemplate",
--        }
--      Returns a Frame with extra Carbonite methods (SetCarbTooltip etc.).
--
--   2. The legacy Nx.Button:Create entry point keeps working unchanged
--      (the heavy state-machine implementation lives in NxUI.lua). New
--      code paths should use the API above.
--
-- This file does NOT replace the legacy Nx.Button table; it sits next
-- to it. Both can coexist while migration proceeds.

local Carbonite = _G.Carbonite
local Widget = Carbonite.UI.Widget
local Mixin  = Carbonite.UI.Mixin
local Tooltipable = Carbonite.UI.Mixins and Carbonite.UI.Mixins.Tooltipable

local Button = {}
Carbonite.UI.Button = Button

-- --------------------------------------------------------------------
-- Modern factory.
-- --------------------------------------------------------------------

local Methods = {}

function Methods:SetText(text)
    if self.SetTextLabel then self:SetTextLabel(text) end
end

function Methods:SetEnabled_(enabled)
    if enabled then self:Enable() else self:Disable() end
end

function Methods:SetClickHandler(fn)
    self.onClickFn = fn
    self:SetScript("OnClick", function(self_, mouseButton)
        if self_.onClickFn then
            local ok, err = pcall(self_.onClickFn, self_, mouseButton)
            if not ok and Carbonite.Core.Logger then
                Carbonite.Core.Logger:Get("Button"):error("click handler failed: %s", err)
            end
        end
    end)
end

function Button:New(spec)
    spec = spec or {}
    local template = spec.template or "UIPanelButtonTemplate"
    local parent = spec.parent or UIParent

    local b = CreateFrame("Button", spec.name, parent, template)
    Mixin.Apply(b, Methods)
    if Tooltipable then Mixin.Apply(b, Tooltipable) end

    if spec.width or spec.height then
        b:SetSize(spec.width or 80, spec.height or 22)
    end

    if spec.anchor then
        b:SetPoint(spec.anchor.point or "CENTER",
            spec.anchor.relativeTo or parent,
            spec.anchor.relPoint or (spec.anchor.point or "CENTER"),
            spec.anchor.x or 0,
            spec.anchor.y or 0)
    end

    if spec.text then
        if b.SetText then b:SetText(spec.text) end
    end

    if spec.tooltip and b.SetCarbTooltip then
        b:SetCarbTooltip(spec.tooltip, spec.tooltipAnchor or "ANCHOR_RIGHT")
    end

    if spec.onClick then
        b:SetClickHandler(spec.onClick)
    end

    if spec.enabled == false then b:Disable() end

    return b
end

-- --------------------------------------------------------------------
-- Type registry. The legacy Nx.Button supported a "type" string that
-- selected texture and behaviour from TypeData. New code can declare
-- types via Button:DefineType.
-- --------------------------------------------------------------------

function Button:DefineType(typeName, data)
    local NxButton = _G.Nx and _G.Nx.Button
    if NxButton and NxButton.TypeData then
        NxButton.TypeData[typeName] = data
    end
end

function Button:GetType(typeName)
    local NxButton = _G.Nx and _G.Nx.Button
    return NxButton and NxButton.TypeData and NxButton.TypeData[typeName]
end

-- --------------------------------------------------------------------
-- Adapter to the legacy Nx.Button. New code that needs the heavy
-- Carbonite-skinned button keeps working through this adapter. The
-- adapter returns the underlying legacy object so further `:Method`
-- calls behave exactly the same.
-- --------------------------------------------------------------------

function Button:NewLegacy(parent, typ, text, tip, x, y, side, w, h, fn, user, template)
    local NxButton = _G.Nx and _G.Nx.Button
    if NxButton and NxButton.Create then
        return NxButton:Create(parent, typ, text, tip, x, y, side, w, h, fn, user, template)
    end
end
