extends RefCounted
class_name CardfrontEnvironmentBuilder

const AssetRegistryScript = preload("res://scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd")

const EDGE_DRESSING_LIMIT: int = 8

var _world_root: Node3D
var _palette: Dictionary = {}
var _created_nodes: Array[Node3D] = []
var _loaded_asset_count: int = 0
var _fallback_count: int = 0
var _materials: Dictionary = {}


func setup(world_root: Node3D, palette: Dictionary) -> bool:
	if world_root == null or not is_instance_valid(world_root):
		return false
	_world_root = world_root
	_palette = palette.duplicate(true)
	return true


func build_edge_dressing(height: float, arena_width: float, z_scale: float) -> int:
	if _world_root == null:
		return 0
	var edge_x: float = arena_width * 0.5 + 2.6
	var placements: Array[Dictionary] = [
		{"id": "tree_a", "position": Vector3(-edge_x, 0.0, -height * 0.31 * z_scale), "scale": 3.65, "rotation": 0.18},
		{"id": "tree_b", "position": Vector3(edge_x, 0.0, -height * 0.28 * z_scale), "scale": 3.50, "rotation": -0.32},
		{"id": "tree_b", "position": Vector3(-edge_x, 0.0, height * 0.27 * z_scale), "scale": 3.35, "rotation": 0.56},
		{"id": "tree_a", "position": Vector3(edge_x, 0.0, height * 0.32 * z_scale), "scale": 3.60, "rotation": -0.48},
		{"id": "rock_a", "position": Vector3(-edge_x + 0.7, 0.0, -height * 0.13 * z_scale), "scale": 5.8, "rotation": 0.42},
		{"id": "rock_b", "position": Vector3(edge_x - 0.6, 0.0, -height * 0.08 * z_scale), "scale": 5.4, "rotation": -0.28},
		{"id": "rock_c", "position": Vector3(-edge_x + 0.5, 0.0, height * 0.11 * z_scale), "scale": 5.1, "rotation": -0.62},
		{"id": "rock_a", "position": Vector3(edge_x - 0.7, 0.0, height * 0.15 * z_scale), "scale": 5.9, "rotation": 0.74},
	]
	for placement in placements.slice(0, EDGE_DRESSING_LIMIT):
		var node := _spawn_asset(
			str(placement.get("id", "")),
			placement.get("position", Vector3.ZERO) as Vector3,
			Vector3.ONE * float(placement.get("scale", 1.0)),
			float(placement.get("rotation", 0.0)),
			_color_for_role(str(placement.get("id", "")))
		)
		if node != null:
			node.set_meta("environment_zone", "outer_edge")
	return placements.size()


func build_bridge_dressing(bridge_x: float, z_scale: float) -> int:
	var count: int = 0
	for side in [-1.0, 1.0]:
		var node := _spawn_asset(
			"wall_straight",
			Vector3(bridge_x + side * 1.48, 0.36, 0.0),
			Vector3(1.58, 0.34, 0.55 * z_scale / 1.28),
			PI * 0.5,
			_palette.get("wood", Color(0.50, 0.36, 0.25)) as Color
		)
		if node != null:
			node.set_meta("environment_zone", "bridge")
			count += 1
	return count


func build_gate_foundations(bridge_x: float, z_scale: float) -> int:
	var count: int = 0
	for side in [-1.0, 1.0]:
		var node := _spawn_asset(
			"wall_gate",
			Vector3(bridge_x + side * 1.82, 0.50, 0.0),
			Vector3(1.35, 1.35, 1.35 * z_scale / 1.28),
			PI * 0.5 if side < 0.0 else -PI * 0.5,
			_palette.get("stone", Color(0.48, 0.49, 0.44)) as Color
		)
		if node != null:
			node.set_meta("environment_zone", "bridge")
			count += 1
	return count


func get_created_count() -> int:
	return _created_nodes.size()


func get_loaded_asset_count() -> int:
	return _loaded_asset_count


func get_fallback_count() -> int:
	return _fallback_count


func get_edge_dressing_limit() -> int:
	return EDGE_DRESSING_LIMIT


func get_material_count() -> int:
	return _materials.size()


func get_layout_metrics() -> Dictionary:
	var edge_count: int = 0
	var bridge_count: int = 0
	var min_edge_abs_x: float = INF
	for node in _created_nodes:
		if node == null or not is_instance_valid(node):
			continue
		var zone: String = str(node.get_meta("environment_zone", ""))
		if zone == "outer_edge":
			edge_count += 1
			min_edge_abs_x = minf(min_edge_abs_x, absf(node.position.x))
		elif zone == "bridge":
			bridge_count += 1
	return {
		"edge_count": edge_count,
		"bridge_count": bridge_count,
		"min_edge_abs_x": min_edge_abs_x if edge_count > 0 else 0.0,
	}


func _spawn_asset(
	asset_id: String,
	position_value: Vector3,
	scale_value: Vector3,
	rotation_y: float,
	color: Color
) -> Node3D:
	if _world_root == null:
		return null
	var scene: PackedScene = AssetRegistryScript.load_scene(asset_id)
	var node: Node3D
	if scene != null:
		node = scene.instantiate() as Node3D
		_loaded_asset_count += 1
	else:
		node = _build_fallback(asset_id)
		_fallback_count += 1
	if node == null:
		return null
	node.name = "Environment_%s" % asset_id
	node.position = position_value
	node.scale = scale_value
	node.rotation.y = rotation_y
	node.set_meta("environment_asset_id", asset_id)
	node.set_meta("presentation_only", true)
	_apply_material(node, color)
	_world_root.add_child(node)
	_created_nodes.append(node)
	return node


func _build_fallback(asset_id: String) -> Node3D:
	var mesh_instance := MeshInstance3D.new()
	if asset_id.begins_with("tree"):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.10
		mesh.bottom_radius = 0.52
		mesh.height = 1.15
		mesh.radial_segments = 7
		mesh_instance.mesh = mesh
	elif asset_id.begins_with("rock"):
		var mesh := SphereMesh.new()
		mesh.radius = 0.18
		mesh.height = 0.22
		mesh.radial_segments = 7
		mesh.rings = 3
		mesh_instance.mesh = mesh
	else:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.5, 0.25, 1.4)
		mesh_instance.mesh = mesh
	return mesh_instance


func _apply_material(node: Node, color: Color) -> void:
	var material := _get_material(color)
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material(child, color)


func _get_material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.84
		material.metallic = 0.0
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


func _color_for_role(asset_id: String) -> Color:
	if asset_id.begins_with("tree"):
		return _palette.get("foliage", Color(0.28, 0.42, 0.31)) as Color
	if asset_id.begins_with("rock"):
		return _palette.get("stone", Color(0.48, 0.49, 0.44)) as Color
	return _palette.get("wood", Color(0.50, 0.36, 0.25)) as Color
