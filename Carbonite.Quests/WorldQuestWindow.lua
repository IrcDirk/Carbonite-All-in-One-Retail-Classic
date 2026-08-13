-- Carbonite.Quests | WorldQuestWindow
-- Movable, resizable, scrollable world-quest list for Retail.
-- World-quest discovery remains separate from the active quest catalog.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Quest", true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}
Nx.Quest.WQList = Nx.Quest.WQList or {}

local C_Item = _G.C_Item
local C_Map = _G.C_Map
local C_QuestLog = _G.C_QuestLog
local C_Reputation = _G.C_Reputation
local C_TaskQuest = _G.C_TaskQuest
local C_Timer = _G.C_Timer
local Enum = _G.Enum
local QuestUtil = _G.QuestUtil

local GetFactionInfoByID = _G.GetFactionInfoByID
local GetNumQuestLogRewardCurrencies = _G.GetNumQuestLogRewardCurrencies
local GetNumQuestLogRewards = _G.GetNumQuestLogRewards
local GetQuestLogRewardArtifactXP = _G.GetQuestLogRewardArtifactXP
local GetQuestLogRewardCurrencyInfo = _G.GetQuestLogRewardCurrencyInfo
local GetQuestLogRewardHonor = _G.GetQuestLogRewardHonor
local GetQuestLogRewardInfo = _G.GetQuestLogRewardInfo
local GetQuestLogRewardMoney = _G.GetQuestLogRewardMoney
local GetQuestLogRewardXP = _G.GetQuestLogRewardXP
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo
local GetTime = _G.GetTime
local HaveQuestRewardData = _G.HaveQuestRewardData
local QuestUtils_IsQuestWorldQuest = _G.QuestUtils_IsQuestWorldQuest
local format = string.format
local ipairs = ipairs
local issecretvalue = _G.issecretvalue
local max = math.max
local min = math.min
local pairs = pairs
local sort = table.sort
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local type = type
local wipe = _G.wipe

local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

Nx.Quest.worldquestdb = Nx.Quest.worldquestdb or {}
local worldquestdb = Nx.Quest.worldquestdb

local COLUMN_ICON = 1
local COLUMN_NAME = 2
local COLUMN_ZONE = 3
local COLUMN_REWARD = 4
local COLUMN_TIME = 5
local DEFAULT_SORT_COLUMN = COLUMN_ZONE

local MAX_SCAN_MAPS = 128
local REFRESH_DELAY_SECONDS = 0.20
local REWARD_REQUEST_RETRY_SECONDS = 5
local MAX_EXPIRY_TIMER_SECONDS = 86400
local WINDOW_LAYOUT_VERSION = 2
local WINDOW_MIN_WIDTH = 480
local WINDOW_MIN_HEIGHT = 180
local WINDOW_DEFAULT_WIDTH = 620
local WINDOW_DEFAULT_HEIGHT = 360

local UI_MAP_TYPE_CONTINENT = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
local UI_MAP_TYPE_ZONE = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
local ITEM_CLASS_WEAPON = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
local ITEM_CLASS_ARMOR = Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4
local ITEM_CLASS_TRADEGOODS = Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods or 7
local QUEST_TAG_PVP = Enum and Enum.QuestTagType and Enum.QuestTagType.PvP or 3
local QUEST_WATCH_MANUAL = Enum and Enum.QuestWatchType
    and Enum.QuestWatchType.Manual or 1

local REWARD_ORDER = {
    { key = "gear", label = "Gear", option = "showgear" },
    { key = "gold", label = "Gold", option = "showgold" },
    { key = "currency", label = "Currency", option = "showorder" },
    { key = "materials", label = "Materials", option = "showorder" },
    { key = "reputation", label = "Reputation", option = "showorder" },
    { key = "power", label = "Power", option = "showap" },
    { key = "pvp", label = "PvP", option = "showpvp" },
    { key = "other", label = "Other", option = "showother" },
}

local function IsSafeValue(value)
    return not (issecretvalue and issecretvalue(value))
end

local function IsSafeNumber(value)
    return IsSafeValue(value) and type(value) == "number"
end

local function IsSafeString(value)
    return IsSafeValue(value) and type(value) == "string"
end

local function GetCurrentMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if IsSafeNumber(mapID) and mapID > 0 then
            return mapID
        end
    end

    if Nx.Map and Nx.Map.GetCurrentMapAreaID then
        local mapID = Nx.Map:GetCurrentMapAreaID()
        if IsSafeNumber(mapID) and mapID > 0 then
            return mapID
        end
    end
end

local function GetContinentMapID(mapID)
    if not C_Map or not C_Map.GetMapInfo or not IsSafeNumber(mapID) then
        return
    end

    local currentMapID = mapID
    for _ = 1, 16 do
        local mapInfo = C_Map.GetMapInfo(currentMapID)
        if type(mapInfo) ~= "table" then
            return
        end

        if IsSafeNumber(mapInfo.mapType) and mapInfo.mapType == UI_MAP_TYPE_CONTINENT then
            return currentMapID
        end

        local parentMapID = mapInfo.parentMapID
        if not IsSafeNumber(parentMapID) or parentMapID <= 0 or parentMapID == currentMapID then
            return
        end
        currentMapID = parentMapID
    end
end

local function AddScanMap(mapIDs, seen, mapID)
    if #mapIDs >= MAX_SCAN_MAPS
        or not IsSafeNumber(mapID)
        or mapID <= 0
        or seen[mapID] then
        return
    end

    seen[mapID] = true
    mapIDs[#mapIDs + 1] = mapID
end

local function GetScanMapIDs(currentMapID, currentZoneOnly)
    local mapIDs = {}
    local seen = {}

    if currentZoneOnly then
        AddScanMap(mapIDs, seen, currentMapID)
        return mapIDs
    end

    local rootMapID = GetContinentMapID(currentMapID) or currentMapID
    AddScanMap(mapIDs, seen, rootMapID)

    if C_Map and C_Map.GetMapChildrenInfo then
        local children = C_Map.GetMapChildrenInfo(rootMapID, UI_MAP_TYPE_ZONE, true)
        if type(children) == "table" then
            for _, childInfo in ipairs(children) do
                if type(childInfo) == "table" then
                    AddScanMap(mapIDs, seen, childInfo.mapID)
                end
            end
        end
    end

    AddScanMap(mapIDs, seen, currentMapID)
    sort(mapIDs)
    return mapIDs
end

local function GetTasksForMap(mapID)
    if not C_TaskQuest then
        return {}
    end

    if C_TaskQuest.GetQuestsOnMap then
        local tasks = C_TaskQuest.GetQuestsOnMap(mapID)
        return type(tasks) == "table" and tasks or {}
    end

    if C_TaskQuest.GetQuestsForPlayerByMapID then
        local tasks = C_TaskQuest.GetQuestsForPlayerByMapID(mapID, mapID)
        return type(tasks) == "table" and tasks or {}
    end

    return {}
end

local function GetQuestTimeLeftSeconds(questID)
    if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds then
        local seconds = C_TaskQuest.GetQuestTimeLeftSeconds(questID)
        if IsSafeNumber(seconds) then
            return seconds
        end
    end

    if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftMinutes then
        local minutes = C_TaskQuest.GetQuestTimeLeftMinutes(questID)
        if IsSafeNumber(minutes) then
            return minutes * 60
        end
    end
end

local function GetMapName(mapID)
    if C_Map and C_Map.GetMapInfo and IsSafeNumber(mapID) then
        local mapInfo = C_Map.GetMapInfo(mapID)
        if type(mapInfo) == "table" and IsSafeString(mapInfo.name) and mapInfo.name ~= "" then
            return mapInfo.name
        end
    end
    return L["Unknown Zone"]
end

local function GetFactionName(factionID)
    if not IsSafeNumber(factionID) then
        return
    end

    if C_Reputation and C_Reputation.GetFactionDataByID then
        local factionData = C_Reputation.GetFactionDataByID(factionID)
        if type(factionData) == "table"
            and IsSafeString(factionData.name)
            and factionData.name ~= "" then
            return factionData.name
        end
    end

    if GetFactionInfoByID then
        local name = GetFactionInfoByID(factionID)
        if IsSafeString(name) and name ~= "" then
            return name
        end
    end
end

local function IsWorldQuest(questID)
    if not QuestUtils_IsQuestWorldQuest then
        return false
    end

    local isWorldQuest = QuestUtils_IsQuestWorldQuest(questID)
    return IsSafeValue(isWorldQuest) and isWorldQuest == true
end

local function GetWorldQuestWatchType(questID)
    if not C_QuestLog
        or not C_QuestLog.GetQuestWatchType
        or not IsSafeNumber(questID) then
        return
    end

    local watchType = C_QuestLog.GetQuestWatchType(questID)
    if IsSafeValue(watchType) then
        return watchType
    end
end

local function IsWorldQuestWatched(questID)
    return GetWorldQuestWatchType(questID) ~= nil
end

local function GetItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemID)
    end
    if _G.GetItemInfo then
        return _G.GetItemInfo(itemID)
    end
