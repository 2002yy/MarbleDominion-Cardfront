extends SceneTree

const SimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1DeckMatchSimulator.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var simulator = SimulatorScript.new()
	_test_gate_contract(simulator)
	for raw_upgrade_id in UpgradeManifestScript.get_all_upgrade_ids():
		_test_upgrade_contract(simulator, str(raw_upgrade_id))
	_assert.report("[CardfrontB1ModelConsistencyTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_gate_contract(simulator) -> void:
	var half: Dictionary = GateRulesScript.state_from_control("a", 55, 100, "")
	var closed: Dictionary = GateRulesScript.state_from_control("a", 80, 100, "")
	_assert.eq(str(half.get("state", "")), GateRulesScript.STATE_HALF_OPEN, "shared gate rule should use the live 55 percent threshold")
	_assert.eq(str(closed.get("state", "")), GateRulesScript.STATE_CLOSED, "shared gate rule should use the live 80 percent threshold")
	_assert.that(GateRulesScript.is_projectile_allowed("a", 0, closed, 1, ""), "gate owner should always pass")
	_assert.that(not GateRulesScript.is_projectile_allowed("b", 0, closed, 1, ""), "closed gate should reject the opponent")
	var simulated: Dictionary = simulator.gate_snapshot_for_test("default_duel", 0, 0.75, 0.10, 0)
	_assert.eq(str(simulated.get("state", "")), str(closed.get("state", "")), "B1 and live gate rules should resolve the same closed state")


func _test_upgrade_contract(simulator, upgrade_id: String) -> void:
	var live_state = RunStateScript.new()
	live_state.setup_from_hero(1, HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var simulated_state: Dictionary = simulator.make_virtual_state_for_test(
		HeroRegistryScript.HERO_BALANCED_COMMANDER,
		1
	)
	if upgrade_id == UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
		var defense_cells: Array = simulated_state.get("virtual_defense_cells", []) as Array
		for index in range(mini(6, defense_cells.size())):
			defense_cells[index] = 0
	var live_result: Dictionary = UpgradeResolverScript.new().resolve(live_state, upgrade_id)
	var simulated_success: bool = simulator.apply_upgrade_for_test(simulated_state, upgrade_id)
	_assert.that(bool(live_result.get("success", false)), "live resolver should apply %s" % upgrade_id)
	_assert.that(simulated_success, "B1 resolver should apply %s" % upgrade_id)

	if upgrade_id == UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
		var live_repair: Dictionary = live_state.consume_pending_repair()
		var simulated_total: int = int(simulated_state.get("last_repair_applied", 0)) + int(simulated_state.get("last_repair_wasted", 0))
		_assert.eq(simulated_total, int(live_repair.get("points", 0)), "repair budget should match live resolution")
		return

	for key in [
		"next_volley_bonus",
		"next_volley_multiplier",
		"next_volley_armor_pierce_contacts",
		"attack_level",
		"territory_defense_cap",
		"rarity_level",
		"echo_next_choice_armed",
		"queued_echo_upgrade_id",
		"next_volley_conversions",
		"bridgehead_prefab_charges",
		"bridgehead_prefab_defense_bonus",
	]:
		_assert.eq(simulated_state.get(key), live_state.get(key), "state parity %s after %s" % [key, upgrade_id])

	var live_plan = VolleyResolverScript.new().build_and_consume(live_state)
	var simulated_plan: Dictionary = simulator.build_and_consume_volley_for_test(simulated_state)
	_assert.eq(
		simulated_plan.get("projectile_sequence", []),
		live_plan.projectile_sequence,
		"volley sequence should match live resolution after %s" % upgrade_id
	)
	_assert.eq(
		int(simulated_plan.get("armor_pierce_contacts", 0)),
		int(live_plan.armor_pierce_contacts),
		"armor-pierce budget should match live resolution after %s" % upgrade_id
	)
