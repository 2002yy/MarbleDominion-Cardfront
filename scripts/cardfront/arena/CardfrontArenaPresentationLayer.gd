extends Node2D
class_name CardfrontArenaPresentationLayer

const FLOOR_COLOR: Color = Color(0.56, 0.72, 0.52, 1.0)
const FLOOR_INNER: Color = Color(0.67, 0.79, 0.59, 1.0)
const FLOOR_OUTLINE: Color = Color(0.18, 0.31, 0.25, 0.96)
const CENTER_ACCENT: Color = Color(0.32, 0.78, 0.92, 0.72)
const PLAYER_ACCENT: Color = Color(0.18, 0.66, 0.96, 0.72)
const AI_ACCENT: Color = Color(0.94, 0.31, 0.42, 0.68)

var battlefield = null
var battlefield_rect: Rect2 = Rect2()
var floor_polygon: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	name = "CardfrontArenaPresentationLayer"
	z_index = -5
	set_process(false)


func setup(new_battlefield, layout: Dictionary) -> bool:
	battlefield = new_battlefield
	battlefield_rect = layout.get("battlefield_rect", Rect2())
	if battlefield == null or not is_instance_valid(battlefield) or battlefield_rect.size == Vector2.ZERO:
		visible = false
		return false
	floor_polygon = _build_floor_polygon(battlefield_rect)
	visible = true
	queue_redraw()
	return true


func get_floor_polygon_for_test() -> PackedVector2Array:
	return floor_polygon


func _build_floor_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position + Vector2(24.0, -20.0),
		Vector2(rect.end.x - 24.0, rect.position.y - 20.0),
		rect.end + Vector2(48.0, 38.0),
		Vector2(rect.position.x - 48.0, rect.end.y + 38.0),
	])


func _draw() -> void:
	if not visible or floor_polygon.size() != 4:
		return
	var shadow := PackedVector2Array()
	for point in floor_polygon:
		shadow.append(point + Vector2(0.0, 12.0))
	draw_colored_polygon(shadow, Color(0.08, 0.18, 0.16, 0.24))
	draw_colored_polygon(floor_polygon, FLOOR_COLOR)
	var outline := floor_polygon.duplicate()
	outline.append(floor_polygon[0])
	draw_polyline(outline, FLOOR_OUTLINE, 8.0, true)

	var inset := battlefield_rect.grow(10.0)
	draw_rect(inset, FLOOR_INNER, true)
	draw_rect(inset, FLOOR_OUTLINE, false, 5.0)
	var center_y: float = battlefield_rect.get_center().y
	draw_line(
		Vector2(battlefield_rect.position.x - 20.0, center_y),
		Vector2(battlefield_rect.end.x + 20.0, center_y),
		FLOOR_OUTLINE,
		9.0,
		true
	)
	draw_line(
		Vector2(battlefield_rect.position.x - 20.0, center_y),
		Vector2(battlefield_rect.end.x + 20.0, center_y),
		CENTER_ACCENT,
		3.0,
		true
	)
	for lane_ratio in [0.25, 0.5, 0.75]:
		var lane_x: float = lerpf(battlefield_rect.position.x, battlefield_rect.end.x, lane_ratio)
		draw_line(
			Vector2(lane_x, battlefield_rect.position.y - 10.0),
			Vector2(lane_x, battlefield_rect.end.y + 14.0),
			Color(0.55, 0.78, 0.82, 0.10),
			2.0,
			true
		)
	draw_line(
		Vector2(battlefield_rect.position.x - 30.0, battlefield_rect.end.y + 22.0),
		Vector2(battlefield_rect.end.x + 30.0, battlefield_rect.end.y + 22.0),
		PLAYER_ACCENT,
		6.0,
		true
	)
	draw_line(
		Vector2(battlefield_rect.position.x - 12.0, battlefield_rect.position.y - 12.0),
		Vector2(battlefield_rect.end.x + 12.0, battlefield_rect.position.y - 12.0),
		AI_ACCENT,
		5.0,
		true
	)
