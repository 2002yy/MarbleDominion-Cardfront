extends RefCounted
class_name FortifyTargetSelector

const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")


static func select_owned_border_cells(region_map, battlefield, owner_id: int, max_cells: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if battlefield == null:
		return result
	var extent: Vector2i = battlefield.grid_extent
	for x in range(extent.x):
		for y in range(extent.y):
			var cell := Vector2i(x, y)
			if not DeploymentRulesScript.is_owned_border(region_map, battlefield, cell, owner_id):
				continue
			result.append(cell)
			if result.size() >= max_cells:
				return result
	return result
