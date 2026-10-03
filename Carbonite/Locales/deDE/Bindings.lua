if ( GetLocale() ~= "deDE" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "deDE")
if not L then return end

L["Carbonite"] = "Carbonite"
L["NxMAPTOGORIGINAL"] = "Blizzards Weltkarte ein/ausblenden"
L["NxMAPTOGNORMMAX"] = "Gr\195\182\195\159e der Karte umschalten"
L["NxMAPTOGNONEMAX"] = "maximierte Karte ein/ausblenden"
L["NxMAPTOGNONENORM"] = "Karte ein/ausblenden"
L["NxMAPSCALERESTORE"] = "Kartenskalierung wiederherstellen"
L["NxMAPTOGMINIFULL"] = "zwischen Minikarte und Gro\195\159er Karte umschalten"
L["NxMAPTOGHERB"] = "Kr\195\164uter ein/ausblenden"
L["NxMAPTOGMINE"] = "Erze ein/ausblenden"
L["NxTOGGLEGUIDE"] = "Wegweiser Infos ein/ausblenden"
L["NxMAPSKIPTARGET"] = "Kartenziel \195\188berspringen"
L["NxMAPTOGTIMBER"] = "Bauholz anzeigen/verbergen"
