-- Carbonite | Modules / CombatLockdown
-- Defer combat-protected operations until lockdown lifts. The
-- legacy code does this inline with `if not InCombatLockdown()`
-- branches and a `Nx.CombatMessage` flag; this class centralizes
-- the pattern so callers can hand any function over and forget
-- about whether they're in combat right now.
--
-- Public API:
--   CombatLockdown:IsActive()
--   CombatLockdown:RunWhenSafe(fn, ...)
--     Calls fn(...) immediately if out of combat; otherwise queues
--     it for the PLAYER_REGEN_ENABLED event.
--   CombatLockdown:OnEnter(fn)         - subscribe to combat start
--   CombatLockdown:OnExit(fn)          - subscribe to combat end

local Carbonite = _G.Carbonite

local CombatLockdown = {}
Carbonite.Modules.CombatLockdown = CombatLockdown

local queued = {}        -- pending { fn, args }
local enterSubs, exitSubs = {}, {}

function CombatLockdown:IsActive()
    return _G.InCombatLockdown and _G.InCombatLockdown() or false
end

function CombatLockdown:RunWhenSafe(fn, ...)
    if type(fn) ~= "function" then return end
    if not self:IsActive() then
        pcall(fn, ...)
        return
    end
    queued[#queued + 1] = { fn = fn, args = { ... } }
end

function CombatLockdown:OnEnter(fn)
    if type(fn) == "function" then enterSubs[#enterSubs + 1] = fn end
end

function CombatLockdown:OnExit(fn)
    if type(fn) == "function" then exitSubs[#exitSubs + 1] = fn end
end

local function fireAll(list)
    for _, fn in ipairs(list) do pcall(fn) end
end

local function flushQueue()
    local snap = queued
    queued = {}
    for _, item in ipairs(snap) do
        pcall(item.fn, table.unpack(item.args or {}))
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbCombatLockdownListener")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            Carbonite.Core.EventBus:Fire("COMBAT_ENTERED")
            fireAll(enterSubs)
        else
            flushQueue()
            Carbonite.Core.EventBus:Fire("COMBAT_LEFT")
            fireAll(exitSubs)
        end
    end)
end)
