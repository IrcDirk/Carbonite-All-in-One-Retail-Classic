if ( GetLocale() ~= "itIT" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Notes", "itIT")
if not L then return end

L["Note Options"] = "Opzioni Note"
L["Show Notes On Map"] = "Mostra Note sulla Mappa"
L["Shows your notes on the carbonite map"] = "Mostra le tue Note sulla Mappa di Carbonite"
L["Show Notes"] = "Mostra Note"
L["-Notes-"] = "-Note-"
L["Add Note"] = "Aggiungi NOta"
L["Notes Module"] = "Modulo Note"
L["Toggle Notes"] = "Dis/Attiva Note"
L["Record"] = "Registra"
L["Up"] = "Su"
L["Down"] = "Gi\195\185"
L["Delete Item"] = "Cancella Oggetto"
L["Name"] = "Nome"
L["Type"] = "Tipologia"
L["Value"] = "Valore"
L["Location"] = "Locazione"
L["Select a favorite before recording"] = "Seleziona un FAVORITO prima di registrare"
L["Add Folder"] = "Aggiungi Cartella"
L["Add Favorite"] = "Aggiungi Favorito"
L["Rename"] = "Rinomina"
L["Cut"] = "Taglia"
L["Copy"] = "Copia"
L["Paste"] = "Incolla"
L["Options"] = "Opzioni"
L["Add Comment"] = "Aggiungi Commento"
L["Set Icon"] = "Imposta Icona"
L["Name"] = "Nome"
L["Nothing to paste"] = "Niente da Incollare"
L["Can't paste that on the left side"] = "Non posso incollare questo nella parte sinistra"
L["Can't paste that on the right side"] = "Non posso incollare questo nella parte destra"
L["Note"] = "Nota"
L["Notes"] = "Note"
L["Note Addons"] = "Addon Note"
L["My Notes"] = "Le mie Note"

L["Reset old notes data"] = "Reset vecchi dati note"
L["Display Handynotes On Map"] = true
L["If you have HandyNotes installed, allows them on the Carbonite map"] = true
L["Handnotes Icon Size"] = true

L["Display RareScanner icons On Map"] = true
L["If you have RareScanner installed, allows its icons on the Carbonite map"] = true
L["RareScanner Icon Size"] = true

L["Display RXPGuides waypoints On Map"] = "Mostra waypoint RXPGuides sulla mappa"
L["If you have RXPGuides installed, mirrors its active-step waypoint pins onto the Carbonite map"] = "Se hai RXPGuides installato, replica i suoi marker dei passi attivi sulla mappa di Carbonite"
L["RXPGuides Icon Size"] = "Dimensione icona RXPGuides"
L["Route RXPGuides arrow through Carbonite"] = "Instrada la freccia di RXPGuides tramite Carbonite"
L["Replaces the RXPGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"] = "Sostituisce la freccia di navigazione di RXPGuides con la freccia di viaggio (HUD) di Carbonite, puntando al passo corrente"

-- Keybinds
L["Carbonite Notes"] = "Note Carbonite"
L["NxTOGGLEFAV"] = "mostra/nascondi Note"
