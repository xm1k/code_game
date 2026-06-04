extends Node2D

var messages = []
var emotes = []
var current_text_to_print = ""

func _ready() -> void:
	message("Привет! Ты попал в свой компьтер.\nЧтобы выбраться тебе нужно будет пройти уровни.\nОстерегайся жуков, если ты им попадешься,\nто придется решать задачи. Чтобы увидеть задачу нажми Esc", "happy") #1
	message("Переменная - это коробка с именем. Имя (например, a)\n — наклейка на коробке. Тип — что внутри: целые числа (5),\n вещественные (3,14) или символы (А).\n Значение — то, что лежит. Оператор = кладёт значение: a = 5.", "happy")#1
	message("Арифметика в коде работает так: сначала умножение,\nпотом сложение. Целочисленное деление // — сколько раз \nпомещается (9//4=2). Остаток % — что останется (9%4=1)", "happy")#1
	message("Условие(if): — развилка. and / or исользуют для \nсложных условий. Минимум двух: if a<b: min=a else: min=b.", "happy")#2
	message("Полное: if условие: действие1 else: действие2. \nНеполное: только if без else. Условие истинно (True) или \nложно (False). Простое: x>5. Составное: x>5 and y<10.", "happy")#2
	message("Цикл for i in range(5): — исполняется 5 раз; \nfor i in range(1,11): — с переменной i от 1 до 10.", "happy")#3
	message("Цикл while(условие) — исполняется пока выполняется \nусловие; a = 1, b =3 while(b!=a)\n b=b-1 будет выполнен два раза", "happy") #4
	message("НОД — наибольший общий делитель. Пока числа не\nравны: большее заменяем на остаток от деления на меньшее.\n Когда остаток 0 — меньшее и есть НОД.", "happy") #5
	
func message(str: String, emote: String = 'happy'):
	messages.append(str)
	emotes.append(emote)

func _process(_delta: float) -> void:
	if messages.size() > 0 and current_text_to_print == "" and $print.is_stopped() and $exit.is_stopped():
		set("visible", true)
		current_text_to_print = messages.pop_front().c_unescape()
		var current_emote = emotes.pop_front()
		$anim.animation = current_emote
		$text.text = ""
		$print.start()
	elif messages.size() == 0 and $print.is_stopped() and $exit.is_stopped():
		set("visible", false)

func _on_print_timeout() -> void:
	if current_text_to_print.length() > 0:
		var char_to_print = current_text_to_print[0]
		$text.text += char_to_print
		current_text_to_print = current_text_to_print.erase(0, 1)
		$print.start()
	else:
		$exit.start()
		$print.stop()
