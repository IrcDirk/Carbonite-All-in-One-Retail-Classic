-- Carbonite | Core / EventBus
-- Thin pub/sub layer on top of CallbackHandler-1.0. Used for
-- in-addon events such as "MAP_VIEW_OPENED", "QUEST_TRACKED_CHANGED"
-- so modules can talk to each other without holding direct refs.
-- For actual WoW game events keep using AceEvent-3.0 / RegisterEvent.

local Carbonite = _G.Carbonite
local CallbackHandler = LibStub("CallbackHandler-1.0")

local EventBus = {}
Carbonite.Core.EventBus = EventBus

EventBus.callbacks = CallbackHandler:New(EventBus, "Subscribe", "Unsubscribe", "UnsubscribeAll")

-- CallbackHandler keys subscriptions by (event, self). When callers
-- use the convenient `EventBus:Subscribe(event, fn)` colon form, self
-- is always EventBus, so every subscriber to a given event clobbers
-- the previous one and only the last file to load actually receives
-- the dispatch. Wrap Subscribe so each call gets a unique owner
-- table; we cache by fn so a second Subscribe with the same fn is a
-- no-op (idempotent), which is the behaviour callers expect anyway.
local rawSubscribe = EventBus.Subscribe
local owners = setmetatable({}, { __mode = "k" })   -- weak keys: GC the fn → owner mapping if fn dies

-- CallbackHandler dispatches subscribers unprotected, so the first one that
-- errors aborts the rest of the chain for that event. On CARBONITE_ENABLE that
-- is fatal by design: SlashCommands:Init() (which creates /cb) and every module
-- registration behind it simply never run, and the addon looks half-dead with
-- no hint as to why. Wrap each subscriber so a failure is reported and
-- contained instead of taking its siblings down.
local wrapped = setmetatable({}, { __mode = "k" })

function EventBus:Subscribe(event, fn)
    local owner = owners[fn]
    if not owner then
        owner = {}
        owners[fn] = owner
    end

    local safe = wrapped[fn]
    if not safe then
        safe = function(...)
            local ok, err = pcall(fn, ...)
            if not ok then
                local Logger = Carbonite.Core and Carbonite.Core.Logger
                if Logger then
                    Logger:Get("EventBus"):error("%s subscriber failed: %s",
                        tostring(event), tostring(err))
                end
            end
        end
        wrapped[fn] = safe
    end

    return rawSubscribe(owner, event, safe)
end

-- Unsubscribe takes the original function, so translate it back to the wrapper
-- CallbackHandler actually holds.
local rawUnsubscribe = EventBus.Unsubscribe

function EventBus:Unsubscribe(event, fn)
    local owner = fn and owners[fn]
    local safe = fn and wrapped[fn]
    if owner and safe then
        return rawUnsubscribe(owner, event)
    end
    return rawUnsubscribe(self, event)
end

function EventBus:Fire(event, ...)
    self.callbacks:Fire(event, ...)
end
