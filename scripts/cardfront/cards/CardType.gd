extends RefCounted

const FORTIFY: String = "fortify"
const CALIBRATED_SHOT: String = "calibrated_shot"
const MORALE_FLUCTUATION: String = "morale_fluctuation"
const PIONEER_BEACON: String = "pioneer_beacon"
const DEVICE: String = "device"
const REGION_RULE: String = "region_rule"
const FIRE_RULE: String = "fire_rule"

static func is_valid(card_type: String) -> bool:
	return card_type in [FORTIFY, CALIBRATED_SHOT, MORALE_FLUCTUATION, PIONEER_BEACON, DEVICE, REGION_RULE, FIRE_RULE]
