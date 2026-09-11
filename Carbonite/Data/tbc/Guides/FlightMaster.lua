local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

local guideData = { ["Mode"] = 30 }
Nx.GuideData[L["Flight Master"]] = guideData

-- Structured format: { FactionID (1=Alliance, 2=Horde, 0=Neutral), MapID, X, Y, Name, Level }
local FLIGHT_DATA = {
    { 2, 1413, 51.50, 30.41, L["Crossroads, The Barrens"] },
    { 2, 1413, 44.46, 59.10, L["Camp Taurajo, The Barrens"] },
    { 0, 1413, 63.12, 37.11, L["Ratchet, The Barrens"] },
    { 1, 1417, 45.79, 46.13, L["Refuge Pointe, Arathi"] },
    { 2, 1417, 73.06, 32.62, L["Hammerfall, Arathi"] },
    { 2, 1418, 4.06,  44.89, L["Kargath, Badlands"] },
    { 1, 1419, 65.49, 24.43, L["Nethergarde Keep, Blasted Lands"] },
    { 2, 1420, 83.52, 70.06, L["The Bulwark, Tirisfal"] },
    { 2, 1421, 45.56, 42.42, L["The Sepulcher, Silverpine Forest"] },
    { 0, 1422, 69.21, 49.68, L["Thondoril River, Western Plaguelands"] },
    { 1, 1422, 42.95, 84.95, L["Chillwind Camp, Western Plaguelands"] },
    { 1, 1423, 81.74, 59.32, L["Light's Hope Chapel, Eastern Plaguelands"] },
    { 2, 1423, 74.40, 51.23, L["Light's Hope Chapel, Eastern Plaguelands"] },
    { 2, 1424, 60.21, 18.75, L["Tarren Mill, Hillsbrad"] },
    { 1, 1424, 49.44, 52.10, L["Southshore, Hillsbrad"] },
    { 1, 1425, 11.11, 46.09, L["Aerie Peak, The Hinterlands"] },
    { 2, 1425, 81.70, 81.89, L["Revantusk Village, The Hinterlands"] },
    { 1, 1427, 37.89, 30.43, L["Thorium Point, Searing Gorge"] },
    { 2, 1427, 34.83, 30.58, L["Thorium Point, Searing Gorge"] },
    { 2, 1428, 65.58, 24.22, L["Flame Crest, Burning Steppes"] },
    { 1, 1428, 84.38, 68.30, L["Morgan's Vigil, Burning Steppes"] },
    { 1, 1431, 77.59, 44.38, L["Darkshire, Duskwood"] },
    { 1, 1432, 33.94, 50.79, L["Thelsamar, Loch Modan"] },
    { 1, 1433, 30.43, 58.99, L["Lakeshire, Redridge"] },
    { 2, 1434, 26.82, 77.00, L["Booty Bay, Stranglethorn"] },
    { 1, 1434, 27.53, 77.67, L["Booty Bay, Stranglethorn"] },
    { 1, 1434, 38.20, 4.12,  L["Rebel Camp, Stranglethorn Vale"] },
    { 2, 1434, 32.51, 29.28, L["Grom'gol, Stranglethorn"] },
    { 2, 1435, 46.05, 54.68, L["Stonard, Swamp of Sorrows"] },
    { 1, 1436, 56.56, 52.68, L["Sentinel Hill, Westfall"] },
    { 1, 1437, 9.52,  59.66, L["Menethil Harbor, Wetlands"] },
    { 1, 1438, 58.40, 93.93, L["Rut'theran Village, Teldrassil"] },
    { 1, 1439, 36.40, 45.62, L["Auberdine, Darkshore"] },
    { 1, 1440, 85.01, 43.52, L["Forest Song, Ashenvale"] },
    { 1, 1440, 34.50, 48.02, L["Astranaar, Ashenvale"] },
    { 2, 1440, 12.19, 33.77, L["Zoram'gar Outpost, Ashenvale"] },
    { 2, 1440, 73.26, 61.67, L["Splintertree Post, Ashenvale"] },
    { 2, 1441, 45.02, 49.13, L["Freewind Post, Thousand Needles"] },
    { 2, 1442, 45.16, 59.89, L["Sun Rock Retreat, Stonetalon Mountains"] },
    { 1, 1442, 36.54, 7.23,  L["Stonetalon Peak, Stonetalon Mountains"] },
    { 1, 1443, 64.67, 10.44, L["Nijel's Point, Desolace"] },
    { 2, 1443, 21.56, 74.04, L["Shadowprey Village, Desolace"] },
    { 1, 1444, 89.46, 45.87, L["Thalanaar, Feralas"] },
    { 1, 1444, 30.26, 43.32, L["Feathermoon, Feralas"] },
    { 2, 1444, 75.43, 44.31, L["Camp Mojache, Feralas"] },
    { 0, 1445, 42.88, 72.37, L["Mudsprocket, Dustwallow Marsh"] },
    { 1, 1445, 67.46, 51.20, L["Theramore, Dustwallow Marsh"] },
    { 2, 1445, 35.57, 31.83, L["Brackenwall Village, Dustwallow Marsh"] },
    { 1, 1446, 50.95, 29.33, L["Gadgetzan, Tanaris"] },
    { 2, 1446, 51.62, 25.52, L["Gadgetzan, Tanaris"] },
    { 2, 1447, 21.95, 49.69, L["Valormok, Azshara"] },
    { 1, 1447, 11.90, 77.48, L["Talrendis Point, Azshara"] },
    { 0, 1448, 51.44, 82.29, L["Emerald Sanctuary, Felwood"] },
    { 2, 1448, 34.42, 53.87, L["Bloodvenom Post, Felwood"] },
    { 1, 1448, 62.46, 24.19, L["Talonbranch Glade, Felwood"] },
    { 0, 1449, 45.30, 5.97,  L["Marshal's Refuge, Un'Goro Crater"] },
    { 1, 1450, 47.91, 67.11, L["Moonglade"] },
    { 1, 1450, 44.28, 45.34, L["Nighthaven, Moonglade"] },
    { 2, 1450, 44.31, 45.72, L["Nighthaven, Moonglade"] },
    { 2, 1450, 32.15, 66.33, L["Moonglade"] },
    { 2, 1451, 48.83, 36.72, L["Cenarion Hold, Silithus"] },
    { 1, 1451, 50.68, 34.59, L["Cenarion Hold, Silithus"] },
    { 1, 1452, 62.33, 36.69, L["Everlook, Winterspring"] },
    { 2, 1452, 60.49, 36.34, L["Everlook, Winterspring"] },
    { 1, 1453, 70.98, 72.93, L["Stormwind, Elwynn"] },
    { 2, 1454, 45.28, 63.75, L["Orgrimmar, Durotar"] },
    { 1, 1455, 55.89, 47.87, L["Ironforge, Dun Morogh"] },
    { 2, 1456, 46.65, 49.90, L["Thunder Bluff, Mulgore"] },
    { 2, 1458, 63.09, 48.32, L["Undercity, Tirisfal"] },

    -- Outland & TBC Additions
    { 2, 1941, 54.38, 50.75, L["Silvermoon City"] },
    { 0, 1942, 74.67, 67.13, L["Zul'Aman, Ghostlands"] },
    { 2, 1942, 45.48, 30.55, L["Tranquillien, Ghostlands"] },
    { 1, 1943, 48.34, 49.26, L["Azure Watch, Azuremyst Isle"] },
    { 1, 1944, 54.65, 62.57, L["Honor Hold, Hellfire Peninsula"] },
    { 1, 1944, 25.13, 37.23, L["Temple of Telhamat, Hellfire Peninsula"] },
    { 2, 1944, 27.85, 60.07, L["Falcon Watch, Hellfire Peninsula"] },
    { 1, 1944, 87.50, 52.52, L["Hellfire Peninsula, The Dark Portal, Alliance"] },
    { 2, 1944, 87.38, 48.18, L["Hellfire Peninsula, The Dark Portal, Horde"] },
    { 2, 1944, 61.59, 81.25, L["Spinebreaker Ridge, Hellfire Peninsula"] },
    { 1, 1944, 78.47, 34.99, L["Shatter Point, Hellfire Peninsula"] },
    { 2, 1944, 56.27, 36.38, L["Thrallmar, Hellfire Peninsula"] },
    { 1, 1946, 67.86, 51.36, L["Telredor, Zangarmarsh"] },
    { 2, 1946, 33.00, 51.19, L["Zabra'jin, Zangarmarsh"] },
    { 2, 1946, 84.74, 55.00, L["Swamprat Post, Zangarmarsh"] },
    { 1, 1946, 41.29, 28.90, L["Orebor Harborage, Zangarmarsh"] },
    { 1, 1947, 68.79, 63.18, L["The Exodar"] },
    { 2, 1948, 30.33, 29.20, L["Shadowmoon Village, Shadowmoon Valley"] },
    { 1, 1948, 37.61, 55.48, L["Wildhammer Stronghold, Shadowmoon Valley"] },
    { 0, 1948, 63.19, 30.48, L["Altar of Sha'tar, Shadowmoon Valley"] },
    { 0, 1948, 56.39, 57.96, L["Sanctum of the Stars, Shadowmoon Valley"] },
    { 1, 1949, 37.81, 61.51, L["Sylvanaar, Blade's Edge Mountains"] },
    { 2, 1949, 52.07, 54.25, L["Thunderlord Stronghold, Blade's Edge Mountains"] },
    { 1, 1949, 61.09, 70.53, L["Toshley's Station, Blade's Edge Mountains"] },
    { 0, 1949, 61.65, 39.60, L["Evergrove, Blade's Edge Mountains"] },
    { 2, 1949, 76.32, 65.79, L["Mok'Nathal Village, Blade's Edge Mountains"] },
    { 0, 1949, 28.40, 51.40, L["Skyguard Outpost, Blade's Edge Mountains"] },
    { 1, 1950, 57.61, 54.02, L["Blood Watch, Bloodmyst Isle"] },
    { 1, 1951, 54.13, 75.22, L["Telaar, Nagrand"] },
    { 2, 1951, 57.24, 35.37, L["Garadar, Nagrand"] },
    { 1, 1952, 59.45, 55.20, L["Allerian Stronghold, Terokkar Forest"] },
    { 2, 1952, 49.25, 43.54, L["Stonebreaker Hold, Terokkar Forest"] },
    { 0, 1952, 64.15, 66.28, L["Blackwind Landing, Terokkar Forest"] },
    { 0, 1953, 33.85, 63.87, L["Area 52, Netherstorm"] },
    { 0, 1953, 45.27, 34.94, L["The Stormspire, Netherstorm"] },
    { 0, 1953, 65.20, 66.76, L["Cosmowrench, Netherstorm"] },
    { 0, 1955, 63.80, 41.72, L["Shattrath, Terokkar Forest"] },
    { 0, 1957, 48.28, 25.06, L["Shattered Sun Staging Area"] },
}

