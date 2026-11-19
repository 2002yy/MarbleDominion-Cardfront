extends RefCounted
class_name CardfrontMode

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const CardfrontArenaLayoutScript = preload("res://scripts/cardfront/arena/CardfrontArenaLayout.gd")
const CardfrontRuntimeBuilderScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeBuilder.gd")
const CardfrontRegionInfoPanelScript = preload("res://scripts/cardfront/ui/CardfrontRegionInfoPanel.gd")
const CardfrontAimControlScene = preload("res://scenes/ui/cardfront/CardfrontAimControl.tscn")
const CardfrontThreeChoicePanelScene = preload("res://scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn")
const CardfrontBattlefieldScaleControlScene = preload("res://scenes/ui/cardfront/CardfrontBattlefieldScaleControl.tscn")

const FIRE_STATUS_TEXT: String = "拖动左侧方向滑杆｜炮塔按设定方向自动射击"


static func is_selected(mode_name: String) -> bool:
	return Rules.is_cardfront_mode(mode_name)


static func is_active() -> bool:
	return is_selected(GameConfig.get_game_mode_name())


static func uses_control_chambers() -> bool:
	return false


static func get_active_factions() -> Array:
	return Rules.get_duel_factions()


static func get_match_duration_seconds() -> float:
	return Rules.MATCH_DURATION_SECONDS


static func configure_runtime_layout(base_layout: Dictionary, grid_extent_value, viewport_size: Vector2) -> Dictionary:
	return CardfrontArenaLayoutScript.apply_to(base_layout, grid_extent_value, viewport_size)


static func configure_battlefield(battlefield) -> Dictionary:
	var result: Dictionary = BattlefieldInitializer.configure_duel(battlefield)
	if not bool(result.get("configured", false)):
		return result
	result.merge({
		"configured": true,
		"mode_name": GameConfig.GAME_MODE_CARDFRONT,
		"active_factions": get_active_factions(),
		"match_duration_seconds": get_match_duration_seconds(),
	}, true)
	return result


static func create_regions(game_layer: Node, battlefield) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_regions(game_layer, battlefield)


static func create_region_control_blocks(game_layer: Node, region_map, battlefield) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_region_control_blocks(game_layer, region_map, battlefield)


static func create_fortify(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_fortify(game_layer, battlefield, region_map)


static func create_fire_director(game_layer: Node, region_map, battlefield, turrets: Dictionary) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_fire_director(game_layer, region_map, battlefield, turrets)


static func create_aim_control(ui_layer: Node, direction_controller, layout: Dictionary) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}
	if direction_controller == null or not is_instance_valid(direction_controller):
		return {"configured": false, "reason": "missing_direction_controller"}
	var control = CardfrontAimControlScene.instantiate()
	ui_layer.add_child(control)
	if not control.setup(direction_controller, layout, GameConfig.GAME_MODE_CARDFRONT):
		control.queue_free()
		return {"configured": false, "reason": "aim_control_setup_failed"}
	return {"configured": true, "aim_control": control}


static func create_three_choice_panel(ui_layer: Node, round_director, view_size: Vector2) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}
	if round_director == null or not is_instance_valid(round_director):
		return {"configured": false, "reason": "missing_round_director"}
	var panel = CardfrontThreeChoicePanelScene.instantiate()
	ui_layer.add_child(panel)
	if not panel.setup(round_director, view_size):
		panel.queue_free()
		return {"configured": false, "reason": "three_choice_panel_setup_failed"}
	return {
		"configured": true,
		"three_choice_panel": panel,
	}


static func create_battlefield_scale_control(ui_layer: Node, orthographic_arena_view, view_size: Vector2) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}
	if orthographic_arena_view == null or not is_instance_valid(orthographic_arena_view):
		return {"configured": false, "reason": "missing_orthographic_arena_view"}
	var control = CardfrontBattlefieldScaleControlScene.instantiate()
	ui_layer.add_child(control)
	if not control.setup(orthographic_arena_view, view_size):
		control.queue_free()
		return {"configured": false, "reason": "battlefield_scale_control_setup_failed"}
	return {
		"configured": true,
		"battlefield_scale_control": control,
	}


