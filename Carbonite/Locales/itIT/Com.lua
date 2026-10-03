if ( GetLocale() ~= "itIT" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "itIT")
if not L then return end

L["reached level"] = "raggiunto livello"
L["Monitor Error: All 10 chat channels are in use"] = "Errore Visualizzazione: tutti i 10 canali della chat erano in uso"
L["This will disable some communication features"] = "Questo disabiliter\195\160 alcune funzionalit\195\160 di comunicazione"
L["You may free channels using the chat tab"] = "Puoi liberare dei canali usando il menu di configurazione interno alla chat"
L["chat channel(s)!"] = "canale/i di chat!"
L["Need"] = "Necessari"
L["Monitored:"] = "Monitorati:"
L["Druid"] = "Druido"
L["Hunter"] = "Cacciatore"
L["Mage"] = "Mago"
L["Paladin"] = "Paladino"
L["Priest"] = "Prete"
L["Rogue"] = "Ladro"
L["Shaman"] = "Sciamano"
L["Warlock"] = "Stregone"
L["Warrior"] = "Guerriero"
L["Deathknight"] = "Cavalliere della Morte"
L["Monk"] = "Monaco"

L["Com options reset (%f, %f)"] = "Opzioni com reimpostate (%f, %f)"
L["ComTest"] = "ComTest"
L["Disabling com functions!"] = "Disattivazione funzioni com!"
L["JoinChan Err %s"] = "Errore JoinChan %s"
L["SendSecG Error: %s"] = "Errore SendSecG: %s"
L[" %s (pending)"] = " %s (in attesa)"
L["Com %d Bytes sec %d"] = "Com %d Byte sec %d"
