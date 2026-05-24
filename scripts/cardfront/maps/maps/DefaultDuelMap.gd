extends RefCounted
class_name DefaultDuelMap

const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const CardfrontContentManifestScript = preload("res://scripts/cardfront/content/CardfrontContentManifest.gd")
const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")


static func make(grid_size: int) -> Dictionary:
	var size: int = maxi(1, int(grid_size))
	var spawn_columns: int = BattlefieldInitializer.get_spawn_columns(size)
	var contest_min_x: int = spawn_columns
	var contest_max_x: int = size - spawn_columns - 1
	var center: int = size >> 1
	var resource_radius: int = maxi(1, floori(float(size) / 20.0))
	var lab_radius: int = maxi(2, floori(float(size) / 12.0))
	var energy_margin: int = maxi(2, floori(float(size) / 20.0))
	var energy_y_top: int = floori(float(size) / 4.0)
	var energy_y_bottom: int = size - energy_y_top - 1
	var contest_width: int = maxi(1, contest_max_x - contest_min_x + 1)
	var factory_left_x: int = contest_min_x + floori(float(contest_width) / 4.0)
	var factory_right_x: int = contest_max_x - floori(float(contest_width) / 4.0)

	var regions: Array = [
		_rect(contest_min_x + energy_margin, energy_y_top - resource_radius, contest_max_x - energy_margin, energy_y_top + resource_radius, RegionTypeScript.ENERGY),
		_rect(contest_min_x + energy_margin, energy_y_bottom - resource_radius, contest_max_x - energy_margin, energy_y_bottom + resource_radius, RegionTypeScript.ENERGY),
		_rect(factory_left_x - resource_radius, center - lab_radius, factory_left_x + resource_radius, center + lab_radius, RegionTypeScript.FACTORY),
		_rect(factory_right_x - resource_radius, center - lab_radius, factory_right_x + resource_radius, center + lab_radius, RegionTypeScript.FACTORY),
		_diamond(center, center, lab_radius, RegionTypeScript.LAB),
	]
	return CardfrontMapDefinitionScript.make("default_duel", size, regions, {
		"display_name": "Default Duel",
		"spawn_zones": [
			{"owner": CardfrontRulesScript.PLAYER_FACTION, "x0": 0, "x1": spawn_columns - 1},
			{"owner": CardfrontRulesScript.AI_FACTION, "x0": size - spawn_columns, "x1": size - 1},
		],
		"neutral_zones": [{"x0": contest_min_x, "x1": contest_max_x}],
		"win_rule": "capture_target_percent",
		"time_limit": CardfrontRulesScript.MATCH_DURATION_SECONDS,
		"resource_multiplier": 1.0,
		"allowed_card_pool": CardfrontContentManifestScript.get_default_hand_ids(),
		"ai_profile": "baseline_duel",
	})


static func _rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_RECT, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "type": region_type}


static func _diamond(center_x: int, center_y: int, radius: int, region_type: String) -> Dictionary:
	return {"shape": CardfrontMapDefinitionScript.SHAPE_DIAMOND, "center_x": center_x, "center_y": center_y, "radius": radius, "type": region_type}
