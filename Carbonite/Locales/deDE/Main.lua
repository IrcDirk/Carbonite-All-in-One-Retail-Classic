if ( GetLocale() ~= "deDE" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "deDE")
if not L then return end

NXClassLocToCap = {
	["Todesritter"] = "DEATHKNIGHT",
	["Druide"] = "DRUID",
	["Druidin"] = "DRUID",
	["J\195\164ger"] = "HUNTER",
	["J\195\164gerin"] = "HUNTER",
	["Magier"] = "MAGE",
	["Magierin"] = "MAGE",
	["M\195\182nch"] = "MONK",
	["Paladin"] = "PALADIN",
	["Priester"] = "PRIEST",
	["Priesterin"] = "PRIEST",
	["Schurke"] = "ROGUE",
	["Schurkin"] = "ROGUE",
	["Schamane"] = "SHAMAN",
	["Schamanin"] = "SHAMAN",
	["Hexenmeister"] = "WARLOCK",
	["Hexenmeisterin"] = "WARLOCK",
	["Krieger"] = "WARRIOR",
	["Kriegerin"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = "Carbonite"
L["CARBONITE"] = "CARBONITE"
L["Loading"] = "Laden"
L["Loading Done"] = "Fertig geladen"
L["None"] = "Nichts"
L["Goto"] = "Gehe zu"
L["Show Player Zone"] = "Zeige Spieler-Zone"
L["Menu"] = "Men\195\188"
L["Show Selected Zone"] = "Zeige gew\195\164hlte Zone"
L["Add Note"] = "Notiz hinzuf\195\188gen"
L["TopRight"] = "Oben rechts"
L["Help"] = "Hilfe"
L["Options"] = "Einstellungen"
L["Toggle Map"] = "Karte ein-/ausblenden"
L["Toggle Combat Graph"] = "Kampfverlauf ein-/ausblenden"
L["Toggle Events"] = "Ereignisse ein-/ausblenden"
L["Left-Click to Toggle Map"] = "Linksklick, um die Karte ein-/auszublenden"
L["Shift Left-Click to Toggle Minimize"] = "Umschalt + Linksklick, um zu minimieren/maximieren"
L["Middle-Click to Toggle Guide"] = "Mittel-Klick, um den Wegweiser ein-/auszublenden"
L["Right-Click for Menu"] = "Rechtsklick f\195\188r Men\195\188"
L["Carbonite requires v5.0 or higher"] = "Carbonite ben\195\182tigt v5.0 oder h\195\182her"
L["GUID player"] = "GUID Spieler"
L["GUID NPC"] = "GUID Nichtspielercharakter"
L["GUID pet"] = "GUID Tier"
L["Unit map error"] = "interner Kartenfehler" -- pls review
L["Gather"] = "Sammeln"
L["Entered"] = "Betreten"
L["Level"] = "Stufe"
L["Deaths"] = "Tode"
L["Bonus"] = "Bonus"
L["Reset old data"] = "Alte Daten zur\195\188cksetzen"
L["Reset old global options"] = "Alte globale Einstellungen zur\195\188cksetzen"
L["Options have been reset for the new version."] = "Optionen wurden f\195\188r die neue Version zur\195\188ckgesetzt"
L["Privacy or other settings may have changed."] = "Privatsph\195\164ren- oder andere Einstellungen haben sich m\195\182glicherweise ge\195\164ndert"
L["Cleaned"] = "Bereinigt"
L["items"] = "Gegenst\195\164nde"
L["Reset old HUD options"] = "Alte Anzeigeoptionen zur\195\188cksetzen"
L["Reset old travel data"] = "Alte Reisedaten zur\195\188cksetzen"
L["Reset old gather data"] = "Alte Sammeldaten zur\195\188cksetzen"
L["Missing character data!"] = "Charakter-Daten fehlen!"
L["Deathknight"] = "Todesritter"
L["Death Knight"] = "Todesritter"
L["Version"] = "Version"
L["Maintained by"] = "Gepflegt von"
L["crit"] = "Kritischer Treffer"
L["hit"] = "Treffer"
L["Killed"] = "Get\195\182tet"
L["honor"] = "Ehre"
L["Hit"] = "Treffer"
L["Peak"] = "Spitze"
L["Best"] = "am Besten"
L["Total"] = "Total"
L["Time"] = "Zeit"
L["Event"] = "Ereignis"
L["Events"] = "Ereignisse"
L["Position"] = "Position"
L["Died"] = "Gestorben"
L["Picked"] = "Gepfl\195\188ckt"
L["Mined"] = "Abgebaut"
L["Fished"] = "Geangelt"
L["Unknown herb"] = "Unbekanntes Kraut"
L["Unknown ore"] = "Unbekanntes Erz"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Gathermate2_Data_Carbonite Addon ist nicht geladen!"
L["Imported"] = "Importiert"
L["nodes from GatherMate2_Data"] = "Sammelstellen von GatherMate2_Data"
L["Delete visited vendor data?"] = "Daten besuchter H\195\164ndler l\195\182schen?"
L["This will stop the attempted retrieval of items on login."] = "Das wird die versuchte Gegenstands-Wiederherstellung beim Login unterbrechen."
L["Delete"] = "L\195\182schen"
L["Cancel"] = "Abbrechen"
L["items retrieved"] = "Gegenst\195\164nde abgerufen"
L["Item retrieval from server complete"] = "Gegenstands-Erfassung vom Server vollst\195\164ndig"
L["Show Map"] = "Karte zeigen"
L["Show Combat Graph"] = "Kampfverlauf zeigen"
L["Show Events"] = "Ereignisse zeigen"
L["Show Auction Buyout Per Item"] = "Zeige Auktionskauf/Gegenstand"
L["Show Com Window"] = "Kommunikations-Fenster zeigen"
L["Toggle Profiling"] = "Profilerstellung an-/ausschalten"
L["Left click toggle Map"] = "Linksklick blendet die Karte ein/aus"
L["Shift left click toggle minimize"] = "Umschalt + Linksklick zum minimieren/maximieren"
L["Alt left click toggle Watch List"] = "Alt + Linksklick schaltet Beobachtungsliste ein/aus"
L["Middle click toggle Guide"] = "Mittelklick schaltet Wegweiser an/aus"
L["Right click for Menu"] = "Rechtsklick f\195\188r Men\195\188"
L["Shift drag to move"] = "Umschalt-Ziehen zum Bewegen"
L["Hide In Combat"] = "Im Kampf verstecken"
L["Lock"] = "Feststellen"
L["Fade In"] = "Einblenden"
L["Fade Out"] = "Ausblenden"
L["Layer"] = "Ebene"
L["Scale"] = "Skalierung"
L["Transparency"] = "Transparenz"
L["Reset Layout"] = "Layout zur\195\188cksetzen"

-- UI Tooltips
L["Close/Menu"] = "Schlie\195\159en/Men\195\188"
L["Close/Unlock"] = "Schlie\195\159en/Entsperren"
L["Pick Color"] = "Farbe ausw\195\164hlen"
L["Unlock"] = "Entsperren"
L["Maximize"] = "Maximieren"
L["Restore"] = "Wiederherstellen"
L["Minimize"] = "Minimieren"
L["Auto Scale"] = "Auto-Skalierung"

-- Stuff from old localization
L["Searching for Artifacts"] = "Suche nach Artefakten" 		-- NXlARTIFACTS
L["Extract Gas"] = "Gas extrahieren"				-- NXlEXTRACTGAS
L["Herb Gathering"] = "Kr\195\164utersammeln"			-- NXlHERBGATHERING
L["In Conflict"] = "Umk\195\164mpft"				-- NXlINCONFLICT
L["Opening"] = "\195\150ffnen"					-- NXlOpening
L["Opening - No Text"] = "\195\150ffnen - Kein Text"		-- NXlOpeningNoText
L["Everfrost Chip"] = "Immerfrostsplitter"			-- NXlEverfrost

L["yds"] = "m"
L["secs"] = "sek"
L["mins"] = "min"

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = true
L[" EScale %f, Lvl %f"] = true
L[" LR %f, %f"] = true
L[" BT %f, %f"] = true
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = true
L["%.1f days"] = "%.1f Tage"
L["%.1f hours"] = "%.1f Stunden"
L["%d mins"] = "%d Minuten"
L["Reset old layout data"] = "alte Gestaltungsdaten zur\195\188cksetzen"
L["Window version mismatch!"] = "Fenster Version Unterschied"
L["XY missing (%s)"] = "XY fehlt (%s)"
L["Window not found (%s)"] = "Fenster nicht gefunden (%s)"
L["Detach %s"] = "L\195\182se %s"
L["Detach found %s"] = "Abl\195\182sung gefunden %s"
L["Search: [click]"] = "Suche: [Klick]"
L["Search: %[click%]"] = "Suche: %[click%]"
L["Reset old list data"] = "Alte Listendaten zur\195\188cksetzen"
L["!BUT %s"] = true
L["Key %s transfered to Watch List Item"] = true
L["CLICK (.+):"] = "KLICK (.+):"
L["Key %s %s #%s %s"] = true
L["shift left/right click to change size"] = "Umschalt Links/Rechts Klick um Grß195\182\195\159e zu \194\164ndern"
L["Reset old tool bar data"] = "Alte Funktionsleistendaten zur\195\188cksetzen"
L["|cffffff00%dg"] = true
L["%s |cffbfbfbf%ds"] = true
L["%s |cff7f7f00%dc"] = true

-- NxTravel.lua
L["Connection: %s to %s"] = "Verbindung: %s nach %s"
L["Fly: %s to %s"] = "Fliege: %s nach %s"

-- NxHud.lua
L[" %.1f deg"] = true
L[" %d deg"] = true
L["Remove Current Point"] = true
L["Remove All Points"] = true

-- Carbonite.Info kill-marker tooltip
L["kill"] = "Tötung"
L["death"] = "Tod"
L["kills: %s"] = "Tötungen: %s"
L["NPC ID: %s"] = "NSC-ID: %s"
