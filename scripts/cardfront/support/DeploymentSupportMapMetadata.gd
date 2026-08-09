extends RefCounted
class_name DeploymentSupportMapMetadata

const METADATA_KEY: String = "deployment_supports"

const SupportDefinitionScript = preload("res://scripts/cardfront/support/DeploymentSupportDefinition.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")


static func validate(map_definition: Dictionary) -> Array:
	if not map_definition.has(METADATA_KEY):
		return []
	var errors: Array = []
	var raw_definitions = map_definition.get(METADATA_KEY)
	if not raw_definitions is Array or (raw_definitions as Array).is_empty():
		return ["invalid_deployment_supports"]

	var definitions_by_id: Dictionary = {}
	var non_core_anchor_owner: Dictionary = {}
	for raw_definition in raw_definitions as Array:
		if not raw_definition is Dictionary:
			errors.append("invalid_support_definition")
			continue
		var definition: Dictionary = raw_definition as Dictionary
		var support_id: String = str(definition.get("support_id", ""))
		for definition_error in SupportDefinitionScript.validate(definition):
			errors.append(str(definition_error))
		if support_id == "":
			continue
		if definitions_by_id.has(support_id):
			errors.append("duplicate_support_id:%s" % support_id)
			continue
		definitions_by_id[support_id] = definition
		if not bool(definition.get("is_core", false)) and definition.get("anchor_cell") is Vector2i:
			var anchor_key: String = str(definition.get("anchor_cell"))
			if non_core_anchor_owner.has(anchor_key):
				errors.append("duplicate_support_anchor:%s:%s" % [non_core_anchor_owner[anchor_key], support_id])
			else:
				non_core_anchor_owner[anchor_key] = support_id

	for support_id in definitions_by_id.keys():
		var definition: Dictionary = definitions_by_id[support_id] as Dictionary
		var expected_core: bool = SupportIdsScript.is_core_id(str(support_id))
		if SupportIdsScript.is_default_duel_id(str(support_id)) and bool(definition.get("is_core", false)) != expected_core:
			errors.append("core_classification_mismatch:%s" % support_id)
		for raw_neighbor_id in definition.get("authored_neighbors", []) as Array:
			var neighbor_id: String = str(raw_neighbor_id)
			if not definitions_by_id.has(neighbor_id):
				errors.append("unknown_neighbor:%s:%s" % [support_id, neighbor_id])
				continue
			var neighbor: Dictionary = definitions_by_id[neighbor_id] as Dictionary
			if not (neighbor.get("authored_neighbors", []) as Array).has(support_id):
				errors.append("asymmetric_neighbor:%s:%s" % [support_id, neighbor_id])
	if str(map_definition.get("id", "")) == "default_duel":
		errors.append_array(_validate_default_duel_contract(definitions_by_id))
	return errors


static func _validate_default_duel_contract(definitions_by_id: Dictionary) -> Array:
	var errors: Array = []
	if _sorted_strings(definitions_by_id.keys()) != _sorted_strings(SupportIdsScript.DEFAULT_DUEL_ALL):
		errors.append("default_duel_support_ids_mismatch")

	var expected_roles: Dictionary = {
		SupportIdsScript.CORE_PLAYER: SupportDefinitionScript.ROUTE_ROLE_CORE,
		SupportIdsScript.SUPPORT_LEFT_SOUTH: SupportDefinitionScript.ROUTE_ROLE_LEFT,
		SupportIdsScript.SUPPORT_RIGHT_SOUTH: SupportDefinitionScript.ROUTE_ROLE_RIGHT,
		SupportIdsScript.SUPPORT_CENTER: SupportDefinitionScript.ROUTE_ROLE_CENTER_TRANSFER,
		SupportIdsScript.SUPPORT_LEFT_NORTH: SupportDefinitionScript.ROUTE_ROLE_LEFT,
		SupportIdsScript.SUPPORT_RIGHT_NORTH: SupportDefinitionScript.ROUTE_ROLE_RIGHT,
		SupportIdsScript.CORE_AI: SupportDefinitionScript.ROUTE_ROLE_CORE,
	}
	for support_id in expected_roles.keys():
		if definitions_by_id.has(support_id) and str((definitions_by_id[support_id] as Dictionary).get("route_role", "")) != str(expected_roles[support_id]):
			errors.append("default_duel_route_role_mismatch:%s" % support_id)

	var actual_edges: Array[String] = _undirected_edges(definitions_by_id)
	var expected_edges: Array[String] = _sorted_strings([
		"core_player<->support_left_south",
		"core_player<->support_right_south",
		"support_left_north<->support_left_south",
		"support_right_north<->support_right_south",
		"support_center<->support_left_south",
		"support_center<->support_right_south",
		"support_center<->support_left_north",
		"support_center<->support_right_north",
		"core_ai<->support_left_north",
		"core_ai<->support_right_north",
	])
	if actual_edges != expected_edges:
		errors.append("default_duel_topology_mismatch")
	return errors


static func _undirected_edges(definitions_by_id: Dictionary) -> Array[String]:
	var edges: Dictionary = {}
	for support_id in definitions_by_id.keys():
		var definition: Dictionary = definitions_by_id[support_id] as Dictionary
		for raw_neighbor_id in definition.get("authored_neighbors", []) as Array:
			var pair: Array[String] = [str(support_id), str(raw_neighbor_id)]
			pair.sort()
			edges["%s<->%s" % pair] = true
	return _sorted_strings(edges.keys())


static func _sorted_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	result.sort()
	return result
