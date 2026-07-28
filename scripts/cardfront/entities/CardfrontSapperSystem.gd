extends RefCounted
class_name CardfrontSapperSystem

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")

var runtime = null


func setup(new_runtime) -> void:
	runtime = new_runtime


func run(creature) -> void:
	if runtime == null or creature == null or not creature.is_alive():
		return
	var target: Dictionary = find_target(creature.owner_id, creature.cell)
	if target.is_empty():
		return
	var target_cell: Vector2i = target.get("cell", creature.cell) as Vector2i
	if target_cell != creature.cell:
		var navigation_target: Vector2i = _navigation_target(
			creature.owner_id,
			creature.cell,
			target_cell
		)
		var next_cell: Vector2i = _next_step_toward(
			creature.owner_id,
			creature.cell,
			navigation_target
		)
		if next_cell != creature.cell:
			runtime.registry.move_entity(creature.entity_id, next_cell)
	if creature.cell == target_cell:
		resolve_target(creature, target)


func find_target(owner_id: int, origin: Vector2i) -> Dictionary:
	var opponent_id: int = (
		RulesScript.AI_FACTION
		if int(owner_id) == RulesScript.PLAYER_FACTION
		else RulesScript.PLAYER_FACTION
	)
	var enemy_towers: Array = runtime._owner_towers(opponent_id)
	if not enemy_towers.is_empty():
		enemy_towers.sort_custom(func(left, right) -> bool:
			return _distance(origin, left.cell) < _distance(origin, right.cell)
		)
		var tower = enemy_towers[0]
		return {
			"kind": "defense_tower",
			"cell": tower.cell,
			"entity_id": str(tower.entity_id),
		}

	var defense_target: Vector2i = _find_highest_defense_cell(opponent_id, origin)
	if defense_target.x >= 0:
		return {"kind": "territory_defense", "cell": defense_target}

	return {
		"kind": "command_chamber",
		"cell": command_chamber_cell(opponent_id),
		"owner_id": opponent_id,
	}


func resolve_target(creature, target: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"owner_id": int(creature.owner_id),
		"target_kind": str(target.get("kind", "")),
		"cell": target.get("cell", creature.cell) as Vector2i,
		"damage": 0,
	}
	var target_cell: Vector2i = result["cell"] as Vector2i
	match str(result["target_kind"]):
		"defense_tower":
			var tower = runtime.registry.get_entity(str(target.get("entity_id", "")))
			if tower == null or not tower.is_alive():
				return result
			result["damage"] = tower.apply_damage(3)
		"territory_defense":
			if (
				runtime.territory_defense_system == null
				or not is_instance_valid(runtime.territory_defense_system)
				or runtime.territory_defense_system.fortify_layer == null
			):
				return result
			var removed: int = 0
			for _index in range(2):
				if not runtime.territory_defense_system.fortify_layer.consume_hit(target_cell):
					break
				removed += 1
			result["damage"] = removed
		"command_chamber":
			var chamber = _command_chamber_for_owner(int(target.get("owner_id", -1)))
			if chamber == null or not chamber.has_method("take_damage"):
				return result
			chamber.take_damage(1)
			result["damage"] = 1
		_:
			return result
	creature.active = false
	runtime.emit_signal(
		"sapper_detonated",
		int(creature.owner_id),
		str(result["target_kind"]),
		target_cell,
		int(result["damage"])
	)
	runtime._cleanup_dead_entities()
	runtime._mark_visuals_dirty()
	return result


func command_chamber_cell(owner_id: int) -> Vector2i:
	var slot: Dictionary = runtime.registry.building_slots.get(
		"%d_chamber_facility" % int(owner_id),
		{}
	) as Dictionary
	return slot.get("cell", Vector2i.ZERO) as Vector2i


