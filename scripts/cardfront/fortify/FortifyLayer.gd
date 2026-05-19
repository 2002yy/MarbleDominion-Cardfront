extends RefCounted
class_name FortifyLayer

const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")

var grid_size: int = 0
var stacks: Array = []


func configure(new_grid_size: int) -> void:
	grid_size = new_grid_size
	stacks.clear()
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(0)
		stacks.append(col)


func get_fortify_stack(cell: Vector2i) -> int:
	if not _is_inside(cell):
		return 0
	return int(stacks[cell.x][cell.y])


func set_fortify_stack(cell: Vector2i, value: int) -> void:
	if not _is_inside(cell):
		return
	stacks[cell.x][cell.y] = clampi(value, 0, FortifyRulesScript.MAX_FORTIFY_STACKS)


func add_fortify_stack(cell: Vector2i, amount: int = 1) -> void:
	if not _is_inside(cell):
		return
	stacks[cell.x][cell.y] = clampi(int(stacks[cell.x][cell.y]) + amount, 0, FortifyRulesScript.MAX_FORTIFY_STACKS)


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
	return true


func is_fortified(cell: Vector2i) -> bool:
	return get_fortify_stack(cell) > 0


func snapshot() -> Dictionary:
	var data: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(int(stacks[x][y]))
		data.append(col)
	return {
		"grid_size": grid_size,
		"stacks": data,
	}


func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	grid_size = int(data.get("grid_size", grid_size))
	var source: Array = data.get("stacks", [])
	if source.is_empty() or source.size() != grid_size:
		return
	stacks.clear()
	for x in range(grid_size):
		var col: Array = []
		var src_col = source[x] as Array
		for y in range(grid_size):
			col.append(clampi(int(src_col[y]) if y < src_col.size() else 0, 0, FortifyRulesScript.MAX_FORTIFY_STACKS))
		stacks.append(col)


func _is_inside(cell: Vector2i) -> bool:
	if grid_size <= 0 or stacks.is_empty():
		return false
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size
