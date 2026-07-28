extends RefCounted
class_name CardfrontBattlefieldEntityRegistry

const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const DefenseTowerStateScript = preload("res://scripts/cardfront/entities/CardfrontDefenseTowerState.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")

const MAX_CREATURES_PER_FACTION: int = 3
const MAX_DEFENSE_TOWERS_PER_FACTION: int = 2
const MAX_CREATURE_SLOTS_PER_CELL: int = 2

var entities_by_id: Dictionary = {}
var entity_ids_by_cell: Dictionary = {}
var building_slots: Dictionary = {}


func clear() -> void:
	entities_by_id.clear()
	entity_ids_by_cell.clear()
	building_slots.clear()


func register_building_slot(slot_id: String, cell: Vector2i, slot_kind: String = "defense_tower") -> bool:
	var safe_id: String = str(slot_id)
	if safe_id == "" or building_slots.has(safe_id):
		return false
	building_slots[safe_id] = {
		"slot_id": safe_id,
		"cell": cell,
		"slot_kind": str(slot_kind),
		"entity_id": "",
	}
	return true


func spawn_creature(
	entity_id: String,
	creature_id: String,
	owner_id: int,
	cell: Vector2i,
	max_hp: int,
	armor_type: String = "normal",
	movement: int = 1,
	behavior_type: String = "hold_frontline",
	rounds_remaining: int = -1,
	size_slots: int = 1
):
	if not _can_register_entity(entity_id):
		return null
	if owner_id >= 0 and count_owner_entities(owner_id, BattlefieldEntityScript.KIND_CREATURE) >= MAX_CREATURES_PER_FACTION:
		return null
	var safe_size_slots: int = clampi(int(size_slots), 1, MAX_CREATURE_SLOTS_PER_CELL)
	if _creature_slots_at(cell) + safe_size_slots > MAX_CREATURE_SLOTS_PER_CELL:
		return null
	var creature = CreatureStateScript.new()
	creature.setup_creature(
		entity_id,
		creature_id,
		owner_id,
		cell,
		max_hp,
		armor_type,
		movement,
		behavior_type,
		rounds_remaining
	)
	creature.size_slots = safe_size_slots
	_register_entity(creature)
	return creature


func spawn_defense_tower(
	entity_id: String,
	tower_id: String,
	owner_id: int,
	slot_id: String,
	max_hp: int
):
	if not _can_register_entity(entity_id):
		return null
	if owner_id >= 0 and count_owner_entities(owner_id, BattlefieldEntityScript.KIND_DEFENSE_TOWER) >= MAX_DEFENSE_TOWERS_PER_FACTION:
		return null
	var safe_slot_id: String = str(slot_id)
	if not building_slots.has(safe_slot_id):
		return null
	var slot: Dictionary = building_slots[safe_slot_id] as Dictionary
	if str(slot.get("slot_kind", "")) != "defense_tower" or str(slot.get("entity_id", "")) != "":
		return null
	var tower = DefenseTowerStateScript.new()
	tower.setup_tower(
		entity_id,
		tower_id,
		owner_id,
		slot.get("cell", Vector2i.ZERO) as Vector2i,
		max_hp,
		safe_slot_id
	)
	_register_entity(tower)
	slot["entity_id"] = str(entity_id)
	building_slots[safe_slot_id] = slot
	return tower


func move_entity(entity_id: String, target_cell: Vector2i) -> bool:
	var entity = get_entity(entity_id)
	if entity == null or not entity.is_alive():
		return false
	if entity.entity_kind == BattlefieldEntityScript.KIND_CREATURE:
		var occupied_slots: int = _creature_slots_at(target_cell)
		if entity.cell != target_cell and occupied_slots + maxi(1, int(entity.size_slots)) > MAX_CREATURE_SLOTS_PER_CELL:
			return false
	_remove_cell_index(entity.entity_id, entity.cell)
	entity.cell = target_cell
	_add_cell_index(entity.entity_id, target_cell)
	return true


