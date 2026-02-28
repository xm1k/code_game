extends CharacterBody2D

var speed = 5000
var direction = Vector2(1,0)
@onready var password = str(randi_range(3, 3))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func try_pass(passw):
	if str(passw) == password:
		queue_free()

func _check_direction():
	if direction.x <= 0:
		$sprite.flip_h = true
	else:
		$sprite.flip_h = false

func _on_hit(body):
	if body.is_in_group("player"):
		#direction = direction * -1
		pass

func _check_collisions():
	var collision_count := get_slide_collision_count()
	for i in range(collision_count):
		var coll := get_slide_collision(i)
		if coll:
			_on_hit(coll.get_collider())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_check_collisions()
	_check_direction()
	velocity = direction * speed * delta
	move_and_slide()
