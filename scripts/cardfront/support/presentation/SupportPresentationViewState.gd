extends RefCounted
class_name SupportPresentationViewState

const ACTIVE: String = "ACTIVE"
const DISABLED_NEUTRAL: String = "DISABLED_NEUTRAL"
const CAPTURING: String = "CAPTURING"
const CAPTURED_OFFLINE: String = "CAPTURED_OFFLINE"
const CONTESTED: String = "CONTESTED"

const ALL: Array[String] = [
	ACTIVE,
	DISABLED_NEUTRAL,
	CAPTURING,
	CAPTURED_OFFLINE,
	CONTESTED,
]


static func derive(
	claim_owner: int,
	operational: bool,
	network_connected: bool,
	capture_side: int,
	capture_progress_normalized: float,
	contested: bool,
	neutral_owner: int = -1
) -> String:
	if contested:
		return CONTESTED
	if capture_side != neutral_owner and capture_progress_normalized > 0.0:
		return CAPTURING
	if claim_owner == neutral_owner or not operational:
		return DISABLED_NEUTRAL
	if network_connected:
		return ACTIVE
	return CAPTURED_OFFLINE


static func is_valid(view_state: String) -> bool:
	return str(view_state) in ALL
