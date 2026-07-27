extends SceneTree

const SimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1ArchetypeMatchSimulator.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const MapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontB1SimulationTest] Starting B1 tests")
	await process_frame
	var simulator = SimulatorScript.new()
	for map_id in MapRegistryScript.get_registered_map_ids():
		var safe_map_id: String = str(map_id)
		var definition: Dictionary = MapRegistryScript.get_map_definition(safe_map_id, ConfigScript.GRID_SIZE)
		_assert.eq(MapDefinitionScript.validate(definition), [], "B1 map schema should validate: %s" % safe_map_id)
		var profile: Dictionary = definition.get("simulation_profile", {}) as Dictionary
		var stall_chance: float = float(profile.get("b1_tail_stall_chance", 0.0))
		var stall_multiplier: float = float(profile.get("b1_tail_hit_multiplier", 0.0))
		_assert.gt(stall_chance, 0.0, "B1 map should expose a positive tail-stall chance: %s" % safe_map_id)
		_assert.that(stall_chance < 0.25, "B1 tail-stall chance should remain bounded: %s" % safe_map_id)
		_assert.gt(stall_multiplier, 0.0, "B1 tail multiplier should stay positive: %s" % safe_map_id)
		_assert.that(stall_multiplier < 1.0, "B1 tail multiplier should reduce only stalled matches: %s" % safe_map_id)

	var engineer: Dictionary = simulator.make_virtual_state_for_test(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var defense: Array = engineer["virtual_defense_cells"] as Array
	for index in range(5):
		_assert.eq(int(defense[index]), 2, "Engineer contact front should initialize at 2/2")
	_assert.eq(int(defense[5]), 1, "Engineer interior should initialize at 1/2")
	defense[0] = 0
	defense[1] = 0
	var repair: Dictionary = simulator.repair_virtual_state_for_test(engineer, 6)
	_assert.eq(int(repair["applied"]), 6, "repair should visit six distinct eligible cells")

	var context_simulator = SimulatorScript.new()
	var balanced_state: Dictionary = context_simulator.make_virtual_state_for_test(HeroRegistryScript.HERO_BALANCED_COMMANDER, 1)
	context_simulator.make_virtual_state_for_test(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER, 2)
	var opponent_context: Dictionary = context_simulator.call("_proxy_value_context", balanced_state) as Dictionary
	_assert.eq(int(opponent_context.get("enemy_defense_points", 0)), 45, "B1 AI context should read the Engineer opponent's 45 initial defense points")

	var pure_standard: Array = [
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.STANDARD,
	]
	var siege_mix: Array = [ProjectileTypeScript.SIEGE, ProjectileTypeScript.STANDARD]
	var suppression_mix: Array = [ProjectileTypeScript.SUPPRESSION, ProjectileTypeScript.STANDARD]
	_assert.eq(simulator.composition_followthrough_for_test(pure_standard), ProjectileTypeScript.PURE_STANDARD_FOLLOWTHROUGH_MULTIPLIER, "B1 composition: pure standard volleys should hold a route more accurately")
	_assert.eq(simulator.composition_followthrough_for_test(siege_mix), 1.0, "B1 composition: siege mixtures should keep neutral standard follow-through")
	_assert.eq(simulator.composition_followthrough_for_test(suppression_mix), ProjectileTypeScript.SUPPRESSION_FOLLOWTHROUGH_MULTIPLIER, "B1 composition: suppression openers should pay a visible rapid-follow-up accuracy cost")

	var typed_sequence: Array = [
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.SUPPRESSION,
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.SIEGE,
	]
	var prioritized_contacts: Dictionary = simulator.prioritized_defense_contacts_for_test(typed_sequence, 2, 17)
	_assert.that(prioritized_contacts.has(3), "B1 intent: siege should claim the first defended contact")
	_assert.that(prioritized_contacts.has(1), "B1 intent: suppression should claim the next defended contact")
	_assert.that(not prioritized_contacts.has(0) and not prioritized_contacts.has(2), "B1 intent: standards should follow after special projectiles")
	var intents: Dictionary = simulator.projectile_intents_for_test(typed_sequence)
	var chamber_candidates: Array = intents.get("chamber_candidates", []) as Array
	var territory_only: Array = intents.get("territory_only", []) as Array
	_assert.eq(chamber_candidates, [ProjectileTypeScript.STANDARD, ProjectileTypeScript.STANDARD, ProjectileTypeScript.SIEGE], "B1 intent: standards and siege may pressure the chamber")
	_assert.eq(territory_only, [ProjectileTypeScript.SUPPRESSION], "B1 intent: suppression should remain route-only")
	_assert.that(not chamber_candidates.has(ProjectileTypeScript.SUPPRESSION), "B1 intent: suppression must never enter chamber targeting")

	var open_gate: Dictionary = simulator.gate_snapshot_for_test("default_duel", 0, 0.25, 0.25, 0)
	var closed_gate: Dictionary = simulator.gate_snapshot_for_test("default_duel", 0, 0.75, 0.10, 0)
	_assert.eq(str(open_gate["state"]), "open", "balanced control should keep a gate open")
	_assert.eq(str(closed_gate["state"]), "closed", "dominant control should close a gate")

	var paired_seed_a: int = int(simulator.call("_b1_stream_seed", 91, 4, "a", 0))
	var paired_seed_b: int = int(simulator.call("_b1_stream_seed", 91, 4, "a", 1))
	_assert.eq(paired_seed_a, paired_seed_b, "side reruns should share the same random stream")

	var first: Dictionary = simulator.simulate("balanced_commander", "rapid_gunner", "cross_resource", 0, 91, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	var repeat: Dictionary = simulator.simulate("balanced_commander", "rapid_gunner", "cross_resource", 0, 91, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	var swapped: Dictionary = simulator.simulate("balanced_commander", "rapid_gunner", "cross_resource", 1, 91, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	_assert.eq(first, repeat, "B1 simulation should remain deterministic")
	_assert.neq(str(first["position_signature"]), str(swapped["position_signature"]), "side variants should be actual distinct simulation calls")
	var metrics: Dictionary = first["metrics"] as Dictionary
	_assert.gt(int(metrics.get("gate_passes", 0)) + int(metrics.get("gate_reflections", 0)), 0, "B1 should record gate traffic")
	_assert.gt(int(first.get("shared_upgrade_choice_count", 0)), 0, "B1 should use shared marginal AI")
	var card_by_hero: Dictionary = ((first.get("card_metrics", {}) as Dictionary).get("by_hero", {}) as Dictionary)
	_assert.that(card_by_hero.has(HeroRegistryScript.HERO_BALANCED_COMMANDER), "B1 should expose Balanced card metrics")
	_assert.that(card_by_hero.has(HeroRegistryScript.HERO_RAPID_GUNNER), "B1 should expose Gunner card metrics")
	_assert.that(bool(first.get("b1_model", false)), "B1 result should identify the model")
	_assert.report("[CardfrontB1SimulationTest]")
	quit(0 if _assert.failures.is_empty() else 1)