static func create_region_info_panel(ui_layer: Node, region_map, battlefield, territory_defense_system = null, stronghold_system = null, layout: Dictionary = {}, arena_view = null) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}

	var panel = CardfrontRegionInfoPanelScript.new()
	panel.setup(region_map, battlefield, GameConfig.GAME_MODE_CARDFRONT, territory_defense_system, stronghold_system, layout, arena_view)
	ui_layer.add_child(panel)

	return {
		"configured": true,
		"region_info_panel": panel,
	}


static func configure_runtime_hud(hud_nodes: Dictionary) -> void:
	# CardfrontHUD 场景已不包含 BallWar 专属节点，
	# 但 fallback 路径（GameHUD.tscn）仍需要隐藏。
	if hud_nodes.get("game_title_label", null) != null:
		_hide_node(hud_nodes.get("game_title_label", null))
		_hide_node(hud_nodes.get("event_label", null))
		_hide_node(hud_nodes.get("fps_label", null))
		var ui_canvas = hud_nodes.get("ui_canvas", null)
		if ui_canvas != null and is_instance_valid(ui_canvas):
			_hide_node(ui_canvas.get_node_or_null("FPSBg"))

	# Always set event label for Cardfront mode (both CardfrontHUD and GameHUD fallback)
	var event_label = hud_nodes.get("event_label", null)
	if event_label != null and is_instance_valid(event_label):
		event_label.text = FIRE_STATUS_TEXT

	RuntimeHudController.set_performance_visible(false)
	_compact_side_buttons(hud_nodes)


static func restore_ballwar_hud(hud_nodes: Dictionary) -> void:
	_show_node(hud_nodes.get("game_title_label", null))
	_show_node(hud_nodes.get("event_label", null))
	_show_node(hud_nodes.get("fps_label", null))
	var ui_canvas = hud_nodes.get("ui_canvas", null)
	if ui_canvas != null and is_instance_valid(ui_canvas):
		_show_node(ui_canvas.get_node_or_null("FPSBg"))
	RuntimeHudController.set_performance_visible(true)


static func _hide_node(node) -> void:
	if node != null and is_instance_valid(node):
		node.visible = false


static func _show_node(node) -> void:
	if node != null and is_instance_valid(node):
		node.visible = true


static func _compact_side_buttons(hud_nodes: Dictionary) -> void:
	var settings_button = hud_nodes.get("settings_button", null)
	var pause_button = hud_nodes.get("pause_button", null)
	var exit_button = hud_nodes.get("exit_button", null)
	if settings_button == null or pause_button == null or exit_button == null:
		return
	if not is_instance_valid(settings_button) or not is_instance_valid(pause_button) or not is_instance_valid(exit_button):
		return

	var button_size := Vector2(48.0, 28.0)
	var view_width: float = 1120.0
	var viewport = settings_button.get_viewport()
	if viewport != null:
		var view_size: Vector2 = viewport.get_visible_rect().size
		view_width = view_size.x
	var start_y: float = 74.0
	var settings_x: float = view_width - button_size.x * 2.0 - 16.0
	var pause_x: float = view_width - button_size.x - 12.0

	settings_button.size = button_size
	pause_button.size = button_size
	settings_button.position = Vector2(settings_x, start_y)
	pause_button.position = Vector2(pause_x, start_y)
	settings_button.add_theme_font_size_override("font_size", 12)
	pause_button.add_theme_font_size_override("font_size", 12)
	exit_button.visible = false

	var settings_panel = hud_nodes.get("settings_panel", null)
	if settings_panel != null and is_instance_valid(settings_panel):
		settings_panel.position = Vector2(view_width - 298.0, start_y + button_size.y + 8.0)
