extends Control

var level = 1
@onready var main = get_node("/root/main")
@onready var laptop = main.get_node("UI/Laptop")

var dict = {
	1: {"cost": [1,1,1,1], "lines": 10},
	2: {"cost": [2,1,1,1], "lines": 20},
	3: {"cost": [3,1,1,1], "lines": 40},
	4: {"cost": [4,1,1,1], "lines": 80},
	5: {"cost": [5,1,1,1], "lines": 200}
}

func refresh():
	laptop.MAX_CALLS = dict[level]['lines']
	laptop.save_and_apply_code(false)
	$progress.value=level
	if level == len(dict):
		$button.set("visible", false)
func _on_button_button_down() -> void:
	if level<=len(dict):
		var string = """
Upgrading the CPU will cost {cost} data.

This upgrade increases your processing capacity, allowing you to execute [color=#a33939]{from}[/color] → [color=#39a359]{to}[/color] lines per run.
""".format({
		"cost": main.build_cost_from_arr(dict[level]['cost']),
		"from": dict[level]['lines'],
		"to": dict[level+1]['lines']
		})

		main.create_context_menu(string,"cpu", self)

func ok(operation):
	level+=1
	refresh()
