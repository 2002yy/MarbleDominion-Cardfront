extends CanvasLayer
class_name CardfrontTargetedDeploymentPrototypeController

# Explicitly opt-in gameplay experiment; never constructed in formal runs.
signal deployment_zone_changed(cells: Array, revision: int)

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var director = null
var entity_runtime = null
var arena_view = null
var active: bool = false
var preview_revision: int = -1
var _legal_cells: Dictionary = {}
var _banner: PanelContainer
var _status: Label


func _init() -> void:
	name = "TargetedDeploymentPrototype"
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(new_director, new_entity_runtime, new_arena_view) -> bool:
	if new_director == null or new_entity_runtime == null or new_arena_view == null:
		return false
	if not new_arena_view.set_deployment_zone_source(self):
		return false
	director = new_director
	entity_runtime = new_entity_runtime
	arena_view = new_arena_view
	_build_banner()
	director.targeted_deployment_requested.connect(_on_targeted_deployment_requested)
	director.director_stopped.connect(_on_director_stopped)
	return true


func _build_banner() -> void:
	_banner = PanelContainer.new()
	_banner.name = "TargetedDeploymentHelp"
	var screen_width: float = get_viewport().get_visible_rect().size.x
	var banner_width: float = minf(800.0, maxf(300.0, screen_width - 16.0))
	_banner.position = Vector2((screen_width - banner_width) * 0.5, 12)
	_banner.custom_minimum_size = Vector2(banner_width, 58)
	_banner.size = _banner.custom_minimum_size
	_banner.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.10, 0.12, 0.96)
	style.border_color = Color(0.30, 0.91, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	_banner.add_theme_stylebox_override("panel", style)
	add_child(_banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_banner.add_child(row)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color(0.85, 1.0, 0.91))
	row.add_child(_status)
	var skip := Button.new()
	skip.text = "跳过（Esc）"
	skip.pressed.connect(func(): _finish(false))
	row.add_child(skip)


func _on_targeted_deployment_requested(_round_number: int) -> void:
	active = true
	_banner.visible = true
	_refresh_preview()


func _refresh_preview() -> void:
	_legal_cells.clear()
	var snapshot: Dictionary = entity_runtime.targeted_guard_preview(RulesScript.PLAYER_FACTION)
	preview_revision = int(snapshot.get("revision", -1))
	var cells: Array = snapshot.get("cells", []) as Array
	for cell in cells:
		if cell is Vector2i:
			_legal_cells[cell as Vector2i] = true
	deployment_zone_changed.emit(_legal_cells.keys(), preview_revision)
	if _legal_cells.is_empty():
		_status.text = "没有可用部署格，自动跳过此次原型增援"
		_finish(false)
	else:
		_status.text = "定向部署：点击绿色区域召唤装甲护卫（%d 个可选格）" % _legal_cells.size()


func try_deploy_cell(cell: Vector2i) -> bool:
	if not active:
		return false
	var result: Dictionary = entity_runtime.deploy_targeted_guard(RulesScript.PLAYER_FACTION, cell, preview_revision)
	if bool(result.get("allowed", false)):
		entity_runtime.sync_run_state_entity_summaries(director.run_states)
		_finish(true)
		return true
	var reason: String = str(result.get("reason", "unknown"))
	_refresh_preview()
	if active:
		_status.text = "无法部署：%s。请重新选择绿色区域" % _reason_text(reason)
	return false


func _reason_text(reason: String) -> String:
	match reason:
		"outside_map":
			return "位置超出地图"
		"not_owned_cell":
			return "该格尚未归己方控制"
		"outside_deployment_zone", "wrong_deploy_direction":
			return "不在 Core 或在线据点的合法增援方向"
		"support_offline", "support_disconnected", "no_valid_deployment_source":
			return "当前没有可使用的部署据点"
		"cell_capacity_reached":
			return "该格已没有单位容量"
		"entity_capacity_reached":
			return "己方单位数量已达到上限"
		"stale_deployment_revision":
			return "据点状态已变化，合法区域已刷新"
		"entity_spawn_failed":
			return "单位生成失败，请更换位置"
	return reason


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_finish(false)
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var cell: Vector2i = arena_view.screen_to_deployment_cell(mouse.position)
			if cell.x >= 0:
				get_viewport().set_input_as_handled()
				try_deploy_cell(cell)


func _finish(placed: bool) -> void:
	if not active:
		return
	active = false
	_banner.visible = false
	_legal_cells.clear()
	deployment_zone_changed.emit([], -1)
	preview_revision = -1
	director.complete_targeted_deployment(placed)


func _on_director_stopped() -> void:
	if active:
		active = false
		_banner.visible = false
		_legal_cells.clear()
		deployment_zone_changed.emit([], -1)
