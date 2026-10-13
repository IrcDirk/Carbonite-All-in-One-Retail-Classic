-- Carbonite.Quests | QuestCatalogDisplay
-- Read-only presentation bridge for the recovered catalog. Tracking, item
-- actions, party state, and map coordinates remain owned by their existing
-- Carbonite components. Consumers borrow a committed snapshot by quest ID.

local Nx = _G.Nx
local Quest = Nx and Nx.Quest
local Catalog = Quest and Quest.Catalog
if not Catalog then return end

local QuestAPI = Nx.Compat and Nx.Compat.Api and Nx.Compat.Api.Quest
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo
local Display = { preparing = false }
Quest.CatalogDisplay = Display

local function FormatObjective(objective)
    local text = objective.text
    local required, fulfilled = objective.numRequired, objective.numFulfilled
    if type(text) == "string" and type(required) == "number"
        and type(fulfilled) == "number" and required > 1
        and objective.type ~= "progressbar"
        and not text:find("%d+%s*/%s*%d+") then
        return string.format("%d/%d %s", fulfilled, required, text)
    end
    return text
end

function Display:Prepare(reason)
    if self.preparing then return end
    self.preparing = true
    Catalog:EnsureFresh(reason or "quest-display")
    self.preparing = false
end

function Display:GetRecord(currentQuest)
    if not Catalog.hasStateSnapshot or Catalog.stateDirty or Catalog.refreshing then
        return nil
    end
    local questID = currentQuest
    if type(currentQuest) == "table" then
        -- Party-only and history rows have their own data source.
        if currentQuest.Party or not currentQuest.QI or currentQuest.QI <= 0 then
            return nil
        end
        questID = currentQuest.QId
    end
    return Catalog:GetQuestRecord(questID)
end

function Display:GetRecordByLogIndex(logIndex)
    if not QuestAPI or not logIndex or logIndex <= 0 then return nil end
    -- Re-resolve transient indices for every indexed read. A collapsed header
    -- or an accepted/removed quest can move indices without changing identity.
    return self:GetRecord(QuestAPI:GetQuestIDForLogIndex(logIndex))
end

function Display:GetObjective(record, objectiveIndex)
    if record and record.objectiveDataReliable ~= false then
        local objective = record.objectives and record.objectives[objectiveIndex]
        if objective then
            return FormatObjective(objective), objective.type, objective.finished,
                objective.numFulfilled, objective.numRequired
        end
    end
end

function Quest:GetCatalogDisplayRecord(currentQuest)
    return Display:GetRecord(currentQuest)
end

function Quest:PrepareCatalogDisplay(reason)
    Display:Prepare(reason)
end

function Quest:GetDisplayObjectiveCount(logIndex)
    local record = Display:GetRecordByLogIndex(logIndex)
    if record and record.objectiveDataReliable ~= false then
        return record.objectiveCount
    end
    return QuestAPI and QuestAPI:GetNumObjectivesForLogIndex(logIndex) or 0
end

function Quest:GetDisplayObjectiveByLogIndex(objectiveIndex, logIndex)
    local record = Display:GetRecordByLogIndex(logIndex)
    local text, objectiveType, finished, fulfilled, required =
        Display:GetObjective(record, objectiveIndex)
    if text then return text, objectiveType, finished, fulfilled, required end
    if QuestAPI then
        return QuestAPI:GetObjectiveForLogIndex(objectiveIndex, logIndex)
    end
end

function Quest:GetDisplayObjectiveInfo(questID, objectiveIndex)
    local text, objectiveType, finished, fulfilled, required =
        Display:GetObjective(Display:GetRecord(questID), objectiveIndex)
    if text then return text, objectiveType, finished, fulfilled, required end
    if GetQuestObjectiveInfo then
        return GetQuestObjectiveInfo(questID, objectiveIndex, false)
    end
    local logIndex = QuestAPI and QuestAPI:GetLogIndexForQuestID(questID) or 0
    return self:GetDisplayObjectiveByLogIndex(objectiveIndex, logIndex)
end

function Quest:GetCatalogDisplayObjective(record, objectiveIndex)
    return Display:GetObjective(record, objectiveIndex)
end

local function OnCatalogChanged(self, catalog, reason, revision, delta)
    local watch = Quest.Watch
    if catalog:DeltaAffects("watch", delta) and watch then
        watch.ForceListRefresh = true
        if not self.preparing and watch.Win and watch.Update then
            watch:Update()
        end
    end
    local list = Quest.List
    if not self.preparing and catalog:DeltaAffects("list", delta)
        and list and list.Win and list.Win:IsShown() and list.Update then
        list:Update()
    end
end

Catalog:RegisterCallback(Display, OnCatalogChanged, { "watch", "list" })
