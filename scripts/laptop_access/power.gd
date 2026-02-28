extends Control

var level = 1
@onready var main = get_node("/root/main")
@onready var counters = main.get_node("UI/Laptop/Inventory/laptop/Tab/Counters")

var dict = {
	1: {"cost": [1,1,1,1], "capacity": 1000},
	2: {"cost": [2,1,1,1], "capacity": 2000},
	3: {"cost": [3,1,1,1], "capacity": 3000},
	4: {"cost": [4,1,1,1], "capacity": 4000},
	5: {"cost": [5,1,1,1], "capacity": 5000}
}

func refresh():
	if counters.max_energy!=dict[level]['capacity']:
		var cur_per = float(counters.energy)/float(counters.max_energy)
		counters.max_energy = dict[level]['capacity']
		counters.energy = counters.max_energy * cur_per
	$progress.value=level
	if level == len(dict):
		$button.set("visible", false)

func _on_button_button_down() -> void:
	if level<=len(dict):
		var string = """
Upgrading the Power Supply will cost {cost} data.
This upgrade increases the laptop's maximum energu capacity [color=#a33939]{from}[/color] → [color=#39a359]{to}[/color]
""".format({
		"cost": main.build_cost_from_arr(dict[level]['cost']),
		"from": dict[level]['capacity'],
		"to": dict[level+1]['capacity']
		})

		main.create_context_menu(string,"power", self)

func ok(operation):
	level+=1
	refresh()
