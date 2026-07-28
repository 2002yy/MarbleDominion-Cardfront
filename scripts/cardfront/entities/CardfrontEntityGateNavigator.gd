extends RefCounted
class_name CardfrontEntityGateNavigator

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")

var runtime = null


func setup(new_runtime) -> void:
	runtime = new_runtime


func navigation_target(
	actor_owner_id: int,
	origin: Vector2i,
	target: Vector2i,
	neutral_actor: bool = false
) -> Vector2i:
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
		var gate_x: int = gate_x(lane_index)
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
	return (
		best_destination
		if gate_allows(actor_owner_id, best_lane_index, neutral_actor)
		else origin
	)


func next_step_toward(
	actor_owner_id: int,
	origin: Vector2i,
	target: Vector2i,
	neutral_actor: bool = false
) -> Vector2i:
	var best: Vector2i = origin
	var best_distance: int = _distance(origin, target)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if (
			not runtime.battlefield.is_inside(candidate)
			or not _crossing_allowed(actor_owner_id, origin, candidate, neutral_actor)
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


func gate_allows(actor_owner_id: int, lane_index: int, neutral_actor: bool = false) -> bool:
	if (
		runtime.round_director == null
		or not is_instance_valid(runtime.round_director)
		or runtime.round_director.gate_connectivity_system == null
		or not is_instance_valid(runtime.round_director.gate_connectivity_system)
	):
		return true
	var state: Dictionary = runtime.round_director.gate_connectivity_system.get_lane_state(lane_index)
	var state_id: String = str(state.get("state", "open"))
	if neutral_actor:
		return state_id != "closed"
	var gate_owner: int = int(state.get("owner_id", RulesScript.NEUTRAL_OWNER))
	return state_id != "closed" or gate_owner == int(actor_owner_id)


func gate_x(lane_index: int) -> int:
	return clampi(
		roundi(
			float(int(runtime.battlefield.grid_size) - 1)
			* runtime._lane_center_ratio(lane_index)
		),
		0,
		int(runtime.battlefield.grid_size) - 1
	)


func _crossing_allowed(
	actor_owner_id: int,
	origin: Vector2i,
	candidate: Vector2i,
	neutral_actor: bool
) -> bool:
	var river_y: int = int(runtime.battlefield.grid_size) >> 1
	if not (
		(origin.y == river_y - 1 and candidate.y == river_y)
		or (origin.y == river_y and candidate.y == river_y - 1)
	):
		return true
	for lane_index in range(2):
		var crossing_x: int = gate_x(lane_index)
		if origin.x == crossing_x and candidate.x == crossing_x:
			return gate_allows(actor_owner_id, lane_index, neutral_actor)
	return false


func _distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	return absi(from_cell.x - to_cell.x) + absi(from_cell.y - to_cell.y)
