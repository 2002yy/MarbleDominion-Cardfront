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
	errors.append_array(_validate_route_layout(definition.get("route_layout", {}) as Dictionary))
	var strategy_profile: Dictionary = definition.get("strategy_profile", {}) as Dictionary
	if str(strategy_profile.get("identity", "")) == "":
		errors.append("missing_strategy_identity")
	if str(strategy_profile.get("opening_hint", "")) == "":
		errors.append("missing_strategy_opening_hint")
	return errors


static func _validate_route_layout(route_layout: Dictionary) -> Array:
	var errors: Array = []
	var lanes: Array = route_layout.get("lanes", []) as Array
	if lanes.size() != 2:
		return ["route_lane_count"]
	var previous_right: float = -1.0
	for index in range(lanes.size()):
		var lane: Dictionary = lanes[index] as Dictionary
		var center: float = float(lane.get("center_ratio", -1.0))
		var half_width: float = float(lane.get("half_width_ratio", 0.0))
		var control_half_width: float = float(lane.get("control_half_width_ratio", 0.0))
		var control_half_height: float = float(lane.get("control_half_height_ratio", 0.0))
		var weight: float = float(lane.get("traffic_weight", 0.0))
		if center <= 0.0 or center >= 1.0:
			errors.append("route_lane_center:%d" % index)
		if half_width <= 0.0 or center - half_width < 0.0 or center + half_width > 1.0:
			errors.append("route_lane_width:%d" % index)
		if control_half_width <= 0.0 or control_half_height <= 0.0:
			errors.append("route_control_zone:%d" % index)
		if weight <= 0.0:
			errors.append("route_traffic_weight:%d" % index)
		var left: float = center - half_width
		if left <= previous_right:
			errors.append("route_lane_overlap_or_unsorted:%d" % index)
		previous_right = center + half_width
	var off_bridge_rate: float = float(route_layout.get("off_bridge_rate", -1.0))
	if off_bridge_rate < 0.0 or off_bridge_rate > 0.5:
		errors.append("route_off_bridge_rate")
	return errors
