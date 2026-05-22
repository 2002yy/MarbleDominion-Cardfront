extends Node2D
class_name CardfrontVfxLayer

const TICK_INTERVAL: float = 0.05
const ENERGY_RIPPLE_DURATION: float = 1.0
const SHIELD_CRACK_DURATION: float = 1.5
const REGION_PULSE_DURATION: float = 2.0

const TEXTURE_BASE := "res://assets/cardfront_runtime/视觉特效_vfx/128/"

var battlefield = null
var region_map = null
var _effects: Array = []
var _elapsed: float = 0.0
var _texture_cache: Dictionary = {}


func _init() -> void:
	name = "CardfrontVfxLayer"
	z_index = 6
	set_process(false)


func setup(new_battlefield, new_region_map, mode_name: String) -> void:
	battlefield = new_battlefield
	region_map = new_region_map
	visible = mode_name == GameConfig.GAME_MODE_CARDFRONT
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
	_effects.clear()
	_texture_cache.clear()
	set_process(visible)


func play_energy_ripple(cell: Vector2i) -> void:
	_add_effect(cell, "energy_ripple", ENERGY_RIPPLE_DURATION)


func play_shield_crack(cell: Vector2i) -> void:
	_add_effect(cell, "shield_crack", SHIELD_CRACK_DURATION)


func play_shield_pulse(cell: Vector2i) -> void:
	play_shield_crack(cell)


func play_region_pulse(region_id: int) -> void:
	if region_id < 0 or region_map == null:
		return
	if not region_map.has_method("get_region_cells"):
		return
	var cells: Array = region_map.get_region_cells(region_id)
	if cells.is_empty():
		return
	_add_effect(cells[0], "region_pulse", REGION_PULSE_DURATION)


func get_active_effects_for_test() -> Array:
	return _effects.duplicate(true)


func _add_effect(cell: Vector2i, effect_type: String, duration: float) -> void:
	var tex = _get_texture(effect_type)
	_effects.append({
		"cell": cell,
		"effect_type": effect_type,
		"remaining": duration,
		"total": duration,
		"texture_loaded": tex != null,
	})
	if visible:
		set_process(true)
	queue_redraw()


func _get_texture(effect_type: String) -> Texture2D:
	if _texture_cache.has(effect_type):
		return _texture_cache[effect_type]
	var path: String = _texture_path(effect_type)
	if path == "" or not ResourceLoader.exists(path):
		_texture_cache[effect_type] = null
		return null
	var tex: Texture2D = load(path)
	_texture_cache[effect_type] = tex
	return tex


func _texture_path(effect_type: String) -> String:
	match effect_type:
		"energy_ripple":
			return TEXTURE_BASE + "能量波纹环_energy_ripple_ring_v01.png"
		"shield_crack":
			return TEXTURE_BASE + "护盾裂纹_shield_crack_v01.png"
		"region_pulse":
			return TEXTURE_BASE + "区域控制脉冲_region_threshold_pulse_v01.png"
	return ""


func _draw() -> void:
	if not visible or battlefield == null:
		return
	var cell_size: int = int(battlefield.cell_size)
	for effect in _effects:
		var cell: Vector2i = effect.get("cell", Vector2i.ZERO)
		var remaining: float = float(effect.get("remaining", 0.0))
		var total: float = maxf(0.01, float(effect.get("total", 1.0)))
		var ratio: float = clampf(remaining / total, 0.0, 1.0)
		var tex = _get_texture(str(effect.get("effect_type", "")))
		if tex != null:
			var size: float = float(cell_size) * 2.5 * ratio
			var pos: Vector2 = Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * float(cell_size)
			var rect := Rect2(pos - Vector2(size * 0.5, size * 0.5), Vector2(size, size))
			draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, ratio))
		else:
			var fallback: Color = _fallback_color(str(effect.get("effect_type", "")))
			var r: float = float(cell_size) * ratio
			var pos: Vector2 = Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * float(cell_size)
			draw_circle(pos, r, Color(fallback.r, fallback.g, fallback.b, ratio * 0.5))


func _fallback_color(effect_type: String) -> Color:
	match effect_type:
		"energy_ripple":
			return Color(0.38, 0.78, 1.0)
		"shield_crack":
			return Color(1.0, 0.35, 0.30)
		_:
			return Color(0.72, 0.45, 1.0)


func _process(delta: float) -> void:
	_elapsed += maxf(0.0, delta)
	while _elapsed >= TICK_INTERVAL:
		_elapsed -= TICK_INTERVAL
		_tick_effects(TICK_INTERVAL)
	queue_redraw()


func _tick_effects(delta: float) -> void:
	var alive: Array = []
	for effect in _effects:
		var remaining: float = float(effect.get("remaining", 0.0)) - maxf(0.0, delta)
		if remaining > 0.0:
			effect["remaining"] = remaining
			alive.append(effect)
	_effects = alive
	if _effects.is_empty():
		set_process(false)
	else:
		queue_redraw()
