extends RefCounted
class_name CentralLabMap

const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")


static func make(grid_size: int) -> Dictionary:
	var size: int = maxi(1, int(grid_size))
	var center: int = size >> 1
	var lab_radius: int = maxi(3, floori(float(size) / 9.0))
	var side_radius: int = maxi(1, floori(float(size) / 20.0))
	var regions: Array = [
		_diamond(center, center, lab_radius, RegionTypeScript.LAB),
		_rect(center - lab_radius - side_radius - 2, center - side_radius, center - lab_radius - 2, center + side_radius, RegionTypeScript.ENERGY),
		_rect(center + lab_radius + 2, center - side_radius, center + lab_radius + side_radius + 2, center + side_radius, RegionTypeScript.FACTORY),
	]
	return CardfrontMapDefinitionScript.make("central_lab", size, regions, {
		"display_name": "Central Lab",
		"spawn_zones": [],
		"neutral_zones": [],
		"objective_rule": CardfrontMapDefinitionScript.OBJECTIVE_DESTROY_COMMAND_CHAMBER,
		"stronghold_ruleset": StrongholdRulesScript.RULESET_ID,
		"time_limit": CardfrontRulesScript.MATCH_DURATION_SECONDS,
		"ai_profile": "baseline_duel",
	})


static func _rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_RECT, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "type": region_type}


static func _diamond(center_x: int, center_y: int, radius: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_DIAMOND, "center_x": center_x, "center_y": center_y, "radius": radius, "type": region_type}
