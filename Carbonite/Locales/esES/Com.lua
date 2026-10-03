if ( GetLocale() ~= "esES" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "esES")
if not L then return end

L["reached level"] = "alcanzó el nivel"
L["Monitor Error: All 10 chat channels are in use"] = "Error de Monitor: los 10 canales de chat están en uso"
L["This will disable some communication features"] = "Esto desactivará algunas funciones de comunicación"
L["You may free channels using the chat tab"] = "Puedes liberar canales usando la pestaña de chat"
L["chat channel(s)!"] = "canal(es) de chat!"
L["Need"] = "Necesita"
L["Monitored:"] = "Monitorizados:"
L["Druid"] = "Druida"
L["Hunter"] = "Cazador"
L["Mage"] = "Mago"
L["Paladin"] = "Paladín"
L["Priest"] = "Sacerdote"
L["Rogue"] = "Pícaro"
L["Shaman"] = "Chamán"
L["Warlock"] = "Brujo"
L["Warrior"] = "Guerrero"
L["Deathknight"] = true
L["Monk"] = "Monje"

L["Com options reset (%f, %f)"] = "Opciones de comunicación restablecidas (%f, %f)"
L["ComTest"] = "ComTest"
L["Disabling com functions!"] = "¡Desactivando funciones de comunicación!"
L["JoinChan Err %s"] = "Error JoinChan %s"
L["SendSecG Error: %s"] = "Error SendSecG: %s"
L[" %s (pending)"] = " %s (pendiente)"
L["Com %d Bytes sec %d"] = "Com %d bytes seg %d"
