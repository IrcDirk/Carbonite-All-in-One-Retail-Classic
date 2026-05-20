-- Carbonite | Modules / AchievementHelper
-- GetAchievementInfo + criteria wrappers. Carbonite uses these for
-- zone-achievement queries on the world map (Loremaster, Explorer
-- subzones). This class is the canonical accessor so other modules
-- don't need to know the 12-tuple return shape.
--
-- Public API:
--   AchievementHelper:GetInfo(id)
--     -> { id, name, points, completed, month, day, year, description, ... }
--   AchievementHelper:GetCriteria(id, index)
--   AchievementHelper:IsCompleted(id)
--   AchievementHelper:GetCriteriaCount(id)

local Carbonite = _G.Carbonite
local AchievementHelper = {}
Carbonite.Modules.AchievementHelper = AchievementHelper

function AchievementHelper:GetInfo(id)
    if not id or not _G.GetAchievementInfo then return nil end
    local id_, name, points, completed, month, day, year, description,
          flags, icon, rewardText, wasEarnedByMe, earnedBy =
        _G.GetAchievementInfo(id)
    if not name then return nil end
    return {
        id = id_, name = name, points = points, completed = completed,
        month = month, day = day, year = year, description = description,
        flags = flags, icon = icon, rewardText = rewardText,
        wasEarnedByMe = wasEarnedByMe, earnedBy = earnedBy,
    }
end

function AchievementHelper:IsCompleted(id)
    local info = self:GetInfo(id)
    return info and info.completed or false
end

function AchievementHelper:GetCriteriaCount(id)
    if not _G.GetAchievementNumCriteria then return 0 end
    return _G.GetAchievementNumCriteria(id) or 0
end

function AchievementHelper:GetCriteria(id, index)
    if not id or not index or not _G.GetAchievementCriteriaInfo then return nil end
    local desc, _, completed, quantity, total = _G.GetAchievementCriteriaInfo(id, index)
    return {
        description = desc, completed = completed,
        quantity = quantity, total = total,
    }
end
