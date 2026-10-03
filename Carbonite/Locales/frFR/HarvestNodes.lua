if ( GetLocale() ~= "frFR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "frFR")
if not L then return end

-- General Nodes
L["Artifact"] = "Artéfact"
L["Everfrost"] = "Permagivre"
L["Gas"] = "Gaz"
L["Ooze Covered"] = "Couvert de Limon"

-- Timber (WoD Lumber Mill)
L["Small Timber"] = true
L["Medium Timber"] = true
L["Large Timber"] = true
L["Timber"] = "Arbre"
L["Logging"] = true

-- Herbs - Classic
L["Peacebloom"] = "Pacifique"
L["Silverleaf"] = "Feuillargent"
L["Earthroot"] = "Terrestrine"
L["Mageroyal"] = "Mage-Royal"
L["Briarthorn"] = "Eglantine"
L["Stranglekelp"] = "Etouffante"
L["Bruiseweed"] = "Doulourante"
L["Wild Steelbloom"] = "Aciérite Sauvage"
L["Grave Moss"] = "Tombeline"
L["Kingsblood"] = "Mage Royal"
L["Liferoot"] = "Viétérule"
L["Fadeleaf"] = "Pâlerette"
L["Goldthorn"] = "Dorépine"
L["Khadgar's Whisker"] = "Moustache de Khadgar"
L["Dragon's Teeth"] = "Dents de Dragon"
L["Firebloom"] = "Fleur de Feu"
L["Purple Lotus"] = "Lotus Pourpre"
L["Arthas' Tears"] = "Larmes d'arthas"
L["Sungrass"] = "Soleillette"
L["Blindweed"] = "Aveuglette"
L["Ghost Mushroom"] = "Champignon Fantôme"
L["Gromsblood"] = "Gromsang"
L["Golden Sansam"] = "Sansam Doré"
L["Dreamfoil"] = "Feuillerêve"
L["Mountain Silversage"] = "Sauge-Argent des Montagnes"
L["Plaguebloom"] = "Fleur de peste"
L["Sorrowmoss"] = "Chagrinelle"
L["Icecap"] = "Chapeglace"
L["Black Lotus"] = "Lotus Noir"

-- Herbs - TBC
L["Felweed"] = "Gangrelette"
L["Dreaming Glory"] = "Glaurier"
L["Ragveil"] = "Voile-Misère"
L["Flame Cap"] = "Chapeflamme"
L["Terocone"] = "Terocône"
L["Ancient Lichen"] = "Lichen Ancien"
L["Netherbloom"] = "Néantine"
L["Netherdust Bush"] = "Buisson de Purinéante"
L["Nightmare Vine"] = "Cauchemardelle"
L["Mana Thistle"] = "Chardon de Mana"
L["Bloodthistle"] = "Fleur de Sang"
L["Glowcap"] = "Chapeluisant"

-- Herbs - WotLK
L["Goldclover"] = "Trèfle Doré"
L["Firethorn"] = "Epine de Feu"
L["Tiger Lily"] = "Lotus Tigré"
L["Talandra's Rose"] = "Rose de Talandra"
L["Adder's Tongue"] = "Langue de Serpent"
L["Frozen Herb"] = "Herbe Gelée"
L["Lichbloom"] = "Fleur de Liche"
L["Icethorn"] = "Glacépine"
L["Frost Lotus"] = "Lotus Givré"

-- Herbs - Cataclysm
L["Cinderbloom"] = "Fleur de Flammes"
L["Stormvine"] = "Vignétincelle"
L["Azshara's Veil"] = "Voile d'azshara"
L["Heartblossom"] = "Pétales de Coeur"
L["Whiptail"] = "Fouettine"
L["Twilight Jasmine"] = "Jasmin Crépusculaire"

-- Herbs - MoP
L["Green Tea Leaf"] = "Feuille de Thé Vert"
L["Rain Poppy"] = "Pavot de Pluie"
L["Silkweed"] = "Herbe à Soie"
L["Snow Lily"] = "Lys des Neiges"
L["Golden Lotus"] = "Lotus doré"
L["Fool's Cap"] = "Berluette"
L["Sha-Touched Herb"] = "Plante touchée par les Sha"
L["Chameleon Lotus"] = "Lotus Caméléon"

-- Herbs - WoD
L["Frostweed"] = "Givrelette"
L["Fireweed"] = "Ignescente"
L["Gorgrond Flytrap"] = "Dionée de Gorgrond"
L["Starflower"] = "Bourrache"
L["Nagrand Arrowbloom"] = "Sagittaire de Nagrand"
L["Talador Orchid"] = "Orchidée de Talador"
L["Withered Herb"] = "Herbe Flétrie"

-- Herbs - Legion
L["Aethril"] = "Aethril"
L["Dreamleaf"] = "Songefeuille"
L["Foxflower"] = "Vulpille"
L["Fjarnskaggl"] = "Fjarnskaggl"
L["Starlight Rose"] = "Rose Lumétoile"
L["Felwort"] = "Gangrèche"
L["Astral Glory"] = "Astraléee"

-- Herbs - BfA
L["Akunda's Bite"] = "Mâche d'Akunda"
L["Anchor Weed"] = "Ancoracée"
L["Riverbud"] = "Rivebulbe"
L["Sea Stalks"] = "Brins-de-mer"
L["Siren's Sting"] = "Épine de sirène"
L["Star Moss"] = "Mousse étoilée"
L["Winter's Kiss"] = "Bise-d'hiver"

-- Herbs - Shadowlands
L["Death Blossom"] = "Fatalée"
L["Marrowroot"] = "Courgineuse"
L["Nightshade"] = "Belladone"
L["Rising Glory"] = "Belle-de-l'aube"
L["Vigil's Torch"] = "Plante-torche du veilleur"
L["Widowbloom"] = "Endeuillée"

-- Herbs - Dragonflight
L["Hochenblume"] = "Hochenblume"
L["Decayed Hochenblume"] = "Hochenblume décomposée"
L["Frigid Hochenblume"] = "Hochenblume algide"
L["Infurious Hochenblume"] = "Hochenblume ardente"
L["Lush Hochenblume"] = "Hochenblume luxuriante"
L["Titan-Touched Hochenblume"] = "Hochenblume touchée par les titans"
L["Windswept Hochenblume"] = "Hochenblume balayée par le vent"
L["Bubble Poppy"] = "Pavot à bulle"
L["Decayed Bubble Poppy"] = "Pavot à bulle décomposé"
L["Frigid Bubble Poppy"] = "Pavot à bulle algide"
L["Infurious Bubble Poppy"] = "Pavot à bulle ardent"
L["Lush Bubble Poppy"] = "Pavot à bulle luxuriant"
L["Titan-Touched Bubble Poppy"] = "Pavot à bulle touché par les Titans"
L["Windswept Bubble Poppy"] = "Pavot à bulle balayé par le vent"
L["Saxifrage"] = "Saxifrage"
L["Decayed Saxifrage"] = "Saxifrage décomposée"
L["Frigid Saxifrage"] = "Saxifrage algide"
L["Infurious Saxifrage"] = "Saxifrage ardente"
L["Lush Saxifrage"] = "Saxifrage luxuriante"
L["Titan-Touched Saxifrage"] = "Saxifrage touchée par les Titans"
L["Windswept Saxifrage"] = "Saxifrage balayée par le vent"
L["Writhebark"] = "Écorce tordue"
L["Decayed Writhebark"] = "Écorce tordue décomposée"
L["Frigid Writhebark"] = "Écorce tordue algide"
L["Infurious Writhebark"] = "Écorce tordue ardente"
L["Lush Writhebark"] = "Écorce tordue luxuriante"
L["Titan-Touched Writhebark"] = "Écorce tordue touchée par les Titans"
L["Windswept Writhebark"] = "Écorce tordue balayée par le vent"

-- Herbs - The War Within
L["Mycobloom"] = "Champifleur"
L["Altered Mycobloom"] = "Champifleur altéré"
L["Crystallized Mycobloom"] = "Champifleur cristallisé"
L["Irradiated Mycobloom"] = "Champifleur irradié"
L["Lush Mycobloom"] = "Champifleur luxuriant"
L["Sporefused Mycobloom"] = "Champifleur fusiospore"
L["Luredrop"] = "Pose-appât"
L["Altered Luredrop"] = "Pose-appât altérée"
L["Crystallized Luredrop"] = "Pose-appât cristallisée"
L["Irradiated Luredrop"] = "Pose-appât irradiée"
L["Lush Luredrop"] = "Pose-appât luxuriante"
L["Sporefused Luredrop"] = "Pose-appât fusiospore"
L["Arathor's Spear"] = "Lance d'Arathor"
L["Crystallized Arathor's Spear"] = "Lance d'Arathor cristallisée"
L["Irradiated Arathor's Spear"] = "Lance d'Arathor irradiée"
L["Lush Arathor's Spear"] = "Lance d'Arathor luxuriante"
L["Sporefused Arathor's Spear"] = "Lance d'Arathor fusiospore"
L["Blessing Blossom"] = "Floraison bénie"
L["Crystallized Blessing Blossom"] = "Floraison bénie cristallisée"
L["Irradiated Blessing Blossom"] = "Floraison bénie irradiée"
L["Lush Blessing Blossom"] = "Floraison bénie luxuriante"
L["Sporefused Blessing Blossom"] = "Floraison bénie fusiospore"
L["Orbinid"] = "Orbinide"
L["Altered Orbinid"] = "Orbinide altéré"
L["Crystallized Orbinid"] = "Orbinide cristallisé"
L["Irradiated Orbinid"] = "Orbinide irradié"
L["Lush Orbinid"] = "Orbinide luxuriant"
L["Sporefused Orbinid"] = "Orbinide fusiospore"

-- Herbs - Midnight
L["Argentleaf"] = true
L["Lush Argentleaf"] = true
L["Lightfused Argentleaf"] = true
L["Primal Argentleaf"] = true
L["Voidbound Argentleaf"] = true
L["Wild Argentleaf"] = true
L["Azeroot"] = true
L["Lush Azeroot"] = true
L["Lightfused Azeroot"] = true
L["Primal Azeroot"] = true
L["Voidbound Azeroot"] = true
L["Wild Azeroot"] = true
L["Mana Lily"] = true
L["Lush Mana Lily"] = true
L["Lightfused Mana Lily"] = true
L["Primal Mana Lily"] = true
L["Voidbound Mana Lily"] = true
L["Wild Mana Lily"] = true
L["Sanguithorn"] = true
L["Lush Sanguithorn"] = true
L["Lightfused Sanguithorn"] = true
L["Primal Sanguithorn"] = true
L["Voidbound Sanguithorn"] = true
L["Wild Sanguithorn"] = true
L["Tranquility Bloom"] = true
L["Lush Tranquility Bloom"] = true
L["Lightfused Tranquility Bloom"] = true
L["Primal Tranquility Bloom"] = true
L["Voidbound Tranquility Bloom"] = true
L["Wild Tranquility Bloom"] = true

-- Mines - Classic
L["Copper Vein"] = "Filon de Cuivre"
L["Tin Vein"] = "Filon d'étain"
L["Silver Vein"] = "Filon d'argent"
L["Incendicite Mineral Vein"] = "Filon de minerai d'incendicite"
L["Lesser Bloodstone Deposit"] = "Gisement de minerai pierre de Sang inférieure"
L["Iron Deposit"] = "Gisement de Fer"
L["Indurium Mineral Vein"] = "Filon de minerai d'indurium"
L["Gold Vein"] = "Filon d'or"
L["Mithril Deposit"] = "Gisement de Mithril"
L["Truesilver Deposit"] = "Gisement de Vrai-Argent"
L["Dark Iron Deposit"] = "Gisement de Sombrefer"
L["Small Thorium Vein"] = "Petit filon de Thorium"
L["Thorium Vein"] = "Filon de Thorium"
L["Rich Thorium Vein"] = "Riche filon de Thorium"
L["Small Obsidian Chunk"] = "Petit morceau d'obsidienne"
L["Large Obsidian Chunk"] = "Grand morceau d'obsidienne"

-- Mines - TBC
L["Fel Iron Deposit"] = "Gisement de Gangrefer"
L["Adamantite Deposit"] = "Gisement d'adamantite"
L["Rich Adamantite Deposit"] = "Riche Gisement d'adamantite"
L["Khorium Vein"] = "Filon de Khorium"
L["Nethercite Deposit"] = "Gisement de Néanticite"
L["Ancient Gem Vein"] = "Ancien filon de Gemmes"

-- Mines - WotLK
L["Cobalt Deposit"] = "Gisement de Cobalt"
L["Rich Cobalt Deposit"] = "Riche Gisement de Cobalt"
L["Saronite Deposit"] = "Gisement de Saronite"
L["Rich Saronite Deposit"] = "Riche Gisement de Saronite"
L["Titanium Vein"] = "Veine de Titane"

-- Mines - Cataclysm
L["Obsidium Deposit"] = "Gisement d'obsidium"
L["Rich Obsidium Deposit"] = "Riche Gisement d'obsidium"
L["Elementium Vein"] = "Filon d'élémentium"
L["Rich Elementium Vein"] = "Riche filon d'élémentium"
L["Pyrite Deposit"] = "Gisement de Pyrite"
L["Rich Pyrite Deposit"] = "Riche Gisement de Pyrite"

-- Mines - MoP
L["Ghost Iron Deposit"] = "Gisement d'ectofer"
L["Rich Ghost Iron Deposit"] = "Riche Gisement d'ectofer"
L["Kyparite Deposit"] = "Gisement de Kyparite"
L["Rich Kyparite Deposit"] = "Riche Gisement de Kyparite"
L["Trillium Vein"] = "Filon de Trillium"
L["Rich Trillium Vein"] = "Riche filon de Trillium"

-- Mines - WoD
L["True Iron Deposit"] = "Gisement de vérifer"
L["Rich True Iron Deposit"] = "Riche gisement de vérifer"
L["Smoldering True Iron Deposit"] = "Gisement fumant de vérifer"
L["Blackrock Deposit"] = "Gisement de rochenoire"
L["Rich Blackrock Deposit"] = "Riche gisement de rochenoire"

-- Mines - Legion
L["Leystone Deposit"] = "Gisement de Tellurium"
L["Leystone Seam"] = "Veine de Tellurium"
L["Living Leystone"] = "Tellurium Vivant"
L["Felslate Deposit"] = "Gisement de Gangreschiste"
L["Felslate Seam"] = "Veine de Gangreschiste"
L["Living Felslate"] = "Gangreschiste Vivant"
L["Empyrium Deposit"] = "Gisement D'Empyrium"
L["Rich Empyrium Deposit"] = "Riche Gisement D'Empyrium"
L["Empyrium Seam"] = "Veine D'Empyrium"

-- Mines - BfA
L["Monelite Deposit"] = "Gisement de monélite"
L["Rich Monelite Deposit"] = "Riche gisement de monélite"
L["Monelite Seam"] = "Veine de monélite"
L["Platinum Deposit"] = "Gisement de platine"
L["Rich Platinum Deposit"] = "Riche gisement de platine"
L["Storm Silver Deposit"] = "Gisement de foudrargent"
L["Rich Storm Silver Deposit"] = "Riche gisement de foudrargent"
L["Storm Silver Seam"] = "Veine de foudrargent"

-- Mines - Shadowlands
L["Laestrite Deposit"] = "Gisement de læstrite"
L["Rich Laestrite Deposit"] = "Riche gisement de læstrite"
L["Elethium Deposit"] = "Gisement d'éléthium"
L["Rich Elethium Deposit"] = "Riche gisement d'éléthium"
L["Solenium Deposit"] = "Gisement de solénium"
L["Rich Solenium Deposit"] = "Riche gisement de solénium"
L["Oxxein Deposit"] = "Gisement d'oxxéine"
L["Rich Oxxein Deposit"] = "Riche gisement d'oxxéine"
L["Phaedrum Deposit"] = "Gisement de phædrum"
L["Rich Phaedrum Deposit"] = "Riche gisement de phædrum"
L["Sinvyr Deposit"] = "Gisement de vicevyr"
L["Rich Sinvyr Deposit"] = "Riche gisement de vicevyr"

-- Mines - Dragonflight
L["Serevite Deposit"] = "Gisement de sérévite"
L["Hardened Serevite Deposit"] = "Gisement de sérévite durcie"
L["Infurious Serevite Deposit"] = "Gisement de sérévite ardente"
L["Molten Serevite Deposit"] = "Gisement de sérévite fondue"
L["Primal Serevite Deposit"] = "Gisement de sérévite primordiale"
L["Rich Serevite Deposit"] = "Riche gisement de sérévite"
L["Titan-Touched Serevite Deposit"] = "Gisement de sérévite touchée par les Titans"
L["Draconium Deposit"] = "Gisement de draconium"
L["Hardened Draconium Deposit"] = "Gisement de draconium durcie"
L["Infurious Draconium Deposit"] = "Gisement de draconium ardent"
L["Molten Draconium Deposit"] = "Gisement de draconium fondu"
L["Primal Draconium Deposit"] = "Gisement de draconium primordial"
L["Rich Draconium Deposit"] = "Riche gisement de draconium"
L["Titan-Touched Draconium Deposit"] = "Gisement de draconium touché par les Titans"

-- Mines - The War Within
L["Bismuth"] = "Bismuth"
L["Crystallized Bismuth"] = "Bismuth cristallisé"
L["EZ-Mine Bismuth"] = "Bismuth Mine-Trankil"
L["Rich Bismuth"] = "Bismuth riche"
L["Weeping Bismuth"] = "Bismuth larmoyant"
L["Ironclaw"] = "Griffefer"
L["Crystallized Ironclaw"] = "Griffefer cristallisé"
L["EZ-Mine Ironclaw"] = "Griffefer Mine-Trankil"
L["Rich Ironclaw"] = "Griffefer riche"
L["Weeping Ironclaw"] = "Griffefer larmoyant"
L["Aqirite"] = "Aqirite"
L["Crystallized Aqirite"] = "Aqirite cristalisée"
L["EZ-Mine Aqirite"] = "Aqirite Mine-Trankil"
L["Rich Aqirite"] = "Aqirite riche"
L["Weeping Aqirite"] = "Aqirite larmoyante"
L["Webbed Ore Deposit"] = "Gisement de minerai entoilé"

-- Mines - Midnight
L["Brilliant Silver"] = true
L["Rich Brilliant Silver"] = true
L["Lightfused Brilliant Silver"] = true
L["Primal Brilliant Silver"] = true
L["Voidbound Brilliant Silver"] = true
L["Wild Brilliant Silver"] = true
L["Refulgent Copper"] = true
L["Rich Refulgent Copper"] = true
L["Lightfused Refulgent Copper"] = true
L["Primal Refulgent Copper"] = true
L["Voidbound Refulgent Copper"] = true
L["Wild Refulgent Copper"] = true
L["Umbral Tin"] = true
L["Rich Umbral Tin"] = true
L["Lightfused Umbral Tin"] = true
L["Primal Umbral Tin"] = true
L["Voidbound Umbral Tin"] = true
L["Wild Umbral Tin"] = true
