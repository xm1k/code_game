extends CharacterBody2D

enum Difficulty { 
	EASY = 1, MEDIUM = 2, HARD = 3, 
	LEVEL4 = 4, LEVEL5 = 5, LEVEL6 = 6 
}

@export var difficulty: Difficulty = Difficulty.EASY
@export var move_speed: float = 50.0

var password: String = ""
var challenge_text: String = ""
var player_in_range: bool = false
var player_node: Node2D = null
var is_active: bool = true
var busy: bool = false

var move_direction: Vector2 = Vector2.RIGHT
var change_dir_timer: float = 0.0
var change_dir_interval: float = 2.0

@onready var detection_area = $DetectionArea
@onready var ui = get_node("/root/main/UI")
@onready var animated_sprite = $AnimatedSprite2D
@onready var laptop = get_node("/root/main/UI/Laptop")

func _ready():
	randomize()
	_generate_challenge()
	
	match difficulty:
		Difficulty.EASY:
			animated_sprite.modulate = Color.GREEN
			move_speed = 40.0
		Difficulty.MEDIUM:
			animated_sprite.modulate = Color.YELLOW
			move_speed = 50.0
		Difficulty.HARD:
			animated_sprite.modulate = Color.ORANGE
			move_speed = 60.0
		Difficulty.LEVEL4:
			animated_sprite.modulate = Color.DEEP_SKY_BLUE
			move_speed = 70.0
		Difficulty.LEVEL5:
			animated_sprite.modulate = Color.PURPLE
			move_speed = 80.0
		Difficulty.LEVEL6:
			animated_sprite.modulate = Color.RED
			move_speed = 90.0
	
	_set_random_direction()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	print("Враг инициализирован. Сложность: ", difficulty)
	if difficulty <= Difficulty.HARD:
		print("Пароль: ", password)
	else:
		print("Задание: ", challenge_text, " | Ответ: ", password)
	
	if laptop:
		print("Laptop найден")
	else:
		print("ОШИБКА: Laptop не найден по пути /root/main/UI/Laptop")

func _set_random_direction():
	var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	move_direction = directions[randi() % directions.size()]
	print("Новое направление: ", move_direction)

func _update_animation():
	if not is_active or busy:
		if animated_sprite.is_playing():
			animated_sprite.stop()
		return
	
	if move_direction == Vector2.RIGHT:
		_play_if_exists("walk_right")
	elif move_direction == Vector2.LEFT:
		_play_if_exists("walk_left")
	elif move_direction == Vector2.DOWN:
		_play_if_exists("walk_down")
	elif move_direction == Vector2.UP:
		_play_if_exists("walk_up")
	else:
		_play_if_exists("idle")

func _play_if_exists(anim_name: String):
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
	else:
		if animated_sprite.is_playing():
			animated_sprite.stop()

func _generate_challenge():
	match difficulty:
		Difficulty.EASY:
			password = str(randi() % 10)
			challenge_text = "Введи цифру от 0 до 9"
		Difficulty.MEDIUM:
			password = str(randi() % 90 + 10)
			challenge_text = "Введи число от 10 до 99"
		Difficulty.HARD:
			var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			password = ""
			for i in range(3):
				password += letters[randi() % letters.length()]
			challenge_text = "Введи 3 заглавные буквы"
		Difficulty.LEVEL4:
			_generate_level4()
		Difficulty.LEVEL5:
			_generate_level5()
		Difficulty.LEVEL6:
			_generate_level6()

func _generate_level4():
	var r = randi() % 3
	match r:
		0:
			var a = randi() % 20 + 1
			var b = randi() % 20 + 1
			var op = ["+", "-"][randi() % 2]
			var result = a + b if op == "+" else a - b
			challenge_text = str(a) + " " + op + " " + str(b) + " = ?"
			password = str(result)
		1:
			var a = randi() % 50 + 1
			var b = randi() % 50 + 1
			challenge_text = "Что больше: " + str(a) + " или " + str(b) + "? (введи число)"
			password = str(max(a, b))
		2:
			var a = randi() % 10
			var b = randi() % 10
			var correct = (a == b)
			challenge_text = str(a) + " равно " + str(b) + "? (да/нет)"
			password = "true" if correct else "false"

