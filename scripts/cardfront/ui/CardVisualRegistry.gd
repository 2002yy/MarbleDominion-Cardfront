extends RefCounted
class_name CardVisualRegistry

const RUNTIME_BASE: String = "res://assets/cardfront_runtime/卡牌插图_cards/512/"

const CARD_VISUALS := {
	1001: {"filename": "前线加固_frontline_fortify_v01.png", "thumbnail": ""},
	1002: {"filename": "校准射击_calibrated_shot_v01.png", "thumbnail": ""},
	1003: {"filename": "民心起伏_morale_shift_v01.png", "thumbnail": ""},
	1004: {"filename": "拓荒信标_pioneer_beacon_v01.png", "thumbnail": ""},
}


static func get_texture_path(card_id: int) -> String:
	var entry: Dictionary = CARD_VISUALS.get(card_id, {})
	var filename: String = str(entry.get("filename", ""))
	if filename == "":
		return ""
	return RUNTIME_BASE + filename


static func has_texture(card_id: int) -> bool:
	return CARD_VISUALS.has(card_id)
