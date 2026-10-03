if ( GetLocale() ~= "esMX" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "esMX")
if not L then return end

L["Carbonite"] = "Carbonite"
L["NxMAPTOGORIGINAL"] = "show/hide Blizzard's Map"
L["NxMAPTOGNORMMAX"] = "switch Mapsize"
L["NxMAPTOGNONEMAX"] = "show/hide Fullmap"
L["NxMAPTOGNONENORM"] = "show/hide Map"
L["NxMAPSCALERESTORE"] = "Restore Mapscale"
L["NxMAPTOGMINIFULL"] = "switch Minimap/Fullmap"
L["NxMAPTOGHERB"] = "show/hide Herbs"
L["NxMAPTOGMINE"] = "show/hide Mine"
L["NxTOGGLEGUIDE"] = "show/hide Guide"
L["NxMAPSKIPTARGET"] = "skip Map target"
L["NxMAPTOGTIMBER"] = "mostrar/ocultar Madera"
