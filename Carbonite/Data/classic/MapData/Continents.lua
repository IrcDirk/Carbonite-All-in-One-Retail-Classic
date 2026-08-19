---------------------------------------------------------------------------------------
-- Carbonite - classic continent definitions and zone membership
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

Map.ContCnt = 2

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
        1,1,1,1,
        1,1,1,1,
        1,1,1,1
    }
}


Map.MapZones = {
    [0] = {12,13,1945,113,0,-1},
    [1] = {1411,1412,1413,1438,1439,1440,1441,1442,1443,1444,1445,1446,1447,1448,1449,1450,1451,1452,1454,1456,1457},
    [2] = {1416,1417,1418,1419,1420,1421,1422,1423,1424,1425,1426,1427,1428,1429,1430,1431,1432,1433,1434,1435,1436,1437,1453,1455,1458},

    [90] = {91,92,93,112,128,169,206,275,397,417,423,519,623},
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
        FileName = "Kalimdor",
        X = -2500,
        Y = 200,
    },
    [2] = {
        Name = L["Eastern Kingdoms"],
        FileName = "Azeroth",
        X = 2000,
        Y = -200,
    },
    [90] = {
        Name = "BG",
        X = 2000,
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
