-- Carbonite | UI / DropDown
-- Modern dropdown widget. Uses Blizzard's UIDropDownMenuTemplate /
-- LibUIDropDownMenu under the hood and exposes a clean spec-table
-- API instead of the legacy Nx.DropDown:Create / SetItems
-- positional-argument pattern.
--
--   local dd = Carbonite.UI.DropDown:New {
--       parent = parentFrame,
--       label  = "Theme",
--       width  = 160,
--       anchor = { point = "TOPLEFT", x = 10, y = -10 },
--       items  = {
--           { value = "modern_dark",  text = "Modern Dark" },
--           { value = "modern_light", text = "Modern Light" },
--           { value = "glass",        text = "Glass" },
--       },
--       value  = "modern_dark",
--       onSelect = function(dd, value, text) ... end,
--   }
--
--   dd:GetValue() / dd:SetValue(v) / dd:SetItems(list)
--
-- This file does NOT replace the legacy Nx.DropDown (the menu-driven
-- variant used inside Nx.Menu still lives in NxUI.lua). New code
-- should use this class; legacy code keeps working unchanged.

local Carbonite = _G.Carbonite
local DropDown = {}
Carbonite.UI.DropDown = DropDown

local Methods = {}

function Methods:GetValue() return self._value end

function Methods:SetValue(value, fireCallback)
    self._value = value
    for _, item in ipairs(self._items or {}) do
        if item.value == value then
            if _G.UIDropDownMenu_SetSelectedValue then _G.UIDropDownMenu_SetSelectedValue(self, value) end
            if _G.UIDropDownMenu_SetText then _G.UIDropDownMenu_SetText(self, item.text) end
            if fireCallback ~= false and self._onSelect then
                self._onSelect(self, value, item.text)
            end
            return
        end
    end
    -- value not in items: clear display
    if _G.UIDropDownMenu_SetText then _G.UIDropDownMenu_SetText(self, "") end
end

function Methods:SetItems(items)
    self._items = items or {}
    -- Reinitialize so the menu rebuilds from the new list.
    if _G.UIDropDownMenu_Initialize then
        _G.UIDropDownMenu_Initialize(self, self._initializer)
    end
end

local function defaultInitializer(self, level)
    local items = self._items or {}
    for _, item in ipairs(items) do
        local info = _G.UIDropDownMenu_CreateInfo and _G.UIDropDownMenu_CreateInfo() or {}
        info.text  = item.text or tostring(item.value)
        info.value = item.value
        info.checked = (item.value == self._value)
        info.disabled = item.disabled
        info.func = function(infoArg)
            self:SetValue(infoArg.value, true)
            if _G.CloseDropDownMenus then _G.CloseDropDownMenus() end
        end
        if _G.UIDropDownMenu_AddButton then _G.UIDropDownMenu_AddButton(info, level) end
    end
end

function DropDown:New(spec)
    spec = spec or {}
    local parent = spec.parent or UIParent
    local frame = CreateFrame("Frame", spec.name, parent, "UIDropDownMenuTemplate")
    for k, v in pairs(Methods) do frame[k] = v end

    frame._items    = spec.items or {}
    frame._value    = spec.value
    frame._onSelect = spec.onSelect
    frame._initializer = defaultInitializer

    if spec.anchor then
        frame:SetPoint(spec.anchor.point or "TOPLEFT",
            spec.anchor.relativeTo or parent,
            spec.anchor.relPoint or (spec.anchor.point or "TOPLEFT"),
            spec.anchor.x or 0, spec.anchor.y or 0)
    end

    if _G.UIDropDownMenu_SetWidth and spec.width then
        _G.UIDropDownMenu_SetWidth(frame, spec.width)
    end

    if spec.label then
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 16, 2)
        label:SetText(spec.label)
        frame._labelStr = label
    end

    if _G.UIDropDownMenu_Initialize then _G.UIDropDownMenu_Initialize(frame, defaultInitializer) end
    if spec.value then frame:SetValue(spec.value, false) end

    return frame
end
