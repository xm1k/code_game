extends CharacterBody2D

@export var gravity: float = 980.0
@export var speed: float = 200.0
@export var jump_force: float = 500.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_force

	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed
	if velocity.x != 0 and is_on_floor():
		$sprite.play('go')
	else:
		$sprite.stop()
	if velocity.x > 0:
		$sprite.flip_h = false
	elif velocity.x < 0:
		$sprite.flip_h = true
	move_and_slide()
