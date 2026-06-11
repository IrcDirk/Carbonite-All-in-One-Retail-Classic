if ( GetLocale() ~= "ruRU" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "ruRU")
if not L then return end

L["Info Options"] = "Настройки Информации"
L["Lock Info Windows"] = "Закрепить окно информации"
L["Locks the location of your info windows"] = "Устанавливает пложение для вашего окна информации"
L["Info Window Background Color"] = "Фон окна информации"
L["Info Font"] = "Информационый шрифт"
L["Sets the font to be used for info windows"] = "Задает шрифт который будет использоваться в окне информации"
L["Info Font Size"] = "Размер информационного шрифта"
L["Sets the size of the info font"] = "Задает размер информационного шрифта"
L["Info Font Spacing"] = "Межстрочный интервал информационного шрифта"
L["Sets the spacing of the info font"] = "Задает размер межстрочного интервала информационного шрифта"
L["Show Info Windows"] = "Показать окно информации"
L["Toggle Info Windows"] = "Вкл./Выкл. окна информации"
L["Info Module"] = "Модуль информации"
L["Close"] = "Закрыть"
L["Edit Item"] = "Изменить"
L["Show"] = "Показать"
L["New Info Window"] = "Новое окно информации"
L["Delete This Window"] = "Удалить это окно"
L["Options"] = "Настройки"
L["Info"] = "Информация"
L["Edit View"] = "Настроить вид"
L["Stop Edit"] = "Прекратить редактирование"
L["Change Text"] = "Изменить текст"
L["Delete Info Window"] = "Удалить окно информации"
L["Delete"] = "Удалить"
L["Cancel"] = "Отменить"

L["One minute until the Arena"] = "Одна минута до боя на Арене"
L["Thirty seconds until the Arena"] = "Тридцать секунд до боя на Арене"
L["Fifteen seconds until the Arena"] = "Пятнадцать до боя на Арене"

L["Reset old info data %f"] = true
L[" begins? in (%d+) "] = true
L["(%d+) minutes? until the battle"] = true

-- Kill marker icons (Carbonite map skull/seal markers)
L["Kill Icons"] = "Иконки убийств"
L["Show kill markers on map"] = "Показывать метки убийств на карте"
L["When enabled, killed mobs leave a skull icon on your map at the kill location"] = "Если включено, убитые мобы оставляют иконку черепа на карте в месте убийства"
L["Auto-clear kill markers after"] = "Удалять метки убийств через"
L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"] = "Секунд до автоматического удаления метки убийства. 0 = никогда (только ручная очистка)"
L["Keep kill history"] = "Хранить историю убийств"
L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."] = "Если включено, таймер только скрывает истёкшие метки, но сохраняет записи об убийствах. Полезно для постоянного журнала убийств."

-- Font outline/shadow options
L["Font Outline"] = "Контур шрифта"
L["Font Shadow"] = "Тень шрифта"
L["Sets the outline style of this font"] = "Задаёт стиль контура шрифта"
L["Adds a drop shadow to this font"] = "Добавляет тень к шрифту"
L["None"] = "Нет"
L["Outline"] = "Контур"
L["Thick Outline"] = "Толстый контур"
