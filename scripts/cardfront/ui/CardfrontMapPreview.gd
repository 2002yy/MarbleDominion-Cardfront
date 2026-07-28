extends Control
class_name CardfrontMapPreview

const Catalog = preload("res://scripts/cardfront/ui/CardfrontPresentationCatalog.gd")

var map_id: String = "default_duel"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(new_map_id: String) -> void:
	map_id = new_map_id
	queue_redraw()


func _draw() -> void:
	var field := Rect2(Vector2(8.0, 5.0), size - Vector2(16.0, 10.0))
	var accent: Color = Catalog.map(map_id).get("accent", Color(0.5, 0.7, 0.3))
	draw_rect(field, accent.darkened(0.30), true)
	var cell := Vector2(field.size.x / 8.0, field.size.y / 5.0)
	for x in range(8):
		for y in range(5):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(field.position + Vector2(x * cell.x, y * cell.y), cell), Color(1, 1, 1, 0.055), true)
	var river_y: float = field.position.y + field.size.y * 0.5 - 5.0
	draw_rect(Rect2(field.position.x, river_y, field.size.x, 10.0), Color(0.20, 0.68, 0.82), true)
	for bridge_x in [field.position.x + field.size.x * 0.30, field.position.x + field.size.x * 0.70]:
		draw_rect(Rect2(bridge_x - 8.0, river_y - 3.0, 16.0, 16.0), Color(0.74, 0.52, 0.27), true)
	match map_id:
		"central_lab":
			_draw_stronghold(field.get_center(), Color(0.72, 0.52, 0.93), 13.0)
			_draw_stronghold(field.position + Vector2(field.size.x * 0.24, field.size.y * 0.18), Color(0.95, 0.74, 0.24), 6.0)
			_draw_stronghold(field.position + Vector2(field.size.x * 0.76, field.size.y * 0.82), Color(0.95, 0.74, 0.24), 6.0)
		"cross_resource":
			for point in [
				Vector2(0.25, 0.20), Vector2(0.75, 0.20),
				Vector2(0.25, 0.80), Vector2(0.75, 0.80),
			]:
				_draw_stronghold(field.position + field.size * point, Color(0.96, 0.63, 0.20), 8.0)
			_draw_stronghold(field.get_center(), Color(0.62, 0.48, 0.84), 7.0)
		_:
			for point in [
				Vector2(0.24, 0.20), Vector2(0.76, 0.20), Vector2(0.50, 0.50),
				Vector2(0.24, 0.80), Vector2(0.76, 0.80),
			]:
				_draw_stronghold(field.position + field.size * point, Color(1.0, 0.78, 0.25), 7.0)
	draw_rect(field, accent.lightened(0.25), false, 3.0)


func _draw_stronghold(center: Vector2, color: Color, radius: float) -> void:
	draw_circle(center, radius + 3.0, Color(0.08, 0.11, 0.09, 0.85))
	draw_circle(center, radius, color)
