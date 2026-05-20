-- Carbonite | Modules / PartyState
-- Public surface around IsInGroup / IsInRaid + group-type tracking.
-- Distinct from GroupMembers (which caches names) and PositionShare
-- (which broadcasts coords); this is the simple "am I in a party,
-- raid, or solo" answer.
--
-- Public API:
--   PartyState:IsSolo()
--   PartyState:IsInParty()
--   PartyState:IsInRaid()
--   PartyState:GetGroupSize()        -> int
--   PartyState:GetGroupType()        -> "solo"/"party"/"raid"
--   PartyState:OnChanged(fn)         - fired when type changes

local Carbonite = _G.Carbonite
local PartyState = {}
Carbonite.Modules.PartyState = PartyState

local lastType = "solo"

function PartyState:IsSolo()
    if _G.IsInGroup then return not _G.IsInGroup() end
    return true
end

function PartyState:IsInParty()
    if _G.IsInGroup then return _G.IsInGroup() and not (_G.IsInRaid and _G.IsInRaid()) end
    return false
end

function PartyState:IsInRaid()
    return _G.IsInRaid and _G.IsInRaid() or false
end

function PartyState:GetGroupSize()
    if _G.GetNumGroupMembers then return _G.GetNumGroupMembers() or 0 end
    return 0
end

function PartyState:GetGroupType()
    if self:IsInRaid() then return "raid" end
    if self:IsInParty() then return "party" end
    return "solo"
end

function PartyState:OnChanged(fn)
    if type(fn) == "function" then
        Carbonite.Core.EventBus:Subscribe("PARTY_STATE_CHANGED", fn)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    lastType = PartyState:GetGroupType()
    local f = CreateFrame("Frame", "CarbPartyState")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        local now = PartyState:GetGroupType()
        if now ~= lastType then
            local prev = lastType
            lastType = now
            Carbonite.Core.EventBus:Fire("PARTY_STATE_CHANGED", now, prev)
        end
    end)
end)