func _generate_level5():
	var r = randi() % 3
	match r:
		0:
			var a = randi() % 10 + 1
			var b = randi() % 10 + 1
			var c = randi() % 5 + 1
			var ops = ["+", "-", "*"]
			var op1 = ops[randi() % 3]
			var op2 = ops[randi() % 3]
			var expr = str(a) + " " + op1 + " " + str(b) + " " + op2 + " " + str(c)
			var result = _eval_expr(expr)
			challenge_text = expr + " = ?"
			password = str(result)
		1:
			var a = randi() % 20
			var b = randi() % 20
			var cmp = ["<", ">", "=="][randi() % 3]
			var correct = false
			match cmp:
				"<": correct = a < b
				">": correct = a > b
				"==": correct = a == b
			challenge_text = str(a) + " " + cmp + " " + str(b) + " ? (да/нет)"
			password = "да" if correct else "нет"
		2:
			var words = ["HELLO", "WORLD", "GODOT", "PYTHON", "GAME"]
			var word = words[randi() % words.size()]
			var encrypted = ""
			for ch in word:
				var code = ch.unicode_at(0)
				var shifted = code + 1
				if shifted > 'Z'.unicode_at(0):
					shifted = 'A'.unicode_at(0)
				encrypted += char(shifted)
			challenge_text = "Расшифруй (сдвиг -1): " + encrypted
			password = word

func _generate_level6():
	var r = randi() % 3
	match r:
		0:
			var n = randi() % 20 + 5
			var sum = n * (n + 1) / 2
			challenge_text = "Сумма чисел от 1 до " + str(n) + " = ?"
			password = str(sum)
		1:
			var a = randi() % 5 + 1
			var b = randi() % 20
			var c = randi() % 50 + 10
			while (c - b) % a != 0:
				c = randi() % 50 + 10
			var x = (c - b) / a
			challenge_text = str(a) + "*x + " + str(b) + " = " + str(c) + "  (найди x)"
			password = str(x)
		2:
			var a = randi() % 50 + 10
			var b = randi() % 50 + 10
			var gcd = _gcd(a, b)
			challenge_text = "НОД(" + str(a) + ", " + str(b) + ") = ?"
			password = str(gcd)

func _eval_expr(expr: String) -> int:
	var parts = expr.split(" ")
	var a = int(parts[0])
	var op1 = parts[1]
	var b = int(parts[2])
	var op2 = parts[3]
	var c = int(parts[4])
	
	if op1 == "*" or op1 == "/":
		var left = a * b if op1 == "*" else a / b
		return left + c if op2 == "+" else left - c if op2 == "-" else left * c if op2 == "*" else left / c
	elif op2 == "*" or op2 == "/":
		var right = b * c if op2 == "*" else b / c
		return a + right if op1 == "+" else a - right if op1 == "-" else a * right if op1 == "*" else a / right
	else:
		var left = a + b if op1 == "+" else a - b
		return left + c if op2 == "+" else left - c

func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t = b
		b = a % b
		a = t
	return a

func _physics_process(delta):
	if not is_active or busy:
		_update_animation()
		return
	
	move_and_collide(move_direction * move_speed * delta)
	
	change_dir_timer += delta
	if change_dir_timer >= change_dir_interval:
		change_dir_timer = 0.0
		_set_random_direction()
	
	_update_animation()
	
	if player_in_range and player_node and not _is_player_busy() and not busy:
		_start_password_challenge()

func _on_body_entered(body):
	print("Тело вошло в зону: ", body.name, " (класс: ", body.get_class(), ")")
	if body == self:
		print("Игнорируем себя")
		return
	if body.name == "Player" or body.is_in_group("player"):
		print("ИГРОК обнаружен!")
		player_in_range = true
		player_node = body
		_start_password_challenge()
	else:
		print("Это не игрок")

