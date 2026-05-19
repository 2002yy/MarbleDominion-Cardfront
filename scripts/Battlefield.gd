extends Node2D
class_name Battlefield

signal scores_changed(counts)

const BattlefieldDecorLayerScript = preload("res://scripts/BattlefieldDecorLayer.gd")

const UNKNOWN_OWNER_COLOR: Color = Color(0.28, 0.31, 0.38, 0.94)

var grid_size: int = GameConfig.GRID_SIZE
var cell_size: int = GameConfig.CELL_SIZE
var owners: Array = []
var owner_counts: Dictionary = _empty_owner_counts()
var owner_color_overrides: Dictionary = {}
var redraw_pending: bool = false
var score_emit_pending: bool = false
var redraw_elapsed: float = 0.0
var score_emit_elapsed: float = 0.0
var changed_cells_since_draw: int = 0

var cell_image: Image
var cell_texture: ImageTexture
var cell_texture_dirty: bool = false
var debug_elapsed: float = 0.0
var redraw_calls_this_second: int = 0
var redraw_calls_per_second: int = 0
var cell_changes_this_second: int = 0
var cell_changes_per_second: int = 0
var capture_interceptor = null
var decor_layer: BattlefieldDecorLayer

const LOW_CHANGE_REDRAW_INTERVAL: float = 0.016
const MID_CHANGE_REDRAW_INTERVAL: float = 0.033
const HIGH_CHANGE_REDRAW_INTERVAL: float = 0.050
const SCORE_EMIT_INTERVAL: float = 0.080

func _process(delta: float) -> void:
	if redraw_pending:
		redraw_elapsed += delta
		if redraw_elapsed >= _current_redraw_interval():
			_upload_cell_texture()
			queue_redraw()
			redraw_pending = false
			redraw_elapsed = 0.0
			changed_cells_since_draw = 0

	if score_emit_pending:
		score_emit_elapsed += delta
		if score_emit_elapsed >= SCORE_EMIT_INTERVAL:
			scores_changed.emit(count_cells_by_team())
			score_emit_pending = false
			score_emit_elapsed = 0.0

	debug_elapsed += delta
	if debug_elapsed >= 1.0:
		redraw_calls_per_second = redraw_calls_this_second
		cell_changes_per_second = cell_changes_this_second
		redraw_calls_this_second = 0
		cell_changes_this_second = 0
		debug_elapsed = 0.0

func configure(new_grid_size: int) -> void:
	grid_size = new_grid_size
	match grid_size:
		10:
			cell_size = 34
		20:
			cell_size = 22
		30:
			cell_size = 16
		40:
			cell_size = 13
		50:
			cell_size = 11
		60:
			cell_size = 9
		_:
			cell_size = GameConfig.CELL_SIZE
	_ensure_decor_layer()
	decor_layer.configure(grid_size, cell_size)
	decor_layer.apply_visual_settings()

func apply_quality_style() -> void:
	_ensure_decor_layer()
	decor_layer.apply_visual_settings()

func mark_decor_dirty() -> void:
	_ensure_decor_layer()
	decor_layer.mark_dirty()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_decor_layer()
	decor_layer.configure(grid_size, cell_size)
	decor_layer.apply_visual_settings()
	reset_quadrants()
	queue_redraw()
	scores_changed.emit(count_cells_by_team())

func reset_quadrants() -> void:
	owners.clear()
	owner_counts = _empty_owner_counts()
	var half_grid: int = grid_size >> 1
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			var f: int = GameConfig.Faction.BLUE
			if x >= half_grid and y < half_grid:
				f = GameConfig.Faction.RED
			elif x < half_grid and y >= half_grid:
				f = GameConfig.Faction.GREEN
			elif x >= half_grid and y >= half_grid:
				f = GameConfig.Faction.YELLOW
			col.append(f)
			_add_owner_count(f, 1)
		owners.append(col)
	_rebuild_cell_texture()

func replace_owners(new_owners: Array, emit_scores: bool = true) -> bool:
	if not _owner_grid_matches_size(new_owners):
		return false
	owners.clear()
	for x in range(grid_size):
		var col: Array = []
		var src_col: Array = new_owners[x] as Array
		for y in range(grid_size):
			col.append(int(src_col[y]))
		owners.append(col)
	rebuild_owner_counts()
	_request_visual_update()
	if emit_scores:
		scores_changed.emit(count_cells_by_team())
	return true

func rebuild_owner_counts() -> void:
	owner_counts = _empty_owner_counts()
	for x in range(grid_size):
		for y in range(grid_size):
			var cell_owner: int = int(owners[x][y])
			owners[x][y] = cell_owner
			_add_owner_count(cell_owner, 1)
	_rebuild_cell_texture()

func set_owner_color_override(owner_id: int, color: Color, refresh: bool = true) -> void:
	owner_color_overrides[owner_id] = color
	if refresh:
		_rebuild_cell_texture()
		queue_redraw()

func clear_owner_color_overrides(refresh: bool = true) -> void:
	owner_color_overrides.clear()
	if refresh:
		_rebuild_cell_texture()
		queue_redraw()

