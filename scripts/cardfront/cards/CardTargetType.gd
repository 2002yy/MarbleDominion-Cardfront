extends RefCounted

const OWNED_BORDER: String = "owned_border"
const ENEMY_REGION: String = "enemy_region"
const OWNED_REGION: String = "owned_region"

static func is_valid(target_type: String) -> bool:
	return target_type in [OWNED_BORDER, ENEMY_REGION, OWNED_REGION]
