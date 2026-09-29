---------------------------------------------------------------------------------------
-- NxMapData - Map code
-- Copyright 2007-2012 Carbon Based Creations, LLC
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Carbonite - Addon for World of Warcraft(tm)
-- Copyright 2007-2012 Carbon Based Creations, LLC
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
---------------------------------------------------------------------------------------

local Map = Nx.Map
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- X and Y are the absolute position (lower-left corner) on the overall
-- super-zoomed-out continent image (https://github.com/dratr/Carbonite/commits/map-zonesdocs)

-- Support maps with multiple level
Map.ContCnt = 3

-- Which of the 4x3 continent tiles get drawn. The two outer columns are
-- deliberately off: that is how the continent canvas is cropped, same as
-- Classic Era. (The tiles themselves do contain art - checked by extracting
-- them from the 1.60.1.69893 client - so if a continent ever looks cut off
-- at the sides, this mask is the place to look, not the client data.)
Map.ContBlks = {
    {
        0,1,1,0,
        0,1,1,0,
        0,1,1,0
    },
    {
        0,1,1,0,
        0,1,1,0,
        0,1,1,0
    },
    {
        1,1,1,1,
        1,1,1,1,
        1,1,1,1
    },
    {
        0,0,0,0,
        0,0,0,0,
        0,0,0,0
    }
}


Map.MapZones = {
    [0] = {12,13,2521,113,0,-1},
    -- 2482 Mount Hyjal and 2652 Shen'dralas are carved out of the Kalimdor
    -- instance map, 2548 Riverglades out of Eastern Kingdoms. Membership here
    -- is not cosmetic: UpdateWorld walks these lists to stamp winfo[4]/winfo[5]
    -- (the zone's world anchor) from MapInfo[winfo.Cont], and Hotspots:Build
    -- iterates them too. A zone missing from the list has no world position at
    -- all, which is why the new zones drew nothing on the continent.
    -- Zephras Isle (2521) and Darkspear Islands (2524) sit on their own
    -- instance maps and stay out until we know where they belong.
    [1] = {1411,1412,1413,1438,1439,1440,1441,1442,1443,1444,1445,1446,1447,1448,1449,1450,1451,1452,1454,1456,1457,2482,2652},
    [2] = {1416,1417,1418,1419,1420,1421,1422,1423,1424,1425,1426,1427,1428,1429,1430,1431,1432,1433,1434,1435,1436,1437,1453,1455,1458,2548},

    [3] = {2521},

    [90] = {91,92,93,112,128,169,206,275,397,417,423,519,623,2524},
    [100] = {},
}

Map.MapInfo = {
    [0] = {        -- Dummy
        Name = "Instance",
        X = 0,
        Y = 0,
    },
    [1] = {
        Name = L["Kalimdor"],
        -- Forever re-exported the continent art into interface/worldmap/kalimdor_c60
        -- (12 tiles, 4x3). MapEngine builds the tile path as
        -- Interface\WorldMap\<FileName>\<FileName><i>, so pointing FileName at the
        -- new folder is all that is needed - the tiles ship in the client.
        FileName = "kalimdor_c60",
        X = -2500,
        Y = 200,
    },
    [2] = {
        Name = L["Eastern Kingdoms"],
        -- Legacy folder was "Azeroth"; Forever ships easternkingdoms_c60.
        FileName = "easternkingdoms_c60",
        X = 2000,
        Y = -200,
    },
    [3] = {
        Name = L["Zephras Isle"],
        X = 440,
        Y = 620,
    },
    [90] = {
        Name = "BG",
        X = 8000,
        Y = 200,
    },
    [100] = {
        Name = "Instance",
        X = 2000,
        Y = 100,
    },
}

Map.BloodelfXO = -503
Map.BloodelfYO = 516
Map.DraeneiXO = -3500
Map.DraeneiYO = -2010

-- UIMapAssignment
Map.MapWorldInfo = {

    -- Dummy if we get a zero on startup
    [-1] = {
        1.0,
        0,0,
    },
    [0] = {
        10,
        0, 0,
        0, 0,        -- Index 4,5 XY world position created for zones in continents 1-5, 9
        Overlay = "barrens",
    },
    [1411] = {
        Scale = 10.575,
        X = 392.5,
        Y = -361.6666,
        Overlay = "durotar_c60",
        Name = L["Durotar"],
    },
    [1412] = {
        -- Forever re-bounded Mulgore (classic era: 10.275 / -409.5834 / 54.58334)
        Scale = 12.308334,
        X = -495.8334,
        Y = -53.3332,
        Overlay = "mulgore_c60",
        Name = L["Mulgore"],
    },
    [1413] = {
        Scale = 20.266668,
        X = -524.5834,
        Y = -322.5,
        Overlay = "barrens_c60",
        Name = L["The Barrens"],
        QAchievementIdH = 4933,
    },
    [12] = {
        Scale = 73.59962,
        X = -3413.32,
        Y = -2559.98,
        -- [1414] Kalimdor
    },
    [13] = {
        Scale = 70.3998,
        X = -3200,
        Y = -1493.32,
        -- [1415] Eastern Kingdoms
    },
    [14] = {
        Scale = 6.9541665039062,
        X = 225.41665039063,
        Y = 28.333331298828,
        Overlay = "arathi",
        Name = L["Arathi Highlands"],
        QAchievementId = 4896,
    },
    [1416] = {
        Scale = 5.6000006,
        X = -156.66666,
        Y = -300,
        Overlay = "alterac_c60",
        Name = L["Alterac Mountains"],
    },
    [1417] = {
        Scale = 7.2000008,
        X = 173.33332,
        Y = 26.66666,
        Overlay = "arathi_c60",
        Name = L["Arathi Highlands"],
    },
    [1418] = {
        Scale = 4.975,
        X = 415.8334,
        Y = 1177.9166,
        Overlay = "badlands_c60",
        Name = L["Badlands"],
        QAchievementId = 4900,
    },
    [1419] = {
        Scale = 6.7,
        X = 248.3334,
        Y = 2113.334,
        Overlay = "blastedlands_c60",
        Name = L["Blasted Lands"],
        QAchievementId = 4909,
    },
    [1420] = {
        Scale = 9.0375,
        X = -606.6666,
        Y = -767.5,
        Overlay = "tirisfal_c60",
        Name = L["Tirisfal Glades"],
    },
    [1421] = {
        Scale = 8.4,
        X = -690,
        Y = -333.3334,
        Overlay = "silverpine_c60",
        Name = L["Silverpine Forest"],
        QAchievementIdH = 4894,
    },
    [1422] = {
        Scale = 8.5999994,
        X = -83.33334,
        Y = -673.3334,
        Overlay = "westernplaguelands_c60",
        Name = L["Western Plaguelands"],
        QAchievementId = 4893,
    },
    [1423] = {
        -- Forever re-bounded EPL (classic era: 7.741666 / 437.0834 / -760)
        Scale = 8.604168,
        X = 451.25,
        Y = -738.3334,
        Overlay = "easternplaguelands_c60",
        Name = L["Eastern Plaguelands"],
        QAchievementId = 4892,
    },
    [1424] = {
        Scale = 6.4,
        X = -213.3334,
        Y = -80,
        Overlay = "hillsbrad_c60",
        Name = L["Hillsbrad Foothills"],
        QAchievementIdH = 4895,
    },
    [1425] = {
        Scale = 7.7,
        X = 315,
        Y = -293.3334,
        Overlay = "hinterlands_c60",
        Name = L["The Hinterlands"],
        QAchievementId = 4897,
    },
    [1426] = {
        Scale = 9.85,
        X = -360.4166,
        Y = 775.4166,
        Overlay = "dunmorogh_c60",
        Name = L["Dun Morogh"],
    },
    [1427] = {
        Scale = 4.4625006,
        X = 64.58334,
        Y = 1220,
        Overlay = "searinggorge_c60",
        Name = L["Searing Gorge"],
        QAchievementId = 4910,
    },
    [1428] = {
        Scale = 5.8583326,
        X = 53.33334,
        Y = 1406.25,
        Overlay = "burningsteppes_c60",
        Name = L["Burning Steppes"],
        QAchievementId = 4901,
    },
    [1429] = {
        Scale = 6.941668,
        X = -307.0834,
        Y = 1587.9166,
        Overlay = "elwynn_c60",
        Name = L["Elwynn Forest"],
    },
    [1430] = {
        Scale = 4.9999994,
        X = 166.66666,
        Y = 1973.3332,
        Overlay = "deadwindpass_c60",
        Name = L["Deadwind Pass"],
    },
    [1431] = {
        Scale = 5.4000006,
        X = -166.66666,
        Y = 1943.3332,
        Overlay = "duskwood_c60",
        Name = L["Duskwood"],
        QAchievementIdA = 4907,
    },
    [1432] = {
        Scale = 5.516666,
        X = 398.75,
        Y = 897.5,
        Overlay = "lochmodan_c60",
        Name = L["Loch Modan"],
        QAchievementIdA = 4899,
    },
    [1433] = {
        Scale = 4.341668,
        X = 336.25,    -- Forever shifted Redridge east (classic era: 314.1666)
        Y = 1715,
        Overlay = "redridge_c60",
        Name = L["Redridge Mountains"],
        QAchievementIdA = 4902,
    },
    [1434] = {
        Scale = 12.7625,
        X = -444.1666,
        Y = 2233.75,
        Overlay = "stranglethorn_c60",
        Name = L["Stranglethorn Vale"],
        QAchievementId = 4906,
    },
    [1435] = {
        Scale = 4.5875,
        X = 444.5834,
        Y = 1924.1666,
        Overlay = "swampofsorrows_c60",
        Name = L["Swamp of Sorrows"],
        QAchievementId = 4904,
    },
    [1436] = {
        Scale = 7.0000006,
        X = -603.3334,
        Y = 1880,
        Overlay = "westfall_c60",
        Name = L["Westfall"],
        QAchievementIdA = 4903,
    },
    [1437] = {
        Scale = 8.2708334,
        X = 77.91666,
        Y = 429.5834,
        Overlay = "wetlands_c60",
        Name = L["Wetlands"],
        QAchievementIdA = 4898,
    },
    [1438] = {
        Scale = 10.183332,
        X = -762.9166,
        Y = -2366.25,
        Overlay = "teldrassil_c60",
        Name = L["Teldrassil"],
    },
    [1439] = {
        Scale = 13.1,
        X = -588.3334,
        Y = -1666.6666,
        Overlay = "darkshore_c60",
        Name = L["Darkshore"],
    },
    [1440] = {
        Scale = 11.533334,
        X = -340,
        Y = -934.5834,
        Overlay = "ashenvale_c60",
        Name = L["Ashenvale"],
    },
    [1441] = {
        Scale = 8.7999994,
        X = 86.66666,
        Y = 793.3334,
        Overlay = "thousandneedles_c60",
        Name = L["Thousand Needles"],
    },
    [1442] = {
        Scale = 9.766666,
        X = -649.1666,
        Y = -583.3334,
        Overlay = "stonetalonmountain_c60",
        Name = L["Stonetalon Mountains"],
        QAchievementId = 4936,
        QAchievementIdH = 4980,
    },
    [1443] = {
        Scale = 8.991666,
        X = -846.6666,
        Y = -90.41666,
        Overlay = "desolace_c60",
        Name = L["Desolace"],
        QAchievementId = 4930,
    },
    [1444] = {
        Scale = 13.9,
        X = -1088.3334,
        Y = 473.3334,
        Overlay = "feralas_c60",
        Name = L["Feralas"],
        QAchievementId = 4932,
        QAchievementIdH = 4979,
    },
    [1445] = {
        Scale = 10.5000002,
        X = 194.99998,
        Y = 406.6666,
        Overlay = "dustwallowmarsh_c60",
        Name = L["Dustwallow Marsh"],
        QAchievementId = 4929,
        QAchievementIdH = 4978,
    },
    [1446] = {
        Scale = 13.8,
        X = 43.75,
        Y = 1175,
        Overlay = "tanaris_c60",
        Name = L["Tanaris"],
        QAchievementId = 4935,
    },
    [1447] = {
        Scale = 10.141666,
        X = 655.4166,
        Y = -1068.3334,
        Overlay = "azshara_c60",
        Name = L["Azshara"],
        QAchievementIdH = 4927,
    },
    [1448] = {
        Scale = 11.5,
        X = -328.3334,
        Y = -1426.6666,
        Overlay = "felwood_c60",
        Name = L["Felwood"],
        QAchievementId = 4931,
    },
    [1449] = {
        Scale = 7.4000006,
        X = -106.66666,
        Y = 1193.3334,
        Overlay = "ungorocrater_c60",
        Name = L["Un'Goro Crater"],
        QAchievementId = 4939,
    },
    [1450] = {
        Scale = 4.616666,
        X = 276.25,
        Y = -1698.3332,
        Overlay = "moonglade_c60",
        Name = L["Moonglade"],
    },
    [1451] = {
        Scale = 6.966668,
        X = -507.5,
        Y = 1191.6668,
        Overlay = "silithus_c60",
        Name = L["Silithus"],
        QAchievementIdA = 4934,
    },
    [1452] = {
        Scale = 14.2000006,
        X = 63.33334,
        Y = -1706.6666,
        Overlay = "winterspring_c60",
        Name = L["Winterspring"],
        QAchievementId = 4940,
    },
    [1453] = {
        -- Forever re-bounded Stormwind (classic era: 2.68854074 / -276.1942 / 1655.7702)
        Scale = 3.475008,
        X = -344.584,
        Y = 1599.166,
        Overlay = "stormwindcity",
        Name = L["Stormwind City"],
        City = true,
        MMOutside = true,
    },
    [1454] = {
        Scale = 2.80521,
        X = 736.1202,
        Y = -454.7754,
        Overlay = "orgrimmar",
        Name = L["Orgrimmar"],
        City = true,
        MMOutside = true,
    },
    --[[[1455] = {
        Scale = 3.47875,
        X = 701.27080078125,
        Y = -497.33334960938,
        Overlay = "orgrimmar",
        MapBaseName = "orgrimmar1_",
        Name = L["Orgrimmar"],
        City = true,
        MMOutside = true,
    },]]--
    [1455] = {
        Scale = 1.5812492,
        X = 142.71828,
        Y = 913.8482,
        Overlay = "ironforge",
        Name = L["Ironforge"],
        City = true,
    },
    [1456] = {
        Scale = 2.0874998,
        X = -103.33332,
        Y = 169.99998,
        Overlay = "thunderbluff",
        Name = L["Thunder Bluff"],
        City = true,
        MMOutside = true,
    },
    [1457] = {
        Scale = 2.116666,
        X = -587.6726,
        Y = -2047.664,
        Overlay = "darnassus",
        Name = L["Darnassus"],
        City = true,
        MMOutside = true,
    },
    [1458] = {
        Scale = 1.91875,
        X = -174.63852,
        Y = -375.589,
        Overlay = "undercity",
        Name = L["Undercity"],
        City = true,
    },
    [1459] = {
        Name = L["Alterac Valley"],
        Scale = 8.4749997558594,
        X = 16000,
        Y = 2000,
        Short = "AV",
    },
    [1460] = {
        Name = L["Warsong Gulch"],
        Scale = 2.2916666259766,
        X = -16000,
        Y = 1000,
        Short = "WG",
    },
    [1461] = {
        Name = L["Arathi Basin"],
        Scale = 3.5124998474121,
        X = -16000,
        Y = 0,
        Short = "AB",
    },

    -- ---------------------------------------------------------------
    -- WoW Forever (game type "camelot") content. Scale/X/Y derived from
    -- UiMapAssignment of build 1.60.1.69893:
    --   Scale = (Region_4 - Region_1) / 500,  X = -Region_4 / 5,  Y = -Region_3 / 5
    -- ---------------------------------------------------------------

    -- Carved out of the Kalimdor instance map (MapID 1), so the world
    -- coordinates line up with the rest of the continent.
    [2482] = {
        Scale = 6.945836,
        X = 184.5832,
        Y = -1260.8332,
        Overlay = "hyjal",
        Name = L["Mount Hyjal"],
    },
    [2652] = {
        Scale = 4.1,
        X = -405,
        Y = 380,
        Overlay = "shendralas",
        Name = L["Shen'dralas"],
    },
    -- Eastern Kingdoms instance map (MapID 0).
    [2548] = {
        Scale = 9.7,
        X = 378.3332,
        Y = 1293.3332,
        Overlay = "riverlands",
        Name = L["Riverglades"],
    },
    [2521] = {
        MId = 2991,
        Name = L["Zephras Isle"],
        Scale = 11.125,
        X = -846.25,
        Y = -991.25,
        Overlay = "zephrasisle",
        Explored = true,
    },
    [2524] = {
        MId = 2997,
        Name = L["Darkspear Islands"],
        Scale = 3.85,
        X = -583.75,
        Y = -89.5832,
        Short = "DI",
        Explored = true,
    },
}

--------

Map.InstanceInfo = {        -- Blizzard instance maps (SetInstanceMap uses size of 3 for table entries)
}

-- UIMapXMapArt -> WorldMapOverlay -> WorldMapOverlayTitle
Map.ZoneOverlays = {

-- AUTO-GENERATED for WoW Forever ("camelot") from the wago.tools DB2 of build
-- 1.60.1.69893:  generate_overlays.py --cache-dir <db2> --all
-- Blizzard re-authored every vanilla zone map into interface/worldmap/<zone>_c60,
-- so the legacy name-keyed entries would have drawn the old art on the new maps.
-- Keys here are the fileDataID lists of the overlay tiles and the renderer sets
-- them by ID (MapEngine: arTx path), so no texture folder is involved and
-- nothing has to be extracted from the client.
-- Value is "x,y,w,h"; the comment is subzone|uiMapID|grid.
-- Cities and battlegrounds have no overlays in DB2 and are absent here.

["durotar_c60"] = {
    ["8073637"] = "427,78,256,256", -- drygulchravine|5358|1x1
    ["8074089"] = "549,427,256,241", -- echoisles|5359|1x1
    ["8074090"] = "413,476,256,128", -- kolkarcrag|5360|1x1
    ["8074091,8074092"] = "244,0,512,256", -- orgrimmar|5361|2x1
    ["8074093"] = "432,170,256,256", -- razorhill|5362|1x1
    ["8074094"] = "301,189,256,256", -- razormanegrounds|5363|1x1
    ["8074095"] = "474,384,256,256", -- senjinvillage|5364|1x1
    ["8074096"] = "464,33,128,128", -- skullrock|5365|1x1
    ["8074097"] = "327,60,256,256", -- thunderridge|5366|1x1
    ["8074098"] = "462,286,256,256", -- tiragardekeep|5367|1x1
    ["8074099"] = "355,320,256,256", -- valleyoftrials|5368|1x1
},

["mulgore_c60"] = {
    ["7938948,7938949"] = "277,448,462,210", -- redcloudmesa|182|2x1
    ["7938946"] = "262,349,171,231", -- palemanerock|184|1x1
    ["7938945"] = "357,328,238,206", -- bloodhoofvillage|186|1x1
    ["7938961"] = "458,389,121,136", -- winterhoofwaterwell|188|1x1
    ["7938954"] = "494,381,253,151", -- therollingplains|190|1x1
    ["7938955"] = "509,279,227,214", -- theventurecomine|192|1x1
    ["7938947"] = "451,289,143,139", -- ravagedcaravan|194|1x1
    ["7938953"] = "419,170,220,214", -- thegoldenplains|196|1x1
    ["7938958"] = "369,266,151,158", -- thunderhornwaterwell|198|1x1
    ["7938944"] = "270,265,194,164", -- baeldundigsite|200|1x1
    ["7938956,7938957"] = "250,131,284,204", -- thunderbluff|202|2x1
    ["7938959"] = "339,71,159,157", -- wildmanewaterwell|204|1x1
    ["7938950"] = "496,119,180,181", -- redrocks|206|1x1
    ["7938960"] = "416,50,190,183", -- windfuryridge|208|1x1
    ["7938951,7938952"] = "218,0,303,225", -- skywatcher|4987|2x1
},

["barrens_c60"] = {
    ["8095985"] = "340,234,256,256", -- agamagor|5463|1x1
    ["8095986"] = "431,479,128,128", -- baelmodan|5464|1x1
    ["8095999"] = "335,462,256,128", -- blackthornridge|5465|1x1
    ["8096000"] = "555,0,128,128", -- boulderlodemine|5466|1x1
    ["8096001"] = "442,298,128,256", -- bramblescar|5467|1x1
    ["8096002"] = "365,350,256,128", -- camptaurajo|5468|1x1
    ["8096003"] = "419,63,128,128", -- deadmistpeak|5469|1x1
    ["8096004"] = "564,52,128,256", -- farwatchpost|5470|1x1
    ["8096005"] = "355,402,256,256", -- fieldofgiants|5471|1x1
    ["8096006"] = "492,63,128,128", -- groldomfarm|5472|1x1
    ["8096007"] = "306,130,128,128", -- honorsstand|5473|1x1
    ["8096008"] = "365,177,256,256", -- lushwateroasis|5474|1x1
    ["8096009"] = "527,307,256,128", -- northwatchhold|5475|1x1
    ["8096010"] = "507,294,128,128", -- raptorgrounds|5476|1x1
    ["8096011"] = "556,189,128,128", -- ratchet|5477|1x1
    ["8096012"] = "407,553,256,115", -- razorfendowns|5478|1x1
    ["8096013"] = "341,537,128,128", -- razorfenkraul|5479|1x1
    ["8096014"] = "481,211,256,128", -- stagnantoasis|5480|1x1
    ["8096015"] = "431,118,256,256", -- thecrossroads|5481|1x1
    ["8096016"] = "317,29,256,256", -- thedryhills|5482|1x1
    ["8096017"] = "384,115,128,128", -- theforgottenpools|5483|1x1
    ["8096018"] = "581,247,128,128", -- themerchantcoast|5484|1x1
    ["8096019"] = "412,0,128,128", -- themorshan|5485|1x1
    ["8096020"] = "456,0,256,128", -- thesludgefen|5486|1x1
    ["8096021"] = "498,119,256,128", -- thornhill|5487|1x1
},

["alterac_c60"] = {
    ["7975729,7975730,7975731,7975732"] = "626,253,376,384", -- chillwindpoint|5036|2x2
    ["7975733,7975734"] = "399,380,256,288", -- corrahnsdagger|5037|1x2
    ["7975735,7975736"] = "334,162,288,256", -- crushridgehold|5038|2x1
    ["7975744,7975745,7975746,7975747"] = "0,207,426,461", -- newdalaran|5039|2x2
    ["7975737,7975738"] = "276,0,288,256", -- dandredsfold|5040|2x1
    ["7975739"] = "406,279,256,256", -- gallowscorner|5041|1x1
    ["7975740"] = "225,478,256,190", -- gavinsnaze|5042|1x1
    ["7975741"] = "317,372,256,256", -- growlesscave|5043|1x1
    ["7975742,7975743"] = "196,131,256,288", -- mistyshore|5044|1x2
    ["7975748,7975749"] = "0,447,454,221", -- newlordamere|5045|2x1
    ["7975750"] = "270,197,256,256", -- ruinsofalterac|5046|1x1
    ["7975751,7975752"] = "462,307,256,320", -- soferasnaze|5047|1x2
    ["7975753,7975754,7975755,7975756"] = "549,105,384,320", -- strahnbrad|5048|2x2
    ["7975757"] = "314,471,256,197", -- theheadland|5049|1x1
    ["7975758"] = "462,77,256,256", -- theuplands|5050|1x1
},

["arathi_c60"] = {
    ["8039746"] = "432,362,256,256", -- boulderfisthall|5087|1x1
    ["8039747"] = "232,145,256,256", -- bouldergor|5088|1x1
    ["8039748"] = "558,112,256,256", -- circleofeastbinding|5089|1x1
    ["8039749"] = "286,310,256,256", -- circleofinnerbinding|5090|1x1
    ["8039750"] = "419,293,256,256", -- circleofouterbinding|5091|1x1
    ["8039751"] = "138,54,256,256", -- circleofwestbinding|5092|1x1
    ["8039752"] = "472,165,256,256", -- dabyriesfarmstead|5093|1x1
    ["8039753"] = "171,424,256,244", -- faldirscove|5094|1x1
    ["8039754"] = "531,276,256,256", -- goshekfarm|5095|1x1
    ["8039755"] = "656,119,256,256", -- hammerfall|5096|1x1
    ["8039756"] = "192,90,256,256", -- northfoldmanor|5097|1x1
    ["8039757"] = "370,186,256,256", -- refugepoint|5098|1x1
    ["8039758"] = "108,287,256,256", -- stromgardekeep|5099|1x1
    ["8039759"] = "355,412,256,256", -- thandolspan|5100|1x1
    ["8039760"] = "87,138,256,256", -- thoradinswall|5101|1x1
    ["8039761"] = "559,333,256,256", -- witherbarkvillage|5102|1x1
},

["badlands_c60"] = {
    ["7939140,7939141,7939142,7939143"] = "345,389,288,279", -- agmondsend|5213|2x2
    ["7939144"] = "325,148,256,256", -- angorfortress|5214|1x1
    ["7939145"] = "17,310,256,256", -- apocryphansrest|5215|1x1
    ["7939146,7939147"] = "501,341,256,288", -- campboff|5216|1x2
    ["7939148"] = "12,428,256,240", -- campcagg|5217|1x1
    ["7939149"] = "551,48,256,256", -- campkosh|5218|1x1
    ["7939150"] = "498,209,256,256", -- dustwindgulch|5219|1x1
    ["7939151"] = "445,121,256,256", -- hammertoesdigsite|5220|1x1
    ["7938928"] = "0,148,256,256", -- kargath|5221|1x1
    ["7939152,7939153,7939154,7939155"] = "611,110,384,512", -- lethlorravine|5222|2x2
    ["7939156,7939157"] = "148,384,288,256", -- mirageflats|5223|2x1
    ["7939158,7939159,7939160,7939161"] = "159,199,288,288", -- thedustbowl|5224|2x2
    ["7939162"] = "389,7,256,256", -- themakersterrace|5225|1x1
    ["7939163"] = "349,256,256,256", -- valleyoffangs|5226|1x1
},

["blastedlands_c60"] = {
    ["8040017"] = "310,133,256,256", -- altarofstorms|5103|1x1
    ["8040030"] = "361,15,256,256", -- dreadmaulhold|5104|1x1
    ["8040031"] = "361,195,256,256", -- dreadmaulpost|5105|1x1
    ["8040032"] = "472,9,256,256", -- garrisonarmory|5106|1x1
    ["8040033"] = "559,30,256,256", -- nethergardekeep|5107|1x1
    ["8040034"] = "405,123,256,256", -- riseofthedefiler|5108|1x1
    ["8040035"] = "501,140,256,256", -- serpentscoil|5109|1x1
    ["8040036,8040037"] = "453,259,288,256", -- thedarkportal|5110|2x1
    ["8040038,8040039,8040040,8040041"] = "212,178,384,490", -- thetaintedscar|5111|2x2
},

["tirisfal_c60"] = {
    ["7958233"] = "335,139,256,256", -- agamandmills|4997|1x1
    ["7958234"] = "630,326,256,256", -- balnirfarmstead|4998|1x1
    ["7958235,7958236"] = "584,139,256,288", -- brightwaterlake|4999|1x2
    ["7958237"] = "537,299,128,256", -- brill|5000|1x1
    ["7958238"] = "474,327,256,128", -- coldhearthmanor|5001|1x1
    ["7958239"] = "694,289,256,128", -- crusaderoutpost|5002|1x1
    ["7958240"] = "227,328,256,256", -- deathknell|5003|1x1
    ["7958241"] = "497,145,256,256", -- garrenshaunt|5004|1x1
    ["7958242"] = "746,125,256,256", -- monastary|5005|1x1
    ["7958243"] = "363,349,256,256", -- nightmarevale|5006|1x1
    ["7958244,7958245"] = "463,361,320,256", -- ruinsoflordaeron|5007|2x1
    ["7958246"] = "689,104,256,256", -- scarletwatchpost|5008|1x1
    ["7958247"] = "239,250,256,256", -- solidenfarmstead|5009|1x1
    ["7958248"] = "395,277,256,128", -- stillwaterpond|5010|1x1
    ["7958249"] = "698,362,256,256", -- thebulwark|5011|1x1
    ["7958262"] = "757,205,245,256", -- venomwebvale|5012|1x1
    ["7958263,7958264,7958265,7958266"] = "4,198,335,424", -- whisperingforest|5013|2x2
},

["silverpine_c60"] = {
    ["8064912"] = "494,262,256,256", -- ambermill|5198|1x1
    ["8064914"] = "491,417,256,251", -- berensperil|5199|1x1
    ["8064915"] = "470,261,256,256", -- deepelemmine|5200|1x1
    ["8064916"] = "593,74,256,256", -- fenrisisle|5201|1x1
    ["8064917"] = "465,0,256,256", -- maldensorchard|5202|1x1
    ["8064919"] = "323,128,256,128", -- northtideshollow|5203|1x1
    ["8064920"] = "382,252,256,256", -- olsensfarthing|5204|1x1
    ["8064922"] = "391,446,256,128", -- pyrewoodvillage|5205|1x1
    ["8064923"] = "364,359,256,256", -- shadowfangkeep|5206|1x1
    ["8064943"] = "402,65,256,256", -- thedeadfield|5207|1x1
    ["8064944"] = "457,144,256,256", -- thedecrepitferry|5208|1x1
    ["8064946"] = "379,446,256,222", -- thegreymanewall|5209|1x1
    ["8064947"] = "352,168,256,256", -- thesepulcher|5210|1x1
    ["8064949"] = "459,13,256,256", -- theshiningstrand|5211|1x1
    ["8064950"] = "286,37,256,256", -- theskitteringdark|5212|1x1
},

["westernplaguelands_c60"] = {
    ["8067724"] = "137,293,256,256", -- bulwark|5279|1x1
    ["8067725"] = "600,412,256,256", -- caerdarrow|5280|1x1
    ["8067726"] = "381,265,256,256", -- dalsonstears|5281|1x1
    ["8067727,8067728,8067729,8067730"] = "504,343,384,288", -- darrowmerelake|5282|2x2
    ["8067731"] = "300,311,256,128", -- felstonefield|5283|1x1
    ["8067732"] = "520,250,256,256", -- gahrronswithering|5284|1x1
    ["8067733,8067734,8067735,8067736"] = "307,16,384,288", -- hearthglen|5285|2x2
    ["8067737"] = "382,164,256,256", -- northridgelumbercamp|5286|1x1
    ["8067738,8067739"] = "260,355,288,256", -- ruinsofandorhol|5287|2x1
    ["8067740,8067741"] = "355,462,320,206", -- sorrowhill|5288|2x1
    ["8067742"] = "566,198,256,256", -- theweepingcave|5289|1x1
    ["8067743"] = "451,323,256,256", -- thewrithinghaunt|5290|1x1
    ["8067744,8067745"] = "590,86,256,384", -- thondrorilriver|5291|1x2
},

["easternplaguelands_c60"] = {
    ["7997922"] = "352,136,253,254", -- blackwoodlake|5051|1x1
    ["7997923"] = "417,259,226,216", -- corinscrossing|5052|1x1
    ["7997924"] = "218,313,242,206", -- crownguardtower|5053|1x1
    ["7997925"] = "213,405,231,231", -- darrowshire|5054|1x1
    ["7997938"] = "508,160,193,200", -- eastwalltower|5055|1x1
    ["7997939,7997940,7997941,7997942"] = "409,353,260,283", -- lakemereldar|5056|2x2
    ["7997943"] = "644,256,180,217", -- lightshopechapel|5057|1x1
    ["7997944,7997945,7997946,7997947"] = "678,202,324,466", -- newavalon|5058|2x2
    ["7997948"] = "544,62,227,234", -- northdale|5059|1x1
    ["7997949,7997950"] = "386,34,258,237", -- northpasstower|5060|2x1
    ["7997951,7997952,7997953,7997954"] = "125,28,361,289", -- plaguewood|5061|2x2
    ["7997955"] = "341,0,256,160", -- quellithienlodge|5062|1x1
    ["7997956,7997957"] = "18,0,419,174", -- stratholme|5063|2x1
    ["7997958,7997959"] = "11,19,228,313", -- terrordale|5064|1x2
    ["7997960,7997961"] = "203,186,273,244", -- thefungalvale|5065|2x1
    ["7997962"] = "534,247,207,255", -- theinfectisscar|5066|1x1
    ["7997963,7997964"] = "86,221,239,283", -- themarrisstead|5067|1x2
    ["7997965,7997966,7997967,7997968"] = "609,0,393,349", -- thenoxiousglade|5068|2x2
    ["7997969,7997970"] = "331,299,235,323", -- thepestilentscar|5069|1x2
    ["7997971,7997972"] = "111,399,231,259", -- theundercroft|5070|1x2
    ["7997973,7997974"] = "0,112,230,462", -- thondrorilriver|5071|1x2
    ["7997975,7997976,7997977,7997978"] = "542,366,286,289", -- tyrshand|5072|2x2
    ["7997979,7997980"] = "485,0,309,172", -- zulmashar|5073|2x1
},

["hillsbrad_c60"] = {
    ["8062819"] = "175,275,256,256", -- azureloadmine|5168|1x1
    ["8062820"] = "414,154,256,256", -- darrowhill|5169|1x1
    ["8062821,8062822"] = "637,294,256,288", -- dungarok|5170|1x2
    ["8062823,8062824,8062825,8062826"] = "605,75,384,384", -- durnholdekeep|5171|2x2
    ["8062827,8062828"] = "524,339,256,320", -- easternstrand|5172|1x2
    ["8062829,8062830,8062831,8062832"] = "198,155,320,288", -- hillsbradfields|5173|2x2
    ["8062845"] = "541,236,256,256", -- nethanderstead|5174|1x1
    ["8062846"] = "108,482,129,128", -- purgationisle|5175|1x1
    ["8062847,8062848"] = "2,192,288,256", -- southpointtower|5176|2x1
    ["8062849,8062850"] = "398,196,256,320", -- southshore|5177|1x2
    ["8062851,8062852"] = "509,0,256,320", -- tarrenmill|5178|1x2
    ["8062853,8062854"] = "208,368,288,256", -- westernstrand|5179|2x1
},

["hinterlands_c60"] = {
    ["8067557"] = "13,245,256,256", -- aeriepeak|5265|1x1
    ["8067558"] = "374,164,256,256", -- agolwatha|5266|1x1
    ["8067571"] = "171,306,256,256", -- hiriwatha|5267|1x1
    ["8067572,8067573"] = "505,333,256,288", -- jinthaalor|5268|1x2
    ["8067574"] = "158,149,256,256", -- plaguemistravine|5269|1x1
    ["8067575"] = "237,185,256,256", -- queldanillodge|5270|1x1
    ["8067576,8067577,8067578,8067579"] = "509,19,288,288", -- seradane|5271|2x2
    ["8067580"] = "240,387,256,256", -- shadraalor|5272|1x1
    ["8067581,8067582"] = "571,239,288,256", -- shaolwatha|5273|2x1
    ["8067583"] = "512,232,256,256", -- skulkrock|5274|1x1
    ["8067584"] = "373,365,256,256", -- thealtarofzul|5275|1x1
    ["8067585"] = "408,260,256,256", -- thecreepingruin|5276|1x1
    ["8067586,8067587"] = "693,303,256,320", -- theoverlookcliffs|5277|1x2
    ["8067588"] = "319,302,256,256", -- valorwindlake|5278|1x1
},

["dunmorogh_c60"] = {
    ["8061325"] = "573,280,128,128", -- amberstillranch|5125|1x1
    ["8061326"] = "155,403,256,256", -- anvilmar|5126|1x1
    ["8061327"] = "252,249,128,128", -- brewnallvillage|5127|1x1
    ["8061328"] = "274,296,256,128", -- chillbreezevalley|5128|1x1
    ["8061329"] = "295,385,256,128", -- coldridgepass|5129|1x1
    ["8061342"] = "217,287,128,128", -- frostmanehold|5130|1x1
    ["8061343"] = "166,184,256,256", -- gnomeragon|5131|1x1
    ["8061344"] = "608,291,256,256", -- golbolarquarry|5132|1x1
    ["8061345"] = "694,273,256,256", -- helmsbedlake|5133|1x1
    ["8061346"] = "281,167,128,256", -- iceflowlake|5134|1x1
    ["8061347,8061348"] = "397,163,320,256", -- ironforge|5135|2x1
    ["8061349"] = "386,294,256,256", -- kharanos|5136|1x1
    ["8061350"] = "502,221,128,256", -- mistypinerefuge|5137|1x1
    ["8061351"] = "759,173,128,256", -- northernoutpost|5138|1x1
    ["8061352"] = "347,163,128,256", -- shimmerridge|5139|1x1
    ["8061353"] = "792,279,128,128", -- southernoutpost|5140|1x1
    ["8061354"] = "314,311,256,256", -- thegrizzledden|5141|1x1
    ["8061355"] = "522,322,256,128", -- thetundridhills|5142|1x1
},

["searinggorge_c60"] = {
    ["8064749,8064750"] = "77,366,288,256", -- blackcharcave|5191|2x1
    ["8064751,8064752,8064753,8064754"] = "422,8,512,384", -- dustfirevalley|5192|2x2
    ["8064755,8064756,8064757,8064758"] = "85,30,512,512", -- firewatchridge|5193|2x2
    ["8064759,8064760"] = "494,300,320,256", -- grimesiltdigsite|5194|2x1
    ["8064773,8064774"] = "545,407,320,256", -- tannercamp|5195|2x1
    ["8064775,8064776,8064777,8064778"] = "250,170,512,384", -- thecauldron|5196|2x2
    ["8064779,8064780,8064781,8064782"] = "247,388,384,280", -- theseaofcinders|5197|2x2
},

["burningsteppes_c60"] = {
    ["8060538"] = "36,109,256,256", -- altarofstorms|5112|1x1
    ["8060539,8060540"] = "173,101,256,288", -- blackrockmountain|5113|1x2
    ["8060541,8060542,8060543,8060544"] = "589,279,288,320", -- blackrockpass|5114|2x2
    ["8060545,8060546"] = "334,114,256,288", -- blackrockstronghold|5115|1x2
    ["8060559,8060560,8060561,8060562"] = "56,258,512,320", -- dracodar|5116|2x2
    ["8060563"] = "707,168,256,256", -- dreadmaulrock|5117|1x1
    ["8060564,8060644,8060645,8060646"] = "708,311,294,288", -- morgansvigil|5118|2x2
    ["8060647,8060648,8060650,8060651"] = "377,285,320,288", -- pillarofash|5119|2x2
    ["8060652,8060653,8060654,8060656"] = "513,99,288,288", -- ruinsofthaurissan|5120|2x2
    ["8060657,8060658,8060659,8060660"] = "722,46,280,384", -- terrorwingpath|5121|2x2
},

["elwynn_c60"] = {
    ["8061955"] = "577,419,256,249", -- brackwellpumpkinpatch|5156|1x1
    ["8061956"] = "422,332,256,256", -- crystallake|5157|1x1
    ["8061957"] = "704,330,256,256", -- eastvaleloggingcamp|5158|1x1
    ["8061970"] = "238,428,256,240", -- fargodeepmine|5159|1x1
    ["8061971,8061972"] = "124,327,256,341", -- forestsedge|5160|1x2
    ["8061973"] = "250,270,256,256", -- goldshire|5161|1x1
    ["8061974"] = "425,431,256,237", -- jerodslanding|5162|1x1
    ["8061975"] = "381,147,256,256", -- northshirevalley|5163|1x1
    ["8061976,8061977"] = "696,435,306,233", -- ridgepointtower|5164|2x1
    ["8061978,8061979"] = "587,190,320,256", -- stonecairnlake|5165|2x1
    ["8061980,8061981,8061982,8061983"] = "0,0,512,512", -- stormwind|5166|2x2
    ["8061984"] = "551,292,256,256", -- towerofazora|5167|1x1
},

["deadwindpass_c60"] = {
    ["8060886,8060887,8060888,8060889"] = "249,76,384,384", -- deadmanscrossing|5122|2x2
    ["8060902,8060903"] = "269,337,320,256", -- karazhan|5123|2x1
    ["8060904,8060905,8060906,8060909"] = "426,299,288,288", -- thevice|5124|2x2
},

["duskwood_c60"] = {
    ["8061676,8061677"] = "55,342,288,256", -- addlesstead|5143|2x1
    ["8061678,8061679"] = "504,117,256,384", -- brightwoodgrove|5144|1x2
    ["8061680,8061681,8061682,8061683"] = "631,162,320,288", -- darkshire|5145|2x2
    ["8061696"] = "653,120,256,256", -- manormistmantle|5146|1x1
    ["8061697"] = "102,302,256,256", -- ravenhill|5147|1x1
    ["8061698,8061699,8061700,8061701"] = "85,149,384,320", -- ravenhillcemetary|5148|2x2
    ["8061702,8061703,8061704,8061705"] = "89,31,913,256", -- thedarkenedbank|5149|4x1
    ["8061706,8061707"] = "19,132,256,384", -- thehushedbank|5150|1x2
    ["8061708"] = "539,369,256,256", -- therottingorchard|5151|1x1
    ["8061709"] = "390,382,256,256", -- theyorgenfarmstead|5152|1x1
    ["8061710"] = "690,353,256,256", -- tranquilgardenscemetery|5153|1x1
    ["8061711,8061712,8061713,8061714"] = "298,79,384,512", -- twilightgrove|5154|2x2
    ["8061715,8061716"] = "243,348,256,288", -- vulgologremound|5155|1x2
},

["lochmodan_c60"] = {
    ["8063099,8063100,8063101,8063102"] = "309,310,320,358", -- grizzlepawridge|5180|2x2
    ["8063103,8063104"] = "482,321,384,256", -- ironbandsexcavationsite|5181|2x1
    ["8063117,8063118"] = "542,48,320,256", -- mogroshstronghold|5182|2x1
    ["8063119,8063120"] = "125,12,256,320", -- northgatepass|5183|1x2
    ["8063121,8063122"] = "229,11,256,320", -- silverstreammine|5184|1x2
    ["8063123,8063126"] = "215,348,256,320", -- stonesplintervalley|5185|1x2
    ["8063127,8063128"] = "339,11,320,256", -- stonewroughtdam|5186|2x1
    ["8063129,8063130,8063131,8063132"] = "546,199,384,320", -- thefarstriderlodge|5187|2x2
    ["8063133,8063134,8063135,8063136"] = "352,87,320,512", -- theloch|5188|2x2
    ["8063137"] = "217,203,256,256", -- thelsamar|5189|1x1
    ["8063138"] = "109,370,256,256", -- valleyofkings|5190|1x1
},

["redridge_c60"] = {
    ["7939758,7939759,7939760,7939761"] = "0,260,331,384", -- threecorners|361|2x2
    ["7939720,7939721,7939722,7939723"] = "118,324,462,324", -- lakeridgehighway|362|2x2
    ["7939713,7939715,7939716,7939717,7939718,7939719"] = "0,223,635,306", -- lakeeverstill|363|3x2
    ["7939724,7939725"] = "0,187,430,218", -- lakeshire|364|2x1
    ["7939726,7939727,7939728,7939729"] = "50,0,399,331", -- redridgecanyons|365|2x2
    ["7939742,7939743,7939744,7939745"] = "202,0,465,281", -- renderscamp|366|2x2
    ["7939703,7939704,7939705,7939706"] = "334,92,266,321", -- althersmill|367|2x2
    ["7939754,7939755,7939756,7939757"] = "436,88,287,442", -- stonewatchkeep|368|2x2
    ["7939746,7939747,7939748,7939749"] = "410,347,506,299", -- rendersvalley|369|2x2
    ["7939750,7939751,7939752,7939753"] = "538,266,464,329", -- stonewatchfalls|370|2x2
    ["7939707,7939708,7939709,7939712"] = "548,0,427,422", -- galardellvalley|371|2x2
},

["stranglethorn_c60"] = {
    ["8065937"] = "241,92,128,128", -- balalruins|5227|1x1
    ["8065938"] = "371,129,128,256", -- baliamahruins|5228|1x1
    ["8065939"] = "194,284,256,256", -- bloodsailcompound|5229|1x1
    ["8065940"] = "203,433,256,128", -- bootybay|5230|1x1
    ["8065941"] = "345,276,128,128", -- crystalveinmine|5231|1x1
    ["8065942"] = "260,132,128,128", -- gromgolbasecamp|5232|1x1
    ["8065943"] = "314,493,128,128", -- jagueroisle|5233|1x1
    ["8065944"] = "299,88,128,128", -- kalairuins|5234|1x1
    ["8065945"] = "388,0,256,256", -- kurzenscompound|5235|1x1
    ["8065946"] = "331,59,128,128", -- lakenazferiti|5236|1x1
    ["8065947"] = "280,368,128,128", -- mistvalevalley|5237|1x1
    ["8065948"] = "311,131,128,128", -- mizjahruins|5238|1x1
    ["8065949"] = "432,94,128,256", -- moshoggogremound|5239|1x1
    ["8065950"] = "211,359,128,128", -- nekmaniwellspring|5240|1x1
    ["8065951"] = "269,26,256,128", -- nesingwarysexpedition|5241|1x1
    ["8065952"] = "284,0,256,128", -- rebelcamp|5242|1x1
    ["8065953"] = "350,335,128,128", -- ruinsofaboraz|5243|1x1
    ["8065954"] = "306,301,128,128", -- ruinsofjubuwal|5244|1x1
    ["8065955"] = "196,3,128,256", -- ruinsofzulkunda|5245|1x1
    ["8065956"] = "394,212,256,128", -- ruinsofzulmamwe|5246|1x1
    ["8065969"] = "235,189,256,256", -- thearena|5247|1x1
    ["8065970"] = "152,90,256,256", -- thevilereef|5248|1x1
    ["8065979"] = "387,64,128,128", -- venturecobasecamp|5249|1x1
    ["8065972"] = "229,422,256,246", -- wildshore|5250|1x1
    ["8065973"] = "364,231,128,128", -- ziatajairuins|5251|1x1
    ["8065975"] = "156,42,128,128", -- zuuldalaruins|5253|1x1
},

["swampofsorrows_c60"] = {
    ["8067384,8067385,8067386,8067387"] = "492,0,384,320", -- fallowsanctuary|5254|2x2
    ["8067388"] = "0,262,256,256", -- ithariuscave|5255|1x1
    ["8067389,8067390,8067391"] = "746,0,256,668", -- mistyreedstrand|5256|1x3
    ["8067392,8067393"] = "0,140,256,320", -- mistyvalley|5257|1x2
    ["8067394,8067395,8067396,8067397"] = "565,218,320,288", -- pooloftears|5258|2x2
    ["8067398,8067399"] = "724,120,256,384", -- sorrowmurk|5259|1x2
    ["8067400,8067401"] = "129,236,288,256", -- splinterspearjunction|5260|2x1
    ["8067402,8067403"] = "552,378,384,256", -- stagalbog|5261|2x1
    ["8067404,8067405,8067406,8067407"] = "279,237,384,320", -- stonard|5262|2x2
    ["8067420"] = "171,145,256,256", -- theharborage|5263|1x1
    ["8067421,8067422"] = "286,110,320,256", -- theshiftingmire|5264|2x1
},

["westfall_c60"] = {
    ["8067794,8067795"] = "204,260,320,256", -- alexstonfarmstead|5292|2x1
    ["8067796"] = "208,375,256,256", -- demontsplace|5293|1x1
    ["8067800"] = "387,11,256,256", -- furlbrowspumpkinfarm|5294|1x1
    ["8067801"] = "220,102,256,256", -- goldcoastquarry|5295|1x1
    ["8067802"] = "307,29,256,256", -- jangolodemine|5296|1x1
    ["8067803"] = "317,331,256,256", -- moonbrook|5297|1x1
    ["8067804"] = "459,105,256,256", -- saldeansfarm|5298|1x1
    ["8067807"] = "442,241,256,256", -- sentinelhill|5299|1x1
    ["8067810"] = "339,418,256,250", -- thedaggerhills|5300|1x1
    ["8067815"] = "524,252,256,256", -- thedeadacre|5301|1x1
    ["8067816,8067817"] = "523,377,288,256", -- thedustplains|5302|2x1
    ["8067818"] = "488,0,256,256", -- thejansenstead|5303|1x1
    ["8067819"] = "328,148,256,256", -- themolsenfarm|5304|1x1
    ["8067820,8067821"] = "205,467,288,201", -- westfalllighthouse|5305|2x1
},

["wetlands_c60"] = {
    ["8068388"] = "347,218,256,256", -- angerfangencampment|5306|1x1
    ["8068389"] = "77,245,256,256", -- blackchannelmarsh|5307|1x1
    ["8068390"] = "89,142,256,256", -- bluegillmarsh|5308|1x1
    ["8068391"] = "507,115,256,256", -- direforgehill|5309|1x1
    ["8068392"] = "401,21,256,256", -- dunmodre|5310|1x1
    ["8068393,8068394,8068395,8068396"] = "611,230,384,384", -- grimbatol|5311|2x2
    ["8068397"] = "349,115,256,256", -- ironbeardstomb|5312|1x1
    ["8068398"] = "13,314,256,128", -- menethilharbor|5313|1x1
    ["8068399"] = "527,264,256,256", -- mosshidefen|5314|1x1
    ["8068400"] = "628,176,256,256", -- raptorridge|5315|1x1
    ["8068401"] = "237,41,256,256", -- saltsprayglen|5316|1x1
    ["8068402,8068403"] = "92,82,320,256", -- sundownmarsh|5317|2x1
    ["8068404"] = "456,125,256,256", -- thegreenbelt|5318|1x1
    ["8068405"] = "470,371,256,256", -- thelganrock|5319|1x1
    ["8068418"] = "247,205,256,256", -- whelgarsexcavationsite|5320|1x1
},

["teldrassil_c60"] = {
    ["8095477"] = "382,281,256,256", -- banethilhollow|5452|1x1
    ["8095478,8095479"] = "101,247,320,256", -- darnassus|5453|2x1
    ["8095480"] = "462,323,256,128", -- dolanaar|5454|1x1
    ["8095481"] = "368,443,256,128", -- gnarlpinehold|5455|1x1
    ["8095482"] = "436,380,256,256", -- lakealameth|5456|1x1
    ["8095483"] = "335,313,128,256", -- poolsofarlithrien|5457|1x1
    ["8095484"] = "494,548,128,120", -- ruttheranvillage|5458|1x1
    ["8095485"] = "491,153,256,256", -- shadowglen|5459|1x1
    ["8095486"] = "561,292,256,256", -- starbreezevillage|5460|1x1
    ["8095500"] = "272,127,256,256", -- theoracleglade|5461|1x1
    ["8095501"] = "377,93,256,256", -- wellspringlake|5462|1x1
},

["darkshore_c60"] = {
    ["8085570"] = "324,306,256,256", -- ametharan|5385|1x1
    ["8085571"] = "318,162,256,256", -- auberdine|5386|1x1
    ["8085572"] = "365,181,256,256", -- bashalaran|5387|1x1
    ["8085573"] = "375,94,256,256", -- cliffspringriver|5388|1x1
    ["8085586"] = "305,412,256,256", -- groveoftheancients|5389|1x1
    ["8085587"] = "229,485,256,183", -- remtravelsexcavation|5390|1x1
    ["8085588"] = "510,0,256,256", -- ruinsofmathystra|5391|1x1
    ["8085589"] = "329,508,256,160", -- themastersglaive|5392|1x1
    ["8085590"] = "468,85,256,256", -- towerofalthalaxx|5393|1x1
},

["ashenvale_c60"] = {
    ["8073181"] = "272,251,256,256", -- astranaar|5321|1x1
    ["8073182"] = "856,151,146,256", -- boughshadow|5322|1x1
    ["8073183"] = "547,426,256,242", -- fallenskylake|5323|1x1
    ["8073184"] = "713,344,256,256", -- felfirehill|5324|1x1
    ["8073185"] = "189,324,256,256", -- firescarshrine|5325|1x1
    ["8073186"] = "392,218,256,256", -- irislake|5326|1x1
    ["8073187"] = "131,137,128,256", -- lakefalathim|5327|1x1
    ["8073188,8073190"] = "205,38,256,320", -- maestraspost|5328|1x2
    ["8073191,8073192"] = "356,347,288,256", -- mystrallake|5329|2x1
    ["8073193"] = "597,258,256,256", -- nightrun|5330|1x1
    ["8073194"] = "520,238,256,256", -- raynewoodretreat|5331|1x1
    ["8073195,8073196"] = "694,225,288,256", -- satyrnaar|5332|2x1
    ["8073197"] = "463,141,256,256", -- thehowlingvale|5333|1x1
    ["8073198"] = "260,373,256,256", -- theruinsofstardust|5334|1x1
    ["8073199"] = "104,259,256,256", -- theshrineofaessina|5335|1x1
    ["8073200"] = "19,28,256,256", -- thezoramstrand|5336|1x1
    ["8073201"] = "203,158,256,256", -- thislefurvillage|5337|1x1
    ["8073202"] = "796,311,206,256", -- warsonglumbercamp|5338|1x1
},

["thousandneedles_c60"] = {
    ["8096360,8096361,8096362,8096363"] = "0,0,320,320", -- campethok|5488|2x2
    ["8096364"] = "259,131,256,256", -- darkcloudpinnacle|5489|1x1
    ["8096365"] = "357,264,256,256", -- freewindpost|5490|1x1
    ["8096366"] = "31,155,256,256", -- highperch|5491|1x1
    ["8096367"] = "391,192,256,256", -- splithoofcrag|5492|1x1
    ["8096368"] = "205,70,256,256", -- thegreatlift|5493|1x1
    ["8096369"] = "179,200,256,256", -- thescreechingcanyon|5494|1x1
    ["8096370,8096371,8096372,8096373"] = "610,300,320,368", -- theshimmeringflats|5495|2x2
    ["8096386"] = "492,250,256,256", -- windbreakcanyon|5496|1x1
},

["stonetalonmountain_c60"] = {
    ["8094123"] = "572,561,256,107", -- boulderslideravine|5421|1x1
    ["8094124"] = "718,571,256,97", -- campaparaje|5422|1x1
    ["8094125"] = "668,515,256,128", -- grimtotempost|5423|1x1
    ["8094126"] = "663,582,128,86", -- malakajin|5424|1x1
    ["8094127"] = "390,145,256,256", -- mirkfallonlake|5425|1x1
    ["8094128"] = "475,433,128,128", -- sishircanyon|5426|1x1
    ["8094141,8094142"] = "247,0,288,256", -- stonetalonpeak|5427|2x1
    ["8094143"] = "389,320,256,256", -- sunrockretreat|5428|1x1
    ["8094144,8094145"] = "210,234,256,384", -- thecharredvale|5429|1x2
    ["8094146,8094147,8094148,8094149"] = "457,282,288,384", -- webwinderpath|5430|2x2
    ["8094150,8094151,8094152,8094153"] = "553,197,320,288", -- windshearcrag|5431|2x2
},

["desolace_c60"] = {
    ["7963797"] = "311,61,256,256", -- ethelrethor|5014|1x1
    ["7963798"] = "293,426,256,242", -- gelkisvillage|5015|1x1
    ["7963799,7963800"] = "387,244,288,256", -- kodograveyard|5016|2x1
    ["7963801"] = "607,215,256,256", -- kolkarvillage|5017|1x1
    ["7963802"] = "555,181,256,256", -- kormekshut|5018|1x1
    ["7963803,7963804"] = "590,365,256,288", -- magramvillage|5019|1x2
    ["7963805,7963806,7963807,7963808"] = "399,380,288,288", -- mannoroccoven|5020|2x2
    ["7963809"] = "554,0,256,256", -- nijelspoint|5021|1x1
    ["7963810"] = "241,6,128,128", -- ranazjarisle|5022|1x1
    ["7963811,7963812,7963813,7963814"] = "598,10,360,328", -- sargeron|5023|2x2
    ["7963815"] = "690,444,256,224", -- shadowbreakravine|5024|1x1
    ["7963816"] = "167,389,256,256", -- shadowpreyvillage|5025|1x1
    ["7963817"] = "431,0,256,256", -- tethrisaran|5026|1x1
    ["7963818"] = "447,102,256,256", -- thunderaxefortress|5027|1x1
    ["7963819,7963820"] = "212,215,256,288", -- valleyofspears|5028|1x2
},

["feralas_c60"] = {
    ["8078745"] = "689,233,256,256", -- campmojache|5369|1x1
    ["8078746"] = "454,201,256,256", -- diremaul|5370|1x1
    ["8078759"] = "486,329,128,128", -- feralscarvale|5371|1x1
    ["8078760"] = "478,386,128,256", -- frayfeatherhighlands|5372|1x1
    ["8078761"] = "690,141,256,256", -- gordunnioutpost|5373|1x1
    ["8078762"] = "623,167,128,256", -- grimtotemcompound|5374|1x1
    ["8078763,8078764"] = "192,375,256,293", -- isleofdread|5375|1x2
    ["8078765"] = "751,198,251,256", -- lowerwilds|5376|1x1
    ["8078766"] = "493,70,128,128", -- oneiros|5377|1x1
    ["8078767"] = "540,320,256,256", -- ruinsofisildien|5378|1x1
    ["8078768"] = "305,0,256,256", -- ruinsofravenwind|5379|1x1
    ["8078769"] = "208,234,256,256", -- sardorisle|5380|1x1
    ["8078770"] = "454,0,256,128", -- thedreambough|5381|1x1
    ["8078771,8078772"] = "404,256,256,320", -- theforgottencoast|5382|1x2
    ["8078773,8078774"] = "319,75,288,256", -- thetwincolossals|5383|2x1
    ["8078775"] = "618,298,256,256", -- thewrithingdeep|5384|1x1
},

["dustwallowmarsh_c60"] = {
    ["8085988"] = "660,21,256,256", -- alcazisland|5394|1x1
    ["8085989,8085990"] = "239,189,512,256", -- backbaywetlands|5395|2x1
    ["8085991,8085992,8085993,8085994"] = "230,0,288,288", -- brackenwallvillage|5396|2x2
    ["8086007"] = "257,313,256,256", -- thedenofflame|5397|1x1
    ["8086008"] = "534,224,256,256", -- theramore|5398|1x1
    ["8086009,8086010"] = "367,381,288,256", -- thewyrmbog|5399|2x1
    ["8086011,8086012"] = "422,0,256,320", -- witchhill|5400|1x2
},

["tanaris_c60"] = {
    ["8095031"] = "363,194,256,256", -- abyssalsands|5432|1x1
    ["8095032"] = "473,234,128,256", -- brokenpillar|5433|1x1
    ["8095033"] = "561,256,256,256", -- cavernsoftime|5434|1x1
    ["8095034"] = "325,289,256,256", -- dunemaulcompound|5435|1x1
    ["8095035"] = "395,346,256,256", -- eastmoonruins|5436|1x1
    ["8095036"] = "421,91,256,256", -- gadgetzan|5437|1x1
    ["8095037"] = "445,511,256,157", -- landsendbeach|5438|1x1
    ["8095038"] = "629,220,256,256", -- lostriggercove|5439|1x1
    ["8095039"] = "533,104,128,256", -- noonshaderuins|5440|1x1
    ["8095040"] = "299,100,256,256", -- sandsorrowwatch|5441|1x1
    ["8095041"] = "499,293,256,256", -- southbreakshore|5442|1x1
    ["8095042"] = "323,359,256,256", -- southmoonruins|5443|1x1
    ["8095043"] = "592,75,256,256", -- steamwheedleport|5444|1x1
    ["8095056"] = "449,372,256,256", -- thegapingchasm|5445|1x1
    ["8095057"] = "252,199,256,256", -- thenoxiouslair|5446|1x1
    ["8095058"] = "203,286,256,256", -- thistleshrubvalley|5447|1x1
    ["8095059"] = "291,434,256,234", -- valleyofthewatchers|5448|1x1
    ["8095060"] = "509,168,256,256", -- waterspringfield|5449|1x1
    ["8095061"] = "611,147,128,256", -- zalashjisden|5450|1x1
    ["8095062"] = "254,0,256,256", -- zulfarrak|5451|1x1
},

["azshara_c60"] = {
    ["8073311,8073312,8073313,8073377"] = "479,201,288,320", -- bayofstorms|5339|2x2
    ["8073442"] = "644,40,256,256", -- bitterreaches|5340|1x1
    ["8073517"] = "191,369,256,256", -- forlornridge|5341|1x1
    ["8073586"] = "77,331,256,256", -- haldarrencampment|5342|1x1
    ["8073612,8073613,8073614"] = "366,0,576,256", -- jaggedreef|5343|3x1
    ["8073615,8073616"] = "296,429,320,239", -- lakemennar|5344|2x1
    ["8073617"] = "478,44,256,256", -- legashencampment|5345|1x1
    ["8073619"] = "552,499,256,128", -- ravencrestmonument|5346|1x1
    ["8073620,8073621,8073622,8073623"] = "238,221,288,288", -- ruinsofeldarath|5347|2x2
    ["8073624"] = "35,422,256,246", -- shadowsongshrine|5348|1x1
    ["8073625,8073626"] = "389,353,384,256", -- southridgebeach|5349|2x1
    ["8073627"] = "681,153,256,256", -- templeofarkkoran|5350|1x1
    ["8073628"] = "499,119,256,256", -- thalassianbasecamp|5351|1x1
    ["8073629,8073630"] = "396,540,512,128", -- theruinedreaches|5352|2x1
    ["8073631"] = "404,194,256,256", -- theshatteredstrand|5353|1x1
    ["8073632,8073633"] = "250,106,256,288", -- timbermawhold|5354|1x2
    ["8073634"] = "818,107,128,256", -- towerofeldara|5355|1x1
    ["8073635"] = "422,95,256,256", -- ursolan|5356|1x1
    ["8073636"] = "84,229,256,256", -- valormok|5357|1x1
},

["felwood_c60"] = {
    ["8093156"] = "292,263,256,256", -- bloodvenomfalls|5401|1x1
    ["8093157"] = "408,533,256,135", -- deadwoodvillage|5402|1x1
    ["8093158"] = "405,429,256,239", -- emeraldsanctuary|5403|1x1
    ["8093159"] = "483,0,256,256", -- felpawvillage|5404|1x1
    ["8093172"] = "420,54,256,256", -- irontreewoods|5405|1x1
    ["8093173"] = "332,465,256,203", -- jadefireglen|5406|1x1
    ["8093174"] = "330,29,256,256", -- jadefirerun|5407|1x1
    ["8093175"] = "271,331,256,128", -- jaedenar|5408|1x1
    ["8093176"] = "496,509,256,159", -- morlosaran|5409|1x1
    ["8093177"] = "297,381,256,256", -- ruinsofconstellas|5410|1x1
    ["8093178"] = "307,123,256,256", -- shatterscarvale|5411|1x1
    ["8093179"] = "548,90,256,256", -- talonbranchglade|5412|1x1
},

["ungorocrater_c60"] = {
    ["8097029,8097030,8097031,8097032"] = "367,178,320,288", -- fireplumeridge|5497|2x2
    ["8097033,8097034,8097035,8097036"] = "121,151,320,384", -- golakkahotsprings|5498|2x2
    ["8097037,8097038,8097039,8097040"] = "582,67,288,288", -- ironstoneplateau|5499|2x2
    ["8097041,8097042,8097043,8097044,8097045,8097046"] = "160,6,576,288", -- lakkaritarpits|5500|3x2
    ["8097047,8097048,8097049,8097050"] = "158,368,384,288", -- terrorrun|5501|2x2
    ["8097051,8097052,8097053,8097054"] = "560,240,320,384", -- themarshlands|5502|2x2
    ["8097055,8097056,8097057,8097058"] = "367,380,384,288", -- theslitheringscar|5503|2x2
},

["moonglade_c60"] = {
    ["8093181,8093182,8093183,8093184,8093185,8093186"] = "244,89,576,512", -- lakeeluneara|5413|3x2
},

["silithus_c60"] = {
    ["8093548,8093549,8093550,8093586"] = "264,11,512,320", -- hiveashi|5414|2x2
    ["8093679,8093771,8093873,8093939"] = "244,284,512,384", -- hiveregal|5415|2x2
    ["8093940,8093941,8093942,8093943"] = "96,143,384,512", -- hivezora|5416|2x2
    ["8093956,8093957,8093958,8093959"] = "499,64,384,384", -- southwindvillage|5417|2x2
    ["8093960,8093961,8093962,8093963"] = "103,23,320,288", -- thecrystalvale|5418|2x2
    ["8093964,8093965"] = "115,412,288,256", -- thescarabwall|5419|2x1
    ["8093966,8093967"] = "343,196,320,256", -- twilightbasecamp|5420|2x1
},

["winterspring_c60"] = {
    ["8097071"] = "447,441,256,227", -- darkwhispergorge|5504|1x1
    ["8097072"] = "509,107,256,256", -- everlook|5505|1x1
    ["8097073"] = "222,172,256,256", -- frostfirehotsprings|5506|1x1
    ["8097074"] = "368,7,256,256", -- frostsaberrock|5507|1x1
    ["8097075"] = "523,376,256,256", -- frostwhisperravine|5508|1x1
    ["8097076"] = "611,242,128,256", -- icethistlehills|5509|1x1
    ["8097077"] = "401,198,256,256", -- lakekeltheril|5510|1x1
    ["8097078"] = "493,258,256,256", -- mazthoril|5511|1x1
    ["8097079"] = "593,340,256,256", -- owlwingthicket|5512|1x1
    ["8097080"] = "392,137,256,256", -- starfallvillage|5513|1x1
    ["8097081"] = "555,27,256,256", -- thehiddengrove|5514|1x1
    ["8097082"] = "229,243,256,128", -- timbermawpost|5515|1x1
    ["8097083"] = "617,158,256,128", -- winterfallvillage|5516|1x1
},

["alteracvalley_c60"] = {
    ["8097530,8097531"] = "348,13,288,256", -- dunbaldar|5517|2x1
    ["8097532,8097533"] = "399,375,256,293", -- frostwolfkeep|5518|1x2
    ["8097534,8097535,8097536,8097537"] = "335,172,320,320", -- icebloodgarrison|5519|2x2
},

["hyjal"] = {
    ["7950773,7950774,7950775,7950776"] = "195,110,321,362", -- cradleoftranquility|4988|2x2
    ["7950777,7950778,7950779,7950780"] = "379,79,361,334", -- daegun|4989|2x2
    ["7950781,7950782,7950783,7950784"] = "0,197,258,338", -- elderwild|4990|2x2
    ["7950785,7950786,7950787,7950788"] = "313,381,307,287", -- felbloodscar|4991|2x2
    ["7950789,7950790,7950791,7950792"] = "42,363,430,305", -- malornesretreat|4992|2x2
    ["7950793"] = "138,213,218,247", -- mourningsrest|4993|1x1
    ["7950794"] = "380,285,254,214", -- shrineofaviana|4994|1x1
    ["7950795,7950796,7950797,7950798"] = "612,69,390,395", -- summitofeternity|4995|2x2
    ["7950799,7950800,7950801,7950802"] = "488,328,502,340", -- taintedfoothills|4996|2x2
},

["zephrasisle"] = {
    ["8124653"] = "600,357,209,191", -- eastpylonwatchtower|5520|1x1
    ["8124654"] = "460,453,146,180", -- fairweatherstables|5521|1x1
    ["8124655"] = "415,289,141,147", -- falaathvillage|5522|1x1
    ["8124656"] = "457,339,158,141", -- overlookstandingstones|5523|1x1
    ["8124657"] = "652,222,227,239", -- rohashispires|5524|1x1
    ["8124658,8124659"] = "475,14,237,265", -- ruinsofbanaethal|5525|1x2
    ["8124660,8124661"] = "494,122,290,217", -- shadowgaleforest|5526|2x1
    ["8124662,8124663,8124664,8124665"] = "248,192,302,257", -- shendarvillage|5527|2x2
    ["8124666"] = "526,252,207,185", -- shrineofakir|5528|1x1
    ["8124667,8124668,8124669,8124670"] = "250,22,325,267", -- thendalgrove|5529|2x2
    ["8124671,8124672,8124673,8124674"] = "479,332,302,336", -- valanaar|5530|2x2
    ["8124675"] = "298,351,198,152", -- westpylonwatchtower|5531|1x1
    ["8124676,8124677"] = "350,372,212,271", -- windfieldorchard|5532|1x2
    ["8124678"] = "398,230,207,206", -- windsonglake|5533|1x1
    ["8124679"] = "381,169,194,150", -- windsongstandingstones|5534|1x1
},

["riverlands"] = {
    ["8032430,8032431,8032432,8032433"] = "493,0,277,291", -- bolderok|5074|2x2
    ["8032436,8032437,8032438,8032439"] = "25,320,382,302", -- bristlehills|5075|2x2
    ["8032440"] = "544,427,241,241", -- farholdekeep|5076|1x1
    ["8032441,8032442,8032443,8032444"] = "309,0,334,313", -- kroldokstronghold|5077|2x2
    ["8032445,8032446,8032447,8032448"] = "292,407,338,261", -- meadowsbrook|5078|2x2
    ["8032449,8032450,8032451,8032452"] = "625,266,261,310", -- powderfuseport|5079|2x2
    ["8032453"] = "504,215,213,200", -- rogmar|5080|1x1
    ["8032454,8032455"] = "371,215,230,274", -- sunnyglade|5081|1x2
    ["8032456"] = "499,330,220,186", -- terralswatch|5082|1x1
    ["8032457"] = "292,291,182,210", -- turnersloggingcamp|5083|1x1
    ["8032458,8032459,8032460,8032461"] = "125,98,343,314", -- twilightsshroud|5084|2x2
    ["8032462"] = "444,413,228,195", -- wheelersgrange|5085|1x1
    ["8032463,8032464,8032465,8032466"] = "633,52,323,318", -- windstead|5086|2x2
},

["shendralas"] = {
    ["7970575,7970581,7970582,7970583"] = "583,0,334,415", -- bristlebackretreat|5029|2x2
    ["7970620,7970621,7970622,7970623"] = "339,180,327,488", -- buildings|5030|2x2
    ["7970584,7970585,7970586,7970587"] = "150,178,316,301", -- evenshadeoverlook|5031|2x2
    ["7970588,7970589,7970590,7970591"] = "570,323,317,331", -- forlorngardens|5032|2x2
    ["7970592,7970593"] = "495,255,257,229", -- magramfront|5033|2x1
    ["7970594,7970595,7970596,7970597"] = "125,362,344,306", -- outcasthideaway|5034|2x2
    ["7970612,7970613,7970614,7970615,7970616,7970617"] = "81,0,620,344", -- valleyofbones|5035|3x2
},
}

--------
-- Minimap block tables (tile key tx*100+ty -> minimap texture fileDataID) are
-- generated from the client WDT files into MapData/MinimapTiles.lua
-- (Map.CamelotKalMapBlks / Map.CamelotEkMapBlks).

-- Zephras Isle has its own instance map (2991), so its minimap tiles live in
-- world/minimaps/2991/ rather than in a continent tileset.
Map.ZephrasMapBlks = {
    [2522] = 7198902,
    [2523] = 7198908,
    [2524] = 7198914,
    [2525] = 7198918,
    [2526] = 7199201,
    [2527] = 7199207,
    [2528] = 7199211,
    [2529] = 7199219,
    [2622] = 7198904,
    [2623] = 7198912,
    [2624] = 7198916,
    [2625] = 7198922,
    [2626] = 7199203,
    [2627] = 7199209,
    [2628] = 7199213,
    [2629] = 7199221,
    [2722] = 7198906,
    [2723] = 7198910,
    [2724] = 7198920,
    [2725] = 7198924,
    [2726] = 7199205,
    [2727] = 7199215,
    [2728] = 7199217,
    [2729] = 7199223,
    [2822] = 7199013,
    [2823] = 7199015,
    [2824] = 7199025,
    [2825] = 7199027,
    [2826] = 7199299,
    [2827] = 7199305,
    [2828] = 7199309,
    [2829] = 7199315,
    [2922] = 7199011,
    [2923] = 7199017,
    [2924] = 7199023,
    [2925] = 7199031,
    [2926] = 7199297,
    [2927] = 7199303,
    [2928] = 7199311,
    [2929] = 7199317,
    [3022] = 7199009,
    [3023] = 7199019,
    [3024] = 7199021,
    [3025] = 7199029,
    [3026] = 7199301,
    [3027] = 7199307,
    [3028] = 7199313,
    [3029] = 7199319,
    [3122] = 7199105,
    [3123] = 7199111,
    [3124] = 7199117,
    [3125] = 7199125,
    [3126] = 7199397,
    [3127] = 7199401,
    [3128] = 7199405,
    [3129] = 7199411,
    [3222] = 7199107,
    [3223] = 7199113,
    [3224] = 7199119,
    [3225] = 7199123,
    [3226] = 7199395,
    [3227] = 7199399,
    [3228] = 7199407,
    [3229] = 7199413,
    [3322] = 7199109,
    [3323] = 7199115,
    [3324] = 7199121,
    [3325] = 7199127,
    [3326] = 7199393,
    [3327] = 7199403,
    [3328] = 7199409,
    [3329] = 7199415,
}

-- Darkspear Islands has its own instance map (2997), so its minimap tiles live in
-- world/minimaps/2997/ rather than in a continent tileset.
Map.DarkspearMapBlks = {
    [2630] = 7252061,
    [2631] = 7253387,
    [2632] = 7253417,
    [2633] = 7253447,
    [2634] = 7253477,
    [2730] = 7253363,
    [2731] = 7253393,
    [2732] = 7253423,
    [2733] = 7253453,
    [2734] = 7253483,
    [2830] = 7253369,
    [2831] = 7253399,
    [2832] = 7253429,
    [2833] = 7253459,
    [2834] = 7253489,
    [2930] = 7253375,
    [2931] = 7253405,
    [2932] = 7253435,
    [2933] = 7253465,
    [2934] = 7253495,
    [3030] = 7253381,
    [3031] = 7253411,
    [3032] = 7253441,
    [3033] = 7253471,
    [3034] = 7253501,
}

Map.MiniMapBlks = {
    [1] = {
        Map.CamelotKalMapBlks,
        1908,
        19, 8,
        Map.MapWorldInfo[13].X + Map.MapInfo[1].X + 1600 + 212.52, Map.MapWorldInfo[13].Y + Map.MapInfo[1].Y + -800 + -266.42,
        "World\\Minimaps\\Kalimdor"
    },
    [2] = {
        Map.CamelotEkMapBlks,
        2420,
        24, 20,
        Map.MapWorldInfo[14].X + Map.MapInfo[2].X -1080, Map.MapWorldInfo[14].Y + Map.MapInfo[2].Y - 1308,
        "World\\Minimaps\\Azeroth"
    },
    [2991] = {
        Map.ZephrasMapBlks,
        2522,
        25, 22,
        Map.MapWorldInfo[2521].X + Map.MapInfo[3].X + 99.58, Map.MapWorldInfo[2521].Y + Map.MapInfo[3].Y + -75.42,
        "World\\Minimaps\\2991"
    },
    [2997] = {
        Map.DarkspearMapBlks,
        2630,
        26, 30,
        Map.MapWorldInfo[2524].X + Map.MapInfo[90].X + -56.25, Map.MapWorldInfo[2524].Y + Map.MapInfo[90].Y + -123.75,
        "World\\Minimaps\\2997"
    }
}

--------
-- Get minimap info for map
-- (map id)
-- ret: table, x, y

function Nx.Map:GetMiniInfo (mapId)

    local winfo = self.MapWorldInfo[mapId]
    if not winfo then return end
    local id = winfo.MId

    if not id then
        id = winfo.Cont

        if not id then
            return
        end

        if id == 9 then        -- BGs?
            return
        end

        local info = self.MapInfo[id]
        if not info then
            return
        end
    end

    local t = self.MiniMapBlks[id]

    if not t then            -- "Isle of Quel'Danas"??

--        if NxData.DebugMap then
--            Nx.prt ("GetMiniInfo: missing %s", id)
--        end
        return
    end

    return t, t[5], t[6]
end

--------
-- Get minimap block file name (256x256 texture)

function Nx.Map:GetMiniBlkName (miniT, x, y)

    local off = x * 100 + y

--    Nx.prtCtrl ("%s, %s, %s = %s", x, y, off, off + miniT[2])

    --V4

    local v = miniT[1][off + miniT[2]]

    if v then

        if #v > 0 then
            return format ("%s\\noLiquid_map%02d_%02d", miniT[7], x + miniT[3], y + miniT[4])
        end
        if (strfind(miniT[7],"HawaiiMainLand")) then
            local hasFac = false
            for factionIndex = 1, GetNumFactions() do
                local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith,canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(factionIndex)
                if (name == "Operation: Shieldwall") or (name == "Dominance Offensive") then
                    hasFac = true
                end
            end
            if (hasFac) then
                if ((x + miniT[3] == 33) or (x + miniT[3] == 34)) and ((y + miniT[4] == 33) or (y + miniT[4] == 34)) then
                    return format("World\\Minimaps\\AllianceBeachDailyArea\\map%02d_%02d", x + miniT[3], y + miniT[4])
                end
                if ((x + miniT[3] == 27) or (x + miniT[3] == 28)) and ((y + miniT[4] == 35) or (y + miniT[4] == 36) or (y + miniT[4] == 37) or (y + miniT[4] == 38)) then
                    return format("World\\Minimaps\\HordeBeachDailyArea\\map%02d_%02d", x + miniT[3], y + miniT[4])
                end
            end
            if (x + miniT[3] >= 18) and (x + miniT[3] <= 25) and (y + miniT[4] >= 17) and (y + miniT[4] <= 24) then
                return format("World\\Minimaps\\MoguIslandDailyArea\\map%02d_%02d",x+miniT[3], y + miniT[4]-2)
            end
          return format ("%s\\map%02d_%02d", miniT[7], x + miniT[3], y + miniT[4])
        else
            return format ("%s\\map%02d_%02d", miniT[7], x + miniT[3], y + miniT[4])
        end

    end
end

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

Map.MapLevels={
    [811] = { [3] = 6010, [4] = 6011, },
    [903] = { [1] = 6012, [2] = 6013, },
    [905] = { [3] = 6010, [4] = 6011, },
    [504] = { [2] = 4014, },
    [321] = { [2] = 1034, },
}

--[[ !!!!!!!!!!!!!!!! PLEASE DONT REMOVE THIS !!!!!!!!!!!!!!!!
function Nx.Map:ConvertMapData()

    local data = {}
    Nx.DumpZoneOverlays = data

    local areas = {}
    Nx.DumpMapAreas = areas

    local wma = { strsplit ("\n", self.WorldMapArea) }
    local wmo = { strsplit ("\n", self.WorldMapOverlay) }

    for n, s in ipairs (wma) do

        local aid, map, _, aname, ay1, ay2, ax1, ax2 = strsplit (",", s)
        aid = tonumber (aid)
        map = tonumber (map)

        aname = gsub (aname, '"', "")
        aname = strlower (aname)
        Nx.prt(aid)
        local nxid = aid
        if nxid and nxid > 0 then

--            local name, minLvl, maxLvl, faction, cont = strsplit ("|", Nx.Zones[nxid])

--            if faction ~= "3" then        -- Not instance

                ay1 = tonumber (ay1)
                ay2 = tonumber (ay2)
                ax1 = tonumber (ax1)
                ax2 = tonumber (ax2)

                local scale = (-ay2 + ay1) / 500
                Nx.prt(scale)
                if scale > 0 then
                    local t = {}
                    areas[nxid] = t
                    t[1] = scale
                    t[2] = -ay1 / 5        -- X
                    t[3] = -ax1 / 5        -- Y
                    t[4] = aname
                    Nx.prt("%s %s %s %s",t[4],t[2],t[3],t[1])
                end
--            end
        end

--        if map == 0 or map == 1 then
--        if map == 648 or map == 646 or map == 730 then        -- Maelstrom
--        if map == 654 then                    -- Gilneas
--        if map == 571 or map == 609 then            -- Northrend, DK start
        if map == 1064 or map == 870 then
--            Nx.prt ("%s %s %s", aid, map, aname)

            local area = {}

            for n, os in ipairs (wmo) do

                -- 84,41,736,0,0,0,"BanethilHollow",175,235,374,221,292,430,375,497,0x0,

                local _, oaid, _, _, _, _, oname, w, h, x, y = strsplit (",", os)

                oname = gsub (oname, '"', "")

                if tonumber (oaid) == aid and #oname > 0 then
                    oname = strlower (oname)
                    area[oname] = format ("%s,%s,%s,%s", x, y, w, h)
                end
            end

            if next (area) then                -- Not empty?
                data[aname] = area
            end
        end
    end
end
]]--

-- Copied from HereBeDragons-Migrate all credit goes to HereBeDragons team
local SetupMigrationData
local MapMigrationData, mapFileToIdMap, uiMapIdToIdMap
function Nx.Map:GetLegacyMapInfo(uiMapId)
    if not uiMapId then return nil end
    if not uiMapIdToIdMap then SetupMigrationData() end
    local c = uiMapIdToIdMap[uiMapId]
    if not c then return end

    local m, f = floor(c / 10000), (c % 10000)
    return m, f, MapMigrationData[m].mapFile
end
MapMigrationData = {
    [4] = { mapFile = "Durotar", [0] = 1, [8] = 2, [12] = 5, [19] = 6, [11] = 4, [10] = 3},
    [9] = { mapFile = "Mulgore", [0] = 7, [6] = 8, [7] = 9},
    [11] = { mapFile = "Barrens", [0] = 10, [20] = 11},
    [13] = { mapFile = "Kalimdor", [0] = 12},
    [14] = { mapFile = "Azeroth", [0] = 13},
    [16] = { mapFile = "Arathi", [0] = 14},
    [17] = { mapFile = "Badlands", [0] = 15, [18] = 16},
    [19] = { mapFile = "BlastedLands", [0] = 17},
    [20] = { mapFile = "Tirisfal", [0] = 18, [13] = 19, [25] = 20},
    [21] = { mapFile = "Silverpine", [0] = 21},
    [22] = { mapFile = "WesternPlaguelands", [0] = 22},
    [23] = { mapFile = "EasternPlaguelands", [0] = 23, [20] = 24},
    [24] = { mapFile = "HillsbradFoothills", [0] = 25},
    [26] = { mapFile = "Hinterlands", [0] = 26},
    [27] = { mapFile = "DunMorogh", [6] = 28, [7] = 29, [11] = 31, [10] = 30, [0] = 27},
    [28] = { mapFile = "SearingGorge", [0] = 32, [15] = 34, [14] = 33, [16] = 35},
    [29] = { mapFile = "BurningSteppes", [0] = 36},
    [30] = { mapFile = "Elwynn", [1] = 38, [2] = 39, [0] = 37, [19] = 40, [21] = 41},
    [32] = { mapFile = "DeadwindPass", [0] = 42, [24] = 45, [22] = 43, [23] = 44, [27] = 46},
    [758] = { mapFile = "TheBastionofTwilight", [1] = 294, [2] = 295, [3] = 296},
    [886] = { mapFile = "TerraceOfEndlessSpring", [0] = 456},
    [1014] = { mapFile = "Dalaran70", [0] = 625, [12] = 629, [4] = 626, [11] = 628, [10] = 627},
    [759] = { mapFile = "HallsofOrigination", [1] = 297, [2] = 298, [3] = 299},
    [887] = { mapFile = "SiegeofNiuzaoTemple", [1] = 458, [2] = 459, [0] = 457},
    [1015] = { mapFile = "Azsuna", [0] = 630, [17] = 631, [19] = 633, [18] = 632},
    [760] = { mapFile = "RazorfenDowns", [1] = 300},
    [888] = { mapFile = "ShadowglenStart", [0] = 460},
    [761] = { mapFile = "RazorfenKraul", [1] = 301},
    [889] = { mapFile = "ValleyofTrialsStart", [0] = 461},
    [1017] = { mapFile = "Stormheim", [1] = 635, [0] = 634, [28] = 640, [27] = 639, [26] = 638, [9] = 636, [25] = 637},
    [762] = { mapFile = "ScarletMonastery", [1] = 302, [2] = 303, [3] = 304, [4] = 305},
    [890] = { mapFile = "CampNaracheStart", [0] = 462},
    [1018] = { mapFile = "Valsharah", [0] = 641, [13] = 642, [15] = 644, [14] = 643},
    [763] = { mapFile = "Scholomance", [1] = 306, [2] = 307, [3] = 308, [4] = 309},
    [891] = { mapFile = "EchoIslesStart", [0] = 463, [9] = 464},
    [510] = { mapFile = "CrystalsongForest", [0] = 127},
    [40] = { mapFile = "Wetlands", [0] = 56},
    [764] = { mapFile = "ShadowfangKeep", [1] = 310, [2] = 311, [3] = 312, [4] = 313, [5] = 314, [6] = 315, [7] = 316},
    [892] = { mapFile = "DeathknellStart", [0] = 465, [12] = 466},
    [1020] = { mapFile = "TwistingNether70", [0] = 645},
    [765] = { mapFile = "Stratholme", [1] = 317, [2] = 318},
    [893] = { mapFile = "SunstriderIsleStart", [0] = 467},
    [1021] = { mapFile = "BrokenShore", [1] = 647, [2] = 648, [0] = 646},
    [766] = { mapFile = "AhnQiraj", [1] = 319, [2] = 320, [3] = 321},
    [894] = { mapFile = "AmmenValeStart", [0] = 468},
    [1022] = { mapFile = "Helheim", [0] = 649},
    [767] = { mapFile = "ThroneofTides", [1] = 322, [2] = 323},
    [895] = { mapFile = "NewTinkertownStart", [0] = 469, [8] = 470},
    [512] = { mapFile = "StrandoftheAncients", [0] = 128},
    [640] = { mapFile = "Deepholm", [1] = 208, [2] = 209, [0] = 207},
    [768] = { mapFile = "TheStonecore", [1] = 324},
    [896] = { mapFile = "MogushanVaults", [1] = 471, [2] = 472, [3] = 473},
    [1024] = { mapFile = "Highmountain", [0] = 650, [29] = 657, [8] = 653, [16] = 654, [5] = 651, [40] = 660, [20] = 655, [21] = 656, [6] = 652, [31] = 659, [30] = 658},
    [321] = { mapFile = "Orgrimmar", [1] = 86, [0] = 85},
    [769] = { mapFile = "Skywall", [1] = 325},
    [897] = { mapFile = "HeartofFear", [1] = 474, [2] = 475},
    [1026] = { mapFile = "HellfireRaid", [1] = 662, [2] = 663, [3] = 664, [4] = 665, [5] = 666, [6] = 667, [7] = 668, [8] = 669, [9] = 670, [0] = 661},
    [161] = { mapFile = "Tanaris", [0] = 71, [17] = 74, [15] = 72, [16] = 73, [18] = 75},
    [1027] = { mapFile = "AraukNashalIntroScenario", [0] = 671},
    [898] = { mapFile = "Scholomance", [1] = 476, [2] = 477, [3] = 478, [4] = 479},
    [1028] = { mapFile = "MardumtheShatteredAbyss", [1] = 673, [2] = 674, [3] = 675, [0] = 672},
    [899] = { mapFile = "ProvingGrounds", [1] = 480},
    [772] = { mapFile = "AhnQirajTheFallenKingdom", [0] = 327},
    [900] = { mapFile = "AncientMoguCrypt", [1] = 481, [2] = 482},
    [1032] = { mapFile = "VaultOfTheWardensDH", [1] = 677, [2] = 678, [3] = 679},
    [81] = { mapFile = "StonetalonMountains", [0] = 65},
    [773] = { mapFile = "ThroneoftheFourWinds", [1] = 328},
    [1034] = { mapFile = "HelmouthShallows", [0] = 694},
    [1035] = { mapFile = "ValhallasWarriorOrderHome", [1] = 695},
    [775] = { mapFile = "CoTMountHyjal", [0] = 329},
    [520] = { mapFile = "TheNexus", [1] = 129},
    [776] = { mapFile = "GruulsLair", [1] = 330},
    [521] = { mapFile = "CoTStratholme", [1] = 131, [0] = 130},
    [1041] = { mapFile = "HallsofValor", [1] = 704, [2] = 705, [0] = 703},
    [522] = { mapFile = "Ahnkahet", [1] = 132},
    [906] = { mapFile = "DustwallowMarshScenarioAlliance", [0] = 483},
    [523] = { mapFile = "UtgardeKeep", [1] = 133, [2] = 134, [3] = 135},
    [779] = { mapFile = "MagtheridonsLair", [1] = 331},
    [524] = { mapFile = "UtgardePinnacle", [1] = 136, [2] = 137},
    [41] = { mapFile = "Teldrassil", [2] = 58, [3] = 59, [4] = 60, [0] = 57, [5] = 61},
    [780] = { mapFile = "CoilfangReservoir", [1] = 332},
    [525] = { mapFile = "HallsofLightning", [1] = 138, [2] = 139},
    [781] = { mapFile = "ZulAman", [0] = 333},
    [526] = { mapFile = "Ulduar77", [1] = 140},
    [782] = { mapFile = "TempestKeep", [1] = 334},
    [527] = { mapFile = "TheEyeofEternity", [1] = 141},
    [911] = { mapFile = "KrasarangAlliance", [0] = 486},
    [528] = { mapFile = "Nexus80", [1] = 143, [2] = 144, [3] = 145, [4] = 146, [0] = 142},
    [912] = { mapFile = "KrasarangPatience", [0] = 487},
    [529] = { mapFile = "Ulduar", [1] = 148, [2] = 149, [3] = 150, [4] = 151, [5] = 152, [0] = 147},
    [1057] = { mapFile = "MaelstromShaman", [0] = 726},
    [530] = { mapFile = "Gundrak", [1] = 154, [0] = 153},
    [1059] = { mapFile = "TerraceofEndlessSpringScenario", [0] = 728},
    [914] = { mapFile = "VoljinScenario", [1] = 489, [0] = 488},
    [531] = { mapFile = "TheObsidianSanctum", [0] = 155},
    [532] = { mapFile = "VaultofArchavon", [1] = 156},
    [533] = { mapFile = "AzjolNerub", [1] = 157, [2] = 158, [3] = 159},
    [789] = { mapFile = "SunwellPlateau", [1] = 336, [0] = 335},
    [534] = { mapFile = "DrakTharonKeep", [1] = 160, [2] = 161},
    [1067] = { mapFile = "DarkheartThicket", [0] = 733},
    [535] = { mapFile = "Naxxramas", [1] = 162, [2] = 163, [3] = 164, [4] = 165, [5] = 166, [6] = 167},
    [1069] = { mapFile = "TheBeyond", [1] = 736},
    [919] = { mapFile = "BlackTempleScenario", [1] = 491, [2] = 492, [3] = 493, [4] = 494, [5] = 495, [6] = 496, [7] = 497, [0] = 490},
    [536] = { mapFile = "VioletHold", [1] = 168},
    [1071] = { mapFile = "FirelandsShaman", [0] = 738},
    [920] = { mapFile = "KrasarangHorde", [0] = 498},
    [1072] = { mapFile = "TrueshotLodge", [0] = 739},
    [793] = { mapFile = "ZulGurub", [0] = 337},
    [461] = { mapFile = "ArathiBasin", [0] = 93},
    [1075] = { mapFile = "AbyssalMawShamanAcquisition", [1] = 742, [2] = 743},
    [922] = { mapFile = "DeeprunTram", [1] = 499, [2] = 500},
    [1076] = { mapFile = "UlduarMagni", [1] = 744, [2] = 745, [3] = 746},
    [795] = { mapFile = "MoltenFront", [0] = 338},
    [462] = { mapFile = "EversongWoods", [0] = 94},
    [34] = { mapFile = "Duskwood", [0] = 47},
    [42] = { mapFile = "Darkshore", [0] = 62},
    [796] = { mapFile = "BlackTemple", [1] = 340, [2] = 341, [3] = 342, [4] = 343, [5] = 344, [6] = 345, [7] = 346, [0] = 339},
    [924] = { mapFile = "DalaranCity", [1] = 501, [2] = 502},
    [541] = { mapFile = "HrothgarsLanding", [0] = 170},
    [797] = { mapFile = "HellfireRamparts", [1] = 347},
    [925] = { mapFile = "BrawlgarArena", [1] = 503},
    [542] = { mapFile = "TheArgentColiseum", [1] = 171},
    [798] = { mapFile = "MagistersTerrace", [1] = 348, [2] = 349},
    [543] = { mapFile = "TheArgentColiseum", [1] = 172, [2] = 173},
    [799] = { mapFile = "Karazhan", [1] = 350, [2] = 351, [3] = 352, [4] = 353, [5] = 354, [6] = 355, [7] = 356, [8] = 357, [9] = 358, [10] = 359, [11] = 360, [12] = 361, [13] = 362, [14] = 363, [15] = 364, [16] = 365, [17] = 366},
    [464] = { mapFile = "AzuremystIsle", [0] = 97, [2] = 98, [3] = 99},
    [544] = { mapFile = "TheLostIsles", [1] = 175, [2] = 176, [3] = 177, [4] = 178, [0] = 174},
    [800] = { mapFile = "Firelands", [1] = 368, [2] = 369, [0] = 367},
    [928] = { mapFile = "IsleoftheThunderKing", [1] = 505, [2] = 506, [0] = 504},
    [545] = { mapFile = "Gilneas", [1] = 180, [2] = 181, [3] = 182, [0] = 179},
    [673] = { mapFile = "TheCapeOfStranglethorn", [0] = 210},
    [401] = { mapFile = "AlteracValley", [0] = 91},
    [929] = { mapFile = "IsleOfGiants", [0] = 507},
    [1090] = { mapFile = "TolBaradWarlockScenario", [1] = 774, [0] = 773},
    [201] = { mapFile = "UngoroCrater", [0] = 78, [14] = 79},
    [930] = { mapFile = "ThunderKingRaid", [1] = 508, [2] = 509, [3] = 510, [4] = 511, [5] = 512, [6] = 513, [7] = 514, [8] = 515},
    [1092] = { mapFile = "AzuremystIsleScenario", [0] = 776},
    [803] = { mapFile = "TheNexusLegendary", [1] = 370},
    [466] = { mapFile = "Expansion01", [0] = 101},
    [1094] = { mapFile = "NightmareRaid", [1] = 777, [2] = 778, [3] = 779, [4] = 780, [5] = 781, [6] = 782, [7] = 783, [8] = 784, [9] = 785, [10] = 786, [11] = 787, [12] = 788, [13] = 789},
    [1096] = { mapFile = "AszunaDungeonExterior", [0] = 790},
    [101] = { mapFile = "Desolace", [0] = 66, [22] = 68, [21] = 67},
    [933] = { mapFile = "IsleoftheThunderKingScenario", [1] = 517, [0] = 516},
    [806] = { mapFile = "TheJadeForest", [6] = 372, [7] = 373, [15] = 374, [16] = 375, [0] = 371},
    [934] = { mapFile = "ThunderKingLootRoom", [1] = 518},
    [1100] = { mapFile = "KarazhanScenario", [1] = 794, [2] = 795, [3] = 796, [4] = 797},
    [807] = { mapFile = "ValleyoftheFourWinds", [0] = 376, [14] = 377},
    [935] = { mapFile = "GoldRush", [0] = 519},
    [1102] = { mapFile = "ArcwayScenario", [1] = 798},
    [680] = { mapFile = "Ragefire", [1] = 213},
    [808] = { mapFile = "TheWanderingIsle", [0] = 378},
    [1104] = { mapFile = "MageCampaignTheOculus", [1] = 800, [2] = 801, [3] = 802, [4] = 803, [0] = 799},
    [341] = { mapFile = "Ironforge", [0] = 87},
    [809] = { mapFile = "KunLaiSummit", [0] = 379, [8] = 380, [9] = 381, [10] = 382, [20] = 386, [11] = 383, [21] = 387, [12] = 384, [17] = 385},
    [937] = { mapFile = "ValeOfEternalBlossomsScenario", [1] = 521, [0] = 520},
    [810] = { mapFile = "TownlongWastes", [0] = 388, [13] = 389},
    [938] = { mapFile = "EmberdeepScenario", [1] = 522},
    [811] = { mapFile = "ValeofEternalBlossoms", [1] = 391, [2] = 392, [3] = 393, [4] = 394, [0] = 390, [19] = 396, [18] = 395},
    [939] = { mapFile = "DunMoroghScenario", [0] = 523},
    [35] = { mapFile = "LochModan", [0] = 48},
    [43] = { mapFile = "Ashenvale", [0] = 63},
    [940] = { mapFile = "tempKrasarangHordeBase", [0] = 524},
    [685] = { mapFile = "RuinsofGilneasCity", [0] = 218},
    [813] = { mapFile = "NetherstormArena", [0] = 397},
    [471] = { mapFile = "TheExodar", [0] = 103},
    [1114] = { mapFile = "HelheimRaid", [1] = 807, [2] = 808, [0] = 806},
    [686] = { mapFile = "ZulFarrak", [0] = 219},
    [1115] = { mapFile = "LegionKarazhanDungeon", [1] = 809, [2] = 810, [3] = 811, [4] = 812, [5] = 813, [6] = 814, [7] = 815, [8] = 816, [9] = 817, [10] = 818, [11] = 819, [12] = 820, [13] = 821, [14] = 822},
    [1116] = { mapFile = "PitofSaronDK", [0] = 823},
    [687] = { mapFile = "TheTempleOfAtalHakkar", [1] = 220},
    [688] = { mapFile = "BlackfathomDeeps", [1] = 221, [2] = 222, [3] = 223},
    [816] = { mapFile = "WellofEternity", [0] = 398},
    [281] = { mapFile = "Winterspring", [0] = 83},
    [689] = { mapFile = "StranglethornVale", [0] = 224},
    [473] = { mapFile = "ShadowmoonValley", [0] = 104},
    [141] = { mapFile = "Dustwallow", [0] = 70},
    [690] = { mapFile = "TheStockade", [1] = 225},
    [946] = { mapFile = "Talador", [0] = 535, [13] = 536, [14] = 537, [30] = 538},
    [691] = { mapFile = "Gnomeregan", [1] = 226, [2] = 227, [3] = 228, [4] = 229},
    [819] = { mapFile = "HourofTwilight", [1] = 400, [0] = 399},
    [947] = { mapFile = "ShadowmoonValleyDR", [0] = 539, [22] = 541, [15] = 540},
    [1126] = {[0] = 824},
    [692] = { mapFile = "Uldaman", [1] = 230, [2] = 231},
    [820] = { mapFile = "EndTime", [1] = 402, [2] = 403, [3] = 404, [4] = 405, [5] = 406, [0] = 401},
    [948] = { mapFile = "SpiresOfArak", [0] = 542},
    [181] = { mapFile = "Aszhara", [0] = 76},
    [1220] = {[0] = 981},
    [1129] = { mapFile = "CaveoftheBloodtotemScenario", [1] = 826},
    [949] = { mapFile = "Gorgrond", [0] = 543, [17] = 545, [21] = 549, [20] = 548, [19] = 547, [16] = 544, [18] = 546},
    [1130] = { mapFile = "StratholmePaladinClassMount", [1] = 827},
    [1219] = {[1] = 975, [2] = 976, [3] = 977, [4] = 978, [5] = 979, [6] = 980, [0] = 974},
    [1131] = { mapFile = "TheEyeofEternityMageClassMount", [1] = 828},
    [950] = { mapFile = "NagrandDraenor", [11] = 552, [12] = 553, [0] = 550, [10] = 551},
    [1132] = { mapFile = "HallsOfValorWarriorClassMount", [1] = 829},
    [1050] = { mapFile = "WarlockClassShrine", [0] = 717},
    [823] = { mapFile = "DarkmoonFaireIsland", [1] = 408, [0] = 407},
    [476] = { mapFile = "BloodmystIsle", [0] = 106},
    [1216] = { mapFile = "VoidElfScenario", [0] = 972},
    [696] = { mapFile = "MoltenCore", [1] = 232},
    [824] = { mapFile = "DragonSoul", [1] = 410, [2] = 411, [3] = 412, [4] = 413, [5] = 414, [6] = 415, [0] = 409},
    [1215] = { mapFile = "VoidElfHub", [0] = 971},
    [1136] = { mapFile = "ColdridgeValleyScenario", [0] = 834},
    [697] = { mapFile = "ZulGurub", [0] = 233},
    [1137] = { mapFile = "TheDeadminesPetBattle", [1] = 835, [2] = 836},
    [477] = { mapFile = "Nagrand", [0] = 107},
    [1052] = { mapFile = "DemonHunterOrderHallTerrain", [1] = 720, [2] = 721, [0] = 719},
    [1054] = { mapFile = "TheVioletHoldAcquisition", [1] = 723},
    [1139] = { mapFile = "ArathiBasinWinter", [0] = 837},
    [1212] = { mapFile = "LightforgedVindicaar", [1] = 940, [2] = 941},
    [1140] = { mapFile = "BattleforBlackrockMountain", [0] = 838},
    [699] = { mapFile = "DireMaul", [1] = 235, [2] = 236, [3] = 237, [4] = 238, [5] = 239, [6] = 240, [0] = 234},
    [1211] = {[0] = 939},
    [478] = { mapFile = "TerokkarForest", [0] = 108},
    [36] = { mapFile = "Redridge", [0] = 49},
    [700] = { mapFile = "TwilightHighlands", [0] = 241},
    [1143] = { mapFile = "GnomereganPetBattle", [1] = 840, [2] = 841, [3] = 842},
    [1210] = {[0] = 938},
    [1144] = { mapFile = "SmallBattlegroundC", [0] = 843},
    [1066] = { mapFile = "LegionVioletHoldDungeon", [1] = 732},
    [1145] = {[0] = 844},
    [479] = { mapFile = "Netherstorm", [0] = 109},
    [1146] = { mapFile = "TombofSargerasDungeon", [1] = 845, [2] = 846, [3] = 847, [4] = 848, [5] = 849},
    [1204] = {[1] = 934, [2] = 935},
    [1147] = { mapFile = "TombRaid", [1] = 850, [2] = 851, [3] = 852, [4] = 853, [5] = 854, [6] = 855, [7] = 856},
    [1202] = { mapFile = "LightforgedDraeneiSwamp", [0] = 933},
    [1148] = { mapFile = "ThroneoftheFourWinds", [1] = 857},
    [1201] = { mapFile = "InvasionPointVal", [0] = 932},
    [1149] = { mapFile = "AssaultonBrokenShoreScenario", [0] = 858},
    [480] = { mapFile = "SilvermoonCity", [0] = 110},
    [1150] = {[0] = 859},
    [704] = { mapFile = "BlackrockDepths", [1] = 242, [2] = 243},
    [1151] = { mapFile = "TheRubySanctumDKMountScenario", [0] = 860},
    [1200] = { mapFile = "InvasionPointSangua", [0] = 931},
    [1152] = { mapFile = "FelwingLedgeMardumArea", [0] = 861},
    [1199] = { mapFile = "InvasionPointNaigtal", [0] = 930},
    [1153] = {[0] = 862},
    [481] = { mapFile = "ShattrathCity", [0] = 111},
    [1154] = {[0] = 863},
    [1068] = { mapFile = "MageClassShrine", [1] = 734, [2] = 735},
    [1155] = {[0] = 864},
    [241] = { mapFile = "Moonglade", [0] = 80},
    [1156] = { mapFile = "StormheimInvasionScenario", [1] = 865, [2] = 866},
    [1070] = { mapFile = "TheVortexPinnacle", [1] = 737},
    [1157] = { mapFile = "AzsunaInvasionScenario", [1] = 867},
    [482] = { mapFile = "NetherstormArena", [0] = 112},
    [1158] = { mapFile = "ValsharahInvasionScenario", [1] = 868},
    [708] = { mapFile = "TolBarad", [0] = 244},
    [1159] = { mapFile = "HighmountainInvasionScenario", [1] = 869, [2] = 870},
    [964] = { mapFile = "OgreMines", [1] = 573},
    [1160] = { mapFile = "LostGlacierDKMountScenario", [0] = 871},
    [709] = { mapFile = "TolBaradDailyArea", [0] = 245},
    [1161] = { mapFile = "StormstoutBreweryScenario", [1] = 873, [2] = 874, [0] = 872},
    [121] = { mapFile = "Feralas", [0] = 69},
    [1162] = {[0] = 875},
    [710] = { mapFile = "TheShatteredHalls", [1] = 246},
    [1163] = {[0] = 876},
    [1073] = { mapFile = "ArtifactSubtletyRogueAcquisition", [1] = 740, [2] = 741},
    [1164] = { mapFile = "HallsofValor", [0] = 877},
    [1078] = { mapFile = "Niskara", [0] = 748},
    [1165] = { mapFile = "DemonHunterOrderHallTerrain", [1] = 879, [2] = 880, [0] = 878},
    [1079] = { mapFile = "SuamarCatacombsDungeon", [1] = 749},
    [1166] = { mapFile = "TheEyeofEternityMageClassMount", [1] = 881},
    [1080] = { mapFile = "ThunderTotem", [0] = 750},
    [1081] = { mapFile = "BlackRookHoldDungeon", [1] = 751, [2] = 752, [3] = 753, [4] = 754, [5] = 755, [6] = 756},
    [1082] = { mapFile = "UrsocsLairScenario", [0] = 757},
    [1084] = { mapFile = "GloamingReef", [0] = 758},
    [1085] = { mapFile = "70BlackTempleLegion", [1] = 759},
    [1086] = { mapFile = "MalornesNightmare", [0] = 760},
    [485] = { mapFile = "Northrend", [0] = 113},
    [1170] = { mapFile = "ArgusMacAree", [0] = 882, [3] = 883, [4] = 884},
    [1087] = { mapFile = "SuramarNoblesDistrict", [1] = 762, [2] = 763, [0] = 761},
    [1171] = { mapFile = "ArgusCore", [0] = 885, [6] = 887, [5] = 886},
    [970] = { mapFile = "TanaanJungleIntro", [1] = 578, [0] = 577},
    [1172] = { mapFile = "HallOfCommunion", [1] = 888},
    [1091] = { mapFile = "TheExodar", [0] = 775},
    [1173] = { mapFile = "TKArcatrazScenario", [1] = 889, [2] = 890},
    [486] = { mapFile = "BoreanTundra", [0] = 114},
    [37] = { mapFile = "StranglethornJungle", [0] = 50},
    [1097] = { mapFile = "ArtifactBrewmasterScenario", [1] = 791, [2] = 792},
    [1175] = {[0] = 895},
    [61] = { mapFile = "ThousandNeedles", [0] = 64},
    [1176] = {[0] = 896},
    [717] = { mapFile = "RuinsofAhnQiraj", [0] = 247},
    [1177] = { mapFile = "DragonblightChromieScenario", [1] = 898, [2] = 899, [3] = 900, [4] = 901, [5] = 902, [0] = 897},
    [973] = { mapFile = "garrisonsmvalliance_tier1", [0] = 582},
    [1178] = { mapFile = "ArgusDungeon", [0] = 903},
    [718] = { mapFile = "OnyxiasLair", [1] = 248},
    [1099] = { mapFile = "BlackRookHoldScenario", [0] = 793},
    [1174] = { mapFile = "AzuremystScenario", [1] = 892, [2] = 893, [3] = 894, [0] = 891},
    [1142] = { mapFile = "PriestClassMountScenario", [1] = 839},
    [1135] = { mapFile = "ArgusSurface", [1] = 831, [2] = 832, [0] = 830, [7] = 833},
    [1127] = { mapFile = "WailingCavernsPetBattle", [1] = 825},
    [488] = { mapFile = "Dragonblight", [0] = 115},
    [1105] = { mapFile = "ScarletMonestaryDK", [1] = 804, [2] = 805},
    [720] = { mapFile = "Uldum", [0] = 249},
    [1183] = { mapFile = "SilithusBrawl", [0] = 904},
    [976] = { mapFile = "garrisonffhorde", [27] = 586, [28] = 587, [26] = 585},
    [1184] = { mapFile = "Argus", [0] = 994},
    [721] = { mapFile = "BlackrockSpire", [1] = 250, [2] = 251, [3] = 252, [4] = 253, [5] = 254, [6] = 255},
    [1185] = {[0] = 906},
    [1088] = { mapFile = "SuramarRaid", [1] = 764, [2] = 765, [3] = 766, [4] = 767, [5] = 768, [6] = 769, [7] = 770, [8] = 771, [9] = 772},
    [1186] = { mapFile = "AzeriteBG", [0] = 907},
    [722] = { mapFile = "AuchenaiCrypts", [1] = 256, [2] = 257},
    [1187] = {[0] = 908},
    [978] = { mapFile = "Ashran", [0] = 588, [29] = 589},
    [1188] = { mapFile = "ArgusRaid", [1] = 910, [2] = 911, [3] = 912, [4] = 913, [5] = 914, [6] = 915, [7] = 916, [8] = 917, [9] = 918, [10] = 919, [11] = 920, [0] = 909},
    [723] = { mapFile = "SethekkHalls", [1] = 258, [2] = 259},
    [851] = { mapFile = "DustwallowMarshScenario", [0] = 416},
    [490] = { mapFile = "GrizzlyHills", [0] = 116},
    [1190] = { mapFile = "InvasionPointAurinor", [0] = 921},
    [724] = { mapFile = "ShadowLabyrinth", [1] = 260},
    [1191] = { mapFile = "InvasionPointBonich", [0] = 922},
    [980] = { mapFile = "garrisonffhorde_tier1", [0] = 590},
    [1192] = { mapFile = "InvasionPointCengar", [0] = 923},
    [725] = { mapFile = "TheBloodFurnace", [1] = 261},
    [1193] = { mapFile = "InvasionPointNaigtal", [0] = 924},
    [491] = { mapFile = "HowlingFjord", [0] = 117},
    [1194] = { mapFile = "InvasionPointSangua", [0] = 925},
    [726] = { mapFile = "TheUnderbog", [1] = 262},
    [1195] = { mapFile = "InvasionPointVal", [0] = 926},
    [1077] = { mapFile = "TheDreamgrove", [0] = 747},
    [1196] = { mapFile = "InvasionPointAurinor", [0] = 927},
    [727] = { mapFile = "TheSteamvault", [1] = 263, [2] = 264},
    [1197] = { mapFile = "InvasionPointBonich", [0] = 928},
    [492] = { mapFile = "IcecrownGlacier", [0] = 118},
    [1198] = { mapFile = "InvasionPointCengar", [0] = 929},
    [728] = { mapFile = "TheSlavePens", [1] = 265},
    [856] = { mapFile = "TempleofKotmogu", [0] = 417},
    [984] = { mapFile = "DraenorAuchindoun", [1] = 593},
    [601] = { mapFile = "TheForgeofSouls", [1] = 183},
    [729] = { mapFile = "TheBotanica", [1] = 266},
    [857] = { mapFile = "Krasarang", [1] = 419, [2] = 420, [3] = 421, [0] = 418},
    [493] = { mapFile = "SholazarBasin", [0] = 119},
    [602] = { mapFile = "PitofSaron", [0] = 184},
    [730] = { mapFile = "TheMechanar", [1] = 267, [2] = 268},
    [858] = { mapFile = "DreadWastes", [0] = 422},
    [986] = { mapFile = "TaladorScenario", [0] = 594},
    [603] = { mapFile = "HallsofReflection", [1] = 185},
    [731] = { mapFile = "TheArcatraz", [1] = 269, [2] = 270, [3] = 271},
    [1205] = {[0] = 936},
    [987] = { mapFile = "IronDocks", [1] = 595},
    [38] = { mapFile = "SwampOfSorrows", [0] = 51},
    [732] = { mapFile = "ManaTombs", [1] = 272},
    [860] = { mapFile = "STVDiamondMineBG", [1] = 423},
    [988] = { mapFile = "FoundryRaid", [1] = 596, [2] = 597, [3] = 598, [4] = 599, [5] = 600},
    [605] = { mapFile = "Kezan", [6] = 196, [7] = 197, [5] = 195, [0] = 194},
    [733] = { mapFile = "CoTTheBlackMorass", [0] = 273},
    [1065] = { mapFile = "NeltharionsLair", [0] = 731},
    [495] = { mapFile = "TheStormPeaks", [0] = 120},
    [606] = { mapFile = "Hyjal", [0] = 198},
    [734] = { mapFile = "CoTHillsbradFoothills", [0] = 274},
    [862] = { mapFile = "Pandaria", [0] = 424},
    [1060] = { mapFile = "DeepholmShamanAcquisition", [1] = 729},
    [607] = { mapFile = "SouthernBarrens", [0] = 199},
    [1056] = { mapFile = "MaelstromShamanHubIntro", [0] = 725},
    [1213] = {[0] = 942},
    [496] = { mapFile = "ZulDrak", [0] = 121},
    [1214] = {[0] = 943},
    [736] = { mapFile = "GilneasBattleground2", [0] = 275},
    [864] = { mapFile = "Northshire", [0] = 425, [3] = 426},
    [1051] = { mapFile = "DreadscarRift", [0] = 718},
    [609] = { mapFile = "TheRubySanctum", [0] = 200},
    [737] = { mapFile = "TheMaelstrom", [0] = 276},
    [1217] = { mapFile = "TheSunwellUnlockScenario", [1] = 973},
    [993] = { mapFile = "BlackrockTrainDepotDungeon", [1] = 606, [2] = 607, [3] = 608, [4] = 609},
    [610] = { mapFile = "VashjirKelpForest", [0] = 201},
    [1049] = { mapFile = "ArtifactSkywall", [1] = 716},
    [866] = { mapFile = "ColdridgeValley", [0] = 427, [9] = 428},
    [994] = { mapFile = "HighmaulRaid", [1] = 611, [2] = 612, [3] = 613, [4] = 614, [5] = 615, [0] = 610},
    [611] = { mapFile = "GilneasCity", [0] = 202},
    [1048] = { mapFile = "EmeraldDreamway", [0] = 715},
    [867] = { mapFile = "EastTemple", [1] = 429, [2] = 430},
    [995] = { mapFile = "UpperBlackrockSpire", [1] = 616, [2] = 617, [3] = 618},
    [1047] = { mapFile = "Niskara", [0] = 714},
    [1046] = { mapFile = "AszunaDungeon", [0] = 713},
    [1045] = { mapFile = "VaultOfTheWardens", [1] = 710, [2] = 711, [3] = 712},
    [1044] = { mapFile = "MonkOrderHallTheWanderingIsle", [0] = 709},
    [613] = { mapFile = "Vashjir", [0] = 203},
    [1042] = { mapFile = "HelheimDungeonDock", [1] = 707, [2] = 708, [0] = 706},
    [1040] = { mapFile = "NetherlightTemple", [1] = 702},
    [499] = { mapFile = "Sunwell", [0] = 122},
    [614] = { mapFile = "VashjirDepths", [0] = 204},
    [1039] = { mapFile = "IcecrownCitadelDeathKnight", [1] = 698, [2] = 699, [3] = 700, [4] = 701},
    [1038] = { mapFile = "HulnFlashback", [0] = 697},
    [1037] = { mapFile = "StormheimArtifactProtWarrior", [0] = 696},
    [615] = { mapFile = "VashjirRuins", [0] = 205},
    [1033] = { mapFile = "Suramar", [24] = 683, [33] = 685, [35] = 687, [39] = 691, [41] = 692, [42] = 693, [32] = 684, [34] = 686, [36] = 688, [38] = 690, [37] = 689, [22] = 681, [23] = 682, [0] = 680},
    [871] = { mapFile = "ScarletHalls", [1] = 431, [2] = 432},
    [1031] = { mapFile = "BrokenShorePaladin", [0] = 676},
    [301] = { mapFile = "StormwindCity", [0] = 84},
    [475] = { mapFile = "BladesEdgeMountains", [0] = 105},
    [382] = { mapFile = "Undercity", [0] = 998},
    [953] = { mapFile = "OrgrimmarRaid", [1] = 557, [2] = 558, [3] = 559, [4] = 560, [5] = 561, [6] = 562, [7] = 563, [8] = 564, [9] = 565, [10] = 566, [11] = 567, [12] = 568, [13] = 569, [14] = 570, [0] = 556},
    [1007] = { mapFile = "BrokenIsles", [0] = 619},
    [989] = { mapFile = "SpiresofArakDungeon", [1] = 601, [2] = 602},
    [873] = { mapFile = "TheHiddenPass", [0] = 433, [5] = 434},
    [501] = { mapFile = "LakeWintergrasp", [0] = 123},
    [983] = { mapFile = "DefenseofKarabor", [0] = 592},
    [971] = { mapFile = "garrisonsmvalliance", [24] = 580, [25] = 581, [23] = 579},
    [874] = { mapFile = "ScarletCathedral", [1] = 435, [2] = 436},
    [969] = { mapFile = "ShadowmoonDungeon", [1] = 574, [2] = 575, [3] = 576},
    [261] = { mapFile = "Silithus", [0] = 81, [13] = 82},
    [747] = { mapFile = "LostCityofTolvir", [0] = 277},
    [875] = { mapFile = "TheGreatWall", [1] = 437, [2] = 438},
    [502] = { mapFile = "ScarletEnclave", [0] = 124},
    [39] = { mapFile = "Westfall", [0] = 52, [17] = 55, [4] = 53, [5] = 54},
    [962] = { mapFile = "Draenor", [0] = 572},
    [876] = { mapFile = "StormstoutBrewery", [1] = 439, [2] = 440, [3] = 441, [4] = 442},
    [955] = { mapFile = "CelestialChallenge", [0] = 571},
    [951] = { mapFile = "TimelessIsle", [0] = 554, [22] = 555},
    [749] = { mapFile = "WailingCaverns", [1] = 279},
    [877] = { mapFile = "ShadowpanHideout", [1] = 444, [2] = 445, [3] = 446, [0] = 443},
    [945] = { mapFile = "TanaanJungle", [0] = 534},
    [941] = { mapFile = "FrostfireRidge", [1] = 526, [2] = 527, [3] = 528, [4] = 529, [6] = 530, [7] = 531, [8] = 532, [0] = 525, [9] = 533},
    [750] = { mapFile = "Maraudon", [1] = 280, [2] = 281},
    [878] = { mapFile = "BrewmasterScenario01", [0] = 447},
    [684] = { mapFile = "RuinsofGilneas", [0] = 217},
    [362] = { mapFile = "ThunderBluff", [0] = 88},
    [751] = { mapFile = "TheMaelstromContinent", [0] = 948},
    [182] = { mapFile = "Felwood", [0] = 77},
    [504] = { mapFile = "Dalaran", [1] = 125, [2] = 126},
    [465] = { mapFile = "Hellfire", [0] = 100},
    [752] = { mapFile = "BaradinHold", [1] = 282},
    [880] = { mapFile = "TheJadeForestScenario", [0] = 448},
    [1008] = { mapFile = "OvergrownOutpost", [1] = 621, [0] = 620},
    [443] = { mapFile = "WarsongGulch", [0] = 92},
    [753] = { mapFile = "BlackrockCaverns", [1] = 283, [2] = 284},
    [881] = { mapFile = "ValleyOfPowerScenario", [0] = 449},
    [1009] = { mapFile = "AshranAllianceFactionHub", [0] = 622},
    [626] = { mapFile = "TwinPeaks", [0] = 206},
    [754] = { mapFile = "BlackwingDescent", [1] = 285, [2] = 286},
    [882] = { mapFile = "BrewmasterScenario03", [0] = 450},
    [1010] = { mapFile = "HillsbradFoothillsBG", [0] = 623},
    [463] = { mapFile = "Ghostlands", [1] = 96, [0] = 95},
    [755] = { mapFile = "BlackwingLair", [1] = 287, [2] = 288, [3] = 289, [4] = 290},
    [883] = { mapFile = "Tyrivess", [0] = 451},
    [1011] = { mapFile = "AshranHordeFactionHub", [0] = 624},
    [381] = { mapFile = "Darnassus", [0] = 89},
    [756] = { mapFile = "TheDeadmines", [1] = 291, [2] = 292},
    [884] = { mapFile = "KunLaiPassScenario", [0] = 452},
    [540] = { mapFile = "IsleofConquest", [0] = 169},
    [604] = { mapFile = "IcecrownCitadel", [1] = 186, [2] = 187, [3] = 188, [4] = 189, [5] = 190, [6] = 191, [7] = 192, [8] = 193},
    [757] = { mapFile = "GrimBatol", [1] = 293},
    [885] = { mapFile = "MogushanPalace", [1] = 453, [2] = 454, [3] = 455},
    [467] = { mapFile = "Zangarmarsh", [0] = 102},
}
function SetupMigrationData()
    mapFileToIdMap = {}
    for id, t in pairs(MapMigrationData) do
        if t.mapFile then
            mapFileToIdMap[t.mapFile] = id
        end
    end

    uiMapIdToIdMap = {}
    for id, t in pairs(MapMigrationData) do
        for floor, uiMapId in pairs(t) do
            if floor ~= "mapFile" and floor ~= "defaultFloor" then
                uiMapIdToIdMap[uiMapId] = id * 10000 + floor
            end
        end
    end
end
-------------------------------------------------------------------------------
-- EOF
