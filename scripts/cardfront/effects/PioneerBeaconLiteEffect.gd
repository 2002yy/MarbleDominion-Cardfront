extends RefCounted
class_name PioneerBeaconLiteEffect

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")

const MAX_CONVERTED_CELLS: int = 3
const REASON_SUCCESS: String = "success"
const REASON_MISSING_SYSTEM: String = "missing_system"
const REASON_INVALID_TARGET: String = "invalid_target"
const REASON_NO_NEUTRAL_NEIGHBOR: String = "no_neutral_neighbor"

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(-1, -1),
	Vector2i(-1, 1),
]


static func apply(region_map, battlefield, owner_id: int, target_cell: Vector2i, max_cells: int = MAX_CONVERTED_CELLS) -> Dictionary:
	if region_map == null or battlefield == null or not battlefield.has_method("apply_owner_change"):
		return _result(false, REASON_MISSING_SYSTEM, [])
	if not DeploymentRulesScript.is_owned_border(region_map, battlefield, target_cell, owner_id):
		return _result(false, REASON_INVALID_TARGET, [])

	var neutral_neighbors: Array[Vector2i] = _find_neutral_neighbors(region_map, battlefield, target_cell)
	if neutral_neighbors.is_empty():
		return _result(false, REASON_NO_NEUTRAL_NEIGHBOR, [])

	var converted_cells: Array[Vector2i] = []
	var limit: int = clampi(int(max_cells), 1, MAX_CONVERTED_CELLS)
	for cell in neutral_neighbors:
		if converted_cells.size() >= limit:
			break
		var result: String = str(battlefield.apply_owner_change(cell, owner_id, "pioneer_beacon"))
		if result == "OWNER_CHANGED":
			converted_cells.append(cell)

	if converted_cells.is_empty():
		return _result(false, REASON_NO_NEUTRAL_NEIGHBOR, [])
	return _result(true, REASON_SUCCESS, converted_cells)


static func _find_neutral_neighbors(region_map, battlefield, target_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in NEIGHBOR_OFFSETS:
		var neighbor: Vector2i = target_cell + offset
		if not _is_inside(region_map, battlefield, neighbor):
			continue
		if DeploymentRulesScript.get_owner_at(battlefield, neighbor) == CardfrontRulesScript.NEUTRAL_OWNER:
			cells.append(neighbor)
	return cells


static func _is_inside(region_map, battlefield, cell: Vector2i) -> bool:
	if region_map != null and region_map.has_method("is_inside"):
		return bool(region_map.is_inside(cell))
	if battlefield != null and battlefield.has_method("is_inside"):
		return bool(battlefield.is_inside(cell))
	return false


static func _result(success: bool, reason: String, converted_cells: Array[Vector2i]) -> Dictionary:
	return {
		"success": success,
		"reason": reason,
		"converted_cells": converted_cells,
	}
