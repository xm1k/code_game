extends Camera2D

@export var deadzone_size := Vector2(50, 30)

@onready var player = get_node("/root/main/Player")

func _physics_process(delta):
	if not is_instance_valid(player):
		return

	var diff = player.global_position - global_position
	var new_pos = global_position

	if diff.x > deadzone_size.x:
		new_pos.x = player.global_position.x - deadzone_size.x
	elif diff.x < -deadzone_size.x:
		new_pos.x = player.global_position.x + deadzone_size.x

	if diff.y > deadzone_size.y:
		new_pos.y = player.global_position.y - deadzone_size.y
	elif diff.y < -deadzone_size.y:
		new_pos.y = player.global_position.y + deadzone_size.y

	global_position = new_pos
