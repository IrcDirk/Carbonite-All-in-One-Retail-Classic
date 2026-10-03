if ( GetLocale() ~= "esMX" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "esMX")
if not L then return end

L["Info Options"] = "Opciones de información"
L["Lock Info Windows"] = "Bloquear ventanas de información"
L["Locks the location of your info windows"] = "Bloquea la posición de tus ventanas de información"
L["Info Window Background Color"] = "Color de fondo de las ventanas de información"
L["Info Font"] = "Fuente de información"
L["Sets the font to be used for info windows"] = "Establece la fuente usada en las ventanas de información"
L["Info Font Size"] = "Tamaño de fuente de información"
L["Sets the size of the info font"] = "Establece el tamaño de la fuente de información"
L["Info Font Spacing"] = "Espaciado de fuente de información"
L["Sets the spacing of the info font"] = "Establece el espaciado de la fuente de información"
L["Show Info Windows"] = "Mostrar ventanas de información"
L["Toggle Info Windows"] = "Alternar ventanas de información"
L["Info Module"] = "Módulo de información"
L["Close"] = "Cerrar"
L["Edit Item"] = "Editar elemento"
L["Show"] = "Mostrar"
L["New Info Window"] = "Nueva ventana de información"
L["Delete This Window"] = "Borrar esta ventana"
L["Options"] = "Opciones"
L["Info"] = true
L["Edit View"] = "Editar vista"
L["Stop Edit"] = "Dejar de editar"
L["Change Text"] = "Cambiar texto"
L["Delete Info Window"] = "Borrar ventana de información"
L["Delete"] = "Borrar"
L["Cancel"] = "Cancelar"

L["One minute until the Arena"] = "Un minuto para que comience la batalla en arena"
L["Thirty seconds until the Arena"] = "Treinta segundos para que comience la batalla en arena"
L["Fifteen seconds until the Arena"] = "Quince segundos para que comience la batalla en arena"

L["Reset old info data %f"] = "Restablecidos datos de información antiguos %f"
L[" begins? in (%d+) "] = " comenzará en (%d+) "
L["(%d+) minutes? until the battle"] = "(%d+) minutos? para"
L["Info"] = true
L["Info"] = "Info"
-- Kill marker icons (Carbonite map skull/seal markers)
L["Kill Icons"] = "Iconos de muerte"
L["Show kill markers on map"] = "Mostrar marcadores de muerte en el mapa"
L["When enabled, killed mobs leave a skull icon on your map at the kill location"] = "Cuando se activa, los enemigos muertos dejan un icono de calavera en el lugar de la muerte"
L["Auto-clear kill markers after"] = "Borrar marcadores de muerte tras"
L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"] = "Segundos antes de que un marcador desaparezca. 0 = nunca (solo borrado manual)"

L["Keep kill history"] = "Conservar historial de muertes para siempre"
L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."] = "Cuando se activa, el temporizador solo oculta los marcadores expirados pero conserva los registros. Útil como registro permanente de muertes."

-- Font outline/shadow options
L["Font Outline"] = "Contorno de la fuente"
L["Font Shadow"] = "Sombra de la fuente"
L["Sets the outline style of this font"] = "Establece el estilo de contorno de esta fuente"
L["Adds a drop shadow to this font"] = "Añade una sombra a esta fuente"
L["None"] = "Ninguno"
L["Outline"] = "Contorno"
L["Thick Outline"] = "Contorno grueso"
L["Best"] = "Mejor"
L["Hit"] = "Golpe"
L["Killed"] = "Muertos"
L["Peak"] = "Pico"
L["Show Combat Graph"] = "Mostrar gráfico de combate"
L["Time"] = "Tiempo"
L["Toggle Combat Graph"] = "Alternar gráfico de combate"
L["crit"] = "crítico"
L["hit"] = "golpe"
