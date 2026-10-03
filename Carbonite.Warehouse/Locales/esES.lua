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

L["-Warehouse-"] = "-Almacén-"
L["Warehouse Module"] = "Módulo de almacén"
L["Warehouse Options"] = "Opciones de almacén"
L["Add Warehouse Tooltip"] = "Añadir información de almacén"
L["When enabled, will show warehouse information in hover tooltips of items"] = "Cuando está activado, mostrará información del almacén en las descripciones emergentes de los objetos"
L["Warehouse Font"] = "Fuente del almacén"
L["Sets the font to be used for warehouse windows"] = "Establece la fuente usada en las ventanas del almacén"
L["Warehouse Font Size"] = "Tamaño de fuente del almacén"
L["Sets the size of the warehouse font"] = "Establece el tamaño de la fuente del almacén"
L["Warehouse Font Spacing"] = "Espaciado de fuente del almacén"
L["Sets the spacing of the warehouse font"] = "Establece el espaciado de la fuente del almacén"
L["Toggle Warehouse"] = "Alternar almacén"
L["Remove Character or Guild"] = "Quitar personaje o hermandad"
L["Import settings from selected character"] = "Importar ajustes del personaje seleccionado"
L["Export current settings to all characters"] = "Exportar ajustes actuales a todos los personajes"
L["Sync account transfer file"] = "Sincronizar archivo de transferencia de cuenta"
L["Show Lowest Equipped Rarity"] = "Mostrar rareza equipada más baja"
L["Show Item Headers"] = "Mostrar cabeceras de objetos"
L["Sort By Rarity"] = "Ordenar por rareza"
L["Show Lowest Rarity"] = "Mostrar rareza más baja"
L["Sort By Slot"] = "Ordenar por ranura"
L["Import %s's character data and reload?"] = "¿Importar los datos del personaje %s y recargar?"
L["Overwrite all character settings and reload?"] = "¿Sobrescribir los ajustes de todos los personajes y recargar?"
L["Warehouse: %d characters"] = "Almacén: %d personajes"
L["DurPattern"] = "^Durabilidad (%d+) / (%d+)"
L["Show Warehouse"] = "Mostrar almacén"

L["Import"] = "Importar"
L["Cancel"] = "Cancelar"
L["Export"] = "Exportar"
L["Warehouse"] = true
L[" Realm:%s %s"] = " Reino:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " Conectado: %s%2d:%02d:%02d|r, Jugado: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " Dinero de la sesión:%s %s|r, Por hora:%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " Durabilidad: %s%d%%, mínima %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " PX de la sesión:%s %s|r, Por hora:%s %.0f"
L[" Hours To Level: %s%.1f"] = " Horas para subir de nivel: %s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = " Última conexión: %s%s|r, Jugado: %s%s"
L[" Location: %s%s (%d, %d)"] = " Ubicación: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " PX iniciales: %s%s/%s (%.0f%%)|r Descanso: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " PX: %s%s/%s (%.0f%%)|r Descanso: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " Honor: %s%s|r  Conquista: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " Valor: %s%s|r  Justicia: %s%s"
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfafTodos: %s. |cffafdfafJugado: %s%s"
L["%s's Items"] = "Objetos de %s"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010Sin datos del banco: visita tu banco"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010Sin datos del banco de componentes: visita tu banco"
L["---- Equipped ----"] = "---- Equipado ----"
L["Slot"] = "Ranura"
L["---- %s Equipped ----"] = "---- %s equipado ----"
L["All Items"] = "Todos los objetos"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(%s en banco)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(%s en correo)"
L["%s %d (%d Worn)"] = "%s %d (%d puestos)"
L["%s (%d Bank)"] = "%s (%d en banco)"
L["%s (%d RBank)"] = "%s (%d en banco comp.)"
L["%s (%s Mail)"] = "%s (%s en correo)"
L["%s (%s Pets)"] = "%s (%s en mascotas)"
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Bolsas:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Puesto:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Correo:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Banco:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00BComp:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Mascotas:%d|cFFFF0000]"
L["%s's %s Skills"] = "%s: habilidades de %s"
L["|cffff1010No data - open %s window"] = "|cffff1010Sin datos: abre la ventana de %s"
L["|cffffffffW%sarehouse:"] = "|cffffffffA%slmacén:"
L["LOOT_OPENED %s (%s %s)"] = "LOOT_OPENED %s (%s %s)"
L["no LootTarget"] = "sin LootTarget"
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = "LOOT_SLOT_CLEARED #%s %s (misión)"
L["%s deleted"] = "%s borrado"
L["enchant:(%d+)"] = true
L["item:(%d+)"] = true

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite Warehouse"
L["NxTOGGLEWAREHOUSE"] = "show/hide Warehouse"

