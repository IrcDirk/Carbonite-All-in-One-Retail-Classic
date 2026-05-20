-- Carbonite | Modules / EventDispatcher
-- Owns the top-level event-routing layer. The legacy
-- Nx:NXOnEvent reads a single self.Events table that the
-- RegisterEvent / Nx:Set... helpers populate. This class exposes
-- the routing as a public API so modules can subscribe / unsubscribe
-- without touching the legacy `self.Events` table directly.
--
--   EventDispatcher:Register(event, handler [, name])
--   EventDispatcher:Unregister(event [, name])
--   EventDispatcher:Dispatch(event, ...)
--   EventDispatcher:GetHandlers(event)
--   EventDispatcher:IsBound(event)
--
-- The legacy Nx:NXOnEvent stays as the actual handler for the
-- addon's frame.OnEvent script. We hook into the same `Nx.Events`
-- map so events the legacy code already binds still fire on the
-- legacy handler. New code can register additional handlers for
-- the same event - this class keeps a per-event handler list so
-- multiple modules can listen without stomping each other.

local Carbonite = _G.Carbonite

local EventDispatcher = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.EventDispatcher = EventDispatcher

-- Our extension layer: event -> { { name=, fn= }, ... }
local extensions = {}
local frame                       -- private listener frame

local function bindFrameTo(event)
    if not frame then return end
    pcall(frame.RegisterEvent, frame, event)
end

local function fireExtensions(event, ...)
    local list = extensions[event]
    if not list then return end
    for _, sub in ipairs(list) do
        local ok, err = pcall(sub.fn, event, ...)
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("EventDispatcher"):error("%s/%s: %s", event, sub.name or "?", err)
        end
    end
end

function EventDispatcher:Register(event, handler, name)
    if not event or type(handler) ~= "function" then return end
    extensions[event] = extensions[event] or {}
    table.insert(extensions[event], { name = name or "anon", fn = handler })
    bindFrameTo(event)
end

function EventDispatcher:Unregister(event, name)
    local list = extensions[event]
    if not list then return end
    if not name then
        extensions[event] = nil
        return
    end
    for i, sub in ipairs(list) do
        if sub.name == name then
            table.remove(list, i)
            if #list == 0 then extensions[event] = nil end
            return
        end
    end
end

function EventDispatcher:GetHandlers(event)
    return extensions[event] or {}
end

function EventDispatcher:IsBound(event)
    return extensions[event] ~= nil
end

-- Forward a dispatch into our extension table. Other code (e.g.
-- the legacy NXOnEvent) can call this on every event so our
-- extension handlers run in sync.
function EventDispatcher:Dispatch(event, ...)
    fireExtensions(event, ...)
end

-- Bind to PLAYER_LOGIN through our own frame so we can extend events
-- the legacy code didn't register. Our frame is independent so we
-- never disturb Nx's frame.OnEvent contract.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if frame then return end
    frame = CreateFrame("Frame", "CarbEventDispatcher")
    for event in pairs(extensions) do bindFrameTo(event) end
    frame:SetScript("OnEvent", function(_, event, ...) fireExtensions(event, ...) end)
end)
