if ( GetLocale() ~= "ptBR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "ptBR")
if not L then return end

L["reached level"] = "Nivel alcancado"
L["Monitor Error: All 10 chat channels are in use"] = "Erro: Todos 10 canais estão em uso"
L["This will disable some communication features"] = "Isso irá desabilitar alguns recursos de comunicação"
L["You may free channels using the chat tab"] = "Você poderar liberar canais usando a aba de chat"
L["chat channel(s)!"] = "Canal (s) de chat!"
L["Need"] = "Necessidade"
L["Monitored:"] = "Monitorado:"
L["Druid"] = "Druida"
L["Hunter"] = "Caçador"
L["Mage"] = "Mago"
L["Paladin"] = "Paladino"
L["Priest"] = "Sacerdote"
L["Rogue"] = "Ladino"
L["Shaman"] = "Xamã"
L["Warlock"] = "Bruxo"
L["Warrior"] = "Guerreiro"
L["Deathknight"] = "Cavaleiro da Morte"
L["Monk"] = "Monje"

L["Com options reset (%f, %f)"] = "Opções de com redefinidas (%f, %f)"
L["ComTest"] = "ComTest"
L["Disabling com functions!"] = "Desativando funções de com!"
L["JoinChan Err %s"] = "Erro JoinChan %s"
L["SendSecG Error: %s"] = "Erro SendSecG: %s"
L[" %s (pending)"] = " %s (pendente)"
L["Com %d Bytes sec %d"] = "Com %d bytes seg %d"
