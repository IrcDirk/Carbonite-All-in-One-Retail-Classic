-- Carbonite.Quests | Blizzard quest-map compatibility
--
-- Blizzard ships two materially different QuestDataProvider implementations:
--   * Classic Era, Burning Crusade Classic, and Mists Classic use the legacy
--     numbered UI-QuestPoi textures and require both questPOI and questHelper.
--   * Retail uses POIButton atlases, filters map-indicator/bonus quests, and
--     adds GetNextWaypointForMap only for the focused or super-tracked quest.
--
-- Keep that client split here instead of scattering project/version checks
-- through MapIcons.lua. Detection is by API capability so a future client can
-- adopt the newer provider without a Carbonite release that hard-codes it.

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

local Compat = {}
Nx.QuestMapCompatibility = Compat

local floor = math.floor
local min = math.min
local max = math.max
local issecretvalue = _G.issecretvalue

local function IsPublicValue(value)
    return value ~= nil
        and (not issecretvalue or not issecretvalue(value))
end

local function ReadCVar(name)
    local getter = _G.C_CVar and _G.C_CVar.GetCVar or _G.GetCVar
    if type(getter) ~= "function" then return nil end

    local ok, value = pcall(getter, name)
    if not ok or not IsPublicValue(value) then return nil end
    return value
end

local function ReadCVarBool(name)
    -- GetCVarBool returns false for an unknown CVar on some clients. Confirm
    -- that the CVar exists first so a removed legacy option cannot disable the
    -- whole Carbonite quest layer.
    if ReadCVar(name) == nil or type(_G.GetCVarBool) ~= "function" then
        return nil
    end

    local ok, value = pcall(_G.GetCVarBool, name)
    if not ok or not IsPublicValue(value) then return nil end
    return value == true
end

function Compat:IsModernQuestDataProvider()
    -- Of the supplied clients, GetNextWaypointForMap exists only in Retail's
    -- POIButton-based QuestDataProvider. The older three archives contain the
    -- identical legacy provider and no per-map waypoint API.
    return _G.C_QuestLog
        and type(_G.C_QuestLog.GetNextWaypointForMap) == "function"
        or false
end

function Compat:AreQuestPOIsEnabled()
    local questPOI = ReadCVarBool("questPOI")
    if questPOI == false then return false end

    -- Era/TBC/Mists Blizzard providers also gate on questHelper. Retail
    -- intentionally stopped doing so. Missing CVars are treated as unknown,
    -- not disabled, to keep the adapter safe during loading and on PTR builds.
    if not self:IsModernQuestDataProvider() then
        local questHelper = ReadCVarBool("questHelper")
        if questHelper == false then return false end
    end

    return true
end

local function IsWorldQuest(questID)
    if type(_G.QuestUtils_IsQuestWorldQuest) == "function" then
        local ok, result = pcall(_G.QuestUtils_IsQuestWorldQuest, questID)
        if ok and IsPublicValue(result) then return result == true end
    end
    if _G.C_QuestLog and type(_G.C_QuestLog.IsWorldQuest) == "function" then
        local ok, result = pcall(_G.C_QuestLog.IsWorldQuest, questID)
        if ok and IsPublicValue(result) then return result == true end
    end
    return false
end

function Compat:ShouldUseQuestMapEntry(questID, mapID, info)
    if not questID or not mapID or not self:AreQuestPOIsEnabled() then
        return false
    end

    local mapInfo
    if _G.C_Map and type(_G.C_Map.GetMapInfo) == "function" then
        local ok, result = pcall(_G.C_Map.GetMapInfo, mapID)
        if ok then mapInfo = result end
    end
    if mapInfo and _G.MapUtil
        and type(_G.MapUtil.ShouldMapTypeShowQuests) == "function" then
        local ok, result = pcall(
            _G.MapUtil.ShouldMapTypeShowQuests,
            mapInfo.mapType
        )
        if ok and result == false then return false end
    end

    -- Carbonite's task provider already owns world/bonus quest pins. Keeping
    -- them out of this regular-quest mirror prevents two independently styled
    -- markers at the same coordinate.
    if IsWorldQuest(questID) then return false end

    if self:IsModernQuestDataProvider() then
        if info and info.isMapIndicatorQuest == true then return false end

        if type(_G.QuestUtils_IsQuestBonusObjective) == "function" then
            local ok, result = pcall(
                _G.QuestUtils_IsQuestBonusObjective,
                questID
            )
            if ok and result == true then return false end
        end

        if type(_G.HaveQuestData) == "function" then
            local ok, result = pcall(_G.HaveQuestData, questID)
            if ok and result == false then return false end
        end
    end

    return true
end

local function GetQuestClassification(questID)
    if _G.C_QuestInfoSystem
        and type(_G.C_QuestInfoSystem.GetQuestClassification) == "function" then
        local ok, value = pcall(
            _G.C_QuestInfoSystem.GetQuestClassification,
            questID
        )
        if ok and IsPublicValue(value) then return value end
    end

    if _G.C_QuestLog
        and type(_G.C_QuestLog.GetLogIndexForQuestID) == "function"
        and type(_G.C_QuestLog.GetInfo) == "function" then
        local okIndex, index = pcall(
            _G.C_QuestLog.GetLogIndexForQuestID,
            questID
        )
        if okIndex and type(index) == "number" and index > 0 then
            local okInfo, info = pcall(_G.C_QuestLog.GetInfo, index)
            if okInfo and type(info) == "table"
                and IsPublicValue(info.questClassification) then
                return info.questClassification
            end
        end
    end
