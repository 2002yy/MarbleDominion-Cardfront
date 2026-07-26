extends RefCounted
class_name CardfrontGateRules

const STATE_OPEN: String = "open"
const STATE_HALF_OPEN: String = "half_open"
const STATE_CLOSED: String = "closed"

const LANE_COUNT: int = 2
const LANE_CENTER_RATIOS: Array[float] = [0.265, 0.735]
const LANE_HALF_WIDTH_RATIO: float = 0.085
const CONTROL_ZONE_HALF_WIDTH_RATIO: float = 0.10
const CONTROL_ZONE_HALF_HEIGHT_RATIO: float = 0.10

const HALF_OPEN_CONTROL_PERCENT: int = 55
const CLOSED_CONTROL_PERCENT: int = 80


static func openness_for_state(state_id: String) -> float:
	match str(state_id):
		STATE_CLOSED:
			return 0.0
		STATE_HALF_OPEN:
			return 0.5
	return 1.0


static func is_valid_state(state_id: String) -> bool:
	return str(state_id) in [STATE_OPEN, STATE_HALF_OPEN, STATE_CLOSED]
