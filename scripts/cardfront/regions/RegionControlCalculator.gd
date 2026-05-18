extends RefCounted
class_name RegionControlCalculator

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

const STATUS_EMPTY: String = "empty"
const STATUS_CONTESTED: String = "contested"
const STATUS_INFLUENCED: String = "influenced"
const STATUS_CONTROLLED: String = "controlled"


static func calculate(region_map, battlefield, region_id: int) -> Dictionary:
	var cells: Array = []
	var region_type: String = RegionTypeScript.NORMAL
	if region_map != null:
		cells = region_map.get_region_cells(region_id)
		region_type = region_map.get_region_type_by_id(region_id)

	var owner_counts: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: 0,
		CardfrontRulesScript.AI_FACTION: 0,
		CardfrontRulesScript.NEUTRAL_OWNER: 0,
	}
	for cell in cells:
		var owner_id: int = _get_owner_at(battlefield, cell)
		owner_counts[owner_id] = int(owner_counts.get(owner_id, 0)) + 1

	return {
		"region_id": region_id,
		"region_type": region_type,
		"total_cells": cells.size(),
		"owner_counts": owner_counts,
	}


static func get_owner_percent(control: Dictionary, owner_id: int) -> int:
	var total_cells: int = int(control.get("total_cells", 0))
	if total_cells <= 0:
		return 0
	var owner_counts: Dictionary = control.get("owner_counts", {})
	var owner_cells: int = int(owner_counts.get(owner_id, 0))
	return int(floor(float(owner_cells) * 100.0 / float(total_cells)))


static func get_region_status(control: Dictionary) -> String:
	var total_cells: int = int(control.get("total_cells", 0))
	if total_cells <= 0:
		return STATUS_EMPTY

	var owner_counts: Dictionary = control.get("owner_counts", {})
	var best_owner: int = CardfrontRulesScript.NEUTRAL_OWNER
	var best_percent: int = -1
	var tied: bool = false
	for owner_id in owner_counts.keys():
		var percent: int = get_owner_percent(control, int(owner_id))
		if percent > best_percent:
			best_owner = int(owner_id)
			best_percent = percent
			tied = false
		elif percent == best_percent:
			tied = true

	if tied or best_percent < 50:
		return STATUS_CONTESTED
	if best_owner == CardfrontRulesScript.NEUTRAL_OWNER:
		return STATUS_CONTESTED
	if best_percent >= 80:
		return STATUS_CONTROLLED
	return STATUS_INFLUENCED


static func get_yield_tier(control: Dictionary, owner_id: int) -> int:
	var percent: int = get_owner_percent(control, owner_id)
	if percent >= 80:
		return 2
	if percent >= 50:
		return 1
	return 0


static func _get_owner_at(battlefield, cell: Vector2i) -> int:
	if battlefield == null:
		return CardfrontRulesScript.NEUTRAL_OWNER
	var owner_grid = battlefield.get("owners")
	if not (owner_grid is Array):
		return CardfrontRulesScript.NEUTRAL_OWNER
	if cell.x < 0 or cell.y < 0 or cell.x >= (owner_grid as Array).size():
		return CardfrontRulesScript.NEUTRAL_OWNER
	var col = (owner_grid as Array)[cell.x]
	if not (col is Array) or cell.y >= (col as Array).size():
		return CardfrontRulesScript.NEUTRAL_OWNER
	return int((col as Array)[cell.y])