func _find_highest_defense_cell(owner_id: int, origin: Vector2i) -> Vector2i:
	if (
		runtime.territory_defense_system == null
		or not is_instance_valid(runtime.territory_defense_system)
	):
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_defense: int = 0
	var best_distance: int = 1 << 30
	for x in range(int(runtime.battlefield.grid_size)):
		for y in range(int(runtime.battlefield.grid_size)):
			if int(runtime.battlefield.owners[x][y]) != int(owner_id):
				continue
			var cell := Vector2i(x, y)
			var defense: int = runtime.territory_defense_system.get_cell_defense(cell)
			var distance: int = _distance(origin, cell)
			if defense > best_defense or (defense == best_defense and defense > 0 and distance < best_distance):
				best = cell
				best_defense = defense
				best_distance = distance
	return best


func _navigation_target(owner_id: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	var river_y: int = int(runtime.battlefield.grid_size) >> 1
	var origin_top: bool = origin.y < river_y
	var target_top: bool = target.y < river_y
	if origin_top == target_top:
		return target
	var source_y: int = river_y - 1 if origin_top else river_y
	var destination_y: int = river_y if origin_top else river_y - 1
	var best_source := Vector2i(-1, -1)
	var best_destination := Vector2i(-1, -1)
	var best_lane_index: int = -1
	var best_distance: int = 1 << 30
	for lane_index in range(2):
		var gate_x: int = _gate_x(lane_index)
		var source := Vector2i(gate_x, source_y)
		var destination := Vector2i(gate_x, destination_y)
		var distance: int = _distance(origin, source) + _distance(destination, target)
		if distance < best_distance:
			best_source = source
			best_destination = destination
			best_lane_index = lane_index
			best_distance = distance
	if best_source.x < 0:
		return origin
	if origin != best_source:
		return best_source
	return best_destination if _gate_allows(owner_id, best_lane_index) else origin


func _next_step_toward(owner_id: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_distance: int = _distance(origin, target)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if (
			not runtime.battlefield.is_inside(candidate)
			or not _crossing_allowed(owner_id, origin, candidate)
		):
			continue
		var occupied_slots: int = 0
		for entity in runtime.registry.get_entities_at(candidate):
			if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
				occupied_slots += maxi(1, int(entity.size_slots))
		if occupied_slots >= RegistryScript.MAX_CREATURE_SLOTS_PER_CELL:
			continue
		var distance: int = _distance(candidate, target)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _crossing_allowed(owner_id: int, origin: Vector2i, candidate: Vector2i) -> bool:
	var river_y: int = int(runtime.battlefield.grid_size) >> 1
	if not (
		(origin.y == river_y - 1 and candidate.y == river_y)
		or (origin.y == river_y and candidate.y == river_y - 1)
	):
		return true
	for lane_index in range(2):
		var gate_x: int = _gate_x(lane_index)
		if origin.x == gate_x and candidate.x == gate_x:
			return _gate_allows(owner_id, lane_index)
	return false


func _gate_allows(owner_id: int, lane_index: int) -> bool:
	if (
		runtime.round_director == null
		or not is_instance_valid(runtime.round_director)
		or runtime.round_director.gate_connectivity_system == null
		or not is_instance_valid(runtime.round_director.gate_connectivity_system)
	):
		return true
	var state: Dictionary = runtime.round_director.gate_connectivity_system.get_lane_state(lane_index)
	var state_id: String = str(state.get("state", "open"))
	var gate_owner: int = int(state.get("owner_id", RulesScript.NEUTRAL_OWNER))
	return state_id != "closed" or gate_owner == int(owner_id)


func _gate_x(lane_index: int) -> int:
	return clampi(
		roundi(
			float(int(runtime.battlefield.grid_size) - 1)
			* runtime._lane_center_ratio(lane_index)
		),
		0,
		int(runtime.battlefield.grid_size) - 1
	)


func _command_chamber_for_owner(owner_id: int):
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return null
	return runtime.round_director.turrets.get(int(owner_id), null)


func _distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	return absi(from_cell.x - to_cell.x) + absi(from_cell.y - to_cell.y)
