-- Carbonite | Map hotspot construction and hover selection, shared by all flavors.
-- Authored shapes control browsing; full bounds protect the player's active layer.

local Carbonite = _G.Carbonite
local Hotspots = {}
Carbonite.Modules.Map.Hotspots = Hotspots

local function nxMap() return _G.Nx and _G.Nx.Map end

local function finite(value)
    return type(value) == "number"
        and not (_G.issecretvalue and _G.issecretvalue(value))
        and value == value and value > -math.huge and value < math.huge
end

local function contains(spot, wx, wy)
    return spot and finite(spot.WX1) and finite(spot.WY1)
        and finite(spot.WX2) and finite(spot.WY2)
        and spot.WX2 > spot.WX1 and spot.WY2 > spot.WY1
        and wx >= spot.WX1 and wx <= spot.WX2
        and wy >= spot.WY1 and wy <= spot.WY2
end

local function setBounds(map, mapID, spot, zx, zy, width, height)
    local info = map.MapWorldInfo and map.MapWorldInfo[mapID]
    local geometry = info and (info.BaseMap and map.MapWorldInfo[info.BaseMap] or info)
    if not geometry or not finite(geometry.Scale) or geometry.Scale <= 0
        or not finite(geometry[4]) or not finite(geometry[5])
        or not finite(zx) or not finite(zy) or not finite(width) or not finite(height)
        or width <= 0 or height <= 0 or not map.GetWorldPos then
        spot.WX1, spot.WY1, spot.WX2, spot.WY2 = nil, nil, nil, nil
        return false
    end

    spot.WX1, spot.WY1 = map:GetWorldPos(mapID, zx, zy)
    spot.WX2, spot.WY2 = map:GetWorldPos(mapID, zx + width, zy + height)
    return contains(spot, spot.WX1, spot.WY1)
end

local function encoding(mapID)
    local Nx = _G.Nx
    local loc = Nx.MapWorldHotspots and Nx.MapWorldHotspots[mapID]
    if loc ~= nil then return loc, 4 end
    return Nx.MapWorldHotspots2 and Nx.MapWorldHotspots2[mapID], 12
end

local function unpackRect(map, chunk, size)
    if #chunk ~= size then return end
    if size == 4 then
        if not map.UnpackLocRect then return end
        local x, y, width, height = map:UnpackLocRect(chunk)
        return x, y, width / 1002 * 100, height / 668 * 100
    end
    if chunk:find("[^%x]") then return end
    return tonumber(chunk:sub(1, 3), 16) * 100 / 4095,
        tonumber(chunk:sub(4, 6), 16) * 100 / 4095,
        tonumber(chunk:sub(7, 9), 16) * 100 / 4095,
        tonumber(chunk:sub(10, 12), 16) * 100 / 4095
end

function Hotspots:Record(map, mapID, tip)
    if not finite(mapID) or mapID <= 0 then return end
    self.byMap = self.byMap or {}
    local record = self.byMap[mapID]
    if record then return record end
    local info = map.MapWorldInfo and map.MapWorldInfo[mapID]
    if not info then return end
    local loc = encoding(mapID)
    record = {
        spots = {}, city = info.City or info.StartZone or false,
        fallback = loc == nil, disabled = loc == "",
        spot = {MapId = mapID, mapID = mapID, NxTipBase = tip or map:IdToName(mapID)},
    }
    self.byMap[mapID] = record
    return record
end