end

local function IsResourceCurrency(currencyID)
    if currencyID == 1220 then
        return true
    end

    local currencyInfo = _G.C_CurrencyInfo
    if currencyInfo and currencyInfo.GetWarResourcesCurrencyID then
        local resourceID = currencyInfo.GetWarResourcesCurrencyID()
        if IsSafeNumber(resourceID) and resourceID == currencyID then
            return true
        end
    end

    if currencyInfo and currencyInfo.GetDragonIslesSuppliesCurrencyID then
        local resourceID = currencyInfo.GetDragonIslesSuppliesCurrencyID()
        if IsSafeNumber(resourceID) and resourceID == currencyID then
            return true
        end
    end

    return false
end

local function IsPowerCurrency(currencyID)
    if _G.C_CurrencyInfo and _G.C_CurrencyInfo.GetAzeriteCurrencyID then
        local powerCurrencyID = _G.C_CurrencyInfo.GetAzeriteCurrencyID()
        return IsSafeNumber(powerCurrencyID) and powerCurrencyID == currencyID
    end
    return false
end

local function IsReputationCurrency(currencyID)
    if _G.C_CurrencyInfo and _G.C_CurrencyInfo.GetFactionGrantedByCurrency then
        local factionID = _G.C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID)
        return IsSafeNumber(factionID) and factionID > 0
    end
    return false
end

local function AddCurrencyReward(flags, currencyID)
    if not IsSafeNumber(currencyID) then
        return
    end

    if IsPowerCurrency(currencyID) then
        flags.power = true
    elseif IsReputationCurrency(currencyID) then
        flags.reputation = true
    else
        flags.currency = true
        if IsResourceCurrency(currencyID) then
            flags.resources = true
        end
    end
end

local function HasKnownReward(flags)
    for _, rewardInfo in ipairs(REWARD_ORDER) do
        if flags[rewardInfo.key] then
            return true
        end
    end
    return false
end

