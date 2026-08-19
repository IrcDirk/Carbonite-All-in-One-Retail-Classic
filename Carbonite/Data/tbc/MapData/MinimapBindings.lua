---------------------------------------------------------------------------------------
-- Carbonite - tbc minimap tileset bindings and coordinate anchors
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map

Map.MiniMapBlks = {
    [1] = {
        Map.KalMapBlks,
        1908,
        19, 8,
         Map.MapWorldInfo[13].X + Map.MapInfo[1].X + 2025.753921875 + 222, Map.MapWorldInfo[13].Y + Map.MapInfo[1].Y + -0.476021875 - 324,
        "World\\Minimaps\\Kalimdor"
    },
    [2] = {
        Map.EkMapBlks,
        2420,
        24, 20,
        Map.MapWorldInfo[14].X + Map.MapInfo[2].X -1080, Map.MapWorldInfo[14].Y + Map.MapInfo[2].Y - 1308,
        "World\\Minimaps\\Azeroth"
    },
    [3] = {
        Map.OLMapBlks,
        1221,
        12, 21,
        Map.MapWorldInfo[1945].X + Map.MapInfo[3].X + 465.4, Map.MapWorldInfo[1945].Y + Map.MapInfo[3].Y + -9.7,
        "World\\Minimaps\\Expansion01"
    },
    [94] = {
        Map.BloodelfMapBlks,
        4111,
        41, 11,
        Map.MapWorldInfo[14].X + Map.MapInfo[2].X + 231.60, Map.MapWorldInfo[14].Y + Map.MapInfo[2].Y - 1751.40,
        "World\\Minimaps\\Expansion01"
    },
    [97] = {
        Map.DraeneiMapBlks,
        5033,
        50, 33,
        Map.MapWorldInfo[13].X + Map.MapInfo[1].X + 1833.076104875 + 221.20 , Map.MapWorldInfo[13].Y + Map.MapInfo[1].Y + 656.598490125 - 325.10,
        "World\\Minimaps\\Expansion01"
    },
}

--------
