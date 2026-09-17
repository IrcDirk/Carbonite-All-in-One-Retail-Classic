local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

Nx.BuggedSubZones = {
    [0] = "null",
    [1] = "Caverns of Time",
    [2] = "Cleft of Shadow",
    [3] = "Temple of Earth",
    [4] = "Terrace of Light"
}

Nx.BuggedAreas = {
    [0] = "null",
    [1] = 125,
    [2] = 126,
    [3] = 103,
    [4] = 87,
    [5] = 90,
}


    -- Can anyone expand/corect this (from dratr https://github.com/dratr/Carbonite/commits/map-zonesdocs)
    -- Fields: name, minLvl, maxLvl, faction, cont, entryId, ex, ey, ??
    -- entryId, ex, ey only for instances.
    -- entryId is map id of zone that has dungeon entrance; ex, ey is loc in zone
    -- Faction:
    -- 0 Alliance
    -- 1 Horde
    -- 2 Contested
    -- 3 Instance
    -- 4 Unknown
Nx.Zones = {
    [0] = L["Unknown Zone"] .. "|0|0|4|0||",
    [1411] = L["Durotar"] .. "|1|10|1|1||",
    [1412] = L["Mulgore"] .. "|1|10|1|1||",
    [1413] = L["Northern Barrens"] .. "|20|60|1|1||",
    [12] = L["Kalimdor"] .. "|1|60|2|1||",
    [13] = L["Eastern Kingdoms"] .. "|1|60|2|2||",
    [1416] = L["Alterac Mountains"] .. "|30|40|2|2||",
    [1417] = L["Arathi Highlands"] .. "|30|40|2|2||",
    [1418] = L["Badlands"] .. "|35|45|2|2||",
    [1419] = L["Blasted Lands"] .. "|45|55|2|2||",
    [1420] = L["Tirisfal Glades"] .. "|1|10|1|2||",
    [1421] = L["Silverpine Forest"] .. "|10|20|1|2||",
    [1422] = L["Western Plaguelands"] .. "|51|58|2|2||",
    [1423] = L["Eastern Plaguelands"] .. "|53|60|2|2||",
    [1424] = L["Hillsbrad Foothills"] .. "|20|30|2|2||",
    [1425] = L["The Hinterlands"] .. "|40|50|2|2||",
    [1426] = L["Dun Morogh"] .. "|1|10|0|2||",
    [1427] = L["Searing Gorge"] .. "|43|50|2|2||",
    [1428] = L["Burning Steppes"] .. "|50|58|2|2||",
    [1429] = L["Elwynn Forest"] .. "|1|10|0|2||",
    [1430] = L["Deadwind Pass"] .. "|55|60|2|2||",
    [1431] = L["Duskwood"] .. "|18|30|2|2||",
    [1432] = L["Loch Modan"] .. "|10|20|0|2||",
    [1433] = L["Redridge Mountains"] .. "|15|25|2|2||",
    [1434] = L["Stranglethorn Vale"] .. "|30|45|2|2||",
    [1435] = L["Swamp of Sorrows"] .. "|35|45|2|2||",
    [1436] = L["Westfall"] .. "|10|20|0|2||",
    [1437] = L["Wetlands"] .. "|20|30|2|2||",
    [1438] = L["Teldrassil"] .. "|1|10|0|1||",
    [1439] = L["Darkshore"] .. "|10|20|0|1||",
    [1440] = L["Ashenvale"] .. "|18|30|2|1||",
    [1441] = L["Thousand Needles"] .. "|25|35|2|1||",
    [1442] = L["Stonetalon Mountains"] .. "|15|27|2|1||",
    [1443] = L["Desolace"] .. "|30|40|2|1||",
    [1444] = L["Feralas"] .. "|40|50|2|1||",
    [1445] = L["Dustwallow Marsh"] .. "|35|45|2|1||",
    [1446] = L["Tanaris"] .. "|40|50|2|1||",
    [1447] = L["Azshara"] .. "|45|55|1|1||",
    [1448] = L["Felwood"] .. "|48|55|2|1||",
    [1449] = L["Un'Goro Crater"] .. "|48|55|2|1||",
    [1450] = L["Moonglade"] .. "|0|0|2|1||",
    [1451] = L["Silithus"] .. "|55|60|2|1||",
    [1452] = L["Winterspring"] .. "|55|60|2|1||",
    [1453] = L["Stormwind City"] .. "|0|0|0|2||",
    [1454] = L["Orgrimmar"] .. "|0|0|1|1||",
    --[86] = L["Orgrimmar"] .. "|0|0|1|1||",
    [1455] = L["Ironforge"] .. "|0|0|0|2||",
    [1456] = L["Thunder Bluff"] .. "|0|0|1|1||",
    [1457] = L["Darnassus"] .. "|0|0|0|1||",
    [1458] = L["Undercity"] .. "|0|0|1|2||",
    [1459] = L["Alterac Valley"] .. "|0|0|3|4||",
    [1460] = L["Warsong Gulch"] .. "|0|0|3|4||",
    [1461] = L["Arathi Basin"] .. "|0|0|3|4||",

    -- WoW Forever ("camelot") zones. Fields: name|minLvl|maxLvl|faction|cont|entryId|ex|ey
    -- Level ranges left at 0|0 and factions at 2 (contested) until we have
    -- walked them in-game; UiMap of build 1.60.1.69893 carries no ContentTuningID.
    [2482] = L["Mount Hyjal"] .. "|0|0|2|1||",        -- TODO levels/faction
    [2652] = L["Shen'dralas"] .. "|0|0|2|1||",        -- TODO levels/faction
    [2548] = L["Riverglades"] .. "|0|0|2|2||",        -- TODO levels/faction
    -- Own instance map (2991), hangs off the Azeroth world map rather than a
    -- continent. Parked in the off-world bucket (cont 4) together with its
    -- off-canvas MapWorldInfo placement. TODO once we know where it sits.
    [2521] = L["Zephras Isle"] .. "|0|0|2|4||",
    -- New battleground, same shape as AV/WSG/AB.
    [2524] = L["Darkspear Islands"] .. "|0|0|3|4||",

    [213] = L["Ragefire Chasm"] .. "|13|18|3|5|1454|51.9|58.4|5",
    [219] = L["Zul'Farrak"] .. "|44|54|3|5|1446|39.2|21.4|5",
    [220] = L["The Temple of Atal'Hakkar"] .. "|50|60|3|5|1435|69.83|54.14|5",
    [225] = L["The Stockade"] .. "|22|32|3|5|1453|40.1|54.9|5",
    [226] = L["Gnomeregan"] .. "|24|34|3|5|1426|24.38|39.8|5",
    [221] = L["Blackfathom Deeps"] .. "|22|32|3|5|1440|14.15|13.9|5",
    [230] = L["Uldaman"] .. "|41|51|3|5|1418|44.44|12.19|5",
    [234] = L["Dire Maul"] .. "|45|55|3|5|1444|59.1|45.4|5",
    [242] = L["Blackrock Depths"] .. "|48|60|3|5|1428|15.70|28.33|5",
    [250] = L["Blackrock Spire"] .. "|55|60|3|5|1428|15.70|33.33|10",
    [280] = L["Maraudon"] .. "|45|52|3|5|1443|29.48|62.53|5",
    [291] = L["The Deadmines"] .. "|15|25|3|5|1436|42.56|71.72|5",
    [279] = L["Wailing Caverns"] .. "|17|27|3|5|1413|39|69.4|5",
    [300] = L["Razorfen Downs"] .. "|37|47|3|5|1413|45.43|89.48|5",
    [301] = L["Razorfen Kraul"] .. "|32|42|3|5|1413|43.59|90.16|5",
    [306] = L["Scholomance"] .. "|55|60|3|5|1422|69.77|73.51|5",
    [310] = L["Shadowfang Keep"] .. "|22|30|3|5|1421|44.86|67.86|5",
    [317] = L["Stratholme"] .. "|55|60|3|5|1423|27.09|12.6|5",
    [435] = L["Scarlet Monastery"] .. "|26|45|3|5|1420|85.57|36.04|5",

    [162] = L["Naxxramas"] .. "|60|60|3|5|1423|40.0|25.8|40",
    [232] = L["Molten Core"] .. "|60|60|3|5|1428|20.70|33.33|40",
    [247] = L["Ruins of Ahn'Qiraj"] .. "|60|60|3|5|1451|29.1|93.8|20",
    [248] = L["Onyxia's Lair"] .. "|60|60|3|5|70|52.41|76.39|40",
    [287] = L["Blackwing Lair"] .. "|60|60|3|5|1428|20.70|35.33|40",
    [319] = L["Temple of Ahn'Qiraj"] .. "|60|60|3|5|1451|29.1|93.8|40",
    [337] = L["Zul'Gurub"] .. "|55|60|3|5|1434|67.2|32.8|5",

    -- ---------------------------------------------------------------
    -- WoW Forever ("camelot") instances, from Map.db2 of build 1.60.1.69893
    -- (diff against Classic Era 1.15.9 — 14 maps Era does not have).
    -- Blizzard ships NO dungeon-type UiMaps (no Type=4 rows at all, same as
    -- Era), so these need Carbonite's own floor maps plus an entrance
    -- zone/coords, which we can only capture in-game. Keys below are the
    -- Map.db2 instance IDs for reference; the live entries must use
    -- Carbonite's own instance numbering like the vanilla ones above.
    --
    --   party:      2959 City of Dalaran
    --               2998 Excavation Site: Wetlands
    --               2999 Ruins of Lordaeron
    --               3002 Half-Pint Tavern
    --               3065 The Hall of Thanes
    --               3109 Manor Mistmantle
    --   pvp:        2997 Darkspear Islands (uiMap 2524, added above)
    --               3005 Battle for Gilneas
    --   arena:      2995 Hyjal Crater
    --   world:      2980 Dalaran City, 2991 Zephras Isle (uiMap 2521),
    --               2996 Warsong Gulch (Winter), 3021 Eastern Kingdoms Preserved,
    --               3104 "nothing to see here"
    --
    -- TODO fill in after the in-game dump run: entrance uiMap + x/y, group
    -- size, level range, and our own floor-map art.
    -- ---------------------------------------------------------------
}


Nx.SubNames = {}
