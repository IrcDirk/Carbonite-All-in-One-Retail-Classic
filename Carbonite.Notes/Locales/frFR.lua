if ( GetLocale() ~= "frFR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Notes", "frFR")
if not L then return end

L["Note Options"] = "Options Note"
L["Show Notes On Map"] = "Afficher Notes sur la Map"
L["Shows your notes on the carbonite map"] = "Afficher vos Notes sur la Map Carbonite"
L["Show Notes"] = "Afficher Notes"
L["-Notes-"] = "-Notes-"
L["Add Note"] = "Ajouter Note"
L["Notes Module"] = "Module Notes"
L["Toggle Notes"] = "Basculer Notes"
L["Record"] = "Enregistrer"
L["Up"] = "Haut"
L["Down"] = "Bas"
L["Delete Item"] = "Effacer Objet"
L["Name"] = "Nom"
L["Type"] = "Type"
L["Value"] = "Valeur"
L["Location"] = "Emplacement"
L["Select a favorite before recording"] = "S\195\169lectionner un favori avant l'enregistrement"
L["Add Folder"] = "Ajouter Dossier"
L["Add Favorite"] = "Ajouter Favori"
L["Rename"] = "Renommer"
L["Cut"] = "Couper"
L["Copy"] = "Copier"
L["Paste"] = "Coller"
L["Options"] = "Options"
L["Add Comment"] = "Ajouter Commentaire"
L["Set Icon"] = "D\195\169finir l'ic\195\180ne"
L["Name"] = "Nom"
L["Nothing to paste"] = "Rien \195\160 Coller"
L["Can't paste that on the left side"] = "Impossible de coller ceci au c\195\160t\195\169 Gauche"
L["Can't paste that on the right side"] = "Impossible de coller ceci au c\195\160t\195\169 Droit"
L["Note"] = "Note"
L["Notes"] = "Notes"
L["Note Addons"] = "Notes add-on(s)"
L["My Notes"] = "Mes Notes"

L["Reset old notes data"] = "R\195\169initialiser anciennes donn\195\169s de vos Notes"
L["Display Handynotes On Map"] = "Afficher Handynotes sur la Map"
L["If you have HandyNotes installed, allows them on the Carbonite map"] = "Si vous avez Handynotes install\195\169, autorise celui-ci \195\160 afficher sur la map Carbonite"
L["Handnotes Icon Size"] = "Taille de l'ic\195\180ne Handynotes"

L["Display RareScanner icons On Map"] = true
L["If you have RareScanner installed, allows its icons on the Carbonite map"] = true
L["RareScanner Icon Size"] = true

L["Display RXPGuides waypoints On Map"] = "Afficher les points de cheminement RXPGuides sur la carte"
L["If you have RXPGuides installed, mirrors its active-step waypoint pins onto the Carbonite map"] = "Si RXPGuides est installé, reflète ses marqueurs d'étape active sur la carte Carbonite"
L["RXPGuides Icon Size"] = "Taille des icônes RXPGuides"
L["Route RXPGuides arrow through Carbonite"] = "Faire passer la flèche RXPGuides par Carbonite"
L["Step"] = "Étape"
L["Replaces the RXPGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"] = "Remplace la flèche de navigation de RXPGuides par la propre flèche de trajet (HUD) de Carbonite, pointant vers l'étape actuelle"
L["Route ZygorGuides arrow through Carbonite"] = "Faire passer la flèche ZygorGuides par Carbonite"
L["Replaces the ZygorGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"] = "Remplace la flèche de navigation de ZygorGuides par la propre flèche de trajet (HUD) de Carbonite, pointant vers l'étape actuelle"

-- Keybinds
L["Carbonite Notes"] = "Carbonite Notes"
L["NxTOGGLEFAV"] = "Afficher/Cacher Notes"
