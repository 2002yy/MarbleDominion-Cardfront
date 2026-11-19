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
	await _test_real_card_and_battlefield_click(main, Vector2(1120.0, 720.0))
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()
	var narrow_main = _make_main()
	await _flush()
	await _test_real_card_and_battlefield_click(narrow_main, Vector2(760.0, 540.0))
	narrow_main._cleanup_game_layer()
	TestFixtures.cleanup_node(narrow_main)
	await _flush()
	var prototype_main = _make_main()
	await _flush()
	await _test_opt_in_targeted_deployment_click(prototype_main)
	prototype_main._cleanup_game_layer()
	TestFixtures.cleanup_node(prototype_main)
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
	return main


func _test_decorative_layers_ignore_mouse(main) -> void:
	_assert.eq(main.get_node("MainBackground").mouse_filter, Control.MOUSE_FILTER_IGNORE, "click-through: full-screen background must not consume gameplay clicks")
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


func _test_real_card_and_battlefield_click(main, viewport_size: Vector2) -> void:
	var panel = main.runtime.three_choice_panel
	_assert.that(panel.setup(main.runtime.round_director, viewport_size), "%s: UI setup succeeds" % viewport_size)
	main.runtime.round_director.force_open_draft_for_test()
	await _flush()
	await _click_at(panel._peek_button.get_global_rect().get_center())
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "%s: real battlefield button opens preview" % viewport_size)
	_assert.that(not panel.choice_shell.visible, "%s: preview hides the offer without rerolling" % viewport_size)
	await _click_at(panel._peek_button.get_global_rect().get_center())
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_DRAFT_VISIBLE, "%s: real return button restores the draft" % viewport_size)
	await _click_at(panel.upgrade_history_button.get_global_rect().get_center())
	_assert.that(panel.is_upgrade_history_open_for_test(), "%s: real history button opens the drawer" % viewport_size)
	await _click_at(panel.upgrade_history_close_button.get_global_rect().get_center())
	_assert.that(not panel.is_upgrade_history_open_for_test(), "%s: real close button dismisses the drawer" % viewport_size)
	var cards: Array = panel.get_choice_cards()
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


func _test_opt_in_targeted_deployment_click(main) -> void:
	_assert.that(main._targeted_deployment_prototype == null, "targeted opt-in: formal runtime does not create a targeting controller")
	main._create_targeted_deployment_prototype()
	var controller = main._targeted_deployment_prototype
	_assert.that(controller != null, "targeted opt-in: dev-only controller attaches to the live 3D arena")
	if controller == null:
		return
	var director = main.runtime.round_director
	var view = main.runtime.orthographic_arena_view
	var entity_runtime = main.runtime.battlefield.capture_interceptor.entity_runtime
	director.force_open_draft_for_test()
	await _flush()
	var guard_card = null
	for card in main.runtime.three_choice_panel.get_choice_cards():
		if str(card.upgrade_id) == "armored_guard":
			guard_card = card
	_assert.that(guard_card != null, "targeted opt-in: one three-choice card offers manual armored-guard placement")
	if guard_card == null:
		director.stop()
		return
	await _click_at(guard_card.get_global_rect().get_center())
	_assert.eq(director.get_phase(), "resolve_choices", "targeted opt-in: real card click advances to choice reveal")
	director._process(director.REVEAL_DURATION)
	_assert.that(controller.active, "targeted opt-in: reveal opens the paused targeting state")
	_assert.that(paused, "targeted opt-in: gameplay remains paused during manual targeting")
	_assert.that(not main.runtime.three_choice_panel.draft_root.visible, "targeted opt-in: draft overlay no longer obscures legal tiles")
	_assert.that(view.deployment_zone_layer.visible, "targeted opt-in: legal cells appear on the current 3D arena")
	var legal_cells: Array = view.deployment_zone_layer.get_visible_cells_for_test()
	_assert.that(not legal_cells.is_empty(), "targeted opt-in: Core always provides a legal candidate on the normal opening map")
	if legal_cells.is_empty():
		controller._finish(false)
		return
	_assert.that(not controller.try_deploy_cell(Vector2i(-1, -1)), "targeted opt-in: outside click is rejected without consuming the pending guard")
	_assert.that(controller.active and controller._status.text.contains("位置超出地图"), "targeted opt-in: invalid location explains its cause in Chinese")
	var target: Vector2i = legal_cells[0] as Vector2i
	var rejected: Dictionary = entity_runtime.deploy_targeted_guard(CardfrontRulesScript.PLAYER_FACTION, target, controller.preview_revision + 1)
	_assert.eq(str(rejected.get("reason", "")), "stale_deployment_revision", "targeted opt-in: mismatched authority revision cannot commit")
	var viewport_point: Vector2 = view.get_camera_for_test().unproject_position(view.cell_to_world(target, 0.205))
	var screen_position: Vector2 = view.viewport_container.global_position + viewport_point * Vector2(
		view.viewport_container.size.x / float(view.world_viewport.size.x),
		view.viewport_container.size.y / float(view.world_viewport.size.y)
	)
	_assert.eq(view.screen_to_deployment_cell(screen_position), target, "targeted opt-in: projected 3D legal marker maps back to the clicked cell")
	await _click_at(screen_position)
	_assert.that(not controller.active, "targeted opt-in: clicking a legal tile closes the targeting state")
	_assert.that(not view.deployment_zone_layer.visible, "targeted opt-in: deployment highlights clear after commit")
	_assert.that(not paused, "targeted opt-in: volley resumes after successful placement")
	_assert.eq(director.get_phase(), "battle_countdown", "targeted opt-in: regular three-choice round cycle resumes")
	var guards: Array = entity_runtime.registry.get_entities_at(target)
	_assert.that(guards.any(func(entity) -> bool: return str(entity.creature_id) == "armored_guard"), "targeted opt-in: a real armored guard is spawned at the exact selected tile")
	_assert.eq(
		int(director.get_run_state(CardfrontRulesScript.PLAYER_FACTION).owned_creature_count),
		entity_runtime.registry.count_owner_entities(CardfrontRulesScript.PLAYER_FACTION, "creature"),
		"targeted opt-in: newly placed guard immediately updates run-state entity summary"
	)
	director.force_open_draft_for_test()
	await _flush()
	for card in main.runtime.three_choice_panel.get_choice_cards():
		if str(card.upgrade_id) == "armored_guard":
			await _click_at(card.get_global_rect().get_center())
			break
	director._process(director.REVEAL_DURATION)
	_assert.that(controller.active, "targeted opt-in: next round can enter manual targeting again")
	var before_skip: int = entity_runtime.registry.count_owner_entities(CardfrontRulesScript.PLAYER_FACTION, "creature")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	get_root().push_input(escape, true)
	await _flush()
	_assert.that(not controller.active and not paused, "targeted opt-in: Esc cancels targeting and resumes regular combat")
	_assert.eq(entity_runtime.registry.count_owner_entities(CardfrontRulesScript.PLAYER_FACTION, "creature"), before_skip, "targeted opt-in: cancelling does not secretly spawn another unit")
	director.force_open_draft_for_test()
	await _flush()
	_assert.that(director.phase_controller.select_upgrade(CardfrontRulesScript.PLAYER_FACTION, "armored_guard"), "targeted opt-in: model an automatic guard choice without a player click")
	director._begin_resolution()
	director.complete_reveal_for_test()
	_assert.that(not controller.active and not paused, "targeted opt-in: an automatic fallback never blocks volley waiting for a manual click")


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
