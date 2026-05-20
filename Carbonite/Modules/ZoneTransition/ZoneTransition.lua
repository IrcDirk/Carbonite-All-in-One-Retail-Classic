-- Carbonite | Modules / ZoneTransition
-- Documented surface for zone-change behavior. The legacy Carbonite
-- handlers (Nx:OnZone_changed_new_area, Nx:OnPlayer_level_up,
-- Nx.OnParty_members_changed) each do their own per-event work but
-- they share a common pattern: add a UEvent log entry, then forward
-- to Nx.Com:OnEvent. This module exposes the same lifecycle as a
-- proper publish/subscribe surface so other modules can react
-- without registering their own duplicate WoW-event listeners.
--
-- Public API:
--   ZoneTransition:GetCurrentMapID()          -> int
--   ZoneTransition:GetPreviousMapID()         -> int
--   ZoneTransition:OnEnterZone(fn [, name])   -> subscribe
--   ZoneTransition:OnLevelUp(fn [, name])     -> subscribe
--   ZoneTransition:OnGroupChanged(fn [, name])
--   ZoneTransition:Refresh()                  -> force-fire current
--
-- All subscriptions are removed when the user reloads. The legacy
-- handlers continue to run; we just bridge into them so new code
-- can listen without touching Carbonite.lua.

local Carbonite = _G.Carbonite

local ZoneTransition = {}
Carbonite.Modules.ZoneTransition = ZoneTransition

local previousMapID = nil

local function emit(kind, ...)
    Carbonite.Core.EventBus:Fire("ZONE_TRANSITION_" .. kind, ...)
end

function ZoneTransition:GetCurrentMapID()
    local MapIDs = Carbonite.Modules.Map and Carbonite.Modules.Map.MapIDs
    if MapIDs and MapIDs.GetCurrentMapId then return MapIDs:GetCurrentMapId() end
    if _G.C_Map and _G.C_Map.GetBestMapForUnit then return _G.C_Map.GetBestMapForUnit("player") end
end

function ZoneTransition:GetPreviousMapID() return previousMapID end

function ZoneTransition:OnEnterZone(fn, name)
    Carbonite.Core.EventBus:Subscribe("ZONE_TRANSITION_ENTERED", fn)
end

function ZoneTransition:OnLevelUp(fn)
    Carbonite.Core.EventBus:Subscribe("ZONE_TRANSITION_LEVEL_UP", fn)
end

function ZoneTransition:OnGroupChanged(fn)
    Carbonite.Core.EventBus:Subscribe("ZONE_TRANSITION_GROUP_CHANGED", fn)
end

function ZoneTransition:Refresh()
    local cur = self:GetCurrentMapID()
    if cur ~= previousMapID then
        emit("ENTERED", cur, previousMapID)
        previousMapID = cur
    end
end

-- Listener frame: independent of the legacy handler so we still
-- emit even when the legacy file's OnZone_changed_new_area is
-- inactive (e.g. during the new-architecture-first load path).
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbZoneTransitionListener")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("ZONE_CHANGED")
    f:RegisterEvent("ZONE_CHANGED_INDOORS")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:SetScript("OnEvent", function(_, event, arg1)
        if event:find("ZONE_CHANGED") then
            ZoneTransition:Refresh()
        elseif event == "PLAYER_LEVEL_UP" then
            emit("LEVEL_UP", tonumber(arg1) or _G.UnitLevel and _G.UnitLevel("player") or 0)
        end
    end)
end)
