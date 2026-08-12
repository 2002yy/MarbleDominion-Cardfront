extends Node2D
class_name CardfrontTargetPreviewLayer

signal deployment_zone_changed(cells, revision)

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const DeploymentQueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")

var battlefield = null
var region_map = null
var cell_size: int = GameConfig.CELL_SIZE
var _active: bool = false
var _valid_cells: Array[Vector2i] = []
var _hint_cells: Array[Vector2i] = []
var _preview_color: Color = Color(0.62, 0.90, 1.0, 0.35)
var _hint_color: Color = Color(0.90, 0.72, 0.18, 0.28)
var _preview_type: String = ""
var _owner_id: int = CardfrontRulesScript.PLAYER_FACTION
var _pulse_time: float = 0.0
var _deployment_context_provider = null
var _deployment_revision_provider = null
var _preview_revision: int = -1

const INVALID_FLASH_DURATION: float = 0.25
var _invalid_flash_cells: Array[Dictionary] = []


func _init() -> void:
	name = "CardfrontTargetPreviewLayer"
	z_index = 5
	set_process(false)


func setup(new_battlefield, new_region_map, mode_name: String) -> void:
	battlefield = new_battlefield
	region_map = new_region_map
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
		cell_size = int(battlefield.cell_size)
	clear_preview()


func configure_deployment_authority(context_provider, revision_provider = null) -> void:
	_deployment_context_provider = context_provider
	_deployment_revision_provider = revision_provider


func show_for_card(card_id: int, card_data: Dictionary) -> void:
	_reset_preview_state()
	_active = true
	_pulse_time = 0.0
	var target_type: String = str(card_data.get("target_type", ""))
	_preview_type = target_type
	_owner_id = CardfrontRulesScript.PLAYER_FACTION

	match target_type:
		CardTargetTypeScript.OWNED_BORDER:
			_preview_color = Color(0.24, 0.62, 1.0, 0.35)
			_find_owned_border_cells()
			if card_id == 1004:
				_find_adjacent_neutral_cells(Color(0.90, 0.72, 0.18, 0.28))
		CardTargetTypeScript.ENEMY_REGION:
			_preview_color = Color(0.20, 0.78, 0.82, 0.30)
			_find_enemy_region_cells()
		CardTargetTypeScript.OWNED_REGION:
			_preview_color = Color(0.72, 0.45, 1.0, 0.30)
			_find_owned_region_cells()
		CardTargetTypeScript.FRONTLINE_DEPLOYMENT:
			_preview_color = Color(0.30, 0.82, 0.52, 0.34)
			_find_frontline_deployment_cells(card_data)

	_emit_deployment_zone()
	set_process(visible)
	queue_redraw()


func clear_preview() -> void:
	_reset_preview_state()
	deployment_zone_changed.emit([], -1)
	queue_redraw()


func _reset_preview_state() -> void:
	_active = false
	_valid_cells.clear()
	_hint_cells.clear()
	_invalid_flash_cells.clear()
	_preview_type = ""
	_preview_revision = -1
	_pulse_time = 0.0
	set_process(false)


func _emit_deployment_zone() -> void:
	var cells: Array = []
	if _active and _preview_type == CardTargetTypeScript.FRONTLINE_DEPLOYMENT:
		cells = _valid_cells.duplicate()
	deployment_zone_changed.emit(cells, _preview_revision)


func is_valid_target(cell: Vector2i) -> bool:
	return _active and cell in _valid_cells


func get_target_region_id(cell: Vector2i) -> int:
	match _preview_type:
		CardTargetTypeScript.OWNED_REGION, CardTargetTypeScript.ENEMY_REGION:
			if region_map != null and region_map.has_method("get_region_id") and region_map.is_inside(cell):
				return int(region_map.get_region_id(cell))
	return -1


func get_preview_type() -> String:
	return _preview_type


func get_preview_revision() -> int:
	return _preview_revision


func get_preview_pulse_alpha_for_test() -> float:
	return _preview_fill_alpha()


