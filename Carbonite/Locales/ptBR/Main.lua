if ( GetLocale() ~= "ptBR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "ptBR")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["Cavaleiro da Morte"] = "DEATHKNIGHT",
	["Cavaleira da Morte"] = "DEATHKNIGHT",
	["Druída"] = "DRUID",
	["Caçador"] = "HUNTER",
	["Caçadora"] = "HUNTER",
	["Mago"] = "MAGE",
	["Maga"] = "MAGE",
	["Monje"] = "MONK",
	["Paladino"] = "PALADIN",
	["Paladina"] = "PALADIN",
	["Sacerdote"] = "PRIEST",
	["Sacerdotiza"] = "PRIEST",
	["Ladino"] = "ROGUE",
	["Ladina"] = "ROGUE",
	["Xamã"] = "SHAMAN",
	["Bruxo"] = "WARLOCK",
	["Bruxa"] = "WARLOCK",
	["Guerreiro"] = "WARRIOR",
	["Guerreira"] = "WARRIOR",
	["Troll"] = "TROLL",
	["Trolleza"] = "TROLL",
}

-- Main Carbonite
L["Carbonite"] = "Carbonite"
L["CARBONITE"] = "CARBONITE"
L["Loading"] = "Carregando"
L["Loading Done"] = "Carregado"
L["None"] = "Nemum"
L["Goto"] = "Vá"
L["Show Player Zone"] = "Mostre possição de jogador"
L["Menu"] = true
L["Show Selected Zone"] = "Mostre possição selecionada"
L["Add Note"] = "Adicionar Nota"
L["TopRight"] = "Canto superior direito"
L["Help"] = "Ajuda"
L["Options"] = "Opções"
L["Toggle Map"] = "Alternar Mapa"
L["Toggle Combat Graph"] = "Alternar combate"
L["Toggle Events"] = "Alternar Eventos"
L["Left-Click to Toggle Map"] = "Botão Esquerdo para abrir mapa"
L["Shift Left-Click to Toggle Minimize"] = "Shift Botão esquerdo para minimizar o mapa"
L["Middle-Click to Toggle Guide"] = "Botão do Meio para o Guia"
L["Right-Click for Menu"] = "Botão Direito para o Menu"
L["Carbonite requires v5.0 or higher"] = "Carbonite requer v5.0 ou maior"
L["GUID player"] = "GUID jogador"
L["GUID NPC"] = true
L["GUID pet"] = "GUID Companheiro"
L["Unit map error"] = "Erro na unidade do mapa"
L["Gather"] = "Colheita"
L["Entered"] = "Entrado"
L["Level"] = "Nível"
L["Deaths"] = "Mortes"
L["Bonus"] = true
L["Reset old data"] = "Reseta data velha"
L["Reset old global options"] = "Reseta opções globais velhas"
L["Options have been reset for the new version."] = "Opções foram resetadas para nova versão."
L["Privacy or other settings may have changed."] = "Privacidade ou outras configurações devem ter mudado."
L["Cleaned"] = "Limpado"
L["items"] = "itens"
L["Reset old HUD options"] = "Reseta opções de HUD velha"
L["Reset old travel data"] = "Reseta data de transporte velha"
L["Reset old gather data"] = "Reseta data de colheita velha"
L["Missing character data!"] = "data de personagem perdida!"
L["Deathknight"] = "CavaleirodaMorte"
L["Death Knight"] = "Cavaleiro da Morte"
L["Version"] = "Versão"
L["Maintained by"] = "Mantido por"
L["crit"] = true
L["hit"] = "acerto"
L["Killed"] = "Morto"
L["honor"] = "honra"
L["Hit"] = "Acerto"
L["Peak"] = "Pico"
L["Best"] = "Melhor"
L["Total"] = true
L["Time"] = "Tempo"
L["Event"] = "Evento"
L["Events"] = "Eventos"
L["Position"] = "Possição"
L["Died"] = "Morreu"
L["Picked"] = "Escolheu"
L["Mined"] = "Minerado"
L["Fished"] = "Pescado"
L["Unknown herb"] = "Erva desconhecida"
L["Unknown ore"] = "Minerio desconhecido"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Addon Gathermate2_Data_Carbonite não carregado!"
L["Imported"] = "Importado"
L["nodes from GatherMate2_Data"] = "Pontos do GatherMate2_Data"
L["Delete visited vendor data?"] = "Apagar data de vendendores visitados?"
L["This will stop the attempted retrieval of items on login."] = "Isso ira parar com a recuperação de itens no login."
L["Delete"] = "Apagar"
L["Cancel"] = "Cancelar"
L["items retrieved"] = "itens recuperados"
L["Item retrieval from server complete"] = "itens recuperados do servidor completo"
L["Show Map"] = "Mostrar Mapa"
L["Show Combat Graph"] = "Mostrar Combate"
L["Show Events"] = "Mostrar Eventos"
L["Show Auction Buyout Per Item"] = "Mostrar Arremate por iten no Leilão"
L["Show Com Window"] = "Mostrar Janela"
L["Toggle Profiling"] = "Abrir Perfil"
L["Left click toggle Map"] = "Botão esquerdo abri o Mapa"
L["Shift left click toggle minimize"] = "Shift botão esquerdo minimiza o mapa"
L["Alt left click toggle Watch List"] = "Alt botão esquerdo abri Lista de Observação"
L["Middle click toggle Guide"] = "Botão do meio abri o Guia"
L["Right click for Menu"] = "Botão direito para o menu"
L["Shift drag to move"] = "Shift e puxa para mover"
L["Hide In Combat"] = "Esconder em combate"
L["Lock"] = "Trava"
L["Fade In"] = "Aparecer"
L["Fade Out"] = "Desaparecer"
L["Layer"] = "Camada"
L["Scale"] = "Escala"
L["Transparency"] = "Transparencia"
L["Reset Layout"] = "Reseta Possição"

