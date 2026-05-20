extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontBottomHudStatusTest] Starting bottom HUD status tests")
	await process_frame

	_test_cardfront_event_label_has_fire_status()
	_test_cardfront_fps_label_visible()
	_test_ballwar_old_event_hud_still_works()
	_test_device_count_updates_status_text()
	_test_status_text_updates_after_device_change()

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


func _test_cardfront_fps_label_visible() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var fps_label = main._hud_ref("fps_label")
	_assert.that(fps_label != null, "hud: fps_label should exist")
	_assert.that(fps_label.visible, "hud: fps_label should be visible in Cardfront")

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


func _test_device_count_updates_status_text() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var DevicePlacementRequestScript = load("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
	var DeviceTypeScript = load("res://scripts/cardfront/devices/DeviceType.gd")
	var CardfrontRulesScript = load("res://scripts/cardfront/CardfrontRules.gd")

	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, Vector2i(1, 1))
	main.runtime.device_layer.place(req)

	main._update_cardfront_status_label()
	var text: String = str(main._cardfront_status_label().text)
	_assert.that(text.find("吸弹1") >= 0, "hud: status should show device count after placement (got: %s)" % text)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_status_text_updates_after_device_change() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	main._update_cardfront_status_label()
	var before: String = str(main._cardfront_status_label().text)

	var DevicePlacementRequestScript = load("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
	var DeviceTypeScript = load("res://scripts/cardfront/devices/DeviceType.gd")
	var CardfrontRulesScript = load("res://scripts/cardfront/CardfrontRules.gd")

	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ENGINEER_BOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i(2, 2))
	main.runtime.device_layer.place(req)

	main._update_cardfront_status_label()
	var after: String = str(main._cardfront_status_label().text)
	_assert.neq(after, before, "hud: status text should change after device placement")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
