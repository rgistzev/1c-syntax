﻿#Использовать cmdline
#Использовать logos

Перем Лог;
Перем ДелатьКоммит;

Функция ВыполнитьКоманду(Знач КомандаЗапуска, Знач ТекстОшибки = "", Знач РабочийКаталог = "")

	Лог.Информация("Выполняю команду: " + КомандаЗапуска);

	ВыводКоманды = "";

	Процесс = СоздатьПроцесс("cmd.exe /C " + ОбернутьВКавычки(КомандаЗапуска), РабочийКаталог, Истина, , КодировкаТекста.UTF8);
	Процесс.Запустить();
	
	Процесс.ОжидатьЗавершения();
	
	Пока НЕ Процесс.Завершен ИЛИ Процесс.ПотокВывода.ЕстьДанные Цикл
		СтрокаВывода = Процесс.ПотокВывода.ПрочитатьСтроку();
		ВыводКоманды = ВыводКоманды + СтрокаВывода + Символы.ПС;
		Сообщить(СтрокаВывода);
	КонецЦикла;
	
	Если Процесс.КодВозврата <> 0 Тогда
		Лог.Ошибка("Код возврата: " + Процесс.КодВозврата);
		ТекстВывода = Процесс.ПотокОшибок.Прочитать();
		ВызватьИсключение ТекстОшибки + Символы.ПС + ТекстВывода;
	КонецЕсли;

	Возврат ВыводКоманды;
	
КонецФункции

Функция ОбернутьВКавычки(Знач Строка)
	Возврат """" + Строка + """";
КонецФункции

Процедура КопироватьСодержимоеКаталога(Откуда, Куда)
	
	КаталогНазначения = Новый Файл(Куда);
	Если КаталогНазначения.Существует() Тогда
		Если КаталогНазначения.ЭтоФайл() Тогда
			УдалитьФайлы(КаталогНазначения.ПолноеИмя);
			СоздатьКаталог(Куда);
		КонецЕсли;
	Иначе
		СоздатьКаталог(Куда);
	КонецЕсли;

	Файлы = НайтиФайлы(Откуда, ПолучитьМаскуВсеФайлы());
	Для Каждого Файл Из Файлы Цикл
		ПутьКопирования = ОбъединитьПути(Куда, Файл.Имя);
		Если Файл.ЭтоКаталог() Тогда
			КопироватьСодержимоеКаталога(Файл.ПолноеИмя, ПутьКопирования);
		Иначе
			КопироватьФайл(Файл.ПолноеИмя, ПутьКопирования);
		КонецЕсли;
	КонецЦикла;

КонецПроцедуры

Процедура ОбновитьПакетРедактора(ДанныеКоманды)
	
	Если ДелатьКоммит Тогда
		ВыполнитьКоманду("git pull", , ДанныеКоманды.ПутьККаталогуРепозитория);
	КонецЕсли;
	
	ПутьККаталогуПриемнику = ДанныеКоманды.ПутьККаталогуРепозитория;
	
	ТекстСообщения = СтрШаблон("Копирую файлы пакета в репозиторий %1", ДанныеКоманды.ПутьККаталогуРепозитория);
	Лог.Информация(ТекстСообщения);
	
	КопироватьСодержимоеКаталога(ДанныеКоманды.ПутьККаталогуИсточнику, ДанныеКоманды.ПутьККаталогуРепозитория);
	
	Если ДелатьКоммит Тогда

		ВыводКоманды = ВыполнитьКоманду("git status", , ДанныеКоманды.ПутьККаталогуРепозитория);
		Если Найти(ВыводКоманды, "nothing to commit, working directory clean") Тогда
			Возврат;
		КонецЕсли;

		ВыполнитьКоманду("git add .", , ДанныеКоманды.ПутьККаталогуРепозитория);

		ВыполнитьКоманду("git commit -m ""Package update""", , ДанныеКоманды.ПутьККаталогуРепозитория);

	КонецЕсли;
	
КонецПроцедуры

Функция Конструктор_ДанныеКомандыОбновленияПакета()

	ДанныеКоманды = Новый Структура;

	ДанныеКоманды.Вставить("ПутьККаталогуИсточнику", 	"");
	ДанныеКоманды.Вставить("ПутьККаталогуРепозитория",	"");
	
	Возврат ДанныеКоманды;

КонецФункции

Лог = Логирование.ПолучитьЛог("1c-syntax.app.publish");
Лог.УстановитьУровень(УровниЛога.Информация);

Парсер = Новый ПарсерАргументовКоманднойСтроки();
Парсер.ДобавитьПараметрФлаг("-commit");
Параметры = Парсер.Разобрать(АргументыКоманднойСтроки);

ДелатьКоммит = Ложь;

Если Параметры.Количество() > 0 Тогда
	ДелатьКоммит = Параметры["-commit"];
КонецЕсли;

ИмяКаталогаСборки = "build";
КаталогСборки = ОбъединитьПути(ТекущийКаталог(), ИмяКаталогаСборки);

ПапкаРепозиториев = ОбъединитьПути(ТекущийКаталог(), "..");
ИмяПакета = "language-1c-bsl";

ИмяПапки_Atom 		= "atom-" + ИмяПакета;
ИмяПапки_Sublime 	= "sublime-" + ИмяПакета;
ИмяПапки_VSC 		= "vsc-" + ИмяПакета;

Папка_Atom 		= ОбъединитьПути(ПапкаРепозиториев, ИмяПапки_Atom);
Папка_Sublime 	= ОбъединитьПути(ПапкаРепозиториев, ИмяПапки_Sublime);
Папка_VSC 		= ОбъединитьПути(ПапкаРепозиториев, ИмяПапки_VSC);

ДанныеКоманды_Atom = Конструктор_ДанныеКомандыОбновленияПакета();
ДанныеКоманды_Atom.ПутьККаталогуИсточнику = ОбъединитьПути(КаталогСборки, "Atom");
ДанныеКоманды_Atom.ПутьККаталогуРепозитория = Папка_Atom;

ОбновитьПакетРедактора(ДанныеКоманды_Atom);

ДанныеКоманды_Sublime = Конструктор_ДанныеКомандыОбновленияПакета();
ДанныеКоманды_Sublime.ПутьККаталогуИсточнику = ОбъединитьПути(КаталогСборки, "ST");
ДанныеКоманды_Sublime.ПутьККаталогуРепозитория = Папка_Sublime;

ОбновитьПакетРедактора(ДанныеКоманды_Sublime);

ДанныеКоманды_VSC = Конструктор_ДанныеКомандыОбновленияПакета();
ДанныеКоманды_VSC.ПутьККаталогуИсточнику = ОбъединитьПути(КаталогСборки, "VSC");
ДанныеКоманды_VSC.ПутьККаталогуРепозитория = Папка_VSC;

ОбновитьПакетРедактора(ДанныеКоманды_VSC);
