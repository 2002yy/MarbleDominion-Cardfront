extends SceneTree

const BulletPoolScript = preload("res://scripts/BulletPool.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontVisualPolicyTest] Starting Cardfront visual policy tests (v0.1.3.1 rebalance)")
	await process_frame

	_test_cardfront_low_active_full_effects()
	_test_cardfront_low_active_high_queue_still_low()
	_test_cardfront_moderate_active_high_queue_not_simple()
	_test_cardfront_severity_1_at_250_active()
	_test_cardfront_severity_2_at_700_active()
	_test_cardfront_severity_3_at_1500_active()
	_test_cardfront_low_fps_extreme()
	_test_cardfront_idle_full_effects()

	_assert.report("[CardfrontVisualPolicyTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _resolve(pool, active_count: int, fps: int, queue_total: int, trail_segments: int = 0, trail_redraws: int = 0) -> Dictionary:
	return pool.resolve_visual_profile_for_tests(active_count, fps, queue_total, trail_segments, trail_redraws, GameConfig.GAME_MODE_CARDFRONT)


func _test_cardfront_low_active_full_effects() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 60, 0)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 0, "CF: severity should be 0 (active=8, q=0, fps=60)")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "CF: simple_draw should be false (active=8)")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "CF: reduce_visual_effects should be false (active=8)")
	_assert.eq(int(profile.get("trail_points", -1)), 12, "CF: trail_points should be 12 (active=8)")
	pool.free()


func _test_cardfront_low_active_high_queue_still_low() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 60, 1200)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 0, "CF: severity should stay 0 even with high queue when active is low")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "CF: simple_draw should be false (active=8, q=1200)")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "CF: reduce should be false (active=8, q=1200)")
	pool.free()


func _test_cardfront_moderate_active_high_queue_not_simple() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 80, 60, 2000)

	var sev: int = int(profile.get("trail_pressure_severity", -1))
	_assert.eq(sev, 0, "CF: severity should be 0 (active=80 < 220, q doesn't participate)")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "CF: simple_draw should be false (active=80, q=2000)")
	pool.free()


func _test_cardfront_severity_1_at_250_active() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 250, 60, 0)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 1, "CF: severity should be 1 (active=250 >= 220)")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "CF: simple_draw should be false (severity 1)")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "CF: reduce should be false (severity 1)")
	_assert.eq(int(profile.get("trail_points", -1)), 8, "CF: trail_points should be 8 (severity 1)")
	pool.free()


func _test_cardfront_severity_2_at_700_active() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 700, 60, 0)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 2, "CF: severity should be 2 (active=700 >= 650)")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "CF: simple_draw should be false (severity 2)")
	_assert.eq(bool(profile.get("reduce_visual_effects", false)), true, "CF: reduce should be true (severity 2)")
	_assert.eq(int(profile.get("trail_points", -1)), 4, "CF: trail_points should be 4 (severity 2)")
	pool.free()


func _test_cardfront_severity_3_at_1500_active() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 1500, 60, 0)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 3, "CF: severity should be 3 (active=1500 >= 1400)")
	_assert.eq(bool(profile.get("simple_draw", false)), true, "CF: simple_draw should be true (severity 3)")
	_assert.eq(int(profile.get("trail_points", -1)), 0, "CF: trail_points should be 0 (severity 3)")
	pool.free()


func _test_cardfront_low_fps_extreme() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 24, 0)

	_assert.gte(int(profile.get("trail_pressure_severity", -1)), 3, "CF: severity should be >= 3 when fps=24")
	_assert.eq(bool(profile.get("simple_draw", false)), true, "CF: simple_draw should be true (fps extreme)")
	pool.free()


func _test_cardfront_idle_full_effects() -> void:
	var pool = BulletPoolScript.new()
	var profile: Dictionary = _resolve(pool, 8, 60, 0, 0, 0)

	_assert.eq(int(profile.get("trail_pressure_severity", -1)), 0, "CF: idle should have severity 0")
	_assert.eq(bool(profile.get("simple_draw", true)), false, "CF: idle should not simple_draw")
	_assert.eq(bool(profile.get("reduce_visual_effects", true)), false, "CF: idle should not reduce")
	_assert.eq(int(profile.get("trail_points", -1)), 12, "CF: idle trail_points should be 12")
	_assert.eq(str(profile.get("trail_degrade_reason", "?")), "none", "CF: idle reason should be none")
	pool.free()
