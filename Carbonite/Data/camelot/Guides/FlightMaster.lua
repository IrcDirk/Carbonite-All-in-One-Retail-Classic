local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

Nx.GuideData [L["Flight Master"]] = {
    ["Mode"] = 30
}

local FLIGHT_DATA = {
    ["1,1444,30.2,43.2"] = L["Feathermoon, Feralas"],
    ["1,1437,9.4,59.6"] = L["Menethil Harbor, Wetlands"],
    ["1,1455,55.6,48"] = L["Ironforge, Dun Morogh"],
    ["1,1439,36.4,45.6"] = L["Auberdine, Darkshore"],
    ["2,1441,45,49.2"] = L["Freewind Post, Thousand Needles"],
    ["2,1435,46,54.6"] = L["Stonard, Swamp of Sorrows"],
    ["1,1431,77.4,44.4"] = L["Darkshire, Duskwood"],
    ["2,1450,32.2,66.4"] = L["Moonglade"],
    ["1,1427,37.8,30.6"] = L["Thorium Point, Searing Gorge"],
    ["1,1425,11,46"] = L["Aerie Peak, The Hinterlands"],
    ["2,1456,46.8,50"] = L["Thunder Bluff, Mulgore"],
    ["0,1449,45.2,5.8"] = L["Marshal's Refuge, Un'Goro Crater"],
    ["2,1423,80.2,57"] = L["Light's Hope Chapel, Eastern Plaguelands"],
    ["2,1440,12.2,33.8"] = L["Zoram'gar Outpost, Ashenvale"],
    ["1,1423,81.6,59.2"] = L["Light's Hope Chapel, Eastern Plaguelands"],
    ["1,1450,44.2,45.2"] = L["Darnassus Flight Master"],
    ["1,1434,27.4,77.6"] = L["Booty Bay, Stranglethorn"],
    ["1,1453,66.2,62.4"] = L["Stormwind, Elwynn"],
    ["1,1428,84.4,68.2"] = L["Morgan's Vigil, Burning Steppes"],
    ["1,1448,62.4,24.2"] = L["Talonbranch Glade, Felwood"],
    ["2,1424,60.2,18.6"] = L["Tarren Mill, Hillsbrad"],
    ["1,1442,36.4,7.2"] = L["Stonetalon Peak, Stonetalon Mountains"],
    ["2,1427,34.8,30.6"] = L["Thorium Point, Searing Gorge"],
    ["1,1450,48,67.2"] = L["Moonglade"],
    ["2,1417,73,32.6"] = L["Hammerfall, Arathi"],
    ["1,1424,49.4,52.4"] = L["Southshore, Hillsbrad"],
    ["1,1447,11.8,77.4"] = L["Talrendis Point, Azshara"],
    ["2,1444,75.4,44.2"] = L["Camp Mojache, Feralas"],
    ["2,1446,51.6,25.4"] = L["Gadgetzan, Tanaris"],
    ["1,1445,67.4,51.2"] = L["Theramore, Dustwallow Marsh"],
    ["1,1436,56.4,52.6"] = L["Sentinel Hill, Westfall"],
    ["1,1440,34.4,48"] = L["Astranaar, Ashenvale"],
    ["2,1418,4,44.8"] = L["Kargath, Badlands"],
    ["1,1443,64.6,10.4"] = L["Nijel's Point, Desolace"],
    ["2,1413,51.5,30.34"] = L["Crossroads, The Barrens"],
    ["2,1428,65.6,24.2"] = L["Flame Crest, Burning Steppes"],
    ["2,1450,44.4,45.4"] = L["Thunder Bluff Flight Master"],
    ["2,1413,44.4,59"] = L["Camp Taurajo, The Barrens"],
    ["2,1434,26.8,77"] = L["Booty Bay, Stranglethorn"],
    ["1,1446,51,29.2"] = L["Gadgetzan, Tanaris"],
    ["1,1452,62.2,36.6"] = L["Everlook, Winterspring"],
    ["2,1442,45.2,59.8"] = L["Sun Rock Retreat, Stonetalon Mountains"],
    ["1,1419,65.4,24.4"] = L["Nethergarde Keep, Blasted Lands"],
    ["0,1413,63,37"] = L["Ratchet, The Barrens"],
    ["1,1438,58.4,94"] = L["Rut'theran Village, Teldrassil"],
    ["2,1451,48.8,36.6"] = L["Cenarion Hold, Silithus"],
    ["1,1432,33.8,50.8"] = L["Thelsamar, Loch Modan"],
    ["1,1444,89.4,45.8"] = L["Thalanaar, Feralas"],
    ["2,1447,22,49.6"] = L["Valormok, Azshara"],
    ["1,1422,43,85"] = L["Chillwind Camp, Western Plaguelands"],
    ["1,1433,30.6,59.2"] = L["Lakeshire, Redridge"],
    ["2,1454,45.2,63.8"] = L["Orgrimmar, Durotar"],
    ["2,1425,81.6,81.8"] = L["Revantusk Village, The Hinterlands"],
    ["2,1458,63.4,48.6"] = L["Undercity, Tirisfal"],
    ["2,1448,34.4,53.8"] = L["Bloodvenom Post, Felwood"],
    ["2,1421,45.6,42.4"] = L["The Sepulcher, Silverpine Forest"],
    ["2,1440,73.2,61.6"] = L["Splintertree Post, Ashenvale"],
    ["2,1434,32.4,29.2"] = L["Grom'gol, Stranglethorn"],
    ["2,1452,60.4,36.4"] = L["Everlook, Winterspring"],
    ["2,1445,35.6,31.8"] = L["Brackenwall Village, Dustwallow Marsh"],
    ["1,1417,45.8,46.2"] = L["Refuge Pointe, Arathi"],
    ["1,1451,50.6,34.4"] = L["Cenarion Hold, Silithus"],
    ["2,1443,21.6,74"] = L["Shadowprey Village, Desolace"],
}
local NX_FLIGHT_LOC = { ["1"] = L["Alliance Flight"], ["2"] = L["Horde Flight"], ["0"] = L["Neutral Flight"], }
Nx.NPCData={}
for k, v in pairs(FLIGHT_DATA) do
    local side, zon, x, y, level = Nx.Split(",", k)
    if not level then level = 0 end
    local name = v
    name = NX_FLIGHT_LOC[side].."|"..name
    x,y,zon=tonumber(x),tonumber(y),tonumber(zon)
    table.insert(Nx.NPCData, format("%s|%s|%s|%s|%s|%s",side,name,zon,x,y,level))
    local i = #Nx.NPCData
    if not Nx.GuideData[L["Flight Master"]][zon] then
        Nx.GuideData[L["Flight Master"]][zon] = format("%s,%s,%s,%s,%s",side,x,y,level,i)
    else
        Nx.GuideData[L["Flight Master"]][zon]=Nx.GuideData[L["Flight Master"]][zon] .. format("|%s,%s,%s,%s,%s",side,x,y,level,i)
    end
end
FLIGHT_DATA = nil
NX_FLIGHT_LOC=nil
Nx.FlightConnection=""
