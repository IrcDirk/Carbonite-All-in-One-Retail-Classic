if ( GetLocale() ~= "itIT" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "itIT")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"Consumabili",
	"Contenitori",
	"Gemme",
	"Glifi",
	"Chiavi",
	"Varie",
	"Proiettili",
	"Missioni",
	"Faretre",
	"Reagenti",
	"Ricette",
	AUCTION_CATEGORY_TRADE_GOODS,
	"Oggetti Artigianato",
	"Armi",
}

L["-Warehouse-"] = "-Magazzino-"
L["Warehouse Module"] = "Modulo Magazzino"
L["Warehouse Options"] = "Opzioni Magazzino"
L["Add Warehouse Tooltip"] = "Aggiungi Infonote Magazzino"
L["When enabled, will show warehouse information in hover tooltips of items"] = "Quando abilitato, sar\195\160 mostrata una breve descrizione degli oggetti in una finestrella 'volante'"
L["Warehouse Font"] = "Caratteri Magazzino"
L["Sets the font to be used for warehouse windows"] = "Imposta il carattere tipografico per le finestre del Magazzino"
L["Warehouse Font Size"] = "Dimensione Caratteri Magazzino"
L["Sets the size of the warehouse font"] = "Imposta la dimensione del carattere tipografico del Magazzino"
L["Warehouse Font Spacing"] = "Spazio Caratteri Magazzino"
L["Sets the spacing of the warehouse font"] = "Imposta lo spazio tra i caratteri tipografici del Magazzino"
L["Toggle Warehouse"] = "Dis/Attiva Magazzino"
L["Remove Character or Guild"] = "Rimuovi il Personaggio o la Gilda"
L["Import settings from selected character"] = "Importa le impostazioni da un altro personaggio"
L["Export current settings to all characters"] = "Esporta le impostazioni attuali a tutti i personaggi del Magazzino"
L["Sync account transfer file"] = "Sincronizza il trasferimento dati dell'account"
L["Show Lowest Equipped Rarity"] = "Mostra la Rarit\195\160 pi\195\185 bassa dell'equipaggiamento"
L["Show Item Headers"] = "Mostra Titolo Oggetto"
L["Sort By Rarity"] = "Ordina per Rarit\195\160"
L["Show Lowest Rarity"] = "Mostra Rarit\195\160 pi\195\185 Bassa"
L["Sort By Slot"] = "Ordina per Spazio"
L["Import %s's character data and reload?"] = "Importo i dati del personaggio %s e ricarico l'interfaccia?"
L["Overwrite all character settings and reload?"] = "Sovrascrivo tutte le impostazioni dei personaggi e ricarico l'interfaccia?"
L["Warehouse: %d characters"] = "Magazzino: %d Personaggi"
L["DurPattern"] = "Durabilit\195\160 (%d+) / (%d+)"
L["Show Warehouse"] = "Mostra Magazzino"

L["Import"] = "Importa"
L["Cancel"] = "Annulla"
L["Export"] = "Esporta"
L["Warehouse"] = "Magazzino"
L[" Realm:%s %s"] = " Reame:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " Attivo: %s%2d:%02d:%02d|r, Giocato: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " Denaro della Sessione:%s %s|r, All'Ora:%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " Danneggiato: %s%d%%, il peggiore %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " ESP Sessione:%s %s|r, Per Ora:%s %.0f"
L[" Hours To Level: %s%.1f"] = " Ore al prossimo Livello: %s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = " Ultima data: %s%s|r, Giocato: %s%s"
L[" Location: %s%s (%d, %d)"] = " Luogo: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " ESP Iniziale: %s%s/%s (%.0f%%)|r Riposato: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " ESP: %s%s/%s (%.0f%%)|r Riposato: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " Onori: %s%s|r  Conquista: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " Valore: %s%s|r  Giustizia: %s%s"
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfafTutto: %s. |cffafdfafGiocato: %s%s"
L["%s's Items"] = true
L["|cffff1010No bank data - visit your bank"] = "|cffff1010Nessun Dato dalla Banca - Visita la Tua Banca"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010Nessun Dato dalla Banca Reagenti - Visita la Tua Banca Reagenti"
L["---- Equipped ----"] = "---- Equipaggiato ----"
L["Slot"] = true
L["---- %s Equipped ----"] = "---- %s Equipaggiati ----"
L["All Items"] = "Tutti gli Oggetti"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(%s Banca)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(%s Posta)"
L["%s %d (%d Worn)"] = "%s %d (%d Indossato)"
L["%s (%d Bank)"] = "%s (%d Banca)"
L["%s (%d RBank)"] = "%s (%d BancaReag)"
L["%s (%s Mail)"] = "%s (%s Posta)"
L["%s (%s Pets)"] = true
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Borse:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Indossati:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Posta:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Banca:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00BancaReag:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = true
L["%s's %s Skills"] = "%s %s Abilit\195\160"
L["|cffff1010No data - open %s window"] = "|cffff1010Nessun Dato - Apri la Finestra %s"
L["|cffffffffW%sarehouse:"] = "|cffffffffM%sagazzino:"
L["LOOT_OPENED %s (%s %s)"] = true
L["no LootTarget"] = true
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = true
L["%s deleted"] = "%s cancellato"
L["enchant:(%d+)"] = "incanto:(%d+)"
L["item:(%d+)"] = "oggetto:(%d+)"