local function BuildRewardLabel(flags)
    local labels = {}

    for _, rewardInfo in ipairs(REWARD_ORDER) do
        if flags[rewardInfo.key] then
            labels[#labels + 1] = L[rewardInfo.label]
        end
    end

    if #labels == 0 then
        if flags.pending then
            return L["Loading..."]
        end
        return L["Other"]
    end

    return tconcat(labels, ", ")
end

local function IsRewardVisible(flags)
    if flags.pending then
        return true
    end

    local options = Nx.qdb and Nx.qdb.profile and Nx.qdb.profile.WQList
    if not options then
        return true
    end

    for _, rewardInfo in ipairs(REWARD_ORDER) do
        if flags[rewardInfo.key] and options[rewardInfo.option] ~= false then
            return true
        end
    end

    return false
end

local function BuildQuestTooltip(info)
    local lines = {
        "|cffffffff" .. info.title .. "|r",
        L["Zone"] .. ": " .. info.zoneName,
        L["Reward"] .. ": " .. info.rewardLabel,
        L["Time Left"] .. ": " .. info.timeLabel,
    }

    if info.factionName then
        lines[#lines + 1] = L["Faction"] .. ": " .. info.factionName
    end

    local objectives
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        objectives = C_QuestLog.GetQuestObjectives(info.questid)
    end

    if type(objectives) == "table" then
        for _, objective in ipairs(objectives) do
            if type(objective) == "table"
                and IsSafeString(objective.text)
                and objective.text ~= "" then
                local completed = IsSafeValue(objective.finished) and objective.finished == true
                local color = completed and "|cff808080" or "|cffffffff"
                lines[#lines + 1] = color .. (QUEST_DASH or "- ") .. objective.text .. "|r"
            end
        end
    elseif GetQuestObjectiveInfo then
        for objectiveIndex = 1, info.numobjectives do
            local text, _, completed = GetQuestObjectiveInfo(info.questid, objectiveIndex, false)
            if IsSafeString(text) and text ~= "" then
                local isComplete = IsSafeValue(completed) and completed == true
                local color = isComplete and "|cff808080" or "|cffffffff"
                lines[#lines + 1] = color .. (QUEST_DASH or "- ") .. text .. "|r"
            end
        end
    end

    lines[#lines + 1] = "|cff80c0ff" .. L["Click the icon to set a map target."] .. "|r"
    return tconcat(lines, "\n")
end

local function FindQuestRow(list, questID)
    if not IsSafeNumber(questID) then
        return
    end

    for rowIndex = 1, list.Num do
        local rowData = list:ItemGetData(rowIndex)
        if type(rowData) == "table" and rowData.questid == questID then
            return rowIndex
        end
    end
end

local function GetRowQuestID(rowData)
    if type(rowData) == "table" and IsSafeNumber(rowData.questid) then
        return rowData.questid
    end
end

local function IsSortableColumn(columnID)
    return columnID == COLUMN_NAME
        or columnID == COLUMN_ZONE
        or columnID == COLUMN_REWARD
end

local function RestoreListState(list, topQuestID, selectedQuestID)
    local topRow = FindQuestRow(list, topQuestID)
    if topRow then
        list.Top = topRow
    end

    local selectedRow = FindQuestRow(list, selectedQuestID)
    if selectedRow then
        list.Selected = selectedRow
    elseif list.Num > 0 then
        list.Selected = 1
    else
        list.Selected = 0
    end

    list:Update()
end

local function UpdateListColumnWidths(list, listWidth)
    if not IsSafeNumber(listWidth) or listWidth <= 0 then
        return false
    end

    local reservedWidth = list:ColumnGetWidth(COLUMN_ICON)
        + list:ColumnGetWidth(COLUMN_ZONE)
        + list:ColumnGetWidth(COLUMN_REWARD)
        + list:ColumnGetWidth(COLUMN_TIME)
        + 12
    local nameWidth = max(150, listWidth - reservedWidth)
    if list:ColumnGetWidth(COLUMN_NAME) == nameWidth then
        return false
    end

    list:ColumnSetWidth(COLUMN_NAME, nameWidth)
    return true
end

function Nx.Quest.WQList:IsAvailable()
    if _G.WOW_PROJECT_ID and _G.WOW_PROJECT_MAINLINE
        and _G.WOW_PROJECT_ID ~= _G.WOW_PROJECT_MAINLINE then
        return false
    end

    return C_Map
        and C_Map.GetBestMapForUnit
        and C_TaskQuest
        and (C_TaskQuest.GetQuestsOnMap or C_TaskQuest.GetQuestsForPlayerByMapID)
        and QuestUtils_IsQuestWorldQuest
        and true or false
end

function Nx.Quest.WQList:Open()
    if self.Opened or not self:IsAvailable() then
        return
    end

    local options = Nx.qdb.profile.WQList
    local firstActivation = options.reactivated ~= true
    options.reactivated = true

    Nx.Window:SetCreateFade(1, 0.15)
    local win = Nx.Window:Create(
        "NxQuestWQList",
        WINDOW_MIN_WIDTH,
        WINDOW_MIN_HEIGHT,
        nil,
        1,
        nil,
        true
    )

    self.Opened = true
    self.Win = win
    self.Dirty = true
    self.RewardRequests = self.RewardRequests or {}

    win:InitLayoutData(
        nil,
        999999,
        999999,
        WINDOW_DEFAULT_WIDTH,
        WINDOW_DEFAULT_HEIGHT
    )

    local layout = win.SaveData
    local migrateLayout = tonumber(options.layoutVersion) ~= WINDOW_LAYOUT_VERSION
    local repairLayout = false

    -- The dormant list stored proportional dimensions (-.2 by -.1). A
    -- previous reactivation run may already have recorded its migration flag,
    -- so validate the saved geometry every time instead of trusting only the
    -- flag. Otherwise the 460-pixel list can extend beyond the old narrow
    -- window background.
    if not IsSafeNumber(layout.W) or layout.W < WINDOW_MIN_WIDTH then
        layout.W = WINDOW_DEFAULT_WIDTH
        repairLayout = true
    end
    if not IsSafeNumber(layout.H) or layout.H < WINDOW_MIN_HEIGHT then
        layout.H = WINDOW_DEFAULT_HEIGHT
        repairLayout = true
    end

    if migrateLayout then
        if firstActivation then
            layout.A = nil
            layout.X = 999999
            layout.Y = 999999
            layout.S = nil
        end
        layout._W = WINDOW_DEFAULT_WIDTH
        layout._H = WINDOW_DEFAULT_HEIGHT
        options.layoutVersion = WINDOW_LAYOUT_VERSION
    end

    if Nx.Window.LoginDone and (migrateLayout or repairLayout) then
        -- InitLayoutData already selected the normal layout. Clear that state
        -- before applying the repaired dimensions so SetLayoutMode does not
        -- call RecordLayoutData and overwrite them with the stale live width.
        -- This matches Carbonite's own first-login window initialization.
        win.LayoutMode = false
        win:SetLayoutMode(1)
    end

    if firstActivation or migrateLayout then
        win:Lock(false)
    end

    win:CreateButtons(true, nil, nil)
    win:SetBGAlpha(0, 1)
    win:SetSizeable(true)
    win:SetTitleXOff(28, -4)
    win:SetTitle(L["World Quest List"])
    win.Frm:SetClampedToScreen(true)
    win.UserUpdateFade = self.WinUpdateFade

    local function OpenMenu()
        self.Menu:Open()
    end
    self.ButMenu = Nx.Button:Create(
        win.Frm,
        "WQListMenu",
        nil,
        nil,
        7,
        -2,
        "TOPLEFT",
        1,
        1,
        OpenMenu,
        self
    )

    Nx.List:SetCreateFont("QuestWatch.WatchFont", 12)
    local list = Nx.List:Create(
        "NxQuestWQList",
        2,
        -2,
        100,
        36,
        win.Frm,
        false,
        false
    )
    self.List = list
    list:SetMinSize(460, 120)
    list:ColumnAdd("", COLUMN_ICON, 16)
    list:ColumnAdd(L["Name"], COLUMN_NAME, 190)
    list:ColumnAdd(L["Zone"], COLUMN_ZONE, 105)
    list:ColumnAdd(L["Reward"], COLUMN_REWARD, 115)
    list:ColumnAdd(L["Time Left"], COLUMN_TIME, 70)
    list:SetUser(self, self.OnListEvent)
    list.Frm.NxSetSize = function(_, width, height)
        if UpdateListColumnWidths(list, width) then
            -- ColumnSetWidth does not invalidate Carbonite's cached geometry.
            list.SSW = nil
            list:SetSize(width, height)
        end
    end
    win:Attach(list.Frm, 0, 1, 0, 1)

    local savedSortColumn = tonumber(options.sortmode)
    if savedSortColumn ~= 0
        and not IsSortableColumn(savedSortColumn) then
        savedSortColumn = DEFAULT_SORT_COLUMN
        options.sortmode = savedSortColumn
    end
    list.SortColumnId = savedSortColumn ~= 0 and savedSortColumn or nil
    for columnID, column in pairs(list.Columns) do
        list:ColumnSetName(columnID, column.Name)
    end

    local menu = Nx.Menu:Create(list.Frm)
    self.Menu = menu

    -- Row actions are deliberately separate from the filter menu. The dot
    -- remains the existing Carbonite map-target action; right-clicking a row
    -- opens an explicit manual watch action instead of changing that behavior.
    local rowMenu = Nx.Menu:Create(list.Frm, 190)
    self.RowMenu = rowMenu

    local function ToggleSelectedWorldQuest(owner)
        owner:ToggleWorldQuestWatch(owner.RowMenuQuestID)
    end
    self.RowMenuItem = rowMenu:AddItem(
        0,
        L["Track World Quest"],
        ToggleSelectedWorldQuest,
        self
    )

    local function UpdateFilters()
        self:Update()
    end

    local function RefreshScope()
        self:ScheduleUpdateDB("FILTER_CHANGED", true)
    end

    local item = menu:AddItem(0, L["Show Gear Rewards"], UpdateFilters, self)
    item:SetChecked(options, "showgear")
    item = menu:AddItem(0, L["Show Gold Rewards"], UpdateFilters, self)
    item:SetChecked(options, "showgold")
    item = menu:AddItem(0, L["Show Currency, Material, and Reputation Rewards"], UpdateFilters, self)
    item:SetChecked(options, "showorder")
    item = menu:AddItem(0, L["Show Power Rewards"], UpdateFilters, self)
    item:SetChecked(options, "showap")
    item = menu:AddItem(0, L["Show PVP Rewards"], UpdateFilters, self)
    item:SetChecked(options, "showpvp")
    item = menu:AddItem(0, L["Show Other Rewards"], UpdateFilters, self)
    item:SetChecked(options, "showother")

    menu:AddItem(0, "")
    item = menu:AddItem(0, L["Current Zone Only"], RefreshScope, self)
    item:SetChecked(options, "zoneonly")
    menu:AddItem(0, L["Refresh World Quest List"], RefreshScope, self)

    LibStub("AceEvent-3.0"):Embed(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "ScheduleUpdateDB")
    self:RegisterEvent("ZONE_CHANGED", "ScheduleUpdateDB")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ScheduleUpdateDB")
    self:RegisterEvent("QUEST_LOG_UPDATE", "ScheduleUpdateDB")
    self:RegisterEvent("QUEST_POI_UPDATE", "ScheduleUpdateDB")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED", "ScheduleUpdateDB")
    self:RegisterEvent("QUEST_DATA_LOAD_RESULT", "ScheduleUpdateDB")
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "ScheduleUpdateDB")
    self:RegisterEvent("QUEST_WATCH_LIST_CHANGED", "OnWatchListChanged")

    win.Frm:SetScript("OnShow", function()
        self:ScheduleUpdateDB("WINDOW_SHOWN", true)
    end)
    win.Frm:SetScript("OnHide", function()
        self:CancelTimers()
        self.Dirty = true
    end)

    self:Update()

    if firstActivation then
        win:Show(false)
    elseif win:IsShown() then
        self:ScheduleUpdateDB("RESTORE_VISIBLE", true)
    end
end

function Nx.Quest.WQList:OnWatchListChanged()
    -- This event also fires when Blizzard's world map changes a watch. Keep
    -- the row indicator and Carbonite's own Quest Watch in sync with it.
    self:Update()

    local watch = Nx.Quest and Nx.Quest.Watch
    if watch and watch.Update then
        watch.ForceListRefresh = true
        watch:Update()
    end
end

function Nx.Quest.WQList:ToggleWorldQuestWatch(questID)
    if not IsSafeNumber(questID) or not C_QuestLog then
        return
    end

    local shouldTrack = not IsWorldQuestWatched(questID)
    local canTrack = QuestUtil and QuestUtil.TrackWorldQuest
        or C_QuestLog.AddWorldQuestWatch
    local canUntrack = QuestUtil and QuestUtil.UntrackWorldQuest
        or C_QuestLog.RemoveWorldQuestWatch
    if shouldTrack and not canTrack or not shouldTrack and not canUntrack then
        return
    end

    -- Match Carbonite's world-map pin path: leave the tainted row-click stack
    -- before touching Blizzard's watch API, and defer again if combat begins.
    local function ApplyWatchChange()
        if shouldTrack then
            if QuestUtil and QuestUtil.TrackWorldQuest then
                QuestUtil.TrackWorldQuest(questID, QUEST_WATCH_MANUAL)
            else
                C_QuestLog.AddWorldQuestWatch(questID, QUEST_WATCH_MANUAL)
            end
        elseif QuestUtil and QuestUtil.UntrackWorldQuest then
            QuestUtil.UntrackWorldQuest(questID)
        else
            C_QuestLog.RemoveWorldQuestWatch(questID)
        end

        self:OnWatchListChanged()
    end

    local function RunWhenSafe()
        if Nx.SuperTrackSafe then
            Nx.SuperTrackSafe(ApplyWatchChange)
        else
            ApplyWatchChange()
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, RunWhenSafe)
    else
        RunWhenSafe()
    end
end

function Nx.Quest.WQList:Show()
    if not self:IsAvailable() then
        return false
    end

    if not self.Opened then
        self:Open()
    end

    if self.Win then
        self.Win:Show(true)
        return true
    end

    return false
end

function Nx.Quest.WQList:CancelTimers()
    if self.RefreshTimer then
        self.RefreshTimer:Cancel()
        self.RefreshTimer = nil
    end
    if self.ExpiryTimer then
        self.ExpiryTimer:Cancel()
        self.ExpiryTimer = nil
    end
end

function Nx.Quest.WQList:WinUpdateFade(fade)
    local wqlist = Nx.Quest.WQList
    if wqlist.Win then
        wqlist.Win:SetTitleColors(1, 1, 1, fade)
    end
    if wqlist.List then
        wqlist.List.Frm:SetAlpha(fade)
    end
    if wqlist.ButMenu then
        wqlist.ButMenu.Frm:SetAlpha(fade)
    end
end

function Nx.Quest.WQList:RequestRewardData(questID)
    if not C_TaskQuest or not C_TaskQuest.RequestPreloadRewardData then
        return
    end

    local now = GetTime and GetTime() or 0
    local lastRequest = self.RewardRequests[questID]
    if not lastRequest or now - lastRequest >= REWARD_REQUEST_RETRY_SECONDS then
        self.RewardRequests[questID] = now
        C_TaskQuest.RequestPreloadRewardData(questID)
    end
end

function Nx.Quest.WQList:ClassifyRewards(questID, tagInfo)
    local flags = {}

    if HaveQuestRewardData then
        local rewardDataLoaded = HaveQuestRewardData(questID)
        if not IsSafeValue(rewardDataLoaded) or rewardDataLoaded ~= true then
            flags.pending = true
            self:RequestRewardData(questID)
            return flags
        end
    end

    if tagInfo and IsSafeNumber(tagInfo.worldQuestType)
        and tagInfo.worldQuestType == QUEST_TAG_PVP then
        flags.pvp = true
    end

    if GetQuestLogRewardHonor then
        local honor = GetQuestLogRewardHonor(questID)
        if IsSafeNumber(honor) and honor > 0 then
            flags.pvp = true
        end
    end

    if GetQuestLogRewardArtifactXP then
        local artifactPower = GetQuestLogRewardArtifactXP(questID)
        if IsSafeNumber(artifactPower) and artifactPower > 0 then
            flags.power = true
        end
    end

    if GetQuestLogRewardMoney then
        local money = GetQuestLogRewardMoney(questID)
        if IsSafeNumber(money) and money > 0 then
            flags.gold = true
        end
    end

    if GetNumQuestLogRewards and GetQuestLogRewardInfo then
        local rewardCount = GetNumQuestLogRewards(questID)
        if IsSafeNumber(rewardCount) then
            for rewardIndex = 1, rewardCount do
                local itemName, _, _, _, _, itemID =
                    GetQuestLogRewardInfo(rewardIndex, questID)

                if IsSafeNumber(itemID) and itemID > 0 then
                    local categorized = false
                    local itemPending = false

                    if C_Item and C_Item.IsArtifactPowerItem then
                        local isPowerItem = C_Item.IsArtifactPowerItem(itemID)
                        if IsSafeValue(isPowerItem) and isPowerItem == true then
                            flags.power = true
                            categorized = true
                        end
                    end

                    if C_Item and C_Item.IsAnimaItemByID then
                        local isAnima = C_Item.IsAnimaItemByID(itemID)
                        if IsSafeValue(isAnima) and isAnima == true then
                            flags.power = true
                            categorized = true
                        end
                    end

                    local _, _, _, _, _, _, _, _, equipLocation, _, _, classID =
                        GetItemInfo(itemID)

                    if IsSafeNumber(classID) then
                        if classID == ITEM_CLASS_WEAPON or classID == ITEM_CLASS_ARMOR
                            or (IsSafeString(equipLocation) and equipLocation ~= "") then
                            flags.gear = true
                            categorized = true
                        elseif classID == ITEM_CLASS_TRADEGOODS then
                            flags.materials = true
                            categorized = true
                        end
                    else
                        flags.pending = true
                        itemPending = true
                        if C_Item and C_Item.RequestLoadItemDataByID then
                            C_Item.RequestLoadItemDataByID(itemID)
                        end
                    end

                    if not categorized and not itemPending then
                        flags.other = true
                    end
                elseif IsSafeString(itemName) and itemName ~= "" then
                    flags.other = true
                end
            end
        end
    end

    local usedModernCurrencies = false
    if C_QuestLog and C_QuestLog.GetQuestRewardCurrencies then
        local currencyRewards = C_QuestLog.GetQuestRewardCurrencies(questID)
        if type(currencyRewards) == "table" then
            usedModernCurrencies = true
            for _, currencyReward in ipairs(currencyRewards) do
                if type(currencyReward) == "table" then
                    AddCurrencyReward(flags, currencyReward.currencyID)
                end
            end
        end
    end

    if not usedModernCurrencies
        and GetNumQuestLogRewardCurrencies
        and GetQuestLogRewardCurrencyInfo then
        local currencyCount = GetNumQuestLogRewardCurrencies(questID)
        if IsSafeNumber(currencyCount) then
            for currencyIndex = 1, currencyCount do
                local _, _, _, currencyID =
                    GetQuestLogRewardCurrencyInfo(currencyIndex, questID)
                AddCurrencyReward(flags, currencyID)
            end
        end
    end

    if C_QuestLog and C_QuestLog.GetQuestLogMajorFactionReputationRewards then
        local reputationRewards =
            C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
        if type(reputationRewards) == "table" and #reputationRewards > 0 then
            flags.reputation = true
        end
    end

    if not HasKnownReward(flags) and GetQuestLogRewardXP then
        local experience = GetQuestLogRewardXP(questID)
        if IsSafeNumber(experience) and experience > 0 then
            flags.other = true
        end
    end

    if not HasKnownReward(flags) and not flags.pending then
        flags.other = true
    end

    return flags
end

function Nx.Quest.WQList:GenWQTip(questID)
    local info = IsSafeNumber(questID) and worldquestdb[questID]
    if not info then
        return
    end

    if not info.tip then
        info.tip = BuildQuestTooltip(info)
    end
    return info.tip
end

function Nx.Quest.WQList:GetWQReward(questID)
    local info = IsSafeNumber(questID) and worldquestdb[questID]
    local flags = info and info.rewardFlags
    if not flags then
        return false
    end

    if flags.power then
        return 10
    elseif flags.gold then
        return 20
    elseif flags.currency or flags.materials or flags.reputation then
        return 30
    elseif flags.gear then
        return 40
    end

    return false
end

function Nx.Quest.WQList:CheckBounty(questID)
    if not C_QuestLog
        or not C_QuestLog.GetBountiesForMapID
        or not C_QuestLog.IsQuestCriteriaForBounty
        or not IsSafeNumber(questID) then
        return false
    end

    local info = worldquestdb[questID]
    local mapID = info and info.mapid or self.CurrentMapID
    local rootMapID = GetContinentMapID(mapID) or mapID
    if not IsSafeNumber(rootMapID) then
        return false
    end

    local bounties = C_QuestLog.GetBountiesForMapID(rootMapID)
    if type(bounties) ~= "table" then
        return false
    end

    for _, bounty in ipairs(bounties) do
        if type(bounty) == "table" and IsSafeNumber(bounty.questID) then
            local isCriteria =
                C_QuestLog.IsQuestCriteriaForBounty(questID, bounty.questID)
            if IsSafeValue(isCriteria) and isCriteria == true then
                return true
            end
        end
    end

    return false
end

function Nx.Quest.WQList:AddQuestToSnapshot(snapshot, taskInfo, scanMapID)
    if type(taskInfo) ~= "table" then
        return
    end

    local questID = taskInfo.questID
    if not IsSafeNumber(questID) then
        questID = taskInfo.questId
    end

    if not IsSafeNumber(questID) or questID <= 0 or not IsWorldQuest(questID) then
        return
    end

    local timeLeftSeconds = GetQuestTimeLeftSeconds(questID)
    if IsSafeNumber(timeLeftSeconds) and timeLeftSeconds <= 0 then
        return
    end

    local title
    local factionID
    if C_TaskQuest.GetQuestInfoByQuestID then
        title, factionID = C_TaskQuest.GetQuestInfoByQuestID(questID)
    end

    if not IsSafeString(title) or title == "" then
        if C_QuestLog and C_QuestLog.GetTitleForQuestID then
            title = C_QuestLog.GetTitleForQuestID(questID)
        end
    end

    if not IsSafeString(title) or title == "" then
        if C_QuestLog and C_QuestLog.RequestLoadQuestByID then
            C_QuestLog.RequestLoadQuestByID(questID)
        end
        title = _G.RETRIEVING_DATA or L["Retrieving data"]
    end

    local questMapID
    if C_TaskQuest.GetQuestZoneID then
        questMapID = C_TaskQuest.GetQuestZoneID(questID)
    end
    if not IsSafeNumber(questMapID) or questMapID <= 0 then
        questMapID = taskInfo.mapID
    end
    if not IsSafeNumber(questMapID) or questMapID <= 0 then
        questMapID = scanMapID
    end

    local x
    local y
    if C_TaskQuest.GetQuestLocation then
        x, y = C_TaskQuest.GetQuestLocation(questID, questMapID)
    end
    if not IsSafeNumber(x) or not IsSafeNumber(y) then
        x = taskInfo.x
        y = taskInfo.y
    end
    if not IsSafeNumber(x) or not IsSafeNumber(y) then
        x = 0
        y = 0
    end

    local numObjectives = taskInfo.numObjectives
    if not IsSafeNumber(numObjectives) and C_QuestLog and C_QuestLog.GetNumQuestObjectives then
        numObjectives = C_QuestLog.GetNumQuestObjectives(questID)
    end
    if not IsSafeNumber(numObjectives) or numObjectives < 0 then
        numObjectives = 0
    end

    local tagInfo = GetQuestTagInfoCompat and GetQuestTagInfoCompat(questID)
    local rewardFlags = self:ClassifyRewards(questID, tagInfo)
    local timeLabel = IsSafeNumber(timeLeftSeconds)
        and Nx.Util_GetTimeElapsedStr(max(0, timeLeftSeconds))
        or L["Unknown"]

    local info = {
        questid = questID,
        mapid = questMapID,
        x = x * 100,
        y = y * 100,
        title = title,
        factionID = IsSafeNumber(factionID) and factionID or nil,
        factionName = GetFactionName(factionID),
        zoneName = GetMapName(questMapID),
        numobjectives = numObjectives,
        rewardFlags = rewardFlags,
        rewardLabel = BuildRewardLabel(rewardFlags),
        timeLeftSeconds = timeLeftSeconds,
        timeLabel = timeLabel,
        PVP = rewardFlags.pvp == true,
    }
    info.tip = BuildQuestTooltip(info)
    snapshot[questID] = info

    return timeLeftSeconds
end

function Nx.Quest.WQList:ScheduleUpdateDB(event, ...)
    if event == "UNIT_QUEST_LOG_CHANGED" then
        local unit = ...
        if unit and unit ~= "player" then
            return
        end
    end

    if not self.Opened or not self:IsAvailable() then
        return
    end

    local immediate = select(1, ...) == true
    if not self.Win or not self.Win.Frm:IsShown() then
        self.Dirty = true
        return
    end

    if self.RefreshTimer then
        self.RefreshTimer:Cancel()
        self.RefreshTimer = nil
    end

    local function Refresh()
        self.RefreshTimer = nil
        self:UpdateDB(event)
    end

    if C_Timer and C_Timer.NewTimer then
        self.RefreshTimer = C_Timer.NewTimer(
            immediate and 0 or REFRESH_DELAY_SECONDS,
            Refresh
        )
    else
        Refresh()
    end
end

function Nx.Quest.WQList:ScheduleExpiryRefresh(secondsUntilExpiry)
    if self.ExpiryTimer then
        self.ExpiryTimer:Cancel()
        self.ExpiryTimer = nil
    end

    if not IsSafeNumber(secondsUntilExpiry)
        or secondsUntilExpiry <= 0
        or not C_Timer
        or not C_Timer.NewTimer then
        return
    end

    local delay = min(secondsUntilExpiry + 1, MAX_EXPIRY_TIMER_SECONDS)
    self.ExpiryTimer = C_Timer.NewTimer(delay, function()
        self.ExpiryTimer = nil
        self:ScheduleUpdateDB("QUEST_EXPIRED", true)
    end)
end

function Nx.Quest.WQList:UpdateDB()
    if not self.Opened or not self:IsAvailable() then
        return
    end

    if not self.Win or not self.Win.Frm:IsShown() then
        self.Dirty = true
        return
    end

    if self.Refreshing then
        self.RefreshQueued = true
        return
    end

    self.Refreshing = true
    self.RefreshQueued = false

    local currentMapID = GetCurrentMapID()
    self.CurrentMapID = currentMapID

    local snapshot = {}
    local soonestExpiry

    if IsSafeNumber(currentMapID) then
        local options = Nx.qdb.profile.WQList
        local scanMapIDs = GetScanMapIDs(currentMapID, options.zoneonly == true)

        for _, scanMapID in ipairs(scanMapIDs) do
            local tasks = GetTasksForMap(scanMapID)
            for _, taskInfo in ipairs(tasks) do
                local secondsUntilExpiry =
                    self:AddQuestToSnapshot(snapshot, taskInfo, scanMapID)
                if IsSafeNumber(secondsUntilExpiry) and secondsUntilExpiry > 0 then
                    soonestExpiry = soonestExpiry
                        and min(soonestExpiry, secondsUntilExpiry)
                        or secondsUntilExpiry
                end
            end
        end

        self.StatusMessage = nil
    else
        self.StatusMessage = L["World quest data is unavailable for this location."]
    end

    wipe(worldquestdb)
    for questID, info in pairs(snapshot) do
        worldquestdb[questID] = info
    end

    for questID in pairs(self.RewardRequests) do
        if not snapshot[questID] then
            self.RewardRequests[questID] = nil
        end
    end

    self.Dirty = false
    self.Refreshing = false
    self:ScheduleExpiryRefresh(soonestExpiry)
    self:Update()

    if self.RefreshQueued then
        self.RefreshQueued = false
        self:ScheduleUpdateDB("QUEUED_REFRESH")
    end
end

function Nx.Quest.WQList:OnListEvent(eventName, selectedRow, columnID)
    local list = self.List
    if not list then
        return
    end

    if eventName == "sort" then
        if IsSortableColumn(columnID) then
            local topQuestID = GetRowQuestID(list:ItemGetData(list.Top))
            local selectedQuestID =
                GetRowQuestID(list:ItemGetData(list.Selected))

            list:ColumnSort(columnID)
            Nx.qdb.profile.WQList.sortmode = list.SortColumnId or 0
            list:Update()
            RestoreListState(list, topQuestID, selectedQuestID)
        end
        return
    end

    local itemData = list:ItemGetData(selectedRow)

    if eventName == "menu" then
        if type(itemData) ~= "table"
            or itemData.placeholder
            or not IsSafeNumber(itemData.questid) then
            return
        end

        self.RowMenuQuestID = itemData.questid
        self.RowMenuItem:SetText(
            IsWorldQuestWatched(itemData.questid)
                and L["Untrack World Quest"]
                or L["Track World Quest"]
        )
        self.RowMenu:Open()
        return
    end

    if eventName ~= "button" then
        return
    end

    if type(itemData) ~= "table"
        or itemData.placeholder
        or not IsSafeNumber(itemData.questid)
        or not IsSafeNumber(itemData.mapid) then
        return
    end

    local map = Nx.Map and Nx.Map:GetMap(1)
    if map and map.SetTargetXY then
        map:SetTargetXY(
            itemData.mapid,
            itemData.x,
            itemData.y,
            itemData.title,
            false
        )
    end

    -- QuestWatchCustomTip is not a toggle button. Reapply the actual watch
    -- state after the click so a tracked row keeps its brighter indicator.
    self:Update()
end

function Nx.Quest.WQList:Update()
    local list = self.List
    if not list then
        return
    end

    local topQuestID = GetRowQuestID(list:ItemGetData(list.Top))
    local selectedQuestID = GetRowQuestID(list:ItemGetData(list.Selected))
    local options = Nx.qdb.profile.WQList
    local rows = {}

    for _, info in pairs(worldquestdb) do
        -- UpdateDB already builds a zone-scoped snapshot when zoneonly is on.
        -- Trust that discovery scope so sub-zone map IDs do not hide valid rows.
        if IsRewardVisible(info.rewardFlags) then
            rows[#rows + 1] = info
        end
    end

    sort(rows, function(left, right)
        if left.title == right.title then
            return left.questid < right.questid
        end
        return left.title < right.title
    end)

    list:Empty()

    for _, info in ipairs(rows) do
        local isWatched = IsWorldQuestWatched(info.questid)
        list:ItemAdd(info)
        list:ItemSet(COLUMN_NAME, info.title)
        list:ItemSet(COLUMN_ZONE, info.zoneName)
        list:ItemSet(COLUMN_REWARD, info.rewardLabel)
        list:ItemSet(COLUMN_TIME, info.timeLabel)
        list:ItemSetButton("QuestWatchCustomTip", isWatched)
        list:ItemSetButtonTip(
            info.tip
                .. "\n|cff80c0ff"
                .. L["Right-click the row to track or untrack this world quest."]
                .. "|r"
        )
    end

    if #rows == 0 then
        local message = self.StatusMessage
        if not message then
            if options.zoneonly then
                message = L["No world quests are available in the current zone."]
            else
                message = L["No world quests are available in this region."]
            end
        end

        list:ItemAdd({ placeholder = true })
        list:ItemSet(COLUMN_NAME, "|cffb0b0b0" .. message .. "|r")
    end

    list:Update()
    RestoreListState(list, topQuestID, selectedQuestID)

    if self.Win then
        self.Win:SetTitle(format(L["World Quest List (%d)"], #rows))
    end
end


-------------------------------------------------------------------------------
-- QUEST HUB TOOLTIP SUPPORT
-- Functions to display related quest offers for Quest Hub POIs
-------------------------------------------------------------------------------

---
-- Get quest offers related to a Quest Hub POI
-- @param mapID         The map ID to get quest offers for
-- @param hubAreaPoiID  The areaPoiID of the Quest Hub
-- @return              Table of related quest offers {questID = questInfo, ...}
--
function Nx.Quest:GetRelatedQuestOffersForHub(mapID, hubAreaPoiID)
    if not mapID or not hubAreaPoiID then
        return {}
    end

    -- Check if required APIs exist
    if not C_QuestLine or not C_QuestLine.GetAvailableQuestLines then
        return {}
    end
    if not C_QuestHub or not C_QuestHub.IsQuestCurrentlyRelatedToHub then
        return {}
    end

    local relatedQuests = {}

    -- Get available quest lines for the map
    local questLines = C_QuestLine.GetAvailableQuestLines(mapID)
    if questLines then
        for _, questLineInfo in ipairs(questLines) do
            if questLineInfo.questID then
                -- Check if this quest is related to the hub
                local isRelated = C_QuestHub.IsQuestCurrentlyRelatedToHub(questLineInfo.questID, hubAreaPoiID)
                if isRelated then
                    relatedQuests[questLineInfo.questID] = {
                        questID = questLineInfo.questID,
                        questName = questLineInfo.questName,
                        questLineID = questLineInfo.questLineID,
                        questLineName = questLineInfo.questLineName,
                        isLegendary = questLineInfo.isLegendary,
                        isCampaign = questLineInfo.isCampaign,
                        isImportant = questLineInfo.isImportant,
                    }
                end
            end
        end
    end

    return relatedQuests
end

---
-- Add Quest Hub related quests to a tooltip
-- @param tooltip       The GameTooltip to add to
-- @param mapID         The map ID
-- @param hubAreaPoiID  The areaPoiID of the Quest Hub
-- @return              Number of quests added
--
function Nx.Quest:AddQuestHubTooltipData(tooltip, mapID, hubAreaPoiID)
    if not tooltip or not mapID or not hubAreaPoiID then
        return 0
    end

    local relatedQuests = self:GetRelatedQuestOffersForHub(mapID, hubAreaPoiID)

    -- Count quests
    local questCount = 0
    for _ in pairs(relatedQuests) do
        questCount = questCount + 1
    end

    if questCount == 0 then
        return 0
    end

    -- Add header
    GameTooltip_AddBlankLineToTooltip(tooltip)
    if QUEST_HUB_TOOLTIP_AVAILABLE_QUESTS_HEADER then
        GameTooltip_AddHighlightLine(tooltip, QUEST_HUB_TOOLTIP_AVAILABLE_QUESTS_HEADER)
    else
        GameTooltip_AddHighlightLine(tooltip, "Available Quests:")
    end

    -- Add quest names (limit to 5)
    local displayed = 0
    local maxDisplay = 5

    -- Sort quests by priority (Campaign > Important > Legendary > Normal)
    local sortedQuests = {}
    for questID, questInfo in pairs(relatedQuests) do
        table.insert(sortedQuests, questInfo)
    end
    table.sort(sortedQuests, function(a, b)
        -- Campaign first
        if a.isCampaign ~= b.isCampaign then
            return a.isCampaign
        end
        -- Then Important
        if a.isImportant ~= b.isImportant then
            return a.isImportant
        end
        -- Then Legendary
        if a.isLegendary ~= b.isLegendary then
            return a.isLegendary
        end
        -- Then alphabetical
        return (a.questName or "") < (b.questName or "")
    end)

    for _, questInfo in ipairs(sortedQuests) do
        if displayed < maxDisplay then
            local questName = questInfo.questName or ("Quest " .. questInfo.questID)
            local prefix = ""
            if questInfo.isCampaign then
                prefix = "|cFFFFD100" -- Gold for campaign
            elseif questInfo.isImportant then
                prefix = "|cFFFF8000" -- Orange for important
            elseif questInfo.isLegendary then
                prefix = "|cFFFF8000" -- Orange for legendary
            else
                prefix = "|cFFFFFFFF" -- White for normal
            end
            GameTooltip_AddNormalLine(tooltip, prefix .. "  " .. questName .. "|r")
            displayed = displayed + 1
        end
    end

    -- Show overflow count
    if questCount > maxDisplay then
        local remaining = questCount - maxDisplay
        if QUEST_HUB_TOOLTIP_MORE_QUESTS_REMAINING then
            GameTooltip_AddNormalLine(tooltip, QUEST_HUB_TOOLTIP_MORE_QUESTS_REMAINING:format(remaining))
        else
            GameTooltip_AddNormalLine(tooltip, "  +" .. remaining .. " more quests")
        end
    end

    return questCount
end

-------------------------------------------------------------------------------
-- QUEST OFFER MAP ICONS
-- Functions to display quest offers on the Carbonite map
-------------------------------------------------------------------------------

-- Quest offer icon atlas based on classification
local questOfferAtlas = {
    Normal = "QuestNormal",
    Questline = "QuestNormal",
    Recurring = "UI-QuestPoiRecurring-QuestBang",
    Meta = "quest-wrapper-available",
    Calling = "Quest-DailyCampaign-Available",
    Campaign = "Quest-Campaign-Available",
    Legendary = "UI-QuestPoiLegendary-QuestBang",
    Important = "importantavailablequesticon",
}

-- Cache for quest offers
Nx.Quest.QuestOfferCache = nil
Nx.Quest.QuestOfferCacheMapID = nil
Nx.Quest.QuestOfferCacheTime = 0

function Nx.Quest:ClearQuestOfferCache()
    self.QuestOfferCache = nil
    self.QuestOfferCacheMapID = nil
    self.QuestOfferCacheTime = 0
end

local function IsInstanceQuestIconContext(mapID)
    return Nx.Map and Nx.Map.IsInstanceDisplayContext
        and Nx.Map:IsInstanceDisplayContext(mapID) or false
end

---
-- Get all quest offers for a map
-- @param mapID  The map ID to get quest offers for
-- @return       Table of quest offers {questID = questInfo, ...}
--
function Nx.Quest:GetQuestOffersForMap(mapID)
    if not mapID or IsInstanceQuestIconContext(mapID) then
        return {}
    end

    -- Check if required APIs exist
    if not C_QuestLine or not C_QuestLine.GetAvailableQuestLines then
        return {}
    end

    -- Use cache if valid (same map, less than 2 seconds old)
    local now = GetTime()
    if self.QuestOfferCache and self.QuestOfferCacheMapID == mapID and (now - self.QuestOfferCacheTime) < 2 then
        return self.QuestOfferCache
    end

    local questOffers = {}

    -- Get quest hubs for the map to filter out hub-related quests (unless toggled on)
    local questHubIds = {}
    local toggledHubs = Nx.Map and Nx.Map.QuestHubToggles or {}
    if C_AreaPoiInfo and C_AreaPoiInfo.GetQuestHubsForMap then
        local hubs = C_AreaPoiInfo.GetQuestHubsForMap(mapID)
        if hubs then
            for _, hubAreaPoiID in ipairs(hubs) do
                local hubKey = mapID .. "_" .. hubAreaPoiID
                -- Only add to filter if hub is NOT toggled on
                if not toggledHubs[hubKey] then
                    questHubIds[hubAreaPoiID] = true
                end
            end
        end
    end

    -- Helper function to check if quest is related to any non-toggled hub
    -- If a hub is toggled on, we want to show its quests, so don't filter them out
    local function isQuestRelatedToNonToggledHub(questID)
        if not C_QuestHub or not C_QuestHub.IsQuestCurrentlyRelatedToHub then
            return false
        end
        for hubAreaPoiID in pairs(questHubIds) do
            if C_QuestHub.IsQuestCurrentlyRelatedToHub(questID, hubAreaPoiID) then
                return true
            end
        end
        return false
    end

    -- Get available quest lines for the map
    local questLines = C_QuestLine.GetAvailableQuestLines(mapID)
    if questLines then
        for _, info in ipairs(questLines) do
            -- C_QuestLine.GetAvailableQuestLines returns every node
            -- in every quest line known for this map — including
            -- accepted quests (inProgress=true) and mid-line nodes
            -- (isQuestStart=false). Only ones that are actually a
            -- "new quest available to pick up here" deserve the
            -- yellow ! marker. isQuestStart may not exist on older
            -- flavors (MoP Classic etc.) — treat nil as "yes,
            -- counts as a start" so we don't filter everything out.
            -- (isAccountCompleted means the player has done it
            -- before on this account — not relevant for a fresh
            -- character, so don't filter on that.)
            local isStart = info.isQuestStart
            if isStart == nil then isStart = true end
            if info.questID and isStart and not info.inProgress then
                -- Skip quests that are related to a non-toggled Quest Hub (they'll show in hub tooltip)
                -- If a hub is toggled on (expanded), show its quests on the map
                if not isQuestRelatedToNonToggledHub(info.questID) then
                    -- Get quest classification
                    local questClassification = nil
                    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
                        questClassification = C_QuestInfoSystem.GetQuestClassification(info.questID)
                    end
                    
                    -- Determine atlas icon
                    local atlas = "QuestNormal"
                    local priority = 1
                    if questClassification then
                        if questClassification == Enum.QuestClassification.Legendary then
                            atlas = questOfferAtlas.Legendary
                            priority = 6
                        elseif questClassification == Enum.QuestClassification.Important then
                            atlas = questOfferAtlas.Important
                            priority = 7
                        elseif questClassification == Enum.QuestClassification.Campaign then
                            atlas = questOfferAtlas.Campaign
                            priority = 5
                        elseif questClassification == Enum.QuestClassification.Calling then
                            atlas = questOfferAtlas.Calling
                            priority = 4
                        elseif questClassification == Enum.QuestClassification.Meta then
                            atlas = questOfferAtlas.Meta
                            priority = 3
                        elseif questClassification == Enum.QuestClassification.Recurring then
                            atlas = questOfferAtlas.Recurring
                            priority = 2
                        end
                    elseif info.isLegendary then
                        atlas = questOfferAtlas.Legendary
                        priority = 6
                    elseif info.isCampaign then
                        atlas = questOfferAtlas.Campaign
                        priority = 5
                    elseif info.isImportant then
                        atlas = questOfferAtlas.Important
                        priority = 7
                    end
                    
                    -- Check if quest should be hidden
                    local isHidden = false
                    if C_QuestLog and C_QuestLog.IsQuestTrivial then
                        isHidden = C_QuestLog.IsQuestTrivial(info.questID)
                    end
                    
                    -- Skip hidden quests unless tracking them
                    local skipHidden = isHidden and C_Minimap and C_Minimap.IsTrackingHiddenQuests and not C_Minimap.IsTrackingHiddenQuests()
                    if not skipHidden then
                        questOffers[info.questID] = {
                            questID = info.questID,
                            questName = info.questName,
                            questLineID = info.questLineID,
                            questLineName = info.questLineName,
                            isLegendary = info.isLegendary,
                            isCampaign = info.isCampaign,
                            isImportant = info.isImportant,
                            isHidden = isHidden,
                            x = info.x,
                            y = info.y,
                            atlas = atlas,
                            priority = priority,
                            floorLocation = info.floorLocation,
                        }
                    end
                end
            end
        end
    end

    -- Cache the results
    self.QuestOfferCache = questOffers
    self.QuestOfferCacheMapID = mapID
    self.QuestOfferCacheTime = now

    return questOffers
end

---
-- Update quest offer icons on the map
-- Called from map update loop
-- @param map  The Carbonite map object
--
function Nx.Quest:UpdateQuestOfferIcons(map)
    if not map or not Nx.qdb or not Nx.qdb.profile or not Nx.qdb.profile.Quest then
        return
    end

    -- Check if quest offer display is enabled
    if not Nx.qdb.profile.Quest.ShowQuestOffers then
        return
    end

    local mapID = map.MapId
    if not mapID then
        return
    end
    if IsInstanceQuestIconContext(mapID) then
        self:ClearQuestOfferCache()
        return
    end

    local questOffers = self:GetQuestOffersForMap(mapID)

    for questID, offer in pairs(questOffers) do
        if offer.x and offer.y then
            -- Get world position
            local wx, wy = map:GetWorldPos(mapID, offer.x * 100, offer.y * 100)
            
            -- Get icon frame
            local icon = map:GetIcon(1)

            -- 10-unit footprint (was 16) — ClipFrameTL multiplies by
            -- map.ScaleDraw so the previous 16 ended up huge at
            -- typical zoom levels. Half-offset keeps the icon
            -- centered on (wx, wy).
            if map:ClipFrameTL(icon, wx - 5, wy - 5, 10, 10, 0) then
                -- Set atlas texture
                if offer.atlas then
                    icon.texture:SetAtlas(offer.atlas)
                else
                    icon.texture:SetTexture("Interface\\Minimap\\ObjectIcons")
                    icon.texture:SetTexCoord(0.125, 0.25, 0, 0.25) -- Quest icon
                end
                
                -- Alpha for hidden quests
                if offer.isHidden then
                    icon.texture:SetVertexColor(1, 1, 1, 0.5)
                else
                    icon.texture:SetVertexColor(1, 1, 1, 1)
                end
                
                -- Set tooltip
                local tipText = offer.questName or ("Quest " .. questID)
                if offer.questLineName then
                    tipText = tipText .. "\n|cFF808080" .. offer.questLineName .. "|r"
                end
                if offer.isCampaign then
                    tipText = "|cFFFFD100[Campaign]|r " .. tipText
                elseif offer.isImportant then
                    tipText = "|cFFFF8000[Important]|r " .. tipText
                elseif offer.isLegendary then
                    tipText = "|cFFFF8000[Legendary]|r " .. tipText
                end
                
                icon.NxTip = tipText
                -- Use NXType 8500 range for quest offers (not 9000+ which is for active quests)
                -- This prevents IconOnEnter from treating these as active quest icons
                icon.NXType = 8500
                -- Mark as quest offer - set NXData to nil explicitly to clear stale data
                icon.NXData = nil
                -- Flag to prevent TooltipProcess from adding wrong quest data
                icon.NxQuestOffer = true
            end
        end
    end
end

---
-- Initialize quest offer display options
-- Called during quest system initialization
--
function Nx.Quest:InitQuestOfferOptions()
    -- Add default option if not exists
    if Nx.qdb and Nx.qdb.profile and Nx.qdb.profile.Quest then
        if Nx.qdb.profile.Quest.ShowQuestOffers == nil then
            Nx.qdb.profile.Quest.ShowQuestOffers = true
        end
    end
end
