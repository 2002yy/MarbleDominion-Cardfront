extends RefCounted
class_name CardfrontMode

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const CardfrontArenaLayoutScript = preload("res://scripts/cardfront/arena/CardfrontArenaLayout.gd")
const CardfrontRuntimeBuilderScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeBuilder.gd")
const CardfrontTopResourceBarScene = preload("res://scenes/ui/cardfront/CardfrontTopResourceBar.tscn")
const CardfrontHandPanelScene = preload("res://scenes/ui/cardfront/CardfrontHandPanel.tscn")
const CardfrontCardSelectionControllerScript = preload("res://scripts/cardfront/ui/CardfrontCardSelectionController.gd")
const CardfrontRegionInfoPanelScript = preload("res://scripts/cardfront/ui/CardfrontRegionInfoPanel.gd")
const CardfrontFeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")
const CardfrontCardDetailPopupScene = preload("res://scenes/ui/cardfront/CardfrontCardDetailPopup.tscn")
const CardfrontToastLayerScene = preload("res://scenes/ui/cardfront/CardfrontToastLayer.tscn")
const CardfrontEffectVisualBridgeScript = preload("res://scripts/cardfront/ui/CardfrontEffectVisualBridge.gd")
const CardfrontCardAudioFeedbackScript = preload("res://scripts/cardfront/ui/CardfrontCardAudioFeedback.gd")
const CardfrontTutorialOverlayScene = preload("res://scenes/ui/cardfront/CardfrontTutorialOverlay.tscn")
const CardfrontAimControlScene = preload("res://scenes/ui/cardfront/CardfrontAimControl.tscn")
const CardfrontThreeChoicePanelScene = preload("res://scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn")
const LEGACY_SIDE_BUTTON_TOP_AFTER_REGION: float = 324.0
const LEGACY_SIDE_BUTTON_GAP: float = 8.0

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


static func configure_runtime_layout(base_layout: Dictionary, grid_size: int, viewport_size: Vector2) -> Dictionary:
	return CardfrontArenaLayoutScript.apply_to(base_layout, grid_size, viewport_size)


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


