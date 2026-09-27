-- Carbonite | Compat / Api
-- Shared Blizzard API compatibility layer.
--
-- This module owns version-sensitive API access for Carbonite core and modules.
-- It intentionally captures legacy globals before ApiShims.lua installs any
-- transitional aliases, preventing wrapper recursion on modern clients.

local Carbonite = _G.Carbonite
local Compat = Carbonite.Compat

Compat.Api = Compat.Api or {}
local Api = Compat.Api

-------------------------------------------------------------------------------
-- Captured Blizzard APIs
-------------------------------------------------------------------------------

local C_AddOns = _G.C_AddOns
local C_Container = _G.C_Container
local C_Item = _G.C_Item
local C_QuestLog = _G.C_QuestLog
local C_Spell = _G.C_Spell
local C_UnitAuras = _G.C_UnitAuras

local LegacyIsAddOnLoaded = _G.IsAddOnLoaded
local LegacyLoadAddOn = _G.LoadAddOn
local LegacyEnableAddOn = _G.EnableAddOn
local LegacyDisableAddOn = _G.DisableAddOn
local LegacyGetAddOnInfo = _G.GetAddOnInfo
local LegacyGetAddOnMetadata = _G.GetAddOnMetadata

local LegacyGetContainerNumSlots = _G.GetContainerNumSlots
local LegacyGetContainerItemID = _G.GetContainerItemID
local LegacyGetContainerItemInfo = _G.GetContainerItemInfo
local LegacyGetContainerItemLink = _G.GetContainerItemLink
local LegacyPickupContainerItem = _G.PickupContainerItem
local LegacyUseContainerItem = _G.UseContainerItem

local LegacyGetItemInfo = _G.GetItemInfo
local LegacyGetItemQualityColor = _G.GetItemQualityColor
local LegacyGetItemIcon = _G.GetItemIcon

local LegacyGetQuestLogTitle = _G.GetQuestLogTitle
local LegacyGetNumQuestLogEntries = _G.GetNumQuestLogEntries
local LegacyGetQuestLogSelection = _G.GetQuestLogSelection
local LegacySelectQuestLogEntry = _G.SelectQuestLogEntry
local LegacyGetQuestLogPushable = _G.GetQuestLogPushable
local LegacyGetQuestLogIsAutoComplete = _G.GetQuestLogIsAutoComplete
local LegacyGetQuestLogIndexByID = _G.GetQuestLogIndexByID
local LegacyGetNumQuestLeaderBoards = _G.GetNumQuestLeaderBoards
local LegacyGetQuestLogLeaderBoard = _G.GetQuestLogLeaderBoard
local LegacyGetQuestLogQuestText = _G.GetQuestLogQuestText
local LegacyGetQuestLogTimeLeft = _G.GetQuestLogTimeLeft

local LegacyGetSpellInfo = _G.GetSpellInfo
local LegacyGetSpellLink = _G.GetSpellLink
local LegacyGetSpellTexture = _G.GetSpellTexture
local LegacyDoesSpellExist = _G.DoesSpellExist

local LegacyUnitAura = _G.UnitAura

local canaccessvalue = _G.canaccessvalue
local issecretvalue = _G.issecretvalue

-------------------------------------------------------------------------------
-- Value safety
-------------------------------------------------------------------------------

Api.Value = Api.Value or {}
local Value = Api.Value

function Value:CanAccess(value)
    if canaccessvalue and not canaccessvalue(value) then
        return false
    end
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return true
end

function Value:Number(value, fallback)
    if not self:CanAccess(value) then
        return fallback
    end
    local number = tonumber(value)
    if number == nil then
        return fallback
    end
    return number
end

-------------------------------------------------------------------------------
-- AddOn API
-------------------------------------------------------------------------------

Api.AddOn = Api.AddOn or {}
local AddOn = Api.AddOn

function AddOn:IsLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    if LegacyIsAddOnLoaded then
        return LegacyIsAddOnLoaded(name)
    end
    return false
end

function AddOn:Load(name)
    if C_AddOns and C_AddOns.LoadAddOn then
        return C_AddOns.LoadAddOn(name)
    end
    if LegacyLoadAddOn then
        return LegacyLoadAddOn(name)
    end
end

function AddOn:Enable(name, character)
    if C_AddOns and C_AddOns.EnableAddOn then
        return C_AddOns.EnableAddOn(name, character)
    end
    if LegacyEnableAddOn then
        return LegacyEnableAddOn(name, character)
    end
