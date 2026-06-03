-- Carbonite | Modules / PlayerSpec
-- Player specialization tracking. Spans the WotLK dual-spec era
-- (GetActiveTalentGroup) through modern specialization
-- (GetSpecialization) so callers don't have to branch by client.
--
-- Public API:
--   PlayerSpec:GetActiveSpecID()      -> int (modern Spec ID, or 0)
--   PlayerSpec:GetActiveTalentGroup() -> 1 / 2 (legacy dual-spec)
--   PlayerSpec:GetSpecName()
--   PlayerSpec:GetSpecRole()          -> "DAMAGER" / "TANK" / "HEALER" / nil
--   PlayerSpec:OnChanged(fn)

local Carbonite = _G.Carbonite
local PlayerSpec = {}
Carbonite.Modules.PlayerSpec = PlayerSpec

function PlayerSpec:GetActiveSpecID()
    if _G.GetSpecialization then return _G.GetSpecialization() or 0 end
    return 0
end

function PlayerSpec:GetActiveTalentGroup()
    if _G.GetActiveTalentGroup then return _G.GetActiveTalentGroup() or 1 end
    return 1
end

function PlayerSpec:GetSpecName()
    local id = self:GetActiveSpecID()
    if not id or id == 0 then return nil end
    if _G.GetSpecializationInfo then
        local _, name = _G.GetSpecializationInfo(id)
        return name
    end
end

function PlayerSpec:GetSpecRole()
    local id = self:GetActiveSpecID()
    if not id or id == 0 then return nil end
    if _G.GetSpecializationInfo then
        local _, _, _, _, role = _G.GetSpecializationInfo(id)
        return role
    end
end

function PlayerSpec:OnChanged(fn)
    if type(fn) == "function" then
        Carbonite.Core.EventBus:Subscribe("PLAYER_SPEC_CHANGED", fn)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbPlayerSpec")
    -- pcall per event: which spec events exist depends on the flavor/client,
    -- not a fixed expansion (e.g. TBC on the modern engine does expose specs).
    -- RegisterEvent throws "unknown event" wherever a given one is absent, so
    -- guard each independently -- keep whatever the client supports, skip the
    -- rest. The getters already degrade to 0/1 when the spec APIs are missing.
    pcall(f.RegisterEvent, f, "ACTIVE_TALENT_GROUP_CHANGED")
    pcall(f.RegisterEvent, f, "PLAYER_SPECIALIZATION_CHANGED")
    f:SetScript("OnEvent", function()
        Carbonite.Core.EventBus:Fire("PLAYER_SPEC_CHANGED",
            PlayerSpec:GetActiveSpecID(),
            PlayerSpec:GetSpecName(),
            PlayerSpec:GetSpecRole())
    end)
end)
