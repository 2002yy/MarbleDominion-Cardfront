extends Node2D
class_name CardfrontDeviceOverlayLayer

var device_layer = null
var battlefield = null
var device_visual_registry = null
var _texture_cache: Dictionary = {}
var _dirty: bool = true

const DeviceVisualRegistryScript = preload("res://scripts/cardfront/devices/DeviceVisualRegistry.gd")


func _init() -> void:
	name = "CardfrontDeviceOverlayLayer"
	z_index = 5
	device_visual_registry = DeviceVisualRegistryScript.new()
	set_process(false)


func setup(new_device_layer, new_battlefield, mode_name: String) -> void:
	device_layer = new_device_layer
	battlefield = new_battlefield
	visible = mode_name == GameConfig.GAME_MODE_CARDFRONT
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
	_texture_cache.clear()
	set_process(false)
	mark_dirty()


func mark_dirty() -> void:
	_dirty = true
	queue_redraw()


func _draw() -> void:
	if not visible or not _dirty or device_layer == null or battlefield == null:
		return
	_dirty = false

	for instance in device_layer.get_all_active_devices():
		var tex = _get_texture(str(instance.device_type))
		var cell: Vector2i = instance.cell
		var cell_size: int = int(battlefield.cell_size)
		var rect := Rect2(Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))
		if tex != null:
			draw_texture_rect(tex, rect, false)
		else:
			var fallback: Color = device_visual_registry.get_fallback_color(str(instance.device_type))
			draw_rect(rect, Color(fallback.r, fallback.g, fallback.b, 0.55), true)
			draw_rect(rect, fallback.lightened(0.3), false, 1.5)


func _get_texture(device_type: String) -> Texture2D:
	if _texture_cache.has(device_type):
		return _texture_cache[device_type]
	var path: String = device_visual_registry.get_texture_path(str(device_type))
	if path == "" or not ResourceLoader.exists(path):
		_texture_cache[device_type] = null
		return null
	var tex: Texture2D = load(path)
	_texture_cache[device_type] = tex
	return tex


func get_draw_items_for_test() -> Array:
	var items = []
	if device_layer == null:
		return items
	for instance in device_layer.get_all_active_devices():
		var device_type: String = str(instance.device_type)
		items.append({
			"device_type": device_type,
			"cell": instance.cell,
			"owner_id": instance.owner_id,
			"texture_path": device_visual_registry.get_texture_path(device_type),
			"texture_loaded": _get_texture(device_type) != null,
			"has_fallback": device_visual_registry.get_fallback_color(device_type) != Color.GRAY,
		})
	return items
