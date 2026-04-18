extends Control

# UI элементы (настройте пути под вашу сцену)
@onready var code_editor = get_node("/root/main/UI/Laptop/CodeEditor")
@onready var logger = get_node("/root/main/UI/Laptop/Logger")
@onready var health = get_node("/root/main/UI/Health")

# Счётчики символов
var cur_code_symb = 0
var cur_logs_symb = 0
var max_code_symb = 200
var max_logs_symb = 200

# Энергия
var max_energy = 1000
var energy = 1000
var energy_drain_multiplier = 1.0   # увеличивает расход энергии (от врага)

# Температура
var original_target_temp = 35.0
var target_temp = 35.0
var temp = 35.0
var cooling = 1.0                  # базовая скорость охлаждения (влияет на динамику)
var cooling_rate = 5.0             # скорость остывания после ухода врага (градусов/сек)

# Нагрев от врага (плавный)
var current_temp_boost = 0.0
var target_temp_boost = 0.0
var heating_rate = 0.0             # градусов в секунду

# Цвета для отображения
var code_color
var logs_color

func _ready():
	randomize()
	original_target_temp = target_temp
	# Убедимся, что таймер подключён (если нет – создадим)
	if not $Timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
		$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()

# ---------- Методы, вызываемые из Enemy.gd ----------
func set_energy_drain_multiplier(mult: float):
	energy_drain_multiplier = mult
	print("Energy drain multiplier = ", mult)

# Запуск постепенного нагрева
func start_heating(rate: float, max_boost: float):
	heating_rate = rate
	target_temp_boost = max_boost
	print("Нагрев включён: скорость = ", rate, "°C/с, максимум = ", max_boost, "°C")

# Остановка нагрева (например, враг побеждён или игрок ушёл)
func stop_heating():
	target_temp_boost = 0.0
	heating_rate = 0.0
	print("Нагрев выключен, начинается остывание")

# Для совместимости со старым кодом (мгновенный буст) – можно оставить, но лучше не использовать
func set_temp_boost(boost: float):
	current_temp_boost = boost
	target_temp_boost = boost
	target_temp = original_target_temp + current_temp_boost
	print("Установлен мгновенный буст температуры: ", boost)

# ---------- Обновление UI счётчиков ----------
func update_logs():
	cur_logs_symb = len(logger.text)
	if cur_logs_symb <= max_logs_symb:
		logs_color = "#39a359"
	else:
		logs_color = "#a33939"
	$logs.text = "[color={color}]{cur}/{max}[/color]".format({
		'cur': cur_logs_symb, 'max': max_logs_symb, 'color': logs_color
	})

func get_color_by_temp(temp_val: float) -> String:
	var t = clamp(temp_val, -50.0, 200.0)
	if t <= 30.0:
		return "#A9D6FF"
	elif t <= 50.0:
		return "#A8E6CF"
	elif t <= 65.0:
		return "#B8E6A0"
	elif t <= 75.0:
		return "#FFF5A8"
	elif t <= 90.0:
		return "#FFD6A5"
	else:
		return "#FF9AA2"

func _process(delta):
	# Обновление счётчиков символов
	cur_code_symb = len(code_editor.text)
	if cur_code_symb <= max_code_symb:
		code_color = "#39a359"
	else:
		code_color = "#a33939"
	$code.text = "[color={color}]{cur}/{max}[/color]".format({
		'cur': cur_code_symb, 'max': max_code_symb, 'color': code_color
	})
	update_logs()
	
	# Плавное изменение температурного буста
	if current_temp_boost < target_temp_boost:
		current_temp_boost += heating_rate * delta
		if current_temp_boost > target_temp_boost:
			current_temp_boost = target_temp_boost
	elif current_temp_boost > target_temp_boost:
		current_temp_boost -= cooling_rate * delta
		if current_temp_boost < target_temp_boost:
			current_temp_boost = target_temp_boost
	
	# Обновляем целевую температуру (базовая + буст)
	target_temp = original_target_temp + current_temp_boost
	
	# Обновление прогресс-бара здоровья
	health.value = energy
	health.max_value = max_energy

func _on_timer_timeout():
	# Расход энергии с учётом множителя
	energy -= 0.5 * energy_drain_multiplier
	if energy < 0:
		energy = 0
	
	# Динамика температуры (естественное стремление к target_temp)
	if temp <= target_temp:
		temp += (target_temp - temp) / 4 + randi_range(0, 5 - cooling)
	elif temp > target_temp:
		temp -= cooling / 2
	
	# Ограничения температуры
	temp = clamp(temp, -50.0, 200.0)
	
	# Обновление UI температуры и энергии
	$temp.text = "[color={color}]{temp}°C[/color]".format({
		'temp': int(temp), 'color': get_color_by_temp(temp)
	})
	$energy.text = "{energy}/{max_energy}".format({
		'energy': int(energy), 'max_energy': max_energy
	})
	
	# Дополнительные эффекты при перегреве (опционально)
	if temp >= 90.0:
		# Например, ускоренный расход энергии
		energy -= 0.2 * energy_drain_multiplier
		pass
