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


class FailingTurret:
	extends RefCounted

	var global_position: Vector2 = Vector2.ZERO
	var is_destroyed: bool = false
	var request_count: int = 0

	func request_directed_burst(_intent) -> bool:
		request_count += 1
		return false


class SignalCollector:
	extends RefCounted

	var ticks: Array = []
	var requested: Array = []
	var issued: Array = []
	var skipped: Array = []

	func on_fire_tick(owner_id, intent) -> void:
		ticks.append({"owner_id": int(owner_id), "intent": intent})

	func on_fire_requested(owner_id, intent) -> void:
		requested.append({"owner_id": int(owner_id), "intent": intent})

	func on_fire_issued(owner_id, intent) -> void:
		issued.append({"owner_id": int(owner_id), "intent": intent})

	func on_fire_skipped(owner_id, reason) -> void:
		skipped.append({"owner_id": int(owner_id), "reason": str(reason)})

	func clear() -> void:
		ticks.clear()
		requested.clear()
		issued.clear()
		skipped.clear()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontFireDirectorSignalTest] Starting signal seam tests")
	await process_frame

	_test_fire_issued_signal_emitted_on_success()
	_test_fire_skipped_signal_on_turret_failure()
	_test_fire_skipped_signal_on_no_target()
	_test_fire_skipped_signal_on_budget_exceeded()
	_test_fire_tick_signal_emitted_with_valid_intent()
	_test_fire_requested_signal_emitted_before_dispatch()
	_test_signals_not_emitted_after_cleanup()
	await _test_old_tests_still_pass()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontFireDirectorSignalTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_fire_issued_signal_emitted_on_success() -> void:
	var collector := _make_fixture_with_collector()
	fixture.signal_collector = collector

	fixture.director.tick(0.0)

	_assert.eq(collector.issued.size(), 1, "fire_issued should emit once for successful fire")
	_assert.eq(int(collector.issued[0].owner_id), CardfrontRulesScript.PLAYER_FACTION, "fire_issued owner should match")

	_cleanup_fixture(fixture)


func _test_fire_skipped_signal_on_turret_failure() -> void:
	var fixture: Dictionary = _make_fixture()
	var failing_turret := FailingTurret.new()
	failing_turret.global_position = Vector2(-80.0, 100.0)
	fixture.turrets[CardfrontRulesScript.PLAYER_FACTION] = failing_turret
	fixture.director.setup(fixture.rm, fixture.bf, fixture.turrets, fixture.target_bias_system, [CardfrontRulesScript.PLAYER_FACTION])

	var collector := SignalCollector.new()
	fixture.signal_collector = collector
	fixture.director.fire_skipped.connect(collector.on_fire_skipped)

	fixture.director.tick(0.0)

	_assert.that(collector.skipped.size() > 0, "fire_skipped should emit when turret fails")
	if collector.skipped.size() > 0:
		_assert.eq(str(collector.skipped[0].reason), "turret_unavailable", "fire_skipped reason should be turret_unavailable")

	_cleanup_fixture(fixture)


func _test_fire_skipped_signal_on_no_target() -> void:
	var fixture: Dictionary = _make_fixture()
	var collector := SignalCollector.new()
	fixture.director.fire_skipped.connect(collector.on_fire_skipped)

	var intent = fixture.director.build_intent(CardfrontRulesScript.PLAYER_FACTION)
	_assert.that(intent == null, "no target with empty region map produces null intent")

	fixture.director.shot_interval = 0.0
	fixture.director.tick(0.0)

	var had_no_target: bool = false
	for entry in collector.skipped:
		if str(entry.reason) == "no_target":
			had_no_target = true
			break
	_assert.that(had_no_target, "fire_skipped with no_target reason should be emitted when no valid target exists")

	_cleanup_fixture(fixture)


