extends Control

var level = 1
@onready var main = get_node("/root/main")
@onready var laptop = main.get_node("UI/Laptop")
@onready var temp = laptop.get_node("Inventory/laptop/Tab/Counters")

var dict = {
	1: {"cost": [1,1,1,1], "cool_effect": 1.0, "target_temp": 35.0},
	2: {"cost": [2,1,1,1], "cool_effect": 2.0, "target_temp": 30.0},
	3: {"cost": [3,1,1,1], "cool_effect": 3.0, "target_temp": 25.0},
	4: {"cost": [4,1,1,1], "cool_effect": 4.0, "target_temp": 20.0},
	5: {"cost": [5,1,1,1], "cool_effect": 5.0, "target_temp": 10.0}
}

func refresh():
	temp.cooling = dict[level]["cool_effect"]
	temp.target_temp = dict[level]["target_temp"]
	$progress.value=level
	if level == len(dict):
		$button.set("visible", false)

func _on_button_button_down() -> void:
	if level<=len(dict):
		var string = """
Upgrading the FAN will cost {cost} data. 
The upgrade increase tour cool effect [color=#a33939]{from_cool_eff}[/color] → [color=#39a359]{to_cool_eff}[/color]
and decrease default laptop temperature [color=#a33939]{from_tt}[/color] → [color=#39a359]{to_tt}[/color]
""".format({
		"cost": main.build_cost_from_arr(dict[level]['cost']),
		"from_cool_eff": dict[level]['cool_effect'],
		"to_cool_eff": dict[level+1]['cool_effect'],
		"from_tt": dict[level]['target_temp'],
		"to_tt": dict[level+1]['target_temp']
		})

		main.create_context_menu(string,"cpu", self)

func ok(operation):
	level+=1
	refresh()
