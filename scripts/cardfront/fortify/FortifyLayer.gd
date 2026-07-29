extends RefCounted
class_name FortifyLayer

signal stack_changed(cell, previous_value, current_value)
signal refill_completed(owner_caps, defended_cell_count)

const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")

var grid_size: int = 0
var grid_extent: Vector2i = Vector2i.ZERO
var stacks: Array = []
var overlay_dirty_callback = null


func configure(new_grid_size: int) -> void:
	configure_extent(Vector2i(new_grid_size, new_grid_size))


func configure_extent(new_grid_extent) -> void:
	grid_extent = GridExtentScript.normalize(new_grid_extent)
	grid_size = grid_extent.x
	stacks.clear()
	for x in range(grid_extent.x):
		var col: Array = []
		for y in range(grid_extent.y):
			col.append(0)
		stacks.append(col)


func get_fortify_stack(cell: Vector2i) -> int:
	if not _is_inside(cell):
		return 0
	return int(stacks[cell.x][cell.y])


func set_fortify_stack(cell: Vector2i, value: int) -> void:
	if not _is_inside(cell):
		return
	var previous: int = int(stacks[cell.x][cell.y])
	var current: int = clampi(value, 0, FortifyRulesScript.MAX_FORTIFY_STACKS)
	stacks[cell.x][cell.y] = current
	if previous != current:
		stack_changed.emit(cell, previous, current)
	_notify_overlay()


func add_fortify_stack(cell: Vector2i, amount: int = 1) -> void:
	if not _is_inside(cell):
		return
	set_fortify_stack(cell, int(stacks[cell.x][cell.y]) + amount)


func clear_fortify_stack(cell: Vector2i) -> void:
	set_fortify_stack(cell, 0)


func fortify_cells(cells: Array, amount: int = FortifyRulesScript.DEFAULT_FORTIFY_STACKS) -> void:
	for raw_cell in cells:
		var cell: Vector2i
		if raw_cell is Vector2i:
			cell = raw_cell
		elif raw_cell is Dictionary:
			cell = Vector2i(int(raw_cell.get("x", 0)), int(raw_cell.get("y", 0)))
		else:
			continue
		add_fortify_stack(cell, amount)


func consume_hit(cell: Vector2i) -> bool:
	if not _is_inside(cell):
		return false
	var current: int = int(stacks[cell.x][cell.y])
	if current <= 0:
		return false
	stacks[cell.x][cell.y] = current - 1
	stack_changed.emit(cell, current, current - 1)
	_notify_overlay()
	return true


func refill_from_owner_caps(owner_grid: Array, owner_caps: Dictionary) -> int:
	if owner_grid.size() != grid_extent.x:
		return 0
	var defended_cell_count: int = 0
	var changed: bool = false
	for x in range(grid_extent.x):
		if not (owner_grid[x] is Array) or (owner_grid[x] as Array).size() < grid_extent.y:
			return 0
		for y in range(grid_extent.y):
			var owner_id: int = int(owner_grid[x][y])
			var target: int = clampi(
				int(owner_caps.get(owner_id, 0)),
				0,
				FortifyRulesScript.MAX_FORTIFY_STACKS
			)
			var previous: int = int(stacks[x][y])
			if previous != target:
				stacks[x][y] = target
				stack_changed.emit(Vector2i(x, y), previous, target)
				changed = true
			if target > 0:
				defended_cell_count += 1
	if changed:
		_notify_overlay()
	refill_completed.emit(owner_caps.duplicate(), defended_cell_count)
	return defended_cell_count


func is_fortified(cell: Vector2i) -> bool:
	return get_fortify_stack(cell) > 0


func snapshot() -> Dictionary:
	var data: Array = []
	for x in range(grid_extent.x):
		var col: Array = []
		for y in range(grid_extent.y):
			col.append(int(stacks[x][y]))
		data.append(col)
	return {
		"grid_size": grid_size,
		"grid_extent": GridExtentScript.to_array(grid_extent),
		"stacks": data,
	}


func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	grid_extent = GridExtentScript.from_config(data, grid_extent if grid_extent != Vector2i.ZERO else GridExtentScript.DEFAULT)
	grid_size = grid_extent.x
	var source: Array = data.get("stacks", [])
	if source.is_empty() or source.size() != grid_extent.x:
		return
	stacks.clear()
	for x in range(grid_extent.x):
		var col: Array = []
		var src_col = source[x] as Array
		for y in range(grid_extent.y):
			col.append(clampi(int(src_col[y]) if y < src_col.size() else 0, 0, FortifyRulesScript.MAX_FORTIFY_STACKS))
		stacks.append(col)


func _is_inside(cell: Vector2i) -> bool:
	if grid_extent.x <= 0 or grid_extent.y <= 0 or stacks.is_empty():
		return false
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_extent.x and cell.y < grid_extent.y


func _notify_overlay() -> void:
	if overlay_dirty_callback != null and overlay_dirty_callback is Callable and overlay_dirty_callback.is_valid():
		overlay_dirty_callback.call()
