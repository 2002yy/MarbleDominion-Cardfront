extends RefCounted
class_name SupportTopologyContract

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")


static func from_support_definitions(definitions: Array) -> Dictionary:
	var nodes: Array = []
	var definition_ids: Dictionary = {}
	for raw_definition in definitions:
		if not raw_definition is Dictionary:
			continue
		var definition: Dictionary = raw_definition as Dictionary
		var support_id: String = str(definition.get("support_id", ""))
		definition_ids[support_id] = true
		nodes.append({
			"support_id": support_id,
			"is_core": bool(definition.get("is_core", false)),
			"route_role": str(definition.get("route_role", "")),
			"player_deploy_direction": definition.get("player_deploy_direction", Vector2i.ZERO),
			"ai_deploy_direction": definition.get("ai_deploy_direction", Vector2i.ZERO),
			"deployment_profile_id": str(definition.get("deployment_profile_id", "")),
		})
	nodes.sort_custom(func(left, right): return str(left.support_id) < str(right.support_id))

	var edge_keys: Dictionary = {}
	for raw_definition in definitions:
		if not raw_definition is Dictionary:
			continue
		var definition: Dictionary = raw_definition as Dictionary
		var support_id: String = str(definition.get("support_id", ""))
		for raw_neighbor in definition.get("authored_neighbors", []) as Array:
			var pair: Array[String] = [support_id, str(raw_neighbor)]
			pair.sort()
			edge_keys["%s<->%s" % pair] = {"a": pair[0], "b": pair[1]}
	var edge_names: Array = edge_keys.keys()
	edge_names.sort()
	var edges: Array = []
	for edge_name in edge_names:
		edges.append(edge_keys[edge_name])

	var core_roots: Dictionary = {}
	if definition_ids.has(SupportIdsScript.CORE_PLAYER):
		core_roots[RulesScript.PLAYER_FACTION] = SupportIdsScript.CORE_PLAYER
	if definition_ids.has(SupportIdsScript.CORE_AI):
		core_roots[RulesScript.AI_FACTION] = SupportIdsScript.CORE_AI
	return {
		"nodes": nodes,
		"core_roots": core_roots,
		"edges": edges,
	}
