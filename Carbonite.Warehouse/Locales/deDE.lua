if ( GetLocale() ~= "deDE" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "deDE")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"Essbar",
	"Beh\195\164lter",
	"Juwelen",
	"Glyphen",
	"Schl\195\188ssel",
	"Diverse",
	"Munition",
	"Quest",
	"K\195\182cher",
	"Zutat",
	"Rezept",
	"Handelsware",
	"Waffe",
}

L["-Warehouse-"] = true
L["Warehouse Module"] = "Lager Modul"
L["Warehouse Options"] = "Lager Optionen"
L["Add Warehouse Tooltip"] = "Lager Kurzinfo hinzuf\195\188gen"
L["When enabled, will show warehouse information in hover tooltips of items"] = "Wenn eingestellt, werden Lagerinformationen in den Schaltfl\195\164chentexten von Gegenst\195\164nden angezeigt"
L["Warehouse Font"] = "Lager Schriftart"
L["Sets the font to be used for warehouse windows"] = "Schriftart f\195\188r Lager Fenster einstellen"
L["Warehouse Font Size"] = "Schriftgr\195\182\195\159e"
L["Sets the size of the warehouse font"] = "Einstellen der Schriftgr\195\182\195\159e der Lagerfenster"
L["Warehouse Font Spacing"] = "Abstand der Lagerschrift"
L["Sets the spacing of the warehouse font"] = "Einstellen des Abstands der Lagerschrift"
L["Toggle Warehouse"] = "Lager umschalten"
L["Remove Character or Guild"] = "Gilde- oder Charakterdaten entfernen"
L["Import settings from selected character"] = "Einstellungen des ausgew\195\164hlten Charakters laden"
L["Export current settings to all characters"] = "Aktuelle Einstellungen auf alle Charakter \195\188bertragen"
L["Sync account transfer file"] = "Benutzerkontodatei syncronisieren"
L["Show Lowest Equipped Rarity"] = "Seltenheit des niedrigsten angelegten Gegenstands anzeigen"
L["Show Item Headers"] = "Gegendstandsname zeigen"
L["Sort By Rarity"] = "nach Seltenheit sortieren"
L["Show Lowest Rarity"] = "Niedrigste Seltenheit anzeigen"
L["Sort By Slot"] = "Nach Slot sortieren"
L["Import %s's character data and reload?"] = "%s's Charakterdaten einf\195\188gen und neu laden"
L["Overwrite all character settings and reload?"] = "Alle Charaktereinstellungen \195\188berschreiben und neu laden"
L["Warehouse: %d characters"] = "Lager: %d Charaktere"
L["DurPattern"] = "^Haltbarkeit (%d+) / (%d+)"
L["Show Warehouse"] = "Zeige Warenhaus"

