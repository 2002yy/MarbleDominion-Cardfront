extends SceneTree

const SimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1BalanceMatchSimulator.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const MapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
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
		var definition: Dictionary = MapRegistryScript.get_map_definition(str(map_id), ConfigScript.GRID_SIZE)
		_assert.eq(MapDefinitionScript.validate(definition), [], "B1 map schema should validate: %s" % str(map_id))

	var engineer: Dictionary = simulator.make_virtual_state_for_test(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var defense: Array = engineer["virtual_defense_cells"] as Array
	for index in range(5):
		_assert.eq(int(defense[index]), 2, "Engineer contact front should initialize at 2/2")
	_assert.eq(int(defense[5]), 1, "Engineer interior should initialize at 1/2")
	defense[0] = 0
	defense[1] = 0
	var repair: Dictionary = simulator.repair_virtual_state_for_test(engineer, 6)
	_assert.eq(int(repair["applied"]), 6, "repair should visit six distinct eligible cells")

	var open_gate: Dictionary = simulator.gate_snapshot_for_test("default_duel", 0, 0.25, 0.25, 0)
	var closed_gate: Dictionary = simulator.gate_snapshot_for_test("default_duel", 0, 0.75, 0.10, 0)
	_assert.eq(str(open_gate["state"]), "open", "balanced control should keep a gate open")
	_assert.eq(str(closed_gate["state"]), "closed", "dominant control should close a gate")

	var first: Dictionary = simulator.simulate("balanced_commander", "rapid_gunner", "cross_resource", 0, 91, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	var repeat: Dictionary = simulator.simulate("balanced_commander", "rapid_gunner", "cross_resource", 0, 91, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	var swapped: Dictionary = simulator.simulate("balanced_commander", "rapid_gunner", "cross_resource", 1, 91, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	_assert.eq(first, repeat, "B1 simulation should remain deterministic")
	_assert.neq(str(first["position_signature"]), str(swapped["position_signature"]), "side variants should be actual distinct simulation calls")
	var metrics: Dictionary = first["metrics"] as Dictionary
	_assert.gt(int(metrics.get("gate_passes", 0)) + int(metrics.get("gate_reflections", 0)), 0, "B1 should record gate traffic")
	_assert.gt(int(first.get("shared_upgrade_choice_count", 0)), 0, "B1 should use shared marginal AI")
	_assert.that(bool(first.get("b1_model", false)), "B1 result should identify the model")
	_assert.report("[CardfrontB1SimulationTest]")
	quit(0 if _assert.failures.is_empty() else 1)
