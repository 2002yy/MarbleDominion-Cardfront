extends RefCounted
class_name SupportTopologyValidator

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")


static func validate(topology: Dictionary) -> Array:
	var errors: Array = []
	var nodes = topology.get("nodes", [])
	if not nodes is Array or (nodes as Array).is_empty():
		return ["missing_topology_nodes"]

	var nodes_by_id: Dictionary = {}
	var core_count: int = 0
	for raw_node in nodes as Array:
		if not raw_node is Dictionary:
			errors.append("invalid_topology_node")
			continue
		var node: Dictionary = raw_node as Dictionary
		var support_id: String = str(node.get("support_id", ""))
		if support_id == "":
			errors.append("missing_support_id")
			continue
		if nodes_by_id.has(support_id):
			errors.append("duplicate_support_id:%s" % support_id)
			continue
		nodes_by_id[support_id] = node
		if bool(node.get("is_core", false)):
			core_count += 1
		if not _is_cardinal(node.get("player_deploy_direction")):
			errors.append("invalid_player_deploy_direction:%s" % support_id)
		if not _is_cardinal(node.get("ai_deploy_direction")):
			errors.append("invalid_ai_deploy_direction:%s" % support_id)
		if str(node.get("deployment_profile_id", "")) == "":
			errors.append("missing_deployment_profile:%s" % support_id)
	if core_count != 2:
		errors.append("invalid_core_count:%d" % core_count)

	var roots = topology.get("core_roots", {})
	if not roots is Dictionary:
		errors.append("invalid_core_roots")
		roots = {}
	var root_ids: Array[String] = []
	for side in [RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION]:
		var root_id: String = str((roots as Dictionary).get(side, ""))
		if root_id == "":
			errors.append("missing_core_root:%d" % side)
			continue
		root_ids.append(root_id)
		if not nodes_by_id.has(root_id):
			errors.append("unknown_core_root:%d:%s" % [side, root_id])
		elif not bool((nodes_by_id[root_id] as Dictionary).get("is_core", false)):
			errors.append("root_not_core:%d:%s" % [side, root_id])
	if root_ids.size() == 2 and root_ids[0] == root_ids[1]:
		errors.append("duplicate_core_root:%s" % root_ids[0])

	var adjacency: Dictionary = {}
	for support_id in nodes_by_id.keys():
		adjacency[support_id] = []
	var seen_edges: Dictionary = {}
	var edges = topology.get("edges", [])
	if not edges is Array:
		errors.append("invalid_topology_edges")
		edges = []
	for raw_edge in edges as Array:
		if not raw_edge is Dictionary:
			errors.append("invalid_topology_edge")
			continue
		var edge: Dictionary = raw_edge as Dictionary
		var a: String = str(edge.get("a", ""))
		var b: String = str(edge.get("b", ""))
		if a == b:
			errors.append("self_edge:%s" % a)
			continue
		var pair: Array[String] = [a, b]
		pair.sort()
		var edge_key: String = "%s<->%s" % pair
		if seen_edges.has(edge_key):
			errors.append("duplicate_edge:%s" % edge_key)
			continue
		seen_edges[edge_key] = true
		if not nodes_by_id.has(a) or not nodes_by_id.has(b):
			errors.append("unknown_edge_endpoint:%s" % edge_key)
			continue
		(adjacency[a] as Array).append(b)
		(adjacency[b] as Array).append(a)

	if root_ids.size() == 2 and nodes_by_id.has(root_ids[0]) and nodes_by_id.has(root_ids[1]):
		if _count_simple_paths(root_ids[0], root_ids[1], adjacency, {}, 2) < 2:
			errors.append("missing_alternate_core_path")
	return errors


static func _is_cardinal(value) -> bool:
	return value is Vector2i and absi((value as Vector2i).x) + absi((value as Vector2i).y) == 1


static func _count_simple_paths(current: String, target: String, adjacency: Dictionary, visited: Dictionary, limit: int) -> int:
	if current == target:
		return 1
	var next_visited: Dictionary = visited.duplicate()
	next_visited[current] = true
	var count: int = 0
	for neighbor in adjacency.get(current, []) as Array:
		var neighbor_id: String = str(neighbor)
		if next_visited.has(neighbor_id):
			continue
		count += _count_simple_paths(neighbor_id, target, adjacency, next_visited, limit - count)
		if count >= limit:
			return count
	return count
