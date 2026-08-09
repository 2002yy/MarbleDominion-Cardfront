extends RefCounted
class_name DeploymentRules

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DeploymentResultScript = preload("res://scripts/cardfront/deployment/DeploymentResult.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const DeploymentGeometryScript = preload("res://scripts/cardfront/deployment/DeploymentGeometry.gd")

const REASON_ALLOWED: String = "allowed"
const REASON_OUTSIDE_MAP: String = "outside_map"
const REASON_INVALID_REGION: String = "invalid_region"
const REASON_INVALID_RULE_TYPE: String = "invalid_rule_type"
const REASON_NOT_OWNED_CELL: String = "not_owned_cell"
const REASON_NOT_OWNED_BORDER: String = "not_owned_border"
const REASON_REGION_CONTROL_TOO_LOW: String = "region_control_too_low"
const REASON_NOT_CONTESTED_REGION: String = "not_contested_region"
const REASON_NOT_ENEMY_REGION: String = "not_enemy_region"
const REASON_SUPPORT_NOT_CLAIMED: String = "support_not_claimed"
const REASON_SUPPORT_OFFLINE: String = "support_offline"
const REASON_SUPPORT_DISCONNECTED: String = "support_disconnected"
const REASON_OUTSIDE_DEPLOYMENT_ZONE: String = "outside_deployment_zone"
const REASON_WRONG_DEPLOY_DIRECTION: String = "wrong_deploy_direction"
const REASON_NO_VALID_DEPLOYMENT_SOURCE: String = "no_valid_deployment_source"


static func evaluate(region_map, battlefield, query):
	if query == null:
		return _make_result(false, REASON_INVALID_RULE_TYPE, -1, 0)
	if not DeploymentRuleTypeScript.is_valid(query.rule_type):
		return _make_result(false, REASON_INVALID_RULE_TYPE, _resolve_region_id(region_map, query), 0)

	var resolved_region_id: int = _resolve_region_id(region_map, query)
	match query.rule_type:
		DeploymentRuleTypeScript.OWNED_CELL:
			return _evaluate_owned_cell(region_map, battlefield, query, resolved_region_id)
		DeploymentRuleTypeScript.OWNED_BORDER:
			return _evaluate_owned_border(region_map, battlefield, query, resolved_region_id)
		DeploymentRuleTypeScript.OWNED_REGION_CONTROLLED:
			return _evaluate_region_controlled(region_map, battlefield, query, resolved_region_id)
		DeploymentRuleTypeScript.CONTESTED_REGION:
			return _evaluate_contested_region(region_map, battlefield, query, resolved_region_id)
		DeploymentRuleTypeScript.ENEMY_REGION:
			return _evaluate_enemy_region(region_map, battlefield, query, resolved_region_id)
		DeploymentRuleTypeScript.SUPPORT_NETWORK:
			return _evaluate_support_network(region_map, battlefield, query, resolved_region_id)
		_:
			return _make_result(false, REASON_INVALID_RULE_TYPE, resolved_region_id, 0)


static func is_owned_cell(battlefield, cell: Vector2i, owner_id: int) -> bool:
	if not _is_inside_battlefield(battlefield, cell):
		return false
	return get_owner_at(battlefield, cell) == owner_id


static func is_owned_border(region_map, battlefield, cell: Vector2i, owner_id: int) -> bool:
	if not is_owned_cell(battlefield, cell, owner_id):
		return false
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var neighbor := Vector2i(cell.x + dx, cell.y + dy)
			if not _is_inside_map(region_map, battlefield, neighbor):
				continue
			if get_owner_at(battlefield, neighbor) != owner_id:
				return true
	return false


static func is_region_controlled(region_map, battlefield, region_id: int, owner_id: int, min_percent: int = 50) -> bool:
	if not _is_valid_region(region_map, region_id):
		return false
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	return RegionControlCalculatorScript.get_owner_percent(control, owner_id) >= clampi(min_percent, 0, 100)


static func get_owner_at(battlefield, cell: Vector2i) -> int:
	if not _is_inside_battlefield(battlefield, cell):
		return CardfrontRulesScript.NEUTRAL_OWNER
	var owner_grid = battlefield.get("owners")
	if not (owner_grid is Array):
		return CardfrontRulesScript.NEUTRAL_OWNER
	return int((owner_grid as Array)[cell.x][cell.y])


static func _evaluate_owned_cell(region_map, battlefield, query, region_id: int):
	if not _is_inside_map(region_map, battlefield, query.cell):
		return _make_result(false, REASON_OUTSIDE_MAP, region_id, 0)
	if not is_owned_cell(battlefield, query.cell, query.owner_id):
		return _make_result(false, REASON_NOT_OWNED_CELL, region_id, 0)
	return _make_result(true, REASON_ALLOWED, region_id, 100)


static func _evaluate_owned_border(region_map, battlefield, query, region_id: int):
	if not _is_inside_map(region_map, battlefield, query.cell):
		return _make_result(false, REASON_OUTSIDE_MAP, region_id, 0)
	if not is_owned_cell(battlefield, query.cell, query.owner_id):
		return _make_result(false, REASON_NOT_OWNED_CELL, region_id, 0)
	if not is_owned_border(region_map, battlefield, query.cell, query.owner_id):
		return _make_result(false, REASON_NOT_OWNED_BORDER, region_id, 100)
	return _make_result(true, REASON_ALLOWED, region_id, 100)


static func _evaluate_region_controlled(region_map, battlefield, query, region_id: int):
	if not _is_valid_region(region_map, region_id):
		return _make_result(false, REASON_INVALID_REGION, region_id, 0)
	var owner_percent: int = _owner_percent(region_map, battlefield, region_id, query.owner_id)
	if owner_percent < clampi(query.min_region_control_percent, 0, 100):
		return _make_result(false, REASON_REGION_CONTROL_TOO_LOW, region_id, owner_percent)
	return _make_result(true, REASON_ALLOWED, region_id, owner_percent)


static func _evaluate_contested_region(region_map, battlefield, query, region_id: int):
	if not _is_valid_region(region_map, region_id):
		return _make_result(false, REASON_INVALID_REGION, region_id, 0)
	var owner_percent: int = _owner_percent(region_map, battlefield, region_id, query.owner_id)
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var status: String = RegionControlCalculatorScript.get_region_status(control)
	if status != RegionControlCalculatorScript.STATUS_CONTESTED:
		return _make_result(false, REASON_NOT_CONTESTED_REGION, region_id, owner_percent)
	return _make_result(true, REASON_ALLOWED, region_id, owner_percent)


static func _evaluate_enemy_region(region_map, battlefield, query, region_id: int):
	if not _is_valid_region(region_map, region_id):
		return _make_result(false, REASON_INVALID_REGION, region_id, 0)
	var owner_percent: int = _owner_percent(region_map, battlefield, region_id, query.owner_id)
	if not _has_enemy_control(region_map, battlefield, region_id, query.owner_id, query.min_region_control_percent):
		return _make_result(false, REASON_NOT_ENEMY_REGION, region_id, owner_percent)
	return _make_result(true, REASON_ALLOWED, region_id, owner_percent)


static func _evaluate_support_network(region_map, battlefield, query, region_id: int):
	var context: Dictionary = query.support_network_context
	if context.is_empty() or int(context.get("side", -1)) != int(query.owner_id):
		return _make_result(false, REASON_NO_VALID_DEPLOYMENT_SOURCE, region_id, 0)
	if not _is_inside_map(region_map, battlefield, query.cell):
		return _make_result(false, REASON_OUTSIDE_MAP, region_id, 0)
	var core_source: Dictionary = context.get("core_source", {}) as Dictionary
	var core_support_id: String = str(core_source.get("support_id", ""))
	if core_support_id == "":
		return _make_result(false, REASON_NO_VALID_DEPLOYMENT_SOURCE, region_id, 0)
	var requested_id: String = str(query.requested_support_id)
	var known_support_ids: Array = context.get("known_support_ids", []) as Array
	var online_support_ids: Array = context.get("online_support_ids", []) as Array
	if requested_id != "" and requested_id not in known_support_ids:
		return _make_result(false, REASON_SUPPORT_NOT_CLAIMED, region_id, 0)
	if requested_id != "" and requested_id != core_support_id and requested_id not in online_support_ids:
		return _make_result(false, REASON_SUPPORT_OFFLINE, region_id, 0)

	var extent: Vector2i = _battlefield_extent(battlefield)
	var matching_sources: Array = []
	var requested_classification: String = DeploymentGeometryScript.CLASS_OUTSIDE
	for raw_source in context.get("support_sources", []) as Array:
		var source: Dictionary = raw_source as Dictionary
		if requested_id != "" and str(source.get("support_id", "")) != requested_id:
			continue
		if str(query.spawn_profile_id) != "" and str(source.get("profile_id", "")) != str(query.spawn_profile_id):
			continue
		var classification: String = DeploymentGeometryScript.classify(
			str(source.get("profile_id", "")),
			source.get("anchor_cell", Vector2i.ZERO) as Vector2i,
			source.get("forward", Vector2i.ZERO) as Vector2i,
			query.cell,
			extent
		)
		if requested_id != "":
			requested_classification = classification
		if classification == DeploymentGeometryScript.CLASS_INSIDE:
			matching_sources.append(source)
	if not matching_sources.is_empty():
		matching_sources.sort_custom(func(left, right): return _source_precedes(left, right, query.cell))
		var resolved_source: Dictionary = matching_sources[0] as Dictionary
		if not is_owned_cell(battlefield, query.cell, query.owner_id):
			return _make_result(false, REASON_NOT_OWNED_CELL, region_id, 0)
		return _make_result(true, REASON_ALLOWED, region_id, 100, str(resolved_source.support_id), DeploymentResultScript.SOURCE_SUPPORT, "support:%s" % str(resolved_source.support_id))
	if requested_id != "" and requested_id != core_support_id:
		var reason: String = REASON_WRONG_DEPLOY_DIRECTION if requested_classification == DeploymentGeometryScript.CLASS_WRONG_DIRECTION else REASON_OUTSIDE_DEPLOYMENT_ZONE
		return _make_result(false, reason, region_id, 0)

	if requested_id == "" or requested_id == core_support_id:
		if query.cell in (core_source.get("candidate_cells", []) as Array):
			if not is_owned_cell(battlefield, query.cell, query.owner_id):
				return _make_result(false, REASON_NOT_OWNED_CELL, region_id, 0)
			return _make_result(true, REASON_ALLOWED, region_id, 100, core_support_id, DeploymentResultScript.SOURCE_CORE, "core:%s" % core_support_id)
	return _make_result(false, REASON_OUTSIDE_DEPLOYMENT_ZONE, region_id, 0)


static func _source_precedes(left: Dictionary, right: Dictionary, target: Vector2i) -> bool:
	var left_distance: int = (left.get("anchor_cell", Vector2i.ZERO) as Vector2i).distance_squared_to(target)
	var right_distance: int = (right.get("anchor_cell", Vector2i.ZERO) as Vector2i).distance_squared_to(target)
	if left_distance != right_distance:
		return left_distance < right_distance
	return str(left.get("support_id", "")) < str(right.get("support_id", ""))


static func _battlefield_extent(battlefield) -> Vector2i:
	if battlefield == null:
		return Vector2i.ZERO
	var extent = battlefield.get("grid_extent")
	if extent is Vector2i:
		return extent as Vector2i
	var size: int = int(battlefield.get("grid_size"))
	return Vector2i(size, size)


static func _owner_percent(region_map, battlefield, region_id: int, owner_id: int) -> int:
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	return RegionControlCalculatorScript.get_owner_percent(control, owner_id)


static func _has_enemy_control(region_map, battlefield, region_id: int, owner_id: int, min_percent: int) -> bool:
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var threshold: int = clampi(min_percent, 0, 100)
	var owner_counts: Dictionary = control.get("owner_counts", {})
	for candidate_owner in owner_counts.keys():
		var candidate_id: int = int(candidate_owner)
		if candidate_id == owner_id or candidate_id == CardfrontRulesScript.NEUTRAL_OWNER:
			continue
		if RegionControlCalculatorScript.get_owner_percent(control, candidate_id) >= threshold:
			return true
	return false


static func _resolve_region_id(region_map, query) -> int:
	if query == null:
		return -1
	if query.region_id >= 0:
		return query.region_id
	if region_map != null and region_map.has_method("is_inside") and region_map.is_inside(query.cell):
		return int(region_map.get_region_id(query.cell))
	return query.region_id


static func _is_valid_region(region_map, region_id: int) -> bool:
	if region_map == null or region_id < 0:
		return false
	if not region_map.has_method("get_region_cells"):
		return false
	return not region_map.get_region_cells(region_id).is_empty()


static func _is_inside_map(region_map, battlefield, cell: Vector2i) -> bool:
	if region_map != null and region_map.has_method("is_inside"):
		return region_map.is_inside(cell)
	return _is_inside_battlefield(battlefield, cell)


static func _is_inside_battlefield(battlefield, cell: Vector2i) -> bool:
	if battlefield == null:
		return false
	if battlefield.has_method("is_inside"):
		return battlefield.is_inside(cell)
	var owner_grid = battlefield.get("owners")
	if not (owner_grid is Array):
		return false
	if cell.x < 0 or cell.y < 0 or cell.x >= (owner_grid as Array).size():
		return false
	var col = (owner_grid as Array)[cell.x]
	return col is Array and cell.y < (col as Array).size()


static func _make_result(
	allowed: bool,
	reason: String,
	region_id: int,
	owner_percent: int,
	resolved_support_id: String = "",
	source_kind: String = DeploymentResultScript.SOURCE_NONE,
	debug_explanation: String = ""
):
	var result = DeploymentResultScript.new()
	result.allowed = allowed
	result.reason = reason
	result.region_id = region_id
	result.owner_percent = owner_percent
	result.resolved_support_id = str(resolved_support_id)
	result.source_kind = str(source_kind)
	result.debug_explanation = str(debug_explanation) if debug_explanation != "" else str(reason)
	return result
