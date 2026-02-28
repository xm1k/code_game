extends TextureRect

@export var description: String
@export var operation: String
var parent

func _ready() -> void:
	$description.text = description
	pass
	
func _on_ok_button_down() -> void:
	parent.ok(operation)
	queue_free()

func _on_cancel_button_down() -> void:
	queue_free()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		queue_free()
