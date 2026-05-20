extends CanvasLayer
class_name CardfrontTopResourceBar

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var resource_states: Dictionary = {}
var economy_system = null
var last_energy: int = -1
var last_parts: int = -1

@onready var _energy_value: Label = $Margin/HBox/EnergyBox/Margin2/Inner/Value
@onready var _parts_value: Label = $Margin/HBox/PartsBox/Margin2/Inner/Value
@onready var _yield_label: Label = $Margin/HBox/YieldLabel


func setup(new_economy_system, new_resource_states: Dictionary, mode_name: String) -> void:
	economy_system = new_economy_system
	resource_states = new_resource_states.duplicate(false)
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if not visible:
		return
	_connect_economy_signals()
	refresh(true)


func _connect_economy_signals() -> void:
	if economy_system == null:
		return
	var c := Callable(self, "_on_resources_changed")
	if economy_system.has_signal("resources_changed") and not economy_system.resources_changed.is_connected(c):
		economy_system.resources_changed.connect(c)
	var y := Callable(self, "_on_yield_tick")
	if economy_system.has_signal("yield_tick") and not economy_system.yield_tick.is_connected(y):
		economy_system.yield_tick.connect(y)


func _on_resources_changed(owner_id: int, _snapshot: Dictionary) -> void:
	if int(owner_id) != CardfrontRulesScript.PLAYER_FACTION:
		return
	refresh()


func _on_yield_tick(owner_id: int, yield_data: Dictionary) -> void:
	if int(owner_id) != CardfrontRulesScript.PLAYER_FACTION:
		return
	var total: Dictionary = yield_data.get("total_yield", {})
	var energy_yield: int = int(total.get("energy", 0))
	var parts_yield: int = int(total.get("parts", 0))
	if _yield_label != null and is_instance_valid(_yield_label):
		if energy_yield > 0 or parts_yield > 0:
			_yield_label.text = "+%d⚡/s | +%d⚙/s" % [energy_yield, parts_yield]
		else:
			_yield_label.text = "本秒无产出"


func refresh(force: bool = false) -> void:
	var state = resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	if state == null:
		return
	var e := int(state.energy)
	var p := int(state.parts)
	if force or e != last_energy:
		if _energy_value != null and is_instance_valid(_energy_value):
			_energy_value.text = str(e)
		last_energy = e
	if force or p != last_parts:
		if _parts_value != null and is_instance_valid(_parts_value):
			_parts_value.text = str(p)
		last_parts = p
