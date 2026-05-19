extends RefCounted
class_name CardfrontStatusFormatter

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")


static func build_status_text(runtime) -> String:
	var parts: Array[String] = ["射击ON"]
	parts.append(_device_text(runtime))
	parts.append(_card_text(runtime))
	parts.append(_bias_text(runtime))
	parts.append("VFX ON" if _vfx_enabled(runtime) else "")
	var result: String = ""
	for p in parts:
		if str(p) != "":
			result += (" | " if result != "" else "") + str(p)
	return result


static func _vfx_enabled(runtime) -> bool:
	return runtime.cardfront_vfx_layer != null and is_instance_valid(runtime.cardfront_vfx_layer) and runtime.cardfront_vfx_layer.visible


static func _device_text(runtime) -> String:
	if runtime.device_layer == null or not is_instance_valid(runtime.device_layer):
		return "设备 -"
	if not runtime.device_layer.has_method("get_all_active_devices"):
		return "设备 -"
	var devices = runtime.device_layer.get_all_active_devices()
	var counts: Dictionary = {}
	for d in devices:
		var t: String = str(d.device_type)
		counts[t] = int(counts.get(t, 0)) + 1
	if counts.is_empty():
		return "设备 0"
	var entries: Array[String] = []
	if counts.has("absorber_core"): entries.append("吸弹%d" % int(counts.absorber_core))
	if counts.has("engineer_bot"): entries.append("工程%d" % int(counts.engineer_bot))
	if counts.has("pioneer_beacon"): entries.append("信标%d" % int(counts.pioneer_beacon))
	return "设备 " + " ".join(entries)


static func _card_text(runtime) -> String:
	if runtime.card_system == null or not is_instance_valid(runtime.card_system):
		return "卡牌 -"
	if not runtime.card_system.has_method("get_available_card_data"):
		return "卡牌 -"
	var available = runtime.card_system.get_available_card_data()
	return "卡牌%d手" % available.size()


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
