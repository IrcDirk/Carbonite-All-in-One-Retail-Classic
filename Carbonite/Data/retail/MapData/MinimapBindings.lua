---------------------------------------------------------------------------------------
-- Carbonite - retail minimap tileset bindings and coordinate anchors
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
        Map.MapWorldInfo[101].X + Map.MapInfo[3].X + 465.4, Map.MapWorldInfo[101].Y + Map.MapInfo[3].Y + -9.7,
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
    [7] = {
        Map.DraenorMapBlks,
        1220,
        12, 20,
        Map.MapWorldInfo[572].X + Map.MapInfo[7].X + 314.8, Map.MapWorldInfo[572].Y + Map.MapInfo[7].Y + 958.6,
        "World\\Minimaps\\Draenor"
    },
    [8] = {
        Map.BrokenIslesMapBlks,
        1117,
        11, 17,
        Map.MapWorldInfo[619].X + Map.MapInfo[8].X + 380, Map.MapWorldInfo[619].Y + Map.MapInfo[8].Y - 147.8,
        "World\\Minimaps\\Troll Raid"
    },
    [10] = {
        Map.ZandalarMapBlks,
        1616,
        16, 16,
        Map.MapWorldInfo[875].X + Map.MapInfo[10].X + 38.80, Map.MapWorldInfo[875].Y + Map.MapInfo[10].Y - 801.10,
        "World\\Minimaps\\zandalar"
    },
    [11] = {
        Map.KultirasMapBlks,
        1616,
        16, 16,
        Map.MapWorldInfo[876].X + Map.MapInfo[11].X + 38.80 - 257.30 + 16.51, Map.MapWorldInfo[876].Y + Map.MapInfo[11].Y - 801.10 + 150.95 + 39.22,
        "World\\Minimaps\\kultiras"
    },
    [12] = {
        Map.NazjatarBlks,
        2824,
        28, 24,
        Map.MapWorldInfo[1355].X + Map.MapInfo[12].X - 106.85, Map.MapWorldInfo[1355].Y + Map.MapInfo[12].Y - 295.44,
        "World\\Minimaps\\nazjatar"
    },
    [13] = {
        Map.ShadowlandsBlks,
        1416,
        14, 16,
        Map.MapWorldInfo[1550].X + Map.MapInfo[13].X + 594.95, Map.MapWorldInfo[1550].Y + Map.MapInfo[13].Y - 440,
        "World\\Minimaps\\2222"
    },
    [14] = {
        Map.DragonIslesBlks,
        0712,
        07, 12,
        Map.MapWorldInfo[1978].X + Map.MapInfo[14].X + 3, Map.MapWorldInfo[1978].Y + Map.MapInfo[14].Y - 444.5,
        "World\\Minimaps\\2444"
    },
    [15] = {
        Map.KhazAlgarBlks,
        1413,
        14, 13,
        Map.MapWorldInfo[2274].X + Map.MapInfo[15].X - 402, Map.MapWorldInfo[2274].Y + Map.MapInfo[15].Y - 215,
            "World\\Minimaps\\2601"
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
        Map.MapWorldInfo[338].X + Map.MapInfo[1].X + 3152.92266259766, Map.MapWorldInfo[338].Y + Map.MapInfo[1].Y + -2105.97034960937,
        "World\\Minimaps\\FirelandsDailies"
    },
    [378] = {
        Map.TheWanderingIsleMapBlks,
        2328,
        23,28,
        Map.MapWorldInfo[378].X + Map.MapWorldInfo[378].XOff + Map.MapInfo[6].X  + 35.7, Map.MapWorldInfo[378].Y + Map.MapWorldInfo[378].YOff + Map.MapInfo[6].Y-69.55,
        "World\\Minimaps\\NewRaceStartZone"
    },
    [407] = {
        Map.DarkMoonFaireBlks,
        1636,
        16, 36,
        Map.MapWorldInfo[407].X + Map.MapInfo[5].X + -253,Map.MapWorldInfo[407].Y + Map.MapInfo[5].Y + -238,
        "World\\Minimaps\\DarkmoonFaire"
    },
    [830] = {
        Map.Argus1MapBlks,
        2627,
        26, 27,
        Map.MapWorldInfo[830].X + Map.MapWorldInfo[830].XOff + Map.MapInfo[9].X + 114.1, Map.MapWorldInfo[830].Y + Map.MapWorldInfo[830].YOff + Map.MapInfo[9].Y + -2.6,
        "World\\Minimaps\\Argus 1"
    },
    [882] = {
        Map.Argus3MapBlks,
        1119,
        11, 19,
        Map.MapWorldInfo[882].X + Map.MapWorldInfo[882].XOff + Map.MapInfo[9].X + 69.1, Map.MapWorldInfo[882].Y + Map.MapWorldInfo[882].YOff + Map.MapInfo[9].Y + -62.6,
        "World\\Minimaps\\Argus 1"
    },
    [885] = {
        Map.Argus2MapBlks,
        1135,
        11, 35,
        Map.MapWorldInfo[885].X + Map.MapWorldInfo[885].XOff + Map.MapInfo[9].X + 15.7, Map.MapWorldInfo[885].Y + Map.MapWorldInfo[885].YOff + Map.MapInfo[9].Y + -37.6,
        "World\\Minimaps\\Argus 1"
    },
    [1409] = {
        Map.NPEBlks,
        2038,
        20, 38,
        Map.MapWorldInfo[1409].X - 1383.72, Map.MapWorldInfo[1409].Y + 927.67,
        "World\\Minimaps\\2175"
    },
    [1970] = {
        Map.ZerethMortisBlks,
        2936,
        29, 36,
        Map.MapWorldInfo[1970].X + Map.MapInfo[13].X + 169.5, Map.MapWorldInfo[1970].Y + Map.MapInfo[13].Y + 12,
        "World\\Minimaps\\2374"
    },
    [2133] = {
        Map.ZaralekCavernBlks,
        2226,
        22, 26,
        Map.MapWorldInfo[2133].X + Map.MapInfo[14].X + 147.5, Map.MapWorldInfo[2133].Y + Map.MapInfo[14].Y - 174,
        "World\\Minimaps\\2454"
    },
    [2200] = {
        Map.DreamTreeBlks,
        0523,
        05, 23,
        Map.MapWorldInfo[2200].X + Map.MapInfo[14].X - 688, Map.MapWorldInfo[2200].Y + Map.MapInfo[14].Y - 1014,
        "World\\Minimaps\\2549"
    },
    [2248] = {
        Map.IsleOfDornBlks,
        2820,
        28, 20,
        Map.MapWorldInfo[2248].X + Map.MapInfo[15].X - 94, Map.MapWorldInfo[2248].Y + Map.MapInfo[15].Y - 252,
        "World\\Minimaps\\2552"
    },
    [2346] = {
        Map.UndermineBlks,
        2929,
        29, 29,
        Map.MapWorldInfo[2346].X + Map.MapInfo[15].X - 36, Map.MapWorldInfo[2346].Y + Map.MapInfo[15].Y - 182,
        "World\\Minimaps\\2706"
    },
    [2371] = {
        Map.KareshBlks,
        2325,
        23, 25,
        Map.MapWorldInfo[2371].X + Map.MapInfo[15].X + 88, Map.MapWorldInfo[2371].Y + Map.MapInfo[15].Y - 102,
        "World\\Minimaps\\2738"
    },
    [2405] = {
        Map.VoidStormBlks,
        2423,
        24, 23,
        Map.MapWorldInfo[2405].X + Map.MapInfo[16].X + 108, Map.MapWorldInfo[2405].Y + Map.MapInfo[16].Y + 172,
        "World\\Minimaps\\2771"
    },
    [2413] = {
        Map.HaradarBlks,
        2443,
        24, 43,
        Map.MapWorldInfo[2413].X + Map.MapInfo[16].X - 137, Map.MapWorldInfo[2413].Y + Map.MapInfo[16].Y + 1680,
        "World\\Minimaps\\2694"
    },
}

--------