func _test_fire_skipped_signal_on_budget_exceeded() -> void:
	var fixture: Dictionary = _make_fixture()
	var collector := SignalCollector.new()
	fixture.director.fire_skipped.connect(collector.on_fire_skipped)

	fixture.director.shot_interval = 0.0
	fixture.director.max_total_shots_per_second = 1
	fixture.director.max_owner_shots_per_second = 1
	fixture.director.base_shot_count = 1

	var issued_all: Array = fixture.director.tick(0.0)
	_assert.eq(issued_all.size(), 1, "first tick should issue")

	var second_issued: Array = fixture.director.tick(0.0)
	_assert.eq(second_issued.size(), 0, "second tick within window should not issue")

	var had_budget_skip: bool = false
	for entry in collector.skipped:
		if str(entry.reason) == "budget_exceeded":
			had_budget_skip = true
			break
	_assert.that(had_budget_skip, "fire_skipped with budget_exceeded should be emitted")

	_cleanup_fixture(fixture)


func _test_fire_tick_signal_emitted_with_valid_intent() -> void:
	var collector := _make_fixture_with_collector()
	fixture.signal_collector = collector

	fixture.director.tick(0.0)

	_assert.eq(collector.ticks.size(), 1, "fire_tick should emit once for successful fire")
	var tick_data: Dictionary = collector.ticks[0]
	_assert.eq(int(tick_data.owner_id), CardfrontRulesScript.PLAYER_FACTION, "fire_tick owner should match")
	_assert.that(tick_data.intent != null, "fire_tick intent should not be null")

	_cleanup_fixture(fixture)


func _test_fire_requested_signal_emitted_before_dispatch() -> void:
	var collector := _make_fixture_with_collector()
	fixture.signal_collector = collector

	fixture.director.tick(0.0)

	_assert.eq(collector.requested.size(), 1, "fire_requested should emit once for each successful fire")
	var req_data: Dictionary = collector.requested[0]
	_assert.eq(int(req_data.owner_id), CardfrontRulesScript.PLAYER_FACTION, "fire_requested owner should match")
	_assert.that(req_data.intent != null, "fire_requested intent should not be null")

	_cleanup_fixture(fixture)


func _test_signals_not_emitted_after_cleanup() -> void:
	var collector := _make_fixture_with_collector()
	fixture.signal_collector = collector

	fixture.director.tick(0.0)
	_assert.eq(collector.issued.size(), 1, "first tick should issue one intent")

	collector.clear()
	fixture.director.set_process(false)

	fixture.director.tick(0.5)

	_assert.eq(collector.ticks.size(), 0, "no signals should be emitted after set_process(false)")
	_assert.eq(collector.issued.size(), 0, "no fire_issued after set_process(false)")

	_cleanup_fixture(fixture)


func _test_old_tests_still_pass() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await process_frame

	_assert.that(main.runtime.fire_director != null, "fire director should exist in Cardfront mode")
	_assert.that(main.runtime.fire_director.has_signal("fire_tick"), "fire_director should have fire_tick signal")
	_assert.that(main.runtime.fire_director.has_signal("fire_requested"), "fire_director should have fire_requested signal")
	_assert.that(main.runtime.fire_director.has_signal("fire_issued"), "fire_director should have fire_issued signal")
	_assert.that(main.runtime.fire_director.has_signal("fire_skipped"), "fire_director should have fire_skipped signal")

	var intent = main.runtime.fire_director.build_intent(CardfrontRulesScript.PLAYER_FACTION)
	_assert.that(intent != null, "build_intent should still work after signal refactor")

	main._cleanup_game_layer()
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
		"turrets": turrets,
	}


func _make_fixture_with_collector() -> Dictionary:
	var fixture: Dictionary = _make_fixture()
	var collector := SignalCollector.new()
	fixture.director.fire_tick.connect(collector.on_fire_tick)
	fixture.director.fire_requested.connect(collector.on_fire_requested)
	fixture.director.fire_issued.connect(collector.on_fire_issued)
	fixture.director.fire_skipped.connect(collector.on_fire_skipped)
	fixture.signal_collector = collector
	return fixture


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
	TestFixtures.cleanup_node(fixture.get("target_bias_system", null))
	TestFixtures.cleanup_node(fixture.get("director", null))
