extends RefCounted
class_name CardfrontFormalAssetValidator

const NODE_PREFIXES: PackedStringArray = [
	"GEO_",
	"PIV_",
	"SOCKET_",
	"VFX_",
	"DMG_",
]
const SURFACE_ROLES: PackedStringArray = [
	"STONE",
	"WOOD",
	"METAL",
	"CERAMIC",
	"CLOTH",
	"FOLIAGE",
	"WATER",
	"ENERGY",
]
const RUNTIME_CHANNELS: PackedStringArray = [
	"STATIC",
	"THEME",
	"FACTION_PRIMARY",
	"FACTION_TRIM",
	"OWNERSHIP",
	"CORE",
	"DAMAGE",
]
const TRANSFORM_EPSILON := 0.0001

var _material_role_regex := RegEx.new()


func _init() -> void:
	var surfaces := "|".join(SURFACE_ROLES)
	var channels := "|".join(RUNTIME_CHANNELS)
	_material_role_regex.compile("^CF_(%s)__(%s)$" % [surfaces, channels])


static func tower_module_contract() -> Dictionary:
	return {
		"required_nodes": PackedStringArray([
			"PIV_Turret",
			"SOCKET_Muzzle",
			"VFX_Intercept",
		]),
		"forward_nodes": PackedStringArray(["SOCKET_Muzzle"]),
		"require_ground_contact": true,
		"require_visible_geometry": true,
	}


static func bridge_contract() -> Dictionary:
	return {
		"required_nodes": PackedStringArray(),
		"require_ground_contact": true,
		"require_visible_geometry": true,
	}


static func gate_frame_contract() -> Dictionary:
	return {
		"required_nodes": PackedStringArray(["SOCKET_BarAnchor"]),
		"require_ground_contact": true,
		"require_visible_geometry": true,
	}


static func beacon_function_contract() -> Dictionary:
	return {
		"required_nodes": PackedStringArray([
			"PIV_BeaconHead",
			"SOCKET_Guidance",
			"VFX_BeaconPulse",
		]),
		# Crown module lives high in the shared tower space and is deliberately
		# forward-asymmetric (emitter slot), so ground-contact/center checks
		# that apply to ground-standing assets are not meaningful here.
		"require_ground_contact": false,
		"require_visible_geometry": true,
	}


static func fortification_contract() -> Dictionary:
	return {
		"required_nodes": PackedStringArray(),
		"require_ground_contact": true,
		"require_visible_geometry": true,
	}


func validate_resource_path(path: String, contract: Dictionary = {}) -> Dictionary:
	if path.is_empty() or not ResourceLoader.exists(path):
		return _failure_result("RESOURCE_MISSING", path, "PackedScene resource does not exist")
	var resource := load(path)
	if not resource is PackedScene:
		return _failure_result("RESOURCE_NOT_PACKED_SCENE", path, "Formal asset must import as PackedScene")
	return validate_packed_scene(resource as PackedScene, contract)


func validate_packed_scene(scene: PackedScene, contract: Dictionary = {}) -> Dictionary:
	if scene == null:
		return _failure_result("PACKED_SCENE_NULL", "", "PackedScene is null")
	var instance := scene.instantiate()
	if instance == null:
		return _failure_result("SCENE_INSTANTIATION_FAILED", "", "PackedScene could not be instantiated")
	var result := validate_instance(instance, contract)
	instance.free()
	return result


