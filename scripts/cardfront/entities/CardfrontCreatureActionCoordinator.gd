extends RefCounted
class_name CardfrontCreatureActionCoordinator

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")

var runtime = null
var _repaired_cells_this_round: Dictionary = {}


func setup(new_runtime) -> void:
	runtime = new_runtime


func begin_round() -> void:
	_repaired_cells_this_round.clear()


func spawn_repair_units(owner_id: int, amount: int = 2) -> Array:
	var spawned: Array = []
	for index in range(maxi(0, int(amount))):
		var spawn_cell: Vector2i = find_owner_spawn_cell(owner_id, index)
		var creature = runtime.registry.spawn_creature(
			runtime._next_entity_id("repair"),
			runtime.CREATURE_REPAIR_UNIT,
			owner_id,
			spawn_cell,
			1,
			CreatureStateScript.ARMOR_NORMAL,
			1,
			"repair_frontline",
			3
		)
		if creature == null:
			continue
		_set_action_feedback(creature, "下轮行动")
		spawned.append(creature)
		runtime.entity_spawned.emit(
			creature.entity_id,
			creature.entity_kind,
			creature.owner_id,
			creature.cell
		)
	runtime._mark_visuals_dirty()
	return spawned


func spawn_armored_guard(owner_id: int):
	var spawn_cell: Vector2i = find_owner_spawn_cell(owner_id, 0)
	var guard = runtime.registry.spawn_creature(
		runtime._next_entity_id("guard"),
		runtime.CREATURE_ARMORED_GUARD,
		owner_id,
		spawn_cell,
		4,
		CreatureStateScript.ARMOR_ARMORED,
		1,
		"guard_frontline",
		-1
	)
	if guard != null:
		_set_action_feedback(guard, "下轮行动")
		runtime.entity_spawned.emit(guard.entity_id, guard.entity_kind, guard.owner_id, guard.cell)
	runtime._mark_visuals_dirty()
	return guard


func spawn_sapper_unit(owner_id: int):
	var spawn_cell: Vector2i = find_owner_spawn_cell(owner_id, 1)
	var sapper = runtime.registry.spawn_creature(
		runtime._next_entity_id("sapper"),
		runtime.CREATURE_SAPPER_UNIT,
		owner_id,
		spawn_cell,
		3,
		CreatureStateScript.ARMOR_ARMORED,
		1,
		"sapper_assault",
		-1
	)
	if sapper != null:
		_set_action_feedback(sapper, "下轮行动")
		runtime.entity_spawned.emit(sapper.entity_id, sapper.entity_kind, sapper.owner_id, sapper.cell)
	runtime._mark_visuals_dirty()
	return sapper


func run_actions() -> void:
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity == null
			or not entity.is_alive()
			or str(entity.entity_kind) != BattlefieldEntityScript.KIND_CREATURE
			or not entity.can_act()
		):
			continue
		if (
			int(entity.owner_id) == RulesScript.NEUTRAL_OWNER
			and str(entity.behavior_type) == "neutral_gate_colossus"
		):
			runtime._neutral_creature_system.run(entity)
			continue
		match str(entity.behavior_type):
			"repair_frontline":
				run_repair_unit(entity)
			"guard_frontline":
				run_armored_guard(entity)
			"sapper_assault":
				run_sapper_unit(entity)


func run_repair_unit(creature) -> void:
	var target: Vector2i = find_nearest_repairable_frontline(creature.owner_id, creature.cell)
	if target.x < 0:
		_run_repair_frontline_support(creature)
		return
	if runtime._manhattan_distance(creature.cell, target) <= 1 and repair_frontline_cell(creature, target):
		_set_action_feedback(creature, "修复前线 +1")
		return
	var next_cell: Vector2i = next_owned_step_toward(creature.owner_id, creature.cell, target)
	if next_cell != creature.cell:
		runtime.registry.move_entity(creature.entity_id, next_cell)
		_set_action_feedback(creature, "前往受损前线")
	else:
		_set_action_feedback(creature, "前线路径受阻")