L["Guilds"] = "Hermandades"
L["Characters"] = "Personajes"
L["Guild Bank"] = "Banco de hermandad"
L["Current Funds"] = "Fondos actuales"
L["Last Updated"] = "Última actualización"
L["Tab is empty or no access"] = "Pestaña vacía o sin acceso"
L["ago"] = "hace"
L["not opened or scanned."] = "no abierta ni escaneada."
L["Tab"] = "Pestaña"
L["All Characters"] = "Todos los personajes"
L["AUTO-REPAIR"] = "REPARACIÓN AUTOMÁTICA"
L["Auto Repair"] = "Reparación automática"
L["GUILD WITHDRAW"] = "RETIRADA DE HERMANDAD"
L["Not enough funds to repair."] = "No hay fondos suficientes para reparar."
L["Auto Repair Gear"] = "Reparar equipo automáticamente"
L["When you open a merchant, will attempt to auto repair your gear"] = "Al abrir un mercader, intentará reparar tu equipo automáticamente"
L["Use Guild Repair First"] = "Usar primero reparación de hermandad"
L["Will try to use guild funds to pay for repairs before your own"] = "Intentará pagar las reparaciones con fondos de la hermandad antes que con los tuyos"

L["Verbose Selling"] = "Venta detallada"
L["When enabled shows what items got sold instead of just the grand total earned."] = "Cuando está activado, muestra qué objetos se vendieron en lugar de solo el total ganado."
L["Test Selling"] = "Venta de prueba"
L["Enabling this allows you to see what would get sold, without actually selling."] = "Al activarlo puedes ver qué se vendería, sin vender nada realmente."
L["Warehouse"] = "Almacén"
L["Auto Sell"] = "Venta automática"
L["Items"] = "Objetos"
L["Grey"] = "Gris"
L["White"] = "Blanco"
L["Green"] = "Verde"
L["Blue"] = "Azul"
L["Purple"] = "Morado"
L["Selling"] = "Venta"
L["When you open a merchant, will auto sell your grey items"] = "Al abrir un mercader, venderá automáticamente tus objetos grises"
L["When you open a merchant, will auto sell your white items."] = "Al abrir un mercader, venderá automáticamente tus objetos blancos."
L["When you open a merchant, will auto sell your green items."] = "Al abrir un mercader, venderá automáticamente tus objetos verdes."
L["When you open a merchant, will auto sell your blue items."] = "Al abrir un mercader, venderá automáticamente tus objetos azules."
L["When you open a merchant, will auto sell your purple items."] = "Al abrir un mercader, venderá automáticamente tus objetos morados."
L["iLevel"] = "Nivel de objeto"
L["Enable iLevel Limit"] = "Activar límite de nivel de objeto"
L["Only sells items that are under the ilvl specified"] = "Solo vende objetos por debajo del nivel de objeto indicado"
L["Sets the maximum item level which will be auto sold"] = "Establece el nivel de objeto máximo que se venderá automáticamente"
L["Sell BOP Items"] = "Vender objetos ligados al recogerlos"
L["When enabled will sell items that are BOP"] = "Cuando está activado, venderá objetos que se ligan al recogerlos"
L["Sell BOE Items"] = "Vender objetos ligados al equiparlos"
L["When enabled will sell items that are BOE"] = "Cuando está activado, venderá objetos que se ligan al equiparlos"
L["Sell items based on a list"] = "Vender objetos según una lista"
L["If item name matches one on the list, auto-sell it"] = "Si el nombre del objeto coincide con uno de la lista, se vende automáticamente"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "Escribe el nombre del objeto que quieres vender automáticamente. También puedes arrastrar y soltar un objeto desde tu inventario."
L["New Item To Sell (Case Insensative)"] = "Nuevo objeto a vender (sin distinguir mayúsculas)"
L["AUTO-SELL: You Earned"] = "VENTA AUTOMÁTICA: Has ganado"
L["Delete Item"] = "Borrar elemento"
L["Delete"] = "Borrar"
L["Yes"] = "Sí"
L["No"] = "No"

L["Show coin count in warehouse list"] = "Mostrar monedas en la lista del almacén"
L["Restores the coin totals after character names in warehouse listing"] = "Vuelve a mostrar el total de monedas tras los nombres de personaje en el listado del almacén"

L["Use don't display list"] = "Usar lista de no mostrar"
L["If enabled, don't show listed items in tooltips"] = "Si está activado, no muestra los objetos de la lista en las descripciones emergentes"
L["New Item To Ignore (Case Insensative)"] = "Nuevo objeto a ignorar (sin distinguir mayúsculas)"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "Escribe el nombre del objeto que no quieres seguir en las descripciones emergentes. También puedes arrastrar y soltar un objeto desde tu inventario."
L["Ignore"] = "Ignorar"

-- Font outline/shadow options
L["Font Outline"] = "Contorno de la fuente"
L["Font Shadow"] = "Sombra de la fuente"
L["Sets the outline style of this font"] = "Establece el estilo de contorno de esta fuente"
L["Adds a drop shadow to this font"] = "Añade una sombra a esta fuente"
L["None"] = "Ninguno"
L["Outline"] = "Contorno"
L["Thick Outline"] = "Contorno grueso"
