if ( GetLocale() ~= "koKR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "koKR")
if not L then return end

L["Info Options"] = true
L["Lock Info Windows"] = true
L["Locks the location of your info windows"] = true
L["Info Window Background Color"] = true
L["Info Font"] = true
L["Sets the font to be used for info windows"] = true
L["Info Font Size"] = true
L["Sets the size of the info font"] = true
L["Info Font Spacing"] = true
L["Sets the spacing of the info font"] = true
L["Show Info Windows"] = true
L["Toggle Info Windows"] = true
L["Info Module"] = true
L["Close"] = true
L["Edit Item"] = true
L["Show"] = true
L["New Info Window"] = true
L["Delete This Window"] = true
L["Options"] = true
L["Info"] = true
L["Edit View"] = true
L["Stop Edit"] = true
L["Change Text"] = true
L["Delete Info Window"] = true
L["Delete"] = true
L["Cancel"] = true

L["One minute until the Arena"] = true
L["Thirty seconds until the Arena"] = true
L["Fifteen seconds until the Arena"] = true

L["Reset old info data %f"] = true
L[" begins? in (%d+) "] = true
L["(%d+) minutes? until the battle"] = true
L["Info"] = true