extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionMoraleRulesScript = preload("res://scripts/cardfront/morale/RegionMoraleRules.gd")
const RegionMoraleSystemScript = preload("res://scripts/cardfront/morale/RegionMoraleSystem.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

var _assert: TestAssert
var _morale_ticks: Array = []
var _morale_finished: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[RegionMoraleTest] Starting Cardfront region morale tests")
	await process_frame

	_test_support_player_neutral_to_player()
	_test_support_player_ai_to_neutral_when_no_neutral()
	_test_unrest_enemy_ai_to_neutral()
	_test_does_not_affect_cells_outside_target_region()
	_test_no_candidate_finishes_without_error()
	_test_fixed_seed_is_stable()
	_test_process_interval()
	_test_region_map_identity_is_unchanged()
	await _test_main_morale_integration()
	await _flush()

	_assert.report("[RegionMoraleTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_support_player_neutral_to_player() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.NEUTRAL_OWNER)
	var system = _make_system(fixture.region_map, fixture.battlefield, 11)
	var region_id: int = int(fixture.region_id)

	_reset_signal_logs()
	_assert.that(system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 1), "support player: apply should accept valid morale request")
	system.tick_once()

	_assert.eq(_count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.PLAYER_FACTION), 1, "support player: one neutral cell should become player")
	_assert.eq(_morale_ticks.size(), 1, "support player: morale_tick should emit")
	_assert.eq(_morale_ticks[0].old_owner, CardfrontRulesScript.NEUTRAL_OWNER, "support player: old owner should be neutral")
	_assert.eq(_morale_ticks[0].new_owner, CardfrontRulesScript.PLAYER_FACTION, "support player: new owner should be player")
	_assert.eq(_morale_finished.size(), 1, "support player: one-point morale should finish")
	_cleanup_fixture(fixture, system)


func _test_support_player_ai_to_neutral_when_no_neutral() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.AI_FACTION)
	var system = _make_system(fixture.region_map, fixture.battlefield, 12)
	var region_id: int = int(fixture.region_id)
	var initial_ai: int = _count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.AI_FACTION)

	_reset_signal_logs()
	system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 1)
	system.tick_once()

	_assert.eq(_count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.NEUTRAL_OWNER), 1, "support player: no neutral candidate should push one AI cell to neutral")
	_assert.eq(_count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.AI_FACTION), initial_ai - 1, "support player: AI count should decrease by one")
	_assert.eq(_morale_ticks[0].old_owner, CardfrontRulesScript.AI_FACTION, "support player fallback: old owner should be AI")
	_assert.eq(_morale_ticks[0].new_owner, CardfrontRulesScript.NEUTRAL_OWNER, "support player fallback: new owner should be neutral")
	_cleanup_fixture(fixture, system)


func _test_unrest_enemy_ai_to_neutral() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.AI_FACTION)
	var system = _make_system(fixture.region_map, fixture.battlefield, 13)
	var region_id: int = int(fixture.region_id)
	var initial_ai: int = _count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.AI_FACTION)

	_reset_signal_logs()
	system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.UNREST_ENEMY, 1)
	system.tick_once()

	_assert.eq(_count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.AI_FACTION), initial_ai - 1, "unrest enemy: one AI cell should become neutral")
	_assert.eq(_count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.NEUTRAL_OWNER), 1, "unrest enemy: neutral count should increase by one")
	_assert.eq(_morale_ticks.size(), 1, "unrest enemy: morale_tick should emit")
	_assert.eq(_morale_finished.size(), 1, "unrest enemy: one-point morale should finish")
	_cleanup_fixture(fixture, system)


func _test_does_not_affect_cells_outside_target_region() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.NEUTRAL_OWNER, CardfrontRulesScript.AI_FACTION)
	var system = _make_system(fixture.region_map, fixture.battlefield, 14)
	var region_id: int = int(fixture.region_id)
	var outside_cell: Vector2i = _first_cell_outside_region(fixture.region_map, region_id)
	var outside_owner_before: int = int(fixture.battlefield.owners[outside_cell.x][outside_cell.y])

	system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 1)
	system.tick_once()

	_assert.eq(int(fixture.battlefield.owners[outside_cell.x][outside_cell.y]), outside_owner_before, "morale: cells outside target region should not change")
	_cleanup_fixture(fixture, system)


func _test_no_candidate_finishes_without_error() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.PLAYER_FACTION)
	var system = _make_system(fixture.region_map, fixture.battlefield, 15)
	var region_id: int = int(fixture.region_id)
	var initial_player: int = _count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.PLAYER_FACTION)

	_reset_signal_logs()
	system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 3)
	system.tick_once()

	_assert.eq(_count_region_owner(fixture.region_map, fixture.battlefield, region_id, CardfrontRulesScript.PLAYER_FACTION), initial_player, "morale: no candidate should leave owners unchanged")
	_assert.eq(_morale_ticks.size(), 0, "morale: no candidate should not emit morale_tick")
	_assert.eq(_morale_finished.size(), 1, "morale: no candidate should finish cleanly")
	_cleanup_fixture(fixture, system)


