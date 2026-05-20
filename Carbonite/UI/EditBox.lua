-- Carbonite | UI / EditBox
-- Modern EditBox widget. Provides the same "search-style" placeholder
-- behavior as the legacy Nx.EditBox (placeholder text shown until the
-- user clicks, restored when the box is empty and loses focus) but
-- with a clean callback signature and Blizzard's InputBoxTemplate
-- visual chrome.
--
-- Usage:
--   local search = Carbonite.UI.EditBox:New {
--       parent      = parentFrame,
--       width       = 200,
--       maxLetters  = 60,
--       placeholder = "Search:",
--       anchor      = { point = "TOPLEFT", x = 10, y = -10 },
--       onChanged   = function(box, text) ... end,
--       onSubmit    = function(box, text) ... end,
--   }
--
-- The legacy Nx.EditBox:Create entry point is preserved verbatim in
-- NxUI.lua; legacy callers keep working unchanged.

local Carbonite = _G.Carbonite
local EditBox = {}
Carbonite.UI.EditBox = EditBox

local Methods = {}

function Methods:GetUserText()
    return self._userText or ""
end

function Methods:SetUserText(text, fireCallback)
    self._userText = text or ""
    if self._hasFocus or self._userText ~= "" then
        self:SetText(self._userText)
    else
        self:SetText(self._placeholder or "")
    end
    if fireCallback and self._onChanged then
        self._onChanged(self, self._userText)
    end
end

function Methods:Clear()
    self._userText = ""
    if not self._hasFocus then
        self:SetText(self._placeholder or "")
    end
end

local function installPlaceholderScripts(box, placeholder, escPattern)
    box._placeholder = placeholder or ""
    box._userText = ""
    box._hasFocus = false

    box:SetText(box._placeholder)

    box:SetScript("OnEditFocusGained", function(f)
        f._hasFocus = true
        if f._userText == "" then
            f:SetText("")
        else
            f:SetText(f._userText)
        end
    end)

    box:SetScript("OnEditFocusLost", function(f)
        f._hasFocus = false
        if f._userText == "" then
            f:SetText(f._placeholder)
        end
    end)

    box:SetScript("OnTextChanged", function(f)
        local raw = f:GetText() or ""
        if escPattern and raw ~= "" then
            raw = raw:gsub(escPattern, "")
        end
        f._userText = raw
        if f._onChanged then f._onChanged(f, raw) end
    end)

    box:SetScript("OnEnterPressed", function(f)
        if f._onSubmit then f._onSubmit(f, f._userText) end
        f:ClearFocus()
    end)

    box:SetScript("OnEscapePressed", function(f)
        f._userText = ""
        f:ClearFocus()
    end)
end

function EditBox:New(spec)
    spec = spec or {}
    local parent = spec.parent or UIParent
    local box = CreateFrame("EditBox", spec.name, parent, "InputBoxTemplate")
    for k, v in pairs(Methods) do box[k] = v end

    box:SetAutoFocus(false)
    box:SetFontObject((spec.fontObject) or "ChatFontNormal")
    if spec.height then box:SetHeight(spec.height) else box:SetHeight(20) end
    if spec.width  then box:SetWidth(spec.width) end

    if spec.anchor then
        box:SetPoint(spec.anchor.point or "TOPLEFT",
            spec.anchor.relativeTo or parent,
            spec.anchor.relPoint or (spec.anchor.point or "TOPLEFT"),
            spec.anchor.x or 0, spec.anchor.y or 0)
    end
    if spec.maxLetters then box:SetMaxLetters(spec.maxLetters) end

    box._onChanged = spec.onChanged
    box._onSubmit  = spec.onSubmit

    local placeholder = spec.placeholder
    local escapePattern
    if placeholder then
        -- Build a literal pattern from the placeholder so OnTextChanged
        -- can strip it cleanly when the user's text contains it.
        escapePattern = placeholder:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    end
    installPlaceholderScripts(box, placeholder, escapePattern)

    return box
end
