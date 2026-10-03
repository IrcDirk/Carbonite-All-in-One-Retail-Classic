if ( GetLocale() ~= "ptBR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "ptBR")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"Consumable",
	"Container",
	"Gem",
	"Glyph",
	"Key",
	"Miscellaneous",
	"Projectile",
	"Quest",
	"Quiver",
	"Reagent",
	"Recipe",
	AUCTION_CATEGORY_TRADE_GOODS,
	"Trade Goods",
	"Weapon",
}

L["-Warehouse-"] = "-Armazém-"
L["Warehouse Module"] = "Módulo de armazém"
L["Warehouse Options"] = "Opções do armazém"
L["Add Warehouse Tooltip"] = "Adicionar dica do armazém"
L["When enabled, will show warehouse information in hover tooltips of items"] = "Quando ativado, mostra informações do armazém nas dicas dos itens"
L["Warehouse Font"] = "Fonte do armazém"
L["Sets the font to be used for warehouse windows"] = "Define a fonte usada nas janelas do armazém"
L["Warehouse Font Size"] = "Tamanho da fonte do armazém"
L["Sets the size of the warehouse font"] = "Define o tamanho da fonte do armazém"
L["Warehouse Font Spacing"] = "Espaçamento da fonte do armazém"
L["Sets the spacing of the warehouse font"] = "Define o espaçamento da fonte do armazém"
L["Toggle Warehouse"] = "Alternar armazém"
L["Remove Character or Guild"] = "Remover personagem ou guilda"
L["Import settings from selected character"] = "Importar configurações do personagem selecionado"
L["Export current settings to all characters"] = "Exportar configurações atuais para todos os personagens"
L["Sync account transfer file"] = "Sincronizar arquivo de transferência da conta"
L["Show Lowest Equipped Rarity"] = "Mostrar menor raridade equipada"
L["Show Item Headers"] = "Mostrar cabeçalhos de itens"
L["Sort By Rarity"] = "Ordenar por raridade"
L["Show Lowest Rarity"] = "Mostrar menor raridade"
L["Sort By Slot"] = "Ordenar por espaço"
L["Import %s's character data and reload?"] = "Importar os dados do personagem %s e recarregar?"
L["Overwrite all character settings and reload?"] = "Sobrescrever todas as configurações de personagens e recarregar?"
L["Warehouse: %d characters"] = "Armazém: %d personagens"
L["DurPattern"] = "^Durabilidade (%d+) / (%d+)"
L["Show Warehouse"] = "Mostrar armazém"

L["Import"] = "Importar"
L["Cancel"] = "Cancelar"
L["Export"] = "Exportar"
L["Warehouse"] = true
L[" Realm:%s %s"] = " Reino:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " Tempo online: %s%2d:%02d:%02d|r, Jogado: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " Dinheiro da sessão:%s %s|r, Por hora:%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " Durabilidade: %s%d%%, menor %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " XP da sessão:%s %s|r, Por hora:%s %.0f"
L[" Hours To Level: %s%.1f"] = " Horas até o nível: %s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = " Última vez: %s%s|r, Jogado: %s%s"
L[" Location: %s%s (%d, %d)"] = " Local: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " XP inicial: %s%s/%s (%.0f%%)|r Descanso: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " XP: %s%s/%s (%.0f%%)|r Descanso: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " Honra: %s%s|r  Conquista: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " Valor: %s%s|r  Justiça: %s%s"
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfafTotal: %s. |cffafdfafJogado: %s%s"
L["%s's Items"] = "Itens de %s"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010Sem dados do banco - visite seu banco"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010Sem dados do banco de reagentes - visite seu banco"
L["---- Equipped ----"] = "---- Equipado ----"
L["Slot"] = "Espaço"
L["---- %s Equipped ----"] = "---- %s Equipado ----"
L["All Items"] = "Todos os itens"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(%s Banco)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(%s Correio)"
L["%s %d (%d Worn)"] = "%s %d (%d Vestido)"
L["%s (%d Bank)"] = "%s (%d Banco)"
L["%s (%d RBank)"] = "%s (%d BReag)"
L["%s (%s Mail)"] = "%s (%s Correio)"
L["%s (%s Pets)"] = "%s (%s Mascotes)"
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Bolsas:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Vestido:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Correio:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Banco:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00BReag:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Mascotes:%d|cFFFF0000]"
L["%s's %s Skills"] = "Habilidades de %s (%s)"
L["|cffff1010No data - open %s window"] = "|cffff1010Sem dados - abra a janela de %s"
L["|cffffffffW%sarehouse:"] = "|cffffffffA%srmazém:"
L["LOOT_OPENED %s (%s %s)"] = "LOOT_OPENED %s (%s %s)"
L["no LootTarget"] = "sem LootTarget"
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = "LOOT_SLOT_CLEARED #%s %s (missão)"
L["%s deleted"] = "%s excluído"
L["enchant:(%d+)"] = true
L["item:(%d+)"] = true

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite Warehouse"
L["NxTOGGLEWAREHOUSE"] = "show/hide Warehouse"

