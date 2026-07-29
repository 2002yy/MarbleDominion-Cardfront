extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontBattlefieldScaleTest] Starting battlefield scale tests")
	await process_frame

	await _test_cardfront_scale_presets_and_authority_isolation()
	await _test_ballwar_does_not_create_scale_control()
	GameConfig.reset_runtime_defaults()

	_assert.report("[CardfrontBattlefieldScaleTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_cardfront_scale_presets_and_authority_isolation() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, 40)
	var view = main.runtime.orthographic_arena_view
	var control = main.runtime.battlefield_scale_control
	_assert.that(view != null and is_instance_valid(view), "scale: Cardfront should create an orthographic view")
	_assert.that(control != null and is_instance_valid(control), "scale: Cardfront should create the formal scale control")
	if view == null or control == null:
		TestFixtures.cleanup_node(main)
		await _flush()
		return

	_assert.eq(control.get_button_count_for_test(), 3, "scale: control should expose exactly three deliberate presets")
	_assert.eq(control.get_selected_scale_for_test(), 1.0, "scale: match should begin at 100 percent")
	var authority_snapshot: String = JSON.stringify(main.runtime.battlefield.owners, "", true, true)
	var base_size: float = view.get_camera_for_test().size

	control.select_scale(0.92, false)
	_assert.eq(view.get_presentation_scale(), 0.92, "scale: 92 percent preset should be selected")
	_assert.that(view.get_camera_for_test().size > base_size, "scale: 92 percent should widen the orthographic framing")
	_assert.eq(JSON.stringify(main.runtime.battlefield.owners, "", true, true), authority_snapshot, "scale: zooming out must not mutate authoritative cells")

	control.select_scale(1.08, false)
	_assert.eq(view.get_presentation_scale(), 1.08, "scale: 108 percent preset should be selected")
	_assert.that(view.get_camera_for_test().size < base_size, "scale: 108 percent should tighten the orthographic framing")
	_assert.eq(JSON.stringify(main.runtime.battlefield.owners, "", true, true), authority_snapshot, "scale: zooming in must not mutate authoritative cells")

	_assert.eq(control.select_scale(1.03, false), 1.0, "scale: arbitrary values should snap to the nearest approved preset")
	_assert.eq(view.get_camera_for_test().size, base_size, "scale: snapped 100 percent should restore the base camera size")
	_assert.that(main.runtime.battlefield is Node2D, "scale: authoritative battlefield remains 2D")
	_assert.that(main.runtime.bullet_pool is Node2D, "scale: authoritative projectile pool remains 2D")
	_assert.eq(view.get_gate_count_for_test(), 2, "scale: gate presentation should remain intact")
	_assert.eq(view.get_turret_proxy_count_for_test(), 2, "scale: both command chambers should remain represented")

	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_does_not_create_scale_control() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, 20)
	_assert.eq(main.runtime.orthographic_arena_view, null, "scale: BallWar should not create the Cardfront orthographic view")
	_assert.eq(main.runtime.battlefield_scale_control, null, "scale: BallWar should not create the Cardfront scale control")
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, grid_size: int):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = grid_size
	main._start_game(grid_size, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
