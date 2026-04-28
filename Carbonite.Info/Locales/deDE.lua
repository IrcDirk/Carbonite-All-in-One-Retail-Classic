if ( GetLocale() ~= "deDE" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "deDE")
if not L then return end

L["Info Options"] = "Info-Optionen"
L["Lock Info Windows"] = "Info-Fenster fixieren"
L["Locks the location of your info windows"] = "Fixiert das Info-Fenster an seiner aktuellen Position."
L["Info Window Background Color"] = "Info-Fenster Hintergrundfarbe"
L["Info Font"] = "Info-Schriftart"
L["Sets the font to be used for info windows"] = "Legt fest, welche Schriftart im Info-Fenster benutzt wird."
L["Info Font Size"] = "Info-Schriftgr\195\182\195\159e"
L["Sets the size of the info font"] = "Legt die im Info-Fenster verwendete Schriftgr\195\182\195\159e fest."
L["Info Font Spacing"] = "Info Zeilenabstand"
L["Sets the spacing of the info font"] = "Legt den im Info-Fenster verwendeten Zeilenabstand fest."
L["Show Info Windows"] = "Info-Fenster zeigen"
L["Toggle Info Windows"] = "Info-Fenster an-/ausschalten"
L["Info Module"] = "Info-Modul"
L["Close"] = "Schlie\195\159en"
L["Edit Item"] = "Punkt bearbeiten"
L["Show"] = "Zeige"
L["New Info Window"] = "Neues Info-Fenster"
L["Delete This Window"] = "Aktuelles Fenster entfernen"
L["Options"] = "Einstellungen"
L["Info"] = "Info"
L["Edit View"] = "Ansicht bearbeiten"
L["Stop Edit"] = "Bearbeitung stoppen"
L["Change Text"] = "Text \195\164ndern"
L["Delete Info Window"] = "L\195\182sche Info Fenster"
L["Delete"] = "L\195\182schen"
L["Cancel"] = "Abbrechen"

L["One minute until the Arena"] = "Eine Minute bis zum Arenastart"
L["Thirty seconds until the Arena"] = "Drei\195\159\ig Sekunden bis zum Arenastart"
L["Fifteen seconds until the Arena"] = "F\195\188nfzehn Sekunden bis zum Arenastart"

L["Reset old info data %f"] = "Alte Info-Daten zur\195\188cksetzen"
L[" begins? in (%d+) "] = " startet? in (%d+) "
L["(%d+) minutes? until the battle"] = "(%d+) Minuten? bis zur Schlacht"
L["Info"] = "Info"