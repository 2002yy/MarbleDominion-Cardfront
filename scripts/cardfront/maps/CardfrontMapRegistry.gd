extends RefCounted
class_name CardfrontMapRegistry

const CentralLabMapScript = preload("res://scripts/cardfront/maps/maps/CentralLabMap.gd")
const CrossResourceMapScript = preload("res://scripts/cardfront/maps/maps/CrossResourceMap.gd")
const DefaultDuelMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")

const DEFAULT_DUEL_MAP_ID: String = "default_duel"
const CROSS_RESOURCE_MAP_ID: String = "cross_resource"
const CENTRAL_LAB_MAP_ID: String = "central_lab"


static func get_registered_map_ids() -> Array:
	return [DEFAULT_DUEL_MAP_ID, CROSS_RESOURCE_MAP_ID, CENTRAL_LAB_MAP_ID]


static func get_map_definition(map_id: String = DEFAULT_DUEL_MAP_ID, grid_size: int = 40) -> Dictionary:
	match str(map_id):
		DEFAULT_DUEL_MAP_ID:
			return DefaultDuelMapScript.make(grid_size)
		CROSS_RESOURCE_MAP_ID:
			return CrossResourceMapScript.make(grid_size)
		CENTRAL_LAB_MAP_ID:
			return CentralLabMapScript.make(grid_size)
	return {}