func _on_body_exited(body):
	print("Тело покинуло зону: ", body.name)
	if body.name == "Player" or body.is_in_group("player"):
		print("Игрок покинул зону")
		player_in_range = false
		if busy:
			busy = false
			is_active = true
			if player_node and player_node.has_method("set_busy"):
				player_node.call("set_busy", false)
			var counters = ui.get_node("Laptop/Inventory/laptop/Tab/Counters")
			if counters:
				if counters.has_method("set_energy_drain_multiplier"):
					counters.set_energy_drain_multiplier(1.0)
				if counters.has_method("stop_heating"):
					counters.stop_heating()
			#_show_message("Враг потерял интерес", "yellow")
		player_node = null

func _is_player_busy():
	return false

func _get_energy_multiplier() -> float:
	match difficulty:
		Difficulty.EASY:    return 1.0
		Difficulty.MEDIUM:  return 1.5
		Difficulty.HARD:    return 2.0
		Difficulty.LEVEL4:  return 2.5
		Difficulty.LEVEL5:  return 3.0
		Difficulty.LEVEL6:  return 4.0
		_:                  return 1.0

func _get_temp_boost() -> float:
	match difficulty:
		Difficulty.EASY:    return 20.0
		Difficulty.MEDIUM:  return 25.0
		Difficulty.HARD:    return 30.0
		Difficulty.LEVEL4:  return 35.0
		Difficulty.LEVEL5:  return 40.0
		Difficulty.LEVEL6:  return 45.0
		_:                  return 0.0
		
# Добавьте функцию для получения скорости нагрева
func _get_heating_rate() -> float:
	match difficulty:
		Difficulty.EASY:    return 1.0   # °C в секунду
		Difficulty.MEDIUM:  return 1.15
		Difficulty.HARD:    return 1.3
		Difficulty.LEVEL4:  return 1.5
		Difficulty.LEVEL5:  return 2.0
		Difficulty.LEVEL6:  return 3.0
		_:                  return 1.0

func _start_password_challenge():
	busy = true
	is_active = false
	var color = _get_color_by_difficulty()
	_show_message("Враг требует ответ!\n" + challenge_text + "\n", color)
	if player_node and player_node.has_method("set_busy"):
		player_node.call("set_busy", true)
	
	var counters = ui.get_node("Laptop/Inventory/laptop/Tab/Counters")
	if counters:
		if counters.has_method("set_energy_drain_multiplier"):
			counters.set_energy_drain_multiplier(_get_energy_multiplier())
		# Запускаем постепенный нагрев
		if counters.has_method("start_heating"):
			counters.start_heating(_get_heating_rate(), _get_temp_boost())

func _get_color_by_difficulty() -> String:
	match difficulty:
		Difficulty.EASY:    return "green"
		Difficulty.MEDIUM:  return "yellow"
		Difficulty.HARD:    return "orange"
		Difficulty.LEVEL4:  return "deepskyblue"
		Difficulty.LEVEL5:  return "purple"
		Difficulty.LEVEL6:  return "red"
		_:                  return "white"

func _show_message(text: String, color: String = "white"):
	var bbcode_text = "[color={color}]{text}[/color]".format({"color": color, "text": text})
	if laptop and laptop.has_method("logging"):
		laptop.call("logging", bbcode_text)
		print("Сообщение отправлено в Laptop")
	else:
		print("ОШИБКА: Laptop не найден или нет logging. Текст: ", text)

func try_pass(attempt: String) -> bool:
	if not busy:
		_show_message("Сначала подойди к врагу", "red")
		return false
	
	var normalized_attempt = attempt.strip_edges().to_lower()
	var normalized_password = password.strip_edges().to_lower()
	
	if normalized_attempt == normalized_password:
		_show_message("✅ Верно! Враг побеждён.", "green")
		if player_node and player_node.has_method("set_busy"):
			player_node.call("set_busy", false)
		
		var counters = ui.get_node("Laptop/Inventory/laptop/Tab/Counters")
		if counters:
			if counters.has_method("set_energy_drain_multiplier"):
				counters.set_energy_drain_multiplier(1.0)
			if counters.has_method("stop_heating"):
				counters.stop_heating()
		queue_free()
		return true
	else:
		_show_message("❌", "red")
		var counters = ui.get_node("Laptop/Inventory/laptop/Tab/Counters")
		if counters and "energy" in counters:
			counters.energy -= 1
		return false
