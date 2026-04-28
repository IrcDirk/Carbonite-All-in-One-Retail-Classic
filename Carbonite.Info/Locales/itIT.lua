if ( GetLocale() ~= "itIT" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "itIT")
if not L then return end

L["Info Options"] = "Informazioni Opzioni"
L["Lock Info Windows"] = "Blocca Finestra Informazioni"
L["Locks the location of your info windows"] = "Blocca la posizione della tua finestra Informazioni"
L["Info Window Background Color"] = "Colore di Sfondo - Finestra Informazioni"
L["Info Font"] = "Colore Testo - Finestra Informazioni"
L["Sets the font to be used for info windows"] = "Imposta il carattere usato nella Finestra Informazioni"
L["Info Font Size"] = "Dimensione Carattere - Finestra Informazioni"
L["Sets the size of the info font"] = "Imposta la dimensione dei caratteri usati nella Finestra Informazioni"
L["Info Font Spacing"] = "Spazio Testo - Finestra Informazioni"
L["Sets the spacing of the info font"] = "Imposta lo spazio tra i caratteri usati nella Finestra Informazioni"
L["Show Info Windows"] = "Mostra Finestra Informazioni"
L["Toggle Info Windows"] = "Dis/Attiva la Finestra Informazioni"
L["Info Module"] = "Modulo Informazioni"
L["Close"] = "Chiudi"
L["Edit Item"] = "Modifica oggetto"
L["Show"] = "Mostra"
L["New Info Window"] = "Nuova Finestra Informazioni"
L["Delete This Window"] = "Cancella questa Finestra"
L["Options"] = "Opzioni"
L["Info"] = "Informazioni"
L["Edit View"] = "Modifica la Visualizzazione"
L["Stop Edit"] = "Ferma Modifiche"
L["Change Text"] = "Cambia Testo"
L["Delete Info Window"] = "Cancella Finestra Informazioni"
L["Delete"] = "Cancella"
L["Cancel"] = "Annulla"

L["One minute until the Arena"] = "1 (Uno) Minuti all'avvio dell'Arena"
L["Thirty seconds until the Arena"] = "30 (trenta) Secondi all'avvio dell'Arena"
L["Fifteen seconds until the Arena"] = "15 (quindici) Secondi all'avvio dell'Arena"

L["Reset old info data %f"] = "Reset vecchi dati info %f"
L[" begins? in (%d+) "] = " inizio? in (%d+) "
L["(%d+) minutes? until the battle"] = "(%d+) minuti? all'inizio della Battaglia"
L["Info"] = true
L["Info"] = "Info"
-- Kill marker icons (Carbonite map skull/seal markers)
L["Kill Icons"] = "Icone Uccisioni"
L["Show kill markers on map"] = "Mostra marcatori di uccisione sulla mappa"
L["When enabled, killed mobs leave a skull icon on your map at the kill location"] = "Se attivato, i mob uccisi lasciano un'icona del teschio sulla mappa nel luogo dell'uccisione"
L["Auto-clear kill markers after"] = "Rimuovi marcatori automaticamente dopo"
L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"] = "Secondi prima che un marcatore scompaia. 0 = mai (solo cancellazione manuale)"

L["Keep kill history"] = "Mantieni cronologia uccisioni per sempre"
L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."] = "Se attivato, il timer nasconde solo i marcatori scaduti ma mantiene i record. Utile come registro permanente delle uccisioni."
