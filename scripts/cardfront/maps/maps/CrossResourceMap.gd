extends RefCounted
class_name CrossResourceMap

const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")


static func make(grid_extent_value) -> Dictionary:
	var extent := GridExtentScript.normalize(grid_extent_value)
	var center_x: int = extent.x >> 1
	var center_y: int = extent.y >> 1
	var radius: int = maxi(2, floori(float(mini(extent.x, extent.y)) / 14.0))
	var arm_x: int = maxi(4, floori(float(extent.x) / 6.0))
	var arm_y: int = maxi(4, floori(float(extent.y) / 6.0))
	var regions: Array = [
		_rect(center_x - arm_x, center_y - radius, center_x + arm_x, center_y + radius, RegionTypeScript.ENERGY),
		_rect(center_x - radius, center_y - arm_y, center_x + radius, center_y + arm_y, RegionTypeScript.FACTORY),
		_diamond(center_x, center_y, radius, RegionTypeScript.LAB),
	]
	return CardfrontMapDefinitionScript.make("cross_resource", extent, regions, {
		"display_name": "Cross Strongholds",
		"spawn_zones": [],
		"neutral_zones": [],
		"objective_rule": CardfrontMapDefinitionScript.OBJECTIVE_DESTROY_COMMAND_CHAMBER,
		"stronghold_ruleset": StrongholdRulesScript.RULESET_ID,
		"time_limit": CardfrontRulesScript.MATCH_DURATION_SECONDS,
		"ai_profile": "baseline_duel",
		"strategy_profile": {
			"identity": "central_crossfire",
			"opening_hint": "The inward bridges make central control influence both routes early.",
		},
		"balance_targets": {
			"pacing_identity": "fast_attack",
			"median_round_min": 18.0,
			"median_round_max": 21.0,
			"p90_round_min": 27.0,
			"p90_round_max": 32.0,
			"timeout_rate_min": 2.0,
			"timeout_rate_max": 8.0,
			"blue_point_rate_min": 47.0,
			"blue_point_rate_max": 53.0,
			"lane0_share_min": 52.0,
			"lane0_share_max": 56.0,
			"route_rejection_rate_min": 24.0,
			"route_rejection_rate_max": 32.0,
		},
		"route_layout": {
			"off_bridge_rate": 0.075,
			"lanes": [
				{"center_ratio": 0.40, "half_width_ratio": 0.075, "control_half_width_ratio": 0.115, "control_half_height_ratio": 0.11, "traffic_weight": 1.08, "route_quality": 1.00, "blue_side_bias": 0.030},
				{"center_ratio": 0.60, "half_width_ratio": 0.075, "control_half_width_ratio": 0.115, "control_half_height_ratio": 0.11, "traffic_weight": 0.92, "route_quality": 1.00, "blue_side_bias": -0.030},
			],
		},
		"simulation_profile": {
			"chamber_hit_chance": 0.165,
			"average_cells_crossed": 17.5,
			"defense_contact_chance": 0.13,
			"territory_pressure": 1.02,
			"stronghold_tempo": -1,
			"b1_tail_stall_chance": 0.08,
			"b1_tail_hit_multiplier": 0.15,
		},
	})


static func _rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_RECT, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "type": region_type}


static func _diamond(center_x: int, center_y: int, radius: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_DIAMOND, "center_x": center_x, "center_y": center_y, "radius": radius, "type": region_type}
