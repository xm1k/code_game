# Laptop.gd
extends Node2D

@onready var code_editor: CodeEdit = $CodeEditor
@onready var save_button: Button = $SaveButton
@onready var player: Node2D = get_parent().get_parent().get_node("Player")
@onready var game_code = get_python_script()
@onready var logger = $Logger
@onready var quotes = get_node("Inventory/laptop/Tab/Counters")

var MAX_CALLS = 10

const USER_SCRIPT_PATH := "res://user_code.py"

func get_code_text() -> String:
	return code_editor.text
	
func get_python_script() -> String:
	var path = "res://system_code/code.py"
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	return text

func logging(logs):
	quotes.update_logs()
	if quotes.max_logs_symb>=quotes.cur_logs_symb:
		logger.text = logger.text + logs
		quotes.update_logs()

func _ready():
	save_button.pressed.connect(save_and_apply_code)
	quotes.update_logs()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.shift_pressed:
			if event.keycode == Key.KEY_ENTER or event.keycode == Key.KEY_KP_ENTER:
				save_and_apply_code()

func save_and_apply_code(apply = true) -> void:
	if quotes.max_code_symb>=quotes.cur_code_symb:
		var game_vars = """
MAX_CALLS={max_calls}
""".format({
			'max_calls': MAX_CALLS
		}) + "\n"
		var code = game_vars + game_code + code_editor.text
		var file := FileAccess.open(USER_SCRIPT_PATH, FileAccess.WRITE)
		file.store_string(code)
		file.close()
		player.load_user_code(USER_SCRIPT_PATH, apply)
	else:
		get_node("/root/main").create_message("ERROR: out of code quota", "#a33939")
func _process(delta: float) -> void:
	if get_parent().get("is_laptop"):
		if position.y > 700:
			position.y-=70
			set("visible", true)
	else:
		if position.y < 2000:
			position.y+=70
		else:
			set("visible", false)

func ok(operation="none"):
	if operation =="clear_logs":
		logger.text = ""
		logging("")

func _on_clear_button_down() -> void:
	get_node("/root/main").create_context_menu("Do you really want to clear your logs?", "clear_logs", self)
