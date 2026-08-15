-- Carbonite | Modules / TaintlessHelpers
-- Documented surface around Carbonite's Taintless.xml hooks. The
-- legacy file defines a handful of Frame templates that proxy
-- combat-protected operations through a sandbox so the addon
-- doesn't taint Blizzard's secure code path. This class is the
-- public accessor for asking "is the sandbox loaded?" and
-- forwarding through it.
--
-- Public API:
--   TaintlessHelpers:IsAvailable()
--   TaintlessHelpers:GetSandbox()
--   TaintlessHelpers:ProxyCall(fn, ...)
--
-- ProxyCall: schedules `fn(...)` for the next OnUpdate tick so it
-- runs outside a tainted call stack. The legacy Carbonite code
-- threads many secure operations through this idiom; this wrapper
-- gives it a name.

local Carbonite = _G.Carbonite
local TaintlessHelpers = {}
Carbonite.Modules.TaintlessHelpers = TaintlessHelpers

-- WoW Lua 5.1: `unpack` is the global; `table.unpack` (5.2+) is nil on
-- some 12.0-engine flavors. Resolve portably.
local unpack = table.unpack or unpack
local securecallfunction = _G.securecallfunction

function TaintlessHelpers:GetSandbox()
    return _G.NxTaintlessFrame
end

function TaintlessHelpers:IsAvailable()
    return self:GetSandbox() ~= nil
end

-- Run a Blizzard-owned function without carrying Carbonite's execution taint
-- into synchronous events and callback registries fired by that function.
-- This matters on Retail 12.x because those callbacks can acquire map pins or
-- lay out secret UI-widget dimensions before the original API call returns.
local function CallBlizzardSecurely(api, ...)
    if type(api) ~= "function" then
        return false
    end

    if securecallfunction then
        securecallfunction(api, ...)
    else
        -- Classic clients without securecallfunction do not expose Retail's
        -- secret-value map/widget path. Keep their legacy behavior intact.
        api(...)
    end
    return true
end

function TaintlessHelpers:SecureAPICall(api, ...)
    if type(api) ~= "function" then
        return false
    end

    local args = { ... }
    local function Invoke()
        CallBlizzardSecurely(api, unpack(args))
    end

    if _G.InCombatLockdown and _G.InCombatLockdown() then
        local CL = Carbonite.Modules.CombatLockdown
        if CL then
            CL:RunWhenSafe(Invoke)
            return true
        end
    end

    Invoke()
    return true
end

-- Scheduling half of the super-track boundary. This keeps a complete logical
-- mutation together and defers it through combat; mutation closures must call
-- the specialized *Safe wrappers below so the Blizzard C API itself is also
-- entered through securecallfunction. A timer or regen deferral alone still
-- executes as Carbonite and therefore does not remove taint.
function TaintlessHelpers:SuperTrackCall(fn)
    if type(fn) ~= "function" then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        local CL = Carbonite.Modules.CombatLockdown
        if CL then
            CL:RunWhenSafe(fn)
            return
        end
    end
    fn()
end

-- Nx-level alias so legacy Carbonite code and the Carbonite.Quests
-- addon (which load after this module) can reach the wrapper
-- without going through Carbonite.Modules.
if _G.Nx then
    _G.Nx.SuperTrackSafe = function(fn) TaintlessHelpers:SuperTrackCall(fn) end

    -- Specialized wrappers deliberately secure-call the Blizzard API itself.
    -- Secure-calling an addon closure would not protect the nested C API call.
    _G.Nx.SetSuperTrackedQuestIDSafe = function(questID)
        local api = _G.C_SuperTrack and _G.C_SuperTrack.SetSuperTrackedQuestID
        return TaintlessHelpers:SecureAPICall(api, questID)
    end

    _G.Nx.SetSuperTrackedUserWaypointSafe = function(enabled)
        local api = _G.C_SuperTrack and _G.C_SuperTrack.SetSuperTrackedUserWaypoint
        return TaintlessHelpers:SecureAPICall(api, enabled)
    end

    _G.Nx.ClearAllSuperTrackedSafe = function()
        local api = _G.C_SuperTrack and _G.C_SuperTrack.ClearAllSuperTracked
        return TaintlessHelpers:SecureAPICall(api)
    end

    _G.Nx.AddWorldQuestWatchSafe = function(questID, watchType)
        -- Prefer Blizzard's public Lua helper so its last-tracked bookkeeping
        -- and automatic-super-track rules stay intact. securecallfunction
        -- keeps the whole helper (including its nested C calls) on Blizzard's
        -- side of the boundary.
        local api = _G.QuestUtil and _G.QuestUtil.TrackWorldQuest
            or (_G.C_QuestLog and _G.C_QuestLog.AddWorldQuestWatch)
        return TaintlessHelpers:SecureAPICall(api, questID, watchType)
    end

    _G.Nx.RemoveWorldQuestWatchSafe = function(questID)
        local api = _G.QuestUtil and _G.QuestUtil.UntrackWorldQuest
            or (_G.C_QuestLog and _G.C_QuestLog.RemoveWorldQuestWatch)
        return TaintlessHelpers:SecureAPICall(api, questID)
    end
end

function TaintlessHelpers:ProxyCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args = { ... }
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, function() pcall(fn, unpack(args)) end)
        return
    end
    -- Fallback: schedule via Carbonite's main updater.
    local mu = Carbonite.Modules.MainUpdater
    if mu then
        mu:Subscribe(function()
            mu:Unsubscribe("Taintless.ProxyCall")
            pcall(fn, unpack(args))
        end, "Taintless.ProxyCall", 1)
    else
        pcall(fn, ...)
    end
end
