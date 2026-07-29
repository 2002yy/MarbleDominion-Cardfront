extends RefCounted
class_name SaveGameCodec

const GridExtentScript = preload("res://scripts/GridExtent.gd")

const SUPPORTED_SAVE_MAJOR_PREFIXES: Array[String] = ["1.9", "2.0", "2.1"]
const SAVE_SCHEMA_VERSION: String = "2.1.0"
const CURRENT_SAVE_VERSION: String = SAVE_SCHEMA_VERSION
const MAX_RESTORE_CONTROL_BALLS: int = 8
const PAYLOAD_HASH_KEY: String = "payload_hash"
const INTEGRITY_STATUS_MISSING: String = "missing"
const INTEGRITY_STATUS_VALID: String = "valid"
const INTEGRITY_STATUS_MISMATCH: String = "mismatch"

static func get_current_save_version() -> String:
	return CURRENT_SAVE_VERSION

static func attach_payload_hash(core_payload: Dictionary) -> Dictionary:
	var normalized_core: Dictionary = extract_core_payload(core_payload)
	var payload_with_hash: Dictionary = normalized_core.duplicate(true)
	payload_with_hash[PAYLOAD_HASH_KEY] = compute_payload_hash(normalized_core)
	return payload_with_hash

static func extract_core_payload(payload: Dictionary) -> Dictionary:
	var core_payload: Dictionary = payload.duplicate(true)
	core_payload.erase(PAYLOAD_HASH_KEY)
	return core_payload

static func compute_payload_hash(core_payload: Dictionary) -> int:
	return hash(JSON.stringify(core_payload, "", true, true))

static func inspect_payload_integrity(payload: Dictionary) -> Dictionary:
	var core_payload: Dictionary = extract_core_payload(payload)
	if not payload.has(PAYLOAD_HASH_KEY):
		return {
			"data": core_payload,
			"integrity_status": INTEGRITY_STATUS_MISSING,
			"integrity_ok": true,
			"expected_hash": 0,
			"stored_hash": null,
		}

	var stored_hash_raw = payload.get(PAYLOAD_HASH_KEY, null)
	var stored_hash = null
	if stored_hash_raw is int:
		stored_hash = stored_hash_raw
	elif stored_hash_raw is float:
		stored_hash = int(stored_hash_raw)
	elif stored_hash_raw is String and str(stored_hash_raw).is_valid_int():
		stored_hash = int(stored_hash_raw)

	var expected_hash: int = compute_payload_hash(core_payload)
	var integrity_ok: bool = stored_hash != null and int(stored_hash) == expected_hash
	return {
		"data": core_payload,
		"integrity_status": INTEGRITY_STATUS_VALID if integrity_ok else INTEGRITY_STATUS_MISMATCH,
		"integrity_ok": integrity_ok,
		"expected_hash": expected_hash,
		"stored_hash": stored_hash,
	}

static func is_supported_save_version(version: String) -> bool:
	var normalized: String = str(version)
	for prefix in SUPPORTED_SAVE_MAJOR_PREFIXES:
		if normalized.begins_with(prefix):
			return true
	return false

static func vec2_to_arr(v: Vector2) -> Array:
	return [v.x, v.y]

