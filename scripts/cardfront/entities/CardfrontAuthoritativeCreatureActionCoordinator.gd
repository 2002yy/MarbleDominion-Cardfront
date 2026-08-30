extends "res://scripts/cardfront/entities/CardfrontCreatureActionCoordinator.gd"
class_name CardfrontAuthoritativeCreatureActionCoordinator


func spawn_repair_units_at(owner_id: int, cells: Array) -> Array:
	var spawned: Array = []
	for raw_cell in cells:
		if not raw_cell is Vector2i:
			continue
		var cell: Vector2i = raw_cell as Vector2i
		var creature = runtime.registry.spawn_creature(
			runtime._next_entity_id("repair"),
			runtime.CREATURE_REPAIR_UNIT,
			owner_id,
			cell,
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


func spawn_armored_guard_at(owner_id: int, cell: Vector2i):
	if cell.x < 0 or cell.y < 0:
		return null
	var guard = runtime.registry.spawn_creature(
		runtime._next_entity_id("guard"),
		runtime.CREATURE_ARMORED_GUARD,
		owner_id,
		cell,
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


func spawn_sapper_unit_at(owner_id: int, cell: Vector2i):
	if cell.x < 0 or cell.y < 0:
		return null
	var sapper = runtime.registry.spawn_creature(
		runtime._next_entity_id("sapper"),
		runtime.CREATURE_SAPPER_UNIT,
		owner_id,
		cell,
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


func spawn_repair_units(owner_id: int, amount: int = 2) -> Array:
	if runtime == null or not runtime.has_method("_resolve_spawn_cells"):
		return []
	var resolution: Dictionary = runtime._resolve_spawn_cells(owner_id, amount, {})
	if not bool(resolution.get("allowed", false)):
		return []
	return spawn_repair_units_at(owner_id, resolution.get("cells", []) as Array)


func spawn_armored_guard(owner_id: int):
	if runtime == null or not runtime.has_method("_resolve_spawn_cells"):
		return null
	var resolution: Dictionary = runtime._resolve_spawn_cells(owner_id, 1, {})
	if not bool(resolution.get("allowed", false)):
		return null
	var cells: Array = resolution.get("cells", []) as Array
	if cells.is_empty():
		return null
	return spawn_armored_guard_at(owner_id, cells[0] as Vector2i)


func spawn_sapper_unit(owner_id: int):
	if runtime == null or not runtime.has_method("_resolve_spawn_cells"):
		return null
	var resolution: Dictionary = runtime._resolve_spawn_cells(owner_id, 1, {})
	if not bool(resolution.get("allowed", false)):
		return null
	var cells: Array = resolution.get("cells", []) as Array
	if cells.is_empty():
		return null
	return spawn_sapper_unit_at(owner_id, cells[0] as Vector2i)


func find_owner_spawn_cell(owner_id: int, _index: int) -> Vector2i:
	if runtime == null or not runtime.has_method("resolve_automatic_spawn_cell"):
		return Vector2i(-1, -1)
	var resolution: Dictionary = runtime.resolve_automatic_spawn_cell(owner_id)
	if not bool(resolution.get("allowed", false)):
		return Vector2i(-1, -1)
	return resolution.get("cell", Vector2i(-1, -1)) as Vector2i


func find_adjacent_spawn_cell(owner_id: int, _origin: Vector2i) -> Vector2i:
	return find_owner_spawn_cell(owner_id, 0)
