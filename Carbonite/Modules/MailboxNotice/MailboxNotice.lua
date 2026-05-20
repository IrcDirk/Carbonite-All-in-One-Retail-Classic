-- Carbonite | Modules / MailboxNotice
-- Listens on UPDATE_PENDING_MAIL and pulses the minimap-button
-- glow when the player has new mail. Standalone from Blizzard's
-- own MiniMapMailFrame so it works even when the user has the
-- mail-frame option hidden.
--
-- Public API:
--   MailboxNotice:HasPending()       -> bool
--   MailboxNotice:GetCount()         -> int (best-effort)
--   MailboxNotice:OnNewMail(fn)

local Carbonite = _G.Carbonite
local MailboxNotice = {}
Carbonite.Modules.MailboxNotice = MailboxNotice

function MailboxNotice:HasPending()
    if not _G.HasNewMail then return false end
    return _G.HasNewMail()
end

function MailboxNotice:GetCount()
    -- Blizzard's API doesn't expose a count without opening the
    -- mailbox; we return 1 / 0 as a fallback.
    return self:HasPending() and 1 or 0
end

function MailboxNotice:OnNewMail(fn)
    if type(fn) == "function" then
        Carbonite.Core.EventBus:Subscribe("MAILBOX_NEW_MAIL", fn)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbMailboxNotice")
    f:RegisterEvent("UPDATE_PENDING_MAIL")
    f:SetScript("OnEvent", function()
        if MailboxNotice:HasPending() then
            Carbonite.Core.EventBus:Fire("MAILBOX_NEW_MAIL")
            local g = Carbonite.Modules.Map and Carbonite.Modules.Map.NameplateGlow
            if g and g.Pulse then g:Pulse() end
        end
    end)
end)
