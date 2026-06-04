extends Node2D

var messages = []
var emotes = []
var current_text_to_print = ""

func message(str: String, emote: String = 'happy'):
	messages.append(str)
	emotes.append(emote)

func _process(_delta: float) -> void:
	if messages.size() > 0 and current_text_to_print == "" and $print.is_stopped() and $exit.is_stopped():
		set("visible", true)
		current_text_to_print = messages.pop_front().c_unescape()
		var current_emote = emotes.pop_front()
		$anim.animation = current_emote
		$text.text = ""
		$print.start()
	elif messages.size() == 0 and $print.is_stopped() and $exit.is_stopped():
		set("visible", false)

func _on_print_timeout() -> void:
	if current_text_to_print.length() > 0:
		var char_to_print = current_text_to_print[0]
		$text.text += char_to_print
		current_text_to_print = current_text_to_print.erase(0, 1)
		$print.start()
	else:
		$exit.start()
		$print.stop()