func _run_repair_frontline_support(creature) -> void:
	var target: Vector2i = find_nearest_guard_post(creature.owner_id, creature.cell)
	if target.x < 0:
		_set_action_feedback(creature, "等待争夺前线")
		return
	if target == creature.cell:
		_set_action_feedback(creature, "支援争夺")
		return
	var next_cell: Vector2i = next_owned_step_toward(creature.owner_id, creature.cell, target)
	if next_cell != creature.cell:
		runtime.registry.move_entity(creature.entity_id, next_cell)
		_set_action_feedback(creature, "支援前线")
	else:
		_set_action_feedback(creature, "支援路径受阻")


func run_armored_guard(creature) -> void:
	var target: Vector2i = find_nearest_guard_post(creature.owner_id, creature.cell)
	if target.x < 0:
		_set_action_feedback(creature, "等待争夺前线")
		return
	if target == creature.cell:
		_set_action_feedback(creature, "驻守前线")
		return
	var next_cell: Vector2i = next_owned_step_toward(creature.owner_id, creature.cell, target)
	if next_cell != creature.cell:
		runtime.registry.move_entity(creature.entity_id, next_cell)
		_set_action_feedback(creature, "向前线推进")
	else:
		_set_action_feedback(creature, "驻守路径受阻")


func run_sapper_unit(creature) -> void:
	var target: Dictionary = runtime._sapper_system.find_target(creature.owner_id, creature.cell)
	var before_cell: Vector2i = creature.cell
	runtime._sapper_system.run(creature)
	if creature == null or not creature.is_alive():
		return
	if target.is_empty():
		_set_action_feedback(creature, "等待爆破目标")
	elif creature.cell != before_cell:
		_set_action_feedback(creature, "向%s推进" % _sapper_target_name(str(target.get("kind", ""))))
	else:
		_set_action_feedback(creature, "等待闸门 / 路径受阻")


func _set_action_feedback(creature, text: String) -> void:
	if creature == null:
		return
	creature.metadata["action_feedback"] = str(text)


func _sapper_target_name(target_kind: String) -> String:
	match target_kind:
		"defense_tower":
			return "敌塔"
		"territory_defense":
			return "防线"
		_:
			return "指挥室"


func repair_frontline_cell(creature, cell: Vector2i) -> bool:
	var key: String = runtime._cell_key(cell)
	if _repaired_cells_this_round.has(key):
		return false
	if (
		runtime.territory_defense_system == null
		or not is_instance_valid(runtime.territory_defense_system)
	):
		return false
	var cap: int = runtime.territory_defense_system.get_owner_cap(creature.owner_id)
	var current: int = runtime.territory_defense_system.get_cell_defense(cell)
	if cap <= 0 or current >= cap:
		return false
	var fortify_layer = runtime.territory_defense_system.fortify_layer
	if fortify_layer == null:
		return false
	fortify_layer.add_fortify_stack(cell, 1)
	_repaired_cells_this_round[key] = true
	runtime.creature_repaired.emit(creature.entity_id, cell, 1)
	return true


func has_owner_creature_id(owner_id: int, creature_id: String) -> bool:
	return find_owner_creature_id(owner_id, creature_id) != null


func find_owner_creature_id(owner_id: int, creature_id: String):
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE
			and int(entity.owner_id) == int(owner_id)
			and str(entity.creature_id) == str(creature_id)
		):
			return entity
	return null


func push_creature(creature, projectile_direction: Vector2, distance: int) -> bool:
	var step := Vector2i.ZERO
	if absf(projectile_direction.x) >= absf(projectile_direction.y):
		step.x = 1 if projectile_direction.x >= 0.0 else -1
	else:
		step.y = 1 if projectile_direction.y >= 0.0 else -1
	if step == Vector2i.ZERO:
		step = Vector2i.UP
	var current: Vector2i = creature.cell
	var moved: bool = false
	for _index in range(maxi(0, int(distance))):
		var target: Vector2i = current + step
		if not runtime.battlefield.is_inside(target):
			break
		if not runtime.registry.move_entity(creature.entity_id, target):
			break
		current = target
		moved = true
	return moved


