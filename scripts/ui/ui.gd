extends CanvasLayer

@onready var laptop = $Laptop
var is_laptop = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			is_laptop=not(laptop.get("visible"))
