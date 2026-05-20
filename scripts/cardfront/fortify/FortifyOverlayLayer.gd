extends Node2D
class_name FortifyOverlayLayer

const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")

var fortify_layer = null
var battlefield = null
var cell_size: int = GameConfig.CELL_SIZE
var _sprite: Sprite2D
var _dirty: bool = true


func _init() -> void:
	name = "FortifyOverlayLayer"
	z_index = 3
	set_process(false)
	_sprite = Sprite2D.new()
	_sprite.name = "CachedOverlay"
	_sprite.centered = false
	_sprite.z_index = 0
	add_child(_sprite)


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
	_dirty = false
	_build_texture()


func _build_texture() -> void:
	if fortify_layer == null or int(fortify_layer.grid_size) <= 0 or cell_size <= 0:
		return
	var gs: int = int(fortify_layer.grid_size)
	var img_w: int = gs * cell_size
	var img_h: int = gs * cell_size
	var image := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for x in range(gs):
		for y in range(gs):
			var cell := Vector2i(x, y)
			var stack: int = fortify_layer.get_fortify_stack(cell)
			if stack <= 0:
				continue
			var rect := Rect2i(Vector2i(x * cell_size, y * cell_size), Vector2i(cell_size, cell_size))
			var alpha: float = 0.30 + float(stack) * 0.15
			var border_color: Color
			match stack:
				3: border_color = Color(0.20, 0.60, 1.0, alpha)
				2: border_color = Color(0.30, 0.55, 0.90, alpha)
				_: border_color = Color(0.40, 0.50, 0.80, alpha)

			if cell_size > 3:
				image.fill_rect(Rect2i(rect.position + Vector2i(1, 1), rect.size - Vector2i(2, 2)), Color(0.05, 0.08, 0.16, alpha * 0.5))
			var b := maxi(1, int(float(cell_size) * 0.15))
			image.fill_rect(Rect2i(Vector2i(x * cell_size + b, y * cell_size + b), Vector2i(maxi(1, cell_size - b * 2), b)), border_color)
			image.fill_rect(Rect2i(Vector2i(x * cell_size + b, y * cell_size + cell_size - b), Vector2i(maxi(1, cell_size - b * 2), b)), border_color)
			image.fill_rect(Rect2i(Vector2i(x * cell_size + b, y * cell_size + b), Vector2i(b, maxi(1, cell_size - b * 2))), border_color)
			image.fill_rect(Rect2i(Vector2i(x * cell_size + cell_size - b, y * cell_size + b), Vector2i(b, maxi(1, cell_size - b * 2))), border_color)

	var texture := ImageTexture.create_from_image(image)
	_sprite.texture = texture
