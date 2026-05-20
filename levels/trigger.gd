extends Node2D

@export var message: String = "hello world"
@export_enum("happy", "broken", "embarassed", "sad", "serious", "shoked") var emote: String = "happy"

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_parent().get_node("UI").get_node("talk").message(message, emote)
		self.queue_free()
