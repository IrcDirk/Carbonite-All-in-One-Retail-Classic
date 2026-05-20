-- Carbonite | Modules / ProfileSwitcher
-- Documented surface around AceDB-3.0 profile operations on the
-- live Carbonite database. The legacy code wires
-- OnProfileChanged / OnProfileCopied / OnProfileReset directly on
-- Nx.db; this class is the public accessor + handy slash commands.
--
-- Public API:
--   ProfileSwitcher:GetCurrent()
--   ProfileSwitcher:GetProfiles()    -> array
--   ProfileSwitcher:SetProfile(name)
--   ProfileSwitcher:CopyProfile(srcName)
--   ProfileSwitcher:ResetProfile()
--   ProfileSwitcher:DeleteProfile(name)

local Carbonite = _G.Carbonite

local ProfileSwitcher = {}
Carbonite.Modules.ProfileSwitcher = ProfileSwitcher

local function db() return _G.Nx and _G.Nx.db end

function ProfileSwitcher:GetCurrent()
    local d = db()
    return d and d.keys and d.keys.profile or nil
end

function ProfileSwitcher:GetProfiles()
    local d = db()
    return d and d.GetProfiles and d:GetProfiles() or {}
end

function ProfileSwitcher:SetProfile(name)
    local d = db()
    if not d or not d.SetProfile or not name then return end
    d:SetProfile(name)
    Carbonite.Core.EventBus:Fire("PROFILE_SWITCHED", name)
end

function ProfileSwitcher:CopyProfile(srcName)
    local d = db()
    if not d or not d.CopyProfile or not srcName then return end
    d:CopyProfile(srcName)
    Carbonite.Core.EventBus:Fire("PROFILE_COPIED", srcName)
end

function ProfileSwitcher:ResetProfile()
    local d = db()
    if not d or not d.ResetProfile then return end
    d:ResetProfile()
    Carbonite.Core.EventBus:Fire("PROFILE_RESET", self:GetCurrent())
end

function ProfileSwitcher:DeleteProfile(name)
    local d = db()
    if not d or not d.DeleteProfile or not name then return end
    d:DeleteProfile(name)
    Carbonite.Core.EventBus:Fire("PROFILE_DELETED", name)
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("profile", function(rest)
        local log = Carbonite.Core.Logger:Get("ProfileSwitcher")
        rest = rest or ""
        local cmd, arg = rest:match("^(%S+)%s*(.*)$")
        if cmd == "list" or cmd == nil then
            log:info("current: %s", tostring(ProfileSwitcher:GetCurrent()))
            for _, name in ipairs(ProfileSwitcher:GetProfiles()) do log:info("  %s", name) end
        elseif cmd == "set" then
            ProfileSwitcher:SetProfile(arg)
        elseif cmd == "copy" then
            ProfileSwitcher:CopyProfile(arg)
        elseif cmd == "reset" then
            ProfileSwitcher:ResetProfile()
        elseif cmd == "delete" then
            ProfileSwitcher:DeleteProfile(arg)
        else
            log:info("usage: /cb profile [list|set|copy|reset|delete] [name]")
        end
    end, "AceDB profile operations")
end)
