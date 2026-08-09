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
		runtime.entity_spawned.emit(sapper.entity_id, sapper.entity_kind, sapper.owner_id, sapper.cell)
	runtime._mark_visuals_dirty()
	return sapper


func spawn_repair_units(_owner_id: int, _amount: int = 2) -> Array:
	push_error("Automatic creature spawning requires pre-resolved DeploymentRules cells")
	return []


func spawn_armored_guard(_owner_id: int):
	push_error("Automatic creature spawning requires a pre-resolved DeploymentRules cell")
	return null


func spawn_sapper_unit(_owner_id: int):
	push_error("Automatic creature spawning requires a pre-resolved DeploymentRules cell")
	return null
