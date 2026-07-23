extends Node
class_name CardfrontTerritoryDefenseSystem

signal defense_refreshed(owner_caps, defended_cell_count)

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")

var battlefield = null
var region_map = null
var fortify_layer = null
var round_director = null
var owner_caps: Dictionary = {}
var last_defended_cell_count: int = 0


func _init() -> void:
	name = "CardfrontTerritoryDefenseSystem"
	set_process(false)


func setup(new_battlefield, new_region_map, new_fortify_layer, new_round_director) -> bool:
	battlefield = new_battlefield
	region_map = new_region_map
	fortify_layer = new_fortify_layer
	round_director = new_round_director
	if battlefield == null or not is_instance_valid(battlefield):
		return false
	if fortify_layer == null:
		return false
	if round_director == null or not is_instance_valid(round_director):
		return false
	var launch_callable := Callable(self, "_on_volley_launched")
	if not round_director.volley_launched.is_connected(launch_callable):
		round_director.volley_launched.connect(launch_callable)
	_sync_caps_from_run_states()
	return true


func get_owner_cap(owner_id: int) -> int:
	return clampi(
		int(owner_caps.get(int(owner_id), 0)),
		0,
		TuningScript.MAX_TERRITORY_DEFENSE_CAP
	)


func get_cell_defense(cell: Vector2i) -> int:
	if fortify_layer == null:
		return 0
	return int(fortify_layer.get_fortify_stack(cell))


func get_region_defense_summary(region_id: int, owner_id: int) -> Dictionary:
	var cap: int = get_owner_cap(owner_id)
	if region_map == null or not region_map.has_method("get_region_cells"):
		return {"cap": cap, "average": 0.0, "defended_cells": 0, "owned_cells": 0}
	var total_defense: int = 0
	var defended_cells: int = 0
	var owned_cells: int = 0
	for raw_cell in region_map.get_region_cells(region_id):
		var cell: Vector2i = raw_cell
		if not battlefield.is_inside(cell):
			continue
		if int(battlefield.owners[cell.x][cell.y]) != int(owner_id):
			continue
		owned_cells += 1
		var defense: int = get_cell_defense(cell)
		total_defense += defense
		if defense > 0:
			defended_cells += 1
	return {
		"cap": cap,
		"average": float(total_defense) / float(maxi(1, owned_cells)),
		"defended_cells": defended_cells,
		"owned_cells": owned_cells,
	}


func refresh_territory_defense(plans: Dictionary = {}) -> int:
	if not plans.is_empty():
		for owner_id in RulesScript.get_duel_factions():
			var plan = plans.get(int(owner_id), null)
			if plan != null:
				owner_caps[int(owner_id)] = clampi(
					int(plan.territory_defense_cap),
					1,
					TuningScript.MAX_TERRITORY_DEFENSE_CAP
				)
	else:
		_sync_caps_from_run_states()
	last_defended_cell_count = int(fortify_layer.refill_from_owner_caps(
		battlefield.owners,
		owner_caps
	))
	defense_refreshed.emit(owner_caps.duplicate(), last_defended_cell_count)
	return last_defended_cell_count


func _sync_caps_from_run_states() -> void:
	owner_caps.clear()
	for owner_id in RulesScript.get_duel_factions():
		var state = round_director.get_run_state(int(owner_id)) if round_director != null else null
		owner_caps[int(owner_id)] = clampi(
			int(state.territory_defense_cap) if state != null else 1,
			1,
			TuningScript.MAX_TERRITORY_DEFENSE_CAP
		)


func _on_volley_launched(plans: Dictionary, _issued_intents: Dictionary) -> void:
	refresh_territory_defense(plans)