func _draw() -> void:
	if not _active:
		return
	var pulse: float = _pulse_value()
	var fill_alpha: float = _preview_fill_alpha()
	var outline_alpha: float = lerpf(0.76, 1.0, pulse)
	var outline_width: float = maxf(1.0, float(cell_size) * 0.12) * lerpf(1.0, 1.65, pulse)
	var fill_color := _with_alpha(_preview_color, fill_alpha)
	var outline_color := _with_alpha(_preview_color.lightened(0.42), outline_alpha)
	for cell in _valid_cells:
		var rect := Rect2(Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))
		draw_rect(rect.grow(-1.5), fill_color, true)
		draw_rect(rect.grow(-0.5), outline_color, false, outline_width)
	var hint_alpha: float = lerpf(0.26, 0.48, pulse)
	var hint_outline_alpha: float = lerpf(0.58, 0.88, pulse)
	var hint_width: float = maxf(1.0, float(cell_size) * 0.10) * lerpf(1.0, 1.45, pulse)
	var hint_fill := _with_alpha(_hint_color, hint_alpha)
	var hint_outline := _with_alpha(_hint_color.lightened(0.36), hint_outline_alpha)
	for cell in _hint_cells:
		var rect := Rect2(Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))
		draw_rect(rect.grow(-1.5), hint_fill, true)
		draw_rect(rect.grow(-0.5), hint_outline, false, hint_width)

	var flash_color := Color(1.0, 0.18, 0.18, 0.50)
	for entry in _invalid_flash_cells:
		var fc: Vector2i = entry.get("cell", Vector2i(-1, -1))
		if fc.x < 0 or fc.y < 0:
			continue
		var frac: float = clampf(entry.get("remaining", 0.0) / INVALID_FLASH_DURATION, 0.0, 1.0)
		var flash_alpha: float = 0.60 * frac
		var rect := Rect2(Vector2(fc.x * cell_size, fc.y * cell_size), Vector2(cell_size, cell_size))
		draw_rect(rect.grow(-1.0), Color(flash_color.r, flash_color.g, flash_color.b, flash_alpha), true)


func _process(delta: float) -> void:
	var needs_redraw: bool = false
	if _active:
		_pulse_time += maxf(0.0, delta)
		needs_redraw = true
	if not _invalid_flash_cells.is_empty():
		var all_expired: bool = true
		for i in range(_invalid_flash_cells.size() - 1, -1, -1):
			_invalid_flash_cells[i]["remaining"] -= maxf(0.0, delta)
			if _invalid_flash_cells[i]["remaining"] <= 0.0:
				_invalid_flash_cells.remove_at(i)
			else:
				all_expired = false
		if not all_expired:
			needs_redraw = true
	if needs_redraw:
		queue_redraw()
	else:
		set_process(false)


func _pulse_value() -> float:
	return 0.5 + 0.5 * sin(_pulse_time * 5.4)


func _preview_fill_alpha() -> float:
	return lerpf(0.34, 0.58, _pulse_value())


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))



func get_hover_target_info(cell: Vector2i) -> Dictionary:
	if not _active:
		return {
			"active": false,
			"valid": false,
			"reason": "no_active_card",
		}

	if cell in _valid_cells:
		return {
			"active": true,
			"valid": true,
			"reason": "valid_target",
			"preview_type": _preview_type,
			"region_id": get_target_region_id(cell),
		}

	return {
		"active": true,
		"valid": false,
		"reason": _invalid_reason_for_preview_type(),
		"preview_type": _preview_type,
	}


func _invalid_reason_for_preview_type() -> String:
	match _preview_type:
		CardTargetTypeScript.OWNED_BORDER:
			return "need_owned_border"
		CardTargetTypeScript.ENEMY_REGION:
			return "need_enemy_region"
		CardTargetTypeScript.OWNED_REGION:
			return "need_owned_region"
		CardTargetTypeScript.FRONTLINE_DEPLOYMENT:
			return "outside_current_deployment_authority"
	return "invalid_target"


