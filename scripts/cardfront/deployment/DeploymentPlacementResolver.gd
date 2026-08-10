extends RefCounted
class_name DeploymentPlacementResolver

const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const ResultScript = preload("res://scripts/cardfront/deployment/DeploymentResult.gd")


static func resolve(
	region_map,
	battlefield,
	owner_id: int,
	deployment_context: Dictionary,
	request: Dictionary = {},
	availability: Callable = Callable()
) -> Dictionary:
	var revision: int = int(deployment_context.get("deployment_revision", 0))
	if deployment_context.is_empty() or int(deployment_context.get("side", -1)) != int(owner_id):
		return _failure(revision)

	var preferred_support_id: String = str(request.get("preferred_support_id", ""))
	var preferred_route_role: String = str(request.get("preferred_route_role", ""))
	var spawn_profile_id: String = str(request.get("deployment_profile_id", ""))
	for raw_source in _ordered_support_sources(
		deployment_context.get("support_sources", []) as Array,
		preferred_support_id,
		preferred_route_role
	):
		var source: Dictionary = raw_source as Dictionary
		var support_result: Dictionary = _best_support_cell(
			region_map,
			battlefield,
			owner_id,
			deployment_context,
			source,
			spawn_profile_id,
			availability
		)
		if bool(support_result.get("allowed", false)):
			support_result["deployment_revision"] = revision
			return support_result

	var core_result: Dictionary = _best_core_cell(
		region_map,
		battlefield,
		owner_id,
		deployment_context,
		availability
	)
	if bool(core_result.get("allowed", false)):
		core_result["deployment_revision"] = revision
		return core_result
	return _failure(revision)


static func _ordered_support_sources(
	raw_sources: Array,
	preferred_support_id: String,
	preferred_route_role: String
) -> Array:
	var preferred: Array = []
	var route_matches: Array = []
	var remaining: Array = []
	for raw_source in raw_sources:
		if not raw_source is Dictionary:
			continue
		var source: Dictionary = raw_source as Dictionary
		var support_id: String = str(source.get("support_id", ""))
		if preferred_support_id != "" and support_id == preferred_support_id:
			preferred.append(source)
		elif preferred_route_role != "" and str(source.get("route_role", "")) == preferred_route_role:
			route_matches.append(source)
		else:
			remaining.append(source)
	preferred.sort_custom(_source_precedes)
	route_matches.sort_custom(_source_precedes)
	remaining.sort_custom(_source_precedes)
	var result: Array = []
	result.append_array(preferred)
	result.append_array(route_matches)
	result.append_array(remaining)
	return result


static func _source_precedes(left, right) -> bool:
	var left_depth: int = int((left as Dictionary).get("graph_depth", 0))
	var right_depth: int = int((right as Dictionary).get("graph_depth", 0))
	if left_depth != right_depth:
		return left_depth > right_depth
	return str((left as Dictionary).get("support_id", "")) < str((right as Dictionary).get("support_id", ""))


static func _best_support_cell(
	region_map,
	battlefield,
	owner_id: int,
	context: Dictionary,
	source: Dictionary,
	requested_profile_id: String,
	availability: Callable
) -> Dictionary:
	var extent: Vector2i = _battlefield_extent(battlefield)
	var source_id: String = str(source.get("support_id", ""))
	var profile_id: String = requested_profile_id
	if profile_id == "":
		profile_id = str(source.get("profile_id", ""))
	var legal_candidates: Array = []
	for x in range(extent.x):
		for y in range(extent.y):
			var cell := Vector2i(x, y)
			var result = _evaluate_cell(
				region_map,
				battlefield,
				owner_id,
				context,
				cell,
				source_id,
				profile_id
			)
			if not bool(result.allowed) or not _is_available(availability, cell):
				continue
			legal_candidates.append(_support_candidate(source, cell))
	if legal_candidates.is_empty():
		return {"allowed": false}
	legal_candidates.sort_custom(_candidate_precedes)
	var winner: Dictionary = legal_candidates[0] as Dictionary
	return {
		"allowed": true,
		"reason": DeploymentRulesScript.REASON_ALLOWED,
		"cell": winner.cell,
		"resolved_support_id": source_id,
		"source_kind": ResultScript.SOURCE_SUPPORT,
		"legal_candidate_count": legal_candidates.size(),
	}