func remove_entity(entity_id: String) -> bool:
	var safe_id: String = str(entity_id)
	var entity = entities_by_id.get(safe_id, null)
	if entity == null:
		return false
	_remove_cell_index(safe_id, entity.cell)
	if entity.entity_kind == BattlefieldEntityScript.KIND_DEFENSE_TOWER:
		var slot_id: String = str(entity.building_slot_id)
		if building_slots.has(slot_id):
			var slot: Dictionary = building_slots[slot_id] as Dictionary
			slot["entity_id"] = ""
			building_slots[slot_id] = slot
	entities_by_id.erase(safe_id)
	return true


func get_entity(entity_id: String):
	return entities_by_id.get(str(entity_id), null)


func get_entities_at(cell: Vector2i) -> Array:
	var result: Array = []
	for entity_id in entity_ids_by_cell.get(cell, []):
		var entity = entities_by_id.get(str(entity_id), null)
		if entity != null and entity.is_alive():
			result.append(entity)
	return result


func get_collision_targets(cell: Vector2i, incoming_owner_id: int) -> Array:
	var creatures: Array = []
	var towers: Array = []
	var others: Array = []
	for entity in get_entities_at(cell):
		if int(entity.owner_id) == int(incoming_owner_id):
			continue
		match str(entity.entity_kind):
			BattlefieldEntityScript.KIND_CREATURE:
				creatures.append(entity)
			BattlefieldEntityScript.KIND_DEFENSE_TOWER:
				towers.append(entity)
			_:
				others.append(entity)
	var result: Array = []
	result.append_array(creatures)
	result.append_array(towers)
	result.append_array(others)
	return result


func count_owner_entities(owner_id: int, entity_kind: String = "") -> int:
	var count: int = 0
	for entity in entities_by_id.values():
		if not entity.is_alive() or int(entity.owner_id) != int(owner_id):
			continue
		if entity_kind != "" and str(entity.entity_kind) != str(entity_kind):
			continue
		count += 1
	return count


func begin_volley() -> void:
	for entity in entities_by_id.values():
		if entity != null and entity.is_alive() and entity.has_method("begin_volley"):
			entity.begin_volley()


func tick_round() -> void:
	var expired_ids: Array = []
	for entity_id in entities_by_id.keys():
		var entity = entities_by_id[entity_id]
		entity.tick_round()
		if not entity.is_alive():
			expired_ids.append(str(entity_id))
	for entity_id in expired_ids:
		remove_entity(entity_id)


func snapshot() -> Dictionary:
	var entities: Array = []
	var ids: Array = entities_by_id.keys()
	ids.sort()
	for entity_id in ids:
		entities.append(entities_by_id[entity_id].snapshot())
	return {
		"entities": entities,
		"building_slots": building_slots.duplicate(true),
	}


func _can_register_entity(entity_id: String) -> bool:
	var safe_id: String = str(entity_id)
	return safe_id != "" and not entities_by_id.has(safe_id)


func _register_entity(entity) -> void:
	entities_by_id[str(entity.entity_id)] = entity
	_add_cell_index(str(entity.entity_id), entity.cell)


func _add_cell_index(entity_id: String, cell: Vector2i) -> void:
	var ids: Array = (entity_ids_by_cell.get(cell, []) as Array).duplicate()
	if str(entity_id) not in ids:
		ids.append(str(entity_id))
	entity_ids_by_cell[cell] = ids


func _remove_cell_index(entity_id: String, cell: Vector2i) -> void:
	if not entity_ids_by_cell.has(cell):
		return
	var ids: Array = (entity_ids_by_cell[cell] as Array).duplicate()
	ids.erase(str(entity_id))
	if ids.is_empty():
		entity_ids_by_cell.erase(cell)
	else:
		entity_ids_by_cell[cell] = ids


func _creature_slots_at(cell: Vector2i) -> int:
	var total: int = 0
	for entity in get_entities_at(cell):
		if entity.entity_kind == BattlefieldEntityScript.KIND_CREATURE:
			total += maxi(1, int(entity.size_slots))
	return total
