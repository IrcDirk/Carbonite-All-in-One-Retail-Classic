if ( GetLocale() ~= "deDE" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "deDE")
if not L then return end

L["reached level"] = "Erreichtes Level"
L["Monitor Error: All 10 chat channels are in use"] = "\195\156berwachungsfehler: Alle 10 Chat-Kan\195\164le werden benutzt"
L["This will disable some communication features"] = "Das wird einige Kommunikationsfunktionen ausschalten"
L["You may free channels using the chat tab"] = "Kan\195\164le k\195\182nnen \195\188ber den Chat-Tab freigegeben werden"
L["chat channel(s)!"] = "Chat-Kan\195\164le!"
L["Need"] = "Ben\195\182tigt"
L["Monitored:"] = "\195\156berwacht:"
L["Druid"] = "Druide"
L["Hunter"] = "J\195\164ger"
L["Mage"] = "Magier"
L["Paladin"] = "Paladin"
L["Priest"] = "Priester"
L["Rogue"] = "Schurke"
L["Shaman"] = "Schamane"
L["Warlock"] = "Hexenmeister"
L["Warrior"] = "Krieger"
L["Deathknight"] = "Todesritter"
L["Monk"] = "M\195\182nch"

L["Com options reset (%f, %f)"] = "Com Einstellungen zur\195\188cksetzen (%f, %f)"
L["ComTest"] = "ComTest"
L["Disabling com functions!"] = "Com Funktionen ausgeschaltet!"
L["JoinChan Err %s"] = "JoinChan-Fehler %s"
L["SendSecG Error: %s"] = "SendeSekG Fehler: %s"
L[" %s (pending)"] = " %s (ausstehend)"
L["Com %d Bytes sec %d"] = "Com %d Bytes sek %d"
