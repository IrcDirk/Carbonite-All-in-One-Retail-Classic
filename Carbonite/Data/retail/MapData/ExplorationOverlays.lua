---------------------------------------------------------------------------------------
-- Carbonite - retail exploration and fog-of-war overlay definitions
-- Copyright 2007-2012 Carbon Based Creations, LLC
-- Distributed under the GNU General Public License, version 3 or later.
---------------------------------------------------------------------------------------

local Map = Nx.Map

Map.ZoneOverlays = {
    -- Kalimdor
    ["moonglade"] = {
        ["shrineofremulos"] = "209,91,271,296",
        ["lakeeluneara"] = "219,273,431,319",
        ["stormragebarrowdens"] = "542,210,275,346",
        ["nighthaven"] = "370,135,346,244",
    },
    ["barrens"] = {
        ["dreadmistpeak"] = "290,104,241,195",
        ["thornhill"] = "481,254,239,231",
        ["thestagnantoasis"] = "344,379,336,289",
        ["farwatchpost"] = "555,129,207,332",
        ["thesludgefen"] = "403,6,257,249",
        ["thewailingcaverns"] = "152,318,377,325",
        ["thedryhills"] = "116,57,283,270",
        ["themerchantcoast"] = "556,456,315,212",
        ["boulderlodemine"] = "511,7,278,209",
        ["theforgottenpools"] = "100,208,446,256",
        ["morshanrampart"] = "258,6,261,216",
        ["ratchet"] = "547,379,219,175",
        ["thecrossroads"] = "362,275,233,193",
        ["groldomfarm"] = "448,127,243,217",
    },
    ["winterspring"] = {
        ["icethistlehills"] = "581,314,249,217",
        ["lakekeltheril"] = "372,268,271,258",
        ["starfallvillage"] = "229,33,367,340",
        ["mazthoril"] = "399,340,257,238",
        ["frostsaberrock"] = "304,0,332,268",
        ["timbermawpost"] = "92,302,362,252",
        ["thehiddengrove"] = "500,17,333,255",
        ["frostwhispergorge"] = "424,474,317,183",
        ["everlook"] = "482,195,194,229",
        ["owlwingthicket"] = "556,439,254,150",
        ["winterfallvillage"] = "588,181,221,209",
        ["frostfirehotsprings"] = "93,118,376,289",
    },
    ["uldum_terrain1"] = {
        ["thegateofunendingcycles"] = "647,15,161,236",
        ["thecursedlanding"] = "752,170,237,316",
        ["ruinsofammon"] = "217,289,203,249",
        ["akhenetfields"] = "471,277,164,185",
        ["orsis"] = "264,136,249,243",
        ["nahom"] = "583,162,237,194",
        ["ramkahen"] = "411,67,228,227",
        ["obeliskofthemoon"] = "110,0,400,224",
        ["obeliskofthesun"] = "340,282,269,203",
        ["thetrailofdevestation"] = "657,349,206,204",
        ["cradeloftheancient"] = "341,402,202,169",
        ["schnottzslanding"] = "28,221,312,289",
        ["marat"] = "406,174,160,193",
        ["virnaaldam"] = "479,215,151,144",
        ["throneofthefourwinds"] = "229,433,270,229",
        ["thevortexpinnacle"] = "656,473,213,195",
        ["hallsoforigination"] = "599,184,269,242",
        ["templeofuldum"] = "132,127,296,209",
        ["obeliskofthestars"] = "551,121,196,170",
        ["ruinsofahmtul"] = "365,0,278,173",
        ["khartutstomb"] = "542,0,203,215",
        ["neferset"] = "407,384,209,254",
        ["tahretgrounds"] = "545,193,150,159",
        ["lostcityofthetolvir"] = "527,291,233,321",
    },
    ["ashenvale"] = {
        ["theshrineofassenia"] = "40,275,306,283",
        ["nightrun"] = "595,253,221,257",
        ["fallenskylake"] = "529,385,287,276",
        ["warsonglumbercamp"] = "771,265,231,223",
        ["lakefalathim"] = "112,148,184,232",
        ["satyrnaar"] = "696,154,235,236",
        ["thehowlingvale"] = "473,97,325,239",
        ["raynewoodretreat"] = "481,221,231,256",
        ["thezoramstrand"] = "0,0,262,390",
        ["felfirehill"] = "714,317,277,333",
        ["maelstraspost"] = "188,0,246,361",
        ["thunderpeak"] = "377,121,203,310",
        ["theruinsofstardust"] = "210,331,236,271",
        ["orendilsretreat"] = "143,0,244,251",
        ["astranaar"] = "255,164,251,271",
        ["thistlefurvillage"] = "255,78,314,241",
        ["silverwindrefuge"] = "338,335,347,308",
        ["boughshadow"] = "836,148,166,211",
    },
    ["teldrassil"] = {
        ["banethilhollow"] = "374,221,175,235",
        ["shadowglen"] = "481,104,241,217",
        ["gnarlpinehold"] = "347,355,198,181",
        ["thecleft"] = "432,109,144,226",
        ["theoracleglade"] = "276,90,194,244",
        ["rutheranvillage"] = "329,448,317,220",
        ["lakealameth"] = "422,310,289,202",
        ["wellspringlake"] = "382,83,165,249",
        ["starbreezevillage"] = "544,217,187,196",
        ["galardellvalley"] = "466,237,178,186",
        ["poolsofarlithrien"] = "345,243,140,210",
        ["darnassus"] = "149,181,298,337",
        },
    ["mulgore"] = {
        ["baeldundigsite"] = "226,220,218,192",
        ["winterhoofwaterwell"] = "449,340,174,185",
        ["redcloudmesa"] = "286,401,446,264",
        ["redrocks"] = "514,43,186,185",
        ["ravagedcaravan"] = "435,224,187,165",
        ["thunderhornwaterwell"] = "333,202,201,167",
        ["theventurecomine"] = "530,138,208,300",
        ["wildmanewaterwell"] = "331,0,190,172",
        ["thunderbluff"] = "208,62,373,259",
        ["windfuryridge"] = "400,0,222,202",
        ["bloodhoofvillage"] = "319,273,302,223",
        ["stonetalonpass"] = "201,0,237,184",
        ["therollingplains"] = "527,291,260,243",
        ["palemanerock"] = "248,321,172,205",
        ["thegoldenplains"] = "448,101,186,216",
    },
    ["hyjal"] = {
        ["archimondesvengeance"] = "320,5,270,300",
        ["shrineofgoldrinn"] = "116,17,291,321",
        ["nordrassil"] = "392,0,537,323",
        ["gatesofsothann"] = "622,320,272,334",
        ["sethriasroost"] = "139,436,277,232",
        ["theregrowth"] = "52,253,441,319",
        ["direforgehill"] = "303,197,270,173",
        ["ashenlake"] = "6,78,282,418",
        ["thescorchedplain"] = "411,216,365,264",
        ["thethroneofflame"] = "318,378,419,290",
        ["darkwhispergorge"] = "682,128,320,471",
    },
    ["felwood"] = {
        ["irontreewoods"] = "406,55,261,273",
        ["morlosaran"] = "476,484,187,176",
        ["bloodvenomfalls"] = "220,231,345,192",
        ["jaedenar"] = "234,317,319,176",
        ["felpawvillage"] = "471,0,307,161",
        ["jadefirerun"] = "303,9,263,199",
        ["ruinsofconstellas"] = "278,359,268,214",
        ["deadwoodvillage"] = "410,505,173,163",
        ["emeraldsanctuary"] = "394,382,274,212",
        ["shatterscarvale"] = "243,107,343,250",
        ["talonbranchglade"] = "531,57,209,226",
        ["jadefireglen"] = "288,458,229,210",
    },
    ["darkshore"] = {
        ["lordanel"] = "391,54,277,281",
        ["eyeofthevortex"] = "300,239,330,192",
        ["nazjvel"] = "207,467,244,201",
        ["wildbendriver"] = "280,378,314,193",
        ["ruinsofauberdine"] = "280,182,203,194",
        ["witheringthicket"] = "305,118,328,250",
        ["shatterspearvale"] = "596,16,250,241",
        ["shatterspearwarcamp"] = "565,0,245,147",
        ["ametharan"] = "294,330,326,145",
        ["ruinsofmathystra"] = "517,28,200,263",
        ["themastersglaive"] = "277,483,303,185",
    },
    ["aszhara"] = {
        ["bearshead"] = "113,141,256,224",
        ["thesecretlab"] = "353,396,184,213",
        ["ruinsofarkkoran"] = "575,121,219,193",
        ["darnassianbasecamp"] = "343,3,243,262",
        ["lakemennar"] = "245,377,210,232",
        ["ravencrestmonument"] = "476,401,295,267",
        ["stormcliffs"] = "407,403,207,232",
        ["theshatteredstrand"] = "316,168,206,329",
        ["gallywixpleasurepalace"] = "70,222,250,230",
        ["blackmawhold"] = "204,53,260,267",
        ["bilgewaterharbor"] = "395,127,587,381",
        ["towerofeldara"] = "684,22,306,337",
        ["orgimmarreargate"] = "22,344,352,274",
        ["bitterreaches"] = "477,0,321,247",
        ["ruinsofeldarath"] = "228,229,218,237",
    },
    ["ungorocrater"] = {
        ["lakkaritarpits"] = "305,0,432,294",
        ["ironstoneplateau"] = "706,201,197,222",
        ["therollinggarden"] = "565,39,337,321",
        ["golakkahotsprings"] = "145,226,309,277",
        ["theslitheringscar"] = "335,384,381,274",
        ["thescreamingreaches"] = "157,0,332,332",
        ["mossypile"] = "328,179,186,185",
        ["themarshlands"] = "573,256,263,412",
        ["fireplumeridge"] = "356,192,321,288",
        ["terrorrun"] = "162,357,316,293",
        ["fungalrock"] = "557,0,224,191",
        ["marshalsstand"] = "462,330,204,170",
    },
    ["desolace"] = {
        ["valleyofspears"] = "170,196,321,275",
        ["gelkisvillage"] = "207,472,274,196",
        ["mannoroccoven"] = "381,357,326,311",
        ["thunderaxefortress"] = "440,49,220,205",
        ["shokthokar"] = "589,319,309,349",
        ["cenarionwildlands"] = "415,156,312,285",
        ["sargeron"] = "655,0,317,293",
        ["nijelspoint"] = "573,0,231,257",
        ["magramterritory"] = "613,170,289,244",
        ["thargadscamp"] = "275,376,212,186",
        ["tethrisaran"] = "399,0,274,145",
        ["kodograveyard"] = "360,273,250,215",
        ["ranzjarisle"] = "210,0,161,141",
        ["shadowbreakravine"] = "637,402,292,266",
        ["shadowpreyvillage"] = "142,369,222,299",
        ["slitherbladeshore"] = "208,24,338,342",
    },
    ["tanaris"] = {
        ["landsendbeach"] = "431,452,224,216",
        ["southbreakshore"] = "437,289,274,186",
        ["zulfarrak"] = "184,0,315,190",
        ["valleryofthewatchers"] = "255,431,269,190",
        ["southmoonruins"] = "301,349,232,211",
        ["brokenpillar"] = "413,211,195,163",
        ["thegapingchasm"] = "448,364,225,187",
        ["cavernsoftime"] = "507,238,213,173",
        ["gadgetzan"] = "412,92,189,180",
        ["dunemaulcompound"] = "305,257,231,177",
        ["gadgetzanbay"] = "479,9,254,341",
        ["lostriggercover"] = "615,201,178,243",
        ["eastmoonruins"] = "380,341,173,163",
        ["abyssalsands"] = "297,148,255,194",
        ["thistleshrubvalley"] = "185,280,221,293",
        ["thenoxiouslair"] = "258,211,179,190",
        ["sandsorrowwatch"] = "293,99,214,149",
    },
    ["uldum"] = {
        ["thegateofunendingcycles"] = "647,15,161,236",
        ["thecursedlanding"] = "752,170,237,316",
        ["ruinsofammon"] = "217,289,203,249",
        ["akhenetfields"] = "471,277,164,185",
        ["orsis"] = "264,136,249,243",
        ["nahom"] = "583,162,237,194",
        ["ramkahen"] = "411,67,228,227",
        ["obeliskofthemoon"] = "110,0,400,224",
        ["obeliskofthesun"] = "340,282,269,203",
        ["thetrailofdevestation"] = "657,349,206,204",
        ["cradeloftheancient"] = "341,402,202,169",
        ["schnottzslanding"] = "28,221,312,289",
        ["marat"] = "406,174,160,193",
        ["virnaaldam"] = "479,215,151,144",
        ["throneofthefourwinds"] = "229,433,270,229",
        ["thevortexpinnacle"] = "656,473,213,195",
        ["hallsoforigination"] = "599,184,269,242",
        ["templeofuldum"] = "132,127,296,209",
        ["obeliskofthestars"] = "551,121,196,170",
        ["ruinsofahmtul"] = "365,0,278,173",
        ["khartutstomb"] = "542,0,203,215",
        ["neferset"] = "407,384,209,254",
        ["tahretgrounds"] = "545,193,150,159",
        ["lostcityofthetolvir"] = "527,291,233,321",
    },
    ["ahnqirajthefallenkingdom"] = {
        ["aqkingdom"] = "115,0,887,668",
    },
    ["durotar"] = {
        ["razormanegrounds"] = "302,264,248,158",
        ["echoisles"] = "429,413,330,255",
        ["thunderridge"] = "295,48,220,218",
        ["skullrock"] = "438,0,208,157",
        ["tiragardekeep"] = "462,298,210,200",
        ["valleyoftrials"] = "304,312,254,258",
        ["southfurywatershed"] = "282,174,244,222",
        ["drygulchravine"] = "415,60,236,196",
        ["senjinvillage"] = "457,406,192,184",
        ["razorhill"] = "431,157,224,227",
        ["northwatchfoothold"] = "399,440,162,157",
        ["orgrimmar"] = "309,0,259,165",
    },
    ["feralas"] = {
        ["campmojache"] = "671,181,174,220",
        ["feathermoonstronghold"] = "362,237,217,192",
        ["darkmistruins"] = "568,287,172,198",
        ["writhingdeep"] = "652,298,232,206",
        ["ruinsoffeathermoon"] = "186,229,208,204",
        ["theforgottencoast"] = "375,343,194,304",
        ["feralscar"] = "457,281,191,179",
        ["grimtotemcompund"] = "607,170,159,218",
        ["ruinsofisildien"] = "467,354,206,237",
        ["gordunnioutpost"] = "663,116,192,157",
        ["thetwincolossals"] = "271,0,350,334",
        ["diremaul"] = "485,101,265,284",
        ["lowerwilds"] = "756,191,207,209",
    },
    ["silithus"] = {
        ["thescarabwall"] = "0,455,580,213",
        ["valorsrest"] = "614,0,315,285",
        ["twilightbasecamp"] = "100,151,434,231",
        ["southwindvillage"] = "550,181,309,243",
        ["thecrystalvale"] = "126,0,329,246",
        ["hiveashi"] = "345,4,405,267",
        ["cenarionhold"] = "427,143,292,260",
        ["hiveregal"] = "380,310,489,358",
        ["hivezora"] = "0,206,542,367",
    },
    ["stonetalonmountains"] = {
        ["windshearcrag"] = "533,179,374,287",
        ["kromgarfortress"] = "588,341,183,196",
        ["stonetalonpeak"] = "265,0,305,244",
        ["unearthedgrounds"] = "654,369,265,206",
        ["greatwoodvale"] = "602,448,322,220",
        ["boulderslideravine"] = "532,512,194,156",
        ["cliffwalkerpost"] = "366,95,241,192",
        ["webwinderpath"] = "468,263,267,352",
        ["sunrockretreat"] = "353,285,222,222",
        ["webwinderhollow"] = "479,401,164,258",
        ["ruinsofeldrethar"] = "367,411,221,235",
        ["battlescarvalley"] = "220,189,290,297",
        ["windshearhold"] = "516,289,176,189",
        ["thaldarahoverlook"] = "252,121,210,189",
        ["malakajin"] = "618,537,211,131",
        ["mirkfallonlake"] = "417,143,244,247",
        ["thecharredvale"] = "199,368,277,274",
    },
    ["southernbarrens"] = {
        ["huntershill"] = "300,64,218,178",
        ["honorsstand"] = "201,0,315,170",
        ["ruinsoftaurajo"] = "244,286,285,171",
        ["razorfenkraul"] = "273,528,214,140",
        ["vendettapoint"] = "267,196,254,214",
        ["forwardcommand"] = "423,251,216,172",
        ["battlescar"] = "274,307,384,248",
        ["theovergrowth"] = "289,117,355,226",
        ["baelmodan"] = "398,457,269,211",
        ["northwatchhold"] = "548,147,280,279",
        ["frazzlecrazmotherload"] = "269,436,242,195",
    },
    ["dustwallow"] = {
        ["witchhill"] = "428,0,270,353",
        ["theramoreisle"] = "542,223,305,247",
        ["direhornpost"] = "358,169,279,301",
        ["blackhoofvillage"] = "199,0,344,183",
        ["brackenwllvillage"] = "133,59,384,249",
        ["alcazisland"] = "656,21,206,200",
        ["mudsprocket"] = "109,313,433,351",
        ["shadyrestinn"] = "137,188,317,230",
        ["thewyrmbog"] = "359,369,436,299",
    },
    ["hyjal_terrain1"] = {
        ["archimondesvengeance"] = "320,5,270,300",
        ["shrineofgoldrinn"] = "116,17,291,321",
        ["nordrassil"] = "392,0,537,323",
        ["gatesofsothann"] = "622,320,272,334",
        ["sethriasroost"] = "139,436,277,232",
        ["theregrowth"] = "52,253,441,319",
        ["direforgehill"] = "303,197,270,173",
        ["ashenlake"] = "6,78,282,418",
        ["thescorchedplain"] = "411,216,365,264",
        ["thethroneofflame"] = "318,378,419,290",
        ["darkwhispergorge"] = "682,128,320,471",
    },
    ["thousandneedles"] = {
        ["southseaholdfast"] = "756,412,246,256",
        ["thetwilightwithering"] = "347,329,374,339",
        ["splithoofheights"] = "571,49,431,410",
        ["thegreatlift"] = "136,0,272,232",
        ["razorfendowns"] = "298,0,361,314",
        ["theshimmeringdeep"] = "591,257,411,411",
        ["freewindpost"] = "276,186,436,271",
        ["highperch"] = "0,134,246,380",
        ["rustmauldivesite"] = "527,465,234,203",
        ["westreachsummit"] = "0,0,280,325",
        ["twilightbulwark"] = "125,241,358,418",
        ["darkcloudpinnacle"] = "169,116,317,252",
    },

    -- Eastern Kingdoms

    ["vashjirruins"] = {
        ["nespirah"] = "460,261,286,269",
        ["glimmeringdeepgorge"] = "270,222,272,180",
        ["silvertidehollow"] = "150,32,480,319",
        ["shimmeringgrotto"] = "400,0,339,278",
        ["ruinsofvashjir"] = "217,268,349,361",
        ["ruinsoftherseral"] = "554,175,197,223",
        ["bethmoraridge"] = "407,445,335,223",
    },
    ["duskwood"] = {
        ["theyorgenfarmstead"] = "401,396,233,248",
        ["addlesstead"] = "32,348,299,296",
        ["thetranquilgardenscemetary"] = "627,344,291,244",
        ["darkshire"] = "640,128,329,314",
        ["brightwoodgrove"] = "497,112,279,399",
        ["vulgologremound"] = "228,355,268,282",
        ["thehushedbank"] = "0,152,189,307",
        ["thedarkenedbank"] = "71,26,931,235",
        ["manormistmantle"] = "661,122,219,182",
        ["racenhill"] = "96,292,205,157",
        ["thetwilightgrove"] = "314,101,320,388",
        ["therottingorchard"] = "539,368,291,263",
        ["ravenhillcemetary"] = "91,132,323,309",
    },
    ["vashjirkelpforest"] = {
        ["darkwhispergorge"] = "528,228,220,189",
        ["honorstomb"] = "380,43,291,206",
        ["legionsfate"] = "210,35,278,315",
        ["gnawsboneyard"] = "451,325,311,217",
        ["theaccursedreef"] = "365,162,340,225",
        ["gubogglesledge"] = "399,280,227,207",
        ["holdingpens"] = "456,401,316,267",
    },
    ["twilighthighlands_terrain1"] = {
        ["victorypoint"] = "302,306,177,159",
        ["dragonmawpass"] = "76,120,283,206",
        ["bloodgulch"] = "416,205,215,157",
        ["obsidianforest"] = "436,380,342,288",
        ["thundermar"] = "374,93,238,229",
        ["grimbatol"] = "83,223,230,276",
        ["theblackbreach"] = "498,121,211,210",
        ["wyrmsbend"] = "205,232,191,198",
        ["dragonmawport"] = "631,245,251,207",
        ["crucibleofcarnage"] = "387,268,203,208",
        ["twilightshore"] = "610,345,260,202",
        ["vermillionredoubt"] = "71,16,324,264",
        ["thegullet"] = "269,179,175,180",
        ["humboldtconflaguration"] = "344,89,143,141",
        ["gorshakwarcamp"] = "543,220,194,170",
        ["highbank"] = "697,403,220,227",
        ["crushblow"] = "370,447,182,195",
        ["thetwilightcitadel"] = "151,314,361,354",
        ["highlandforest"] = "482,330,239,232",
        ["thetwilightbreach"] = "312,192,199,212",
        ["thekrazzworks"] = "654,0,226,232",
        ["slitheringcove"] = "622,169,198,201",
        ["thetwilightgate"] = "327,356,165,199",
        ["ruinsofdrakgor"] = "296,0,206,182",
        ["firebeardspatrol"] = "499,265,215,181",
        ["dunwaldruins"] = "395,367,197,218",
        ["weepingwound"] = "358,0,214,190",
        ["kirthaven"] = "482,0,308,267",
        ["glopgutshollow"] = "291,89,174,190",
    },
    ["hinterlands"] = {
        ["queldanillodge"] = "220,181,241,211",
        ["thealtarofzul"] = "357,343,225,196",
        ["shaolwatha"] = "565,208,281,261",
        ["thecreepingruin"] = "390,252,199,199",
        ["zunwatha"] = "152,284,226,225",
        ["plaguemistravine"] = "133,105,191,278",
        ["shadraalor"] = "220,379,240,196",
        ["aeriepeak"] = "0,236,238,267",
        ["valorwindlake"] = "286,269,199,212",
        ["agolwatha"] = "367,159,208,204",
        ["jinthaalor"] = "487,334,287,289",
        ["skulkrock"] = "490,195,176,235",
        ["seradane"] = "475,5,303,311",
        ["theoverlookcliffs"] = "677,267,244,401",
    },
    ["blastedlands"] = {
        ["serpentscoil"] = "459,97,218,183",
        ["nethergardekeep"] = "530,6,295,205",
        ["dreadmaulpost"] = "327,182,235,188",
        ["altarofstorms"] = "225,110,238,195",
        ["riseofthedefiler"] = "375,102,168,170",
        ["dreadmaulhold"] = "258,0,272,206",
        ["thetaintedforest"] = "132,311,348,357",
        ["surwich"] = "333,474,199,191",
        ["thedarkportal"] = "368,179,370,298",
        ["theredreaches"] = "533,268,268,354",
        ["shattershore"] = "578,91,240,270",
        ["sunveilexcursion"] = "386,374,233,266",
        ["nethergardesupplycamps"] = "436,0,195,199",
        ["thetaintedscar"] = "144,175,308,226",
    },
    ["wetlands"] = {
        ["sundownmarsh"] = "121,63,276,243",
        ["blackchannelmarsh"] = "37,240,301,232",
        ["dunalgaz"] = "346,419,298,215",
        ["slabchiselssurvey"] = "532,352,300,316",
        ["satlspray"] = "218,0,250,282",
        ["greenwardensgrove"] = "460,102,250,269",
        ["raptorridge"] = "599,123,256,245",
        ["thelganrock"] = "371,335,258,207",
        ["bluegillmarsh"] = "31,102,321,248",
        ["mosshidefen"] = "506,232,369,235",
        ["direforgehills"] = "506,34,329,228",
        ["angerfangencampment"] = "359,201,236,256",
        ["whelgarsexcavationsite"] = "185,195,298,447",
        ["dunmodr"] = "356,7,257,185",
        ["ironbeardstomb"] = "372,76,185,224",
        ["menethilharbor"] = "0,297,325,363",
    },
    ["easternplaguelands"] = {
        ["zulmashar"] = "528,0,286,176",
        ["thefungalvale"] = "183,211,274,216",
        ["theundercroft"] = "56,457,280,211",
        ["lightshopechapel"] = "687,271,196,220",
        ["corinscrossing"] = "493,289,186,213",
        ["tyrshand"] = "651,414,214,254",
        ["eastwalltower"] = "541,184,181,176",
        ["northpasstower"] = "401,69,250,192",
        ["acherus"] = "774,102,228,273",
        ["thondorilriver"] = "0,100,262,526",
        ["themarrisstead"] = "133,335,202,202",
        ["thenoxiousglade"] = "650,55,297,299",
        ["thepestilentscar"] = "383,348,182,320",
        ["theinfectisscar"] = "595,263,177,266",
        ["terrordale"] = "0,10,258,320",
        ["blackwoodlake"] = "382,151,238,231",
        ["stratholme"] = "118,0,310,178",
        ["quellithienlodge"] = "351,0,277,175",
        ["plaguewood"] = "144,40,328,253",
        ["darrowshire"] = "211,462,248,206",
        ["ruinsofthescarletenclave"] = "738,295,264,373",
        ["lightsshieldtower"] = "391,271,243,162",
        ["northdale"] = "570,61,265,232",
        ["crownguardtower"] = "258,351,202,191",
        ["lakemereldar"] = "462,427,266,241",
    },
    ["badlands"] = {
        ["agmondsend"] = "230,315,342,353",
        ["apocryphansrest"] = "0,66,252,353",
        ["campcagg"] = "0,281,339,347",
        ["uldaman"] = "336,0,266,210",
        ["lethlorravine"] = "533,55,469,613",
        ["campboff"] = "407,220,274,448",
        ["hammertoesdigsite"] = "411,116,209,196",
        ["campkosh"] = "504,19,236,260",
        ["angorfortress"] = "230,68,285,223",
        ["deathwingscar"] = "175,178,328,313",
        ["thedustbowl"] = "144,99,214,285",
    },
    ["silverpine"] = {
        ["northtidesrun"] = "147,0,281,345",
        ["thesepulcher"] = "341,157,218,200",
        ["forsakenhighcommand"] = "445,0,361,175",
        ["thedecrepitfields"] = "471,156,176,152",
        ["northtidesbeachhead"] = "323,68,174,199",
        ["theforsakenfront"] = "433,327,152,189",
        ["valgansfield"] = "461,77,162,172",
        ["deepelemmine"] = "483,212,217,198",
        ["thebattlefront"] = "349,429,255,180",
        ["fenrisisle"] = "581,15,352,302",
        ["shadowfangkeep"] = "337,337,179,165",
        ["olsensfarthing"] = "312,249,251,167",
        ["ambermill"] = "509,250,283,243",
        ["berensperil"] = "505,405,318,263",
        ["forsakenrearguard"] = "369,0,186,238",
        ["thegreymanewall"] = "318,506,409,162",
        ["theskitteringdark"] = "236,0,227,172",
    },
    ["thecapeofstranglethorn"] = {
        ["bootybay"] = "289,341,225,255",
        ["gurubashiarena"] = "345,0,238,260",
        ["mistvalevalley"] = "408,248,253,242",
        ["crystalveinmine"] = "528,73,271,204",
        ["wildshore"] = "340,392,236,276",
        ["nekmaniwellspring"] = "292,213,246,221",
        ["ruinsofaboraz"] = "533,181,184,176",
        ["jagueroisle"] = "471,404,240,264",
        ["thesundering"] = "452,0,244,209",
        ["hardwrenchhideaway"] = "208,116,356,221",
        ["ruinsofjubuwal"] = "468,119,155,221",
    },
    ["vashjirdepths"] = {
        ["abyssalbreach"] = "497,0,491,470",
        ["seabrush"] = "415,183,225,250",
        ["fireplumetrench"] = "315,110,298,251",
        ["lghorek"] = "162,210,306,293",
        ["coldlightchasm"] = "266,280,267,374",
        ["abandonedreef"] = "50,263,371,394",
        ["korthunsend"] = "412,283,370,385",
        ["deepfinridge"] = "275,32,363,262",
    },
    ["stranglethornjungle"] = {
        ["kurzenscompound"] = "499,0,244,238",
        ["balalruins"] = "267,168,159,137",
        ["thevilereef"] = "140,208,236,224",
        ["moshoggogremound"] = "543,253,234,206",
        ["ruinsofzulkunda"] = "158,0,228,265",
        ["fortlivingston"] = "398,375,230,170",
        ["mazthoril"] = "488,364,350,259",
        ["nesingwarysexpedition"] = "306,63,227,190",
        ["zuuldalaruins"] = "9,22,324,263",
        ["kalairuins"] = "354,184,139,150",
        ["zulgurub"] = "626,0,376,560",
        ["baliamahruins"] = "397,243,239,205",
        ["bambala"] = "566,164,190,176",
        ["mizjahruins"] = "387,246,157,173",
        ["lakenazferiti"] = "413,95,240,228",
        ["gromgolbasecamp"] = "298,228,167,179",
        ["rebelcamp"] = "306,0,302,166",
    },
    ["ruinsofgilneas"] = {
        ["gilneaspuzzle"] = "0,0,1002,668",
    },

    ["gilneas_terrain2"] = {
        ["greymanemanor"] = "141,202,244,241",
        ["theblackwald"] = "504,394,280,224",
        ["theheadlands"] = "160,0,328,336",
        ["crowleyorchard"] = "261,427,210,166",
        ["emberstonemine"] = "639,43,281,351",
        ["duskhaven"] = "272,333,286,178",
        ["tempestsreach"] = "652,290,350,345",
        ["korothsden"] = "393,386,222,268",
        ["hammondfarmstead"] = "167,352,194,236",
        ["haywardfishery"] = "293,449,177,219",
        ["stormglenvillage"] = "516,465,321,203",
        ["northgatewoods"] = "482,14,282,298",
        ["northernheadlands"] = "387,0,267,314",
        ["keelharbor"] = "298,95,280,342",
    },
    ["searinggorge"] = {
        ["blackrockmountain"] = "243,424,304,244",
        ["thoriumpoint"] = "255,38,429,301",
        ["tannercamp"] = "413,360,571,308",
        ["thecauldron"] = "232,171,481,360",
        ["blackcharcave"] = "0,361,375,307",
        ["grimsiltworksite"] = "531,241,441,266",
        ["firewatchridge"] = "0,75,365,393",
        ["dustfirevalley"] = "588,0,392,355",
    },
    ["elwynn"] = {
        ["westbrookgarrison"] = "116,355,269,313",
        ["jerodslanding"] = "396,430,230,206",
        ["northshirevalley"] = "355,138,295,296",
        ["goldshire"] = "247,294,276,231",
        ["stromwind"] = "0,0,512,422",
        ["stonecairnlake"] = "552,186,340,272",
        ["crystallake"] = "417,327,220,207",
        ["towerofazora"] = "529,287,270,241",
        ["ridgepointtower"] = "708,442,285,194",
        ["brackwellpumpkinpatch"] = "532,424,287,216",
        ["fargodeepmine"] = "240,420,269,248",
        ["eastvaleloggingcamp"] = "703,292,294,243",
    },
    ["arathi"] = {
        ["refugepoint"] = "293,145,196,270",
        ["galensfall"] = "0,144,212,305",
        ["northfoldmanor"] = "132,105,227,268",
        ["circleofeastbinding"] = "506,126,183,238",
        ["bouldergor"] = "171,123,249,278",
        ["goshekfarm"] = "430,249,306,248",
        ["cirecleofouterbinding"] = "332,273,215,188",
        ["hammerfall"] = "581,118,270,271",
        ["thandolspan"] = "261,416,237,252",
        ["boulderfisthall"] = "327,367,252,258",
        ["faldirscove"] = "77,400,273,268",
        ["witherbarkvillage"] = "476,359,260,220",
        ["stromgardekeep"] = "21,269,284,306",
        ["dabyriesfarmstead"] = "404,144,210,227",
        ["circleofinnerbinding"] = "201,312,228,227",
        ["circleofwestbinding"] = "85,24,220,287",
    },
    ["dunmorogh"] = {
        ["thegrizzledden"] = "374,287,211,160",
        ["coldridgepass"] = "360,340,225,276",
        ["kharanos"] = "449,220,184,188",
        ["gnomeregan"] = "0,27,409,318",
        ["thetundridhills"] = "579,306,174,249",
        ["theshimmeringdeep"] = "397,132,171,234",
        ["golbolarquarry"] = "663,288,198,251",
        ["iceflowlake"] = "263,0,236,358",
        ["amberstillranch"] = "595,225,249,183",
        ["ironforgeairfield"] = "630,0,308,335",
        ["frostmanehold"] = "50,227,437,249",
        ["coldridgevalley"] = "100,366,398,302",
        ["ironforge"] = "398,0,376,347",
        ["helmsbedlake"] = "760,268,218,234",
        ["northgateoutpost"] = "765,43,237,366",
        ["frostmanefront"] = "469,256,226,335",
    },
    ["westfall"] = {
        ["thedaggerhills"] = "303,395,292,273",
        ["furlbrowspumpkinfarm"] = "394,0,197,213",
        ["thegapingchasm"] = "294,168,184,217",
        ["jangoloadmine"] = "311,0,196,229",
        ["goldcoastquarry"] = "199,79,235,306",
        ["themolsenfarm"] = "348,118,202,224",
        ["westfalllighthouse"] = "221,477,211,167",
        ["sentinelhill"] = "404,226,229,265",
        ["demontsplace"] = "203,376,201,195",
        ["alexstonfarmstead"] = "167,263,346,222",
        ["saldeansfarm"] = "451,81,244,237",
        ["moonbrook"] = "308,325,232,213",
        ["thedustplains"] = "480,378,317,261",
        ["thedeadacre"] = "531,200,193,273",
        ["thejansenstead"] = "474,0,202,179",
    },
    ["burningsteppes"] = {
        ["blackrockpass"] = "419,258,298,410",
        ["dreadmaulrock"] = "568,151,274,263",
        ["dracodar"] = "0,237,362,431",
        ["altarofstorms"] = "0,0,182,360",
        ["ruinsofthaurissan"] = "421,0,324,354",
        ["blackrockmountain"] = "79,0,281,388",
        ["terrorwingpath"] = "646,7,350,341",
        ["blackrockstronghold"] = "235,0,320,385",
        ["morgansvigil"] = "615,255,383,413",
        ["pillarofash"] = "253,255,274,413",
    },
    ["westernplaguelands"] = {
        ["thebulwark"] = "48,235,316,316",
        ["hearthglen"] = "235,0,432,271",
        ["caerdarrow"] = "601,390,194,208",
        ["sorrowhill"] = "261,448,368,220",
        ["felstonefield"] = "229,228,241,212",
        ["darrowmerelake"] = "510,354,492,314",
        ["northridgelumbercamp"] = "231,123,359,182",
        ["thewrithinghaunt"] = "472,332,169,195",
        ["thondrorilriver"] = "533,0,311,436",
        ["theweepingcave"] = "551,151,185,230",
        ["redpinedell"] = "286,211,290,133",
        ["dalsonsfarm"] = "300,232,325,192",
        ["andorhal"] = "96,343,464,325",
        ["gahrronswithering"] = "495,213,241,252",
    },
    ["tirisfal"] = {
        ["balnirfarmstead"] = "594,324,242,179",
        ["venomwebvale"] = "752,150,250,279",
        ["thebulwark"] = "709,330,293,338",
        ["brill"] = "480,252,199,182",
        ["scarletmonastery"] = "740,47,262,262",
        ["scarletwatchpost"] = "692,99,161,234",
        ["agamandmills"] = "324,90,285,260",
        ["brightwaterlake"] = "573,122,210,292",
        ["ruinsoflorderon"] = "423,359,390,267",
        ["sollidenfarmstead"] = "201,192,286,225",
        ["calstonestate"] = "389,255,179,169",
        ["coldhearthmanor"] = "418,317,212,177",
        ["deathknell"] = "9,207,431,407",
        ["nightmarevale"] = "347,325,225,281",
        ["crusaderoutpost"] = "686,232,175,210",
        ["garrenshaunt"] = "477,129,190,214",
    },
    ["redridge"] = {
        ["rendersvalley"] = "451,377,427,291",
        ["stonewatchkeep"] = "480,0,228,420",
        ["lakeridgehighway"] = "148,316,392,352",
        ["campeverstill"] = "445,286,189,193",
        ["renderscamp"] = "214,0,357,246",
        ["lakeeverstill"] = "81,214,464,250",
        ["lakeshire"] = "0,110,410,256",
        ["althersmill"] = "350,139,228,247",
        ["shalewindcanyon"] = "688,283,306,324",
        ["stonewatchfalls"] = "525,302,316,182",
        ["galardellvalley"] = "574,0,428,463",
        ["threecorners"] = "0,256,323,406",
        ["redridgecanyons"] = "37,0,413,292",
    },
    ["swampofsorrows"] = {
        ["splinterspearjunction"] = "194,236,238,343",
        ["stagalbog"] = "540,360,347,303",
        ["marshtidewatch"] = "478,0,330,342",
        ["pooloftears"] = "575,238,257,229",
        ["theshiftingmire"] = "331,24,292,360",
        ["sorrowmurk"] = "703,80,229,418",
        ["ithariuscave"] = "7,242,268,316",
        ["mistyreedstrand"] = "600,0,402,668",
        ["stonard"] = "297,258,357,308",
        ["mistyvalley"] = "0,80,268,285",
        ["theharborage"] = "161,79,266,284",
        ["bogpaddle"] = "600,0,262,193",
    },
    ["lochmodan"] = {
        ["thefarstriderlodge"] = "570,209,349,292",
        ["stronewroughtdam"] = "339,0,333,200",
        ["silverstreammine"] = "221,0,225,252",
        ["northgatepass"] = "16,0,319,289",
        ["ironbandsexcavationsite"] = "481,296,397,291",
        ["stonesplintervalley"] = "177,345,273,294",
        ["thelsamar"] = "0,146,455,295",
        ["grizzlepawridge"] = "245,324,273,230",
        ["valleyofkings"] = "0,311,310,345",
        ["theloch"] = "340,81,330,474",
        ["mogroshstronghold"] = "549,52,294,249",
    },
    ["deadwindpass"] = {
        ["deadmanscrossing"] = "83,0,617,522",
        ["thevice"] = "433,208,350,449",
        ["karazhan"] = "92,310,513,358",
    },
    ["hillsbradfoothills"] = {
        ["tarrenmill"] = "494,226,165,203",
        ["gavinsnaze"] = "344,254,116,129",
        ["lordamereinternmentcamp"] = "194,216,250,167",
        ["mistyshore"] = "321,42,158,169",
        ["nethandersteed"] = "502,373,204,244",
        ["hillsbradfields"] = "191,302,302,175",
        ["growlesscave"] = "359,191,171,136",
        ["theheadland"] = "390,255,105,148",
        ["azurelodemine"] = "287,399,180,182",
        ["dalarancrater"] = "102,137,316,238",
        ["gallowscorner"] = "451,140,155,147",
        ["strahnbrad"] = "505,44,275,193",
        ["darrowhill"] = "425,279,147,160",
        ["southpointtower"] = "59,310,312,254",
        ["dandredsfold"] = "341,0,258,113",
        ["slaughterhollow"] = "413,55,148,120",
        ["soferasnaze"] = "484,166,148,146",
        ["ruinsofalterac"] = "347,85,189,181",
        ["corrahnsdagger"] = "426,224,135,160",
        ["purgationisle"] = "200,505,144,139",
        ["crushridgehold"] = "463,101,134,124",
        ["dungarok"] = "542,410,269,258",
        ["durnholdekeep"] = "565,217,437,451",
        ["chillwindpoint"] = "555,68,447,263",
        ["theuplands"] = "441,0,212,160",
        ["southshore"] = "383,352,229,219",
    },

    -- Jamie exports

    ["azuremystisle"] =
    {
        ["ammenford"] = "515,279,256,256",
        ["ammenvale"] = "527,104,475,512",
        ["azurewatch"] = "383,249,256,256",
        ["bristlelimbvillage"] = "174,363,256,256",
        ["emberglade"] = "488,24,256,256",
        ["fairbridgestrand"] = "356,0,256,128",
        ["greezlescamp"] = "507,350,256,256",
        ["moongrazewoods"] = "449,183,256,256",
        ["odesyuslanding"] = "352,378,256,256",
        ["podcluster"] = "281,305,256,256",
        ["podwreckage"] = "462,349,128,256",
        ["siltingshore"] = "291,3,256,256",
        ["silvermystisle"] = "23,446,256,222",
        ["stillpinehold"] = "365,49,256,256",
        ["theexodar"] = "74,85,512,512",
        ["valaarsberth"] = "176,303,256,256",
        ["wrathscalepoint"] = "220,421,256,247",
    },
    ["bladesedgemountains"] =
    {
        ["bashirlanding"] = "422,0,256,256",
        ["bladedgulch"] = "623,147,256,256",
        ["bladesiprehold"] = "314,161,256,507",
        ["bloodmaulcamp"] = "412,95,256,256",
        ["bloodmauloutpost"] = "342,371,256,297",
        ["brokenwilds"] = "733,109,256,256",
        ["circleofwrath"] = "439,210,256,256",
        ["deathsdoor"] = "512,249,256,419",
        ["forgecampanger"] = "586,147,416,256",
        ["forgecampterror"] = "144,416,512,252",
        ["forgecampwrath"] = "254,176,256,256",
        ["grishnath"] = "286,28,256,256",
        ["gruulslayer"] = "527,81,256,256",
        ["jaggedridge"] = "446,414,256,254",
        ["moknathalvillage"] = "658,297,256,256",
        ["ravenswood"] = "214,55,512,256",
        ["razorridge"] = "533,332,256,336",
        ["ridgeofmadness"] = "554,258,256,410",
        ["ruuanweald"] = "479,98,256,512",
        ["skald"] = "673,71,256,256",
        ["sylvanaar"] = "289,350,256,318",
        ["thecrystalpine"] = "585,0,256,256",
        ["thunderlordstronghold"] = "405,272,256,396",
        ["veillashh"] = "271,428,256,240",
        ["veilruuan"] = "563,151,256,128",
        ["vekhaarstand"] = "629,406,256,256",
        ["vortexpinnacle"] = "166,206,256,462",
    },
    ["bloodmystisle"] =
    {
        ["amberwebpass"] = "44,62,256,512",
        ["axxarien"] = "297,136,256,256",
        ["blacksiltshore"] = "177,426,512,242",
        ["bladewood"] = "367,209,256,256",
        ["bloodscaleisle"] = "763,256,239,256",
        ["bloodwatch"] = "437,258,256,256",
        ["bristlelimbenclave"] = "546,410,256,256",
        ["kesselscrossing"] = "517,527,485,141",
        ["middenvale"] = "414,406,256,256",
        ["mystwood"] = "309,483,256,185",
        ["nazzivian"] = "250,404,256,256",
        ["ragefeatherridge"] = "481,117,256,256",
        ["ruinsofloretharan"] = "556,216,256,256",
        ["talonstand"] = "657,78,256,256",
        ["telathionscamp"] = "180,216,128,128",
        ["thebloodcursedreef"] = "729,54,256,256",
        ["thebloodwash"] = "302,27,256,256",
        ["thecrimsonreach"] = "555,87,256,256",
        ["thecryocore"] = "293,285,256,256",
        ["thefoulpool"] = "221,136,256,256",
        ["thehiddenreef"] = "205,39,256,256",
        ["thelostfold"] = "503,470,256,198",
        ["thevectorcoil"] = "43,238,512,430",
        ["thewarppiston"] = "451,29,256,256",
        ["veridianpoint"] = "637,0,256,256",
        ["vindicatorsrest"] = "232,242,256,256",
        ["wrathscalelair"] = "598,338,256,256",
        ["wyrmscarisland"] = "613,82,256,256",
    },
    ["eversongwoods"] =
    {
        ["azurebreezecoast"] = "669,228,256,256",
        ["duskwithergrounds"] = "605,253,256,256",
        ["eastsanctum"] = "460,373,256,256",
        ["elrendarfalls"] = "580,399,128,256",
        ["fairbreezevilliage"] = "386,386,256,256",
        ["farstriderretreat"] = "524,359,256,128",
        ["goldenboughpass"] = "243,469,256,128",
        ["lakeelrendar"] = "584,471,128,197",
        ["northsanctum"] = "361,298,256,256",
        ["ruinsofsilvermoon"] = "307,136,256,256",
        ["runestonefalithas"] = "378,496,256,172",
        ["runestoneshandor"] = "464,494,256,174",
        ["satherilshaven"] = "324,384,256,256",
        ["silvermooncity"] = "440,87,512,512",
        ["stillwhisperpond"] = "474,314,256,256",
        ["sunsailanchorage"] = "231,404,256,128",
        ["sunstriderisle"] = "195,5,512,512",
        ["thegoldenstrand"] = "183,415,128,253",
        ["thelivingwood"] = "511,420,128,248",
        ["thescortchedgrove"] = "255,507,256,128",
        ["thuronslivery"] = "539,305,256,128",
        ["torwatha"] = "648,315,256,353",
        ["tranquilshore"] = "215,298,256,256",
        ["westsanctum"] = "292,319,128,256",
        ["zebwatha"] = "554,475,128,193",
    },
    ["ghostlands"] =
    {
        ["amanipass"] = "598,232,404,436",
        ["bleedingziggurat"] = "184,238,256,256",
        ["dawnstarspire"] = "575,0,427,256",
        ["deatholme"] = "95,375,512,293",
        ["elrendarcrossing"] = "326,0,512,256",
        ["farstriderenclave"] = "573,136,429,256",
        ["goldenmistvillage"] = "44,0,512,512",
        ["howlingziggurat"] = "340,219,256,449",
        ["isleoftribulations"] = "585,0,256,256",
        ["sanctumofthemoon"] = "210,126,256,256",
        ["sanctumofthesun"] = "448,150,256,512",
        ["suncrownvillage"] = "460,0,512,256",
        ["thalassiapass"] = "364,406,256,262",
        ["tranquillien"] = "365,2,256,512",
        ["windrunnerspire"] = "40,287,256,256",
        ["windrunnervillage"] = "60,117,256,512",
        ["zebnowa"] = "466,237,512,431",
    },
    ["hellfire"] =
    {
        ["denofhaalesh"] = "182,412,256,256",
        ["expeditionarmory"] = "261,413,512,255",
        ["falconwatch"] = "183,326,512,342",
        ["fallenskyridge"] = "34,142,256,256",
        ["forgecamprage"] = "478,25,512,512",
        ["hellfirecitadel"] = "338,210,256,458",
        ["honorhold"] = "469,298,256,256",
        ["magharpost"] = "206,110,256,256",
        ["poolsofaggonar"] = "326,45,256,512",
        ["ruinsofshanaar"] = "25,290,256,378",
        ["templeoftelhamat"] = "38,152,512,512",
        ["thelegionfront"] = "579,128,256,512",
        ["thestairofdestiny"] = "737,156,256,512",
        ["thrallmar"] = "467,154,256,256",
        ["throneofkiljaeden"] = "477,6,512,256",
        ["voidridge"] = "705,368,256,256",
        ["warpfields"] = "308,408,256,260",
        ["zethgor"] = "580,430,422,238",
    },
    ["nagrand"] =
    {
        ["burningbladeruins"] = "660,334,256,334",
        ["clanwatch"] = "532,363,256,256",
        ["forgecampfear"] = "36,248,512,420",
        ["forgecamphate"] = "162,154,256,256",
        ["garadar"] = "431,143,256,256",
        ["halaa"] = "335,193,256,256",
        ["kilsorrowfortress"] = "558,427,256,241",
        ["laughingskullruins"] = "351,52,256,256",
        ["oshugun"] = "168,334,512,334",
        ["ringoftrials"] = "533,267,256,256",
        ["southwindcleft"] = "391,258,256,256",
        ["sunspringpost"] = "219,199,256,256",
        ["telaar"] = "387,390,256,256",
        ["throneoftheelements"] = "504,53,256,256",
        ["twilightridge"] = "10,107,256,512",
        ["warmaulhill"] = "157,32,256,256",
        ["windyreedpass"] = "598,79,256,256",
        ["windyreedvillage"] = "666,233,256,256",
        ["zangarridge"] = "277,54,256,256",
    },
    ["netherstorm"] =
    {
        ["area52"] = "241,388,256,128",
        ["arklonruins"] = "328,397,256,256",
        ["celestialridge"] = "644,173,256,256",
        ["ecodomefarfield"] = "396,10,256,256",
        ["etheriumstaginggrounds"] = "481,208,256,256",
        ["forgebaseog"] = "237,22,256,256",
        ["kirinvarvillage"] = "490,523,256,145",
        ["manaforgebanar"] = "147,281,256,387",
        ["manaforgecoruu"] = "357,489,256,179",
        ["manaforgeduro"] = "465,336,256,256",
        ["manafrogeara"] = "171,155,256,256",
        ["netherstone"] = "411,20,256,256",
        ["netherstormbridge"] = "132,294,256,256",
        ["ruinedmanaforge"] = "513,138,256,256",
        ["ruinsofenkaat"] = "253,301,256,256",
        ["ruinsoffarahlon"] = "354,49,512,256",
        ["socretharsseat"] = "229,38,256,256",
        ["sunfuryhold"] = "454,451,256,217",
        ["tempestkeep"] = "593,284,409,384",
        ["theheap"] = "239,455,256,213",
        ["thescrapfield"] = "356,261,256,256",
        ["thestormspire"] = "298,134,256,256",
    },
    ["shadowmoonvalley"] =
    {
        ["altarofshatar"] = "520,93,256,256",
        ["coilskarpoint"] = "348,8,512,512",
        ["eclipsepoint"] = "343,310,512,358",
        ["illadarpoint"] = "143,256,256,256",
        ["legionhold"] = "104,155,512,512",
        ["netherwingcliffs"] = "554,308,256,256",
        ["netherwingledge"] = "510,445,492,223",
        ["shadowmoonvilliage"] = "116,35,512,512",
        ["theblacktemple"] = "606,126,396,512",
        ["thedeathforge"] = "290,129,256,512",
        ["thehandofguldan"] = "394,90,512,512",
        ["thewardenscage"] = "469,258,512,410",
        ["wildhammerstronghold"] = "168,229,512,439",
    },
    ["terokkarforest"] =
    {
        ["allerianstronghold"] = "480,277,256,256",
        ["auchenaigrounds"] = "247,434,256,234",
        ["bleedinghollowclanruins"] = "103,301,256,367",
        ["bonechewerruins"] = "521,275,256,256",
        ["carrionhill"] = "377,272,256,256",
        ["cenarionthicket"] = "314,0,256,256",
        ["firewingpoint"] = "617,149,385,512",
        ["grangolvarvilliage"] = "143,171,512,256",
        ["raastokglade"] = "505,154,256,256",
        ["razorthornshelf"] = "478,19,256,256",
        ["refugecaravan"] = "316,268,128,256",
        ["ringofobservance"] = "310,345,256,256",
        ["sethekktomb"] = "245,289,256,256",
        ["shattrathcity"] = "104,4,512,512",
        ["skethylmountains"] = "449,348,512,320",
        ["smolderingcaravan"] = "321,460,256,208",
        ["stonebreakerhold"] = "397,165,256,256",
        ["thebarrierhills"] = "116,4,256,256",
        ["tuurem"] = "455,34,256,512",
        ["veilrhaze"] = "222,362,256,256",
        ["writhingmound"] = "417,327,256,256",
    },
    ["zangarmarsh"] =
    {
        ["angoroshgrounds"] = "88,50,256,256",
        ["angoroshstronghold"] = "124,0,256,128",
        ["bloodscaleenclave"] = "596,412,256,256",
        ["cenarionrefuge"] = "694,321,308,256",
        ["coilfangreservoir"] = "462,90,256,512",
        ["feralfenvillage"] = "314,332,512,336",
        ["marshlightlake"] = "81,152,256,256",
        ["oreborharborage"] = "329,25,256,512",
        ["quaggridge"] = "141,325,256,343",
        ["sporeggar"] = "20,202,512,256",
        ["telredor"] = "569,112,256,512",
        ["thedeadmire"] = "716,128,286,512",
        ["thehewnbog"] = "219,51,256,512",
        ["thelagoon"] = "512,303,256,256",
        ["thespawningglen"] = "31,339,256,256",
        ["twinspireruins"] = "342,249,256,256",
        ["umbrafenvillage"] = "720,461,256,207",
        ["zabrajin"] = "175,232,256,256",
    },

    -- Manually added for patch 2.4
    ["sunwell"] =
    {
        ["sunsreachharbor"] = "252,252,512,416",
        ["sunsreachsanctum"] = "251,4,512,512",
    },

    -- WotLK

    ["scarletenclave"] =
    {
        ["scarletenclave"] = "0,0,1024,768",    -- FIX!!
    },
    ["lakewintergrasp"] = {
        ["lakewintergrasp"] = "0,0,1024,768",
    },
    ["dalaran"] = {
        ["dalaran1_"] = "0,0,1024,768",        -- FIX!!
    },

    ["npe"] = {
        ["npe"] = "0,0,1024,768",        -- FIX!!
    },

    ["boreantundra"] = {
        ["deathsstand"] = "707,181,289,279",
        ["templecityofenkilah"] = "712,15,290,292",
        ["warsongstronghold"] = "329,237,260,278",
        ["riplashstrand"] = "293,383,382,258",
        ["thedensofdying"] = "662,11,203,209",
        ["thegeyserfields"] = "480,0,375,342",
        ["torpsfarm"] = "272,237,186,276",
        ["valiancekeep"] = "457,264,259,302",
        ["garroshslanding"] = "153,238,267,378",
        ["borgorokoutpost"] = "314,0,396,203",
        ["amberledge"] = "325,140,244,214",
        ["kaskala"] = "509,214,385,316",
        ["steeljawscaravan"] = "397,66,244,319",
        ["coldarra"] = "50,0,460,381",
    },
    ["sholazarbasin"] = {
        ["kartakshold"] = "76,375,329,293",
        ["theavalanche"] = "596,92,322,265",
        ["thesavagethicket"] = "396,51,293,229",
        ["thesuntouchedpillar"] = "82,186,455,316",
        ["themakersperch"] = "172,135,249,248",
        ["themakersoverlook"] = "705,236,233,286",
        ["rainspeakercanopy"] = "427,244,207,235",
        ["themosslightpillar"] = "265,355,239,313",
        ["theglimmeringpillar"] = "308,34,294,327",
        ["thelifebloodpillar"] = "501,134,312,369",
        ["thestormwrightsshelf"] = "138,58,268,288",
        ["riversheart"] = "359,339,468,329",
    },
    ["dragonblight"] = {
        ["lightsrest"] = "703,7,299,278",
        ["galakrondsrest"] = "433,118,258,225",
        ["newhearthglen"] = "614,358,214,261",
        ["rubydragonshrine"] = "374,208,188,211",
        ["icemistvillage"] = "134,165,235,337",
        ["venomspite"] = "661,264,226,212",
        ["westwindrefugeecamp"] = "42,187,229,299",
        ["obsidiandragonshrine"] = "256,104,304,203",
        ["naxxramas"] = "691,160,311,272",
        ["wyrmresttemple"] = "453,219,317,353",
        ["scarletpoint"] = "569,7,235,354",
        ["emeralddragonshrine"] = "543,362,196,218",
        ["agmarshammer"] = "258,203,236,218",
        ["theforgottenshore"] = "698,332,301,286",
        ["thecrystalvice"] = "487,0,229,259",
        ["angrathar"] = "210,0,306,242",
        ["lakeindule"] = "217,313,356,300",
        ["coldwindheights"] = "403,0,213,219",
    },
    ["crystalsongforest"] = {
        ["windrunnersoverlook"] = "444,383,558,285",
        ["theunboundthicket"] = "500,105,502,477",
        ["theazurefront"] = "0,244,416,424",
        ["forlornwoods"] = "129,0,544,668",
        ["violetstand"] = "0,176,264,303",
        ["thegreattree"] = "0,91,252,260",
        ["thedecrepitflow"] = "0,0,288,222",
        ["sunreaverscommand"] = "536,40,446,369",
    },
    ["howlingfjord"] = {
        ["scalawagpoint"] = "168,410,350,258",
        ["baleheim"] = "576,170,174,173",
        ["giantsrun"] = "572,0,298,306",
        ["halgrind"] = "397,208,187,263",
        ["utgardekeep"] = "477,216,248,382",
        ["vengeancelanding"] = "664,25,223,338",
        ["nifflevar"] = "595,240,178,208",
        ["emberclutch"] = "283,203,213,256",
        ["ivaldsruin"] = "668,223,193,201",
        ["cauldrosisle"] = "490,161,181,178",
        ["fortwildervar"] = "490,0,251,192",
        ["thetwistedglade"] = "420,57,266,210",
        ["newagamand"] = "415,360,284,308",
        ["baelgunsexcavationsite"] = "621,327,244,305",
        ["apothecarycamp"] = "99,37,263,265",
        ["ancientlift"] = "342,351,177,191",
        ["kamagua"] = "99,278,333,265",
        ["gjalerbron"] = "225,0,242,189",
        ["explorersleagueoutpost"] = "585,336,232,216",
        ["westguardkeep"] = "90,180,347,220",
        ["skorn"] = "343,108,238,232",
        ["campwinterhoof"] = "354,0,223,209",
        ["steelgate"] = "222,100,222,168",
    },
    ["zuldrak"] = {
        ["zeramas"] = "7,412,307,256",
        ["draksotrafields"] = "326,358,286,265",
        ["altarofrhunok"] = "431,127,247,304",
        ["altarofsseratus"] = "288,168,237,248",
        ["kolramas"] = "380,437,302,231",
        ["gundrak"] = "629,0,336,297",
        ["altarofquetzlun"] = "607,251,261,288",
        ["altarofharkoa"] = "533,345,265,257",
        ["lightsbreach"] = "181,363,321,305",
        ["thrymsend"] = "0,247,272,268",
        ["amphitheaterofanguish"] = "289,287,266,254",
        ["voltarus"] = "174,191,218,291",
        ["altarofmamtoth"] = "575,88,291,258",
        ["zimtorga"] = "479,241,249,258",
    },
    ["grizzlyhills"] = {
        ["grizzlemaw"] = "358,187,294,227",
        ["voldrune"] = "176,421,283,247",
        ["conquesthold"] = "17,307,332,294",
        ["dunargol"] = "547,257,455,400",
        ["ragefangshrine"] = "312,294,475,362",
        ["drakiljinruins"] = "607,41,351,284",
        ["venturebay"] = "18,461,274,207",
        ["thormodan"] = "509,0,329,246",
        ["granitesprings"] = "7,207,356,224",
        ["blueskylogginggrounds"] = "232,129,249,235",
        ["draktheronkeep"] = "0,46,382,285",
        ["amberpinelodge"] = "217,244,278,290",
        ["ursocsden"] = "331,32,328,260",
        ["camponeqwah"] = "548,137,324,265",
    },
    ["thestormpeaks"] = {
        ["frosthold"] = "134,429,244,220",
        ["templeofstorms"] = "239,301,169,164",
        ["ulduar"] = "218,0,369,265",
        ["sparksocketminefield"] = "242,468,251,200",
        ["borsbreath"] = "109,375,322,195",
        ["engineofthemakers"] = "316,296,210,179",
        ["garmsbane"] = "395,470,184,191",
        ["dunniffelem"] = "481,285,309,383",
        ["narvirscradle"] = "214,144,180,239",
        ["nidavelir"] = "108,206,221,200",
        ["brunnhildarvillage"] = "339,370,305,298",
        ["snowdriftplains"] = "162,143,205,232",
        ["valkyrion"] = "98,318,228,158",
        ["templeoflife"] = "570,113,182,270",
        ["terraceofthemakers"] = "292,122,363,341",
        ["thunderfall"] = "627,179,306,484",
    },
    ["icecrownglacier"] = {
        ["aldurthar"] = "355,37,373,375",
        ["corprethar"] = "342,392,308,212",
        ["thebombardment"] = "538,181,248,243",
        ["onslaughtharbor"] = "0,167,204,268",
        ["sindragosasfall"] = "626,31,300,343",
        ["thefleshwerks"] = "218,291,219,283",
        ["jotunheim"] = "22,122,393,474",
        ["valleyofechoes"] = "715,390,269,217",
        ["theconflagration"] = "327,305,227,210",
        ["thebrokenfront"] = "558,329,283,231",
        ["scourgeholme"] = "690,267,245,239",
        ["ymirheim"] = "444,276,223,207",
        ["theshadowvault"] = "321,15,223,399",
        ["argenttournamentground"] = "616,30,314,224",
        ["icecrowncitadel"] = "392,466,308,202",
        ["valhalas"] = "217,50,238,240",
    },

    -- Patch 3.2
    ["hrothgarslanding"] =
    {
--        ["hrothgarslanding"] = "0,0,1024,768",
        ["hrothgarslanding2"] = "256,0,256,256,1",    -- Just draw 4 parts
        ["hrothgarslanding3"] = "512,0,256,256,1",
        ["hrothgarslanding6"] = "256,256,256,256,1",
        ["hrothgarslanding7"] = "512,256,256,256,1",
    },

    -- Cataclysm
    ["tolbarad"] = {
        ["tolbarad"] = "0,0,1024,768",            -- Manual
    },
    ["tolbaraddailyarea"] = {
        ["tolbaraddailyarea"] = "0,0,1024,768",        -- Manual
    },

    ["themaelstrom"] = {
        ["themaelstrom"] = "0,0,1024,768",        -- Manual
    },
    ["thelostisles_terrain2"] = {
        ["gallywixdocks"] = "351,21,173,180",
        ["alliancebeachhead"] = "129,348,177,172",
        ["bilgewaterlumberyard"] = "462,43,248,209",
        ["thesavageglen"] = "213,325,231,216",
        ["oostan"] = "492,161,210,258",
        ["raptorrise"] = "416,368,168,205",
        ["warchiefslookout"] = "264,144,159,230",
        ["ooomlotvillage"] = "508,345,221,211",
        ["scorchedgully"] = "323,185,305,288",
        ["ktcoilplatform"] = "433,11,156,142",
        ["hordebasecamp"] = "244,458,222,190",
        ["lostpeak"] = "581,21,350,517",
        ["shipwreckshore"] = "189,408,172,175",
        ["skyfalls"] = "416,131,190,186",
        ["ruinsofvashelan"] = "440,452,212,216",
        ["landingsite"] = "377,359,142,133",
        ["theslavepits"] = "279,68,212,193",
    },
    ["kezan"] = {
        ["bilgewaterport"] = "163,148,694,290",
        ["firstbankofkezan"] = "98,325,376,343",
        ["swindlestreet"] = "317,232,168,213",
        ["theslick"] = "219,108,592,202",
        ["kajamine"] = "586,308,354,360",
        ["kajarofield"] = "383,260,250,307",
        ["gallywixsvilla"] = "0,41,303,452",
        ["kezanmap"] = "0,4,1002,664",
        ["drudgetown"] = "180,367,351,301",
    },
    ["deepholm"] = {
        ["stonehearth"] = "0,314,371,354",
        ["twilightterrace"] = "297,384,237,198",
        ["scouredreach"] = "448,0,516,287",
        ["needlerockchasm"] = "20,0,378,359",
        ["stormsfurywreckage"] = "458,383,292,285",
        ["twilightoverlook"] = "570,420,411,248",
        ["deathwingsfall"] = "549,297,454,343",
        ["thepaleroost"] = "85,0,467,273",
        ["needlerockslag"] = "0,146,370,285",
        ["theshatteredfield"] = "141,438,430,230",
        ["therazanesthrone"] = "434,0,274,156",
        ["crimsonexpanse"] = "540,12,462,400",
        ["templeofearth"] = "287,177,355,345",
    },

    ["moltenfront"] = {
        ["moltenfront"] = "0,0,1024,768",        -- Manual
    },
    -- Pandaria
    ["thejadeforest"] = {
        ["chuntianmonastery"] = "300,56,227,198",
        ["dawnsblossom"] = "325,178,234,210",
        ["dreamerspavillion"] = "474,520,218,148",
        ["emperorsomen"] = "430,21,202,204",
        ["glassfinvillage"] = "525,358,278,310",
        ["grookinmound"] = "182,214,253,229",
        ["hellscreamshope"] = "181,75,196,166",
        ["jademines"] = "400,146,236,142",
        ["nectarbreezeorchard"] = "290,330,219,256",
        ["nookanooka"] = "189,151,219,205",
        ["ruinsofganshi"] = "316,0,196,158",
        ["serpentsspine"] = "388,299,191,216",
        ["slingtailpits"] = "428,416,179,180",
        ["templeofthejadeserpent"] = "468,295,264,211",
        ["thearboretum"] = "481,215,242,210",
        ["waywardlanding"] = "346,482,219,186",
        ["windlessisle"] = "539,43,251,348",
        ["wreckoftheskyshark"] = "202,0,210,158",
    },
    ["dreadwastes"] = {
        ["klaxxivess"] = "458,110,236,204",
        ["zanvess"] = "162,385,290,283",
        ["brewgarden"] = "351,0,250,218",
        ["dreadwaterlake"] = "437,313,322,211",
        ["clutchesofshekzeer"] = "341,125,209,318",
        ["horridmarch"] = "441,224,323,194",
        ["brinymuck"] = "214,311,325,270",
        ["soggysgamble"] = "450,406,268,241",
        ["terraceofgurthan"] = "593,92,209,234",
        ["rikkitunvillage"] = "236,32,218,186",
        ["heartoffear"] = "191,122,262,293",
        ["kyparivor"] = "485,0,325,190",
    },
    ["krasarang"] = {
        ["redwingrefuge"] = "317,63,212,265",
        ["anglersoutpost"] = "545,205,265,194",
        ["templeoftheredcrane"] = "300,215,219,259",
        ["dojaniriver"] = "513,3,190,282",
        ["krasarangcove"] = "701,19,286,268",
        ["thedeepwild"] = "397,59,188,412",
        ["lostdynasty"] = "589,27,217,279",
        ["fallsongriver"] = "218,77,214,393",
        ["thesouthernisles"] = "23,267,252,313",
        ["zhusbastion"] = "612,0,306,204",
        ["ruinsofdojan"] = "444,44,204,383",
        ["theforbiddenjungle"] = "0,79,257,300",
        ["ruinsofkorja"] = "125,88,211,395",
        ["cradleofchiji"] = "176,376,272,250",
        ["ungaingoo"] = "330,498,258,170",
        ["nayelilagoon"] = "343,373,246,240",
    },
    ["krasarang_terrain1"] = {
        ["redwingrefuge"] = "317,63,212,265",
        ["anglersoutpost"] = "545,205,265,194",
        ["templeoftheredcrane"] = "300,215,219,259",
        ["dojaniriver"] = "513,3,190,282",
        ["krasarangcove"] = "701,19,295,293",
        ["thedeepwild"] = "397,59,188,412",
        ["lostdynasty"] = "589,27,217,279",
        ["fallsongriver"] = "218,77,214,393",
        ["thesouthernisles"] = "0,267,275,329",
        ["zhusbastion"] = "612,0,306,204",
        ["ruinsofdojan"] = "444,44,204,383",
        ["theforbiddenjungle"] = "0,79,257,300",
        ["ruinsofkorja"] = "125,88,211,395",
        ["cradleofchiji"] = "176,376,272,250",
        ["ungaingoo"] = "330,498,258,170",
        ["nayelilagoon"] = "343,373,246,240",
    },
    ["kunlaisummit"] = {
        ["binanvillage"] = "607,470,240,198",
        ["mogujia"] = "462,411,253,208",
        ["muskpawranch"] = "603,313,229,262",
        ["mountneverset"] = "228,264,313,208",
        ["zouchinvillage"] = "502,64,298,219",
        ["templeofthewhitetiger"] = "587,170,250,260",
        ["gateoftheaugust"] = "449,506,261,162",
        ["shadopanmonastery"] = "88,92,385,385",
        ["theburlaptrail"] = "398,310,310,276",
        ["peakofserenity"] = "333,63,287,277",
        ["valleyofemperors"] = "453,191,224,241",
        ["kotapeak"] = "233,360,252,257",
        ["iseoflostsouls"] = "602,4,259,233",
        ["fireboughnook"] = "322,496,224,172",
    },
    ["valeofeternalblossoms"] = {
        ["guolairuins"] = "87,3,337,349",
        ["whitemoonshrine"] = "482,10,298,262",
        ["mistfallvillage"] = "200,363,310,305",
        ["settingsuntraining"] = "0,234,350,429",
        ["tushenburialground"] = "349,316,267,308",
        ["thestairsascent"] = "556,267,446,359",
        ["winterboughglade"] = "4,107,361,333",
        ["thegoldenstair"] = "328,16,242,254",
        ["whitepetallake"] = "278,170,267,281",
        ["thetwinmonoliths"] = "444,97,272,522",
        ["mogushanpalace"] = "629,22,373,385",
    },
    ["valleyofthefourwinds"] = {
        ["thunderfootfields"] = "622,0,380,317",
        ["poolsofpurity"] = "513,58,213,246",
        ["rumblingterrace"] = "582,301,277,245",
        ["paoquanhollow"] = "12,105,273,246",
        ["stormsoutbrewery"] = "227,380,257,288",
        ["dustbackgorge"] = "0,343,209,308",
        ["cliffsofdispair"] = "215,404,510,264",
        ["theheartland"] = "253,75,286,392",
        ["silkenfields"] = "530,253,254,259",
        ["harvesthome"] = "5,239,260,251",
        ["gildedfan"] = "438,41,208,292",
        ["grandgranery"] = "334,325,314,212",
        ["singingmarshes"] = "170,130,175,291",
        ["zhusdecent"] = "699,114,303,323",
        ["halfhill"] = "438,177,206,245",
        ["nesingwarysafari"] = "104,326,249,342",
        ["mudmugsplace"] = "561,161,230,217",
        ["kuzenvillage"] = "224,74,199,304",
    },
    ["townlongwastes"] = {
        ["niuzaotemple"] = "213,241,296,359",
        ["shanzedao"] = "125,0,300,246",
        ["thesumprushes"] = "545,369,271,205",
        ["sikvess"] = "306,433,261,235",
        ["gaoranblockade"] = "546,468,353,200",
        ["mingchicrossroads"] = "417,447,247,221",
        ["palewindvillage"] = "692,362,282,306",
        ["osulmesa"] = "560,185,238,296",
        ["shadopangarrison"] = "413,385,213,170",
        ["krivess"] = "420,209,255,269",
        ["srivess"] = "92,192,294,283",
    },
    ["thewanderingisle"] = {
        ["thedawningvalley"] = "325,0,677,667",
        ["templeoffivedawns"] = "395,182,607,461",
        ["mandorivillage"] = "392,294,610,374",
        ["ridgeoflaughingwinds"] = "183,198,313,321",
        ["pei-wuforest"] = "351,406,651,262",
        ["poolofthepaw"] = "297,324,220,188",
        ["skyfirecrash-site"] = "124,405,346,263",
        ["therows"] = "504,295,385,373",
        ["thesingingpools"] = "545,12,372,475",
        ["morningbreezevillage"] = "203,36,261,315",
        ["fe-fangvillage"] = "134,9,234,286",
        ["thewoodofstaves"] = "13,202,989,466",
    },
    ["darkmoonfaireisland"] = {
        ["darkmoonfaireisland"] = "0,0,1024,768",
    },
    ["thehiddenpass"] = {
        ["thehiddencliffs"] = "443,0,294,220",
        ["theblackmarket"] = "371,175,479,493",
        ["thehiddensteps"] = "412,477,290,191",
    },

    ["isleofgiants"] = {
        ["isleofgiants"] = "0,0,1024,768",        -- Manual
    },
    ["timelessisle"] = {
        ["timelessisle"] = "0,0,1024,768",
    },
    ["isleofthethunderking"] = {
        ["isleofthethunderking"] = "0,0,1024,768",    -- Manual
        --["dynamic"] = "0,0,0,0",
    },

    -- Draenor

    ["ashranhordefactionhub"] = {        -- 1011
        ["ashranhordefactionhub"] = "0,0,1024,768",
    },
    ["ashranalliancefactionhub"] = {    -- 1009
        ["ashranalliancefactionhub"] = "0,0,1024,768",
    },
    ["ashran"] = {                -- 978
        ["ashran"] = "0,0,1024,768",
    },
    ["frostfireridge"] = {            -- 941
        ["bladespirefortress"] = "38,117,356,303",
        ["bloodmaulstronghold"] = "311,4,258,217",
        ["bonesofagurak"] = "729,319,273,349",
        ["daggermawravine"] = "284,91,255,191",
        ["frostwinddunes"] = "121,0,274,214",
        ["grimfrosthill"] = "597,210,178,203",
        ["grombolash"] = "483,33,217,239",
        ["gromgar"] = "505,323,282,341",
        ["hordegarrison"] = "336,327,267,257",
        ["ironsiegeworks"] = "673,156,329,294",
        ["ironwaystation"] = "641,304,199,335",
        ["magnarok"] = "609,33,213,278",
        ["nogarrison"] = "336,327,267,257",
        ["stonefangoutpost"] = "306,281,251,191",
        ["theboneslag"] = "290,192,256,210",
        ["thecracklingplains"] = "439,137,266,293",
        ["worgol"] = "72,292,317,233",
    },
    ["garrisonffhorde_tier1"] = {        -- Horde Garrison Tier 1
        ["garrisonffhorde_tier1"] = "0,0,1024,768",
    },
    ["garrisonffhorde_tier2"] = {        -- Horde Garrison Tier 2
        ["garrisonffhorde_tier2"] = "0,0,1024,768",
    },
    ["garrisonffhorde_tier3"] = {        -- Horde Garrison Tier 3
        ["garrisonffhorde_tier3"] = "0,0,1024,768",
    },
    ["garrisonsmvalliance_tier1"] = {    -- Alliance Garrison Tier 1
        ["garrisonsmvalliance_tier1"] = "0,0,1024,768",
    },
    ["garrisonsmvalliance_tier2"] = {    -- Alliance Garrison Tier 2
        ["garrisonsmvalliance_tier2"] = "0,0,1024,768",
    },
    ["garrisonsmvalliance_tier3"] = {    -- Alliance Garrison Tier 3
        ["garrisonsmvalliance_tier3"] = "0,0,1024,768",
    },
    ["gorgrond"] = {            -- 949
        ["bastionrise"] = "283,507,324,161",
        ["beastwatch"] = "383,371,166,161",
        ["easternruin"] = "525,260,210,193",
        ["evermorn"] = "281,444,297,181",
        ["foundry"] = "455,74,211,221",
        ["foundrysouth"] = "454,183,217,180",
        ["gronncanyon"] = "258,213,279,241",
        ["highlandpass"] = "547,73,285,323",
        ["highpass"] = "411,250,209,225",
        ["irondocks"] = "350,0,315,180",
        ["mushrooms"] = "444,323,253,198",
        ["stonemaularena"] = "259,335,217,178",
        ["stonemaulsouth"] = "275,416,208,142",
        ["stripmine"] = "312,77,250,232",
        ["tangleheart"] = "451,372,262,221",
    },
    ["nagranddraenor"] = {            -- 950
        ["ancestral"] = "239,259,234,191",
        ["brokenprecipice"] = "256,12,305,227",
        ["elementals"] = "588,0,286,274",
        ["grommashar"] = "600,367,256,301",
        ["hallvalor"] = "766,118,236,372",
        ["highmaul"] = "0,0,471,437",
        ["ironfistharbor"] = "283,354,236,242",
        ["lokrath"] = "382,187,316,221",
        ["margoks"] = "753,380,249,288",
        ["mushrooms"] = "746,25,250,287",
        ["oshugun"] = "366,323,262,266",
        ["ringofblood"] = "430,0,263,287",
        ["ringoftrials"] = "523,159,354,315",
        ["sunspringwatch"] = "312,98,274,254",
        ["telaar"] = "461,353,296,272",
    },
    ["spiresofarak"] = {            -- 948
        ["bloodbladeredoubt"] = "334,210,209,154",
        ["bloodmanevalley"] = "410,350,229,246",
        ["centerravennest"] = "444,255,188,190",
        ["clutchpop"] = "533,382,217,224",
        ["eastmushrooms"] = "649,155,182,244",
        ["emptygarrison"] = "282,261,190,187",
        ["howlingcrag"] = "459,0,382,274",
        ["nwcorner"] = "102,0,314,304",
        ["sethekkhollow"] = "520,127,238,295",
        ["skettis"] = "289,0,371,174",
        ["solospirenorth"] = "429,84,196,284",
        ["solospiresouth"] = "374,276,169,178",
        ["southport"] = "310,328,197,179",
        ["veilakraz"] = "281,83,252,230",
        ["veilzekk"] = "521,268,198,232",
        ["venturecove"] = "465,475,226,193",
        ["writhingmire"] = "197,198,229,213",
    },
    ["shadowmoonvalleydr"] = {        -- 947
        ["anguishfortress"] = "140,160,309,264",
        ["darktideroost"] = "468,467,282,201",
        ["elodor"] = "426,0,291,266",
        ["embaari"] = "270,158,346,252",
        ["garrison"] = "194,0,223,279",
        ["gloomshade"] = "319,5,229,240",
        ["gulvar"] = "26,0,260,309",
        ["karabor"] = "537,150,393,318",
        ["nogarrison"] = "194,0,223,279",
        ["shazgul"] = "259,315,282,225",
        ["shimmeringmoor"] = "453,306,288,261",
        ["socrethar"] = "383,411,202,201",
        ["swisland"] = "309,460,173,160",
    },
    ["talador"] = {                -- 946
        ["aruuna"] = "597,178,389,234",
        ["auchindoun"] = "338,356,309,262",
        ["centerisles"] = "546,228,252,280",
        ["courtofsouls"] = "150,264,307,229",
        ["fortwrynn"] = "567,42,292,235",
        ["gordalfortress"] = "548,378,423,290",
        ["gulrok"] = "165,364,278,270",
        ["northgate"] = "571,0,398,149",
        ["orunaicoast"] = "427,0,279,267",
        ["seentrance"] = "685,298,308,276",
        ["shattrath"] = "173,22,406,367",
        ["telmor"] = "207,511,497,157",
        ["tomboflights"] = "352,271,326,212",
        ["tuurem"] = "472,148,225,224",
        ["zangarra"] = "713,35,287,277",
    },
    ["TanaanJungle"] = {            -- 945
        ["darkportal"] = "637,136,333,437",
        ["draeneisw"] = "81,367,174,208",
        ["fangrila"] = "429,392,343,264",
        ["felforge"] = "392,187,223,183",
        ["ironfront"] = "0,264,209,245",
        ["ironharbor"] = "303,62,189,294",
        ["kiljaeden"] = "392,23,365,276",
        ["kranak"] = "54,94,338,254",
        ["lionswatch"] = "465,313,270,208",
        ["marshlands"] = "296,383,246,218",
        ["shanaar"] = "170,354,248,314",
        ["volmar"] = "501,171,238,229",
        ["zethgol"] = "118,194,274,251",
        ["hellfirecitadel"] = "254,262,327,241",
    },
    ["tanaanjungleintro"] = {        -- 970
        ["tanaanjungleintro"] = "0,0,1024,768",
    },
    ["azsuna"] = {
        ["faronaar"] = "166,202,330,265",
        ["felblaze"] = "594,0,239,303",
        ["greenway"] = "450,95,247,184",
        ["isleofthewatchers"] = "281,401,321,267",
        ["llothienhighlands"] = "219,69,351,245",
        ["lostorchard"] = "257,0,315,185",
        ["narthalas"] = "441,173,272,192",
        ["oceanuscove"] = "396,244,206,266",
        ["ruinedsanctum"] = "523,233,220,288",
        ["templelights"] = "481,340,181,243",
        ["zarkhenar"] = "477,0,288,195",
    },
    ["stormheim"] = {
        ["aggrammarsvault"] = "361,210,199,185",
        ["blackbeakoverlook"] = "154,129,297,210",
        ["dreadwake"] = "457,412,215,247",
        ["dreyrgrot"] = "689,266,132,145",
        ["greywatch"] = "648,339,173,163",
        ["hallsofvalor"] = "585,372,252,280",
        ["haustvald"] = "612,187,200,174",
        ["hrydshal"] = "0,353,631,315",
        ["mawofnashal"] = "17,0,509,251",
        ["morheim"] = "741,313,150,180",
        ["nastrondir"] = "345,95,241,194",
        ["qatchmansrock"] = "623,81,135,162",
        ["runewood"] = "592,226,194,214",
        ["shieldsrest"] = "689,0,289,172",
        ["skoldashil"] = "506,345,177,169",
        ["stormsreach"] = "510,118,180,160",
        ["talonrest"] = "316,282,291,208",
        ["tideskornharbor"] = "479,183,205,199",
        ["valdisdall"] = "522,288,186,158",
        ["weepingbluffs"] = "56,185,386,314",
    },
    ["valsharah"] = {
        ["andutalah"] = "587,250,241,240",
        ["blackrookhold"] = "262,175,250,253",
        ["bradensbrook"] = "259,275,311,244",
        ["dreamgrove"] = "283,0,294,364",
        ["gloamingreef"] = "136,274,239,301",
        ["groveofcenarius"] = "457,351,171,150",
        ["lorlathil"] = "467,413,177,156",
        ["mistvale"] = "610,18,274,344",
        ["moonclawvale"] = "549,380,254,281",
        ["shalanir"] = "419,0,326,360",
        ["smolderhide"] = "324,480,341,188",
        ["templeofelune"] = "459,240,216,219",
        ["thastalah"] = "342,416,218,168",
    },
    ["brokenshore"] = {
        ["brokenvalley"] = "254,84,338,322",
        ["deadwoodlanding"] = "220,260,182,245",
        ["deliverancepoint"] = "312,302,387,314",
        ["felragestrand"] = "596,100,332,276",
        ["soulruin"] = "389,180,338,270",
        ["thelosttemple"] = "632,169,308,244",
        ["theweepingterrace"] = "350,13,276,213",
        ["tombofsargeras"] = "500,0,312,301",
    },
    ["highmountain"] = {
        ["bloodhunthighlands"] = "307,75,297,250",
        ["feltotem"] = "172,31,256,326",
        ["frosthoofwatch"] = "391,408,186,213",
        ["ironhornenclave"] = "452,410,288,258",
        ["nightwatchersperch"] = "0,244,344,295",
        ["pinerockbasin"] = "323,249,217,148",
        ["riverbend"] = "314,360,214,308",
        ["rockawayshallows"] = "469,45,207,302",
        ["shipwreckcove"] = "331,0,283,170",
        ["skyhorn"] = "357,179,311,229",
        ["stonehoofwatch"] = "494,236,341,328",
        ["sylvanfalls"] = "0,342,445,326",
        ["thundertotem"] = "332,302,244,199",
        ["trueshotlodge"] = "249,236,172,204",
        ["cavea"] = "445,190,110,98",
    },
    ["suramar"] = {
        ["ambervale"] = "132,179,222,311",
        ["crimsonthicket"] = "492,0,327,381",
        ["falanaar"] = "23,136,248,317",
        ["felsoulhold"] = "183,305,289,363",
        ["grandpromenade"] = "344,285,355,291",
        ["jandvik"] = "583,0,419,538",
        ["moonguardstronghold"] = "58,0,480,245",
        ["moonwhispergulch"] = "201,0,428,316",
        ["ruinsofeluneeth"] = "264,226,221,224",
        ["suramarcity"] = "390,331,470,337",
        ["telanor"] = "327,0,387,372",
    },
    ["mardumtheshatteredabyss"] = {
        ["mardumtheshatteredabyss"] = "0,0,1024,768",
    },
    ["argussurface"] = {
        ["annihilanpits"] = "371,178,296,336",
        ["krokulhovel"] = "428,364,307,304",
        ["nathraxas"] = "167,0,835,422",
        ["petrifiedforest"] = "557,289,445,379",
        ["shatteredfields"] = "37,138,498,530",
    },
    ["argusmacaree"] = {
        ["conservatory"] = "498,111,313,353",
        ["ruinsoforonaar"] = "278,284,265,310",
        ["seatoftriumvirate"] = "265,54,463,519",
        ["shadowguard"] = "0,0,498,461",
        ["triumvirates"] = "410,375,284,264",
        ["upperterrace"] = "0,0,701,323",
    },
    ["arguscore"] = {
        ["defiledpath"] = "293,0,626,385",
        ["felfirearmory"] = "0,0,660,668",
        ["terminus"] = "535,238,467,430",
    },

    -- BfA

    ["threatvaleofeternalblossoms"] =
    {
        ["threatvaleofeternalblossoms1"] = "0,0,256,256,1",
        ["threatvaleofeternalblossoms2"] = "256,0,256,256,1",
        ["threatvaleofeternalblossoms3"] = "512,0,256,256,1",
        ["threatvaleofeternalblossoms4"] = "768,0,256,256,1",

        ["threatvaleofeternalblossoms5"] = "0,256,256,256,1",
        ["threatvaleofeternalblossoms6"] = "256,256,256,256,1",
        ["threatvaleofeternalblossoms7"] = "512,256,256,256,1",
        ["threatvaleofeternalblossoms8"] = "768,256,256,256,1",

        ["threatvaleofeternalblossoms9"] = "0,512,256,256,1",
        ["threatvaleofeternalblossoms10"] = "256,512,256,256,1",
        ["threatvaleofeternalblossoms11"] = "512,512,256,256,1",
        ["threatvaleofeternalblossoms12"] = "768,512,256,256,1",
    },


    ["zuldazar"] = {
        ["2034162,2034173,2034184,2034195,2034206,2034207,2034208,2034209,2034210,2034163,2034164,2034165,2034166,2034167,2034168,2034169,2034170,2034171,2034172,2034174,2034175,2034176,2034177,2034178,2034179,2034180,2034181,2034182,2034183,2034185,2034186,2034187,2034188,2034189,2034190,2034191,2034192,2034193,2034194,2034196,2034197,2034198,2034199,2034200,2034201,2034202,2034203,2034204,2034205,6238761,6238762,6238763,6238764,6238765,6238766,6238767,6238768,6238769,6238770,6238771,6238772,6238773,6238774,6238775"] = "119,378,1852,1885", -- ataldazar|3946|8x8
        ["2034211,2034215,2034216,2034217,2034218,2034219,2034220,2034221,2034222,2034212,2034213,2034214"] = "2685,633,793,668", -- atalgral|3947|4x3
        ["2034223,2034230,2034231,2034232,2034233,2034234,2034235,2034236,2034237,2034224,2034225,2034226,2034227,2034228,2034229"] = "1357,0,1130,672", -- bloodgate|3948|5x3
        ["2034238,2034245,2034246,2034247,2034248,2034249,2034250,2034251,2034252,2034239,2034240,2034241,2034242,2034243,2034244"] = "1815,260,699,1207", -- dazaralor|3949|3x5
        ["2034253,2034261,2034262,2034263,2034264,2034265,2034266,2034267,2034268,2034254,2034255,2034256,2034257,2034258,2034259,2034260"] = "2325,1270,934,830", -- dreadpearl|3950|4x4
        ["2034269,2034280,2034286,2034287,2034288,2034289,2034290,2034291,2034292,2034270,2034271,2034272,2034273,2034274,2034275,2034276,2034277,2034278,2034279,2034281,2034282,2034283,2034284,2034285"] = "1312,82,888,1512", -- kingsmouth|3951|4x6
        ["2034293,2034304,2034314,2034315,2034316,2034317,2034318,2034319,2034320,2034294,2034295,2034296,2034297,2034298,2034299,2034300,2034301,2034302,2034303,2034305,2034306,2034307,2034308,2034309,2034310,2034311,2034312,2034313"] = "2144,0,943,1559", -- savagelands|3952|4x7
        ["2034321,2034329,2034330,2034331,2034332,2034333,2034334,2034335,2034336,2034322,2034323,2034324,2034325,2034326,2034327,2034328"] = "2107,327,769,967", -- sliver|3953|4x4
        ["2034337,2034348,2034354,2034355,2034356,2034357,2034358,2034359,2034360,2034338,2034339,2034340,2034341,2034342,2034343,2034344,2034345,2034346,2034347,2034349,2034350,2034351,2034352,2034353"] = "1825,1216,999,1344", -- southdocks|3954|4x6
        ["2034361,2034362,2034363,2034364,2034365,2034366,2034367,2034368,2034369"] = "2631,1023,726,617", -- talanji|3955|3x3
        ["2034370,2034381,2034392,2034394,2034395,2034396,2034397,2034398,2034399,2034371,2034372,2034373,2034374,2034375,2034376,2034377,2034378,2034379,2034380,2034382,2034383,2034384,2034385,2034386,2034387,2034388,2034389,2034390,2034391,2034393"] = "1046,1273,1243,1287", -- xibala|3956|5x6
        ["2034400,2034408,2034409,2034410,2034411,2034412,2034413,2034414,2034415,2034401,2034402,2034403,2034404,2034405,2034406,2034407"] = "2409,0,979,912", -- zebhari|3957|4x4
    },

    ["nazmir"] = {
        ["2023693,2023704,2023706,2023707,2023708,2023709,2023710,2023711,2023712,2023694,2023695,2023696,2023697,2023698,2023699,2023700,2023701,2023702,2023703,2023705"] = "2349,871,1098,996", -- frogmarsh|3887|5x4
        ["2023713,2023721,2023722,2023723,2023724,2023725,2023726,2023727,2023728,2023714,2023715,2023716,2023717,2023718,2023719,2023720"] = "1511,1043,800,991", -- heartofdarkness|3888|4x4
        ["2023868,2023879,2023886,2023887,2023888,2023889,2023890,2023891,2023892,2023869,2023870,2023871,2023872,2023873,2023874,2023875,2023876,2023877,2023878,2023880,2023881,2023882,2023883,2023884,2023885"] = "2309,210,1065,1103", -- nazwatha|3889|5x5
        ["2023893,2023904,2023915,2023917,2023918,2023919,2023920,2023921,2023922,2023894,2023895,2023896,2023897,2023898,2023899,2023900,2023901,2023902,2023903,2023905,2023906,2023907,2023908,2023909,2023910,2023911,2023912,2023913,2023914,2023916"] = "1097,281,1534,1119", -- necropolis|3890|6x5
        ["2023923,2023934,2023936,2023937,2023938,2023939,2023940,2023941,2023942,2023924,2023925,2023926,2023927,2023928,2023929,2023930,2023931,2023932,2023933,2023935"] = "484,1539,1157,967", -- primalwetlands|3891|5x4
        ["2023943,2023954,2023960,2023961,2023962,2023963,2023964,2023965,2023966,2023944,2023945,2023946,2023947,2023948,2023949,2023950,2023951,2023952,2023953,2023955,2023956,2023957,2023958,2023959"] = "1072,1676,1289,809", -- rivermarsh|3892|6x4
        ["2023967,2023978,2023989,2023991,2023992,2023993,2023994,2023995,2023996,2023968,2023969,2023970,2023971,2023972,2023973,2023974,2023975,2023976,2023977,2023979,2023980,2023981,2023982,2023983,2023984,2023985,2023986,2023987,2023988,2023990"] = "1682,0,1349,1029", -- torgasrest|3893|6x5
        ["2023997,2024008,2024010,2024011,2024012,2024013,2024014,2024015,2024016,2023998,2023999,2024000,2024001,2024002,2024003,2024004,2024005,2024006,2024007,2024009"] = "1807,1043,841,1075", -- zalamak|3894|4x5
        ["2024017,2024028,2024035,2024036,2024037,2024038,2024039,2024040,2024041,2024018,2024019,2024020,2024021,2024022,2024023,2024024,2024025,2024026,2024027,2024029,2024030,2024031,2024032,2024033,2024034"] = "620,565,1225,1249", -- zalamar|3895|5x5
        ["2024042,2024043,2024044,2024045,2024046,2024047,2024048,2024049,2024050"] = "1298,1561,534,709", -- zuljan|4071|3x3
    },

    ["voldun"] = {
        ["2033821,2033832,2033838,2033839,2033840,2033841,2033842,2033843,2033844,2033822,2033823,2033824,2033825,2033826,2033827,2033828,2033829,2033830,2033831,2033833,2033834,2033835,2033836,2033837"] = "1469,1684,1287,876", -- akunda|3933|6x4
        ["2033845,2033856,2033858,2033859,2033860,2033861,2033862,2033863,2033864,2033846,2033847,2033848,2033849,2033850,2033851,2033852,2033853,2033854,2033855,2033857"] = "1569,1281,1139,822", -- atulaman|3934|5x4
        ["2033865,2033869,2033870,2033871,2033872,2033873,2033874,2033875,2033876,2033866,2033867,2033868"] = "1316,895,849,672", -- centerdesert|3935|4x3
        ["2033877,2033881,2033882,2033883,2033884,2033885,2033886,2033887,2033888,2033878,2033879,2033880"] = "2063,517,913,727", -- eastcoast|3936|4x3
        ["2033889,2033897,2033898,2033899,2033900,2033901,2033902,2033903,2033904,2033890,2033891,2033892,2033893,2033894,2033895,2033896"] = "1880,859,969,835", -- eastdesert|3937|4x4
        ["2033905,2033909,2033910,2033911,2033912,2033913,2033914,2033915,2033916,2033906,2033907,2033908"] = "807,1801,926,688", -- portzemlan|3938|4x3
        ["2033917,2033925,2033926,2033927,2033928,2033929,2033930,2033931,2033932,2033918,2033919,2033920,2033921,2033922,2033923,2033924"] = "1006,341,881,897", -- shatterstone|3939|4x4
        ["2033933,2033941,2033942,2033943,2033944,2033945,2033946,2033947,2033948,2033934,2033935,2033936,2033937,2033938,2033939,2033940"] = "1579,220,915,966", -- slithering|3940|4x4
        ["2033949,2033953,2033954,2033955,2033956,2033957,2033958,2033959,2033960,2033950,2033951,2033952"] = "1362,2018,794,542", -- southcoast|3941|4x3
        ["2033961,2033965,2033966,2033967,2033968,2033969,2033970,2033971,2033972,2033962,2033963,2033964"] = "1180,1255,666,856", -- southerndesert|3942|3x4
        ["2033973,2033981,2033982,2033983,2033984,2033985,2033986,2033987,2033988,2033974,2033975,2033976,2033977,2033978,2033979,2033980"] = "739,1332,769,816", -- swcoast|3943|4x4
        ["2033989,2033996,2033997,2033998,2033999,2034000,2034001,2034002,2034003,2033990,2033991,2033992,2033993,2033994,2033995"] = "576,902,1086,703", -- terracedevoted|3944|5x3
        ["2034004,2034015,2034017,2034018,2034019,2034020,2034021,2034022,2034023,2034005,2034006,2034007,2034008,2034009,2034010,2034011,2034012,2034013,2034014,2034016"] = "1733,0,1223,843", -- tortanka|3945|5x4
    },

    ["tiragarde"] = {
        ["2033457,2033465,2033466,2033467,2033468,2033469,2033470,2033471,2033472,2033458,2033459,2033460,2033461,2033462,2033463,2033464"] = "1108,451,859,788", -- anglepoint|3905|4x4
        ["2033473,2033484,2033490,2033491,2033492,2033493,2033494,2033495,2033496,2033474,2033475,2033476,2033477,2033478,2033479,2033480,2033481,2033482,2033483,2033485,2033486,2033487,2033488,2033489"] = "2117,332,1432,1009", -- boralus|3922|6x4
        ["2033497,2033508,2033518,2033519,2033520,2033521,2033522,2033523,2033524,2033498,2033499,2033500,2033501,2033502,2033503,2033504,2033505,2033506,2033507,2033509,2033510,2033511,2033512,2033513,2033514,2033515,2033516,2033517"] = "1806,0,1777,900", -- fernwood|3924|7x4
        ["2033525,2033536,2033538,2033539,2033540,2033541,2033542,2033543,2033544,2033526,2033527,2033528,2033529,2033530,2033531,2033532,2033533,2033534,2033535,2033537"] = "2314,1739,1047,821", -- freehold|3925|5x4
        ["2033545,2033556,2033562,2033563,2033564,2033565,2033566,2033567,2033568,2033546,2033547,2033548,2033549,2033550,2033551,2033552,2033553,2033554,2033555,2033557,2033558,2033559,2033560,2033561"] = "1538,176,908,1284", -- norwington|3926|4x6
        ["2033569,2033577,2033578,2033579,2033580,2033581,2033582,2033583,2033584,2033570,2033571,2033572,2033573,2033574,2033575,2033576"] = "766,100,828,899", -- nwport|3927|4x4
        ["2033585,2033596,2033598,2033599,2033600,2033601,2033602,2033603,2033604,2033586,2033587,2033588,2033589,2033590,2033591,2033592,2033593,2033594,2033595,2033597"] = "2054,995,978,1171", -- rustedvault|3928|4x5
        ["2033605,2033616,2033618,2033619,2033620,2033621,2033622,2033623,2033624,2033606,2033607,2033608,2033609,2033610,2033611,2033612,2033613,2033614,2033615,2033617"] = "2451,1035,1242,944", -- seabove|3929|5x4
        ["2033625,2033636,2033638,2033639,2033640,2033641,2033642,2033643,2033644,2033626,2033627,2033628,2033629,2033630,2033631,2033632,2033633,2033634,2033635,2033637"] = "2852,1503,891,1057", -- secorner|3930|4x5
        ["2033783,2033794,2033796,2033797,2033798,2033799,2033800,2033801,2033802,2033784,2033785,2033786,2033787,2033788,2033789,2033790,2033791,2033792,2033793,2033795"] = "1772,1199,953,1223", -- vigilhill|3931|4x5
        ["2033803,2033813,2033814,2033815,2033816,2033817,2033818,2033819,2033820,2033804,2033805,2033806,2033807,2033808,2033809,2033810,2033811,2033812"] = "802,0,1306,678", -- waningglacier|3932|6x3
    },

    ["drustvar"] = {
        ["2037789,2037800,2037811,2037813,2037814,2037815,2037816,2037817,2037818,2037790,2037791,2037792,2037793,2037794,2037795,2037796,2037797,2037798,2037799,2037801,2037802,2037803,2037804,2037805,2037806,2037807,2037808,2037809,2037810,2037812"] = "933,863,1188,1421", -- aromsstand|3958|5x6
        ["2037819,2037830,2037832,2037833,2037834,2037835,2037836,2037837,2037838,2037820,2037821,2037822,2037823,2037824,2037825,2037826,2037827,2037828,2037829,2037831"] = "1812,760,1125,880", -- barrowknoll|3959|5x4
        ["2037839,2037850,2037857,2037858,2037859,2037860,2037861,2037862,2037863,2037840,2037841,2037842,2037843,2037844,2037845,2037846,2037847,2037848,2037849,2037851,2037852,2037853,2037854,2037855,2037856"] = "1839,0,1154,1059", -- carverharbor|3960|5x5
        ["2037864,2037875,2037877,2037878,2037879,2037880,2037881,2037882,2037883,2037865,2037866,2037867,2037868,2037869,2037870,2037871,2037872,2037873,2037874,2037876"] = "388,570,1239,839", -- corlain|3961|5x4
        ["2037884,2037895,2037902,2037903,2037904,2037905,2037906,2037907,2037908,2037885,2037886,2037887,2037888,2037889,2037890,2037891,2037892,2037893,2037894,2037896,2037897,2037898,2037899,2037900,2037901"] = "377,939,1139,1154", -- crimsonforest|3962|5x5
        ["2038047,2038058,2038060,2038061,2038062,2038063,2038064,2038065,2038066,2038048,2038049,2038050,2038051,2038052,2038053,2038054,2038055,2038056,2038057,2038059"] = "1644,361,948,1081", -- fallhaven|3963|4x5
        ["2038067,2038078,2038080,2038081,2038082,2038083,2038084,2038085,2038086,2038068,2038069,2038070,2038071,2038072,2038073,2038074,2038075,2038076,2038077,2038079"] = "2386,1049,770,1181", -- fletcherhollow|3964|4x5
        ["2038087,2038098,2038105,2038106,2038107,2038108,2038109,2038110,2038111,2038088,2038089,2038090,2038091,2038092,2038093,2038094,2038095,2038096,2038097,2038099,2038100,2038101,2038102,2038103,2038104"] = "1847,1025,1090,1169", -- golkoval|3965|5x5
        ["2038112,2038123,2038130,2038131,2038132,2038133,2038134,2038135,2038136,2038113,2038114,2038115,2038116,2038117,2038118,2038119,2038120,2038121,2038122,2038124,2038125,2038126,2038127,2038128,2038129"] = "1261,0,1079,1204", -- northmtns|3966|5x5
        ["2038137,2038148,2038154,2038155,2038156,2038157,2038158,2038159,2038160,2038138,2038139,2038140,2038141,2038142,2038143,2038144,2038145,2038146,2038147,2038149,2038150,2038151,2038152,2038153"] = "0,0,1373,1010", -- nwisland|3967|6x4
        ["2038161,2038172,2038183,2038191,2038192,2038193,2038194,2038195,2038196,2038162,2038163,2038164,2038165,2038166,2038167,2038168,2038169,2038170,2038171,2038173,2038174,2038175,2038176,2038177,2038178,2038179,2038180,2038181,2038182,2038184,2038185,2038186,2038187,2038188,2038189,2038190"] = "1212,1237,1521,1323", -- southmtns|3968|6x6
        ["2038197,2038208,2038219,2038221,2038222,2038223,2038224,2038225,2038226,2038198,2038199,2038200,2038201,2038202,2038203,2038204,2038205,2038206,2038207,2038209,2038210,2038211,2038212,2038213,2038214,2038215,2038216,2038217,2038218,2038220"] = "438,0,1424,1026", -- waycrest|3969|6x5
    },

    ["stormsongvalley"] = {
        ["2033045,2033056,2033063,2033064,2033065,2033066,2033067,2033068,2033069,2033046,2033047,2033048,2033049,2033050,2033051,2033052,2033053,2033054,2033055,2033057,2033058,2033059,2033060,2033061,2033062"] = "1750,1336,1167,1224", -- brennadam|3896|5x5
        ["2033070,2033081,2033088,2033089,2033090,2033091,2033092,2033093,2033094,2033071,2033072,2033073,2033074,2033075,2033076,2033077,2033078,2033079,2033080,2033082,2033083,2033084,2033085,2033086,2033087"] = "1288,1426,1030,1134", -- briarback|3897|5x5
        ["2033095,2033106,2033117,2033128,2033132,2033133,2033134,2033135,2033136,2033096,2033097,2033098,2033099,2033100,2033101,2033102,2033103,2033104,2033105,2033107,2033108,2033109,2033110,2033111,2033112,2033113,2033114,2033115,2033116,2033118,2033119,2033120,2033121,2033122,2033123,2033124,2033125,2033126,2033127,2033129,2033130,2033131"] = "2181,1069,1659,1491", -- brineworks|3898|7x6
        ["2033137,2033148,2033154,2033155,2033156,2033157,2033158,2033159,2033160,2033138,2033139,2033140,2033141,2033142,2033143,2033144,2033145,2033146,2033147,2033149,2033150,2033151,2033152,2033153"] = "1365,0,929,1380", -- clearcut|3899|4x6
        ["2033161,2033171,2033172,2033173,2033174,2033175,2033176,2033177,2033178,2033162,2033163,2033164,2033165,2033166,2033167,2033168,2033169,2033170"] = "1153,1056,1403,711", -- deadwash|3900|6x3
        ["2033179,2033190,2033192,2033193,2033194,2033195,2033196,2033197,2033198,2033180,2033181,2033182,2033183,2033184,2033185,2033186,2033187,2033188,2033189,2033191"] = "840,475,859,1050", -- fortdaelin|3901|4x5
        ["2033199,2033210,2033221,2033223,2033224,2033225,2033226,2033227,2033228,2033200,2033201,2033202,2033203,2033204,2033205,2033206,2033207,2033208,2033209,2033211,2033212,2033213,2033214,2033215,2033216,2033217,2033218,2033219,2033220,2033222"] = "1918,0,1052,1466", -- sagehold|3902|5x6
        ["2033229,2033240,2033251,2033262,2033272,2033273,2033274,2033275,2033276,2033230,2033231,2033232,2033233,2033234,2033235,2033236,2033237,2033238,2033239,2033241,2033242,2033243,2033244,2033245,2033246,2033247,2033248,2033249,2033250,2033252,2033253,2033254,2033255,2033256,2033257,2033258,2033259,2033260,2033261,2033263,2033264,2033265,2033266,2033267,2033268,2033269,2033270,2033271"] = "2515,0,1325,1981", -- shrineofstorm|3903|6x8
        ["2033415,2033426,2033437,2033448,2033452,2033453,2033454,2033455,2033456,2033416,2033417,2033418,2033419,2033420,2033421,2033422,2033423,2033424,2033425,2033427,2033428,2033429,2033430,2033431,2033432,2033433,2033434,2033435,2033436,2033438,2033439,2033440,2033441,2033442,2033443,2033444,2033445,2033446,2033447,2033449,2033450,2033451"] = "0,1103,1628,1457", -- windfarmsw|3904|7x6
    },

    ["nazjatar"] = {
        ["3020529,3020540,3020542,3020543,3020544,3020545,3020546,3020547,3020548,3020530,3020531,3020532,3020533,3020534,3020535,3020536,3020537,3020538,3020539,3020541"] = "729,315,815,1065", -- ashenstrand|4074|4x5
        ["3020549,3020550,3020551,3020552,3020553,3020554,3020555,3020556,3020557"] = "1876,340,648,650", -- azshariterrace|4075|3x3
        ["3020558,3020566,3020567,3020568,3020569,3020570,3020571,3020572,3020573,3020559,3020560,3020561,3020562,3020563,3020564,3020565"] = "1863,804,795,866", -- coralforest|4076|4x4
        ["3020574,3020578,3020579,3020580,3020581,3020582,3020583,3020584,3020585,3020575,3020576,3020577"] = "2321,57,583,800", -- deepcoil|4077|3x4
        ["3020586,3020590,3020591,3020592,3020593,3020594,3020595,3020596,3020597,3020587,3020588,3020589"] = "1360,1027,790,517", -- dragonsteeth|4078|4x3
        ["3020598,3020602,3020603,3020604,3020605,3020606,3020607,3020608,3020609,3020599,3020600,3020601"] = "2574,909,783,597", -- drownedmarket|4079|4x3
        ["3020610,3020611,3020612,3020613,3020614,3020615,3020616,3020617"] = "2502,692,979,480", -- elunalor|4080|4x2
        ["3020618,3020619,3020620,3020621,3020622,3020623"] = "1653,708,510,520", -- empressapproach|4081|2x3
        ["3020624,3020632,3020633,3020634,3020635,3020636,3020637,3020638,3020639,3020625,3020626,3020627,3020628,3020629,3020630,3020631"] = "1469,50,850,835", -- gateofthequeen|4082|4x4
        ["3020640,3020650,3020651,3020652,3020653,3020654,3020655,3020656,3020657,3020641,3020642,3020643,3020644,3020645,3020646,3020647,3020648,3020649"] = "895,1151,1411,710", -- hangingreef|4083|6x3
        ["3020658,3020662,3020663,3020664,3020665,3020666,3020667,3020668,3020669,3020659,3020660,3020661"] = "2213,691,703,905", -- kalmethir|4084|3x4
        ["3020670,3020671,3020672,3020673,3020674,3020675"] = "1007,1200,738,490", -- mezzamere|4085|3x2
        ["3020676,3020677,3020678,3020679,3020680,3020681"] = "1570,1432,737,461", -- newhome|4086|3x2
        ["3020682,3020683,3020684,3020685,3020686,3020687,3020688,3020689,3020690"] = "1987,49,527,528", -- shirakess|4087|3x3
        ["3020691,3020702,3020709,3020710,3020711,3020712,3020713,3020714,3020715,3020692,3020693,3020694,3020695,3020696,3020697,3020698,3020699,3020700,3020701,3020703,3020704,3020705,3020706,3020707,3020708"] = "935,1429,1224,1131", -- spearsofazshara|4088|5x5
        ["3020716,3020724,3020725,3020726,3020727,3020728,3020729,3020730,3020731,3020717,3020718,3020719,3020720,3020721,3020722,3020723"] = "1110,118,770,835", -- zanjirterrace|4089|4x4
        ["3020732,3020733,3020734,3020735,3020736,3020737,3020738,3020739,3020740"] = "1297,693,558,602", -- zanjirwash|4090|3x3
        ["3020741,3020745,3020746,3020747,3020748,3020749,3020750,3020751,3020752,3020742,3020743,3020744"] = "2490,365,990,564", -- zinazshari|4091|4x3
    },

    ["mechagonisland"] = {
        ["3022251,3022262,3022269,3022270,3022271,3022272,3022273,3022274,3022275,3022252,3022253,3022254,3022255,3022256,3022257,3022258,3022259,3022260,3022261,3022263,3022264,3022265,3022266,3022267,3022268"] = "1154,496,1169,1264", -- fleetingforest|4092|5x5
        ["3022276,3022287,3022289,3022290,3022291,3022292,3022293,3022294,3022295,3022277,3022278,3022279,3022280,3022281,3022282,3022283,3022284,3022285,3022286,3022288"] = "1910,557,1009,1191", -- heaps|4093|4x5
        ["3022296,3022307,3022318,3022326,3022327,3022328,3022329,3022330,3022331,3022297,3022298,3022299,3022300,3022301,3022302,3022303,3022304,3022305,3022306,3022308,3022309,3022310,3022311,3022312,3022313,3022314,3022315,3022316,3022317,3022319,3022320,3022321,3022322,3022323,3022324,3022325"] = "1125,1222,1479,1338", -- junkwattdepot|4094|6x6
        ["3022332,3022343,3022354,3022362,3022363,3022364,3022365,3022366,3022367,3022333,3022334,3022335,3022336,3022337,3022338,3022339,3022340,3022341,3022342,3022344,3022345,3022346,3022347,3022348,3022349,3022350,3022351,3022352,3022353,3022355,3022356,3022357,3022358,3022359,3022360,3022361"] = "2172,1134,1366,1426", -- outflow|4095|6x6
        ["3022368,3022376,3022377,3022378,3022379,3022380,3022381,3022382,3022383,3022369,3022370,3022371,3022372,3022373,3022374,3022375"] = "2513,406,1014,1022", -- rustbolt|4096|4x4
        ["3022384,3022395,3022405,3022406,3022407,3022408,3022409,3022410,3022411,3022385,3022386,3022387,3022388,3022389,3022390,3022391,3022392,3022393,3022394,3022396,3022397,3022398,3022399,3022400,3022401,3022402,3022403,3022404"] = "1315,40,1723,945", -- scrapboneden|4097|7x4
        ["3022412,3022423,3022430,3022431,3022432,3022433,3022434,3022435,3022436,3022413,3022414,3022415,3022416,3022417,3022418,3022419,3022420,3022421,3022422,3022424,3022425,3022426,3022427,3022428,3022429"] = "2791,121,1049,1055", -- sparkweaver|4098|5x5
        ["3022437,3022448,3022459,3022467,3022468,3022469,3022470,3022471,3022472,3022438,3022439,3022440,3022441,3022442,3022443,3022444,3022445,3022446,3022447,3022449,3022450,3022451,3022452,3022453,3022454,3022455,3022456,3022457,3022458,3022460,3022461,3022462,3022463,3022464,3022465,3022466"] = "46,978,1424,1511", -- westernspray|4099|6x6
    },

    ["revendreth"] = {
        ["3730685,3730688,3730690,3730694,3730695,3730698,3730701,3730704,3730706"] = "1527,300,685,688", -- destroyed|4301|3x3
        ["3730584,3730588,3730589,3730590,3730591,3730592,3730593,3730594,3730595,3730585,3730586,3730587"] = "2290,474,1019,737", -- archivam|4302|4x3
        ["3730596,3730600,3730601,3730602,3730603,3730604,3730605,3730606,3730607,3730597,3730598,3730599"] = "2597,1316,718,847", -- caretakermanor|4303|3x4
        ["3730608,3730619,3730621,3730622,3730623,3730624,3730625,3730626,3730627,3730609,3730610,3730611,3730612,3730613,3730614,3730615,3730616,3730617,3730618,3730620"] = "1647,484,885,1060", -- castlenathria|4304|4x5
        ["3730628,3730633,3730634,3730635,3730636,3730637,3730638,3730639,3730640,3730629,3730630,3730631,3730722,3730723,3730632"] = "1987,1377,711,1183", -- darkhaven|4305|3x5
        ["3730641,3730648,3730649,3730650,3730651,3730652,3730653,3730657,3730669,3730642,3730643,3730644,3730645,3730646,3730647"] = "1306,555,586,1091", -- darkwalltower|4306|3x5
        ["3730707,3730718,3730720,3730721,3730725,3730726,3730727,3730728,3730729,3730708,3730709,3730710,3730711,3730712,3730713,3730714,3730715,3730716,3730717,3730719"] = "485,0,1192,963", -- dominancekeep|4307|5x4
        ["3730730,3730741,3730743,3730744,3730745,3730746,3730747,3730748,3730749,3730731,3730732,3730733,3730734,3730735,3730736,3730737,3730738,3730739,3730740,3730742"] = "869,1682,1087,878", -- dreadhaven|4308|5x4
        ["3730750,3730760,3730761,3730762,3730763,3730764,3730765,3730766,3730767,3730751,3730752,3730753,3730754,3730755,3730756,3730757,3730758,3730759"] = "1974,919,1339,746", -- hallsofatonement|4309|6x3
        ["3730768,3730769,3730770,3730771,3730772,3730773,3730774,3730775,3730776"] = "1527,300,685,688", -- intact|4310|3x3
        ["3730777,3730778,3730779,3730780,3730781,3730782,3730783,3730784,3730785"] = "1487,1982,720,578", -- nightmarket|4311|3x3
        ["3730786,3730797,3730799,3730800,3730801,3730802,3730803,3730804,3730805,3730787,3730788,3730789,3730790,3730791,3730792,3730793,3730794,3730795,3730796,3730798"] = "2324,1520,835,1040", -- pridefall|4312|4x5
        ["3730807,3730818,3730829,3730831,3730832,3730833,3730834,3730835,3730836,3730808,3730809,3730810,3730811,3730812,3730813,3730814,3730815,3730816,3730817,3730819,3730820,3730821,3730822,3730823,3730824,3730825,3730826,3730827,3730828,3730830"] = "433,596,1207,1465", -- shroudedasylem|4313|5x6
        ["3730837,3730848,3730855,3730856,3730857,3730858,3730859,3730860,3730861,3730838,3730839,3730840,3730841,3730842,3730843,3730844,3730845,3730846,3730847,3730849,3730850,3730851,3730852,3730853,3730854"] = "1200,1407,1030,1129", -- waincrypthill|4314|5x5
    },

    ["bastion"] = {
        ["3192856,3192857,3192858,3192859,3192860,3192861"] = "1566,1551,591,503", -- agthiarepose|4106|3x2
        ["3192862,3192866,3192867,3192868,3192869,3192870,3192871,3192872,3192873,3192863,3192864,3192865"] = "1626,1949,804,564", -- aspirantcrucible|4107|4x3
        ["3192874,3192881,3192882,3192883,3192884,3192885,3192886,3192887,3192888,3192875,3192876,3192877,3192878,3192879,3192880"] = "881,993,1115,704", -- braveheart|4108|5x3
        ["3192889,3192900,3192906,3192907,3192908,3192909,3192910,3192911,3192912,3192890,3192891,3192892,3192893,3192894,3192895,3192896,3192897,3192898,3192899,3192901,3192902,3192903,3192904,3192905"] = "495,250,1357,856", -- citadelloyalty|4109|6x4
        ["3192913,3192917,3192918,3192919,3192920,3192921,3192922,3192923,3192924,3192914,3192915,3192916"] = "1975,155,892,763", -- elysianhold|4110|4x3
        ["3192925,3192933,3192934,3192935,3192936,3192937,3192938,3192939,3192940,3192926,3192927,3192928,3192929,3192930,3192931,3192932"] = "1400,48,984,847", -- eternalforge|4111|4x4
        ["3192941,3192942,3192943,3192944,3192945,3192946,3192947,3192948,3192949"] = "1793,1220,746,528", -- memoryextraction|4112|3x3
        ["3192950,3192954,3192955,3192956,3192957,3192958,3192959,3192960,3192961,3192951,3192952,3192953"] = "1475,706,985,652", -- orchard|4113|4x3
        ["3192962,3192963,3192964,3192965,3192966,3192967,3192968,3192969"] = "2004,1590,826,494", -- puritypinnacle|4114|4x2
        ["3192970,3192978,3192979,3192980,3192981,3192982,3192983,3192984,3192985,3192971,3192972,3192973,3192974,3192975,3192976,3192977"] = "2110,588,881,911", -- templehumility|4115|4x4
        ["3192986,3192990,3192991,3192992,3192993,3192994,3192995,3192996,3192997,3192987,3192988,3192989"] = "1167,1387,783,542", -- unnamed|4116|4x3
        ["3192998,3193002,3193003,3193004,3193005,3193006,3193007,3193008,3193009,3192999,3193000,3193001"] = "1068,1768,839,558", -- vestibuleeternity|4117|4x3
    },

    ["maldraxxus"] = {
        ["3745117,3745124,3745125,3745126,3745127,3745128,3745129,3745130,3745131,3745118,3745119,3745120,3745121,3745122,3745123"] = "284,1085,1149,703", -- burningthicket|4327|5x3
        ["3745132,3745133,3745134,3745135,3745136,3745137,3745138,3745139,3745140"] = "1815,517,694,666", -- forgottenwounds|4328|3x3
        ["3745141,3745145,3745146,3745147,3745148,3745149,3745150,3745151,3745152,3745142,3745143,3745144"] = "2028,894,719,802", -- glutharnsdecay|4329|3x4
        ["3745153,3745164,3745166,3745167,3745168,3745169,3745170,3745171,3745172,3745154,3745155,3745156,3745157,3745158,3745159,3745160,3745161,3745162,3745163,3745165"] = "631,46,951,1071", -- houseofconstructs|4330|4x5
        ["3745173,3745181,3745182,3745183,3745184,3745185,3745186,3745187,3745188,3745174,3745175,3745176,3745177,3745178,3745179,3745180"] = "1692,0,932,919", -- houseofeyes|4331|4x4
        ["3745189,3745200,3745211,3745213,3745214,3745215,3745216,3745217,3745218,3745190,3745191,3745192,3745193,3745194,3745195,3745196,3745197,3745198,3745199,3745201,3745202,3745203,3745204,3745205,3745206,3745207,3745208,3745209,3745210,3745212"] = "2232,13,1363,1137", -- houseofrituals|4332|6x5
        ["3745219,3745230,3745241,3745243,3745244,3745245,3745246,3745247,3745248,3745220,3745221,3745222,3745223,3745224,3745225,3745226,3745227,3745228,3745229,3745231,3745232,3745233,3745234,3745235,3745236,3745237,3745238,3745239,3745240,3745242"] = "330,1351,1508,1209", -- houseofthechosen|4333|6x5
        ["3745249,3745260,3745271,3745282,3745284,3745285,3745286,3745287,3745288,3745250,3745251,3745252,3745253,3745254,3745255,3745256,3745257,3745258,3745259,3745261,3745262,3745263,3745264,3745265,3745266,3745267,3745268,3745269,3745270,3745272,3745273,3745274,3745275,3745276,3745277,3745278,3745279,3745280,3745281,3745283"] = "1582,1424,1925,1136", -- houseoftheplagues|4334|8x5
        ["3745289,3745300,3745302,3745303,3745304,3745305,3745306,3745307,3745308,3745290,3745291,3745292,3745293,3745294,3745295,3745296,3745297,3745298,3745299,3745301"] = "2438,785,1194,998", -- rottingmound|4335|5x4
        ["3745309,3745313,3745314,3745315,3745316,3745317,3745318,3745319,3745320,3745310,3745311,3745312"] = "1551,1342,757,985", -- seatoftheprimus|4336|3x4
        ["3745321,3745332,3745334,3745335,3745336,3745337,3745338,3745339,3745340,3745322,3745323,3745324,3745325,3745326,3745327,3745328,3745329,3745330,3745331,3745333"] = "1202,0,858,1178", -- sepulcher|4337|4x5
        ["3745341,3745345,3745346,3745347,3745348,3745349,3745350,3745351,3745352,3745342,3745343,3745344"] = "1171,836,673,788", -- spearhead|4338|3x4
        ["3745353,3745364,3745375,3745377,3745378,3745379,3745380,3745381,3745382,3745354,3745355,3745356,3745357,3745358,3745359,3745360,3745361,3745362,3745363,3745365,3745366,3745367,3745368,3745369,3745370,3745371,3745372,3745373,3745374,3745376"] = "261,65,1231,1391", -- stitchyard|4339|5x6
        ["3745383,3745384,3745385,3745386,3745387,3745388,3745389,3745390,3745391"] = "1566,862,730,730", -- theaterofpain|4340|3x3
    },

    ["mawmaxlevel"] = {
        ["4178838,4178839,4178840,4178841,4178842,4178843,4178844,4178845,4178846,4178847,4178848,4178849,4178850,4178851,4178852,4178853"] = "1442,1262,1009,835", -- beastwarrens|4728|4x4
        ["4179006,4179007,4179008,4179009,4179010,4179011,4179012,4179013,4179014,4179015,4179016,4179017,4179018,4179019,4179020,4179021,4179022,4179023,4179024,4179025,4179026,4179027,4179028,4179029,4179030"] = "0,342,1232,1236", -- calcis|4730|5x5
        ["4178946,4178947,4178948,4178949,4178950,4178951,4178952,4178953,4178954,4178955,4178956,4178957,4178958,4178959,4178960,4178961,4178962,4178963,4178964,4178965"] = "1100,696,1186,821", -- cocyrus|4731|5x4
        ["4178986,4178987,4178988,4178989,4178990,4178991,4178992,4178993,4178994,4178995,4178996,4178997,4178998,4178999,4179000,4179001,4179002,4179003,4179004,4179005"] = "49,918,1053,934", -- crucibledamned|4732|5x4
        ["4178854,4178855,4178856,4178857,4178858,4178859,4178860,4178861,4178862,4178863,4178864,4178865,4178866,4178867,4178868,4178869,4178870,4178871,4178872,4178873,4178874,4178875,4178876,4178877,4178878,4178879,4178880,4178881,4178882,4178883,4178884,4178885,4178886,4178887,4178888,4178889,4178890,4178891,4178892,4178893,4178894,4178895,4178896,4178897,4178898,4178899,4178900,4178901"] = "1797,0,1488,1946", -- desmotaeron|4733|6x8
        ["4179055,4179056,4179057,4179058,4179059,4179060,4179061,4179062,4179063,4179064,4179065,4179066,4179067,4179068,4179069,4179070,4179071,4179072,4179073,4179074,4179075,4179076,4179077,4179078"] = "1171,0,1504,929", -- gorgoa|4734|6x4
        ["4178826,4178827,4178828,4178829,4178830,4178831,4178832,4178833,4178834,4178835,4178836,4178837"] = "1404,1831,928,729", -- marrow|4735|4x3
        ["4178922,4178923,4178924,4178925,4178926,4178927,4178928,4178929,4178930,4178931,4178932,4178933,4178934,4178935,4178936,4178937,4178938,4178939,4178940,4178941,4178942,4178943,4178944,4178945"] = "808,1201,928,1359", -- perditionhold|4736|4x6
        ["4179031,4179032,4179033,4179034,4179035,4179036,4179037,4179038,4179039,4179040,4179041,4179042,4179043,4179044,4179045,4179046,4179047,4179048,4179049,4179050,4179051,4179052,4179053,4179054"] = "183,0,1395,932", -- planesoftorment|4737|6x4
        ["4178802,4178803,4178804,4178805,4178806,4178807,4178808,4178809,4178810,4178811,4178812,4178813,4178814,4178815,4178816,4178817,4178818,4178819,4178820,4178821,4178822,4178823,4178824,4178825"] = "1856,1572,1408,988", -- ravener|4738|6x4
        ["4178966,4178967,4178968,4178969,4178970,4178971,4178972,4178973,4178974,4178975,4178976,4178977,4178978,4178979,4178980,4178981,4178982,4178983,4178984,4178985"] = "772,598,1078,824", -- zovaalscauldron|4739|5x4
        ["4178902,4178903,4178904,4178905,4178906,4178907,4178908,4178909,4178910,4178911,4178912,4178913,4178914,4178915,4178916,4178917,4178918,4178919,4178920,4178921"] = "262,1423,954,1076", -- altardamnation|4740|4x5
    },

    ["ardenweald"] = {
        ["3604198,3604206,3604207,3604208,3604209,3604210,3604211,3604212,3604213,3604199,3604200,3604201,3604202,3604203,3604204,3604205"] = "1036,316,847,783", -- blackthorn|4248|4x4
        ["3604214,3604218,3604219,3604220,3604221,3604222,3604223,3604224,3604225,3604215,3604216,3604217"] = "2338,474,904,714", -- crubledridge|4249|4x3
        ["3604226,3604237,3604239,3604240,3604241,3604242,3604243,3604244,3604245,3604227,3604228,3604229,3604230,3604231,3604232,3604233,3604234,3604235,3604236,3604238"] = "1190,1242,845,1048", -- darkreach|4250|4x5
        ["3604246,3604254,3604255,3604256,3604257,3604258,3604259,3604260,3604261,3604247,3604248,3604249,3604250,3604251,3604252,3604253"] = "2339,1049,886,821", -- fallentree|4251|4x4
        ["3604262,3604269,3604270,3604271,3604272,3604273,3604274,3604275,3604276,3604263,3604264,3604265,3604266,3604267,3604268"] = "1679,54,688,1139", -- glitterfall|4252|3x5
        ["3604277,3604285,3604286,3604287,3604288,3604289,3604290,3604291,3604292,3604278,3604279,3604280,3604281,3604282,3604283,3604284"] = "1701,1607,798,896", -- gormhive|4253|4x4
        ["3604293,3604294,3604295,3604296,3604297,3604298,3604299,3604300,3604301"] = "1487,945,686,742", -- heartoftheforest|4254|3x3
        ["3604302,3604303,3604304,3604305,3604306,3604307,3604308,3604309,3604310"] = "1993,885,669,747", -- hibernalhollow|4255|3x3
        ["3604311,3604322,3604333,3604335,3604336,3604337,3604338,3604339,3604340,3604312,3604313,3604314,3604315,3604316,3604317,3604318,3604319,3604320,3604321,3604323,3604324,3604325,3604326,3604327,3604328,3604329,3604330,3604331,3604332,3604334"] = "379,811,1179,1340", -- mistvaletangle|4256|5x6
        ["3604341,3604345,3604346,3604347,3604348,3604349,3604350,3604351,3604352,3604342,3604343,3604344"] = "1736,1234,770,603", -- shimmerbough|4257|4x3
        ["3604353,3604357,3604358,3604359,3604360,3604361,3604362,3604363,3604364,3604354,3604355,3604356"] = "2211,168,803,645", -- starlitoverlook|4258|4x3
        ["3604365,3604369,3604370,3604371,3604372,3604373,3604374,3604375,3604376,3604366,3604367,3604368"] = "946,723,864,650", -- thestalks|4259|4x3
        ["3604377,3604378,3604379,3604380,3604381,3604382,3604383,3604384,3604385"] = "2107,638,563,685", -- tirnavaal|4260|3x3
    },

    ["korthia"] = {
        ["4074917,4074918,4074919,4074920,4074921,4074922,4074923,4074924,4074925"] = "958,997,766,637", -- estuaryofawakening|4619|3x3
        ["4074926,4074937,4074948,4074955,4074956,4074957,4074958,4074959,4074960,4074927,4074928,4074929,4074930,4074931,4074932,4074933,4074934,4074935,4074936,4074938,4074939,4074940,4074941,4074942,4074943,4074944,4074945,4074946,4074947,4074949,4074950,4074951,4074952,4074953,4074954"] = "153,0,1612,1268", -- hopesascent|4620|7x5
        ["4074961,4074969,4074970,4074971,4074972,4074973,4074974,4074975,4074976,4074962,4074963,4074964,4074965,4074966,4074967,4074968"] = "2113,0,844,875", -- keepersrespite|4621|4x4
        ["4074977,4074988,4074999,4075001,4075002,4075003,4075004,4075005,4075006,4074978,4074979,4074980,4074981,4074982,4074983,4074984,4074985,4074986,4074987,4074989,4074990,4074991,4074992,4074993,4074994,4074995,4074996,4074997,4074998,4075000"] = "945,0,1362,1088", -- maulersoutlook|4622|6x5
        ["4075007,4075011,4075012,4075013,4075014,4075015,4075016,4075017,4075018,4075008,4075009,4075010"] = "1500,0,834,696", -- sanctuaryofguidance|4623|4x3
        ["4075019,4075026,4075027,4075028,4075029,4075030,4075031,4075032,4075033,4075020,4075021,4075022,4075023,4075024,4075025"] = "1841,645,1264,715", -- scholarsden|4624|5x3
        ["4075034,4075045,4075051,4075052,4075053,4075054,4075055,4075056,4075057,4075035,4075036,4075037,4075038,4075039,4075040,4075041,4075042,4075043,4075044,4075046,4075047,4075048,4075049,4075050"] = "1474,891,1412,792", -- seekersquorum|4625|6x4
        ["4075058,4075069,4075080,4075084,4075085,4075086,4075087,4075088,4075089,4075059,4075060,4075061,4075062,4075063,4075064,4075065,4075066,4075067,4075068,4075070,4075071,4075072,4075073,4075074,4075075,4075076,4075077,4075078,4075079,4075081,4075082,4075083"] = "1231,1429,1871,1010", -- vaultofsecrets|4626|8x4
        ["4075090,4075098,4075099,4075100,4075101,4075102,4075103,4075104,4075105,4075091,4075092,4075093,4075094,4075095,4075096,4075097"] = "597,1053,929,817", -- windsweptaerie|4627|4x4
    },

    ["zerethmortis"] = {
        ["4261283,4261284,4261285,4261286,4261287,4261288,4261289,4261290,4261291"] = "1162,535,649,666", -- circleoftransmutation|4741|3x3
        ["4261292,4261296,4261297,4261298,4261299,4261300,4261301,4261302,4261303,4261293,4261294,4261295"] = "1497,1932,823,628", -- creationcatalyst|4742|4x3
        ["4261304,4261315,4261317,4261318,4261319,4261320,4261321,4261322,4261323,4261305,4261306,4261307,4261308,4261309,4261310,4261311,4261312,4261313,4261314,4261316"] = "1924,140,880,1087", -- desolatecollapse|4743|4x5
        ["4261324,4261328,4261329,4261330,4261331,4261332,4261333,4261334,4261335,4261325,4261326,4261327"] = "1736,1363,1008,726", -- dimensionalfalls|4744|4x3
        ["4261336,4261337,4261338,4261339,4261340,4261341,4261349,4261350,4261351"] = "1912,112,582,590", -- dreadportal|4745|3x3
        ["4261352,4261363,4261370,4261371,4261372,4261373,4261374,4261375,4261376,4261353,4261354,4261355,4261356,4261357,4261358,4261359,4261360,4261361,4261362,4261364,4261365,4261366,4261367,4261368,4261369"] = "269,730,1072,1207", -- entrance|4746|5x5
        ["4261377,4261378,4261379,4261380,4261381,4261382,4261383,4261384,4261385"] = "1466,991,736,755", -- forgeofafterlives|4747|3x3
        ["4261386,4261397,4261399,4261400,4261401,4261402,4261403,4261404,4261405,4261387,4261388,4261389,4261390,4261391,4261392,4261393,4261394,4261395,4261396,4261398"] = "777,1548,1117,1012", -- genesisfields|4748|5x4
        ["4261406,4261407,4261408,4261409,4261410,4261411"] = "1058,1264,579,479", -- greatveldt|4749|3x2
        ["4261412,4261413,4261414,4261415,4261416,4261417,4261418,4261419,4261420"] = "900,1499,629,554", -- haven|4750|3x3
        ["4261421,4261429,4261430,4261431,4261432,4261433,4261434,4261435,4261436,4261422,4261423,4261424,4261425,4261426,4261427,4261428"] = "1198,0,928,910", -- hookscar|4751|4x4
        ["4261437,4261448,4261459,4261470,4261474,4261475,4261476,4261477,4261478,4261438,4261439,4261440,4261441,4261442,4261443,4261444,4261445,4261446,4261447,4261449,4261450,4261451,4261452,4261453,4261454,4261455,4261456,4261457,4261458,4261460,4261461,4261462,4261463,4261464,4261465,4261466,4261467,4261468,4261469,4261471,4261472,4261473"] = "2072,665,1709,1426", -- hub_b|4752|7x6
        ["4261479,4261480,4261481,4261482,4261483,4261484,4261485,4261486,4261487"] = "2005,872,516,516", -- kaasoless|4753|3x3
        ["4261488,4261499,4261510,4261512,4261513,4261514,4261515,4261516,4261517,4261489,4261490,4261491,4261492,4261493,4261494,4261495,4261496,4261497,4261498,4261500,4261501,4261502,4261503,4261504,4261505,4261506,4261507,4261508,4261509,4261511"] = "2240,35,1362,1236", -- lostruins|4754|6x5
        ["4261518,4261522,4261523,4261524,4261525,4261526,4261527,4261528,4261529,4261519,4261520,4261521"] = "1841,1640,986,700", -- overgrownruins|4755|4x3
        ["4261530,4261544,4261555,4261563,4261564,4261565,4261566,4261567,4261568,4261531,4261532,4261533,4261534,4261535,4261536,4261538,4261539,4261541,4261543,4261545,4261546,4261547,4261548,4261549,4261550,4261551,4261552,4261553,4261554,4261556,4261557,4261558,4261559,4261560,4261561,4261562"] = "364,57,1289,1364", -- quietalcove|4756|6x6
        ["4261569,4261570,4261571,4261572,4261573,4261574,4261575,4261576,4261577"] = "1641,431,563,715", -- unstabledesert|4757|3x3
    },

    ["thewakingshores"] = {
        ["4699777,4699784,4699785,4699786,4699787,4699788,4699789,4699790,4699791,4699778,4699779,4699780,4699781,4699782,4699783"] = "283,1861,1035,699", -- apexcanopy|4796|5x3
        ["4699812,4699823,4699825,4699826,4699827,4699828,4699829,4699830,4699831,4699813,4699814,4699815,4699816,4699817,4699818,4699819,4699820,4699821,4699822,4699824"] = "1004,1789,1067,771", -- dragonscale|4797|5x4
        ["4699792,4699803,4699805,4699806,4699807,4699808,4699809,4699810,4699811,4699793,4699794,4699795,4699796,4699797,4699798,4699799,4699800,4699801,4699802,4699804"] = "2136,824,1278,851", -- dragonheart|4798|5x4
        ["4699832,4699840,4699841,4699842,4699843,4699844,4699845,4699846,4699847,4699833,4699834,4699835,4699836,4699837,4699838,4699839"] = "1743,1590,820,970", -- frostflash|4799|4x4
        ["4699848,4699859,4699861,4699862,4699863,4699864,4699865,4699866,4699867,4699849,4699850,4699851,4699852,4699853,4699854,4699855,4699856,4699857,4699858,4699860"] = "1574,35,1029,899", -- lifebinder|4800|5x4
        ["4699868,4699879,4699890,4699892,4699893,4699894,4699895,4699896,4699897,4699869,4699870,4699871,4699872,4699873,4699874,4699875,4699876,4699877,4699878,4699880,4699881,4699882,4699883,4699884,4699885,4699886,4699887,4699888,4699889,4699891"] = "521,919,1505,1257", -- obsidianbulwark|4801|6x5
        ["4699898,4699909,4699920,4699922,4699923,4699924,4699925,4699926,4699927,4699899,4699900,4699901,4699902,4699903,4699904,4699905,4699906,4699907,4699908,4699910,4699911,4699912,4699913,4699914,4699915,4699916,4699917,4699918,4699919,4699921"] = "240,712,1331,1177", -- obsidiancitadel|4802|6x5
        ["4699928,4699939,4699950,4699952,4699953,4699954,4699955,4699956,4699957,4699929,4699930,4699931,4699932,4699933,4699934,4699935,4699936,4699937,4699938,4699940,4699941,4699942,4699943,4699944,4699945,4699946,4699947,4699948,4699949,4699951"] = "1372,467,1057,1289", -- overflowingrapids|4803|5x6
        ["4699958,4699969,4699971,4699972,4699973,4699974,4699975,4699976,4699977,4699959,4699960,4699961,4699962,4699963,4699964,4699965,4699966,4699967,4699968,4699970"] = "1848,1260,1120,913", -- rubylifepools|4804|5x4
        ["4699978,4699989,4699996,4699997,4699998,4699999,4700000,4700001,4700002,4699979,4699980,4699981,4699982,4699983,4699984,4699985,4699986,4699987,4699988,4699990,4699991,4699992,4699993,4699994,4699995"] = "2181,0,1163,1037", -- scalekeeper|4805|5x5
        ["4700003,4700007,4700008,4700009,4700010,4700011,4700012,4700013,4700014,4700004,4700005,4700006"] = "2536,1124,692,784", -- skytop|4806|3x4
        ["4700015,4700026,4700028,4700029,4700030,4700031,4700032,4700033,4700034,4700016,4700017,4700018,4700019,4700020,4700021,4700022,4700023,4700024,4700025,4700027"] = "2473,311,1191,928", -- wingcrest|4807|5x4
    },

    ["plainsofohnahra"] = {
        ["4697275,4697276,4697277,4697278,4697279,4697280,4697281,4697282,4697283"] = "315,920,746,767", -- ancientbough|4784|3x3
        ["4697284,4697295,4697306,4697314,4697315,4697316,4697317,4697318,4697319,4697285,4697286,4697287,4697288,4697289,4697290,4697291,4697292,4697293,4697294,4697296,4697297,4697298,4697299,4697300,4697301,4697302,4697303,4697304,4697305,4697307,4697308,4697309,4697310,4697311,4697312,4697313"] = "1338,404,1444,1292", -- broadhoofoutpost|4785|6x6
        ["4697320,4697328,4697329,4697330,4697331,4697332,4697333,4697334,4697335,4697321,4697322,4697323,4697324,4697325,4697326,4697327"] = "1877,50,983,813", -- emberwatch|4786|4x4
        ["4697336,4697347,4697353,4697354,4697355,4697356,4697357,4697358,4697359,4697337,4697338,4697339,4697340,4697341,4697342,4697343,4697344,4697345,4697346,4697348,4697349,4697350,4697351,4697352"] = "505,531,1023,1309", -- emeraldgardens|4787|4x6
        ["4697360,4697371,4697382,4697384,4697385,4697386,4697387,4697388,4697389,4697361,4697362,4697363,4697364,4697365,4697366,4697367,4697368,4697369,4697370,4697372,4697373,4697374,4697375,4697376,4697377,4697378,4697379,4697380,4697381,4697383"] = "2343,1317,1285,1226", -- forkriver|4788|6x5
        ["4697390,4697398,4697399,4697400,4697401,4697402,4697403,4697404,4697405,4697391,4697392,4697393,4697394,4697395,4697396,4697397"] = "1838,527,942,774", -- maruukai|4789|4x4
        ["4697406,4697414,4697415,4697416,4697417,4697418,4697419,4697420,4697421,4697407,4697408,4697409,4697410,4697411,4697412,4697413"] = "790,460,982,989", -- nokhudonhold|4790|4x4
        ["4697422,4697433,4697435,4697436,4697437,4697438,4697439,4697440,4697441,4697423,4697424,4697425,4697426,4697427,4697428,4697429,4697430,4697431,4697432,4697434"] = "2432,752,1270,973", -- pinewoodpost|4791|5x4
        ["4697442,4697453,4697464,4697466,4697467,4697468,4697469,4697470,4697471,4697443,4697444,4697445,4697446,4697447,4697448,4697449,4697450,4697451,4697452,4697454,4697455,4697456,4697457,4697458,4697459,4697460,4697461,4697462,4697463,4697465"] = "2464,112,1337,1164", -- ruszathar|4792|6x5
        ["4697472,4697483,4697494,4697496,4697497,4697498,4697499,4697500,4697501,4697473,4697474,4697475,4697476,4697477,4697478,4697479,4697480,4697481,4697482,4697484,4697485,4697486,4697487,4697488,4697489,4697490,4697491,4697492,4697493,4697495"] = "512,1211,1341,1228", -- teerakai|4793|6x5
        ["4697502,4697506,4697507,4697508,4697509,4697510,4697511,4697512,4697513,4697503,4697504,4697505"] = "2733,113,919,694", -- wandererssteppe|4794|4x3
        ["4697514,4697525,4697527,4697528,4697529,4697530,4697531,4697532,4697533,4697515,4697516,4697517,4697518,4697519,4697520,4697521,4697522,4697523,4697524,4697526"] = "1511,1419,1184,961", -- windsongrise|4795|5x4
        ["5447781,5447785,5447787,5447790,5447793,5447797,5447800,5447802,5447805,5447808,5447810,5447813,5447816,5447819,5447821,5447824,5447827,5447829,5447832,5447835,5447837,5447840,5447843,5447846"] = "0,702,914,1504", -- amirdrassil|4833|4x6
    },

    ["theazurespan"] = {
        ["4697970,4697981,4697992,4697993,4697994,4697995,4697996,4697997,4697998,4697971,4697972,4697973,4697974,4697975,4697976,4697977,4697978,4697979,4697980,4697982,4697983,4697984,4697986,4697987,4697988,4697989,4697990,4697991"] = "1211,350,980,1732", -- antonidas|4765|4x7
        ["4697999,4698012,4698015,4698016,4698018,4698019,4698020,4698021,4698022,4698000,4698001,4698002,4698003,4698005,4698007,4698008,4698009,4698010,4698011,4698014"] = "706,1160,1129,954", -- azurearchives|4766|5x4
        ["4698024,4698036,4698043,4698044,4698045,4698046,4698047,4698048,4698049,4698026,4698027,4698028,4698029,4698030,4698031,4698032,4698033,4698034,4698035,4698037,4698038,4698039,4698040,4698041,4698042"] = "660,324,1032,1233", -- bigtreehills|4767|5x5
        ["4698050,4698061,4698063,4698064,4698065,4698066,4698067,4698068,4698069,4698051,4698052,4698053,4698054,4698055,4698056,4698057,4698058,4698059,4698060,4698062"] = "10,462,1109,909", -- brackenhide|4768|5x4
        ["4698070,4698106,4698180,4698193,4698199,4698207,4698213,4698220,4698226,4698071,4698072,4698073,4698074,4698075,4698077,4698082,4698088,4698094,4698100,4698114,4698120,4698127,4698133,4698140,4698146,4698153,4698160,4698167,4698173,4698186"] = "1843,946,1294,1096", -- campnowhere|4769|6x5
        ["4698233,4698281,4698287,4698292,4698298,4698304,4698311,4698317,4698323,4698239,4698246,4698252,4698258,4698265,4698271,4698276"] = "1357,162,908,825", -- cobaltassembly|4770|4x4
        ["4698331,4698377,4698383,4698390,4698397,4698403,4698410,4698417,4698424,4698336,4698343,4698349,4698355,4698361,4698365,4698371"] = "0,839,870,818", -- iskaara|4771|4x4
        ["4698430,4698500,4698504,4698505,4698512,4698518,4698524,4698531,4698538,4698437,4698444,4698451,4698458,4698463,4698470,4698476,4698483,4698489,4698494,4698503"] = "1683,478,1080,945", -- snowhideden|4772|5x4
        ["4698734,4698746,4698753,4698760,4698767,4698773,4698779,4698786,4698793,4698735,4698736,4698737,4698738,4698739,4698740"] = "1883,57,1205,689", -- theronswatch|4773|5x3
        ["4698800,4698829,4698836,4698843,4698850,4698857,4698864,4698871,4698878,4698808,4698815,4698822"] = "208,115,901,742", -- threefalls|4774|4x3
        ["4698885,4698947,4698958,4698966,4698967,4698968,4698969,4698970,4698971,4698891,4698898,4698905,4698912,4698918,4698924,4698930,4698936,4698943,4698946,4698948,4698949,4698950,4698951,4698952,4698953,4698954,4698955,4698956,4698957,4698959,4698960,4698961,4698962,4698963,4698964,4698965"] = "2446,60,1291,1459", -- vakthros|4775|6x6
    },

    ["thaldraszus"] = {
        ["4696503,4696514,4696520,4696521,4696522,4696523,4696524,4696525,4696526,4696504,4696505,4696506,4696507,4696508,4696509,4696510,4696511,4696512,4696513,4696515,4696516,4696517,4696518,4696519"] = "1525,508,1416,947", -- algetharacademy|4776|6x4
        ["4696527,4696535,4696536,4696537,4696538,4696539,4696540,4696541,4696542,4696528,4696529,4696530,4696531,4696532,4696533,4696534"] = "1467,1239,913,812", -- gelikyrpost|4777|4x4
        ["4696543,4696554,4696556,4696557,4696558,4696559,4696560,4696561,4696562,4696544,4696545,4696546,4696547,4696548,4696549,4696550,4696551,4696552,4696553,4696555"] = "937,1631,1140,924", -- southholdgate|4778|5x4
        ["4696563,4696574,4696580,4696581,4696582,4696583,4696584,4696585,4696586,4696564,4696565,4696566,4696567,4696568,4696569,4696570,4696571,4696572,4696573,4696575,4696576,4696577,4696578,4696579"] = "1611,1641,1433,919", -- temporalconflux|4779|6x4
        ["4696592,4696600,4696601,4696602,4696603,4696604,4696605,4696606,4696607,4696593,4696594,4696595,4696596,4696597,4696598,4696599"] = "1935,1048,787,839", -- tyrhold|4780|4x4
        ["4696608,4696619,4696621,4696622,4696623,4696624,4696625,4696626,4696627,4696609,4696610,4696611,4696612,4696613,4696614,4696615,4696616,4696617,4696618,4696620"] = "835,952,1180,977", -- valdrakken|4781|5x4
        ["4696628,4696639,4696650,4696657,4696658,4696659,4696660,4696661,4696662,4696629,4696630,4696631,4696632,4696633,4696634,4696635,4696636,4696637,4696638,4696640,4696641,4696642,4696643,4696644,4696645,4696646,4696647,4696648,4696649,4696651,4696652,4696653,4696654,4696655,4696656"] = "2424,798,1205,1762", -- vaultofincarnates|4782|5x7
        ["4696663,4696674,4696676,4696677,4696678,4696679,4696680,4696681,4696682,4696664,4696665,4696666,4696667,4696668,4696669,4696670,4696671,4696672,4696673,4696675"] = "1951,0,1036,798", -- veiledossuary|4783|5x4
        ["4703622,4703633,4703639,4703640,4703641,4703642,4703643,4703644,4703645,4703623,4703624,4703625,4703626,4703627,4703628,4703629,4703630,4703631,4703632,4703634,4703635,4703636,4703637,4703638"] = "1611,1641,1433,919", -- primalisticon|4808|6x4
    },

    ["underground"] = {
        ["5097222,5097233,5097244,5097245,5097246,5097247,5097248,5097249,5097250,5097223,5097224,5097225,5097226,5097227,5097228,5097229,5097230,5097231,5097232,5097234,5097235,5097236,5097237,5097238,5097239,5097240,5097242,5097243"] = "1000,0,1720,1002", -- aberrus|4815|7x4
        ["5097251,5097255,5097256,5097257,5097258,5097259,5097260,5097261,5097262,5097252,5097253,5097254"] = "1748,1868,898,692", -- buriedvault|4816|4x3
        ["5097263,5097274,5097285,5097287,5097288,5097289,5097290,5097291,5097292,5097264,5097265,5097266,5097267,5097268,5097269,5097270,5097271,5097272,5097273,5097275,5097276,5097277,5097278,5097279,5097280,5097281,5097282,5097283,5097284,5097286"] = "744,1408,1317,1152", -- glimmerogg|4817|6x5
        ["5097293,5097294,5097295,5097296,5097297,5097298,5097299,5097300,5097301"] = "1868,1092,603,592", -- loamm|4818|3x3
        ["5097302,5097309,5097310,5097311,5097312,5097313,5097314,5097315,5097316,5097303,5097304,5097305,5097306,5097307,5097308"] = "1801,1472,1224,754", -- nalkskol|4819|5x3
        ["5097317,5097328,5097330,5097331,5097332,5097333,5097334,5097335,5097336,5097318,5097319,5097320,5097321,5097322,5097323,5097324,5097325,5097326,5097327,5097329"] = "1384,716,783,1052", -- sulfurwastes|4820|4x5
        ["5097337,5097348,5097354,5097355,5097356,5097357,5097358,5097359,5097360,5097338,5097339,5097340,5097341,5097342,5097343,5097344,5097345,5097346,5097347,5097349,5097350,5097351,5097352,5097353"] = "1906,761,1340,930", -- throughway|4821|6x4
        ["5097361,5097375,5097382,5097383,5097384,5097385,5097386,5097387,5097388,5097362,5097363,5097364,5097366,5097367,5097368,5097371,5097372,5097373,5097374,5097376,5097377,5097378,5097379,5097380,5097381"] = "504,693,1264,1110", -- zaqalicaldera|4822|5x5
    },

    ["theforbiddenreach_full"] = {
        ["4915287,4915775,4915934,4916210,4916453,4916474,4916499,4916521,4916543,4915288,4915289,4915293,4915513,4915760,4915768,4915769,4915770,4915771,4915772,4915776,4915777,4915778,4915779,4915798,4915819,4915846,4915867,4915888,4915909,4915964,4915988,4916011,4916035,4916057,4916080,4916093,4916142,4916163,4916188,4916233,4916258,4916282"] = "1201,1234,1660,1326", -- weyrngroundsfull|4809|7x6
        ["4915095,4915106,4915129,4915131,4915132,4915133,4915134,4915135,4915136,4915096,4915097,4915098,4915099,4915100,4915101,4915102,4915103,4915104,4915105,4915110,4915114,4915118,4915121,4915123"] = "2350,1013,1378,1023", -- stormsunderfull|4810|6x4
        ["4915075,4915086,4915088,4915089,4915090,4915091,4915092,4915093,4915094,4915076,4915077,4915078,4915079,4915080,4915081,4915082,4915083,4915084,4915085,4915087,5047286,5047287,5047288,5047289,5047290,5047291,5047292,5047293,5047294,5047295,5047296,5047297,5047298,5047299,5047300,5047301"] = "128,1011,1377,1521", -- morqutfull|4811|6x6
        ["4914916,4914969,4915016,4915062,4915069,4915070,4915071,4915073,4915074,4914921,4914926,4914932,4914936,4914941,4914946,4914950,4914955,4914960,4914964,4914973,4914978,4914983,4914989,4914994,4914999,4915004,4915009,4915012,4915014,4915018"] = "1765,21,1176,1497", -- frostonefull|4812|5x6
        ["4914864,4914887,4914888,4914889,4914892,4914896,4914900,4914905,4914910,4914865,4914868,4914869,4914871,4914873,4914880,4914885"] = "2625,450,876,811", -- dragonskullfull|4813|4x4
        ["4914793,4914811,4914831,4914848,4914855,4914856,4914858,4914860,4914862,4914796,4914797,4914799,4914800,4914802,4914803,4914805,4914806,4914807,4914809,4914812,4914815,4914817,4914820,4914822,4914823,4914826,4914827,4914829,4914830,4914832,4914834,4914836,4914837,4914838,4914839,4914840,4914843,4914844,4914846,4914849,4914851,4914853,5047279,5047280,5047281,5047282,5047283,5047284"] = "243,91,1811,1399", -- calderafull|4814|8x6
    },

    ["dreamtree"] = {
        ["5393987,5393988,5393989,5393990,5393991,5393992,5393993,5393994,5393995,5393996,5393997,5393998,5393999,5394000,5394001,5394002"] = "1485,1193,863,852", -- amirdrassil|4823|4x4
        ["5393927,5393928,5393929,5393930,5393931,5393932,5393933,5393934,5393935,5393936,5393937,5393938,5393939,5393940,5393941,5393942"] = "2383,840,992,948", -- ancientbough|4824|4x4
        ["5393862,5393863,5393864,5393865,5393866,5393867,5393868,5393869,5393870,5393871,5393872,5393873,5393874,5393875,5393876,5393877,5393878,5393879,5393880,5393881,5393882,5393883,5393884,5393885,5393886"] = "1729,0,1086,1044", -- eyeofysera|4825|5x5
        ["5393903,5393904,5393905,5393906,5393907,5393908,5393909,5393910,5393911,5393912,5393913,5393914,5393915,5393916,5393917,5393918,5393919,5393920,5393921,5393922,5393923,5393924,5393925,5393926"] = "1407,668,1404,891", -- lushdreamcrags|4826|6x4
        ["5393837,5393838,5393839,5393840,5393841,5393842,5393843,5393844,5393845,5393846,5393847,5393848,5393849,5393850,5393851,5393852,5393853,5393854,5393855,5393856,5393857,5393858,5393859,5393860,5393861"] = "958,0,1227,1055", -- scorchingchasm|4827|5x5
        ["5393943,5393944,5393945,5393946,5393947,5393948,5393949,5393950,5393951,5393952,5393953,5393954,5393955,5393956,5393957,5393958,5393959,5393960,5393961,5393962"] = "2026,1101,974,1153", -- shorelineroots|4828|4x5
        ["5393887,5393888,5393889,5393890,5393891,5393892,5393893,5393894,5393895,5393896,5393897,5393898,5393899,5393900,5393901,5393902"] = "866,750,941,849", -- smolderingcopse|4829|4x4
        ["5393963,5393964,5393965,5393966,5393967,5393968,5393969,5393970,5393971,5393972,5393973,5393974,5393975,5393976,5393977,5393978,5393979,5393980,5393981,5393982,5393983,5393984,5393985,5393986"] = "1433,1616,1495,944", -- twistingwood|4830|6x4
        ["5393807,5393808,5393809,5393810,5393811,5393812,5393813,5393814,5393815,5393816,5393817,5393818,5393819,5393820,5393821,5393822,5393823,5393824,5393825,5393826,5393827,5393828,5393829,5393830,5393831,5393832,5393833,5393834,5393835,5393836"] = "214,0,1262,1382", -- wellspringtemple|4831|5x6
        ["5394003,5394004,5394005,5394006,5394007,5394008,5394009,5394010,5394011,5394012,5394013,5394014,5394015,5394016,5394017,5394018,5394019,5394020,5394021,5394022,5394023,5394024,5394025,5394026,5394027,5394028,5394029,5394030,5394031,5394032,5394033,5394034,5394035,5394036,5394037,5394038,5394039,5394040,5394041,5394042,5394043,5394044"] = "362,1272,1537,1288", -- whorlwingbasin|4832|7x6
    },

    ["earthenworks"] = {
        ["6015159,6015160,6015161,6015162,6015163,6015164,6015165,6015166,6015167,6015178,6015181,6015183,6015184,6015185,6015186,6015187,6015188,6015189,6015190,6015191"] = "704,230,1023,1091", -- coreway|4863|4x5
        ["6015094,6015095,6015096,6015097,6015098,6015099,6015100,6015101,6015102,6015103,6015104,6015105,6015106,6015107,6015108,6015109,6015110,6015111,6015112,6015113,6015114"] = "1846,657,1590,691", -- extractionsite|4864|7x3
        ["6015150,6015151,6015152,6015153,6015154,6015155,6015156,6015157,6015158"] = "1504,508,610,612", -- gundargaz|4865|3x3
        ["6014950,6014951,6014952,6014953,6014954,6014955,6014956,6014957,6014958,6014959,6014960,6014961,6014962,6014963,6014964,6014965,6014966,6014967,6014968,6014969,6014970,6014974,6014975,6014976,6014977,6014978,6014979,6014980,6014981,6014982,6014983,6014984,6014985,6014986,6014987"] = "649,1300,1692,1260", -- livinggrotto|4866|7x5
        ["6015115,6015116,6015117,6015118,6015119,6015120,6015121,6015122,6015123,6015124,6015125,6015126,6015127,6015128,6015129,6015130,6015131,6015132,6015133,6015134,6015135,6015136,6015137,6015138,6015139,6015140,6015141,6015142,6015143,6015144,6015145,6015146,6015147,6015148,6015149"] = "1823,0,1604,1056", -- lostmines|4867|7x5
        ["6014988,6014989,6014990,6014991,6014992,6014993,6014994,6014995,6014996,6014997,6014998,6014999,6015000,6015001,6015002,6015003,6015004,6015005,6015006,6015007,6015008,6015009,6015010,6015011"] = "1813,1617,1427,943", -- opportunity|4868|6x4
        ["6015036,6015037,6015038,6015039,6015040,6015041,6015042,6015043,6015044,6015045,6015053,6015057,6015058,6015059,6015060,6015061,6015062,6015063,6015064,6015065,6015066,6015067,6015068,6015069"] = "1636,873,1497,910", -- shadowvein|4869|6x4
        ["6015012,6015013,6015014,6015015,6015016,6015017,6015018,6015019,6015020,6015021,6015022,6015023,6015024,6015025,6015026,6015027,6015028,6015029,6015030,6015031,6015032,6015033,6015034,6015035"] = "1845,1138,1473,913", -- taelloch|4870|6x4
        ["6015070,6015071,6015072,6015073,6015074,6015075,6015076,6015077,6015078,6015079,6015080,6015081,6015082,6015083,6015084,6015085,6015086,6015087,6015088,6015089,6015090,6015091,6015092,6015093"] = "754,834,1284,866", -- waterworks|4871|6x4
        ["6019756,6019767,6019777,6019778,6019779,6019780,6019781,6019782,6019783,6019757,6019758,6019759,6019760,6019761,6019762,6019763,6019764,6019765,6019766,6019768,6019769,6019770,6019771,6019772,6019773,6019774,6019775,6019776"] = "768,0,1649,802", -- stonevault|4872|7x4
        ["6330350,6330361,6330368,6330369,6330370,6330371,6330372,6330373,6330374,6330351,6330352,6330353,6330354,6330355,6330356,6330357,6330358,6330359,6330360,6330362,6330363,6330364,6330365,6330366,6330367"] = "2280,1390,1152,1170", -- gutterville|4888|5x5
    },

    ["arathorcanyons"] = {
        ["6014106,6014107,6014108,6014109,6014110,6014111,6014112,6014113,6014114,6014115,6014116,6014117,6014118,6014119,6014120,6014121,6014122,6014123,6014124,6014125,6014126,6014127,6014128,6014129,6014130,6014131,6014132,6014133,6014134,6014135,6014136,6014137,6014138,6014139,6014140,6014141,6014142,6014143,6014144,6014145,6014146,6014147,6014148,6014149,6014150,6014151,6014152,6014153"] = "1781,1253,1992,1307", -- aegiswall|4834|8x6
        ["6013983,6013984,6013985,6013986,6013987,6013988,6013989,6013990,6013991,6013992,6013993,6013994,6013995,6013996,6013997,6013998,6013999,6014000,6014001,6014002,6014003,6014004,6014005,6014006,6014007,6014008,6014009,6014010,6014011,6014012"] = "2433,399,1407,1198", -- dunelle|4835|6x5
        ["6014091,6014092,6014093,6014094,6014095,6014096,6014097,6014098,6014099,6014100,6014101,6014102,6014103,6014104,6014105"] = "1719,1002,1166,619", -- fangs|4836|5x3
        ["6014013,6014014,6014015,6014016,6014017,6014018,6014019,6014020,6014021,6014022,6014023,6014024,6014025,6014026,6014027,6014028,6014029,6014030,6014031,6014032,6014033,6014034,6014035,6014036,6014037,6014038,6014039,6014040,6014041,6014042,6014043,6014044,6014045,6014046,6014047,6014048,6014049,6014050,6014051,6014052,6014053,6014054,6014055,6014056,6014057,6014058,6014059,6014060"] = "1865,0,1975,1338", -- lightsblooming|4837|8x6
        ["6014278,6014280,6014283,6014284,6014285,6014286,6014287,6014288,6014289,6014290,6014291,6014292,6014293,6014294,6014295,6014296,6014297,6014298,6014299,6014300,6014301,6014302,6014303,6014304,6014305,6014306,6014307,6014308,6014309,6014310,6014311,6014312,6014313,6014314,6014315,6014316,6014317,6014318,6014319,6014320"] = "487,1586,2459,974", -- lightsredoubt|4838|10x4
        ["6014061,6014062,6014063,6014064,6014065,6014066,6014067,6014068,6014069,6014070,6014071,6014072,6014073,6014074,6014075,6014076,6014077,6014078,6014079,6014080,6014081,6014082,6014083,6014084,6014085,6014086,6014087,6014088,6014089,6014090"] = "1407,0,1232,1341", -- lorelscrossing|4839|5x6
        ["6014154,6014155,6014156,6014157,6014158,6014159,6014160,6014161,6014162,6014163,6014164,6014165,6014166,6014167,6014168,6014169,6014170,6014171,6014172,6014173,6014174,6014175,6014176,6014177"] = "666,976,1441,1024", -- mereldar|4840|6x4
        ["6014178,6014179,6014180,6014181,6014182,6014183,6014184,6014185,6014186,6014187,6014188,6014189,6014190,6014191,6014192,6014193,6014194,6014195,6014196,6014197,6014198,6014199,6014200,6014201,6014202,6014203,6014204,6014205,6014206,6014207"] = "429,161,1490,1082", -- priory|4841|6x5
        ["6014208,6014209,6014210,6014211,6014212,6014213,6014214,6014215,6014216,6014217,6014218,6014219,6014220,6014221,6014222,6014223,6014224,6014225,6014226,6014227,6014228,6014229,6014230,6014231,6014232,6014233,6014234,6014235,6014236,6014237,6014238,6014239,6014240,6014241,6014242,6014243,6014244,6014245,6014246,6014247,6014248,6014249,6014250,6014251,6014252,6014253,6014254,6014255,6014256,6014257,6014258,6014259,6014260,6014261,6014262,6014263,6014264,6014265,6014266,6014267,6014268,6014269,6014270,6014271,6014272,6014273,6014274,6014275,6014276,6014277"] = "0,0,1723,2560", -- undersea|4842|7x10
    },

    ["isleofdorn"] = {
        ["6015192,6015193,6015194,6015195,6015196,6015197,6015198,6015199,6015200,6015201,6015202,6015203,6015204,6015205,6015206,6015207,6015208,6015209,6015210,6015211,6015212,6015213,6015214,6015215,6015216,6015217,6015218,6015219"] = "1145,0,1734,969", -- dharkazhad|4875|7x4
        ["6015272,6015273,6015274,6015275,6015276,6015277,6015278,6015279,6015280,6015281,6015282,6015283,6015284,6015285,6015286,6015287,6015288,6015289,6015290,6015291"] = "2007,1094,1127,786", -- bouldersprings|4876|5x4
        ["6015252,6015253,6015254,6015255,6015256,6015257,6015258,6015259,6015260,6015261,6015262,6015263,6015264,6015265,6015266,6015267,6015268,6015269,6015270,6015271"] = "2470,716,1122,941", -- cinderbrew|4877|5x4
        ["6015377,6015378,6015379,6015380,6015381,6015382,6015383,6015384,6015385,6015399,6015400,6015401,6015402,6015403,6015404,6015405,6015406,6015407,6015408,6015409,6015410,6015411,6015412,6015413,6015414,6015415,6015416,6015417,6015418,6015419"] = "331,821,1210,1335", -- dharoztan|4878|5x6
        ["6015307,6015308,6015309,6015310,6015311,6015312,6015313,6015314,6015315,6015316,6015317,6015318,6015319,6015320,6015321,6015322,6015323,6015324,6015325,6015326,6015327,6015328,6015329,6015330"] = "967,558,1409,1002", -- dornogal|4879|6x4
        ["6015361,6015362,6015363,6015364,6015365,6015366,6015367,6015368,6015369,6015370,6015371,6015372,6015373,6015374,6015375,6015376"] = "993,1615,1010,899", -- freywold|4880|4x4
        ["6015331,6015332,6015333,6015334,6015335,6015336,6015337,6015338,6015339,6015340,6015341,6015342,6015343,6015344,6015345,6015346,6015347,6015348,6015349,6015350,6015351,6015352,6015353,6015354,6015355,6015356,6015357,6015358,6015359,6015360"] = "1551,1499,1480,1061", -- golgrin|4881|6x5
        ["6015292,6015293,6015294,6015295,6015296,6015297,6015298,6015299,6015300,6015301,6015302,6015303,6015304,6015305,6015306"] = "1274,1298,1054,668", -- opalgreg|4883|5x3
        ["6015240,6015241,6015242,6015243,6015244,6015245,6015246,6015247,6015248,6015249,6015250,6015251"] = "2005,530,725,792", -- rambleshire|4884|3x4
        ["6015220,6015221,6015222,6015223,6015224,6015225,6015226,6015227,6015228,6015229,6015230,6015231,6015232,6015233,6015234,6015235,6015236,6015237,6015238,6015239"] = "2359,223,1095,784", -- threeshields|4885|5x4
        ["6226977,6226988,6226995,6226996,6226997,6226998,6226999,6227000,6227001,6226978,6226979,6226980,6226981,6226982,6226983,6226984,6226985,6226986,6226987,6226989,6226990,6226991,6226992,6226993,6226994"] = "70,82,1118,1258", -- sirenisle|4887|5x5
    },

    ["azjkahet"] = {
        ["6013727,6013728,6013729,6013730,6013731,6013732,6013733,6013734,6013735,6013736,6013737,6013738,6013739,6013740,6013741,6013742,6013743,6013744,6013745,6013746,6013747,6013748,6013749,6013750,6013751,6013752,6013753,6013754,6013755,6013756,6013757,6013758,6013759,6013760,6013761,6013762,6013763,6013764,6013765,6013766"] = "1845,0,1995,1151", -- crawlingchasm|4843|8x5
        ["6013587,6013588,6013589,6013590,6013591,6013592,6013593,6013594,6013595,6013596,6013597,6013598,6013599,6013600,6013601,6013602"] = "1653,1780,876,780", -- highhollows|4844|4x4
        ["6013420,6013421,6013422,6013423,6013424,6013425,6013426,6013427,6013428,6013429,6013430,6013431,6013432,6013433,6013434,6013435,6013436,6013437,6013438,6013439,6013440,6013441,6013442,6013443,6013444,6013445,6013446,6013447,6013448,6013449,6013450,6013451,6013452,6013453,6013454,6013455,6013456,6013457,6013458,6013459,6013460,6013461,6013462,6013463,6013464,6013465,6013466,6013467,6013468"] = "756,0,1628,1647", -- lightless|4845|7x7
        ["6013643,6013644,6013645,6013646,6013647,6013648,6013649,6013650,6013651,6013652,6013653,6013654,6013655,6013656,6013657,6013658,6013659,6013660,6013661,6013662,6013663,6013664,6013665,6013666,6013667,6013668,6013669,6013670,6013671,6013672,6013673,6013674,6013675,6013676,6013677,6013678,6013679,6013680,6013681,6013682,6013683,6013684"] = "2129,1181,1711,1379", -- rakush|4846|7x6
        ["6013469,6013470,6013471,6013472,6013473,6013474,6013475,6013476,6013477,6013478,6013479,6013480,6013481,6013482,6013483,6013484,6013485,6013486,6013487,6013488,6013489,6013490,6013491,6013492,6013493,6013494,6013495,6013496,6013497,6013498,6013499,6013500,6013501,6013502,6013503,6013504,6013505,6013506,6013507,6013508,6013509,6013510,6013511,6013512,6013513,6013514,6013515,6013516,6013517,6013518,6013519,6013520,6013521,6013522,6013523,6013524"] = "0,0,1704,1897", -- rupturedlake|4847|7x8
        ["6013525,6013526,6013527,6013528,6013529,6013530,6013531,6013532,6013533,6013534,6013535,6013536,6013537,6013538,6013539,6013540,6013541,6013542,6013543,6013544,6013545,6013546,6013547,6013548,6013549,6013550,6013551,6013552,6013553,6013554"] = "383,1379,1467,1181", -- theskeins|4848|6x5
        ["6013603,6013604,6013605,6013606,6013607,6013608,6013609,6013610,6013611,6013612,6013613,6013614,6013615,6013616,6013617,6013618,6013619,6013620,6013621,6013622,6013623,6013624,6013625,6013626,6013627,6013628,6013629,6013630,6013631,6013632,6013633,6013634,6013635,6013636,6013637,6013638,6013639,6013640,6013641,6013642"] = "1424,1308,1844,1252", -- twichinggorge|4849|8x5
        ["6013555,6013556,6013557,6013558,6013559,6013560,6013561,6013562,6013563,6013564,6013565,6013566,6013567,6013568,6013569,6013570,6013571,6013572,6013573,6013574,6013575,6013576,6013577,6013578,6013579,6013580,6013581,6013582,6013583,6013584,6013585,6013586"] = "422,1612,1819,948", -- umbralbazaar|4850|8x4
        ["6013685,6013686,6013687,6013688,6013689,6013690,6013691,6013692,6013693,6013694,6013695,6013696,6013697,6013698,6013699,6013700,6013701,6013702,6013703,6013704,6013705,6013706,6013707,6013708,6013709,6013710,6013711,6013712,6013713,6013714,6013715,6013716,6013717,6013718,6013719,6013720,6013721,6013722,6013723,6013724,6013725,6013726"] = "2227,401,1613,1379", -- untamedvalley|4851|7x6
        ["6013404,6013405,6013406,6013407,6013408,6013409,6013410,6013411,6013412,6013413,6013414,6013415,6013416,6013417,6013418,6013419"] = "1649,686,991,934", -- weaverslair|4852|4x4
    },

    ["azjkahet_lower"] = {
        ["6014521,6014522,6014523,6014524,6014525,6014526,6014527,6014528,6014529,6014530,6014531,6014532,6014533,6014534,6014535,6014536"] = "1649,686,991,934", -- weaverslair|4853|4x4
        ["6014852,6014853,6014854,6014855,6014856,6014857,6014858,6014859,6014860,6014861,6014869,6014873,6014875,6014876,6014877,6014878,6014879,6014880,6014881,6014882,6014883,6014884,6014885,6014886,6014887,6014888,6014889,6014890,6014891,6014892,6014893,6014894,6014895,6014896,6014897,6014898,6014899,6014900,6014901,6014902"] = "1845,0,1995,1151", -- crawlingchasm|4854|8x5
        ["6014704,6014705,6014706,6014707,6014708,6014709,6014710,6014711,6014712,6014713,6014714,6014715,6014716,6014717,6014718,6014719"] = "1653,1780,876,780", -- highhollows|4855|4x4
        ["6014537,6014538,6014539,6014540,6014541,6014542,6014543,6014544,6014545,6014546,6014547,6014548,6014549,6014550,6014551,6014552,6014553,6014554,6014555,6014556,6014557,6014558,6014559,6014560,6014561,6014562,6014563,6014564,6014565,6014566,6014567,6014568,6014569,6014570,6014571,6014572,6014573,6014574,6014575,6014576,6014577,6014578,6014579,6014580,6014581,6014582,6014583,6014584,6014585"] = "756,0,1628,1647", -- lightless|4856|7x7
        ["6014764,6014765,6014766,6014767,6014768,6014769,6014770,6014771,6014772,6014773,6014774,6014775,6014776,6014777,6014778,6014779,6014784,6014785,6014786,6014787,6014788,6014789,6014790,6014791,6014792,6014793,6014794,6014795,6014796,6014797,6014798,6014799,6014800,6014801,6014802,6014803,6014804,6014805,6014806,6014807,6014808,6014809"] = "2129,1181,1711,1379", -- rakush|4857|7x6
        ["6014586,6014587,6014588,6014589,6014590,6014591,6014592,6014593,6014594,6014595,6014596,6014597,6014598,6014599,6014600,6014601,6014602,6014603,6014604,6014605,6014606,6014607,6014608,6014609,6014610,6014611,6014612,6014613,6014614,6014615,6014616,6014617,6014618,6014619,6014620,6014621,6014622,6014623,6014624,6014625,6014626,6014627,6014628,6014629,6014630,6014631,6014632,6014633,6014634,6014635,6014636,6014637,6014638,6014639,6014640,6014641"] = "0,0,1704,1897", -- rupturedlake|4858|7x8
        ["6014642,6014643,6014644,6014645,6014646,6014647,6014648,6014649,6014650,6014651,6014652,6014653,6014654,6014655,6014656,6014657,6014658,6014659,6014660,6014661,6014662,6014663,6014664,6014665,6014666,6014667,6014668,6014669,6014670,6014671"] = "383,1379,1467,1181", -- theskeins|4859|6x5
        ["6014720,6014721,6014722,6014723,6014724,6014725,6014726,6014727,6014728,6014729,6014730,6014731,6014732,6014733,6014734,6014735,6014736,6014737,6014738,6014739,6014740,6014741,6014742,6014743,6014744,6014745,6014746,6014747,6014748,6014753,6014754,6014755,6014756,6014757,6014758,6014759,6014760,6014761,6014762,6014763"] = "1424,1308,1844,1252", -- twichinggorge|4860|8x5
        ["6014672,6014673,6014674,6014675,6014676,6014677,6014678,6014679,6014680,6014681,6014682,6014683,6014684,6014685,6014686,6014687,6014688,6014689,6014690,6014691,6014692,6014693,6014694,6014695,6014696,6014697,6014698,6014699,6014700,6014701,6014702,6014703"] = "422,1612,1819,948", -- umbralbazaar|4861|8x4
        ["6014810,6014811,6014812,6014813,6014814,6014815,6014816,6014817,6014818,6014819,6014820,6014821,6014822,6014823,6014824,6014825,6014826,6014827,6014828,6014829,6014830,6014831,6014832,6014833,6014834,6014835,6014836,6014837,6014838,6014839,6014840,6014841,6014842,6014843,6014844,6014845,6014846,6014847,6014848,6014849,6014850,6014851"] = "2227,401,1613,1379", -- untamedvalley|4862|7x6
    },

    ["underminezone"] = {
        ["6369087,6369100,6369107,6369108,6369109,6369110,6369111,6369112,6369113,6369088,6369089,6369090,6369091,6369093,6369095,6369096,6369097,6369098,6369099,6369101,6369102,6369103,6369104,6369105,6369106"] = "1071,5,1177,1213", -- bilgewater|4889|5x5
        ["6369114,6369125,6369127,6369128,6369129,6369130,6369131,6369132,6369133,6369115,6369116,6369117,6369118,6369119,6369120,6369121,6369122,6369123,6369124,6369126"] = "2080,0,1179,990", -- blackwater|4890|5x4
        ["6369134,6369142,6369143,6369144,6369145,6369146,6369147,6369148,6369149,6369135,6369136,6369137,6369138,6369139,6369140,6369141"] = "1500,0,967,825", -- demolitiondome|4891|4x4
        ["6369150,6369161,6369171,6369172,6369173,6369174,6369175,6369176,6369177,6369151,6369152,6369153,6369154,6369155,6369156,6369157,6369158,6369159,6369160,6369162,6369163,6369164,6369165,6369166,6369167,6369168,6369169,6369170"] = "1766,665,1637,966", -- gallagio|4892|7x4
        ["6369178,6369189,6369196,6369197,6369198,6369199,6369200,6369201,6369202,6369179,6369180,6369181,6369182,6369183,6369184,6369185,6369186,6369187,6369188,6369190,6369191,6369192,6369193,6369194,6369195"] = "2304,1347,1151,1083", -- golfcourse|4893|5x5
        ["6369203,6369242,6369267,6369284,6369285,6369286,6369287,6369288,6369289,6369204,6369205,6369207,6369208,6369209,6369210,6369237,6369238,6369239,6369240,6369243,6369244,6369245,6369247,6369248,6369249,6369250,6369252,6369253,6369254,6369277,6369278,6369279,6369280,6369281,6369282,6369283"] = "1466,1261,1482,1299", -- heaps|4894|6x6
        ["6369290,6369336,6369343,6369344,6369345,6369346,6369347,6369352,6369369,6369291,6369292,6369293,6369294,6369295,6369296,6369320,6369333,6369334,6369335,6369337,6369338,6369339,6369340,6369341,6369342"] = "639,277,1092,1059", -- hovelhill|4895|5x5
        ["6369370,6369381,6369409,6369414,6369416,6369417,6369418,6369419,6369420,6369371,6369372,6369373,6369374,6369375,6369376,6369377,6369378,6369379,6369380,6369382,6369383,6369384,6369393,6369407"] = "168,955,1801,668", -- slamcentral|4896|8x3
        ["6369535,6369575,6369582,6369583,6369584,6369585,6369586,6369587,6369611,6369536,6369537,6369538,6369539,6369540,6369570,6369571,6369572,6369573,6369574,6369576,6369577,6369578,6369579,6369580,6369581"] = "536,1282,1214,1278", -- vatworks|4897|5x5
    },

    ["karesh"] = {
        ["6995959,6995960,6995961,6995962,6995963,6995964,6995965,6995966,6995967"] = "2111,680,734,759", -- castigaar|4929|3x3
        ["6995969,6995977,6995978,6995979,6995980,6995981,6995982,6995983,6995984,6995970,6995971,6995972,6995973,6995974,6995975,6995976,7002084,7002085,7002086,7002087"] = "2435,410,1052,786", -- oasis|4930|5x4
        ["6995985,6995996,6996003,6996004,6996005,6996006,6996007,6996008,6996009,6995986,6995987,6995988,6995989,6995990,6995991,6995992,6995993,6995994,6995995,6995997,6995998,6995999,6996000,6996001,6996002"] = "1273,878,1224,1151", -- primus|4931|5x5
        ["6996010,6996022,6996024,6996025,6996026,6996027,6996028,6996029,6996030,6996011,6996012,6996014,6996015,6996016,6996017,6996018,6996019,6996020,6996021,6996023"] = "2349,968,1215,797", -- rhovan|4932|5x4
        ["6996031,6996039,6996040,6996041,6996042,6996043,6996044,6996045,6996046,6996032,6996033,6996034,6996035,6996036,6996037,6996038"] = "1208,73,959,829", -- shadowpoint|4933|4x4
        ["6996047,6996048,6996049,6996050,6996051,6996052,6996053,6996054,6996055"] = "1911,232,747,724", -- shandorah|4934|3x3
        ["6996056,6996087,6996099,6996108,6996111,6996112,6996113,6996114,6996115,6996057,6996058,6996059,6996060,6996063,6996065,6996069,6996074,6996078,6996082,6996094,7002094,7002095,7002096,7002097"] = "1909,1587,1333,973", -- tazavesh|4935|6x4
        ["6996116,6996117,6996118,6996119"] = "2606,64,378,414", -- vanquisher|4936|2x2
        ["6996120,6996124,6996125,6996126,6996127,6996128,6996129,6996130,6996131,6996121,6996122,6996123,7002121,7002126,7002133"] = "1251,702,1026,610", -- zoshuul|4937|5x3
    },

    ["eversongwoodsek"] = {
        ["7577998,7577999,7578000,7578001,7578002,7578003,7578004,7578005,7578006,7578007,7578008,7578009,7578010,7578011,7578012,7578013,7578014,7578015,7578016,7578017"] = "1790,1706,1093,854", -- newamani|4942|5x4
        ["7578113,7578114,7578115,7578116,7578117,7578118,7578119,7578120,7578122,7578123,7578124,7578125,7578126,7578127,7578128"] = "2189,265,661,1040", -- newbrightwing|4943|3x5
        ["7578083,7578084,7578085,7578091,7578102,7578103,7578104,7578105,7578106,7578107,7578108,7578109,7578110,7578111,7578112"] = "1217,768,1155,726", -- newfairbreeze|4944|5x3
        ["7578070,7578071,7578072,7578073,7578074,7578075,7578076,7578078,7578079,7578080,7578081,7578082"] = "1069,1105,1017,705", -- newgoldenmist|4945|4x3
        ["7578129,7578130,7578131,7578132,7578133,7578134,7578135,7578136,7578137,7578138,7578139,7578140,7578141,7578142,7578143,7578144,7578145,7578146,7578147,7578148,7578149,7578150,7578151,7578152,7578153"] = "1364,0,1198,1169", -- newsilvermoon|4946|5x5
        ["7578050,7578051,7578052,7578053,7578054,7578055,7578056,7578057,7578058,7578059,7578060,7578061,7578062,7578063,7578064,7578065,7578066,7578067,7578068,7578069"] = "1800,1063,1190,856", -- newsuncrown|4947|5x4
        ["7578154,7578155,7578156,7578157,7578158,7578159,7578160,7578161,7578162,7578163,7578164,7578165,7578166,7578167,7578168,7578169"] = "1050,0,858,795", -- newsunstriderisle|4948|4x4
        ["7578038,7578039,7578040,7578041,7578042,7578043,7578044,7578045,7578046,7578047,7578048,7578049"] = "1517,1534,804,697", -- newtranquillien|4949|4x3
        ["7578018,7578019,7578020,7578021,7578022,7578023,7578024,7578025,7578026,7578027,7578028,7578029,7578030,7578031,7578032,7578033,7578034,7578035,7578036,7578037"] = "846,1591,1243,969", -- newwindrunner|4950|5x4
    },

    ["voidstorm"] = {
        ["7580968,7580969,7580970,7580971,7580972,7580973,7580974,7580975,7580976,7580977,7580978,7580979,7580980,7580981,7580982,7580983,7580984,7580985,7580986,7580987,7580988,7580989,7580990,7580991,7580992,7580993,7580994,7580995,7580996,7580997"] = "0,528,1334,1191", -- antius|4964|6x5
        ["7580956,7580957,7580958,7580959,7580960,7580961,7580962,7580963,7580964,7580965,7580966,7580967"] = "746,626,923,714", -- etherealrise|4965|4x3
        ["7581069,7581070,7581071,7581072,7581073,7581074,7581075,7581076,7581077"] = "1549,1490,756,732", -- howlingridge|4966|3x3
        ["7581033,7581034,7581035,7581036,7581037,7581038,7581039,7581040,7581041,7581042,7581043,7581044,7581045,7581046,7581047,7581048,7581049,7581050,7581051,7581052,7581053,7581054,7581055,7581056,7581057,7581058,7581059,7581060,7581061,7581062,7581063,7581064,7581065,7581066,7581067,7581068"] = "0,1705,2207,855", -- midar|4967|9x4
        ["7581078,7581079,7581080,7581081,7581082,7581083,7581084,7581085,7581086,7581087,7581088,7581089,7581090,7581091,7581092,7581093,7581094,7581095,7581096,7581097,7581098,7581099,7581100,7581101,7581102,7581103,7581104,7581105,7581106,7581107,7581108,7581109"] = "1914,1570,1926,990", -- obscurion|4968|8x4
        ["7580866,7580867,7580868,7580869,7580870,7580871,7580872,7580873,7580874,7580875,7580876,7580877,7580878,7580879,7580880,7580881,7580882,7580883,7580884,7580885,7580886,7580887,7580888,7580889,7580890,7580891,7580892,7580893,7580894,7580895,7580896,7580897,7580898,7580899,7580900,7580901,7580902,7580903,7580904,7580905,7580906,7580907,7580908,7580909,7580910,7580911,7580912,7580913,7580914,7580915,7580916,7580917,7580918,7580919,7580920,7580921,7580922,7580923,7580924,7580925,7580926,7580927,7580928,7580929,7580930,7580931,7580932,7580933,7580934,7580935,7580936,7580937,7580938,7580939,7580940,7580941,7580942,7580943,7580944,7580945,7580946,7580947,7580948,7580949,7580950,7580951,7580952,7580953,7580954,7580955"] = "0,0,3840,1374", -- slayersrise|4969|15x6
        ["7581015,7581016,7581017,7581018,7581019,7581020,7581021,7581022,7581023,7581024,7581025,7581026,7581027,7581028,7581029,7581030,7581031,7581032"] = "0,1427,1481,705", -- stormarion|4970|6x3
        ["7580998,7580999,7581001,7581002,7581003,7581004,7581005,7581006,7581007,7581008,7581009,7581010,7581011,7581012,7581013,7581014"] = "1006,972,866,915", -- stormfields|4971|4x4
        ["7581110,7581111,7581112,7581113,7581114,7581115,7581116,7581117,7581118,7581119,7581120,7581121,7581122,7581123,7581124,7581125,7581126,7581127,7581128,7581129,7581130,7581131,7581132,7581133,7581134,7581135,7581136,7581137,7581138,7581139,7581140,7581141,7581142,7581143,7581144,7581145,7581146,7581147,7581148,7581149,7581150,7581151,7581152,7581153,7581154"] = "1654,543,2186,1223", -- voidspire|4972|9x5
        ["7581155,7581156,7581157,7581158,7581159,7581160,7581161,7581162,7581163,7581164,7581165,7581166,7581167,7581168,7581169,7581170,7581171,7581172,7581173,7581174,7581175,7581176,7581177,7581178,7581179,7581180,7581181,7581182,7581183,7581184,7581185,7581186"] = "2026,1183,1814,770", -- xenas|4973|8x4
    },

    ["harandar"] = {
        ["7581940,7581941,7581942,7581943,7581944,7581945,7581946,7581947,7581948,7581949,7581950,7581951,7581952,7581953,7581954,7581955,7581956,7581957,7581958,7581959,7581960,7581961,7581962,7581963"] = "1630,0,890,1348", -- bloominglattice|4974|4x6
        ["7581900,7581901,7581902,7581903,7581904,7581905,7581906,7581907,7581908,7581909,7581910,7581911,7581912,7581913,7581914"] = "860,830,1117,640", -- denechoes|4975|5x3
        ["7581973,7581974,7581975,7581976,7581977,7581978,7581979,7581980,7581981"] = "1306,1503,643,614", -- fungara|4976|3x3
        ["7581982,7581983,7581984,7581985,7581986,7581987,7581988,7581989,7581990,7581991,7581992,7581993,7581994,7581995,7581996,7581997,7581998,7581999,7582000,7582001"] = "1588,1524,786,1025", -- gloommire|4977|4x5
        ["7582050,7582051,7582052,7582053,7582054,7582055,7582056,7582057,7582058,7582059,7582060,7582061,7582062,7582063,7582064,7582065"] = "2411,1250,913,886", -- grudgepit|4978|4x4
        ["7581876,7581877,7581878,7581879,7581880,7581881,7581882,7581883,7581884,7581885,7581886,7581887,7581888,7581889,7581890,7581891,7581892,7581893,7581894,7581895,7581896,7581897,7581898,7581899"] = "508,1225,1323,818", -- haralnor|4979|6x4
        ["7582035,7582036,7582037,7582038,7582039,7582040,7582041,7582042,7582043,7582044,7582045,7582046,7582047,7582048,7582049"] = "2517,440,763,1137", -- harathir|4980|3x5
        ["7582019,7582020,7582021,7582022,7582023,7582024,7582025,7582026,7582027,7582028,7582029,7582030,7582031,7582032,7582033,7582034"] = "2242,232,779,962", -- harkuai|4981|4x4
        ["7581915,7581916,7581917,7581918,7581919,7581920,7581921,7581922,7581923,7581924,7581925,7581926,7581927,7581928,7581929,7581930,7581931,7581932,7581933,7581934,7581935,7581936,7581937,7581938,7581939"] = "805,0,1100,1065", -- harmara|4982|5x5
        ["7581851,7581852,7581853,7581854,7581855,7581856,7581857,7581858,7581859,7581860,7581861,7581862,7581863,7581864,7581865,7581866,7581867,7581868,7581869,7581870,7581871,7581872,7581873,7581874,7581875"] = "609,1535,1160,1025", -- lightbloom|4983|5x5
        ["7582002,7582003,7582004,7582005,7582006,7582007,7582008,7582009"] = "2153,1269,491,830", -- riftofaln|4984|2x4
        ["7581964,7581965,7581966,7581967,7581968,7581969,7581970,7581971,7581972"] = "1677,980,637,753", -- theden|4985|3x3
        ["7582010,7582011,7582012,7582013,7582014,7582015,7582016,7582017,7582018"] = "2010,999,686,563", -- valeofmists|4986|3x3
    },

    ["newqueldanas"] = {
        ["7578743,7578744,7578745,7578746,7578747,7578748,7578749,7578750,7578751,7578752,7578753,7578754,7578755,7578756,7578757,7578758,7578759,7578760,7578761,7578762,7578763,7578764,7578765,7578766,7578767,7578768,7578769,7578770,7578771,7578772,7578773,7578774,7578775,7578776,7578777,7578778,7578779,7578780,7578781,7578782,7578783,7578784,7578785,7578786,7578787,7578788,7578789,7578790"] = "1431,651,1421,1909", -- newsunwell|4951|6x8
        ["7578791,7578792,7578793,7578794,7578795,7578796,7578797,7578798,7578799,7578800,7578801,7578802,7578803,7578804,7578805,7578806,7578807,7578808,7578809,7578810,7578811,7578812,7578813,7578814,7578815,7578816,7578817,7578818,7578819,7578820"] = "2015,0,1331,1082", -- newmagisters|4952|6x5
        ["7578821,7578822,7578823,7578824,7578825,7578826,7578827,7578828,7578829,7578830,7578831,7578832,7578833,7578834,7578835,7578836,7578837,7578838,7578839,7578840,7578841,7578842,7578843,7578844,7578845,7578846,7578847,7578848,7578849,7578850,7578851,7578852,7578853,7578854,7578855,7578856,7578857,7578858,7578859,7578860,7578861,7578862"] = "811,0,1520,1720", -- newparhelion|4953|6x7
    },

    ["newzulaman"] = {
        ["7580217,7580218,7580219,7580220,7580221,7580222,7580223,7580224,7580225,7580226,7580227,7580228,7580229,7580230,7580231,7580232"] = "1646,1561,870,974", -- akilzon|4954|4x4
        ["7580233,7580234,7580235,7580236,7580237,7580238,7580239,7580240,7580241,7580242,7580243,7580244,7580245,7580246,7580247,7580248"] = "1200,1360,1009,776", -- amanizar|4955|4x4
        ["7580284,7580285,7580286,7580287,7580288,7580289,7580290,7580291,7580292,7580293,7580294,7580295,7580296,7580297,7580298,7580299,7580300,7580301,7580302,7580303,7580304,7580305,7580306,7580307"] = "228,1006,1373,800", -- atalaman|4956|6x4
        ["7580264,7580265,7580266,7580267,7580268,7580269,7580270,7580271,7580272,7580273,7580274,7580275,7580276,7580277,7580278,7580279,7580280,7580281,7580282,7580283"] = "305,1521,1063,949", -- brokenthrone|4957|5x4
        ["7580360,7580361,7580362,7580363,7580364,7580365,7580366,7580367,7580368,7580369,7580370,7580371,7580372,7580373,7580374,7580375,7580376,7580377,7580378,7580379"] = "461,275,1049,977", -- halazzi|4958|5x4
        ["7580324,7580325,7580326,7580327,7580328,7580329,7580330,7580331,7580332,7580333,7580334,7580335,7580336,7580337,7580338,7580339"] = "1533,91,899,953", -- janalai|4959|4x4
        ["7580308,7580309,7580310,7580311,7580312,7580313,7580314,7580315,7580316,7580317,7580318,7580319,7580320,7580321,7580322,7580323"] = "1319,698,816,827", -- maisaradeeps|4960|4x4
        ["7580249,7580250,7580251,7580252,7580253,7580254,7580255,7580256,7580257,7580258,7580259,7580260,7580261,7580262,7580263"] = "687,1904,1172,656", -- nalorakk|4961|5x3
        ["7580177,7580178,7580179,7580180,7580181,7580182,7580183,7580184,7580185,7580186,7580187,7580188,7580189,7580190,7580191,7580192,7580193,7580194,7580195,7580196,7580197,7580198,7580199,7580200,7580201,7580202,7580203,7580204,7580205,7580206,7580207,7580208,7580209,7580210,7580211,7580212,7580213,7580214,7580215,7580216"] = "1967,70,1250,1994", -- straightofhexxalor|4962|5x8
        ["7580340,7580341,7580342,7580343,7580344,7580345,7580346,7580347,7580348,7580349,7580350,7580351,7580352,7580353,7580354,7580355,7580356,7580357,7580358,7580359"] = "675,33,1184,820", -- witherbarkbluffs|4963|5x4
    },

    ["coiledisle"] = {
        ["8140096,8140104,8140105,8140106,8140107,8140108,8140109,8140110,8140111,8140097,8140098,8140099,8140100,8140101,8140102,8140103"] = "1228,309,874,778", -- blisteringterrace|5535|4x4
        ["8140112,8140128,8140137,8140138,8140139,8140140,8140141,8140142,8140143,8140113,8140114,8140115,8140116,8140117,8140118,8140119,8140121,8140124,8140125,8140130,8140132,8140134,8140135,8140136"] = "1253,1192,856,1323", -- gateoftheeasternfang|5536|4x6
        ["8140144,8140168,8140170,8140171,8140172,8140173,8140174,8140175,8140176,8140145,8140146,8140147,8140148,8140149,8140150,8140164,8140165,8140166,8140167,8140169"] = "1046,727,1027,845", -- gateoftheserpentseye|5537|5x4
        ["8140177,8140181,8140182,8140183,8140184,8140185,8140186,8140187,8140188,8140178,8140179,8140180"] = "1910,1726,930,666", -- gnarldorisle|5538|4x3
        ["8140189,8140200,8140206,8140207,8140208,8140209,8140210,8140211,8140217,8140190,8140191,8140192,8140193,8140194,8140195,8140196,8140197,8140198,8140199,8140201,8140202,8140203,8140204,8140205"] = "2106,18,950,1361", -- mlurkkrmire|5539|4x6
        ["8140357,8140368,8140374,8140375,8140376,8140377,8140378,8140379,8140380,8140358,8140359,8140360,8140361,8140362,8140363,8140364,8140365,8140366,8140367,8140369,8140370,8140371,8140372,8140373"] = "571,1084,967,1344", -- theforum|5540|4x6
        ["8140381,8140390,8140391,8140392,8140393,8140394,8140395,8140396,8140397,8140384,8140385,8140386,8140387,8140388,8140389"] = "1756,215,692,1092", -- theserpentstail|5541|3x5
        ["8140398,8140409,8140411,8140412,8140413,8140414,8140415,8140416,8140417,8140399,8140400,8140401,8140402,8140403,8140404,8140405,8140406,8140407,8140408,8140410"] = "2355,1118,833,1101", -- thewhisperingmarsh|5542|4x5
        ["8140418,8140422,8140423,8140424,8140425,8140426,8140427,8140428,8140429,8140419,8140420,8140421"] = "1908,834,683,877", -- tokkaslanding|5543|3x4
        ["8140430,8140431,8140432,8140433,8140434,8140435,8140436,8140437,8140438"] = "1956,1431,609,549", -- wreckofpakustalon|5544|3x3
    },

    -- UIMapID 2525 (The Darkway) uses UiMapArtID 2035, but Blizzard ships
    -- no WorldMapOverlay rows for that art.  Its absence here is intentional.
}

--------
