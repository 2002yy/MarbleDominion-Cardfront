extends Control
class_name CardfrontHeroSilhouette

const Catalog = preload("res://scripts/cardfront/ui/CardfrontPresentationCatalog.gd")

var hero_id: String = "balanced_commander"
var accent: Color = Color(0.20, 0.66, 0.86)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(96.0, 88.0)
	queue_redraw()


func configure(new_hero_id: String) -> void:
	hero_id = new_hero_id
	accent = Catalog.hero(hero_id).get("accent", accent)
	queue_redraw()


func _draw() -> void:
	var center := size * Vector2(0.5, 0.52)
	draw_circle(center + Vector2(0.0, 23.0), 31.0, Color(0.035, 0.07, 0.09))
	draw_circle(center - Vector2(0.0, 14.0), 20.0, accent.darkened(0.18))
	match hero_id:
		"rapid_gunner":
			_draw_gunner(center)
		"fortification_engineer":
			_draw_engineer(center)
		_:
			_draw_commander(center)


func _draw_commander(center: Vector2) -> void:
	var shield := PackedVector2Array([
		center + Vector2(-23, 4), center + Vector2(23, 4),
		center + Vector2(17, 34), center + Vector2(0, 46),
		center + Vector2(-17, 34),
	])
	draw_colored_polygon(shield, accent)
	draw_polyline(PackedVector2Array([center + Vector2(-12, -23), center + Vector2(0, -34), center + Vector2(12, -23)]), Color(1.0, 0.86, 0.32), 6.0)
	draw_line(center + Vector2(0, 8), center + Vector2(0, 34), Color.WHITE, 5.0)
	draw_line(center + Vector2(-10, 21), center + Vector2(10, 21), Color.WHITE, 5.0)


func _draw_gunner(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-26, 5), Vector2(52, 30)), accent, true)
	draw_rect(Rect2(center + Vector2(9, -4), Vector2(38, 12)), Color(0.96, 0.75, 0.31), true)
	draw_circle(center + Vector2(-16, 38), 9.0, Color(0.10, 0.13, 0.14))
	draw_circle(center + Vector2(16, 38), 9.0, Color(0.10, 0.13, 0.14))
	draw_line(center + Vector2(-18, -24), center + Vector2(18, -24), accent.lightened(0.28), 8.0)


func _draw_engineer(center: Vector2) -> void:
	draw_arc(center - Vector2(0, 13), 25.0, PI, TAU, 20, accent, 11.0)
	draw_rect(Rect2(center + Vector2(-30, -15), Vector2(60, 10)), Color(0.96, 0.77, 0.28), true)
	draw_rect(Rect2(center + Vector2(-24, 8), Vector2(48, 31)), accent.darkened(0.08), true)
	for angle in range(0, 360, 45):
		var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
		draw_line(center + Vector2(0, 23) + direction * 14.0, center + Vector2(0, 23) + direction * 24.0, Color(0.12, 0.19, 0.18), 6.0)
	draw_circle(center + Vector2(0, 23), 15.0, Color(0.12, 0.19, 0.18))
	draw_circle(center + Vector2(0, 23), 6.0, Color(0.84, 0.92, 0.72))
