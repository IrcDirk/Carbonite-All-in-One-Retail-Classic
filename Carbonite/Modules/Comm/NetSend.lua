-- Carbonite | Modules / Comm / NetSend
-- The position-broadcast loop. The legacy Nx:NXOnUpdate ticks the
-- Nx.NetSendPos flag + Nx.NetPlyrSendTime throttle every frame and
-- shapes a "Map~px~py~mapID" payload onto Nx.Com:Send("Z", ...).
-- This class is the public accessor + lets other code tune the
-- broadcast cadence.
--
-- Public API:
--   NetSend:IsEnabled()
--   NetSend:Enable(on)
--   NetSend:GetInterval()             -> seconds between sends
--   NetSend:SetInterval(seconds)
--   NetSend:BroadcastNow()            -- force a send next tick
--   NetSend:GetLastSendTime()         -> GetTime() of the last send

local Carbonite = _G.Carbonite
local NetSend = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.NetSend = NetSend

NetSend.DEFAULT_INTERVAL = 1.5     -- seconds between broadcasts

function NetSend:IsEnabled()
    return _G.Nx and _G.Nx.NetSendPos == true
end

function NetSend:Enable(on)
    if _G.Nx then _G.Nx.NetSendPos = on and true or false end
    Carbonite.Core.EventBus:Fire("NET_SEND_TOGGLED", on == true)
end

function NetSend:GetInterval()
    return self._interval or self.DEFAULT_INTERVAL
end

function NetSend:SetInterval(seconds)
    if not seconds or seconds <= 0 then return end
    self._interval = seconds
end

function NetSend:BroadcastNow()
    if _G.Nx then _G.Nx.NetPlyrSendTime = 0 end
end

function NetSend:GetLastSendTime()
    return _G.Nx and _G.Nx.NetPlyrSendTime or 0
end
