extends SceneTree

const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const SharedSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontSharedAiBalanceMatchSimulator.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const ValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSharedSimulatorDispatchTest] Starting shared simulator dispatch test")
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
	_assert.report("[CardfrontSharedSimulatorDispatchTest]")
	quit(0 if _assert.failures.is_empty() else 1)
