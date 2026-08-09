extends RefCounted
class_name SupportConnectivityResolver

const ValidatorScript = preload("res://scripts/cardfront/support/graph/SupportTopologyValidator.gd")


static func resolve(
	topology: Dictionary,
	side: int,
	claim_owner_by_support: Dictionary,
	operational_by_support: Dictionary
) -> Dictionary:
	var validation_errors: Array = ValidatorScript.validate(topology)
	if not validation_errors.is_empty():
		return {
			"valid": false,
			"errors": validation_errors,
			"connected_support_ids": [],
			"unconnected_claimed_support_ids": [],
			"reachable_parent": {},
			"revision": 0,
		}

	var nodes_by_id: Dictionary = {}
	for node in topology.nodes as Array:
		nodes_by_id[str(node.support_id)] = node
	var adjacency: Dictionary = {}
	for support_id in nodes_by_id.keys():
		adjacency[support_id] = []
	for edge in topology.edges as Array:
		(adjacency[str(edge.a)] as Array).append(str(edge.b))
		(adjacency[str(edge.b)] as Array).append(str(edge.a))
	for support_id in adjacency.keys():
		(adjacency[support_id] as Array).sort()

	var connected: Array[String] = []
	var reachable_parent: Dictionary = {}
	var root_id: String = str((topology.core_roots as Dictionary).get(side, ""))
	if _is_traversable(root_id, side, claim_owner_by_support, operational_by_support):
		var queue: Array[String] = [root_id]
		var visited: Dictionary = {root_id: true}
		while not queue.is_empty():
			var current: String = queue.pop_front()
			connected.append(current)
			for neighbor in adjacency.get(current, []) as Array:
				var neighbor_id: String = str(neighbor)
				if visited.has(neighbor_id) or not _is_traversable(neighbor_id, side, claim_owner_by_support, operational_by_support):
					continue
				visited[neighbor_id] = true
				reachable_parent[neighbor_id] = current
				queue.append(neighbor_id)
	connected.sort()

	var unconnected_claimed: Array[String] = []
	for support_id in nodes_by_id.keys():
		if int(claim_owner_by_support.get(support_id, -1)) == side and support_id not in connected:
			unconnected_claimed.append(str(support_id))
	unconnected_claimed.sort()
	return {
		"valid": true,
		"errors": [],
		"connected_support_ids": connected,
		"unconnected_claimed_support_ids": unconnected_claimed,
		"reachable_parent": reachable_parent,
		"revision": 0,
	}


static func _is_traversable(support_id: String, side: int, claims: Dictionary, operational: Dictionary) -> bool:
	return int(claims.get(support_id, -1)) == side and bool(operational.get(support_id, false))
