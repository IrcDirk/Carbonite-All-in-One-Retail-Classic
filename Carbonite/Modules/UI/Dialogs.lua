-- Carbonite | Modules / UI / Dialogs
-- Modal dialog helpers extracted from Carbonite.lua. Carbonite
-- wraps Blizzard's StaticPopupDialogs for two common cases:
--   * a 1/2-button message popup with caller-supplied callbacks
--   * a single-line edit-box popup with accept/cancel
--
-- Methods remain on the Nx namespace (Nx:ShowMessage, Nx:ShowEditBox)
-- so unmigrated callers keep working. The new public-facing aliases
-- live on Carbonite.UI.Dialogs.

local Carbonite = _G.Carbonite

local Dialogs = {}
Carbonite.UI = Carbonite.UI or {}
Carbonite.UI.Dialogs = Dialogs

---
-- Show a one- or two-button message dialog.
-- @param msg       Body text.
-- @param func1Txt  Button 1 label.
-- @param func1     Button 1 callback (Blizzard OnAccept).
-- @param func2Txt  Button 2 label (optional).
-- @param func2     Button 2 callback (optional, Blizzard OnCancel).
--
function Nx:ShowMessage(msg, func1Txt, func1, func2Txt, func2)
    local pop = StaticPopupDialogs["NxMsg"]

    if not pop then
        pop = {
            ["whileDead"]    = 1,
            ["hideOnEscape"] = 1,
            ["timeout"]      = 0,
        }
        StaticPopupDialogs["NxMsg"] = pop
    end

    pop["text"]     = msg
    pop["button1"]  = func1Txt
    pop["OnAccept"] = func1
    pop["button2"]  = func2Txt
    pop["OnCancel"] = func2

    pop["OnShow"] = function(this)
        this:SetFrameStrata("FULLSCREEN_DIALOG")
        this:SetFrameLevel(100)
    end

    StaticPopup_Show("NxMsg")
end

---
-- Show a single-line edit-box dialog with accept/cancel callbacks.
-- The accept callback receives (text, userData).
-- @param msg         Prompt text.
-- @param val         Initial edit-box value.
-- @param userData    Opaque value passed back to funcAccept.
-- @param funcAccept  Accept callback.
-- @param funcCancel  Cancel callback (Blizzard OnCancel).
--
function Nx:ShowEditBox(msg, val, userData, funcAccept, funcCancel)
    local pop = StaticPopupDialogs["NxEdit"]

    if not pop then
        pop = {
            ["whileDead"]    = 1,
            ["hideOnEscape"] = 1,
            ["timeout"]      = 0,
            ["exclusive"]    = 1,
            ["hasEditBox"]   = 1,
        }
        StaticPopupDialogs["NxEdit"] = pop
    end

    pop["maxLetters"] = 110
    pop["text"]       = msg

    Nx.ShowEditBoxVal   = tostring(val)
    Nx.ShowEditBoxUData = userData
    Nx.ShowEditBoxFunc  = funcAccept

    pop["OnAccept"] = function(this)
        if Nx.ShowEditBoxFunc then
            Nx.ShowEditBoxFunc(_G[this:GetName() .. "EditBox"]:GetText(), Nx.ShowEditBoxUData)
        end
    end

    pop["EditBoxOnEnterPressed"] = function(this)
        if Nx.ShowEditBoxFunc then
            Nx.ShowEditBoxFunc(_G[this:GetParent():GetName() .. "EditBox"]:GetText(), Nx.ShowEditBoxUData)
        end
        this:GetParent():Hide()
    end

    pop["EditBoxOnEscapePressed"] = function(this)
        this:GetParent():Hide()
    end

    pop["OnShow"] = function(this)
        this:SetFrameStrata("FULLSCREEN_DIALOG")
        this:SetFrameLevel(100)

        ChatEdit_FocusActiveWindow()
        local eb = _G[this:GetName() .. "EditBox"]
        eb:SetFocus()
        eb:SetText(Nx.ShowEditBoxVal)
        eb:HighlightText()
    end

    pop["OnHide"] = function(this)
        _G[this:GetName() .. "EditBox"]:SetText("")
    end

    pop["button1"]  = ACCEPT
    pop["button2"]  = CANCEL
    pop["OnCancel"] = funcCancel

    StaticPopup_Show("NxEdit")
end

---
-- Stub for trial-version messaging. Carbonite is fully free now;
-- callsites in legacy code still invoke this to gate paid features.
--
function Nx:ShowMessageTrial()
end

---
-- Return the currently focused chat edit box if any -- thin wrapper
-- around Blizzard's ChatEdit_GetActiveWindow so older code can
-- forward through Nx:FindActiveChatFrameEditBox.
--
function Nx:FindActiveChatFrameEditBox()
    return ChatEdit_GetActiveWindow()
end

-- New-style aliases on the public Carbonite.UI.Dialogs surface.
function Dialogs:Message(...)   return Nx:ShowMessage(...) end
function Dialogs:EditBox(...)   return Nx:ShowEditBox(...) end
function Dialogs:ActiveChatEditBox() return Nx:FindActiveChatFrameEditBox() end
