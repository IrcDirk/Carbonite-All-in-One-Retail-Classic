---------------------------------------------------------------------------------------
-- Carbonite - Shared lazy runtime map resolver
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- Missing maps are resolved through Carbonite's existing map-data entry point.
-- Keep the lookup lazy: rebuilding the entire catalog during startup changes
-- active instance placement and can disturb unlocked map/minimap windows.
local zoneInfoInProgress = {}

local function NormalizeZoneMapID(mapID)
    if Nx.OldMapIDs then
        if mapID == 1414 then
            return 12
        end
        if mapID == 1415 then
            return 13
        end
    end
    return mapID
end

local function GetSafeZoneMapInfo(mapID)
    if not mapID or mapID <= 0 or not C_Map or not C_Map.GetMapInfo then
        return nil
    end

    local ok, mapInfo = pcall(C_Map.GetMapInfo, mapID)
    if ok and type(mapInfo) == "table" then
        return mapInfo
    end
    return nil
end

local function IsFiniteMapCoordinate(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function GetZoneMapGeometry(mapID)
    if not C_Map or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then
        return nil
    end

    local topOK, worldMapID, topLeft = pcall(
        C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(0, 0)
    )
    local bottomOK, secondWorldMapID, bottomRight = pcall(
        C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(0.5, 0.5)
    )
    if not topOK or not bottomOK or not topLeft or not bottomRight then
        return nil
    end

    local topPositionOK, top, left = pcall(topLeft.GetXY, topLeft)
    local bottomPositionOK, bottom, right = pcall(bottomRight.GetXY, bottomRight)
    if not topPositionOK or not bottomPositionOK
        or not IsFiniteMapCoordinate(top)
        or not IsFiniteMapCoordinate(left)
        or not IsFiniteMapCoordinate(bottom)
        or not IsFiniteMapCoordinate(right) then
        return nil
    end

    right = left + (right - left) * 2
    local scale = (left - right) / 500
    if not IsFiniteMapCoordinate(scale) or scale <= 0 then
        return nil
    end

    return {
        worldMapID = worldMapID or secondWorldMapID,
        x = -left / 5,
        y = -top / 5,
        scale = scale,
    }
end

local function GetZoneMapFields(mapID)
    local zoneData = Nx.Zones and Nx.Zones[mapID]
    if not zoneData then
        return nil
    end

    local _, _, _, faction, continent, entryID, entryX, entryY = Nx.Split("|", zoneData)
    return {
        faction = tonumber(faction),
        continent = tonumber(continent),
        entryID = tonumber(entryID),
        entryX = tonumber(entryX),
        entryY = tonumber(entryY),
    }
end

local function ResolveZoneMapAnchor(mapID)
    local seen = {}
    local entryX, entryY = 50, 50

    for _ = 1, 16 do
        mapID = NormalizeZoneMapID(mapID)
        if not mapID or mapID <= 0 or seen[mapID] then
            return nil
        end
        seen[mapID] = true

        local fields = GetZoneMapFields(mapID)
        if fields then
            if fields.faction == 3 and fields.continent == 5 and fields.entryID then
                entryX = fields.entryX or entryX
                entryY = fields.entryY or entryY
                mapID = fields.entryID
            elseif fields.continent and fields.continent > 0
                and Map.MapInfo and Map.MapInfo[fields.continent]
                and Map.MapWorldInfo and Map.MapWorldInfo[mapID]
                and Map.MapWorldInfo[mapID].Scale then
                return {
                    mapID = mapID,
                    continent = fields.continent,
                    x = entryX,
                    y = entryY,
                }
            else
                local mapInfo = GetSafeZoneMapInfo(mapID)
                mapID = mapInfo and mapInfo.parentMapID
            end
        else
            local mapInfo = GetSafeZoneMapInfo(mapID)
            mapID = mapInfo and mapInfo.parentMapID
        end
    end

    return nil
end

local function FindZoneMapAnchor(mapInfo, ownFields)
    if ownFields and ownFields.faction == 3 and ownFields.continent == 5 then
        local ownAnchor = ResolveZoneMapAnchor(mapInfo.mapID)
        if ownAnchor then
            return ownAnchor
        end
    end

    return ResolveZoneMapAnchor(mapInfo.parentMapID)
end

local function FindStableZoneMapAnchor()
    local rootMaps = Map.MapZones and Map.MapZones[0]
    if not rootMaps then
        return nil
    end

    for _, rootMapID in ipairs(rootMaps) do
        local anchor = ResolveZoneMapAnchor(rootMapID)
        if anchor then
            return anchor
        end
    end
    return nil
end

local function AddUniqueZoneMapID(mapList, mapID)
    if not mapList then
        return
    end

    for _, existingMapID in ipairs(mapList) do
        if existingMapID == mapID then
            return
        end
    end
    mapList[#mapList + 1] = mapID
end

local function IsPrimaryInstanceMap(mapID)
    if not C_Map or not C_Map.GetMapGroupID or not C_Map.GetMapGroupMembersInfo then
        return true
    end

    local groupOK, groupID = pcall(C_Map.GetMapGroupID, mapID)
    if not groupOK or not groupID or groupID == 0 then
        return true
    end

    local membersOK, members = pcall(C_Map.GetMapGroupMembersInfo, groupID)
    if not membersOK or type(members) ~= "table" then
        return true
    end

    local mapTypes = Enum and Enum.UIMapType or {}
    local dungeonType = mapTypes.Dungeon or 4
    local microType = mapTypes.Micro or 5
    local lowestMapID = mapID

    for _, member in ipairs(members) do
        local memberMapID = member.mapID
        if memberMapID and memberMapID ~= mapID then
            local memberFields = GetZoneMapFields(memberMapID)
            local memberWorldInfo = Map.MapWorldInfo and Map.MapWorldInfo[memberMapID]
            if (memberFields and memberFields.faction == 3 and memberFields.continent == 5)
                or (memberWorldInfo and memberWorldInfo.Instance) then
                return false
            end

            local memberInfo = GetSafeZoneMapInfo(memberMapID)
            if memberInfo and (memberInfo.mapType == dungeonType or memberInfo.mapType == microType)
                and memberMapID < lowestMapID then
                lowestMapID = memberMapID
            end
        end
    end

    return mapID == lowestMapID
end

local function IsCurrentZoneInstance(mapID)
    if not IsInInstance or not C_Map or not C_Map.GetBestMapForUnit then
        return false
    end

    local instanceOK, inInstance = pcall(IsInInstance)
    if not instanceOK or not inInstance then
        return false
    end

    local playerMapOK, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
    return playerMapOK and NormalizeZoneMapID(playerMapID) == mapID
end

local function BuildMissingZoneInfo(mapID, force)
    local worldInfo = Map.MapWorldInfo
    if not worldInfo then
        return nil
    end

    local existingInfo = worldInfo[mapID]
    if existingInfo and existingInfo.Scale and not force then
        return existingInfo
    end

    local mapInfo = GetSafeZoneMapInfo(mapID)
    if not mapInfo or not mapInfo.name then
        return nil
    end
    mapInfo.mapID = mapInfo.mapID or mapID

    local mapTypes = Enum and Enum.UIMapType or {}
    local continentType = mapTypes.Continent or 2
    local zoneType = mapTypes.Zone or 3
    local dungeonType = mapTypes.Dungeon or 4
    local microType = mapTypes.Micro or 5
    local orphanType = mapTypes.Orphan or 6
    local mapType = mapInfo.mapType
    if mapType ~= zoneType and mapType ~= dungeonType
        and mapType ~= microType and mapType ~= orphanType then
        return nil
    end

    local parentMapID = NormalizeZoneMapID(mapInfo.parentMapID)
    local parentWorldInfo = parentMapID and worldInfo[parentMapID]
    if parentMapID and parentMapID > 0 and parentMapID ~= mapID
        and (not parentWorldInfo or not parentWorldInfo.Scale) then
        local parentInfo = GetSafeZoneMapInfo(mapInfo.parentMapID)
        if parentInfo and parentInfo.mapType ~= continentType then
            Map:GetZoneInfo(parentMapID)
        end
    end

    local ownFields = GetZoneMapFields(mapID)
    local anchor = FindZoneMapAnchor(mapInfo, ownFields)
    local geometry
    if mapType == zoneType or mapType == orphanType then
        geometry = GetZoneMapGeometry(mapID)
    end

    local isInstance = mapType == dungeonType or mapType == microType
        or (ownFields and ownFields.faction == 3 and ownFields.continent == 5)
        or IsCurrentZoneInstance(mapID)

    if not isInstance and geometry and anchor then
        local parentGeometry = GetZoneMapGeometry(anchor.mapID)
        isInstance = parentGeometry and geometry.worldMapID
            and parentGeometry.worldMapID
            and geometry.worldMapID ~= parentGeometry.worldMapID or false
    end
    if not isInstance and (not geometry or not anchor
        or not Map.MapInfo or not Map.MapInfo[anchor.continent]) then
        isInstance = true
    end

    if isInstance then
        anchor = anchor or FindStableZoneMapAnchor()
        if not anchor then
            return nil
        end
    end

    local winfo = existingInfo or {}
    local localizedName = L[mapInfo.name] or mapInfo.name
    winfo.Name = localizedName
    winfo.parentMapID = mapInfo.parentMapID

    if C_Map.GetMapArtID then
        local artOK, mapArtID = pcall(C_Map.GetMapArtID, mapID)
        if artOK and mapArtID then
            winfo.MapArt = mapArtID
        end
    end

    if isInstance then
        local worldX, worldY = 0, 0
        if Map.GetWorldPos then
            local positionOK, x, y = pcall(
                Map.GetWorldPos, Map, anchor.mapID, anchor.x or 50, anchor.y or 50
            )
            if positionOK and IsFiniteMapCoordinate(x) and IsFiniteMapCoordinate(y) then
                worldX, worldY = x, y
            end
        end

        winfo.EntryMId = anchor.mapID
        winfo.Scale = 1002 / 25600
        winfo.X = worldX
        winfo.Y = worldY
        winfo[4] = worldX
        winfo[5] = worldY
        winfo.Cont = anchor.continent
        winfo.Zone = mapID
        winfo.Instance = true

        if not Nx.Zones[mapID] then
            Nx.Zones[mapID] = localizedName .. "|0|0|3|5|" .. anchor.mapID
                .. "|" .. (anchor.x or 50) .. "|" .. (anchor.y or 50) .. "|0"
        end

        if mapType ~= microType and IsPrimaryInstanceMap(mapID) then
            Map.MapZones[100] = Map.MapZones[100] or {}
            AddUniqueZoneMapID(Map.MapZones[100], mapID)
        end
    else
        local continentInfo = Map.MapInfo[anchor.continent]
        winfo.Scale = geometry.scale
        winfo.X = geometry.x
        winfo.Y = geometry.y
        winfo[4] = continentInfo.X + geometry.x
        winfo[5] = continentInfo.Y + geometry.y
        winfo.Cont = anchor.continent
        winfo.Zone = mapID
        winfo.Instance = nil

        if not Nx.Zones[mapID] then
            Nx.Zones[mapID] = localizedName .. "|0|0|2|" .. anchor.continent .. "||"
        end

        local parentInfo = GetSafeZoneMapInfo(mapInfo.parentMapID)
        if parentInfo and parentInfo.mapType == continentType then
            Map.MapZones[anchor.continent] = Map.MapZones[anchor.continent] or {}
            AddUniqueZoneMapID(Map.MapZones[anchor.continent], mapID)
        end
    end

    worldInfo[mapID] = winfo
    if Nx.MapIdToName then
        Nx.MapIdToName[mapID] = localizedName
    end
    if Nx.MapNameToId and not Nx.MapNameToId[localizedName] then
        Nx.MapNameToId[localizedName] = mapID
    end

    return winfo
end

function Nx.Map:GetZoneInfo(mapID, force)
    mapID = tonumber(mapID)
    if not mapID or mapID <= 0 or mapID == 9000 then
        return nil
    end
    if zoneInfoInProgress[mapID] then
        return Map.MapWorldInfo and Map.MapWorldInfo[mapID] or nil
    end

    zoneInfoInProgress[mapID] = true
    local ok, result = pcall(BuildMissingZoneInfo, mapID, force)
    zoneInfoInProgress[mapID] = nil

    if ok then
        return result
    end
    return nil
end
