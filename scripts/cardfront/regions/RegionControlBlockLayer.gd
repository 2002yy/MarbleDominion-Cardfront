extends Node2D
class_name RegionControlBlockLayer

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")

const DARK_OUTLINE: Color = Color(0.015, 0.025, 0.045, 0.96)
const BADGE_BG: Color = Color(0.02, 0.035, 0.065, 0.90)

var region_map = null
var battlefield = null
var cell_size: int = GameConfig.CELL_SIZE
var _dirty: bool = true
var _visuals: Array[Dictionary] = []


func _init() -> void:
	name = "RegionControlBlockLayer"
	z_index = 3
	set_process(false)


func setup(new_region_map, new_battlefield, mode_name: String) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
		cell_size = int(battlefield.cell_size)
		var changed := Callable(self, "mark_dirty")
		if battlefield.has_signal("scores_changed") and not battlefield.scores_changed.is_connected(changed):
			battlefield.scores_changed.connect(changed)
	mark_dirty()


func mark_dirty(_counts = {}) -> void:
	_dirty = true
	_rebuild_visuals()
	queue_redraw()


func get_region_visuals_for_test() -> Array:
	return _visuals.duplicate(true)


func _rebuild_visuals() -> void:
	_visuals.clear()
	if not visible or region_map == null or battlefield == null:
		return
	for region_id_value in region_map.get_controllable_region_ids():
		var region_id: int = int(region_id_value)
		var cells: Array = region_map.get_region_cells(region_id)
		if cells.is_empty():
			continue
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
		var leader: Dictionary = _get_leader(control)
		_visuals.append({
			"region_id": region_id,
			"region_type": str(control.get("region_type", "normal")),
			"cells": cells,
			"bounds": _cell_bounds(cells),
			"owner_id": int(leader.owner_id),
			"percent": int(leader.percent),
			"label": "%s · %s %d%%" % [_region_type_name(str(control.get("region_type", "normal"))), CardfrontRulesScript.owner_display_name(int(leader.owner_id)), int(leader.percent)],
		})


func _draw() -> void:
	if not visible or not _dirty:
		return
	_dirty = false
	var outer_width: float = maxf(3.0, float(cell_size) * 0.24)
	var color_width: float = maxf(1.5, float(cell_size) * 0.11)
	for visual in _visuals:
		var region_id: int = int(visual.region_id)
		var owner_id: int = int(visual.owner_id)
		var owner_color: Color = CardfrontRulesScript.owner_color(owner_id)
		var fill_alpha: float = 0.24 if owner_id != CardfrontRulesScript.NEUTRAL_OWNER else 0.12
		for cell_value in visual.cells:
			var cell: Vector2i = cell_value
			var rect := Rect2(Vector2(cell.x, cell.y) * float(cell_size), Vector2.ONE * float(cell_size))
			draw_rect(rect.grow(-1.0), Color(owner_color.r, owner_color.g, owner_color.b, fill_alpha), true)
			_draw_boundary_edges(cell, region_id, outer_width, DARK_OUTLINE)
			_draw_boundary_edges(cell, region_id, color_width, owner_color.lightened(0.22))
		_draw_badge(visual, owner_color)


func _draw_boundary_edges(cell: Vector2i, region_id: int, width: float, color: Color) -> void:
	var x0: float = float(cell.x * cell_size)
	var y0: float = float(cell.y * cell_size)
	var x1: float = x0 + float(cell_size)
	var y1: float = y0 + float(cell_size)
	if _neighbor_region(cell + Vector2i.LEFT) != region_id:
		draw_line(Vector2(x0, y0), Vector2(x0, y1), color, width, true)
	if _neighbor_region(cell + Vector2i.RIGHT) != region_id:
		draw_line(Vector2(x1, y0), Vector2(x1, y1), color, width, true)
	if _neighbor_region(cell + Vector2i.UP) != region_id:
		draw_line(Vector2(x0, y0), Vector2(x1, y0), color, width, true)
	if _neighbor_region(cell + Vector2i.DOWN) != region_id:
		draw_line(Vector2(x0, y1), Vector2(x1, y1), color, width, true)


func _draw_badge(visual: Dictionary, owner_color: Color) -> void:
	var bounds: Rect2 = visual.bounds
	var font_size: int = clampi(int(round(float(cell_size) * 0.95)), 14, 24)
	var badge_size := Vector2(clampf(bounds.size.x - 12.0, 92.0, 154.0), float(font_size + 16))
	var badge := Rect2(bounds.get_center() - badge_size * 0.5, badge_size)
	draw_rect(badge, BADGE_BG, true)
	draw_rect(badge, DARK_OUTLINE, false, 5.0)
	draw_rect(badge.grow(-2.0), owner_color.lightened(0.25), false, 2.0)
	var baseline := Vector2(badge.position.x, badge.position.y + (badge.size.y + float(font_size)) * 0.5 - 4.0)
	draw_string(ThemeDB.fallback_font, baseline, str(visual.label), HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, font_size, Color.WHITE)


func _get_leader(control: Dictionary) -> Dictionary:
	var best_owner: int = CardfrontRulesScript.NEUTRAL_OWNER
	var best_percent: int = -1
	for owner_id in CardfrontRulesScript.get_score_owner_ids():
		var percent: int = RegionControlCalculatorScript.get_owner_percent(control, int(owner_id))
		if percent > best_percent:
			best_owner = int(owner_id)
			best_percent = percent
	return {"owner_id": best_owner, "percent": maxi(0, best_percent)}


func _cell_bounds(cells: Array) -> Rect2:
	var min_cell: Vector2i = cells[0]
	var max_cell: Vector2i = cells[0]
	for cell_value in cells:
		var cell: Vector2i = cell_value
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	return Rect2(Vector2(min_cell) * float(cell_size), Vector2(max_cell - min_cell + Vector2i.ONE) * float(cell_size))


func _neighbor_region(cell: Vector2i) -> int:
	if region_map == null or not region_map.is_inside(cell):
		return -1
	return int(region_map.get_region_id(cell))


func _region_type_name(region_type: String) -> String:
	match region_type:
		"energy":
			return "能源"
		"factory":
			return "工厂"
		"lab":
			return "实验室"
		_:
			return "区域"
