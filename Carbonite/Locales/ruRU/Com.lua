if ( GetLocale() ~= "ruRU" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "ruRU")
if not L then return end

L["reached level"] = "Достигнутый уровень"
L["Monitor Error: All 10 chat channels are in use"] = "Ошибка слежения: все 10 чат каналов заняты"
L["This will disable some communication features"] = "Это действие отключит некоторые функции связи"
L["You may free channels using the chat tab"] = "Вы можете освободить каналы используя закладки чата"
L["chat channel(s)!"] = "Канал(ы) чата"
L["Need"] = "Нужно"
L["Monitored:"] = "Следим:"
L["Druid"] = "Друид"
L["Hunter"] = "Охотник"
L["Mage"] = "Маг"
L["Paladin"] = "Паладин"
L["Priest"] = "Жрец"
L["Rogue"] = "Разбойник"
L["Shaman"] = "Шаман"
L["Warlock"] = "Чернокнижник"
L["Warrior"] = "Воин"
L["Deathknight"] = "Рыдцарь Смерти"
L["Monk"] = "Монах"

L["Com options reset (%f, %f)"] = "Настройки связи сброшены (%f, %f)"
L["ComTest"] = "ComTest"
L["Disabling com functions!"] = "Отключение функций связи!"
L["JoinChan Err %s"] = "Ошибка JoinChan %s"
L["SendSecG Error: %s"] = "Ошибка SendSecG: %s"
L[" %s (pending)"] = " %s (ожидание)"
L["Com %d Bytes sec %d"] = "Связь %d байт, сек %d"
