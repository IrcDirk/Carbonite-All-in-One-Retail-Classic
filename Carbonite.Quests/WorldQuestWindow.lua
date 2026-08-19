-- Carbonite.Quests | WorldQuestWindow
-- Window for tracking and filtering world quests (retail only).
-- Hosts Nx.Quest:OpenWorldQuestList plus the in-window list event
-- handlers, sort / filter logic, and tooltip wiring. Self-contained
-- and only invoked when the user explicitly opens the panel.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed.
local GetQuestObjectiveInfo = _G.GetQuestObjectiveInfo or _G.GetQuestObjectiveInfo
local GetTime = _G.GetTime or _G.GetTime
local format = _G.string.format or _G.format
local sort = _G.table.sort or _G.sort

-- File-locals brought from NxQuest.lua so this extraction can see
-- the same shared state. NxQuest.lua publishes them onto Nx.Quest.*
-- before this file loads.
local worldquestdb  = Nx.Quest.worldquestdb
local worldquesttip = Nx.Quest.worldquesttip
local ITEM_LEVEL    = Nx.Quest.ITEM_LEVEL

-- Promoted from NxQuest.lua's file-local compat shim.
local GetQuestTagInfoCompat = Nx.Quest.GetQuestTagInfoCompat

-------------------------------------------------------------------------------
-- WORLD QUEST LIST WINDOW
-- Window for tracking and filtering world quests
-------------------------------------------------------------------------------

