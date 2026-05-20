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

function EventBus:Fire(event, ...)
    self.callbacks:Fire(event, ...)
end
