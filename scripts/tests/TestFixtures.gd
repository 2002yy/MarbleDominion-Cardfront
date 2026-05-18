extends RefCounted
class_name TestFixtures

class MockTurret:
	var faction_id: int
	var is_destroyed: bool

	func _init(p_faction_id: int, p_is_destroyed: bool) -> void:
		faction_id = p_faction_id
		is_destroyed = p_is_destroyed

# ---- save payload builders --------------------------------------------

static func build_realistic_save_payload() -> Dictionary:
	var owners: Array = []
	for x in range(10):
		var col: Array = []
		for y in range(10):
			col.append(GameConfig.Faction.BLUE)
		owners.append(col)
	owners[0][0] = GameConfig.Faction.RED

	return {
		"save_version": "2.0.0",
		"save_slot": 1,
		"grid_size": 10,
		"palette_name": "经典",
		"quality_name": "中",
		"game_mode_name": GameConfig.GAME_MODE_BASIC,
		"time_limit_minutes": 5,
		"owners": owners,
		"game_elapsed_time": 120.0,
		"is_game_over": false,
		"factions": build_save_faction_states(),
		"bullets": [],
		"winner_text": "",
		"event_state": build_save_event_state(),
	}

static func build_save_faction_states() -> Array:
	var result: Array = []
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		result.append({
			"faction_id": faction_id,
			"chamber_pending_count": 8,
			"chamber_locked_remaining": 0,
			"chamber_is_locked": false,
			"chamber_is_damaged": false,
			"chamber_ball_count": 2,
			"chamber_release_ball_index": -1,
			"chamber_jammed_time_left": 0.0,
			"queued_round_modifiers": [],
			"control_balls": [],
			"turret_health": GameConfig.TURRET_MAX_HEALTH,
			"turret_destroyed": false,
			"turret_sweep_phase": 0.0,
			"turret_rotation": 0.0,
			"turret_burst_remaining": 0,
			"turret_burst_total": 0,
			"turret_burst_index": 0,
			"turret_burst_timer": 0.0,
			"turret_burst_locked": false,
		})
	return result

static func build_save_event_state() -> Dictionary:
	return {
		"event_roulette_enabled": true,
		"next_event_time_left": 30.5,
		"current_event_interval": 60.0,
		"last_event_faction": GameConfig.Faction.GREEN,
		"last_event_effect": EventRouletteController.EFFECT_X2,
		"reroll_count": 0,
	}

static func build_invalid_save_payload() -> Dictionary:
	return {
		"save_version": "1.9.0",
		"grid_size": 40,
		"quality_name": "中",
		"game_mode_name": "not_a_mode",
		"time_limit_minutes": 5,
		"factions": [],
	}

static func build_minimal_save_payload(version: String = "2.0.0") -> Dictionary:
	return {
		"save_version": version,
		"grid_size": 40,
		"quality_name": "中",
		"game_mode_name": GameConfig.GAME_MODE_BASIC,
		"time_limit_minutes": 5,
		"factions": [],
	}

# ---- turret mocks -----------------------------------------------------

static func make_mock_turret(faction_id: int, destroyed: bool = false):
	return MockTurret.new(faction_id, destroyed)

static func make_mock_turrets(destroyed_map: Dictionary = {}) -> Array:
	return [
		make_mock_turret(GameConfig.Faction.BLUE, bool(destroyed_map.get(GameConfig.Faction.BLUE, false))),
		make_mock_turret(GameConfig.Faction.RED, bool(destroyed_map.get(GameConfig.Faction.RED, false))),
		make_mock_turret(GameConfig.Faction.GREEN, bool(destroyed_map.get(GameConfig.Faction.GREEN, false))),
		make_mock_turret(GameConfig.Faction.YELLOW, bool(destroyed_map.get(GameConfig.Faction.YELLOW, false))),
	]

# ---- battlefield helpers ----------------------------------------------

