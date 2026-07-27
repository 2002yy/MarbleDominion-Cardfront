extends Node
class_name CardfrontTerritoryDefenseSystem

signal defense_refreshed(owner_caps, defended_cell_count)
signal territory_repaired(owner_id, requested_points, restored_points, zone)

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")

var battlefield = null
var region_map = null
var fortify_layer = null
var round_director = null
var owner_caps: Dictionary = {}
var starting_contact_front_cells: Dictionary = {}
var last_defended_cell_count: int = 0
var _starting_defense_initialized: bool = false


func _init() -> void:
	name = "CardfrontTerritoryDefenseSystem"
	set_process(false)


func setup(new_battlefield, new_region_map, new_fortify_layer, new_round_director) -> bool:
	battlefield = new_battlefield
	region_map = new_region_map
	fortify_layer = new_fortify_layer
	round_director = new_round_director
	starting_contact_front_cells.clear()
	_starting_defense_initialized = false
	if battlefield == null or not is_instance_valid(battlefield):
		return false
	if fortify_layer == null:
		return false
	if round_director == null or not is_instance_valid(round_director):
		return false
	if round_director.has_method("set_territory_defense_system"):
		round_director.set_territory_defense_system(self)
	var interceptor = battlefield.capture_interceptor
	if interceptor != null and interceptor.has_method("configure_runtime"):
		interceptor.configure_runtime(round_director, self)
	var launch_callable := Callable(self, "_on_volley_launched")
	if not round_director.volley_launched.is_connected(launch_callable):
		round_director.volley_launched.connect(launch_callable)
	_sync_caps_from_run_states()
	initialize_starting_defense()
	return true


func apply_pending_repair(owner_id: int, run_state) -> int:
	if run_state == null:
		return 0
	var request: Dictionary = run_state.consume_pending_repair()
	var requested_points: int = maxi(0, int(request.get("points", 0)))
	var zone: String = str(request.get("zone", "frontline"))
	if requested_points <= 0:
		return 0
	owner_caps[int(owner_id)] = clampi(
		int(run_state.territory_defense_cap),
		1,
		TuningScript.MAX_TERRITORY_DEFENSE_CAP
	)
	var restored_points: int = repair_owner(owner_id, requested_points, zone)
	territory_repaired.emit(owner_id, requested_points, restored_points, zone)
	return restored_points


func repair_owner(owner_id: int, amount: int, zone: String = "frontline") -> int:
	if battlefield == null or fortify_layer == null or amount <= 0:
		return 0
	var cap: int = get_owner_cap(owner_id)
	if cap <= 0:
		return 0
	var candidates: Array = _repair_candidates(owner_id, zone, cap)
	var restored: int = 0
	for raw_cell in candidates:
		if restored >= amount:
			break
		var cell: Vector2i = raw_cell
		var current: int = get_cell_defense(cell)
		if current >= cap:
			continue
		fortify_layer.add_fortify_stack(cell, 1)
		restored += 1
	last_defended_cell_count = _count_current_defended_cells()
	return restored


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


func get_starting_contact_front_cells(owner_id: int) -> Array:
	return (starting_contact_front_cells.get(int(owner_id), []) as Array).duplicate()


func get_owner_defense_snapshot(owner_id: int, zone: String = "frontline") -> Dictionary:
	var cap: int = get_owner_cap(owner_id)
	var snapshot: Dictionary = {
		"owner_id": int(owner_id),
		"cap": cap,
		"owned_cell_count": 0,
		"defended_cell_count": 0,
		"cells_at_cap": 0,
		"total_defense_points": 0,
		"repairable_frontline_cells": 0,
	}
	if battlefield == null or not is_instance_valid(battlefield) or fortify_layer == null:
		return snapshot
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			if int(battlefield.owners[x][y]) != int(owner_id):
				continue
			var cell := Vector2i(x, y)
			var defense: int = get_cell_defense(cell)
			snapshot["owned_cell_count"] = int(snapshot["owned_cell_count"]) + 1
			snapshot["total_defense_points"] = int(snapshot["total_defense_points"]) + defense
			if defense > 0:
				snapshot["defended_cell_count"] = int(snapshot["defended_cell_count"]) + 1
			if cap > 0 and defense >= cap:
				snapshot["cells_at_cap"] = int(snapshot["cells_at_cap"]) + 1
	if cap > 0:
		snapshot["repairable_frontline_cells"] = _repair_candidates(owner_id, zone, cap).size()
	return snapshot