L["Guilds"] = "Guildas"
L["Characters"] = "Personagens"
L["Guild Bank"] = "Banco da Guilda"
L["Current Funds"] = "Fundos atuais"
L["Last Updated"] = "Última atualização"
L["Tab is empty or no access"] = "Aba vazia ou sem acesso"
L["ago"] = "atrás"
L["not opened or scanned."] = "não aberto ou não verificado."
L["Tab"] = "Aba"
L["All Characters"] = "Todos os personagens"
L["AUTO-REPAIR"] = "REPARO AUTOMÁTICO"
L["Auto Repair"] = "Reparo automático"
L["GUILD WITHDRAW"] = "SAQUE DA GUILDA"
L["Not enough funds to repair."] = "Dinheiro insuficiente para reparar."
L["Auto Repair Gear"] = "Reparar equipamento automaticamente"
L["When you open a merchant, will attempt to auto repair your gear"] = "Ao abrir um mercador, tenta reparar seu equipamento automaticamente"
L["Use Guild Repair First"] = "Usar reparo da guilda primeiro"
L["Will try to use guild funds to pay for repairs before your own"] = "Tenta usar os fundos da guilda para pagar os reparos antes do seu dinheiro"

L["Verbose Selling"] = "Venda detalhada"
L["When enabled shows what items got sold instead of just the grand total earned."] = "Quando ativado, mostra quais itens foram vendidos em vez de só o total ganho."
L["Test Selling"] = "Venda de teste"
L["Enabling this allows you to see what would get sold, without actually selling."] = "Ativar isto permite ver o que seria vendido, sem vender de fato."
L["Warehouse"] = "Armazém"
L["Auto Sell"] = "Venda automática"
L["Items"] = "Itens"
L["Grey"] = "Cinza"
L["White"] = "Branco"
L["Green"] = "Verde"
L["Blue"] = "Azul"
L["Purple"] = "Roxo"
L["Selling"] = "Venda"
L["When you open a merchant, will auto sell your grey items"] = "Ao abrir um mercador, vende automaticamente seus itens cinza"
L["When you open a merchant, will auto sell your white items."] = "Ao abrir um mercador, vende automaticamente seus itens brancos."
L["When you open a merchant, will auto sell your green items."] = "Ao abrir um mercador, vende automaticamente seus itens verdes."
L["When you open a merchant, will auto sell your blue items."] = "Ao abrir um mercador, vende automaticamente seus itens azuis."
L["When you open a merchant, will auto sell your purple items."] = "Ao abrir um mercador, vende automaticamente seus itens roxos."
L["iLevel"] = "iLevel"
L["Enable iLevel Limit"] = "Ativar limite de iLevel"
L["Only sells items that are under the ilvl specified"] = "Vende apenas itens abaixo do iLevel especificado"
L["Sets the maximum item level which will be auto sold"] = "Define o nível de item máximo que será vendido automaticamente"
L["Sell BOP Items"] = "Vender itens VAO"
L["When enabled will sell items that are BOP"] = "Quando ativado, vende itens Vinculados ao Obter"
L["Sell BOE Items"] = "Vender itens VAE"
L["When enabled will sell items that are BOE"] = "Quando ativado, vende itens Vinculados ao Equipar"
L["Sell items based on a list"] = "Vender itens com base em uma lista"
L["If item name matches one on the list, auto-sell it"] = "Se o nome do item estiver na lista, vende automaticamente"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "Digite o nome do item que você quer vender automaticamente. Você também pode arrastar e soltar um item do seu inventário."
L["New Item To Sell (Case Insensative)"] = "Novo item para vender (sem diferenciar maiúsculas)"
L["AUTO-SELL: You Earned"] = "VENDA AUTOMÁTICA: Você ganhou"
L["Delete Item"] = "Excluir item"
L["Delete"] = "Excluir"
L["Yes"] = "Sim"
L["No"] = "Não"

L["Show coin count in warehouse list"] = "Mostrar total de moedas na lista do armazém"
L["Restores the coin totals after character names in warehouse listing"] = "Restaura os totais de moedas após os nomes dos personagens na lista do armazém"

L["Use don't display list"] = "Usar lista de não exibir"
L["If enabled, don't show listed items in tooltips"] = "Se ativado, não mostra os itens da lista nas dicas"
L["New Item To Ignore (Case Insensative)"] = "Novo item para ignorar (sem diferenciar maiúsculas)"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "Digite o nome do item que você não quer rastrear nas dicas. Você também pode arrastar e soltar um item do seu inventário."
L["Ignore"] = "Ignorar"

-- Font outline/shadow options
L["Font Outline"] = "Contorno da fonte"
L["Font Shadow"] = "Sombra da fonte"
L["Sets the outline style of this font"] = "Define o estilo de contorno desta fonte"
L["Adds a drop shadow to this font"] = "Adiciona uma sombra a esta fonte"
L["None"] = "Nenhum"
L["Outline"] = "Contorno"
L["Thick Outline"] = "Contorno grosso"