end

function AddOn:Disable(name, character)
    if C_AddOns and C_AddOns.DisableAddOn then
        return C_AddOns.DisableAddOn(name, character)
    end
    if LegacyDisableAddOn then
        return LegacyDisableAddOn(name, character)
    end
end

function AddOn:GetInfo(nameOrIndex)
    if C_AddOns and C_AddOns.GetAddOnInfo then
        return C_AddOns.GetAddOnInfo(nameOrIndex)
    end
    if LegacyGetAddOnInfo then
        return LegacyGetAddOnInfo(nameOrIndex)
    end
end

function AddOn:GetMetadata(name, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, field)
    end
    if LegacyGetAddOnMetadata then
        return LegacyGetAddOnMetadata(name, field)
    end
end

-------------------------------------------------------------------------------
-- Item API
-------------------------------------------------------------------------------

Api.Item = Api.Item or {}
local Item = Api.Item

function Item:GetInfo(item)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    end
    if LegacyGetItemInfo then
        return LegacyGetItemInfo(item)
    end
end

function Item:GetQualityColor(quality)
    if C_Item and C_Item.GetItemQualityColor then
        return C_Item.GetItemQualityColor(quality)
    end
    if LegacyGetItemQualityColor then
        return LegacyGetItemQualityColor(quality)
    end
    return 1, 1, 1, "ffffffff"
end

function Item:GetIcon(item)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(item)
    end
    if LegacyGetItemIcon then
        return LegacyGetItemIcon(item)
    end
end

function Item:GetID(item)
    if type(item) == "number" then
        return item
    end
    if type(item) ~= "string" then
        return nil
    end

    local numericID = tonumber(item)
    if numericID then
        return numericID
    end
    return tonumber(string.match(item, "item:(%d+)"))
end

function Item:RequestData(item)
    local itemID = self:GetID(item)
    if not itemID then
        return nil
    end

    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    elseif LegacyGetItemInfo then
        -- Legacy GetItemInfo also initiates the asynchronous cache request.
        LegacyGetItemInfo(itemID)
    end
    return itemID
end

-------------------------------------------------------------------------------
-- Container API
-------------------------------------------------------------------------------

Api.Container = Api.Container or {}
local Container = Api.Container

local function NormalizeLegacyContainerItemInfo(iconFileID, stackCount, isLocked,
        quality, isReadable, hasLoot, hyperlink, isFiltered, hasNoValue,
        itemID, isBound)
    if not iconFileID and not hyperlink and not itemID then
        return nil
    end
    return {
        iconFileID = iconFileID,
        stackCount = stackCount,
        isLocked = isLocked,
        quality = quality,
        isReadable = isReadable,
        hasLoot = hasLoot,
        hyperlink = hyperlink,
        isFiltered = isFiltered,
        hasNoValue = hasNoValue,
        itemID = itemID,
        isBound = isBound,
    }
end

function Container:GetNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if LegacyGetContainerNumSlots then
        return LegacyGetContainerNumSlots(bag) or 0
    end
    return 0
end

function Container:GetItemID(bag, slot)
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    end
    if LegacyGetContainerItemID then
        return LegacyGetContainerItemID(bag, slot)
    end
end

function Container:GetItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    end
    if LegacyGetContainerItemInfo then
        return NormalizeLegacyContainerItemInfo(LegacyGetContainerItemInfo(bag, slot))
    end
end

function Container:GetLegacyItemInfo(bag, slot)
    local info = self:GetItemInfo(bag, slot)
    if not info then
        return nil
    end
    return info.iconFileID, info.stackCount, info.isLocked, info.quality,
        info.isReadable, info.hasLoot, info.hyperlink, info.isFiltered,
        info.hasNoValue, info.itemID, info.isBound
end

function Container:GetItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if LegacyGetContainerItemLink then
        return LegacyGetContainerItemLink(bag, slot)
    end
end

function Container:PickupItem(bag, slot)
    if C_Container and C_Container.PickupContainerItem then
        return C_Container.PickupContainerItem(bag, slot)
    end
    if LegacyPickupContainerItem then
        return LegacyPickupContainerItem(bag, slot)
    end
end

function Container:UseItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        return C_Container.UseContainerItem(bag, slot)
    end
    if LegacyUseContainerItem then
        return LegacyUseContainerItem(bag, slot)
    end
