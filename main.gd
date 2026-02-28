extends Node2D

@onready var gui = $UI

func create_context_menu(desc, operation, parent):
	var scene := preload("res://objects/context_menu.tscn")
	var instance = scene.instantiate()
	instance.description = desc
	instance.operation = operation
	instance.set("parent", parent)
	gui.add_child(instance)

func create_message(text = "ERROR", color = "white"):
	var scene := preload("res://objects/msg.tscn")
	var instance = scene.instantiate()
	gui.get_node("Messages").add_child(instance)
	instance.init(text, color)

func build_cost_from_arr(arr):
	var string = ""
	for i in range(len(arr)):
		if str(arr[i]>0):
			string+=str(arr[i]) + "[img height=32]res://images/data/data{id}.png[/img]".format({'id': i+1})
	return string
	
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
