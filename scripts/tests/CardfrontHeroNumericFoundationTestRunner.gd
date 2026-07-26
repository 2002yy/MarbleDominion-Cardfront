extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontHeroNumericFoundationTest] Starting hero numeric foundation tests")
	await process_frame

	_test_registry_baseline()
	_test_hero_run_state_and_volley_injection()
	await _test_runtime_assignments_drive_health_and_defense()
	await _test_ballwar_does_not_create_hero_runtime()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontHeroNumericFoundationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_registry_baseline() -> void:
	_assert.eq(HeroRegistryScript.validate_all(), [], "heroes: all first-generation definitions should validate")
	_assert.eq(HeroRegistryScript.get_hero_ids().size(), 3, "heroes: the baseline should contain exactly three heroes")
	_assert.eq(TuningScript.BASE_VOLLEY_COUNT, 6, "heroes: shared fallback should match the balanced commander")
	_assert.eq(TuningScript.MAX_TERRITORY_DEFENSE_CAP, 4, "heroes: territory defense hard cap should be four")
	_assert.eq(
		HeroRegistryScript.sanitize_hero_id("missing"),
		HeroRegistryScript.HERO_BALANCED_COMMANDER,
		"heroes: invalid selections should fall back to the balanced commander"
	)


func _test_hero_run_state_and_volley_injection() -> void:
	var expected: Dictionary = {
		HeroRegistryScript.HERO_BALANCED_COMMANDER: [6, 40, 1, 1, 1],
		HeroRegistryScript.HERO_RAPID_GUNNER: [7, 36, 1, 1, 1],
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: [5, 42, 1, 2, 2],
	}
	var resolver = VolleyResolverScript.new()
	for hero_id in expected.keys():
		var values: Array = expected[hero_id]
		var state = RunStateScript.new()
		state.setup_from_hero(RulesScript.PLAYER_FACTION, str(hero_id))
		_assert.eq(state.hero_id, str(hero_id), "heroes: run state should retain %s" % str(hero_id))
		_assert.eq(state.base_volley_count, int(values[0]), "heroes: %s base volley should match" % str(hero_id))
		_assert.eq(state.command_chamber_health, int(values[1]), "heroes: %s health should match" % str(hero_id))
		_assert.eq(state.starting_territory_defense, int(values[2]), "heroes: %s starting defense should match" % str(hero_id))
		_assert.eq(state.territory_defense_cap, int(values[3]), "heroes: %s defense cap should match" % str(hero_id))
		_assert.eq(state.starting_contact_front_defense, int(values[4]), "heroes: %s contact-front defense should match" % str(hero_id))
		_assert.eq(int(state.snapshot().get("starting_contact_front_defense", -1)), int(values[4]), "heroes: snapshot should retain contact-front defense")
		var plan = resolver.build_and_consume(state)
		_assert.eq(plan.shot_count, int(values[0]), "heroes: %s first volley should use its hero baseline" % str(hero_id))


func _test_runtime_assignments_drive_health_and_defense() -> void:
	var main = await _start_main(
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
		HeroRegistryScript.HERO_RAPID_GUNNER
	)
	var player_state = main.runtime.round_director.get_run_state(RulesScript.PLAYER_FACTION)
	var ai_state = main.runtime.round_director.get_run_state(RulesScript.AI_FACTION)
	var player_turret = main.runtime.turrets[RulesScript.PLAYER_FACTION]
	var ai_turret = main.runtime.turrets[RulesScript.AI_FACTION]
	var defense = main.runtime.territory_defense_system
	var player_front_cells: Array = defense.get_starting_contact_front_cells(RulesScript.PLAYER_FACTION)
	var ai_front_cells: Array = defense.get_starting_contact_front_cells(RulesScript.AI_FACTION)
	var player_front_cell: Vector2i = player_front_cells[0] if not player_front_cells.is_empty() else Vector2i(-1, -1)
	var ai_front_cell: Vector2i = ai_front_cells[0] if not ai_front_cells.is_empty() else Vector2i(-1, -1)
	var player_interior_cell: Vector2i = _find_owned_cell_excluding(
		main.runtime.battlefield,
		RulesScript.PLAYER_FACTION,
		player_front_cells
	)

	_assert.eq(str(main.runtime.hero_assignments[RulesScript.PLAYER_FACTION]), HeroRegistryScript.HERO_FORTIFICATION_ENGINEER, "runtime heroes: player assignment should be explicit")
	_assert.eq(str(main.runtime.hero_assignments[RulesScript.AI_FACTION]), HeroRegistryScript.HERO_RAPID_GUNNER, "runtime heroes: AI assignment should be explicit")
	_assert.eq(player_state.base_volley_count, 5, "runtime heroes: engineer should launch five base shots")
	_assert.eq(ai_state.base_volley_count, 7, "runtime heroes: gunner should launch seven base shots")
	_assert.eq(int(player_turret.max_health), 42, "runtime heroes: engineer chamber should have 42 health")
	_assert.eq(int(ai_turret.max_health), 36, "runtime heroes: gunner chamber should have 36 health")
	_assert.eq(defense.get_owner_cap(RulesScript.PLAYER_FACTION), 2, "runtime heroes: engineer should begin with defense capacity two")
	_assert.eq(defense.get_owner_cap(RulesScript.AI_FACTION), 1, "runtime heroes: gunner should begin with defense capacity one")
	_assert.that(player_front_cell.x >= 0 and player_interior_cell.x >= 0 and ai_front_cell.x >= 0, "runtime heroes: test cells should exist")
	_assert.eq(defense.get_cell_defense(player_front_cell), 2, "runtime heroes: engineer contact front should begin at two of two defense")
	_assert.eq(defense.get_cell_defense(player_interior_cell), 1, "runtime heroes: engineer interior territory should remain one of two defense")
	_assert.eq(defense.get_cell_defense(ai_front_cell), 1, "runtime heroes: gunner contact front should remain one of one defense")
	_assert.that(str(main.runtime.three_choice_panel.battle_phase_label.text).contains("筑垒工程师"), "runtime heroes: formal battle HUD should name the selected player hero")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_does_not_create_hero_runtime() -> void:
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	_assert.eq(main.runtime.hero_assignments, {}, "runtime heroes: BallWar should not create Cardfront hero assignments")
	_assert.eq(main.runtime.round_director, null, "runtime heroes: BallWar should not create a Cardfront round director")
	TestFixtures.cleanup_node(main)
	await _flush()


func _find_owned_cell_excluding(battlefield, owner_id: int, excluded: Array) -> Vector2i:
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			var cell := Vector2i(x, y)
			if int(battlefield.owners[x][y]) == int(owner_id) and not excluded.has(cell):
				return cell
	return Vector2i(-1, -1)


func _start_main(player_hero_id: String, ai_hero_id: String):
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main.selected_cardfront_player_hero_id = player_hero_id
	main.selected_cardfront_ai_hero_id = ai_hero_id
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
