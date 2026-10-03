if ( GetLocale() ~= "itIT" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "itIT")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["Cavaliere della Morte"] = "DEATHKNIGHT",
	["Druido"] = "DRUID",
	["Druida"] = "DRUID",
	["Cacciatore"] = "HUNTER",
	["Cacciatrice"] = "HUNTER",
	["Mago"] = "MAGE",
	["Maga"] = "MAGE",
	["Monaco"] = "MONK",
	["Monaca"] = "MONK",
	["Paladino"] = "PALADIN",
	["Paladina"] = "PALADIN",
	["Sacerdote"] = "PRIEST",
	["Sacerdotessa"] = "PRIEST",
	["Ladro"] = "ROGUE",
	["Ladra"] = "ROGUE",
	["Sciamano"] = "SHAMAN",
	["Sciamana"] = "SHAMAN",
	["Stregone"] = "WARLOCK",
	["Strega"] = "WARLOCK",
	["Guerriero"] = "WARRIOR",
	["Guerriera"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = "Carbonite"
L["CARBONITE"] = "CARBONITE"
L["Loading"] = "Caricamento"
L["Loading Done"] = "Caricamento Completato"
L["None"] = true
L["Goto"] = "Vai"
L["Show Player Zone"] = "Mostra Zona Giocatore"
L["Menu"] = true
L["Show Selected Zone"] = "Mostra Zona Selezionata"
L["Add Note"] = "Aggiungi Nota"
L["TopRight"] = "Alto a Destra"
L["Help"] = "Aiuto"
L["Options"] = "Opzioni"
L["Toggle Map"] = "Dis/Attiva Mappa"
L["Toggle Combat Graph"] = "Dis/Attiva Grafico Combattimento"
L["Toggle Events"] = "Dis/Attiva Eventi"
L["Left-Click to Toggle Map"] = "Click Sinistro per Dis/Attivare la Mappa"
L["Shift Left-Click to Toggle Minimize"] = "Maiuscola + Click Sinistro per Dis/Attivare la Minimizzazione"
L["Middle-Click to Toggle Guide"] = "Click Tasto Centrale Mouse per Dis/Attivare la Guida"
L["Right-Click for Menu"] = "Click Tasto Destro per il Menu"
L["Carbonite requires v5.0 or higher"] = "Carbonite richiede v5.0 o superiore"
L["GUID player"] = "GUID giocatore"
L["GUID NPC"] = "GUID PNG"
L["GUID pet"] = "GUID famiglio"
L["Unit map error"] = "Errore di Mappa"
L["Gather"] = "Raccogli"
L["Entered"] = "Entrato"
L["Level"] = "Livello"
L["Deaths"] = "Morti"
L["Bonus"] = "Bonus"
L["Reset old data"] = "Resetta i vecchi dati"
L["Reset old global options"] = "Resetta le vecchie opzioni globali"
L["Options have been reset for the new version."] = "Le Opzioni sono state resettate per la nuova versione"
L["Privacy or other settings may have changed."] = "Privacy o altri settaggi possono essere cambiati"
L["Cleaned"] = "Pulito"
L["items"] = "oggetti"
L["Reset old HUD options"] = "Resettate le vecchie opzioni dell'HUD"
L["Reset old travel data"] = "Resettati i vecchi valori dei tragitti"
L["Reset old gather data"] = "Resettati i vecchi valori di raccolta"
L["Missing character data!"] = "I dati del Personaggio sono andati persi!"
L["Deathknight"] = "Cavalliere della Morte"
L["Death Knight"] = "Cavalliere della Morte"
L["Version"] = "Versione"
L["Maintained by"] = "Mantenuto da"
L["crit"] = "Indice Crit"
L["hit"] = "colpo"
L["Killed"] = "Uccisi"
L["honor"] = "onore"
L["Hit"] = "Colpo"
L["Peak"] = "Picco"
L["Best"] = "Migliore"
L["Total"] = "Totale"
L["Time"] = "Tempo"
L["Event"] = "Evento"
L["Events"] = "Eventi"
L["Position"] = "Posizione"
L["Died"] = "Morto"
L["Picked"] = "Raccolto"
L["Mined"] = "Estratto"
L["Fished"] = "Pescato"
L["Unknown herb"] = "Erba Sconosciuta"
L["Unknown ore"] = "Minerale Sconosciuto"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "L'addon Gathermate2_Data_Carbonite non \195\168 stato caricato!"
L["Imported"] = "Importato"
L["nodes from GatherMate2_Data"] = "Nodi da Gathermate2_Data"
L["Delete visited vendor data?"] = "Cancellare i dati dei vendor visitati?"
L["This will stop the attempted retrieval of items on login."] = "Questo impedir\195\160 il tentativo di recuperare informazioni sugli oggetti durante la fase di accesso al gioco"
L["Delete"] = "Cancella"
L["Cancel"] = "Annulla"
L["items retrieved"] = "informazioni sugli oggetti recuperati"
L["Item retrieval from server complete"] = "informazioni sugli oggetti recuperati dal server effettuata"
L["Show Map"] = "Mostra Mappa"
L["Show Combat Graph"] = "Mostra Grafico di Combattimento"
L["Show Events"] = "Mostra Eventi"
L["Show Auction Buyout Per Item"] = "Mostra Prelazione d'Asta per Oggetto"
L["Show Com Window"] = "Mostra Finestra Comunicazioni"
L["Toggle Profiling"] = "Dis/Attiva Profili"
L["Left click toggle Map"] = "Click Tasto Destro Dis/Attiva Mappa"
L["Shift left click toggle minimize"] = "Maiuscola + Click Sinistro Dis/Attiva Minimizzazione"
L["Alt left click toggle Watch List"] = "Alt + Click Sinistro Dis/Attiva Lista Visualizzazione"
L["Middle click toggle Guide"] = "Click Tasto Centrale Mouse Dis/Attiva Guida"
L["Right click for Menu"] = "Click Destro per il Menu"
L["Shift drag to move"] = "Maiuscola + Trascinare per Muovere"
L["Hide In Combat"] = "Nascondi in Combattimento"
L["Lock"] = "Blocca"
L["Layer"] = "Strato"
L["Scale"] = "Scala"
L["Transparency"] = "Trasparenza"
L["Reset Layout"] = "Resetta Strati"

-- UI Tooltips
L["Close/Menu"] = "Chiudi/Menu"
L["Close/Unlock"] = "Chiudi/Sblocca"
L["Pick Color"] = "Prendi Colore"
L["Unlock"] = "Sblocca"
L["Maximize"] = "Massimiza"
L["Restore"] = "Ripristina"
L["Minimize"] = "Minimizza"
L["Auto Scale"] = "Autodimensiona"

-- Stuff from old localization
L["Searching for Artifacts"] = "Ricerca di Manufatti"
L["Extract Gas"] = "Estrazione di Gas"				-- NXlEXTRACTGAS
L["Herb Gathering"] = "Raccolta Erbe"				-- NXlHERBGATHERING
L["In Conflict"] = "Territorio Conteso"				-- NXlINCONFLICT
L["Opening"] = "Apertura"					-- NXlOpening
L["Opening - No Text"] = "Apertura - Nessun Testo"		-- NXlOpeningNoText
L["Everfrost Chip"] = "Morceau de permagivre"			-- NXlEverfrost

L["yds"] = "mtr"
L["secs"] = "sec"
L["mins"] = "min"

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = " Frame: %s Mostrato%d Vis%d P>%s"
L[" EScale %f, Lvl %f"] = " EScale %f, Liv %f"
L[" LR %f, %f"] = " LR %f, %f"
L[" BT %f, %f"] = " BT %f, %f"
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = "%s#%d %s ID%s (%s) show%d l%d x%d y%d"
L["%.1f days"] = "%.1f giorni"
L["%.1f hours"] = "%.1f ore"
L["%d mins"] = "%d min"
L["Reset old layout data"] = "Ripristinato vecchio layout"
L["Window version mismatch!"] = "Versione Window non pertinente!"
L["XY missing (%s)"] = "XY mancante (%s)"
L["Window not found (%s)"] = "Finestra non trovata (%s)"
L["Detach %s"] = "Distacca %s"
L["Detach found %s"] = "Distacco trovato %s"
L["Search: [click]"] = "Cerca: [click]"
L["Search: %[click%]"] = "Cerca: %[click%]"
L["Reset old list data"] = "Ripristino vecchi dati lista"
L["!BUT %s"] = "!BUT %s"
L["Key %s transfered to Watch List Item"] = "Chiave %s trasferita a Watch List Item"
L["CLICK (.+):"] = true
L["Key %s %s #%s %s"] = "Chiave %s %s #%s %s"
L["shift left/right click to change size"] = "shift + click mouse sinistro/destro per cambiare dimensione"
L["Reset old tool bar data"] = "Ripristino vecchi dati barra strumenti"
L["|cffffff00%dg"] = "|cffffff00%do"
L["%s |cffbfbfbf%ds"] = "%s |cffbfbfbf%da"
L["%s |cff7f7f00%dc"] = "%s |cff7f7f00%dr"

-- NxTravel.lua
L["Connection: %s to %s"] = "Connessione: %s a %s"
L["Fly: %s to %s"] = "Volo: %s a %s"

-- NxHud.lua
L[" %.1f deg"] = " %.1f gradi"
L[" %d deg"] = " %d gradi"
L["Remove Current Point"] = "Rimuovi Punto Attuale"
L["Remove All Points"] = "Rimuovi Tutti i Punti"

-- Carbonite.Info kill-marker tooltip
L["kill"] = "uccisione"
L["death"] = "morte"
L["kills: %s"] = "uccisioni: %s"
L["NPC ID: %s"] = "ID PNG: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "Clic sinistro"
L["Right click"] = "Clic destro"
L["Toggle icons"] = "Mostra/nascondi icone"
L["Context menu"] = "Menu contestuale"
L["Open settings"] = "Apri impostazioni"
L["Whats New!"] = "Novità!"
L["Don't show for this update again"] = "Non mostrare più per questo aggiornamento"
L["Carbonite What's New"] = "Novità di Carbonite"
L["Carbonite.Gathermate2_Data addon is not loaded!"] = "L'addon Carbonite.Gathermate2_Data non è caricato!"
L["nodes from Carbonite.Gathermate2_Data"] = "nodi da Carbonite.Gathermate2_Data"
L["Health"] = "Salute"
