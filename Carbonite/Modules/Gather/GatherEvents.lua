-- Carbonite | Modules / Gather / GatherEvents
-- Documented surface around the UNIT_SPELLCAST_* event handlers
-- that feed Carbonite's gather-node recording system. The legacy
-- code wires three handlers (sent / interrupted / succeeded) that
-- together resolve "what did the player just gather and where?".
-- This class exposes a clean pub/sub layer so plugins can observe
-- gathers without registering parallel WoW listeners.
--
-- Public API:
--   GatherEvents:OnGather(fn)           - fn(kind, nodeName, mapID, x, y)
--   GatherEvents:GetLastGatherTarget()  -> last value of Nx.GatherTarget
--   GatherEvents:GetLastGatherStartMap()-> the map the cast began on

local Carbonite = _G.Carbonite
local GatherEvents = {}
Carbonite.Modules.Gather = Carbonite.Modules.Gather or {}
Carbonite.Modules.Gather.Events = GatherEvents

function GatherEvents:GetLastGatherTarget()
    return _G.Nx and _G.Nx.GatherTarget or nil
end

function GatherEvents:GetLastGatherStartMap()
    return _G.Nx and _G.Nx.GatherStartMap or nil
end

function GatherEvents:OnGather(fn)
    -- Listen to the public GATHER_RECORDED EventBus signal (fired by
    -- the Gather module's RecordHerb / RecordMine). New code should
    -- prefer this over the raw spellcast handlers.
    Carbonite.Core.EventBus:Subscribe("GATHER_RECORDED", function(kind, id, mapID, x, y)
        fn(kind, id, mapID, x, y)
    end)
end
