if ( GetLocale() ~= "ptBR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "ptBR")
if not L then return end

L["Info Options"] = "Opções de info"
L["Lock Info Windows"] = "Travar janelas de info"
L["Locks the location of your info windows"] = "Trava a posição das suas janelas de info"
L["Info Window Background Color"] = "Cor de fundo da janela de info"
L["Info Font"] = "Fonte de info"
L["Sets the font to be used for info windows"] = "Define a fonte usada nas janelas de info"
L["Info Font Size"] = "Tamanho da fonte de info"
L["Sets the size of the info font"] = "Define o tamanho da fonte de info"
L["Info Font Spacing"] = "Espaçamento da fonte de info"
L["Sets the spacing of the info font"] = "Define o espaçamento da fonte de info"
L["Show Info Windows"] = "Mostrar janelas de info"
L["Toggle Info Windows"] = "Alternar janelas de info"
L["Info Module"] = "Módulo de info"
L["Close"] = "Fechar"
L["Edit Item"] = "Editar item"
L["Show"] = "Mostrar"
L["New Info Window"] = "Nova janela de info"
L["Delete This Window"] = "Excluir esta janela"
L["Options"] = "Opções"
L["Info"] = true
L["Edit View"] = "Editar visualização"
L["Stop Edit"] = "Parar edição"
L["Change Text"] = "Alterar texto"
L["Delete Info Window"] = "Excluir janela de info"
L["Delete"] = "Excluir"
L["Cancel"] = "Cancelar"

L["One minute until the Arena"] = "Um minuto até a Arena"
L["Thirty seconds until the Arena"] = "Trinta segundos até a Arena"
L["Fifteen seconds until the Arena"] = "Quinze segundos até a Arena"

L["Reset old info data %f"] = "Dados antigos de info redefinidos %f"
L[" begins? in (%d+) "] = " begins? in (%d+) "
L["(%d+) minutes? until the battle"] = "(%d+) minutes? until the battle"
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
L["Best"] = "Melhor"
L["Hit"] = "Acerto"
L["Killed"] = "Mortos"
L["Peak"] = "Pico"
L["Show Combat Graph"] = "Mostrar gráfico de combate"
L["Time"] = "Tempo"
L["Toggle Combat Graph"] = "Alternar gráfico de combate"
L["Total"] = "Total"
L["crit"] = "crítico"
L["hit"] = "acerto"
L["honor"] = "honra"
