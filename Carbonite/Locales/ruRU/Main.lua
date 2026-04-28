if ( GetLocale() ~= "ruRU" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "ruRU")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["Рыцарь смерти"] = "DEATHKNIGHT",
	["Друид"] = "DRUID",
	["Охотник"] = "HUNTER",
	["Охотница"] = "HUNTER",
	["Маг"] = "MAGE",
	["Монах"] = "MONK",
	["Паладин"] = "PALADIN",
	["Паладинша"] = "PALADIN",
	["Жрец"] = "PRIEST",
	["Жрица"] = "PRIEST",
	["Разбойник"] = "ROGUE",
	["Разбойница"] = "ROGUE",
	["Шаман"] = "SHAMAN",
	["Шаманка"] = "SHAMAN",
	["Чернокнижник"] = "WARLOCK",
	["Чернокнижница"] = "WARLOCK",
	["Воин"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = true
L["CARBONITE"] = true
L["Whats New!"] = "Новости аддона"
L["Loading"] = "Загрузка"
L["Loading Done"] = "Загрузка Завершена"
L["None"] = "Нет"
L["Goto"] = "Идти к"
L["Show Player Zone"] = "Показать местонахождение игрока"
L["Menu"] = "Меню"
L["Show Selected Zone"] = "Показать выбранную локацию"
L["Add Note"] = "Добавить Заметку"
L["TopRight"] = "Верхний Правый"
L["Help"] = "Помощь"
L["Options"] = "Настройки"
L["Toggle Map"] = "Вкл/Выкл Карту"
L["Toggle Combat Graph"] = "Вкл/Выкл График боя"
L["Toggle Events"] = "Вкл/Выкл События"
L["Left-Click to Toggle Map"] = "Левый клик чтобы Вкл/Выкл Карту"
L["Shift Left-Click to Toggle Minimize"] = "Шифт Левый клик чтобы Вкл/Выкл Минимизацию"
L["Middle-Click to Toggle Guide"] = "Средний клик чтобы Вкл/Выкл Слежение"
L["Right-Click for Menu"] = "Правый клик для Меню"
L["Carbonite requires v5.0 or higher"] = "Carbonite нужна v5.0 или выше"
L["GUID player"] = "GUID игрока"
L["GUID NPC"] = true
L["GUID pet"] = "GUID питомца"
L["Unit map error"] = "Ошибка модуля карты"
L["Gather"] = "Добыча"
L["Entered"] = "Войти"
L["Level"] = "Уровень"
L["Deaths"] = "Смерти"
L["Bonus"] = "Бонус"
L["Reset old data"] = "Удалить старую информацию"
L["Reset old global options"] = "Удалить старые глобальные настройки"
L["Options have been reset for the new version."] = "Настройки будут сброшены для новой версии."
L["Privacy or other settings may have changed."] = "Личные или другие настройки могли изменится."
L["Cleaned"] = "Очищено"
L["items"] = "Вещи"
L["Reset old HUD options"] = "Удаление старых настроек HUD"
L["Reset old travel data"] = "Удаление старых данных о путешествии"
L["Reset old gather data"] = "Удаление старых данных о добыче"
L["Missing character data!"] = "Отсутствует информация о персонаже!"
L["Deathknight"] = "Рыцарь Смерти"
L["Death Knight"] = "Рыцарь Смерти"
L["Version"] = "Версия"
L["Maintained by"] = "Поддерживается"
L["crit"] = "Крит"
L["hit"] = "Меткость"
L["Killed"] = "Убито"
L["honor"] = "Чести"
L["Hit"] = "Попаданий"
L["Peak"] = "Максимальный"
L["Best"] = "Лучший"
L["Total"] = "Всего"
L["Time"] = "Время"
L["Event"] = "Событие"
L["Events"] = "События"
L["Position"] = "Место"
L["Died"] = "Умер"
L["Picked"] = "Собранно"
L["Mined"] = "Добыто"
L["Fished"] = "Выловлено"
L["Unknown herb"] = "Неизвестная трава"
L["Unknown ore"] = "Неизвестная руда"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Модификация Gathermate2_Data_Carbonite не загружена!"
L["Imported"] = "Импортированно"
L["nodes from GatherMate2_Data"] = "точки из GatherMate2_Data"
L["Delete visited vendor data?"] = "Удалить информацию о посещенных торговцах?"
L["This will stop the attempted retrieval of items on login."] = "Прекратит попытки получения предметов при входе."
L["Delete"] = "Удалить"
L["Cancel"] = "Отмена"
L["items retrieved"] = "Элементы извлекаются"
L["Item retrieval from server complete"] = "Извлечение элементов с сервера завершено"
L["Show Map"] = "Показать карту"
L["Show Combat Graph"] = "Показать график боя"
L["Show Events"] = "Показать События"
L["Show Auction Buyout Per Item"] = "Показать цену выкупа на аукционе для ед."
L["Show Com Window"] = "Delete"
L["Toggle Profiling"] = "Вкл/Выкл Профилирование"
L["Left click toggle Map"] = "Левый клик чтобы Вкл/Выкл Карту"
L["Shift left click toggle minimize"] = "Шифт Левый клик чтобы Вкл/Выкл Минимизацию"
L["Alt left click toggle Watch List"] = "Альт Левый клик чтобы Вкл/Выкл Журнал Отслеживания"
L["Middle click toggle Guide"] = "Шифт Левый клик чтобы Вкл/Выкл Слежение"
L["Right click for Menu"] = "Правый клик для Меню"
L["Shift drag to move"] = "Перемещение с зажатым шифтом"
L["Hide In Combat"] = "Скрыть в бою"
L["Lock"] = "Закрепить"
L["Fade In"] = "Приблизить"
L["Fade Out"] = "Отдалить"
L["Layer"] = "Слой"
L["Scale"] = "Маштаб"
L["Transparency"] = "Прозрачность"
L["Reset Layout"] = "Сбросить "

-- UI Tooltips
L["Close/Menu"] = "Закрыть/Меню"
L["Close/Unlock"] = "Закрыть/Разблокировать"
L["Pick Color"] = "Взять цвет"
L["Unlock"] = "Разблокировать"
L["Maximize"] = "Максимизировать"
L["Restore"] = "Развернуть"
L["Minimize"] = "Минимизировать"
L["Auto Scale"] = "Автоматический маштаб"

-- Stuff from old localization
L["Searching for Artifacts"] = "Поиск артефактов"		-- NXlARTIFACTS
L["Extract Gas"] = "Извлечение газа"				-- NXlEXTRACTGAS
L["Herb Gathering"] = "Сбор трав"				-- NXlHERBGATHERING
L["In Conflict"] = "В конфликте"				-- NXlINCONFLICT
L["Opening"] = "Открытие"					-- NXlOpening
L["Opening - No Text"] = "Открытие - нет текста"		-- NXlOpeningNoText
L["Everfrost Chip"] = "Осколок Вечного льда"			-- NXlEverfrost

L["yds"] = "м."
L["secs"] = "сек."
L["mins"] = "мин."

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = true
L[" EScale %f, Lvl %f"] = true
L[" LR %f, %f"] = true
L[" BT %f, %f"] = true
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = true
L["%.1f days"] = "%.1f дней"
L["%.1f hours"] = "%.1f часов"
L["%d mins"] = "%d минут"
L["Reset old layout data"] = "Сброить старые данные отображения"
L["Window version mismatch!"] = "Неверная версия окна!"
L["XY missing (%s)"] = "XY отсутсвуют (%s)"
L["Window not found (%s)"] = "Окно не найдено (%s)"
L["Detach %s"] = "открепить %s"
L["Detach found %s"] = "Обнаруженно открепление %s"
L["Search: [click]"] = "Искать: [click]"
L["Search: %[click%]"] = "Искать: %[click%]"
L["Reset old list data"] = "Сброить старые данные списка"
L["!BUT %s"] = true
L["Key %s transfered to Watch List Item"] = "Ключ %s перемещен в Журнал Отслеживания"
L["CLICK (.+):"] = "клик (.+):"
L["Key %s %s #%s %s"] = "Ключ %s %s #%s %s"
L["shift left/right click to change size"] = "shift левый/правый клик для изменения размера"
L["Reset old tool bar data"] = "Сбросить данные старой панели инструментов"
L["|cffffff00%dg"] = "|cffffff00%d зол."
L["%s |cffbfbfbf%ds"] = "%s |cffbfbfbf%d сер."
L["%s |cff7f7f00%dc"] = "%s |cff7f7f00%d мед."

-- NxTravel.lua
L["Connection: %s to %s"] = "Соединение: %s с %s"
L["Fly: %s to %s"] = "Лететь: %s до %s"

-- NxHud.lua
L[" %.1f deg"] = " %.1f град."
L[" %d deg"] = " %d град."
L["Remove Current Point"] = "Удалить текущую точку"
L["Remove All Points"] = "Удалить все точки"

-- Carbonite.Info kill-marker tooltip
L["kill"] = "убийство"
L["death"] = "смерть"
L["kills: %s"] = "убийств: %s"
L["NPC ID: %s"] = "ID моба: %s"
