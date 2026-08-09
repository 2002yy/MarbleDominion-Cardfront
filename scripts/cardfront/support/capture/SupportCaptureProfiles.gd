extends RefCounted
class_name SupportCaptureProfiles

const PROFILE_LIGHT_CONTROL: String = "light_control"
const PROFILE_STANDARD_CONTROL: String = "standard_control"
const PROFILE_HEAVY_CONTROL: String = "heavy_control"
const PROFILE_NON_CONTROL: String = "non_control"

const TAG_GOOD_AT_CAPTURE: String = "good_at_capture"
const TAG_STANDARD_CAPTURE: String = "standard_capture"
const TAG_SLOW_CAPTURE: String = "slow_capture"
const TAG_CANNOT_CAPTURE: String = "cannot_capture"

const PROFILE_DEFINITIONS: Dictionary = {
	PROFILE_LIGHT_CONTROL: {"weight": 2.0, "tag": TAG_GOOD_AT_CAPTURE},
	PROFILE_STANDARD_CONTROL: {"weight": 1.0, "tag": TAG_STANDARD_CAPTURE},
	PROFILE_HEAVY_CONTROL: {"weight": 0.5, "tag": TAG_SLOW_CAPTURE},
	PROFILE_NON_CONTROL: {"weight": 0.0, "tag": TAG_CANNOT_CAPTURE},
}

const CREATURE_PROFILE_BY_ID: Dictionary = {
	"scout_unit": PROFILE_LIGHT_CONTROL,
	"repair_unit": PROFILE_STANDARD_CONTROL,
	"sapper_unit": PROFILE_STANDARD_CONTROL,
	"armored_guard": PROFILE_HEAVY_CONTROL,
	"gate_colossus": PROFILE_NON_CONTROL,
}


static func profile_for_creature(creature_id: String) -> String:
	return str(CREATURE_PROFILE_BY_ID.get(str(creature_id), PROFILE_NON_CONTROL))


static func definition_for_profile(profile_id: String) -> Dictionary:
	return (PROFILE_DEFINITIONS.get(str(profile_id), PROFILE_DEFINITIONS[PROFILE_NON_CONTROL]) as Dictionary).duplicate(true)


static func weight_for_profile(profile_id: String) -> float:
	return maxf(0.0, float(definition_for_profile(profile_id).get("weight", 0.0)))


static func tag_for_profile(profile_id: String) -> String:
	return str(definition_for_profile(profile_id).get("tag", TAG_CANNOT_CAPTURE))


static func validate_all() -> Array:
	var errors: Array = []
	for profile_id in PROFILE_DEFINITIONS.keys():
		var definition: Dictionary = PROFILE_DEFINITIONS[profile_id] as Dictionary
		if float(definition.get("weight", -1.0)) < 0.0:
			errors.append("negative_capture_weight:%s" % profile_id)
		if str(definition.get("tag", "")) == "":
			errors.append("missing_capture_tag:%s" % profile_id)
	for creature_id in CREATURE_PROFILE_BY_ID.keys():
		var profile_id: String = str(CREATURE_PROFILE_BY_ID[creature_id])
		if not PROFILE_DEFINITIONS.has(profile_id):
			errors.append("unknown_capture_profile:%s:%s" % [creature_id, profile_id])
	return errors