func world_to_cell(world_position: Vector2) -> Vector2i:
	var lp: Vector2 = to_local(world_position)
	return Vector2i(floori(lp.x / float(cell_size)), floori(lp.y / float(cell_size)))

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size

func apply_bullet(cell: Vector2i, faction_id: int) -> String:
	if not is_inside(cell):
		return "OUTSIDE"
	var old: int = owners[cell.x][cell.y]
	if old == faction_id:
		return "SAME_CELL"
	if capture_interceptor != null and is_instance_valid(capture_interceptor) and capture_interceptor.has_method("should_block_capture"):
		if capture_interceptor.should_block_capture(cell, faction_id, old):
			return "BLOCKED_BY_FORTIFY"
	owners[cell.x][cell.y] = faction_id
	_add_owner_count(old, -1)
	_add_owner_count(faction_id, 1)
	_paint_cached_cell(cell, faction_id)
	_request_visual_update()
	_request_score_emit()
	return "HIT_ENEMY_CELL"

func count_cells_by_team() -> Dictionary:
	return owner_counts.duplicate()

func flush_visual_update() -> void:
	redraw_pending = false
	redraw_elapsed = 0.0
	changed_cells_since_draw = 0
	_upload_cell_texture()
	queue_redraw()

func flush_score_emit() -> void:
	score_emit_pending = false
	score_emit_elapsed = 0.0
	scores_changed.emit(count_cells_by_team())

func _request_visual_update() -> void:
	changed_cells_since_draw += 1
	cell_changes_this_second += 1
	redraw_pending = true

func _request_score_emit() -> void:
	score_emit_pending = true

func _current_redraw_interval() -> float:
	if changed_cells_since_draw >= 48:
		return HIGH_CHANGE_REDRAW_INTERVAL
	if changed_cells_since_draw >= 12:
		return MID_CHANGE_REDRAW_INTERVAL
	return LOW_CHANGE_REDRAW_INTERVAL

func _ensure_decor_layer() -> void:
	if decor_layer != null and is_instance_valid(decor_layer):
		return
	decor_layer = BattlefieldDecorLayerScript.new()
	decor_layer.name = "DecorLayer"
	decor_layer.z_index = 1
	add_child(decor_layer)

func _empty_owner_counts() -> Dictionary:
	return {
		GameConfig.Faction.BLUE: 0,
		GameConfig.Faction.RED: 0,
		GameConfig.Faction.GREEN: 0,
		GameConfig.Faction.YELLOW: 0,
	}

func _owner_draw_color(owner_id: int) -> Color:
	if owner_color_overrides.has(owner_id):
		return owner_color_overrides[owner_id] as Color
	if owner_id >= GameConfig.Faction.BLUE and owner_id <= GameConfig.Faction.YELLOW:
		var c: Color = GameConfig.faction_color(owner_id).darkened(0.08)
		c.a = 0.94
		return c
	return UNKNOWN_OWNER_COLOR

func _add_owner_count(owner_id: int, delta: int) -> void:
	owner_counts[owner_id] = int(owner_counts.get(owner_id, 0)) + delta

func _owner_grid_matches_size(candidate: Array) -> bool:
	if candidate.size() != grid_size:
		return false
	for x in range(grid_size):
		if not (candidate[x] is Array):
			return false
		if (candidate[x] as Array).size() < grid_size:
			return false
	return true

func _rebuild_cell_texture() -> void:
	if owners.size() != grid_size:
		return
	cell_image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGBA8)
	for x in range(grid_size):
		if not (owners[x] is Array):
			continue
		for y in range(grid_size):
			cell_image.set_pixel(x, y, _owner_draw_color(int(owners[x][y])))
	cell_texture = ImageTexture.create_from_image(cell_image)
	cell_texture_dirty = false

func _paint_cached_cell(cell: Vector2i, faction_id: int) -> void:
	if cell_image == null:
		return
	if not is_inside(cell):
		return
	cell_image.set_pixel(cell.x, cell.y, _owner_draw_color(faction_id))
	cell_texture_dirty = true

func _upload_cell_texture() -> void:
	if not cell_texture_dirty:
		return
	if cell_texture == null or cell_image == null:
		return
	cell_texture.update(cell_image)
	cell_texture_dirty = false

func get_redraw_debug_text() -> String:
	return "%d / %d" % [redraw_calls_per_second, cell_changes_per_second]

func get_debug_metrics() -> Dictionary:
	return {
		"redraw_calls_per_second": redraw_calls_per_second,
		"cell_changes_per_second": cell_changes_per_second,
		"changed_cells_since_draw": changed_cells_since_draw,
		"redraw_pending": redraw_pending,
	}

func _draw() -> void:
	redraw_calls_this_second += 1
	var size: float = grid_size * cell_size

	if cell_texture != null:
		if cell_texture_dirty:
			_upload_cell_texture()
		draw_texture_rect(cell_texture, Rect2(Vector2.ZERO, Vector2(size, size)), false)
	else:
		for x in range(grid_size):
			for y in range(grid_size):
				var c: Color = _owner_draw_color(owners[x][y])
				draw_rect(Rect2(x * cell_size, y * cell_size, cell_size, cell_size), c, true)
