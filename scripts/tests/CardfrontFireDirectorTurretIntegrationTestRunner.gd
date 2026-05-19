extends SceneTree

const CardfrontFireDirectorScript = preload("res://scripts/cardfront/fire/CardfrontFireDirector.gd")
const CardfrontFireIntentScript = preload("res://scripts/cardfront/fire/CardfrontFireIntent.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontFireDirectorTurretIntegrationTest] Starting real-Turret + FireDirector integration tests")
	await process_frame

	_test_fire_directed_called_with_real_turret()
	_test_burst_directed_flag_set()
	_test_current_burst_shot_angle_matches_intent()
	_test_old_fire_burst_not_affected()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontFireDirectorTurretIntegrationTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fixture(grid_size: int = 32):
	var bf = Battlefield.new()
	bf.configure(grid_size)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var rm = RegionMapScript.new()
	rm.configure(grid_size)
	rm.generate_default_layout()

	var pool = BulletPool.new()
	get_root().add_child(pool)

	var turret = Turret.new()
	turret.faction_id = CardfrontRulesScript.PLAYER_FACTION
	turret.battlefield = bf
	turret.bullet_container = pool
	turret.position = Vector2(float(grid_size) * bf.cell_size * 0.25, float(grid_size) * bf.cell_size * 0.25)
	get_root().add_child(turret)

	var target_bias_system = CardfrontTargetBiasSystemScript.new()
	target_bias_system.setup(rm)
	get_root().add_child(target_bias_system)

	var turrets: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: turret,
	}

	var director = CardfrontFireDirectorScript.new()
	director.setup(rm, bf, turrets, target_bias_system, CardfrontRulesScript.get_duel_factions())
	get_root().add_child(director)

	return {
		"bf": bf,
		"rm": rm,
		"pool": pool,
		"turret": turret,
		"target_bias_system": target_bias_system,
		"director": director,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	for node in [fixture.get("director", null), fixture.get("target_bias_system", null), fixture.get("turret", null), fixture.get("pool", null), fixture.get("bf", null)]:
		TestFixtures.cleanup_node(node)


func _test_fire_directed_called_with_real_turret() -> void:
	var fixture: Dictionary = _make_fixture(20)
	var director = fixture.director
	var turret = fixture.turret
	var target_bias = fixture.target_bias_system

	var region_id: int = _first_controllable_region_id(fixture.rm)
	target_bias.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, region_id, 30.0)

	var issued: Array = director.tick(0.0)
	_assert.eq(issued.size(), 1, "integration: tick should issue one intent with bias set")

	var intent = issued[0] if issued.size() > 0 else null
	_assert.that(intent != null, "integration: intent should be valid")

	_assert.eq(int(turret.burst_remaining), int(intent.shot_count), "integration: turret should have burst count matching intent")
	_assert.eq(int(turret.burst_total), int(intent.shot_count), "integration: burst total should equal intent shot count")

	_cleanup_fixture(fixture)


func _test_burst_directed_flag_set() -> void:
	var fixture: Dictionary = _make_fixture(20)
	var turret = fixture.turret
	var target_bias = fixture.target_bias_system

	turret.burst_directed = false
	var region_id: int = _first_controllable_region_id(fixture.rm)
	target_bias.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, region_id, 30.0)

	fixture.director.tick(0.0)

	_assert.that(turret.burst_directed, "integration: burst_directed should be true after fire_directed")
	_assert.that(turret.burst_directed_spread >= 0.0, "integration: burst_directed_spread should be set")

	turret.burst_remaining = 0
	turret.burst_total = 0
	turret.burst_directed = false

	_cleanup_fixture(fixture)


func _test_current_burst_shot_angle_matches_intent() -> void:
	var fixture: Dictionary = _make_fixture(20)
	var turret = fixture.turret
	var target_bias = fixture.target_bias_system

	var region_id: int = _first_controllable_region_id(fixture.rm)
	target_bias.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, region_id, 30.0)

	var issued: Array = fixture.director.tick(0.0)
	var intent = issued[0] if issued.size() > 0 else null
	_assert.that(intent != null, "integration angle: intent should exist")

	var angle: float = turret._current_burst_shot_angle()
	_assert.that(not is_equal_approx(angle, turret.rotation) or turret.burst_total <= 1, "integration angle: directed angle should differ from default rotation (or single shot)")

	_cleanup_fixture(fixture)


func _test_old_fire_burst_not_affected() -> void:
	var fixture: Dictionary = _make_fixture(20)
	var turret = fixture.turret
	turret.burst_remaining = 0
	turret.burst_total = 0
	turret.burst_directed = true
	turret.burst_directed_spread = 1.0

	turret.fire_burst(5)
	_assert.eq(int(turret.burst_total), 5, "integration legacy: burst_total should be 5 from fire_burst")
	_assert.eq(int(turret.burst_remaining), 5, "integration legacy: burst_remaining should be 5")
	_assert.that(not turret.burst_directed, "integration legacy: burst_directed should be false after old fire_burst")
	_assert.that(turret.burst_locked, "integration legacy: burst should be locked")

	turret.cancel_burst()

	_cleanup_fixture(fixture)


func _first_controllable_region_id(rm) -> int:
	if rm == null or not rm.has_method("get_controllable_region_ids"):
		return -1
	var ids: Array = rm.get_controllable_region_ids()
	return int(ids[0]) if not ids.is_empty() else -1
