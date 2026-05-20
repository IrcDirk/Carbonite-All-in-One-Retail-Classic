-- Carbonite | Modules / Map / TaxiCapture
-- The flight-master capture system that lives inside NxTravel.lua.
-- When the user opens a flight-master window, Carbonite records
-- which nodes are reachable so the routing graph can later quote
-- accurate "you can fly here" answers. This class exposes that
-- subsystem with a clean API and lets other modules read the
-- captured data without poking Nx.db.char.Travel.Taxi.Taxi.
--
-- Public API:
--   TaxiCapture:Capture()                 - scan the open taxi map now
--   TaxiCapture:IsKnown(nodeName)         - bool from current char's data
--   TaxiCapture:GetCurrentNode()          - last "CURRENT" node name
--   TaxiCapture:CalcTime(destIndex)       - seconds to that destination
--   TaxiCapture:Each(fn)                  - iterate { name, reachable }
--   TaxiCapture:GetKnownNodes()           - sorted array of reachable names
--
-- The actual capture is performed by Nx.Travel:CaptureTaxi so the
-- saved-variable layout matches; we just delegate.

local Carbonite = _G.Carbonite

local TaxiCapture = {}
Carbonite.Modules.Map.TaxiCapture = TaxiCapture

local function travel() return _G.Nx and _G.Nx.Travel end
local function taxiTable()
    local Nx = _G.Nx
    return Nx and Nx.db and Nx.db.char and Nx.db.char.Travel and Nx.db.char.Travel.Taxi and Nx.db.char.Travel.Taxi.Taxi
end

function TaxiCapture:Capture()
    local t = travel()
    if t and t.CaptureTaxi then t:CaptureTaxi() end
    Carbonite.Core.EventBus:Fire("TAXI_CAPTURED", self:GetCurrentNode())
end

function TaxiCapture:IsKnown(nodeName)
    local tt = taxiTable()
    return tt and tt[nodeName] == true or false
end

function TaxiCapture:GetCurrentNode()
    local t = travel()
    return t and t.TaxiNameStart or nil
end

function TaxiCapture:CalcTime(destIndex)
    local t = travel()
    if not t or not t.TaxiCalcTime then return 0 end
    return t:TaxiCalcTime(destIndex) or 0
end

function TaxiCapture:Each(fn)
    local tt = taxiTable() or {}
    for name, reachable in pairs(tt) do fn(name, reachable == true) end
end

function TaxiCapture:GetKnownNodes()
    local out = {}
    self:Each(function(name, reachable) if reachable then out[#out + 1] = name end end)
    table.sort(out)
    return out
end

function TaxiCapture:CountKnown()
    local n = 0
    self:Each(function(_, reachable) if reachable then n = n + 1 end end)
    return n
end

-- Slash command for diagnostics.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("taxi", function()
        local log = Carbonite.Core.Logger:Get("TaxiCapture")
        log:info("current node: %s", tostring(TaxiCapture:GetCurrentNode()))
        log:info("known nodes:  %d", TaxiCapture:CountKnown())
    end, "summarize captured flight-master nodes")
end)
