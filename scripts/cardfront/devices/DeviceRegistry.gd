extends RefCounted
class_name DeviceRegistry

const DeviceDataScript = preload("res://scripts/cardfront/devices/DeviceData.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")

var registry: Dictionary = {}


func _init() -> void:
	_register(DeviceTypeScript.ABSORBER_CORE, 3, 45.0, "吸弹核心")
	_register(DeviceTypeScript.ENGINEER_BOT, 2, 60.0, "工程机器人")
	_register(DeviceTypeScript.PIONEER_BEACON, 2, 120.0, "拓荒信标")


func _register(device_type: String, max_per_owner: int, default_lifetime: float, display_name: String) -> void:
	var data = DeviceDataScript.new()
	data.device_type = str(device_type)
	data.max_per_owner = int(max_per_owner)
	data.default_lifetime = float(default_lifetime)
	data.display_name = str(display_name)
	registry[str(device_type)] = data


func get_device_data(device_type: String):
	return registry.get(str(device_type), null)


func get_max_per_owner(device_type: String) -> int:
	var data = get_device_data(device_type)
	if data == null:
		return 0
	return int(data.max_per_owner)


func get_default_lifetime(device_type: String) -> float:
	var data = get_device_data(device_type)
	if data == null:
		return 0.0
	return float(data.default_lifetime)


func is_valid_type(device_type: String) -> bool:
	return DeviceTypeScript.is_valid(device_type)
