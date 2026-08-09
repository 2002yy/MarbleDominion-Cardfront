extends Node
class_name CardfrontGateConnectivitySystem

signal snapshot_sampled(snapshot)
signal projectile_filtered(faction_id, lane_index, state_id, reason)

const GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var battlefield = null
var bullet_pool = null
var arena_view = null
var locked_snapshot: Dictionary = {}
var sampled_round: int = 0
var projectile_serial: int = 0


func _init() -> void:
	name = "CardfrontGateConnectivitySystem"
	set_process(false)


func setup(new_battlefield, new_bullet_pool = null, new_arena_view = null) -> bool:
	if new_battlefield == null or not is_instance_valid(new_battlefield):
		return false
	battlefield = new_battlefield
	bullet_pool = new_bullet_pool
	arena_view = new_arena_view
	locked_snapshot = _open_snapshot(0)
	projectile_serial = 0
	if bullet_pool != null and is_instance_valid(bullet_pool) and bullet_pool.has_method("set_route_filter"):
		bullet_pool.set_route_filter(self)
	_sync_arena_view()
	return true


func detach() -> void:
	if bullet_pool != null and is_instance_valid(bullet_pool) and bullet_pool.has_method("set_route_filter"):
		if bullet_pool.get("route_filter") == self:
			bullet_pool.set_route_filter(null)
	bullet_pool = null
	arena_view = null


func sample_and_lock(round_number: int = 0) -> Dictionary:
	sampled_round = maxi(0, int(round_number))
	var next_snapshot: Dictionary = {}
	for lane_index in range(GateRulesScript.LANE_COUNT):
		next_snapshot[lane_index] = _sample_lane(lane_index, sampled_round)
	locked_snapshot = next_snapshot
	_sync_arena_view()
	snapshot_sampled.emit(get_snapshot())
	return get_snapshot()


func get_snapshot() -> Dictionary:
	return locked_snapshot.duplicate(true)


func get_lane_state(lane_index: int) -> Dictionary:
	return (locked_snapshot.get(int(lane_index), _open_lane(lane_index, sampled_round)) as Dictionary).duplicate(true)


func make_projectile_context(_faction_id: int) -> Dictionary:
	projectile_serial += 1
	return {
		"gate_snapshot": get_snapshot(),
		"projectile_serial": projectile_serial,
		"sampled_round": sampled_round,
	}


func filter_step(
	faction_id: int,
	from_local: Vector2,
	to_local: Vector2,
	direction: Vector2,
	projectile_context: Dictionary = {}
) -> Dictionary:
	if battlefield == null or not is_instance_valid(battlefield):
		return {"crossed": false, "allowed": true}
	var map_width: float = float(battlefield.grid_extent.x) * float(battlefield.cell_size)
	var map_height: float = float(battlefield.grid_extent.y) * float(battlefield.cell_size)
	var river_y: float = map_height * 0.5
	var from_delta: float = from_local.y - river_y
	var to_delta: float = to_local.y - river_y
	if is_zero_approx(from_delta):
		from_delta = -0.001 if direction.y > 0.0 else 0.001
	if from_delta * to_delta > 0.0 or is_zero_approx(to_local.y - from_local.y):
		return {"crossed": false, "allowed": true}

	var crossing_t: float = clampf((river_y - from_local.y) / (to_local.y - from_local.y), 0.0, 1.0)
	var crossing_x: float = lerpf(from_local.x, to_local.x, crossing_t)
	var lane_index: int = _lane_for_crossing_x(crossing_x, map_width)
	var state: Dictionary = {}
	var allowed: bool = false
	var reason: String = "river_bank"
	if lane_index >= 0:
		var snapshot: Dictionary = projectile_context.get("gate_snapshot", locked_snapshot) as Dictionary
		state = snapshot.get(lane_index, _open_lane(lane_index, sampled_round)) as Dictionary
		allowed = _is_allowed(
			int(faction_id),
			lane_index,
			state,
			int(projectile_context.get("projectile_serial", 0))
		)
		reason = "gate_pass" if allowed else "gate_filtered"
	if allowed:
		return {
			"crossed": true,
			"allowed": true,
			"lane_index": lane_index,
			"state": state.duplicate(true),
			"reason": reason,
		}

	var source_side: float = 1.0 if from_delta > 0.0 else -1.0
	var reflected_direction := Vector2(direction.x, absf(direction.y) * source_side).normalized()
	var blocked_position := Vector2(
		clampf(crossing_x, 0.0, map_width),
		river_y + source_side * maxf(1.0, float(battlefield.cell_size) * 0.35)
	)
	var state_id: String = str(state.get("state", GateRulesScript.STATE_CLOSED))
	projectile_filtered.emit(int(faction_id), lane_index, state_id, reason)
	return {
		"crossed": true,
		"allowed": false,
		"lane_index": lane_index,
		"state": state.duplicate(true),
		"position": blocked_position,
		"direction": reflected_direction,
		"reason": reason,
	}


