extends RefCounted
class_name CardfrontBattlefieldInitializer

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")


static func configure_duel(battlefield) -> Dictionary:
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if not battlefield.has_method("replace_owners"):
		return {"configured": false, "reason": "missing_replace_owners"}

	var extent := GridExtentScript.normalize(battlefield.get("grid_extent"), Vector2i(int(battlefield.grid_size), int(battlefield.grid_size)))
	var owner_grid: Array = build_duel_owner_grid_extent(extent)
	if battlefield.has_method("set_owner_color_override"):
		battlefield.set_owner_color_override(Rules.NEUTRAL_OWNER, Rules.NEUTRAL_COLOR, false)

	var applied: bool = bool(battlefield.replace_owners(owner_grid, true))
	if not applied:
		return {"configured": false, "reason": "owner_grid_rejected"}

	return {
		"configured": true,
		"grid_size": int(battlefield.grid_size),
		"grid_extent": GridExtentScript.to_array(extent),
		"spawn_rows": get_spawn_rows(extent.y),
		"spawn_columns": get_spawn_columns(extent.x),
	}


static func build_duel_owner_grid(grid_size: int) -> Array:
	return build_duel_owner_grid_extent(Vector2i(grid_size, grid_size))


static func build_duel_owner_grid_extent(grid_extent_value) -> Array:
	var extent := GridExtentScript.normalize(grid_extent_value)
	var result: Array = []
	for x in range(extent.x):
		var col: Array = []
		for y in range(extent.y):
			col.append(duel_owner_for_cell(x, y, extent.y))
		result.append(col)
	return result


static func get_spawn_columns(grid_size: int) -> int:
	return get_spawn_rows(grid_size)


static func get_spawn_rows(grid_size: int) -> int:
	var safe_size: int = maxi(4, grid_size)
	var desired: int = int(round(float(safe_size) * 0.20))
	return clampi(desired, 2, maxi(2, floori(float(safe_size) / 2.0) - 1))


static func duel_owner_for_cell(_x: int, y: int, grid_size: int) -> int:
	var spawn_rows: int = get_spawn_rows(grid_size)
	if y < spawn_rows:
		return Rules.AI_FACTION
	if y >= grid_size - spawn_rows:
		return Rules.PLAYER_FACTION
	return Rules.NEUTRAL_OWNER
