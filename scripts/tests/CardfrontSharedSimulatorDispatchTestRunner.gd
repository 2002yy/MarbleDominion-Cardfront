extends SceneTree

const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const SharedSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontSharedAiBalanceMatchSimulator.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const ValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSharedSimulatorDispatchTest] Starting shared simulator dispatch tests")
	await process_frame
	var simulator = SharedSimulatorScript.new()
	var parity: Dictionary = simulator.call(
		"simulate",
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
		HeroRegistryScript.HERO_RAPID_GUNNER,
		"default_duel",
		0,
		73,
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	) as Dictionary
	_assert.that(bool(parity.get("success", false)), "shared simulator: parity match should complete")
	_assert.eq(str(parity.get("upgrade_valuation_mode", "")), ValuePolicyScript.MODE_MARGINAL, "shared simulator: parity should disclose marginal valuation")
	_assert.gt(int(parity.get("shared_upgrade_choice_count", 0)), 0, "shared simulator: parity core loop should dispatch choices through the shared policy")

	var historical_state: Dictionary = {
		"base_volley_count": 5,
		"attack_level": 0,
		"territory_defense_cap": 2,
		"rarity_level": 0,
		"echo_next_choice_armed": false,
		"applied_upgrade_counts": {},
	}
	var historical_choice: String = str(simulator.call(
		"choose_upgrade_id_for_test",
		[
			UpgradeManifestScript.UPGRADE_VOLLEY_X2,
			UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5,
		],
		historical_state,
		{},
		ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
	))
	_assert.eq(historical_choice, UpgradeManifestScript.UPGRADE_VOLLEY_X2, "shared simulator: historical replay should preserve the frozen x2 priority")

	_assert.report("[CardfrontSharedSimulatorDispatchTest]")
	quit(0 if _assert.failures.is_empty() else 1)
