---------------------------------------------------------------------------------------
-- Carbonite - Shared minimap lookup and texture compatibility
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map

function Map:GetMiniInfo(mapID)
    local worldInfo = self.MapWorldInfo and self.MapWorldInfo[mapID]
    if not worldInfo then
        return nil
    end

    local tilesetID = worldInfo.MId
    if not tilesetID then
        tilesetID = worldInfo.Cont
        if not tilesetID or tilesetID == 9 or not self.MapInfo[tilesetID] then
            return nil
        end
    end

    local binding = self.MiniMapBlks and self.MiniMapBlks[tilesetID]
    if not binding then
        return nil
    end

    -- Mists merges phased subzone tiles into the existing continent tileset.
    -- Keep the original table identity and tolerate unavailable phase bindings.
    if worldInfo.SubZones and binding[1] then
        for _, subzoneID in ipairs(worldInfo.SubZones) do
            local subzoneBinding = self.MiniMapBlks[subzoneID]
            local subzoneTiles = subzoneBinding and subzoneBinding[1]
            if subzoneTiles then
                for textureIndex, textureFileID in pairs(subzoneTiles) do
                    binding[1][textureIndex] = textureFileID
                end
            end
        end
    end

    return binding, binding[5], binding[6]
end

function Map:GetMiniBlkName(binding, x, y)
    if type(binding) ~= "table" or type(binding[1]) ~= "table" then
        return nil
    end

    local textureID = binding[1][x * 100 + y + binding[2]]
    if type(textureID) == "number" then
        -- Current WoW clients accept numeric FileDataIDs directly.
        return textureID
    end
    if type(textureID) ~= "string" then
        return nil
    end

    local texturePath = binding[7]
    if type(texturePath) ~= "string" then
        return nil
    end

    local tileX = x + binding[3]
    local tileY = y + binding[4]

    if textureID ~= "" then
        return string.format("%s\\noLiquid_map%02d_%02d", texturePath, tileX, tileY)
    end

    if string.find(texturePath, "HawaiiMainLand", 1, true) then
        local hasCampaignFaction = false
        if type(_G.GetNumFactions) == "function" and type(_G.GetFactionInfo) == "function" then
            for factionIndex = 1, _G.GetNumFactions() do
                local factionName = _G.GetFactionInfo(factionIndex)
                if type(factionName) == "table" then
                    factionName = factionName.name
                end
                if factionName == "Operation: Shieldwall" or factionName == "Dominance Offensive" then
                    hasCampaignFaction = true
                    break
                end
            end
        end

        if hasCampaignFaction then
            if (tileX == 33 or tileX == 34) and (tileY == 33 or tileY == 34) then
                return string.format("World\\Minimaps\\AllianceBeachDailyArea\\map%02d_%02d", tileX, tileY)
            end
            if (tileX == 27 or tileX == 28) and tileY >= 35 and tileY <= 38 then
                return string.format("World\\Minimaps\\HordeBeachDailyArea\\map%02d_%02d", tileX, tileY)
            end
        end

        if tileX >= 18 and tileX <= 25 and tileY >= 17 and tileY <= 24 then
            return string.format("World\\Minimaps\\MoguIslandDailyArea\\map%02d_%02d", tileX, tileY - 2)
        end
    end

    return string.format("%s\\map%02d_%02d", texturePath, tileX, tileY)
end
