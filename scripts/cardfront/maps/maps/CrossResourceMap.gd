extends RefCounted
class_name CrossResourceMap

const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")


static func make(grid_size: int) -> Dictionary:
	var size: int = maxi(1, int(grid_size))
	var center: int = size >> 1
	var radius: int = maxi(2, floori(float(size) / 14.0))
	var arm: int = maxi(4, floori(float(size) / 6.0))
	var regions: Array = [
		_rect(center - arm, center - radius, center + arm, center + radius, RegionTypeScript.ENERGY),
		_rect(center - radius, center - arm, center + radius, center + arm, RegionTypeScript.FACTORY),
		_diamond(center, center, radius, RegionTypeScript.LAB),
	]
	return CardfrontMapDefinitionScript.make("cross_resource", size, regions, {
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
			"timeout_rate_min": 4.0,
			"timeout_rate_max": 12.0,
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
		},
	})


static func _rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_RECT, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "type": region_type}


static func _diamond(center_x: int, center_y: int, radius: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_DIAMOND, "center_x": center_x, "center_y": center_y, "radius": radius, "type": region_type}
