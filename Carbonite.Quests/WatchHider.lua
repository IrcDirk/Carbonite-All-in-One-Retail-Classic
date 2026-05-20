-- Carbonite.Quests | WatchHider
-- Class wrapper around Nx.Quest:TrackerHider_*. Its job is to hide
-- Blizzard's stock quest tracker frame when Carbonite's own watch
-- list is enabled. The legacy implementation in NxQuest.lua keeps
-- doing the actual work (because it ties into the Blizzard EditMode
-- hooks + the protected-frame combat lockout); this class exposes
-- a clean public surface so other plugins / commands can ask "is
-- the Blizzard tracker hidden right now?" or force a refresh.
--
-- Public API:
--   WatchHider:Apply()        - re-evaluate visibility now
--   WatchHider:IsHidden()     - bool
--   WatchHider:ShouldHide()   - what the policy says
--   WatchHider:SetEnabled(on) - flip the policy (DB toggle)
--   WatchHider:IsBlizzardLockedDown(frame) - combat-protected check

local Carbonite = _G.Carbonite
if not Carbonite then return end

local WatchHider = {}
Carbonite.Quests = Carbonite.Quests or {}
Carbonite.Quests.WatchHider = WatchHider

local function quest()
    local Nx = _G.Nx
    return Nx and Nx.Quest
end

function WatchHider:Apply()
    local q = quest()
    if q and q.TrackerHider_Apply then q:TrackerHider_Apply() end
end

function WatchHider:IsHidden()
    -- Heuristic: when the policy says hide and there is no protected
    -- lockdown pending, the tracker is hidden. We can't ask the
    -- frame directly (it may have been reparented to a hidden one).
    local q = quest()
    if not q or not q._trackerHider then return false end
    return self:ShouldHide() and q._trackerHider.pending ~= true
end

function WatchHider:ShouldHide()
    local q = quest()
    if not q or not q.TrackerHider_ShouldHide then return false end
    return q:TrackerHider_ShouldHide()
end

function WatchHider:SetEnabled(on)
    local Nx = _G.Nx
    if not Nx or not Nx.qdb or not Nx.qdb.profile then return end
    Nx.qdb.profile.QuestWatch = Nx.qdb.profile.QuestWatch or {}
    Nx.qdb.profile.QuestWatch.HideBlizz = on and true or false
    self:Apply()
end

function WatchHider:IsBlizzardLockedDown(frame)
    if _G.NxTracker_IsProtectedAndLockedDown then
        return _G.NxTracker_IsProtectedAndLockedDown(frame) == true
    end
    return false
end

-- Slash command + auto-rebind on combat exit.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("hidewatch", function(rest)
        rest = (rest or ""):lower()
        if rest == "on" then WatchHider:SetEnabled(true)
        elseif rest == "off" then WatchHider:SetEnabled(false)
        else
            local q = _G.Nx and _G.Nx.qdb and _G.Nx.qdb.profile and _G.Nx.qdb.profile.QuestWatch
            local cur = q and q.HideBlizz == true
            WatchHider:SetEnabled(not cur)
        end
        local log = Carbonite.Core.Logger:Get("WatchHider")
        log:info("hide Blizzard tracker: %s", WatchHider:ShouldHide() and "on" or "off")
    end, "toggle hide of the Blizzard quest tracker")
end)
