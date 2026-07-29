extends RefCounted
class_name RegionMap

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const CardfrontMapBuilderScript = preload("res://scripts/cardfront/maps/CardfrontMapBuilder.gd")
const CardfrontMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")

const NORMAL_REGION_ID: int = 0

var grid_size: int = 0
var grid_extent: Vector2i = Vector2i.ZERO
var regions: Array = []
var region_ids: Array = []
var region_types: Dictionary = {}
var region_cells: Dictionary = {}
var next_region_id: int = 1
var map_definition: Dictionary = {}


func configure(new_grid_size: int) -> void:
	configure_extent(Vector2i(new_grid_size, new_grid_size))


func configure_extent(new_grid_extent) -> void:
	grid_extent = GridExtentScript.normalize(new_grid_extent)
	grid_size = grid_extent.x
	_reset_regions_to_normal()


func generate_default_layout() -> void:
	generate_layout(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID)


func generate_layout(map_id: String) -> void:
	if grid_extent.x <= 0 or grid_extent.y <= 0:
		configure_extent(GridExtentScript.DEFAULT)
	var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition(map_id, grid_extent)
	generate_from_definition(definition)


func generate_from_definition(definition: Dictionary) -> void:
	if grid_extent.x <= 0 or grid_extent.y <= 0:
		configure_extent(GridExtentScript.DEFAULT)
	map_definition = definition.duplicate(true)
	if not CardfrontMapBuilderScript.apply_to_region_map(self, definition):
		map_definition.clear()
		clear_regions()


func clear_regions() -> void:
	_reset_regions_to_normal()


func paint_region_rect(x0: int, y0: int, x1: int, y1: int, region_type: String) -> int:
	return _paint_rect_instance(x0, y0, x1, y1, region_type)


func paint_region_diamond(center_x: int, center_y: int, radius: int, region_type: String) -> int:
	return _paint_diamond_instance(center_x, center_y, radius, region_type)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_extent.x and cell.y < grid_extent.y


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
	if not (battlefield.get("grid_extent") is Vector2i) or battlefield.grid_extent != grid_extent:
		return 0
	if not (battlefield.owners is Array) or battlefield.owners.size() != grid_extent.x:
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
	if region_ids.size() != grid_extent.x:
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
		"grid_extent": GridExtentScript.to_array(grid_extent),
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
	for x in range(grid_extent.x):
		var type_col: Array = []
		var id_col: Array = []
		for y in range(grid_extent.y):
			type_col.append(RegionTypeScript.NORMAL)
			id_col.append(NORMAL_REGION_ID)
			(region_cells[NORMAL_REGION_ID] as Array).append(Vector2i(x, y))
		regions.append(type_col)
		region_ids.append(id_col)


func _paint_rect_instance(x0: int, y0: int, x1: int, y1: int, region_type: String) -> int:
	if not RegionTypeScript.is_valid(region_type):
		return NORMAL_REGION_ID
	var region_id: int = _allocate_region(region_type)
	for x in range(clampi(x0, 0, grid_extent.x - 1), clampi(x1, 0, grid_extent.x - 1) + 1):
		for y in range(clampi(y0, 0, grid_extent.y - 1), clampi(y1, 0, grid_extent.y - 1) + 1):
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
