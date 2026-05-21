-- Carbonite | Modules / Gather / GatherStorage
-- The Carbonite gather subsystem: per-node-type herb/mine/timber
-- metadata, the GatherMate2 import remap table, the in-memory
-- gather cache, and every Nx:Gather* function (recording, lookup,
-- delete, GatherMate import). Lifted out of Carbonite.lua; methods
-- stay on Nx because the Modules/Gather/* documented surfaces
-- (Gather.lua, GatherEvents.lua, GatherEngine.lua) still proxy
-- through these.
--
-- Three earlier extractions related to gather already exist:
--   * Modules/Gather/Gather.lua           - documented public API
--   * Modules/Gather/GatherEvents.lua     - public surface for events
--   * Modules/Gather/GatherEngine.lua     - Nx:GetMaxGatherSkill /
--                                           ShouldShowGatherNode /
--                                           GetGatherNodeName
-- This file owns the data + bulk of the per-node bookkeeping.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-------------------------------------------------------------------------------
-- GATHERING SYSTEM
-- Tracks and stores locations of herb/mining nodes
-- Data structure: { skillLevel, iconPath, localizedName }
-------------------------------------------------------------------------------

Nx.GatherInfo = {
    [" "] = {    -- Misc
        ["Art"] = { 0, "Trade_Archaeology", L["Artifact"]},
        ["Everfrost"] = { 0, "spell_shadow_teleport", L["Everfrost"]},
        ["Gas"] = { 0, "inv_gizmo_zapthrottlegascollector",    L["Gas"]},
    },
    ["L"] = {    -- Timber (WoD Lumber Mill)
        { 1, "inv_tradeskillitem_03", L["Small Timber"]},
        { 2, "inv_tradeskillitem_03", L["Medium Timber"]},
        { 3, "inv_tradeskillitem_03", L["Large Timber"]},
    },
    ["H"] = {    -- Herbs (4th element is itemId for localization)
        { 340,    "inv_misc_herb_ancientlichen",L["Ancient Lichen"], 22790},
        { 220,    "inv_misc_herb_13",L["Arthas' Tears"], 8836},
        { 300,    "inv_misc_herb_17",L["Black Lotus"], 13468},
        { 235,    "inv_misc_herb_14",L["Blindweed"], 8839},
        { 1,    "inv_misc_herb_11a",L["Bloodthistle"], 22710},
        { 70,    "inv_misc_root_01",L["Briarthorn"], 2450},
        { 100,    "inv_misc_herb_01",L["Bruiseweed"], 2453},
        { 270,    "inv_misc_herb_dreamfoil",L["Dreamfoil"], 13463},
        { 315,    "inv_misc_herb_dreamingglory",L["Dreaming Glory"], 22786},
        { 15,    "inv_misc_herb_07",L["Earthroot"], 2449},
        { 160,    "inv_misc_herb_12",L["Fadeleaf"], 3818},
        { 300,    "inv_misc_herb_felweed",L["Felweed"], 22785},
        { 205,    "inv_misc_herb_19",L["Firebloom"], 4625},
        { 335,    "inv_misc_herb_flamecap",L["Flame Cap"], 22788},
        { 245,    "inv_mushroom_08",L["Ghost Mushroom"], 8845},
        { 260,    "inv_misc_herb_sansamroot",L["Golden Sansam"], 13464},
        { 170,    "inv_misc_herb_15",L["Goldthorn"], 3821},
        { 120,    "inv_misc_dust_02",L["Grave Moss"], 3369},
        { 250,    "inv_misc_herb_16",L["Gromsblood"], 8846},
        { 290,    "inv_misc_herb_iceCap",L["Icecap"], 13467},
        { 185,    "inv_misc_herb_08",L["Khadgar's Whisker"], 3358},
        { 125,    "inv_misc_herb_03",L["Kingsblood"], 3356},
        { 150,    "inv_misc_root_02",L["Liferoot"], 3357},
        { 50,    "inv_jewelry_talisman_03",L["Mageroyal"], 785},
        { 375,    "inv_misc_herb_manathistle",L["Mana Thistle"], 22793},
        { 280,    "inv_misc_herb_mountainsilversage",L["Mountain Silversage"], 13465},
        { 350,    "inv_misc_herb_netherbloom",L["Netherbloom"], 22791},
        { 350,    "inv_enchant_dustsoul",L["Netherdust Bush"], 32468},
        { 365,    "inv_misc_herb_nightmarevine",L["Nightmare Vine"], 22792},
        { 1,    "inv_misc_flower_02",L["Peacebloom"], 2447},
        { 285,    "inv_misc_herb_plaguebloom",L["Plaguebloom"], 13466},
        { 210,    "inv_misc_herb_17",L["Purple Lotus"], 8831},
        { 325,    "inv_misc_herb_ragveil",L["Ragveil"], 22787},
        { 1,    "inv_misc_herb_10",L["Silverleaf"], 765},
        { 85,    "inv_misc_herb_11",L["Stranglekelp"], 3820},
        { 230,    "inv_misc_herb_18",L["Sungrass"], 8838},
        { 325,    "inv_misc_herb_terrocone",L["Terocone"], 22789},
        { 115,    "inv_misc_flower_01",L["Wild Steelbloom"], 3355},
        { 195,    "inv_misc_flower_03",L["Dragon's Teeth"], 3819},
        { 1,    "inv_mushroom_02",L["Glowcap"], 24245},
        { 350,    "inv_misc_herb_goldclover",L["Goldclover"], 36901},
        { 385,    "inv_misc_herb_talandrasrose",L["Talandra's Rose"], 36907},
        { 400,    "inv_misc_herb_evergreenmoss",L["Adder's Tongue"], 36903},
        { 400,    "inv_misc_herb_goldclover",L["Frozen Herb"], 36908},
        { 400,    "inv_misc_herb_tigerlily",L["Tiger Lily"], 36904},
        { 425,    "inv_misc_herb_whispervine",L["Lichbloom"], 36905},
        { 435,    "inv_misc_herb_icethorn",L["Icethorn"], 36906},
        { 450,    "inv_misc_herb_frostlotus",L["Frost Lotus"], 36908},
        { 360,    "inv_misc_herb_11a",L["Firethorn"], 39970},
        { 425, "inv_misc_herb_azsharasveil", L["Azshara's Veil"], 52983},
        { 425, "inv_misc_herb_cinderbloom", L["Cinderbloom"], 52983},
        { 425, "inv_misc_herb_stormvine", L["Stormvine"], 52987},
        { 475, "inv_misc_herb_heartblossom", L["Heartblossom"], 52986},
        { 500, "inv_misc_herb_whiptail", L["Whiptail"], 52988},
        { 525, "inv_misc_herb_twilightjasmine", L["Twilight Jasmine"], 52984},
        { 600,    "inv_misc_herb_foolscap",L["Fool's Cap"], 79011},
        { 550,    "inv_misc_herb_goldenlotus",L["Golden Lotus"], 72238},
        { 500,    "inv_misc_herb_jadetealeaf",L["Green Tea Leaf"], 72234},
        { 525,    "inv_misc_herb_rainpoppy",L["Rain Poppy"], 72237},
        { 575,    "inv_misc_herb_shaherb",L["Sha-Touched Herb"], 79010},
        { 545,    "inv_misc_herb_silkweed",L["Silkweed"], 72235},
        { 550,    "inv_misc_herb_snowlily",L["Snow Lily"], 79010},
        { 550,    "inv_misc_herb_chamlotus",L["Chameleon Lotus"], 97619},
        -- WoD Herbs
        { 1,    "inv_misc_herb_frostweed",L["Frostweed"], 109124},
        { 1,    "inv_misc_herb_flytrap",L["Gorgrond Flytrap"], 109126},
        { 1,    "inv_misc_herb_starflower",L["Starflower"], 109127},
        { 1,    "inv_misc_herb_arrowbloom",L["Nagrand Arrowbloom"], 109128},
        { 1,    "inv_misc_herb_taladororchid",L["Talador Orchid"], 109129},
        { 1,    "inv_misc_herb_fireweed",L["Fireweed"], 109125},
        { 1,    "inv_farm_pumpkinseed_yellow",L["Withered Herb"], 109125},
        -- Legion Herbs
        { 1,    "inv_herbalism_70_aethril",L["Aethril"], 124101},
        { 1,    "inv_herbalism_70_dreamleaf",L["Dreamleaf"], 124102},
        { 1,    "inv_herbalism_70_felwort",L["Felwort"], 124106},
        { 1,    "inv_herbalism_70_fjarnskaggl",L["Fjarnskaggl"], 124104},
        { 1,    "inv_herbalism_70_foxflower",L["Foxflower"], 124103},
        { 1,    "inv_herbalism_70_starlightrosepetals",L["Starlight Rose"], 124105},
        { 1,    "inv_misc_herb_astralglory",L["Astral Glory"], 151565},
        -- BfA Herbs
        { 1,    "inv_misc_herb_akundasbite",L["Akunda's Bite"], 152507},
        { 1,    "inv_misc_herb_anchorweed",L["Anchor Weed"], 152510},
        { 1,    "inv_misc_herb_riverbud",L["Riverbud"], 152505},
        { 1,    "inv_misc_herb_seastalk",L["Sea Stalks"], 152511},
        { 1,    "inv_misc_herb_pollen",L["Siren's Sting"], 152509},
        { 1,    "inv_misc_herb_starmoss",L["Star Moss"], 152506},
        { 1,    "inv_misc_herb_winterskiss",L["Winter's Kiss"], 152508},
        -- Shadowlands Herbs
        { 1,    "inv_misc_herb_bloodcup",L["Widowbloom"], 168583},
        { 1,    "inv_misc_herb_deathblossom",L["Death Blossom"], 168586},
        { 1,    "inv_misc_herb_risingglory",L["Rising Glory"], 168589},
        { 1,    "inv_misc_herb_marrowroot",L["Marrowroot"], 168583},
        { 1,    "inv_misc_herb_ardenweald",L["Vigil's Torch"], 170554},
        { 1,    "inv_misc_herb_nightshade",L["Nightshade"], 171315},
        -- Dragonflight Herbs
        { 1,    "Inv_misc_herb_dragonsbreath",L["Hochenblume"], 191460},
        { 1,    "Inv_misc_herb_bubblepoppy",L["Bubble Poppy"], 191467},
        { 1,    "Inv_misc_herb_saxifrage",L["Saxifrage"], 191470},
        { 1,    "Inv_misc_herb_writhebark",L["Writhebark"], 191473},
        -- The War Within Herbs
        { 1,    "Inv_misc_herb_mycobloom",L["Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Altered Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Crystallized Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Irradiated Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Lush Mycobloom"], 210796},
        { 1,    "Inv_misc_herb_mycobloom",L["Sporefused Mycobloom"], 210796},
        { 1,    "inv_misc_herb_luredrop",L["Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Altered Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Crystallized Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Irradiated Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Lush Luredrop"], 210798},
        { 1,    "inv_misc_herb_luredrop",L["Sporefused Luredrop"], 210798},
        { 1,    "inv_misc_herb_arathorsspear",L["Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Crystallized Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Irradiated Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Lush Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_arathorsspear",L["Sporefused Arathor's Spear"], 210799},
        { 1,    "inv_misc_herb_blessingblossom",L["Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Crystallized Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Irradiated Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Lush Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_blessingblossom",L["Sporefused Blessing Blossom"], 210800},
        { 1,    "inv_misc_herb_orbinid",L["Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Altered Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Crystallized Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Irradiated Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Lush Orbinid"], 210797},
        { 1,    "inv_misc_herb_orbinid",L["Sporefused Orbinid"], 210797},
        -- Midnight Herbs
        { 1,    "inv_misc_herb_silverleaf",L["Argentleaf"], 256963},
        { 1,    "inv_misc_herb_earthroot",L["Azeroot"], 256964},
        { 1,    "inv_misc_herb_mageroyal",L["Mana Lily"], 256965},
        { 1,    "inv_herb_bloodthistle",L["Sanguithorn"], 256966},
        { 1,    "inv_misc_herb_peacebloom",L["Tranquility Bloom"], 256967},
    },
    ["M"] = {    -- Mine node (4th element is itemId for localization)
        { 325,    "inv_ore_adamantium",L["Adamantite Deposit"], 23425},
        { 375,    "inv_misc_gem_01",L["Ancient Gem Vein"], 23426},
        { 1,    "inv_ore_copper_01",L["Copper Vein"], 2770},
        { 230,    "inv_ore_mithril_01",L["Dark Iron Deposit"], 11370},
        { 300,    "inv_ore_feliron",L["Fel Iron Deposit"], 23424},
        { 155,    "inv_ore_copper_01",L["Gold Vein"], 2776},
        { 65,    "inv_ore_thorium_01",L["Incendicite Mineral Vein"], 3340},
        { 150,    "inv_ore_mithril_01",L["Indurium Mineral Vein"], 5833},
        { 125,    "inv_ore_iron_01",L["Iron Deposit"], 2772},
        { 375,    "inv_ore_khorium",L["Khorium Vein"], 23426},
        { 305,    "inv_stone_15",L["Large Obsidian Chunk"], 22203},
        { 75,    "inv_ore_thorium_01",L["Lesser Bloodstone Deposit"], 4278},
        { 175,    "inv_ore_mithril_02",L["Mithril Deposit"], 3858},
        { 275,    "inv_ore_ethernium_01",L["Nethercite Deposit"], 32464},
        { 350,    "inv_ore_adamantium",L["Rich Adamantite Deposit"], 23425},
        { 255,    "inv_ore_thorium_02",L["Rich Thorium Vein"], 10620},
        { 75,    "inv_stone_16",L["Silver Vein"], 2775},
        { 305,    "inv_misc_stonetablet_01",L["Small Obsidian Chunk"], 22202},
        { 230,    "inv_ore_thorium_02",L["Small Thorium Vein"], 10620},
        { 65,    "inv_ore_tin_01",L["Tin Vein"], 2771},
        { 230,    "inv_ore_truesilver_01",L["Truesilver Deposit"], 7911},
        { 350,    "inv_ore_cobalt",L["Cobalt Deposit"], 36909},
        { 375,    "inv_ore_cobalt",L["Rich Cobalt Deposit"], 36909},
        { 425,    "inv_ore_saronite_01",L["Saronite Deposit"], 36912},
        { 425,    "inv_ore_saronite_01",L["Rich Saronite Deposit"], 36912},
        { 450,    "inv_ore_platinum_01",L["Titanium Vein"], 36910},
        { 425,    "item_elementiumore", L["Obsidium Deposit"], 53038},
        { 450,    "item_elementiumore", L["Rich Obsidium Deposit"], 53038},
        { 475,    "item_pyriumore", L["Elementium Vein"], 52185},
        { 500,    "item_pyriumore", L["Rich Elementium Vein"], 52185},
        { 525,    "inv_ore_arcanite_01", L["Pyrite Deposit"], 52183},
        { 525,    "inv_ore_arcanite_01", L["Rich Pyrite Deposit"], 52183},
        { 515,    "inv_ore_ghostiron",L["Ghost Iron Deposit"], 72092},
        { 550,    "inv_ore_ghostiron",L["Rich Ghost Iron Deposit"], 72092},
        { 550,    "inv_ore_manticyte",L["Kyparite Deposit"], 72093},
        { 575,    "inv_ore_manticyte",L["Rich Kyparite Deposit"], 72093},
        { 600,    "inv_ore_trilliumwhite",L["Trillium Vein"], 72094},
        { 600,    "inv_ore_trilliumWhite",L["Rich Trillium Vein"], 72094},
        -- WoD Mining
        { 1,    "inv_ore_trueironore",L["True Iron Deposit"], 109118},
        { 1,    "inv_ore_trueironore",L["Rich True Iron Deposit"], 109118},
        { 1,    "inv_ore_trueironore",L["Smoldering True Iron Deposit"], 109118},
        { 1,    "inv_ore_blackrock_ore",L["Blackrock Deposit"], 109119},
        { 1,    "inv_ore_blackrock_ore",L["Rich Blackrock Deposit"], 109119},
        -- Legion Mining
        { 1,    "inv_felslate",L["Felslate Deposit"], 123919},
        { 1,    "inv_felslate",L["Felslate Seam"], 123919},
        { 1,    "inv_felslate",L["Living Felslate"], 123919},
        { 1,    "inv_leystone",L["Leystone Deposit"], 123918},
        { 1,    "inv_leystone",L["Leystone Seam"], 123918},
        { 1,    "inv_leystone",L["Living Leystone"], 123918},
        { 1,    "inv_misc_starmetal",L["Empyrium Deposit"], 151564},
        { 1,    "inv_misc_starmetal",L["Rich Empyrium Deposit"], 151564},
        { 1,    "inv_misc_starmetal",L["Empyrium Seam"], 151564},
        -- BfA Mining
        { 1,    "inv_ore_monalite",L["Monelite Deposit"], 152512},
        { 1,    "inv_ore_monalite",L["Rich Monelite Deposit"], 152512},
        { 1,    "inv_ore_monalite",L["Monelite Seam"], 152512},
        { 1,    "inv_ore_platinum",L["Platinum Deposit"], 152513},
        { 1,    "inv_ore_platinum",L["Rich Platinum Deposit"], 152513},
        { 1,    "inv_ore_stormsilver",L["Storm Silver Deposit"], 152579},
        { 1,    "inv_ore_stormsilver",L["Rich Storm Silver Deposit"], 152579},
        { 1,    "inv_ore_stormsilver",L["Storm Silver Seam"], 152579},
        -- Shadowlands Mining
        { 1,    "inv_ore_lastrite",L["Laestrite Deposit"], 171828},
        { 1,    "inv_ore_lastrite",L["Rich Laestrite Deposit"], 171828},
        { 1,    "inv_ore_elethium",L["Elethium Deposit"], 171833},
        { 1,    "inv_ore_elethium",L["Rich Elethium Deposit"], 171833},
        { 1,    "inv_ore_solenium",L["Solenium Deposit"], 171829},
        { 1,    "inv_ore_solenium",L["Rich Solenium Deposit"], 171829},
        { 1,    "inv_ore_oxxein",L["Oxxein Deposit"], 171830},
        { 1,    "inv_ore_oxxein",L["Rich Oxxein Deposit"], 171830},
        { 1,    "inv_ore_phaedrite",L["Phaedrum Deposit"], 171831},
        { 1,    "inv_ore_phaedrite",L["Rich Phaedrum Deposit"], 171831},
        { 1,    "inv_ore_sinvyr",L["Sinvyr Deposit"], 171832},
        { 1,    "inv_ore_sinvyr",L["Rich Sinvyr Deposit"], 171832},
        -- Dragonflight Mining
        { 1,    "Inv_ore_tyrivite",L["Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Hardened Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Infurious Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Molten Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Primal Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Rich Serevite Deposit"], 190395},
        { 1,    "Inv_ore_tyrivite",L["Titan-Touched Serevite Deposit"], 190395},
        { 1,    "Inv_ore_draconium",L["Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Hardened Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Infurious Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Molten Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Primal Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Rich Draconium Deposit"], 189143},
        { 1,    "Inv_ore_draconium",L["Titan-Touched Draconium Deposit"], 189143},
        -- The War Within Mining
        { 1,    "inv_ore_bismuth",L["Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["Crystallized Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["EZ-Mine Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["Rich Bismuth"], 210930},
        { 1,    "inv_ore_bismuth",L["Weeping Bismuth"], 210930},
        { 1,    "inv_ore_ironclaw_normal",L["Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["Crystallized Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["EZ-Mine Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["Rich Ironclaw"], 210932},
        { 1,    "inv_ore_ironclaw_normal",L["Weeping Ironclaw"], 210932},
        { 1,    "inv_ore_nerubian_red",L["Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["Crystallized Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["EZ-Mine Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["Rich Aqirite"], 210933},
        { 1,    "inv_ore_nerubian_red",L["Weeping Aqirite"], 210933},
        { 1,    "ui_profession_mining",L["Webbed Ore Deposit"], 210933},
        -- Midnight Mining
        { 1,    "inv_ore_brilliantsilver",L["Brilliant Silver"], 256970},
        { 1,    "inv_ore_refulgentcopper",L["Refulgent Copper"], 256971},
        { 1,    "inv_ore_umbraltin",L["Umbral Tin"], 256972},
    }
}

Nx.GatherRemap = {
    ["NXHerb"] = {
        [47] = 46,        -- Icethorn
    },
    ["NXMine"] = {
        [6] = 9,        -- Gold
        [17] = 20,        -- Silver
        [23] = 22,        -- Rich Cobalt Deposit
        [25] = 24,        -- Rich Saronite Deposit
        [26] = 24,        -- Titanium
    }
}

---
-- Initialize gathering system
-- Must be called after map init for proper node display
--
function Nx:GatherInit()
    if self.DoGatherUpgrade then
        self.DoGatherUpgrade = nil
        Nx:GatherVerUpgrade()
    end
    Nx.GatherVerUpgrade = nil        -- Kill it
    Nx.GatherVerUpgradeType = nil        -- Kill it
end

---
-- Get gather node info by type and ID
-- @param typ  Node type: "H" (herb), "M" (mine)
-- @param id   Node ID number
-- @return     name, iconPath, skillLevel
--
function Nx:GetGather (typ, id)
    local v = Nx.GatherInfo[typ][id]
    if v then
        return v[3], v[2], v[1]
    end
end

-- Cache for quick node type lookups (nil = not yet built)
Nx.GatherCache = {}
Nx.GatherCache.H = nil  -- Herbs
Nx.GatherCache.M = nil  -- Mines

---
-- Check if a spell name is a gathering spell
-- @param nodename  Spell/node name
-- @return          "Herb Gathering" or "Mining" or nil
--
function Nx:IsGathering(nodename)
    if not Nx.GatherCache.H then
        Nx.GatherCache.H = {}
        for k, v in ipairs (Nx.GatherInfo["H"]) do
            if type(v[3]) == "string" then
                Nx.GatherCache.H[v[3]] = true
            end
        end
    end
    if not Nx.GatherCache.M then
        Nx.GatherCache.M = {}
        for k, v in ipairs (Nx.GatherInfo["M"]) do
            if type(v[3]) == "string" then
                Nx.GatherCache.M[v[3]] = true
            end
        end
    end
    if type(nodename) ~= "string" then return end
    local isHerb, isMine = false, false
    pcall(function() isHerb = Nx.GatherCache.H[nodename] end)
    pcall(function() isMine = Nx.GatherCache.M[nodename] end)
    if isHerb then return L["Herb Gathering"] end
    if isMine then return L["Mining"] end
end

---
-- Convert herb name to internal ID
-- @param name  Localized herb name
-- @return      Herb ID or nil if not found
--
function Nx:HerbNameToId (name)
    for k, v in ipairs (Nx.GatherInfo["H"]) do
        if v[3] == name then
            return k
        end
    end

    if Nx.db.profile.Debug.DBGather then
        Nx.prt (L["Unknown herb"] .. " %s", name)
    end
end

---
-- Convert mining node name to internal ID
-- @param name  Localized node name
-- @return      Node ID or nil if not found
--
function Nx:MineNameToId (name)

    name = gsub (name, L["Ooze Covered"] .. " ", "")
    if name == L["Thorium Vein"] then                -- Created when Ooze Covered removed
        name = L["Small Thorium Vein"]
    end
    for k, v in ipairs (Nx.GatherInfo["M"]) do
        if v[3] == name then
            return k
        end
    end

    if Nx.db.profile.Debug.DBGather then
        Nx.prt (L["Unknown ore"] .. " %s", name)
    end
end

--------
-- Upgrade gather data

function Nx:GatherVerUpgrade()
    Nx:GatherVerUpgradeType ("NXHerb")
    Nx:GatherVerUpgradeType ("NXMine")
    Nx:GatherVerUpgradeType ("NXTimber")
end

function Nx:GatherVerUpgradeType (tName)
end

---
-- Record a gathered herb location
-- @param id     Herb ID
-- @param mapId  Map ID
-- @param x      Zone X (0-100)
-- @param y      Zone Y (0-100)
-- @param level  Dungeon level
--
function Nx:GatherHerb (id, mapId, x, y, level)
    self:Gather ("NXHerb", id, mapId, x, y, level)
end

---
-- Record a gathered mining node location
-- @param id     Node ID
-- @param mapId  Map ID
-- @param x      Zone X (0-100)
-- @param y      Zone Y (0-100)
-- @param level  Dungeon level
--
function Nx:GatherMine (id, mapId, x, y, level)
    self:Gather ("NXMine", id, mapId, x, y, level)
end

---
-- Record a gathered timber location
-- @param id     Timber ID (1=Small, 2=Medium, 3=Large)
-- @param mapId  Map ID
-- @param x      Zone X (0-100)
-- @param y      Zone Y (0-100)
-- @param level  Dungeon level
--
function Nx:GatherTimber (id, mapId, x, y, level)
    self:Gather ("NXTimber", id, mapId, x, y, level)
end

---
-- Record a gathered node location (generic)
-- Merges nearby nodes and stores position
-- @param nodeType  "NXHerb", "NXMine", or "Misc"
-- @param id        Node ID
-- @param mapId     Map ID
-- @param x         Zone X (0-100)
-- @param y         Zone Y (0-100)
-- @param level     Dungeon level
--
function Nx:Gather (nodeType, id, mapId, x, y, level)
    level = level or 0  -- Default to 0 if not provided
    local remap = self.GatherRemap[nodeType]
    if remap then
        id = remap[id] or id
    end
    local data = Nx.db.profile.GatherData[nodeType]
    if not data then
        Nx.db.profile.GatherData[nodeType] = {}
        data = Nx.db.profile.GatherData[nodeType]
    end

    local zoneT = data[mapId]

    if not zoneT or not Nx.Map.MapWorldInfo[mapId] then
--        Nx.prt ("Gather new %d", mapId)
        zoneT = {}
        data[mapId] = zoneT
    end

    local maxDist = (5 / Nx.Map:GetWorldZoneScale (mapId)) ^ 2
    local index
    local nodeT = zoneT[id] or {}
    zoneT[id] = nodeT

    for n, node in ipairs (nodeT) do
        local nx, ny, nlevel = Nx.Split("|",node)
        nx, ny, nlevel = tonumber(nx), tonumber(ny), tonumber(nlevel)

        if not nlevel then
            nlevel = 0
        end
        if nlevel == level then
            local dist = (nx - x) ^ 2 + (ny - y) ^ 2
            if dist < maxDist then        -- Squared compare
                index = n
                break
            end
        end
    end
    local cnt = 1
    if not index then
        index = #nodeT + 1
    else
        local nx,xy, level = Nx.Split ("|", nodeT[index])
    end
    nodeT[index] = format ("%f|%f|%d", x, y, level)
end

---
-- Unpack gather node position string
-- Optimized to avoid creating temporary tables
-- @param item  "x|y|level" string
-- @return      x, y, level numbers
--
function Nx:GatherUnpack (item)
    -- Use string.find instead of Split to avoid table creation
    local p1 = string.find(item, "|", 1, true)
    if not p1 then
        return tonumber(item), 0, 0
    end
    local p2 = string.find(item, "|", p1 + 1, true)
    local x = tonumber(string.sub(item, 1, p1 - 1))
    local y, level
    if p2 then
        y = tonumber(string.sub(item, p1 + 1, p2 - 1))
        level = tonumber(string.sub(item, p2 + 1)) or 0
    else
        y = tonumber(string.sub(item, p1 + 1))
        level = 0
    end
    return x, y, level
end

---
-- Delete all herb gathering data
--
function Nx:GatherDeleteHerb()
    Nx.db.profile.GatherData.NXHerb = {}
end

---
-- Delete all mining gathering data
--
function Nx:GatherDeleteMine()
    Nx.db.profile.GatherData.NXMine = {}
end

---
-- Delete all timber gathering data
--
function Nx:GatherDeleteTimber()
    Nx.db.profile.GatherData.NXTimber = {}
end

---
-- Delete all misc gathering data
--
function Nx:GatherDeleteMisc()
    Nx.db.profile.GatherData["Misc"] = {}
end

-------------------------------------------------------------------------------
-- GATHERMATE DATA IMPORT
-- Functions to import node data from Carbonite.Gathermate2_Data addon
-------------------------------------------------------------------------------

---
-- Import herb data from Gathermate2_Data
--
function Nx:GatherImportCarbHerb()
    Nx:GatherImportCarb ("NXHerb")
end

function Nx:GatherImportCarbMine()
    Nx:GatherImportCarb ("NXMine")
end

function Nx:GatherImportCarbMisc()
    Nx:GatherImportCarb ("Misc")
end

function Nx:GatherConvert (id)
    return floor(id/1000000)/10000, floor(id % 1000000 / 100)/10000, id % 100
end

-- Cached lookup table (built once, reused across all import calls)
local GatherNodeToCarbCache = nil

function Nx:GatherNodeToCarb (id)

    if GatherNodeToCarbCache then
        return GatherNodeToCarbCache[id]
    end

    GatherNodeToCarbCache = {
    -- Mining Node Conversions (GatherMate ID -> Carbonite GatherInfo["M"] index)
    -- Classic
        [201] = 3,   -- Copper Vein
        [202] = 20,  -- Tin Vein
        [203] = 9,   -- Iron Deposit
        [204] = 17,  -- Silver Vein
        [205] = 6,   -- Gold Vein
        [206] = 13,  -- Mithril Deposit
        [207] = 13,  -- Ooze Covered Mithril Deposit
        [208] = 21,  -- Truesilver Deposit
        [209] = 17,  -- Ooze Covered Silver Vein
        [210] = 6,   -- Ooze Covered Gold Vein
        [211] = 21,  -- Ooze Covered Truesilver Deposit
        [212] = 16,  -- Ooze Covered Rich Thorium Vein
        [213] = 19,  -- Ooze Covered Thorium Vein
        [214] = 19,  -- Small Thorium Vein
        [215] = 16,  -- Rich Thorium Vein
        [216] = 19,  -- Hakkari Thorium Vein
        [217] = 4,   -- Dark Iron Deposit
        [218] = 12,  -- Lesser Bloodstone Deposit
        [219] = 7,   -- Incendicite Mineral Vein
        [220] = 8,   -- Indurium Mineral Vein
    -- TBC
        [221] = 5,   -- Fel Iron Deposit
        [222] = 1,   -- Adamantite Deposit
        [223] = 15,  -- Rich Adamantite Deposit
        [224] = 10,  -- Khorium Vein
        [225] = 11,  -- Large Obsidian Chunk
        [226] = 18,  -- Small Obsidian Chunk
        [227] = 14,  -- Nethercite Deposit
    -- WotLK
        [228] = 22,  -- Cobalt Deposit
        [229] = 23,  -- Rich Cobalt Deposit
        [230] = 26,  -- Titanium Vein
        [231] = 24,  -- Saronite Deposit
        [232] = 25,  -- Rich Saronite Deposit
    -- Cataclysm
        [233] = 27,  -- Obsidium Deposit
        [234] = 27,  -- Huge Obsidian Slab
        [235] = 24,  -- Pure Saronite Deposit
        [236] = 29,  -- Elementium Vein
        [237] = 30,  -- Rich Elementium Vein
        [238] = 31,  -- Pyrite Deposit
        [239] = 28,  -- Rich Obsidium Deposit
        [240] = 32,  -- Rich Pyrite Deposit
    -- MoP
        [241] = 33,  -- Ghost Iron Deposit
        [242] = 34,  -- Rich Ghost Iron Deposit
        [243] = 37,  -- Black Trillium Deposit
        [244] = 37,  -- White Trillium Deposit
        [245] = 35,  -- Kyparite Deposit
        [246] = 36,  -- Rich Kyparite Deposit
        [247] = 37,  -- Trillium Vein
        [248] = 38,  -- Rich Trillium Vein
    -- WoD
        [249] = 39,  -- True Iron Deposit
        [250] = 40,  -- Rich True Iron Deposit
        [251] = 42,  -- Blackrock Deposit
        [252] = 43,  -- Rich Blackrock Deposit
    -- Legion
        [253] = 47,  -- Leystone Deposit
        [254] = 47,  -- Rich Leystone Deposit
        [255] = 48,  -- Leystone Seam
        [256] = 44,  -- Felslate Deposit
        [257] = 44,  -- Rich Felslate Deposit
        [258] = 45,  -- Felslate Seam
        [259] = 50,  -- Empyrium Deposit
        [260] = 51,  -- Rich Empyrium Deposit
        [261] = 52,  -- Empyrium Seam
    -- BfA
        [262] = 53,  -- Monelite Deposit
        [263] = 54,  -- Rich Monelite Deposit
        [264] = 55,  -- Monelite Seam
        [265] = 56,  -- Platinum Deposit
        [266] = 57,  -- Rich Platinum Deposit
        [267] = 58,  -- Storm Silver Deposit
        [268] = 59,  -- Rich Storm Silver Deposit
        [269] = 60,  -- Storm Silver Seam
        [270] = 53,  -- Osmenite Deposit (map to Monelite)
        [271] = 54,  -- Rich Osmenite Deposit
        [272] = 55,  -- Osmenite Seam
    -- Shadowlands
        [273] = 61,  -- Laestrite Deposit
        [274] = 62,  -- Rich Laestrite Deposit
        [275] = 69,  -- Phaedrum Deposit
        [276] = 70,  -- Rich Phaedrum Deposit
        [277] = 67,  -- Oxxein Deposit
        [278] = 68,  -- Rich Oxxein Deposit
        [280] = 63,  -- Elethium Deposit
        [281] = 64,  -- Rich Elethium Deposit
        [282] = 65,  -- Solenium Deposit
        [283] = 66,  -- Rich Solenium Deposit
        [284] = 71,  -- Sinvyr Deposit
        [285] = 72,  -- Rich Sinvyr Deposit
        [287] = 63,  -- Progenium Deposit (map to Elethium)
        [288] = 64,  -- Rich Progenium Deposit
        [289] = 63,  -- Elusive Progenium
        [290] = 64,  -- Elusive Rich Progenium
        [291] = 63,  -- Elusive Elethium
        [292] = 64,  -- Elusive Rich Elethium
    -- Dragonflight
        [1200] = 73, -- Serevite Seam
        [1201] = 73, -- Serevite Deposit
        [1202] = 78, -- Rich Serevite Deposit
        [1203] = 77, -- Primal Serevite Deposit
        [1204] = 76, -- Molten Serevite Deposit
        [1205] = 74, -- Hardened Serevite Deposit
        [1206] = 75, -- Infurious Serevite Deposit
        [1207] = 79, -- Titan-Touched Serevite Deposit
        [1208] = 80, -- Draconium Seam
        [1209] = 80, -- Draconium Deposit
        [1210] = 85, -- Rich Draconium Deposit
        [1211] = 84, -- Primal Draconium Deposit
        [1212] = 83, -- Molten Draconium Deposit
        [1213] = 81, -- Hardened Draconium Deposit
        [1214] = 82, -- Infurious Draconium Deposit
        [1215] = 86, -- Titan-Touched Draconium Deposit
        [1216] = 73, -- Metamorphic Serevite
        [1217] = 80, -- Metamorphic Draconium
    -- The War Within
        [1218] = 87, -- Bismuth
        [1219] = 90, -- Rich Bismuth
        [1220] = 87, -- Camouflaged Bismuth
        [1221] = 88, -- Crystallized Bismuth
        [1222] = 91, -- Weeping Bismuth
        [1223] = 87, -- Webbed Bismuth
        [1224] = 89, -- EZ-Mine Bismuth
        [1225] = 87, -- Bismuth Seam
        [1226] = 97, -- Aqirite
        [1227] = 100, -- Rich Aqirite
        [1228] = 97, -- Camouflaged Aqirite
        [1229] = 98, -- Crystallized Aqirite
        [1230] = 101, -- Weeping Aqirite
        [1231] = 97, -- Webbed Aqirite
        [1232] = 99, -- EZ-Mine Aqirite
        [1233] = 97, -- Aqirite Seam
        [1234] = 92, -- Ironclaw
        [1235] = 95, -- Rich Ironclaw
        [1236] = 92, -- Camouflaged Ironclaw
        [1237] = 93, -- Crystallized Ironclaw
        [1238] = 96, -- Weeping Ironclaw
        [1239] = 92, -- Webbed Ironclaw
        [1240] = 94, -- EZ-Mine Ironclaw
        [1241] = 92, -- Ironclaw Seam
        [1242] = 102, -- Webbed Ore Deposit
        [1243] = 87, -- Desolate Deposit
        [1244] = 87, -- Rich Desolate Deposit
    -- Midnight Mining (GatherMate IDs 1245-1250)
        [1245] = 103, -- Brilliant Silver
        [1246] = 103, -- Brilliant Silver Seam
        [1247] = 104, -- Refulgent Copper
        [1248] = 104, -- Refulgent Copper Seam
        [1249] = 105, -- Umbral Tin
        [1250] = 105, -- Umbral Tin Seam
    -- Herbalism Nodes (GatherMate ID -> Carbonite GatherInfo["H"] index)
    -- Classic
        [401] = 30,  -- Peacebloom
        [402] = 34,  -- Silverleaf
        [403] = 10,  -- Earthroot
        [404] = 24,  -- Mageroyal
        [405] = 6,   -- Briarthorn
        [406] = 6,   -- Swiftthistle (from Briarthorn)
        [407] = 35,  -- Stranglekelp
        [408] = 7,   -- Bruiseweed
        [409] = 38,  -- Wild Steelbloom
        [410] = 18,  -- Grave Moss
        [411] = 22,  -- Kingsblood
        [412] = 23,  -- Liferoot
        [413] = 11,  -- Fadeleaf
        [414] = 17,  -- Goldthorn
        [415] = 21,  -- Khadgar's Whisker
        [416] = 0,   -- Wintersbite (not in Carbonite)
        [417] = 13,  -- Firebloom
        [418] = 32,  -- Purple Lotus
        [419] = 32,  -- Wildvine (from Purple Lotus)
        [420] = 2,   -- Arthas' Tears
        [421] = 36,  -- Sungrass
        [422] = 4,   -- Blindweed
        [423] = 15,  -- Ghost Mushroom
        [424] = 19,  -- Gromsblood
        [425] = 16,  -- Golden Sansam
        [426] = 8,   -- Dreamfoil
        [427] = 26,  -- Mountain Silversage
        [428] = 31,  -- Plaguebloom
        [429] = 20,  -- Icecap
        [430] = 0,   -- Bloodvine (not in Carbonite)
        [431] = 3,   -- Black Lotus
    -- TBC
        [432] = 12,  -- Felweed
        [433] = 9,   -- Dreaming Glory
        [434] = 37,  -- Terocone
        [435] = 1,   -- Ancient Lichen
        [436] = 5,   -- Bloodthistle
        [437] = 25,  -- Mana Thistle
        [438] = 27,  -- Netherbloom
        [439] = 29,  -- Nightmare Vine
        [440] = 33,  -- Ragveil
        [441] = 14,  -- Flame Cap
        [442] = 28,  -- Netherdust Bush
    -- WotLK
        [443] = 43,  -- Adder's Tongue
        [444] = 0,   -- Constrictor Grass (not in Carbonite)
        [445] = 0,   -- Deadnettle (not in Carbonite)
        [446] = 41,  -- Goldclover
        [447] = 47,  -- Icethorn
        [448] = 46,  -- Lichbloom
        [449] = 42,  -- Talandra's Rose
        [450] = 45,  -- Tiger Lily
        [451] = 49,  -- Firethorn
        [452] = 44,  -- Frozen Herb
        [453] = 48,  -- Frost Lotus
    -- Cataclysm
        [454] = 39,  -- Dragon's Teeth
        [455] = 31,  -- Sorrowmoss (map to Plaguebloom)
        [456] = 50,  -- Azshara's Veil
        [457] = 51,  -- Cinderbloom
        [458] = 52,  -- Stormvine
        [459] = 53,  -- Heartblossom
        [460] = 55,  -- Twilight Jasmine
        [461] = 54,  -- Whiptail
    -- MoP
        [462] = 57,  -- Golden Lotus
        [463] = 56,  -- Fool's Cap
        [464] = 62,  -- Snow Lily
        [465] = 61,  -- Silkweed
        [466] = 58,  -- Green Tea Leaf
        [467] = 59,  -- Rain Poppy
        [468] = 60,  -- Sha-Touched Herb
    -- WoD
        [469] = 68,  -- Talador Orchid
        [470] = 67,  -- Nagrand Arrowbloom
        [471] = 66,  -- Starflower
        [472] = 65,  -- Gorgrond Flytrap
        [473] = 69,  -- Fireweed
        [474] = 64,  -- Frostweed
        [475] = 70,  -- Withered Herb
    -- Legion
        [476] = 71,  -- Aethril
        [477] = 72,  -- Dreamleaf
        [478] = 73,  -- Felwort
        [479] = 74,  -- Fjarnskaggl
        [480] = 75,  -- Foxflower
        [481] = 76,  -- Starlight Rose
        [482] = 71,  -- Fel-Encrusted Herb (map to Aethril)
        [483] = 71,  -- Fel-Encrusted Herb Cluster
        [484] = 77,  -- Astral Glory
    -- BfA
        [485] = 78,  -- Akunda's Bite
        [486] = 79,  -- Anchor Weed
        [487] = 80,  -- Riverbud
        [488] = 81,  -- Sea Stalks
        [489] = 82,  -- Siren's Sting
        [490] = 83,  -- Star Moss
        [491] = 84,  -- Winter's Kiss
        [492] = 84,  -- Zin'anthid (map to Winter's Kiss)
    -- Shadowlands
        [493] = 86,  -- Death Blossom
        [494] = 90,  -- Nightshade
        [495] = 88,  -- Marrowroot
        [496] = 89,  -- Vigil's Torch
        [497] = 87,  -- Rising Glory
        [498] = 85,  -- Widowbloom
        [499] = 90,  -- First Flower (map to Nightshade)
        [1401] = 90, -- Lush Nightshade
        [1402] = 90, -- Elusive Nightshade
        [1403] = 90, -- Lush First Flower
        [1404] = 90, -- Elusive First Flower
        [1405] = 90, -- Lush Elusive First Flower
        [1406] = 90, -- Lush Elusive Nightshade
    -- Dragonflight
        [1407] = 91, -- Hochenblume
        [1408] = 91, -- Lush Hochenblume
        [1409] = 91, -- Frigid Hochenblume
        [1410] = 91, -- Decayed Hochenblume
        [1411] = 91, -- Windswept Hochenblume
        [1412] = 91, -- Infurious Hochenblume
        [1413] = 91, -- Titan-Touched Hochenblume
        [1414] = 92, -- Bubble Poppy
        [1415] = 92, -- Lush Bubble Poppy
        [1416] = 92, -- Frigid Bubble Poppy
        [1417] = 92, -- Decayed Bubble Poppy
        [1418] = 92, -- Windswept Bubble Poppy
        [1419] = 92, -- Infurious Bubble Poppy
        [1420] = 92, -- Titan-Touched Bubble Poppy
        [1421] = 93, -- Saxifrage
        [1422] = 93, -- Lush Saxifrage
        [1423] = 93, -- Frigid Saxifrage
        [1424] = 93, -- Decayed Saxifrage
        [1425] = 93, -- Windswept Saxifrage
        [1426] = 93, -- Infurious Saxifrage
        [1427] = 93, -- Titan-Touched Saxifrage
        [1428] = 94, -- Writhebark
        [1429] = 94, -- Lush Writhebark
        [1430] = 94, -- Frigid Writhebark
        [1431] = 94, -- Decayed Writhebark
        [1432] = 94, -- Windswept Writhebark
        [1433] = 94, -- Infurious Writhebark
        [1434] = 94, -- Titan-Touched Writhebark
        [1435] = 91, -- Lambent Hochenblume
        [1436] = 92, -- Lambent Bubble Poppy
        [1437] = 93, -- Lambent Saxifrage
        [1438] = 94, -- Lambent Writhebark
    -- The War Within
        [1439] = 95,  -- Mycobloom
        [1440] = 99,  -- Lush Mycobloom
        [1441] = 98,  -- Irradiated Mycobloom
        [1442] = 100, -- Sporefused Mycobloom
        [1443] = 95,  -- Sporelusive Mycobloom
        [1444] = 97,  -- Crystallized Mycobloom
        [1445] = 96,  -- Altered Mycobloom
        [1446] = 95,  -- Camouflaged Mycobloom
        [1447] = 112, -- Blessing Blossom
        [1448] = 115, -- Lush Blessing Blossom
        [1449] = 114, -- Irradiated Blessing Blossom
        [1450] = 116, -- Sporefused Blessing Blossom
        [1451] = 112, -- Sporelusive Blessing Blossom
        [1452] = 113, -- Crystallized Blessing Blossom
        [1453] = 112, -- Altered Blessing Blossom
        [1454] = 112, -- Camouflaged Blessing Blossom
        [1455] = 101, -- Luredrop
        [1456] = 105, -- Lush Luredrop
        [1457] = 104, -- Irradiated Luredrop
        [1458] = 106, -- Sporefused Luredrop
        [1459] = 101, -- Sporelusive Luredrop
        [1460] = 103, -- Crystallized Luredrop
        [1461] = 102, -- Altered Luredrop
        [1462] = 101, -- Camouflaged Luredrop
        [1463] = 117, -- Orbinid
        [1464] = 121, -- Lush Orbinid
        [1465] = 120, -- Irradiated Orbinid
        [1466] = 122, -- Sporefused Orbinid
        [1467] = 117, -- Sporelusive Orbinid
        [1468] = 119, -- Crystallized Orbinid
        [1469] = 118, -- Altered Orbinid
        [1470] = 117, -- Camouflaged Orbinid
        [1471] = 107, -- Arathor's Spear
        [1472] = 110, -- Lush Arathor's Spear
        [1473] = 109, -- Irradiated Arathor's Spear
        [1474] = 111, -- Sporefused Arathor's Spear
        [1475] = 107, -- Sporelusive Arathor's Spear
        [1476] = 108, -- Crystallized Arathor's Spear
        [1477] = 107, -- Altered Arathor's Spear
        [1478] = 107, -- Camouflaged Arathor's Spear
        [1479] = 95,  -- Phantom Bloom (map to Mycobloom)
        [1480] = 95,  -- Lush Phantom Bloom
    -- Midnight Herbs (GatherMate IDs 1481-1485)
        [1481] = 123, -- Argentleaf
        [1482] = 124, -- Azeroot
        [1483] = 125, -- Mana Lily
        [1484] = 126, -- Sanguithorn
        [1485] = 127, -- Tranquility Bloom
    }
    return GatherNodeToCarbCache[id]
end

-- Batched import state
Nx.GatherImportState = nil

function Nx:GatherImportCarb (nodeType)
    -- Prevent multiple imports at once
    if Nx.GatherImportState then
        Nx.prt("Import already in progress, please wait...")
        return
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Carbonite.Gathermate2_Data")
    else
        LoadAddOn("Carbonite.Gathermate2_Data")
    end

    -- Validate data exists
    if nodeType == "NXMine" then
        if not GatherMateData2MineDB then
            Nx.prt (L["Carbonite.Gathermate2_Data addon is not loaded!"])
            return
        end
    elseif nodeType == "NXHerb" then
        if not GatherMateData2HerbDB then
            Nx.prt (L["Carbonite.Gathermate2_Data addon is not loaded!"])
            return
        end
    elseif nodeType == "Misc" then
        if not GatherMateData2FishDB and not GatherMateData2TreasureDB then
            Nx.prt (L["Carbonite.Gathermate2_Data addon is not loaded!"])
            return
        end
    end

    -- Get source data table(s)
    local srcT = nil
    local srcTables = {}

    if nodeType == "NXMine" then
        srcT = GatherMateData2MineDB
    elseif nodeType == "NXHerb" then
        srcT = GatherMateData2HerbDB
    elseif nodeType == "Misc" then
        -- Misc includes Fish and Treasure data
        if GatherMateData2FishDB then
            srcTables[#srcTables + 1] = {data = GatherMateData2FishDB, subType = "Fish"}
        end
        if GatherMateData2TreasureDB then
            srcTables[#srcTables + 1] = {data = GatherMateData2TreasureDB, subType = "Treasure"}
        end
    end

    -- For single-source types
    if srcT then
        srcTables[1] = {data = srcT, subType = nodeType}
    end

    if #srcTables == 0 then
        Nx.prt("No data to import for " .. nodeType)
        return
    end

    -- Build a flat list of items to import (for chunked processing)
    local importList = {}
    for _, srcInfo in ipairs(srcTables) do
        for mapId, zoneT in pairs(srcInfo.data) do
            for coords, nodetype in pairs(zoneT) do
                importList[#importList + 1] = {mapId = mapId, coords = coords, nodetype = nodetype, subType = srcInfo.subType}
            end
        end
    end

    local totalCount = #importList
    if totalCount == 0 then
        Nx.prt("No data to import")
        return
    end

    Nx.prt("Starting import of %d nodes (this may take a moment)...", totalCount)

    -- Setup batched import state
    Nx.GatherImportState = {
        nodeType = nodeType,
        importList = importList,
        currentIndex = 1,
        importedCount = 0,
        totalCount = totalCount,
        batchSize = 500,  -- Process 500 nodes per frame
    }

    -- Start the batched import timer
    Nx:ScheduleRepeatingTimer("GatherImportBatch", 0.01)  -- Run every 10ms
end

function Nx:GatherImportBatch()
    local state = Nx.GatherImportState
    if not state then
        Nx:CancelTimer("GatherImportBatch")
        return
    end

    local nodeType = state.nodeType
    local importList = state.importList
    local batchEnd = min(state.currentIndex + state.batchSize - 1, state.totalCount)

    -- Process a batch
    for i = state.currentIndex, batchEnd do
        local item = importList[i]
        local nx, ny = Nx:GatherConvert(item.coords)
        local nodeId = Nx:GatherNodeToCarb(item.nodetype)

        -- For Mine/Herb, use nodetype as fallback; for Misc, always use nodetype
        if not nodeId then
            if nodeType == "NXMine" or nodeType == "NXHerb" then
                nodeId = item.nodetype
            elseif nodeType == "Misc" then
                nodeId = item.nodetype
            end
        end

        if nx and ny and nodeId then
            -- For Misc, store under the "Misc" category
            local storeType = nodeType
            Nx:Gather(storeType, nodeId, item.mapId, nx * 100, ny * 100)
            state.importedCount = state.importedCount + 1
        end
    end

    state.currentIndex = batchEnd + 1

    -- Check if done
    if state.currentIndex > state.totalCount then
        Nx.prt(L["Imported"] .. " %d " .. L["nodes from Carbonite.Gathermate2_Data"], state.importedCount)
        Nx.GatherImportState = nil
        Nx:CancelTimer("GatherImportBatch")
        -- Refresh map icons so newly imported nodes appear immediately
        if Nx.Map and Nx.Map.Guide then
            Nx.Map.Guide:UpdateMapIcons()
        end
    elseif state.currentIndex % 5000 < state.batchSize then
        -- Progress update every 5000 nodes
        local progress = floor(state.currentIndex / state.totalCount * 100)
        Nx.prt("Import progress: %d%% (%d/%d)", progress, state.currentIndex, state.totalCount)
    end
end

