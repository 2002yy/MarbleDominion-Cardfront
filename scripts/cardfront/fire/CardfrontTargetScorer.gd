extends RefCounted
class_name CardfrontTargetScorer

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const FireRulesScript = preload("res://scripts/cardfront/fire/CardfrontFireRules.gd")


static func select_base_target(region_map, battlefield, owner_id: int) -> Dictionary:
	return _select_target(region_map, battlefield, owner_id, -1, FireRulesScript.REASON_BASE)


static func select_region_target(region_map, battlefield, owner_id: int, region_id: int, reason: String = FireRulesScript.REASON_TARGET_BIAS) -> Dictionary:
	return _select_target(region_map, battlefield, owner_id, int(region_id), reason)


static func _select_target(region_map, battlefield, owner_id: int, preferred_region_id: int, preferred_reason: String) -> Dictionary:
	if region_map == null or battlefield == null:
		return _result(false, -1, Vector2i(-1, -1), preferred_reason)
	if not region_map.has_method("get_all_region_ids") or not region_map.has_method("get_region_cells"):
		return _result(false, -1, Vector2i(-1, -1), preferred_reason)

	var best_score: int = -999999
	var best_region_id: int = -1
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_reason: String = preferred_reason
	var region_ids: Array = [preferred_region_id] if preferred_region_id >= 0 else region_map.get_all_region_ids()

	for region_id in region_ids:
		var safe_region_id: int = int(region_id)
		var cells: Array = region_map.get_region_cells(safe_region_id)
		if cells.is_empty():
			continue
		var region_type: String = str(region_map.get_region_type_by_id(safe_region_id))
		var enemy_resource_region: bool = _is_enemy_controlled_resource_region(region_map, battlefield, safe_region_id, owner_id, region_type)
		for raw_cell in cells:
			var cell: Vector2i = raw_cell
			var owner_at_cell: int = DeploymentRulesScript.get_owner_at(battlefield, cell)
			if owner_at_cell == int(owner_id):
				continue
			var score: int = _score_cell(region_map, battlefield, owner_id, cell, owner_at_cell, region_type, enemy_resource_region, preferred_region_id >= 0)
			if score > best_score:
				best_score = score
				best_region_id = safe_region_id
				best_cell = cell
				best_reason = _reason_for_cell(region_map, battlefield, owner_id, cell, owner_at_cell, region_type, enemy_resource_region, preferred_reason)

	if best_region_id < 0:
		return _result(false, -1, Vector2i(-1, -1), preferred_reason)
	return _result(true, best_region_id, best_cell, best_reason)


static func _score_cell(region_map, battlefield, owner_id: int, cell: Vector2i, owner_at_cell: int, region_type: String, enemy_resource_region: bool, preferred_region: bool) -> int:
	var score: int = 0
	if preferred_region:
		score += 1000
	if owner_at_cell == CardfrontRulesScript.NEUTRAL_OWNER:
		score += 120
		if _touches_owner(region_map, battlefield, cell, owner_id):
			score += 300
	else:
		score += 50
	if _is_resource_type(region_type):
		score += 80
	if enemy_resource_region:
		score += 120
	score -= cell.x + cell.y
	return score


static func _reason_for_cell(region_map, battlefield, owner_id: int, cell: Vector2i, owner_at_cell: int, region_type: String, enemy_resource_region: bool, preferred_reason: String) -> String:
	if preferred_reason == FireRulesScript.REASON_TARGET_BIAS:
		return FireRulesScript.REASON_TARGET_BIAS
	if owner_at_cell == CardfrontRulesScript.NEUTRAL_OWNER and _touches_owner(region_map, battlefield, cell, owner_id):
		return FireRulesScript.REASON_NEUTRAL_BOUNDARY
	if enemy_resource_region:
		return FireRulesScript.REASON_ENEMY_RESOURCE_REGION
	if _is_resource_type(region_type):
		return FireRulesScript.REASON_RESOURCE_REGION
	return FireRulesScript.REASON_BASE


static func _touches_owner(region_map, battlefield, cell: Vector2i, owner_id: int) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var neighbor := Vector2i(cell.x + dx, cell.y + dy)
			if not _is_inside(region_map, battlefield, neighbor):
				continue
			if DeploymentRulesScript.get_owner_at(battlefield, neighbor) == int(owner_id):
				return true
	return false


static func _is_enemy_controlled_resource_region(region_map, battlefield, region_id: int, owner_id: int, region_type: String) -> bool:
	if not _is_resource_type(region_type):
		return false
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	for candidate_owner in [CardfrontRulesScript.PLAYER_FACTION, CardfrontRulesScript.AI_FACTION]:
		if int(candidate_owner) == int(owner_id):
			continue
		if RegionControlCalculatorScript.get_owner_percent(control, int(candidate_owner)) >= 50:
			return true
	return false


static func _is_resource_type(region_type: String) -> bool:
	return region_type == RegionTypeScript.ENERGY or region_type == RegionTypeScript.FACTORY or region_type == RegionTypeScript.LAB


static func _is_inside(region_map, battlefield, cell: Vector2i) -> bool:
	if region_map != null and region_map.has_method("is_inside"):
		return bool(region_map.is_inside(cell))
	if battlefield != null and battlefield.has_method("is_inside"):
		return bool(battlefield.is_inside(cell))
	return false


static func _result(success: bool, region_id: int, cell: Vector2i, reason: String) -> Dictionary:
	return {
		"success": success,
		"target_region_id": region_id,
		"target_cell": cell,
		"reason": reason,
	}
