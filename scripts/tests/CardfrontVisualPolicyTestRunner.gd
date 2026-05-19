extends SceneTree

const BulletPoolScript = preload("res://scripts/BulletPool.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontVisualPolicyTest] Starting Cardfront visual policy tests")
	await process_frame

	_test_cardfront_low_pressure_keeps_full_effects()
	_test_ballwar_mid_pressure_keeps_original_strategy()
	_test_cardfront_high_pressure_can_still_degrade()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontVisualPolicyTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_cardfront_low_pressure_keeps_full_effects() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_quality_by_name(GameConfig.QUALITY_MEDIUM)
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var pool = BulletPoolScript.new()
	pool.set_visual_pressure_fps_override_for_tests(60)
	var profile: Dictionary = pool._resolve_visual_profile(GameConfig.get_mid_pressure_threshold())

	_assert.eq(bool(profile.get("simple_draw", true)), false, "visual policy: Cardfront low pressure should not enable simple_draw")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "visual policy: Cardfront low pressure should not reduce effects")
	_assert.gte(int(profile.get("trail_points", 0)), 10, "visual policy: Cardfront low pressure should keep at least ten trail points")
	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 1, "visual policy: Cardfront mid threshold should still report mid pressure")
	pool.free()


func _test_ballwar_mid_pressure_keeps_original_strategy() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_quality_by_name(GameConfig.QUALITY_MEDIUM)
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)
	var pool = BulletPoolScript.new()
	pool.set_visual_pressure_fps_override_for_tests(60)
	var profile: Dictionary = pool._resolve_visual_profile(GameConfig.get_mid_pressure_threshold())

	_assert.eq(bool(profile.get("simple_draw", true)), false, "visual policy: BallWar mid pressure should not force simple_draw")
	_assert.eq(bool(profile.get("reduce_visual_effects", false)), true, "visual policy: BallWar mid pressure should still reduce effects")
	_assert.eq(int(profile.get("trail_points", -1)), GameConfig.get_mid_trail_points(), "visual policy: BallWar mid pressure should keep the original trail budget")
	pool.free()


func _test_cardfront_high_pressure_can_still_degrade() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_quality_by_name(GameConfig.QUALITY_MEDIUM)
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var pool = BulletPoolScript.new()
	pool.set_visual_pressure_fps_override_for_tests(60)
	var profile: Dictionary = pool._resolve_visual_profile(GameConfig.get_high_pressure_threshold())

	_assert.eq(bool(profile.get("reduce_visual_effects", false)), true, "visual policy: Cardfront high pressure should still allow reduced effects")
	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 2, "visual policy: Cardfront high threshold should report high pressure")
	pool.free()
