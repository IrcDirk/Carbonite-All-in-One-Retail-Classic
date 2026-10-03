if ( GetLocale() ~= "esES" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "esES")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["Caballero de la muerte"] = "DEATHKNIGHT",
	["Druida"] = "DRUID",
	["Cazador"] = "HUNTER",
	["Cazadora"] = "HUNTER",
	["Mago"] = "MAGE",
	["Maga"] = "MAGE",
	["Monje"] = "MONK",
	["Palad\195\173n"] = "PALADIN",
	["Sacerdote"] = "PRIEST",
	["Sacerdotisa"] = "PRIEST",
	["P\195\173caro"] = "ROGUE",
	["P\195\173cara"] = "ROGUE",
	["Cham\195\161n"] = "SHAMAN",
	["Brujo"] = "WARLOCK",
	["Bruja"] = "WARLOCK",
	["Guerrero"] = "WARRIOR",
	["Guerrera"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = "Carbonite"
L["CARBONITE"] = "CARBONITE"
L["Loading"] = "Cargando"
L["Loading Done"] = "Carga completada"
L["None"] = true
L["Goto"] = true
L["Show Player Zone"] = true
L["Menu"] = true
L["Show Selected Zone"] = true
L["Add Note"] = "Añadir nota"
L["TopRight"] = "Arriba derecha"
L["Help"] = true
L["Options"] = "Opciones"
L["Toggle Map"] = "Alternar mapa"
L["Toggle Combat Graph"] = "Alternar gráfico de combate"
L["Toggle Events"] = "Alternar eventos"
L["Left-Click to Toggle Map"] = "Clic izquierdo para alternar el mapa"
L["Shift Left-Click to Toggle Minimize"] = "Mayús + clic izquierdo para alternar minimizar"
L["Middle-Click to Toggle Guide"] = "Clic central para alternar la guía"
L["Right-Click for Menu"] = "Clic derecho para el menú"
L["Carbonite requires v5.0 or higher"] = "Carbonite requiere v5.0 o superior"
L["GUID player"] = "GUID jugador"
L["GUID NPC"] = "GUID PNJ"
L["GUID pet"] = "GUID mascota"
L["Unit map error"] = "Error de mapa de unidad"
L["Gather"] = "Recolección"
L["Entered"] = "Entrado"
L["Level"] = "Nivel"
L["Deaths"] = "Muertes"
L["Bonus"] = "Bonificación"
L["Reset old data"] = "Datos antiguos restablecidos"
L["Reset old global options"] = "Opciones globales antiguas restablecidas"
L["Options have been reset for the new version."] = "Las opciones se han restablecido para la nueva versión."
L["Privacy or other settings may have changed."] = "La privacidad u otros ajustes pueden haber cambiado."
L["Cleaned"] = "Limpiados"
L["items"] = "objetos"
L["Reset old HUD options"] = "Opciones de HUD antiguas restablecidas"
L["Reset old travel data"] = "Datos de viaje antiguos restablecidos"
L["Reset old gather data"] = "Datos de recolección antiguos restablecidos"
L["Missing character data!"] = "¡Faltan datos del personaje!"
L["Deathknight"] = "Caballero de la Muerte"
L["Death Knight"] = "Caballero de la Muerte"
L["Version"] = "Versión"
L["Maintained by"] = true
L["crit"] = "crítico"
L["hit"] = "golpe"
L["Killed"] = "Muerto"
L["honor"] = "honor"
L["Hit"] = "Golpe"
L["Peak"] = "Pico"
L["Best"] = "Mejor"
L["Total"] = "Total"
L["Time"] = "Tiempo"
L["Event"] = "Evento"
L["Events"] = true
L["Position"] = "Posición"
L["Died"] = "Murió"
L["Picked"] = "Recogido"
L["Mined"] = "Minado"
L["Fished"] = "Pescado"
L["Unknown herb"] = "Hierba desconocida"
L["Unknown ore"] = "Mineral desconocido"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "¡El addon Gathermate2_Data_Carbonite no está cargado!"
L["Imported"] = "Importados"
L["nodes from GatherMate2_Data"] = "nodos de GatherMate2_Data"
L["Delete visited vendor data?"] = "¿Borrar los datos de vendedores visitados?"
L["This will stop the attempted retrieval of items on login."] = "Esto detendrá el intento de obtener objetos al iniciar sesión."
L["Delete"] = true
L["Cancel"] = true
L["items retrieved"] = "objetos obtenidos"
L["Item retrieval from server complete"] = "Obtención de objetos del servidor completada"
L["Show Map"] = "Mostrar mapa"
L["Show Combat Graph"] = "Mostrar gráfico de combate"
L["Show Events"] = "Mostrar eventos"
L["Show Auction Buyout Per Item"] = "Mostrar precio de compra por objeto en subasta"
L["Show Com Window"] = "Mostrar ventana de comunicación"
L["Toggle Profiling"] = "Alternar perfilado"
L["Left click toggle Map"] = "Clic izquierdo: alternar mapa"
L["Shift left click toggle minimize"] = "Mayús + clic izquierdo: alternar minimizar"
L["Alt left click toggle Watch List"] = "Alt + clic izquierdo: alternar lista de seguimiento"
L["Middle click toggle Guide"] = "Clic central: alternar guía"
L["Right click for Menu"] = "Clic derecho: menú"
L["Shift drag to move"] = "Mayús + arrastrar para mover"
L["Hide In Combat"] = "Ocultar en combate"
L["Lock"] = "Bloquear"
L["Layer"] = "Capa"
L["Scale"] = true
L["Transparency"] = true
L["Reset Layout"] = "Restablecer disposición"

-- UI Tooltips
L["Close/Menu"] = "Cerrar/Menú"
L["Close/Unlock"] = "Cerrar/Desbloquear"
L["Pick Color"] = "Elegir color"
L["Unlock"] = "Desbloquear"
L["Maximize"] = "Maximizar"
L["Restore"] = "Restaurar"
L["Minimize"] = "Minimizar"
L["Auto Scale"] = "Escala automática"

-- Stuff from old localization
L["Searching for Artifacts"] = "B\195\186squeda de artefactos"		-- NXlARTIFACTS
L["Extract Gas"] = "Extraer gas"					-- NXlEXTRACTGAS
L["Herb Gathering"] = "Recolectar hierbas"				-- NXlHERBGATHERING
L["In Conflict"] = "En conflicto"					-- NXlINCONFLICT
L["Opening"] = "Apertura"						-- NXlOpening
L["Opening - No Text"] = "Apertura - Sin texto"				-- NXlOpeningNoText
L["Everfrost Chip"] = "Esquirla de siemprescarcha"			-- NXlEverfrost

L["yds"] = "m"
L["secs"] = "s"
L["mins"] = "min"

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = " Marco: %s Mostrado%d Vis%d P>%s"
L[" EScale %f, Lvl %f"] = " EScale %f, Nvl %f"
L[" LR %f, %f"] = " LR %f, %f"
L[" BT %f, %f"] = " BT %f, %f"
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = "%s#%d %s ID%s (%s) mostrar%d l%d x%d y%d"
L["%.1f days"] = "%.1f días"
L["%.1f hours"] = "%.1f horas"
L["%d mins"] = "%d min"
L["Reset old layout data"] = "Datos de disposición antiguos restablecidos"
L["Window version mismatch!"] = "¡Versión de ventana no coincide!"
L["XY missing (%s)"] = "Falta XY (%s)"
L["Window not found (%s)"] = "Ventana no encontrada (%s)"
L["Detach %s"] = "Separar %s"
L["Detach found %s"] = "Separación encontrada %s"
L["Search: [click]"] = "Buscar: [clic]"
L["Search: %[click%]"] = "Buscar: %[clic%]"
L["Reset old list data"] = "Datos de lista antiguos restablecidos"
L["!BUT %s"] = "!BUT %s"
L["Key %s transfered to Watch List Item"] = "Tecla %s transferida al objeto de la lista de seguimiento"
L["CLICK (.+):"] = true
L["Key %s %s #%s %s"] = "Tecla %s %s #%s %s"
L["shift left/right click to change size"] = "Mayús + clic izquierdo/derecho para cambiar el tamaño"
L["Reset old tool bar data"] = "Datos de barra de herramientas antiguos restablecidos"
L["|cffffff00%dg"] = "|cffffff00%do"
L["%s |cffbfbfbf%ds"] = "%s |cffbfbfbf%dp"
L["%s |cff7f7f00%dc"] = "%s |cff7f7f00%dc"

-- NxTravel.lua
L["Connection: %s to %s"] = "Conexión: %s a %s"
L["Fly: %s to %s"] = "Vuelo: %s a %s"

-- NxHud.lua
L[" %.1f deg"] = " %.1f grados"
L[" %d deg"] = " %d grados"
L["Remove Current Point"] = "Eliminar punto actual"
L["Remove All Points"] = "Eliminar todos los puntos"

-- Carbonite.Info kill-marker tooltip
L["kill"] = "muerte"
L["death"] = "fallecimiento"
L["kills: %s"] = "muertes: %s"
L["NPC ID: %s"] = "ID PNJ: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "Clic izquierdo"
L["Right click"] = "Clic derecho"
L["Toggle icons"] = "Alternar iconos"
L["Context menu"] = "Menú contextual"
L["Open settings"] = "Abrir ajustes"
L["Whats New!"] = "¡Novedades!"
L["Don't show for this update again"] = "No volver a mostrar en esta actualización"
L["Carbonite What's New"] = "Novedades de Carbonite"
L["Carbonite.Gathermate2_Data addon is not loaded!"] = "¡El addon Carbonite.Gathermate2_Data no está cargado!"
L["nodes from Carbonite.Gathermate2_Data"] = "nodos de Carbonite.Gathermate2_Data"
L["Health"] = "Salud"
