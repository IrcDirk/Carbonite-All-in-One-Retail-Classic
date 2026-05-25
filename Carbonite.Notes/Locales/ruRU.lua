if ( GetLocale() ~= "ruRU" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Notes", "ruRU")
if not L then return end

L["Note Options"] = "Настройки заметок"
L["Show Notes On Map"] = "Показывать заметки на карте"
L["Shows your notes on the carbonite map"] = "Показывать ваши заметки на карте carbonite"
L["Show Notes"] = "Показывать заметки"
L["-Notes-"] = "-Заметки-"
L["Add Note"] = "Добавить Заметку"
L["Notes Module"] = "Модуль Заметок"
L["Toggle Notes"] = "Вкл./Выкл. Заметки"
L["Record"] = "Запись"
L["Up"] = "Вверх"
L["Down"] = "Вниз"
L["Delete Item"] = "Удалить"
L["Name"] = "Имя"
L["Type"] = "Тип"
L["Value"] = "Значение"
L["Location"] = "Местоположение"
L["Select a favorite before recording"] = "Выберите избранную перед записью"
L["Add Folder"] = "Добавить папку"
L["Add Favorite"] = "Добавить в избранное"
L["Rename"] = "Переименовать"
L["Cut"] = "Вырезать"
L["Copy"] = "Копировать"
L["Paste"] = "Вставить"
L["Options"] = "Настройки"
L["Add Comment"] = "Добавить комментарий"
L["Set Icon"] = "Задать иконку"
L["Name"] = "Имя"
L["Nothing to paste"] = "Нечего вставить"
L["Can't paste that on the left side"] = "Не могу это вставить в левую часть"
L["Can't paste that on the right side"] = "Не могу это вставить в правую часть"
L["Note"] = true
L["Notes"] = "Заметки"
L["Note Addons"] = "Дополнения заметок"
L["My Notes"] = "Мои заметки"

L["Reset old notes data"] = "Сбросить старые заметки"
L["Display Handynotes On Map"] = "Показывать на карте отметки плагина HandyNotes"
L["If you have HandyNotes installed, allows them on the Carbonite map"] = "Включить отображение иконок handyNotes на карте Carbonite (требуется плагин HandyNotes)"
L["Handnotes Icon Size"] = "Размер иконки HandyNotes"

L["Display RareScanner icons On Map"] = "Показывать на карте отметки плагина RareScanner"
L["If you have RareScanner installed, allows its icons on the Carbonite map"] = "Включить отображение иконок RareScanner на карте Carbonite (Требуется плагин RareScanner)"
L["RareScanner Icon Size"] = "Размер иконки RareScanner"

L["Display Questie quest objective icons On Map (Beware: might cause lags and fps loss)"] = "Показывать на карте отметки плагина Questie (Внимание: может вызвать лаги и потерю фпс)"
L["If you have Questie installed, allows its icons for quest objectives on the Carbonite map"] = "Включить отображение иконок Questie для текущих заданий на карте Carbonite (требуется плагин Questie)"
L["Display icons for Available quests from Questie on Carbonite Map"] = "Показывать на карте иконки Questie для доступных вам заданий"
L["If you have Questie installed, allows its icons for available quests on the Carbonite map"] =  "Включить отображение иконок Questie для доступных для вас, но не взятых заданий на карте Carbonite (требуется плагин Questie)"
L["Questie Icon Size"] = "Размер иконки Questie"

L["Display RXPGuides waypoints On Map"] = "Показывать на карте точки маршрута RXPGuides"
L["If you have RXPGuides installed, mirrors its active-step waypoint pins onto the Carbonite map"] = "Если установлен RXPGuides, дублирует его метки активных шагов на карте Carbonite"
L["RXPGuides Icon Size"] = "Размер иконки RXPGuides"

-- Keybinds
L["Carbonite Notes"] = "Заметки Carbonite"
L["NxTOGGLEFAV"] = "Показать/Скрыть Заметки"
