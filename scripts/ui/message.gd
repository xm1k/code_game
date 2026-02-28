extends PanelContainer

var to_destroy=false

func init(text="ERROR", color = "white"):
	$Margin/Message.text = "[color={color}]{text}[/color]".format({'color': color, 'text': text})


func _ready() -> void:
	init()

func _process(delta: float) -> void:
	if to_destroy:
		modulate.a -= 2 * delta
		if modulate.a <= 0.0:
			queue_free()

func _on_timer_timeout() -> void:
	to_destroy = true
