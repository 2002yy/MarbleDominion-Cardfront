extends RefCounted
class_name CardfrontEnvironmentAssetRegistry

const SOURCE_ROOT := "res://assets/cardfront_environment/source/kaykit_medieval_hexagon"

const ASSETS: Dictionary = {
	"wall_straight": {
		"path": SOURCE_ROOT + "/buildings/neutral/wall_straight.gltf",
		"role": "outer_structure",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_wall",
	},
	"wall_gate": {
		"path": SOURCE_ROOT + "/buildings/neutral/wall_straight_gate.gltf",
		"role": "gate_foundation",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_gate",
	},
	"rock_a": {
		"path": SOURCE_ROOT + "/decoration/nature/rock_single_A.gltf",
		"role": "outer_dressing",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_rock",
	},
	"rock_b": {
		"path": SOURCE_ROOT + "/decoration/nature/rock_single_B.gltf",
		"role": "outer_dressing",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_rock",
	},
	"rock_c": {
		"path": SOURCE_ROOT + "/decoration/nature/rock_single_C.gltf",
		"role": "outer_dressing",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_rock",
	},
	"tree_a": {
		"path": SOURCE_ROOT + "/decoration/nature/tree_single_A.gltf",
		"role": "outer_dressing",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_tree",
	},
	"tree_b": {
		"path": SOURCE_ROOT + "/decoration/nature/tree_single_B.gltf",
		"role": "outer_dressing",
		"source_pack": "kaykit_medieval_hexagon",
		"fallback": "primitive_tree",
	},
	"custom_defense_tower": {
		"path": "res://assets/cardfront_environment/source/custom/defense_tower.glb",
		"role": "command_chamber",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_chamber",
	},
	"formal_hq_common": {
		"path": "res://assets/cardfront_environment/formal/hq/hq_common.glb",
		"role": "command_chamber_common",
		"source_pack": "cardfront_formal_hq_v1",
		"fallback": "primitive_chamber",
	},
	"formal_hq_hero_balanced": {
		"path": "res://assets/cardfront_environment/formal/hq/hq_hero_balanced.glb",
		"role": "command_chamber_hero_module",
		"source_pack": "cardfront_formal_hq_v1",
		"fallback": "none",
	},
	"formal_hq_theme_castle": {
		"path": "res://assets/cardfront_environment/formal/hq/hq_theme_castle.glb",
		"role": "command_chamber_theme_module",
		"source_pack": "cardfront_formal_hq_v1",
		"fallback": "none",
	},
	"formal_hq_damage": {
		"path": "res://assets/cardfront_environment/formal/hq/hq_damage_common.glb",
		"role": "command_chamber_damage_module",
		"source_pack": "cardfront_formal_hq_v1",
		"fallback": "none",
	},
	"formal_tower_common": {
		"path": "res://assets/cardfront_environment/formal/tower/tower_common.glb",
		"role": "defense_tower_common",
		"source_pack": "cardfront_formal_tower_v1",
		"fallback": "primitive_tower",
	},
	"formal_tower_interceptor": {
		"path": "res://assets/cardfront_environment/formal/tower/tower_interceptor.glb",
		"role": "defense_tower_function_module",
		"source_pack": "cardfront_formal_tower_v1",
		"fallback": "custom_interceptor_tower",
	},
	"formal_tower_beacon": {
		"path": "res://assets/cardfront_environment/formal/tower/tower_beacon.glb",
		"role": "defense_tower_function_module",
		"source_pack": "cardfront_formal_tower_v1",
		"fallback": "custom_beacon_tower",
	},
	"formal_tower_theme_castle": {
		"path": "res://assets/cardfront_environment/formal/tower/tower_theme_castle.glb",
		"role": "defense_tower_theme_module",
		"source_pack": "cardfront_formal_tower_v1",
		"fallback": "none",
	},
	"formal_tower_damage": {
		"path": "res://assets/cardfront_environment/formal/tower/tower_damage_common.glb",
		"role": "defense_tower_damage_module",
		"source_pack": "cardfront_formal_tower_v1",
		"fallback": "none",
	},
	"formal_bridge": {
		"path": "res://assets/cardfront_environment/formal/bridge/bridge.glb",
		"role": "river_bridge",
		"source_pack": "cardfront_formal_bridge_v1",
		"fallback": "primitive_bridge",
	},
	"formal_gate_frame": {
		"path": "res://assets/cardfront_environment/formal/gate/gate_frame.glb",
		"role": "gate_frame",
		"source_pack": "cardfront_formal_gate_v1",
		"fallback": "primitive_gate",
	},
	"formal_fortification": {
		"path": "res://assets/cardfront_environment/formal/fortification/fortification.glb",
		"role": "cell_fortification_module",
		"source_pack": "cardfront_formal_fort_v1",
		"fallback": "none",
	},
	"formal_stronghold_base_center": {
		"path": "res://assets/cardfront_environment/formal/stronghold_base/stronghold_base_center.glb",
		"role": "stronghold_base_pad",
		"source_pack": "cardfront_formal_stronghold_v1",
		"fallback": "primitive_platform",
	},
	"formal_stronghold_base_corner": {
		"path": "res://assets/cardfront_environment/formal/stronghold_base/stronghold_base_corner.glb",
		"role": "stronghold_base_pad",
		"source_pack": "cardfront_formal_stronghold_v1",
		"fallback": "primitive_platform",
	},
	"custom_industrial_stack": {
		"path": "res://assets/cardfront_environment/source/custom/industrial_stack.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_stack",
	},
	"custom_lab_pylon": {
		"path": "res://assets/cardfront_environment/source/custom/lab_crystal_pylon.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_pylon",
	},
	"custom_beacon_tower": {
		"path": "res://assets/cardfront_environment/source/custom/beacon_tower.glb",
		"role": "defense_tower",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_tower",
	},
	"custom_interceptor_tower": {
		"path": "res://assets/cardfront_environment/source/custom/interceptor_tower.glb",
		"role": "defense_tower",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_tower",
	},
	"custom_castle_wall": {
		"path": "res://assets/cardfront_environment/source/custom/castle_wall_segment.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_wall",
	},
	"custom_banner_flag": {
		"path": "res://assets/cardfront_environment/source/custom/banner_flag.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_banner",
	},
	"custom_storage_tank": {
		"path": "res://assets/cardfront_environment/source/custom/storage_tank.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_tank",
	},
	"custom_lab_dome": {
		"path": "res://assets/cardfront_environment/source/custom/lab_dome.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_dome",
	},
	"custom_energy_ring": {
		"path": "res://assets/cardfront_environment/source/custom/energy_ring.glb",
		"role": "map_landmark",
		"source_pack": "cardfront_custom_blender",
		"fallback": "primitive_ring",
	},
}


static func get_entry(asset_id: String) -> Dictionary:
	return (ASSETS.get(asset_id, {}) as Dictionary).duplicate(true)


static func get_path(asset_id: String) -> String:
	return str((ASSETS.get(asset_id, {}) as Dictionary).get("path", ""))


static func is_available(asset_id: String) -> bool:
	var path := get_path(asset_id)
	return not path.is_empty() and ResourceLoader.exists(path)


static func load_scene(asset_id: String) -> PackedScene:
	if not is_available(asset_id):
		return null
	return load(get_path(asset_id)) as PackedScene


static func registered_ids() -> Array[String]:
	var result: Array[String] = []
	for asset_id in ASSETS.keys():
		result.append(str(asset_id))
	result.sort()
	return result
