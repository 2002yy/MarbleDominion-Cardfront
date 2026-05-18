extends RefCounted
class_name RegionMap

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")

var grid_size: int = 0
var regions: Array = []


func configure(new_grid_size: int) -> void:
	grid_size = maxi(1, int(new_grid_size))
	_fill_regions(RegionTypeScript.NORMAL)


func generate_default_layout() -> void:
	if grid_size <= 0:
		configure(40)
	_fill_regions(RegionTypeScript.NORMAL)

	var spawn_columns: int = BattlefieldInitializer.get_spawn_columns(grid_size)
	var contest_min_x: int = spawn_columns
	var contest_max_x: int = grid_size - spawn_columns - 1
	var center: int = grid_size >> 1
	var resource_radius: int = maxi(1, grid_size / 20)
	var lab_radius: int = maxi(2, grid_size / 12)

	var energy_margin: int = maxi(2, grid_size / 20)
	var energy_y_top: int = grid_size / 4
	var energy_y_bottom: int = grid_size - energy_y_top - 1
	_paint_rect(
		contest_min_x + energy_margin,
		energy_y_top - resource_radius,
		contest_max_x - energy_margin,
		energy_y_top + resource_radius,
		RegionTypeScript.ENERGY
	)
	_paint_rect(
		contest_min_x + energy_margin,
		energy_y_bottom - resource_radius,
		contest_max_x - energy_margin,
		energy_y_bottom + resource_radius,
		RegionTypeScript.ENERGY
	)

	var contest_width: int = maxi(1, contest_max_x - contest_min_x + 1)
	var factory_left_x: int = contest_min_x + contest_width / 4
	var factory_right_x: int = contest_max_x - contest_width / 4
	_paint_rect(
		factory_left_x - resource_radius,
		center - lab_radius,
		factory_left_x + resource_radius,
		center + lab_radius,
		RegionTypeScript.FACTORY
	)
	_paint_rect(
		factory_right_x - resource_radius,
		center - lab_radius,
		factory_right_x + resource_radius,
		center + lab_radius,
		RegionTypeScript.FACTORY
	)

	_paint_diamond(center, center, lab_radius, RegionTypeScript.LAB)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size


func get_region_type(cell: Vector2i) -> String:
	if not is_inside(cell):
		return RegionTypeScript.NORMAL
	return str(regions[cell.x][cell.y])


func set_region_type(cell: Vector2i, region_type: String) -> bool:
	if not is_inside(cell):
		return false
	if not RegionTypeScript.is_valid(region_type):
		return false
	regions[cell.x][cell.y] = region_type
	return true


func count_region_cells(region_type: String) -> int:
	if not RegionTypeScript.is_valid(region_type):
		return 0
	var total: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if str(regions[x][y]) == region_type:
				total += 1
	return total


func count_owned_region_cells(battlefield, owner_id: int, region_type: String) -> int:
	if battlefield == null or not RegionTypeScript.is_valid(region_type):
		return 0
	if int(battlefield.grid_size) != grid_size:
		return 0
	if not (battlefield.owners is Array) or battlefield.owners.size() != grid_size:
		return 0

	var total: int = 0
	for x in range(grid_size):
		if not (battlefield.owners[x] is Array):
			continue
		for y in range(grid_size):
			if str(regions[x][y]) == region_type and int(battlefield.owners[x][y]) == owner_id:
				total += 1
	return total


func snapshot() -> Dictionary:
	return {
		"grid_size": grid_size,
		"regions": regions.duplicate(true),
	}


func _fill_regions(region_type: String) -> void:
	regions.clear()
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(region_type)
		regions.append(col)


func _paint_rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> void:
	if not RegionTypeScript.is_valid(region_type):
		return
	for x in range(clampi(x0, 0, grid_size - 1), clampi(x1, 0, grid_size - 1) + 1):
		for y in range(clampi(y0, 0, grid_size - 1), clampi(y1, 0, grid_size - 1) + 1):
			set_region_type(Vector2i(x, y), region_type)


func _paint_diamond(center_x: int, center_y: int, radius: int, region_type: String) -> void:
	if not RegionTypeScript.is_valid(region_type):
		return
	for x in range(center_x - radius, center_x + radius + 1):
		for y in range(center_y - radius, center_y + radius + 1):
			if abs(x - center_x) + abs(y - center_y) <= radius:
				set_region_type(Vector2i(x, y), region_type)
