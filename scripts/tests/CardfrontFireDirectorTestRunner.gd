extends SceneTree

const CardfrontFireDirectorScript = preload("res://scripts/cardfront/fire/CardfrontFireDirector.gd")
const CardfrontFireRulesScript = preload("res://scripts/cardfront/fire/CardfrontFireRules.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


class MockTurret:
	extends RefCounted

	var global_position: Vector2 = Vector2.ZERO
	var rotation: float = 0.0
	var is_destroyed: bool = false
	var request_count: int = 0
	var shot_total: int = 0
	var intents: Array = []

	func request_directed_burst(intent) -> bool:
		request_count += 1
		shot_total += int(intent.shot_count)
		intents.append(intent)
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontFireDirectorTest] Starting Cardfront fire director tests")
	await process_frame

	_test_base_intent_without_target_bias()
	_test_target_bias_controls_intent_region()
	_test_tick_requests_turret_fire()
	_test_interval_limits_fire_frequency()
	_test_owner_shot_budget_hard_limit()
	_test_global_and_owner_budgets_keep_second_owner_firing()
	await _test_old_ballwar_mode_does_not_create_fire_director()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontFireDirectorTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_base_intent_without_target_bias() -> void:
	var fixture: Dictionary = _make_fixture()
	var director = fixture.director
	var intent = director.build_intent(CardfrontRulesScript.PLAYER_FACTION)

	_assert.that(intent != null, "fire director: base intent should be generated without target bias")
	if intent != null:
		_assert.eq(intent.owner_id, CardfrontRulesScript.PLAYER_FACTION, "fire director: intent owner")
		_assert.that(fixture.rm.is_inside(intent.target_cell), "fire director: target cell should be inside region map")
		_assert.that(intent.target_region_id >= 0, "fire director: target region should be valid")
		_assert.that(intent.shot_count >= 1, "fire director: intent should request at least one shot")
		_assert.neq(intent.reason, CardfrontFireRulesScript.REASON_TARGET_BIAS, "fire director: base intent should not be marked as target bias")

	_cleanup_fixture(fixture)


func _test_target_bias_controls_intent_region() -> void:
	var fixture: Dictionary = _make_fixture()
	var biased_region_id: int = _first_controllable_region_id(fixture.rm)
	fixture.target_bias_system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, biased_region_id, 5.0)

	var intent = fixture.director.build_intent(CardfrontRulesScript.PLAYER_FACTION)

	_assert.that(intent != null, "fire director: biased intent should be generated")
	if intent != null:
		_assert.eq(intent.target_region_id, biased_region_id, "fire director: target bias should control target region")
		_assert.eq(intent.reason, CardfrontFireRulesScript.REASON_TARGET_BIAS, "fire director: biased intent reason")

	_cleanup_fixture(fixture)


func _test_tick_requests_turret_fire() -> void:
	var fixture: Dictionary = _make_fixture()
	var turret: MockTurret = fixture.player_turret

	var issued: Array = fixture.director.tick(0.0)

	_assert.eq(issued.size(), 1, "fire director: first tick should issue one player intent")
	_assert.eq(turret.request_count, 1, "fire director: tick should request turret fire")
	_assert.eq(turret.shot_total, 1, "fire director: tick should request one shot")
	_assert.that(fixture.director.get_last_intent(CardfrontRulesScript.PLAYER_FACTION) != null, "fire director: last intent should be stored")

	_cleanup_fixture(fixture)


func _test_interval_limits_fire_frequency() -> void:
	var fixture: Dictionary = _make_fixture()
	var turret: MockTurret = fixture.player_turret

	fixture.director.tick(0.0)
	fixture.director.tick(0.10)
	_assert.eq(turret.request_count, 1, "fire director: interval should block immediate repeated fire")

	fixture.director.tick(CardfrontFireRulesScript.BASE_SHOT_INTERVAL)
	_assert.eq(turret.request_count, 2, "fire director: firing should resume after interval")

	_cleanup_fixture(fixture)


func _test_owner_shot_budget_hard_limit() -> void:
	var fixture: Dictionary = _make_fixture()
	var turret: MockTurret = fixture.player_turret
	fixture.director.shot_interval = 0.0
	fixture.director.max_total_shots_per_second = 5
	fixture.director.max_owner_shots_per_second = 2
	fixture.director.base_shot_count = 1

	for _i in range(6):
		fixture.director.tick(0.0)

	_assert.eq(turret.shot_total, 2, "fire director: per-owner shot budget should cap same-window fire")

	fixture.director.tick(1.0)
	_assert.eq(turret.shot_total, 3, "fire director: shot budget should reset after one second")

	_cleanup_fixture(fixture)


func _test_global_and_owner_budgets_keep_second_owner_firing() -> void:
	var fixture: Dictionary = _make_fixture(true)
	var player_turret: MockTurret = fixture.player_turret
	var ai_turret: MockTurret = fixture.ai_turret
	fixture.director.shot_interval = 0.0
	fixture.director.max_total_shots_per_second = 4
	fixture.director.max_owner_shots_per_second = 2
	fixture.director.base_shot_count = 4

	var issued: Array = fixture.director.tick(0.0)

	_assert.eq(issued.size(), 2, "fire director: both owners should receive an intent within the same shot window")
	_assert.eq(player_turret.shot_total, 2, "fire director: first owner should be capped by owner budget")
	_assert.eq(ai_turret.shot_total, 2, "fire director: second owner should receive remaining global budget")

	_cleanup_fixture(fixture)


func _test_old_ballwar_mode_does_not_create_fire_director() -> void:
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await process_frame

	_assert.eq(main.runtime.fire_director, null, "fire director: old BallWar mode should not create fire director")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _make_fixture(include_ai: bool = false) -> Dictionary:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var target_bias_system = CardfrontTargetBiasSystemScript.new()
	target_bias_system.setup(rm)

	var player_turret = MockTurret.new()
	player_turret.global_position = Vector2(-80.0, 100.0)
	var turrets: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_turret,
	}
	var active_factions: Array = [CardfrontRulesScript.PLAYER_FACTION]
	var ai_turret = null
	if include_ai:
		ai_turret = MockTurret.new()
		ai_turret.global_position = Vector2(480.0, 100.0)
		turrets[CardfrontRulesScript.AI_FACTION] = ai_turret
		active_factions.append(CardfrontRulesScript.AI_FACTION)

	var director = CardfrontFireDirectorScript.new()
	director.setup(rm, bf, turrets, target_bias_system, active_factions)

	return {
		"bf": bf,
		"rm": rm,
		"target_bias_system": target_bias_system,
		"director": director,
		"player_turret": player_turret,
		"ai_turret": ai_turret,
	}


func _first_controllable_region_id(region_map) -> int:
	var ids: Array = region_map.get_controllable_region_ids()
	if ids.is_empty():
		return 0
	return int(ids[0])


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
	TestFixtures.cleanup_node(fixture.get("target_bias_system", null))
	TestFixtures.cleanup_node(fixture.get("director", null))
