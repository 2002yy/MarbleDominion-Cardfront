extends RefCounted

const FORTIFY: String = "fortify"
const CALIBRATED_SHOT: String = "calibrated_shot"
const MORALE_FLUCTUATION: String = "morale_fluctuation"

static func is_valid(card_type: String) -> bool:
	return card_type in [FORTIFY, CALIBRATED_SHOT, MORALE_FLUCTUATION]
