extends RefCounted
class_name RegionMoraleRules

const SUPPORT_PLAYER: String = "support_player"
const UNREST_ENEMY: String = "unrest_enemy"

const DEFAULT_POINTS: int = 5
const TICK_INTERVAL: float = 1.0


static func is_valid_mode(mode: String) -> bool:
	return mode == SUPPORT_PLAYER or mode == UNREST_ENEMY