---
-- Open and initialize the world quest list window
--
function Nx.Quest.WQList:Open()
    self.GOpts = opts
    local qopts = Nx.Quest:GetQuestOpts()
    local win = Nx.Window:Create("NxQuestWQList", nil, nil, nil, 1, false)
    local xo, yo = 7,3
    Nx.Window:SetCreateFade (1, .15)
    self.Opened = true
    self.Win = win
    win:InitLayoutData (nil, -.80, -.35, -.2, -.1)
    win:CreateButtons (true, nil, nil)
    win:SetBGAlpha (0, 1)
    win:SetBorderSize (0, 7)
    win.Sizeable = false
    win:SetTitleXOff (84 + xo, -1 - yo)
    win.Frm:SetClampedToScreen (true)
    win.UserUpdateFade = self.WinUpdateFade
    win:SetTitle (L["World Quest Tracker"])
    local function update (self)
        self:Update()
    end
    local function func (self)
        self.Menu:Open()
    end
    self.ButMenu = Nx.Button:Create (win.Frm, "WQListMenu", nil, nil, 4, -5 + yo, "TOPLEFT", 1, 1, func, self)
    local function func (self)
        self.MenuPri:Open()
    end
    Nx.List:SetCreateFont ("QuestWatch.WatchFont", 12)
    local list = Nx.List:Create (false, 2, -2, 100, 12 * 3, win.Frm, true, true)
    self.List = list
    list:SetMinSize (200, 20)
    list.Frm:EnableMouse (false)
    list:ColumnAdd ("", 1, 14)
    list:ColumnAdd ("Name", 2, 120)
    list:ColumnAdd ("", 3, 0)
    list:ColumnAdd ("Faction", 4, 20)
    list:ColumnAdd ("Reward", 5, 40)
    list:ColumnAdd ("Time Left", 6, 20)
    win:Attach (list.Frm, 0, 1, 0, 1)
    list:SetUser (self, self.OnListEvent)

    local wqlist = Nx.Quest.WQList
    local menu = Nx.Menu:Create (list.Frm)
    self.Menu = menu

    local function func ()
        self:Update()
    end

    local item = menu:AddItem (0, L["Show Gold Rewards"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showgold")
    local item = menu:AddItem (0, L["Show AP Rewards"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showap")
    local item = menu:AddItem (0, L["Show Order Resource Rewards"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showorder")
    local item = menu:AddItem (0, L["Show Gear Rewards"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showgear")
    local item = menu:AddItem (0, L["Show PVP Rewards"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showpvp")
    local item = menu:AddItem (0, L["Show Other Rewards"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showother")
    local item = menu:AddItem (0, "", func, wqlist)
    local item = menu:AddItem (0, L["Court of Farondis"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showfaronis")
    local item = menu:AddItem (0, L["Dreamweavers"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showdreamweaver")
    local item = menu:AddItem (0, L["Highmountain Tribe"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showhighmountain")
    local item = menu:AddItem (0, L["Armies of Legionfall"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showlegionfall")
    local item = menu:AddItem (0, L["Nightfallen"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "shownightfallen")
    local item = menu:AddItem (0, L["Wardens"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showwardens")
    local item = menu:AddItem (0, L["Kirin Tor"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showkirintor")
    local item = menu:AddItem (0, L["Army of the Light"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showarmyoflight")
    local item = menu:AddItem (0, L["Argussian Reach"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showargussian")
    local item = menu:AddItem (0, L["Valarjar"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showvalarjar")
    local item = menu:AddItem (0, "", func, wqlist)
    local item = menu:AddItem (0, L["Color Active Faction Bounties"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "bountycolor")
    local item = menu:AddItem (0, L["Current Zone Only"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "zoneonly")
    local item = menu:AddItem (0, L["Faction Bounties Only"], func, wqlist)
    item:SetChecked (Nx.qdb.profile.WQList, "showbounty")
    self.FirstUpdate = true
    self.FlashColor = 0
    LibStub("AceEvent-3.0"):Embed(Nx.Quest.WQList)
    Nx.Quest.WQList:RegisterEvent ("QUEST_LOG_UPDATE", "UpdateDB")
    Nx.Quest.WQList:RegisterEvent ("UNIT_QUEST_LOG_CHANGED", "UpdateDB")
    --C_Timer.NewTicker(30, function() Nx.Quest.WQList:UpdateDB() end)
    Nx.Quest.WQList:RegisterEvent ("ZONE_CHANGED_NEW_AREA", "Update")
    win.Frm:SetScript ("OnShow",self.UpdateDB)
--    self:SetSortMode (1)
    win.Frm:Hide()
end

---
-- Update world quest list window fade
-- @param fade  Fade alpha value
--
function Nx.Quest.WQList:WinUpdateFade(fade)
    Nx.Quest.WQList.Win:SetTitleColors(1, 1, 1, fade)
    Nx.Quest.WQList.List.Frm:SetAlpha(fade)
    Nx.Quest.WQList.ButMenu.Frm:SetAlpha(fade)
end

---
-- Generate tooltip text for a world quest
-- @param questId  World quest ID
-- @return         Tooltip string
--
function Nx.Quest.WQList:GenWQTip(questId)
    if worldquestdb[questId].tip and worldquestdb[questId].tip ~= false then
        return worldquestdb[questId].tip
    end
    worldquesttip:ClearLines()
    local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questId)
    local questTagInfo = GetQuestTagInfoCompat(questId)
    local tagID = questTagInfo and questTagInfo.tagID
    local tagName = questTagInfo and questTagInfo.tagName
    local worldQuestType = questTagInfo and questTagInfo.worldQuestType
    local rarity = questTagInfo and questTagInfo.quality
    local isElite = questTagInfo and questTagInfo.isElite
    local tradeskillLineIndex = questTagInfo and questTagInfo.tradeskillLineID
    local displayTimeLeft = questTagInfo and questTagInfo.displayExpiration
    local color = WORLD_QUEST_QUALITY_COLORS[rarity]
    local style = TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT
    local tipdone = false

    worldquesttip:SetText(title, color.r, color.g, color.b)
    QuestUtils_AddQuestTypeToTooltip(worldquesttip, questId, NORMAL_FONT_COLOR)
    if factionID then
        local factionName = GetFactionInfoByID(factionID)
        if factionName then
            if capped then
                worldquesttip:AddLine(factionName, GRAY_FONT_COLOR:GetRGB())
            else
                worldquesttip:AddLine(factionName)
            end
        end
    end

    if displayTimeLeft then
        WorldMap_AddQuestTimeToTooltip(questId)
    end

    for objectiveIndex = 1, worldquestdb[questId].numobjectives do
        local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(questId, objectiveIndex, false)
        if objectiveText and #objectiveText > 0 then
            local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR
            worldquesttip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true)
        end
    end

    local percent = C_TaskQuest.GetQuestProgressBarInfo(questId)
    if percent then
        worldquesttip:AddLine(L["Percent Complete"] .. ":  " .. percent .. "%")
    end

    if (GetQuestLogRewardXP(questId) > 0 or GetNumQuestLogRewardCurrencies(questId) > 0 or GetNumQuestLogRewards(questId) > 0 or GetQuestLogRewardMoney(questId) > 0 or GetQuestLogRewardArtifactXP(questId) > 0 or GetQuestLogRewardHonor(questId)) then
        GameTooltip_AddBlankLinesToTooltip(worldquesttip, style.prefixBlankLineCount)
        worldquesttip:AddLine(style.headerText, style.headerColor.r, style.headerColor.g, style.headerColor.b, style.wrapHeaderText)
        GameTooltip_AddBlankLinesToTooltip(worldquesttip, style.postHeaderBlankLineCount)

        local xp = GetQuestLogRewardXP(questId)
        if ( xp > 0 ) then
            worldquesttip:AddLine(BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(xp), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
            tipdone = true
        end
        local artifactXP = GetQuestLogRewardArtifactXP(questId)
        if ( artifactXP > 0 ) then
            worldquesttip:AddLine(BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactXP), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
            tipdone = true
        end
        local numAddedQuestCurrencies = QuestUtils_AddQuestCurrencyRewardsToTooltip(questId, worldquesttip)
        if ( numAddedQuestCurrencies > 0 ) then
            tipdone = true
        end
        local honorAmount = GetQuestLogRewardHonor(questId)
        if ( honorAmount > 0 ) then
            worldquesttip:AddLine(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format("Interface\\ICONS\\Achievement_LegionPVPTier4", honorAmount, HONOR), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
            tipdone = true
            worldquestdb[questId].PVP = true
        end
        local money = GetQuestLogRewardMoney(questId)
        if ( money > 0 ) then
            worldquesttip:AddLine(Nx.Util_GetMoneyStr (money))
            tipdone = true
        end
        local numQuestRewards = GetNumQuestLogRewards(questId)
        if numQuestRewards > 0 then
            local name,icon,numItems,quality,_,itemID = GetQuestLogRewardInfo(1,questId)
            local color =  BAG_ITEM_QUALITY_COLORS[quality < LE_ITEM_QUALITY_COMMON and LE_ITEM_QUALITY_COMMON or quality]
            if name then
                worldquesttip:AddLine("|T"..icon..":0|t "..(numItems and numItems > 1 and numItems.."x " or "")..name, color.r, color.g, color.b)
                tipdone = true
            end
        end
    end
    if not tipdone then
        return false
    end
    local tip = ""
    for i=1, worldquesttip:NumLines() do
        local line = _G["WQListTipTextLeft" .. i]:GetText()
        local r, g, b = _G["WQListTipTextLeft" .. i]:GetTextColor()
        tip = tip .. format("|cff%02x%02x%02x%s|r\n", r * 255, g * 255, b * 255, line)
    end

    return tip
end

---
-- Get reward type for a world quest
-- @param questId  World quest ID
-- @return         Reward type code (10=AP, 20=gold, 30=resources, 40=gear, false=other)
--
function Nx.Quest.WQList:GetWQReward(questId)
    local reward = ""

    local artxp = GetQuestLogRewardArtifactXP(questId)
    if artxp > 0 then
        return 10
    end
    local items = GetNumQuestLogRewards(questId)
    if items > 0 then
        worldquesttip:ClearLines()
        local name,icon,qty,quality,_,itemID = GetQuestLogRewardInfo(1,questId)
        local foundartifact = false
        worldquesttip:SetQuestLogItem("reward", 1, questId)
        local link = select(2,worldquesttip:GetItem())
        for i=2, worldquesttip:NumLines() do
            local line = _G["WQListTipTextLeft" .. i]:GetText()
            if line and ( line:find(ARTIFACT_POWER.."|r$") or line:find("Artifact Power|r$") ) then
                return 10
            end
            if line and line:find(ITEM_LEVEL) then
                return 40
            end
        end
        worldquesttip:ClearLines()
    end
    local gold = GetQuestLogRewardMoney(questId)
    if gold > 0 then
        return 20
    end
    local numcurrency = GetNumQuestLogRewardCurrencies(questId)
    for i = 1, numcurrency do
        local name, texture, num, id = GetQuestLogRewardCurrencyInfo(i, questId)
        if id == 1220 then
            return 30
        end
    end
    return false
end

---
-- Handle world quest list events
-- @param eventName  Event type
-- @param sel        Selected index
-- @param val2       Additional value
-- @param click      Click info
--
function Nx.Quest.WQList:OnListEvent(eventName, sel, val2, click)
    local itemData = self.List:ItemGetData(sel) or 0
    local shift = IsShiftKeyDown() or eventName == "mid"
    local map = Nx.Map:GetMap(1)
    if eventName == "button" and itemData then
        local title, faction = C_TaskQuest.GetQuestInfoByQuestID(itemData.questid)
        map:SetTargetXY(itemData.mapid, itemData.x, itemData.y, title, false)
    end
end

local WQListUpdateDBTimer

---
-- Update world quest database from API
-- @param event  Event type
-- @param ...    Event arguments
--
function Nx.Quest.WQList:UpdateDB(event, ...)
    if WQListUpdateDBTimer then
        WQListUpdateDBTimer:Cancel()
    end
--    if not Nx.Quest.WQList.Win.Frm:IsVisible() then
--        return
--    end

    local func = function ()
        Nx.prtD("Nx.Quest.WQList:UpdateDB")
        if WQListUpdateDBTimer then
            WQListUpdateDBTimer:Cancel()
        end

        local worldquestzones = { 947, 830, 885, 882, 1355, 1462 }
        for i=1,#worldquestzones do
            local zonequests = {}
            if worldquestzones[i] == 625 then
                zonequests = C_TaskQuest.GetQuestsForPlayerByMapID(worldquestzones[i])
            else
                zonequests = C_TaskQuest.GetQuestsForPlayerByMapID(worldquestzones[i], worldquestzones[i])
            end
            for j, quest in pairs(zonequests) do
                local questId = quest.questId
                C_TaskQuest.RequestPreloadRewardData (questId)
                if questId and QuestUtils_IsQuestWorldQuest (questId) then
                    if not worldquestdb[questId] then
                        worldquestdb[questId] = {}
                    end
                    worldquestdb[questId].x = quest.x * 100
                    worldquestdb[questId].y = quest.y * 100
                    worldquestdb[questId].mapid = C_TaskQuest.GetQuestZoneID(questId) --worldquestzones[i]
                    worldquestdb[questId].questid = questId
                    worldquestdb[questId].numobjectives = quest.numObjectives
                    local tip = Nx.Quest.WQList:GenWQTip(questId)
                    if not worldquestdb[questId].tip and tip then
                        worldquestdb[questId].tip = tip
                    end
                end
            end
        end
        if Nx.Quest.WQList.Win.Frm:IsVisible() then
            Nx.Quest.WQList:Update()
        end
    end

    if event == "QUEST_LOG_UPDATE" then
        Nx.Quest.WQList:UnregisterEvent("QUEST_LOG_UPDATE")
        --C_Timer.After(5, function() Nx.Quest.WQList:UpdateDB() end)
    else
        --WQListUpdateDBTimer = C_Timer.NewTimer(IsInInstance() and 5 or 1, func)
    end
end

---
-- Check if quest counts toward a faction bounty
-- @param questId  World quest ID
-- @return         true if quest is a bounty criteria
--
function Nx.Quest.WQList:CheckBounty(questId)
    local bounties = GetQuestBountyInfoForMapID(1014)
    local isbounty = false
    for bountyIndex, bounty in ipairs(bounties) do
        if IsQuestCriteriaForBounty(questId, bounty.questID) then
            isbounty = true
        end
    end
    return isbounty
end

---
-- Update the world quest list display
--
function Nx.Quest.WQList:Update()
    local list = Nx.Quest.WQList.List
    list:Empty()
    list:ColumnSetWidth(2,120)
    list:ColumnSetWidth(4,20)
    list:ColumnSetWidth(5,40)
    list:ColumnSetWidth(6,20)

    for quest, _ in pairs(worldquestdb) do
        local info = worldquestdb[quest]
        local questId = quest
        local title, faction = C_TaskQuest.GetQuestInfoByQuestID(questId)
        local newwidth = #title * 7 + 10
        local timeleft = C_TaskQuest.GetQuestTimeLeftMinutes(questId) or 0
        local rewardstring = ""
        local isbounty = Nx.Quest.WQList:CheckBounty(questId)

        if timeleft > 0 then
            local reward = Nx.Quest.WQList:GetWQReward(questId)
            if (reward == 10 and not Nx.qdb.profile.WQList.showap) or
               (reward == 20 and not Nx.qdb.profile.WQList.showgold) or
               (reward == 30 and not Nx.qdb.profile.WQList.showorder) or
               (reward == 40 and not Nx.qdb.profile.WQList.showgear) or
               (info.PVP and not Nx.qdb.profile.WQList.showpvp) or
               (faction == 1900 and not Nx.qdb.profile.WQList.showfaronis) or
               (faction == 1883 and not Nx.qdb.profile.WQList.showdreamweaver) or
               (faction == 1828 and not Nx.qdb.profile.WQList.showhighmountain) or
               (faction == 2045 and not Nx.qdb.profile.WQList.showlegionfall) or
               (faction == 1859 and not Nx.qdb.profile.WQList.shownightfallen) or
               (faction == 1894 and not Nx.qdb.profile.WQList.showwardens) or
               (faction == 1948 and not Nx.qdb.profile.WQList.showvalarjar) or
               (faction == 1090 and not Nx.qdb.profile.WQList.showkirintor) or
               (faction == 2165 and not Nx.qdb.profile.WQList.showarmyoflight) or
               (faction == 2170 and not Nx.qdb.profile.WQList.showargussian) or
               (isbounty == false and Nx.qdb.profile.WQList.showbounty) or
               (info.mapid ~= Nx.Map:GetCurrentMapAreaID() and Nx.qdb.profile.WQList.zoneonly) or
               (reward == false and not Nx.qdb.profile.WQList.showother)then
                    worldquestdb[questId].Filtered = true
            else
                local colstring = "|r"
                if isbounty and Nx.qdb.profile.WQList.bountycolor then
                    colstring = "|cff00DD00"
                end
                if newwidth > list:ColumnGetWidth(2) then
                    list:ColumnSetWidth(2,newwidth)
                end
                list:ItemAdd(0)
                list:ItemSet(2,colstring .. title)
                if faction then
                    local factionname = GetFactionInfoByID(faction)
                    newwidth = #factionname * 7 + 10
                    if newwidth > list:ColumnGetWidth(4) then
                        list:ColumnSetWidth(4,newwidth)
                    end
                    list:ItemSet(4,colstring .. factionname)
                end
                if reward == 10 then
                    rewardstring = "Artifact Power"
                elseif reward == 20 then
                    rewardstring = "Gold"
                elseif reward == 30 then
                    rewardstring = "Order Resources"
                elseif reward == 40 then
                    rewardstring = "Gear"
                end
                newwidth = #rewardstring * 7 + 10
                if newwidth > list:ColumnGetWidth(5) then
                    list:ColumnSetWidth (5, newwidth)
                end
                list:ItemSet(5, colstring .. rewardstring)
                local timestr = Nx.Util_GetTimeElapsedStr (timeleft * 60)
                newwidth = #timestr * 7 +10
                if newwidth > list:ColumnGetWidth(6) then
                    list:ColumnSetWidth (6, newwidth)
                end
                list:ItemSet(6,colstring .. timestr)
                list:ItemSetButton ("QuestWatchCustomTip", false)
                list:ItemSetData(list:ItemGetNum(), info)
                if info.tip then
                    list:ItemSetButtonTip(info.tip)
                end
                worldquestdb[questId].Filtered = false
            end
        end
    end
    list:Update()
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
