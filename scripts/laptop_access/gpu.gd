extends Control

var level = 1
@onready var main = get_node("/root/main")
@onready var laptop = main.get_node("UI/Laptop")
@onready var dur = laptop.get_node("Inventory/laptop/Tab/Duration")

var dict = {
	1: {"cost": [1,1,1,1], "time": "1"},
	2: {"cost": [2,1,1,1], "time": "0.75"},
	3: {"cost": [3,1,1,1], "time": "0.5"},
	4: {"cost": [4,1,1,1], "time": "0.25"},
	5: {"cost": [5,1,1,1], "time": "0.1"}
}

func refresh():
	for i in range(level):
		dur.set_item_disabled(i, false)
	$progress.value=level
	if level == len(dict):
		$button.set("visible", false)

func _on_button_button_down() -> void:
	if level<=len(dict):
		var string = """
Upgrading the GPU will cost {cost} data. The upgrade allows you to run the script every [color=#39a359]{time}[/color] seconds.
""".format({
		"cost": main.build_cost_from_arr(dict[level]['cost']),
		"time": dict[level+1]['time']
		})

		main.create_context_menu(string,"cpu", self)

func ok(operation):
	level+=1
	refresh()