func get_repairable_cell_count(owner_id: int, zone: String = "frontline", limit: int = 6) -> int:
	if limit <= 0:
		return 0
	var cap: int = get_owner_cap(owner_id)
	if cap <= 0:
		return 0
	return mini(limit, _repair_candidates(owner_id, zone, cap).size())


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
	last_defended_cell_count = _count_current_defended_cells()
	defense_refreshed.emit(owner_caps.duplicate(), last_defended_cell_count)
	return last_defended_cell_count


func initialize_starting_defense() -> int:
	if _starting_defense_initialized:
		return last_defended_cell_count
	_starting_defense_initialized = true
	starting_contact_front_cells.clear()

	var starting_values: Dictionary = {}
	for owner_id in RulesScript.get_duel_factions():
		var state = round_director.get_run_state(int(owner_id)) if round_director != null else null
		starting_values[int(owner_id)] = clampi(
			int(state.starting_territory_defense) if state != null else 1,
			0,
			get_owner_cap(int(owner_id))
		)

	fortify_layer.refill_from_owner_caps(battlefield.owners, starting_values)
	for owner_id in RulesScript.get_duel_factions():
		var state = round_director.get_run_state(int(owner_id)) if round_director != null else null
		var contact_front_value: int = clampi(
			int(state.starting_contact_front_defense) if state != null else int(starting_values[int(owner_id)]),
			int(starting_values[int(owner_id)]),
			get_owner_cap(int(owner_id))
		)
		var contact_cells: Array = _find_contact_front_cells(int(owner_id))
		starting_contact_front_cells[int(owner_id)] = contact_cells.duplicate()
		if contact_front_value <= int(starting_values[int(owner_id)]):
			continue
		for raw_cell in contact_cells:
			var contact_cell: Vector2i = raw_cell
			fortify_layer.set_fortify_stack(contact_cell, contact_front_value)

	last_defended_cell_count = _count_current_defended_cells()
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


func _count_current_defended_cells() -> int:
	var defended: int = 0
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			if get_cell_defense(Vector2i(x, y)) > 0:
				defended += 1
	return defended


func _find_contact_front_cells(owner_id: int) -> Array:
	var cells: Array = []
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			var cell := Vector2i(x, y)
			if int(battlefield.owners[x][y]) != int(owner_id):
				continue
			if _is_frontline_cell(cell, owner_id):
				cells.append(cell)
	cells.sort_custom(_sort_cells)
	return cells


func _repair_candidates(owner_id: int, zone: String, cap: int) -> Array:
	var preferred: Array = []
	var fallback: Array = []
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			var cell := Vector2i(x, y)
			if int(battlefield.owners[x][y]) != int(owner_id):
				continue
			if get_cell_defense(cell) >= cap:
				continue
			if zone == "frontline" and _is_frontline_cell(cell, owner_id):
				preferred.append(cell)
			else:
				fallback.append(cell)
	preferred.sort_custom(_sort_cells)
	fallback.sort_custom(_sort_cells)
	if zone == "frontline":
		return preferred
	return fallback


func _is_frontline_cell(cell: Vector2i, owner_id: int) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + offset
		if not battlefield.is_inside(neighbor):
			continue
		if int(battlefield.owners[neighbor.x][neighbor.y]) != int(owner_id):
			return true
	return false


func _sort_cells(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y
