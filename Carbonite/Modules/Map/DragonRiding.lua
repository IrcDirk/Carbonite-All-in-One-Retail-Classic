-- Carbonite | Modules / Map / DragonRiding
-- Detects whether the player currently has Dragonflight skyriding
-- unlocked. The Skyriding feature is gated by completing the
-- introductory quest (Blizzard quest ID 68795). This class
-- centralizes the check + adds a /cb skyriding diagnostic slash.
--
-- Public API:
--   DragonRiding:IsUnlocked()
--   DragonRiding:GetIntroQuestID()
--   DragonRiding:GetSpeedMultiplier()  -- legacy Travel.Speed

local Carbonite = _G.Carbonite
local DragonRiding = {}
Carbonite.Modules.Map.DragonRiding = DragonRiding

DragonRiding.INTRO_QUEST_ID = 68795

function DragonRiding:GetIntroQuestID() return self.INTRO_QUEST_ID end

function DragonRiding:IsUnlocked()
    if not _G.C_QuestLog or not _G.C_QuestLog.IsQuestFlaggedCompleted then return false end
    return _G.C_QuestLog.IsQuestFlaggedCompleted(self.INTRO_QUEST_ID) == true
end

function DragonRiding:GetSpeedMultiplier()
    local t = _G.Nx and _G.Nx.Travel
    return t and t.Speed or 0
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("skyriding", function()
        local log = Carbonite.Core.Logger:Get("DragonRiding")
        log:info("Skyriding: %s", DragonRiding:IsUnlocked() and "unlocked" or "locked")
        log:info("intro quest %d", DragonRiding:GetIntroQuestID())
    end, "show skyriding unlock status")
end)
