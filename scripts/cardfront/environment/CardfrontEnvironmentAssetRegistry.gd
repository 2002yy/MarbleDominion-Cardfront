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