func find_nearest_repairable_frontline(owner_id: int, origin: Vector2i) -> Vector2i:
	if (
		runtime.territory_defense_system == null
		or not is_instance_valid(runtime.territory_defense_system)
	):
		return Vector2i(-1, -1)
	var cap: int = runtime.territory_defense_system.get_owner_cap(owner_id)
	var best := Vector2i(-1, -1)
	var best_distance: int = 1 << 30
	for x in range(int(runtime.battlefield.grid_extent.x)):
		for y in range(int(runtime.battlefield.grid_extent.y)):
			var cell := Vector2i(x, y)
			if int(runtime.battlefield.owners[x][y]) != int(owner_id):
				continue
			if (
				runtime.territory_defense_system.get_cell_defense(cell) >= cap
				or not is_frontline_cell(cell, owner_id)
			):
				continue
			var distance: int = runtime._manhattan_distance(origin, cell)
			if distance < best_distance:
				best = cell
				best_distance = distance
	return best


func find_nearest_guard_post(owner_id: int, origin: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var width: int = int(runtime.battlefield.grid_extent.x)
	var height: int = int(runtime.battlefield.grid_extent.y)
	var river_y: int = height >> 1
	var gate_y: int = river_y - 1 if int(owner_id) == RulesScript.AI_FACTION else river_y
	var lanes: Array = (
		(runtime.map_definition.get("route_layout", {}) as Dictionary).get("lanes", [])
		as Array
	)
	if lanes.size() < 2:
		lanes = [{"center_ratio": 0.30}, {"center_ratio": 0.70}]
	for lane in lanes:
		var gate_x: int = clampi(
			roundi(float(width - 1) * float((lane as Dictionary).get("center_ratio", 0.5))),
			0,
			width - 1
		)
		var gate_cell := Vector2i(gate_x, gate_y)
		if (
			runtime.battlefield.is_inside(gate_cell)
			and int(runtime.battlefield.owners[gate_cell.x][gate_cell.y]) == int(owner_id)
		):
			candidates.append(gate_cell)
	for x in range(width):
		for y in range(height):
			var cell := Vector2i(x, y)
			if (
				int(runtime.battlefield.owners[x][y]) == int(owner_id)
				and is_frontline_cell(cell, owner_id)
			):
				candidates.append(cell)
	var best := Vector2i(-1, -1)
	var best_distance: int = 1 << 30
	for candidate in candidates:
		var distance: int = runtime._manhattan_distance(origin, candidate)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func command_chamber_cell(owner_id: int) -> Vector2i:
	return runtime._sapper_system.command_chamber_cell(owner_id)


func next_owned_step_toward(owner_id: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_distance: int = runtime._manhattan_distance(origin, target)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if not runtime.battlefield.is_inside(candidate):
			continue
		if int(runtime.battlefield.owners[candidate.x][candidate.y]) != int(owner_id):
			continue
		var occupied_slots: int = 0
		for entity in runtime.registry.get_entities_at(candidate):
			if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
				occupied_slots += maxi(1, int(entity.size_slots))
		if occupied_slots >= RegistryScript.MAX_CREATURE_SLOTS_PER_CELL:
			continue
		var distance: int = runtime._manhattan_distance(candidate, target)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func is_frontline_cell(cell: Vector2i, owner_id: int) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + offset
		if (
			runtime.battlefield.is_inside(neighbor)
			and int(runtime.battlefield.owners[neighbor.x][neighbor.y]) != int(owner_id)
		):
			return true
	return false


func find_owner_spawn_cell(owner_id: int, index: int) -> Vector2i:
	var lane_index: int = index % 2
	var slot: Dictionary = runtime.registry.building_slots.get(
		runtime._route_slot_id(owner_id, lane_index),
		{}
	) as Dictionary
	var origin: Vector2i = slot.get("cell", Vector2i.ZERO) as Vector2i
	return find_adjacent_spawn_cell(owner_id, origin)


func find_adjacent_spawn_cell(owner_id: int, origin: Vector2i) -> Vector2i:
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if not runtime.battlefield.is_inside(candidate):
			continue
		if int(runtime.battlefield.owners[candidate.x][candidate.y]) != int(owner_id):
			continue
		if runtime.registry.get_entities_at(candidate).size() < 2:
			return candidate
	return origin