static func create_economy(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_economy(game_layer, battlefield, region_map)


static func create_morale(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_morale(game_layer, battlefield, region_map)


static func create_fortify(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_fortify(game_layer, battlefield, region_map)


static func create_target_bias(game_layer: Node, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_target_bias(game_layer, region_map)


static func create_card_system(resource_states: Dictionary, region_map, battlefield, fortify_layer, morale_system, region_overlay, target_bias_system = null) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_card_system(resource_states, region_map, battlefield, fortify_layer, morale_system, region_overlay, target_bias_system)


static func create_fire_director(game_layer: Node, region_map, battlefield, turrets: Dictionary, target_bias_system = null) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_fire_director(game_layer, region_map, battlefield, turrets, target_bias_system)


static func create_shot_guide(game_layer: Node, battlefield, target_bias_system, turrets: Dictionary, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_shot_guide(game_layer, battlefield, target_bias_system, turrets, region_map)


static func create_device_layer(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_device_layer(game_layer, battlefield, region_map)


static func create_absorber_core_effect_system(game_layer: Node, device_layer, bullet_pool, resource_states: Dictionary, battlefield, vfx_layer = null) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_absorber_core_effect_system(game_layer, device_layer, bullet_pool, resource_states, battlefield, vfx_layer)


static func create_engineer_bot_effect_system(game_layer: Node, device_layer, fortify_layer, battlefield, region_map, vfx_layer = null) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_engineer_bot_effect_system(game_layer, device_layer, fortify_layer, battlefield, region_map, vfx_layer)


static func create_durable_pioneer_beacon_effect_system(game_layer: Node, device_layer, battlefield, region_map, vfx_layer = null) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_durable_pioneer_beacon_effect_system(game_layer, device_layer, battlefield, region_map, vfx_layer)


static func create_vfx_layer(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_vfx_layer(game_layer, battlefield, region_map)


static func create_debug_action_panel(game_layer: Node, device_layer, card_system, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_debug_action_panel(game_layer, device_layer, card_system, battlefield, region_map)


static func create_feedback_bus(ui_layer: Node) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}

	var bus = CardfrontFeedbackBusScript.new()
	ui_layer.add_child(bus)

	return {
		"configured": true,
		"feedback_bus": bus,
	}


static func create_feedback_layers(ui_layer: Node, feedback_bus, resource_states: Dictionary, view_size: Vector2) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}
	if feedback_bus == null:
		return {"configured": false, "reason": "missing_feedback_bus"}

	var player_state = resource_states.get(Rules.PLAYER_FACTION, null)
	var detail_popup = CardfrontCardDetailPopupScene.instantiate()
	ui_layer.add_child(detail_popup)
	detail_popup.setup(feedback_bus, player_state, GameConfig.GAME_MODE_CARDFRONT)

	var toast_layer = CardfrontToastLayerScene.instantiate()
	ui_layer.add_child(toast_layer)
	toast_layer.setup(feedback_bus, GameConfig.GAME_MODE_CARDFRONT, view_size)

	var audio_feedback = CardfrontCardAudioFeedbackScript.new()
	ui_layer.add_child(audio_feedback)
	audio_feedback.setup(feedback_bus)

	return {
		"configured": true,
		"card_detail_popup": detail_popup,
		"toast_layer": toast_layer,
		"card_audio_feedback": audio_feedback,
	}


static func create_tutorial_overlay(ui_layer: Node, view_size: Vector2 = Vector2(1120, 720)) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}

	var overlay = CardfrontTutorialOverlayScene.instantiate()
	ui_layer.add_child(overlay)
	overlay.setup(view_size)

	return {
		"configured": true,
		"tutorial_overlay": overlay,
	}


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


static func create_effect_visual_bridge(game_layer: Node, feedback_bus, vfx_layer) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if feedback_bus == null:
		return {"configured": false, "reason": "missing_feedback_bus"}

	var bridge = CardfrontEffectVisualBridgeScript.new()
	bridge.setup(feedback_bus, vfx_layer)
	game_layer.add_child(bridge)

	return {
		"configured": true,
		"effect_visual_bridge": bridge,
	}


static func create_top_resource_bar(ui_layer: Node, economy_system, resource_states: Dictionary) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}

	var bar = CardfrontTopResourceBarScene.instantiate()
	ui_layer.add_child(bar)
	bar.setup(economy_system, resource_states, GameConfig.GAME_MODE_CARDFRONT)

	return {
		"configured": true,
		"top_resource_bar": bar,
	}


static func create_hand_panel(ui_layer: Node, card_system, resource_states: Dictionary, economy_system, view_size: Vector2, feedback_bus = null) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}
	if card_system == null:
		return {"configured": false, "reason": "missing_card_system"}

	var panel = CardfrontHandPanelScene.instantiate()
	ui_layer.add_child(panel)
	panel.setup(card_system, resource_states, economy_system, GameConfig.GAME_MODE_CARDFRONT, view_size, feedback_bus)

	return {
		"configured": true,
		"hand_panel": panel,
	}


static func create_target_preview_layer(game_layer: Node, battlefield, region_map) -> Dictionary:
	return CardfrontRuntimeBuilderScript.create_target_preview_layer(game_layer, battlefield, region_map)


static func create_region_info_panel(ui_layer: Node, region_map, battlefield, territory_defense_system = null, stronghold_system = null) -> Dictionary:
	if ui_layer == null or not is_instance_valid(ui_layer):
		return {"configured": false, "reason": "missing_ui_layer"}

	var panel = CardfrontRegionInfoPanelScript.new()
	panel.setup(region_map, battlefield, GameConfig.GAME_MODE_CARDFRONT, territory_defense_system, stronghold_system)
	ui_layer.add_child(panel)

	return {
		"configured": true,
		"region_info_panel": panel,
	}


static func create_card_selection_controller(card_system, resource_states: Dictionary, hand_panel, top_resource_bar, target_preview = null, feedback_bus = null) -> Dictionary:
	var controller = CardfrontCardSelectionControllerScript.new()
	controller.setup(card_system, resource_states, hand_panel, top_resource_bar, target_preview, feedback_bus)
	if hand_panel != null:
		hand_panel.set_selection_controller(controller)
	return {
		"configured": true,
		"selection_controller": controller,
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
	_lower_legacy_side_buttons(hud_nodes)


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


static func _lower_legacy_side_buttons(hud_nodes: Dictionary) -> void:
	var settings_button = hud_nodes.get("settings_button", null)
	var pause_button = hud_nodes.get("pause_button", null)
	var exit_button = hud_nodes.get("exit_button", null)
	if settings_button == null or pause_button == null or exit_button == null:
		return
	if not is_instance_valid(settings_button) or not is_instance_valid(pause_button) or not is_instance_valid(exit_button):
		return

	var button_size: Vector2 = settings_button.size
	var view_height: float = 720.0
	var viewport = settings_button.get_viewport()
	if viewport != null:
		view_height = viewport.get_visible_rect().size.y
	var stack_height: float = button_size.y * 3.0 + LEGACY_SIDE_BUTTON_GAP * 2.0
	var start_y: float = clampf(LEGACY_SIDE_BUTTON_TOP_AFTER_REGION, 84.0, maxf(84.0, view_height - stack_height - 12.0))
	var x: float = settings_button.position.x

	settings_button.position = Vector2(x, start_y)
	pause_button.position = Vector2(x, start_y + button_size.y + LEGACY_SIDE_BUTTON_GAP)
	exit_button.position = Vector2(x, pause_button.position.y + button_size.y + LEGACY_SIDE_BUTTON_GAP)

	var settings_panel = hud_nodes.get("settings_panel", null)
	if settings_panel != null and is_instance_valid(settings_panel):
		settings_panel.position = Vector2(settings_panel.position.x, exit_button.position.y + button_size.y + 10.0)
