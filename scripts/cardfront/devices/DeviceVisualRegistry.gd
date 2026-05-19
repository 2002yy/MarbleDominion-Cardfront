extends RefCounted
class_name DeviceVisualRegistry

const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")

const RUNTIME_BASE: String = "res://assets/cardfront_runtime/装置精灵_devices/96/"

var _path_map: Dictionary = {}
var _fallback_color_map: Dictionary = {}
var _label_map: Dictionary = {}


func _init() -> void:
	_register(DeviceTypeScript.ABSORBER_CORE, "吸弹核心_absorber_core_v01.png", Color(0.30, 0.60, 1.0), "吸弹核心")
	_register(DeviceTypeScript.ENGINEER_BOT, "工程机器人_engineer_bot_v01.png", Color(1.0, 0.55, 0.22), "工程机器人")
	_register(DeviceTypeScript.PIONEER_BEACON, "拓荒信标_pioneer_beacon_v01.png", Color(0.72, 0.45, 1.0), "拓荒信标")
	_register("temporary_reflector", "临时反弹板_temporary_reflector_v01.png", Color(0.85, 0.85, 0.35), "临时反弹板")


func _register(device_type: String, filename: String, fallback_color: Color, label: String) -> void:
	_path_map[str(device_type)] = RUNTIME_BASE + filename
	_fallback_color_map[str(device_type)] = fallback_color
	_label_map[str(device_type)] = str(label)


func get_texture_path(device_type: String) -> String:
	return _path_map.get(str(device_type), "")


func get_fallback_color(device_type: String) -> Color:
	return _fallback_color_map.get(str(device_type), Color.GRAY)


func get_label(device_type: String) -> String:
	return _label_map.get(str(device_type), str(device_type))
