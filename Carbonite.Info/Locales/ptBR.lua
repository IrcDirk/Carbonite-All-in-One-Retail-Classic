if ( GetLocale() ~= "ptBR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "ptBR")
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
L["Info"] = "Info"
-- Kill marker icons (Carbonite map skull/seal markers)
L["Kill Icons"] = "Ícones de Morte"
L["Show kill markers on map"] = "Mostrar marcadores de morte no mapa"
L["When enabled, killed mobs leave a skull icon on your map at the kill location"] = "Quando ativado, mobs mortos deixam um ícone de caveira no mapa no local da morte"
L["Auto-clear kill markers after"] = "Limpar marcadores de morte após"
L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"] = "Segundos antes de um marcador desaparecer. 0 = nunca (apenas limpeza manual)"

L["Keep kill history"] = "Manter histórico de mortes para sempre"
L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."] = "Quando ativado, o temporizador apenas oculta os marcadores expirados mas mantém os registros. Útil como log permanente de mortes."

-- Font outline/shadow options
L["Font Outline"] = "Contorno da fonte"
L["Font Shadow"] = "Sombra da fonte"
L["Sets the outline style of this font"] = "Define o estilo de contorno desta fonte"
L["Adds a drop shadow to this font"] = "Adiciona uma sombra a esta fonte"
L["None"] = "Nenhum"
L["Outline"] = "Contorno"
L["Thick Outline"] = "Contorno grosso"
