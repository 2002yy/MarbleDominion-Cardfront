extends RefCounted
class_name CardfrontRules

const PLAYER_FACTION: int = GameConfig.Faction.BLUE
const AI_FACTION: int = GameConfig.Faction.RED
const NEUTRAL_OWNER: int = -1

const MATCH_DURATION_SECONDS: float = 8.0 * 60.0
const CAPTURE_TARGET_PERCENT: int = 70
const DEFAULT_GRID_SIZE: int = 40
const OPTIONAL_GRID_SIZE: int = 60
const DEFAULT_AI_DECISION_INTERVAL: float = 2.0

const NEUTRAL_COLOR: Color = Color(0.28, 0.31, 0.38, 0.94)


static func get_duel_factions() -> Array:
	return [PLAYER_FACTION, AI_FACTION]


static func get_score_owner_ids() -> Array:
	return [PLAYER_FACTION, AI_FACTION, NEUTRAL_OWNER]


static func get_spawn_columns(grid_size: int) -> int:
	var safe_size: int = maxi(4, grid_size)
	var desired: int = int(round(float(safe_size) * 0.20))
	return clampi(desired, 2, maxi(2, (safe_size / 2) - 1))


static func duel_owner_for_cell(x: int, _y: int, grid_size: int) -> int:
	var spawn_columns: int = get_spawn_columns(grid_size)
	if x < spawn_columns:
		return PLAYER_FACTION
	if x >= grid_size - spawn_columns:
		return AI_FACTION
	return NEUTRAL_OWNER


static func owner_display_name(owner_id: int) -> String:
	match owner_id:
		PLAYER_FACTION:
			return "玩家"
		AI_FACTION:
			return "AI"
		NEUTRAL_OWNER:
			return "中立"
		_:
			return GameConfig.faction_name(owner_id)


static func owner_color(owner_id: int) -> Color:
	if owner_id == NEUTRAL_OWNER:
		return NEUTRAL_COLOR
	return GameConfig.faction_color(owner_id)


static func is_cardfront_mode(mode_name: String) -> bool:
	return mode_name == GameConfig.GAME_MODE_CARDFRONT
