-- Carbonite | Modules / ChatHooks
-- Chat-output + popup helpers. The legacy code shipped Nx.prt /
-- Nx.prtD / Nx.prtVar / Nx.prtError / Nx.prtStack across NxUI.lua
-- and Nx:ShowMessage / Nx:ShowEditBox in Carbonite.lua. This class
-- gives all of them a single home and exposes Carbonite-friendly
-- aliases so new code doesn't depend on the legacy names.
--
-- Public API:
--   ChatHooks:Print(fmt, ...)             -> chat-frame message with prefix
--   ChatHooks:Debug(fmt, ...)             -> gated on Nx.DebugOn
--   ChatHooks:Warn(fmt, ...)
--   ChatHooks:Error(fmt, ...)
--   ChatHooks:DumpVar(label, value)
--   ChatHooks:DumpStack(label)
--   ChatHooks:Confirm(msg, okText, okFn, cancelText, cancelFn)
--   ChatHooks:Prompt(msg, initial, userData, onAccept, onCancel)
--
-- Confirm + Prompt wrap StaticPopupDialogs slots so the popup
-- queue stays consistent with the legacy Nx:ShowMessage /
-- Nx:ShowEditBox callers (same popup names: "NxMsg", "NxEdit").

local Carbonite = _G.Carbonite

local ChatHooks = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.ChatHooks = ChatHooks

local function nx() return _G.Nx end

-- ----------------------------------------------------------------
-- Print family.
-- ----------------------------------------------------------------

function ChatHooks:Print(fmt, ...)
    if nx() and nx().prt then return nx().prt(fmt, ...) end
    if Carbonite.Core.Logger then Carbonite.Core.Logger:info(fmt, ...) end
end

function ChatHooks:Debug(fmt, ...)
    if nx() and nx().prtD then return nx().prtD(fmt, ...) end
    if Carbonite.Core.Logger then Carbonite.Core.Logger:debug(fmt, ...) end
end

function ChatHooks:Warn(fmt, ...)
    if Carbonite.Core.Logger then Carbonite.Core.Logger:warn(fmt, ...) end
end

function ChatHooks:Error(fmt, ...)
    if nx() and nx().prtError then return nx().prtError(fmt, ...) end
    if Carbonite.Core.Logger then Carbonite.Core.Logger:error(fmt, ...) end
end

function ChatHooks:DumpVar(label, value)
    if nx() and nx().prtVar then return nx().prtVar(label, value) end
    if Carbonite.Core.Logger then Carbonite.Core.Logger:info("%s = %s", label, tostring(value)) end
end

function ChatHooks:DumpStack(label)
    if nx() and nx().prtStack then return nx().prtStack(label) end
end

-- ----------------------------------------------------------------
-- Popup confirmations. Reuses the legacy `NxMsg` / `NxEdit` slots
-- so other code calling Nx:ShowMessage / Nx:ShowEditBox shares the
-- queue (popups are mutually exclusive, "second hides first").
-- ----------------------------------------------------------------

function ChatHooks:Confirm(msg, okText, okFn, cancelText, cancelFn)
    local n = nx()
    if n and n.ShowMessage then return n:ShowMessage(msg, okText, okFn, cancelText, cancelFn) end

    local pop = _G.StaticPopupDialogs["NxMsg"]
    if not pop then
        pop = { whileDead = 1, hideOnEscape = 1, timeout = 0 }
        _G.StaticPopupDialogs["NxMsg"] = pop
    end
    pop.text     = msg
    pop.button1  = okText
    pop.OnAccept = okFn
    pop.button2  = cancelText
    pop.OnCancel = cancelFn
    pop.OnShow   = function(this)
        this:SetFrameStrata("FULLSCREEN_DIALOG")
        this:SetFrameLevel(100)
    end
    if _G.StaticPopup_Show then _G.StaticPopup_Show("NxMsg") end
end

function ChatHooks:Prompt(msg, initial, userData, onAccept, onCancel)
    local n = nx()
    if n and n.ShowEditBox then return n:ShowEditBox(msg, initial, userData, onAccept, onCancel) end
end

-- ----------------------------------------------------------------
-- Convenience: filter Blizzard's TimePlayed display so Carbonite's
-- Nx:RequestTimePlayed handler can capture without spamming chat.
-- This is the legacy behavior preserved from Carbonite.lua:
--     Nx.BlizzChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
--     ChatFrame_DisplayTimePlayed = function() end
-- ----------------------------------------------------------------

function ChatHooks:SuppressBlizzTimePlayed()
    if _G.ChatFrame_DisplayTimePlayed and not Carbonite._timePlayedSuppressed then
        Carbonite._timePlayedDisplay = _G.ChatFrame_DisplayTimePlayed
        _G.ChatFrame_DisplayTimePlayed = function() end
        Carbonite._timePlayedSuppressed = true
    end
end

function ChatHooks:RestoreBlizzTimePlayed()
    if Carbonite._timePlayedDisplay then
        _G.ChatFrame_DisplayTimePlayed = Carbonite._timePlayedDisplay
        Carbonite._timePlayedSuppressed = false
    end
end