func validate_instance(root: Node, contract: Dictionary = {}) -> Dictionary:
	if root == null:
		return _failure_result("ROOT_NULL", "", "Formal asset root is null")

	var errors: Array[Dictionary] = []
	var facts := {
		"node_count": 0,
		"visible_geometry_count": 0,
		"material_slot_count": 0,
		"required_node_count": 0,
		"has_visible_bounds": false,
	}
	var nodes_by_name: Dictionary = {}
	var root_path := str(root.name)

	if not root.name.begins_with("CF_"):
		_add_error(errors, "ROOT_PREFIX_INVALID", root_path, "Root name must begin with CF_")
	if not root is Node3D:
		_add_error(errors, "ROOT_TYPE_INVALID", root_path, "Formal asset root must be Node3D")
	elif not (root as Node3D).transform.is_equal_approx(Transform3D.IDENTITY):
		_add_error(errors, "ROOT_TRANSFORM_NOT_IDENTITY", root_path, "Root transform must remain identity at ground-contact origin")

	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_front()
		facts["node_count"] = int(facts["node_count"]) + 1
		var node_path := _node_path(root, node)
		var node_name := str(node.name)
		if not nodes_by_name.has(node_name):
			nodes_by_name[node_name] = []
		(nodes_by_name[node_name] as Array).append(node)

		if node != root and not _has_allowed_node_prefix(node_name):
			_add_error(errors, "NODE_PREFIX_UNKNOWN", node_path, "Exported node must use a frozen D22 semantic prefix")
		if node is CollisionObject3D or node is CollisionShape3D:
			_add_error(errors, "FORBIDDEN_COLLISION_NODE", node_path, "Presentation GLB must not carry collision authority")
		if node is Camera3D:
			_add_error(errors, "FORBIDDEN_CAMERA_NODE", node_path, "Authoring cameras must not be exported")
		if node is Light3D:
			_add_error(errors, "FORBIDDEN_LIGHT_NODE", node_path, "Authoring lights must not be exported")

		if node is Node3D and not (node as Node3D).scale.is_equal_approx(Vector3.ONE):
			_add_error(errors, "NODE_SCALE_NOT_APPLIED", node_path, "Node scale must be applied and equal to 1,1,1")

		if node is MeshInstance3D:
			_validate_mesh_instance(root, node as MeshInstance3D, errors, facts)

		for child in node.get_children():
			pending.append(child)

	var required_nodes = contract.get("required_nodes", PackedStringArray())
	for required_name_value in required_nodes:
		var required_name := str(required_name_value)
		facts["required_node_count"] = int(facts["required_node_count"]) + 1
		var matches: Array = nodes_by_name.get(required_name, []) as Array
		if matches.is_empty():
			_add_error(errors, "REQUIRED_NODE_MISSING", root_path, "Required node is missing: %s" % required_name)
		elif matches.size() > 1:
			_add_error(errors, "REQUIRED_NODE_DUPLICATE", root_path, "Required node must be unique: %s" % required_name)

	var forward_nodes = contract.get("forward_nodes", PackedStringArray())
	for forward_name_value in forward_nodes:
		var forward_name := str(forward_name_value)
		var forward_matches: Array = nodes_by_name.get(forward_name, []) as Array
		if forward_matches.size() != 1:
			continue
		var forward_node: Node = forward_matches[0]
		if not forward_node is Node3D:
			_add_error(errors, "FORWARD_NODE_TYPE_INVALID", _node_path(root, forward_node), "Directional semantic node must be Node3D")
			continue
		var forward_vector := _transform_from_root(root, forward_node).basis.z.normalized()
		if forward_vector.dot(Vector3.BACK) < float(contract.get("forward_min_dot", 0.999)):
			_add_error(errors, "SOCKET_FORWARD_INVALID", _node_path(root, forward_node), "Directional socket local +Z must point toward model +Z")

	if bool(contract.get("require_visible_geometry", true)) and int(facts["visible_geometry_count"]) == 0:
		_add_error(errors, "VISIBLE_GEOMETRY_MISSING", root_path, "Formal asset must contain GEO_ or DMG_ visible geometry")
	if bool(contract.get("require_ground_contact", false)) and bool(facts["has_visible_bounds"]):
		var bounds_min: Vector3 = facts["visible_bounds_min"]
		var bounds_max: Vector3 = facts["visible_bounds_max"]
		var ground_tolerance := float(contract.get("ground_tolerance", 0.001))
		if absf(bounds_min.y) > ground_tolerance:
			_add_error(errors, "GROUND_CONTACT_INVALID", root_path, "Visible bounds must touch root Y=0 ground plane")
		if bool(contract.get("require_ground_center", true)):
			var horizontal_center := Vector2(
				(bounds_min.x + bounds_max.x) * 0.5,
				(bounds_min.z + bounds_max.z) * 0.5
			)
			if horizontal_center.length() > float(contract.get("ground_center_tolerance", 0.001)):
				_add_error(errors, "GROUND_CENTER_INVALID", root_path, "Ground-contact footprint must be centered on root X/Z")

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"facts": facts,
	}


