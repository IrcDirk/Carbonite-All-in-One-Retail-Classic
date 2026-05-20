-- Carbonite | Modules / Comm / PositionShare
-- Public API around the legacy player-position broadcast protocol
-- that lives inside Nx.Com. Carbonite tracks position and a small
-- info packet (level, class, zone) for every friend / guild member
-- ("pal") and broadcasts updates on a round-robin schedule via the
-- addon channel.
--
-- This class is the canonical accessor for that data so other
-- modules (map pin rendering, raid frame integration, party
-- dashboards) can read it without reaching into Nx.Com.PalsInfo
-- directly.
--
-- Public API:
--   PositionShare:GetPals()          -> { name -> info, ... } snapshot
--   PositionShare:GetPal(name)       -> info or nil
--   PositionShare:GetPalNames()      -> sorted array of pal names
--   PositionShare:IsPal(name)        -> bool
--   PositionShare:IsEnabled()        -> bool (DB toggle)
--   PositionShare:SetEnabled(on)
--   PositionShare:GetLastSendTime()  -> GetTime() of last broadcast
--   PositionShare:GetSendIndex()     -> the round-robin cursor
--
-- An `info` table from PalsInfo looks like:
--   { MapId, X, Y, Level, Class, Race, Zone, LastUpdate, ... }
-- We don't reshape it; consumers should expect the legacy field
-- names so a future refactor of the wire format remains compatible.

local Carbonite = _G.Carbonite

local PositionShare = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.PositionShare = PositionShare

local function nxCom() return _G.Nx and _G.Nx.Com end

function PositionShare:GetPals()
    local c = nxCom()
    return c and c.PalsInfo or {}
end

function PositionShare:GetPal(name)
    if not name then return nil end
    local c = nxCom()
    return c and c.PalsInfo and c.PalsInfo[name] or nil
end

function PositionShare:IsPal(name)
    local c = nxCom()
    return c and c.PalNames and c.PalNames[name] ~= nil or false
end

function PositionShare:GetPalNames()
    local c = nxCom()
    if not c or not c.PalNames then return {} end
    local out = {}
    for name in pairs(c.PalNames) do out[#out + 1] = name end
    table.sort(out)
    return out
end

function PositionShare:IsEnabled()
    local Nx = _G.Nx
    return Nx and Nx.NetSendPos == true
end

function PositionShare:SetEnabled(on)
    local Nx = _G.Nx
    if Nx then Nx.NetSendPos = on and true or false end
    Carbonite.Core.EventBus:Fire("POSITION_SHARE_TOGGLED", on == true)
end

function PositionShare:GetLastSendTime()
    local Nx = _G.Nx
    return Nx and Nx.NetPlyrSendTime or 0
end

function PositionShare:GetSendIndex()
    local c = nxCom()
    return c and c.PosSendNext or 0
end

-- Force-broadcast the player's position right now, ignoring the
-- normal round-robin schedule. Useful when the user wants the map
-- pin update visible to their group immediately (e.g. after a
-- teleport).
function PositionShare:ForceBroadcast()
    local c = nxCom()
    if not c then return end
    -- The legacy update loop branches on PosSendNext < 0 to fire an
    -- "info" packet on the next tick; set it so the next OnUpdate
    -- handles the send. Behavior matches the legacy bootstrap path
    -- after a fresh PALS_LIST refresh.
    c.PosSendNext = -2
end

-- Debug snapshot for `/cb pals`.
function PositionShare:Snapshot()
    local out = {}
    for name, info in pairs(self:GetPals()) do
        out[name] = {
            mapID = info.MapId or info.mapID,
            x = info.X or info.x,
            y = info.Y or info.y,
            level = info.Level or info.level,
            zone = info.Zone or info.zone,
            lastUpdate = info.LastUpdate or info.lastUpdate,
        }
    end
    return out
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("pals", function()
        local log = Carbonite.Core.Logger:Get("PositionShare")
        local snap = PositionShare:Snapshot()
        local n = 0
        for name, info in pairs(snap) do
            n = n + 1
            log:info("%-20s lvl=%s zone=%s pos=%.2f,%.2f",
                name, tostring(info.level or "?"),
                tostring(info.zone or "?"),
                info.x or 0, info.y or 0)
        end
        log:info("total pals tracked: %d", n)
    end, "list tracked friend/guild positions")
end)
