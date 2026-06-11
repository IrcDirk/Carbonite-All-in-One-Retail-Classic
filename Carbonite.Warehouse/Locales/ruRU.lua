if ( GetLocale() ~= "ruRU" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "ruRU")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"Потребительское",
	"Контейнер",
	"Камень",
	"Глиф",
	"Ключ",
	"Другое",
	"Патроны",
	"Задание",
	"Колчан",
	"Реагент",
	"Рецепт",
	AUCTION_CATEGORY_TRADE_GOODS,
	"Материалы",
	"Оружие",
}

L["-Warehouse-"] = "-Склад-"
L["Warehouse Module"] = "Склад"
L["Warehouse Options"] = "Параметры склада"
L["Add Warehouse Tooltip"] = "Добавлять подсказку склада"
L["When enabled, will show warehouse information in hover tooltips of items"] = "При включении будет добавлять информацию со склада при наведении курсора мыши на предмет"
L["Warehouse Font"] = "Шрифт"
L["Sets the font to be used for warehouse windows"] = "Установить шрифт для текста в окне склада"
L["Warehouse Font Size"] = "Размер шрифта"
L["Sets the size of the warehouse font"] = "Установить размер шрифта для текста в окне склада"
L["Warehouse Font Spacing"] = "Отступы в тексте"
L["Sets the spacing of the warehouse font"] = "Установить отступы для текста в окне склада"
L["Toggle Warehouse"] = "Переключить Склад"
L["Remove Character or Guild"] = "Удалить персонажа или гильдию"
L["Import settings from selected character"] = "Импортировать настройки выбранного персонажа"
L["Export current settings to all characters"] = "Экспортировать текущие настройки всем персонажам"
L["Sync account transfer file"] = "Синхронизировать файл переноса аккаунта"
L["Show Lowest Equipped Rarity"] = "Показать наименее редкие надетые предметы"
L["Show Item Headers"] = "Показывать заголовки предметов"
L["Sort By Rarity"] = "Сортировать по редкости"
L["Show Lowest Rarity"] = "Показать наименее редкий"
L["Sort By Slot"] = "Сортировать по слотам"
L["Import %s's character data and reload?"] = "Импортировать данные персонажа %s и перезагрузить интерфейс?"
L["Overwrite all character settings and reload?"] = "Перезаписать настройки всех персонажей и перезагрузить интерфейс?"
L["Warehouse: %d characters"] = "Склад: %s персонажей"
L["DurPattern"] = "^Прочность: (%d+) / (%d+)"
L["Show Warehouse"] = "Показать склад"

L["Import"] = "Импорт"
L["Cancel"] = "Отмена"
L["Export"] = "Экспорт"
L["Warehouse"] = "Склад"
L[" Realm:%s %s"] = " Сервер:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " Время онлайн: %s%2d:%02d:%02d|r, В игре: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " Заработано в текущей сессии:%s %s|r, В час:%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " Прочность: %s%d%%, наименьшая %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " Опыта за сессию:%s %s|r, В час:%s %.0f"
L[" Hours To Level: %s%.1f"] = " Время до уровна: %s%.1f часов"
L[" Last On: %s%s|r, Played: %s%s"] = " Последний вход: %s%s|r, В игре: %s%s"
L[" Location: %s%s (%d, %d)"] = " Расположение: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " Начальный опыт: %s%s/%s (%.0f%%)|r Отдых: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " Опыта: %s%s/%s (%.0f%%)|r Отдых: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " Очки чести: %s%s|r  Очки завоевания: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " Очки доблести: %s%s|r  Очки справедливости: %s%s"
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfafВсего: %s. |cffafdfafВ игре: %s%s"
L["%s's Items"] = "Предметы %s"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010Отсутстуют сведения из банка, посетите банк"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010Отсутствуют сведения о реагентах, посетите банк"
L["---- Equipped ----"] = "---- На персонаже ----"
L["Slot"] = "Слот"
L["---- %s Equipped ----"] = "---- %s На персонаже ----"
L["All Items"] = "Все предметы"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(В банке %s)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(На почте %s)"
L["%s %d (%d Worn)"] = "%s %d (%d На персонаже)"
L["%s (%d Bank)"] = "%s (%d в банке)"
L["%s (%d RBank)"] = true
L["%s (%s Mail)"] = "%s (На почте %s)"
L["%s (%s Pets)"] = "%s (Питомцев %s)"
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00В сумках: %d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00На персонаже: %d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00На почте: %d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00В банке: %d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = true
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00Питомцев: %d|cFFFF0000]"
L["%s's %s Skills"] = "%s Умения %s"
L["|cffff1010No data - open %s window"] = "|cffff1010Нет данных, открытие окна %s"
L["|cffffffffW%sarehouse:"] = "|cffffffffС%sклад:"
L["LOOT_OPENED %s (%s %s)"] = "ДОБЫЧА %s (%s %s)"
L["no LootTarget"] = true
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = true
L["%s deleted"] = "%s удалено"
L["enchant:(%d+)"] = "наложение чар:(%d+)"
L["item:(%d+)"] = "предмет:(%d+)"
L["No Currency Data Saved"] = "Отсутствует информация о валюте у персонажа"

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite Warehouse"
L["NxTOGGLEWAREHOUSE"] = "show/hide Warehouse"

