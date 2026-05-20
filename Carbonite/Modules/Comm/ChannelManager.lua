-- Carbonite | Modules / Comm / ChannelManager
-- Public surface around Nx.Com channel join / leave / count logic.
-- Carbonite uses two ad-hoc chat channels for its pal-position
-- protocol and the zone discovery system:
--   "A"  the addon channel (Crb{Y|M|B} for free/ads/standard builds)
--   "Z"  the zone channel (one per active zone the player is in)
-- This class is the canonical accessor so plugin code stops poking
-- Nx.Com.ChanAName / Nx.Com.ChanALetter / Nx.Com.ZStatus directly.
--
-- Public API:
--   ChannelManager:Join(kind)         - "A" / "Z" (or any chanId Nx.Com understands)
--   ChannelManager:Leave(kind)
--   ChannelManager:Refresh()          - re-evaluate which channels we should be in
--   ChannelManager:GetChannelCount()  - non-header channels in use
--   ChannelManager:IsInChannel(name)  - by channel name
--   ChannelManager:GetAddonChannelName()
--   ChannelManager:GetMonitoredZones()
--   ChannelManager:Each(fn)           - iterate (id, name)
--
-- The actual join / leave RPCs still run inside NxCom because they
-- depend on the legacy login throttling state machine. We delegate.

local Carbonite = _G.Carbonite

local ChannelManager = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.Channels = ChannelManager

local function com() return _G.Nx and _G.Nx.Com end

function ChannelManager:Join(kind)
    local c = com()
    if c and c.JoinChan then c:JoinChan(kind) end
    Carbonite.Core.EventBus:Fire("COMM_CHANNEL_JOIN_REQUESTED", kind)
end

function ChannelManager:Leave(kind)
    local c = com()
    if c and c.LeaveChan then c:LeaveChan(kind) end
    Carbonite.Core.EventBus:Fire("COMM_CHANNEL_LEAVE_REQUESTED", kind)
end

function ChannelManager:Refresh()
    local c = com()
    if c and c.UpdateChannels then c:UpdateChannels() end
end

function ChannelManager:GetChannelCount()
    local c = com()
    if c and c.GetChanCount then return c:GetChanCount() end
    -- Fallback inline computation matching the legacy implementation.
    if not _G.GetNumDisplayChannels then return 0 end
    local n = 0
    for i = 1, _G.GetNumDisplayChannels() do
        local _, header = _G.GetChannelDisplayInfo(i)
        if not header then n = n + 1 end
    end
    return n
end

function ChannelManager:IsInChannel(name)
    if not name or not _G.GetChannelName then return false end
    for i = 1, 10 do
        local id, n = _G.GetChannelName(i)
        if id and id > 0 and n == name then return true end
    end
    return false
end

function ChannelManager:GetAddonChannelName()
    local c = com()
    return c and c.ChanAName or nil
end

function ChannelManager:GetMonitoredZones()
    local c = com()
    return (c and c.ZMonitor) or {}
end

function ChannelManager:Each(fn)
    if not _G.GetChannelName then return end
    for i = 1, 10 do
        local id, n = _G.GetChannelName(i)
        if id and id > 0 and n then fn(id, n) end
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("channels", function()
        local log = Carbonite.Core.Logger:Get("ChannelManager")
        log:info("addon channel: %s", tostring(ChannelManager:GetAddonChannelName()))
        log:info("total in-use channels: %d", ChannelManager:GetChannelCount())
        ChannelManager:Each(function(id, name) log:info("  %d  %s", id, name) end)
    end, "summarize Carbonite addon channels")
end)
