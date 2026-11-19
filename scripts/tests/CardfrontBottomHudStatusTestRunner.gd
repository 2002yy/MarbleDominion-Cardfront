extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontBottomHudStatusTest] Starting bottom HUD status tests")
	await process_frame

	_test_cardfront_event_label_has_fire_status()
	_test_cardfront_fps_label_hidden()
	_test_ballwar_old_event_hud_still_works()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontBottomHudStatusTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_cardfront_event_label_has_fire_status() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var status_label = main._cardfront_status_label()
	_assert.that(status_label != null, "hud: cardfront status label should exist")
	var text: String = str(status_label.text)
	_assert.that(text.find("射击") >= 0, "hud: status text should mention fire (got: %s)" % text)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
func _test_cardfront_fps_label_hidden() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var fps_label = main._hud_ref("fps_label")
	_assert.that(fps_label != null, "hud: fps_label should exist")
	_assert.that(not fps_label.visible, "hud: technical FPS text should stay hidden in the formal Cardfront HUD")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_old_event_hud_still_works() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var event_label = main._hud_ref("event_label")
	_assert.that(event_label != null, "hud: BallWar event_label should exist")
	_assert.that(event_label.visible, "hud: BallWar event_label should be visible")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
