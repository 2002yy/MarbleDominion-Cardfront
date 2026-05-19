extends SceneTree

const BulletPoolScript = preload("res://scripts/BulletPool.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[VisualPressurePolicyTest] Starting legacy/BallWar visual pressure tests (v0.1.3.1 rebalance)")
	await process_frame

	_test_legacy_idle_full_effects()
	_test_legacy_low_active_high_queue_no_degrade()
	_test_legacy_80_active_queue_mid_only()
	_test_legacy_250_active_queue_high()
	_test_legacy_700_active_queue_extreme()
	_test_legacy_force_simple_threshold()
	_test_legacy_low_fps_extreme()
	_test_legacy_trail_segments_protection()
	_test_legacy_trail_redraws_protection()
	_test_legacy_active_count_mid_pressure()

	_assert.report("[VisualPressurePolicyTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _resolve(pool, active_count: int, fps: int, queue_total: int, trail_segments: int = 0, trail_redraws: int = 0) -> Dictionary:
	return pool.resolve_visual_profile_for_tests(active_count, fps, queue_total, trail_segments, trail_redraws, GameConfig.GAME_MODE_BASIC)


func _test_legacy_idle_full_effects() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 60, 0)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 0, "Legacy: idle severity should be 0")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "Legacy: idle simple_draw should be false")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "Legacy: idle reduce should be false")
	_assert.eq(str(profile.get("trail_degrade_reason", "?")), "none", "Legacy: idle reason should be none")
	pool.free()


func _test_legacy_low_active_high_queue_no_degrade() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 60, 1200)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 0, "Legacy: active=8 with q=1200 should stay severity 0 (active < 80)")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "Legacy: active=8 q=1200 should not simple_draw")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "Legacy: active=8 q=1200 should not reduce")
	pool.free()


func _test_legacy_80_active_queue_mid_only() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 80, 60, 1200)

	var sev: int = int(profile.get("trail_pressure_severity", -1))
	_assert.gte(sev, 1, "Legacy: active=80 q=1200 severity should be at least 1")
	_assert.that(sev < 3, "Legacy: active=80 q=1200 should not reach extreme (actual=%d)" % sev)
	_assert.eq(bool(profile.get("simple_draw", true)), false, "Legacy: active=80 q=1200 should not simple_draw")
	pool.free()


func _test_legacy_250_active_queue_high() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 250, 60, 1500)

	var sev: int = int(profile.get("trail_pressure_severity", -1))
	_assert.gte(sev, 2, "Legacy: active=250 q=1500 severity should be at least 2")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "Legacy: active=250 q=1500 should not simple_draw (active < force_simple)")
	pool.free()


func _test_legacy_700_active_queue_extreme() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 700, 60, 2200)

	var sev: int = int(profile.get("trail_pressure_severity", -1))
	_assert.gte(sev, 3, "Legacy: active=700 q=2200 severity should reach extreme")
	_assert.eq(bool(profile.get("simple_draw", false)), true, "Legacy: active=700 q=2200 should simple_draw")
	pool.free()


func _test_legacy_force_simple_threshold() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_quality_by_name(GameConfig.QUALITY_MEDIUM)
	var threshold: int = GameConfig.get_force_simple_threshold()
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, threshold, 60, 0)

	_assert.eq(bool(profile.get("simple_draw", false)), true, "Legacy: force_simple_threshold should enable simple_draw")
	var sev: int = int(profile.get("trail_pressure_severity", -1))
	_assert.eq(sev, 3, "Legacy: force_simple_threshold should have severity 3")
	pool.free()


func _test_legacy_low_fps_extreme() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 15, 0)

	var sev: int = int(profile.get("trail_pressure_severity", -1))
	_assert.gte(sev, 3, "Legacy: fps=15 should reach extreme severity")
	_assert.eq(bool(profile.get("simple_draw", false)), true, "Legacy: fps=15 should simple_draw")
	_assert.eq(int(profile.get("trail_points", -1)), 0, "Legacy: fps=15 trail_points should be 0")
	pool.free()


func _test_legacy_trail_segments_protection() -> void:
	var pool = BulletPoolScript.new()
	var extreme_seg: int = GameConfig.get_trail_extreme_segments_threshold()
	var profile: Dictionary = _resolve(pool, 8, 60, 0, extreme_seg, 0)

	_assert.gte(int(profile.get("trail_pressure_severity", -1)), 3, "Legacy: trail_segments at extreme threshold should reach severity 3")
	_assert.eq(bool(profile.get("simple_draw", false)), true, "Legacy: extreme trail_segments should simple_draw")
	pool.free()


func _test_legacy_trail_redraws_protection() -> void:
	var pool = BulletPoolScript.new()
	var extreme_redraw: int = GameConfig.get_trail_extreme_redraws_threshold()
	var profile: Dictionary = _resolve(pool, 8, 60, 0, 0, extreme_redraw)

	_assert.gte(int(profile.get("trail_pressure_severity", -1)), 3, "Legacy: trail_redraws at extreme threshold should reach severity 3")
	_assert.eq(bool(profile.get("simple_draw", false)), true, "Legacy: extreme trail_redraws should simple_draw")
	pool.free()


func _test_legacy_active_count_mid_pressure() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_quality_by_name(GameConfig.QUALITY_MEDIUM)
	var threshold: int = GameConfig.get_mid_pressure_threshold()
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, threshold, 60, 0)

	_assert.gte(int(profile.get("trail_pressure_severity", -1)), 1, "Legacy: mid pressure threshold should yield severity >= 1")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "Legacy: mid pressure should not simple_draw")
	pool.free()
