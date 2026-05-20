extends RefCounted
class_name CardfrontStatusFormatter

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")


static func build_status_text(runtime) -> String:
	var parts: Array[String] = ["射击ON"]
	parts.append(_bias_text(runtime))
	parts.append("VFX ON" if _vfx_enabled(runtime) else "")
	var result: String = ""
	for p in parts:
		if str(p) != "":
			result += (" | " if result != "" else "") + str(p)
	return result


static func _vfx_enabled(runtime) -> bool:
	return runtime.cardfront_vfx_layer != null and is_instance_valid(runtime.cardfront_vfx_layer) and runtime.cardfront_vfx_layer.visible


static func _bias_text(runtime) -> String:
	if runtime.target_bias_system == null or not is_instance_valid(runtime.target_bias_system):
		return ""
	if not runtime.target_bias_system.has_method("get_biased_region"):
		return ""
	var biased: int = runtime.target_bias_system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION)
	if biased < 0:
		return ""
	var remaining: float = 0.0
	if runtime.target_bias_system.has_method("get_bias_remaining"):
		remaining = runtime.target_bias_system.get_bias_remaining(CardfrontRulesScript.PLAYER_FACTION)
	return "校准#%d %.0fs" % [biased, remaining]
