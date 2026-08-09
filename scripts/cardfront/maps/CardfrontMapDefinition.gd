extends RefCounted
class_name CardfrontMapDefinition

const GridExtentScript = preload("res://scripts/GridExtent.gd")
const SupportMapMetadataScript = preload("res://scripts/cardfront/support/DeploymentSupportMapMetadata.gd")
const SHAPE_RECT: String = "rect"
const SHAPE_DIAMOND: String = "diamond"
const OBJECTIVE_DESTROY_COMMAND_CHAMBER: String = "destroy_command_chamber"


static func make(map_id: String, grid_extent_value, regions: Array, metadata: Dictionary = {}) -> Dictionary:
	var grid_extent := GridExtentScript.normalize(grid_extent_value)
	var definition: Dictionary = metadata.duplicate(true)
	definition["id"] = str(map_id)
	definition["grid_extent"] = GridExtentScript.to_array(grid_extent)
	definition["grid_size"] = grid_extent.x
	definition["regions"] = regions.duplicate(true)
	return definition


static func validate(definition: Dictionary) -> Array:
	var errors: Array = []
	if str(definition.get("id", "")) == "":
		errors.append("missing_id")
	var grid_extent := GridExtentScript.from_config(definition, Vector2i.ZERO)
	if grid_extent.x <= 0 or grid_extent.y <= 0:
		errors.append("invalid_grid_extent")
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
		"b1_tail_stall_chance",
		"b1_tail_hit_multiplier",
	]:
		if not simulation_profile.has(required_key):
			errors.append("missing_simulation_profile:%s" % str(required_key))
	var tail_chance: float = float(simulation_profile.get("b1_tail_stall_chance", -1.0))
	if tail_chance < 0.0 or tail_chance > 0.25:
		errors.append("invalid_b1_tail_stall_chance")
	var tail_multiplier: float = float(simulation_profile.get("b1_tail_hit_multiplier", -1.0))
	if tail_multiplier < 0.05 or tail_multiplier > 1.0:
		errors.append("invalid_b1_tail_hit_multiplier")
	errors.append_array(_validate_route_layout(definition.get("route_layout", {}) as Dictionary))
	errors.append_array(_validate_balance_targets(definition.get("balance_targets", {}) as Dictionary))
	var strategy_profile: Dictionary = definition.get("strategy_profile", {}) as Dictionary
	if str(strategy_profile.get("identity", "")) == "":
		errors.append("missing_strategy_identity")
	if str(strategy_profile.get("opening_hint", "")) == "":
		errors.append("missing_strategy_opening_hint")
	errors.append_array(SupportMapMetadataScript.validate(definition))
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


static func _validate_balance_targets(targets: Dictionary) -> Array:
	var errors: Array = []
	if str(targets.get("pacing_identity", "")) == "":
		errors.append("missing_balance_pacing_identity")
	for prefix in [
		"median_round",
		"p90_round",
		"timeout_rate",
		"blue_point_rate",
		"lane0_share",
		"route_rejection_rate",
	]:
		var min_key: String = "%s_min" % prefix
		var max_key: String = "%s_max" % prefix
		if not targets.has(min_key) or not targets.has(max_key):
			errors.append("missing_balance_target:%s" % prefix)
			continue
		var minimum: float = float(targets[min_key])
		var maximum: float = float(targets[max_key])
		if minimum > maximum:
			errors.append("invalid_balance_target_range:%s" % prefix)
	return errors
