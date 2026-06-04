-- Carbonite.Quests | QuestWatchSurface
-- Documented surface around Nx.Quest.Watch. The legacy code drives
-- the watch list as a complex stateful object with Set / ClearAuto
-- / Update etc.; this class is the public accessor so other code
-- can ask "is this quest tracked?" or trigger track/untrack
-- without touching internal Watch state.
--
-- Public API:
--   QuestWatchSurface:IsTracked(questID)
--   QuestWatchSurface:Track(questID)
--   QuestWatchSurface:Untrack(questID)
--   QuestWatchSurface:ToggleTracker()
--   QuestWatchSurface:IsTrackerShown()
--   QuestWatchSurface:ClearAutoTarget()
--   QuestWatchSurface:Refresh()

local Carbonite = _G.Carbonite
if not Carbonite then return end

local QuestWatchSurface = {}
Carbonite.Quests = Carbonite.Quests or {}
Carbonite.Quests.WatchSurface = QuestWatchSurface

local function watch()
    local Nx = _G.Nx
    return Nx and Nx.Quest and Nx.Quest.Watch
end

function QuestWatchSurface:IsTracked(questID)
    local Quest = _G.Nx and _G.Nx.Quest
    if not Quest or not Quest.IsTargeted then return false end
    return Quest:IsTargeted(questID, 0) == true
end

function QuestWatchSurface:Track(questID)
    local Quest = _G.Nx and _G.Nx.Quest
    if Quest and Quest.SetActiveCarboniteQuest then
        local logIdx = _G.GetQuestLogIndexByID and _G.GetQuestLogIndexByID(questID) or 0
        Quest:SetActiveCarboniteQuest(questID, logIdx)
    end
    if _G.C_SuperTrack and _G.C_SuperTrack.SetSuperTrackedQuestID then
        -- Combat-defer: insecure super-track mutations fire
        -- SUPER_TRACKING_CHANGED in our taint and trip the protected
        -- SetPassThroughButtons in Blizzard's QuestDataProvider.
        _G.Nx.SuperTrackSafe(function()
            _G.C_SuperTrack.SetSuperTrackedQuestID(questID)
        end)
    end
end

function QuestWatchSurface:Untrack(questID)
    if _G.C_SuperTrack and _G.C_SuperTrack.SetSuperTrackedQuestID then
        -- Combat-defer (see Track above).
        _G.Nx.SuperTrackSafe(function()
            _G.C_SuperTrack.SetSuperTrackedQuestID(0)
        end)
    end
    local Quest = _G.Nx and _G.Nx.Quest
    if Quest and Quest.SetActiveCarboniteQuest then
        Quest:SetActiveCarboniteQuest(0, 0)
    end
end

function QuestWatchSurface:ToggleTracker()
    local w = watch()
    if w and w.Win and w.Win.Show then
        w.Win:Show(not w.Win:IsShown())
    end
end

function QuestWatchSurface:IsTrackerShown()
    local w = watch()
    return w and w.Win and w.Win.IsShown and w.Win:IsShown() or false
end

function QuestWatchSurface:ClearAutoTarget()
    local w = watch()
    if w and w.ClearAutoTarget then w:ClearAutoTarget() end
end

function QuestWatchSurface:Refresh()
    local w = watch()
    if w and w.Update then w:Update() end
end