end

local function GetModernAtlasPrefix(questID)
    local classifications = _G.Enum and _G.Enum.QuestClassification
    local classification = GetQuestClassification(questID)
    if not classifications or classification == nil then
        return "UI-QuestPoi", "normal"
    end

    if classification == classifications.Legendary then
        return "UI-QuestPoiLegendary", "legendary"
    elseif classification == classifications.Campaign
        or classification == classifications.Calling then
        return "UI-QuestPoiCampaign",
            classification == classifications.Calling and "calling" or "campaign"
    elseif classification == classifications.Recurring then
        return "UI-QuestPoiRecurring", "recurring"
    elseif classification == classifications.Important then
        return "UI-QuestPoiImportant", "important"
    elseif classification == classifications.Meta then
        return "UI-QuestPoiWrapper", "meta"
    end

    return "UI-QuestPoi", "normal"
end

local function AtlasExists(atlas)
    if not (_G.C_Texture and type(_G.C_Texture.GetAtlasInfo) == "function") then
        return true
    end
    local ok, info = pcall(_G.C_Texture.GetAtlasInfo, atlas)
    return ok and info ~= nil
end

local function LegacyNumberTexCoords(number, selected)
    number = min(max(floor(tonumber(number) or 1), 1), 32)
    local colorOffset = selected and 0 or 0.5

    if type(_G.QuestPOI_CalculateNumericTexCoords) == "function" then
        local ok, left, right, top, bottom = pcall(
            _G.QuestPOI_CalculateNumericTexCoords,
            number,
            colorOffset
        )
        if ok and left then return left, right, top, bottom end
    end

    local iconIndex = number - 1
    local size = 0.125
    local left = (iconIndex % 8) * size
    local top = colorOffset + floor(iconIndex / 8) * size
    return left, left + size, top, top + size
end

local function LegacyQuestPinVisual(selected, complete, questNumber)
    local numberTexture = "Interface\\WorldMap\\UI-QuestPoi-NumberIcons"
    local completeTexture = "Interface\\WorldMap\\UI-WorldMap-QuestIcon"

    if complete and not selected then
        return {
            tex = completeTexture,
            texCoord = { 0, 0.5, 0, 0.5 },
            width = 24,
            height = 24,
        }
    end

    local visual = {
        tex = numberTexture,
        texCoord = selected
            and { 0.500, 0.625, 0.375, 0.500 }
            or  { 0.875, 1.000, 0.375, 0.500 },
        width = selected and 26 or 22,
        height = selected and 26 or 22,
    }

    if complete then
        visual.displayTex = completeTexture
        visual.displayTexCoord = { 0, 0.5, 0, 0.5 }
        visual.displayWidth = 21
        visual.displayHeight = 21
    else
        local left, right, top, bottom = LegacyNumberTexCoords(
            questNumber,
            selected
        )
        visual.displayTex = numberTexture
        visual.displayTexCoord = { left, right, top, bottom }
        visual.displayWidth = selected and 24 or 20
        visual.displayHeight = selected and 24 or 20
    end

    return visual
end

function Compat:GetQuestPinVisual(questID, selected, complete, isWaypoint,
    questNumber)
    selected = selected == true
    complete = complete == true

    if not self:IsModernQuestDataProvider() then
        return LegacyQuestPinVisual(selected, complete, questNumber)
    end

    local prefix, classification = GetModernAtlasPrefix(questID)
    local baseAtlas = prefix .. "-QuestNumber"
        .. (selected and "-SuperTracked" or "")
    if not AtlasExists(baseAtlas) then
        -- A PTR or intermediate client may expose the waypoint API before the
        -- POI atlas set. The legacy texture is present in every supplied build.
        return LegacyQuestPinVisual(selected, complete, questNumber)
    end

    local displayAtlas
    local displayWidth, displayHeight = 16, 16
    if isWaypoint then
        displayAtlas = "poi-traveldirections-arrow"
        displayWidth, displayHeight = 13, 17
    elseif complete then
        local completeAtlases = {
            legendary = "UI-QuestPoiLegendary-QuestBangTurnIn",
            campaign = "UI-QuestPoiCampaign-QuestBangTurnIn",
            calling = "UI-DailyQuestPoiCampaign-QuestBangTurnIn",
            recurring = "UI-QuestPoiRecurring-QuestBangTurnIn",
            important = "UI-QuestPoiImportant-QuestBangTurnIn",
            meta = "UI-QuestPoiWrapper-QuestBangTurnIn",
            normal = "UI-QuestIcon-TurnIn-Normal",
        }
        displayAtlas = completeAtlases[classification]
            or completeAtlases.normal
        displayWidth, displayHeight = 18, 18
    else
        displayAtlas = selected
            and "Quest-In-Progress-Icon-Brown"
            or "Quest-In-Progress-Icon-yellow"
    end

    if not AtlasExists(displayAtlas) then
        return LegacyQuestPinVisual(selected, complete, questNumber)
    end

    return {
        tex = "atlas:" .. baseAtlas,
        displayAtlas = displayAtlas,
        displayWidth = displayWidth,
        displayHeight = displayHeight,
        width = selected and 28 or 24,
        height = selected and 28 or 24,
    }
end

