extends Node
class_name EconomyTickSystem

signal resources_changed(owner_id, snapshot)
signal yield_tick(owner_id, yield_data)

const RegionYieldCalculatorScript = preload("res://scripts/cardfront/economy/RegionYieldCalculator.gd")

var tick_interval: float = 1.0
var region_map = null
var battlefield = null
var resource_states: Dictionary = {}
var _elapsed: float = 0.0


func _init() -> void:
	name = "EconomyTickSystem"


func setup(new_region_map, new_battlefield, new_resource_states: Dictionary) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	resource_states = new_resource_states.duplicate(false)
	_elapsed = 0.0
	set_process(true)


func tick_once() -> void:
	if region_map == null or battlefield == null:
		return
	for owner_id in resource_states.keys():
		var state = get_resource_state(int(owner_id))
		if state == null:
			continue
		var yield_data: Dictionary = RegionYieldCalculatorScript.calculate_for_owner(region_map, battlefield, int(owner_id))
		var total_yield: Dictionary = yield_data.get("total_yield", {})
		state.add_energy(int(total_yield.get("energy", 0)))
		state.add_parts(int(total_yield.get("parts", 0)))
		yield_tick.emit(int(owner_id), yield_data)
		resources_changed.emit(int(owner_id), state.snapshot())


func _process(delta: float) -> void:
	if tick_interval <= 0.0:
		return
	_elapsed += maxf(0.0, delta)
	while _elapsed >= tick_interval:
		_elapsed -= tick_interval
		tick_once()


func get_resource_state(owner_id: int):
	return resource_states.get(owner_id, null)
