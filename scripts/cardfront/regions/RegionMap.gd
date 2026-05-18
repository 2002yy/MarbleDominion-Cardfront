extends RefCounted
class_name RegionMap

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")

const NORMAL_REGION_ID: int = 0

var grid_size: int = 0
var regions: Array = []
var region_ids: Array = []
var region_types: Dictionary = {}
var region_cells: Dictionary = {}
var next_region_id: int = 1


func configure(new_grid_size: int) -> void:
	grid_size = maxi(1, int(new_grid_size))
	_reset_regions_to_normal()


func generate_default_layout() -> void:
	if grid_size <= 0:
		configure(40)
	_reset_regions_to_normal()

	var spawn_columns: int = BattlefieldInitializer.get_spawn_columns(grid_size)
	var contest_min_x: int = spawn_columns
	var contest_max_x: int = grid_size - spawn_columns - 1
	var center: int = grid_size >> 1
	var resource_radius: int = maxi(1, grid_size / 20)
	var lab_radius: int = maxi(2, grid_size / 12)

	var energy_margin: int = maxi(2, grid_size / 20)
	var energy_y_top: int = grid_size / 4
	var energy_y_bottom: int = grid_size - energy_y_top - 1
	_paint_rect_instance(
		contest_min_x + energy_margin,
		energy_y_top - resource_radius,
		contest_max_x - energy_margin,
		energy_y_top + resource_radius,
		RegionTypeScript.ENERGY
	)
	_paint_rect_instance(
		contest_min_x + energy_margin,
		energy_y_bottom - resource_radius,
		contest_max_x - energy_margin,
		energy_y_bottom + resource_radius,
		RegionTypeScript.ENERGY
	)

	var contest_width: int = maxi(1, contest_max_x - contest_min_x + 1)
	var factory_left_x: int = contest_min_x + contest_width / 4
	var factory_right_x: int = contest_max_x - contest_width / 4
	_paint_rect_instance(
		factory_left_x - resource_radius,
		center - lab_radius,
		factory_left_x + resource_radius,
		center + lab_radius,
		RegionTypeScript.FACTORY
	)
	_paint_rect_instance(
		factory_right_x - resource_radius,
		center - lab_radius,
		factory_right_x + resource_radius,
		center + lab_radius,
		RegionTypeScript.FACTORY
	)

	_paint_diamond_instance(center, center, lab_radius, RegionTypeScript.LAB)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size


func get_region_type(cell: Vector2i) -> String:
	if not is_inside(cell):
		return RegionTypeScript.NORMAL
	return get_region_type_by_id(get_region_id(cell))


func set_region_type(cell: Vector2i, region_type: String) -> bool:
	if not is_inside(cell):
		return false
	if not RegionTypeScript.is_valid(region_type):
		return false
	var target_region_id: int = NORMAL_REGION_ID
	if region_type != RegionTypeScript.NORMAL:
		target_region_id = _allocate_region(region_type)
	_assign_cell_to_region(cell, target_region_id)
	return true


func count_region_cells(region_type: String) -> int:
	if not RegionTypeScript.is_valid(region_type):
		return 0
	var total: int = 0
	for region_id in get_region_ids_by_type(region_type):
		total += get_region_cells(int(region_id)).size()
	return total


func count_owned_region_cells(battlefield, owner_id: int, region_type: String) -> int:
	if battlefield == null or not RegionTypeScript.is_valid(region_type):
		return 0
	if int(battlefield.grid_size) != grid_size:
		return 0
	if not (battlefield.owners is Array) or battlefield.owners.size() != grid_size:
		return 0

	var total: int = 0
	for region_id in get_region_ids_by_type(region_type):
		for cell in get_region_cells(int(region_id)):
			if not (battlefield.owners[cell.x] is Array):
				continue
			if int(battlefield.owners[cell.x][cell.y]) == owner_id:
				total += 1
	return total


func get_region_id(cell: Vector2i) -> int:
	if not is_inside(cell):
		return NORMAL_REGION_ID
	if region_ids.size() != grid_size:
		return NORMAL_REGION_ID
	return int(region_ids[cell.x][cell.y])


func get_region_type_by_id(region_id: int) -> String:
	if not region_types.has(region_id):
		return RegionTypeScript.NORMAL
	return str(region_types[region_id])


func get_region_cells(region_id: int) -> Array:
	if not region_cells.has(region_id):
		return []
	return (region_cells[region_id] as Array).duplicate()


