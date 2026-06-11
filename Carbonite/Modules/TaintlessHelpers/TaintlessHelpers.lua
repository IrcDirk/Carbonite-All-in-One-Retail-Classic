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

function TaintlessHelpers:GetSandbox()
    return _G.NxTaintlessFrame
end

function TaintlessHelpers:IsAvailable()
    return self:GetSandbox() ~= nil
end

-- Combat-safe wrapper for C_SuperTrack mutations
-- (SetSuperTrackedQuestID / ClearAllSuperTracked / ...). Calling
-- these from insecure code fires SUPER_TRACKING_CHANGED
-- synchronously in OUR taint context; Blizzard's
-- QuestDataProvider listener then reaches
-- pin:SetPassThroughButtons() (MapCanvas AcquirePin →
-- CheckMouseButtonPassthrough), which is protected during combat
-- lockdown → ADDON_ACTION_BLOCKED blaming Carbonite. Surfaces
-- whenever a quest-pin map (WorldMap / FlightMap) is visible while
-- the player is in combat. Out of combat the tainted chain is
-- permitted, so run synchronously to keep click-toggle ordering;
-- in combat defer to PLAYER_REGEN_ENABLED via CombatLockdown.
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
