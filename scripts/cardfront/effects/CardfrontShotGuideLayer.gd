extends Node2D
class_name CardfrontShotGuideLayer

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var battlefield = null
var target_bias_system = null
var turrets: Dictionary = {}
var region_map = null

var _flash_elapsed: float = 0.0
const FLASH_PERIOD: float = 0.6


func _init() -> void:
	name = "CardfrontShotGuideLayer"
	z_index = 4
	set_process(false)


func setup(new_battlefield, new_target_bias_system, new_turrets: Dictionary, new_region_map) -> void:
	battlefield = new_battlefield
	target_bias_system = new_target_bias_system
	turrets = new_turrets.duplicate(false)
	region_map = new_region_map
	_flash_elapsed = 0.0
	if battlefield != null and is_instance_valid(battlefield):
		position = battlefield.position
	visible = _has_bias(CardfrontRulesScript.PLAYER_FACTION)
	set_process(visible)
	queue_redraw()


func mark_dirty() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if target_bias_system == null or not is_instance_valid(target_bias_system):
		set_process(false)
		visible = false
		return
	_flash_elapsed += delta
	var has: bool = _has_bias(CardfrontRulesScript.PLAYER_FACTION)
	if visible != has:
		visible = has
		set_process(has)
	if has:
		queue_redraw()


func _has_bias(owner_id: int) -> bool:
	if target_bias_system == null or not is_instance_valid(target_bias_system):
		return false
	return target_bias_system.get_biased_region(int(owner_id)) >= 0


func _draw() -> void:
	if not visible:
		return
	if battlefield == null:
		return

	var player_bias = _get_bias_info(CardfrontRulesScript.PLAYER_FACTION)
	if player_bias.is_empty():
		return

	_draw_region_flash(player_bias)
	_draw_guide_line(player_bias)


func _get_bias_info(owner_id: int) -> Dictionary:
	if target_bias_system == null or not is_instance_valid(target_bias_system):
		return {}
	var region_id: int = target_bias_system.get_biased_region(int(owner_id))
	if region_id < 0:
		return {}
	var remaining: float = 0.0
	if target_bias_system.has_method("get_bias_remaining"):
		remaining = float(target_bias_system.get_bias_remaining(int(owner_id)))
	var target_cell: Vector2i = Vector2i(-1, -1)
	if target_bias_system.has_method("get_biased_target_cell"):
		target_cell = target_bias_system.get_biased_target_cell(int(owner_id))
	return {
		"region_id": region_id,
		"remaining": remaining,
		"target_cell": target_cell,
		"owner_id": int(owner_id),
	}


func _draw_region_flash(bias: Dictionary) -> void:
	if region_map == null:
		return
	var region_id: int = int(bias.get("region_id", -1))
	if region_id < 0 or not region_map.has_method("get_region_cells"):
		return
	var cells: Array = region_map.get_region_cells(region_id)
	if cells.is_empty():
		return

	var flash: float = absf(sin(_flash_elapsed * PI / FLASH_PERIOD))
	var base_alpha: float = 0.12 + flash * 0.18
	var cell_size: int = int(battlefield.cell_size)

	for raw_cell in cells:
		var cell: Vector2i = raw_cell
		var rect := Rect2(Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))
		draw_rect(rect, Color(0.38, 0.78, 1.0, base_alpha), true)
		draw_circle(rect.get_center(), maxf(2.0, float(cell_size) * 0.1), Color(0.58, 0.88, 1.0, base_alpha + 0.1))


func _draw_guide_line(bias: Dictionary) -> void:
	var owner_id: int = int(bias.get("owner_id", 0))
	var turret = turrets.get(owner_id, null)
	if turret == null or not is_instance_valid(turret):
		return

	var target_cell: Vector2i = bias.get("target_cell", Vector2i(-1, -1))
	if target_cell.x < 0 or target_cell.y < 0:
		return

	var flash: float = absf(sin(_flash_elapsed * PI / FLASH_PERIOD))
	var alpha: float = 0.25 + flash * 0.25
	var cell_size: int = int(battlefield.cell_size)

	var target_center: Vector2 = Vector2(float(target_cell.x) + 0.5, float(target_cell.y) + 0.5) * float(cell_size)
	var turret_local: Vector2 = to_local(turret.global_position)

	draw_line(turret_local, target_center, Color(0.42, 0.80, 1.0, alpha), maxf(1.0, float(cell_size) * 0.08))