end

-------------------------------------------------------------------------------
-- Spell API
-------------------------------------------------------------------------------

Api.Spell = Api.Spell or {}
local Spell = Api.Spell

function Spell:GetInfo(spellIdentifier)
    if spellIdentifier == nil then
        return nil
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellIdentifier)
        if type(info) == "table" then
            return info
        end
    end

    if LegacyGetSpellInfo then
        local name, subName, iconID, castTime, minRange, maxRange,
            spellID, originalIconID = LegacyGetSpellInfo(spellIdentifier)
        if name then
            return {
                name = name,
                subName = subName,
                iconID = iconID,
                originalIconID = originalIconID or iconID,
                castTime = castTime,
                minRange = minRange,
                maxRange = maxRange,
                spellID = spellID,
            }
        end
    end
end

function Spell:GetLegacyInfo(spellIdentifier)
    local info = self:GetInfo(spellIdentifier)
    if not info then
        return nil
    end
    return info.name, info.subName, info.iconID, info.castTime,
        info.minRange, info.maxRange, info.spellID, info.originalIconID
end

function Spell:GetName(spellIdentifier)
    local info = self:GetInfo(spellIdentifier)
    return info and info.name or nil
end

function Spell:GetLink(spellIdentifier)
    if C_Spell and C_Spell.GetSpellLink then
        return C_Spell.GetSpellLink(spellIdentifier)
    end
    if LegacyGetSpellLink then
        return LegacyGetSpellLink(spellIdentifier)
    end
end

function Spell:GetTexture(spellIdentifier)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellIdentifier)
    end
    if LegacyGetSpellTexture then
        return LegacyGetSpellTexture(spellIdentifier)
    end
end

function Spell:Exists(spellIdentifier)
    if C_Spell and C_Spell.DoesSpellExist then
        return C_Spell.DoesSpellExist(spellIdentifier)
    end
    if LegacyDoesSpellExist then
        return LegacyDoesSpellExist(spellIdentifier)
    end
    return self:GetInfo(spellIdentifier) ~= nil
end

-------------------------------------------------------------------------------
-- Aura API
-------------------------------------------------------------------------------

Api.Aura = Api.Aura or {}
local Aura = Api.Aura

function Aura:GetByIndex(unit, index, filter)
    if not unit or not index then
        return nil
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
    end

    if LegacyUnitAura then
        local name, icon, applications, dispelName, duration, expirationTime,
            sourceUnit, isStealable, nameplateShowPersonal, spellId,
            canApplyAura, isBossAura, castByPlayer, nameplateShowAll,
            timeMod = LegacyUnitAura(unit, index, filter)
        if name then
            return {
                name = name,
                icon = icon,
                applications = applications,
                dispelName = dispelName,
                duration = duration,
                expirationTime = expirationTime,
                sourceUnit = sourceUnit,
                isStealable = isStealable,
                nameplateShowPersonal = nameplateShowPersonal,
                spellId = spellId,
                canApplyAura = canApplyAura,
                isBossAura = isBossAura,
                isFromPlayerOrPlayerPet = castByPlayer,
                nameplateShowAll = nameplateShowAll,
                timeMod = timeMod,
            }
        end
    end
end

-------------------------------------------------------------------------------
-- Unit API
-------------------------------------------------------------------------------

Api.Unit = Api.Unit or {}
local Unit = Api.Unit

function Unit:GetName(unit)
    if not _G.UnitName then
        return nil
    end
    local name, realm = _G.UnitName(unit)
    if not Value:CanAccess(name) or not Value:CanAccess(realm) then
        return nil, nil
    end
    return name, realm
end

function Unit:GetGUID(unit)
    if not _G.UnitGUID then
        return nil
    end
    local guid = _G.UnitGUID(unit)
    if not Value:CanAccess(guid) then
        return nil
    end
    return guid
end

function Unit:GetLevel(unit)
    if not _G.UnitLevel then
        return nil
    end
    local level = _G.UnitLevel(unit)
    if not Value:CanAccess(level) then
        return nil
    end
    return level
end

function Unit:GetPosition(unit)
    if not _G.UnitPosition then
        return nil
    end
    local x, y, z, instanceID = _G.UnitPosition(unit)
    if not Value:CanAccess(x) or not Value:CanAccess(y)
            or not Value:CanAccess(z) or not Value:CanAccess(instanceID) then
        return nil
    end
    return x, y, z, instanceID
