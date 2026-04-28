if ( GetLocale() ~= "frFR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "frFR")
if not L then return end

L["Info Options"] = "Options fen\195\170tre Info"
L["Lock Info Windows"] = "Verrouiller Fen\195\170tre Info"
L["Locks the location of your info windows"] = "Verrouiller l'emplacement de la fen\195\170tre Info"
L["Info Window Background Color"] = "Couleur de fond de la fen\195\170tre Info"
L["Info Font"] = "Police de la fen\195\170tre Info"
L["Sets the font to be used for info windows"] = "D\195\169finir la police de la fen\195\170tre Info"
L["Info Font Size"] = "Taille de la police Info"
L["Sets the size of the info font"] = "D\195\169finir la taille de police de la fen\195\170tre Info"
L["Info Font Spacing"] = "Espacement de la police fen\195\170tre Info"
L["Sets the spacing of the info font"] = "D\195\169finir l'espacement de la police fen\195\170tre Info"
L["Show Info Windows"] = "Afficher fen\195\170tre Info"
L["Toggle Info Windows"] = "Basculer vers fen\195\170tre Info"
L["Info Module"] = "Module Info"
L["Close"] = "Fermer"
L["Edit Item"] = "Editer Objet"
L["Show"] = "Afficher"
L["New Info Window"] = "Nouvelle fen\195\170tre Info"
L["Delete This Window"] = "Effacer cette fen\195\170tre"
L["Options"] = "Options"
L["Info"] = "Info"
L["Edit View"] = "Editer la Vue"
L["Stop Edit"] = "Stopper l'\195\169dition"
L["Change Text"] = "Changer le Texte"
L["Delete Info Window"] = "Effacer fen\195\170tre Info"
L["Delete"] = "Effacer"
L["Cancel"] = "Annuler"

L["One minute until the Arena"] = "Une Minute avant l'ar\195\168ne"
L["Thirty seconds until the Arena"] = "Trente Secondes avant l'ar\195\168ne"
L["Fifteen seconds until the Arena"] = "Quinze Secondes avant l'ar\195\168ne"

L["Reset old info data %f"] = "R\195\169initialiser anciennes donn\195\169es Info %f"
L[" begins? in (%d+) "] = " Commence? dans (%d+) "
L["(%d+) minutes? until the battle"] = "(%d+) minutes? Avant la Bataille"
L["Info"] = true