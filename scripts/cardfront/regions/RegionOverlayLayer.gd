extends Node2D
class_name RegionOverlayLayer

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

var region_map = null
var battlefield = null
var cell_size: int = GameConfig.CELL_SIZE
var _dirty: bool = true


func _init() -> void:
	name = "RegionOverlayLayer"
	z_index = 2
	set_process(false)


func setup(new_region_map, new_battlefield, mode_name: String) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	visible = mode_name == GameConfig.GAME_MODE_CARDFRONT
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
		cell_size = int(battlefield.cell_size)
	mark_dirty()


func mark_dirty() -> void:
	_dirty = true
	queue_redraw()


func _draw() -> void:
	if not visible or not _dirty:
		return
	if region_map == null:
		return
	if int(region_map.grid_size) <= 0:
		return

	_dirty = false
	for x in range(int(region_map.grid_size)):
		for y in range(int(region_map.grid_size)):
			var region_type: String = region_map.get_region_type(Vector2i(x, y))
			if region_type == RegionTypeScript.NORMAL:
				continue
			var rect := Rect2(Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))
			match region_type:
				RegionTypeScript.ENERGY:
					draw_rect(rect.grow(-1.0), Color(0.35, 0.82, 1.0, 0.18), true)
					draw_circle(rect.get_center(), maxf(1.2, float(cell_size) * 0.16), Color(0.65, 0.95, 1.0, 0.42))
				RegionTypeScript.FACTORY:
					draw_rect(rect.grow(-1.0), Color(1.0, 0.64, 0.22, 0.17), true)
					draw_rect(Rect2(rect.position + Vector2(cell_size * 0.28, cell_size * 0.28), Vector2(cell_size * 0.44, cell_size * 0.44)), Color(1.0, 0.78, 0.38, 0.34), false, 1.0)
				RegionTypeScript.LAB:
					draw_rect(rect.grow(-1.0), Color(0.72, 0.45, 1.0, 0.20), true)
					draw_circle(rect.get_center(), maxf(1.5, float(cell_size) * 0.22), Color(0.88, 0.74, 1.0, 0.45))
