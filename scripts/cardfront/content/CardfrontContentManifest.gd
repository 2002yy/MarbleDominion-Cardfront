extends RefCounted
class_name CardfrontContentManifest

const CARD_FRONTLINE_FORTIFY: int = 1001
const CARD_CALIBRATED_SHOT: int = 1002
const CARD_MORALE_FLUCTUATION: int = 1003
const CARD_PIONEER_BEACON: int = 1004

const TARGET_OWNED_CELL: String = "owned_cell"
const TARGET_OWNED_BORDER: String = "owned_border"
const TARGET_OWNED_REGION: String = "owned_region"
const TARGET_ENEMY_REGION: String = "enemy_region"
const TARGET_NEUTRAL_REGION: String = "neutral_region"
const TARGET_ANY_RESOURCE_REGION: String = "any_resource_region"
const TARGET_OWNED_DEVICE: String = "owned_device"
const TARGET_ENEMY_DEVICE: String = "enemy_device"
const TARGET_LINE: String = "target_line"
const TARGET_AREA: String = "target_area"

const TARGET_TYPES: Array[String] = [
	TARGET_OWNED_CELL,
	TARGET_OWNED_BORDER,
	TARGET_OWNED_REGION,
	TARGET_ENEMY_REGION,
	TARGET_NEUTRAL_REGION,
	TARGET_ANY_RESOURCE_REGION,
	TARGET_OWNED_DEVICE,
	TARGET_ENEMY_DEVICE,
	TARGET_LINE,
	TARGET_AREA,
]

const IMPLEMENTED_TARGET_TYPES: Array[String] = [
	TARGET_OWNED_BORDER,
	TARGET_OWNED_REGION,
	TARGET_ENEMY_REGION,
]

const DEFAULT_HAND_IDS: Array[int] = [
	CARD_FRONTLINE_FORTIFY,
	CARD_CALIBRATED_SHOT,
	CARD_MORALE_FLUCTUATION,
	CARD_PIONEER_BEACON,
]

const CARD_DEFINITIONS := {
	CARD_FRONTLINE_FORTIFY: {
		"id": CARD_FRONTLINE_FORTIFY,
		"name": "前线加固",
		"type": "fortify",
		"energy_cost": 10,
		"parts_cost": 3,
		"target_type": TARGET_OWNED_BORDER,
		"effect_id": "fortify_border",
		"params": {"stacks": 3},
		"visual_id": "frontline_fortify_v01",
		"test_coverage": ["CardCoreLiteTestRunner.gd", "CardEffectResolverTestRunner.gd"],
	},
	CARD_CALIBRATED_SHOT: {
		"id": CARD_CALIBRATED_SHOT,
		"name": "校准射击",
		"type": "calibrated_shot",
		"energy_cost": 8,
		"parts_cost": 5,
		"target_type": TARGET_ENEMY_REGION,
		"effect_id": "calibrated_shot",
		"params": {"duration": 6.0},
		"visual_id": "calibrated_shot_v01",
		"test_coverage": ["CardCoreLiteTestRunner.gd", "CardEffectResolverTestRunner.gd"],
	},
	CARD_MORALE_FLUCTUATION: {
		"id": CARD_MORALE_FLUCTUATION,
		"name": "民心起伏",
		"type": "morale_fluctuation",
		"energy_cost": 5,
		"parts_cost": 2,
		"target_type": TARGET_OWNED_REGION,
		"effect_id": "morale_fluctuation",
		"params": {"mode": "support_player"},
		"visual_id": "morale_shift_v01",
		"test_coverage": ["CardCoreLiteTestRunner.gd", "CardEffectResolverTestRunner.gd"],
	},
	CARD_PIONEER_BEACON: {
		"id": CARD_PIONEER_BEACON,
		"name": "拓荒信标",
		"type": "pioneer_beacon",
		"energy_cost": 8,
		"parts_cost": 4,
		"target_type": TARGET_OWNED_BORDER,
		"effect_id": "pioneer_beacon_lite",
		"params": {"max_converted_cells": 3},
		"visual_id": "pioneer_beacon_v01",
		"test_coverage": ["PioneerBeaconLiteTestRunner.gd", "CardEffectResolverTestRunner.gd"],
	},
}

const CARD_VISUALS := {
	"frontline_fortify_v01": {
		"filename": "前线加固_frontline_fortify_v01.png",
		"thumbnail": "前线加固_frontline_fortify_v01.png",
	},
	"calibrated_shot_v01": {
		"filename": "校准射击_calibrated_shot_v01.png",
		"thumbnail": "校准射击_calibrated_shot_v01.png",
	},
	"morale_shift_v01": {
		"filename": "民心起伏_morale_shift_v01.png",
		"thumbnail": "民心起伏_morale_shift_v01.png",
	},
	"pioneer_beacon_v01": {
		"filename": "拓荒信标_pioneer_beacon_v01.png",
		"thumbnail": "拓荒信标_pioneer_beacon_v01.png",
	},
}

