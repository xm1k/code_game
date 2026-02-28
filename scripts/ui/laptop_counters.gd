extends Control

var code_color
var logs_color
var cur_code_symb = 0
var cur_logs_symb = 0

var target_temp = 35.0
var temp = target_temp
var cooling = 1.0
var max_code_symb = 200
var max_logs_symb = 200
var max_energy = 1000
var energy = 1000

@onready var code_editor = get_node("/root/main/UI/Laptop/CodeEditor")
@onready var logger = get_node("/root/main/UI/Laptop/Logger")
@onready var health = get_node("/root/main/UI/Health")

func update_logs():
	cur_logs_symb = len(logger.text)
	if cur_logs_symb <= max_logs_symb:
		logs_color = "#39a359"
	else:
		logs_color = "#a33939"
	$logs.text = "[color={color}]{cur}/{max}[/color]".format({'cur': cur_logs_symb, 'max': max_logs_symb, 'color': logs_color})

func get_color_by_temp(temp: float) -> String:
	var t = clamp(temp, -50.0, 200.0)
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

func _process(delta: float) -> void:
	cur_code_symb = len(code_editor.text)
	if cur_code_symb <= max_code_symb:
		code_color = "#39a359"
	else:
		code_color = "#a33939"
	$code.text = "[color={color}]{cur}/{max}[/color]".format({'cur': cur_code_symb, 'max': max_code_symb, 'color': code_color})
	health.value = energy
	health.max_value = max_energy

func _on_timer_timeout() -> void:
	energy-=0.5
	if temp <= target_temp:
		temp+=(target_temp-temp)/4 + randi_range(0,5-cooling)
	elif temp > target_temp:
		temp-=cooling/2
	$temp.text = "[color={color}]{temp}°C[/color]".format({'temp': int(temp), 'color': get_color_by_temp(temp)})
	$energy.text = "{energy}/{max_energy}".format({'energy': int(energy), 'max_energy': max_energy})
