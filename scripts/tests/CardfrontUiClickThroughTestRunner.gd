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
	main.cardfront_legacy_compatibility_enabled = true
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
	_assert.that(not main.runtime.hand_panel.visible, "click-through: legacy hand should be retired from the live loop")
	main.runtime.round_director.force_open_draft_for_test()
	await _flush()
	var cards: Array = main.runtime.three_choice_panel.get_choice_cards()
	_assert.eq(cards.size(), 3, "click-through: draft should create three real choice cards")
	if cards.is_empty():
		paused = false
		return
	var view: Control = cards[0]
	await _click_at(view.get_global_rect().get_center())
	_assert.eq(
		main.runtime.round_director.phase_controller.get_selected_upgrade_id(CardfrontRulesScript.PLAYER_FACTION),
		str(view.upgrade_id),
		"click-through: a real choice click should establish the round upgrade"
	)
	main.runtime.round_director.complete_reveal_for_test()


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
