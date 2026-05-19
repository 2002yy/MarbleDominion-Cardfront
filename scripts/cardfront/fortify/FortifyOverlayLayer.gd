extends Node2D
class_name FortifyOverlayLayer

const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")

var fortify_layer = null
var battlefield = null
var cell_size: int = GameConfig.CELL_SIZE
var _dirty: bool = true


func _init() -> void:
	name = "FortifyOverlayLayer"
	z_index = 3
	set_process(false)


func setup(new_fortify_layer, new_battlefield, mode_name: String) -> void:
	fortify_layer = new_fortify_layer
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
	if fortify_layer == null:
		return
	if int(fortify_layer.grid_size) <= 0:
		return

	_dirty = false
	for x in range(int(fortify_layer.grid_size)):
		for y in range(int(fortify_layer.grid_size)):
			var cell := Vector2i(x, y)
			var stack: int = fortify_layer.get_fortify_stack(cell)
			if stack <= 0:
				continue
			var rect := Rect2(Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))
			var alpha: float = 0.30 + float(stack) * 0.15
			var border_color: Color
			match stack:
				3: border_color = Color(0.20, 0.60, 1.0, alpha)
				2: border_color = Color(0.30, 0.55, 0.90, alpha)
				_: border_color = Color(0.40, 0.50, 0.80, alpha)
			draw_rect(rect.grow(-0.5), Color(0.05, 0.08, 0.16, alpha * 0.5), true)
			draw_rect(rect.grow(-1.2), border_color, false, maxf(1.0, float(cell_size) * 0.15))
