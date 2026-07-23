extends RefCounted
class_name CardfrontFireRules

const BASE_SHOT_INTERVAL: float = 1.25
const BASE_SHOT_COUNT: int = 1
const BASE_SPREAD_RADIANS: float = 0.10
const MAX_TOTAL_SHOTS_PER_SECOND: int = 6
const MAX_OWNER_SHOTS_PER_SECOND: int = 3
const MAX_SHOTS_PER_SECOND: int = MAX_TOTAL_SHOTS_PER_SECOND
const TARGET_BIAS_STRENGTH: float = 1.0

const REASON_BASE: String = "base_target"
const REASON_TARGET_BIAS: String = "target_bias"
const REASON_NEUTRAL_BOUNDARY: String = "neutral_boundary"
const REASON_STRONGHOLD: String = "stronghold"
const REASON_ENEMY_STRONGHOLD: String = "enemy_stronghold"
const REASON_RESOURCE_REGION: String = REASON_STRONGHOLD
const REASON_ENEMY_RESOURCE_REGION: String = REASON_ENEMY_STRONGHOLD
