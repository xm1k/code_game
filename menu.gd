extends Control

@export_file("*.tscn") var current_level_path: String = "res://levels/1.tscn"

@export_file("*.tscn") var first_level_path: String = "res://levels/1.tscn"


func _ready() -> void:
	$start.pressed.connect(_on_start_button_pressed)
	$exit.pressed.connect(_on_end_button_pressed)
	$continue.pressed.connect(_on_continue_button_pressed)


func _on_start_button_pressed() -> void:
	if first_level_path != "":
		get_tree().change_scene_to_file(first_level_path)
	else:
		push_error("Путь к первому уровню не задан!")

func _on_end_button_pressed() -> void:
	get_tree().quit()

func _on_continue_button_pressed() -> void:
	if current_level_path != "":
		get_tree().change_scene_to_file(current_level_path)
	else:
		push_error("Путь для продолжения игры не задан!")
