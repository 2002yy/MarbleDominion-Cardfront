extends RefCounted
class_name CardfrontSupportIds

const CORE_PLAYER: String = "core_player"
const SUPPORT_LEFT_SOUTH: String = "support_left_south"
const SUPPORT_RIGHT_SOUTH: String = "support_right_south"
const SUPPORT_CENTER: String = "support_center"
const SUPPORT_LEFT_NORTH: String = "support_left_north"
const SUPPORT_RIGHT_NORTH: String = "support_right_north"
const CORE_AI: String = "core_ai"

const DEFAULT_DUEL_ALL: Array[String] = [
	CORE_PLAYER,
	SUPPORT_LEFT_SOUTH,
	SUPPORT_RIGHT_SOUTH,
	SUPPORT_CENTER,
	SUPPORT_LEFT_NORTH,
	SUPPORT_RIGHT_NORTH,
	CORE_AI,
]


static func is_default_duel_id(support_id: String) -> bool:
	return str(support_id) in DEFAULT_DUEL_ALL


static func is_core_id(support_id: String) -> bool:
	return str(support_id) == CORE_PLAYER or str(support_id) == CORE_AI