-- Keybinds
L["Carbonite Warehouse"] = "Magazzino Carbonite"
L["NxTOGGLEWAREHOUSE"] = "Mostra/Nascondi Magazzino"

L["Guilds"] = true
L["Characters"] = true
L["Guild Bank"] = true
L["Current Funds"] = true
L["Last Updated"] = true
L["Tab is empty or no access"] = true
L["ago"] = true
L["not opened or scanned."] = true
L["Tab"] = true
L["All Characters"] = true
L["AUTO-REPAIR"] = true
L["Auto Repair"] = true
L["GUILD WITHDRAW"] = true
L["Not enough funds to repair."] = true
L["Auto Repair Gear"] = true
L["When you open a merchant, will attempt to auto repair your gear"] = true
L["Use Guild Repair First"] = true
L["Will try to use guild funds to pay for repairs before your own"] = true

L["Verbose Selling"] = true
L["When enabled shows what items got sold instead of just the grand total earned."] = true
L["Test Selling"] = true
L["Enabling this allows you to see what would get sold, without actually selling."] = true
L["Warehouse"] = true
L["Auto Sell"] = true
L["Items"] = true
L["Grey"] = true
L["White"] = true
L["Green"] = true
L["Blue"] = true
L["Purple"] = true
L["Selling"] = true
L["When you open a merchant, will auto sell your grey items"] = true
L["When you open a merchant, will auto sell your white items."] = true
L["When you open a merchant, will auto sell your green items."] = true
L["When you open a merchant, will auto sell your blue items."] = true
L["When you open a merchant, will auto sell your purple items."] = true
L["iLevel"] = true
L["Enable iLevel Limit"] = true
L["Only sells items that are under the ilvl specified"] = true
L["Sets the maximum item level which will be auto sold"] = true
L["Sell BOP Items"] = true
L["When enabled will sell items that are BOP"] = true
L["Sell BOE Items"] = true
L["When enabled will sell items that are BOE"] = true
L["Sell items based on a list"] = true
L["If item name matches one on the list, auto-sell it"] = true
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = true
L["New Item To Sell (Case Insensative)"] = true
L["AUTO-SELL: You Earned"] = true
L["Delete Item"] = true
L["Delete"] = true
L["Yes"] = true
L["No"] = true

L["Show coin count in warehouse list"] = true
L["Restores the coin totals after character names in warehouse listing"] = true

L["Use don't display list"] = true
L["If enabled, don't show listed items in tooltips"] = true
L["New Item To Ignore (Case Insensative)"] = true
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = true
L["Ignore"] = true

-- Font outline/shadow options
L["Font Outline"] = "Contorno del Carattere"
L["Font Shadow"] = "Ombra del Carattere"
L["Sets the outline style of this font"] = "Imposta lo stile del contorno di questo carattere"
L["Adds a drop shadow to this font"] = "Aggiunge un'ombra a questo carattere"
L["None"] = "Nessuno"
L["Outline"] = "Contorno"
L["Thick Outline"] = "Contorno Spesso"
