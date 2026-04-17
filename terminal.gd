extends Node2D

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var new_scene_res = load("res://platformer/platformer.tscn")
		var new_scene = new_scene_res.instantiate()
		
		new_scene.get_node("map").current_level_index = 0
		get_tree().root.add_child(new_scene)
		get_tree().current_scene = new_scene

		get_owner().queue_free()