const EFFECT_PARAM_REQUIREMENTS := {
	"fortify_border": ["stacks"],
	"calibrated_shot": ["duration"],
	"morale_fluctuation": ["mode"],
	"pioneer_beacon_lite": ["max_converted_cells"],
}


static func get_card_ids() -> Array:
	var ids: Array = CARD_DEFINITIONS.keys()
	ids.sort()
	return ids


static func get_card_definition(card_id: int) -> Dictionary:
	return (CARD_DEFINITIONS.get(int(card_id), {}) as Dictionary).duplicate(true)


static func has_card(card_id: int) -> bool:
	return CARD_DEFINITIONS.has(int(card_id))


static func get_default_hand_ids() -> Array:
	return DEFAULT_HAND_IDS.duplicate()


static func get_target_types() -> Array:
	return TARGET_TYPES.duplicate()


static func get_implemented_target_types() -> Array:
	return IMPLEMENTED_TARGET_TYPES.duplicate()


static func get_reserved_target_types() -> Array:
	var reserved: Array = []
	for target_type in TARGET_TYPES:
		if not IMPLEMENTED_TARGET_TYPES.has(str(target_type)):
			reserved.append(str(target_type))
	return reserved


static func is_target_type_valid(target_type: String) -> bool:
	return str(target_type) in TARGET_TYPES


static func is_target_type_implemented(target_type: String) -> bool:
	return str(target_type) in IMPLEMENTED_TARGET_TYPES


static func get_declared_effect_ids() -> Array:
	var ids: Array = []
	for card_id in get_card_ids():
		var effect_id: String = str(CARD_DEFINITIONS[int(card_id)].get("effect_id", ""))
		if effect_id != "" and not ids.has(effect_id):
			ids.append(effect_id)
	ids.sort()
	return ids


static func get_required_params(effect_id: String) -> Array:
	return (EFFECT_PARAM_REQUIREMENTS.get(str(effect_id), []) as Array).duplicate()


static func get_visual(visual_id: String) -> Dictionary:
	return (CARD_VISUALS.get(str(visual_id), {}) as Dictionary).duplicate(true)


static func get_visual_for_card(card_id: int) -> Dictionary:
	var definition: Dictionary = get_card_definition(card_id)
	return get_visual(str(definition.get("visual_id", "")))


static func validate_card_definition(card_id: int) -> Array:
	var errors: Array = []
	if not has_card(card_id):
		return ["missing_card:%d" % int(card_id)]
	var definition: Dictionary = CARD_DEFINITIONS[int(card_id)]
	if int(definition.get("id", -1)) != int(card_id):
		errors.append("id_mismatch:%d" % int(card_id))
	if str(definition.get("name", "")) == "":
		errors.append("missing_name:%d" % int(card_id))
	if int(definition.get("energy_cost", -1)) < 0:
		errors.append("negative_energy:%d" % int(card_id))
	if int(definition.get("parts_cost", -1)) < 0:
		errors.append("negative_parts:%d" % int(card_id))
	if not is_target_type_valid(str(definition.get("target_type", ""))):
		errors.append("invalid_target_type:%d" % int(card_id))
	elif not is_target_type_implemented(str(definition.get("target_type", ""))):
		errors.append("unimplemented_target_type:%d:%s" % [int(card_id), str(definition.get("target_type", ""))])
	var effect_id: String = str(definition.get("effect_id", ""))
	if effect_id == "":
		errors.append("missing_effect:%d" % int(card_id))
	var params: Dictionary = definition.get("params", {}) as Dictionary
	for required_param in get_required_params(effect_id):
		if not params.has(str(required_param)):
			errors.append("missing_param:%d:%s" % [int(card_id), str(required_param)])
	var visual_id: String = str(definition.get("visual_id", ""))
	if visual_id == "":
		errors.append("missing_visual:%d" % int(card_id))
	elif get_visual(visual_id).is_empty():
		errors.append("unknown_visual:%d:%s" % [int(card_id), visual_id])
	if (definition.get("test_coverage", []) as Array).is_empty():
		errors.append("missing_test_coverage:%d" % int(card_id))
	return errors


static func validate_all() -> Array:
	var errors: Array = []
	var seen_ids: Dictionary = {}
	for card_id in get_card_ids():
		if seen_ids.has(int(card_id)):
			errors.append("duplicate_id:%d" % int(card_id))
		seen_ids[int(card_id)] = true
		errors.append_array(validate_card_definition(int(card_id)))
	for card_id in DEFAULT_HAND_IDS:
		if not has_card(int(card_id)):
			errors.append("default_hand_missing:%d" % int(card_id))
	return errors
