extends RefCounted
class_name DefaultDuelMap

const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")


static func make(grid_size: int) -> Dictionary:
	var size: int = maxi(1, int(grid_size))
	var spawn_rows: int = BattlefieldInitializer.get_spawn_rows(size)
	var contest_min_y: int = spawn_rows
	var contest_max_y: int = size - spawn_rows - 1
	var center: int = size >> 1
	var contest_width: int = maxi(1, contest_max_y - contest_min_y + 1)
	var stronghold_radius: int = maxi(1, floori(float(size) / 16.0))
	var core_radius: int = maxi(2, floori(float(size) / 10.0))
	var side_inset: int = maxi(stronghold_radius + 1, floori(float(contest_width) * 0.18))
	var left_x: int = side_inset
	var right_x: int = size - side_inset - 1
	var top_y: int = clampi(floori(float(size) * 0.23), stronghold_radius, size - stronghold_radius - 1)
	var bottom_y: int = size - top_y - 1

	var regions: Array = [
		_square(left_x, top_y, stronghold_radius, RegionTypeScript.ENERGY),
		_square(right_x, top_y, stronghold_radius, RegionTypeScript.FACTORY),
		_rect(center - core_radius, center - core_radius, center + core_radius - 1, center + core_radius - 1, RegionTypeScript.LAB),
		_square(left_x, bottom_y, stronghold_radius, RegionTypeScript.FACTORY),
		_square(right_x, bottom_y, stronghold_radius, RegionTypeScript.ENERGY),
	]
	return CardfrontMapDefinitionScript.make("default_duel", size, regions, {
		"display_name": "Five Strongholds",
		"layout_style": "symmetric_five_strongholds",
		"spawn_zones": [
			{"owner": CardfrontRulesScript.AI_FACTION, "y0": 0, "y1": spawn_rows - 1},
			{"owner": CardfrontRulesScript.PLAYER_FACTION, "y0": size - spawn_rows, "y1": size - 1},
		],
		"neutral_zones": [{"y0": contest_min_y, "y1": contest_max_y}],
		"objective_rule": CardfrontMapDefinitionScript.OBJECTIVE_DESTROY_COMMAND_CHAMBER,
		"stronghold_ruleset": StrongholdRulesScript.RULESET_ID,
		"time_limit": CardfrontRulesScript.MATCH_DURATION_SECONDS,
		"ai_profile": "baseline_duel",
	})


static func _rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_RECT, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "type": region_type}


static func _square(center_x: int, center_y: int, radius: int, region_type: String) -> Dictionary:
	return _rect(center_x - radius, center_y - radius, center_x + radius, center_y + radius, region_type)


static func _diamond(center_x: int, center_y: int, radius: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_DIAMOND, "center_x": center_x, "center_y": center_y, "radius": radius, "type": region_type}
