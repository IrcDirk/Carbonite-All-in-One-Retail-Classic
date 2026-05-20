-- Carbonite | Modules / Comm
-- Module wrapper for addon-channel communication. Centralizes prefix
-- registration through AceComm-3.0 and exposes a clean Send/On API
-- so other modules don't have to know which AceComm/SendAddonMessage
-- variant the running client supports.
--
-- The legacy `Nx.Com` table (defined in NxCom.lua) still contains
-- the heavy protocol logic. Until that is fully ported, this module
-- delegates to it after AceComm registration.

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module

local Comm = Module:New("Comm", {
    defaults = {
        profile = {
            Comm = {
                SharePosition = true,
                ShareTarget   = false,
                LevelAnnounce = true,
            },
        },
    },
})

local PREFIX = "Crb"           -- Matches legacy Nx.Com.Name
local handlers = {}

-- Routes raw AceComm payloads through a `kind`-keyed handler table.
-- Wire-level format mirrors the existing protocol so we stay
-- interoperable with old Carbonite clients in the wild:
--   "<kind>|<payload>"
local function dispatch(prefix, msg, channel, sender)
    if prefix ~= PREFIX then return end
    local kind, rest = msg:match("^([^|]+)|(.*)$")
    if not kind then return end
    local list = handlers[kind]
    if not list then return end
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, rest, channel, sender)
        if not ok then Comm.log:error("handler %q failed: %s", kind, err) end
    end
end

function Comm:On(kind, fn)
    handlers[kind] = handlers[kind] or {}
    table.insert(handlers[kind], fn)
end

function Comm:Send(kind, payload, channel, target)
    local msg = kind .. "|" .. (payload or "")
    self:SendCommMessage(PREFIX, msg, channel or "PARTY", target)
end

function Comm:OnEnable()
    self:RegisterComm(PREFIX, function(...) dispatch(...) end)

    -- The legacy implementation registers its own AceComm prefix
    -- through Nx:RegisterComm. Re-route legacy onCommReceived into
    -- our dispatcher so old handlers keep firing.
    if Carbonite.Com and Carbonite.Com.OnReceive then
        self:On("legacy", function(payload, channel, sender)
            Carbonite.Com:OnReceive(payload, channel, sender)
        end)
    end
end
