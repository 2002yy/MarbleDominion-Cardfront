extends RefCounted
class_name CardfrontMode

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionOverlayLayerScript = preload("res://scripts/cardfront/regions/RegionOverlayLayer.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const EconomyTickSystemScript = preload("res://scripts/cardfront/economy/EconomyTickSystem.gd")


static func is_selected(mode_name: String) -> bool:
	return Rules.is_cardfront_mode(mode_name)


static func is_active() -> bool:
	return is_selected(GameConfig.get_game_mode_name())


static func get_active_factions() -> Array:
	return Rules.get_duel_factions()


static func get_match_duration_seconds() -> float:
	return Rules.MATCH_DURATION_SECONDS


static func configure_battlefield(battlefield) -> Dictionary:
	var result: Dictionary = BattlefieldInitializer.configure_duel(battlefield)
	if not bool(result.get("configured", false)):
		return result
	result.merge({
		"configured": true,
		"mode_name": GameConfig.GAME_MODE_CARDFRONT,
		"active_factions": get_active_factions(),
		"match_duration_seconds": get_match_duration_seconds(),
		"capture_target_percent": Rules.CAPTURE_TARGET_PERCENT,
	}, true)
	return result


static func create_regions(game_layer: Node, battlefield) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}

	var region_map = RegionMapScript.new()
	region_map.configure(int(battlefield.grid_size))
	region_map.generate_default_layout()

	var overlay = RegionOverlayLayerScript.new()
	overlay.setup(region_map, battlefield, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(overlay)

	return {
		"configured": true,
		"region_map": region_map,
		"region_overlay": overlay,
	}


static func create_economy(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}

	var resource_states: Dictionary = {
		Rules.PLAYER_FACTION: CardfrontResourceStateScript.new(),
		Rules.AI_FACTION: CardfrontResourceStateScript.new(),
	}
	var economy_system = EconomyTickSystemScript.new()
	economy_system.setup(region_map, battlefield, resource_states)
	game_layer.add_child(economy_system)

	return {
		"configured": true,
		"economy_system": economy_system,
		"resource_states": resource_states,
	}