func _test_fixed_seed_is_stable() -> void:
	var first: Dictionary = _make_fixture(CardfrontRulesScript.NEUTRAL_OWNER)
	var first_system = _make_system(first.region_map, first.battlefield, 101)
	_reset_signal_logs()
	first_system.apply_morale(int(first.region_id), CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 1)
	first_system.tick_once()
	var first_cell: Vector2i = _morale_ticks[0].changed_cell

	var second: Dictionary = _make_fixture(CardfrontRulesScript.NEUTRAL_OWNER)
	var second_system = _make_system(second.region_map, second.battlefield, 101)
	_reset_signal_logs()
	second_system.apply_morale(int(second.region_id), CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 1)
	second_system.tick_once()
	var second_cell: Vector2i = _morale_ticks[0].changed_cell

	_assert.eq(second_cell, first_cell, "morale: fixed seed should pick the same cell")
	_cleanup_fixture(first, first_system)
	_cleanup_fixture(second, second_system)


func _test_process_interval() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.NEUTRAL_OWNER)
	var system = _make_system(fixture.region_map, fixture.battlefield, 16)
	var region_id: int = int(fixture.region_id)

	_reset_signal_logs()
	system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 1)
	system._process(0.99)
	_assert.eq(_morale_ticks.size(), 0, "morale interval: below one second should not tick")
	system._process(0.01)
	_assert.eq(_morale_ticks.size(), 1, "morale interval: reaching one second should tick")
	_cleanup_fixture(fixture, system)


func _test_region_map_identity_is_unchanged() -> void:
	var fixture: Dictionary = _make_fixture(CardfrontRulesScript.NEUTRAL_OWNER)
	var system = _make_system(fixture.region_map, fixture.battlefield, 17)
	var region_id: int = int(fixture.region_id)
	var before_snapshot: String = JSON.stringify(fixture.region_map.snapshot(), "", true, true)

	system.apply_morale(region_id, CardfrontRulesScript.PLAYER_FACTION, RegionMoraleRulesScript.SUPPORT_PLAYER, 2)
	system.tick_once()
	system.tick_once()

	_assert.eq(JSON.stringify(fixture.region_map.snapshot(), "", true, true), before_snapshot, "morale: RegionMap region_id and region_type data should not change")
	_cleanup_fixture(fixture, system)


func _test_main_morale_integration() -> void:
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	_assert.eq(main.runtime.morale_system, null, "main integration: old BallWar mode should not create morale system")

	main._cleanup_game_layer()
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	_assert.that(main.runtime.morale_system != null and is_instance_valid(main.runtime.morale_system), "main integration: Cardfront should create morale system")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _make_fixture(region_owner: int, default_owner: int = CardfrontRulesScript.NEUTRAL_OWNER) -> Dictionary:
	var region_map = _make_region_map(40)
	var region_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)[0])
	var battlefield := _make_battlefield(40, default_owner)
	_set_region_owner(battlefield, region_map, region_id, region_owner)
	return {
		"region_map": region_map,
		"battlefield": battlefield,
		"region_id": region_id,
	}


func _make_region_map(grid_size: int):
	var region_map := RegionMapScript.new()
	region_map.configure(grid_size)
	region_map.generate_default_layout()
	return region_map


func _make_battlefield(grid_size: int, owner_id: int) -> Battlefield:
	var bf := Battlefield.new()
	bf.configure(grid_size)
	get_root().add_child(bf)
	bf.replace_owners(_make_owner_grid(grid_size, owner_id), false)
	return bf


func _make_system(region_map, battlefield, seed_value: int):
	var system = RegionMoraleSystemScript.new()
	get_root().add_child(system)
	system.setup(region_map, battlefield)
	system.set_seed(seed_value)
	system.morale_tick.connect(Callable(self, "_on_morale_tick"))
	system.morale_finished.connect(Callable(self, "_on_morale_finished"))
	return system


func _make_owner_grid(grid_size: int, owner_id: int) -> Array:
	var owners: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(owner_id)
		owners.append(col)
	return owners


func _set_region_owner(battlefield: Battlefield, region_map, region_id: int, owner_id: int) -> void:
	var owners: Array = battlefield.owners.duplicate(true)
	for cell in region_map.get_region_cells(region_id):
		owners[cell.x][cell.y] = owner_id
	battlefield.replace_owners(owners, false)


func _count_region_owner(region_map, battlefield: Battlefield, region_id: int, owner_id: int) -> int:
	var total: int = 0
	for cell in region_map.get_region_cells(region_id):
		if int(battlefield.owners[cell.x][cell.y]) == owner_id:
			total += 1
	return total


func _first_cell_outside_region(region_map, region_id: int) -> Vector2i:
	for x in range(region_map.grid_size):
		for y in range(region_map.grid_size):
			var cell := Vector2i(x, y)
			if region_map.get_region_id(cell) != region_id:
				return cell
	return Vector2i(-1, -1)


func _reset_signal_logs() -> void:
	_morale_ticks.clear()
	_morale_finished.clear()


func _on_morale_tick(region_id: int, changed_cell: Vector2i, old_owner: int, new_owner: int) -> void:
	_morale_ticks.append({
		"region_id": region_id,
		"changed_cell": changed_cell,
		"old_owner": old_owner,
		"new_owner": new_owner,
	})


func _on_morale_finished(region_id: int, mode: String) -> void:
	_morale_finished.append({
		"region_id": region_id,
		"mode": mode,
	})


func _cleanup_fixture(fixture: Dictionary, system) -> void:
	TestFixtures.cleanup_node(system)
	TestFixtures.cleanup_node(fixture.get("battlefield", null))
