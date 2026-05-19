extends SceneTree

const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontControlChamberDecouplingTest] Starting Cardfront control chamber decoupling tests")
	await process_frame

	await _test_cardfront_skips_chambers_buttons_and_shows_fire_status()
	await _test_old_ballwar_keeps_control_chambers_and_buttons()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontControlChamberDecouplingTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_cardfront_skips_chambers_buttons_and_shows_fire_status() -> void:
	GameConfig.reset_runtime_defaults()
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, 40)

	_assert.eq(main.runtime.chambers.size(), 0, "decoupling: Cardfront should not create control chambers")
	_assert.eq(main.runtime.ui_runtime_ref("add_ball_buttons", {}).size(), 0, "decoupling: Cardfront should not create add-ball buttons")
	_assert.that(main.runtime.fire_director != null and is_instance_valid(main.runtime.fire_director), "decoupling: Cardfront should use FireDirector")
	_assert.eq(main.runtime.hud_ref("event_label").text, CardfrontModeScript.FIRE_STATUS_TEXT, "decoupling: Cardfront HUD should explain automatic/card-directed fire")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _test_old_ballwar_keeps_control_chambers_and_buttons() -> void:
	GameConfig.reset_runtime_defaults()
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, 20)

	_assert.gt(main.runtime.chambers.size(), 0, "decoupling: old BallWar should still create control chambers")
	_assert.gt(main.runtime.ui_runtime_ref("add_ball_buttons", {}).size(), 0, "decoupling: old BallWar should still create add-ball buttons")
	_assert.eq(main.runtime.fire_director, null, "decoupling: old BallWar should not create FireDirector")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _start_main(mode_name: String, grid_size: int):
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = mode_name
	main.selected_grid_size = grid_size
	main._start_game(grid_size, true, false)
	await process_frame
	return main
