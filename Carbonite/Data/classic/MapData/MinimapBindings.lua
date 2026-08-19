---------------------------------------------------------------------------------------
-- Carbonite - classic minimap tileset bindings and coordinate anchors
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map

Map.MiniMapBlks = {
    [1] = {
        Map.KalMapBlks,
        1908,
        19, 8,
        Map.MapWorldInfo[13].X + Map.MapInfo[1].X + 1600 + 212.52, Map.MapWorldInfo[13].Y + Map.MapInfo[1].Y + -800 + -266.42,
        "World\\Minimaps\\Kalimdor"
    },
    [2] = {
        Map.EkMapBlks,
        2420,
        24, 20,
        Map.MapWorldInfo[14].X + Map.MapInfo[2].X -1080, Map.MapWorldInfo[14].Y + Map.MapInfo[2].Y - 1308,
        "World\\Minimaps\\Azeroth"
    }
}

--------
