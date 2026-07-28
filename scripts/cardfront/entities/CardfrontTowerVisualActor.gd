extends Node2D
class_name CardfrontTowerVisualActor

signal destruction_finished(entity_id)

const FIRE_CONTROL_BEACON: String = "fire_control_beacon"
const INTERCEPTOR_TOWER: String = "interceptor_tower"
const EFFECT_DURATION: float = 0.48

var entity_id: String = ""
var tower_id: String = ""
var owner_color: Color = Color.WHITE
var cell_size: float = 16.0
var powered: bool = true
var tower_level: int = 1
var intercepts_remaining: int = 0
var _effect: String = ""
var _effect_elapsed: float = 0.0
var _destroyed: bool = false


func setup(
	new_entity_id: String,
	new_tower_id: String,
	new_owner_color: Color,
	new_cell_size: float,
	initial_cell: Vector2i
) -> void:
	entity_id = str(new_entity_id)
	tower_id = str(new_tower_id)
	owner_color = new_owner_color
	cell_size = maxf(1.0, new_cell_size)
	position = (Vector2(initial_cell) + Vector2(0.5, 0.5)) * cell_size
	z_index = -1
	queue_redraw()


func sync(entity) -> void:
	if entity == null:
		return
	position = (Vector2(entity.cell) + Vector2(0.5, 0.5)) * cell_size
	powered = bool(entity.powered)
	tower_level = maxi(1, int(entity.tower_level))
	intercepts_remaining = maxi(0, int(entity.intercepts_remaining))
	queue_redraw()


func play_guidance() -> void:
	_start_effect("guidance")


func play_intercept() -> void:
	_start_effect("intercept")


func play_counter() -> void:
	_start_effect("counter")


func play_fire() -> void:
	_start_effect("fire")


func play_hit() -> void:
	_start_effect("hit")


func play_destroyed() -> void:
	if _destroyed:
		return
	_destroyed = true
	_start_effect("destroyed")


func is_destroyed() -> bool:
	return _destroyed


func _process(delta: float) -> void:
	if _effect.is_empty():
		set_process(false)
		return
	_effect_elapsed += maxf(0.0, delta)
	queue_redraw()
	if _effect_elapsed < EFFECT_DURATION:
		return
	var completed_effect := _effect
	_effect = ""
	set_process(false)
	queue_redraw()
	if completed_effect == "destroyed":
		destruction_finished.emit(entity_id)


func _draw() -> void:
	var unit: float = cell_size
	var pulse: float = sin(clampf(_effect_elapsed / EFFECT_DURATION, 0.0, 1.0) * PI)
	draw_ellipse_shadow(unit)
	if _destroyed:
		_draw_destroyed(unit, pulse)
		return
	var body_color := owner_color if powered else Color(0.36, 0.39, 0.42, 1.0)
	draw_rect(
		Rect2(Vector2(-0.35, -0.10) * unit, Vector2(0.70, 0.48) * unit),
		Color(0.10, 0.13, 0.16, 1.0),
		true
	)
	draw_rect(
		Rect2(Vector2(-0.28, -0.17) * unit, Vector2(0.56, 0.46) * unit),
		body_color,
		true
	)
	draw_rect(
		Rect2(Vector2(-0.28, -0.17) * unit, Vector2(0.56, 0.46) * unit),
		Color(0.08, 0.11, 0.14, 1.0),
		false,
		maxf(1.5, unit * 0.06)
	)
	if tower_id == FIRE_CONTROL_BEACON:
		_draw_beacon(unit, body_color, pulse)
	else:
		_draw_interceptor(unit, body_color, pulse)
	if not powered:
		draw_line(Vector2(-0.24, -0.35) * unit, Vector2(0.24, 0.10) * unit, Color(1.0, 0.30, 0.22), 2.5)
		draw_line(Vector2(0.24, -0.35) * unit, Vector2(-0.24, 0.10) * unit, Color(1.0, 0.30, 0.22), 2.5)
	if _effect == "hit":
		draw_circle(Vector2.ZERO, unit * (0.34 + pulse * 0.18), Color(1.0, 0.28, 0.20, 0.24 * pulse))


func draw_ellipse_shadow(unit: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2(0.0, unit * 0.75), unit * 0.34, Color(0.05, 0.07, 0.08, 0.28))
	draw_set_transform(Vector2.ZERO)


func _draw_beacon(unit: float, body_color: Color, pulse: float) -> void:
	draw_line(Vector2(0.0, -0.17) * unit, Vector2(0.0, -0.54) * unit, Color(0.12, 0.16, 0.19), maxf(3.0, unit * 0.11))
	draw_circle(Vector2(0.0, -0.52) * unit, unit * 0.13, Color(0.08, 0.12, 0.15))
	draw_circle(Vector2(0.0, -0.52) * unit, unit * 0.075, body_color.lightened(0.35))
	if _effect in ["guidance", "fire"]:
		for radius_step in range(2):
			draw_arc(
				Vector2(0.0, -0.52) * unit,
				unit * (0.18 + radius_step * 0.11 + pulse * 0.10),
				0.0,
				TAU,
				24,
				Color(0.32, 0.94, 1.0, 0.78 * (1.0 - pulse * 0.45)),
				maxf(1.5, unit * 0.045)
			)


func _draw_interceptor(unit: float, body_color: Color, pulse: float) -> void:
	var recoil: float = pulse * 0.10 if _effect in ["counter", "fire"] else 0.0
	draw_line(
		Vector2(-recoil, -0.24) * unit,
		Vector2(0.34 - recoil, -0.45) * unit,
		Color(0.12, 0.16, 0.19),
		maxf(4.0, unit * 0.14)
	)
	draw_circle(Vector2(-0.08, -0.23) * unit, unit * 0.16, body_color.lightened(0.18))
	if _effect == "intercept":
		draw_arc(
			Vector2(0.0, -0.18) * unit,
			unit * (0.42 + pulse * 0.18),
			PI * 1.05,
			PI * 1.95,
			24,
			Color(0.32, 0.88, 1.0, 0.88),
			maxf(2.0, unit * 0.075)
		)
	if _effect == "counter":
		draw_circle(Vector2(0.38, -0.46) * unit, unit * (0.06 + pulse * 0.09), Color(1.0, 0.78, 0.22, 0.9))


func _draw_destroyed(unit: float, pulse: float) -> void:
	for index in range(7):
		var angle := float(index) / 7.0 * TAU
		var distance := unit * (0.10 + pulse * 0.38)
		var center := Vector2.RIGHT.rotated(angle) * distance
		draw_rect(
			Rect2(center - Vector2.ONE * unit * 0.06, Vector2.ONE * unit * 0.12),
			owner_color.darkened(0.25),
			true
		)
	draw_circle(Vector2.ZERO, unit * (0.16 + pulse * 0.20), Color(1.0, 0.46, 0.18, 0.55 * pulse))


func _start_effect(effect_name: String) -> void:
	if _destroyed and effect_name != "destroyed":
		return
	_effect = effect_name
	_effect_elapsed = 0.0
	set_process(true)
	queue_redraw()
