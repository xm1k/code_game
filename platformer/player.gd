extends CharacterBody2D

@export_group("Движение")
@export var max_speed: float = 600.0
@export var acceleration: float = 2500.0   
@export var friction: float = 1800.0       
@export var air_resistance: float = 200.0  # Сделал поменьше, чтобы почти не тормозил в полете

@export_group("Прыжок")
@export var gravity: float = 2100.0       
@export var jump_force: float = 1000.0

@onready var camera = get_parent().get_node("Camera")
@onready var sprite = $sprite

func _physics_process(delta):
	# 1. Камера
	if camera:
		camera.position.y = position.y

	# 2. Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Прыжок доступен только на земле
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_force

	# 3. Горизонтальное движение
	var direction = Input.get_axis("move_left", "move_right")

	if is_on_floor():
		# НА ЗЕМЛЕ: Импульс меняется кнопками
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# В ВОЗДУХЕ: Управление игнорируется, работает только сопротивление воздуха
		# Персонаж летит туда, куда его направили в момент отрыва от земли
		velocity.x = move_toward(velocity.x, 0, air_resistance * delta)

	# 4. Вращение спрайта (зависит от скорости)
	sprite.rotation_degrees += (velocity.x * delta * 0.5) 

	move_and_slide()
	
	if position.y<-380:
		var parent_var = get_parent().get_node("map").current_level_index
		var path = "res://levels/" + str(parent_var+2) + ".tscn"
		var new_scene_res = load(path)
		var new_scene = new_scene_res.instantiate() 
		
		get_tree().root.add_child(new_scene)
		get_tree().current_scene = new_scene

		get_owner().queue_free()
