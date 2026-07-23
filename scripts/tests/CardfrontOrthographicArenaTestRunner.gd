extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontOrthographicArenaTest] Starting orthographic arena tests")
	await process_frame

	await _test_cardfront_builds_true_3d_mirror()
	await _test_ballwar_does_not_build_3d_mirror()
	GameConfig.reset_runtime_defaults()

	_assert.report("[CardfrontOrthographicArenaTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_cardfront_builds_true_3d_mirror() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, 40)
	var view = main.runtime.orthographic_arena_view
	_assert.that(view != null and is_instance_valid(view), "orthographic arena: Cardfront should create the 3D mirror")
	if view == null or not is_instance_valid(view):
		TestFixtures.cleanup_node(main)
		await _flush()
		return
	_assert.that(view.world_viewport is SubViewport, "orthographic arena: presentation should render through a SubViewport")
	_assert.eq(view.viewport_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "orthographic arena: presentation must not block 2D battlefield input")
	var camera: Camera3D = view.get_camera_for_test()
	_assert.that(camera != null and camera.current, "orthographic arena: camera should be active")
	_assert.eq(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "orthographic arena: camera must be orthographic")
	_assert.eq(view.get_tile_instance_count_for_test(), 1600, "orthographic arena: every 40x40 simulation cell should have one 3D tile")
	_assert.eq(view.get_region_label_count_for_test(), 5, "orthographic arena: default map should expose five in-world stronghold labels")
	_assert.eq(view.get_turret_proxy_count_for_test(), 2, "orthographic arena: player and AI should each have one visual proxy")
	_assert.that(main.runtime.battlefield is Node2D, "orthographic arena: 2D Battlefield remains the authority")
	_assert.that(main.runtime.bullet_pool is Node2D, "orthographic arena: 2D BulletPool remains the authority")

	var player_turret = main.runtime.turrets.get(CardfrontRulesScript.PLAYER_FACTION, null)
	var world_position: Vector3 = view.simulation_to_world_for_test(player_turret.global_position)
	_assert.that(world_position.z > 0.0, "orthographic arena: bottom player position should map to the positive-Z half")

	main.runtime.bullet_pool.spawn_bullet(
		CardfrontRulesScript.PLAYER_FACTION,
		player_turret.global_position,
		Vector2.UP,
		main.runtime.battlefield,
		main.runtime.turrets
	)
	await process_frame
	_assert.gte(view.get_bullet_proxy_count_for_test(), 1, "orthographic arena: active 2D bullets should receive reusable 3D proxies")

	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_does_not_build_3d_mirror() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, 20)
	_assert.eq(main.runtime.orthographic_arena_view, null, "orthographic arena: BallWar must not create the Cardfront 3D mirror")
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, grid_size: int):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = grid_size
	main._start_game(grid_size, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