end

function Unit:IsPlayer(unit)
    if not _G.UnitIsPlayer then
        return false
    end
    local result = _G.UnitIsPlayer(unit)
    if not Value:CanAccess(result) then
        return false
    end
    return result and true or false
end

-------------------------------------------------------------------------------
-- Quest log API
-------------------------------------------------------------------------------

Api.Quest = Api.Quest or {}
local Quest = Api.Quest

local function LegacyQuestInfo(logIndex)
    if not LegacyGetQuestLogTitle then
        return nil
    end

    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
        frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI,
        isTask, isBounty, isStory, isHidden, isScaling =
        LegacyGetQuestLogTitle(logIndex)

    if title == nil then
        return nil
    end

    return {
        title = title,
        level = level,
        suggestedGroup = suggestedGroup,
        isHeader = isHeader,
        isCollapsed = isCollapsed,
        isComplete = isComplete,
        frequency = frequency,
        questID = questID,
        startEvent = startEvent,
        displayQuestID = displayQuestID or questID,
        isOnMap = isOnMap,
        hasLocalPOI = hasLocalPOI,
        isTask = isTask,
        isBounty = isBounty,
        isStory = isStory,
        isHidden = isHidden,
        isScaling = isScaling,
    }
end

function Quest:GetInfo(logIndex)
    if not logIndex then
        return nil
    end

    if C_QuestLog and C_QuestLog.GetInfo then
        return C_QuestLog.GetInfo(logIndex)
    end
    return LegacyQuestInfo(logIndex)
end

function Quest:GetNumEntries()
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        return C_QuestLog.GetNumQuestLogEntries()
    end
    if LegacyGetNumQuestLogEntries then
        return LegacyGetNumQuestLogEntries()
    end
    return 0, 0
end

function Quest:GetQuestIDForLogIndex(logIndex)
    if not logIndex then
        return nil
    end

    if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
        return C_QuestLog.GetQuestIDForLogIndex(logIndex)
    end

    local info = LegacyQuestInfo(logIndex)
    return info and info.questID or nil
end

function Quest:GetLogIndexForQuestID(questID)
    if not questID then
        return 0
    end

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        return C_QuestLog.GetLogIndexForQuestID(questID) or 0
    end

    if LegacyGetQuestLogIndexByID then
        return LegacyGetQuestLogIndexByID(questID) or 0
    end

    local numEntries = self:GetNumEntries()
    for index = 1, numEntries do
        if self:GetQuestIDForLogIndex(index) == questID then
            return index
        end
    end
    return 0
end

function Quest:GetSelectedLogIndex()
    if C_QuestLog and C_QuestLog.GetSelectedQuest then
        local questID = C_QuestLog.GetSelectedQuest()
        if questID and questID > 0 then
            return self:GetLogIndexForQuestID(questID)
        end
        return 0
    end

    if LegacyGetQuestLogSelection then
        return LegacyGetQuestLogSelection() or 0
    end
    return 0
end

function Quest:GetSelectedQuestID()
    if C_QuestLog and C_QuestLog.GetSelectedQuest then
        return C_QuestLog.GetSelectedQuest()
    end

    local index = self:GetSelectedLogIndex()
    if index > 0 then
        return self:GetQuestIDForLogIndex(index)
    end
end

function Quest:SetSelectedLogIndex(logIndex)
    if not logIndex or logIndex <= 0 then
        return false
    end

    if C_QuestLog and C_QuestLog.SetSelectedQuest then
        local questID = self:GetQuestIDForLogIndex(logIndex)
        if questID and questID > 0 then
            C_QuestLog.SetSelectedQuest(questID)
            return true
        end
        return false
    end

    if LegacySelectQuestLogEntry then
        LegacySelectQuestLogEntry(logIndex)
        return true
    end
    return false
end

function Quest:SetSelectedQuestID(questID)
    if not questID or questID <= 0 then
        return false
    end

    if C_QuestLog and C_QuestLog.SetSelectedQuest then
        C_QuestLog.SetSelectedQuest(questID)
        return true
    end

    local logIndex = self:GetLogIndexForQuestID(questID)
    if logIndex > 0 and LegacySelectQuestLogEntry then
        LegacySelectQuestLogEntry(logIndex)
        return true
    end
    return false
end

