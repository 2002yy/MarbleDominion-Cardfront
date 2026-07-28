extends RefCounted
class_name CardfrontNeutralCreatureSystem

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const GateNavigatorScript = preload("res://scripts/cardfront/entities/CardfrontEntityGateNavigator.gd")

const CREATURE_GATE_COLOSSUS: String = "gate_colossus"
const GATE_COLOSSUS_HP: int = 6
const GATE_COLOSSUS_SIZE_SLOTS: int = 2

var runtime = null
var gate_navigator = GateNavigatorScript.new()


func setup(new_runtime) -> void:
	runtime = new_runtime
	gate_navigator.setup(new_runtime)


func spawn(summoner_owner_id: int):
	if runtime == null or _find_by_summoner(summoner_owner_id) != null:
		return null
	for spawn_cell in _spawn_candidates(summoner_owner_id):
		var creature = runtime.registry.spawn_creature(
			runtime._next_entity_id("colossus"),
			CREATURE_GATE_COLOSSUS,
			RulesScript.NEUTRAL_OWNER,
			spawn_cell,
			GATE_COLOSSUS_HP,
			CreatureStateScript.ARMOR_ARMORED,
			1,
			"neutral_gate_colossus",
			-1,
			GATE_COLOSSUS_SIZE_SLOTS
		)
		if creature == null:
			continue
		creature.metadata["summoned_by"] = int(summoner_owner_id)
		runtime.entity_spawned.emit(
			creature.entity_id,
			creature.entity_kind,
			creature.owner_id,
			creature.cell
		)
		runtime._mark_visuals_dirty()
		return creature
	return null


func run(creature) -> void:
	if runtime == null or creature == null or not creature.is_alive():
		return
	var target_faction: int = _leading_faction(creature)
	var target: Dictionary = _find_target(target_faction, creature.cell)
	if target.is_empty():
		return
	var target_cell: Vector2i = target.get("cell", creature.cell) as Vector2i
	if target_cell != creature.cell:
		var navigation_target: Vector2i = gate_navigator.navigation_target(
			RulesScript.NEUTRAL_OWNER,
			creature.cell,
			target_cell,
			true
		)
		var next_cell: Vector2i = gate_navigator.next_step_toward(
			RulesScript.NEUTRAL_OWNER,
			creature.cell,
			navigation_target,
			true
		)
		if next_cell != creature.cell:
			runtime.registry.move_entity(creature.entity_id, next_cell)
	if creature.cell == target_cell:
		_attack_target(creature, target)


func _leading_faction(creature) -> int:
	var owned_counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 0,
		RulesScript.AI_FACTION: 0,
	}
	for x in range(int(runtime.battlefield.grid_size)):
		for y in range(int(runtime.battlefield.grid_size)):
			var owner_id: int = int(runtime.battlefield.owners[x][y])
			if owned_counts.has(owner_id):
				owned_counts[owner_id] = int(owned_counts[owner_id]) + 1
	var player_count: int = int(owned_counts[RulesScript.PLAYER_FACTION])
	var ai_count: int = int(owned_counts[RulesScript.AI_FACTION])
	if player_count > ai_count:
		return RulesScript.PLAYER_FACTION
	if ai_count > player_count:
		return RulesScript.AI_FACTION
	var summoner: int = int(creature.metadata.get("summoned_by", RulesScript.PLAYER_FACTION))
	return (
		RulesScript.AI_FACTION
		if summoner == RulesScript.PLAYER_FACTION
		else RulesScript.PLAYER_FACTION
	)


func _find_target(target_faction: int, origin: Vector2i) -> Dictionary:
	var towers: Array = runtime._owner_towers(target_faction)
	if not towers.is_empty():
		towers.sort_custom(func(left, right) -> bool:
			return _distance(origin, left.cell) < _distance(origin, right.cell)
		)
		var tower = towers[0]
		return {
			"kind": "defense_tower",
			"cell": tower.cell,
			"entity_id": str(tower.entity_id),
			"owner_id": target_faction,
		}
	var defense_cell: Vector2i = _find_highest_defense_cell(target_faction, origin)
	if defense_cell.x >= 0:
		return {
			"kind": "territory_defense",
			"cell": defense_cell,
			"owner_id": target_faction,
		}
	return {
		"kind": "command_chamber",
		"cell": _command_chamber_cell(target_faction),
		"owner_id": target_faction,
	}


func _attack_target(creature, target: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"creature_id": str(creature.entity_id),
		"target_kind": str(target.get("kind", "")),
		"target_owner_id": int(target.get("owner_id", RulesScript.NEUTRAL_OWNER)),
		"cell": target.get("cell", creature.cell) as Vector2i,
		"damage": 0,
	}
	var target_cell: Vector2i = result["cell"] as Vector2i
	match str(result["target_kind"]):
		"defense_tower":
			var tower = runtime.registry.get_entity(str(target.get("entity_id", "")))
			if tower == null or not tower.is_alive():
				return result
			result["damage"] = tower.apply_damage(2)
		"territory_defense":
			if (
				runtime.territory_defense_system == null
				or not is_instance_valid(runtime.territory_defense_system)
				or runtime.territory_defense_system.fortify_layer == null
			):
				return result
			result["damage"] = (
				1
				if runtime.territory_defense_system.fortify_layer.consume_hit(target_cell)
				else 0
			)
		"command_chamber":
			var chamber = _command_chamber_for_owner(int(result["target_owner_id"]))
			if chamber == null or not chamber.has_method("take_damage"):
				return result
			chamber.take_damage(1)
			result["damage"] = 1
		_:
			return result
	runtime.emit_signal("neutral_creature_attacked", result.duplicate(true))
	runtime._cleanup_dead_entities()
	runtime._mark_visuals_dirty()
	return result


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


func _spawn_candidates(summoner_owner_id: int) -> Array[Vector2i]:
	var river_y: int = int(runtime.battlefield.grid_size) >> 1
	var preferred_lane: int = 0 if summoner_owner_id == RulesScript.PLAYER_FACTION else 1
	var preferred_y: int = river_y if summoner_owner_id == RulesScript.PLAYER_FACTION else river_y - 1
	var result: Array[Vector2i] = []
	for lane_offset in range(2):
		var lane_index: int = (preferred_lane + lane_offset) % 2
		var x: int = gate_navigator.gate_x(lane_index)
		result.append(Vector2i(x, preferred_y))
		result.append(Vector2i(x, river_y - 1 if preferred_y == river_y else river_y))
	return result


func _find_by_summoner(summoner_owner_id: int):
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and str(entity.entity_kind) == "creature"
			and str(entity.creature_id) == CREATURE_GATE_COLOSSUS
			and int(entity.metadata.get("summoned_by", -999)) == int(summoner_owner_id)
		):
			return entity
	return null


func _command_chamber_cell(owner_id: int) -> Vector2i:
	var slot: Dictionary = runtime.registry.building_slots.get(
		"%d_chamber_facility" % int(owner_id),
		{}
	) as Dictionary
	return slot.get("cell", Vector2i.ZERO) as Vector2i


func _command_chamber_for_owner(owner_id: int):
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return null
	return runtime.round_director.turrets.get(int(owner_id), null)


func _distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	return absi(from_cell.x - to_cell.x) + absi(from_cell.y - to_cell.y)
