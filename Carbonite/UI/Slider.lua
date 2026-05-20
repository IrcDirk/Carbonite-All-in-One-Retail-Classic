-- Carbonite | UI / Slider
-- Modern Slider widget using Blizzard's OptionsSliderTemplate. Built
-- as a clean replacement for the legacy `Nx.Slider` (which only
-- existed as an empty namespace + a few methods scattered through
-- the menu code). The legacy Nx.Slider is left untouched; new code
-- should use Carbonite.UI.Slider:New.
--
-- Usage:
--   local s = Carbonite.UI.Slider:New {
--       parent  = parentFrame,
--       label   = "Map opacity",
--       min     = 0,
--       max     = 1,
--       step    = 0.05,
--       value   = 0.6,
--       width   = 180,
--       suffix  = "%",                  -- display suffix (optional)
--       valueFormat = "%.0f",           -- format for displayed value
--       anchor  = { point = "TOPLEFT", x = 10, y = -50 },
--       onChange = function(slider, value) ... end,
--   }

local Carbonite = _G.Carbonite
local Slider = {}
Carbonite.UI.Slider = Slider

local Methods = {}

function Methods:SetUserValue(v, fireCallback)
    self:SetValue(v)
    if fireCallback ~= false and self._onChange then
        self._onChange(self, v)
    end
end

function Methods:GetLabel()  return self._label end
function Methods:SetLabel(text)
    self._label = text
    if self._labelStr then self._labelStr:SetText(text or "") end
end

local function updateValueText(s, v)
    if not s._valueStr then return end
    local fmt = s._valueFormat or "%.2f"
    local display = fmt:format(v)
    if s._suffix then display = display .. s._suffix end
    s._valueStr:SetText(display)
end

function Slider:New(spec)
    spec = spec or {}
    local parent = spec.parent or UIParent
    local s = CreateFrame("Slider", spec.name, parent, "OptionsSliderTemplate")
    for k, v in pairs(Methods) do s[k] = v end

    s:SetMinMaxValues(spec.min or 0, spec.max or 1)
    s:SetValueStep(spec.step or 1)
    s:SetObeyStepOnDrag(true)
    s:SetWidth(spec.width or 150)

    if spec.anchor then
        s:SetPoint(spec.anchor.point or "TOPLEFT",
            spec.anchor.relativeTo or parent,
            spec.anchor.relPoint or (spec.anchor.point or "TOPLEFT"),
            spec.anchor.x or 0, spec.anchor.y or 0)
    end

    -- OptionsSliderTemplate creates a `Text` (title), `Low`, `High`,
    -- and a `Value` font string by convention. Some clients use
    -- different names; resolve by lookup.
    local name = s:GetName()
    if name then
        s._labelStr = _G[name .. "Text"]
        local lowStr  = _G[name .. "Low"]
        local highStr = _G[name .. "High"]
        if lowStr then lowStr:SetText(tostring(spec.min or 0)) end
        if highStr then highStr:SetText(tostring(spec.max or 1)) end
    end

    -- A value-display font string anchored below the slider.
    s._valueStr = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    s._valueStr:SetPoint("TOP", s, "BOTTOM", 0, -2)

    s._label = spec.label
    if s._labelStr and spec.label then s._labelStr:SetText(spec.label) end

    s._suffix = spec.suffix
    s._valueFormat = spec.valueFormat
    s._onChange = spec.onChange

    s:SetValue(spec.value or spec.min or 0)
    updateValueText(s, s:GetValue())

    s:SetScript("OnValueChanged", function(self_, value)
        updateValueText(self_, value)
        if self_._onChange then self_._onChange(self_, value) end
    end)

    return s
end