function Quest:IsSelectedQuestPushable()
    if C_QuestLog and C_QuestLog.GetSelectedQuest and C_QuestLog.IsPushableQuest then
        local questID = C_QuestLog.GetSelectedQuest()
        if questID and questID > 0 then
            return C_QuestLog.IsPushableQuest(questID)
        end
        return false
    end

    if LegacyGetQuestLogPushable then
        return LegacyGetQuestLogPushable()
    end
    return false
end

function Quest:IsAutoCompleteForLogIndex(logIndex)
    if C_QuestLog and C_QuestLog.GetInfo then
        local info = C_QuestLog.GetInfo(logIndex)
        return info and info.isAutoComplete and true or false
    end

    if LegacyGetQuestLogIsAutoComplete then
        return LegacyGetQuestLogIsAutoComplete(logIndex) and true or false
    end
    return false
end

function Quest:GetObjectivesForQuestID(questID)
    if not questID or questID <= 0 then
        return nil
    end

    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
        if ok and objectives then
            return objectives
        end
    end

    local logIndex = self:GetLogIndexForQuestID(questID)
    if logIndex <= 0 or not LegacyGetNumQuestLeaderBoards
            or not LegacyGetQuestLogLeaderBoard then
        return nil
    end

    local count = LegacyGetNumQuestLeaderBoards(logIndex) or 0
    if count <= 0 then
        return {}
    end

    local objectives = {}
    for objectiveIndex = 1, count do
        local text, objectiveType, finished =
            LegacyGetQuestLogLeaderBoard(objectiveIndex, logIndex)
        objectives[objectiveIndex] = {
            text = text,
            type = objectiveType,
            finished = finished and true or false,
        }
    end
    return objectives
end

function Quest:GetObjectivesForLogIndex(logIndex)
    local questID = self:GetQuestIDForLogIndex(logIndex)
    if questID and questID > 0 then
        local objectives = self:GetObjectivesForQuestID(questID)
        if objectives then
            return objectives
        end
    end

    if not logIndex or logIndex <= 0 or not LegacyGetNumQuestLeaderBoards
            or not LegacyGetQuestLogLeaderBoard then
        return nil
    end

    local count = LegacyGetNumQuestLeaderBoards(logIndex) or 0
    local objectives = {}
    for objectiveIndex = 1, count do
        local text, objectiveType, finished =
            LegacyGetQuestLogLeaderBoard(objectiveIndex, logIndex)
        objectives[objectiveIndex] = {
            text = text,
            type = objectiveType,
            finished = finished and true or false,
        }
    end
    return objectives
end

function Quest:GetNumObjectivesForLogIndex(logIndex)
    if not logIndex or logIndex <= 0 then
        return 0
    end

    -- Preserve the lightweight indexed API when Blizzard still provides it.
    -- The structured quest-objective list remains the compatibility fallback.
    if LegacyGetNumQuestLeaderBoards then
        return LegacyGetNumQuestLeaderBoards(logIndex) or 0
    end

    local objectives = self:GetObjectivesForLogIndex(logIndex)
    return objectives and #objectives or 0
end

function Quest:GetObjectiveForLogIndex(objectiveIndex, logIndex)
    if not objectiveIndex or objectiveIndex <= 0 or not logIndex or logIndex <= 0 then
        return nil
    end

    if LegacyGetQuestLogLeaderBoard then
        return LegacyGetQuestLogLeaderBoard(objectiveIndex, logIndex)
    end

    local objectives = self:GetObjectivesForLogIndex(logIndex)
    local objective = objectives and objectives[objectiveIndex]
    if not objective then
        return nil
    end

    return objective.text, objective.type, objective.finished,
        objective.numFulfilled, objective.numRequired, objective.objectiveType
end

function Quest:GetQuestText(logIndex)
    if not LegacyGetQuestLogQuestText then
        return nil
    end
    if logIndex == nil then
        return LegacyGetQuestLogQuestText()
    end
    return LegacyGetQuestLogQuestText(logIndex)
end

function Quest:GetTimeLeft(logIndex)
    if not LegacyGetQuestLogTimeLeft then
        return nil
    end
    if logIndex == nil then
        return LegacyGetQuestLogTimeLeft()
    end
    return LegacyGetQuestLogTimeLeft(logIndex)
end

-- Captured legacy functions are intentionally not exported. ApiShims.lua is
-- the only transitional layer allowed to publish compatibility globals.
