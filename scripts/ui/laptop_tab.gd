extends Button

func _on_button_down() -> void:
	for child in get_parent().get_parent().get_children():
		child.get_node("Tab").set("visible", false)
	get_parent().get_node("Tab").set("visible", true)
