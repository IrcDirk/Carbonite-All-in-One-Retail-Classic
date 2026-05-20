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

function TaintlessHelpers:GetSandbox()
    return _G.NxTaintlessFrame
end

function TaintlessHelpers:IsAvailable()
    return self:GetSandbox() ~= nil
end

function TaintlessHelpers:ProxyCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args = { ... }
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, function() pcall(fn, table.unpack(args)) end)
        return
    end
    -- Fallback: schedule via Carbonite's main updater.
    local mu = Carbonite.Modules.MainUpdater
    if mu then
        mu:Subscribe(function()
            mu:Unsubscribe("Taintless.ProxyCall")
            pcall(fn, table.unpack(args))
        end, "Taintless.ProxyCall", 1)
    else
        pcall(fn, ...)
    end
end
