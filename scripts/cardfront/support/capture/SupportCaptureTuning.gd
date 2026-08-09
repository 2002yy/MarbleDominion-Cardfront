extends RefCounted
class_name SupportCaptureTuning

const SECOND_CONTRIBUTOR_MULTIPLIER: float = 0.60
const THIRD_PLUS_INITIAL_MULTIPLIER: float = 0.25
const THIRD_PLUS_DECAY: float = 0.50
const MAX_CAPTURE_POWER: float = 3.00
const BASE_CAPTURE_RATE_PER_SECOND: float = 0.10
const CAPTURE_IDLE_GRACE_SECONDS: float = 2.00
const CAPTURE_IDLE_DECAY_MULTIPLIER: float = 0.25


static func contributor_multiplier(sorted_index: int) -> float:
	if sorted_index <= 0:
		return 1.0
	if sorted_index == 1:
		return SECOND_CONTRIBUTOR_MULTIPLIER
	return THIRD_PLUS_INITIAL_MULTIPLIER * pow(THIRD_PLUS_DECAY, sorted_index - 2)


static func state_machine_defaults() -> Dictionary:
	return {
		"base_capture_rate_per_second": BASE_CAPTURE_RATE_PER_SECOND,
		"capture_idle_grace_seconds": CAPTURE_IDLE_GRACE_SECONDS,
		"capture_idle_decay_multiplier": CAPTURE_IDLE_DECAY_MULTIPLIER,
	}
