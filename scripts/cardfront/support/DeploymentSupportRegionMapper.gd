extends RefCounted
class_name DeploymentSupportRegionMapper

const SupportDefinitionScript = preload("res://scripts/cardfront/support/DeploymentSupportDefinition.gd")


static func bind(definitions: Array, region_map) -> Dictionary:
	var errors: Array = []
	var bindings: Dictionary = {}
	if region_map == null or not region_map.has_method("is_inside") or not region_map.has_method("get_region_id"):
		return {"ok": false, "bindings": bindings, "errors": ["invalid_region_map"]}

	var definitions_by_id: Dictionary = {}
	for raw_definition in definitions:
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

	for support_id in definitions_by_id.keys():
		var definition: Dictionary = definitions_by_id[support_id] as Dictionary
		for raw_neighbor_id in definition.get("authored_neighbors", []) as Array:
			var neighbor_id: String = str(raw_neighbor_id)
			if neighbor_id != "" and not definitions_by_id.has(neighbor_id):
				errors.append("unknown_neighbor:%s:%s" % [support_id, neighbor_id])

	var support_by_region_id: Dictionary = {}
	for support_id in definitions_by_id.keys():
		var definition: Dictionary = definitions_by_id[support_id] as Dictionary
		if bool(definition.get("is_core", false)):
			continue
		var anchor = definition.get("anchor_cell")
		if not anchor is Vector2i or not region_map.is_inside(anchor as Vector2i):
			errors.append("anchor_outside_map:%s" % support_id)
			continue
		var runtime_region_id: int = int(region_map.get_region_id(anchor as Vector2i))
		if runtime_region_id == 0 or not region_map.get_controllable_region_ids().has(runtime_region_id):
			errors.append("anchor_not_controllable:%s" % support_id)
			continue
		if support_by_region_id.has(runtime_region_id):
			errors.append("duplicate_runtime_region:%s:%s" % [support_by_region_id[runtime_region_id], support_id])
			continue
		support_by_region_id[runtime_region_id] = support_id
		bindings[support_id] = runtime_region_id

	return {
		"ok": errors.is_empty(),
		"bindings": bindings if errors.is_empty() else {},
		"errors": errors,
	}