func get_region_ids_by_type(region_type: String) -> Array:
	if not RegionTypeScript.is_valid(region_type):
		return []
	var matches: Array = []
	for region_id in region_types.keys():
		if str(region_types[region_id]) == region_type:
			matches.append(int(region_id))
	matches.sort()
	return matches


func get_all_region_ids() -> Array:
	var ids: Array = []
	for region_id in region_types.keys():
		ids.append(int(region_id))
	ids.sort()
	return ids


func get_controllable_region_ids() -> Array:
	var ids: Array = []
	for region_id in get_all_region_ids():
		if int(region_id) == NORMAL_REGION_ID:
			continue
		ids.append(int(region_id))
	return ids


func snapshot() -> Dictionary:
	return {
		"grid_size": grid_size,
		"regions": regions.duplicate(true),
		"region_ids": region_ids.duplicate(true),
		"region_types": _snapshot_region_types(),
		"region_cells": _snapshot_region_cells(),
		"next_region_id": next_region_id,
	}


func _reset_regions_to_normal() -> void:
	regions.clear()
	region_ids.clear()
	region_types.clear()
	region_cells.clear()
	next_region_id = 1
	region_types[NORMAL_REGION_ID] = RegionTypeScript.NORMAL
	region_cells[NORMAL_REGION_ID] = []
	for x in range(grid_size):
		var type_col: Array = []
		var id_col: Array = []
		for y in range(grid_size):
			type_col.append(RegionTypeScript.NORMAL)
			id_col.append(NORMAL_REGION_ID)
			(region_cells[NORMAL_REGION_ID] as Array).append(Vector2i(x, y))
		regions.append(type_col)
		region_ids.append(id_col)


func _paint_rect_instance(x0: int, y0: int, x1: int, y1: int, region_type: String) -> int:
	if not RegionTypeScript.is_valid(region_type):
		return NORMAL_REGION_ID
	var region_id: int = _allocate_region(region_type)
	for x in range(clampi(x0, 0, grid_size - 1), clampi(x1, 0, grid_size - 1) + 1):
		for y in range(clampi(y0, 0, grid_size - 1), clampi(y1, 0, grid_size - 1) + 1):
			_assign_cell_to_region(Vector2i(x, y), region_id)
	return region_id


func _paint_diamond_instance(center_x: int, center_y: int, radius: int, region_type: String) -> int:
	if not RegionTypeScript.is_valid(region_type):
		return NORMAL_REGION_ID
	var region_id: int = _allocate_region(region_type)
	for x in range(center_x - radius, center_x + radius + 1):
		for y in range(center_y - radius, center_y + radius + 1):
			if abs(x - center_x) + abs(y - center_y) <= radius:
				_assign_cell_to_region(Vector2i(x, y), region_id)
	return region_id


func _allocate_region(region_type: String) -> int:
	if region_type == RegionTypeScript.NORMAL:
		return NORMAL_REGION_ID
	var region_id: int = next_region_id
	next_region_id += 1
	region_types[region_id] = region_type
	region_cells[region_id] = []
	return region_id


func _assign_cell_to_region(cell: Vector2i, region_id: int) -> void:
	if not is_inside(cell):
		return
	if not region_types.has(region_id):
		return
	var previous_region_id: int = int(region_ids[cell.x][cell.y])
	if previous_region_id == region_id:
		return
	if region_cells.has(previous_region_id):
		(region_cells[previous_region_id] as Array).erase(cell)
		_prune_empty_region(previous_region_id)
	region_ids[cell.x][cell.y] = region_id
	regions[cell.x][cell.y] = str(region_types[region_id])
	(region_cells[region_id] as Array).append(cell)


func _prune_empty_region(region_id: int) -> void:
	if region_id == NORMAL_REGION_ID:
		return
	if region_cells.has(region_id) and (region_cells[region_id] as Array).is_empty():
		region_cells.erase(region_id)
		region_types.erase(region_id)


func _snapshot_region_types() -> Dictionary:
	var data: Dictionary = {}
	for region_id in get_all_region_ids():
		data[str(region_id)] = get_region_type_by_id(int(region_id))
	return data


func _snapshot_region_cells() -> Dictionary:
	var data: Dictionary = {}
	for region_id in get_all_region_ids():
		var cells: Array = []
		for cell in get_region_cells(int(region_id)):
			cells.append([cell.x, cell.y])
		data[str(region_id)] = cells
	return data