local NX_FLIGHT_LOC = {
    [1] = L["Alliance Flight"],
    [2] = L["Horde Flight"],
    [0] = L["Neutral Flight"],
}

-- Upvalue caching
local format, insert, concat = string.format, table.insert, table.concat
local npcData = Nx.NPCData or {}
Nx.NPCData = npcData

local zoneBuffers = {}

for i = 1, #FLIGHT_DATA do
    local node = FLIGHT_DATA[i]
    local side, zon, x, y, name, level = node[1], node[2], node[3], node[4], node[5], node[6] or 0
    local prefix = NX_FLIGHT_LOC[side] or NX_FLIGHT_LOC[0]
    local fullName = prefix .. "|" .. name

    insert(npcData, format("%d|%s|%d|%.2f|%.2f|%d", side, fullName, zon, x, y, level))
    local index = #npcData

    local serialized = format("%d,%.2f,%.2f,%d,%d", side, x, y, level, index)

    if not zoneBuffers[zon] then
        zoneBuffers[zon] = { serialized }
    else
        insert(zoneBuffers[zon], serialized)
    end
end

-- Commit batched zone strings
for zon, entries in pairs(zoneBuffers) do
    guideData[zon] = concat(entries, "|")
end

-- Garbage cleanup
FLIGHT_DATA = nil
NX_FLIGHT_LOC = nil
Nx.FlightConnection = ""