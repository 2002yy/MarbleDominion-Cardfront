extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")


class MockGateSystem:
	extends Node
	var closed_for_player: bool = true
	func get_lane_state(lane_index: int) -> Dictionary:
		return {
			"lane_index": lane_index,
			"state": "closed" if closed_for_player else "open",
			"owner_id": RulesScript.AI_FACTION if closed_for_player else RulesScript.NEUTRAL_OWNER,
		}


class MockTurret:
	extends Node
	var health: int = 10
	func take_damage(amount: int) -> void:
		health = maxi(0, health - maxi(0, int(amount)))


class MockRoundDirector:
	extends Node
	var gate_connectivity_system = null
	var turrets: Dictionary = {}


class MockDefenseSystem:
	extends Node
	var fortify_layer = null
	func get_owner_cap(_owner_id: int) -> int:
		return 4
	func get_cell_defense(cell: Vector2i) -> int:
		return fortify_layer.get_fortify_stack(cell)


var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	var fixture: Dictionary = _make_fixture()
	_test_definition_and_eligibility()
	_test_gate_route_and_tower_demolition(fixture)
	_test_defense_demolition(fixture)
	_test_chamber_damage(fixture)
	_assert.report("[CardfrontSapperUnitTest]")
	TestFixtures.cleanup_node(fixture["battlefield"])
	quit(0 if _assert.failures.is_empty() else 1)


func _make_fixture() -> Dictionary:
	var battlefield = Battlefield.new()
	battlefield.configure(10)
	get_root().add_child(battlefield)
	var owners: Array = []
	for x in range(10):
		var column: Array = []
		for y in range(10):
			column.append(RulesScript.AI_FACTION if y < 5 else RulesScript.PLAYER_FACTION)
		owners.append(column)
	battlefield.replace_owners(owners, false)
	var fortify = FortifyLayerScript.new()
	fortify.configure(10)
	var defense = MockDefenseSystem.new()
	defense.fortify_layer = fortify
	get_root().add_child(defense)
	var gate = MockGateSystem.new()
	get_root().add_child(gate)
	var player_chamber = MockTurret.new()
	var ai_chamber = MockTurret.new()
	get_root().add_child(player_chamber)
	get_root().add_child(ai_chamber)
	var director = MockRoundDirector.new()
	director.gate_connectivity_system = gate
	director.turrets = {
		RulesScript.PLAYER_FACTION: player_chamber,
		RulesScript.AI_FACTION: ai_chamber,
	}
	get_root().add_child(director)
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield), "sapper: runtime setup")
	runtime.round_director = director
	runtime.territory_defense_system = defense
	return {
		"battlefield": battlefield,
		"fortify": fortify,
		"gate": gate,
		"director": director,
		"runtime": runtime,
	}


func _test_definition_and_eligibility() -> void:
	var definition: Dictionary = ManifestScript.get_definition(ManifestScript.UPGRADE_SAPPER_UNIT)
	_assert.eq(str(definition.get("rarity", "")), ManifestScript.RARITY_UNCOMMON, "sapper: rarity is Uncommon")
	_assert.eq(str((definition.get("params", {}) as Dictionary).get("action", "")), "summon_sapper_unit", "sapper: manifest queues the summon action")
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var draft = DraftSystemScript.new()
	_assert.that(draft.is_upgrade_eligible(definition, state), "sapper: available with an open creature slot")
	state.sync_entity_summary(3, 0, {})
	_assert.that(not draft.is_upgrade_eligible(definition, state), "sapper: unavailable at the creature cap")