func flash_invalid_cell(cell: Vector2i) -> void:
	_invalid_flash_cells.append({
		"cell": cell,
		"remaining": INVALID_FLASH_DURATION,
	})
	set_process(true)
	queue_redraw()
func _find_owned_border_cells() -> void:
	_valid_cells.clear()
	if battlefield == null:
		return
	var extent: Vector2i = battlefield.grid_extent
	for x in range(extent.x):
		for y in range(extent.y):
			var cell := Vector2i(x, y)
			if not DeploymentRulesScript.is_owned_border(region_map, battlefield, cell, _owner_id):
				continue
			_valid_cells.append(cell)


func _find_frontline_deployment_cells(card_data: Dictionary) -> void:
	_valid_cells.clear()
	if battlefield == null:
		return
	var deployment_context: Dictionary = _current_deployment_context()
	_preview_revision = _current_deployment_revision()
	var params: Dictionary = card_data.get("params", {}) as Dictionary
	var extent: Vector2i = battlefield.grid_extent
	for x in range(extent.x):
		for y in range(extent.y):
			var query = DeploymentQueryScript.new()
			query.owner_id = _owner_id
			query.cell = Vector2i(x, y)
			query.rule_type = DeploymentRuleTypeScript.SUPPORT_NETWORK
			query.requested_support_id = str(params.get("requested_support_id", ""))
			query.spawn_profile_id = str(params.get("deployment_profile_id", ""))
			query.support_network_context = deployment_context
			if DeploymentRulesScript.evaluate(region_map, battlefield, query).allowed:
				_valid_cells.append(query.cell)


func _current_deployment_context() -> Dictionary:
	if _deployment_context_provider is Callable and (_deployment_context_provider as Callable).is_valid():
		var value = (_deployment_context_provider as Callable).call(_owner_id)
		return (value as Dictionary).duplicate(true) if value is Dictionary else {}
	return {}


func _current_deployment_revision() -> int:
	if _deployment_revision_provider is Callable and (_deployment_revision_provider as Callable).is_valid():
		return int((_deployment_revision_provider as Callable).call(_owner_id))
	return -1


func _find_enemy_region_cells() -> void:
	_valid_cells.clear()
	if region_map == null:
		return
	var enemy_region_ids: Array[int] = []
	var controllable: Array = region_map.get_controllable_region_ids()
	for raw_id in controllable:
		var rid: int = int(raw_id)
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, rid)
		var has_enemy := false
		var owner_counts: Dictionary = control.get("owner_counts", {})
		for candidate_owner in owner_counts.keys():
			var cid: int = int(candidate_owner)
			if cid != _owner_id and cid != CardfrontRulesScript.NEUTRAL_OWNER:
				if int(owner_counts.get(cid, 0)) > 0:
					has_enemy = true
					break
		if has_enemy:
			enemy_region_ids.append(rid)

	for rid in enemy_region_ids:
		var cells: Array = region_map.get_region_cells(rid)
		for c in cells:
			_valid_cells.append(c as Vector2i)


func _find_owned_region_cells() -> void:
	_valid_cells.clear()
	if region_map == null:
		return
	var controllable: Array = region_map.get_controllable_region_ids()
	for raw_id in controllable:
		var rid: int = int(raw_id)
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, rid)
		var owner_pct: int = RegionControlCalculatorScript.get_owner_percent(control, _owner_id)
		if owner_pct >= 50:
			var cells: Array = region_map.get_region_cells(rid)
			for c in cells:
				_valid_cells.append(c as Vector2i)


func _find_adjacent_neutral_cells(hint_c: Color) -> void:
	_hint_cells.clear()
	_hint_color = hint_c
	if battlefield == null:
		return
	var NEUTRAL: int = CardfrontRulesScript.NEUTRAL_OWNER
	for cell in _valid_cells:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbor := Vector2i(cell.x + dx, cell.y + dy)
				if neighbor in _valid_cells or neighbor in _hint_cells:
					continue
				if DeploymentRulesScript.get_owner_at(battlefield, neighbor) == NEUTRAL:
					_hint_cells.append(neighbor)
