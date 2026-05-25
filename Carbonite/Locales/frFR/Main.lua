if ( GetLocale() ~= "frFR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "frFR")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["Chevalier de la mort"] = "DEATHKNIGHT",
	["Druide"] = "DRUID",
	["Druidesse"] = "DRUID",
	["Chasseur"] = "HUNTER",
	["Chasseresse"] = "HUNTER",
	["Mage"] = "MAGE",
	["Moine"] = "MONK",
	["Paladin"] = "PALADIN",
	["Pr\195\170tre"] = "PRIEST",
	["Pr\195\170tresse"] = "PRIEST",
	["Voleur"] = "ROGUE",
	["Voleuse"] = "ROGUE",
	["Chaman"] = "SHAMAN",
	["Chamane"] = "SHAMAN",
	["D\195\169moniste"] = "WARLOCK",
	["Guerrier"] = "WARRIOR",
	["Guerri\195\168re"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = "Carbonite"
L["CARBONITE"] = "CARBONITE"
L["Loading"] = "Chargement"
L["Loading Done"] = "Chargement Termin\195\169"
L["None"] = "Aucun"
L["Goto"] = "Destination"
L["Show Player Zone"] = "Afficher zone Joueur"
L["Menu"] = "Menu"
L["Show Selected Zone"] = "Afficher zone selectionn\195\169e"
L["Add Note"] = "Ajouter une Note"
L["TopRight"] = "En haut \195\160 Droite"
L["Help"] = "Aide"
L["Options"] = "Options"
L["Toggle Map"] = "Basculer vers Map"
L["Toggle"] = "Basculer"
L["Toggle Events"] = "Basculer vers Evenements"
L["Left-Click to Toggle Map"] = "Clic gauche pour basculer vers la map"
L["Shift Left-Click to Toggle Minimize"] = "Maj plus clic gauche pour minimiser"
L["Middle-Click to Toggle Guide"] = "Clic central pour basculer vers le Guide"
L["Right-Click for Menu"] = "Clic droit pour menu"
L["Carbonite requires v5.0 or higher"] = "Carbonite requiert v5.0 ou sup\195\169rieur"
L["GUID player"] = "GUID joueur"
L["GUID NPC"] = "GUID PNJ"
L["GUID pet"] = "GUID Familier"
L["Unit map error"] = "Unit\195\169 Erreur Map"
L["Gather"] = "R\195\169colte"
L["Entered"] = "Entr\195\169e"
L["Level"] = "Niveau"
L["Deaths"] = "Morts"
L["Bonus"] = "Bonus"
L["Reset old data"] = "R\195\169initialiser anciennes donn\195\169es"
L["Reset old global options"] = "r\195\169initialiser anciennes options globales"
L["Options have been reset for the new version."] = "Les options sont r\195\169initialis\195\169es pour la nouvelle version"
L["Privacy or other settings may have changed."] = "Vie Priv\195\169e ou d'autres r\195\169glages peuvent avoir chang\195\169"
L["Cleaned"] = "Nettoy\195\169"
L["items"] = "Objets"
L["Reset old HUD options"] = "R\195\169initialiser anciennes options HUD"
L["Reset old travel data"] = "R\195\169initialiser donn\195\169es des anciens trajets"
L["Reset old gather data"] = "R\195\169initialiser donn\195\169es des anciennes r\195\169coltes"
L["Missing character data!"] = "Donn\195\169es du personnage manquantes!"
L["Deathknight"] = "Chevalier de la Mort"
L["Death Knight"] = "Chevalier de la Mort"
L["Version"] = "Version"
L["Maintained by"] = "Maintenu Par"
L["crit"] = "Critique"
L["hit"] = "coup"
L["Killed"] = "Tu\195\169"
L["honor"] = "Honneur"
L["Hit"] = "coup"
L["Peak"] = "Pointe"
L["Best"] = "Meilleur"
L["Total"] = "Total"
L["Time"] = "Temps"
L["Event"] = "Evenement"
L["Events"] = "Evenements"
L["Position"] = "Position"
L["Died"] = "Mort"
L["Picked"] = "Cueilli"
L["Mined"] = "Min\195\169"
L["Fished"] = "P\195\170ch\195\169"
L["Unknown herb"] = "Herbe Inconnue"
L["Unknown ore"] = "Minerai Inconnu"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Gathermate2_Data_Carbonite l'add-on n'est pas charg\195\169!"
L["Imported"] = "import\195\169"
L["nodes from GatherMate2_Data"] = "Noeuds \195\160 partir de Gathermate2_Data"
L["Delete visited vendor data?"] = "Effacer donn\195\169es des vendeurs visit\195\169s?"
L["This will stop the attempted retrieval of items on login."] = "Ceci arr\195\170te la tentative de r\195\169cup\195\169ration des objets au login"
L["Delete"] = "Effacer"
L["Cancel"] = "Annuler"
L["items retrieved"] = "Objets r\195\169cup\195\169r\195\169s"
L["Item retrieval from server complete"] = "R\195\169cup\195\169ration d'objets \195\160 partir du serveur termin\195\169e"
L["Show Map"] = "Afficher Carte"
L["Show Combat Graph"] = "Afficher Graphique de Combat"
L["Show Events"] = "Afficher Evenements"
L["Show Auction Buyout Per Item"] = "Afficher ench\195\168re par Objet"
L["Show Com Window"] = "Afficher la fen\195\170tre de Com"
L["Toggle Profiling"] = "Basculement profil"
L["Left click toggle Map"] = "Clic gauche affiche la MiniMap Carbonite" --option displayed icon on the minimap carbonite
L["Shift left click toggle minimize"] = "Maj+clic gauche bascule minimis\195\169"
L["Alt left click toggle Watch List"] = "Alt+clic gauche affiche la liste de surveillance des Qu\195\170tes" --option displayed icon on the minimap carbonite
L["Middle click toggle Guide"] = "Clic central affiche le Guide" --option displayed icon on the minimap carbonite
L["Right click for Menu"] = "Clic droit pour afficher le Menu" --option displayed icon on the minimap carbonite
L["Shift drag to move"] = "Maj+clic gauche et glisser pour d\195\169placer l'ic\195\180ne" --option displayed icon on the minimap carbonite
L["Hide In Combat"] = "Masquer en Combat"
L["Lock"] = "Verrouiller"
L["Fade In"] = "Apparition Graduelle"
L["Fade Out"] = "Disparition Graduelle"
L["Layer"] = "Calque"
L["Scale"] = "Echelle"
L["Transparency"] = "Transparence"
L["Reset Layout"] = "R\195\169initialiser mise en page"

-- UI Tooltips
L["Close/Menu"] = "Fermer/Menu"
L["Close/Unlock"] = "Fermer/D\195\169verrouiller"
L["Pick Color"] = "Choisir la couleur"
L["Unlock"] = "D\195\169verrouiller"
L["Maximize"] = "Maximiser"
L["Restore"] = "Restaurer"
L["Minimize"] = "Minimiser"
L["Auto Scale"] = "Echelle automatique"

-- Stuff from old localization
L["Searching for Artifacts"] = "Recherche d'art\195\169facts"		-- NXlARTIFACTS
L["Extract Gas"] = "Extraction de gaz"					-- NXlEXTRACTGAS
L["Herb Gathering"] = "Cueillette"					-- NXlHERBGATHERING
L["In Conflict"] = "Territoire disput\195\169"				-- NXlINCONFLICT
L["Opening"] = "Ouverture"						-- NXlOpening
L["Opening - No Text"] = "Ouverture - pas de texte"			-- NXlOpeningNoText
L["Everfrost Chip"] = "Morceau de permagivre"				-- NXlEverfrost

L["yds"] = "m\195\168tres"
L["secs"] = true
L["mins"] = true

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = true
L[" EScale %f, Lvl %f"] = true
L[" LR %f, %f"] = true
L[" BT %f, %f"] = true
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = true
L["%.1f days"] = "%.1f jours"
L["%.1f hours"] = "%.1f heures"
L["%d mins"] = true
L["Reset old layout data"] = "R\195\169initialiser anciennes donn\195\169es mise en page"
L["Window version mismatch!"] = true
L["XY missing (%s)"] = "XY manquant (%s)"
L["Window not found (%s)"] = "Fen\195\170tre non trouv\195\169e (%s)"
L["Detach %s"] = true
L["Detach found %s"] = true
L["Search: [click]"] = "Rechercher: [clic]"
L["Search: %[click%]"] = "rechercher: %[clic%]"
L["Reset old list data"] = "R\195\169initialiser anciennes donn\195\169es liste"
L["!BUT %s"] = "!MAIS %s"
L["Key %s transfered to Watch List Item"] = true
L["CLICK (.+):"] = "CLIC (.+):"
L["Key %s %s #%s %s"] = true
L["shift left/right click to change size"] = "maj gauche/clic droit pour changer la taille"
L["Reset old tool bar data"] = "R\195\169initialiser anciennes donn\195\169es barre d'outils"
L["|cffffff00%dg"] = true
L["%s |cffbfbfbf%ds"] = true
L["%s |cff7f7f00%dc"] = true

-- NxTravel.lua
L["Connection: %s to %s"] = "Connection: %s vers %s"
L["Fly: %s to %s"] = "Fly: %s vers %s"

-- NxHud.lua
L[" %.1f deg"] = true
L[" %d deg"] = true
L["Remove Current Point"] = true
L["Remove All Points"] = true

-- Carbonite.Info kill-marker tooltip
L["kill"] = "tué"
L["death"] = "mort"
L["kills: %s"] = "tués: %s"
L["NPC ID: %s"] = "ID PNJ: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "Clic gauche"
L["Right click"] = "Clic droit"
L["Toggle icons"] = "Afficher/masquer les icônes"
L["Context menu"] = "Menu contextuel"
L["Open settings"] = "Ouvrir les paramètres"
