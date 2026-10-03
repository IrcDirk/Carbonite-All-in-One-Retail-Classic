if ( GetLocale() ~= "frFR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "frFR")
if not L then return end

L["Carbonite"] = "Carbonite"
L["NxMAPTOGORIGINAL"] = "Afficher/Cacher la Map Blizzard"
L["NxMAPTOGNORMMAX"] = "Changer la taille de Map"
L["NxMAPTOGNONEMAX"] = "Afficher/Cacher la carte Enti\195\168re"
L["NxMAPTOGNONENORM"] = "Afficher/Cacher la Map"
L["NxMAPSCALERESTORE"] = "Restaurer l'\195\169chelle de Map"
L["NxMAPTOGMINIFULL"] = "Changer Minimap/Carte Enti\195\168re"
L["NxMAPTOGHERB"] = "Afficher/Cacher Plantes"
L["NxMAPTOGMINE"] = "Afficher/Cacher Gisements"
L["NxTOGGLEGUIDE"] = "Afficher/Cacher le Guide"
L["NxMAPSKIPTARGET"] = "Passer la cible sur Map"
L["NxMAPTOGTIMBER"] = "Afficher/Cacher Bois"