-- Rebuild once at initialization; an empty authored string disables browsing.
function Hotspots:Build()
    local map = nxMap()
    local general, city = {}, {}
    self.general, self.city, self.byMap = general, city, {}
    if not map then return general, city end
    map.WorldHotspots, map.WorldHotspotsCity = general, city

    for cont = 1, map.ContCnt or 0 do
        local cname = map:GetWorldContinentInfo(cont)
        if cname then
            for _, mapID in pairs(map.MapZones and map.MapZones[cont] or {}) do
                local name = map:GetWorldZoneInfo(cont, mapID)
                if name and not self.byMap[mapID] then
                    local color, desc = Carbonite.Modules.Map.MapIDs:GetZoneDescription(mapID)
                    local tip = ("%s, %s%s (%s)"):format(cname, color, name, desc)
                    local record = self:Record(map, mapID, tip)
                    if record then
                        setBounds(map, mapID, record.spot, 0, 0, 100, 100)
                        local loc, size = encoding(mapID)
                        if record.fallback then loc, size = string.char(85, 85, 135, 135), 4 end
                        local target = record.city and city or general
                        if type(loc) == "string" then
                            for i = 1, #loc - size + 1, size do
                                local chunk = loc:sub(i, i + size - 1)
                                local zx, zy, width, height = unpackRect(map, chunk, size)
                                local spot = {MapId = mapID, mapID = mapID, zx = zx, zy = zy,
                                    x = tonumber(chunk:sub(1, 3), 16) or 0,
                                    y = tonumber(chunk:sub(4, 6), 16) or 0,
                                    NxTipBase = tip, city = record.city}
                                if setBounds(map, mapID, spot, zx, zy, width, height) then
                                    target[#target + 1] = spot
                                    record.spots[#record.spots + 1] = spot
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return general, city
end

local function allowed(map, mapID)
    return finite(mapID) and mapID > 0
        and not (map.ShouldHideQuelThalasZone and map:ShouldHideQuelThalasZone(mapID))
end

-- Prefer the actual current zone within its priority group. Otherwise choose
-- the smallest matching rectangle, then map ID, independently of table order.
function Hotspots:FindInGroup(map, wx, wy, quad, currentID, record, active)
    if active and record and record.fallback
        and quad == (record.city and self.city or self.general)
        and contains(record.spot, wx, wy) and allowed(map, currentID) then
        return record.spot
    end
    local best, bestArea
    for _, spot in ipairs(quad or {}) do
        if contains(spot, wx, wy) and allowed(map, spot.MapId) then
            if active and spot.MapId == currentID then return spot end
            local area = (spot.WX2 - spot.WX1) * (spot.WY2 - spot.WY1)
            if not best or area < bestArea or area == bestArea and spot.MapId < best.MapId then
                best, bestArea = spot, area
            end
        end
    end
    return best
end

function Hotspots:Find(map, wx, wy, quad)
    if not finite(wx) or not finite(wy) then return end
    local currentID = map:GetCurrentMapId()
    local displayableID = map:GetDisplayableMapForPlayer()
    local playerID = map.GetPlayerWorldMapID and map:GetPlayerWorldMapID()
    local active = currentID == displayableID or currentID == playerID
    local info = map.MapWorldInfo and map.MapWorldInfo[currentID]
    local record = self:Record(map, currentID)
    if record then setBounds(map, currentID, record.spot, 0, 0, 100, 100) end

    if info and active and allowed(map, currentID) then
        -- Synthetic instance anchors overlap their outdoor entrance zones.
        if info.Instance and record then return record.spot end
        if record and not record.disabled
            and (info.Underground or finite(info.MapLevel) and info.MapLevel > 0)
            and contains(record.spot, wx, wy) then
            return record.spot
        end
    end

    if map.InstMapId then
        local spot = map._hoverInstanceSpot
        if not spot or spot.MapId ~= map.InstMapId then
            spot = {MapId = map.InstMapId, mapID = map.InstMapId,
                NxTipBase = map:IdToName(map.InstMapId)}
            map._hoverInstanceSpot = spot
        end
        spot.WX1, spot.WY1 = map.InstMapWX1, map.InstMapWY1
        spot.WX2, spot.WY2 = map.InstMapWX2, map.InstMapWY2
        if contains(spot, wx, wy) and allowed(map, spot.MapId) then return spot, true end
    end

    -- Legacy city artwork must remain selected within its authored shapes.
    if info and info.City and info.LegacyMapArt and record and allowed(map, currentID) then
        for _, spot in ipairs(record.spots) do
            if contains(spot, wx, wy) then return spot end
        end
    end
    if quad then return self:FindInGroup(map, wx, wy, quad, currentID, record, active) end

    local first, second = self.city, self.general
    if map.NXCitiesUnder then first, second = second, first end
    return self:FindInGroup(map, wx, wy, first, currentID, record, active)
        or self:FindInGroup(map, wx, wy, second, currentID, record, active)
end

function Hotspots:General() return self.general or {} end
function Hotspots:Cities() return self.city or {} end
function Hotspots:Each(mapID, fn)
    local record = self.byMap and self.byMap[mapID]
    for _, spot in ipairs(record and record.spots or {}) do fn(spot) end
end

local function rewireLegacy()
    local map = nxMap()
    if map then map.InitHotspots = function(_) return Hotspots:Build() end end
end
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)
