extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontHandCollapseLayoutTest] Starting hand collapse layout tests")
	await process_frame

	_test_panel_bg_height_under_100()
	_test_cards_have_collapsed_offset()
	await _test_hover_expands_card()
	await _test_selected_stays_expanded_after_mouse_exit()
	_test_ballwar_no_hand_panel()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontHandCollapseLayoutTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_panel_bg_height_under_100() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.hand_panel != null, "hand_panel exists")
	if main.runtime.hand_panel != null:
		var bg = main.runtime.hand_panel.get_node_or_null("PanelBg")
		_assert.that(bg != null, "PanelBg exists")
		if bg != null:
			_assert.that((bg as Control).size.y < 100.0, "panel bg height should be under 100px (collapsed)")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_cards_have_collapsed_offset() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.hand_panel != null, "hand_panel exists")
	if main.runtime.hand_panel != null:
		var views = main.runtime.hand_panel._card_views
		_assert.eq(views.size(), 4, "should have 4 card views")
		for i in range(views.size()):
			_assert.gte(views[i].position.y, 58.0, "card view %d should have collapsed y offset >= 58" % i)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_hover_expands_card() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()

	_assert.that(main.runtime.hand_panel != null, "hand_panel exists")
	if main.runtime.hand_panel != null and main.runtime.hand_panel._card_views.size() > 0:
		var view = main.runtime.hand_panel._card_views[0]
		var initial_y: float = view.position.y
		view.emit_signal("mouse_entered")
		await create_timer(0.25).timeout
		_assert.that(view.position.y < initial_y, "hover should move card upward (position.y decreased)")
		_assert.that(view.position.y < 10.0, "hover should expand card near y=0")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_selected_stays_expanded_after_mouse_exit() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()

	_assert.that(main.runtime.hand_panel != null, "hand_panel exists")
	if main.runtime.hand_panel != null and main.runtime.hand_panel._card_views.size() > 0:
		var view = main.runtime.hand_panel._card_views[0]
		main.runtime.hand_panel.set_card_selected(view.card_id)
		await create_timer(0.25).timeout
		_assert.that(view.position.y < 10.0, "selected card should be expanded near y=0")
		view.emit_signal("mouse_exited")
		await create_timer(0.25).timeout
		_assert.that(view.position.y < 10.0, "selected card should STAY expanded after mouse_exit")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_no_hand_panel() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.hand_panel == null, "hand_panel should not exist in BallWar mode")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