func _sample_lane(lane_index: int, round_number: int) -> Dictionary:
	var width: int = int(battlefield.grid_extent.x)
	var height: int = int(battlefield.grid_extent.y)
	var center_x: int = clampi(
		roundi(float(width - 1) * GateRulesScript.LANE_CENTER_RATIOS[lane_index]),
		0,
		width - 1
	)
	var center_y: int = height >> 1
	var half_width: int = maxi(2, roundi(float(width) * GateRulesScript.CONTROL_ZONE_HALF_WIDTH_RATIO))
	var half_height: int = maxi(2, roundi(float(height) * GateRulesScript.CONTROL_ZONE_HALF_HEIGHT_RATIO))
	var counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 0,
		RulesScript.AI_FACTION: 0,
		RulesScript.NEUTRAL_OWNER: 0,
	}
	var total: int = 0
	for x in range(maxi(0, center_x - half_width), mini(width, center_x + half_width + 1)):
		for y in range(maxi(0, center_y - half_height), mini(height, center_y + half_height + 1)):
			var cell_owner_id: int = int(battlefield.owners[x][y])
			counts[cell_owner_id] = int(counts.get(cell_owner_id, 0)) + 1
			total += 1

	var player_count: int = int(counts[RulesScript.PLAYER_FACTION])
	var ai_count: int = int(counts[RulesScript.AI_FACTION])
	var owner_id: int = RulesScript.NEUTRAL_OWNER
	var owner_count: int = 0
	if player_count > ai_count:
		owner_id = RulesScript.PLAYER_FACTION
		owner_count = player_count
	elif ai_count > player_count:
		owner_id = RulesScript.AI_FACTION
		owner_count = ai_count
	var resolved: Dictionary = GateRulesScript.state_from_control(
		owner_id,
		owner_count,
		total,
		RulesScript.NEUTRAL_OWNER
	)
	owner_id = int(resolved.get("owner", RulesScript.NEUTRAL_OWNER))
	var state_id: String = str(resolved.get("state", GateRulesScript.STATE_OPEN))
	var control_percent: int = int(resolved.get("control_percent", 0))
	return {
		"lane_index": lane_index,
		"state": state_id,
		"owner_id": owner_id,
		"control_percent": control_percent if owner_id != RulesScript.NEUTRAL_OWNER else 0,
		"openness": float(resolved.get("openness", 1.0)),
		"sampled_round": round_number,
		"control_counts": counts,
	}


func _is_allowed(faction_id: int, lane_index: int, state: Dictionary, serial: int) -> bool:
	return GateRulesScript.is_projectile_allowed(
		int(faction_id),
		lane_index,
		state,
		serial,
		RulesScript.NEUTRAL_OWNER
	)


func _lane_for_crossing_x(crossing_x: float, map_size: float) -> int:
	for lane_index in range(GateRulesScript.LANE_COUNT):
		var center_x: float = map_size * GateRulesScript.LANE_CENTER_RATIOS[lane_index]
		if absf(crossing_x - center_x) <= map_size * GateRulesScript.LANE_HALF_WIDTH_RATIO:
			return lane_index
	return -1


func _sync_arena_view() -> void:
	if arena_view == null or not is_instance_valid(arena_view):
		return
	for lane_index in range(GateRulesScript.LANE_COUNT):
		var state: Dictionary = locked_snapshot.get(lane_index, _open_lane(lane_index, sampled_round)) as Dictionary
		if arena_view.has_method("set_gate_state"):
			arena_view.set_gate_state(lane_index, state)
		elif arena_view.has_method("set_gate_openness"):
			arena_view.set_gate_openness(lane_index, float(state.get("openness", 1.0)))


func _open_snapshot(round_number: int) -> Dictionary:
	var snapshot: Dictionary = {}
	for lane_index in range(GateRulesScript.LANE_COUNT):
		snapshot[lane_index] = _open_lane(lane_index, round_number)
	return snapshot


func _open_lane(lane_index: int, round_number: int) -> Dictionary:
	return {
		"lane_index": lane_index,
		"state": GateRulesScript.STATE_OPEN,
		"owner_id": RulesScript.NEUTRAL_OWNER,
		"control_percent": 0,
		"openness": 1.0,
		"sampled_round": round_number,
		"control_counts": {},
	}