static func set_owner_cell_raw(battlefield, x: int, y: int, faction_id: int) -> void:
	var row = battlefield.owners[x]
	row[y] = faction_id
	battlefield.owners[x] = row

static func fill_battlefield(battlefield, faction_id: int) -> void:
	var size := int(battlefield.grid_size)
	for x in range(size):
		for y in range(size):
			set_owner_cell_raw(battlefield, x, y, faction_id)
	if battlefield.has_method("rebuild_owner_counts"):
		battlefield.rebuild_owner_counts()

static func paint_first_cells(battlefield, faction_id: int, target_cells: int) -> void:
	var size := int(battlefield.grid_size)
	var painted: int = 0
	for x in range(size):
		for y in range(size):
			if painted >= target_cells:
				break
			set_owner_cell_raw(battlefield, x, y, faction_id)
			painted += 1
		if painted >= target_cells:
			break
	if battlefield.has_method("rebuild_owner_counts"):
		battlefield.rebuild_owner_counts()

# ---- win condition simulation (zero dependency on GameConfig state) ---

static func simulate_check_winner(mode_name: String, battlefield, mock_turrets: Array) -> int:
	match mode_name:
		GameConfig.GAME_MODE_BASIC:
			return _basic_winner(mock_turrets)
		GameConfig.GAME_MODE_OCCUPATION:
			return _occupation_winner(battlefield)
		GameConfig.GAME_MODE_TIMED:
			return _timed_winner(battlefield)
		GameConfig.GAME_MODE_WILD:
			return _basic_winner(mock_turrets)
		GameConfig.GAME_MODE_CARDFRONT:
			var total_cells: int = battlefield.grid_size * battlefield.grid_size if battlefield != null else 0
			var result: Dictionary = WinConditionEvaluator.evaluate_cardfront(battlefield.count_cells_by_team(), total_cells, true)
			if bool(result.get("draw", false)):
				return -2
			return int(result.get("winner", -1))
	return -1

static func get_occupation_winner(battlefield, target_percent: float = 0.75) -> int:
	# Public helper: checks whether a faction has reached exactly the given percent.
	var counts: Dictionary = battlefield.count_cells_by_team()
	var total: int = 0
	var best_id: int = -1
	var best_count: int = -1
	var tied: bool = false
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var count: int = int(counts.get(faction_id, 0))
		total += count
		if count > best_count:
			best_count = count
			best_id = int(faction_id)
			tied = false
		elif count == best_count:
			tied = true
	if total <= 0 or tied:
		return -1
	if best_count * 100 >= total * int(target_percent * 100):
		return best_id
	return -1

static func _occupation_winner(battlefield) -> int:
	var counts: Dictionary = battlefield.count_cells_by_team()
	var total: int = 0
	var best_id: int = -1
	var best_count: int = -1
	var tied: bool = false
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var count: int = int(counts.get(faction_id, 0))
		total += count
		if count > best_count:
			best_count = count
			best_id = int(faction_id)
			tied = false
		elif count == best_count:
			tied = true
	if total <= 0 or tied:
		return -1
	if best_count * 100 >= total * GameConfig.get_occupation_target_percent():
		return best_id
	return -1

static func _basic_winner(mock_turrets: Array) -> int:
	var alive: Array = []
	for turret in mock_turrets:
		if turret is MockTurret and not turret.is_destroyed:
			alive.append(turret.faction_id)
	if alive.size() == 1:
		return int(alive[0])
	elif alive.size() == 0:
		return -2
	return -1

static func _timed_winner(battlefield) -> int:
	var counts: Dictionary = battlefield.count_cells_by_team()
	var best_id: int = -1
	var best_count: int = -1
	var tied: bool = false
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var count: int = int(counts.get(faction_id, 0))
		if count > best_count:
			best_count = count
			best_id = faction_id
			tied = false
		elif count == best_count:
			tied = true
	if tied:
		return -1
	return best_id

# ---- node cleanup -----------------------------------------------------

static func cleanup_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.get_parent() != null:
		node.queue_free()
	else:
		node.free()
