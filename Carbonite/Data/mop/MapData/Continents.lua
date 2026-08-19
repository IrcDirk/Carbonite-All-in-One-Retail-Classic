---------------------------------------------------------------------------------------
-- Carbonite - mop continent definitions and zone membership
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

Map.ContCnt = 6

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
    },
    {
        1,1,1,0,
        1,1,1,0,
        1,1,1,0
    },
    {
        1,1,1,1,
        1,1,1,1,
        1,1,1,1
    }
}


Map.MapZones = {
    [0] = {12,13,1467,113,948,424,0,-1},
    [1] = {1,7,10,57,62,63,64,65,66,69,70,71,76,77,78,80,81,83,85,86,88,89,97,103,106,198,199,249,327,338,460,461,462,463,468},
    [2] = {14,15,17,18,21,22,23,25,26,27,32,36,37,42,47,48,49,50,51,52,56,84,87,90,94,95,110,122,124,179,201,202,204,205,203,210,217,218,224,241,244,245,425,427,465,467,469},
    [3] = {100,102,104,105,107,108,109,111},
    [4] = {114,115,116,117,118,119,120,121,123,125,127,170},
    [5] = {174,194,207,276,407},
    [6] = {371,376,378,379,388,390,418,422,433,504,507,554},
    [90] = {91,92,93,112,128,169,206,275,397,417,423,519,623,2104},
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
        X = -3500,
        Y = 200,
    },
    [2] = {
        Name = L["Eastern Kingdoms"],
        FileName = "Azeroth",
        X = 3500,
        Y = -200,
    },
    [3] = {
        Name = L["Outland"],
        FileName = "Expansion01",
        X = 5500,
        Y = -3700,
    },
    [4] = {
        Name = L["Northrend"],
        FileName = "Northrend",
        X = 300,
        Y = -2800,
    },
    [5] = {
        Name = L["The Maelstrom"],
        FileName = "TheMaelstromContinent",
        X = -400,
        Y = -500,
    },
    [6] = {
        Name = L["Pandaria"],
        FileName = "Pandaria",
        X = 600,
        Y = 4400,
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
