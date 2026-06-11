if ( GetLocale() ~= "esES" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "esES")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"Consumible",
	"Contenedor",
	"Gema",
	"Glifo",
	"Llave",
	"Miscel\195\161nea",
	"Proyectil",
	"Misi\195\179n",
	"Carcaj",
	"Componente",
	"Receta",
	AUCTION_CATEGORY_TRADE_GOODS,
	"Objeto comerciable",
	"Arma",
}

L["-Warehouse-"] = true
L["Warehouse Module"] = true
L["Warehouse Options"] = true
L["Add Warehouse Tooltip"] = true
L["When enabled, will show warehouse information in hover tooltips of items"] = true
L["Warehouse Font"] = true
L["Sets the font to be used for warehouse windows"] = true
L["Warehouse Font Size"] = true
L["Sets the size of the warehouse font"] = true
L["Warehouse Font Spacing"] = true
L["Sets the spacing of the warehouse font"] = true
L["Toggle Warehouse"] = true
L["Remove Character or Guild"] = true
L["Import settings from selected character"] = true
L["Export current settings to all characters"] = true
L["Sync account transfer file"] = true
L["Show Lowest Equipped Rarity"] = true
L["Show Item Headers"] = true
L["Sort By Rarity"] = true
L["Show Lowest Rarity"] = true
L["Sort By Slot"] = true
L["Import %s's character data and reload?"] = true
L["Overwrite all character settings and reload?"] = true
L["Warehouse: %d characters"] = true
L["DurPattern"] = "^Durabilidad (%d+) / (%d+)"
L["Show Warehouse"] = true

L["Import"] = true
L["Cancel"] = true
L["Export"] = true
L["Warehouse"] = true
L[" Realm:%s %s"] = true
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = true
L[" Session Money:%s %s|r, Per Hour:%s %s"] = true
L[" Durability: %s%d%%, lowest %d%%"] = true
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = true
L[" Hours To Level: %s%.1f"] = true
L[" Last On: %s%s|r, Played: %s%s"] = true
L[" Location: %s%s (%d, %d)"] = true
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = true
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = true
L[" Honor: %s%s|r  Conquest: %s%s"] = true
L[" Valor: %s%s|r  Justice: %s%s"] = true
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = true
L["%s's Items"] = true
L["|cffff1010No bank data - visit your bank"] = true
L["|cffff1010No reagent bank data - visit your bank"] = true
L["---- Equipped ----"] = true
L["Slot"] = true
L["---- %s Equipped ----"] = true
L["All Items"] = true
L["%s |cffcfcfff(%s Bank)"] = true
L["%s |cffcfffff(%s Mail)"] = true
L["%s %d (%d Worn)"] = true
L["%s (%d Bank)"] = true
L["%s (%d RBank)"] = true
L["%s (%s Mail)"] = true
L["%s (%s Pets)"] = true
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = true
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = true
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = true
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = true
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = true
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = true
L["%s's %s Skills"] = true
L["|cffff1010No data - open %s window"] = true
L["|cffffffffW%sarehouse:"] = true
L["LOOT_OPENED %s (%s %s)"] = true
L["no LootTarget"] = true
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = true
L["%s deleted"] = true
L["enchant:(%d+)"] = true
L["item:(%d+)"] = true

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite Warehouse"
L["NxTOGGLEWAREHOUSE"] = "show/hide Warehouse"

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
L["Font Outline"] = "Contorno de la fuente"
L["Font Shadow"] = "Sombra de la fuente"
L["Sets the outline style of this font"] = "Establece el estilo de contorno de esta fuente"
L["Adds a drop shadow to this font"] = "Añade una sombra a esta fuente"
L["None"] = "Ninguno"
L["Outline"] = "Contorno"
L["Thick Outline"] = "Contorno grueso"
