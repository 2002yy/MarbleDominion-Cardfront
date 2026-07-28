extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const NeutralSystemScript = preload("res://scripts/cardfront/entities/CardfrontNeutralCreatureSystem.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const EntityVisualRegistryScript = preload("res://scripts/cardfront/entities/CardfrontEntityVisualRegistry.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")


class MockGateSystem:
	extends Node
	var closed: bool = true
	func get_lane_state(lane_index: int) -> Dictionary:
		return {
			"lane_index": lane_index,
			"state": "closed" if closed else "open",
			"owner_id": RulesScript.AI_FACTION,
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
	_test_definition_and_once_per_faction()
	_test_visual_registry()
	_test_spawn_and_two_sided_projectile_contact(fixture)
	_test_leader_targeting_gate_route_and_attacks(fixture)
	_assert.report("[CardfrontNeutralCreatureTest]")
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
			column.append(RulesScript.AI_FACTION if y < 6 else RulesScript.PLAYER_FACTION)
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
	_assert.that(runtime.setup(battlefield), "neutral creature: runtime setup")
	runtime.round_director = director
	runtime.territory_defense_system = defense
	return {
		"battlefield": battlefield,
		"fortify": fortify,
		"gate": gate,
		"director": director,
		"runtime": runtime,
	}


func _test_definition_and_once_per_faction() -> void:
	var definition: Dictionary = ManifestScript.get_definition(ManifestScript.UPGRADE_GATE_COLOSSUS)
	_assert.eq(str(definition.get("rarity", "")), ManifestScript.RARITY_RARE, "neutral creature: gate colossus is Rare")
	_assert.eq(str((definition.get("params", {}) as Dictionary).get("action", "")), "summon_gate_colossus", "neutral creature: manifest queues the neutral summon")
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var draft = DraftSystemScript.new()
	_assert.that(draft.is_upgrade_eligible(definition, state), "neutral creature: available before the faction summons one")
	ResolverScript.new().resolve(state, ManifestScript.UPGRADE_GATE_COLOSSUS)
	_assert.that(state.neutral_creature_summoned, "neutral creature: selection records the once-per-faction lock")
	_assert.that(not draft.is_upgrade_eligible(definition, state), "neutral creature: unavailable after the faction summons one")


func _test_visual_registry() -> void:
	var visuals = EntityVisualRegistryScript.new()
	var texture_path: String = visuals.get_texture_path(NeutralSystemScript.CREATURE_GATE_COLOSSUS)
	_assert.that(not texture_path.is_empty(), "neutral creature: visual path is registered centrally")
	_assert.that(ResourceLoader.exists(texture_path), "neutral creature: runtime visual can be loaded")
	_assert.that(visuals.load_texture(NeutralSystemScript.CREATURE_GATE_COLOSSUS) != null, "neutral creature: runtime visual resolves to a texture")
	_assert.that(visuals.load_texture("missing_creature") == null, "neutral creature: missing visual falls back silently")


func _test_spawn_and_two_sided_projectile_contact(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var colossus = _summon_colossus(runtime, RulesScript.PLAYER_FACTION)
	_assert.that(colossus != null, "neutral creature: player card summons the colossus")
	if colossus == null:
		return
	_assert.eq(colossus.owner_id, RulesScript.NEUTRAL_OWNER, "neutral creature: owner remains neutral")
	_assert.eq(colossus.hp, 6, "neutral creature: starts at six HP")
	_assert.eq(str(colossus.armor_type), CreatureStateScript.ARMOR_ARMORED, "neutral creature: uses armored collision rules")
	_assert.eq(colossus.size_slots, 2, "neutral creature: occupies two creature slots")
	_assert.eq(colossus.movement, 1, "neutral creature: moves one cell per round")
	_assert.eq(int(colossus.metadata.get("summoned_by", -1)), RulesScript.PLAYER_FACTION, "neutral creature: records its summoner without changing allegiance")

	var player_hit: Dictionary = runtime.resolve_capture_contact(
		colossus.cell,
		RulesScript.PLAYER_FACTION,
		{"projectile_type": ProjectileTypeScript.STANDARD, "projectile_direction": Vector2.UP}
	)
	var ai_hit: Dictionary = runtime.resolve_capture_contact(
		colossus.cell,
		RulesScript.AI_FACTION,
		{"projectile_type": ProjectileTypeScript.STANDARD, "projectile_direction": Vector2.DOWN}
	)
	_assert.eq(int(player_hit.get("damage_applied", 0)), 1, "neutral creature: player projectile can damage it")
	_assert.eq(int(ai_hit.get("damage_applied", 0)), 1, "neutral creature: AI projectile can damage it")
	_assert.eq(colossus.hp, 4, "neutral creature: damage from both factions accumulates")


func _test_leader_targeting_gate_route_and_attacks(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var gate = fixture["gate"]
	var fortify = fixture["fortify"]
	var director = fixture["director"]
	var colossus = runtime._neutral_creature_system._find_by_summoner(RulesScript.PLAYER_FACTION)
	var tower_result: Dictionary = runtime.build_or_upgrade_tower(
		RulesScript.AI_FACTION,
		RuntimeScript.TOWER_INTERCEPTOR
	)
	_assert.that(bool(tower_result.get("success", false)), "neutral creature: leading-faction tower fixture builds")
	var tower = runtime._find_owner_tower(RulesScript.AI_FACTION, RuntimeScript.TOWER_INTERCEPTOR)
	var target: Dictionary = runtime._neutral_creature_system._find_target(
		runtime._neutral_creature_system._leading_faction(colossus),
		colossus.cell
	)
	_assert.eq(int(target.get("owner_id", -1)), RulesScript.AI_FACTION, "neutral creature: targets the territory leader")

	for _index in range(5):
		runtime.advance_round()
	_assert.that(colossus.cell.y >= 5, "neutral creature: closed gates block neutral crossing")
	gate.closed = false
	for _index in range(12):
		runtime.advance_round()
		if tower.hp < tower.max_hp:
			break
	_assert.eq(tower.hp, tower.max_hp - 2, "neutral creature: tower attack deals two damage")
	_assert.that(colossus.is_alive(), "neutral creature: attacking does not self-destruct")
	runtime._remove_entity(tower.entity_id)

	var defense_cell := Vector2i(5, 3)
	fortify.set_fortify_stack(defense_cell, 2)
	runtime.registry.move_entity(colossus.entity_id, defense_cell)
	runtime._neutral_creature_system.run(colossus)
	_assert.eq(fortify.get_fortify_stack(defense_cell), 1, "neutral creature: removes one defense layer per action")
	_assert.that(colossus.is_alive(), "neutral creature: defense attack does not self-destruct")

	fortify.clear_fortify_stack(defense_cell)
	var chamber = director.turrets[RulesScript.AI_FACTION]
	var before_health: int = chamber.health
	var chamber_cell: Vector2i = runtime._neutral_creature_system._command_chamber_cell(RulesScript.AI_FACTION)
	runtime.registry.move_entity(colossus.entity_id, chamber_cell)
	runtime._neutral_creature_system.run(colossus)
	_assert.eq(chamber.health, before_health - 1, "neutral creature: chamber attack deals one damage")
	_assert.that(colossus.is_alive(), "neutral creature: chamber attack does not self-destruct")


func _summon_colossus(runtime, owner_id: int):
	var state = RunStateScript.new()
	state.setup(owner_id)
	ResolverScript.new().resolve(state, ManifestScript.UPGRADE_GATE_COLOSSUS)
	var results: Array = runtime.apply_pending_upgrade_actions(owner_id, state)
	_assert.eq(int((results[0] as Dictionary).get("spawned", 0)), 1, "neutral creature: queued action spawns exactly one colossus")
	return runtime._neutral_creature_system._find_by_summoner(owner_id)
