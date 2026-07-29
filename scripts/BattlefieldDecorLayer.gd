extends Node2D
class_name BattlefieldDecorLayer

var grid_size: int = GameConfig.GRID_SIZE
var grid_extent: Vector2i = Vector2i(GameConfig.GRID_SIZE, GameConfig.GRID_SIZE)
var cell_size: int = GameConfig.CELL_SIZE
var grid_alpha: float = 0.0
var emblem_alpha_mul: float = 0.0

var _decor_dirty: bool = true
var _cached_grid_line_alpha: float = -1.0
var _cached_emblem_alpha_mul: float = -1.0


func mark_dirty() -> void:
	_decor_dirty = true
	queue_redraw()


func apply_visual_settings() -> void:
	var new_grid_alpha := GameConfig.get_grid_line_alpha()
	var new_emblem_alpha := GameConfig.get_emblem_alpha_mul()

	if (
		is_equal_approx(new_grid_alpha, _cached_grid_line_alpha)
		and is_equal_approx(new_emblem_alpha, _cached_emblem_alpha_mul)
		and not _decor_dirty
	):
		return

	_cached_grid_line_alpha = new_grid_alpha
	_cached_emblem_alpha_mul = new_emblem_alpha
	_decor_dirty = false

	grid_alpha = new_grid_alpha
	emblem_alpha_mul = new_emblem_alpha
	queue_redraw()


func configure(new_grid_size: int, new_cell_size: int) -> void:
	configure_extent(Vector2i(new_grid_size, new_grid_size), new_cell_size)


func configure_extent(new_grid_extent: Vector2i, new_cell_size: int) -> void:
	if grid_extent == new_grid_extent and cell_size == new_cell_size and not _decor_dirty:
		return
	grid_extent = new_grid_extent
	grid_size = new_grid_extent.x
	cell_size = new_cell_size
	_decor_dirty = false
	queue_redraw()

func _draw() -> void:
	var size := Vector2(grid_extent) * float(cell_size)
	var half_size: Vector2 = size * 0.5

	if emblem_alpha_mul > 0.01:
		_draw_emblems(size)

	draw_line(Vector2(half_size.x, 0), Vector2(half_size.x, size.y), Color.BLACK, 2)
	draw_line(Vector2(0, half_size.y), Vector2(size.x, half_size.y), Color.BLACK, 2)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.95), false, 4)

	for i in range(grid_extent.x + 1):
		var p: float = i * cell_size
		draw_line(Vector2(p, 0), Vector2(p, size.y), Color(0, 0, 0, grid_alpha), 1)
	for i in range(grid_extent.y + 1):
		var p: float = i * cell_size
		draw_line(Vector2(0, p), Vector2(size.x, p), Color(0, 0, 0, grid_alpha), 1)

func _draw_emblems(size: Vector2) -> void:
	var q := size * 0.25
	var r: float = minf(size.x, size.y) * 0.145
	_draw_blue_emblem(Vector2(q.x, q.y), r)
	_draw_red_emblem(Vector2(size.x - q.x, q.y), r)
	_draw_green_emblem(Vector2(q.x, size.y - q.y), r)
	_draw_yellow_emblem(Vector2(size.x - q.x, size.y - q.y), r)

func _draw_blue_emblem(center: Vector2, radius: float) -> void:
	var c: Color = Color(1, 1, 1, 0.11 * emblem_alpha_mul)
	draw_circle(center, radius, c)
	draw_circle(center + Vector2(radius * 0.25, 0), radius * 0.82, Color(0, 0, 0, 0.06))
	draw_arc(center, radius * 1.15, 0.2, TAU - 0.2, 40, Color(1, 1, 1, 0.07 * emblem_alpha_mul), 4.0)

func _draw_red_emblem(center: Vector2, radius: float) -> void:
	var c: Color = Color(1, 1, 1, 0.11 * emblem_alpha_mul)
	draw_circle(center, radius * 0.78, c)
	draw_circle(center + Vector2(-radius * 0.25, -radius * 0.10), radius * 0.14, Color(0, 0, 0, 0.12))
	draw_circle(center + Vector2(radius * 0.25, -radius * 0.10), radius * 0.14, Color(0, 0, 0, 0.12))
	var jaw: PackedVector2Array = PackedVector2Array([
		center + Vector2(-radius * 0.42, radius * 0.12),
		center + Vector2(radius * 0.42, radius * 0.12),
		center + Vector2(radius * 0.28, radius * 0.52),
		center + Vector2(-radius * 0.28, radius * 0.52)
	])
	draw_colored_polygon(jaw, c)

func _draw_green_emblem(center: Vector2, radius: float) -> void:
	var c: Color = Color(1, 1, 1, 0.11 * emblem_alpha_mul)
	draw_circle(center, radius * 0.12, c)
	for i in range(8):
		var ang: float = TAU * float(i) / 8.0
		draw_line(center, center + Vector2.RIGHT.rotated(ang) * radius * 0.72, c, 3.0)
	draw_arc(center, radius * 0.86, 0, TAU, 40, Color(1, 1, 1, 0.09 * emblem_alpha_mul), 4.0)

func _draw_yellow_emblem(center: Vector2, radius: float) -> void:
	var c: Color = Color(1, 1, 1, 0.11 * emblem_alpha_mul)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var rr: float = radius if i % 2 == 0 else radius * 0.45
		var ang: float = -PI * 0.5 + TAU * float(i) / 10.0
		pts.append(center + Vector2.RIGHT.rotated(ang) * rr)
	draw_colored_polygon(pts, c)
