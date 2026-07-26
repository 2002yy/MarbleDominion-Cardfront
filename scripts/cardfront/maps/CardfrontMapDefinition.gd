extends RefCounted
class_name CardfrontMapDefinition

const SHAPE_RECT: String = "rect"
const SHAPE_DIAMOND: String = "diamond"
const OBJECTIVE_DESTROY_COMMAND_CHAMBER: String = "destroy_command_chamber"


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
	if str(definition.get("objective_rule", "")) != OBJECTIVE_DESTROY_COMMAND_CHAMBER:
		errors.append("invalid_objective_rule")
	if str(definition.get("stronghold_ruleset", "")) == "":
		errors.append("missing_stronghold_ruleset")
	if str(definition.get("ai_profile", "")) == "":
		errors.append("missing_ai_profile")
	var simulation_profile: Dictionary = definition.get("simulation_profile", {}) as Dictionary
	for required_key in [
		"chamber_hit_chance",
		"average_cells_crossed",
		"defense_contact_chance",
		"territory_pressure",
		"stronghold_tempo",
	]:
		if not simulation_profile.has(required_key):
			errors.append("missing_simulation_profile:%s" % str(required_key))
	return errors