-- UI Tooltips
L["Close/Menu"] = true
L["Close/Unlock"] = true
L["Pick Color"] = true
L["Unlock"] = true
L["Maximize"] = true
L["Restore"] = true
L["Minimize"] = true
L["Auto Scale"] = true

-- Stuff from old localization
L["Searching for Artifacts"] = "Artefatos"		-- NXlARTIFACTS
L["Extract Gas"] = "Extrair Gás"			-- NXlEXTRACTGAS
L["Herb Gathering"] = "Colheita de ervas"		-- NXlHERBGATHERING
L["In Conflict"] = "Em Conflito"			-- NXlINCONFLICT
L["Opening"] = "Abrindo"				-- NXlOpening
L["Opening - No Text"] = "Abrindo - Sem texto"		-- NXlOpeningNoText
L["Everfrost Chip"] = "Chip de Everfrost"		-- NXlEverfrost

L["yds"] = true
L["secs"] = true
L["mins"] = true

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = true
L[" EScale %f, Lvl %f"] = true
L[" LR %f, %f"] = true
L[" BT %f, %f"] = true
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = true
L["%.1f days"] = true
L["%.1f hours"] = true
L["%d mins"] = true
L["Reset old layout data"] = true
L["Window version mismatch!"] = true
L["XY missing (%s)"] = true
L["Window not found (%s)"] = true
L["Detach %s"] = true
L["Detach found %s"] = true
L["Search: [click]"] = true
L["Search: %[click%]"] = true
L["Reset old list data"] = true
L["!BUT %s"] = true
L["Key %s transfered to Watch List Item"] = true
L["CLICK (.+):"] = true
L["Key %s %s #%s %s"] = true
L["shift left/right click to change size"] = true
L["Reset old tool bar data"] = true
L["|cffffff00%dg"] = true
L["%s |cffbfbfbf%ds"] = true
L["%s |cff7f7f00%dc"] = true

-- NxTravel.lua
L["Connection: %s to %s"] = true
L["Fly: %s to %s"] = true

-- NxHud.lua
L[" %.1f deg"] = true
L[" %d deg"] = true
L["Remove Current Point"] = true
L["Remove All Points"] = true

-- Carbonite.Info kill-marker tooltip
L["kill"] = "morte"
L["death"] = "óbito"
L["kills: %s"] = "mortes: %s"
L["NPC ID: %s"] = "ID NPC: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "Clique esquerdo"
L["Right click"] = "Clique direito"
L["Toggle icons"] = "Alternar ícones"
L["Context menu"] = "Menu de contexto"
L["Open settings"] = "Abrir configurações"
