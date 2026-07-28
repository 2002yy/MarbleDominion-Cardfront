extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	var battlefield = _make_battlefield()
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield), "armored guard: runtime setup")
	_test_definition_and_eligibility()
	_test_spawn_movement_and_collision(runtime)
	_assert.report("[CardfrontArmoredGuardTest]")
	TestFixtures.cleanup_node(battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _make_battlefield():
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
	return battlefield


func _test_definition_and_eligibility() -> void:
	var definition: Dictionary = ManifestScript.get_definition(ManifestScript.UPGRADE_ARMORED_GUARD)
	_assert.eq(str(definition.get("rarity", "")), ManifestScript.RARITY_UNCOMMON, "armored guard: rarity is Uncommon")
	_assert.eq(str((definition.get("params", {}) as Dictionary).get("action", "")), "summon_armored_guard", "armored guard: manifest queues the summon action")
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var draft = DraftSystemScript.new()
	_assert.that(draft.is_upgrade_eligible(definition, state), "armored guard: available with an open creature slot")
	state.sync_entity_summary(3, 0, {})
	_assert.that(not draft.is_upgrade_eligible(definition, state), "armored guard: unavailable at the creature cap")


func _test_spawn_movement_and_collision(runtime) -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var resolver = ResolverScript.new()
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_ARMORED_GUARD).get("success", false)), "armored guard: card resolves")
	var results: Array = runtime.apply_pending_upgrade_actions(RulesScript.PLAYER_FACTION, state)
	_assert.eq(int((results[0] as Dictionary).get("spawned", 0)), 1, "armored guard: card summons one unit")
	var guard = runtime._find_owner_creature_id(RulesScript.PLAYER_FACTION, RuntimeScript.CREATURE_ARMORED_GUARD)
	_assert.that(guard != null, "armored guard: runtime registers the unit")
	if guard == null:
		return
	_assert.eq(guard.hp, 4, "armored guard: starts at four HP")
	_assert.eq(str(guard.armor_type), CreatureStateScript.ARMOR_ARMORED, "armored guard: uses armored collision rules")
	_assert.eq(guard.movement, 1, "armored guard: moves one cell per round")
	_assert.eq(guard.rounds_remaining, -1, "armored guard: remains until destroyed")

	var target: Vector2i = runtime._find_nearest_guard_post(guard.owner_id, guard.cell)
	var before_distance: int = runtime._manhattan_distance(guard.cell, target)
	runtime.advance_round()
	_assert.that(runtime._manhattan_distance(guard.cell, target) < before_distance, "armored guard: advances toward the nearest gate or contested frontline")
	_assert.eq(int(runtime.battlefield.owners[guard.cell.x][guard.cell.y]), RulesScript.PLAYER_FACTION, "armored guard: movement stays on friendly territory")
	_assert.that(guard.is_alive(), "armored guard: permanent unit survives a round tick")

	var standard: Dictionary = runtime.resolve_capture_contact(
		guard.cell,
		RulesScript.AI_FACTION,
		{"projectile_type": ProjectileTypeScript.STANDARD, "projectile_direction": Vector2.DOWN}
	)
	_assert.eq(int(standard.get("damage_applied", 0)), 1, "armored guard: standard projectile deals one damage")
	_assert.that(bool(standard.get("bounce_projectile", false)), "armored guard: standard projectile visibly bounces")
	_assert.that(not bool(standard.get("consume_projectile", true)), "armored guard: standard projectile is not silently consumed")

	var siege: Dictionary = runtime.resolve_capture_contact(
		guard.cell,
		RulesScript.AI_FACTION,
		{"projectile_type": ProjectileTypeScript.SIEGE, "projectile_direction": Vector2.DOWN}
	)
	_assert.eq(int(siege.get("damage_applied", 0)), 2, "armored guard: siege projectile deals two armored damage")
	_assert.that(bool(siege.get("consume_projectile", false)), "armored guard: siege projectile is consumed on contact")
