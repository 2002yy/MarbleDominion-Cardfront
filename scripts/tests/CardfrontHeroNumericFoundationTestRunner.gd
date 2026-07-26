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
		HeroRegistryScript.HERO_BALANCED_COMMANDER: [6, 40, 1, 1],
		HeroRegistryScript.HERO_RAPID_GUNNER: [7, 36, 1, 1],
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: [5, 42, 1, 2],
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
	var player_cell: Vector2i = _find_owned_cell(main.runtime.battlefield, RulesScript.PLAYER_FACTION)
	var ai_cell: Vector2i = _find_owned_cell(main.runtime.battlefield, RulesScript.AI_FACTION)

	_assert.eq(str(main.runtime.hero_assignments[RulesScript.PLAYER_FACTION]), HeroRegistryScript.HERO_FORTIFICATION_ENGINEER, "runtime heroes: player assignment should be explicit")
	_assert.eq(str(main.runtime.hero_assignments[RulesScript.AI_FACTION]), HeroRegistryScript.HERO_RAPID_GUNNER, "runtime heroes: AI assignment should be explicit")
	_assert.eq(player_state.base_volley_count, 5, "runtime heroes: engineer should launch five base shots")
	_assert.eq(ai_state.base_volley_count, 7, "runtime heroes: gunner should launch seven base shots")
	_assert.eq(int(player_turret.max_health), 42, "runtime heroes: engineer chamber should have 42 health")
	_assert.eq(int(ai_turret.max_health), 36, "runtime heroes: gunner chamber should have 36 health")
	_assert.eq(main.runtime.territory_defense_system.get_owner_cap(RulesScript.PLAYER_FACTION), 2, "runtime heroes: engineer should begin with defense capacity two")
	_assert.eq(main.runtime.territory_defense_system.get_owner_cap(RulesScript.AI_FACTION), 1, "runtime heroes: gunner should begin with defense capacity one")
	_assert.eq(main.runtime.territory_defense_system.get_cell_defense(player_cell), 1, "runtime heroes: engineer starting cells should begin at one of two defense")
	_assert.eq(main.runtime.territory_defense_system.get_cell_defense(ai_cell), 1, "runtime heroes: gunner starting cells should begin at one of one defense")
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


func _find_owned_cell(battlefield, owner_id: int) -> Vector2i:
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			if int(battlefield.owners[x][y]) == int(owner_id):
				return Vector2i(x, y)
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
