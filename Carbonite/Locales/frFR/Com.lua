if ( GetLocale() ~= "frFR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "frFR")
if not L then return end

L["reached level"] = "Niveau Atteint"
L["Monitor Error: All 10 chat channels are in use"] = "Erreur: les 10 canaux du chat sont utilis\195\169s"
L["This will disable some communication features"] = "Ceci d\195\169sactivera certaines fonctions de communication"
L["You may free channels using the chat tab"] = "Vous pouvez lib\195\169rer des canaux en utilisant l'onglet du chat"
L["chat channel(s)!"] = "Canaux de discussion (s)!"
L["Need"] = "Besoin"
L["Monitored:"] = "Surveill\195\169"
L["Druid"] = "Druide"
L["Hunter"] = "Chasseur"
L["Mage"] = "Mage"
L["Paladin"] = "Paladin"
L["Priest"] = "Pr\195\170tre"
L["Rogue"] = "Voleur"
L["Shaman"] = "Chaman"
L["Warlock"] = "D\195\169moniste"
L["Warrior"] = "Guerrier"
L["Deathknight"] = "Chevalier de la mort"
L["Monk"] = "Moine"

L["Com options reset (%f, %f)"] = "R\195\169initialisation Options de Com (%f, %f)"
L["ComTest"] = "Test de Com"
L["Disabling com functions!"] = "D\195\169sactiver fonctions de Com!"
L["JoinChan Err %s"] = "Erreur rejoindre canal %s"
L["SendSecG Error: %s"] = "SendSecG Erreur: %s"
L[" %s (pending)"] = " %s (en attente)"
L["Com %d Bytes sec %d"] = "Com %d octet sec %d"
