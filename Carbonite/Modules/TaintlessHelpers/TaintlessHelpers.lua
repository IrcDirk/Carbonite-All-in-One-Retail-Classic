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

local function CallBlizzardAPI(api, ...)
    if type(api) ~= "function" then
        return false
    end
    if securecallfunction then
        securecallfunction(api, ...)
    else
        api(...)
    end
    return true
end

local function RunNowOrAfterCombat(fn)
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        local CL = Carbonite.Modules.CombatLockdown
        if CL then
            CL:RunWhenSafe(fn)
            return
        end
    end
    fn()
end

function TaintlessHelpers:SecureAPICall(api, ...)
    if type(api) ~= "function" then
        return false
    end
    local args = { ... }
    RunNowOrAfterCombat(function()
        CallBlizzardAPI(api, unpack(args))
    end)
    return true
end

function TaintlessHelpers:SuperTrackCall(fn)
    if type(fn) ~= "function" then return end
    RunNowOrAfterCombat(fn)
end

if _G.Nx then
    _G.Nx.SuperTrackSafe = function(fn) TaintlessHelpers:SuperTrackCall(fn) end

    local function superTrackAPI(name)
        local st = _G.C_SuperTrack
        local fn = st and st[name]
        return type(fn) == "function" and fn or nil
    end

    local function questLogAPI(name)
        local ql = _G.C_QuestLog
        local fn = ql and ql[name]
        return type(fn) == "function" and fn or nil
    end

    _G.Nx.SetSuperTrackedQuestIDSafe = function(questID)
        local api = superTrackAPI("SetSuperTrackedQuestID")
        if not api then return false end
        questID = questID or 0
        RunNowOrAfterCombat(function()
            local get = superTrackAPI("GetSuperTrackedQuestID")
            if get and (get() or 0) == questID then return end
            CallBlizzardAPI(api, questID)
        end)
        return true
    end

    _G.Nx.SetSuperTrackedUserWaypointSafe = function(enabled)
        local api = superTrackAPI("SetSuperTrackedUserWaypoint")
        if not api then return false end
        enabled = enabled and true or false
        RunNowOrAfterCombat(function()
            local get = superTrackAPI("IsSuperTrackingUserWaypoint")
            if get and (get() and true or false) == enabled then return end
            CallBlizzardAPI(api, enabled)
        end)
        return true
    end

    _G.Nx.ClearAllSuperTrackedSafe = function()
        local api = superTrackAPI("ClearAllSuperTracked")
        if not api then return false end
        RunNowOrAfterCombat(function()
            local anything = superTrackAPI("IsSuperTrackingAnything")
            if anything and not anything() then return end
            CallBlizzardAPI(api)
        end)
        return true
    end

    _G.Nx.ClearNonQuestSuperTrackSafe = function()
        local api = superTrackAPI("ClearAllSuperTracked")
        if not api then return false end
        RunNowOrAfterCombat(function()
            local anything = superTrackAPI("IsSuperTrackingAnything")
            if anything and not anything() then return end
            local quest = superTrackAPI("IsSuperTrackingQuest")
            if quest and quest() then return end
            CallBlizzardAPI(api)
        end)
        return true
    end

    _G.Nx.AddWorldQuestWatchSafe = function(questID, watchType)
        local util = _G.QuestUtil
        local api = (util and type(util.TrackWorldQuest) == "function" and util.TrackWorldQuest)
            or questLogAPI("AddWorldQuestWatch")
        if not api then return false end
        RunNowOrAfterCombat(function()
            local get = questLogAPI("GetQuestWatchType")
            if get then
                local cur = get(questID)
                if cur ~= nil and (watchType == nil or cur == watchType) then return end
            end
            CallBlizzardAPI(api, questID, watchType)
        end)
        return true
    end

    _G.Nx.RemoveWorldQuestWatchSafe = function(questID)
        local util = _G.QuestUtil
        local api = (util and type(util.UntrackWorldQuest) == "function" and util.UntrackWorldQuest)
            or questLogAPI("RemoveWorldQuestWatch")
        if not api then return false end
        RunNowOrAfterCombat(function()
            local get = questLogAPI("GetQuestWatchType")
            if get and get(questID) == nil then return end
            CallBlizzardAPI(api, questID)
        end)
        return true
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