L["Guilds"] = "Гильдии"
L["Characters"] = "Персонажи"
L["Guild Bank"] = "Банк гильдии"
L["Current Funds"] = "Текущие средства"
L["Last Updated"] = "Последнее обновление"
L["Tab is empty or no access"] = "Вкладка пуста или недоступна для вашего персонажа"
L["ago"] = "назад"
L["not opened or scanned."] = "не открыто или отсканировано"
L["Tab"] = "Вкладка"
L["All Characters"] = " у всех персонажей"
L["AUTO-REPAIR"] = "Автоматический ремонт"
L["Auto Repair"] = "Автоматический ремонт"
L["GUILD WITHDRAW"] = "За счет банка гильдии"
L["Not enough funds to repair."] = "Недостаточно средств для ремонта"
L["Auto Repair Gear"] = "Автоматический ремонт предметов"
L["When you open a merchant, will attempt to auto repair your gear"] = "При обращению к торговцу с доступным ремонтом будет произведена попытка автоматически отремонтировать ваши надетые предметы"
L["Use Guild Repair First"] = "Сначала использовать ремонт за счет гильдии"
L["Will try to use guild funds to pay for repairs before your own"] = "Попытаться отремонтировать за счет гильдии прежде чем ремонтировать за свой счет"

L["Verbose Selling"] = "Сообщать подробности продажи"
L["When enabled shows what items got sold instead of just the grand total earned."] = "При включении будет показан список проданных предметов помимо количества заработанного"
L["Test Selling"] = "Тестирование продажи"
L["Enabling this allows you to see what would get sold, without actually selling."] = "При включении будет показан список возможных предметов для продажи без актуальной продажи предметов"
L["Warehouse"] = "Склад"
L["Auto Sell"] = "Автоматическа продажа"
L["Items"] = "Предметы"
L["Grey"] = "Серые"
L["White"] = "Белые"
L["Green"] = "Зеленые"
L["Blue"] = "Синие"
L["Purple"] = "Фиолетовые"
L["Selling"] = "Продажа"
L["When you open a merchant, will auto sell your grey items"] = "При обращении к торговцу будет произведена попытка продать все предметы серого качества в вашем инвентаре"
L["When you open a merchant, will auto sell your white items."] = "При обращении к торговцу будет произведена попытка продать все предметы белого качества в вашем инвентаре"
L["When you open a merchant, will auto sell your green items."] = "При обращении к торговцу будет произведена попытка продать все предметы зеленого качества в вашем инвентаре"
L["When you open a merchant, will auto sell your blue items."] = "При обращении к торговцу будет произведена попытка продать все предметы синего качества в вашем инвентаре"
L["When you open a merchant, will auto sell your purple items."] = "При обращении к торговцу будет произведена попытка продать все предметы фиолетового качества в вашем инвентаре"
L["iLevel"] = "Уровень предмета"
L["Enable iLevel Limit"] = "Включить ограничение по уровню предмета"
L["Only sells items that are under the ilvl specified"] = "Продавать предметы с уровнем ниже указанного"
L["Sets the maximum item level which will be auto sold"] = "Устанавливает максимальный уровень предмета для автоматической продажи"
L["Sell BOP Items"] = "Продавать персональные (BOP) предметы"
L["When enabled will sell items that are BOP"] = "При включении позволяет автоматически продавать персональные (BOP) предметы"
L["Sell BOE Items"] = "Продавать передаваемые (BOE) предметы"
L["When enabled will sell items that are BOE"] = "При включении позволяет автоматически продавать передаваемые (BOE) предметы"
L["Sell items based on a list"] = "Продавать предметы на основании списка"
L["If item name matches one on the list, auto-sell it"] = "Продать предметы, если название предмета совпадает с указанным в списке"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "Введите название предмета для автоматической продажи. Также вы можете перетащить предмет из вашего инвентаря"
L["New Item To Sell (Case Insensative)"] = "Новый предмет для продажи (Регистр не имеет значения)"
L["AUTO-SELL: You Earned"] = "Автоматическая продажа: ваша прибыль"
L["Delete Item"] = "Удалить предмет"
L["Delete"] = "Удалить"
L["Yes"] = "Да"
L["No"] = "Нет"

L["Show coin count in warehouse list"] = "Показывать количество золота у персонажей"
L["Restores the coin totals after character names in warehouse listing"] = "Показывать количество золота у каждого персонажа"

L["Use don't display list"] = "Скрывать предметы из списка"
L["If enabled, don't show listed items in tooltips"] = "При включенгии указанные в списке предметы не будут показаны в подсказках"
L["New Item To Ignore (Case Insensative)"] = "Новый скрытый предмет (Регистр не имеет значения)"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "Введите название предмета, которые не будет отображен в подсказках. Также вы можете перетащить предмет из вашего инвентаря"
L["Ignore"] = "Скрывать"

-- Font outline/shadow options
L["Font Outline"] = "Контур шрифта"
L["Font Shadow"] = "Тень шрифта"
L["Sets the outline style of this font"] = "Задаёт стиль контура шрифта"
L["Adds a drop shadow to this font"] = "Добавляет тень к шрифту"
L["None"] = "Нет"
L["Outline"] = "Контур"
L["Thick Outline"] = "Толстый контур"
