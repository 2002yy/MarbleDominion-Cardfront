extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontUiClickThroughTest] Starting real UI click-through tests")
	await process_frame
	var main = _make_main()
	await _flush()
	_test_decorative_layers_ignore_mouse(main)
	await _test_real_card_and_battlefield_click(main)
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()
	_assert.report("[CardfrontUiClickThroughTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _make_main():
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	if main.runtime.tutorial_overlay != null:
		main.runtime.tutorial_overlay.visible = false
	return main


func _test_decorative_layers_ignore_mouse(main) -> void:
	_assert.eq(main.get_node("MainBackground").mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: full-screen background must not consume gameplay clicks")
	var toast_box: Control = main.runtime.toast_layer.get_node("ToastBox")
	_assert.eq(toast_box.mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: toast container should not block battlefield clicks")
	main.runtime.toast_layer.show_toast("测试提示")
	var toast_label: Control = toast_box.get_child(0)
	_assert.eq(toast_label.mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: toast items should not block battlefield clicks")

	var resource_margin: Control = main.runtime.top_resource_bar.get_node("Margin")
	_assert.eq(resource_margin.mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: resource bar shell should ignore mouse input")
	_assert_controls_ignore(resource_margin, "resource bar")

	var hud_canvas = main.runtime.hud.get("ui_canvas", null)
	_assert.that(hud_canvas != null, "click-through: Cardfront HUD should exist")
	if hud_canvas != null:
		_assert_controls_ignore(hud_canvas.get_node("TopPanel"), "top HUD")
		_assert.eq(hud_canvas.get_node("FPSLabel").mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: FPS label should ignore mouse input")
		_assert.eq(hud_canvas.get_node("EventLabel").mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: status label should ignore mouse input")
		_assert.eq(hud_canvas.get_node("SettingsButton").mouse_filter, Control.MOUSE_FILTER_STOP, "click-through: command buttons must remain clickable")


func _assert_controls_ignore(node: Node, label: String) -> void:
	if node is Control:
		_assert.eq((node as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: %s node %s should ignore mouse input" % [label, node.name])
	for child in node.get_children():
		_assert_controls_ignore(child, label)


func _test_real_card_and_battlefield_click(main) -> void:
	var state = main.runtime.resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	state.add_energy(999)
	state.add_parts(999)
	main.runtime.hand_panel.refresh()
	var view: Control = main.runtime.hand_panel._card_views[0]
	await _click_at(view.get_global_rect().get_center())
	var selected_id: int = main.runtime.selection_controller.get_selected_card_id()
	_assert.that(selected_id >= 0, "click-through: a real card click should establish selection")
	if selected_id < 0:
		return
	var valid_cells: Array = main.runtime.target_preview_layer._valid_cells
	_assert.that(not valid_cells.is_empty(), "click-through: selection should expose valid battlefield targets")
	if valid_cells.is_empty():
		return
	var target: Vector2i = valid_cells[0]
	var local_center := (Vector2(target) + Vector2(0.5, 0.5)) * float(main.runtime.battlefield.cell_size)
	var target_position: Vector2 = main.runtime.battlefield.to_global(local_center)
	await _click_at(target_position)
	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "click-through: a real valid battlefield click should play the card and clear selection")


func _click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_root().push_input(motion, true)
	await _flush()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	get_root().push_input(press, true)
	await _flush()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = position
	release.global_position = position
	get_root().push_input(release, true)
	await _flush()


func _flush() -> void:
	await process_frame
	await process_frame
