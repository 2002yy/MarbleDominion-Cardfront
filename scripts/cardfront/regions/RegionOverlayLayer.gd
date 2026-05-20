extends Node2D
class_name RegionOverlayLayer

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

var region_map = null
var battlefield = null
var cell_size: int = GameConfig.CELL_SIZE
var _cached: bool = false
var _sprite: Sprite2D


func _init() -> void:
	name = "RegionOverlayLayer"
	z_index = 2
	set_process(false)
	_sprite = Sprite2D.new()
	_sprite.name = "CachedOverlay"
	_sprite.centered = false
	_sprite.z_index = 0
	add_child(_sprite)


func setup(new_region_map, new_battlefield, mode_name: String) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	visible = mode_name == GameConfig.GAME_MODE_CARDFRONT
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
		cell_size = int(battlefield.cell_size)
	_build_texture()
	_cached = true


func mark_dirty() -> void:
	pass


func _build_texture() -> void:
	if region_map == null or region_map.grid_size <= 0 or cell_size <= 0:
		return
	var gs: int = int(region_map.grid_size)
	var img_w: int = gs * cell_size
	var img_h: int = gs * cell_size
	var image := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var rect := Rect2i()
	rect.size = Vector2i(cell_size, cell_size)

	for x in range(gs):
		for y in range(gs):
			var region_type: String = region_map.get_region_type(Vector2i(x, y))
			if region_type == RegionTypeScript.NORMAL:
				continue
			rect.position = Vector2i(x * cell_size, y * cell_size)
			match region_type:
				RegionTypeScript.ENERGY:
					image.fill_rect(Rect2i(rect.position + Vector2i(1, 1), rect.size - Vector2i(2, 2)), Color(0.35, 0.82, 1.0, 0.18))
					var center := Vector2i(x * cell_size + cell_size / 2, y * cell_size + cell_size / 2)
					_fill_circle(image, center, maxi(1, cell_size / 6), Color(0.65, 0.95, 1.0, 0.42))
				RegionTypeScript.FACTORY:
					image.fill_rect(Rect2i(rect.position + Vector2i(1, 1), rect.size - Vector2i(2, 2)), Color(1.0, 0.64, 0.22, 0.17))
					var inner := int(cell_size * 0.44)
					var offset := int(cell_size * 0.28)
					image.fill_rect(Rect2i(rect.position + Vector2i(offset, offset), Vector2i(inner, inner)), Color(1.0, 0.78, 0.38, 0.34))
				RegionTypeScript.LAB:
					image.fill_rect(Rect2i(rect.position + Vector2i(1, 1), rect.size - Vector2i(2, 2)), Color(0.72, 0.45, 1.0, 0.20))
					var center := Vector2i(x * cell_size + cell_size / 2, y * cell_size + cell_size / 2)
					_fill_circle(image, center, maxi(1, cell_size / 5), Color(0.88, 0.74, 1.0, 0.45))

	var texture := ImageTexture.create_from_image(image)
	_sprite.texture = texture
	_sprite.position = Vector2.ZERO


func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2: int = radius * radius
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= r2:
				var px: int = center.x + dx
				var py: int = center.y + dy
				if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height():
					var existing := image.get_pixel(px, py)
					image.set_pixel(px, py, existing.blend(color))
