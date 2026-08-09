extends RefCounted
class_name SupportCaptureTuning

const SECOND_CONTRIBUTOR_MULTIPLIER: float = 0.60
const THIRD_PLUS_INITIAL_MULTIPLIER: float = 0.25
const THIRD_PLUS_DECAY: float = 0.50
const MAX_CAPTURE_POWER: float = 3.00


static func contributor_multiplier(sorted_index: int) -> float:
	if sorted_index <= 0:
		return 1.0
	if sorted_index == 1:
		return SECOND_CONTRIBUTOR_MULTIPLIER
	return THIRD_PLUS_INITIAL_MULTIPLIER * pow(THIRD_PLUS_DECAY, sorted_index - 2)