static func _best_core_cell(
	region_map,
	battlefield,
	owner_id: int,
	context: Dictionary,
	availability: Callable
) -> Dictionary:
	var core_source: Dictionary = context.get("core_source", {}) as Dictionary
	var core_id: String = str(core_source.get("support_id", ""))
	if core_id == "":
		return {"allowed": false}
	var candidates: Array[Vector2i] = []
	for raw_cell in core_source.get("candidate_cells", []) as Array:
		if raw_cell is Vector2i:
			candidates.append(raw_cell as Vector2i)
	candidates.sort_custom(func(left: Vector2i, right: Vector2i):
		if left.y != right.y:
			return left.y < right.y
		return left.x < right.x
	)
	var legal_count: int = 0
	var first_legal := Vector2i(-1, -1)
	for cell in candidates:
		var result = _evaluate_cell(
			region_map,
			battlefield,
			owner_id,
			context,
			cell,
			core_id,
			""
		)
		if not bool(result.allowed) or not _is_available(availability, cell):
			continue
		legal_count += 1
		if first_legal.x < 0:
			first_legal = cell
	if first_legal.x < 0:
		return {"allowed": false}
	return {
		"allowed": true,
		"reason": DeploymentRulesScript.REASON_ALLOWED,
		"cell": first_legal,
		"resolved_support_id": core_id,
		"source_kind": ResultScript.SOURCE_CORE,
		"legal_candidate_count": legal_count,
	}


static func _evaluate_cell(
	region_map,
	battlefield,
	owner_id: int,
	context: Dictionary,
	cell: Vector2i,
	requested_support_id: String,
	spawn_profile_id: String
):
	var query = QueryScript.new()
	query.owner_id = owner_id
	query.cell = cell
	query.rule_type = DeploymentRuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = requested_support_id
	query.spawn_profile_id = spawn_profile_id
	query.support_network_context = context
	return DeploymentRulesScript.evaluate(region_map, battlefield, query)


static func _support_candidate(source: Dictionary, cell: Vector2i) -> Dictionary:
	var anchor: Vector2i = source.get("anchor_cell", Vector2i.ZERO) as Vector2i
	var forward: Vector2i = source.get("forward", Vector2i.ZERO) as Vector2i
	var offset: Vector2i = cell - anchor
	var perpendicular := Vector2i(-forward.y, forward.x)
	var forward_component: int = offset.x * forward.x + offset.y * forward.y
	return {
		"cell": cell,
		"rear_distance": -forward_component,
		"lateral_component": absi(offset.x * perpendicular.x + offset.y * perpendicular.y),
		"distance_squared": anchor.distance_squared_to(cell),
	}


static func _candidate_precedes(left, right) -> bool:
	var a: Dictionary = left as Dictionary
	var b: Dictionary = right as Dictionary
	if int(a.rear_distance) != int(b.rear_distance):
		return int(a.rear_distance) < int(b.rear_distance)
	if int(a.lateral_component) != int(b.lateral_component):
		return int(a.lateral_component) < int(b.lateral_component)
	if int(a.distance_squared) != int(b.distance_squared):
		return int(a.distance_squared) < int(b.distance_squared)
	var a_cell: Vector2i = a.cell as Vector2i
	var b_cell: Vector2i = b.cell as Vector2i
	if a_cell.y != b_cell.y:
		return a_cell.y < b_cell.y
	return a_cell.x < b_cell.x


static func _is_available(availability: Callable, cell: Vector2i) -> bool:
	return not availability.is_valid() or bool(availability.call(cell))


static func _battlefield_extent(battlefield) -> Vector2i:
	if battlefield == null:
		return Vector2i.ZERO
	var extent = battlefield.get("grid_extent")
	if extent is Vector2i:
		return extent as Vector2i
	var size: int = int(battlefield.get("grid_size"))
	return Vector2i(size, size)


static func _failure(revision: int) -> Dictionary:
	return {
		"allowed": false,
		"reason": DeploymentRulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE,
		"cell": Vector2i(-1, -1),
		"resolved_support_id": "",
		"source_kind": ResultScript.SOURCE_NONE,
		"legal_candidate_count": 0,
		"deployment_revision": revision,
	}
