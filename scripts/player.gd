extends CharacterBody2D

var direction: Vector2 = Vector2(0,0)
var manual_control = true
var is_manual_moving = false
var speed = 50000 

@onready var ui = get_node("/root/main/UI")
@onready var laptop = ui.get_node("Laptop")
@onready var counters = laptop.get_node("Inventory/laptop/Tab/Counters")
@onready var enemies = get_node("/root/main/enemies")
@onready var sprite = $sprite

var side_direction = "s"
var user_script_instance: Node



func load_user_code(path: String, apply) -> void:
	if user_script_instance: 
		user_script_instance.queue_free()
	user_script_instance = Node2D.new()
	var updated_script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	user_script_instance.set_script(updated_script)
	add_child(user_script_instance)
	if user_script_instance.has_method("delta") and user_script_instance != null and apply:
		counters.energy-=1
		user_script_instance.call("delta", self, laptop, enemies)

func manual_moving():
	if is_manual_moving == true:
		is_manual_moving = false
		direction = Vector2.ZERO
	if not(ui.get("is_laptop")):
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			direction.y -= 1
			is_manual_moving = true
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			direction.y += 1
			is_manual_moving = true
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			direction.x -= 1
			is_manual_moving = true
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			direction.x += 1
			is_manual_moving = true

func _process(delta):
	manual_moving()
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		var rounded_dir = Vector2(round(direction.x), round(direction.y))
		if rounded_dir.y == 1:
			side_direction = "s"
		elif rounded_dir.y == -1:
			side_direction = "n"
		elif  rounded_dir == Vector2(1, 0):
			side_direction = "e"
		elif  rounded_dir == Vector2(-1, 0):
			side_direction = "w"
		sprite.animation = "run_" + side_direction
		#position += direction * speed * delta
		velocity = direction * speed * delta
	else:
		sprite.animation = "idle_" + side_direction
		velocity = Vector2.ZERO
	
	move_and_slide()

func _on_automate_toggled(toggled_on: bool) -> void:
	manual_control = not(toggled_on)
	if not(manual_control):
		$CodeTimer.start()
		$CodeTimer.wait_time = float(laptop.get_node("Inventory/laptop/Tab/Duration").text)
	else:
		$CodeTimer.stop()

func _on_code_timer_timeout() -> void:
	if user_script_instance:
		if user_script_instance.has_method("delta"):
			counters.energy-=1
			user_script_instance.call("delta", self, laptop, enemies)




func _on_duration_item_selected(index: int) -> void:
	_on_automate_toggled(not(manual_control))
