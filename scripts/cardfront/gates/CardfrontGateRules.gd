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


static func state_from_control(
	leading_owner,
	leading_count: int,
	total_count: int,
	neutral_owner
) -> Dictionary:
	var safe_total: int = maxi(1, int(total_count))
	var safe_count: int = clampi(int(leading_count), 0, safe_total)
	var control_percent: int = roundi(100.0 * float(safe_count) / float(safe_total))
	var owner = leading_owner
	var state_id: String = STATE_OPEN
	if owner != neutral_owner and control_percent >= CLOSED_CONTROL_PERCENT:
		state_id = STATE_CLOSED
	elif owner != neutral_owner and control_percent >= HALF_OPEN_CONTROL_PERCENT:
		state_id = STATE_HALF_OPEN
	else:
		owner = neutral_owner
		control_percent = 0
	return {
		"state": state_id,
		"owner": owner,
		"control_percent": control_percent,
		"openness": openness_for_state(state_id),
	}


static func is_projectile_allowed(
	faction,
	lane_index: int,
	state: Dictionary,
	serial: int,
	neutral_owner
) -> bool:
	var state_id: String = str(state.get("state", STATE_OPEN))
	var owner = state.get("owner", state.get("owner_id", neutral_owner))
	if state_id == STATE_OPEN or owner == neutral_owner:
		return true
	if faction == owner:
		return true
	if state_id == STATE_HALF_OPEN:
		return (int(serial) + int(lane_index)) % 2 == 0
	return false
