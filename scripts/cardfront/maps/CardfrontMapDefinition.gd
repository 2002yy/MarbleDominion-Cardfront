extends RefCounted
class_name CardfrontMapDefinition

const SHAPE_RECT: String = "rect"
const SHAPE_DIAMOND: String = "diamond"


static func make(map_id: String, grid_size: int, regions: Array, metadata: Dictionary = {}) -> Dictionary:
	var definition: Dictionary = metadata.duplicate(true)
	definition["id"] = str(map_id)
	definition["grid_size"] = int(grid_size)
	definition["regions"] = regions.duplicate(true)
	return definition


static func validate(definition: Dictionary) -> Array:
	var errors: Array = []
	if str(definition.get("id", "")) == "":
		errors.append("missing_id")
	if int(definition.get("grid_size", 0)) <= 0:
		errors.append("invalid_grid_size")
	var regions: Array = definition.get("regions", []) as Array
	if regions.is_empty():
		errors.append("missing_regions")
	for index in range(regions.size()):
		var region: Dictionary = regions[index] as Dictionary
		var shape: String = str(region.get("shape", ""))
		if shape != SHAPE_RECT and shape != SHAPE_DIAMOND:
			errors.append("invalid_shape:%d" % int(index))
		if str(region.get("type", "")) == "":
			errors.append("missing_region_type:%d" % int(index))
	if (definition.get("allowed_card_pool", []) as Array).is_empty():
		errors.append("missing_allowed_card_pool")
	if str(definition.get("ai_profile", "")) == "":
		errors.append("missing_ai_profile")
	return errors
