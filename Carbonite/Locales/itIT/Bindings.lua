if ( GetLocale() ~= "itIT" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "itIT")
if not L then return end

L["Carbonite"] = "Carbonite"
L["NxMAPTOGORIGINAL"] = "mostra/nascondi Mappa Blizzard"
L["NxMAPTOGNORMMAX"] = "scambia dimensione mappa"
L["NxMAPTOGNONEMAX"] = "mostra/nascondi Mappa Full"
L["NxMAPTOGNONENORM"] = "mostra/nascondi Mappa"
L["NxMAPSCALERESTORE"] = "Ripristina Dimensione Mappa"
L["NxMAPTOGMINIFULL"] = "scambia Minimappa con Mappa Full"
L["NxMAPTOGHERB"] = "mostra/nascondi Nodi Erbe"
L["NxMAPTOGMINE"] = "mostra/nascondi Nodi Estrazione"
L["NxTOGGLEGUIDE"] = "mostra/nascondi Guida"
L["NxMAPSKIPTARGET"] = "salta bersaglio mappa"
L["NxMAPTOGTIMBER"] = "mostra/nascondi Legname"
