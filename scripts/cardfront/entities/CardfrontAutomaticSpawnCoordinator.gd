extends RefCounted
class_name CardfrontAutomaticSpawnCoordinator

const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const DeploymentSupportContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const DeploymentPlacementResolverScript = preload("res://scripts/cardfront/deployment/DeploymentPlacementResolver.gd")

const REASON_ALLOWED: String = "allowed"
const REASON_NO_VALID_DEPLOYMENT_SOURCE: String = "no_valid_deployment_source"
const REASON_ENTITY_CAPACITY_REACHED: String = "entity_capacity_reached"
const REASON_ENTITY_SPAWN_FAILED: String = "entity_spawn_failed"

var runtime = null


func setup(new_runtime) -> void:
	runtime = new_runtime


func placement_request_from_action(action: Dictionary) -> Dictionary:
	return {
		"deployment_profile_id": str(action.get("deployment_profile_id", "")),
		"preferred_support_id": str(action.get("preferred_support_id", "")),
		"preferred_route_role": str(action.get("preferred_route_role", "")),
	}


func resolve_cell(
	owner_id: int,
	placement_request: Dictionary = {},
	availability: Callable = Callable()
) -> Dictionary:
	if runtime == null:
		return _failure(0)
	return DeploymentPlacementResolverScript.resolve(
		null,
		runtime.battlefield,
		owner_id,
		_current_deployment_context(owner_id),
		placement_request,
		availability
	)


func resolve_cells(owner_id: int, amount: int, placement_request: Dictionary) -> Dictionary:
	var requested: int = maxi(0, int(amount))
	if requested == 0:
		return {
			"allowed": true,
			"reason": REASON_ALLOWED,
			"cells": [],
			"placements": [],
		}
	var existing_count: int = runtime.registry.count_owner_entities(
		owner_id,
		BattlefieldEntityScript.KIND_CREATURE
	)
	if existing_count + requested > RegistryScript.MAX_CREATURES_PER_FACTION:
		return {
			"allowed": false,
			"reason": REASON_ENTITY_CAPACITY_REACHED,
			"cells": [],
			"placements": [],
		}
	var reserved_slots: Dictionary = {}
	var resolved_cells: Array[Vector2i] = []
	var placements: Array = []
	for _index in range(requested):
		var availability := func(cell: Vector2i) -> bool:
			var key: String = runtime._cell_key(cell)
			return _creature_slots_at(cell) + int(reserved_slots.get(key, 0)) < RegistryScript.MAX_CREATURE_SLOTS_PER_CELL
		var placement: Dictionary = resolve_cell(owner_id, placement_request, availability)
		if not bool(placement.get("allowed", false)):
			return {
				"allowed": false,
				"reason": str(placement.get("reason", REASON_NO_VALID_DEPLOYMENT_SOURCE)),
				"cells": [],
				"placements": [],
			}
		var cell: Vector2i = placement.get("cell", Vector2i(-1, -1)) as Vector2i
		var cell_key: String = runtime._cell_key(cell)
		reserved_slots[cell_key] = int(reserved_slots.get(cell_key, 0)) + 1
		resolved_cells.append(cell)
		placements.append(_placement_trace(placement))
	return {
		"allowed": true,
		"reason": REASON_ALLOWED,
		"cells": resolved_cells,
		"placements": placements,
	}


func spawn_repair_units(
	owner_id: int,
	amount: int,
	placement_request: Dictionary
) -> Dictionary:
	var resolution: Dictionary = resolve_cells(owner_id, amount, placement_request)
	if not bool(resolution.get("allowed", false)):
		resolution["entities"] = []
		return resolution
	var cells: Array = resolution.get("cells", []) as Array
	var entities: Array = runtime._creature_action_coordinator.spawn_repair_units_at(owner_id, cells)
	resolution["entities"] = entities
	if entities.size() != cells.size():
		resolution["allowed"] = false
		resolution["reason"] = REASON_ENTITY_SPAWN_FAILED
	return resolution


func spawn_single_creature(
	owner_id: int,
	creature_id: String,
	placement_request: Dictionary
) -> Dictionary:
	var resolution: Dictionary = resolve_cells(owner_id, 1, placement_request)
	if not bool(resolution.get("allowed", false)):
		resolution["entity"] = null
		return resolution
	var cells: Array = resolution.get("cells", []) as Array
	var cell: Vector2i = cells[0] as Vector2i
	var entity = null
	if creature_id == str(runtime.CREATURE_ARMORED_GUARD):
		entity = runtime._creature_action_coordinator.spawn_armored_guard_at(owner_id, cell)
	elif creature_id == str(runtime.CREATURE_SAPPER_UNIT):
		entity = runtime._creature_action_coordinator.spawn_sapper_unit_at(owner_id, cell)
	else:
		resolution["allowed"] = false
		resolution["reason"] = REASON_ENTITY_SPAWN_FAILED
	resolution["entity"] = entity
	if entity == null:
		resolution["allowed"] = false
		if str(resolution.get("reason", "")) == REASON_ALLOWED:
			resolution["reason"] = REASON_ENTITY_SPAWN_FAILED
	return resolution


func public_spawn_result(action: String, resolution: Dictionary) -> Dictionary:
	var spawned: int = 0
	if resolution.has("entities"):
		spawned = (resolution.get("entities", []) as Array).size()
	elif resolution.get("entity", null) != null:
		spawned = 1
	return {
		"action": action,
		"allowed": bool(resolution.get("allowed", false)),
		"reason": str(resolution.get("reason", REASON_NO_VALID_DEPLOYMENT_SOURCE)),
		"spawned": spawned,
		"placements": (resolution.get("placements", []) as Array).duplicate(true),
	}


func _current_deployment_context(owner_id: int) -> Dictionary:
	if runtime.deployment_context_provider is Callable:
		var provider: Callable = runtime.deployment_context_provider as Callable
		if provider.is_valid():
			var value = provider.call(owner_id)
			return (value as Dictionary).duplicate(true) if value is Dictionary else {}
	return DeploymentSupportContextScript.core_only(runtime.map_definition, owner_id)


func _placement_trace(placement: Dictionary) -> Dictionary:
	return {
		"cell": placement.get("cell", Vector2i(-1, -1)),
		"resolved_support_id": str(placement.get("resolved_support_id", "")),
		"source_kind": str(placement.get("source_kind", "")),
		"deployment_revision": int(placement.get("deployment_revision", 0)),
		"legal_candidate_count": int(placement.get("legal_candidate_count", 0)),
		"reason": str(placement.get("reason", "")),
	}


func _creature_slots_at(cell: Vector2i) -> int:
	var total: int = 0
	for entity in runtime.registry.get_entities_at(cell):
		if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
			total += maxi(1, int(entity.size_slots))
	return total


func _failure(revision: int) -> Dictionary:
	return {
		"allowed": false,
		"reason": REASON_NO_VALID_DEPLOYMENT_SOURCE,
		"cell": Vector2i(-1, -1),
		"resolved_support_id": "",
		"source_kind": "none",
		"legal_candidate_count": 0,
		"deployment_revision": revision,
	}
