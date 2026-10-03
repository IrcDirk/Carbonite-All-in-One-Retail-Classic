if ( GetLocale() ~= "ruRU" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "ruRU")
if not L then return end

L["Carbonite"] = "Carbonite"
L["NxMAPTOGORIGINAL"] = "показать/скрыть карту Blizzard"
L["NxMAPTOGNORMMAX"] = "сменить размер карты"
L["NxMAPTOGNONEMAX"] = "показать/скрыть полную карту"
L["NxMAPTOGNONENORM"] = "показать/скрыть карту"
L["NxMAPSCALERESTORE"] = "Востановить маштаб карты"
L["NxMAPTOGMINIFULL"] = "переключить миникарта/полная карта"
L["NxMAPTOGHERB"] = "показать/скрыть Травы"
L["NxMAPTOGMINE"] = "показать/скрыть Руду"
L["NxTOGGLEGUIDE"] = "показать/скрыть Проводник"
L["NxMAPSKIPTARGET"] = "пропустить цель на карте"
L["NxMAPTOGTIMBER"] = "показать/скрыть древесину"
