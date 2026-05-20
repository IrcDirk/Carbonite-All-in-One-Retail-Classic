-- Carbonite | Modules / Map / MountHelper
-- Flying-mount + riding-skill detection. The legacy code split this
-- across Nx.Travel:GetRidingSkill (computes skill from spell IDs
-- on modern clients or skill lines on Classic) and
-- Nx.Travel:UpdateFlyingForCont (queries continent-specific flying
-- spells and achievement requirements). This class is the public
-- accessor so other modules can answer the user-visible question
-- "can I fly right now?" without duplicating the per-expansion
-- logic.
--
-- Public API:
--   MountHelper:GetRidingSkill()      -> 0/75/150/225/300/375
--   MountHelper:HasFlying(continent)  -> bool / spell name
--   MountHelper:IsFlyableArea()       -> bool
--   MountHelper:GetSpeed()            -> world units / second
--   MountHelper:IsSkyriding()         -> bool (the new Dragonflight
--                                       free-fly mode)
--   MountHelper:Refresh(continent)    -> recompute live state
--
-- The actual computations stay in NxTravel so the spell-ID tables
-- only live in one place; we forward.

local Carbonite = _G.Carbonite

local MountHelper = {}
Carbonite.Modules.Map.MountHelper = MountHelper

local SKYRIDING_QUEST_ID = 68795   -- "Dragonflight - Initial sky riding"

local function travel() return _G.Nx and _G.Nx.Travel end

function MountHelper:GetRidingSkill()
    local t = travel()
    if not t or not t.GetRidingSkill then return 0 end
    return t:GetRidingSkill() or 0
end

function MountHelper:IsFlyableArea()
    if _G.IsFlyableArea then return _G.IsFlyableArea() end
    return false
end

function MountHelper:HasFlying(continent)
    local t = travel()
    if continent ~= nil and t and t.UpdateFlyingForCont then
        local riding = self:GetRidingSkill()
        t:UpdateFlyingForCont(continent, riding)
    end
    return t and t.FlyingMount or false
end

function MountHelper:GetSpeed()
    local t = travel()
    return t and t.Speed or 0
end

function MountHelper:IsSkyriding()
    if not _G.C_QuestLog or not _G.C_QuestLog.IsQuestFlaggedCompleted then return false end
    return _G.C_QuestLog.IsQuestFlaggedCompleted(SKYRIDING_QUEST_ID) == true
end

function MountHelper:Refresh(continent)
    local t = travel()
    if t and t.UpdateFlyingForCont then
        t:UpdateFlyingForCont(continent, self:GetRidingSkill())
    end
    Carbonite.Core.EventBus:Fire("MOUNT_STATE_REFRESHED", continent, self:HasFlying())
end

-- Slash command: /cb mount tells the user about their mount status.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("mount", function()
        local log = Carbonite.Core.Logger:Get("MountHelper")
        log:info("riding skill : %d", MountHelper:GetRidingSkill())
        log:info("flyable area : %s", tostring(MountHelper:IsFlyableArea()))
        log:info("has flying   : %s", tostring(MountHelper:HasFlying()))
        log:info("speed        : %.3f world u/s", MountHelper:GetSpeed())
        log:info("skyriding    : %s", tostring(MountHelper:IsSkyriding()))
    end, "show mount + flying status")
end)
