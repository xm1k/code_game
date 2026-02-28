extends Control

var level = 1
@onready var main = get_node("/root/main")
@onready var counters = main.get_node("UI/Laptop/Inventory/laptop/Tab/Counters")

var dict = {
	1: {"cost": [1,1,1,1], "max_code": 200, "max_logs": 200},
	2: {"cost": [2,1,1,1], "max_code": 400, "max_logs": 300},
	3: {"cost": [3,1,1,1], "max_code": 600, "max_logs": 400},
	4: {"cost": [4,1,1,1], "max_code": 800, "max_logs": 500},
	5: {"cost": [5,1,1,1], "max_code": 2000, "max_logs": 1000}
}

func refresh():
	counters.max_code_symb = dict[level]['max_code']
	counters.max_logs_symb = dict[level]['max_logs']
	$progress.value+=1
	if level == len(dict):
		$button.set("visible", false)
	counters.update_logs()

func _on_button_button_down() -> void:
	if level<=len(dict):
		var string = """
Upgrading the Storage will cost {cost} data.

This upgrade expands the system’s log quote [color=#a33939]{from_logs}[/color] → [color=#39a359]{to_logs}[/color]
and code storage_capacity [color=#a33939]{from_code}[/color] → [color=#39a359]{to_code}[/color]
""".format({
		"cost": main.build_cost_from_arr(dict[level]['cost']),
		"from_logs": dict[level]['max_logs'],
		"to_logs": dict[level+1]['max_logs'],
		"from_code": dict[level]['max_code'],
		"to_code": dict[level+1]['max_code']
		})

		main.create_context_menu(string,"hdd", self)

func ok(operation):
	level+=1
	refresh()
