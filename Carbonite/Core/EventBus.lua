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

function EventBus:Subscribe(event, fn)
    local owner = owners[fn]
    if not owner then
        owner = {}
        owners[fn] = owner
    end
    return rawSubscribe(owner, event, fn)
end

function EventBus:Fire(event, ...)
    self.callbacks:Fire(event, ...)
end
