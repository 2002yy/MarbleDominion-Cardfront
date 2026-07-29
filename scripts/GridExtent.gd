extends RefCounted
class_name GridExtent

const DEFAULT: Vector2i = Vector2i(40, 40)
const SUPPORTED_SIDES: Array[int] = [10, 20, 30, 40, 50, 60]


static func normalize(value, fallback: Vector2i = DEFAULT) -> Vector2i:
	var extent := fallback
	if value is Vector2i:
		extent = value
	elif value is Vector2:
		extent = Vector2i(roundi(value.x), roundi(value.y))
	elif value is Array and value.size() >= 2:
		extent = Vector2i(int(value[0]), int(value[1]))
	elif value is Dictionary:
		extent = Vector2i(
			int(value.get("width", value.get("x", fallback.x))),
			int(value.get("height", value.get("y", fallback.y)))
		)
	elif value != null:
		var side: int = int(value)
		extent = Vector2i(side, side)
	return Vector2i(maxi(1, extent.x), maxi(1, extent.y))


static func from_config(config: Dictionary, fallback: Vector2i = DEFAULT) -> Vector2i:
	if config.has("grid_extent"):
		return normalize(config.get("grid_extent"), fallback)
	if config.has("grid_size"):
		return normalize(config.get("grid_size"), fallback)
	return normalize(fallback)


static func sanitize(value, fallback: Vector2i = DEFAULT) -> Vector2i:
	var extent := normalize(value, fallback)
	return Vector2i(
		extent.x if extent.x in SUPPORTED_SIDES else fallback.x,
		extent.y if extent.y in SUPPORTED_SIDES else fallback.y
	)


static func to_array(extent_value) -> Array:
	var extent := normalize(extent_value)
	return [extent.x, extent.y]


static func cell_count(extent_value) -> int:
	var extent := normalize(extent_value)
	return extent.x * extent.y


static func is_square(extent_value) -> bool:
	var extent := normalize(extent_value)
	return extent.x == extent.y
