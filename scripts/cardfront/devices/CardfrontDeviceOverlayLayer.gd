extends Node2D
class_name CardfrontDeviceOverlayLayer

var device_layer = null
var battlefield = null
var _texture_cache: Dictionary = {}
var _dirty: bool = true


func _init() -> void:
	name = "CardfrontDeviceOverlayLayer"
	z_index = 5
	set_process(false)


func setup(new_device_layer, new_battlefield, mode_name: String) -> void:
	device_layer = new_device_layer
	battlefield = new_battlefield
	visible = mode_name == GameConfig.GAME_MODE_CARDFRONT
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
	_texture_cache.clear()
	set_process(visible)
	mark_dirty()


func mark_dirty() -> void:
	_dirty = true
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not visible or device_layer == null or battlefield == null:
		return

	for instance in device_layer.get_all_active_devices():
		var tex = _get_texture(str(instance.device_type))
		if tex == null:
			continue
		var cell: Vector2i = instance.cell
		var cell_size: int = int(battlefield.cell_size)
		var rect := Rect2(Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))
		draw_texture_rect(tex, rect, false)


func _get_texture(device_type: String) -> Texture2D:
	if _texture_cache.has(device_type):
		return _texture_cache[device_type]
	var path: String = _texture_path(device_type)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	_texture_cache[device_type] = tex
	return tex


func _texture_path(device_type: String) -> String:
	var base := "res://assets/cardfront_runtime/装置精灵_devices/96/"
	match device_type:
		"absorber_core":
			return base + "吸弹核心_absorber_core_v01.png"
		"engineer_bot":
			return base + "工程机器人_engineer_bot_v01.png"
		"pioneer_beacon":
			return base + "拓荒信标_pioneer_beacon_v01.png"
		"temporary_reflector":
			return base + "临时反弹板_temporary_reflector_v01.png"
	return ""