L["Import"] = "Importieren"
L["Cancel"] = "Abbruch"
L["Export"] = "Export"
L["Warehouse"] = "Lager"
L[" Realm:%s %s"] = " Realm:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " Online seid: %s%2d:%02d:%02d|r, gespielt: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " eingenommenes Gold in dieser Sitzung:%s %s|r, pro Stunde:%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " Haltbarkeit: %s%d%%, niedrigstes %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " erhaltene EP in derzeitiger Sitzung:%s %s|r, pro Stunde:%s %.0f"
L[" Hours To Level: %s%.1f"] = " Stunden bis zum nächsten Level: %s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = " zuletzt Online: %s%s|r, gespielt: %s%s"
L[" Location: %s%s (%d, %d)"] = " Position: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " Start EP: %s%s/%s (%.0f%%)|r ausgeruht: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " EP: %s%s/%s (%.0f%%)|r ausgeruht: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " Ehrenpunkte: %s%s|r  Eroberungspunkte: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " Valor: %s%s|r  Justice: %s%s"	-- not translated not in Game anymore
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfafAlles: %s. |cffafdfafgespielt: %s%s"
L["%s's Items"] = "%s's Items"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010Keine Bankdaten vorhanden - besuche die Bank"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010Keine Daten f\195\188r Handwerkslager vorhanden - besuche die Bank"
L["---- Equipped ----"] = "---- Angelegt ----"
L["Slot"] = "Slot"
L["---- %s Equipped ----"] = "---- %s Angelegt ----"
L["All Items"] = "Alle Items"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(%s Bank)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(%s Post)"
L["%s %d (%d Worn)"] = "%s %d (%d angelegt)"
L["%s (%d Bank)"] = "%s (%d Bank)"
L["%s (%d RBank)"] = "%s (%d HwBank)"
L["%s (%s Mail)"] = "%s (%s Post)"
L["%s (%s Pets)"] = true
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Taschen:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Angelegt:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Post:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00HwBank:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = true
L["%s's %s Skills"] = "%s's %s Fertigkeiten"
L["|cffff1010No data - open %s window"] = "|cffff1010Keine Daten - \195\182ffne %s Fenster"
L["|cffffffffW%sarehouse:"] = "|cffffffffLager:"
L["LOOT_OPENED %s (%s %s)"] = "LOOT_OFFEN %s (%s %s)"
L["no LootTarget"] = "kein LootZiel"
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = "LOOT_SLOT_CLEARED #%s %s (quest)"
L["%s deleted"] = "%s gel\195\182scht"
L["enchant:(%d+)"] = "enzaubern:(%d+)"
L["item:(%d+)"] = "item:(%d+)"

-- Keybinds / Tastaturbelegungen
L["Carbonite Warehouse"] = "Carbonite Lager"
L["NxTOGGLEWAREHOUSE"] = "Lager ein/ausblenden"

L["Guilds"] = "Gilden"
L["Characters"] = "Charaktere"
L["Guild Bank"] = "Gildenbank"
L["Current Funds"] = "verf/195/188gbare Mittel"
L["Last Updated"] = "zuletzt aktualisiert"
L["Tab is empty or no access"] = "Fach ist Leer oder Keine Zugriffberechtigung"
L["ago"] = "vergangen"
L["not opened or scanned."] = "nicht ge\195\182ffnet oder gecannt"
L["Tab"] = "Fach"
L["All Characters"] = "Alle Charaktere"
L["AUTO-REPAIR"] = "AUTO-REPERATUR"
L["Auto Repair"] = "automatisch reparieren"
L["GUILD WITHDRAW"] = "GILDENREPERATUR BETRAG"
L["Not enough funds to repair."] = "Nicht genug Gold verf\195\188gbar"
L["Auto Repair Gear"] = "Ausr\195\188stung automatisch reparieren"
L["When you open a merchant, will attempt to auto repair your gear"] = "Beim Ansprechen eines H\195\164ndlers, wird versucht automatisch zu reparieren"
L["Use Guild Repair First"] = "Reperatur \195\188ber Gildenbank zuerst"
L["Will try to use guild funds to pay for repairs before your own"] = "Bezahlung der Reperatur wird versucht von der Gilde zu bezahlen, bevor vom eigenen Gold bezahlt wird"