func _validate_mesh_instance(root: Node, mesh_instance: MeshInstance3D, errors: Array[Dictionary], facts: Dictionary) -> void:
	var node_path := _node_path(root, mesh_instance)
	var node_name := str(mesh_instance.name)
	if not node_name.begins_with("GEO_") and not node_name.begins_with("DMG_"):
		_add_error(errors, "VISIBLE_NODE_PREFIX_INVALID", node_path, "Visible geometry must use GEO_ or DMG_")
	else:
		facts["visible_geometry_count"] = int(facts["visible_geometry_count"]) + 1

	if not mesh_instance.transform.basis.is_equal_approx(Basis.IDENTITY):
		_add_error(errors, "VISIBLE_TRANSFORM_NOT_APPLIED", node_path, "Visible mesh rotation and scale must be applied before export")

	var mesh := mesh_instance.mesh
	if mesh == null:
		_add_error(errors, "VISIBLE_MESH_MISSING", node_path, "MeshInstance3D has no mesh resource")
		return
	if mesh.get_surface_count() == 0:
		_add_error(errors, "VISIBLE_MESH_EMPTY", node_path, "Visible mesh must contain at least one surface")
		return
	_expand_visible_bounds(root, mesh_instance, mesh.get_aabb(), facts)
	for surface_index in range(mesh.get_surface_count()):
		facts["material_slot_count"] = int(facts["material_slot_count"]) + 1
		var material := mesh_instance.get_surface_override_material(surface_index)
		if material == null:
			material = mesh.surface_get_material(surface_index)
		if material == null:
			_add_error(errors, "MATERIAL_MISSING", node_path, "Surface %d has no material" % surface_index)
			continue
		var material_name := str(material.resource_name)
		if _material_role_regex.search(material_name) == null:
			_add_error(
				errors,
				"MATERIAL_ROLE_UNKNOWN",
				node_path,
				"Surface %d material '%s' must match CF_<SURFACE>__<CHANNEL>" % [surface_index, material_name]
			)


func _expand_visible_bounds(root: Node, mesh_instance: MeshInstance3D, mesh_bounds: AABB, facts: Dictionary) -> void:
	if not root is Node3D:
		return
	var to_root := _transform_from_root(root, mesh_instance)
	for x_value in [mesh_bounds.position.x, mesh_bounds.end.x]:
		for y_value in [mesh_bounds.position.y, mesh_bounds.end.y]:
			for z_value in [mesh_bounds.position.z, mesh_bounds.end.z]:
				var point := to_root * Vector3(float(x_value), float(y_value), float(z_value))
				if not bool(facts["has_visible_bounds"]):
					facts["visible_bounds_min"] = point
					facts["visible_bounds_max"] = point
					facts["has_visible_bounds"] = true
				else:
					var current_min: Vector3 = facts["visible_bounds_min"]
					var current_max: Vector3 = facts["visible_bounds_max"]
					facts["visible_bounds_min"] = current_min.min(point)
					facts["visible_bounds_max"] = current_max.max(point)


func _transform_from_root(root: Node, node: Node) -> Transform3D:
	var chain: Array[Node] = []
	var current: Node = node
	while current != root and current != null:
		chain.push_front(current)
		current = current.get_parent()
	var result := Transform3D.IDENTITY
	for chain_node in chain:
		if chain_node is Node3D:
			result = result * (chain_node as Node3D).transform
	return result


func _has_allowed_node_prefix(node_name: String) -> bool:
	for prefix in NODE_PREFIXES:
		if node_name.begins_with(prefix):
			return true
	return false


func _node_path(root: Node, node: Node) -> String:
	if node == root:
		return str(root.name)
	return "%s/%s" % [root.name, str(root.get_path_to(node))]


func _failure_result(code: String, path: String, detail: String) -> Dictionary:
	var errors: Array[Dictionary] = []
	_add_error(errors, code, path, detail)
	return {
		"valid": false,
		"errors": errors,
		"facts": {},
	}


func _add_error(errors: Array[Dictionary], code: String, path: String, detail: String) -> void:
	errors.append({
		"code": code,
		"path": path,
		"detail": detail,
	})
