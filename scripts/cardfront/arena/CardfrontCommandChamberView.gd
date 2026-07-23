extends Node2D
class_name CardfrontCommandChamberView

signal hit_feedback(owner_id, damage)

const CHAMBER_SIZE: Vector2 = Vector2(164.0, 68.0)
const OUTLINE_COLOR: Color = Color(0.01, 0.02, 0.035, 0.98)
const PANEL_COLOR: Color = Color(0.055, 0.075, 0.10, 0.98)
const HIT_FEEDBACK_SECONDS: float = 0.42

var owner_id: int = -1
var turret = null
var is_player: bool = false
var display_name: String = ""
var _last_health: int = 0
var _last_damage: int = 0
var _hit_feedback_remaining: float = 0.0


func _init() -> void:
	name = "CardfrontCommandChamberView"
	z_index = 13
	set_process(false)


func setup(new_owner_id: int, new_turret, player_owned: bool) -> bool:
	owner_id = int(new_owner_id)
	turret = new_turret
	is_player = bool(player_owned)
	display_name = "玩家控制舱" if is_player else "AI 控制舱"
	if turret == null or not is_instance_valid(turret):
		visible = false
		return false
	global_position = turret.global_position
	_last_health = int(turret.health)
	var health_callable := Callable(self, "_on_health_changed")
	if turret.has_signal("health_changed") and not turret.health_changed.is_connected(health_callable):
		turret.health_changed.connect(health_callable)
	var destroyed_callable := Callable(self, "_on_destroyed")
	if turret.has_signal("destroyed") and not turret.destroyed.is_connected(destroyed_callable):
		turret.destroyed.connect(destroyed_callable)
	visible = true
	queue_redraw()
	return true


func get_health_ratio_for_test() -> float:
	if turret == null or not is_instance_valid(turret):
		return 0.0
	return clampf(float(turret.health) / maxf(1.0, float(turret.max_health)), 0.0, 1.0)


func get_global_bounds_for_test() -> Rect2:
	var local_rect: Rect2 = _chamber_rect()
	return Rect2(global_position + local_rect.position, local_rect.size)


func is_hit_feedback_active_for_test() -> bool:
	return _hit_feedback_remaining > 0.0


func get_last_damage_for_test() -> int:
	return _last_damage


func _process(delta: float) -> void:
	if _hit_feedback_remaining <= 0.0:
		set_process(false)
		return
	_hit_feedback_remaining = maxf(0.0, _hit_feedback_remaining - maxf(0.0, delta))
	queue_redraw()
	if _hit_feedback_remaining <= 0.0:
		set_process(false)


func _on_health_changed(_faction_id: int, new_health: int, _max_health: int) -> void:
	var damage: int = maxi(0, _last_health - int(new_health))
	_last_health = int(new_health)
	if damage > 0:
		_last_damage = damage
		_hit_feedback_remaining = HIT_FEEDBACK_SECONDS
		set_process(true)
		hit_feedback.emit(owner_id, damage)
	queue_redraw()


func _on_destroyed(_faction_id: int) -> void:
	_hit_feedback_remaining = maxf(_hit_feedback_remaining, HIT_FEEDBACK_SECONDS)
	set_process(true)
	queue_redraw()


func _chamber_rect() -> Rect2:
	var y: float = -CHAMBER_SIZE.y - 4.0 if is_player else 4.0
	return Rect2(Vector2(-CHAMBER_SIZE.x * 0.5, y), CHAMBER_SIZE)


func _draw() -> void:
	if not visible:
		return
	var rect: Rect2 = _chamber_rect()
	rect.position += _hit_offset()
	var color: Color = GameConfig.faction_color(owner_id)
	if turret != null and is_instance_valid(turret) and bool(turret.is_destroyed):
		color = Color(0.32, 0.34, 0.38)
	var chamfer: float = 13.0
	var points := PackedVector2Array([
		rect.position + Vector2(chamfer, 0.0),
		Vector2(rect.end.x - chamfer, rect.position.y),
		rect.end - Vector2(0.0, rect.size.y - chamfer),
		rect.end - Vector2(chamfer, 0.0),
		Vector2(rect.position.x + chamfer, rect.end.y),
		rect.position + Vector2(0.0, rect.size.y - chamfer),
	])
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(5.0, 6.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.34))
	draw_colored_polygon(points, PANEL_COLOR)
	var hit_ratio: float = _hit_feedback_remaining / HIT_FEEDBACK_SECONDS
	if hit_ratio > 0.0:
		draw_colored_polygon(points, Color(1.0, 0.22, 0.12, 0.28 * hit_ratio))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, OUTLINE_COLOR, 7.0, true)
	draw_polyline(outline, color.lightened(0.16), 3.0, true)

	var header_rect := Rect2(rect.position + Vector2(10.0, 8.0), Vector2(rect.size.x - 20.0, 23.0))
	draw_rect(header_rect, Color(color.r, color.g, color.b, 0.28), true)
	draw_string(
		ThemeDB.fallback_font,
		header_rect.position + Vector2(0.0, 17.0),
		display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		header_rect.size.x,
		16,
		Color.WHITE
	)
	var ratio: float = get_health_ratio_for_test()
	var bar_rect := Rect2(rect.position + Vector2(18.0, 42.0), Vector2(rect.size.x - 36.0, 11.0))
	draw_rect(bar_rect, OUTLINE_COLOR, true)
	draw_rect(bar_rect.grow(-2.0), Color(0.12, 0.15, 0.18), true)
	var fill_rect := bar_rect.grow(-2.0)
	fill_rect.size.x *= ratio
	var hp_color: Color = color.lightened(0.28)
	if ratio < 0.35:
		hp_color = Color(1.0, 0.24, 0.18)
	draw_rect(fill_rect, hp_color, true)
	draw_string(
		ThemeDB.fallback_font,
		bar_rect.position + Vector2(0.0, 10.0),
		"%d / %d" % [
			int(turret.health) if turret != null and is_instance_valid(turret) else 0,
			int(turret.max_health) if turret != null and is_instance_valid(turret) else 0,
		],
		HORIZONTAL_ALIGNMENT_CENTER,
		bar_rect.size.x,
		11,
		Color.WHITE
	)
	if hit_ratio > 0.0 and _last_damage > 0:
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(0.0, -7.0 if is_player else rect.size.y + 19.0),
			"-%d" % _last_damage,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			18,
			Color(1.0, 0.38, 0.22, hit_ratio)
		)


func _hit_offset() -> Vector2:
	if _hit_feedback_remaining <= 0.0:
		return Vector2.ZERO
	var progress: float = 1.0 - _hit_feedback_remaining / HIT_FEEDBACK_SECONDS
	var strength: float = _hit_feedback_remaining / HIT_FEEDBACK_SECONDS
	return Vector2(sin(progress * TAU * 3.0) * 5.0 * strength, 0.0)