L["Verbose Selling"] = "Ausf\195\188hrlicher Verkauf"
L["When enabled shows what items got sold instead of just the grand total earned."] = "Anzeige der Verkauften Gegenst\195\164nde, anstatt der Zusammenfassung des erhaltenen Goldes"
L["Test Selling"] = "Test Verkauf"
L["Enabling this allows you to see what would get sold, without actually selling."] = "Erlaubt das Anzeigen welche Gegenst\195\164nde verkauft werden w\195\188rden, ohne zu verkaufen"
L["Warehouse"] = "Lager"
L["Auto Sell"] = "Automatisch Verkaufen"
L["Items"] = "Gegenst\195\164nde"
L["Grey"] = "Graue"
L["White"] = "Wei\195\159e "
L["Green"] = "Gr\195\188ne"
L["Blue"] = "Blaue / seltene"
L["Purple"] = "Lila / Epische"
L["Selling"] = "Verkaufen"
L["When you open a merchant, will auto sell your grey items"] = "Automatischer Verkauf deiner grauer Gegenst\195\164nde, sobald ein H\195\164ndler angesprochen wird"
L["When you open a merchant, will auto sell your white items."] = "Automatischer Verkauf deiner wei195\159en Gegenst\195\164nde, sobald ein H\195\164ndler angesprochen wird"
L["When you open a merchant, will auto sell your green items."] = "Automatischer Verkauf deiner gr\195\188nen Gegenst\195\164nde, sobald ein H\195\164ndler angesprochen wird"
L["When you open a merchant, will auto sell your blue items."] = "Automatischer Verkauf deiner blauen Gegenst\195\164nde, sobald ein H\195\164ndler angesprochen wird"
L["When you open a merchant, will auto sell your purple items."] = "Automatischer Verkauf deiner epischen Gegenst\195\164nde, sobald ein H\195\164ndler angesprochen wird"
L["iLevel"] = "iLevel"
L["Enable iLevel Limit"] = "iLevel Limit festlegen"
L["Only sells items that are under the ilvl specified"] = "Nur Gegenst\195\164nde unterhalb des angegbenen iLevel werden verkauft"
L["Sets the maximum item level which will be auto sold"] = "Festlegung des maximalen iLevel bis zu welchem automatisch verkauft wird"
L["Sell BOP Items"] = "Verkaufe BOP Gegenst\195\164nde"
L["When enabled will sell items that are BOP"] = "Verkauf aller seelengebunden Gegenst\195\164nde"
L["Sell BOE Items"] = "Verkaufe BOE Gegenst\195\164nde"
L["When enabled will sell items that are BOE"] = "Verkauf aller beim anlegen gebundener Gegenst\195\164nde"
L["Sell items based on a list"] = "Verkaufe Gegenst\195\164nde nach festgelegter Liste"
L["If item name matches one on the list, auto-sell it"] = "Wenn der Name des Gegenstands auf der Liste steht, wird dieser automatisch verkauft"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "Trage den Namen des zu automatisch zu verkaufenden Gegenstands ein, du kannst diesen auch aus dem Inventar per drag and drop einf\195\188gen"
L["New Item To Sell (Case Insensative)"] = "Neuer Gegenstand zum Verkaufen (Groß-/Kleinschreibung nicht unterschieden)"
L["AUTO-SELL: You Earned"] = "AUTO-VERKAUF: du hast verdient"
L["Delete Item"] = "Gegenstand l\195\182schen"
L["Delete"] = "L\195\182schen"
L["Yes"] = "Ja"
L["No"] = "Nein"

L["Show coin count in warehouse list"] = "Zeige Goldbestand in der Lagerliste an"
L["Restores the coin totals after character names in warehouse listing"] = "Zeigt den Goldbestand hinter den Charackternamen in der Lager\195\188bersicht wieder an"

L["Use don't display list"] = "Nicht anzeigen Liste verwenden"
L["If enabled, don't show listed items in tooltips"] = "In aktiviertem Zustand werden die gelisteten Items nicht in den Tooltips angezeigt"
L["New Item To Ignore (Case Insensative)"] = "Neues Item zum Ignorieren"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "Trage den Namen des Items ein welches nicht in den Tooltips angezeigt werden soll. Du Kannst auch aus deinem Inventar einfügen per drag und drop"
L["Ignore"] = "Ignorieren"

-- Font outline/shadow options
L["Font Outline"] = "Schriftkontur"
L["Font Shadow"] = "Schriftschatten"
L["Sets the outline style of this font"] = "Legt den Konturstil dieser Schriftart fest"
L["Adds a drop shadow to this font"] = "Fügt dieser Schriftart einen Schlagschatten hinzu"
L["None"] = "Keine"
L["Outline"] = "Kontur"
L["Thick Outline"] = "Dicke Kontur"
