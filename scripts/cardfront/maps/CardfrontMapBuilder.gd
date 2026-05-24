extends RefCounted
class_name CardfrontMapBuilder

const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")


static func apply_to_region_map(region_map, definition: Dictionary) -> bool:
	if region_map == null or definition.is_empty():
		return false
	var map_grid_size: int = int(definition.get("grid_size", 0))
	if map_grid_size <= 0:
		return false
	if int(region_map.grid_size) != map_grid_size:
		region_map.configure(map_grid_size)
	if not region_map.has_method("clear_regions"):
		return false
	region_map.clear_regions()

	for raw_region in definition.get("regions", []):
		if raw_region is Dictionary:
			_apply_region(region_map, raw_region)
	return true


static func _apply_region(region_map, region: Dictionary) -> void:
	var region_type: String = str(region.get("type", ""))
	match str(region.get("shape", "")):
		CardfrontMapDefinitionScript.SHAPE_RECT:
			if not region_map.has_method("paint_region_rect"):
				return
			region_map.paint_region_rect(
				int(region.get("x0", 0)),
				int(region.get("y0", 0)),
				int(region.get("x1", 0)),
				int(region.get("y1", 0)),
				region_type
			)
		CardfrontMapDefinitionScript.SHAPE_DIAMOND:
			if not region_map.has_method("paint_region_diamond"):
				return
			region_map.paint_region_diamond(
				int(region.get("center_x", 0)),
				int(region.get("center_y", 0)),
				int(region.get("radius", 0)),
				region_type
			)