static func arr_to_vec2(value, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return default_value

static func vec2i_to_arr(v: Vector2i) -> Array:
	return [v.x, v.y]

static func arr_to_vec2i(value, default_value: Vector2i = Vector2i(-999, -999)) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return default_value

static func get_release_ball_index(chamber) -> int:
	if chamber == null or chamber.release_ball == null:
		return -1
	for i in range(chamber.balls.size()):
		if chamber.balls[i] == chamber.release_ball:
			return i
	return -1

static func collect_control_ball_states(chamber) -> Array:
	var result: Array = []
	if chamber == null:
		return result

	for ball in chamber.balls:
		if ball == null or not is_instance_valid(ball):
			continue
		result.append({
			"position": vec2_to_arr(ball.position),
			"velocity": vec2_to_arr(ball.velocity),
			"radius": ball.radius,
			"stay_time": chamber.get_ball_stay_time(ball),
		})
	return result

static func collect_bullet_states(bullet_container) -> Array:
	var result: Array = []
	if bullet_container == null:
		return result

	var source_bullets: Array = bullet_container.get_active_bullets() if bullet_container.has_method("get_active_bullets") else bullet_container.get_children()
	for node in source_bullets:
		if node is Bullet and node.is_active:
			var trail: Array = []
			for point in node.trail_points:
				trail.append(vec2_to_arr(point))
			result.append({
				"faction_id": node.faction_id,
				"position": vec2_to_arr(node.global_position),
				"direction": vec2_to_arr(node.direction),
				"age": node.age,
				"damage_power": int(node.get("damage_power")),
				"last_cell": vec2i_to_arr(node.last_cell),
				"trail_points": trail,
			})
	return result

static func validate_save_data(data: Dictionary) -> Dictionary:
	var clean: Dictionary = extract_core_payload(data)

	var grid_extent: Vector2i = GridExtentScript.sanitize(
		clean.get("grid_extent", clean.get("grid_size", GridExtentScript.DEFAULT)),
		GridExtentScript.DEFAULT
	)
	clean["grid_extent"] = GridExtentScript.to_array(grid_extent)
	clean["grid_size"] = grid_extent.x

	var version: String = str(clean.get("save_version", ""))
	if version == "" or not is_supported_save_version(version):
		clean["_invalid_reason"] = "存档版本不兼容：%s" % version
		return clean

	if not (str(clean.get("quality_name", GameConfig.QUALITY_MEDIUM)) in GameConfig.get_quality_names()):
		clean["quality_name"] = GameConfig.QUALITY_MEDIUM

	if not (str(clean.get("game_mode_name", GameConfig.GAME_MODE_BASIC)) in GameConfig.get_game_mode_names()):
		clean["game_mode_name"] = GameConfig.GAME_MODE_BASIC
	clean["time_limit_minutes"] = clampi(int(clean.get("time_limit_minutes", GameConfig.DEFAULT_TIMED_MODE_MINUTES)), GameConfig.TIMED_MODE_MIN_MINUTES, GameConfig.TIMED_MODE_MAX_MINUTES)

	var owners = clean.get("owners", [])
	var owners_ok: bool = owners is Array and owners.size() == grid_extent.x
	if owners_ok:
		for x in range(grid_extent.x):
			if not (owners[x] is Array) or owners[x].size() < grid_extent.y:
				owners_ok = false
				break
	if not owners_ok:
		clean.erase("owners")

	var bullets = clean.get("bullets", [])
	if bullets is Array:
		clean["bullets"] = bullets.slice(0, mini(bullets.size(), GameConfig.get_restore_bullet_limit()))
	else:
		clean["bullets"] = []

	var event_state = clean.get("event_state", {})
	if event_state is Dictionary:
		var raw_history = event_state.get("event_history", [])
		var fixed_history: Array = []
		if raw_history is Array:
			for entry in raw_history:
				if entry is Dictionary:
					fixed_history.append({
						"log_text": str(entry.get("log_text", "")),
						"game_time": maxf(0.0, float(entry.get("game_time", 0.0))),
					})
					if fixed_history.size() >= 24:
						break
		clean["event_state"] = {
			"event_roulette_enabled": bool(event_state.get("event_roulette_enabled", true)),
			"next_event_time_left": maxf(0.0, float(event_state.get("next_event_time_left", 0.0))),
			"current_event_interval": maxf(0.0, float(event_state.get("current_event_interval", 0.0))),
			"last_event_faction": clampi(int(event_state.get("last_event_faction", -1)), -1, 3),
			"last_event_effect": str(event_state.get("last_event_effect", "")),
			"reroll_count": clampi(int(event_state.get("reroll_count", 0)), 0, 2),
			"event_history": fixed_history,
		}
	else:
		clean["event_state"] = {}

	var factions = clean.get("factions", [])
	var fixed_factions: Array = []
	if factions is Array:
		for state in factions:
			if not (state is Dictionary):
				continue
			var fixed = state.duplicate(true)
			fixed["faction_id"] = clampi(int(fixed.get("faction_id", 0)), 0, 3)
			fixed["chamber_pending_count"] = clampi(int(fixed.get("chamber_pending_count", 1)), 1, GameConfig.get_max_pending_count())
			fixed["chamber_locked_remaining"] = clampi(int(fixed.get("chamber_locked_remaining", 0)), 0, GameConfig.get_max_pending_count())
			fixed["chamber_jammed_time_left"] = maxf(0.0, float(fixed.get("chamber_jammed_time_left", 0.0)))
			fixed["turret_burst_remaining"] = clampi(int(fixed.get("turret_burst_remaining", 0)), 0, GameConfig.get_max_pending_count())
			fixed["turret_burst_total"] = clampi(int(fixed.get("turret_burst_total", 0)), 0, GameConfig.get_max_pending_count())
			fixed["turret_burst_index"] = clampi(int(fixed.get("turret_burst_index", 0)), 0, GameConfig.get_max_pending_count())

			var queued_modifiers = fixed.get("queued_round_modifiers", [])
			if queued_modifiers is Array:
				var clean_modifiers: Array = []
				for mod in queued_modifiers:
					if mod is Dictionary:
						var clean_mod: Dictionary = {}
						for key in mod.keys():
							clean_mod[str(key)] = mod.get(key, null)
						clean_modifiers.append(clean_mod)
				fixed["queued_round_modifiers"] = clean_modifiers
			else:
				fixed["queued_round_modifiers"] = []
			var control_balls = fixed.get("control_balls", [])
			if control_balls is Array:
				var clean_balls: Array = []
				for ball in control_balls:
					if ball is Dictionary and ball.has("position") and ball.has("velocity"):
						clean_balls.append({
							"position": ball.get("position", []),
							"velocity": ball.get("velocity", []),
							"radius": maxf(0.0, float(ball.get("radius", 0.0))),
							"stay_time": maxf(0.0, float(ball.get("stay_time", 0.0))),
						})
				fixed["control_balls"] = clean_balls.slice(0, mini(clean_balls.size(), MAX_RESTORE_CONTROL_BALLS))
			else:
				fixed["control_balls"] = []

			fixed_factions.append(fixed)
	clean["factions"] = fixed_factions
	return clean
