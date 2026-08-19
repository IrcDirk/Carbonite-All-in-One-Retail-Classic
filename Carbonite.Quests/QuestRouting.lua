-- Carbonite.Quests | QuestRouting
-- Documented surface around quest-driven auto-routing. The legacy
-- code's Quest:TrackOnMap drops a waypoint on the active quest
-- objective and (with the Quests addon installed) auto-plans a
-- route. This class is the public verb.
--
-- Public API:
--   QuestRouting:RouteToQuest(questID)
--   QuestRouting:RouteToObjective(questID, objIndex)
--   QuestRouting:ClearActive()
--   QuestRouting:GetActiveQuestID()

local Carbonite = _G.Carbonite
if not Carbonite then return end

local QuestRouting = {}
Carbonite.Quests = Carbonite.Quests or {}
Carbonite.Quests.Routing = QuestRouting

local function quest()
    local Nx = _G.Nx
    return Nx and Nx.Quest
end

function QuestRouting:RouteToQuest(questID)
    if not questID then return end
    local q = quest()
    if q and q.TrackOnMap then
        local logIdx = _G.GetQuestLogIndexByID and _G.GetQuestLogIndexByID(questID) or 0
        q:TrackOnMap(questID, logIdx)
        Carbonite.Core.EventBus:Fire("QUEST_ROUTE_REQUESTED", questID)
    end
end

function QuestRouting:RouteToObjective(questID, objIndex)
    -- The legacy TrackOnMap signature accepts an extra "obj" arg on
    -- some flavours; we pass it via the optional 3rd parameter.
    local q = quest()
    if q and q.TrackOnMap then
        local logIdx = _G.GetQuestLogIndexByID and _G.GetQuestLogIndexByID(questID) or 0
        q:TrackOnMap(questID, logIdx, objIndex)
    end
end

function QuestRouting:ClearActive()
    local q = quest()
    if q and q.SetActiveCarboniteQuest then q:SetActiveCarboniteQuest(0, 0) end
    if _G.C_SuperTrack and _G.C_SuperTrack.SetSuperTrackedQuestID then
        -- Combat-defer: insecure super-track mutations fire
        -- SUPER_TRACKING_CHANGED in our taint and trip the protected
        -- SetPassThroughButtons in Blizzard's QuestDataProvider.
        _G.Nx.SuperTrackSafe(function()
            _G.C_SuperTrack.SetSuperTrackedQuestID(0)
        end)
    end
    Carbonite.Core.EventBus:Fire("QUEST_ROUTE_CLEARED")
end

function QuestRouting:GetActiveQuestID()
    if _G.C_SuperTrack and _G.C_SuperTrack.GetSuperTrackedQuestID then
        return _G.C_SuperTrack.GetSuperTrackedQuestID()
    end
    local q = quest()
    return q and q.ActiveQuestID or nil
end
