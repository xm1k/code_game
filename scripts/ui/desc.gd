extends Control

func _on_mouse_entered() -> void:
	$Text.set("visible", true)


func _on_mouse_exited() -> void:
	$Text.set("visible", false)
