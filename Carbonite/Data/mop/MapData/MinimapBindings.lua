---------------------------------------------------------------------------------------
-- Carbonite - mop minimap tileset bindings and coordinate anchors
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
        Map.MapWorldInfo[1467].X + Map.MapInfo[3].X + 465.4, Map.MapWorldInfo[1467].Y + Map.MapInfo[3].Y + -9.7,
        "World\\Minimaps\\Expansion01"
    },
    [4] = {
        Map.NRMapBlks,
        1109,
        11, 09,
        Map.MapWorldInfo[113].X + Map.MapInfo[4].X + -397.1, Map.MapWorldInfo[113].Y + Map.MapInfo[4].Y + -334.1,
        "World\\Minimaps\\Northrend"
    },
    [5] = {
        Map.LIMapBlks,
        2324,
        23, 24,
        Map.MapWorldInfo[948].X + Map.MapInfo[5].X + -178.84, Map.MapWorldInfo[948].Y + Map.MapInfo[5].Y + 401.76665039063,
        "World\\Minimaps\\LostIsles"
    },
    [6] = {
        Map.PandariaMapBlks,
        1816,
        18, 16,
        Map.MapWorldInfo[424].X + Map.MapInfo[6].X + 256.3, Map.MapWorldInfo[424].Y + Map.MapInfo[6].Y + -371.0,
        "World\\Minimaps\\HawaiiMainLand"
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
    [244] = {
        Map.TolBaradMapBlks,
        2731,
        27, 31,
        Map.MapWorldInfo[14].X + Map.MapInfo[2].X + 2500.940740625, Map.MapWorldInfo[14].Y + Map.MapInfo[2].Y + 2448.61535,
        "World\\Minimaps\\TolBarad"
    },
    [194] = {
        Map.KezanMapBlks,
        2324,
        23, 24,
        Map.MapWorldInfo[948].X + Map.MapInfo[5].X + 297.05, Map.MapWorldInfo[948].Y + Map.MapInfo[5].Y + -1411.53334960937,
        "World\\Minimaps\\LostIsles"
    },
    [207] = {        -- 2625 to 3534
        Map.DeepholmMapBlks,
        2625,
        26, 25,
        Map.MapWorldInfo[948].X + Map.MapInfo[5].X + 1251.16, Map.MapWorldInfo[948].Y + Map.MapInfo[5].Y + 228.97665039063,
        "World\\Minimaps\\Deephome"
    },
    [338] = {
        Map.MoltenFrontMapBlks,
        2725,        -- 2725 to 3531
        27, 25,
        Map.MapWorldInfo[338].X + Map.MapInfo[1].X + 2452.92, Map.MapWorldInfo[338].Y + Map.MapInfo[1].Y + -1105.97,
        "World\\Minimaps\\FirelandsDailies"
    },
    [407] = {
        Map.DarkMoonFaireBlks,
        1636,
        16, 36,
        Map.MapWorldInfo[407].X + Map.MapInfo[5].X + -253,Map.MapWorldInfo[407].Y + Map.MapInfo[5].Y + -238,
        "World\\Minimaps\\DarkmoonFaire"
    },
    -- SubZones overlaid over original minimap texture blocks
    [10000] = {
        Map.ValeOfEternalBlossomsPhase0Blks,
        "World\\Minimaps\\2862"
    },
    [10001] = {
        Map.AllianceBeachDailyAreaBlks,
        "World\\Minimaps\\AllianceBeachDailyArea"
    },
    [10002] = {
        Map.HordeBeachDailyAreaBlks,
        "World\\Minimaps\\HordeBeachDailyArea"
    },
    [10003] = {
        Map.MoguIslandDailyAreaBlks,
        "World\\Minimaps\\MoguIslandDailyArea"
    },
}

--------
