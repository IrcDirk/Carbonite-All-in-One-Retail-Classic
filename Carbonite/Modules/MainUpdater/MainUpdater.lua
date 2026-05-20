-- Carbonite | Modules / MainUpdater
-- The per-frame pump. The legacy Nx:NXOnUpdate dispatches every
-- per-tick subsystem: Nx.Proc, tooltip scan, owned-tooltip release,
-- net position broadcast, combat-state queries, and a dozen smaller
-- hooks. The Tick counter (Nx.Tick) is what every "do this every
-- Nth frame" check reads.
--
-- We can't safely move the actual per-frame body out of NxOnUpdate
-- because it interleaves with the legacy init state machine and
-- combat-protected operations. Instead, this class exposes a
-- subscription registry so modules can add their own tick handlers
-- without modifying NxOnUpdate.
--
-- Public API:
--   MainUpdater:Subscribe(fn, name [, interval])
--                                 - fn(elapsed, tick) called every
--                                   `interval` frames (default 1)
--   MainUpdater:Unsubscribe(name)
--   MainUpdater:GetTick()         -> current Nx.Tick counter
--   MainUpdater:OnTick(elapsed)   - dispatcher called by NxOnUpdate
--   MainUpdater:RegisterPostHook(fn, name)
--                                 - one-shot per-frame post-update
--                                   hook (no interval semantics)

local Carbonite = _G.Carbonite

local MainUpdater = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.MainUpdater = MainUpdater

local subs = {}        -- list of { fn, name, interval, counter }
local postHooks = {}   -- list of { fn, name }

local function fireAll(list, elapsed)
    for i = 1, #list do
        local s = list[i]
        local ok, err = pcall(s.fn, elapsed, MainUpdater:GetTick())
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("MainUpdater"):error("%s: %s", s.name or "?", err)
        end
    end
end

function MainUpdater:GetTick()
    return (_G.Nx and _G.Nx.Tick) or 0
end

function MainUpdater:Subscribe(fn, name, interval)
    if type(fn) ~= "function" then return end
    interval = interval or 1
    if interval < 1 then interval = 1 end
    subs[#subs + 1] = { fn = fn, name = name or "anon", interval = interval, counter = 0 }
end

function MainUpdater:Unsubscribe(name)
    if not name then return end
    for i = #subs, 1, -1 do if subs[i].name == name then table.remove(subs, i) end end
end

function MainUpdater:RegisterPostHook(fn, name)
    if type(fn) ~= "function" then return end
    postHooks[#postHooks + 1] = { fn = fn, name = name or "anon" }
end

-- Called by the legacy NxOnUpdate or by our own listener frame.
-- Dispatches to every subscriber whose tick counter has reached
-- its `interval`.
function MainUpdater:OnTick(elapsed)
    local ready = {}
    for _, s in ipairs(subs) do
        s.counter = s.counter + 1
        if s.counter >= s.interval then
            s.counter = 0
            ready[#ready + 1] = s
        end
    end
    if #ready > 0 then fireAll(ready, elapsed) end
    if #postHooks > 0 then fireAll(postHooks, elapsed) end
end

-- Stand-alone listener frame in case the legacy NxOnUpdate isn't
-- driving us yet (e.g. we're loaded ahead of the legacy file in
-- some upgrade scenarios). Lifecycle: bind on CARBONITE_ENABLE.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbMainUpdaterDriver")
    f:SetScript("OnUpdate", function(_, elapsed)
        -- Skip if the legacy NxOnUpdate exists - it'll drive us via
        -- the rewire installed below. We only fire if nothing else is.
        if MainUpdater._drivenByLegacy then return end
        MainUpdater:OnTick(elapsed or 0)
    end)
    MainUpdater._driverFrame = f
end)

-- Bridge: if the legacy NxOnUpdate is present, install a post-call
-- hook so each frame ends in MainUpdater:OnTick. This avoids
-- duplicating ticks while still firing our subscribers in the same
-- frame the legacy code finishes its work in.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    local Nx = _G.Nx
    if not Nx or not Nx.NXOnUpdate then return end
    local original = Nx.NXOnUpdate
    Nx.NXOnUpdate = function(self_, elapsed)
        original(self_, elapsed)
        MainUpdater._drivenByLegacy = true
        MainUpdater:OnTick(elapsed or 0)
    end
end)