func _test_gate_route_and_tower_demolition(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var gate = fixture["gate"]
	var tower_result: Dictionary = runtime.build_or_upgrade_tower(
		RulesScript.AI_FACTION,
		RuntimeScript.TOWER_INTERCEPTOR
	)
	_assert.that(bool(tower_result.get("success", false)), "sapper: enemy tower fixture builds")
	var tower = runtime._find_owner_tower(RulesScript.AI_FACTION, RuntimeScript.TOWER_INTERCEPTOR)
	var sapper = _summon_sapper(runtime)
	_assert.that(sapper != null, "sapper: card summons one unit")
	if sapper == null or tower == null:
		return
	_assert.eq(sapper.hp, 3, "sapper: starts at three HP")
	_assert.eq(str(sapper.armor_type), CreatureStateScript.ARMOR_ARMORED, "sapper: uses armored collision rules")
	_assert.eq(sapper.movement, 1, "sapper: moves one cell per round")
	_assert.eq(sapper.rounds_remaining, -1, "sapper: remains until destroyed or detonated")

	var blocked_cell: Vector2i = sapper.cell
	for _index in range(5):
		runtime.advance_round()
	_assert.that(sapper.is_alive(), "sapper: closed enemy gates prevent premature detonation")
	_assert.that(sapper.cell.y >= 5, "sapper: closed enemy gates keep it on its side of the river")
	_assert.that(sapper.cell != blocked_cell, "sapper: still approaches a gate while blocked")

	gate.closed_for_player = false
	var crossed_at_gate: bool = false
	var previous: Vector2i = sapper.cell
	for _index in range(12):
		runtime.advance_round()
		if previous.y >= 5 and sapper != null and sapper.is_alive() and sapper.cell.y < 5:
			var lane_xs: Array[int] = [
				roundi(9.0 * runtime._lane_center_ratio(0)),
				roundi(9.0 * runtime._lane_center_ratio(1)),
			]
			crossed_at_gate = sapper.cell.x in lane_xs
		if runtime._find_owner_creature_id(RulesScript.PLAYER_FACTION, RuntimeScript.CREATURE_SAPPER_UNIT) == null:
			break
		previous = sapper.cell
	_assert.that(crossed_at_gate, "sapper: river crossing occurs at a map gate")
	_assert.eq(tower.hp, 1, "sapper: full-health interceptor survives the three-damage blast at one HP")
	_assert.that(runtime._find_owner_creature_id(RulesScript.PLAYER_FACTION, RuntimeScript.CREATURE_SAPPER_UNIT) == null, "sapper: self-destructs after hitting a tower")
	runtime._remove_entity(tower.entity_id)


func _test_defense_demolition(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var fortify = fixture["fortify"]
	var target := Vector2i(5, 3)
	fortify.set_fortify_stack(target, 3)
	var sapper = _summon_sapper(runtime)
	if sapper == null:
		_assert.that(false, "sapper: defense fixture should spawn")
		return
	runtime.registry.move_entity(sapper.entity_id, target)
	runtime._run_sapper_unit(sapper)
	_assert.eq(fortify.get_fortify_stack(target), 1, "sapper: removes at most two defense layers")
	_assert.that(runtime.registry.get_entity(sapper.entity_id) == null, "sapper: self-destructs after demolishing defense")


func _test_chamber_damage(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var director = fixture["director"]
	var fortify = fixture["fortify"]
	fortify.clear_fortify_stack(Vector2i(5, 3))
	var chamber = director.turrets[RulesScript.AI_FACTION]
	var before_health: int = chamber.health
	var sapper = _summon_sapper(runtime)
	if sapper == null:
		_assert.that(false, "sapper: chamber fixture should spawn")
		return
	var chamber_cell: Vector2i = runtime._command_chamber_cell(RulesScript.AI_FACTION)
	runtime.registry.move_entity(sapper.entity_id, chamber_cell)
	runtime._run_sapper_unit(sapper)
	_assert.eq(chamber.health, before_health - 1, "sapper: deals only one command-chamber damage")
	_assert.that(runtime.registry.get_entity(sapper.entity_id) == null, "sapper: self-destructs after chamber contact")


func _summon_sapper(runtime):
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	ResolverScript.new().resolve(state, ManifestScript.UPGRADE_SAPPER_UNIT)
	var results: Array = runtime.apply_pending_upgrade_actions(RulesScript.PLAYER_FACTION, state)
	_assert.eq(int((results[0] as Dictionary).get("spawned", 0)), 1, "sapper: queued action spawns exactly one unit")
	return runtime._find_owner_creature_id(RulesScript.PLAYER_FACTION, RuntimeScript.CREATURE_SAPPER_UNIT)
