-- Carbonite | Modules / Comm / CommReceive
-- Inbound-message dispatcher. The legacy Nx.Com:OnEvent and
-- Nx.Com:OnChat_msg_channel handlers do the heavy lifting (channel
-- join/leave, pal info ingestion, position deserialization); this
-- module exposes the same routing as a clean class so other modules
-- can subscribe to specific message kinds without scanning the
-- raw addon-channel stream.
--
-- The legacy wire protocol uses a single-byte "command type" prefix
-- and routes messages to subsystem-specific handlers. This class
-- gives those handlers names + a way to attach extra listeners
-- without modifying NxCom.lua.
--
-- Public API:
--   CommReceive:OnReceive(prefix, kind, fn [, name])
--   CommReceive:OffReceive(prefix, kind [, name])
--   CommReceive:Dispatch(prefix, kind, payload, channel, sender)
--   CommReceive:GetHandlers(kind)
--
-- The set of kinds the legacy code emits today (from NxCom.lua):
--   "I"  player info packet (level / class / zone)
--   "P"  position packet (mapID + x + y)
--   "T"  target packet (current target id / name)
--   "Q"  quest packet (quest sync)
--   "K"  kill announcement
--   "L"  legacy info message for the Com log window

local Carbonite = _G.Carbonite

local CommReceive = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.Receive = CommReceive

local handlers = {}    -- kind -> { { name, fn } }

local function fire(kind, ...)
    local list = handlers[kind]
    if not list then return end
    for _, sub in ipairs(list) do
        local ok, err = pcall(sub.fn, ...)
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("CommReceive"):error("kind=%s name=%s: %s",
                kind, sub.name or "?", tostring(err))
        end
    end
end

function CommReceive:OnReceive(kind, fn, name)
    if not kind or type(fn) ~= "function" then return end
    handlers[kind] = handlers[kind] or {}
    table.insert(handlers[kind], { name = name or "anon", fn = fn })
end

function CommReceive:OffReceive(kind, name)
    local list = handlers[kind]
    if not list then return end
    if not name then handlers[kind] = nil; return end
    for i, sub in ipairs(list) do
        if sub.name == name then
            table.remove(list, i)
            if #list == 0 then handlers[kind] = nil end
            return
        end
    end
end

function CommReceive:Dispatch(kind, payload, channel, sender)
    fire(kind, payload, channel, sender, kind)
end

function CommReceive:GetHandlers(kind)
    return handlers[kind] or {}
end

-- Helper for direct legacy-bridge listening. NxCom.lua already
-- dispatches messages internally; new handlers attached through
-- this class should also fire. To keep both worlds in sync, we
-- export a "shim" the legacy code can call right after its own
-- handler runs:
--
--   Nx.Com._dispatchExt = CommReceive.Dispatch
--   ... in NxCom's OnReceive ...
--   if Nx.Com._dispatchExt then Nx.Com._dispatchExt(kind, payload, channel, sender) end
--
-- We install the function reference here; the legacy code that
-- wants to be a good citizen can opt into it.

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    local com = _G.Nx and _G.Nx.Com
    if not com then return end
    com._dispatchExt = function(...) CommReceive:Dispatch(...) end
end)
