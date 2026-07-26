extends RefCounted
class_name CardfrontMapDefinition

const SHAPE_RECT: String = "rect"
const SHAPE_DIAMOND: String = "diamond"
const OBJECTIVE_DESTROY_COMMAND_CHAMBER: String = "destroy_command_chamber"

const FIRST_STAGE_LANE_COUNT: int = 2
const MIN_LANE_CENTER_RATIO: float = 0.10
const MAX_LANE_CENTER_RATIO: float = 0.90
const MIN_LANE_HALF_WIDTH_RATIO: float = 0.02
const MAX_LANE_HALF_WIDTH_RATIO: float = 0.20
const MIN_CONTROL_ZONE_RATIO: float = 0.02
const MAX_CONTROL_ZONE_RATIO: float = 0.25


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

	_validate_simulation_profile(definition, errors)
	_validate_route_layout(definition, errors)
	_validate_strategy_profile(definition, errors)
	return errors


static func route_layout_snapshot(definition: Dictionary) -> Dictionary:
	return (definition.get("route_layout", {}) as Dictionary).duplicate(true)


static func strategy_profile_snapshot(definition: Dictionary) -> Dictionary:
	return (definition.get("strategy_profile", {}) as Dictionary).duplicate(true)


static func _validate_simulation_profile(definition: Dictionary, errors: Array) -> void:
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


static func _validate_route_layout(definition: Dictionary, errors: Array) -> void:
	var route_layout: Dictionary = definition.get("route_layout", {}) as Dictionary
	if route_layout.is_empty():
		errors.append("missing_route_layout")
		return

	var river_y_ratio: float = float(route_layout.get("river_y_ratio", -1.0))
	if river_y_ratio < MIN_LANE_CENTER_RATIO or river_y_ratio > MAX_LANE_CENTER_RATIO:
		errors.append("invalid_route_river_y_ratio")

	var lane_centers: Array = route_layout.get("lane_center_ratios", []) as Array
	if lane_centers.size() != FIRST_STAGE_LANE_COUNT:
		errors.append("invalid_route_lane_count")
	else:
		var previous_center: float = -INF
		for index in range(lane_centers.size()):
			var center: float = float(lane_centers[index])
			if center < MIN_LANE_CENTER_RATIO or center > MAX_LANE_CENTER_RATIO:
				errors.append("invalid_route_lane_center:%d" % index)
			if center <= previous_center:
				errors.append("unsorted_route_lane_centers")
			previous_center = center

	var lane_half_width: float = float(route_layout.get("lane_half_width_ratio", -1.0))
	if lane_half_width < MIN_LANE_HALF_WIDTH_RATIO or lane_half_width > MAX_LANE_HALF_WIDTH_RATIO:
		errors.append("invalid_route_lane_half_width")
	elif lane_centers.size() == FIRST_STAGE_LANE_COUNT:
		if float(lane_centers[1]) - float(lane_centers[0]) <= lane_half_width * 2.0:
			errors.append("overlapping_route_lanes")

	var control_half_width: float = float(route_layout.get("control_zone_half_width_ratio", -1.0))
	var control_half_height: float = float(route_layout.get("control_zone_half_height_ratio", -1.0))
	if control_half_width < MIN_CONTROL_ZONE_RATIO or control_half_width > MAX_CONTROL_ZONE_RATIO:
		errors.append("invalid_route_control_half_width")
	if control_half_height < MIN_CONTROL_ZONE_RATIO or control_half_height > MAX_CONTROL_ZONE_RATIO:
		errors.append("invalid_route_control_half_height")
	if lane_centers.size() == FIRST_STAGE_LANE_COUNT and control_half_width >= 0.0:
		for index in range(lane_centers.size()):
			var center: float = float(lane_centers[index])
			if center - control_half_width < 0.0 or center + control_half_width > 1.0:
				errors.append("route_control_zone_out_of_bounds:%d" % index)

	var lane_names: Array = route_layout.get("lane_names", []) as Array
	if lane_names.size() != FIRST_STAGE_LANE_COUNT:
		errors.append("invalid_route_lane_names")
	else:
		for index in range(lane_names.size()):
			if str(lane_names[index]).strip_edges() == "":
				errors.append("empty_route_lane_name:%d" % index)


static func _validate_strategy_profile(definition: Dictionary, errors: Array) -> void:
	var strategy_profile: Dictionary = definition.get("strategy_profile", {}) as Dictionary
	if strategy_profile.is_empty():
		errors.append("missing_strategy_profile")
		return
	for required_key in ["identity", "summary", "opening_hint"]:
		if str(strategy_profile.get(required_key, "")).strip_edges() == "":
			errors.append("missing_strategy_profile:%s" % required_key)
	var tags: Array = strategy_profile.get("tags", []) as Array
	if tags.is_empty():
		errors.append("missing_strategy_profile:tags")
